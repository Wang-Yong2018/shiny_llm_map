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
box::use(knitr[kable],
         markdown[mark_html],
         DiagrammeR[grViz, renderGrViz, grVizOutput])
box::use(logger[log_info, log_debug, log_error])
box::use(purrrlyr[by_row],
         purrr[pluck])
box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
box::use(stats[runif])
box::use(../etl/llmapi[ get_llm_result, check_llm_connection,get_ai_result])
box::use(../etl/chat_api[db_connect, 
                         read_messages, send_message, db_clear])

box::use(../etl/img_tools[resize_image])
box::use(../etl/agent_sql[get_db_schema,get_db_schema_text,get_dbms_name,
                          get_sql_prompt,get_gv_string])
# language config
box::use(../global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list,
                           db_id_list])
box::use(../etl/agent_router[get_agent_result])

box::use(shiny.i18n[Translator])

i18n<- Translator$new(translation_csvs_path = "./translation/")
i18n$set_translation_language(app_language)


#' @export
ui <- function(id, label='sql_llm'){
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      column(width=6,
             style = "height: 300px;overflow-y: scroll; border: 1px solid black; padding: 10px;",
             textAreaInput(
               inputId = ns('prompt'),
               label = i18n$translate('Prompt'),
               value= i18n$translate(''),
               placeholder = i18n$translate('Enter Prompts Here') )
      ),
      column(width=6,
             #style = 'border: solid 1px black; min-height: 100px;',     
             style = "height: 300px;overflow-y: scroll; border: 1px solid black; padding: 10px;",
             uiOutput(ns('sql_query')) 
      )
    ),
    fluidRow(
      column(width=3,
             actionButton(ns('goButton'), i18n$translate('ask ai')) ),
      column(width=3,selectInput(ns('model_id'),
                                 label= i18n$translate('model list'),
                                 choices=model_id_list,
                                 multiple=FALSE,
                                 selected='gpt')),
      column(width=3,selectInput(ns('db_id'),
                                 label= i18n$translate('database list'),
                                 choices=db_id_list,
                                 multiple=FALSE,
                                 selected=db_id_list[1]))
      ),
    fluidRow(
      column(width=6,
             # style = 'border: solid 1px black; min-height: 300px;',  
             style = "height: 400px; overflow-y: scroll; border: 1px solid black; padding: 10px;",
             uiOutput(ns('system_prompt'))),
      column(width=6,
             # style = 'border: solid 1px black; min-height: 300px;',  
             style = "min-height: 400px; overflow-y: scroll; border: 1px solid black; padding: 10px;",
             grVizOutput(ns('graph_erd'))
      
    ) 
  ))
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
    
 
    get_reactive_sql_prompt <- reactive({
      get_sql_prompt(input$db_id, input$prompt)
    })
    
    output$system_prompt <- renderText({
      get_reactive_sql_prompt() |>
      gsub(pattern= '\n', replacement = '<br />', x=_)
      
    })
    
    # get_reactive_gv <- reactive({
    #   gv_string <- get_gv_string(db_id = input$db_id, 
    #                 model_id = input$model_id ) 
    #   return(gv_string)
    # })
    
    output$graph_erd <- renderGrViz({
      
      file_name <- switch(input$db_id,
                          chinook = './data/chinook.gv',
                          cyd = './data/cyd.gv')
    
      grViz(file_name ,width = "100%", height = "100%")
    })

    observeEvent(input$goButton, {
      output$sql_query<- renderText({
        log_debug(paste0(' input is :',input$prompt))
        
        message <-  get_llm_result(prompt=get_reactive_sql_prompt(),
                                   model_id=input$model_id,
                                   llm_type = 'chat')
        
        if (is.null(message)){
          message <- 'failed to detect!!!'
        }else{
          print(message)
          ai_message <- get_ai_result(message,ai_type='sql_query')   
          log_debug('ai_result===', ai_message)
          sql_result <- 
            get_agent_result(ai_message) |>
            kable()|>
            mark_html()
        }
        log_debug(paste0(' output is :',sql_result))
        
        return(sql_result)
      })
    })
    
  })}