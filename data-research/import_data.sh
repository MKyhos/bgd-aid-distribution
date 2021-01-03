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
PKG_LAYERS=( poly_shelters poly_camp_boundaries )

# Import
# Assumes everything is in place...

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

echo "Done."
