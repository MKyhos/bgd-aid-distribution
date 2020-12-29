#!/bin/bash

# A script for importing Data into the DB
# takes the following flags:
# -p port
# -h localhost
# -d database name
# -u username

# Pass over arguments:
while getopts p:h:d:u:x: flag
do
  case "${flag}" in
    p) port=${OPTARG};;
    h) host=${OPTARG};;
    d) db=${OPTARG};;
    u) user=${OPTARG};;
    x) password=${OPTARG};;
  esac
done

# Import
# Assumes everything is in place...

DATA_DIR="data-research/data_export"
PKG_LAYERS=( poly_shelters poly_camp_boundaries )

# Import OSM Layer Bangladesh

cat "Importing OSM data..."

osm2pgsql -d ${db} -U ${user} -H ${host} \
  -W -P ${port} --create --prefix=osm \
  --hstore --proj=3160 \
  ${DATA_DIR}/data_export/bgd_camps.osm.pbf

# Import

for layer in "${PKG_LAYERS[@]}";
do
  ogr2ogr \
    -append \
    -nln ${layer} \
    -f "PostgreSQL" PG:"host=$host user=$user dbname=$db port=$port password=$password" \
    "${DATA_DIR}/data-collection.gpkg" \
    "${layer}"
done  



