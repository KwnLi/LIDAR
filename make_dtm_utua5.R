library(lidR)
library(tidyverse)
library(fs)
library(sf)

# Testing out parameters on UTUA 5

laspath <- "~/Documents/Local_GIS/LiDAR"
tempdir <- "./tempfiles/"
setwd(laspath)

farms <- readRDS("./rworking/Data/FARMSSHP/all_farms.rds")

# read in 2021 UTUA30 (It's better)
utua30ctg <- readLAScatalog("~/Documents/Local_GIS/LiDAR/LAS/output/classified_ground/UTUA30/2021/")

plot(utua30ctg)
plot(farms, add = TRUE)

# calculate dtm
dtm_tin <- rasterize_terrain(utua30ctg,
                             res = 1, algorithm = tin())
plot_dtm3d(dtm_tin, bg = "white") 

dtm_krg <- rasterize_terrain(utua30ctg,
                             res = 1, algorithm = kriging())
plot_dtm3d(dtm_krg, bg = "white") 

# plot it as overhead
dtm_prod <- terra::terrain(dtm_tin, v = c("slope", "aspect"), unit = "radians")
dtm_hillshade <- terra::shade(slope = dtm_prod$slope, aspect = dtm_prod$aspect)
plot(dtm_hillshade, col = gray(0:50/50), legend = FALSE)
plot(farms, lwd = 3, color = NA, add=TRUE)

# normalize height
opt_output_files(utua30ctg) <- paste0(tempdir, "{*}_temp") # set the temporary output file location
nlas <- normalize_height(utua30ctg, tin())

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
     ext = ext(farms %>% filter(farm_id=="UTUA30")))
plot(chm_hillshade, col = terrain.colors(50), legend = FALSE, alpha = 0.35,
     # ext = ext(farms %>% filter(farm_id=="UTUA30")),
     add = TRUE)
plot(farms %>% filter(farm_id=="UTUA30"), lwd = 3, color = NA, add = TRUE)

# find trees
ttops <- locate_trees(nlas, lmf(4))
ttops