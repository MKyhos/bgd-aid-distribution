--script to add data to dta_sblock table

--1. population density as population per building
alter table dta_sblock 
add pop_indiv_per_build float8, 
add pop_fam_per_build float8, 
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
add pop_m_60_pl_per_build float8;

with sblock_measurements as (
    select sblock_id, 
           avg(pop_indiv_per_build) as pop_indiv_per_build,
           avg(pop_fam_per_build) as pop_fam_per_build, 
           avg(pop_f_bel_1_per_build) as pop_f_bel_1_per_build ,
           avg(pop_f_01_04_per_build) as pop_f_01_04_per_build ,
           avg(pop_f_05_11_per_build) as pop_f_05_11_per_build ,
           avg(pop_f_12_17_per_build) as pop_f_12_17_per_build ,
           avg(pop_f_18_59_per_build) as pop_f_18_59_per_build ,
           avg(pop_f_60_pl_per_build) as pop_f_60_pl_per_build ,
           avg(pop_m_bel_1_per_build) as pop_m_bel_1_per_build ,
           avg(pop_m_01_04_per_build) as pop_m_01_04_per_build ,
           avg(pop_m_05_11_per_build) as pop_m_05_11_per_build ,
           avg(pop_m_12_17_per_build) as pop_m_12_17_per_build ,
           avg(pop_m_18_59_per_build) as pop_m_18_59_per_build ,
           avg(pop_m_60_pl_per_build) as pop_m_60_pl_per_build
    from osm_cxb_buildings
    group by sblock_id
)
update dta_sblock
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
from sblock_measurements as pop
where dta_sblock.sblock_id = pop.sblock_id;

--2. population density as population / area (km²?)
alter table dta_sblock 
add pop_indiv_per_area float8, 
add pop_fam_per_area float8, 
add pop_f_bel_1_per_area float8,
add pop_f_01_04_per_area float8,
add pop_f_05_11_per_area float8,
add pop_f_12_17_per_area float8,
add pop_f_18_59_per_area float8,
add pop_f_60_pl_per_area float8,
add pop_m_bel_1_per_area float8,
add pop_m_01_04_per_area float8,
add pop_m_05_11_per_area float8,
add pop_m_12_17_per_area float8,
add pop_m_18_59_per_area float8,
add pop_m_60_pl_per_area float8;

with pop_density as (
    select ds.sblock_id, 
        (ds.pop_n_individuals / st_area(adm.geom) * 1000) as pop_indiv_per_area,
        (ds.pop_n_family      / st_area(adm.geom) * 1000) as pop_fam_per_area,
        (ds.pop_f_below_1     / st_area(adm.geom) * 1000) as pop_f_bel_1_per_area,
        (ds.pop_f_1_to_4      / st_area(adm.geom) * 1000) as pop_f_01_04_per_area,
        (ds.pop_f_5_to_11     / st_area(adm.geom) * 1000) as pop_f_05_11_per_area,
        (ds.pop_f_12_to_17    / st_area(adm.geom) * 1000) as pop_f_12_17_per_area,
        (ds.pop_f_18_to_59    / st_area(adm.geom) * 1000) as pop_f_18_59_per_area,
        (ds.pop_f_60_plus     / st_area(adm.geom) * 1000) as pop_f_60_pl_per_area,
        (ds.pop_m_below_1     / st_area(adm.geom) * 1000) as pop_m_bel_1_per_area,
        (ds.pop_m_1_to_5      / st_area(adm.geom) * 1000) as pop_m_01_04_per_area,
        (ds.pop_m_5_to_11     / st_area(adm.geom) * 1000) as pop_m_05_11_per_area,
        (ds.pop_m_12_to_17    / st_area(adm.geom) * 1000) as pop_m_12_17_per_area,
        (ds.pop_m_18_to_59    / st_area(adm.geom) * 1000) as pop_m_18_59_per_area,
        (ds.pop_m_60_plus     / st_area(adm.geom) * 1000) as pop_m_60_pl_per_area
    from dta_sblock ds natural join geo_admin adm
)
update dta_sblock 
set pop_indiv_per_area = pop.pop_indiv_per_area,
    pop_fam_per_area       = pop.pop_fam_per_area ,
    pop_f_bel_1_per_area   = pop.pop_f_bel_1_per_area,
    pop_f_01_04_per_area    = pop.pop_f_01_04_per_area,
    pop_f_05_11_per_area   = pop.pop_f_05_11_per_area,
    pop_f_12_17_per_area  = pop.pop_f_12_17_per_area,
    pop_f_18_59_per_area  = pop.pop_f_18_59_per_area,
    pop_f_60_pl_per_area   = pop.pop_f_60_pl_per_area,
    pop_m_bel_1_per_area   = pop.pop_m_bel_1_per_area,
    pop_m_01_04_per_area    = pop.pop_m_01_04_per_area,
    pop_m_05_11_per_area   = pop.pop_m_05_11_per_area,
    pop_m_12_17_per_area  = pop.pop_m_12_17_per_area,
    pop_m_18_59_per_area  = pop.pop_m_18_59_per_area,
    pop_m_60_pl_per_area   = pop.pop_m_60_pl_per_area
from pop_density as pop
where dta_sblock.sblock_id = pop.sblock_id;

--3. population / amenity at sblock level

--3.1 add counts of different amenity types per sblock to sblock dta table
alter table dta_sblock 
add count_wprot int,
add count_tubew int, 
add count_latri int, 
add count_sanit int, 
add count_healt int, 
add count_nutri int; 

--women protection areas: 
with wprot as (
    SELECT adm.sblock_id, count(infra.ogc_fid) as count_wprot
      FROM geo_reach_infra infra INNER JOIN geo_admin adm ON ST_Intersects(infra.geom, adm.geom)
      where infra."class" = 'women_protection'
      group by adm.sblock_id    
)
update dta_sblock 
set count_wprot = wprot.count_wprot
from wprot 
where dta_sblock.sblock_id = wprot.sblock_id

--tubewells:
with tubew as (
    SELECT adm.sblock_id, count(infra.ogc_fid) as count_tubew
      FROM geo_reach_infra infra INNER JOIN geo_admin adm ON ST_Intersects(infra.geom, adm.geom)
      where infra."class" = 'tubewell'
      group by adm.sblock_id    
)
update dta_sblock 
set count_tubew = tubew.count_tubew
from tubew 
where dta_sblock.sblock_id = tubew.sblock_id

--latrines: 
with latri as (
    SELECT adm.sblock_id, count(infra.ogc_fid) as count_latri
      FROM geo_reach_infra infra INNER JOIN geo_admin adm ON ST_Intersects(infra.geom, adm.geom)
      where infra."type" = 'latrine'
      group by adm.sblock_id    
)
update dta_sblock 
set count_latri = latri.count_latri
from latri 
where dta_sblock.sblock_id = latri.sblock_id

--sanitary: 
with sanit as (
    SELECT adm.sblock_id, count(infra.ogc_fid) as count_sanit
      FROM geo_reach_infra infra INNER JOIN geo_admin adm ON ST_Intersects(infra.geom, adm.geom)
      where infra."class" = 'sanitation' or infra."type" = 'bathing'
      group by adm.sblock_id    
)
update dta_sblock 
set count_sanit = sanit.count_sanit
from sanit 
where dta_sblock.sblock_id = sanit.sblock_id

--health centre: (funktioniert noch nicht - 0 updated rows - weiß nicht warum)
/*with healt as (
    SELECT adm.sblock_id, count(infra.ogc_fid) as count_healt
      FROM geo_reach_infra infra INNER JOIN geo_admin adm ON ST_Intersects(infra.geom, adm.geom)
      where infra."type" = 'Community Clinic' or infra."type" = 'Diagnostic point' or infra."type" = 'Health Post Fixed'
       or infra."type" = 'Health Post Mobile' or infra."type" = 'Hospital' or infra."type" = 'PHC' or infra."type" = 'SRH clinic'
      group by adm.sblock_id    
)
update dta_sblock 
set count_healt = healt.count_healt
from healt 
where dta_sblock.sblock_id = healt.sblock_id*/

--nutrition service: 
with nutri as (
    SELECT adm.sblock_id, count(infra.ogc_fid) as count_nutri
      FROM geo_reach_infra infra INNER JOIN geo_admin adm ON ST_Intersects(infra.geom, adm.geom)
      where infra."class" = 'nutrition_service'
      group by adm.sblock_id    
)
update dta_sblock 
set count_nutri = nutri.count_nutri
from nutri 
where dta_sblock.sblock_id = nutri.sblock_id


--3.2 divide pop by amenity -> population per latrine etc.
alter table dta_sblock 
add wmn_per_wprot float8, 
add pop_per_tubew float8, 
add pop_per_latri float8, 
add pop_per_sanit float8, 
add pop_per_healt float8, 
add pop_per_nutri float8;

update dta_sblock 
set wmn_per_wprot = (pop_f_below_1 + pop_f_1_to_4 + pop_f_5_to_11 + pop_f_12_to_17 + pop_f_18_to_59 + pop_f_60_plus) / count_wprot,
    pop_per_tubew = pop_n_individuals / count_tubew,
    pop_per_latri = pop_n_individuals / count_latri,
    pop_per_sanit = pop_n_individuals / count_sanit, 
    pop_per_healt = pop_n_individuals / count_healt,
    pop_per_nutri = pop_n_individuals / count_nutri;
   
/*---4. distance calculations
alter table dta_sblock 
add dist_wprot float8, 
add dist_tubew float8,
add dist_latri float8, 
add dist_sanit float8,
add dist_healt float8,
add dist_nutri float8;

-- aggregate per sblock
with sblock_measurements as (
    select sblock_id, 
    avg(dist_wprot) as dist_wprot, avg(dist_tubew) as dist_tubew , avg(dist_latri) as dist_latri , 
    avg(dist_sanit) as dist_sanit, avg(dist_healt) as dist_healt , avg(dist_nutri) as dist_nutri 
    from osm_cxb_buildings ocb 
    group by sblock_id 
)
update dta_sblock 
set dist_wprot = d.dist_wprot,
    dist_tubew = d.dist_tubew,
    dist_latri = d.dist_latri,
    dist_sanit = d.dist_sanit,
    dist_healt = d.dist_healt,
    dist_nutri = d.dist_nutri
from sblock_measurements d
where dta_sblock.sblock_id = sblock_measurements;*/

---5. flood affectedness
alter table dta_sblock 
add flooded_perc float8 default 0;

--aggregate per sblock level:
with buildings_per_sblock as (
    select sblock_id, count(id) as build_count
    from osm_cxb_buildings ob
    group by sblock_id
), 
buildings_affected as (
    select sblock_id, count(id) as flooded
    from osm_cxb_buildings ob
    where count_flooded >= 1
    group by sblock_id
),
percent_flooded as (
    select bpsb.sblock_id, (100 / bpsb.build_count * ba.flooded) as flooded_perc 
    from buildings_per_sblock bpsb natural join buildings_affected ba
)
update dta_sblock 
set flooded_perc = percent_flooded.flooded_perc
from percent_flooded
where dta_sblock.sblock_id = percent_flooded.sblock_id;

select *
from dta_sblock ds 
where flooded_perc > 0