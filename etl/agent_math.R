box::use(purrr[map])
box::use(jsonlite[fromJSON, toJSON])
box::use(logger[log_info, log_warn,  log_debug, log_error, log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])
box::use(../global_constant)



# log_threshold(log_level)


call_math <- function(func_name, num1, num2) {
  
  # Switch to calculate the result based on the function name
  num1 <- as.numeric(num1)
  num2 <- as.numeric(num2)
  result <- switch(func_name,
         "add" = num1 + num2,
         "addition" = num1 + num2,
         "subtract" = num1 - num2,
         "multiply" = num1 * num2,
         "divide" = num1 / num2,
         "sqrt" = sqrt(num1),
         "log" = log(num1),
         "exp" = exp(num1),
         "sin" = sin(num1),
         "cos" = cos(num1),
         "tan" = tan(num1))
  if (is.null(result)){
    result <-  "This math operation has not support!"
  }
  formula <- paste0("The format is: ",func_name,'(', num1,',', num2,')')
  result<- paste0('The result is :',result)
  text_result <- paste(formula, result, sep = '\n')
  log_debug(paste0('call_math :',text_result) )
  return(text_result) 
}