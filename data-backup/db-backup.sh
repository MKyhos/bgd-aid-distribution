#!/bin/bash

set -e

# Using Authentification via a .pgpass file.
#export PGPASSWORD=$(cat ~/.pgpass)

DFILE="data-backup/gis-db-backup_`date +%Y-%m-%d_%H-%M-%S`.sql.gz"
pg_dump ${PG_URI} | gzip > $DFILE

echo "SQL Backup completed."