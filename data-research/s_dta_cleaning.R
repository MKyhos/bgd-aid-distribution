#' Script for preparing and cleaning
#' geospatial data, and saving them locally
#' (for later import into DB)

library(dplyr)
library(magrittr)
library(sf)
library(here)

#' Import
#' 
#' - read files
#' - transform CRS to Gulshan 303 / Bangladesh Transverse Mercator (EPSG 3106)
#'    this can be debated lateron however..


#' `camp_outline`: Polygon Layer. Outlines of Blocks and Camps etc.
#' Source:
#' Date:
poly_camp_outline <- read_sf(here("data-research/data_raw/camp_outline/Blockoutline/200908_RRC_Outline_Block_AL2/200908_RRC_Outline_Block_AL2.shp")) %>%
  st_transform(crs = 3160) %>%
  select(block_ssid = Block_SSID, camp_ssid = Camp_SSID, block_name = Block_Name,
        camp_name = CampName)

poly_shelter_outline <- read_sf(
  here("data-research/data_raw/camp_outline/BGD_Camp_ShelterFootprint_UNOSAT_REACH_v1_January019/BGD_Camp_ShelterFootprint_UNOSAT_REACH_v1_January2019.shp")) %>%
  st_transform(crs = 3160) %>%
  select(id = id, shelter_class = un_class, area_class = area_class, geometry)    


# Export:

export_file <- here("data-research/data_export/data-collection.gpkg")

write_sf(
  obj = poly_camp_outline,
  dsn = export_file,
  layer = "poly_camp_boundaries")
write_sf(
  obj = poly_shelter_outline,
  dsn = export_file,
  layer = "poly_shelters"
)
