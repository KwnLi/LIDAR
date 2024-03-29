library(lidR)
laspath <- "~/Documents/Data/lidar/all_scan_angle/normalized/"
source("./functions/function_plotcross.R")
source("./functions/lascatalog_inspect.R")

outpics <- list()
for(i in 1:2){
  year.i <- c(2022, 2023)[i]
  farms.i <- list.files(path = paste0(laspath,year.i))
  
  outpics[[i]] <- list()
  
  for(g in 1:length(farms.i)){
    farmname <- farms.i[g]
    ctg.farm <- readLAScatalog(paste0(laspath,year.i,"/",farmname,"/"))
    ctg.farm <- ctg.farm[check_tile_bounds(ctg.farm)]
    ctg.farm <- ctg.farm[find_tile_area(ctg.farm)>20]
    outpics[[i]][[g]] <- plot_cross_class(ctg.farm, 
                     title = paste(farmname, year.i, sep = " "))
  }
}


for(i in 1:2){
  year.i <- c(2022, 2023)[i]
  farms.i <- list.files(path = paste0(laspath,year.i))
  for(g in 1:length(farms.i)){
    png(paste0("./plots_allscan_normalized/",farms.i[g],"_",year.i,".png"), res = 300,
        height = 8.5, width = 11, units = "in", bg = "white")
    plot(outpics[[i]][[g]])
    dev.off()
  }
}
