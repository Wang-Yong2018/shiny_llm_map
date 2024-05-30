# language config
box::use(logger[log_info, log_warn, 
                log_debug, log_error,
                log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])

box::use(../global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list, i18n ])
# box::use(shiny.i18n[Translator])
# i18n<- Translator$new(translation_csvs_path = "./translation/")
# i18n$set_translation_language(app_language)

# shiny UI lib load
box::use(shiny[NS,tagList,icon,h2,
               sliderInput,selectInput,submitButton,
               numericInput,
               checkboxInput,
               actionButton,
               textOutput,renderText,
               moduleServer,
               observeEvent,
               reactive, req])

# shinydashboard UI load
box::use(shinydashboard[sidebarMenu, dashboardBody,
                        tabItem,tabItems,
                        menuSubItem,menuItem])

#' @export
ui <- function(id,label='sidebar'){
  ns <- NS(id)
  tagList(
    sidebarMenu( id='sidebar',collapsed=TRUE,
                 
                 menuItem(i18n$translate('navigate'),icon=icon('dashboard'),startExpanded =F,
                          #menuSubItem(i18n$translate("intro"), tabName='ds_intro',icon=icon('eye'),selected=TRUE),
                          menuSubItem(i18n$translate("chat_echo"), tabName = 'chat_echo',icon=icon('th'))
                          
                 ),
                 menuItem(i18n$translate('ai_chats'),icon=icon('dashboard'),startExpanded =T,
                          menuSubItem(i18n$translate("chat_llm"), tabName = 'chat_llm',icon=icon('google')),
                          menuSubItem(i18n$translate("vision_llm"), tabName = 'vision_llm',icon=icon('image')),
                          menuSubItem(i18n$translate("agent_llm"), tabName = 'agent_llm',icon=icon('bridge')),
                          menuSubItem(i18n$translate("sql_llm"), tabName = 'sql_llm',icon=icon('database'),selected=TRUE),
                          menuSubItem(i18n$translate("chat_debate"), tabName = 'chat_debate',icon=icon('fire')),
                          menuSubItem(i18n$translate("chat_rag"), tabName = 'chat_rag',icon=icon('file')),
                          menuSubItem(i18n$translate("chat_voice"), tabName = 'chat_voice',icon=icon('radio')),
                          menuSubItem(i18n$translate("chat_mm"), tabName = 'chat_mm',icon=icon('bridge'))
                 )  
                 
    ))
}


#' @export
server <- function(id){
  moduleServer(id, function(input, output, session) {
    
  })
}
