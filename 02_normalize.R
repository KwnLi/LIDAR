library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)
library(ggplot2)
library(RCSF)
library(RMCC)
library(future)
source("./functions/lascatalog_inspect.R")

# datadir <- "/project/geoecoservices/kevin.li/lidar_data/all_scan_angle/"
# outdir <- "/project/geoecoservices/kevin.li/lidar_data/all_scan_angle/normalized/" #location to output normalized point clouds

datadir <- "~/Documents/Data/lidar/all_scan_angle/"
outdir <-  "~/Documents/Data/lidar/all_scan_angle/normalized"
dir.create(outdir)

farm_yrs <- c("2022", "2023") # years and directory structure of farms

# set up parallelism
cores <- availableCores()
# set_lidr_threads(round(cores/2))
plan(multisession, workers=cores) # no OpenMP support

# loop over years
for(yr in farm_yrs){
  all_farms <- list.files(paste0(datadir,yr))
  
  for (i in all_farms){
    ctg <- readLAScatalog(paste(datadir,yr,i,sep="/"))
    ctg <- ctg[check_tile_bounds(ctg)] # remove non-bordering tiles
    ctg <- ctg[find_tile_area(ctg)>20] # remove tiny tiles
    ctg <- ctg[check_tile_size(ctg)>200] # remove tiles with few points
    
    farm_out <- paste(outdir,yr,i,sep="/")
    dir.create(farm_out, recursive=TRUE)
    
    # opt_output_files(ctg) <- paste0(outdir,"/","dtm","/",i,"dtm",yr,"_","{XLEFT}_{YBOTTOM}")
    dtm_tin <- rasterize_terrain(ctg, res = 1, algorithm = tin())
    
    opt_output_files(ctg) <- paste0(farm_out,"/",i,"_","{XLEFT}_{YBOTTOM}")
    nlas <- normalize_height(ctg, tin(), dtm=dtm_tin)
  }
}
