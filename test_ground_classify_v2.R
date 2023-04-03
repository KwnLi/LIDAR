library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)

# some more required packages
# install.packages("RMCC")
# install.packages("RCSF")

##### File setup #####

# LAS folder path within the directory (above) where the las files are stored
laspath <- "~/Documents/Local_GIS/LiDAR/LAS/Yao/LAS22/filtered2022"  

# farm vector data
farms_poly <- readRDS("~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.rds")

##### Select farm #####
# use this variable to select your target farm
farm <- "UTUA5"

# use the variable to select the buffer size around the farm
bufdist <- 30   # I chose 30 m

# now extract the farm polygon and create a buffered polygon for clipping
farm_aoi <- farms_poly %>% filter(farm_id == farm)
farm_buf <- st_buffer(farm_aoi, dist = bufdist)
farm_ext <- farm_buf %>% st_bbox() %>% st_as_sfc()  # this gets the extents of the buffered polygon

##### Read in LAS data for farm #####
farm_path <- paste(laspath, farm, sep = "/")  # this creates a string for the path to the farm folder
print(farm_path)  # check for correctness

# here are the files in the farm folder
las_files <- list.files(farm_path)
print(las_files)  # check for correctness

# here is a vector of the file paths for each las file
las_filepaths <- paste(farm_path, las_files, sep = "/")
print(las_filepaths)  # check for correctness

# read the las files for the farm into a list object
farm_las <- lapply(las_filepaths, readLAS)  # the 'lapply' function applies the readLAS function over all the filepaths

##### GROUND CLASSIFICATION #####
# this is where ground classification algorithm is conducted
# this code was set up to define the the Zhang et al. parameters first, and then apply to all farm files
# the loop classifies ground for the las files within the list above and creates the cross section

# get cross section function
source("~/Documents/GitHub/LIDAR/functions/function_plotcross.R")

# Zhang method
# define Zhang parameters
b = 1
dh0 = 0.2
s = 1.2
dhmax = 10

pmfparam <- util_makeZhangParam(b = b, dh0 = dh0, s=s, dhmax = dhmax, exp = FALSE)

# Try Zhang method on 1 flight
flight1_zhang <- classify_ground(farm_las[[1]], algorithm = pmf(ws = pmfparam$ws, th = pmfparam$th))

crossect_zhang <- plot_crossection(flight1_zhang, colour_by = factor(Classification)) + 
  ggtitle("Zhang method")  # use the filename as the title

# Try cloth simulation filter
flight1_csf <- classify_ground(farm_las[[1]], algorithm = csf(
  sloop_smooth = FALSE # when TRUE, this is supposed to be on for steep slopes but it didn't help
))

crossect_csf <- plot_crossection(flight1_csf, colour_by = factor(Classification)) + 
  ggtitle("csf method")  # use the filename as the title

# Try Multiscale Curvature Classification
flight1_mcc <- classify_ground(farm_las[[1]], algorithm = mcc()) # left defaults in place

crossect_mcc <- plot_crossection(flight1_mcc, colour_by = factor(Classification)) + 
  ggtitle("csf method")  # use the filename as the title


