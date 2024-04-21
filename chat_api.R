library(dplyr)
library(dbplyr)
library(DBI)
library(RSQLite)

# boolean to control console messages
debug <- FALSE

# function to connect to a SQLite database, creating a data directory and
# SQLite file if necessary. This could be updated to use a different storage
# mechanism.
db_connect <- function(message_db_schema) {
  # make sure we have a data directory
  if (!dir.exists("data")) dir.create("data")
  
  # connect to SQLite database, or create one
  con <- DBI::dbConnect(RSQLite::SQLite(), "data/messages.sqlite")
  
  # if there is no message table, create one using our schema
  if (!"messages" %in% DBI::dbListTables(con)){
    db_clear(con, message_db_schema)
  }
  
  return(con)
}

db_clear <- function(con, message_db_schema){
  dplyr::copy_to(con, message_db_schema, name = "messages", overwrite = TRUE,  temporary = FALSE )
}

# A separate function in case you want to do any data preparation (e.g. time zone stuff)
read_messages <- function(con){
  dplyr::tbl(con, "messages") %>%
    collect()
}

send_message <- function(con, new_message) {
  RSQLite::dbAppendTable(con, "messages", new_message)
}

# function to render SQL chat messages into HTML that we can style with CSS
# inspired by:
# https://www.r-bloggers.com/2017/07/shiny-chat-in-few-lines-of-code-2/
render_msg_fancy <- function(messages, self_username) {
  div(id = "chat-container",
      class = "chat-container",
      messages %>%
        purrrlyr::by_row(~ div(class =  dplyr::if_else(
          .$username == self_username,
          "chat-message-left", "chat-message-right"),
          a(class = "username", .$username),
          div(class = "message", .$message),
          div(class = "datetime", .$datetime)
        ))
      %>% {.$.out}
  )
}
