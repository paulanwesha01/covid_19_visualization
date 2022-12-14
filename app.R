
install.packages("coronavirus")
install.packages("gridExtra")
install.packages("cowplot")
install.packages("maps")
install.packages("ggExtra")

library(coronavirus)
library(dplyr)
library(tidyr)
library("gridExtra")
library(ggplot2)
library(cowplot)
library("maps")
library(ggExtra)
library(shiny)

data("coronavirus")
data("covid19_vaccine")

world_df <- coronavirus %>% 
            group_by(type, date) %>%
            summarise(total_cases = sum(cases)) %>%
            pivot_wider(names_from = type, values_from = total_cases) %>%
            arrange(date) %>%
            mutate(active = confirmed - death - recovery) %>%
            mutate(active_total = cumsum(active),
                   recovered_total = cumsum(recovery),
                   death_total = cumsum(death))

summary_df <- function(type) {
  coronavirus %>% 
    filter(type == type) %>%
    group_by(country) %>%
    summarise(total_cases = sum(cases)) %>%
    arrange(-total_cases)
}

summary_df2 <- function(type1, type2) {
  coronavirus %>% 
    filter(type == type1 || type == type2) %>%
    group_by(country) %>%
    summarise(total_cases = sum(cases)) %>%
    arrange(-total_cases)
}

world_map <- function(type) {
  options(repr.plot.width = 16, repr.plot.height = 16)
  p <- ggplot(world_df, aes_string("date", type)) +
              geom_bar(stat = "identity") + 
              ggtitle(paste("Cumulative", type, "Cases, Worldwide"))
  p
}

world_comp <- function(type_1, type_2) {
  # print(paste("world_cmp", type_1, type_2))
  g <- ggplot(world_df, aes_string(type_1, type_2)) + 
              geom_count() + 
              ggtitle(paste("Relationship Between", type_1, "and", type_2, "Cases"))

  options(repr.plot.width = 16, repr.plot.height = 16)
  ggMarginal(g, type = "densigram", fill = "pink")
  g
}

province_df <- function(city) {
    df <- coronavirus %>% 
           filter(province == city) %>% 
           filter(type == "confirmed") %>%
           mutate(covid_cases = cumsum(cases))

    select(df, date, covid_cases) %>% filter(covid_cases != 0)
}

province_plot <- function(province) {
  # print(paste("province_plot", province))
  df <- province_df(province)

  options(repr.plot.width = 16, repr.plot.height = 16)
  g <- ggplot(df, aes(date, covid_cases, fill = date)) +  
        geom_bar(stat = "identity") +
        ggtitle(province)
  g
}

vaccine_df <- covid19_vaccine %>% 
              filter(date == max(date), !is.na(population)) %>% 
              mutate(partially_vaccinated_ratio = people_partially_vaccinated / population) %>%
              arrange(- partially_vaccinated_ratio) %>%
              mutate(fully_vaccinated_ratio = people_fully_vaccinated / population) %>%
              arrange(- fully_vaccinated_ratio)

vaccine_df <- vaccine_df %>%
              slice_head(n = 20) %>%
              arrange(fully_vaccinated_ratio) %>%
              mutate(country = factor(country_region, levels = country_region))

vaccine_plot <- function(type) {
  pie_plot = NULL
  if (type == "4") {
    pie_plot <- ggplot(vaccine_df %>% head(20), aes(x ="", y = partially_vaccinated_ratio, fill = country)) +
                geom_bar(stat = "identity", width = 1) +
                coord_polar("y", start = 0)

    # bar_plot <- ggplot(vaccine_df %>% head(20), aes(x = "country", y = people_partially_vaccinated)) +  
    #             geom_bar(stat = "identity") + coord_flip()
  } else {
    pie_plot <- ggplot(vaccine_df %>% head(20), aes(x ="", y = fully_vaccinated_ratio, fill = country)) +
                geom_bar(stat = "identity", width = 1) +
                coord_polar("y", start = 0)

    # bar_plot <- ggplot(vaccine_df %>% head(20), aes(x = "country", y = fully_vaccinated_ratio)) +  
    #             geom_bar(stat = "identity") + coord_flip()   
  }

  options(repr.plot.width = 16, repr.plot.height = 16)
  # plot_grid(pie_plot, bar_plot, ncol = 2, nrow = 1)
  pie_plot
}


ui <- fluidPage(

  titlePanel("Covid"),

  sidebarLayout(

    sidebarPanel(

      tabsetPanel(id = "tab", type = "pills",

        tabPanel(value = 1, "Cases - Worldwide",

          radioButtons(inputId = "world",
                        label = h3("World:"),
                        choices = list(
                                      "Confirmed Cases"     = "1, confirmed",
                                      "Active Cases"        = "1, active_total",
                                      "Recovered Cases"     = "1, recovered_total",
                                      "Death Cases"         = "1, death_total",
                                      "Active vs Death"     = "2, active_total, death_total",
                                      "Active vs Recovered" = "2, active_total, recovered_total",
                                      "Recovered vs Death"  = "2, recovered_total, death_total"),
                      ),
          br()
        ),

        tabPanel(value = 2, "Cases - Countrywise",

          radioButtons(inputId = "province",
                        label = h3("Country: City"),
                        choices = list(
                                      "Canada, Alberta"          = "3, Canada, Alberta",
                                      "Canada, British Columbia" = "3, Canada, British Columbia",
                                      "Canada, Manitoba"         = "3, Canada, Manitoba",
                                      "Canada, Saskatchewan"     = "3, Canada, Saskatchewan",
                                      "Canada, Nova Scotia"      = "3, Canada, Nova Scotia",

                                      "United Kingdom, Anguilla"  = "3, United Kingdom, Anguilla",
                                      "United Kingdom, Bermuda"   = "3, United Kingdom, Bermuda",
                                      "United Kingdom, Guernsey"  = "3, United Kingdom, Guernsey",
                                      "United Kingdom, Jersey"    = "3, United Kingdom, Jersey",
                                      "United Kingdom, Gibraltar" = "3, United Kingdom, Gibraltar",

                                      "China, Beijing"  = "3, China, Beijing",
                                      "China, Fujian"   = "3, China, Fujian",
                                      "China, Gansu"    = "3, China, Gansu",
                                      "China, Hebei"    = "3, China, Hebei",
                                      "China, Hong Kong"= "3, China, Hong Kong",

                                      "Netherlands, Aruba"        = "3, Netherlands, Aruba",
                                      "Netherlands, Curacao"      = "3, Netherlands, Curacao",
                                      "Netherlands, Bonaire, Sint Eustatius and Saba" = "3, Netherlands, Bonaire, Sint Eustatius and Saba",
                                      "Netherlands, Sint Maarten" = "3, Netherlands, Sint Maarten",

                                      "Australia, Queensland"        = "3, Australia, Queensland",
                                      "Australia, South Australia"   = "3, Australia, South Australia",
                                      "Australia, Tasmania"          = "3, Australia, Tasmania",
                                      "Australia, Victoria"          = "3, Australia, Victoria",
                                      "Australia, Western Australia" = "3, Australia, Western Australia"),
                        ),

          br()
        ),

        tabPanel(value = 3, "Vaccine Stats",

          radioButtons(inputId = "vaccine",
                        label = h3("Type:"),
                        choices = list(
                                      "Partially Vaccinated Ratio Plot" = "4",
                                      "Fully Vaccinated Ratio Plot" = "5"),
                        ),

          br()
        )
      )
    ),

    mainPanel(

      tabsetPanel(type = "tabs",
                  tabPanel("Plot", plotOutput("plot")),
                  tabPanel("Summary", verbatimTextOutput("summary")),
                  tabPanel("Table", tableOutput("table"))
      )
    )
  )
)

server <- function(input, output) {

  tp <- reactive({
    input$tab
  })

  world <- reactive({
    strsplit(input$world, ", ")
  })

  province <- reactive({
    strsplit(input$province, ", ")
  })

  vaccine <- reactive({
    input$vaccine
  })

  output$plot <- renderPlot({

    tp <- tp()
    # print("tp value: ")
    # print(tp)

    if (tp == 1) {
      t = world()
      # print(t)  
      if (t[[1]][[1]] == "1") {
        world_map(t[[1]][[2]])
      } else {
        world_comp(t[[1]][[2]], t[[1]][[3]])
      }
    }
    else if (tp == 2) {
      t = province()
      # print(t)
      province_plot(t[[1]][[3]])
    } 
    else {
      vaccine_plot(vaccine())
    }

  }, res = 96)

  output$summary <- renderPrint({

    tp <- tp()
    # print("tp value: ")
    # print(tp)

    if (tp == 1) {
      t = world()
      if (t[[1]][[1]] == "1") {
        summary(summary_df(t[[1]][[2]]))
      } else {
        summary(summary_df2(t[[1]][[2]], t[[1]][[3]]))
      }
    }
    else if (tp == 2) {
      t = province()
      summary(province_df(t[[1]][[3]]))
    } else {
      summary(vaccine_df)
    }    
  })

  output$table <- renderTable({
    tp <- tp()

    if (tp == 1) {
      t = world()

      if (t[[1]][[1]] == "1") {
        summary_df(t[[1]][[2]])
      } else {
        summary_df2(t[[1]][[2]], t[[1]][[3]])
      }
    }
    else if (tp == 2) {
      t = province()
      province_df(t[[1]][[3]])
    } else {
      vaccine_df
    }
  })
}


# if (interactive()) {
  shinyApp(ui = ui, server = server)
# }
