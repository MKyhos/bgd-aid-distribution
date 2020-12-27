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

PKG_DIR="data-research/data_export"
PKG_LAYERS=( poly_shelters poly_camp_boundaries )

# Import OSM Layer Bangladesh

# Import

for layer in "${PKG_LAYERS[@]}";
do
  ogr2ogr \
    -append \
    -nln ${layer} \
    -f "PostgreSQL" PG:"host=$host user=$user dbname=$db port=$port password=$password" \
    "${PKG_DIR}/data-collection.gpkg" \
    "${layer}"
done  

echo "Imported from Geopackage."

# Executing Database Cleaning Script
# Get relative path

# full_path=$(realpath $0)
# dir_path=$(dirname full_path)
# sql_file="$dir_path/import_clean.sql"
# 
# psql -h $host -p $port \
#   -d $db -u $user \
#   -f $sql_file

