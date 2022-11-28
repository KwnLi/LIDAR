library(lidR)
library(tidyverse)
library(fs)
library(sf)

laspath <- "~/Documents/Local_GIS/LiDAR"
setwd(laspath)

# Farm borders
farmshp <- st_read("~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.shp") %>%
  mutate(farm_id = sub("\\*", "", sub("JAYU2/JAYU3", "JAYU2&3", Farm_code))) %>% st_zm()

# saveRDS(farmshp %>% select(farm_id), 
#         file = "~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.rds")

# 2021 LAS catalogs
laspath21 <- "./LASPointCloud202109"

farms21 <- list.files(laspath21)
farms21 <- farms21[farms21 != "metadata"]

farms21 %in% farmshp$farm_id

farms21.las <- lapply(farms21,
                      \(i){list.files(path = paste(laspath21,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

for(i in 1:length(farms21.las)){
  lascat.i <- readLAScatalog(
    folder = paste(laspath21,farms21[i],farms21.las[[i]], sep="/")
    )
  
  farm.i <- filter(farmshp, farm_id == farms21[i])
  farm.ibuf <- st_buffer(farm.i, dist = 20)
  
  png(paste("./LAS/2021/", farms21[i], "_extents.png", sep = ""))
  plot(lascat.i, main = farms21[i])
  plot(farm.ibuf[1], add = TRUE, col = sf.colors(n=1, alpha = .5))
  plot(farm.i[1], add = TRUE, col = sf.colors(n=1, alpha = .5))
  dev.off()
  
  # lascat.iclip <- clip_roi(lascat.i, geometry = farm.ibuf)
  # 
  # saveRDS(lascat.iclip,
  #         file = paste("./LAS/2021/", farms21[i], "_lascatalog.rds", sep = ""))

}

# 2022 LAS catalogs
laspath22 <- "./All Farms .LAS Files"

farms22 <- list.files(laspath22)
# fix farm names to match the ones in the farm border shp
farms22_namefix <- sub(" Flights", "", sub("-", "&", farms22))

farms22_namefix %in% farmshp$farm_id

farms22.las <- lapply(farms22,
                      \(i){list.files(path = paste(laspath22,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

for(i in 1:length(farms22.las)){
  lascat.i <- readLAScatalog(
    folder = paste(laspath22,farms22[i],farms22.las[[i]], sep="/")
  )
  
  farm.i <- filter(farmshp, farm_id == farms22_namefix[i])
  farm.ibuf <- st_buffer(farm.i, dist = 20)
  
  png(paste("./LAS/2022/", farms22_namefix[i], "_extents.png", sep = ""))
  plot(lascat.i, main = farms22_namefix[i])
  plot(farm.ibuf[1], add = TRUE, col = sf.colors(n=1, alpha = .5))
  plot(farm.i[1], add = TRUE, col = sf.colors(n=1, alpha = .5))
  dev.off()
  
  lascat.iclip <- clip_roi(lascat.i, geometry = farm.ibuf)

  saveRDS(lascat.iclip,
          file = paste("./LAS/2022/", farms22_namefix[i], "_lascatalog.rds", sep = ""))
  
}

lascat.iclip <- clip_roi(las_ground, geometry = farm.ibuf)

opt_output_files(lascat.i) <- paste0(tempdir(), "{*}_classified")
projection(las_ground) <- st_crs("ESRI:102361")
