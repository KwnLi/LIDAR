laspath <- "~/Documents/Local_GIS/LiDAR"
setwd(laspath)

# 2021 file paths
laspath21 <- "./LASPointCloud202109"

farms21 <- list.files(laspath21)
farms21 <- farms21[farms21 != "metadata"]

farms21.las <- lapply(farms21,
                      \(i){list.files(path = paste(laspath21,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

names(farms21.las) <- farms21

lapply(list(farms21.las, farms21), \(i){paste(laspath, sub(".", "", laspath21), "/", i[[2]], "/", i[[1]], sep = "")})

# 2022 file paths
laspath22 <- "./All Farms .LAS Files"

farms22 <- list.files(laspath22)
# fix farm names to match the ones in the farm border shp
farms22_namefix <- sub(" Flights", "", sub("-", "&", farms22))

farms22.las <- lapply(farms22,
                      \(i){list.files(path = paste(laspath22,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})
names(farms22.las) <- farms22_namefix
