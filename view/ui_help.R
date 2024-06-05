box::use(shiny[NS,
               moduleServer, 
               h2,h3,tagList,div,a,
               fluidPage, fluidRow, column,mainPanel,
               tags,
               titlePanel,
               uiOutput, renderUI,
               textInput, textOutput,
               renderText, renderImage, plotOutput,markdown,
               selectInput,
               textAreaInput,
               actionButton,
               hr, HTML,includeMarkdown,
               reactiveValues, observe, observeEvent,reactive,
               fileInput,imageOutput,
]) 

box::use(shinycssloaders[withSpinner])
box::use(logger[log_info, log_debug, log_error])
box::use(purrrlyr[by_row],
         purrr[pluck])
box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
box::use(stats[runif])
box::use(../etl/llmapi[ get_llm_result, check_llm_connection,get_ai_result])
box::use(../etl/chat_api[db_connect, 
                         read_messages, send_message, db_clear])

box::use(../etl/img_tools[resize_image])

# language config
box::use(../global_constant[app_name,app_language, i18n,
                            img_vision_prompt, 
                            model_id_list,vision_model_list ])


#' @export
ui <- function(id, label='help'){
  ns <- NS(id)
  
  fluidPage(
    titlePanel("Getting Start"),
    mainPanel(uiOutput(ns("markdown")))
    )
}


#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    output$markdown <- renderUI({
      includeMarkdown("README.md")
    })
    
  })}