-----script to make a buildings table for Cox's Bazar

-- 1. OSM Buildings:

CREATE TABLE osm_cxb_buildings AS (
  SELECT distinct osm_id AS id,
    building AS building_type,
    g.sblock_id AS sblock_id,
    g.block_id as block_id,
    g.camp_id as camp_id,
    ST_Area(way) AS area_sqm,
    ST_Centroid(way) AS geom,
    way as area
  FROM osm_polygon AS o
  JOIN geo_admin AS g ON st_within(o.way, g.geom) --birke: changed st_coveredBy to st_within -> seems to avoid the problem of houses being assigned to several sblock_ids
  WHERE building IS NOT NULL
);

CREATE INDEX osm_cxb_buildings_idx
ON osm_cxb_buildings USING GIST(geom);

alter table osm_cxb_buildings 
add primary key (id);


--1.2 Bevï¿½lkerung auf Gebï¿½ude verteilen (von pop info, die wir auf admin level haben)
select building_type --check what kinds of buildings there are
from osm_cxb_buildings 
group by building_type;

  --entsprechende pop columns zur Tabelle hinzufï¿½gen:
alter table osm_cxb_buildings 
add pop_total_per_build float8, 
add pop_f_bel_1_per_build float8,
add pop_f_01_04_per_build float8, 
add pop_f_05_11_per_build float8,
add pop_f_12_17_per_build float8,
add pop_f_18_59_per_build float8,
add pop_f_60_pl_per_build float8,
add pop_m_bel_1_per_build float8,
add pop_m_01_04_per_build float8,
add pop_m_05_11_per_build float8,
add pop_m_12_17_per_build float8, 
add pop_m_18_59_per_build float8,
add pop_m_60_pl_per_build float8
;

  --residential buildings pro block zï¿½hlen:
with residential_buildings_per_block as 
(
    select block_id, count(id) as build_count
    from osm_cxb_buildings ob
    where ob.building_type = 'apartments' or ob.building_type = 'hamlet' or ob.building_type = 'residential' 
       or ob.building_type = 'house' or ob.building_type = 'roof' or ob.building_type = 'yes' --only select buildings that are possibly residential
    group by block_id
), --population/sblock teilen durch building-count/sblock:
pop_per_building_per_block as 
(
    select ds.block_id,
       (ds.pop_total  / rb.build_count) as pop_total_per_build,
       (ds.f_below_1  / rb.build_count) as pop_f_bel_1_per_build,
       (ds.f_1_to_4   / rb.build_count) as pop_f_01_04_per_build, 
       (ds.f_5_to_11  / rb.build_count) as pop_f_05_11_per_build,
       (ds.f_12_to_17 / rb.build_count) as pop_f_12_17_per_build, 
       (ds.f_18_to_59 / rb.build_count) as pop_f_18_59_per_build,
       (ds.f_60_plus  / rb.build_count) as pop_f_60_pl_per_build,
       (ds.m_below_1  / rb.build_count) as pop_m_bel_1_per_build,
       (ds.m_1_to_5   / rb.build_count) as pop_m_01_04_per_build,
       (ds.m_5_to_11  / rb.build_count) as pop_m_05_11_per_build,
       (ds.m_12_to_17 / rb.build_count) as pop_m_12_17_per_build, 
       (ds.m_18_to_59 / rb.build_count) as pop_m_18_59_per_build,
       (ds.m_60_plus  / rb.build_count) as pop_m_60_pl_per_build
    from dta_block ds natural join residential_buildings_per_block rb --joins on block_id
) 
update osm_cxb_buildings 
set pop_total_per_build   = pop.pop_total_per_build,
    pop_f_bel_1_per_build = pop.pop_f_bel_1_per_build,
    pop_f_01_04_per_build = pop.pop_f_01_04_per_build,
    pop_f_05_11_per_build = pop.pop_f_05_11_per_build,
    pop_f_12_17_per_build = pop.pop_f_12_17_per_build,
    pop_f_18_59_per_build = pop.pop_f_18_59_per_build,
    pop_f_60_pl_per_build = pop.pop_f_60_pl_per_build,
    pop_m_bel_1_per_build = pop.pop_m_bel_1_per_build,
    pop_m_01_04_per_build = pop.pop_m_01_04_per_build,
    pop_m_05_11_per_build = pop.pop_m_05_11_per_build,
    pop_m_12_17_per_build = pop.pop_m_12_17_per_build,
    pop_m_18_59_per_build = pop.pop_m_18_59_per_build,
    pop_m_60_pl_per_build = pop.pop_m_60_pl_per_build
from pop_per_building_per_block as pop
where osm_cxb_buildings.block_id = pop.block_id
;

--checks: 
select pop_total_per_build, count(id)
from osm_cxb_buildings ocb 
group by pop_total_per_build 
order by pop_total_per_build desc

select block_id, count(id)
from osm_cxb_buildings ocb 
where pop_total_per_build is null
group by block_id 
--für manche blocks gibt es keine population daten - erstmal einfach NULL lassen

--2. Add information whether centroids of a building are covered by flood polygons.

-- Create additional column, set to 0 by default.
ALTER TABLE osm_cxb_buildings
ADD COLUMN count_flooded float8 DEFAULT 0;

-- Calculate overlaps with building centroids and update the osm_cxb_buildings
-- table accordingly.
WITH
  building_flooded AS (
    SELECT id AS building_id, sblock_id, flood AS flood_id
    FROM osm_cxb_buildings AS b
    INNER JOIN geo_floods AS f ON st_coveredby(b.geom, f.geom)), --geom is the centroid of the buildings
  building_count AS (
    SELECT building_id, Count(*) AS count 
    FROM building_flooded
    GROUP BY 1
  )
UPDATE osm_cxb_buildings
SET count_flooded = b.count
FROM building_count AS b
WHERE osm_cxb_buildings.id = b.building_id;

--check:
select count_flooded, count(id)
from osm_cxb_buildings ocb 
group by count_flooded ;

/*--4. distance calculations (funktionieren noch nicht bzw. brauchen sehr lange - bisher noch nicht durchgelaufen)
--nearest neighbor von jedem Haus (centroid) zum nï¿½chsten Brunnen (z.B.)
alter table osm_cxb_buildings 
add dist_wprot float8, 
add dist_tubew float8,
add dist_latri float8, 
add dist_sanit float8,
add dist_healt float8,
add dist_nutri float8;

--distance to women protection areas: 
with wprot as (
    select ocb.id, 
    st_distance(ocb.geom, nearest.geom) as dist_wprot
    from osm_cxb_buildings ocb
    cross join lateral (select ogc_fid, geom
                        from geo_reach_infra infra
                        where infra."class" = 'women_protection'
                        order by ocb.geom <-> geom
                        limit 1) as nearest
)
update osm_cxb_buildings 
set dist_wprot = wprot.dist_wprot
from wprot
where osm_cxb_buildings.id = wprot.id;

--distance to tubewells:
with tubew as (
    select ocb.osm_id, 
    st_distance(ocb.centroid, nearest.geom) as dist_tubew
    from osm_cxb_buildings ocb
    cross join lateral (select ogc_fid, geom
                        from geo_reach_infra infra
                        where infra."class" = 'tubewell'
                        order by ocb.centroid <-> geom
                        limit 1) as nearest
)
update osm_cxb_buildings 
set dist_tubew = tubew.dist_tubew
from tubew
where osm_cxb_buildings.osm_id = tubew.osm_id;

--distance to latrines (sort of toilets)
with latri as (
    select ocb.osm_id, 
    st_distance(ocb.centroid, nearest.geom) as dist_latri
    from osm_cxb_buildings ocb
    cross join lateral (select ogc_fid, geom
                        from geo_reach_infra infra
                        where infra."type" = 'latrine'
                        order by ocb.centroid <-> geom
                        limit 1) as nearest
)
update osm_cxb_buildings 
set dist_latri = latri.dist_latri
from latri
where osm_cxb_buildings.osm_id = latri.osm_id;

--distance to sanitation / bathing
with sanit as (
    select ocb.osm_id, 
    st_distance(ocb.centroid, nearest.geom) as dist_sanit
    from osm_cxb_buildings ocb
    cross join lateral (select ogc_fid, geom
                        from geo_reach_infra infra
                        where infra."class" = 'sanitation' or infra."type" = 'bathing'
                        order by ocb.centroid <-> geom
                        limit 1) as nearest
)
update osm_cxb_buildings 
set dist_sanit = sanit.dist_sanit
from sanit
where osm_cxb_buildings.osm_id = sanit.osm_id;

--distance to some form of health centre (funktioniert noch nicht)
with healt as (
    select ocb.osm_id, 
    st_distance(ocb.centroid, nearest.geom) as dist_healt
    from osm_cxb_buildings ocb
    cross join lateral (select ogc_fid, geom
                        from geo_reach_infra infra
                        where infra."type" = 'Community Clinic' or infra."type" = 'Diagnostic point' or infra."type" = 'Health Post Fixed'
                        or infra."type" = 'Health Post Mobile' or infra."type" = 'Hospital' or infra."type" = 'PHC' or infra."type" = 'SRH clinic'
                        order by ocb.centroid <-> geom
                        limit 1) as nearest
)
update osm_cxb_buildings 
set dist_healt = healt.dist_healt
from healt
where osm_cxb_buildings.osm_id = healt.osm_id;

--distance to nutrition service
with nutri as (
    select ocb.osm_id, 
    st_distance(ocb.centroid, nearest.geom) as dist_nutri
    from osm_cxb_buildings ocb
    cross join lateral (select ogc_fid, geom
                        from geo_reach_infra infra
                        where infra."class" = 'nutrition_service'
                        order by ocb.centroid <-> geom
                        limit 1) as nearest
)
update osm_cxb_buildings 
set dist_nutri = nutri.dist_nutri
from nutri
where osm_cxb_buildings.osm_id = nutri.osm_id;

select sblock_id, pop_n_individuals 
from dta_sblock ds 
where pop_n_individuals is null*/