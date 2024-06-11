box::use(DBI[dbListTables,dbListFields, dbConnect,dbDisconnect, dbSendQuery, dbFetch,dbClearResult],
         RPostgres[Postgres],
         RSQLite[SQLite])
box::use(logger[log_info, log_warn,  log_debug, log_error, log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])
box::use(dplyr[case_when],
         dbplyr[as.sql])# add dbplyr[as.sql] jus to shinyio.app report missing the library

box::use(purrr[map,imap,pluck],
         stats[setNames])
box::use(jsonlite[fromJSON, toJSON],
         stringr[str_glue])
box::use(../global_constant[db_id_list, db_chinook_url,db_url_map, MAX_TOKENS,
                            max_sql_query_rows,sql_agent_config_file,
                            IS_DEBUG
                            ])
box::use(../etl/llmapi[get_llm_result, get_ai_result])

get_db_conn <- function(db_id){
  
  conn <- switch(
    db_id,
    music = dbConnect(SQLite(), db_url_map[[db_id]]),
    hispital = dbConnect(SQLite(), db_url_map[[db_id]]),
    dvd_rental = dbConnect(SQLite(), db_url_map[[db_id]]),
    cyd = dbConnect(
      Postgres(),
      dbname = Sys.getenv('cyd_db_name'),
      host =  Sys.getenv('cyd_db_host'),
      port =  Sys.getenv('cyd_db_port'),
      user =  Sys.getenv('cyd_db_user'),
      password = Sys.getenv('cyd_db_password')
    ),
    dbConnect(SQLite(), db_url_map[[db_id]])
  )
  return(conn)
}

#' @export
get_dbms_name <- function(db_id){
  
  conn <-  get_db_conn(db_id) 
  connection_class <- conn |> class() |> pluck(1)
  # Ensure the connection is closed when the function exits, regardless of how it exits
  on.exit(dbDisconnect(conn), add = TRUE)
  
  
  dbms_name <- case_when(
    grepl('SQLite',connection_class) ~ 'sqlite',
    grepl('Postgres',connection_class) ~ 'postgres',
    grepl('MySQL',connection_class) ~ 'mysql',
    grepl('duckdb',connection_class) ~ 'duckdb',
    .default = 'postgres'
  )
  return(dbms_name)
}


#' @export
get_db_schema <- function(db_id){
  
  # Connect to SQLite database
  conn <- get_db_conn(db_id)
  # Ensure the connection is closed when the function exits, regardless of how it exits
  on.exit(dbDisconnect(conn), add = TRUE)
  
  
  # List the tables
  # """Return a list of dicts containing the table name and columns for each table in the database."""
  tables_list <- dbListTables(conn)
  
  table_dict <-
    setNames(tables_list, tables_list) |>
    purrr::imap(\(table_name, idx) dbListFields(conn, table_name))
  
  
  db_schema <- table_dict |> toJSON(auto_unbox = TRUE, pretty = TRUE) 
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

postgres_query <- "select
                        'CREATE TABLE ' || nspname || '.' || relname || ' (' || chr(10)||
                         array_to_string(
                          	array_agg(attname || 
                          	          ' '     || 
                          	          atttypid::regtype::text||
                          	          CASE attnotnull WHEN true THEN ' NOT NULL' ELSE ' NULL' end ||
                          	          coalesce('  -- COMMENT ' || quote_literal(description), '')|| 
                          	          ','  || chr(10)
                          	          ), '  '  
                          	          )  || chr(10)|| ');' as definition
                      from 
                          pg_attribute
                          join
                              pg_class on
                          	pg_class.oid = pg_attribute.attrelid
                          join
                              pg_namespace on
                          	pg_namespace.oid = pg_class.relnamespace
                          left join
                              pg_description on
                          	pg_description.objoid = pg_class.oid
                          	and pg_description.objsubid = pg_attribute.attnum
                      where
                        	nspname not in ('pg_catalog', 'information_schema')
                        	and relkind in ('r', 'v')
                      group by
                      	nspname, relname;"

query <- switch(tolower(get_dbms_name(db_id)),
                sqlite = sqlite_query ,
                postgres = postgres_query,
                postgresql = postgres_query )
return(query)
}



#' @export
get_db_schema_text <- function(db_id){
  
  # Connect to SQLite database
  conn <- get_db_conn(db_id)
  # Ensure the connection is closed when the function exits, regardless of how it exits
  on.exit(dbDisconnect(conn), add = TRUE)
  
  sql <- get_schema_sql(db_id)
  result <- 
    conn |> 
    dbSendQuery(sql) |>
    dbFetch() |>
    pluck(1) |>
    paste0(collapse = '\n\n')
  # Close the database connection
  # dbClearResult(res)
  # remove above code if the on.exit code run OK.
  
  return(result) 
}



#' @export
get_sql_prompt <- function(db_id, user_prompt){
  
  # dbms_name      <- get_dbms_name(db_id)
  # sql_ddl <- get_db_schema_text(db_id)
  # 
  # sql_sample <-''
  # user_question <- user_prompt
  
  system_prompt <- readLines(sql_agent_config_file) |> paste0(collapse = '\n')
  agent_prompt <- str_glue(
    system_prompt,
    dbms_name = get_dbms_name(db_id),
    sql_ddl = get_db_schema_text(db_id),
    sql_sample = '',
    user_question = user_prompt,
    system_prompt = system_prompt
  )
  
  return(agent_prompt) 
}


extract_md_code <- function(text){
  
  # Extract the code inside the ``` ```
  # Remove the backticks from the extracted string
  
  code <- 
    text |>
    gsub(pattern = '```\\w*(\n){0,1}',
         replacement = '',
         x = _)
  
  if (is.null(code)) {
    log_error(paste('extract_md_code error, match is NULL. retunr original text'))
    
    result <- text
  } else{
    result <- code
  } 
  
  return(result)
  
}


#' @export
get_sql_result <- function(arguments){
  db_id = arguments$db_id
  model_id = arguments$model_id
  query <-
    arguments$sql_query |>
    extract_md_code()
  
  log_debug(paste0('get_sql_query function:===>', query, sep = '    '))
  log_debug(paste0('db_id is ===> ', db_id, sep = '    '))
  
  
  conn <- get_db_conn(db_id)
  # Ensure the connection is closed when the function exits, regardless of how it exits
  on.exit(dbDisconnect(conn), add = TRUE)
  
  result = ''
  result <- tryCatch(
    expr = {
      conn |> 
        dbSendQuery(query) |>
        dbFetch(n = max_sql_query_rows)
    },
    error = function(e) {
      error_message <- e |> pluck('message')
      log_error(paste0("An sql agent router parse error occurred: ", error_message))
      result <- error_message
    }
)
  # Close the database connection
  # on.exit(dbDisconnect(conn))
  sql_message <- list(
    query = query,
    result = result,
    db_id = db_id,
    model_id = model_id
  )
  
  #log_info(paste('the sql result function result is sql_message(query, result)===>',sql_message))
  
  return(sql_message) 
}

#' @export
get_gv_string <- function(db_id, model_id){
 
  # db_schema_text <- get_db_schema_text(db_id)
  gv_prompt_template <- 
  'as an expert of database entity, relation and diagram,\n
   pls use graph diagram DOT language code to geneate .gv file for later visulization.
   Input are The sql ddl codes. They are followed for you analyze and generate dot code.\n
   output rules:
   1.output dot code should be inside of the  dot code block.
    ```
   {db_schema_text}
   ```'
  # language <- 'dot'
  gv_prompt <- str_glue(gv_prompt_template) |> toString()
  
  llm_result <- get_llm_result(prompt = gv_prompt,
                               llm_type = 'chat',
                               model_id = model_id)
  ai_result <- get_ai_result(llm_result, ai_type = 'dot') 
  result <- ai_result$content
  log_debug(paste0('gv_string ---->',result))
  return(result)
  
}

