library(lidR)
library(tidyverse)
library(fs)
library(sf)

laspath <- "~/Documents/Local_GIS/LiDAR"
setwd(laspath)

source("~/Documents/GitHub/LIDAR/functions/function_plotcross.R")

farms <- readRDS("./rworking/Data/FARMSSHP/all_farms.rds")

las21 <- list.files(path = "./LAS/2021/", pattern = "\\.rds$")
las22 <- list.files(path = "./LAS/2022/", pattern = "\\.rds$")

dens.plot21 <- list()
for(i in 1:length(las21)){
  las.i <- read_rds(paste("./LAS/2021/", las21[i], sep = ""))
  dens.plot21[[i]] <- rasterize_density(las.i, res=1)
}

dens.plot22 <- list()
for(i in 1:length(las22)){
  las.i <- read_rds(paste("./LAS/2022/", las22[i], sep = ""))
  dens.plot22[[i]] <- rasterize_density(las.i, res=1)
}

# plot densities
farmshp <- st_read("~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.shp") %>%
  mutate(farm_id = sub("\\*", "", sub("JAYU2/JAYU3", "JAYU2&3", Farm_code))) %>% st_zm() %>%
  select(farm_id)

for(z in 1:length(las21)){
  name.z <- sub("_lascatalog.rds", "", las21[z])
  png(paste("./LAS/output/metadatas/lasdens21_", name.z, ".png", sep = ""), height = 5, width = 5, units = "in", res = 300)
  plot(dens.plot21[[z]], main = paste(name.z, 2021))
  plot(farmshp %>% filter(farm_id == name.z), col = NULL, add = TRUE)
  dev.off()
}

for(z in 1:length(las22)){
  name.z <- sub("_lascatalog.rds", "", las22[z])
  png(paste("./LAS/output/metadatas/lasdens22_", name.z, ".png", sep = ""), height = 5, width = 5, units = "in", res = 300)
  plot(dens.plot22[[z]], main = paste(name.z, 2022))
  dev.off()
}

test <- read_rds(paste("./LAS/2022/", las22[8], sep = ""))
ws <- seq(3, 12, 3)
th <- seq(0.1, 1.5, length.out = length(ws))
las_noise <- classify_noise(test, sor())
las_ground <- classify_ground(las_noise, algorithm = mcc())

plot_crossection(las_ground, colour_by = factor(Classification))


ws <- seq(3,12, 3)
th <- seq(0.1, 1.5, length.out = length(ws))

test2 <- read_rds(paste("./LAS/2021/", las21[9], sep = ""))
las_noise2 <- classify_noise(test2, sor())
las_ground2 <- classify_ground(test2, algorithm = pmf(ws, th))
las_ground3 <- classify_noise(las_ground2, sor())

plot_crossection(las_ground2, colour_by = factor(Classification))

plot(las_ground3, color = "Classification", bg = "white")
