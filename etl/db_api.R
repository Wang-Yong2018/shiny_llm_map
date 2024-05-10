library(DBI)
library(dplyr)
library(dbplyr)
library(RSQLite)



get_database_info<- function(db_name="./data/chinook.db",db_type='sqlite'){
  
  # Connect to SQLite database
  conn <- switch(db_type,
                sqlite= DBI::dbConnect(RSQLite::SQLite(), db_name),
                postgresql=DBI::dbConnect(RPostgres),
                postgres=DBI::dbConnect(RPostgres)
                  )
  # List the tables
  # """Return a list of dicts containing the table name and columns for each table in the database."""
  tables_list <- dbListTables(conn)
  
  table_dict <- 
    setNames(tables_list,tables_list) |> 
    purrr::imap(\(table_name,idx) dbListFields(conn,table_name))
  
# Close the database connection
  dbDisconnect(conn)
  return( table_dict)
}


