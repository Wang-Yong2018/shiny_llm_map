# Set up logging 

box::use(logger[log_info, log_warn, 
                log_debug, log_error,
                log_threshold,log_formatter,formatter_pander,
                INFO, DEBUG, WARN,ERROR,OFF])
log_formatter(formatter_pander)
log_threshold(DEBUG,namespace = "global")

# language settting
#Sys.setlocale("LC_ALL", 'Chinese (Simplified)_China.utf8')

# 英文环境 
#Sys.setlocale(category = "LC_ALL",locale = "English_United States")
# 中文环境
#Sys.setlocale(category = "LC_ALL",locale = "Chinese (Simplified)_China.utf8")

app_language = 'cn'

box::use(shiny.i18n[Translator])

i18n<- Translator$new(translation_csvs_path = "./translation/")
i18n$set_translation_language(app_language)
IS_DEBUG <- FALSE
# app level
app_name <- i18n$translate('AI_chatbox')
# time series name
ts_var_name <-'biz_date'
# ts_var_name <-'rq' 
model_id_list <- c('llama','gemini', 'gpt35','gpt4t', 'gpt4v')
db_id_list <-c('chinook')
# group key name
site_var_name <- 'collection_node'
# site_var_name <- 'site_name'
vision_model_list <-c('gemini','gpt4v')
img_vision_prompt <- "As a image tag and classification expert, pls help to analyse the image. Provide follow output:\n1. main topic tag and elements list\n2. using markdown format\n"

# the maximum sql query result row number  
max_sql_query_rows <- 100