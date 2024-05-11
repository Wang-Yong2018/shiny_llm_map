box::use(DBI[dbListTables,dbListFields,dbConnect,dbDisconnect])
box::use(RPostgres[Postgres],
         RSQLite[SQLite])
box::use(purrr[map,imap],
         stats[setNames])


get_database_info<- function(db_name="./data/chinook.db",db_type='sqlite'){
  
  # Connect to SQLite database
  conn <- switch(db_type,
                sqlite= dbConnect(SQLite(), db_name),
                postgresql=dbConnect(RPostgres),
                postgres=dbConnect(RPostgres)
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


