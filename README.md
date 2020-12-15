# gis-viz-project

### To run on your machine:

1. docker-compose up

2. osm2pgsql --database gis_db --host localhost --port 25432 --username gis_user --password --create --slim --drop --latlong --hstore-all bangladesh-latest.osm.pbf

3. gis_pass

4. open in http://localhost:4200/
