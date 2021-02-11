--to test whether something got inserted: 
select * 
from geo_reach_infra 
where class like '%new_%';

--original count: 62,761
select count(*)
from geo_reach_infra gri;

--to delete the insertions:
delete from geo_reach_infra 
where class like '%new_%';