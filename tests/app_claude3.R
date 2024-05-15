# Install and load required packages
# install.packages("httr")
# install.packages("jsonlite")
# install.packages("DBI")
# install.packages("RSQLite")
# install.packages("shiny")
library(httr)
library(jsonlite)
library(DBI)
library(RSQLite)
library(shiny)

# Set up the API endpoint and your API key
api_endpoint <- "https://openrouter.ai/api/v1/chat/completions"
api_key <- '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'

# Function to send a request to the ChatGPT API
send_request <- function(prompt, max_tokens = 50, temperature = 0.7) {
  request_body <- list(
    prompt = prompt,
    max_tokens = max_tokens,
    temperature = temperature
  )
  
  response <- POST(
    api_endpoint,
    add_headers(Authorization = paste("Bearer", api_key)),
    body = request_body,
    encode = "json"
  )
  
  if (status_code(response) == 200) {
    response_text <- content(response, "text")
    response_data <- fromJSON(response_text)
    return(response_data$choices$text[1])
  } else {
    stop("Error: ", status_code(response), " - ", content(response, "text"))
  }
}

# Function to convert text to SQL query
text_to_sql <- function(text) {
  prompt <- paste("Convert the following text to an SQL query:\n", text)
  sql_query <- send_request(prompt)
  return(sql_query)
}

# Shiny UI
ui <- fluidPage(
  titlePanel("AI Agent with Text to SQL"),
  sidebarLayout(
    sidebarPanel(
      textAreaInput("user_input", "User Input:", rows = 5),
      actionButton("send_button", "Send")
    ),
    mainPanel(
      verbatimTextOutput("ai_response"),
      verbatimTextOutput("sql_query")
    )
  )
)

# Shiny Server
server <- function(input, output) {
  # Reactive expression for AI agent response
  ai_response <- eventReactive(input$send_button, {
    user_input <- input$user_input
    send_request(user_input)
  })
  
  # Reactive expression for SQL query
  sql_query <- eventReactive(input$send_button, {
    user_input <- input$user_input
    text_to_sql(user_input)
  })
  
  # Output for AI agent response
  output$ai_response <- renderText({
    paste("AI Agent:", ai_response())
  })
  
  # Output for SQL query
  output$sql_query <- renderText({
    paste("SQL Query:", sql_query())
  })
}

# Run the Shiny app
shinyApp(ui = ui, server = server)
