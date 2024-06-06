box::use(httr2[request, req_cache, req_progress,
               req_perform, req_perform_stream,
               last_response,
               resp_status,req_retry,req_error,req_timeout, req_dry_run,
               resp_check_status,resp_is_error,
               req_body_json, req_user_agent,req_headers,
               req_url_query, req_url_path_append,
               resp_body_json],
         jsonlite[fromJSON, toJSON])

box::use(purrr[map_dfr, pluck])
box::use(cachem[cache_disk,cache_mem],
         memoise[memoise])
box::use(dplyr[as_tibble])
box::use(stringr[str_extract,str_glue])
box::use(rlang[abort,warn])
box::use(base64enc[base64encode])
box::use(../etl/agent_sql[get_db_schema])
box::use(../global_constant[app_name,app_language, 
                           img_vision_prompt, MAX_TOKENS,
                           model_id_list,vision_model_list,
                           global_seed,timeout_seconds,
                           i18n])

box::use(logger[log_info, log_warn, 
                log_debug, log_error,
                INFO, DEBUG, WARN,ERROR,OFF])
TIMEOUT_SECONDS = 30

# cache_dir <- cache_disk("./cache",max_age = 3600*24)

set_llm_conn <- function(
    url = "https://openrouter.ai/api/v1/chat/completions",
    timeout_seconds=TIMEOUT_SECONDS
    ) {
  api_key = Sys.getenv('OPENROUTER_API_KEY') 
  
  req <- request(url) |>
    req_timeout(timeout_seconds)|>
    req_headers(
      Authorization=paste0('Bearer ',api_key) )|>
    # req_cache(tempdir(), debug = TRUE) |>
    req_retry(  max_tries = 3,
                backoff = ~1) |>
    req_progress() |>
    req_user_agent('shiny_ai')
  
  return(req)
}


get_select_model_name <- function(model_id) {
  select_model= switch(model_id,
                       gpt35 = "openai/gpt-3.5-turbo-0125", 
                       gpt4o = "openai/gpt-4o",
                       # gpt4v = "openai/gpt-4-vision-preview",
                       gemini = "google/gemini-pro-1.5",
                       llama = 'meta-llama/llama-3-8b-instruct',
                       claude3s = 'anthropic/claude-3-sonnet:beta',
                       mixtral = 'mistralai/mixtral-8x7b-instruct',
                       deepseekv2 = 'deepseek/deepseek-chat',
                       phi="microsoft/phi-3-medium-128k-instruct:free",
                      "microsoft/phi-3-medium-128k-instruct:free" 
                       )
  return(select_model)
}

#' @export
get_chat_history <- function(message, role='user', last_history=NULL){
  # this function is designed to hangle the chat history
  # case 1: initial chat, 
    #   setup system role and  prompt
    #   append the user role and prompt
  # case 2: record ai response message
    #  append the assistant role and message
  # case 3: 2nd, 3rd  and nth user input append
    # append the user role and message

  # If last_history is NULL, initialize the chat history
  if (is.null(last_history)) {
    last_history <- list(list(role='system',
                              content =  i18n$translate("You are a helpful AI assitan")))
    
  } 
  new_history <- last_history
  new_history <- c(new_history, list(list(role = role, content = message)))
      
  return(new_history)
}
  

get_json_data <- function(user_input,select_model){
  

  # # prepare the configure
  # json_generationConfig = list( temperature = 0.5,
  #                               maxOutputTokens = 1024)
  # prepare the data
  json_contents <- list(list(role = 'user',content=user_input)
                                         # this is a list of messages
                                         
                                         )
  
  json_data <- list(model=select_model,
                    messages = json_contents#,
                    #generationConfig = json_generationConfig
                    )
  return(json_data)
}

get_json_chat_data <- function(user_input, select_model, history=NULL,max_tokens=MAX_TOKENS){
  # this function is used for short memory conversation.
  # The ai could remember what user said and conversation based on history topic'
  
  # # prepare the configure
  json_generationConfig = list( temperature = 0.5# ,
                              # maxOutputTokens = 1024
                               )
  # prepare the data
  # user_message <- list(role = 'user',content=user_input)
  
  json_contents <- get_chat_history(user_input,role='user',history)
  json_data <- list(model=select_model,
                    messages = json_contents,
                    seed=global_seed,
                    max_tokens=MAX_TOKENS,
                    temperature=1#,
                    #top_k = 0.1
                    #generationConfig = json_generationConfig
                    )
  
  return(json_data)
}

get_json_img <- function(user_input, img_url, select_model,image_type='file',max_tokens=MAX_TOKEN){

  # # prepare the configure
  # json_generationConfig = list( temperature = 0.5,
  #                               maxOutputTokens = 1024)
  image_content =switch(image_type,
                       file=paste0("data:image/jpeg;base64,", base64encode(img_url)),
                       url=img_url,
                       img_url)
  
  # prepare the data
  json_contents <- list(list(role = 'user',
                             content=list(list(type='text', text=user_input),
                                          list(type='image_url', 
                                               image_url=list(url=image_content,
                                                              detail='auto'))
                                          ))
                        )
  json_data <- list(model=select_model,
                    messages = json_contents,
                    max_tokens = max_tokens
                    #generationConfig = json_generationConfig
  )
  return(json_data)
}

#' @export
get_json_agent <- function(user_input, select_model,funcs_json){
  
  # prepare the configure
  # json_generationConfig = list( temperature = 0.5,
  #                               maxOutputTokens = 1024)
  # prepare the data
  json_contents <- list(list(role='user', content=user_input) )
  
  #func_json
  # TODO: there should be some code to validate the json of function 
  # for function_call, the google gemini api is not full compatible with chatgpt.
  # so I need remove the extra field chinese_name
  funcs_json
    
  if(grepl('gemini',select_model)){
    gemini_func_json <- list(function_declarations=funcs_json)
    json_data <- list(model=select_model,
                      messages = json_contents,
                      functions = gemini_func_json,
                      tool_config=list(function_calling_config='AUTO'))
    
  } else {
    json_data <- list(model=select_model,
                      messages = json_contents,
                      functions= funcs_json,
                      function_call='auto' )
    
  }
  return(json_data)
}



#' @export
get_llm_post_data <- function(prompt='hi', history=NULL, llm_type='chat',model_id='llama', img_url=NULL,funcs_json=NULL,
                              max_tokens=MAX_TOKENS){
  # select the model
  select_model <- get_select_model_name(model_id)
  
  # select the post_body 
  post_body <- switch(llm_type,
                      chat=get_json_chat_data(user_input=prompt,select_model=select_model,history=history,max_tokens=max_tokens),
                      sql=get_json_chat_data(user_input=prompt,select_model=select_model,history=history),
                      answer=get_json_data(user_input=prompt,select_model=select_model),
                      img_url=get_json_img(user_input=prompt, img_url=img_url, select_model=select_model,image_type='url',max_tokens=max_tokens),
                      img=get_json_img(user_input=prompt, img_url=img_url, select_model=select_model, image_type='file',max_tokens=max_tokens),
                      #func=get_json_func(user_input=prompt,select_model=select_model,history=history),
                      agent=get_json_agent(user_input=prompt,select_model=select_model,funcs_json=funcs_json),
                      get_json_data(user_input=prompt,select_model=select_model)
  )
  return(post_body)
}

# get llm service result
#' @export
get_llm_result <- function(prompt='你好，你是谁',
                           img_url=NULL,
                           model_id='llama',
                           llm_type='chat',
                           history=NULL,
                           funcs_json=NULL,
                           timeout_seconds=TIMEOUT_SECONDS){
  

  post_body <- get_llm_post_data(prompt=prompt,history=history, 
                                 llm_type=llm_type,model_id=model_id, 
                                 img_url=img_url,funcs_json = funcs_json)
  log_debug(paste(' the llm post data is ===> ', post_body,sep='\n'))
  request <- 
    set_llm_conn(timeout_seconds = timeout_seconds) |>
    req_body_json(data=post_body,
                  type = "application/json") 
  
 
  response_message <-  get_stream_data(request) 
  
  log_debug(response_message)
  # print(response_message)
  return(  response_message)
}


# Function to check connection with google

# Replace "https://api.labs.google.com/" with the specific Gemini API endpoint you're using
#' @export
check_llm_connection<- function() {
  # out of date

 #  is_connected =FALSE 
 #  
 #  resp <- get_llm_result()
 #  
 #  # Check the response status code (should be 200 for success)
 #  if (resp|>resp_status() == 200) {
 #    cat(paste0(url,' ', "Connection successful!\n"))
 #    is_connected=TRUE
 #  } else {
 #    cat(paste0(url,' ', "Connection failed with status code:", response$status, "\n"))
 #    is_connected=TRUE
 #  }
 # return(is_connected) 
}

#' @export
llm_chat <- function( user_input, model_id='llama', history=NULL){
  
  # select_model is a fake model_info, it will be actual assigned in get_llm_result function.
  chat_history <- get_json_chat_data(user_input = user_input, 
                                     select_model ='llama', 
                                     history = history)
  
  response_message <- get_llm_result(prompt,model_id, history=chat_history,llm_type='chat') 
  
  chat_history$messages <- append(chat_history$messages, list(response_message))
  
  #text_output <- last_history|>pluck(-1, 'parts',-1,'text') 
  #chat_history <- list(history=last_history,
  #                     text_output = text_output)
  return(chat_history)  
}




#' @export
get_ai_result <- function(ai_response,ai_type='chat',parameter=NULL){
  
  ai_message <- ai_response |> pluck('choices',1,'message')
  ai_model_name <- ai_response|>pluck('model')
  log_debug(paste0('the get_ai_result function ai_message is======>',ai_message))
  finish_reason <- ai_response |> pluck('choices',1,'finish_reason')|>tolower()
  
  ai_result <- switch(tolower(finish_reason),
                      # chat_type
                      stop = list(role=ai_message$role, content=ai_message$content),
                      chat.completion = list(role=ai_message$role, content=ai_message$content),
                      end_turn = list(role=ai_message$role, content=ai_message$content),
                      error = list(role=ai_message$role,content=ai_message$content),
                      function_call = list(role=ai_message$role, content=ai_message$function_call),
                      max_tokens = list(role=ai_message$role, 
                                        content=paste0(ai_message$content, '\n--##', i18n$translate('finish reason'),':',finish_reason)),
                      #sql_query=list(role=ai_message$role, content=list(name='sql_query',arguments=ai_message$content)),
                      list(role=ai_message$role, content=paste0(ai_message$content, '\n--##', i18n$translate('finish reason'),':',finish_reason))
                      )
  log_debug(ai_result)
  if(ai_type %in% c('sql_query','dot','sql') & finish_reason %in% c('stop','function_call','max_tokens')){
    
    code <- ai_message$content
    if(grepl('ERROR', code)) {
      code <- paste0('-- ',code)
    }
    db_id <- parameter$db_id
    model_id <- ai_model_name
    generate_time <- ai_response$created|> as.POSIXct()|>as.character() 
    
    ai_result <- list( role=ai_message$role,
                       content=list(name = 'sql_query',
                                    arguments= list(db_id =db_id,
                                                    sql_query=code,
                                                    model_id=model_id,
                                                    generated_time = generate_time) ) 
                       )
      
    }
    # ai_result <-list(
    #   role=ai_message$role,
    #   content=list(name='sql_query',arguments=code))

  
  log_info(paste0('the ai message result is ====>', ai_result))
  return(ai_result)
}

get_stream_data<- function(req,timeout_seconds=TIMEOUT_SECONDS){
  # Initialize an empty list to store the streamed data
  streamed_data <- list()
  
  # Define a callback function to process each chunk of data
  process_chunk <- function(chunk) {
    # Convert the raw chunk to character
    # Process the JSON data (assuming each chunk is a complete JSON object)
    
    log_debug("Got ", length(chunk), " bytes\n", sep = "")
    text<-  rawToChar(x=chunk)
    # Append the data to the external list
    streamed_data <<- append(streamed_data, text)
    
    # Return TRUE to continue streaming
    TRUE
  }
  
  # After streaming request
  response<-
    try( 
      req|>  req_perform_stream(process_chunk, 
                                timeout_sec = timeout_seconds,
                                buffer_kb = 2,
                                round ='line'
                                )
    )
  
  if('try-error' %in% class(response)){
    error_message <- response |> errorCondition()
    #error_message <- response |> resp_status_desc()
    #http_code <- response |> resp_status()
    #error_code <- paste0('HTTP ',http_code)
    response_message <-list( model =NULL,
                             choices=list(list(message = list(
                               role = 'error',
                               content = error_message),
                               finish_reason='time out')
                             ))
    log_error(paste0('get_stream_data failed, the reason is: ==',error_message))
  } else {
    if(resp_is_error(response)){
      error_message <- response|>httr2::resp_status_desc()
      http_code <- response|>resp_status()
      error_code <- paste('HTTP ',
                          http_code,
                          ':',
                          error_message)
      
      response_message <-list( model =NULL,
                               choices=list(list(message = list(
                                 role = 'error',
                                 content = error_code),
                                 finish_reason=error_message)
                               ))
    }else{
      log_debug(streamed_data)
      response_message <-
        streamed_data |>
        paste0(collapse = '') |>
        fromJSON(txt=_,simplifyVector =FALSE )#|>
      #pluck(1)
      # response_message <- streamed_data |> pluck(1)
    }
  }
  log_info(paste('the response data is ===> ', response_message ,sep='\n')) 
  # Access the streamed data
  return(response_message)
  
}
