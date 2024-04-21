library(shiny)
library(httr)
library(jsonlite)
source('llmapi.R')

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

# Shiny UI
ui <- fluidPage(
  titlePanel("Gemini Chatbox"),
  sidebarLayout(
    sidebarPanel(
      textInput("userInput", "Talk to Gemini!", width = "100%")
    ),
    mainPanel(
      verbatimTextOutput("response")
    )
  )
)

# Shiny server logic
server <- function(input, output) {
  output$response <- renderText({
    if (nchar(input$userInput) > 0) {
      #gemini(input$userInput)
      input_text <- input$userInput
      fast_get_llm_result(prompt = input_text)
    } else {
      "Ask me anything!"
    }
  })
}

# Run the app
shinyApp(ui = ui, server = server)
