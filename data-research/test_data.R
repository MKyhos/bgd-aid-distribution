#' An R script for quick prototyping and testing of maps etc
#' 

# Packages

library(dplyr)
library(magrittr)
library(sf)
library(here)
library(mapview) # For exploration.
library(DBI)
library(leaflet)
library(leafem)
library(ggplot2)


# Database conenction
db <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("PG_HOST"),
  user = Sys.getenv("PG_USER"),
  dbname = Sys.getenv("PG_DB"),
  port = Sys.getenv("PG_PORT")
)



# 1. SBLOCK level

d_sblock <- sf::read_sf(
  db, query = "
        SELECT * FROM tbl_block_features;"
)

# Example: get everything as geojson:d_sblock

d_sblock_geojson <- dbGetQuery(
  conn = db,
  statement = "
    SELECT JSON_Build_Object(
      'type', 'FeatureCollection',
      'features', JSON_Agg(ST_AsGeoJSON(t.*)::json))
    FROM tbl_camp_features AS t;"
)

read_sf(d_sblock_geojson) %>%
  mapview(zcol = "n_latr")
