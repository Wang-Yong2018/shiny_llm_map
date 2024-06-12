box::use(shiny[NS,
               moduleServer, 
               h2,h3,tagList,div,a, tags, hr,
               fluidPage, fluidRow, column,
               tabsetPanel,tabPanel,
               titlePanel,
               selectInput, textInput, textOutput,
               textAreaInput,updateTextAreaInput, 
               renderText, renderImage, plotOutput,markdown,
               actionButton,
               reactiveValues, observe, observeEvent,reactive,
               fileInput,imageOutput,
               uiOutput, renderUI,
               bindCache])
box::use(shinycssloaders[withSpinner])
box::use(knitr[kable],
         markdown[mark_html],
         DiagrammeR[grViz, renderGrViz, grVizOutput],
         DT[renderDataTable],
         jsonlite[toJSON,fromJSON])

box::use(logger[log_info, log_debug, log_error])
box::use(purrrlyr[by_row],
         purrr[pluck])
box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
box::use(stats[runif])
box::use(../etl/llmapi[ get_llm_result, check_llm_connection,get_ai_result])
box::use(../etl/chat_api[db_connect, 
                         read_messages, send_message, db_clear])

# language config
box::use(../global_constant[app_name,app_language, i18n,
                           img_vision_prompt,MAX_TOKENS, 
                           model_id_list,vision_model_list,sql_model_id_list,
                           db_id_list])
box::use(../etl/img_tools[resize_image])
box::use(../etl/agent_sql[get_sql_prompt,get_gv_string,get_db_schema_text,get_db_catalog])
box::use(../etl/agent_router[get_agent_result])
box::use(jsonlite[fromJSON, toJSON],
         stringr[str_glue])

# box::use(shiny.i18n[Translator])
# 
# i18n<- Translator$new(translation_csvs_path = "./translation/")
# i18n$set_translation_language(app_language)


#' @export
ui <- function(id, label='sql_llm'){
  ns <- NS(id)
  
  fluidPage(fluidRow(
    column(
      width = 6,
      style = "height: 200px;overflow-y: scroll; border: 1px solid black; padding: 10px;",
      textAreaInput(
        inputId = ns('prompt'),
        label = i18n$translate('Prompt'),
        value = i18n$translate(''),
        placeholder = i18n$translate('Tell AI, you role and your question '),
        width = '100%',
        rows = 8
      )
    ),
    column(
      width = 6,
      actionButton(ns('goButton'), i18n$translate('Ask Agent'), style = "color: blue;") ,
      selectInput(
        ns('model_id'),
        label = i18n$translate('model list'),
        choices = sql_model_id_list,
        multiple = FALSE,
        selected = 'gpt'
      ),
      selectInput(
        ns('db_id'),
        label = i18n$translate('database list'),
        choices = db_id_list,
        multiple = FALSE,
        selected = NULL
      )
    )
  ), fluidRow(
    tabsetPanel(
      tabPanel(i18n$translate('Evaluate'), withSpinner(uiOutput(ns(
        'evaluation'
      )))),
      tabPanel(i18n$translate('Data'), withSpinner(uiOutput(ns(
        'sql_result'
      )))),
      tabPanel(
        i18n$translate('Context'),
        textAreaInput(
          ns('system_prompt'),
          label = ' system prompt',
          placeholder = '',
          rows = 50
        )
      ),
      tabPanel(i18n$translate('Catalog'), withSpinner(uiOutput(ns(
        'catalog'
      )))),
      tabPanel(i18n$translate('AI_sql'), withSpinner(uiOutput(ns(
        'sql_query'
      )))),
      selected = i18n$translate('Evaluate'),
      
    )
  )
  
    
 )}


#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
   
 
    get_reactive_sql_prompt <- reactive({
      sql_query <-  get_sql_prompt(input$db_id, input$prompt)
    })
    
    get_reactive_evaluation <- reactive({
      db_content <- get_db_schema_text(input$db_id)
      evaluation_prompt_template  <- i18n$translate(
        'As business analysis pls analyze the following database schema and evaluate the business value and opportunities'
      )
      
      evaluation_prompt = paste0(evaluation_prompt_template, '\n', db_content)
      ai_evaluation <- get_llm_result(prompt = evaluation_prompt, model_id =
                                        input$model_id) |>
        get_ai_result(ai_type = 'chat')
      
      log_debug(paste0('ai data_base evaluation result ai_evaluation', ai_evaluation))
      log_debug(ai_evaluation)
      ai_evaluation |>
        pluck('content') |> markdown()
    }) |> bindCache(input$db_id, input$model_id)
    
    
    
    # TODO split get sql message in to get_ai_messag / get_sql_message
    get_sql_message <- reactive({
      log_debug(paste0(' input is :', input$prompt))
      message <-  get_llm_result(
        prompt = get_reactive_sql_prompt(),
        model_id = input$model_id,
        llm_type = 'sql'
      )
      
      result <- ''
      if (is.null(message) | grepl('ERROR|error', toJSON(message))) {
        print(result)
        result <-
          paste0(
            'You answer can not be answered. Pls \n 1. check the AI_SQL for more clue. \n2. revise your question.\n',
            'The detail database error message is followed:\n',
            '--',
            message
          )
        
        
      } else{
        sql_parameter <- list(db_id = input$db_id)
        ai_sql_message <- get_ai_result(message, ai_type = 'sql_query', sql_parameter)
        print(ai_sql_message)
        sql_message <-
          get_agent_result(ai_sql_message)
        result <- sql_message
      }
      return(result)
    }) |> bindCache(input$db_id, input$model_id, input$prompt)
    
    observeEvent(input$db_id, {
      new_prompt <- get_reactive_sql_prompt()
      output$evaluation <- renderUI({
        get_reactive_evaluation()
      })
      updateTextAreaInput(session, 'system_prompt', value = new_prompt)
    })
    
    
    output$catalog <- renderUI(renderDataTable({
      db_catalog_df <- get_db_catalog(input$db_id)
      print(db_catalog_df)
      return(db_catalog_df)
    }))
    

    observeEvent(input$goButton,
                 {
                   sql_message <- get_sql_message()
                   #log_info(paste('the final sql_message (query, result) is ====>',sql_message))
                   
                   output$sql_query  <- renderText({
                     log_debug(sql_message)
                     query_sql <- sql_message |> pluck('query')
                     query_model_id <- sql_message |> pluck('model_id')
                     query_db_id <- sql_message |> pluck('db_id')
                     
                     if (is.null(query_sql)) {
                       query_sql <- sql_message |> toJSON(pretty = T, auto_unbox = T)
                     }
                     # todo use pluck to return null, if expect key no exist. It help to skip error bug
                     
                     format_db_id <- paste0('\n --- database id is ', query_db_id)
                     format_model_id <- paste0('\n--- llm model id is :', query_model_id)
                     sql_message <-
                       paste(query_sql, format_db_id, format_model_id, sep = '\n') |>
                       gsub(pattern = '\n', replacement = '<br />')
                     
                   })
      
                   
                   output$sql_result <- renderUI({
                     sql_result <- sql_message |> pluck('result')
                     is_data.frame <- class(sql_result) |> grepl('data.frame', x = _) |> any()
                     if (is_data.frame == TRUE) {
                       if (nrow(sql_result) > 0) {
                         renderDataTable(sql_result, options = list(pageLength = 20))
                       } else{
                         renderText('No thing found, pls check the ai-sql and revise your question')
                       }
                     } else {
                       renderText(sql_result)
                     }
                   }) 
      
    })
    
    })}