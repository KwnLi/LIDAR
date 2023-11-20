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
plan(multisession)

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
yearslist <- c("2022", "2023")

farmlist2022 <- list.files(paste0(laspath,"/lidar/lidar_2022"))
farmlist2023 <- list.files(paste0(laspath,"/lidar/lidar_2023"))

farmpath2022 <- paste0(laspath,"/lidar/lidar_2022/",farmlist2022)
farmpath2023 <- paste0(laspath,"/lidar/lidar_2023/",farmlist2023)
farmpaths <- c(farmpath2022,farmpath2023)
outpaths <- paste0(
  laspath, "/output/",
  substr(farmpaths, nchar(laspath)+8, nchar(farmpaths))
)
outnames <- paste0(
  substr(farmpaths, nchar(laspath)+19, nchar(farmpaths)),
  "_", substr(farmpaths, nchar(laspath)+14, nchar(laspath)+17)
)

classified <- listenv()

for(j in 1:length(farmpaths)){
  
  ctg <- readLAScatalog(farmpaths[j])
  opt_chunk_size(ctg)<-250
  
  # create output folder
  farm_out <- outpaths[j]
  dir.create(farm_out, recursive = TRUE)
  
  classified[[j]] %<-% {
    
    opt_output_files(ctg) <- paste0(farm_out, "/", outnames[j], "_", "{XLEFT}_{YBOTTOM}")
    
    # create laxindex: https://cran.r-project.org/web/packages/lidR/vignettes/lidR-computation-speed-LAScatalog.html
    lidR:::catalog_laxindex(ctg)
    
    class_nsgnd(ctg, ws = c(3,11), th = c(0.2,1.4))
  }
}
as.list(classified)
