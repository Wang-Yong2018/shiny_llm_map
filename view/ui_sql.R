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
box::use(../etl/db_api[get_db_schema,get_db_schema_text])
# language config
box::use(../global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list,
                           db_id_list])
box::use(knitr[kable])
box::use(../etl/agent_router[get_agent_result])

box::use(shiny.i18n[Translator])

i18n<- Translator$new(translation_csvs_path = "./translation/")
i18n$set_translation_language(app_language)


#' @export
ui <- function(id, label='sql_llm'){
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      column(width=5,
             style = 'border: solid 1px black; min-height: 100px;',   
             textAreaInput(
               inputId = ns('prompt'),
               label = i18n$translate('Prompt'),
               value= i18n$translate(''),
               placeholder = i18n$translate('Enter Prompts Here') )
      ),
      column(width=5,
             style = 'border: solid 1px black; min-height: 100px;',     
             uiOutput(ns('sql_query')) 
      )
    ),
    fluidRow(
      column(width=5,selectInput(ns('model_id'),
                                 label= i18n$translate('model list'),
                                 choices=model_id_list,
                                 multiple=FALSE,
                                 selected='gpt')),
      column(width=5,
             actionButton(ns('goButton'), i18n$translate('ask ai')) ),
      
    ),
    fluidRow(
      column(width=5,selectInput(ns('db_id'),
                                 label= i18n$translate('database list'),
                                 choices=db_id_list,
                                 multiple=FALSE,
                                 selected=db_id_list[1])),
      column(width=5,
             style = 'border: solid 1px black; min-height: 100px;',   
             uiOutput(ns('system_prompt')))

      
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
    
 
    get_system_prompt <- reactive({
      system_prompt <-
        '/*\n
        You are a helpful assistant who answers questions about database tables \n
        by responding with SQL queries.  Users will provide you with a set of \n
        tables represented as CREATE TABLE statements.  Each CREATE TABLE  \n
        statement may optionally be followed by the first few rows from the  \n 
        table in order to help write the correct SQL to answer questions. After 
        the CREATE TABLE statements users will ask a question using a SQL \n
      comment starting with two dashes. You should answer the user question \n
      by writing a pure SQL statement starting with SELECT and ending with a   semicolon.
      constraints: 
      DO: 
       1. For each of query, you can optionaly use the filed which clearly defined in the create table statement.
       2. For each of query, you can optionaly join table for two table has same name.
       3. only output sql query only. It will be used for other agent usage. 
       4. try to use sql language supported by sqlite, postgres
      \n
      */'
      
      
      # As an expert in text to sql, pls read the database tables schema and user question to generate sql query\n
      # 1. database tables definition presented in create table. the table name, field name and field type are defined only in the create table statement\n
      # 2. user input are natural langauge question, \n
      # 3. you answer the question  with sql query, try to use to common table express, with to struction the query.\n
      # 4. output should be markdown format.\n
      # */ \n
      # '
      db_schema_info <- get_db_schema_text(input$db_id)
      paste0( system_prompt, db_schema_info)
    })
    
    output$system_prompt <- renderText({
      get_system_prompt() |>
      gsub(pattern= '\n', replacement = '<br />', x=_)
      
    })
    get_user_prompt <- reactive({
      user_helper_prompt <- '-- Please answer the following question using the tables above: \n'
      user_prompt <-  
        paste(user_helper_prompt, input$prompt)|>
        gsub(pattern= '\n', replacement = '<br />', x=_)
    })
    
    get_sql_prompt<- reactive({
      paste0(get_system_prompt(), get_user_prompt()) 
    }) 
    observeEvent(input$goButton, {
      output$sql_query<- renderText({
        log_debug(paste0(' input is :',input$prompt))
        
        message <-  get_llm_result(prompt=get_sql_prompt(),
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
            kable()
          
          
          fancy_vision_message = markdown(
            paste0(ai_message,
                   '<br />',
                   sql_result)
          )
        }
        log_debug(paste0(' output is :',fancy_vision_message))
        
        return(fancy_vision_message)
      })
    })
    
  })}