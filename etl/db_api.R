box::use(DBI[dbListTables,dbListFields,
             dbConnect,dbDisconnect,
             dbSendQuery, dbFetch])
box::use(RPostgres[Postgres],
         RSQLite[SQLite])
box::use(purrr[map,imap,pluck],
         stats[setNames])
box::use(jsonlite[fromJSON, toJSON])
box::use(../global_constant[db_id_list, max_sql_query_rows])

get_db_conn <- function(db_id){
  db_name <- "./data/chinook.db"
  conn <- dbConnect(SQLite(), db_name)
              
  # conn <- switch(db_type,
  #               sqlite= dbConnect(SQLite(), db_name),
  #               postgresql=dbConnect(RPostgres),
  #               postgres=dbConnect(RPostgres)
  #                 )
}

#' @export
get_db_schema <- function(db_id){
  
  # Connect to SQLite database
  conn <- get_db_conn()
  # List the tables
  # """Return a list of dicts containing the table name and columns for each table in the database."""
  tables_list <- dbListTables(conn)
  
  table_dict <- 
    setNames(tables_list,tables_list) |> 
    purrr::imap(\(table_name,idx) dbListFields(conn,table_name))
  
# Close the database connection
  dbDisconnect(conn)
  db_schema <- table_dict |> toJSON(auto_unbox=TRUE, pretty=TRUE) 
  return( db_schema)
}

get_schema_sql <- function(db_id){
  
  sqlite_query <- "\n\n SELECT 'CREATE TABLE ' || tbl_name || ' (\n' || group_concat(column_statement, ',\n ') || '\n);' AS create_table_statement
FROM (
    SELECT 
        tbl_name,
        cid,
        field_name || ' ' || type || 
        CASE WHEN is_notnull = 1 THEN ' NOT NULL' ELSE '' END || 
        CASE WHEN pk = 1 THEN ' PRIMARY KEY' ELSE '' END AS column_statement
    FROM (
        SELECT 
            tbl_name,
            p.cid,
            p.name as field_name,
            p.type,
            p.\"notnull\" as is_notnull,
            p.pk
        FROM sqlite_master AS m, pragma_table_info((m.name)) as p 
        WHERE m.type = 'table' AND tbl_name NOT LIKE 'sqlite_%'
    )
    ORDER BY tbl_name, cid
)
GROUP BY tbl_name;"
  query <- sqlite_query 
  return(query)
}

#' @param db_id 
#'
#' @export
get_db_schema_text <- function(db_id){
  # Connect to SQLite database
  conn <- get_db_conn()
  sql <- get_schema_sql()
  result <- conn |> 
    dbSendQuery(sql)|>
    dbFetch() |>
    pluck(1) |>
    paste0(collapse = '\n\n')
  return(result) 
}

#' @export
get_sql_result <- function(query=NULL,db_id=NULL){

  tryCatch(
    expr = {
      conn <- get_db_conn(db_id)
      result <- conn |> 
        dbSendQuery(query)|>
        dbFetch(n=max_sql_query_rows)
    },
    error = function(e) {
      log_error(paste0("An sql agent router parse error occurred: ", conditionMessage(e), "\n"))
    }
)
    return(result) 
    
  
}