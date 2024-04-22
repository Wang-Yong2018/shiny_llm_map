# language config
box::use(../global_constant[app_name,app_language])
box::use(shiny.i18n[Translator])
i18n<- Translator$new(translation_csvs_path = "./translation/")
i18n$set_translation_language(app_language)

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
box::use(
   
)

#' @export
ui <- function(id,label='sidebar'){
  ns <- NS(id)
  tagList(
    sidebarMenu( id='sidebar',collapsed=TRUE,
                 
                 menuItem(i18n$translate('navigate'),icon=icon('dashboard'),startExpanded =T,
                          #menuSubItem(i18n$translate("intro"), tabName='ds_intro',icon=icon('eye'),selected=TRUE),
                          menuSubItem(i18n$translate("chat_echo"), tabName = 'chat_echo',icon=icon('th'),selected=TRUE)
                          
                 ),
                 menuItem(i18n$translate('ai_chats'),icon=icon('dashboard'),startExpanded =F,
                          menuSubItem(i18n$translate("chat_gemini"), tabName = 'chat_gemini',icon=icon('flask')),
                          menuSubItem(i18n$translate("chat_openai"), tabName = 'chat_openai',icon=icon('question')),
                          menuSubItem(i18n$translate("chat_debate"), tabName = 'chat_debate',icon=icon('ruler')),
                          menuSubItem(i18n$translate("chat_rag"), tabName = 'chat_rag',icon=icon('magnifying-glass')),
                          menuSubItem(i18n$translate("chat_image"), tabName = 'chat_image',icon=icon('chart-simple')),
                          menuSubItem(i18n$translate("chat_voice"), tabName = 'chat_voice',icon=icon('check')),
                          menuSubItem(i18n$translate("chat_mm"), tabName = 'chat_mm',icon=icon('check'))
                 )  
                 
    ))
}


#' @export
server <- function(id){
  moduleServer(id, function(input, output, session) {
    
  })
}
