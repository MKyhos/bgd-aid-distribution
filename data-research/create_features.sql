

-- Create Table of OSM Buildings:

CREATE TABLE osm_cxb_buildings AS (
  SELECT osm_id AS id,
    building AS building_type,
    g.camp_id AS camp_id,
    g.block_id AS block_id,
    g.sblock_id AS sblock_id,
    ST_Area(way) AS area_sqm,
    ST_Centroid(way) AS geom
  FROM osm_polygon AS o
  JOIN geo_admin AS g ON ST_Intersects(o.way, g.geom)
  WHERE building IS NOT NULL
);

CREATE INDEX osm_cxb_buildings_idx
  ON osm_cxb_buildings USING GIST(geom);


-- Assign population to Building, based on block ID and 

-- Create additional column, set to 0 by default.
ALTER TABLE osm_cxb_buildings
  ADD COLUMN IF NOT EXISTS count_flooded int DEFAULT 0,
  ADD COLUMN IF NOT EXISTS population numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS dist_tube numeric, -- Distance to tubewells
  ADD COLUMN IF NOT EXISTS dist_latr numeric, -- Distance to latrines
  ADD COLUMN IF NOT EXISTS dist_bath numeric, -- Distance to bathing stuff
  ADD COLUMN IF NOT EXISTS dist_heal numeric, -- Distance to health facilities
  ADD COLUMN IF NOT EXISTS dist_nutr numeric, -- Distance to nutrition facilities
  ADD COLUMN IF NOT EXISTS dist_wpro numeric; -- Distance to women protection area



-- Calculate overlaps with building centroids and update the osm_cxb_buildings
-- table accordingly.
WITH
  building_flooded AS (
    SELECT id AS building_id, sblock_id, flood AS flood_id
    FROM osm_cxb_buildings AS b
    INNER JOIN geo_floods AS f ON ST_Within(b.geom, f.geom)),
  building_count AS (
    SELECT building_id, Count(*) AS count 
    FROM building_flooded
    GROUP BY 1
  )
UPDATE osm_cxb_buildings
  SET count_flooded = Coalesce(b.count, 0)
  FROM building_count AS b
  WHERE osm_cxb_buildings.id = b.building_id;

-- Distribute Population to buil  dings according to the share of area of
-- a building to the total building area in the respective block.
-- Status: :checkmark:

WITH 
  block_building_areas AS (
    SELECT block_id, Sum(area_sqm) AS camp_area_sum
    FROM osm_cxb_buildings
    GROUP BY 1
  )
UPDATE osm_cxb_buildings AS b1
  SET population = (d.pop_total * (b1.area_sqm / bba.camp_area_sum))
  FROM dta_block AS d
  JOIN block_building_areas AS bba ON d.block_id = bba.block_id
  WHERE b1.block_id = d.block_id;

-- Get Nearest Neighbor distance for each house to various Elements...

-- 1. Bathing stuff
UPDATE osm_cxb_buildings AS b1
  SET dist_bath = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'sanitation' AND type != 'latrine'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );

-- 2. Tubewells
UPDATE osm_cxb_buildings AS b1
  SET dist_tube = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'tubewell'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );

-- 3. nutrition servicves
UPDATE osm_cxb_buildings AS b1
  SET dist_nutr = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'nutrition_service'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );

 -- 4. Women protection zones
 UPDATE osm_cxb_buildings AS b1
  SET dist_wpro = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'women_protection'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );

-- 5. Latrines 
UPDATE osm_cxb_buildings AS b1
  SET dist_latr = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'sanitation' AND TYPE != 'bathing'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );

-- 6. Health care facilities
UPDATE osm_cxb_buildings AS b1
  SET dist_heal = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class IS NULL AND TYPE NOT IN ('DTC', 'Other specialised services')
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );