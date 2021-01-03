#' Script for preparing and cleaning
#' geospatial data, and saving them locally
#' (for later import into DB)

library(dplyr)
library(magrittr)
library(sf)
library(here)
library(mapview) # For exploration.

#' Import
#' 
#' - read files
#' - transform CRS to Gulshan 303 / Bangladesh Transverse Mercator (EPSG 3106)
#'    this can be debated lateron however..

#' == Camp Boundaries ==

#' Admin levels
#' al1 : Camp level -> camp_id
#' al2 : block level -> block_id
#' al3 : sub-block level -> sblock_id
#' 
#' _Note:_ some camps are not available on al3. Thus, al1 is used as drop in.
#' 
geo_outline_a2 <- read_sf(here("data-research/data_raw/outline/block_al2/200908_RRC_Outline_Block_AL2.shp")) %>%
  st_transform(crs = 3160)

camp_information <- geo_outline_a2 %>%
  st_drop_geometry() %>%
  select(
    camp_id = Camp_SSID, camp_name = CampName,
    block_id = Block_SSID, block_name = Block_Name)

geo_outline_a2 <- geo_outline_a2 %>%
  select(camp_id = Camp_SSID, block_id = Block_SSID, geometry)

geo_outline_a3 <- read_sf(here("data-research/data_raw/outline/block_al3/200908_RRC_Outline_SubBlock_AL3.shp")) %>%
  st_transform(crs = 3160) %>%
  select(camp_id = Camp_SSID, block_id = Block_SSID, sblock_id = Subblock_1, geometry)

# Only on block level available:
only_blocks <- anti_join(
  x = st_drop_geometry(geo_outline_a2),
  y = st_drop_geometry(geo_outline_a3),
  by = "camp_id") %>%
  pull(block_id)

geo_admin <- geo_outline_a2 %>%
  filter(block_id %in% only_blocks) %>%
  mutate(sblock_id = paste0(block_id, "_XX")) %>%
  bind_rows(geo_outline_a3) %>%
  mutate(sblock_id = stringr::str_replace(sblock_id, " ", "")) %>%
  select(camp_id, block_id, sblock_id, geometry) %>%
  arrange(sblock_id) %>%
  st_as_sf()

geo_admin_buffer <- geo_admin %>%
  st_union() %>% 
  st_buffer(dist = 20000)

flood_layers <- c(
  "NOAA_20200712_20200721_FloodExtent_Bangladesh",
  "NOAA_20200723_20200727_FloodExtent_Bangladesh",
  "NOAA_20200729_20200802_FloodExtent_Bangladesh")

geo_fl_01 <- read_sf(
  here("data-research/data_raw/floodings/FL20200713BGD.gdb"),
  layer = flood_layers[1]) %>%
  st_transform(crs = 3160) %>%
  select(sensor_date = Sensor_Date, geometry = SHAPE) %>%
  st_make_valid() %>%
  st_intersection(geo_admin_buffer)
  
geo_fl_02 <- read_sf(
  here("data-research/data_raw/floodings/FL20200713BGD.gdb"),
  layer = flood_layers[2]) %>%
  st_transform(crs = 3160) %>%
  select(sensor_date = Sensor_Date, geometry = SHAPE) %>%
  st_make_valid() %>%
  st_intersection(geo_admin_buffer)

geo_fl_03 <- read_sf(
  here("data-research/data_raw/floodings/FL20200713BGD.gdb"),
  layer = flood_layers[3]) %>%
  st_transform(crs = 3160) %>%
  select(sensor_date = Sensor_Date, geometry = SHAPE) %>%
  st_make_valid() %>%
  st_intersection(geo_admin_buffer)

geo_flood <- geo_fl_01 %>%
  st_union(geo_fl_02) %>%
  st_union(geo_fl_03) %>%
  mutate(flood = c(1, 2, 3, 4)) %>%
  select(flood, geometry)




dta_population <- readxl::read_xlsx(
  here("data-research/data_raw/population_74678.xlsx"),
  sheet = 2) %>%
  tidyr::pivot_longer(
    cols = - c(camp_name, block),
    names_to = "variable",
    values_to = "count") %>% 
  inner_join(camp_information, by = c("camp_name" = "camp_name", "block" = "block_name")) %>%
  select(camp_id, block_id, variable, count)


# Compile potential camp level data:



# Geo Point Infrastructure
dta_health_facilty <- readxl::read_xlsx(
  here("data-research/data_raw/reach/reach_bgd_data_whohealthservices_12122017.xlsx"),
  sheet = 2) %>%
  select(
    type = 'Facility type', status = 'Operational Status',
    lon = Longitude, lat = Latitude) %>%
  mutate(class = "health_service") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(crs = 3160)

dta_tubewells <- readxl::read_xlsx(
  here("data-research/data_raw/reach/reach_bgd_dataset_tubewell-coding_july_2019.xlsx"),
  sheet = "REACH_BGD_dataset_Tubewell codi") %>%
  select(sanitary_inspection_score, contamination_risk_score,
    lon = "GPS Longitude", lat = "GPS Latitude") %>%
  mutate(class = "tubewell") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(crs = 3160)

dta_sanitation <- readxl::read_xlsx(
  here("data-research/data_raw/reach/reach_bgd_dataset_sanitation-infrastructure-coding_nov2019.xls"),
  sheet = "Main_Database") %>%
  select(type = struc_type, lon, lat) %>%
  mutate(class = "sanitation") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(crs = 3160)

dta_womenfriendly <- readxl::read_xlsx(
  here("data-research/data_raw/reach/reach_bgd_who_womenfriendlyspace_clean_15112017.xlsx"),
  sheet = 1) %>%
  select(lat = "_geopoint_latitude", lon = "_geopoint_longitude") %>%
  mutate(class = "women_protection") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(crs = 3160)

dta_nutrition <- readxl::read_xlsx(
  here("data-research/data_raw/reach/reach_bgd_who_nutritionservices_clean_15112017.xlsx"),
  sheet = 1) %>%
  select(lat = "_geopoint_latitude", lon = "_geopoint_longitude") %>%
  mutate(class = "nutrition_service") %>%
  st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
  st_transform(crs = 3160)

geo_reach_infra <- bind_rows(
  dta_tubewells,
  dta_sanitation,
  dta_health_facilty,
  dta_womenfriendly,
  dta_nutrition) %>%
  st_as_sf() %>%
  select(class, type, geometry, type, sanitary_inspection_score, contamination_risk_score)




dta_camp <- bind_rows(
  mutate(dta_population, about = "population")
)


# Export:
export_file <- here("data-research/data_export/data-collection.gpkg")

write_sf(
  obj = geo_admin,
  dsn = export_file,
  layer = "geo_admin")
write_sf(
  obj = geo_flood,
  dsn = export_file,
  layer = "geo_floods")
write_sf(
  obj = geo_reach_infra,
  dsn = export_file,
  layer = "geo_reach_infra"
)

# Recangular data
readr::write_csv(dta_population, "data-research/data_export/dta_population_block.csv")
readr::write_csv(dta_camp, "data-research/data_export/dta_camp.csv")
