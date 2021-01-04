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

1. Run `docker-compose -p osm up`
2. Prepare/import data (see `data-research/`), or simply apply the
   backup file provided in GDrive.
3. View Frontend at `localhost:44200`
   

### Using pgAdmin4

After previous step, go to `localhost:45050`. 

- Login with data defined in `env/pgadmin.env`. 
- Subsequently, add the database server via `Add New Server`. 
- Since both pgAdmin4 and the PostgreSQL
    instance share the same network, use `database` and `5432` 
    as database name/host and port, respectively.
- Also use login data as defined in `env/database.env`.


## Workflow 

Organized with GH issue tracker and ZenHub, with the following definitions:

* **Issue:** Single task / user story, with limited scope and clear description
    of what should be done. Can be assigned to one or more developers.
* **Epic:** A group of (topically) similar issues. An epic is managed by one
  person that tracks the progress on the individual issues.
* **Milestone:** weekly/biweekly sprint, with a given target definition.
