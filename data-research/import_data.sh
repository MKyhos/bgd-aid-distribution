#!/bin/bash

# A script for importing Data into the DB
# takes the following flags:
# -p port
# -h localhost
# -d database name
# -u username


# Defne local directory paths etc:
DATA_DIR="data-research/data_export"
PKG_LAYERS=( geo_admin geo_floods geo_reach_infra )

# Import

# Create hstore if not exists yet.
echo "Create hstore extension in DB."

psql \
  ${PG_URI} \
  -c "CREATE EXTENSION IF NOT EXISTS hstore;"

# Import OSM Layer Bangladesh
echo "Importing OSM data..."

osm2pgsql -d ${PG_URI} \
  --create --prefix=osm \
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
    -f "PostgreSQL" PG:"host=$PG_HOST user=$PG_USER dbname=$PG_DB port=$PG_PORT password=$PG_PASSWORD" \
    "${DATA_DIR}/data-collection.gpkg" \
    "${layer}"
  echo "Imported: ${layer}."
done  


echo "Import rectangular data"

Rscript data-research/import_csv.R


echo "Run cleaning SQL script"
psql \
  ${PG_URI} \
  -f data-research/import_clean.sql


# Create Functions:



echo "Done."
