box::use(shiny[NS,
               moduleServer, 
               h2,h3,tagList,div,a,
               fluidPage, fluidRow, column,
               plotOutput,
               renderImage,
               tags,
               titlePanel,
               renderPrint,renderText, markdown,
               textInput, textOutput,verbatimTextOutput,
               selectInput,
               textAreaInput,
               actionButton,
               hr,
               reactiveValues, observe, observeEvent,reactive,
               uiOutput, renderUI ])
box::use(logger[log_info, log_warn,  log_debug, log_error, log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])
box::use(../etl/chat_api[db_connect, 
                         read_messages, send_message, db_clear])
box::use(../etl/llmapi[ get_llm_result,
                        check_llm_connection,
                        #llm_chat,
                        get_ai_result])
box::use(purrrlyr[by_row],
         purrr[pluck,map_chr, keep])
box::use(../global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list,i18n ])
box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
box::use(cachem[cache_mem])
box::use(jsonlite[read_json, toJSON,fromJSON])
history <- cache_mem()
# box::use(shiny.i18n[Translator])
# i18n<- Translator$new(translation_csvs_path = "./translation/")
# i18n$set_translation_language(app_language)

box::use(stats[runif])
box::use(../etl/agent_router[get_agent_result])


all_funcs_json <- read_json('./data/tools_config.json',simplifyVector = F)
func_chinese_name <-   all_funcs_json|> map_chr(pluck('chinese_name'))




#' @export
ui <- function(id, label='agent_llm'){
  ns <- NS(id)

  fluidPage(
     tags$head(
       tags$script(src = "script.js"),
       tags$link(rel = "stylesheet", type = "text/css", href = "styling.css")
     ),
     #Sidebar with a slider input for number of bins
     fluidRow(
       id = "chatbox-container",
       column(width= 5,
              #  style = 'border: solid 0.1px grey; min-height: 100px;',  
              textAreaInput(inputId = ns("prompt"), 
                            label = "prompt_input:", rows = 2, cols = 30)
       ),
       column(width=1),
       column(width=6,
              style = 'border: solid 0.1px grey; min-height: 100px;',  
              uiOutput(
                         #label = 'AI feedback',
                         outputId = ns('ai_output')#,value = 'AI feedback'
              )
       )
     ),
     fluidRow(
       column( width=6,
               actionButton( ns('goButton'), i18n$translate('ask ai')) 
               )
     ),
     
     fluidRow(
       column(
         width = 2,
         selectInput(inputId =   ns('func_selector'),
           #'func_selector',
           label = '代理清单',
           choices = func_chinese_name,
           selected= func_chinese_name[1]
         )
       ),
       column(
         width = 2,
         selectInput(inputId =  ns('model_id'),
          # 'model_id',
           label = '可用模型清单',
           choices =model_id_list,
           selected = 'gpt35' )
       )
       
     ),
     fluidRow(
       column(width= 6,
              style = 'border: solid 0.1px grey; min-height: 100px;', 
              verbatimTextOutput(
                outputId = ns('txt_json_config'),
                #'txt_json_config'#, value = 'hi,this for show the json function definition'
              )
       ),
       column(width=6,
              style = 'border: solid 0.1px grey; min-height: 100px;',  
              uiOutput(
                outputId = ns('txt_json_feedback'),
                #'txt_json_feedback'#, value = 'hi, this for show the json parameter from LLMAI'
              )
       )
       
     )
    
)}


#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # based on the selectInput to the function definiton
    # 
    # get_func_definition <- reactive({
    #   all_funcs_json |> 
    #     keep(function(x) pluck(x, 'chinese_name') == input$func_selector) 
    # })
    # 
    # output$txt_json_config <- renderPrint({
    #   
    #   json_config <- 
    #     get_func_definition()|>
    #     toJSON(auto_unbox = T, pretty=T)
    #   
    #   print(json_config)
    #   return(json_config) 
    # })
    # 
    get_func_definition <- reactive({
      #print(input$func_selector)
      result <- all_funcs_json |> 
        keep(function(x) pluck(x, 'chinese_name') == input$func_selector)
    })
    
    output$txt_json_config <-renderPrint({
      
      get_func_definition() |>
        toJSON(auto_unbox = T, pretty=T)
    })
    observeEvent(input$goButton, {
      
      #ai_message <- get_reactive_ai_answer()
      func_json <- get_func_definition()
      ai_message <-  
        get_llm_result(prompt=input$prompt,
                       #img_url=input$file$datapath,
                       model_id=input$model_id,
                       llm_type = 'agent',
                       funcs_json = func_json)|>
        get_ai_result(ai_type='agent') 
      
      output$ai_output<- renderUI({
        ai_message|> 
          pluck('content')
        
      })
      
      
      output$txt_json_feedback <- renderPrint({
        func_result <- 'no support! only chatgpt interface compatible'
        if (grepl('gpt',input$model_id)){
          func_result <-  get_agent_result(ai_message)|>
            gsub(pattern='\n',
                 replacement='<br />')|>
            markdown()
          log_debug(paste0('the output of func_result is ===>', func_result))
        }
        
        return(func_result)
        
      })
    }) 
    

    # render the chat data using a custom function
    
  })}