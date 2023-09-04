library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)
library(ggplot2)
library(RCSF)
library(RMCC)

setwd("E:/lidar/pmf_lidar")
output <- "ground_0804"
dir.create(output)

farm_path <- "E:/lidar/filtered2022"
all_farms <- list.files(farm_path)

for (i in all_farms){
  ctg <- readLAScatalog(paste(farm_path,i,i,sep="/"))
  opt_chunk_size(ctg)<-250
  farm_out <- paste(output,i,sep="/")
  dir.create(farm_out)
  opt_output_files(ctg) <- paste(farm_out,"{XLEFT}_{YBOTTOM}",sep="/")
  classified_noise <- classify_noise(ctg, ivf())
  opt_filter(classified_noise) <- "-drop_class 18"
  classified_ground <- classify_ground(classified_noise,
                                       algorithm = pmf(ws = c(3,11), th = c(0.2,1.4)),
                                       last_returns=FALSE)
}
