library(lidR)
library(tidyverse)
library(parallel)


# This code finds and reads in las files and classifies ground and noise
laspath <- "/90daydata/geoecoservices/LiDAR_kl"
setwd(laspath)

# unzip lidar 
# ziplist <- list.files("filtered2021")
# farmlist <- sub(".zip$","",ziplist)

# for(i in 1:length(ziplist)){
#   unzip(paste("./filtered2021/", ziplist[i],sep=""), exdir="./unzipped/")
# }

# Zhang parameters for classify ground
# most parameters taken from Zhang publications except dhmax but in effect the same
pmfparam <- util_makeZhangParam(b = 1, dh0 = 0.2, s=1.2, dhmax = 10, exp = FALSE)

# plotting cross section function
source("./LIDAR/functions/function_plotcross.R")

#### 2021 LAS classification ####
# location of raw files
laspath21 <- "./unzipped/"

# folders
farms21 <- list.files(laspath21, recursive = TRUE)

# function that takes the farm las files and reads in las and clasifies

classlas <- function(lasflight, lasfolder, class.params){
  # extract farm data from the filename
  farmcode <- strsplit(lasflight, "[/.]")[[1]]
  flight <- strsplit(farmcode[2], "[_]")[[1]][3]
  if(!dir.exists(paste("./classified",farmcode[1],sep="/"))){
    dir.create(paste("./classified",farmcode[1],sep="/"), 
               recursive=TRUE) # create output directory
  }
  # don't make separate folders for cross sections
  # if(!dir.exists(paste("./cross_sects",farmcode[1],sep="/"))){
  #   dir.create(paste("./cross_sects",farmcode[1],sep="/"), 
  #              recursive=TRUE) # create cross section directory
  # }
  
  starttime = Sys.time()

  las.in <- readLAS(paste(lasfolder,lasflight,sep="/")) # read in las
  
  # classify ground
  las.in.gnd <- classify_ground(las.in, algorithm = pmf(ws = class.params$ws, th = class.params$th))
  
  # classify noise
  las.in.nois <- classify_noise(las.in.gnd, ivf())
  
  # define the crs, which is missing
  st_crs(las.in.nois) <- 32161
  
  # plot cross section
  cross.las <- plot_crossection(las.in.nois, colour_by = factor(Classification)) + 
    ggtitle(paste(farmcode[1], flight, sep = " "))
  ggsave(filename = paste("./cross_sects/", farmcode[2], ".png", sep = ""), 
         plot = cross.las, height = 4, width = 6.5, units = "in", dpi = 300, bg = "white")
  
  # write output
  writeLAS(las.in.nois, 
           file = paste("./classified/",farmcode[1],"/",farmcode[1], "_class_", flight, ".las", sep = ""))
  
  stoptime <- Sys.time()
  
  las.metrics <- cloud_metrics(las.in.nois, .stdmetrics)
  gnd.metrics <- cloud_metrics(filter_ground(las.in.nois), .stdmetrics)
  
  pt.density <- las.metrics$n/las.metrics$area
  gnd.density <- gnd.metrics$n/gnd.metrics$area
  
  class_metadata <- las.in.nois@data %>% 
    group_by(Classification) %>% summarize(n = n(), .groups = "drop") %>%
    pivot_wider(names_from = Classification, values_from = n, names_prefix = "Class_") %>% 
    mutate(pt.density = pt.density, gnd.density = gnd.density,
           farm_id = farmcode[1], flight = flight,
           orig_filename = farmcode[2], 
           output_filename = paste("/classified/",farmcode[1], "_class_", flight, ".las", sep = ""),
           ground_algorithm = "pmf",
           pmf_ws = paste(class.params$ws, collapse=", "), pmf_th=paste(class.params$th, collapse=","),
           process_time = stoptime-starttime)
  
  return(class_metadata)
}

# parallelization 
num.cores <- detectCores()-2

flightmetadf <- mclapply(farms21[1:2], classlas, lasfolder=laspath21, class.params=pmfparam,
                         mc.cores = num.cores)
