#' pec_dash UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny fluidRow column selectInput
#'   conditionalPanel checkboxInput actionButton tags
#'   reactive NS tagList moduleServer br downloadButton downloadHandler
#'   renderUI req safeError uiOutput withProgress
#' @importFrom utils head
#' @importFrom stats sd
#' @importFrom zoo as.Date as.yearmon
#' @importFrom plotly ggplotly renderPlotly layout
#' @importFrom grDevices dev.off pdf postscript
#' @importFrom shinyWidgets pickerInput
#' @importFrom DT renderDT dataTableOutput datatable
#' @importFrom bs4Dash box boxSidebar boxPad
#' @import dplyr tidyr ggplot2
mod_pec_dash_ui <- function(id){
  ns <- shiny::NS(id)
  shiny::tagList(

    ## fluidRow start ----
    shiny::fluidRow(
      shinyjs::useShinyjs(),
      shiny::column(9,
             ## Box start start ----
             bs4Dash::box(width = NULL,
                 closable = FALSE,
                 collapsible = TRUE,
                 maximizable = TRUE,
                 ## Sidebar ----
                 sidebar = bs4Dash::boxSidebar(
                   startOpen = TRUE,
                   id = "pecsidebar11",
                  shiny::br(),
                   bs4Dash::boxPad(
                     width = 8,
                     shiny::fluidRow(
                       shiny::column( width = 4,
                               shinyWidgets::pickerInput(
                                 inputId = ns("selFeature"),
                                 label = "Compare",
                                 choices = c("Compound" = "compound",
                                             "Matrices" = "matrices",
                                             "Site" = "site"
                                 ),
                                 choicesOpt = list(
                                   icon = c("fas fa-capsules",
                                            "fas fa-water",
                                            "fas fa-map-marker-alt"
                                   )
                                 )
                               )
                       ),
                       shiny::column( width = 4,
                               shinyWidgets::pickerInput(
                                 inputId = ns("select_plot"),
                                 label = "Plot type:",
                                 choices = c("Monthly" = "bar",
                                             "Selected Period" = "box"
                                 ),
                                 choicesOpt = list(
                                   icon = c("fas fa-chart-column",
                                            "fas fa-chart-gantt"
                                   ) )
                               )
                       ),
                     ),
                     shiny::dateRangeInput(ns('date_range'),
                                           label = 'Date range (yyyy-mm-dd):',
                                           start ="2014-12-31",
                                           end = Sys.Date() + 2
                     ),
                    shiny::uiOutput(ns("selz_type_pec")),
                    shiny::selectInput(
                       ns('select_target'),
                       'Target type:',
                       c(
                         'Compound' = 'Compound'
                       ),
                       selected = 'Compound'
                     ),
                    shiny::uiOutput(ns("selz_y_pec")),
                    shiny::uiOutput(ns("selz_site_pec")),
                    shiny::uiOutput(ns("selz_compound_pec")),
                    shiny::actionButton(inputId = ns("gen_plot"),
                                  label = "Generate Graph",
                                  class="btn btn-success action-button")
                   )
                 ),
                 shiny::fluidRow(
                   shiny::column(
                     width = 12,
                    shiny::conditionalPanel("input.select_plot == 'bar'", ns = ns,
                    shiny::conditionalPanel("input.selFeature == 'compound'", ns = ns,
                                      plotly::plotlyOutput(ns("pec_plot_bar01"), height="600px"),
                                      ),
                    shiny::conditionalPanel("input.selFeature == 'matrices'", ns = ns,
                                      plotly::plotlyOutput(ns("pec_plot_bar02"), height="600px")),
                    shiny::conditionalPanel("input.selFeature == 'site'", ns = ns,
                                      plotly::plotlyOutput(ns("pec_plot_bar03"), height="600px"))
                     ),
                    shiny::conditionalPanel("input.select_plot == 'box'", ns = ns,
                                     shiny::conditionalPanel("input.selFeature == 'compound'", ns = ns,
                                                       plotly::plotlyOutput(ns("pec_plot_box01"), height="600px"),
                                      ),
                                     shiny::conditionalPanel("input.selFeature == 'matrices'", ns = ns,
                                                       plotly::plotlyOutput(ns("pec_plot_box02"), height="600px")),
                                     shiny::conditionalPanel("input.selFeature == 'site'", ns = ns,
                                                       plotly::plotlyOutput(ns("pec_plot_box03"), height="600px"))
                     ),
                     shiny::tags$hr(),
                    shiny::uiOutput(ns("uidownload_btn")),
                     shiny::tags$hr(),
                    shiny::checkboxInput(ns("pec_show_tab"),
                                   label = "Show Datatable", value = FALSE),
                    shiny::conditionalPanel(
                       "input.pec_show_tab == true",  ns =ns,
                       DT::dataTableOutput(ns("tab_plot_data"))
                     )
                   ) # End of Column
                 ) # End of Fluid row
             )## End of Box
      )# End of column
    )

  )
}

#' pec_dash Server Functions
#'
#' @noRd
mod_pec_dash_server <- function(id,
                                presc_dat,
                                table_dt,
                                sel_target,
                                api_family,
                                wwtp_info,
                                re_info,
                                fx_info,
                                global){
  shiny::moduleServer( id, function(input, output, session){
    ns <- session$ns
    global <- global

    getData <- reactive ({

     shiny::req(presc_dat$presc_data_full())
     shiny::req(api_family$up_file)
     shiny::req(wwtp_info$up_file)
     shiny::req(re_info$up_file)
     shiny::req(fx_info$up_file)


      api_family_inFile <- api_family$up_file
      wwtp_info_inFile <- wwtp_info$up_file
      re_info_inFile <- re_info$up_file
      fx_info_inFile <- fx_info$up_file

      api_family_fn <- file_input(name = api_family_inFile$name,
                                  path = api_family_inFile$datapath)

      wwtp_info_fn <- file_input(name = wwtp_info_inFile$name,
                                 path = wwtp_info_inFile$datapath)

      re_info_fn <- file_input(name = re_info_inFile$name,
                                 path = re_info_inFile$datapath)

      fx_info_fn <- file_input(name = fx_info_inFile$name,
                               path = fx_info_inFile$datapath)

      presc_data <- presc_dat$presc_data_full()

    return(
        list(
          dt_presc_full = presc_data,
          apifamily = api_family_fn$dataInput,
          reinfo = re_info_fn$dataInput,
          fexcretainfo = fx_info_fn$dataInput,
          wwtpinfo = wwtp_info_fn$dataInput %>%
            dplyr::mutate(Year = zoo::as.yearmon(Year, "%Y")) %>%
            dplyr::mutate(Year = format(Year, format ="%Y"))
        )
      )
    })

    perk_inputs <-shiny::reactive({
     shiny::req(table_dt$up_file)
     shiny::req(api_family$up_file)

      site_id <- input$pec_site_select
      cpd_name <- input$selz_cpd
      PEC_Key <- input$yaxis_pec
      EV_Type <- input$pec_env_type

      ggplot_dark_theme <-
        ggplot2::theme(axis.text.x = ggplot2::element_text(size = 12, angle = 45, hjust = 1, colour = "snow"),
                       axis.text.y = ggplot2::element_text(size = 12, colour = "snow"),
                       axis.title.x = ggplot2::element_text(size = 15, face = "bold", colour = "snow" ),
                       axis.title.y = ggplot2::element_text(size = 15, face = "bold", colour = "snow" ),
                       panel.background = ggplot2::element_rect(fill = "transparent"), # bg of the panel
                       plot.background = ggplot2::element_rect(fill = "transparent", color = NA), # bg of the plot
                       panel.grid.major = ggplot2::element_line(color = "#42484e", size = 0.4), # get rid of major grid
                       panel.grid.minor = ggplot2::element_line(color = "#42484e", size = 0.3), # get rid of minor grid
                       strip.background = ggplot2::element_rect(color="snow",
                                                                fill="transparent"),
                       strip.text.x = ggplot2::element_text(size = 15, color = "snow"),
                       strip.text.y = ggplot2::element_text(size = 15, color = "snow"),
                       legend.title= ggplot2::element_text(size = 12, colour = "snow"),
                       legend.background = ggplot2::element_rect(fill = "transparent"), # get rid of legend bg
                       legend.box.background = ggplot2::element_rect(fill = "transparent") ,# get rid of legend panel bg
                       legend.text = ggplot2::element_text(size = 12, colour = "snow") ,
                       title = ggplot2::element_text(size = 12, color = "snow")
        )

      ggplot_light_theme <-
        ggplot2::theme(axis.text.x = ggplot2::element_text(size = 12, angle = 45, hjust = 1, colour = "black"),
                       axis.text.y = ggplot2::element_text(size = 12, colour = "black"),
                       axis.title.x = ggplot2::element_text(size = 15, face = "bold", colour = "black"),
                       axis.title.y = ggplot2::element_text(size = 15, face = "bold", colour = "black"),
                       panel.background = ggplot2::element_rect(fill = "transparent"), # bg of the panel
                       plot.background = ggplot2::element_rect(fill = "transparent", color = NA), # bg of the plot
                       panel.grid.major = ggplot2::element_line(color = "gray93", size = 0.4), # get rid of major grid
                       panel.grid.minor = ggplot2::element_line(color = "gray93", size = 0.3), # get rid of minor grid
                       strip.background = ggplot2::element_rect(colour="black",
                                                                fill="transparent"),
                       strip.text.x = ggplot2::element_text(size = 15, color = "black"),
                       strip.text.y = ggplot2::element_text(size = 15, color = "black"),
                       legend.title= ggplot2::element_text(size = 12, colour = "black"),
                       legend.background = ggplot2::element_rect(fill = "transparent"), # get rid of legend bg
                       legend.box.background = ggplot2::element_rect(fill = "transparent") ,# get rid of legend panel bg
                       legend.text = ggplot2::element_text(size = 12, colour = "black"),
                       title = ggplot2::element_text(size = 12, color = "black")
        )
      return(
        list(
          site_id = site_id,
          cpd_name = cpd_name,
          ggplot_dark_theme = ggplot_dark_theme,
          ggplot_light_theme = ggplot_light_theme,
          PEC_Key = PEC_Key,
          EV_Type =  EV_Type
        )
      )
    })

    prediction_full <-shiny::reactive({

     shiny::req(getData()$dt_presc_full)
     shiny::req(getData()$apifamily)
     shiny::req(getData()$wwtpinfo)
     shiny::req(getData()$reinfo)
     shiny::req(getData()$fexcretainfo)

      df <- getData()$dt_presc_full
      api <- getData()$apifamily
      wwtp <- getData()$wwtpinfo
      re <-  getData()$reinfo
      fexcreta <-  getData()$fexcretainfo

      pec_sd_01 <- df %>%
        tidyr::separate(date, c("month", "Year"), sep = " ", remove = FALSE) %>%
        dplyr::left_join(dplyr::select(wwtp, c("Total_PE","catchment", "Year")), by = c("catchment", "Year")) %>%
        dplyr::left_join(fexcreta, by = "Compound") %>%
        dplyr::left_join(dplyr::select(re, c("Compound", "catchment", "rm_eff", "rm_eff_SD" )), by = c("Compound", "catchment")) %>%
        dplyr::mutate(WWinhab = 150,
                      dil_avg =  10,
                      PEC0I_influent_Concentration =(((kgmonth_SM*1000000000000)/(Total_PE*30.4167))/WWinhab)*(high/100),
                      PEC0II_influent_Concentration =(((kgmonth_YA*1000000000000)/(Total_PE*30.4167))/WWinhab)*(high/100),
                      PEC0I_influent_SD = sqrt( kgmonth_SD^2),
                      PEC0II_influent_SD = sqrt( kgmonth_YD^2),
                      PEC0I_effluent_Concentration = (PEC0I_influent_Concentration * (1-(rm_eff/100))), # need to work on this - effluent
                      PEC0II_effluent_Concentration = (PEC0II_influent_Concentration * (1-(rm_eff/100))),# need to work on this - effluent
                      PEC0I_effluent_SD = sqrt( PEC0I_influent_SD^2 + rm_eff_SD^2 ),
                      PEC0II_effluent_SD = sqrt( PEC0II_influent_SD^2 + rm_eff_SD^2),
                      PEC0I_riverdown_Concentration = PEC0I_effluent_Concentration/dil_avg, # need to work on the dilution factor
                      PEC0II_riverdown_Concentration = PEC0II_effluent_Concentration/dil_avg,
                      PEC0I_riverdown_SD = sqrt( PEC0I_effluent_SD^2  ),
                      PEC0II_riverdown_SD = sqrt( PEC0II_effluent_SD^2 )
        )

      pred_full_sd <-  pec_sd_01 %>%
          dplyr::select(-c(kgmonth_SM,kgmonth_SD,
                           kgmonth_YA, kgmonth_YD,
                           PNDP_SM, PNDP_YA,
                           kg_year, high,
                           low, avg,
                           dil_avg, month,
                           Year, Total_PE,
                           rm_eff_SD,
                           rm_eff, WWinhab
          )) %>%
          tidyr::pivot_longer(
            cols = -c(Compound,catchment, date, PERIOD),
            names_to = c("compare", "Type", "outcome"),
            names_pattern = "(.*)_(.*)_(.*)",
            values_to = "Concentrations"
          ) %>%
          tidyr::unite(key, c(compare, outcome), sep = "_") %>%
          tidyr::pivot_wider(names_from = key,
                             values_from =Concentrations) %>%
          tidyr::pivot_longer(
            cols = -c(Compound,catchment, date, PERIOD, Type),
            names_to = c("PEC_Key", "Measure_Type"),
            names_pattern = "(.*)_(.*)",
            values_to = "values"
          ) %>%
          dplyr::mutate(PEC_Key = replace(PEC_Key, PEC_Key == "PEC0I","PEC_I"),
                        PEC_Key = replace(PEC_Key, PEC_Key == "PEC0II","PEC_II"),
                        Measure_Type = replace(Measure_Type, Measure_Type == "Concentration","PEC_Concentration"),
                        Measure_Type = replace(Measure_Type, Measure_Type == "SD","PEC_SD")) %>%
          tidyr::pivot_wider(names_from = Measure_Type, values_from = values, values_fill = 0) %>%
          dplyr::mutate(Type = replace(Type, Type == "influent","INF")) %>%
          dplyr::mutate(Type = replace(Type, Type == "effluent","EFF")) %>%
          dplyr::mutate(Type = replace(Type, Type == "riverdown","RDOWN"))

      return(
        list(
          df_full = df,
          pec_sd_01 = pec_sd_01,
          pred_full_sd = pred_full_sd
        )
      )

    })

    plot_data <-shiny::reactive({
     shiny::req(prediction_full()$pred_full_sd)
     shiny::req(perk_inputs()$cpd_name)
     shiny::req(perk_inputs()$site_id)
     shiny::req(perk_inputs()$PEC_Key)
     shiny::req(perk_inputs()$EV_Type)

      cpdname <- perk_inputs()$cpd_name
      sitename <- perk_inputs()$site_id
      PECKey <- perk_inputs()$PEC_Key
      EVType <- perk_inputs()$EV_Type

      df01 <- prediction_full()$pred_full_sd
      tryCatch(
        {
          df <- df01 %>%
            dplyr::filter(Compound %in% cpdname) %>%
            dplyr::filter(PEC_Key %in% PECKey) %>%
            dplyr::filter(catchment %in% sitename) %>%
            dplyr::filter(Type %in% EVType) %>%
            dplyr::filter(PERIOD > !!input$date_range[1] & PERIOD < !!input$date_range[2])

        },
        error = function(e) {
          stop(shiny::safeError(e))
        }
      )
    })

    # bar plot - Compound ----
    output$pec_plot_bar01 <- plotly::renderPlotly (
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(perk_inputs()$cpd_name)
       shiny::req(perk_inputs()$site_id)
       shiny::req(perk_inputs()$PEC_Key)
       shiny::req(perk_inputs()$EV_Type)
       shiny::req(plot_data())
       shiny::req(perk_inputs()$ggplot_dark_theme)
       shiny::req(perk_inputs()$ggplot_light_theme)

        cpdname <- perk_inputs()$cpd_name
        sitename <- perk_inputs()$site_id
        PECKey <- perk_inputs()$PEC_Key
        EVType <- perk_inputs()$EV_Type
        ggplot_light <- perk_inputs()$ggplot_light_theme
        ggplot_dark <- perk_inputs()$ggplot_dark_theme

        plot01 <- plotly::plot_ly(plot_data(),
                                  x = ~ PERIOD, y = ~PEC_Concentration,
                                  color = ~Compound,
                                  type = "bar",
                                  marker = list(
                                    line = list(color =input$colPlotOutline ,
                                                width = input$widthPlotOutline)),
                                  error_y = ~list(array = PEC_SD,
                                                  color =input$colPlotOutline)
                                  ) %>%
          plotly::layout(
            title = list(
              text =  paste('Predicted Concentrations (ng/L) of pharmaceutical in <br>',
                            EVType, 'at WWTP',sitename)
            ),
            legend = list(title=list(text='<b> Compounds</b>')),
            paper_bgcolor = "transparent", plot_bgcolor = "transparent",
            xaxis = list(
              title='Period (Month Year)',
              type = 'date',
              tickformat = "%B %Y"),
            yaxis = list(
              title=paste('<b>',PECKey,'<br> Concentration (ng/L) <br> </b>'))
          )

        plot01
        if (global$dark_mode == TRUE)
        {
          plot01 <- plot01 %>%
            plotly::layout(
              title = list(
                font = list(
                  color = "#C6C8C9")),
              xaxis = list(
                color = "#C6C8C9"),
              yaxis = list(
                color = "#C6C8C9"),
              legend = list(
                font = list(
                  color = "#C6C8C9")
              ))
        }
        else
        {
          plot01
        }
        })
    )

    # bar plot - matrices ----
    output$pec_plot_bar02 <- renderPlotly (
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(perk_inputs()$cpd_name)
       shiny::req(perk_inputs()$site_id)
       shiny::req(perk_inputs()$PEC_Key)
       shiny::req(plot_data())

        cpdname <- perk_inputs()$cpd_name
        sitename <- perk_inputs()$site_id
        PECKey <- perk_inputs()$PEC_Key

        plot01 <- plotly::plot_ly(plot_data(),
                                  x = ~ PERIOD, y = ~PEC_Concentration,
                                  color = ~Type,
                                  type = "bar",
                                  marker = list(
                                    line = list(color =input$colPlotOutline ,
                                                width = input$widthPlotOutline)),
                                  error_y = ~list(array = PEC_SD,
                                                  color =input$colPlotOutline)
        ) %>%
          plotly::layout(
            title = list(
              text =  paste('Predicted Concentrations (ng/L) of',cpdname,
                            '<br>', 'in different matrices at WWTP',sitename)
            ),
            legend = list(title=list(text='<b> WWTP</b>')),
            paper_bgcolor = "transparent", plot_bgcolor = "transparent",
            xaxis = list(
              title='<b> Period (Month Year) </b>',
              type = 'date',
              tickformat = "%B %Y"),
            yaxis = list(
              title=paste('<b>',PECKey,'<br> Concentration (ng/L) <br> </b>'))
          )

        if (global$dark_mode == TRUE)
        {
          plot01 <- plot01 %>%
            plotly::layout(
              title = list(
                font = list(
                  color = "#C6C8C9")),
              xaxis = list(
                color = "#C6C8C9"),
              yaxis = list(
                color = "#C6C8C9"),
              legend = list(
                font = list(
                  color = "#C6C8C9")
              ))
        }
        else
        {
          plot01
        }
      })
    )

    # bar plot - site ----
    output$pec_plot_bar03 <- renderPlotly (
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(perk_inputs()$cpd_name)
       shiny::req(perk_inputs()$site_id)
       shiny::req(perk_inputs()$PEC_Key)
       shiny::req(perk_inputs()$EV_Type)
       shiny::req(plot_data())

        cpdname <- perk_inputs()$cpd_name
        sitename <- perk_inputs()$site_id
        PECKey <- perk_inputs()$PEC_Key
        EVType <- perk_inputs()$EV_Type

        plot01 <- plotly::plot_ly(plot_data(),
                                  x = ~ PERIOD, y = ~PEC_Concentration,
                                  color = ~catchment,
                                  #colors = color_palette(),
                                  type = "bar",
                                  marker = list(
                                    line = list(color =input$colPlotOutline ,
                                                width = input$widthPlotOutline)),
                                  error_y = ~list(array = PEC_SD,
                                                  color =input$colPlotOutline)
        ) %>%
          plotly::layout(
            title = list(
              text =  paste('Predicted Concentrations (ng/L) of',cpdname, '<br>', 'in',
                            EVType, 'at studied WWTPs')
            ),
            legend = list(title=list(text='<b>WWTP</b>')),
            paper_bgcolor = "transparent", plot_bgcolor = "transparent",
            xaxis = list(
              title='<b> Period (Month Year) </b>',
              type = 'date',
              tickformat = "%B %Y"),
            yaxis = list(
              title=paste('<b>',PECKey,'<br> Concentration (ng/L) <br> </b>'))
          )

        if (global$dark_mode)
          plot01 <- plot01 %>%
          plotly::layout(
            title = list(
              font = list(
                color = "#C6C8C9")),
            xaxis = list(
              color = "#C6C8C9"),
            yaxis = list(
              color = "#C6C8C9"),
            legend = list(
              font = list(
                color = "#C6C8C9")
            ))
        else

          plot01
      })
    )

    # box plot - Compound ----
    pec_box <-shiny::reactive({
     shiny::req(perk_inputs()$cpd_name)
     shiny::req(perk_inputs()$site_id)
     shiny::req(perk_inputs()$PEC_Key)
     shiny::req(perk_inputs()$EV_Type)
     shiny::req(plot_data())
     shiny::req(perk_inputs()$ggplot_dark_theme)
     shiny::req(perk_inputs()$ggplot_light_theme)

      cpdname <- perk_inputs()$cpd_name
      sitename <- perk_inputs()$site_id
      PECKey <- perk_inputs()$PEC_Key
      EVType <- perk_inputs()$EV_Type
      ggplot_dark <- perk_inputs()$ggplot_dark_theme
      ggplot_light <- perk_inputs()$ggplot_light_theme

      plot01 <- ggplot2::ggplot(data=plot_data(),
                                ggplot2::aes(x=Compound, y=PEC_Concentration,fill = Compound)) +
        ggplot2::geom_boxplot(position = ggplot2::position_dodge(0.75)) +
        ggplot2::stat_boxplot(geom = "errorbar",
                              position = ggplot2::position_dodge(0.75)) +
        #scale_fill_manual(values = color_palette_ggplot()) +
        ggplot2::labs(title = paste("Predicted Concentrations (ng/L) of", cpdname, "in" ,
                                    EVType,
                                    "at selected WWTPs"),
                      subtitle = "PC (ng/L)",
                      x = "Date", y = "Concentration")+
        ggplot2::theme_bw()+
        ggplot2::theme(
          plot.title = ggplot2::element_text(size = 16, face = "bold"  , hjust = 0.5 ),
          axis.title.x = ggplot2::element_text(size = 14, face = "bold"   ),
          axis.title.y = ggplot2::element_text(size = 14, face = "bold"   ),
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 12  ),
          axis.text.y = ggplot2::element_text(size = 12 ),
          legend.text = ggplot2::element_text(size = 8 ),
          legend.title = ggplot2::element_text(size = 10, face = "bold"   )
        )

      plot02 <- ggplot2::ggplot(data=plot_data(),
                                ggplot2::aes(x=Compound, y=PEC_Concentration,
                                             fill = Type)) +
        ggplot2::geom_boxplot(position = ggplot2::position_dodge(0.75)) +
        ggplot2::stat_boxplot(geom = "errorbar",
                              position = ggplot2::position_dodge(0.75)) +
        #scale_fill_manual(values = color_palette_ggplot()) +
        ggplot2::labs(title = paste("Predicted Concentrations (ng/L) of",cpdname,"in different",
                                    "at WWTP",sitename),
                      subtitle = "PC (ng/L)",
                      x = "Date", y = "Concentration")+
        ggplot2::theme_bw()+
        ggplot2::theme(
          plot.title = ggplot2::element_text(size = 16, face = "bold"  , hjust = 0.5 ),
          axis.title.x = ggplot2::element_text(size = 14, face = "bold"   ),
          axis.title.y = ggplot2::element_text(size = 14, face = "bold"   ),
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 12  ),
          axis.text.y = ggplot2::element_text(size = 12 ),
          legend.text = ggplot2::element_text(size = 8 ),
          legend.title = ggplot2::element_text(size = 10, face = "bold"   )
        )

      plot03 <- ggplot2::ggplot(data=plot_data(),
                                ggplot2::aes(x=Compound, y=PEC_Concentration, fill = catchment)) +
        ggplot2::geom_boxplot(position = ggplot2::position_dodge(0.75) ) +
        ggplot2::stat_boxplot(geom = "errorbar",
                              position = ggplot2::position_dodge(0.75) ) +
        #scale_fill_manual(values = color_palette_ggplot()) +
        ggplot2::labs(title = paste("Predicted Concentrations (ng/L) of", cpdname, "in", EVType,
                                    "at selected WWTPs"),
                      subtitle = "PC (ng/L)",
                      x = "Date", y = "Concentration")+
        ggplot2::theme_bw()+
        ggplot2::theme(
          plot.title = ggplot2::element_text(size = 16, face = "bold"  , hjust = 0.5 ),
          axis.title.x = ggplot2::element_text(size = 14, face = "bold"   ),
          axis.title.y = ggplot2::element_text(size = 14, face = "bold"   ),
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 12  ),
          axis.text.y = ggplot2::element_text(size = 12 ),
          legend.text = ggplot2::element_text(size = 8 ),
          legend.title = ggplot2::element_text(size = 10, face = "bold"   )
        )

      return(
        list(
          plot01 = plot01,
          plot02 = plot02,
          plot03 = plot03
        )
      )
    })

    output$pec_plot_box01 <- renderPlotly (
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(pec_box()$plot01)
       shiny::req(perk_inputs()$ggplot_dark_theme)
       shiny::req(perk_inputs()$ggplot_light_theme)

        plot01 <- pec_box()$plot01
        ggplot_dark <- perk_inputs()$ggplot_dark_theme
        ggplot_light <- perk_inputs()$ggplot_light_theme

        plotly::ggplotly(
          if (global$dark_mode) plot01 + ggplot_dark
          else plot01 + ggplot_light
          )
      })
    )

    # box plot - Matrices ----
    output$pec_plot_box02 <- renderPlotly (
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(pec_box()$plot02)
       shiny::req(perk_inputs()$ggplot_dark_theme)
       shiny::req(perk_inputs()$ggplot_light_theme)

        plot02 <- pec_box()$plot02
        ggplot_dark <- perk_inputs()$ggplot_dark_theme
        ggplot_light <- perk_inputs()$ggplot_light_theme

        plotly::ggplotly(
          if (global$dark_mode) plot02 + ggplot_dark
          else plot02 + ggplot_light
        )
      })
    )

    # box plot - Site ----
    output$pec_plot_box03 <- renderPlotly (
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(pec_box()$plot03)
       shiny::req(perk_inputs()$ggplot_dark_theme)
       shiny::req(perk_inputs()$ggplot_light_theme)

        plot03 <- pec_box()$plot03
        ggplot_dark <- perk_inputs()$ggplot_dark_theme
        ggplot_light <- perk_inputs()$ggplot_light_theme

        plotly::ggplotly(
          if (global$dark_mode) plot03 + ggplot_dark
          else plot03 + ggplot_light
          )
      })
    )

    catchment <-shiny::reactive({
     shiny::req(table_dt$up_file)
      tryCatch(
        {
          df <- readr::read_csv(table_dt$up_file$datapath) %>%
            dplyr::select(catchment) %>%
            unique()

        },
        error = function(e) {
          stop(shiny::safeError(e))
        }
      )
    })

    targets <-shiny::reactive({

     shiny::req(sel_target$up_file)
      tryCatch(
        {
          df <- readr::read_csv(sel_target$up_file$datapath)
        },
        error = function(e) {
          stop(shiny::safeError(e))
        }
      )
    })

    # UI Output - Compounds ----
    output$selz_compound_pec <- shiny::renderUI({
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(api_family$up_file)
       shiny::req(targets()$Compound)
       shiny::req(input$selFeature)

        target_cpd <- unique(targets()$Compound)

        if(input$selFeature %in% c("site","matrices" ))
        {
         shiny::selectInput(inputId= ns("selz_cpd"),
                      label="Select Compound:",
                      choices= target_cpd
          )
        }
        else {
          shinyWidgets::pickerInput(
            inputId =  ns("selz_cpd"),
            label = "Select Compound(s):",
            choices= target_cpd,
            options = list(`actions-box` = TRUE),
            multiple = TRUE,
            selected = head(target_cpd,1)
          )
        }
      })
    })

    # UI Output - site ----
    output$selz_site_pec <- shiny::renderUI({
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(table_dt$up_file)
       shiny::req(catchment()$catchment)

        site_name <- unique(catchment()$catchment)

        if(input$selFeature %in% c("site" ))
        {
          shinyWidgets::pickerInput(
            inputId =  ns("pec_site_select"),
            label="Select the site:",
            choices= site_name,
            options = list(`actions-box` = TRUE),
            multiple = TRUE,
            selected = head(site_name,1)
          )
        }
        else{
         shiny::selectInput(
          inputId=ns("pec_site_select"),
          label="Select the site:",
          choices= site_name,
          selected = head(site_name,1)
        )
        }
      })
    })

    # UI Output - Y axis ----
    output$selz_y_pec <- shiny::renderUI({
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(prediction_full()$pred_full_sd)

        df01 <- prediction_full()$pred_full_sd

        PEC_Key <- unique(df01$PEC_Key)

       shiny::selectInput(
          inputId=ns("yaxis_pec"),
          label="Select Y axis:",
          choices= PEC_Key,
          selected = head(PEC_Key,1)
          )
      })
    })

    # UI Output - Type ----
    output$selz_type_pec <- shiny::renderUI({
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

       shiny::req(prediction_full()$pred_full_sd)

        df01 <- prediction_full()$pred_full_sd

        Type <- unique(df01$Type)

        if(input$selFeature %in% c("matrices" ))
        {
          shinyWidgets::pickerInput(
            inputId =  ns("pec_env_type"),
            label="Select Sample Type:",
            choices = Type,
            options = list(`actions-box` = TRUE),
            multiple = TRUE,
            selected = head(Type,1)
          )
        }
        else{
         shiny::selectInput(
            inputId=ns("pec_env_type"),
            label="Select Sample Type:",
            choices= Type,
            selected = head(Type,1)
          )
          }
      })
    })

    # DT - Tab plot data ----
    output$tab_plot_data <- DT::renderDT({
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {

      options(
        DT.options = list(
          pageLength = nrow(plot_data()),
          autoWidth = FALSE,
          scrollX = TRUE,
          scrollY = "600px"
          )
        )

      DT::datatable(plot_data(),
                    filter = "top",
                    rownames = FALSE,
                    caption = 'List of Entries.',
                    options = list(
                      columnDefs = list(
                        list(className = 'dt-center', targets = "_all")))
      )
      })
    })

    # Download Buttons ----
    output$uidownload_btn <- shiny::renderUI({
      shiny::withProgress(message = 'Data is loading, please wait ...', value = 1:100, {
        shiny::tags$span(
         shiny::downloadButton(ns('downloaddata'), 'Download CSV') ,
         shiny::downloadButton(ns('downloadpdf'), 'Download PDF'),
         shiny::downloadButton(ns('downloadeps'), 'Download EPS')
        )
      })
    })

    # Download csv01
    output$downloaddata <-shiny::downloadHandler(
      filename = function (){ paste0('plot_data', '.csv')},
      content = function(file) {
        write_csv(as.data.frame(plot_data()), file)
      }
    )

    # Download PDF
    output$downloadpdf <-shiny::downloadHandler(
      filename = function(){ paste('prescplot.pdf',sep = '')},
      content = function(file) {
        # pdf ----
        pdf(file, paper = "a4r",width = 14)

       shiny::req(pec_box()$plot01)
       shiny::req(pec_box()$plot02)
       shiny::req(pec_box()$plot03)
       shiny::req(perk_inputs()$ggplot_light_theme)

        plot01 <- pec_box()$plot01
        plot02 <- pec_box()$plot02
        plot03 <- pec_box()$plot03

        ggplot_light <- perk_inputs()$ggplot_light_theme

        if(input$select_plot %in% c('box'))
        {
          if(input$selFeature %in% c('compound'))
          print(plot01 + ggplot_light)
        else if(input$selFeature %in% c('matrices'))
          print(plot02 + ggplot_light)
        else if(input$selFeature %in% c( 'site'))
          print(plot03 + ggplot_light)
        }

        dev.off()
      })

    # Download EPS
    output$downloadeps <-shiny::downloadHandler(
      filename = function(){ paste('prescplot.eps',sep = '')},
      content = function(file) {
        # eps ----
        postscript(file,
                   width = 11.69 , height = 8.27, # inches
                   horizontal = TRUE, onefile = TRUE, paper = "special")
        pdf(file, paper = "a4r",width = 14)

       shiny::req(pec_box()$plot01)
       shiny::req(pec_box()$plot02)
       shiny::req(pec_box()$plot03)
       shiny::req(perk_inputs()$ggplot_light_theme)

        plot01 <- pec_box()$plot01
        plot02 <- pec_box()$plot02
        plot03 <- pec_box()$plot03

        ggplot_light <- perk_inputs()$ggplot_light_theme

        if(input$select_plot %in% c('box'))
        {
          if(input$selFeature %in% c('compound'))
            print(plot01 + ggplot_light)
          else if(input$selFeature %in% c('matrices'))
            print(plot02 + ggplot_light)
          else if(input$selFeature %in% c( 'site'))
            print(plot03 + ggplot_light)
        }
        dev.off()
      })

    ## End of Download buttons ---

    # return list ----
    return(
      list(
        pec_data_full =shiny::reactive({
          prediction_full()$df_full}),
        pec_sd = shiny::reactive({
          prediction_full()$pec_sd_01}),
        pred_full =shiny::reactive({
          prediction_full()$pred_full_sd})
      )
    )

  })
}

## To be copied in the UI
# mod_pec_dash_ui("pec_dash_1")

## To be copied in the server
# mod_pec_dash_server("pec_dash_1")
