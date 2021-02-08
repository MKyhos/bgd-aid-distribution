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
  SELECT g.*, b.population, b.pop_female, b.pop_perBuild, 
  b.dist_bath, b.dist_latr, b.dist_tube, b.dist_heal, b.dist_nutr, b.dist_wpro,
  b.count_buildings, (b.population / (st_area(g.geom) / 1000)) as pop_perArea
  FROM geo_admin AS g left join (
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
  ) AS b on b.sblock_id = g.sblock_id
);

ALTER TABLE tbl_sblock_features
  add column flooded_perc float8 default 0, 
  ADD COLUMN n_bath int,
  ADD COLUMN n_latr int,
  ADD COLUMN n_tube int,
  ADD COLUMN n_tube_risk int,  
  add column perc_tube_risk float8,
  ADD COLUMN pop_endangered float8, 
  ADD COLUMN n_heal int,
  ADD COLUMN n_nutr int,
  ADD COLUMN n_wpro int,
  ADD COLUMN pop_perBath float8, 
  ADD COLUMN pop_perLatr float8, 
  ADD COLUMN pop_perTube float8, 
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
    Count(*) FILTER (WHERE gri.class = 'tubewell') AS tube,
    Count(*) FILTER (WHERE gri.class = 'tubewell' and gri.contamination_risk_score in ('high', 'very high', 'intermediate')) AS tube_risk
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
    n_bath = fl.bath,
    n_tube_risk = fl.tube_risk,
    perc_tube_risk = (100 / nullif(fl.tube, 0)) * (fl.tube_risk)
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
/*UPDATE tbl_sblock_features 
  set
    pop_perLatr = population / nullif(n_latr, 0),
    pop_perHeal = population / nullif(n_heal, 0),
    pop_perNutr = population / nullif(n_nutr, 0),
    wmn_perWpro = pop_female / nullif(n_wpro, 0),
    pop_perTube = population / nullif(n_tube, 0),
    pop_endangered = population * perc_tube_risk / 100,
    pop_perBath = population / nullif(n_bath, 0);*/

--can take ~3 minutes: 
update tbl_sblock_features t
set pop_perBath = vb.pop, 
    pop_perLatr = vl.pop, 
    pop_perTube = vt.pop,
    pop_endangered = r.pop_endangered,
    pop_perHeal = vh.pop, 
    pop_perNutr = vn.pop, 
    wmn_perWpro = vw.pop
from (select t.sblock_id, avg(v.pop) as pop          
      from tbl_sblock_features t 
      left join voronoi_bath_pop v on st_intersects(t.geom, v.point)
      group by t.sblock_id) as vb,
     (select t.sblock_id, avg(v.pop) as pop
      from tbl_sblock_features t
      left join voronoi_latr_pop v on st_intersects(t.geom, v.point)
      group by t.sblock_id) as vl,
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_tube_pop v on st_intersects(t.geom, v.point)
      group by t.sblock_id) as vt,
     (select t.sblock_id, sum(v.pop) as pop_endangered 
      from tbl_sblock_features t
      left join voronoi_tube_pop v on st_intersects(t.geom, v.point)
      where contamination_risk_score in ('very high', 'high', 'intermediate')
      group by t.sblock_id) as r,
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_heal_pop v on st_intersects(t.geom, v.point)
      group by t.sblock_id) as vh, 
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_nutr_pop v on st_intersects(t.geom, v.point)
      group by t.sblock_id) as vn,  
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_wpro_pop v on st_intersects(t.geom, v.point)
      group by t.sblock_id) as vw
where t.sblock_id = vb.sblock_id
  and t.sblock_id = vl.sblock_id
  and t.sblock_id = vt.sblock_id
  and t.sblock_id = r.sblock_id
  and t.sblock_id = vh.sblock_id
  and t.sblock_id = vn.sblock_id
  and t.sblock_id = vw.sblock_id
    
-- Transforming the SRID to webmercator (which is then inherited to the
-- following tables), and add a primary key:
ALTER TABLE tbl_sblock_features
  ADD PRIMARY KEY (sblock_id)/*,
  ALTER COLUMN geom TYPE Geometry(MultiPolygon, 4326)
    USING ST_Transform(geom, 4326)*/;

-- BLOCK level
-- Here, some results from the sblock level can be reused / aggregated.
-- Instead 

CREATE TABLE public.tbl_block_features AS (
  SELECT sb.camp_id, sb.block_id, sb.population, sb.pop_female, 
    b.pop_perBuild, (sb.population / st_area(sb.geom)) as pop_perArea,
    b.dist_heal, b.dist_bath, b.dist_latr, b.dist_nutr, b.dist_wpro, b.dist_tube, 
    b.count_buildings, 
    sb.n_bath, sb.n_latr, sb.n_tube, sb.n_tube_risk, sb.perc_tube_risk,
    sb.pop_endangered, sb.n_heal, sb.n_nutr, sb.n_wpro, 
    sb.pop_perBath, sb.pop_perLatr, sb.pop_perTube, sb.pop_perHeal, sb.pop_perNutr, sb.wmn_perWpro,    
    sb.geom
  FROM (SELECT camp_id, block_id,
          Sum(population)::int AS population,
          Sum(pop_female)::int AS pop_female,
          Sum(n_tube)::int AS n_tube,
          sum(n_tube_risk)::int as n_tube_risk,
          (100 / nullif(Sum(n_tube)::int, 0)) * (sum(n_tube_risk)::int) as perc_tube_risk,
          Sum(n_latr)::int AS n_latr,
          Sum(n_bath)::int AS n_bath,
          Sum(n_wpro)::int AS n_wpro,
          Sum(n_heal)::int AS n_heal,
          Sum(n_nutr)::int AS n_nutr,
          avg(pop_perBath) as pop_perBath,
          avg(pop_perLatr) as pop_perLatr,
          avg(pop_perTube) as pop_perTube,
          sum(pop_endangered) as pop_endangered,
          avg(pop_perHeal) as pop_perHeal,
          avg(pop_perNutr) as pop_perNutr,
          avg(wmn_perWpro) as wmn_perWpro,    
          ST_Union(geom) AS geom
        FROM tbl_sblock_features
        GROUP BY 1, 2) AS sb 
  left join (SELECT block_id,
                    Avg(dist_heal) AS dist_heal,
                    Avg(dist_bath) AS dist_bath,
                    Avg(dist_latr) AS dist_latr,
                    Avg(dist_nutr) AS dist_nutr,
                    Avg(dist_wpro) AS dist_wpro,
                    Avg(dist_tube) AS dist_tube,
                    Count(*)::int AS count_buildings,
                    Avg(population) as pop_perBuild
             FROM buildings
             GROUP BY 1) AS b on sb.block_id = b.block_id
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
ALTER TABLE tbl_block_features/*
  ALTER COLUMN geom TYPE Geometry(geometry, 4326)
    USING ST_SetSRID(geom, 4326),*/
  ADD PRIMARY KEY (block_id);


-- CAMP Level
-- Again, reuse some of the work that has be done on the previous
-- levels...

CREATE TABLE public.tbl_camp_features AS (
  SELECT b.camp_id, sb.population, sb.pop_female, 
    b.pop_perBuild, (sb.population / st_area(sb.geom)) as pop_perArea, 
    b.dist_heal, b.dist_bath, b.dist_latr, b.dist_nutr, b.dist_wpro, b.dist_tube, 
    b.count_buildings, 
    sb.n_bath, sb.n_latr, sb.n_tube, sb.n_tube_risk, sb.perc_tube_risk,
    sb.pop_endangered, sb.n_heal, sb.n_nutr, sb.n_wpro, 
    sb.pop_perBath, sb.pop_perLatr, sb.pop_perTube, sb.pop_perHeal, sb.pop_perNutr, sb.wmn_perWpro,    
    sb.geom
  FROM (
    SELECT camp_id,
      Sum(population)::int AS population,
      Sum(pop_female)::int AS pop_female,
      Sum(n_tube)::int AS n_tube,
      sum(n_tube_risk)::int as n_tube_risk,
      (100 / nullif(Sum(n_tube)::int, 0)) * (sum(n_tube_risk)::int) as perc_tube_risk,
      Sum(n_latr)::int AS n_latr,
      Sum(n_bath)::int AS n_bath,
      Sum(n_wpro)::int AS n_wpro,
      Sum(n_heal)::int AS n_heal,
      Sum(n_nutr)::int AS n_nutr,
      avg(pop_perBath) as pop_perBath,
      avg(pop_perLatr) as pop_perLatr,
      avg(pop_perTube) as pop_perTube,
      sum(pop_endangered) as pop_endangered,
      avg(pop_perHeal) as pop_perHeal,
      avg(pop_perNutr) as pop_perNutr,
      avg(wmn_perWpro) as wmn_perWpro,    
      ST_Union(geom) AS geom
    FROM tbl_block_features
    GROUP BY 1  
    ) AS sb left join 
    (SELECT 
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
  ) AS b on sb.camp_id = b.camp_id
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
ALTER TABLE tbl_camp_features/*
  ALTER COLUMN geom TYPE Geometry(geometry, 4326)
    USING ST_SetSRID(geom, 4326),*/
  ADD PRIMARY KEY (camp_id);