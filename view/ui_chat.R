box::use(shiny[NS,
               moduleServer, 
               h2,h3,tagList,div,a,
               fluidPage, fluidRow, column,
               plotOutput,
               renderImage,
               tags,
               titlePanel,
               uiOutput,
               textInput, textOutput,
               selectInput,
               textAreaInput,
               actionButton,
               hr,
               reactiveValues, observe, observeEvent,reactive
               ])
box::use(logger[log_info, log_warn, 
                log_debug, log_error,
                log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])

box::use(../etl/chat_api[db_connect, 
                         read_messages, send_message, db_clear])
box::use(../etl/llmapi[ get_llm_result, check_llm_connection,
                        llm_chat,
                        get_ai_result,
                        get_chat_history,])
box::use(purrrlyr[by_row],
         purrr[pluck])
box::use(../global_constant[app_name,app_language, i18n,
                            img_vision_prompt, 
                            model_id_list,vision_model_list,
                            db_id_list])
box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
box::use(shiny.i18n[Translator])
# i18n<- Translator$new(translation_csvs_path = "./translation/")
# i18n$set_translation_language(app_language)
box::use(cachem[cache_mem])
history <- cache_mem()

box::use(stats[runif])
# function to render SQL chat messages into HTML that we can style with CSS
# inspired by:
# https://www.r-bloggers.com/2017/07/shiny-chat-in-few-lines-of-code-2/

render_msg_fancy <- function(messages, self_username) {
  fancy_msg <- 
    messages|> 
    by_row(~ div(class =  if_else(
      .$username == self_username,
      "chat-message-left", "chat-message-right"),
      a(class = "username", .$username),
      div(class = "message", .$message),
      div(class = "datetime", .$datetime)
    )) |>
    pluck('.out')
  
  div(id = "chat-container",
      class = "chat-container",
      fancy_msg)
}



#' @export
ui <- function(id, label='chat_llm'){
  ns <- NS(id)

  fluidPage(
     tags$head(
        tags$script(src = "script.js"),
        tags$link(rel = "stylesheet", type = "text/css", href = "styling.css")
      ),

    #Application title

    #tags$div(uiOutput(ns("messages_fancy"))),
    #tags$div(textOutput(ns('messages_fany'))),
    fluidRow(
     id = "chatbox-container",
     uiOutput(ns("messages_fancy"))
      
    ),
    fluidRow(
      column(width=7,
             tags$div(textAreaInput(ns("msg_text"),
                                    label = NULL
             ) )),
      column(width=2,selectInput(ns('model_id'),
                                 label= i18n$translate('model list'),
                                 choices=model_id_list,
                                 multiple=TRUE,
                                 selected=model_id_list[1])),
      column(width=2,
             actionButton(ns("msg_button"),
                          "发送" ),
             style="display:flex")

      ),
    fluidRow(
      column(width=3,
             textInput(ns("msg_username"), "用户名:", value = "八卦之人" )
             ),
      column(width=2,
             actionButton(ns("msg_clearchat"), "清除对话")
             )
    )

    
)}


#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session,chat_history=NULL) {
    shiny::updateTextInput(inputId = "msg_username",
                           value = paste0("八卦之人",
                                          round(runif(n=1, min=1000,max = 9999)),'号'))
    
    con <- db_connect(model_db='gemini')
    
    # set up our messages data locally
    messages_db <- reactiveValues(messages = read_messages(con))
    
    # look for new messages every n milliseconds
    db_check_timer <- shiny::reactiveTimer(intervalMs = 1000)
    
    observe({
      db_check_timer()
    #  if (debug) message("checking table...")
      messages_db$messages <- read_messages(con)
      
    })
    
    # button handler for chat clearing
    observeEvent(input$msg_clearchat, {
    #  if (debug) message("clearing chat log.")
      db_clear(con)
      messages_db <- reactiveValues(messages = read_messages(con))
    })
    
    # button handler for sending a message
    observeEvent(input$msg_button, {
    # if (debug) message(input$msg_text)
    # only do anything if there's a message
      if (!(input$msg_text == "" | is.null(input$msg_text))) {
        send_message(con, 
                     sender=input$msg_username, 
                     content=input$msg_text)
        # Reactive expression to return selected values
        
         for (id in input$model_id) {
           # llm_answer <- get_llm_result(prompt=input$msg_text,
           #                              model_id = id)
           if (!history$exists('chat_history')){
             last_history<-NULL
           }else{ 
             last_history <- history$get('chat_history')
             }
           
           ai_response <- get_llm_result(prompt=input$msg_text, 
                                    model_id=id,
                                    history = last_history) 
           #TODO extract response info and build new history
           last_history <- get_chat_history(input$msg_text,role='user',last_history=last_history)
           ai_message <- get_ai_result(ai_response)
           new_history <- get_chat_history(message=ai_message$content,
                                           role=ai_message$role, 
                                           last_history=last_history) 
            
           history$set('chat_history',new_history)
           
           log_debug("**********************")
           log_debug(paste0('the chat history is ===>', chat_history))
           log_debug(paste0('the ai_message ---->',ai_message))
           log_debug(paste0('the new history is ----->',new_history))
           llm_answer <- ai_message$content
           
           send_message(con, 
                        sender=id,
                        content=llm_answer)
           
           messages_db$messages <- read_messages(con)
           
         }
        # clear the message text
        shiny::updateTextInput(inputId = "msg_text",
                               value = "")
      }
    })
    
    # render the chat data using a custom function
    output$messages_fancy <- shiny::renderUI({
      render_msg_fancy(messages_db$messages,
                       input$msg_username)
    })
  })}