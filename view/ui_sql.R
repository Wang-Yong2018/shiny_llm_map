box::use(shiny[NS,
               moduleServer, 
               h2,h3,tagList,div,a,
               fluidPage, fluidRow, column,
               tags,
               titlePanel,
               uiOutput,
               textInput, textOutput,updateTextAreaInput,
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
box::use(../etl/agent_sql[get_sql_prompt,get_gv_string])
# language config
box::use(../global_constant[app_name,app_language, i18n,
                           img_vision_prompt, 
                           model_id_list,vision_model_list,sql_model_id_list,
                           db_id_list])
box::use(../etl/agent_router[get_agent_result])

# box::use(shiny.i18n[Translator])
# 
# i18n<- Translator$new(translation_csvs_path = "./translation/")
# i18n$set_translation_language(app_language)


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
               value = '查询年龄最大的三个员工的姓名，出生日期',
               placeholder = i18n$translate('Enter Prompts Here'),
               width='100%',
               rows=10
               )
      ),
      column(width=6,
             style = "height: 300px;overflow-y: scroll; border: 1px solid black; padding: 10px;",
             uiOutput(ns('sql_query')) 
      )
      ),
    fluidRow(
      column(width=3,
             actionButton(ns('goButton'), i18n$translate('ask ai')) ),
      column(width=3,selectInput(ns('model_id'),
                                 label= i18n$translate('model list'),
                                 choices=sql_model_id_list,
                                 multiple=FALSE,
                                 selected='gpt')),
      column(width=3,selectInput(ns('db_id'),
                                 label= i18n$translate('database list'),
                                 choices=db_id_list,
                                 multiple=FALSE,
                                 selected=)
      )),
    fluidRow(
      column(width=12,
             #style = 'border: solid 1px black; min-height: 100px;',     
             style = "height: 300px;overflow-y: scroll; border: 1px solid black; padding: 10px;",
             uiOutput(ns('sql_result')) 
      )
    ),
    fluidRow(
      column(width=6,
             # style = 'border: solid 1px black; min-height: 300px;',  
             style = "height: 400px; overflow-y: scroll; border: 1px solid black; padding: 10px;",
             textAreaInput(
               inputId = ns('system_prompt'),
               label=' system prompt',
               placeholder = 'revise the initial system prompt here',
               width='100%',
               rows=50 )
             ),
      
      column(width=6,
             # style = 'border: solid 1px black; min-height: 300px;',  
             style = "min-height: 400px; overflow-y: scroll; border: 1px solid black; padding: 10px;",
             grVizOutput(ns('graph_erd'))
             ) 
      )
  )
  }


#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
   
 
    get_reactive_sql_prompt <- reactive({
      sql_query <-  get_sql_prompt(input$db_id, input$prompt)
      
     
    })
    
    get_sql_message <- reactive({
      
      log_debug(paste0(' input is :',input$prompt))
      message <-  get_llm_result(prompt=get_reactive_sql_prompt(),
                                 model_id=input$model_id,
                                 llm_type = 'chat')
      
      if (is.null(message)){
        message <- 'failed to detect!!!'
      }else{
        print(message)
        ai_message <- get_ai_result(message,ai_type='sql_query')   
        
        
        ai_sql_message <- list(role=ai_message$role,
                               content=list(name = ai_message|>pluck('content','name'),
                                            arguments= list(db_id =input$db_id,
                                                            sql_query=ai_message|>pluck('content','arguments'),
                                                            model_id=input$model_id )
                                            )
        )
        log_debug(paste0('ai_sql_result===', ai_sql_message,sep='\n'))
        sql_message <- 
          get_agent_result(ai_sql_message)
        # |>
        #   kable()|>
        #   mark_html()
      }
      #log_debug(paste0(' output is :',sql_result))
      #log_info(sql_message) 
      return(sql_message)
    })
    
    observeEvent(input$db_id, {
      new_prompt <-
        get_reactive_sql_prompt() 
      
      updateTextAreaInput(session,'system_prompt', value = new_prompt)
    })
    
    
    output$graph_erd <- renderGrViz({
      
      file_name <- switch(input$db_id,
                          chinook = './data/chinook.gv',
                          cyd = './data/cyd.gv')
    
      grViz(file_name ,width = "100%", height = "100%")
    })


    observeEvent(input$goButton, {
      sql_message <- get_sql_message() 
      #log_info(paste('the final sql_message (query, result) is ====>',sql_message))
      output$sql_query  <- renderText({ 
        sql_query <- sql_message$query
        format_db_id <- paste0('\n --- database id is ',input$db_id)
        format_model_id <- paste0('\n--- llm model id is :',input$model_id)
        sql_message <- 
          paste(sql_query, format_db_id, format_model_id, sep='\n') |>
          gsub(pattern='\n',
               replacement='<br />')
        
        })
      output$sql_result <- renderText({ 
        sql_result <- sql_message$result |>
          kable()|>
          mark_html()
        #log_info(sql_result) 
        sql_result
        })
      
    })
    
  })}