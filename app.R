library(shiny)
library(httr)
library(jsonlite)
source('llmapi.R')
source('chat_api.R')
# Function to call Gemini API
gemini <- function(prompt, temperature = 0.5, max_output_tokens = 1024) {
  # Replace with your own API key
  api_key <- Sys.getenv('gemini_api_key')
  model <- "gemini-pro"  # Choose the appropriate model
  
  url <- paste0("https://api.labs.google.com/v1/text-generation/generate",
                "?prompt=", prompt,
                "&temperature=", temperature,
                "&max_output_tokens=", max_output_tokens,
                "&model=", model)
  
  headers <- add_headers(Authorization = paste("Bearer", api_key))
  
  res <- GET(url, headers = headers)
  content <- content(res, as = "character")
  data <- fromJSON(content)
  return(data$generations[[1]]$text)
}

# Define UI for basic chat application
ui <- fluidPage(
  id = "chatbox-container",
  
  tags$head(
    tags$script(src = "script.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styling.css")
  ),
  
  # Application title
  titlePanel("简单聊天机器人-shiny&geminy"),
  
  uiOutput("messages_fancy"),
  
  tags$div(textInput("msg_text", label = NULL),
           actionButton("msg_button", "发送", height="30px"),
           style="display:flex"),
  
  hr(),
  
  textInput("msg_username", "用户名:", value = "八卦之人"),
  actionButton("msg_clearchat", "清除对话")
)

# Server logic for basi cchat
server <- function(input, output) {
  
  # update username to use random numbers
  shiny::updateTextInput(inputId = "msg_username",
                         value = paste0("八卦之人", round(runif(n=1, min=1000000,max = 10000000)),'号'))
  
  # convert time to numeric with 2 decimal degrees precision, need to divide by 100 again later
  # Sys.time( ) %>% format("%s%OS2") %>% as.numeric() %>% `/`(100) %>% as.POSIXct(origin = "1970-01-01") %>% format("%s%OS2") %>% as.numeric()
  message_db_schema <- dplyr::tibble(username = character(0),
                                     #datetime = Sys.time()[0], # if you want POSIXct data instead
                                     #datetime = numeric(0),    # if you want to store datetimes as numeric
                                     datetime = character(0),   # we're taking the easy way here
                                     message = character(0))
  
  con <- db_connect(message_db_schema)
  
  # set up our messages data locally
  messages_db <- reactiveValues(messages = read_messages(con))
  
  # look for new messages every n milliseconds
  db_check_timer <- shiny::reactiveTimer(intervalMs = 1000)
  
  observe({
    db_check_timer()
    if (debug) message("checking table...")
    messages_db$messages <- read_messages(con)
    
  })
  
  # button handler for chat clearing
  observeEvent(input$msg_clearchat, {
    if (debug) message("clearing chat log.")
    
    db_clear(con, message_db_schema)
    
    messages_db <- reactiveValues(messages = read_messages(con))
    
  })
  
  # button handler for sending a message
  observeEvent(input$msg_button, {
    if (debug) message(input$msg_text)
    
    # only do anything if there's a message
    if (!(input$msg_text == "" | is.null(input$msg_text))) {
      
      msg_time <- Sys.time( ) %>%
        as.character()|>
        substr(6,19)
      
      new_message <- dplyr::tibble(username = input$msg_username,
                                   message = input$msg_text,
                                   datetime = msg_time)
      
      send_message(con, new_message)
      
      messages_db$messages <- read_messages(con)
      
      # clear the message text
      shiny::updateTextInput(inputId = "msg_text",
                             value = "")
    }
  })
  
  # render the chat data using a custom function
  output$messages_fancy <- shiny::renderUI({
    render_msg_fancy(messages_db$messages, input$msg_username)
  })
  
}



# Run the application
shinyApp(ui = ui, server = server)