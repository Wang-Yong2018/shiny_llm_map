box::use(purrr[map, pluck])
box::use(jsonlite[toJSON, fromJSON])
box::use(../global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list ])

box::use(logger[log_info, log_warn,  log_debug, log_error, log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])

box::use(./agent_math[call_math])
box::use(./db_api[get_sql_result])

get_tools <- function(){
  tools_source <- './data/tools_config.json'
  tools <- fromJSON(tools_source,simplifyVector = F)
}

get_agent_result<-function(ai_result){
 # ai result is value from get_ai_result(llm_result, ai_type='agent') 
  log_debug(paste0('get agent_result input is ==>',class(ai_result), ai_result))
  result = NULL 

  tryCatch(
    expr = {
      agent_name <- 
        ai_result |> 
        pluck('content','name')
      
      agent_arguments <- 
        ai_result |> 
        pluck('content','arguments') 
      log_debug(paste0('agent name :' ,agent_name))
      log_debug(paste0('agent_arguments :', agent_arguments))

      result <-switch(agent_name,
                      extract_calculation_input=call_math(agent_arguments),
                      sql_query=get_sql_result(agent_arguments)
                      )
      
      log_debug(paste0( 'The agent result is ==>',result))
      if (is.null(result)){
        result <- paste0('the agent (',agent_name,') has not defined')
      }
    },
    error = function(e) {
      log_error(paste0("An agent router parse error occurred: ", conditionMessage(e), "\n"))
    }
  )
  return(result)
}