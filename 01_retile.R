library(lidR)
library(tidyverse)
# library(future)
# library(future.batchtools)
# library(listenv)

# This code finds and reads in las files and classifies ground and noise
laspath <- "~/Documents/Data"
outpath <- "~/Documents/Data/Output"

source("./functions/lascatalog_inspect.R")

## The first level of futures should be submitted to different cores as
## parallel processes. The second level of futures
## should be using multisession. The number of
## parallel processes should be automatically decided based on
## what the cluster grants to each compute node.
# options(parallelly.debug = TRUE)
# plan(list(tweak(cluster, workers=2), tweak(multisession, workers=4)))

# list folder years
yearslist <- c("2022", "2023")

farmlist <- list.files(paste0(laspath,"/lidar/lidar_2022"))
farmlist <- farmlist[1:11]

# test
# test <- listenv()
# for(j in 1:2){
#   test[[j]] %<-% {
#     for(i in 1:10){
#       print(c(Sys.getpid()))
#     }
#   }
# }
# as.list(test)


logfile <- file(paste0(outpath,"/log.txt"), open = "a")

for(i in yearslist){
  for (j in farmlist){
    # start time logging
    start.ij <- Sys.time()
    cat(i, j, "started at",as.character(start.ij),"\n",
        file = paste0(outpath,"/log.txt"), append = TRUE)
    
    # load las ctg
    ctg <- readLAScatalog(paste0(laspath, "/lidar/lidar_",i,"/",j))
    opt_chunk_size(ctg)<-250
    
    # output path
    output <- paste0("retile/", i)
    temp <- paste0("temp/",i)
    
    # create output folder
    farm_temp <- paste(outpath, temp, j, sep="/")
    farm_out <- paste(outpath, output,j,sep="/")
    
    dir.create(farm_temp, recursive = TRUE)
    dir.create(farm_out, recursive = TRUE)
    
    opt_output_files(ctg) <- paste0(farm_temp, "/", j, "_", i, "_", "{XLEFT}_{YBOTTOM}")
    opt_chunk_buffer(ctg) <- 0
    
    catalog_retile(ctg)
    
    newctg <- readLAScatalog(farm_temp)
    
    newctg <- newctg[check_tile_bounds(newctg)] # remove non-bordering tiles
    newctg <- newctg[find_tile_area(newctg)>20] # remove tiny tiles
    newctg <- newctg[check_tile_size(newctg)>200] # remove tiles with few points
    
    opt_output_files(newctg) <- paste0(farm_out, "/", j, "_", i, "_", "{XLEFT}_{YBOTTOM}")
    opt_chunk_buffer(newctg) <- 0
    opt_chunk_size(newctg)<-250
    
    catalog_retile(newctg)
    
    min.elapsed <- round(as.numeric(Sys.time()-start.ij, units="mins"), 1)
    
    # finish time logging
    cat(i, j, "finished at",as.character(Sys.time()),
        "| Time elapsed:", min.elapsed, "minutes","\n", "\n",
        file = paste0(outpath,"/log.txt"), append = TRUE)
    # print(Sys.getpid())
  }
}
close(logfile)
