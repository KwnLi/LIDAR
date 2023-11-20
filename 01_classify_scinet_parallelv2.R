library(lidR)
library(tidyverse)
library(future)
# library(future.batchtools)
library(listenv)

# This code finds and reads in las files and classifies ground and noise
laspath <- "/90daydata/geoecoservices/kevin.li"
# laspath <- "~/Documents/Data"
# setwd(laspath)

## The first level of futures should be submitted to different cores as
## parallel processes. The second level of futures
## should be using multisession. The number of
## parallel processes should be automatically decided based on
## what the cluster grants to each compute node.
options(parallelly.debug = TRUE)
plan(list(cluster, multisession))

# list folder years
yearslist <- c("2022", "2023")

farmlist <- list.files(paste0(laspath,"/lidar/lidar_2022"))

# define a function to classify noise and ground
class_nsgnd <- function(x, ws, th, ...){
  # noise
  classified_noise <- classify_noise(x, ivf())
  opt_filter(classified_noise) <- "-drop_class 18"
  # ground
  classified_ground <- classify_ground(classified_noise,
                                       algorithm = pmf(ws = ws, th = th),
                                       last_returns=FALSE)
  return(classified_ground)
}

# # test
# test <- listenv()
# for(j in 1:10){
#   testj <- listenv()
#   test[[j]] %<-% {
#     for(i in 1:2){
#       testj[[i]] %<-% {
#         print(c(Sys.getpid()))
#       }
#     }
#     as.list(testj)
#   }
# }
# as.list(test)


classified <- listenv()
logfile <- file(paste0(laspath,"/output2/log.txt"), open = "a")

for(i in farmlist){
  
  classified[[i]] %<-% {
    
    for (j in yearslist){
      years <- listenv()
      
      years[[j]] %<-% {
        
        ctg <- readLAScatalog(paste0(laspath, "/lidar/lidar_",j,"/",i))
        opt_chunk_size(ctg)<-250
        
        # output path
        output <- paste0("output2/", j)
        
        # create output folder
        farm_out <- paste(laspath, output,i,sep="/")
        dir.create(farm_out, recursive = TRUE)
        
        opt_output_files(ctg) <- paste0(farm_out, "/", i, "_", j, "_", "{XLEFT}_{YBOTTOM}")
        
        # create laxindex: https://cran.r-project.org/web/packages/lidR/vignettes/lidR-computation-speed-LAScatalog.html
        lidR:::catalog_laxindex(ctg)
        
        class_nsgnd(ctg, ws = c(3,11), th = c(0.2,1.4))
        cat(i, j, Sys.getpid(),"finished at",as.character(Sys.time()),"\n", 
            file = paste0(laspath,"/output2/log.txt"), append = TRUE)
      } %seed% TRUE
    }
    as.list(years)
  } %seed% TRUE
}
as.list(classified)
close(logfile)
