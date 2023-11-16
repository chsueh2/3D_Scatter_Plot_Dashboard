# Created: 210127
# Updated: 210129
# HZO SIR 



# 01 read SIR summary data ------------------------------------------------


# read SIR summary data from Excel file's summary sheet
# read summary for pass criteria = Limit 10^8 Ω
SIR_read.summary <- function(x){
  # read while table
  df_raw <- read_excel(x, sheet = "Summary", range = "A5:P21")
  
  # extract summary of 0603s
  df1 <- df_raw %>% 
    select(c(2, 9:12)) %>% 
    pivot_longer(
      -1, names_to = "Test Summary Name", values_to = "Test Summary Value", 
      names_pattern = "^(.*)(?=\\.{3})") %>% 
    mutate(`Test Structure` = "0603s")
  
  # extract summary of QFPs
  df2 <- df_raw %>%
    select(c(2, 13:16)) %>%
    pivot_longer(
      -1, names_to = "Test Summary Name", values_to = "Test Summary Value", 
      names_pattern = "^(.*)(?=\\.{3})") %>%
    mutate(`Test Structure` = "QFPs")
  
  # join data and pivot to wide format
  df <- df_raw %>% 
    # leading columns
    select(1:8) %>%
    # test summary columns from 0603s and QFPs
    inner_join(bind_rows(df1, df2)) %>% 
    # pivot to wide format
    pivot_wider(names_from = `Test Summary Name`, values_from = `Test Summary Value`) 
}



# tidy summary data
## add test attributes: test file, ID, date and summary label
## extract location
## drop entries without location info
SIR_tidy.summary <- function(df_raw) {
  df_raw %>% 
    # add test ID, date and summary label
    mutate(
      File = basename(File),
      `Test ID` = str_extract(File, "(Test\\d*)"),
      `Coating Date` = str_extract(`Coating Code/Description`, "(\\d{8})"),
      `Test Summary` = 
        `Coating Code/Description` %&% "\n" %&% 
        "FTTF: " %&% FTTF %&% " mins" %&% "\n" %&% 
        "MTTF: " %&% MTTF %&% " mins" %&% "\n" %&% 
        "Pass Rate: " %&% `% Pass` %&% "%"
    ) %>% 
    # extract sample location
    mutate(
      Location = `Coating Code/Description` %>% 
        str_to_upper() %>% 
        str_extract("\\d[A|B|C|D][F|M|B]"),
      X = Location %>% str_sub(1,1) %>% as.numeric(),
      Y = Location %>% str_sub(3,3) %>% factor(levels = c("F", "M", "B")),
      Z = Location %>% str_sub(2,2) %>% factor(levels = rev(LETTERS[1:4])),
      x = X %>% as.numeric(),
      y = Y %>% as.numeric(),
      z = Z %>% as.numeric()
    ) %>% 
    # drop rows without location
    filter(!is.na(Location))
}





# 02 3d scatter plots -----------------------------------------------------


# Plotly scene setup
plotly_layout.scene <- list(
  xaxis = list(
    title = "Left to Right",
    range = c(1, 9),
    tick0 = 1, 
    dtick = 1, 
    tickmode = "linear"),
  yaxis = list(
    title = "Front to Back",
    range = c(1, 3),
    ticktext = list("F", "M", "B"), 
    tickvals = list(1, 2, 3),
    tickmode = "array"),
  zaxis = list(
    title = "Height",
    range = c(0, 4),
    ticktext = list("D", "C", "B", "A"), 
    tickvals = list(1, 2, 3, 4),
    tickmode = "array"),
  #dragmode = "orbit",
  aspectratio = list(x = 9/8, y = 3/8, z = 4/8),
  camera = list(
    center = list(x = 0, y = 0, z = 0),
    up = list(x = 0, y = 0, z = 1),
    eye = list(x = 1, y = -1, z = 1))
)



# Plot 3D scatter plot
## FTTF mapped to color
## `% Pass` mapped to size
SIR_plot3D.summary <- function(df, title) {
  # plot title
  if(is_missing(title)) {
    title <-  "Coating Date: " %&% SIR_shorten.title(df$`Coating Date`)
  }

  df %>% 
    plot_ly(
      x = ~X, y = ~y, z = ~z, text = ~`Test Summary`, symbol = ~`Test ID`,
      hovertemplate = "%{text}",
      #"%{text}" %&% #"<br>Location: %{x}%{y}%{z}" %&% 
      #"<br>FTTF: %{marker.color} mins" %&% "<br>Pass Rate: %{marker.size}%",
      texttemplate = '%{text}',
      type = "scatter3d", mode = 'markers',
      marker = list(
        color = ~FTTF, colorscale = list(c(0,'#F2F2F2'), c(1,'#00FF00')),
        cauto = F, cmax = 1440, cmin = 0,
        colorbar = list(title = "[mins]"),
        size = ~`% Pass`,
        sizeref = 0.01, sizemode = "area", #sizemin = 0,
        showscale = TRUE)
    ) %>% 
    #add_text(size = 2, textposition = "inside") %>% 
    plotly::layout(
      title = title,
      scene = plotly_layout.scene,
      # force to show lengend even if there is only one group
      showlegend = TRUE,
      legend = list(x = 0, y = .95, orientation = "h")
    )
}



# 03 View 3d plots --------------------------------------------------------



# Presets of camera setups - eye positions
## plotly_camera[[x]]
plotly_camera <- list(
  list(camera = list(eye = list(x = 1, y = -1, z = 1))),  
  list(camera = list(eye = list(x = 0, y = -1.6, z = 0.64))),
  list(camera = list(eye = list(x = 0, y = -0.64, z = 1.6)))
)



# View 3D plot at new viewpoint
## either specify preset camera: preset_camera = 2
## or set new eye position: eye = list(x = x, y = y, z = z)
SIR_view3D <- function(p, preset_camera = 1, eye){
  
  if(!is_missing(eye)){
    scene <- list(camera = list(eye = eye))
  } else {
    scene <- plotly_camera[[preset_camera]] %>% print()
    
  }
  
  plotly::layout(p, scene = scene)
}





# 04 Export plots ---------------------------------------------------------





# 05 Misc -----------------------------------------------------------------


SIR_shorten.title <- function(x, length.max = 60) {
  
  x <- x %>% sort() %>% unique()
  x_punc <- c(rep(",", length(x)-1), "")
  title_whole <- paste0(x, x_punc) %>% paste(collapse = " ")
  
  if(length.max >= str_length(title_whole)){
    title <- title_whole 
  } else if(length.max <= str_length(x[1]) + str_length(last(x)) + 4) {
    title <- x[1] %&% ",... " %&% last(x)
  } else {
    # accumulated length
    accumulated_length <- (str_length(x) + str_length(x_punc)) %>% cumsum()
    
    # length without the last element
    length_without.last <- length.max - str_length(last(x)) - 5
    
    is.included <- accumulated_length <= length_without.last
    
    title <- paste0(x[is.included], x_punc[is.included]) %>% paste(collapse = " ") %&% "... " %&% last(x)
  }
  
  return(title)
}
  
