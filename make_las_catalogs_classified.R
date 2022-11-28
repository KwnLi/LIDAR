library(lidR)
library(tidyverse)
library(fs)
library(sf)

# This code finds and reads in las files and classifies ground and noise

laspath <- "~/Documents/Local_GIS/LiDAR"
setwd(laspath)

# Farm borders
farmshp <- st_read("~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.shp") %>%
  mutate(farm_id = sub("\\*", "", sub("JAYU2/JAYU3", "JAYU2&3", Farm_code))) %>% st_zm()

# saveRDS(farmshp %>% select(farm_id), 
#         file = "~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.rds")

# Zhang parameters for classify ground
# most parameters taken from Zhang publications except dhmax but in effect the same
pmfparam <- util_makeZhangParam(b = 1, dh0 = 0.2, s=1.2, dhmax = 10, exp = FALSE)

# plotting cross section function
source("~/Documents/GitHub/LIDAR/functions/function_plotcross.R")

#### 2021 LAS classification ####
# location of raw files
laspath21 <- "./LASPointCloud202109"

# folders
farms21 <- list.files(laspath21)
farms21 <- farms21[farms21 != "metadata"]

# farms21 %in% farmshp$farm_id # check that names are consistent with farm ids

# las file paths within folder structure
farms21.las <- lapply(farms21,
                      \(i){list.files(path = paste(laspath21,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

# nested loop through all las files (j) within each farm (j)
metadata2021 <- list()

for(i in 1:length(farms21.las)){ # farm loop i
  
  #output directories
  outfolder.i <- paste("~/Documents/Local_GIS/LiDAR/LAS/output/classified_ground/",
                       farms21[i], "/2021/", sep = "")
  dir.create(outfolder.i, recursive = TRUE)
  
  crossfolder.i <- paste("./LAS/output/metadatas/cross_sections/",
                       farms21[i], "/2021/", sep = "")
  dir.create(crossfolder.i, recursive = TRUE)
  
  # metadata list for farm i
  meta.i <- list()
  
  for(j in 1:length(farms21.las[[i]])){ # flight loop j
    starttime = Sys.time()
    print(paste(farms21[i],"flight",j, starttime, sep = " "))
    
    las.ij <- readLAS(paste(laspath21,"/",farms21[i],"/",farms21.las[[i]][j], sep = "")) # read in las i,j
    
    # classify ground
    las.ij.gnd <- classify_ground(las.ij, algorithm = pmf(ws = pmfparam$ws, th = pmfparam$th))
    
    # classify noise
    las.ij.class <- classify_noise(las.ij.gnd, ivf())
    
    # define the crs, which is missing
    st_crs(las.ij.class) <- 32161
    
    # plot cross section
    cross.ij <- plot_crossection(las.ij.class, colour_by = factor(Classification)) + 
      ggtitle(paste(farms21[i], "2021", "flight",str_pad(j,2,pad=0), sep = " "))
    ggsave(filename = paste(crossfolder.i,
                            farms21[i], "_2021", "_flight",str_pad(j,2,pad=0), "cross.png", sep = ""), 
           plot = cross.ij, height = 4, width = 6.5, units = "in", dpi = 300, bg = "white")
    
    # write output
    writeLAS(las.ij.class, 
                   file = paste(outfolder.i,
                                farms21[i],"_class_flight",str_pad(j,2,pad=0),".las", sep = ""))
    
    stoptime <- Sys.time()
    
    # write meta data
    meta.i[[j]] <- las.ij.class@data %>% group_by(Classification) %>% summarize(n = n(), .groups = "drop") %>%
      pivot_wider(names_from = Classification, values_from = n, names_prefix = "Class_") %>% 
      mutate(farm_id = farms21[i], year = 2021, flight = j,
             orig_filename = farms21.las[[i]][j], 
             output_filename = paste(farms21[i],"_class_flight",str_pad(j,2,pad=0),".las", sep = ""),
             ground_algorithm = "pmf",
             pmf_ws = paste(pmfparam$ws, collapse=", "), pmf_th=paste(pmfparam$th, collapse=","),
             process_time = starttime-stoptime)
  }
  metadata2021[[i]] <- bind_rows(meta.i)
}

metadata2021_df <- bind_rows(metadata2021) %>%
  mutate(total_pts = rowSums(across(Class_1:Class_18))) %>%
  mutate(pc_ground = 100*Class_2/total_pts)

#### 2022 LAS classification ####
laspath22 <- "./All Farms .LAS Files"

# folders
farms22 <- list.files(laspath22)
# fix farm names to match the ones in the farm border shp
farms22_namefix <- sub(" Flights", "", sub("-", "&", farms22))

# farms22_namefix %in% farmshp$farm_id # check that names are consistent with farm ids

# las file paths within folder structure
farms22.las <- lapply(farms22,
                      \(i){list.files(path = paste(laspath22,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

# nested loop through all las files (j) within each farm (j)
metadata2022 <- list()

# nested loop through all las files (j) within each farm (j)
for(i in 1:length(farms22.las)){ # farm loop i
  
  #output directories
  outfolder.i <- paste("~/Documents/Local_GIS/LiDAR/LAS/output/classified_ground/",
                       farms22_namefix[i], "/2022/", sep = "")
  dir.create(outfolder.i, recursive = TRUE)
  
  crossfolder.i <- paste("./LAS/output/metadatas/cross_sections/",
                         farms22_namefix[i], "/2022/", sep = "")
  dir.create(crossfolder.i, recursive = TRUE)  
  
  # metadata list for farm i
  meta.i <- list()
  
  for(j in 1:length(farms22.las[[i]])){ # flight loop j
    starttime <- Sys.time()
    print(paste(farms22_namefix[i],"flight",j, starttime, sep = " "))
    
    las.ij <- readLAS(paste(laspath22,"/",farms22[i],"/",farms22.las[[i]][j], sep = "")) # read in las i,j
    
    # classify ground
    las.ij.gnd <- classify_ground(las.ij, algorithm = pmf(ws = pmfparam$ws, th = pmfparam$th))
    
    # classify noise
    las.ij.class <- classify_noise(las.ij.gnd, ivf())
    
    # define the crs, which is missing
    st_crs(las.ij.class) <- 32161
    
    # plot cross section
    cross.ij <- plot_crossection(las.ij.class, colour_by = factor(Classification)) + 
      ggtitle(paste(farms22_namefix[i], "2022", "flight",str_pad(j,2,pad=0), sep = " "))
    ggsave(filename = paste(crossfolder.i,
                            farms22_namefix[i], "_2022", "_flight",str_pad(j,2,pad=0), "cross.png", sep = ""), 
           plot = cross.ij, height = 4, width = 6.5, units = "in", dpi = 300, bg = "white")
    
    # write output
    writeLAS(las.ij.class, 
             file = paste(outfolder.i,
                          farms22_namefix[i], "_2022", "_class_flight",str_pad(j,2,pad=0),".las", sep = ""))
    
    stoptime <- Sys.time()
    
    # write meta data
    meta.i[[j]] <- las.ij.class@data %>% group_by(Classification) %>% summarize(n = n(), .groups = "drop") %>%
      pivot_wider(names_from = Classification, values_from = n, names_prefix = "Class_") %>% 
      mutate(farm_id = farms21[i], year = 2022, flight = j,
             orig_filename = farms21.las[[i]][j], 
             output_filename = paste(farms21[i],"_class_flight",str_pad(j,2,pad=0),".las", sep = ""),
             ground_algorithm = "pmf",
             pmf_ws = paste(pmfparam$ws, collapse=", "), pmf_th=paste(pmfparam$th, collapse=","),
             process_time = starttime-stoptime)
  }
  metadata2022[[i]] <- bind_rows(meta.i)
}
