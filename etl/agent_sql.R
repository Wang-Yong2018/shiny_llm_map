box::use(DBI[dbListTables,dbListFields, dbConnect,dbDisconnect, dbSendQuery, dbFetch],
         RPostgres[Postgres],
         RSQLite[SQLite])
box::use(logger[log_info, log_warn,  log_debug, log_error, log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])
box::use(dplyr[case_when])
box::use(purrr[map,imap,pluck],
         stats[setNames])
box::use(jsonlite[fromJSON, toJSON],
         stringr[str_glue])
box::use(../global_constant[db_id_list, max_sql_query_rows,sql_agent_config_file])

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
get_dbms_name <-function(db_id){
  
  conn <- 
    get_db_conn(db_id) 
  
  connection_class <- conn|>class() |>pluck(1)
  
  dbDisconnect(conn)
  dbms_name <- case_when(
    grepl('SQLite',connection_class) ~'sqlite',
    grepl('Postgres',connection_class) ~'postgres',
    grepl('MySQL',connection_class) ~'mysql',
    grepl('duckdb',connection_class) ~'duckdb',
    .default='postgres'
  )
  return(dbms_name)
  
}

#' @export
get_sql_prompt <- function(db_id, user_prompt){
  dbms_name      <- get_dbms_name(db_id)
  sql_ddl <- get_db_schema_text(input$db_id)
  sql_sample <-''
  user_question <- user_prompt
  
  system_prompt <- readLines(sql_agent_config_file) |>paste0(collapse = '\n')
  agent_prompt <- str_glue(system_prompt)
  
  return(agent_prompt) 
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
  result <- tryCatch(
    expr = {
      conn <- get_db_conn(db_id)
      result <- conn |> 
        dbSendQuery(query)|>
        dbFetch(n=max_sql_query_rows)
    },
    error = function(e) {
      error_message <- e|>pluck('message')
      log_error(paste0("An sql agent router parse error occurred: ", error_message))
      result <- error_message
    }
)
    return(result) 
}