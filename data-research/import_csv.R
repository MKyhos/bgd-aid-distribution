# Script for import data.
# Superior to bash as it has to to be defined beforehand
# how the table is created.

library(DBI)
library(readr)
library(here)

# Connection
db <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("PG_HOST"),
  user = Sys.getenv("PG_USER"),
  dbname = Sys.getenv("PG_DB"),
  password = Sys.getenv("PG_PASSWORD"),
  port = Sys.getenv("PG_PORT")
)


# Import

dta_sblock <- readr::read_csv(here("data-research/data_export/dta_sblock.csv"))

DBI::dbWriteTable(
  conn = db,
  name = "dta_sblock",
  value = dta_sblock,
  overwrite = TRUE
)

