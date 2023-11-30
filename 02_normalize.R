library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)
library(ggplot2)
library(RCSF)
library(RMCC)
library(future)

datadir <- "/project/geoecoservices/kevin.li/lidar_data/all_scan_angle/"
outdir <- "/project/geoecoservices/kevin.li/lidar_data/all_scan_angle/normalized/" #location to output normalized point clouds
dir.create(outdir)

farm_yrs <- c("2022", "2023") # years and directory structure of farms

# set up parallelism
cores <- availableCores()
set_lidr_threads(round(cores/2))
plan(multisession, workers=round(cores/2))

# loop over years
for(yr in farm_yrs){
  all_farms <- list.files(paste0(datadir,yr))
  
  for (i in all_farms){
    ctg <- readLAScatalog(paste(farm_path,i,sep="/"))
    #opt_chunk_size(ctg)<-250
    farm_out <- paste(output,i,sep="/")
    dir.create(farm_out)
    
    dtm_tin <- rasterize_terrain(ctg, res = 1, algorithm = tin())
    opt_output_files(ctg) <- paste(farm_out,"{XLEFT}_{YBOTTOM}",sep="/")
    nlas <- normalize_height(ctg, tin(), dtm=dtm_tin)
  }
}
