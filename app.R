box::use(shinydashboard[dashboardPage,dashboardHeader,
                        dashboardSidebar,dashboardBody,
                        tabItem,tabItems,
                        menuItem])


box::use(shiny[NS,icon,shinyApp,h1])
box::use(./global_constant[app_name,app_language, 
                           img_vision_prompt, 
                           model_id_list,vision_model_list ])

box::use(logger[log_info, log_warn, 
                log_debug, log_error,
                log_threshold,
                INFO, DEBUG, WARN,ERROR,OFF])
box::use(
   ./view/ui_sidebar,
   ./view/ui_echo,
   ./view/ui_chat,
   ./view/ui_vision,
   ./view/ui_agent,
   # ./view/ui_sql
#   ./view/ui_glimpse,
#   ./view/ui_plot_xy,
#   ./view/ui_intro,
#   ./view/ui_dmaic_d
 )

ui <- dashboardPage(
  title = app_name,
  dashboardHeader(),
  
  dashboardSidebar(
    collapsed = FALSE,
    ui_sidebar$ui('menu')
  ),
  dashboardBody(
    uiOutput("mainPanelContent")
  ) 
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  ui_echo$server('chat_echo')
  ui_chat$server('chat_llm')
  ui_vision$server('vision_llm')
  ui_agent$server('agent_llm')
  # note: it must add each of module server code here .
  
  output$mainPanelContent <- renderUI({
     switch(input$sidebar,
            'chat_echo'=ui_echo$ui('chat_echo'),
            "chat_llm"= ui_chat$ui('chat_llm') ,
            "vision_llm"= ui_vision$ui('vision_llm'),#h2('image Under construction') ,
            # "chat_openai"= h2('openai Under construction') ,
            "agent_llm"= ui_agent$ui('agent_llm') ,
            "sql_llm"=  h2('debate Under construction') ,
            "chat_debate"= h2('debate Under construction') ,
            "chat_rag"= h2('rag Under construction') ,
            "chat_voice"= h2('voice Under construction') ,
            "chat_mm"= h2('multi media model Under construction')#,
     )
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
