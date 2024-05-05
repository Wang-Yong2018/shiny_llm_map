
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
debug <- TRUE
# app level
app_name <- i18n$translate('AI_chatbox')
# time series name
ts_var_name <-'biz_date'
# ts_var_name <-'rq' 
model_id_list <- c('gemini', 'gpt', 'gpt35', 'gpt4','gpt4t', 'gpt4v')
# group key name
site_var_name <- 'collection_node'
# site_var_name <- 'site_name'


# data source level
tbl_name='v_cyd_steam_gap'