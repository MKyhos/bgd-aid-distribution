--create views that are flexible to when new data was added to the database 

--1. create voronois to 
-- * visualize distances to the nearest e.g. health station from every part of the camp
-- * make distance calculations faster because we already know which is the nearest neighbor

--bathing stuff:
create view voronoi_bath as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        WHERE (class = 'sanitation' AND type != 'latrine') or class = 'new_bathing') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  WHERE (gri.class = 'sanitation' AND gri.type != 'latrine') or class = 'new_bathing'
);

create view voronoi_bath_pop as (
  select v.*, sum(b.n_population) as pop_perBath
  from voronoi_bath v left join buildings b on st_intersects(v.geom, b.geom)
  group by v.fid, v.point, v.geom);

--latrines: 
create view voronoi_latr as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where (class = 'sanitation' AND type != 'bathing') or class = 'new_latrine') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where (gri.class = 'sanitation' AND gri.type != 'bathing') or class = 'new_latrine'
);

create view voronoi_latr_pop as (
  select v.*, sum(b.n_population) as pop_perLatr
  from voronoi_latr v left join buildings b on st_intersects(v.geom, b.geom)
  group by v.fid, v.point, v.geom);

--tubewells (incl. risk score):
create view voronoi_tube as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.contamination_risk_score, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'tubewell' or class = 'new_tubewell') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where gri.class = 'tubewell' or class = 'new_tubewell'
);

create view voronoi_tube_pop as (
  select v.*, sum(b.n_population) as pop_perTube
  from voronoi_tube v left join buildings b on st_intersects(v.geom, b.geom)
  group by v.fid, v.point, v.geom, v.contamination_risk_score);

--health services: 
create view voronoi_heal as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'health_service' or class = 'new_health_service') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where gri.class = 'health_service' or class = 'new_health_service'
);

create view voronoi_heal_pop as (
  select v.*, sum(b.n_population) as pop_perHeal
  from voronoi_heal v left join buildings b on st_intersects(v.geom, b.geom)
  group by v.fid, v.point, v.geom);

--nutrition services: 
create view voronoi_nutr as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom --somehow one of the voronois is missing in the middle
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'nutrition_service' or class = 'new_nutrition_service') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON st_intersects(dmp.geom, o.geom)
  where gri.class = 'nutrition_service' or class = 'new_nutrition_service'
); 

create view voronoi_nutr_pop as (
  select v.*, sum(b.n_population) as pop_perNutr
  from voronoi_nutr v left join buildings b on st_intersects(v.geom, b.geom)
  group by v.fid, v.point, v.geom);

--women protection services: 
create view voronoi_wpro as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'women_protection' or class = 'new_women_protection') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where gri.class = 'women_protection' or class = 'new_women_protection'
);

create view voronoi_wpro_pop as (
  select v.*, sum(b.n_pop_female) as pop_perWpro
  from voronoi_wpro v left join buildings b on st_intersects(v.geom, b.geom)
  group by v.fid, v.point, v.geom);
  
 
 /*
  For every building: calculate distance to nearest instance of
  - bath
  - tubewells
  - nutrition services
  - women protection areas
  - latrines
  - health facilities

*/
-- 1. Bathing stuff
UPDATE buildings AS b1
  SET dist_bath = v.distance
 from (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point, 3857)) as distance
       FROM   voronoi_bath v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;
 --takes: ~ 5sec. (if voronoi_bath is a table)
 --takes: ~48sec. (if voronoi_bath is a view)
 
/*UPDATE buildings AS b1
  SET dist_bath = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'sanitation' AND type != 'latrine'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  ); --takes: <1 min*/

-- 2. Tubewells
UPDATE buildings AS b1
  SET dist_tube = v.distance
 from (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point, 3857)) as distance
       FROM   voronoi_tube v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;
 --takes: ~ 5sec. (if voronoi is a table)
 --takes: ~38sec. (if voronoi is a view)

/*UPDATE buildings AS b1
  SET dist_tube = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'tubewell'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );*/

-- 3. nutrition servicves
UPDATE buildings AS b1
  SET dist_nutr = v.distance
 from (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point, 3857)) as distance
       FROM   voronoi_nutr v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;
--takes: ~ 5sec. (if voronoi is table)
--takes: ~7sec. (if voronoi is a view)

/*UPDATE buildings AS b1
  SET dist_nutr = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'nutrition_service'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );*/

 -- 4. Women protection zones
 UPDATE buildings AS b1
  SET dist_wpro = v.distance
 from (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point, 3857)) as distance
       FROM   voronoi_wpro v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;
 --takes:   3sec. (if voronoi is a table)
 --takes: ~11sec. (if voronoi is a view)

/*UPDATE buildings AS b1
  SET dist_wpro = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'women_protection'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );*/

-- 5. Latrines 
UPDATE buildings AS b1
  SET dist_latr = v.distance
 from (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point, 3857)) as distance
       FROM   voronoi_latr v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;
 --takes: ~ 3sec. (if voronoi is a table)
 --takes: ~57sec. (if voronoi is a view)

/*
UPDATE buildings AS b1
  SET dist_latr = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'sanitation' AND type != 'bathing'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );
*/

-- 6. Health care facilities
UPDATE buildings AS b1
  SET dist_heal = v.distance
 from (SELECT b1.id, ST_Distance(st_transform(b1.geom, 3857), st_transform(v.point, 3857)) as distance
       FROM   voronoi_heal v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;
 --takes: ~ 3sec. (if voronoi is a table)
 --takes: ~15sec. (if voronoi is a view)
 
/*UPDATE buildings AS b1
  SET dist_heal = (
    SELECT ST_Distance(b1.geom, gri.geom)
    FROM geo_reach_infra AS gri
    WHERE class = 'health_service'
    ORDER BY b1.geom <-> gri.geom
    LIMIT 1
  );*/
