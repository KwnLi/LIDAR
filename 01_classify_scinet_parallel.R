library(lidR)
library(tidyverse)
library(future)
# library(future.batchtools)
library(listenv)

# This code finds and reads in las files and classifies ground and noise
laspath <- "/90daydata/geoecoservices/kevin.li"
# laspath <- "~/Documents/Data"
# setwd(laspath)

## The first level of futures should be sequential (originally submitted to the
## cluster using batchtools).  The second level of futures
## should be using multisession, where the number of
## parallel processes is automatically decided based on
## what the cluster grants to each compute node.
plan(list(sequential, tweak(multisession, workers=6)))

# list folder years
# yearslist <- c("2022", "2023")
yearslist <- "2022"

years <- listenv()

# # test
# 
# for(j in yearslist){
#   classified_j <- listenv()
#   years[[j]] %<-% {
#     for(i in 1:10){
#       classified_j[[i]] %<-% {
#         print(c(Sys.getpid()))
#       }
#     }
#     as.list(classified_j)
#   }
# }
# as.list(years)


for(j in yearslist){
  print(j)
  
  # output path
  output <- paste0("output/", j)
  
  farmlist <- list.files(paste0(laspath,"/lidar/lidar_",j))
  
  years[[j]] %<-% {
    classified_j <- listenv()
    
    for (i in farmlist){
      
      classified_j[[i]] %<-% {
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
        
        ctg <- readLAScatalog(paste0(laspath, "/lidar/lidar_",j,"/",i))
        opt_chunk_size(ctg)<-250
        
        # create output folder
        farm_out <- paste(laspath, output,i,sep="/")
        dir.create(farm_out, recursive = TRUE)
        
        opt_output_files(ctg) <- paste0(farm_out, "/", i, "_", j, "_", "{XLEFT}_{YBOTTOM}")
        
        # create laxindex: https://cran.r-project.org/web/packages/lidR/vignettes/lidR-computation-speed-LAScatalog.html
        lidR:::catalog_laxindex(ctg)
        
        class_nsgnd(ctg, ws = c(3,11), th = c(0.2,1.4))
        # print(c(        nbrOfWorkers(),
        #                 availableCores(), Sys.getpid()))

      } %seed% TRUE
    }
    as.list(classified_j)
  }
}
as.list(years)
