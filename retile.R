library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)

# farm vector data
farms <- readRDS("./data/farms.rds")

# Select target farm and year
farm_name <- "UTUA2"  # name of target farm data

farm_poly <- farms %>% filter(farm_id == farm_name)   # isolate farm
farm_buf <- st_buffer(farm_poly, dist = 30)           # buffer farm (distance=30m)
farm_ext <- farm_buf %>% st_bbox() %>% st_as_sfc()    # get extent that includes buffer

# directory setup
laspath <- "~/Documents/Local_GIS/data/flights2021"  # las data directory
datapath <- "~/Documents/Local_GIS/data/"            # output data folder

# read in las files as LAScatalog
farm_ctg <- readLAScatalog(
  paste(laspath, farm_name, sep = "/"),
  ) # this creates a warning because the flights overlap

dens_farm_orig <- rasterize_density(farm_ctg)

# clip las catalog to the farm extents. This combines all point clouds together
farm_clip <- clip_roi(farm_ctg, farm_ext)

# thin the clipped area
farm_clip_thin <- decimate_points(farm_clip, homogenize(density=100, res=1)) 

dens_farm_clip <- rasterize_density(farm_clip_thin)

# thin the catalog
opt_output_files(farm_ctg) <- paste0(datapath, "thinned/", farm_name, "/", farm_name, "_", "retile_{XLEFT}_{YBOTTOM}")

farm_ctg_thin <- decimate_points(
  farm_ctg,
  homogenize(density=100, res=1)
)

dens_farm_ctg <- rasterize_density(farm_ctg_thin)

# retile the (unthinned) catalog and then thin
opt_chunk_buffer(farm_ctg) <- 0   # no buffer around tiles
opt_chunk_size(farm_ctg) <- 1000   # tile size (1000m side square)
opt_output_files(farm_ctg) <- paste0(datapath, "retile/", farm_name, "/", farm_name, "_", "retile_{XLEFT}_{YBOTTOM}")

farm_retile <- catalog_retile(farm_ctg)

# thin the retile
opt_output_files(farm_retile) <- paste0(datapath, "retile_thin/", farm_name, "/", farm_name, "_", "retile_{XLEFT}_{YBOTTOM}")

farm_retile_thin <- decimate_points(
  farm_retile,
  homogenize(density=100, res=1)
)

dens_farm_retile <- rasterize_density(farm_retile_thin)

# view results

par(mfrow=c(2,2))
plot(dens_farm_orig, main = "Original catalog")
plot(dens_farm_clip, main = "Thinned clipped original data")
plot(dens_farm_ctg, main = "Thinned las catalog")
plot(dens_farm_retile, main = "thinned retiled lascatalog")
