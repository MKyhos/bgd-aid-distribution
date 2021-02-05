--create views that are flexible to when new data was added to the database 

drop table if exists voronoi_bath; 
drop table if exists voronoi_heal; 
drop table if exists voronoi_latr;
drop table if exists voronoi_nutr; 
drop table if exists voronoi_tube; 
drop table if exists voronoi_wpro;

--1. create voronois to 
-- * visualize distances to the nearest e.g. health station from every part of the camp
-- * make distance calculations faster because we already know which is the nearest neighbor

--bathing stuff:
create table voronoi_bath as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        WHERE class = 'sanitation' AND type != 'latrine') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  WHERE gri.class = 'sanitation' AND gri.type != 'latrine'
);

alter table voronoi_bath add column population float8; 
update voronoi_bath v
set population = t.pop
from (select v.fid, v.geom, sum(b.population) as pop
      from voronoi_bath v left join buildings b on st_intersects(v.geom, b.geom)
      group by v.fid, v.geom) as t 
where v.fid = t.fid;

--latrines: 
create table voronoi_latr as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'sanitation' AND type != 'bathing') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where gri.class = 'sanitation' AND gri.type != 'bathing'
);

alter table voronoi_latr add column population float8; 
update voronoi_latr v
set population = t.pop
from (select v.fid, v.geom, sum(b.population) as pop
      from voronoi_latr v left join buildings b on st_intersects(v.geom, b.geom)
      group by v.fid, v.geom) as t 
where v.fid = t.fid;

--tubewells (incl. risk score):
create table voronoi_tube as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.contamination_risk_score, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'tubewell') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where gri.class = 'tubewell'
);

alter table voronoi_tube add column population float8; 
update voronoi_tube v
set population = t.pop
from (select v.fid, v.geom, sum(b.population) as pop
      from voronoi_tube v left join buildings b on st_intersects(v.geom, b.geom)
      group by v.fid, v.geom) as t 
where v.fid = t.fid;

--health services: 
create table voronoi_heal as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'health_service') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where gri.class = 'health_service'
);

alter table voronoi_heal add column population float8; 
update voronoi_heal v
set population = t.pop
from (select v.fid, v.geom, sum(b.population) as pop
      from voronoi_heal v left join buildings b on st_intersects(v.geom, b.geom)
      group by v.fid, v.geom) as t 
where v.fid = t.fid;

--nutrition services: 
create table voronoi_nutr as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom --somehow one of the voronois is missing in the middle
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'nutrition_service') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON st_intersects(dmp.geom, o.geom)
  where gri.class = 'nutrition_service'
); 

alter table voronoi_nutr add column population float8; 
update voronoi_nutr v
set population = t.pop
from (select v.fid, v.geom, sum(b.population) as pop
      from voronoi_nutr v left join buildings b on st_intersects(v.geom, b.geom)
      group by v.fid, v.geom) as t 
where v.fid = t.fid;

--women protection services: 
create table voronoi_wpro as ( 
  with outline as (    
    select st_union(geom) as geom from geo_admin
  )
  SELECT gri.fid, gri.geom as point, ST_Intersection(dmp.geom, o.geom) AS geom
  FROM (SELECT ST_Collect(geom) AS geom
        FROM   geo_reach_infra
        where class = 'women_protection') t,   
    LATERAL ST_Dump(ST_VoronoiPolygons(t.geom)) AS dmp
    join geo_reach_infra gri on st_intersects(dmp.geom, gri.geom)
    JOIN outline AS o ON ST_Intersects(dmp.geom, o.geom)
  where gri.class = 'women_protection'
);

alter table voronoi_wpro add column population float8; 
update voronoi_wpro v
set population = t.pop
from (select v.fid, v.geom, sum(b.population) as pop
      from voronoi_wpro v left join buildings b on st_intersects(v.geom, b.geom)
      group by v.fid, v.geom) as t 
where v.fid = t.fid;