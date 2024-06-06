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
               textAreaInput,
               actionButton,
               hr,
               reactiveValues, observe, observeEvent,
               ])

box::use(../etl/chat_api[db_connect, 
                         read_messages, send_message,db_clear])
box::use(purrrlyr[by_row],
         purrr[pluck])
box::use(../global_constant)
box::use(dplyr[tibble, if_else,copy_to,tbl, collect])
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
ui <- function(id, label='chat_echo'){
  ns <- NS(id)

  fluidPage(
     tags$head(
        tags$script(src = "script.js"),
        tags$link(rel = "stylesheet", type = "text/css", href = "styling.css")
      ),

    #Application title
    #titlePanel(ns("chat_echo")),

    #tags$div(uiOutput(ns("messages_fancy"))),
    #tags$div(textOutput(ns('messages_fany'))),
    fluidRow(
     id = "chatbox-container",
        uiOutput(ns("messages_fancy"))
      
    ),
    fluidRow(
      column(width=7,
             tags$div(textAreaInput(ns("msg_text"),
                                    label = NULL,
                                    width='800px',
                                    height='60px',
             ) )),
      column(width=2,
             actionButton(ns("msg_button"),
                          i18n$translate('ask ai'),
                          height="30px"),
             style="display:flex; color: blue;"),
      hr()
      ),
    fluidRow(
      column(width=3,
             textInput(ns("msg_username"), i18n$translate('user name'), value = i18n$translate('stranger'))
             ),
      column(width=2,
             actionButton(ns("msg_clearchat"),
                          i18n$translate('clean chat'),
                          style = "color: blue;")
             )
    )

    
)}


#' @export
server <- function(id) {
  
  moduleServer(id, function(input, output, session) {
    shiny::updateTextInput(inputId = "msg_username",
                           value = paste0("八卦之人", round(runif(n=1, min=1000,max = 9999)),'号'))
    
    con <- db_connect(model_db='echo')
    
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
   #   if (debug) message(input$msg_text)
      
      # only do anything if there's a message
      if (!(input$msg_text == "" | is.null(input$msg_text))) {
        send_message(con, sender=input$msg_username, content=input$msg_text)
        
        messages_db$messages <- read_messages(con)
        
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