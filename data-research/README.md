# Data and Research / Concept

See the file `data-research/concept.md` for WIP concept.

_Note:_ all bash scripts should be executed from the repository root
directory, as otherwise the relative paths might be faulty.

<!-- #TODO find a way for robust relative paths in bash scripts... -->

## Data Overview

The data overview, selection, and status tracking is organized in the 
`GIS Data` spreadsheet.


### `OSM` Data

Using `osmosis` to prefilter the Geofabrik extract to the area of interest,
that are the camp boundaries with a buffer of 20 km.

First, we need to create `poly` files for the boundaries. For that, in the 
first step `R` was used:

```r
library(sf)
library(magrittr)
source(here::here("data-research/f_create_poly.R"))
read_sf(
  here("data-research/data_export/data-collection.gpkg"),
  layer="geo_admin") %>%
  st_union() %>%
  st_buffer(dist = 20000) %>%
  write_poly_file(
    sf_polygon = .,
    output_file = here("data-research/data_export/osm-import.poly")
  )
```

Subsequently, `osmosis` can be run on the Geofabrik extract, using the
following command:

```zsh
osmosis \
  --read-pbf file="data-research/data_raw/bangladesh-latest.osm.pbf" \
  --bounding-polygon file="data-research/data_export/osm-import.poly" \
  --write-pbf file="data-research/data_export/bgd_camps.osm.pbf"
```

Subsequently, we receive a clipped OSM extract of much smaller size. It can
be imported into db the usual way, as stated in `data-research/import_data.sh`,
or simply:

```zsh
osm2pgsql -d gis_db -U gis_user -H localhost \
  -W -P 45432 --create --prefix=osm \
  --hstore --proj=3160 \
  data-research/data_export/bgd_camps.osm.pbf
```

From the raw imported tables, other tables might be derived. 

### Humdata.org and other sources

Every selected data set from humdata.org (see the `GIS Data` spreadsheed)
is cleaned and subsequently stored in the `data-research/data_export/data-collection.gpkg`
file as a separate layer. The geopackage is then imported into the database
via the script `data-research/import_data.sh`.

## Data Model


<!-- Include data model graph here -->


