library(lidR)
library(tidyverse)
library(fs)
library(sf)

# loop version
# Note: I think the projection is "ESRI:102361", which does not have a EPSG code.

laspath <- "~/Documents/Local_GIS/LiDAR"
setwd(laspath)

source("~/Documents/GitHub/LIDAR/functions/function_plotcross.R")

farms <- readRDS("./rworking/Data/FARMSSHP/all_farms.rds")

las21 <- list.files(path = "./LAS/2021/", pattern = "\\.rds$")
las22 <- list.files(path = "./LAS/2022/", pattern = "\\.rds$")

# Zhang parameters
# most parameters taken from Zhang publications except dhmax but in effect the same
pmfparam <- util_makeZhangParam(b = 1, dh0 = 0.2, s=1.2, dhmax = 10, exp = FALSE)
pmfparam <- list(ws = seq(3, 12, 3), th = seq(0.1, 1.5, length.out = 4))
pmfparam <- list(ws = seq(3, 20, 3), th = seq(0.1, 5, length.out = 6))

# 2021 data
for(i in 1:length(las21)){
  start = Sys.time()
  
  print(paste(i, "start:", start, sep = " "))
  
  las.i <- read_rds(paste("./LAS/2021/", las21[i], sep = ""))
  las.i.gnd <- classify_ground(las.i, algorithm = pmf(ws = pmfparam$ws, th = pmfparam$th))
  las.i.denoise <- classify_noise(las.i.gnd, ivf())
  
  stop = Sys.time() 
  print(stop-start)
  
  # plot cross section
  name.i <- sub("_lascatalog.rds", "", las21[i])
  cross.i <- plot_crossection(las.i.denoise, colour_by = factor(Classification)) + 
    ggtitle(paste(name.i, "2021", sep = " "))
  ggsave(filename = paste("./LAS/output/metadatas/cross_sections/cross_", name.i, "_2021", ".png", sep = ""), 
         plot = cross.i, height = 4, width = 6.5, units = "in", dpi = 300, bg = "white")
  
  # save ground classified 
  saveRDS(las.i.denoise,
          file = paste("./LAS/output/2021/classified_ground/", name.i, "_gnd.rds", sep = ""))
  
  stop = Sys.time() 
  print(stop-start)
}

dtm_tin <- rasterize_terrain(las.i.denoise,
                             res = 1, algorithm = tin())
plot_dtm3d(dtm_tin, bg = "white") 
plot(filter_ground(las.i.denoise), bg = "white")

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
