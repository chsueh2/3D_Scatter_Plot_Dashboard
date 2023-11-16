# Created: 190531
# Updated: 210219



#-----------------------------------------------------------
# Packages
#-----------------------------------------------------------
if (!require("pacman")) utils::install.packages("pacman", dependencies = TRUE)
	
pacman::p_load(
  here,
	stats,
	tidyverse, rlang,
	readxl, #vroom,       # fast read large data file 
	lubridate, hms,
	#rebus,					      # build regular expressions using human readable code
	#patchwork,				    # combine separate ggplots
	shiny, shinydashboard, 
  dashboardthemes,
	#flexdashboard,	
	DT,
	#leaflet,
	#htmlwidgets, 			  # used for plotly, leaflet, DT, etc
	plotly       			   	# need orca and the package processx to export plots
)

source(here("01 HZO SIR.R"))



#-----------------------------------------------------------
# Constants
#-----------------------------------------------------------
# save project directory
DIR_PROJECT <- getwd()






#-----------------------------------------------------------
# Helper functions and operators
#-----------------------------------------------------------
# string concatenation
# ex: "act" %&% "5"
'%&%' <- function(x, y) paste0(x, y)


# not %in%
`%not_in%` <- Negate(`%in%`)
# `%not_in%` <- function(lhs, rhs) !(lhs %in% rhs)


# outliers
is_outlier <- function(x) return(x < quantile(x, 0.25) - 1.5 * IQR(x) | x > quantile(x, 0.75) + 1.5 * IQR(x))



# numeric string
is_numstr <- function(x) !is.na(as.numeric(x)) %>% all()
