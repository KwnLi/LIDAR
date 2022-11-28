library(lidR)
library(tidyverse)
library(fs)
library(sf)

## Make DTM script

# Select target farm and year
farm_yr <- 2020       # year of target farm data
farm_name <- "UTUA2"  # name of target farm data

# directory setup
laspath <- "~/Documents/Local_GIS/LiDAR"  # working directory
tempfold <- "./tempfiles/"                 # temp directory
setwd(laspath)

# farm vector data
farms <- readRDS("./rworking/Data/FARMSSHP/all_farms.rds")

# read in las files as LAScatalog
las_ctg <- readLAScatalog(paste("./LAS/output/classified_ground", farm_name, farm_yr, sep = "/"))
las_20 <- readLAS(paste("./LAS", farm_yr, farm_name, sep = "/"))

plot(las_ctg)
plot(farms, add = TRUE)

# calculate dtm
dtm_tin <- rasterize_terrain(las_ctg,
                             res = 1, algorithm = tin())
plot_dtm3d(dtm_tin, bg = "white") 

dtm_krg <- rasterize_terrain(las_ctg,
                             res = 1, algorithm = kriging())
plot_dtm3d(dtm_krg, bg = "white") 

# plot it as overhead
dtm_prod <- terra::terrain(dtm_tin, v = c("slope", "aspect"), unit = "radians")
dtm_hillshade <- terra::shade(slope = dtm_prod$slope, aspect = dtm_prod$aspect)
plot(dtm_hillshade, col = gray(0:50/50), legend = FALSE)
plot(farms, lwd = 3, color = NA, add=TRUE)

# normalize height
opt_output_files(las_ctg) <- paste0(tempfold, "{*}_temp") # set the temporary output file location
nlas <- normalize_height(las_ctg, tin())

# hist(filter_ground(nlas)$Z, main = "", xlab = "Elevation")

# make canopy height model
chm <- rasterize_canopy(nlas, res = 1,
                        algorithm = p2r(
                          subcircle = 0.15, # repl. points w/ 15cm disc
                          na.fill = tin())) # use tin to fill void
col <- height.colors(25)
plot(chm, col = col)
plot(farms, lwd = 3, color = NA, add=TRUE)

# plot it as overhead
chm_prod <- terra::terrain(chm, v = c("slope", "aspect"), unit = "radians")
chm_hillshade <- terra::shade(slope = chm_prod$slope, aspect = chm_prod$aspect)

plot(dtm_hillshade, col = gray(0:50/50), legend = FALSE,
     ext = ext(farms %>% filter(farm_id==farm_name)))
plot(chm, col = height.colors(50), legend = TRUE, alpha = 0.4,
     # ext = ext(farms %>% filter(farm_id=="UTUA30")),
     add = TRUE)
plot(farms %>% filter(farm_id==farm_name), lwd = 3, color = NA, add = TRUE)

# find trees
ttops <- locate_trees(nlas, lmf(4))
ttops