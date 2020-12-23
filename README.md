# [`GIS Project`] Bangladesh Aid Distribution Mapping

Course group project for `INF: Geographic Information Systems` at the
University of Konstanz, winter term 2020/2021.


## Overview, motivation



## Setup

**Note** Changed exposed ports for host:

* Backend: `45000`
* Frontend: `44200`
* pgAdmin: `45050`
* Database: `45432`

### Run at your machine

1. `docker-compose -p osm up`
2. Import data:
   ```
    osm2pgsql \
        --databse gis_db --host localhost --port 45432 \
        --username gis_user --password --create --slim \
        --drop --latlong --hstore-all \
        bangladesh-latest.osm.pbf
   ```
    Enter password: e.g. default `gis_pass`
3. View Frontend at `localhost:44200`
   

### Using pgAdmin4

After previous step, go to `localhost:45050`. 

- Login with data defined in `env/pgadmin.env`. 
- Subsequently, add the database server via `Add New Server`. 
- Since both pgAdmin4 and the PostgreSQL
    instance share the same network, use `database` and `5432` 
    as database name/host and port, respectively.
- Also use login data as defined in `env/database.env`.
