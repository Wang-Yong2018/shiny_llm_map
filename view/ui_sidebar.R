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
               reactiveVal,
               moduleServer,
               observeEvent,
               reactive, req])

# shinydashboard UI load
box::use(shinydashboard[sidebarMenu, dashboardBody,
                        tabItem,tabItems,
                        menuSubItem,menuItem])

#' @export
ui <- function(id, label = 'sidebar') {
  ns <- NS(id)
  tagList(sidebarMenu(
    id = ns('sidebar'),
    collapsed = TRUE,
    menuItem(
      i18n$translate('help'),
      icon = icon('compass'),
      startExpanded = T,
      tabName = 'help',
      selected = TRUE
    ),
    
    menuItem(
      i18n$translate('Features'),
      icon = icon('dashboard'),
      startExpanded = T,
      menuSubItem(
        i18n$translate("Multi_ASK"),
        tabName = 'chat_llm',
        icon = icon('walkie-talkie')
      ),
      menuSubItem(
        i18n$translate("Analyze_IMG"),
        tabName = 'vision_llm',
        icon = icon('image')
      ),
      menuSubItem(
        i18n$translate("Probe_DB"),
        tabName = 'sql_llm',
        icon = icon('database')
      ),
      menuSubItem(
        i18n$translate("Play_agent"),
        tabName = 'agent_llm',
        icon = icon('link')
      ),
      menuSubItem(
        i18n$translate("Play_rag"),
        tabName = 'rag_llm',
        icon = icon('file')
      )
    ),
    menuItem(
      i18n$translate('Config'),
      icon = icon('tools'),
      startExpanded = F
    )
    
  ))
}


#' @export
server <- function(id){
  moduleServer(id, function(input, output, session) {
    selected_mod <- reactive(input$sidebar)
    return(selected_mod)
    
  })
}
