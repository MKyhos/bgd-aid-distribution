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
  SELECT b.*, g.geom
  FROM (
    SELECT
      camp_id,
      block_id,
      sblock_id,
      Round(Sum(population), 0) AS population,
      Avg(dist_heal) AS dist_heal,
      Avg(dist_bath) AS dist_bath,
      Avg(dist_latr) AS dist_latr,
      Avg(dist_nutr) AS dist_nutr,
      Avg(dist_wpro) AS dist_wpro,
      Avg(dist_tube) AS dist_tube,
      Cast(Count(*) AS integer) AS count_buildings
    FROM buildings
    GROUP BY 1, 2, 3
  ) AS b,
  geo_admin AS g
  WHERE b.sblock_id = g.sblock_id
);

ALTER TABLE tbl_sblock_features
  ADD COLUMN n_latr int,
  ADD COLUMN n_heal int,
  ADD COLUMN n_nutr int,
  ADD COLUMN n_wpro int,
  ADD COLUMN n_tube int,
  ADD COLUMN n_bath int;

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
    n_latr = fl.latr::integer,
    n_heal = fl.heal::integer,
    n_nutr = fl.nutr::integer,
    n_wpro = fl.wpro::integer,
    n_tube = fl.tube::integer,
    n_bath = fl.bath::integer
  FROM fl
  WHERE dsf.sblock_id = fl.sblock_id;

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
  SELECT b.camp_id, b.block_id, sb.population,
    b.dist_heal, b.dist_bath, b.dist_latr, b.dist_nutr, b.dist_wpro,
    b.dist_tube, b.count_buildings, sb.n_latr, sb.n_heal, sb.n_nutr,
    sb.n_wpro, sb.n_tube, sb.n_bath, sb.geom
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
      Count(*)::int AS count_buildings
    FROM buildings
    GROUP BY 1, 2
  ) AS b, (
    SELECT block_id,
      Sum(population)::int AS population,
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

-- setting the srid correctly, adding a primary key:
ALTER TABLE tbl_block_features
  ALTER COLUMN geom TYPE Geometry(geometry, 4326)
    USING ST_SetSRID(geom, 4326),
  ADD PRIMARY KEY (block_id);


-- CAMP Level
-- Again, reuse some of the work that has be done on the previous
-- levels...

CREATE TABLE public.tbl_camp_features AS (
  SELECT c.camp_id, b.population,
    c.dist_heal, c.dist_bath, c.dist_latr, c.dist_nutr, c.dist_wpro,
    c.dist_tube, c.count_buildings, b.n_latr, b.n_heal, b.n_nutr,
    b.n_wpro, b.n_tube, b.n_bath, b.geom
  FROM (
    SELECT 
      camp_id,
      Avg(dist_heal) AS dist_heal,
      Avg(dist_bath) AS dist_bath,
      Avg(dist_latr) AS dist_latr,
      Avg(dist_nutr) AS dist_nutr,
      Avg(dist_wpro) AS dist_wpro,
      Avg(dist_tube) AS dist_tube,
      Count(*)::int AS count_buildings
    FROM buildings
    GROUP BY 1
  ) AS c, (
    SELECT camp_id,
      Sum(population)::int AS population,
      Sum(n_tube)::int AS n_tube,
      Sum(n_latr)::int AS n_latr,
      Sum(n_bath)::int AS n_bath,
      Sum(n_wpro)::int AS n_wpro,
      Sum(n_heal)::int AS n_heal,
      Sum(n_nutr)::int AS n_nutr,
      ST_Union(geom) AS geom
    FROM tbl_block_features
    GROUP BY 1  
    ) AS b
  WHERE c.camp_id = b.camp_id
);

-- Setting the srid correctly, add primary key:
ALTER TABLE tbl_camp_features
  ALTER COLUMN geom TYPE Geometry(geometry, 4326)
    USING ST_SetSRID(geom, 4326),
  ADD PRIMARY KEY (camp_id);

