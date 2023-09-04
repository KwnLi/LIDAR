library(lidR)
library(tidyverse)
library(future)
library(future.batchtools)
library(listenv)

# This code finds and reads in las files and classifies ground and noise
# laspath <- "/90daydata/geoecoservices/LiDAR_kl"
laspath <- "~/Documents/Data/PR_data"
setwd(laspath)

## The first level of futures should be submitted to the
## cluster using batchtools.  The second level of futures
## should be using multisession, where the number of
## parallel processes is automatically decided based on
## what the cluster grants to each compute node.
plan(list(batchtools_slurm, multisession))

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

# list folder years
yearslist <- c("2021", "2022", "2023")

years <- listenv()

for(j in yearslist){
  print(j)
  
  # output path
  output <- paste0("output/", j)
  
  farmlist <- list.files(paste0(laspath,"/clean_lidar/lidar_",j))
  
  years[[j]] %<-% {
    classified_j <- listenv()
    
    for (i in farmlist){
      ctg <- readLAScatalog(paste0(laspath, "/clean_lidar/lidar_",j,"/",i), 
                            filter = "-keep_scan_angle -20 20")
      opt_chunk_size(ctg)<-250
      
      # create output folder
      farm_out <- paste(laspath, output,i,sep="/")
      dir.create(farm_out, recursive = TRUE)
      
      opt_output_files(ctg) <- paste0(farm_out, "/", i, "_", j, "_", "{XLEFT}_{YBOTTOM}")
      
      # create laxindex: https://cran.r-project.org/web/packages/lidR/vignettes/lidR-computation-speed-LAScatalog.html
      lidR:::catalog_laxindex(ctg)
      
      classified_j[[i]] %<-% {
        class_nsgnd(ctg, ws = c(3,11), th = c(0.2,1.4))
      }
    }
    as.list(classified_j)
  }
}
as.list(years)
