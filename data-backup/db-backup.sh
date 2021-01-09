#!/bin/bash
set -e

DFILE="data-backup/gis-db-backup_`date +%Y-%m-%d_%H-%M-%S`.sql.gz"
pg_dump ${PG_URI} | gzip > $DFILE
echo "SQL Backup completed."

