box::use(httr2[request, req_perform,
               resp_status,req_retry,req_error,req_timeout, req_dry_run,
               req_body_json, req_user_agent,req_headers,
               req_url_query, req_url_path_append,
               resp_body_json],
         jsonlite[fromJSON, toJSON])

box::use(purrr[map_dfr, pluck])
box::use(cachem[cache_disk,cache_mem],
         memoise[memoise])
box::use(dplyr[as_tibble])
box::use(rlang[abort,warn])
box::use(base64enc[base64encode])
box::use(../etl/db_api[get_database_info])
# library(purrr)
# library(memoise)
cache_dir <- cache_disk("./cache",max_age = 3600*24)

# build llm connection
req_perform_quick <- memoise(req_perform,cache = cache_dir)



set_llm_conn <- function(
    url = "https://openrouter.ai/api/v1/chat/completions",
    #url = "https://openrouter.ai/api/v1",
    max_seconds=3
    ) {
# this is openrouter llm connection 
  api_key = Sys.getenv('OPENROUTER_API_KEY') 
  #prompt_mesage <- 'who are you?'
  #model_type='gemini-pro:generateContent' 
  req <- request(url) |>
    req_timeout(20)|>
    req_headers(
      Authorization=paste0('Bearer ',api_key) )|>
    req_retry(  max_tries = 3,
                backoff = ~2) |>
    req_user_agent('shiny_ai')
  
  return(req)
}


get_select_model_name <- function(model_id) {
  select_model= switch(model_id,
                       gpt = "openai/gpt-3.5-turbo", 
                       gpt35 = "openai/gpt-3.5-turbo", 
                       gpt4 = "openai/gpt-4",
                       gpt4t = "openai/gpt-4-turbo",
                       gpt4v = "openai/gpt-4-vision-preview",
                       gemini = "google/gemini-pro-1.5",
                       llama = 'meta-llama/llama-3-8b-instruct:extended',
                       "google/gemini-pro-1.5" )
}


get_json_data <- function(input,select_model){
  

  # prepare the configure
  json_generationConfig = list( temperature = 0.5,
                                maxOutputTokens = 1024)
  # prepare the data
  json_contents <- list(list(role = 'user',content=input)
                                         # this is a list of messages
                                         
                                         )
  
  json_data <- list(model=select_model,
                    messages = json_contents#,
                    #generationConfig = json_generationConfig
                    )
  return(json_data)
}

get_json_chat_data <- function(prompt, select_model, history=NULL){
  # this function is used for short memory conversation.
  # The ai could remember what user said and conversation based on history topic'
  
  # prepare the configure
  json_generationConfig = list( temperature = 0.5,
                                maxOutputTokens = 1024)
  # prepare the data
  user_message <- list(role = 'user',content=prompt)
  
  json_contents <- get_chat_history(prompt,role='user',history)
  json_data <- list(model=select_model,
                    messages = json_contents#,
                    #generationConfig = json_generationConfig
                    )
  
  return(json_data)
}

get_json_img <- function(user_input, img_url, select_model,image_type='file'){

  # prepare the configure
  json_generationConfig = list( temperature = 0.5,
                                maxOutputTokens = 1024)
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
  json_max_tokens = 300                                             
  json_data <- list(model=select_model,
                    messages = json_contents,
                    max_tokens = json_max_tokens
                    #generationConfig = json_generationConfig
  )
  return(json_data)
}

get_json_call_data <- function(user_input, img_url, select_model,image_type='call'){
  
  # prepare the configure
  json_generationConfig = list( temperature = 0.5,
                                maxOutputTokens = 1024)
  # prepare the data
  json_contents <- list(list(role = 'user',
                             content=list(list(type='text', text=user_input),
                                          list(type='image_url', 
                                               image_url=list(url=image_content,
                                                              detail='auto'))
                             ))
  )
  json_max_tokens = 300                                             
  json_data <- list(model=select_model,
                    messages = json_contents,
                    max_tokens = json_max_tokens
                    #generationConfig = json_generationConfig
  )
  return(json_data)
}

#' @export
get_llm_post_data <- function(prompt='hi', history=NULL, llm_type='chat',model_id='llama', img_url=NULL){
  # select the model
  select_model <- get_select_model_name(model_id)
  
  # select the post_body 
  post_body <- switch(llm_type,
                      chat=get_json_chat_data(prompt,select_model,history),
                      answer=get_json_data(prompt,select_model),
                      img_url=get_json_img(prompt, img_url,select_model,image_type='url'),
                      img=get_json_img(prompt, img_url,select_model,image_type='file'),
                      sql=get_json_sql(prompt, select_mode,history),
                      func=get_json_func(prompt,select_mode,history),
                      get_json_data(prompt,select_model)
  )
  return(post_body)
}

# get llm service result
#' @export
get_llm_result <- function(prompt='你好，你是谁',
                           img_url=NULL,
                           model_id='llama',
                           llm_type='chat',history=NULL,
                           DEBUG=TRUE){
  

  post_body <- get_llm_post_data(prompt,history, llm_type,model_id, img_url)
  request <- 
    set_llm_conn() |>
    req_body_json(data=post_body,
                  type = "application/json") |>
    req_error(is_error = \(resp) FALSE) 
  
  # get response while handling the exception 
  response <- try(  
    request |>
     req_perform() )
  
  if('try-error' %in% class(response)){
    response_message <- 'connection failed! pls check network' 
  } else {
    response_message <- 
      response |> 
      resp_body_json() #|>
      #pluck('choices')  
    
  }
  if (DEBUG==TRUE){
    print(post_body|>toJSON(auto_unbox=TRUE,pretty=TRUE))
    print(response_message|>toJSON(auto_unbox=TRUE,pretty=TRUE))
    
  }
  
  return(response_message)
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
                              content = "你是一个专业的人工智能助理，工作语言是中文。"))
    
  } 
  new_history <- last_history
  new_history <- c(new_history, list(list(role = role, content = message)))
      
  return(new_history)
}
  
#' 
#' #' @export 
#' fast_get_llm_result <- memoise(get_llm_result,cache=cache_dir)
#' 
#' # list the large lanugage model services list info as data frame
#' # two version , list, fast list
#' list_llm_service <- function(){
#'   df_llm_service <- set_llm_conn() |>
#'     req_perform_quick() |>
#'     resp_body_json()|>
#'     purrr::pluck('models') |>
#'     purrr::map_dfr(\(x) as_tibble(x))
#'   
#'   return(df_llm_service)
#' }

# Function to check connection with google

# Replace "https://api.labs.google.com/" with the specific Gemini API endpoint you're using
#' @export
check_llm_connection<- function() {
  # out of date

  is_connected =FALSE 
  
  resp <- get_llm_result()
  
  # Check the response status code (should be 200 for success)
  if (resp|>resp_status() == 200) {
    cat(paste0(url,' ', "Connection successful!\n"))
    is_connected=TRUE
  } else {
    cat(paste0(url,' ', "Connection failed with status code:", response$status, "\n"))
    is_connected=TRUE
  }
 return(is_connected) 
}

#' @export
llm_chat <- function( prompt, model_id='llama', history=NULL){
  
  # select_model is a fake model_info, it will be actual assigned in get_llm_result function.
  chat_history <- get_json_chat_data(prompt = prompt, 
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
llm_func <- function( prompt, model_id='llama', history=NULL){

  # prepare the data
  json_contents <- list(list(role = 'user',content=prompt)
                        # this is a list of messages
                        
  )
  json_function <- fromJSON('./data/tools_config.json',simplifyVector = F) 
  
  json_data <- list(model="openai/gpt-3.5-turbo",
                    messages = json_contents,
                    functions= json_function,
                    function_call='auto'
                    #generationConfig = json_generationConfig
  )
  # setup the request message
  request <- 
    set_llm_conn() |>
    req_body_json(data=json_data,
                  type = "application/json") |>
    req_error(is_error = \(resp) FALSE) 
  
  # get response while handling the exception 
  response <- try(  
    request |>
      req_perform() )
  
  if('try-error' %in% class(response)){
    response_message <- 'connection failed! pls check network' 
  } else {
    response_message <- 
      response |> 
      resp_body_json()|> 
      pluck('choices',1) # R list index from 1
      # note: in R language, the index is come from 1 instead of 0. In python, it is from 0
    
     
  }

  result <- switch(response_message$finish_reason,
                   stop=response_message|>pluck('message','content'),
                   function_call=response_message|>pluck('message','function_call','arguments'),
                   response_message|>pluck('message','content')
                   )
  
  return(result)
  
}


#' @export
get_ai_result <- function(ai_response,ai_type='chat'){
  
  ai_message <- ai_response |> pluck('choices',1,'message')
  
  ai_result <- switch(ai_type,
                      # chat_type
                      chat = list(role=ai_message$role, content=ai_message$content),
                      img  = list(role=ai_message$role,content=ai_message$content)
                      )
  return(ai_result)
}
