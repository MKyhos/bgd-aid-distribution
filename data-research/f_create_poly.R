library(magrittr)
#' Writes a simple polygon in polygon file format for osmosis
#' 
#' Assumes that there is only one polygon, no holes, etc.
#' 
#' @param sf_polygon Input polygon
#' @param output_file <string> Path to desired output file. Wiht .poly ending.
write_poly_file <- function(sf_polygon, output_file) {

  polygon_part <- sf_polygon %>%
    sf::st_transform(crs = 4326) %>%
    sf::st_cast(to = "POINT") %>%
    sf::st_coordinates() %>%
    as.data.frame() %>%
    setNames(c("lon", "lat")) %>%
    dplyr::mutate_all(formatC, format = "e") %>%
    dplyr::mutate(pasted = paste0("   ", toupper(lon), "   ", toupper(lat))) %>%
    dplyr::pull(pasted) %>%
    paste(collapse = "\n")

  result <- glue::glue(
    "
    none
    1
    {polygon_part}
    END
    END
    ")
  writeLines(
    text = result,
    con = output_file
    )

}
