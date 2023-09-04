library(lidR)
library(tidyverse)
library(fs)
library(sf)

# This code finds and reads in las files 

laspath <- "~/Documents/Data/PR_data/"

##### 2021 data #####

# 2021 folders
laspath21 <- "~/Documents/Data/PR_data/raw_lidar/lidar_2021"
farms21 <- list.files(laspath21)
farms21 <- farms21[farms21 != "metadata"]

# las file paths within folder structure
farms21.las <- lapply(farms21,
                      \(i){list.files(path = paste(laspath21,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

# nested loop through all las files (j) within each farm (j)

for(i in 1:length(farms21.las)){ # farm loop i
  
  #output directories
  outfolder.i <- paste("~/Documents/Data/PR_data/clean/lidar_2021/",
                       farms21[i], "/", sep = "")
  if(!file.exists(outfolder.i)) dir.create(outfolder.i, recursive = TRUE)
  
  for(j in 1:length(farms21.las[[i]])){ # flight loop j
    
    print(paste(farms21[i],"flight",j, sep = " "))
    
    las.ij <- readLAS(
      paste(laspath21,"/",farms21[i],"/",farms21.las[[i]][j], sep = "")
      ) # read in las i,j
    
    # define the crs, which is missing
    st_crs(las.ij) <- 32161

    # write output
    writeLAS(las.ij, 
             file = paste(outfolder.i,
                          farms21[i],"_flight",str_pad(j,2,pad=0),".las", sep = ""))

  }
}

##### 2022 data #####

# 2022 folders
laspath22 <- "~/Documents/Data/PR_data/raw_lidar/lidar_2022"
farms22 <- list.files(laspath22)

# las file paths within folder structure
farms22.las <- lapply(farms22,
                      \(i){list.files(path = paste(laspath22,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

# nested loop through all las files (j) within each farm (j)

for(i in 1:length(farms22.las)){ # farm loop i
  
  #output directories
  outfolder.i <- paste("~/Documents/Data/PR_data/clean/lidar_2022/",
                       farms22[i], "/", sep = "")
  if(!file.exists(outfolder.i)) dir.create(outfolder.i, recursive = TRUE)
  
  for(j in 1:length(farms22.las[[i]])){ # flight loop j
    
    print(paste(farms22[i],"flight",j, sep = " "))
    
    las.ij <- readLAS(
      paste(laspath22,"/",farms22[i],"/",farms22.las[[i]][j], sep = "")
    ) # read in las i,j
    
    # define the crs, which is missing
    st_crs(las.ij) <- 32161
    
    # write output
    writeLAS(las.ij, 
             file = paste(outfolder.i,
                          farms22[i],"_flight",str_pad(j,2,pad=0),".las", sep = ""))
    
  }
}


##### 2023 data #####

# 2023 folders
laspath23 <- "~/Documents/Data/PR_data/raw_lidar/lidar_2023"
farms23 <- list.files(laspath23)

# las file paths within folder structure
farms23.las <- lapply(farms23,
                      \(i){list.files(path = paste(laspath23,"/",i, sep = ""),
                                      recursive = TRUE, 
                                      pattern = "\\.las$")})

# nested loop through all las files (j) within each farm (j)

for(i in 1:length(farms23.las)){ # farm loop i
  
  #output directories
  outfolder.i <- paste("~/Documents/Data/PR_data/clean/lidar_2023/",
                       farms23[i], "/", sep = "")
  if(!file.exists(outfolder.i)) dir.create(outfolder.i, recursive = TRUE)
  
  for(j in 1:length(farms23.las[[i]])){ # flight loop j
    
    print(paste(farms23[i],"flight",j, sep = " "))
    
    las.ij <- readLAS(
      paste(laspath23,"/",farms23[i],"/",farms23.las[[i]][j], sep = "")
    ) # read in las i,j
    
    # define the crs, which is missing
    st_crs(las.ij) <- 32161
    
    # write output
    writeLAS(las.ij, 
             file = paste(outfolder.i,
                          farms23[i],"_flight",str_pad(j,2,pad=0),".las", sep = ""))
    
  }
}
