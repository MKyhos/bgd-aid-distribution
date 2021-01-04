#!/bin/bash

# A script for importing Data into the DB
# takes the following flags:
# -p port
# -h localhost
# -d database name
# -u username

# For local developtment, pass constants.
# #TODO change for prod.
PORT=45432
HOST=localhost
DB=gis_db
USER=gis_user
PASSWORD=gis_pass

# Pass over arguments:
# while getopts p:h:d:u:x: flag
# do
#   case "${flag}" in
#     p) PORT=${OPTARG};;
#     h) HOST=${OPTARG};;
#     d) DB=${OPTARG};;
#     u) USER=${OPTARG};;
#     x) PASSWORD=${OPTARG};;
#   esac
# done

# Defne local directory paths etc:
DATA_DIR="data-research/data_export"
PKG_LAYERS=( geo_admin geo_floods geo_reach_infra )

# Import

# Create hstore if not exists yet.
echo "Create hstore extension in DB."

psql \
  -d ${DB} -U ${USER} -h ${HOST} -p ${PORT} \
  -c "CREATE EXTENSION IF NOT EXISTS hstore;"

# Import OSM Layer Bangladesh
echo "Importing OSM data..."

osm2pgsql -d ${DB} -U ${USER} -H ${HOST} \
  -W -P ${PORT} --create --prefix=osm \
  --hstore --proj=3160 \
  ${DATA_DIR}/bgd_camps.osm.pbf

echo "Imported: OSM data."
# Import

echo "Import data-collection layers..."

for layer in "${PKG_LAYERS[@]}";
do
  ogr2ogr \
    -append \
    -nln ${layer} \
    -f "PostgreSQL" PG:"host=$HOST user=$USER dbname=$DB port=$PORT password=$PASSWORD" \
    "${DATA_DIR}/data-collection.gpkg" \
    "${layer}"
  echo "Imported: ${layer}."
done  


echo "Import rectangular data"

Rscript data-research/import_csv.R


echo "Run cleaning SQL script"
psql \
  -h ${HOST} -U ${USER} -p ${PORT} -d ${DB} \
  -f data-research/import_clean.sql


# Create Functions:



echo "Done."
