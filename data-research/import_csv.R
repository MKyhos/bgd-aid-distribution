# Script for import data.
# Superior to bash as it has to to be defined beforehand
# how the table is created.

library(DBI)
library(readr)
library(here)

# Connection
db <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = "localhost",
  user = "gis_user",
  dbname = "gis_db",
  port = 45432
)


# Import

dta_sblock <- readr::read_csv(here("data-research/data_export/dta_sblock.csv"))

DBI::dbWriteTable(
  conn = db,
  name = "dta_sblock",
  value = dta_sblock,
  overwrite = TRUE
)

