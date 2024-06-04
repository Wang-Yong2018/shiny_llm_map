# Set up logging 

box::use(logger[log_info, log_warn, 
                log_debug, log_error,
                log_threshold,log_formatter,formatter_pander,formatter_json,
                log_layout,layout_json_parser,
                log_appender, appender_file,
                INFO, DEBUG, WARN,ERROR,OFF])
log_formatter(formatter_json)
log_layout(layout_json_parser())
log_threshold(INFO,namespace = "global")
log_file <- './llm_message.log'
log_appender(appender_file(log_file,max_line=1000,max_files = 3L))
# language settting
#Sys.setlocale("LC_ALL", 'Chinese (Simplified)_China.utf8')

# 英文环境 
#Sys.setlocale(category = "LC_ALL",locale = "English_United States")
#Sys.setlocale(category = "LC_ALL",locale = "Chinese (Simplified)_China.utf8")

app_language = 'cn'

box::use(shiny.i18n[Translator])

i18n<- Translator$new(translation_csvs_path = "./translation/",translation_csv_config = './translation/config.yaml')
i18n$set_translation_language(app_language)


IS_DEBUG <- FALSE
# app level
app_name <- i18n$translate('ai_chatbox')
# time series name
ts_var_name <-'biz_date'
# ts_var_name <-'rq' 
model_id_list <- c('gpt35','gpt4o','gemini','llama','claude3s','mixtral','deepseekv2','phi')
sql_model_id_list <- c('gpt35','gemini', 'claude3s','deepseekv2')

db_id_list <-c('music','dvd_rental','academic')

db_chinook_url <- './data/chinook.db'

db_url_map <- list(music='./data/chinook.db',
                   dvd_rental= './data/sakila_1.sqlite',
                   academic = './data/academic.sqlite')

# group key name
site_var_name <- 'collection_node'
# site_var_name <- 'site_name'
vision_model_list <- model_id_list
img_vision_prompt <- "As a image tag and classification expert, pls help to analyse the image. Provide follow output:\n1. main topic tag and elements list\n2. using markdown format\n"

# the maximum sql query result row number  
max_sql_query_rows <- 100

sql_agent_config_file <- './data/sql_agent_prompt.txt'
global_seed <- 42 
timeout_seconds <- 60