library(lidR)
library(tidyverse)
library(fs)
library(sf)

laspath <- "~/Documents/LiDAR/unzipped/"
datapath <- "~/Documents/LiDAR/"
year <- 2023

wf <- readLAScatalog(paste0(laspath, "2023/WarrensForest/"),
                     filter = "-keep_scan_angle -20 20")

# params
tile.size <- 1000 # m on side of square
# thinning.density <- 100 # per sq m

# retile the lascatalog and write retiled data to file
# these options define the tile sizes
opt_chunk_buffer(wf) <- 0   # no buffer around tiles
opt_chunk_size(wf) <- tile.size   # tile size (1000m side square)
# define output location of new tiles. Will make a new folder structure within "datapath"
opt_output_files(wf) <- paste0(datapath, "retile/", year, "/", 
                               "WarrensForest", "/", "WF", "_", "retile_{XLEFT}_{YBOTTOM}")

retile.i <- catalog_retile(wf)

# thin the lascatalog
# define output location of thinned tiles
opt_output_files(retile.i) <- paste0(datapath, "retile_thin/", year, "/", farm.i, "/", farm.i, "_", "thin_{XLEFT}_{YBOTTOM}")

thin.i <- decimate_points(
  retile.i,
  homogenize(density=thinning.density, res=1)
)

wf2 <- readLAS(paste0(datapath, "retile/2023/WarrensForest/WF_retile_174000_247000.las"))
