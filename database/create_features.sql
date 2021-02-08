/*
  # CREATE / CALCULATE FEATURES

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

-- Create Table of OSM Buildings:

CREATE TABLE buildings AS (
  SELECT DISTINCT ON (osm_id) 
    osm_id AS id,
    building AS building_type,
    g.camp_id AS camp_id,
    g.block_id AS block_id,
    g.sblock_id AS sblock_id,
    ST_Area(way) AS area_sqm,
    ST_Centroid(o.way) AS geom
  FROM osm_polygon AS o
  JOIN geo_admin AS g ON ST_Intersects(o.way, g.geom)
  WHERE building IN ('yes', 'hut', 'residential', 'house', 'apartments')
);

ALTER TABLE buildings
  ALTER COLUMN geom TYPE geometry(POINT, 4326) USING ST_SetSRID(geom, 4326);

CREATE INDEX buildings_idx
  ON buildings USING GIST(geom);


-- Assign population to Building, based on block ID and 

-- Create additional column, set to 0 by default.
ALTER TABLE buildings
  ADD COLUMN IF NOT EXISTS count_flooded int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS n_population numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS n_pop_female numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS dist_bath numeric, -- Distance to bathing stuff
  ADD COLUMN IF NOT EXISTS dist_latr numeric, -- Distance to latrines
  ADD COLUMN IF NOT EXISTS dist_tube numeric, -- Distance to tubewells
  ADD COLUMN IF NOT EXISTS dist_heal numeric, -- Distance to health facilities
  ADD COLUMN IF NOT EXISTS dist_nutr numeric, -- Distance to nutrition facilities
  ADD COLUMN IF NOT EXISTS dist_wpro numeric; -- Distance to women protection area



-- Calculate overlaps of flooding with building centroids and update the buildings
-- table accordingly.
WITH
  building_flooded AS (
    SELECT id AS building_id, sblock_id, flood AS flood_id
    FROM buildings AS b
    INNER JOIN geo_floods AS f ON ST_Within(b.geom, f.geom)),
  building_count AS (
    SELECT building_id, Count(*) AS count 
    FROM building_flooded
    GROUP BY 1
  )
UPDATE buildings
  SET count_flooded = Coalesce(b.count, 0)
  FROM building_count AS b
  WHERE buildings.id = b.building_id;

-- Distribute Population to buildings according to the share of area of
-- a building to the total building area in the respective block.
-- Status: :checkmark:

WITH 
  camp_info AS (
    SELECT block_id,
      Sum(area_sqm) AS camp_b_area,
      Count(*) AS camp_b_number
    FROM buildings
    GROUP BY 1
  )
UPDATE buildings AS b1
  SET n_population = (
      (0.5 * (d.pop_total / ci.camp_b_number)) +           --distribute half of the population data per building in general
      ((d.pop_total / 2) * (b1.area_sqm / ci.camp_b_area)) --distribute the other half depending on the building size
  )
  FROM dta_block AS d
  JOIN camp_info AS ci ON d.block_id = ci.block_id
  WHERE b1.block_id = d.block_id;
 
WITH 
  camp_info AS (
    SELECT block_id,
      Sum(area_sqm) AS camp_b_area,
      Count(*) AS camp_b_number
    FROM buildings
    GROUP BY 1
  ),
  pop_female as (
    select block_id, (f_below_1 + f_1_to_4 + f_5_to_11 + f_12_to_17 + f_18_to_59 + f_60_plus) as pop_female
    from dta_block d
  )
UPDATE buildings AS b1
  SET n_pop_female = (
      (0.5 * (d.pop_female / ci.camp_b_number)) +           --distribute half of the population data per building in general
      ((d.pop_female / 2) * (b1.area_sqm / ci.camp_b_area)) --distribute the other half depending on the building size
  )
  FROM pop_female as d
  JOIN camp_info AS ci ON d.block_id = ci.block_id
  WHERE b1.block_id = d.block_id;



 