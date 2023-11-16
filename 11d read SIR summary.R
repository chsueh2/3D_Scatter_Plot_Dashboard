# Created: 210121
# process SIR data
# Updated: 210216


# 00 Setups ---------------------------------------------------------------
# specify directory of data files
# to choose directory interactively, use f_dir <- NA
#f_dir <- NA
f_dir <- here("data")



# 01 Read SIR data file ---------------------------------------------------

# choose directory of data files and get file list
if(f_dir %>% is_na()){
  f_file <- file.choose()
  f_dir <- f_file %>% dirname()
}
  
# list files for selection
list.files(path = f_dir, pattern = "^\\w.*\\.(csv|xls|xlsx|xlsm)$") %>% print()

# select data files
f_files <-
  # option 1: select some
  #1:5 %>% list.files(path = f_dir, pattern = "^\\w.*\\.(csv|xls|xlsx|xlsm)$")[.] %>% 
  # option 2: select all
  list.files(path = f_dir, pattern = "^\\w.*\\.(csv|xls|xlsx|xlsm)$") %>% 
  here(f_dir, .) %>% 
  print()


# read the selected data file
df_raw <- f_files %>% 
  set_names() %>% 
  map_dfr(SIR_read.summary, .id = "File")


# 02 Extract run information ----------------------------------------------


# prepare data for plotting
df <- df_raw %>% SIR_tidy.summary()


# save data
saveRDS(df, here("SIR_summary.rds"))



# 03 Plot 3d --------------------------------------------------------------


unique(df$`Test ID`)
unique(df$`Coating Date`)

p <- df %>% 
  #filter(`Test Structure` == "0603s") %>% 
  #filter(`Test ID` == "Test0210" & `Test Structure` == "0603s") %>% 
  #filter(`Coating Date` == "20210113" & `Test Structure` == "0603s") %>% 
  #filter(`Coating Date` == "20210115" & `Test Structure` == "0603s") %>% 
  filter(`Coating Date` == "20210121" & `Test Structure` == "0603s") %>% 
  SIR_plot3D.summary()

p


# view at different camera (eye) position
p1 <- p %>% SIR_view3D(1) %>% print()
p2 <- p %>% SIR_view3D(2) %>% print()
p3 <- p %>% SIR_view3D(3) %>% print()



# 04 Save plots -----------------------------------------------------------

# save 3d plot in a self-contained html
htmlwidgets::saveWidget(p, here("plots", "ZZZ Test0206.html"), title = "Test0206")






