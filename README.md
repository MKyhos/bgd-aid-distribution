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


osm2pgsql --database gis_db --host localhost --port 25432 --username gis_user --password --create --slim --drop --latlong --hstore-all ../bangladesh-latest.osm.pbf

pwd: gis_pass

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a00000004.gdbtable

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a00000009.gdbtable

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a0000000a.gdbtable

ogr2ogr -f "PostgreSQL" PG:"host=localhost port=25432 dbname=gis_db user=gis_user password=gis_pass" ../CampShapes/a0000000b.gdbtable

### Renaming data

ALTER TABLE public.t200908_rrc_outline_block_al2 RENAME TO block;

ALTER TABLE public.t200908_rrc_outline_subblock_al3 RENAME TO subblock;

ALTER TABLE public.t200908_rrc_outline_camp_al1 RENAME TO camp;
