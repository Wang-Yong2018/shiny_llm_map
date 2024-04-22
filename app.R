box::use(shinydashboard[dashboardPage,dashboardHeader,
                        dashboardSidebar,dashboardBody,
                        tabItem,tabItems,
                        menuItem])


box::use(shiny[NS,icon,shinyApp,h1])
box::use(./global_constant[app_name])

box::use(
   ./view/ui_sidebar,
   ./view/ui_echo,
   ./view/ui_gemini
#   ./view/ui_glimpse,
#   ./view/ui_plot_xy,
#   ./view/ui_intro,
#   ./view/ui_dmaic_d
 )

ui <- dashboardPage(
  title=app_name,
  dashboardHeader(),
  
  dashboardSidebar(
    collapsed=F,
    ui_sidebar$ui('menu')
  ),
  dashboardBody(
    uiOutput("mainPanelContent")
  ) 
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  ui_echo$server('chat_echo')
  ui_gemini$server('gemini')
  output$mainPanelContent <- renderUI({
     switch(input$sidebar,
            'chat_echo'=ui_echo$ui('chat_echo'),
            "chat_gemini"= ui_gemini$ui('gemini') ,
            "chat_openai"= h2('openai Under construction') ,
            "chat_debate"= h2('debate Under construction') ,
            "chat_rag"= h2('rag Under construction') ,
            "chat_image"= h2('image Under construction') ,
            "chat_voice"= h2('voice Under construction') ,
            "chat_mm"= h2('multi media model Under construction')#,
   
     )
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
