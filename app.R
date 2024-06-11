box::use(shinydashboard[dashboardPage, 
                        dashboardHeader,
                        dashboardSidebar,
                        dashboardBody,
                        tabItem, tabItems, menuItem])

box::use(shiny[NS,icon,shinyApp,h1])

box::use(./global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list ])

box::use(logger[log_info, log_warn, 
                log_debug, log_error,
                log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])
box::use( ./view/ui_sidebar,
          ./view/ui_echo,
          ./view/ui_chat,
          ./view/ui_vision,
          ./view/ui_agent,
          ./view/ui_sql,
          ./view/ui_help
          #   ./view/ui_glimpse,
          #   ./view/ui_plot_xy,
          #   ./view/ui_intro,
          #   ./view/ui_dmaic_d
)
# !diagnostics suppress=ui_sidebar, ui_chat,ui_vision,ui_agent,ui_sql, ui_help,ui_echo 

ui <- dashboardPage(
 
  dashboardHeader(title = app_name),
  dashboardSidebar(collapsed = FALSE,
                   ui_sidebar$ui('sidebar')),
  dashboardBody(uiOutput("mainPanelContent")) 
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  ui_echo$server('chat_echo')
  ui_chat$server('chat_llm')
  ui_vision$server('vision_llm')
  ui_agent$server('agent_llm')
  ui_sql$server('sql_llm')
  ui_help$server('help')
  # note: it must add each of module server code here .
  #TODO add a message notice for llm service down or credit use out
  get_mod_name <- ui_sidebar$server('sidebar') 
  output$mainPanelContent <- renderUI({
    log_info(get_mod_name())
    log_debug(get_mod_name())
    switch(get_mod_name(),
           #'chat_echo'=ui_echo$ui('chat_echo'),
           'help' = ui_help$ui('help'), 
           "chat_llm" = ui_chat$ui('chat_llm'), 
           "vision_llm" = ui_vision$ui('vision_llm'), #h2('image Under construction') ,
           "agent_llm" = ui_agent$ui('agent_llm') , 
           "sql_llm" =  ui_sql$ui('sql_llm') , 
           "rag_llm" = h2('Under Construction') 
    )
  })
    
  
}

# Run the application 
shinyApp(ui = ui, server = server)
