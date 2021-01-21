# Script for import data.
# Superior to bash as it has to to be defined beforehand
# how the table is created.


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
dta_block <- readr::read_csv(
  here::here("data-research/data_export/dta_block.csv"),
  col_types = readr::cols()
)

DBI::dbWriteTable(
  conn = db,
  name = "dta_block",
  value = dta_block,
  overwrite = TRUE
)

DBI::dbDisconnect(db)
