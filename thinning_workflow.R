library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)

# directory setup
laspath <- "/Users/kevinl/Documents/Local_GIS/data/flights2022"  # input las data folder (farm folders within)
datapath <- "/Users/kevinl/Documents/Local_GIS/data/"            # output data directory

farms <- list.files(laspath)

# params
year <- 2022 # CHANGE THIS FOR OUTPUT NAMING
tile.size <- 1000 # m on side of square
thinning.density <- 100 # per sq m

for(i in 1:length(farms)){
  farm.i <- farms[i]
  # read in lascatalog of farm i. This creates a warning because the flights overlap
  ctg.i <- readLAScatalog(
    paste(laspath, farm.i, sep = "/"),
  )
  
  # retile the lascatalog and write retiled data to file
  # these options define the tile sizes
  opt_chunk_buffer(ctg.i) <- 0   # no buffer around tiles
  opt_chunk_size(ctg.i) <- tile.size   # tile size (1000m side square)
  # define output location of new tiles. Will make a new folder structure within "datapath"
  opt_output_files(ctg.i) <- paste0(datapath, "retile/", year, "/", farm.i, "/", farm.i, "_", "retile_{XLEFT}_{YBOTTOM}")
  
  retile.i <- catalog_retile(ctg.i)
  
  # thin the lascatalog
  # define output location of thinned tiles
  opt_output_files(retile.i) <- paste0(datapath, "retile_thin/", year, "/", farm.i, "/", farm.i, "_", "thin_{XLEFT}_{YBOTTOM}")
  
  thin.i <- decimate_points(
    retile.i,
    homogenize(density=thinning.density, res=1)
  )
  
  # classify ground and noise next
  
}
