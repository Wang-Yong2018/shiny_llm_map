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
ui <- function(id, label='vision_llm'){
  ns <- NS(id)
  
  fluidPage(
    fluidRow(
      column(
        width = 6,
        fileInput(
          inputId = ns('file'),
          label = i18n$translate('Choose file to upload'),
          buttonLabel = i18n$translate('Browse...'),
        )
      ), column(
        width = 6,
        textAreaInput(
          inputId = ns('prompt'),
          label = i18n$translate('Prompt'),
          value = i18n$translate(img_vision_prompt),
          placeholder = i18n$translate('Enter Prompts Here')
        )
        
      )), fluidRow(column(
        width = 6,
        selectInput(
          ns('model_id'),
          label = i18n$translate('vision mode list'),
          choices = vision_model_list,
          multiple = FALSE,
          selected = 'gemini'
        )
      ),
      column(
        width = 6,
        actionButton(ns('goButton'), i18n$translate('ask ai'), style = "color: blue;")
      ),) , 
    fluidRow(
      column(width = 6, div(
        style = 'border: solid 1px black;', imageOutput(
          outputId = ns('image1'),
          width = '50%',
          height = 'auto'
        )
      )),
      column(width = 6, style = 'border: solid 1px black; min-height: 100px;', withSpinner(uiOutput(ns(
        'text1'
      ))))
      
    ), 
  )
}


#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
   
    output$server_status <- renderText({
      status_code <- '200' #get_server_status_code()
      message <- paste0(i18n$translate("server connection:"), status_code)
      return(message)
    })
    
 
    
    observeEvent(input$goButton, {
      output$text1 <- renderText({
        log_debug("\n==========================")
        log_debug(paste0(' input is :',input$prompt))
        message <-  get_llm_result(
          prompt = input$prompt,
          img_url = input$file$datapath,
          model_id = input$model_id,
          llm_type = 'img'
        )
        
        if (is.null(message)) {
          message <- '# failed to detect!!!'
          fancy_vision_message = markdown(message)
        } else{
          ai_message <- get_ai_result(message, ai_type = 'img')
          fancy_vision_message = markdown(ai_message$content)
        }
        
        log_debug(paste0(' output is :',fancy_vision_message))
        
        return(fancy_vision_message)
      })
    })
    
    observeEvent(input$file, {
        img_path <- input$file$datapath
        output$image1 <- renderImage({
        # Use the resized_image function
         tmpfile <- resize_image(img_path)
         list(src = tmpfile, contentType = "image/jpeg")
      }, deleteFile = TRUE)  # Clean up temporary files
    })
   
  })}