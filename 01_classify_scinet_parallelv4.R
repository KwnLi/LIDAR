library(lidR)
library(tidyverse)
library(future)
# library(future.batchtools)
library(listenv)

# This code finds and reads in las files and classifies ground and noise
laspath <- "~/Documents/Data"
outpath <- "~/Documents/Data/Output"

## The first level of futures should be submitted to different cores as
## parallel processes. The second level of futures
## should be using multisession. The number of
## parallel processes should be automatically decided based on
## what the cluster grants to each compute node.
options(parallelly.debug = TRUE)
plan(list(tweak(cluster, workers=2), tweak(multisession, workers=4)))

# list folder years
yearslist <- c("2022", "2023")

farmlist <- list.files(paste0(laspath,"/lidar/lidar_2022"))
farmlist <- farmlist[3:11]

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
test <- listenv()
for(j in 1:2){
  test[[j]] %<-% {
    for(i in 1:10){
        print(c(Sys.getpid()))
    }
  }
}
as.list(test)


logfile <- file(paste0(outpath,"/log.txt"), open = "a")

yrlistenv <- listenv()

for(i in yearslist){
  yrlistenv[[i]] %<-% {
    for (j in farmlist){
      # start time logging
      start.ij <- Sys.time()
      cat(i, j, "started at",as.character(start.ij),"\n",
          file = paste0(outpath,"/log.txt"), append = TRUE)

      # load las ctg
      ctg <- readLAScatalog(paste0(laspath, "/lidar/lidar_",i,"/",j))
      opt_chunk_size(ctg)<-250

      # output path
      output <- paste0("class_1121/", i)

      # create output folder
      farm_out <- paste(outpath, output,j,sep="/")
      dir.create(farm_out, recursive = TRUE)

      opt_output_files(ctg) <- paste0(farm_out, "/", j, "_", i, "_", "{XLEFT}_{YBOTTOM}")

      # create laxindex: https://cran.r-project.org/web/packages/lidR/vignettes/lidR-computation-speed-LAScatalog.html
      lidR:::catalog_laxindex(ctg)

      class_nsgnd(ctg, ws = c(3,11), th = c(0.2,1.4))

      min.elapsed <- round(as.numeric(Sys.time()-start.ij, units="mins"), 1)

      # finish time logging
      cat(i, j, "finished at",as.character(Sys.time()),
          "| Time elapsed:", min.elapsed, "minutes","\n", "\n",
          file = paste0(outpath,"/log.txt"), append = TRUE)
      # print(Sys.getpid())
    }
  }
}
as.list(yrlistenv)
close(logfile)
