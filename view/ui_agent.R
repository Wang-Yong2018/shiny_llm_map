box::use(shiny[NS,
               moduleServer, 
               h2,h3,tagList,div,a,
               fluidPage, fluidRow, column,
               plotOutput,
               renderImage,
               tags,
               titlePanel,
               uiOutput,renderPrint,
               textInput, textOutput,verbatimTextOutput,
               selectInput,
               textAreaInput,
               actionButton,
               hr,
               reactiveValues, observe, observeEvent,reactive
               ])

box::use(../etl/chat_api[db_connect, 
                         read_messages, send_message, db_clear])
box::use(../etl/llmapi[ get_llm_result,
                        check_llm_connection,
                        #llm_chat,
                        get_ai_result])
box::use(purrrlyr[by_row],
         purrr[pluck,map_chr, keep])
box::use(../global_constant[app_name,model_id_list,app_language])
box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
box::use(cachem[cache_mem])
box::use(jsonlite[read_json, toJSON,fromJSON])
history <- cache_mem()
box::use(shiny.i18n[Translator])
i18n<- Translator$new(translation_csvs_path = "./translation/")
i18n$set_translation_language(app_language)

box::use(stats[runif])
all_funcs_json <- read_json('./data/tools_config.json',simplifyVector = F)
func_chinese_name <-   all_funcs_json|> map_chr(pluck('chinese_name'))




#' @export
ui <- function(id, label='agent_llm'){
  ns <- NS(id)

  fluidPage(
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
              textAreaInput(inputId = ns("prompt"), 
                            label = "prompt_input:", rows = 2, cols = 30)
       ),
       column(width=1),
       column(width=6,
              style = 'border: solid 0.1px grey; min-height: 100px;',  
              textOutput(inline=TRUE,
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
  moduleServer(id, function(input, output, session,chat_history=NULL) {
    
    # based on the selectInput to the function definiton
    get_func_definition <- reactive(
      all_funcs_json |> 
        keep(function(x) pluck(x, 'chinese_name') == input$func_selector) 
    )
    output$txt_json_config <-renderPrint({
      json_config <- get_func_definition()|>
      toJSON(auto_unbox = T, pretty=T)
      print(json_config)
      return(json_config) 
    })
    
    output$txt_json_feedback <- renderText({ 'this is json feedback' })
    
    observeEvent(input$goButton, {
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
    }) 
    
    # render the chat data using a custom function
    
  })}