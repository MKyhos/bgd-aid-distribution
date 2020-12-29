#!/bin/bash

set -e

# Using Authentification via a .pgpass file.
#export PGPASSWORD=$(cat ~/.pgpass)

DFILE="data-backup/gis-db-backup_`date +%Y-%m%-d_%H-%M-%S`.sql.gz"

pg_dump \
  --dbname=gis_db \
  --username=gis_user \
  --port=45432 \
  --host=localhost |
  gzip > $DFILE

echo "SQL Backup completed."