------------- backend queries for entering new amenities into the dataset: 
--------1. insert into db: 
insert into geo_reach_infra (fid, class, type, contamination_risk_score, geom)
values row (select max(fid)+1, {1}, {2}, {3}, st_setsrid(st_point({4}, {5}), 4326)
            from geo_reach_infra)

--fid automatisch erstellen als max(fid)+1
--1: class muss angegeben werden
--2: type bei 
    --health_service ('Community Clinic', 'DTC', 'Diagnostic point', 'Health Post Fixed', 'Health Post Mobil', 'Hospital', 'Other specialised services', 'PHC', 'SRH clinic') 
    --sanitation ('latrine', 'bathing')
--3: contamination_risk_score bei 
    --tubewells ('very high', 'high', 'intermediate', 'low')
--4: longitude
--5: latitude

--------2. update db tables accordingly: 

------if class = 'sanitation' and class != 'latrine' (i.e. bathing): dann führe folgende queries aus: 
--update buildings: takes ~30sec.
 UPDATE buildings AS b1
  SET dist_bath = v.distance
 from (SELECT b1.id, ST_Distance(b1.geom, v.point) as distance
       FROM   voronoi_bath v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;

--update feature tables: takes ~30sec.
update tbl_sblock_features f
set dist_bath = b.dist,
    n_bath = n.count,
    pop_perbath = v.pop
from (select sblock_id, avg(dist_bath) as dist
      from buildings 
      group by 1) as b,
     (select sblock_id, count(gri.fid) as count
      FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
      where gri.class = 'sanitation' and gri.class != 'latrine'
      group by 1) as n,
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_bath_pop v on st_intersects(t.geom, v.point)
      group by 1) as v
where f.sblock_id = b.sblock_id
  and f.sblock_id = n.sblock_id
  and f.sblock_id = v.sblock_id
    
update tbl_block_features f
set dist_bath = t.dist, n_bath = t.count, pop_perbath = t.pop
from (select block_id, avg(dist_bath) as dist, sum(n_bath) as count, avg(pop_perbath) as pop         
      from tbl_sblock_features t 
      group by 1) as t
where f.block_id = t.block_id

update tbl_camp_features f
set dist_bath = t.dist, n_bath = t.count, pop_perbath = t.pop
from (select camp_id, avg(dist_bath) as dist, sum(n_bath) as count, avg(pop_perbath) as pop         
      from tbl_block_features t 
      group by 1) as t
where f.camp_id = t.camp_id


------if class = 'sanitation' and class != 'bathing' (i.e. latrine): dann führe folgende queries aus: 
--update buildings: takes ~40sec.
 UPDATE buildings AS b1
  SET dist_latr = v.distance
 from (SELECT b1.id, ST_Distance(b1.geom, v.point) as distance
       FROM   voronoi_latr v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;

--update feature tables: takes ~56sec.
update tbl_sblock_features f
set dist_latr = b.dist,
    n_latr = n.count,
    pop_perlatr = v.pop
from (select sblock_id, avg(dist_latr) as dist
      from buildings 
      group by 1) as b,
     (select sblock_id, count(gri.fid) as count
      FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
      where gri.class = 'sanitation' and gri.class != 'bathing'
      group by 1) as n,
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_latr_pop v on st_intersects(t.geom, v.point)
      group by 1) as v
where f.sblock_id = b.sblock_id
  and f.sblock_id = n.sblock_id
  and f.sblock_id = v.sblock_id
    
update tbl_block_features f
set dist_latr = t.dist, n_latr = t.count, pop_perlatr = t.pop
from (select block_id, avg(dist_latr) as dist, sum(n_latr) as count, avg(pop_perlatr) as pop         
      from tbl_sblock_features t 
      group by 1) as t
where f.block_id = t.block_id

update tbl_camp_features f
set dist_latr = t.dist, n_latr = t.count, pop_perlatr = t.pop
from (select camp_id, avg(dist_latr) as dist, sum(n_latr) as count, avg(pop_perlatr) as pop         
      from tbl_block_features t 
      group by 1) as t
where f.camp_id = t.camp_id


------if class = 'tubewell': dann führe folgende queries aus: 
--update buildings: takes ~30sec.
 UPDATE buildings AS b1
  SET dist_tube = v.distance
 from (SELECT b1.id, ST_Distance(b1.geom, v.point) as distance
       FROM   voronoi_tube v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;

--update feature tables: takes ~40sec.
update tbl_sblock_features f
set dist_tube = b.dist,
    n_tube = n.tube,
    n_tube_risk = n.tube_risk,
    perc_tube_risk = (100 / nullif(n.tube, 0)) * (n.tube_risk),
    pop_pertube = v.pop,
    pop_endangered = v.pop_endangered
from (select sblock_id, avg(dist_tube) as dist
      from buildings 
      group by 1) as b,
     (select sblock_id,
      Count(*) FILTER (WHERE gri.class = 'tubewell') AS tube,
      Count(*) FILTER (WHERE gri.class = 'tubewell' and gri.contamination_risk_score in ('high', 'very high', 'intermediate')) AS tube_risk
      FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
      where gri.class = 'tubewell'
      group by 1) as n,
      (select t.sblock_id, avg(v.pop) as pop,
      sum(v.pop) filter (where v.contamination_risk_score in ('high', 'very high', 'intermediate')) as pop_endangered
      from tbl_sblock_features t 
      left join voronoi_tube_pop v on st_intersects(t.geom, v.point)
      group by 1) as v
where f.sblock_id = b.sblock_id
  and f.sblock_id = n.sblock_id
  and f.sblock_id = v.sblock_id
  
  
update tbl_block_features f
set dist_tube = t.dist, n_tube = t.tube, n_tube_risk = t.tube_risk, 
    perc_tube_risk = (100 / nullif(t.tube, 0)) * (t.tube_risk), pop_pertube = t.pop, pop_endangered = t.pop_endangered 
from (select block_id, avg(dist_tube) as dist, sum(n_tube) as tube, 
      sum(n_tube_risk) as tube_risk, avg(pop_pertube) as pop, sum(pop_endangered) as pop_endangered       
      from tbl_sblock_features t 
      group by 1) as t
where f.block_id = t.block_id

update tbl_camp_features f
set dist_tube = t.dist, n_tube = t.tube, n_tube_risk = t.tube_risk, 
    perc_tube_risk = (100 / nullif(t.tube, 0)) * (t.tube_risk), pop_pertube = t.pop, pop_endangered = t.pop_endangered 
from (select camp_id, avg(dist_tube) as dist, sum(n_tube) as tube, 
      sum(n_tube_risk) as tube_risk, avg(pop_pertube) as pop, sum(pop_endangered) as pop_endangered       
      from tbl_block_features t 
      group by 1) as t
where f.camp_id = t.camp_id



------if class = 'health_service': dann führe folgende queries aus: 
--update buildings: takes ~7sec.
 UPDATE buildings AS b1
  SET dist_heal = v.distance
 from (SELECT b1.id, ST_Distance(b1.geom, v.point) as distance
       FROM   voronoi_heal v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;

--update feature tables:
update tbl_sblock_features f
set dist_heal = b.dist,
    n_heal = n.count,
    pop_perheal = v.pop
from (select sblock_id, avg(dist_heal) as dist
      from buildings 
      group by 1) as b,
     (select sblock_id, count(gri.fid) as count
      FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
      where gri.class = 'health_service'
      group by 1) as n,
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_heal_pop v on st_intersects(t.geom, v.point)
      group by 1) as v
where f.sblock_id = b.sblock_id
  and f.sblock_id = n.sblock_id
  and f.sblock_id = v.sblock_id
    
update tbl_block_features f
set dist_heal = t.dist, n_heal = t.count, pop_perheal = t.pop
from (select block_id, avg(dist_heal) as dist, sum(n_heal) as count, avg(pop_perheal) as pop         
      from tbl_sblock_features t 
      group by 1) as t
where f.block_id = t.block_id

update tbl_camp_features f
set dist_heal = t.dist, n_heal = t.count, pop_perheal = t.pop
from (select camp_id, avg(dist_heal) as dist, sum(n_heal) as count, avg(pop_perheal) as pop         
      from tbl_block_features t 
      group by 1) as t
where f.camp_id = t.camp_id


------if class = 'nutrition_service': dann führe folgende queries aus: 
--update buildings: takes ~7sec.
 UPDATE buildings AS b1
  SET dist_nutr = v.distance
 from (SELECT b1.id, ST_Distance(b1.geom, v.point) as distance
       FROM   voronoi_nutr v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;

--update feature tables:
update tbl_sblock_features f
set dist_nutr = b.dist,
    n_nutr = n.count,
    pop_pernutr = v.pop
from (select sblock_id, avg(dist_nutr) as dist
      from buildings 
      group by 1) as b,
     (select sblock_id, count(gri.fid) as count
      FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
      where gri.class = 'nutrition_service'
      group by 1) as n,
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_nutr_pop v on st_intersects(t.geom, v.point)
      group by 1) as v
where f.sblock_id = b.sblock_id
  and f.sblock_id = n.sblock_id
  and f.sblock_id = v.sblock_id
    
update tbl_block_features f
set dist_nutr = t.dist, n_nutr = t.count, pop_pernutr = t.pop
from (select block_id, avg(dist_nutr) as dist, sum(n_nutr) as count, avg(pop_pernutr) as pop         
      from tbl_sblock_features t 
      group by 1) as t
where f.block_id = t.block_id

update tbl_camp_features f
set dist_nutr = t.dist, n_nutr = t.count, pop_pernutr = t.pop
from (select camp_id, avg(dist_nutr) as dist, sum(n_nutr) as count, avg(pop_pernutr) as pop         
      from tbl_block_features t 
      group by 1) as t
where f.camp_id = t.camp_id

            
------if class = 'women_protection':dann führe folgende queries aus: 
--update buildings: takes ~10sec.
 UPDATE buildings AS b1
  SET dist_wpro = v.distance
 from (SELECT b1.id, ST_Distance(b1.geom, v.point) as distance
       FROM   voronoi_wpro v join buildings b1 on st_intersects(b1.geom, v.geom)) as v
 where b1.id = v.id;

--update feature tables:
update tbl_sblock_features f
set dist_wpro = b.dist,
    n_wpro = n.count,
    wmn_perWpro = v.pop
from --subquery for the distance calculation: 
     (select sblock_id, avg(dist_wpro) as dist
      from buildings 
      group by 1) as b,
     --subquery for the count calculation:
     (select sblock_id, count(gri.fid) as count
      FROM geo_reach_infra AS gri JOIN geo_admin AS ga ON ST_Within(gri.geom, ga.geom)
      where gri.class = 'women_protection'
      group by 1) as n,
     --subquery for the pop per amenity calculation: 
     (select t.sblock_id, avg(v.pop) as pop         
      from tbl_sblock_features t 
      left join voronoi_wpro_pop v on st_intersects(t.geom, v.point)
      group by 1) as v
where f.sblock_id = b.sblock_id
  and f.sblock_id = n.sblock_id
  and f.sblock_id = v.sblock_id
  
update tbl_block_features f
set dist_wpro = t.dist, n_wpro = t.count, wmn_perWpro = t.pop
from (select block_id, avg(dist_wpro) as dist, sum(n_wpro) as count, avg(population) as pop         
      from tbl_sblock_features t 
      group by 1) as t
where f.block_id = t.block_id

update tbl_camp_features f
set dist_wpro = t.dist, n_wpro = t.count, wmn_perWpro = t.pop
from (select camp_id, avg(dist_wpro) as dist, sum(n_wpro) as count, avg(population) as pop         
      from tbl_block_features t 
      group by 1) as t
where f.camp_id = t.camp_id

