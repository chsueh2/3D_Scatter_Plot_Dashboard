# shiny dashboard app to visualize SIR data
#



# 01 setup ----------------------------------------------------------------


# load packages and functions
if (!require("pacman")) utils::install.packages("here", dependencies = TRUE)
source(here::here("00 preloads.R"))


# read data for test purpose
#df <- readRDS(here("SIR_summary.rds"))



# 02 ui -------------------------------------------------------------------


# header
header <- dashboardHeader(
  # Disable header
  #disable = TRUE
  
  title = "SIR",
  titleWidth = 300,
  
  # A message drop down menu
  # dropdownMenu(
  #   type = "messages",
  #   messageItem(
  #     from = "Lu", message = "Hi", 
  #     href = "https://demo.gov/"
  #   ),
  #   messageItem(from = "Ted", message = "Learn more")
  # ),
  
  # A notification drop down menu
  dropdownMenu(
    type = "notifications",
    notificationItem(
      text = "Question or suggestion?",
      icon = icon("poo-storm"),
      href = "mailto: chsueh@hzo.com"
    )
  )
  
  # # A tasks drop down menu
  # dropdownMenu(
  #     type = "tasks",
  #     taskItem(text = "Mission Learn Shiny Dashboard", value = 10)
  # )
)



# sidebar
sidebar <- dashboardSidebar(
  width = 300,
  #tags$head(tags$style(HTML(my_css))),
  
  # sidebarMenu(
  #     # menuItem
  #     menuItem(text = "Dashboard", tabName = "dashboard"),
  #     menuItem(text = "Inputs", tabName = "inputs")
  # ),
  
  fileInput('file', 'Choose SIR files', multiple = TRUE, accept = c(".xlsm", "xlsx")),
  
  # Test structure
  uiOutput("radioButtons"),
  
  # Coating Dates
  uiOutput("checkBoxGroup")
  
)



# body
body <- dashboardBody(
  
  ### changing theme
  shinyDashboardThemes(theme = "grey_light"),
  
  
  tags$head(
    tags$style(HTML("
      .shiny-output-error-validation {
        color: #ff0000;
        font-weight: bold;
      }
    "))
  ),
  
  
  tabBox(
    id = "tabset1", selected = "Tab1", #title = "", 
    height = "250px", width = 12,
    tabPanel(
      title = "3D scatter plot", value = "Tab1",
      textOutput("text"),
      plotlyOutput("plot3d"),
      #DTOutput("table")
    ),
    tabPanel(
      title = "Data", value = "Tab2", 
      DTOutput("table")
    )
  )
)



# ui
ui <- dashboardPage(header, sidebar, body)



# 03 - server -------------------------------------------------------------


# Define server logic required to draw a histogram
server <- function(input, output) {
  options(shiny.maxRequestSize = 30*1024^2)
  
  rx_data <- reactive({
    req(input$file)
    
    # read the selected data file
    df <- input$file$datapath %>% 
      set_names(input$file$name) %>% 
      map_dfr(SIR_read.summary, .id = "File") %>% 
      SIR_tidy.summary() 
  })
  
  rx_data2 <- reactive({
    req(input$Structure)
    
    rx_data() %>% 
      filter(
        `Test Structure` == input$Structure,
        `Coating Date` %in% input$Dates
      )
    
  })
  
  
  output$radioButtons <- renderUI({
    choices <- rx_data()$`Test Structure` %>% unique()
    radioButtons("Structure", "Test Structure", choices = choices)
  })
  
  output$checkBoxGroup <- renderUI({
    choices <- rx_data()$`Coating Date` %>% unique()
    checkboxGroupInput("Dates", "Coating Dates", choices = choices, selected = choices)
  })
  
  
  
  output$text <- renderText({
    validate(
      need(input$Structure, "")
    )
    
    "Test Structure: " %&% input$Structure
  })
  
  #output$filelist <- renderDT(input$file)
  
  output$table <- renderDT({
    dt <- rx_data2() %>%
      select(`Test ID`, `Coating Code/Description`, Location, 10:13) %>% 
      datatable(
        options = list(
          pageLength = -1, info = FALSE,
          lengthMenu = list(c(16, -1), c("16", "All")), 
          order = list(list(4, 'asc'), list(1, 'desc')),
          rownames= FALSE
        )
      )
  })
  
  output$plot3d <- renderPlotly({
    req(input$Structure)
    
    validate(
      need(input$Dates, "Please select at least one coating date.")
    )
    
    rx_data2() %>% SIR_plot3D.summary()
  })
  
  
}



# 04 app ------------------------------------------------------------------


# Run the application 
shinyApp(ui = ui, server = server) %>% runApp(launch.browser = TRUE)
