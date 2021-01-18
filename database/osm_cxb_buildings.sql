-----script to make a buildings table for Cox's Bazar

-- 1. OSM Buildings:

CREATE TABLE osm_cxb_buildings AS (
  SELECT osm_id AS id,
    building AS building_type,
    g.sblock_id AS sblock_id,
    ST_Area(way) AS area_sqm,
    ST_Centroid(way) AS geom
  FROM osm_polygon AS o
  JOIN geo_admin AS g ON ST_Intersects(o.way, g.geom)
  WHERE building IS NOT NULL
);

CREATE INDEX osm_cxb_buildings_idx
ON osm_cxb_buildings USING GIST(geom);



-- Add information whether centroids of a building are covered by flood
-- polygons.

-- Create additional column, set to 0 by default.
ALTER TABLE osm_cxb_buildings
ADD COLUMN count_flooded int DEFAULT 0;

-- Calculate overlaps with building centroids and update the osm_cxb_buildings
-- table accordingly.
WITH
  building_flooded AS (
    SELECT id AS building_id, sblock_id, flood AS flood_id
    FROM osm_cxb_buildings AS b
    INNER JOIN geo_floods AS f ON ST_CoveredBy(b.geom, f.geom)),
  building_count AS (
    SELECT building_id, Count(*) AS count 
    FROM building_flooded
    GROUP BY 1
  )
UPDATE osm_cxb_buildings
SET count_flooded = COALESCE(b.count, 0)
FROM building_count AS b
WHERE osm_cxb_buildings.id = b.building_id;




--1.4 Bev�lkerung auf Geb�ude verteilen (von pop info, die wir auf admin level haben)
select building --check what kinds of buildings there are
from osm_cxb_buildings 
group by building;

  --entsprechende pop columns zur Tabelle hinzuf�gen:
alter table osm_cxb_buildings 
add pop_indiv_per_build float8, 
add pop_fam_per_build  float8, 
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

  --residential buildings pro sblock z�hlen:
with residential_buildings_per_sblock as 
(
    select sblock_id, count(osm_id) as build_count
    from osm_cxb_buildings ob
    where ob.building = 'apartments' or ob.building = 'hamlet' or ob.building = 'residential' 
       or ob.building = 'house' or ob.building = 'roof' or ob.building = 'yes' --only select buildings that are possibly residential
    group by sblock_id
), --population/sblock teilen durch building-count/sblock:
pop_per_building_per_sblock as 
(
    select ds.sblock_id,
       (ds.pop_n_individuals/rb.build_count)as pop_indiv_per_build,
       (ds.pop_n_family   / rb.build_count) as pop_fam_per_build , 
       (ds.pop_f_below_1  / rb.build_count) as pop_f_bel_1_per_build,
       (ds.pop_f_1_to_4   / rb.build_count) as pop_f_01_04_per_build, 
       (ds.pop_f_5_to_11  / rb.build_count) as pop_f_05_11_per_build,
       (ds.pop_f_12_to_17 / rb.build_count) as pop_f_12_17_per_build, 
       (ds.pop_f_18_to_59 / rb.build_count) as pop_f_18_59_per_build,
       (ds.pop_f_60_plus  / rb.build_count) as pop_f_60_pl_per_build,
       (ds.pop_m_below_1  / rb.build_count) as pop_m_bel_1_per_build,
       (ds.pop_m_1_to_5   / rb.build_count) as pop_m_01_04_per_build,
       (ds.pop_m_5_to_11  / rb.build_count) as pop_m_05_11_per_build,
       (ds.pop_m_12_to_17 / rb.build_count) as pop_m_12_17_per_build, 
       (ds.pop_m_18_to_59 / rb.build_count) as pop_m_18_59_per_build,
       (ds.pop_m_60_plus  / rb.build_count) as pop_m_60_pl_per_build
    from dta_sblock ds natural join residential_buildings_per_sblock rb --joins on sblock_id
) 
update osm_cxb_buildings 
set pop_indiv_per_build   = pop.pop_indiv_per_build,
    pop_fam_per_build     = pop.pop_fam_per_build ,
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
from pop_per_building_per_sblock as pop
where osm_cxb_buildings.sblock_id = pop.sblock_id
; --funktioniert noch nicht f�r alle: f�r sblock_ids mit _XX am Ende gibt es keine passenden population Daten


--4. distance calculations
--nearest neighbor von jedem Haus (centroid) zum n�chsten Brunnen (z.B.)
alter table osm_cxb_buildings 
add dist_wprot float8, 
add dist_tubew float8,
add dist_latri float8, 
add dist_sanit float8,
add dist_healt float8,
add dist_nutri float8;

--distance to women protection areas: 
with wprot as (
    select ocb.osm_id, 
    st_distance(ocb.centroid, nearest.geom) as dist_wprot
    from osm_cxb_buildings ocb
    cross join lateral (select ogc_fid, geom
                        from geo_reach_infra infra
                        where infra."class" = 'women_protection'
                        order by ocb.centroid <-> geom
                        limit 1) as nearest
)
update osm_cxb_buildings 
set dist_wprot = wprot.dist_wprot
from wprot
where osm_cxb_buildings.osm_id = wprot.osm_id;

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
/*with healt as (
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
where osm_cxb_buildings.osm_id = healt.osm_id;*/

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
