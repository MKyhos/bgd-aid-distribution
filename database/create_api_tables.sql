/*
  # Given the features created, this SQL script initializes views
    on the various administrative levels to be distayed in the end.

  This SQL script collects the calculation of any in DB feature 
  engineering step. In particular

  - Creating the buildings table
  - Calculate distances, floods, distribute population

  #TODO To be added if desired:
  - Materialized views suitable for joining / optimizig the frontend
    queries.
  - Voronoi partition for facilities, calculate per-facitility population
    etc.
*/

-- If tables already exist: drop em!
DROP TABLE IF EXISTS tbl_sblock_features;
DROP TABLE IF EXISTS tbl_block_features;
DROP TABLE IF EXISTS tbl_camp_features;

-- SBLOCK Level

CREATE TABLE tbl_sblock_features AS (
  SELECT b.*, (b.population / (st_area(g.geom) / 1000)) as pop_perArea, g.geom
  FROM (
    SELECT
      camp_id,
      block_id,
      sblock_id,
      Round(Sum(population), 0) AS population,
      Round(Sum(pop_female), 0) AS pop_female,
      avg(population) AS pop_perBuild, --population density: average population count per building
      Avg(dist_bath) AS dist_bath,
      Avg(dist_latr) AS dist_latr,
      Avg(dist_tube) AS dist_tube,
      Avg(dist_heal) AS dist_heal,
      Avg(dist_nutr) AS dist_nutr,
      Avg(dist_wpro) AS dist_wpro,
      Cast(Count(*) AS integer) AS count_buildings
    FROM buildings
    GROUP BY 1, 2, 3
  ) AS b,
  geo_admin AS g
  WHERE b.sblock_id = g.sblock_id
);

ALTER TABLE tbl_sblock_features
  add column flooded_perc float8 default 0, 
  ADD COLUMN n_bath int,
  ADD COLUMN n_latr int,
  ADD COLUMN n_tube int,
  ADD COLUMN n_heal int,
  ADD COLUMN n_nutr int,
  ADD COLUMN n_wpro int,
  ADD COLUMN pop_perBath float8, 
  ADD COLUMN pop_perTube float8, 
  ADD COLUMN pop_perLatr float8, 
  ADD COLUMN pop_perHeal float8, 
  ADD COLUMN pop_perNutr float8,
  ADD COLUMN wmn_perWpro float8;
 
 WITH fl AS (
  SELECT ga.sblock_id,
    Count(*) FILTER (WHERE gri.class = 'sanitation' AND gri.type IN ('both', 'latrine')) AS latr,
    Count(*) FILTER (WHERE gri.class = 'sanitation' AND gri.type IN ('both', 'bathing')) AS bath,
    Count(*) FILTER (WHERE gri.class = 'health_service') AS heal,
    Count(*) FILTER (WHERE gri.class = 'nutrition_serivice') AS nutr,
    Count(*) FILTER (WHERE gri.class = 'women_protection') AS wpro,
    Count(*) FILTER (WHERE gri.class = 'tubewell') AS tube 
  FROM geo_reach_infra AS gri
  JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
  GROUP BY 1
)
UPDATE tbl_sblock_features AS dsf
  SET
    n_latr = fl.latr,
    n_heal = fl.heal,
    n_nutr = fl.nutr,
    n_wpro = fl.wpro,
    n_tube = fl.tube,
    n_bath = fl.bath
  FROM fl
  WHERE dsf.sblock_id = fl.sblock_id;
 
--aggregate flood data per sblock: 
with buildings_affected as (
    select sblock_id, count(id)::float as flooded
    from buildings
    where count_flooded >= 1
    group by sblock_id
),
percent_flooded as (
  select dsf.sblock_id, ((100 / dsf.count_buildings) * ba.flooded) as flooded_perc
  from tbl_sblock_features as dsf natural join  buildings_affected as ba
)
update tbl_sblock_features 
set flooded_perc = percent_flooded.flooded_perc
from percent_flooded
where tbl_sblock_features.sblock_id = percent_flooded.sblock_id;

--aggregate the number of people per amenity:
UPDATE tbl_sblock_features 
  set
    pop_perLatr = population / nullif(n_latr, 0),
    pop_perHeal = population / nullif(n_heal, 0),
    pop_perNutr = population / nullif(n_nutr, 0),
    wmn_perWpro = pop_female / nullif(n_wpro, 0),
    pop_perTube = population / nullif(n_tube, 0),
    pop_perBath = population / nullif(n_bath, 0);

   
-- Transforming the SRID to webmercator (which is then inherited to the
-- following tables), and add a primary key:
ALTER TABLE tbl_sblock_features
  ADD PRIMARY KEY (sblock_id),
  ALTER COLUMN geom TYPE Geometry(MultiPolygon, 4326)
    USING ST_Transform(geom, 4326);

-- BLOCK level
-- Here, some results from the sblock level can be reused / aggregated.
-- Instead 

CREATE TABLE public.tbl_block_features AS (
  SELECT b.camp_id, b.block_id, sb.population, sb.pop_female, 
    b.pop_perBuild, (sb.population / st_area(sb.geom)) as pop_perArea,
    b.dist_heal, b.dist_bath, b.dist_latr, b.dist_nutr, b.dist_wpro, b.dist_tube, 
    b.count_buildings, 
    sb.n_bath, sb.n_latr, sb.n_tube, sb.n_heal, sb.n_nutr, sb.n_wpro, 
    (sb.population / nullif(sb.n_bath, 0)) as pop_perBath,
    (sb.population / nullif(sb.n_latr, 0)) as pop_perLatr,
    (sb.population / nullif(sb.n_tube, 0)) as pop_perTube,
    (sb.population / nullif(sb.n_heal, 0)) as pop_perHeal,
    (sb.population / nullif(sb.n_nutr, 0)) as pop_perNutr,
    (sb.pop_female / nullif(sb.n_wpro, 0)) as pop_perWpro,    
    sb.geom
  FROM (
    SELECT 
      camp_id,
      block_id,
      Avg(dist_heal) AS dist_heal,
      Avg(dist_bath) AS dist_bath,
      Avg(dist_latr) AS dist_latr,
      Avg(dist_nutr) AS dist_nutr,
      Avg(dist_wpro) AS dist_wpro,
      Avg(dist_tube) AS dist_tube,
      Count(*)::int AS count_buildings,
      Avg(population) as pop_perBuild
    FROM buildings
    GROUP BY 1, 2
  ) AS b, (
    SELECT block_id,
      Sum(population)::int AS population,
      Sum(pop_female)::int AS pop_female,
      Sum(n_tube)::int AS n_tube,
      Sum(n_latr)::int AS n_latr,
      Sum(n_bath)::int AS n_bath,
      Sum(n_wpro)::int AS n_wpro,
      Sum(n_heal)::int AS n_heal,
      Sum(n_nutr)::int AS n_nutr,
      ST_Union(geom) AS geom
    FROM tbl_sblock_features
    GROUP BY 1  
    ) AS sb
  WHERE b.block_id = sb.block_id
);

--aggregate flood data per block: 
alter table tbl_block_features 
add column flooded_perc float8 default 0;

with buildings_affected as (
    select block_id, count(id)::float as flooded
    from buildings
    where count_flooded >= 1
    group by block_id
),
percent_flooded as (
  select dsf.block_id, ((100 / dsf.count_buildings) * ba.flooded) as flooded_perc
  from tbl_block_features as dsf natural join  buildings_affected as ba
)
update tbl_block_features 
set flooded_perc = percent_flooded.flooded_perc
from percent_flooded
where tbl_block_features.block_id = percent_flooded.block_id;

-- setting the srid correctly, adding a primary key:
ALTER TABLE tbl_block_features
  ALTER COLUMN geom TYPE Geometry(geometry, 4326)
    USING ST_SetSRID(geom, 4326),
  ADD PRIMARY KEY (block_id);


-- CAMP Level
-- Again, reuse some of the work that has be done on the previous
-- levels...

CREATE TABLE public.tbl_camp_features AS (
  SELECT b.camp_id, sb.population, sb.pop_female, 
    b.pop_perBuild, (sb.population / st_area(sb.geom)) as pop_perArea,
    b.dist_heal, b.dist_bath, b.dist_latr, b.dist_nutr, b.dist_wpro, b.dist_tube, 
    b.count_buildings, 
    sb.n_bath, sb.n_latr, sb.n_tube, sb.n_heal, sb.n_nutr, sb.n_wpro, 
    (sb.population / nullif(sb.n_bath, 0)) as pop_perBath,
    (sb.population / nullif(sb.n_latr, 0)) as pop_perLatr,
    (sb.population / nullif(sb.n_tube, 0)) as pop_perTube,
    (sb.population / nullif(sb.n_heal, 0)) as pop_perHeal,
    (sb.population / nullif(sb.n_nutr, 0)) as pop_perNutr,
    (sb.pop_female / nullif(sb.n_wpro, 0)) as pop_perWpro,    
    sb.geom
  FROM (
    SELECT 
      camp_id,
      Avg(dist_heal) AS dist_heal,
      Avg(dist_bath) AS dist_bath,
      Avg(dist_latr) AS dist_latr,
      Avg(dist_nutr) AS dist_nutr,
      Avg(dist_wpro) AS dist_wpro,
      Avg(dist_tube) AS dist_tube,
      Count(*)::int AS count_buildings,
      Avg(population) as pop_perBuild
    FROM buildings
    GROUP BY 1
  ) AS b, (
    SELECT camp_id,
      Sum(population)::int AS population,
      Sum(pop_female)::int AS pop_female,
      Sum(n_tube)::int AS n_tube,
      Sum(n_latr)::int AS n_latr,
      Sum(n_bath)::int AS n_bath,
      Sum(n_wpro)::int AS n_wpro,
      Sum(n_heal)::int AS n_heal,
      Sum(n_nutr)::int AS n_nutr,
      ST_Union(geom) AS geom
    FROM tbl_block_features
    GROUP BY 1  
    ) AS sb
  WHERE b.camp_id = sb.camp_id
);

--aggregate flood data per camp: 
alter table tbl_camp_features 
add column flooded_perc float8 default 0;

with buildings_affected as (
    select camp_id, count(id)::float as flooded
    from buildings
    where count_flooded >= 1
    group by camp_id
),
percent_flooded as (
  select dsf.camp_id, ((100 / dsf.count_buildings) * ba.flooded) as flooded_perc
  from tbl_camp_features dsf natural join  buildings_affected as ba
)
update tbl_camp_features 
set flooded_perc = percent_flooded.flooded_perc
from percent_flooded
where tbl_camp_features.camp_id = percent_flooded.camp_id;

-- Setting the srid correctly, add primary key:
ALTER TABLE tbl_camp_features
  ALTER COLUMN geom TYPE Geometry(geometry, 4326)
    USING ST_SetSRID(geom, 4326),
  ADD PRIMARY KEY (camp_id);

 select * from tbl_block_features tbf 
