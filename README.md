# gis-viz-project

### To run on your machine:

1. docker-compose up

2. open in http://localhost:4200/


### If d3 is not installed:
1. Enter your frontend container

docker exec -it bgd-aid-distribution_frontend_1 /bin/bash


2. Run the following two commands:

npm install d3 --save

npm install @types/d3 --save-dev


### To upload the data


osm2pgsql --database gis_db --host localhost --port 25432 --username gis_user --password --create --slim --drop --latlong --hstore-all ../bgd_camps.osm.pbf

pwd: gis_pass

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a00000004.gdbtable

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a00000009.gdbtable

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a0000000a.gdbtable

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a0000000b.gdbtable

ogr2ogr -f PostgreSQL PG:"host=localhost port=25432 user=gis_user dbname=gis_db password=gis_pass" ../health.csv -oo AUTODETECT_TYPE=YES

ogr2ogr -f PostgreSQL PG:"host=localhost port=25432 user=gis_user dbname=gis_db password=gis_pass" ../tubewell.csv -oo AUTODETECT_TYPE=YES

ogr2ogr -f PostgreSQL PG:"host=localhost port=25432 user=gis_user dbname=gis_db password=gis_pass" ../dta_sblock.csv -oo AUTODETECT_TYPE=YES

ogr2ogr -f PostgreSQL PG:"host=localhost port=25432 user=gis_user dbname=gis_db password=gis_pass" ../dta_population_block.csv -oo AUTODETECT_TYPE=YES

ogr2ogr -f PostgreSQL PG:"host=localhost port=25432 user=gis_user dbname=gis_db password=gis_pass" ../dta_camp.csv -oo AUTODETECT_TYPE=YES

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../latrines.csv


#### Upload created datasets

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../camp_info.csv

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../block_info.csv

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../subblock_info.csv

### Renaming datasets, columns and some preprocessing

ALTER TABLE public.t200908_rrc_outline_block_al2 RENAME TO block;

ALTER TABLE public.t200908_rrc_outline_subblock_al3 RENAME TO subblock;

ALTER TABLE public.t200908_rrc_outline_camp_al1 RENAME TO camp;

alter table health ALTER COLUMN latitude TYPE float USING replace(latitude, ',','.')::float

alter table health ALTER COLUMN longitude TYPE float USING replace(longitude, ',','.')::float

alter table tubewell ALTER COLUMN "gps latitude" TYPE float USING replace("gps latitude", ',','.')::float

alter table tubewell ALTER COLUMN "gps longitude" TYPE float USING replace("gps longitude", ',','.')::float

alter table subblock ALTER COLUMN subblock_1 TYPE varchar USING replace(subblock_1, ' ','')::varchar;

alter table block ALTER COLUMN subblock_1 TYPE varchar USING replace(subblock_1, ' ','')::varchar;

alter table camp ALTER COLUMN subblock_1 TYPE varchar USING replace(subblock_1, ' ','')::varchar;

alter table dta_sblock
add column block_id varchar;
add column camp_id varchar;
update dta_sblock
set block_id = substring(sblock_id,1,12);
set camp_id = substring(sblock_id,1,7);


alter table dta_sblock ALTER COLUMN "pop_n_individuals" TYPE INT USING nullif(trim(nullif(pop_n_individuals,'NA')),'')::integer;

alter table dta_sblock ALTER COLUMN "pop_n_family" TYPE INT USING nullif(trim(nullif(pop_n_family,'NA')),'')::integer;
