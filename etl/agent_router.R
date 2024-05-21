box::use(purrr[map, pluck])
box::use(../global_constant)

box::use(logger[log_info, log_warn,  log_debug, log_error, log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])

log_threshold(log_level)
box::use(./agent_math[call_math])


agent_router<-function(ai_result){
 # ai result is value from get_ai_result(llm_result, ai_type='agent') 
  result = NULL 

  tryCatch(
    expr = {
      agent_name <- 
        ai_result |> 
        pluck('content','name')
      
      agent_arguments <- 
        ai_result |> 
        pluck('content','arguments') 
      #log_info('agent name :' ,agent_name)
      #log_info('agent_arguments :', agent_arguments)
                
      agent_arguments <- 
        agent_arguments|>
        fromJSON(simplifyVector = F)
      
      result <-switch(agent_name,
                      extract_calculation_input=call_math(agent_arguments[1], 
                                                          agent_arguments[2],
                                                          agent_arguments[3])
                      )
      if (is.null(result)){
        result <- paste0('the agent (',agent_name,') has not defined')
      }
    },
    error = function(e) {
      #log_error("An agent router parse error occurred: ", conditionMessage(e), "\n")
    }
  )
  return(result)
}