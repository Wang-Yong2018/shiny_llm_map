#library(dplyr)
#library(dbplyr)
#library(DBI)
#library(RSQLite)
#library(magrittr)

box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
box::use(DBI[dbConnect,dbListTables])
box::use(RSQLite[SQLite,dbAppendTable])
box::use(purrrlyr[by_row])

# boolean to control console messages

# function to connect to a SQLite database, creating a data directory and
# SQLite file if necessary. This could be updated to use a different storage
# mechanism.
get_data_schema <- function(){
  message_db_schema <- tibble(username = character(0),
                                     #datetime = Sys.time()[0], # if you want POSIXct data instead
                                     #datetime = numeric(0),    # if you want to store datetimes as numeric
                                     datetime = character(0),   # we're taking the easy way here
                                     message = character(0))
  
  return(message_db_schema)
}

#' @export
db_connect <- function() {
  # make sure we have a data directory
  if (!dir.exists("data")) dir.create("data")
  
  # connect to SQLite database, or create one
  
  con <- dbConnect(SQLite(), "data/messages.sqlite")
  
  # if there is no message table, create one using our schema
  if (!"messages" %in% dbListTables(con)){
    message_db_schema <- get_data_schema()
    
    db_clear(con, message_db_schema)
  }
  
  return(con)
}

#' @export
db_clear <- function(con ){
  message_db_schema <- get_data_schema()
  copy_to(con, 
          message_db_schema, 
          name = "messages",
          overwrite = TRUE,
          temporary = FALSE )
}

# A separate function in case you want to do any data preparation (e.g. time zone stuff)
#' @export
read_messages <- function(con){
  tbl(con, "messages")|>
    collect()
}

#' @export
send_message <- function(con, new_message) {
  dbAppendTable(con, "messages", new_message)
}
