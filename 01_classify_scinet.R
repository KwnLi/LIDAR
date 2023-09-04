library(lidR)
library(tidyverse)
library(future)

# This code finds and reads in las files and classifies ground and noise
# laspath <- "/90daydata/geoecoservices/LiDAR_kl"
laspath <- "~/Documents/Data/PR_data"
setwd(laspath)

# list folder years
yearslist <- c("2021", "2022", "2023")

for(j in yearslist){
  print(j)
  
  # output path
  output <- paste0("output/", j)
  
  farmlist <- list.files(paste0(laspath,"/clean_lidar/lidar_",j))
  
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
    
    # noise
    classified_noise <- classify_noise(ctg, ivf())
    opt_filter(classified_noise) <- "-drop_class 18"
    
    classified_ground <- classify_ground(classified_noise,
                                         algorithm = pmf(ws = c(3,11), th = c(0.2,1.4)),
                                         last_returns=FALSE)
  }
}
