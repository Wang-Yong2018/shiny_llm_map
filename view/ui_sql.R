box::use(shiny[NS,
               moduleServer, 
               h2,h3,tagList,div,a,
               fluidPage, fluidRow, column,
               tags,
               titlePanel,
               uiOutput,
               textInput, textOutput,
               renderText, renderImage, plotOutput,markdown,
               selectInput,
               textAreaInput,
               actionButton,
               hr,
               reactiveValues, observe, observeEvent,reactive,
               fileInput,imageOutput,
])
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
box::use(../global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list ])
box::use(shiny.i18n[Translator])

i18n<- Translator$new(translation_csvs_path = "./translation/")
i18n$set_translation_language(app_language)


#' @export
ui <- function(id, label='sql_llm'){
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      column(width=5,
             textAreaInput(
               inputId = ns('prompt'),
               label = i18n$translate('Prompt'),
               value= i18n$translate(img_vision_prompt),
               placeholder = i18n$translate('Enter Prompts Here') )
      ),
      column(width=5,
             style = 'border: solid 1px black; min-height: 100px;',     
             uiOutput(ns('sql_query')) 
      )
    ),
    fluidRow(
      column(width=5,selectInput(ns('model_id'),
                                 label= i18n$translate('mode list'),
                                 choices=model_id_list,
                                 multiple=FALSE,
                                 selected='gpt')),
      column(width=5,
             actionButton(ns('goButton'), i18n$translate('ask ai')) ),
      
    ) 
  )
  }


#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
   
    output$server_status<- renderText({
      status_code <-'200' #get_server_status_code()
      message <- paste0(
        i18n$translate("server connection:"),
        status_code
      )
      return(message)
    })
    
 
    
    observeEvent(input$goButton, {
      output$sql_query<- renderText({
        log_debug(paste0(' input is :',input$prompt))
        message <-  get_llm_result(prompt=input$prompt,
                                   model_id=input$model_id,
                                   llm_type = 'chat')
        
        if (is.null(message)){
          message <- 'failed to detect!!!'
        }else{
          print(message)
          ai_message <- get_ai_result(message,ai_type='chat')   
          fancy_vision_message = markdown(ai_message$content)
        }
        log_debug(paste0(' output is :',fancy_vision_message))
        
        return(fancy_vision_message)
      })
    })
    
  })}