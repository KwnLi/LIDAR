# unzip lidar 
setwd("/Users/kevinl/Documents/Local_GIS/data")
zipfolder <- "filtered2022"
outfolder <- "flights2022"
ziplist <- list.files(zipfolder) # folder of zipped files

for(i in 1:length(ziplist)){
  unzip(paste0(zipfolder, "/", ziplist[i]), exdir=outfolder)
}
