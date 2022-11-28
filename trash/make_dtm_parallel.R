library(lidR)
library(tidyverse)
library(fs)
library(sf)

# parallel version. Doesn't work.
# Note: I think the projection is "ESRI:102361", which does not have a EPSG code.

laspath <- "~/Documents/Local_GIS/LiDAR"
setwd(laspath)

source("~/Documents/GitHub/LIDAR/functions/function_plotcross.R")

farms <- readRDS("./rworking/Data/FARMSSHP/all_farms.rds")

las21 <- list.files(path = "./LAS/2021/", pattern = "\\.rds$")
las22 <- list.files(path = "./LAS/2022/", pattern = "\\.rds$")

# Zhang parameters
# most parameters taken from Zhang publications except dhmax but in effect the same
pmfparam <- util_makeZhangParam(dh0 = 0.2, s=1.2, dhmax = 10, exp = FALSE)

# parallel setup
library(foreach)
library(doParallel)
parallel::detectCores()
n.cores <- parallel::detectCores() - 1

my.cluster <- parallel::makeCluster(
  n.cores, 
  type = "FORK"
)

#register my.cluster to be used by %dopar%
doParallel::registerDoParallel(cl = my.cluster)
foreach::getDoParRegistered() # check if registered
foreach::getDoParWorkers() # check available workers

# 2021 data
foreach(i = las21) %dopar% {
  start = Sys.time()
  
  print(paste(i, "start:", start, sep = " "))
  
  las.i <- read_rds(paste("./LAS/2021/", i, sep = ""))
  las.i.gnd <- classify_ground(las.i, algorithm = pmf(ws = pmfparam$ws, th = pmfparam$th))
  las.i.denoise <- classify_noise(las.i.gnd, ivf())
  
  # plot cross section
  name.i <- sub("_lascatalog.rds", "", i)
  cross.i <- plot_crossection(las.i.denoise, colour_by = factor(Classification)) + 
    ggtitle(paste(name.i, "2021", sep = " "))
  ggsave(filename = paste("./LAS/output/metadatas/cross_sections/cross_", name.i, "_2021", ".png", sep = ""), 
         plot = cross.i, height = 4, width = 6.5, units = "in", dpi = 300)
  
  # save ground classified 
  saveRDS(lascat.iclip,
          file = paste("./LAS/output/2021/classified_ground/", i, "_gnd.rds", sep = ""))
  
  stop = Sys.time() 
  print(stop-start)
}

for(i in 1:length(las21)){

}

# 2022 data
foreach(i = las22) %dopar% {
  start = Sys.time() 
  
  print(paste(i, "start:", start, sep = " "))
  
  las.i <- read_rds(paste("./LAS/2022/", i, sep = ""))
  las.i.gnd <- classify_ground(las.i, algorithm = pmf(ws = pmfparam$ws, th = pmfparam$th))
  las.i.denoise <- classify_noise(las.i.gnd, ivf())
  
  # plot cross section
  name.i <- sub("_lascatalog.rds", "", i)
  cross.i <- plot_crossection(las.i.denoise, colour_by = factor(Classification)) + 
    ggtitle(paste(name.i, "2022", sep = " "))
  ggsave(filename = paste("./LAS/output/metadatas/cross_sections/cross_", name.i, "_2022", ".png", sep = ""), 
         plot = cross.i, height = 4, width = 6.5, units = "in", dpi = 300)
  
  # save ground classified 
  saveRDS(lascat.iclip,
          file = paste("./LAS/output/2022/classified_ground/", i, "_gnd.rds", sep = ""))
  
  stop = Sys.time() 
  print(stop-start)
}

stopCluster(cl = my.cluster)
