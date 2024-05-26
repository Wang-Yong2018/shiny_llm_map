box::use(purrr[map])
box::use(jsonlite[fromJSON, toJSON])
box::use(logger[log_info, log_warn,  log_debug, log_error,
                INFO, DEBUG, WARN,ERROR,OFF])
box::use(../global_constant[app_name,app_language,
                           img_vision_prompt,
                           model_id_list,vision_model_list ])

call_math <- function(agent_arguments) {
  
  arguments <- 
    agent_arguments|>
    fromJSON(simplifyVector = F)
  
  # Switch to calculate the result based on the function name
  func_name <- arguments[1]
  num1 <- arguments[2]|>as.numeric(num1)
  num2 <- arguments[3]|>as.numeric(num2)
  
  result <- switch(tolower(func_name),
         "addition" = num1 + num2,
         "subtraction" = num1 - num2,
         "multiplication" = num1 * num2,
         "division" = num1 / num2,
         "sqrt" = sqrt(num1),
         "log" = log(num1),
         'mod' = num1%%num2,
         "power" = num1 ** num2,
         "sin" = sin(num1),
         "cos" = cos(num1),
         "tan" = tan(num1))
  if (is.null(result)) {
    result <-  "This math operation has not support!"
  }
  formula <- paste0("The formula is: ",func_name,'(', num1,',', num2,')')
  result <- paste0('The result is :',result)
  text_result <- paste(formula, result, sep = '\n')
  # log_debug(paste0('call_math :',text_result) )
  return(text_result)
}