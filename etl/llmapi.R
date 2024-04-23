box::use(httr2[request, req_perform,
               resp_status,req_retry,req_error,
               req_body_json, req_user_agent,
               req_url_query, req_url_path_append,
               resp_body_json])
box::use(purrr[map_dfr, pluck])
box::use(cachem[cache_disk],
         memoise[memoise])
box::use(dplyr[as_tibble])
box::use(rlang[abort,warn])
# library(purrr)
# library(memoise)
cache_dir <- cache_disk("./cache",max_age = 3600*24)

# build llm connection
req_perform_quick <- memoise(req_perform,cache = cache_dir)


set_llm_conn <- function(
    url='https://generativelanguage.googleapis.com/v1beta/models',
    max_seconds=3
    ) {
  
  api_key <- Sys.getenv('gemini_api_key')
  llm_method <- 'gemini-pro:generateContent' 
  #prompt_message <- 'who are you?'
  #model_type='gemini-pro:generateContent' 
  req <- request(url) |>
    req_url_query(key=api_key) |>
    req_url_path_append(llm_method) |>
    req_retry(  max_tries = 3,
                backoff = ~2) |>
    req_user_agent('shiny_gemini')
  #print(req)
  return(req)
}

# get llm service result
#' @export
get_llm_result <- function(prompt='hi'){
  

  post_body = list(
    contents = list( 
      parts = list(list(text = prompt)
                   )
      ),
    generationConfig = list(
      temperature = 0.5,
      maxOutputTokens = 1024
    )
  )
 
  response <- try( set_llm_conn() |>
                     req_body_json(data=post_body) |>
                     req_error(is_error = \(resp) FALSE) |>
                     req_perform()
                   )
  if('try-error' %in% class(response)){
    response_message <- 'connection failed! pls check network' 
  } else {
    response_message <- 
      response |> 
      resp_body_json() |>
      pluck('candidates',1,'content','parts',1,'text')
    }
  
  
  return(response_message)
}

#' @export 
fast_get_llm_result <- memoise(get_llm_result,cache=cache_dir)

# list the large lanugage model services list info as data frame
# two version , list, fast list
list_llm_service <- function(){
  df_llm_service <- set_llm_conn() |>
    req_perform_quick() |>
    resp_body_json()|>
    purrr::pluck('models') |>
    purrr::map_dfr(\(x) as_tibble(x))
  
  return(df_llm_service)
}

# Function to check connection with google

# Replace "https://api.labs.google.com/" with the specific Gemini API endpoint you're using
#' @export
check_llm_connection<- function() {

  is_connected =FALSE 
  
  resp <- list_llm_service()
  
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
