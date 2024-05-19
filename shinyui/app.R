#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(jsonlite)
library(purrr)
source('../etl/llmapi.R')
all_funcs_json <- read_json('../data/tools_config.json',simplifyVector = F)
func_chinese_name <-   all_funcs_json|> map_chr(pluck('chinese_name'))

# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel("LLM agent playgroud"),
  #ns <- NS(id),
  tags$head(
    tags$script(src = "script.js"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styling.css")
  ),
  #Sidebar with a slider input for number of bins
  fluidRow(
    id = "chatbox-container",
    column(width= 5,
         #  style = 'border: solid 0.1px grey; min-height: 100px;',  
         textAreaInput("prompt", label = "prompt_input:", rows = 2, cols = 30)
    ),
    column(width=1),
    column(width=6,
           style = 'border: solid 0.1px grey; min-height: 100px;',  
           textOutput(inline=TRUE,
                      #label = 'AI feedback',
                      outputId = 'ai_output'#,value = 'AI feedback'
           )
    )
),
  fluidRow(
    column(
      width=6,
      actionButton( #ns('goButton'),
        'goButton',
        'ask ai'
        #i18n$translate('ask ai'))
      )
    )
  ),

  fluidRow(
    column(
      width = 2,
      selectInput( #ns('func_selector'),
        'func_selector',
        label = '代理清单',
        choices = func_chinese_name,
        selected= func_chinese_name[1]
       )
    ),
    column(
      width = 2,
      selectInput( #ns('model_name'),
        'model_id',
        label = '可用模型清单',
        choices = c('gpt35', 'gpt4', 'gemini', 'llama'),
        selected = 'gpt35' )
    )
  
  ),
  fluidRow(
    column(width= 6,
           style = 'border: solid 0.1px grey; min-height: 100px;', 
           verbatimTextOutput(
             #ns('txt_json_config'),
             'txt_json_config'#, value = 'hi,this for show the json function definition'
           )
    ),
    column(width=6,
           style = 'border: solid 0.1px grey; min-height: 100px;',  
           uiOutput(
             #ns('txt_json_feedback'),
             'txt_json_feedback'#, value = 'hi, this for show the json parameter from LLMAI'
           )
    )
    
  ),
  fluidRow(

    )
  )


# Define server logic required to draw a histogram
server <- function(input, output,session) {
  
  # get all function definition json config only load once.
  
  # get all functions chinese name

  
  # based on the selectInput to the function definiton
  get_func_definition <- reactive(
    all_funcs_json |> 
      keep(function(x) pluck(x, 'chinese_name') == input$func_selector) |>
      toJSON(auto_unbox = T, pretty=T)
  )
  output$txt_json_config <-renderPrint({
    get_func_definition()
    })

  output$txt_json_feedback <- renderText({ 'this is json feedback' })
  output$ai_output<- renderText({
    message <-  get_llm_result(prompt=input$prompt,
                               #img_url=input$file$datapath,
                               model_id=input$model_id,
                               llm_type = 'agent',
                               funcs_json = get_func_definition())
    
    
    if (is.null(message)){
      message <- 'failed to detect!!!'
    }else{
      print(message)
      ai_message <- 
        get_ai_result(message,ai_type='agent')  |>
        toJSON(pretty=T,auto_unbox = T)
      
      fancy_vision_message = markdown(ai_message$content)
    }
    print("**************************")
    print(paste0(' output is :',fancy_vision_message))
    
    return(fancy_vision_message)
    })
}

# Run the application
shinyApp(ui = ui, server = server)
