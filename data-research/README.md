# Data and Research / Concept

See the file `data-research/concept.md` for WIP concept.


## Data Overview


### `OSM` Data

Using `osmosis` to prefilter the Geofabrik extract to the area of interest,
that are the camp boundaries with a buffer of 20 km.

First, we need to create `poly` files for the boundaries. For that, in the 
first step `R` was used:

```r
library(sf)
library(magrittr)

read_sf(
  here("data-research/data_export/data-collection.gpkg"),
  layer="poly_camp_boundaries") %>%
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

Subsequently, we receive a clipped OSM extract of much smaller size.

```
osm2pgsql -d gis_db -U gis_user -H localhost \
  -W -P 45432 --create --prefix=osm \
  --hstore --proj=3160 \
  data-research/data_export/bgd_camps.osm.pbf
```


## Research Overview

