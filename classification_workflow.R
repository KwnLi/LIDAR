library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)

# directory setup
laspath <- "/Users/kevinl/Documents/Local_GIS/data/retile_thin/2022/"  # input las data folder (farm folders within)
datapath <- "/Users/kevinl/Documents/Local_GIS/data/"                  # output data directory

farms <- list.files(laspath)

# params
year <- 2022 # CHANGE THIS FOR OUTPUT NAMING
pmfparam <- util_makeZhangParam(b = 1, dh0 = 0.2, s=1.2, dhmax = 10, exp = FALSE)

# testing
source("./functions/function_plotcross.R")
testlas <- readLAS(paste0(laspath,"/",farms[10],"/",list.files(paste0(laspath,"/",farms[10]))))

testlas.gnd <- classify_ground(testlas, algorithm = pmf(ws = pmfparam$ws, th = pmfparam$th))
testlas.nois <- classify_noise(testlas.gnd, ivf())

cross.las <- plot_crossection(testlas.nois, colour_by = factor(Classification))

testdens <- rasterize_density(testlas.nois)

cowplot::plot_grid(cross.las, ggplot()+geom_spatraster(data=testdens) + 
                     scale_fill_continuous(type="viridis")+ggtitle("Point density"))

# classify ground and noise 
for(i in 1:length(farms)){
  farm.i <- farms[i]
  # read in lascatalog of farm i. This creates a warning because the flights overlap
  ctg.i <- readLAScatalog(
    paste(laspath, farm.i, sep = "/"),
  )
  
  # classify ground
  opt_output_files(ctg.i) <- paste0(datapath, "retile/", year, "/", farm.i, "/", farm.i, "_", "retile_{XLEFT}_{YBOTTOM}")
  
  retile.i <- catalog_retile(ctg.i)
  
  # thin the lascatalog
  # define output location of thinned tiles
  opt_output_files(retile.i) <- paste0(datapath, "retile_thin/", year, "/", farm.i, "/", farm.i, "_", "thin_{XLEFT}_{YBOTTOM}")
  
  thin.i <- decimate_points(
    retile.i,
    homogenize(density=thinning.density, res=1)
  )
  
  # classify ground and noise
  
}
