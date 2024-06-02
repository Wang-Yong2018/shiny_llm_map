fluidRow(
  tabsetPanel( 
    tabPanel(i18n$translate('distribution'),   plotOutput(ns("plot_1d"),height = 350)) ,
    tabPanel(i18n$translate('anova'),   plotOutput(ns("plot_boxplot"),height = 350)) ,
    tabPanel(i18n$translate('trends'),   plotOutput(ns("plot_ts"),height = 350)) ,
    tabPanel(i18n$translate('Decision Tree'),   plotOutput(ns("plot_prp_tree"),height = 350)) , 
    tabPanel(i18n$translate('Residual Plot'), plotOutput(ns("plot_resid"),height = 350)) ,
    tabPanel(i18n$translate('Top 10 Factors'), plotOutput(ns("plot_vip"),height = 350)) ,
    tabPanel(i18n$translate('Model Detail'), verbatimTextOutput(ns("plot_model")))
  )
)