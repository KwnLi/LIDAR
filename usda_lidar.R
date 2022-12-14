library(lidR)
library(tidyverse)
library(fs)
library(sf)

# farm vector data
farms <- readRDS("~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.rds")

utua2 <- readLAS("~/Documents/Local_GIS/LiDAR/LAS/2018/UTUA2/USGS_LPC_PR_PRVI_D_2018_19QGA64004950.laz")

utua2_poly <- farms %>% filter(farm_id == "UTUA2")
utua2_buf <- st_buffer(utua2_poly, dist = 30) %>%
  st_transform(st_crs(utua2))
utua2_ext <- utua2_buf %>% st_bbox() %>% st_as_sfc()

las_clip <- clip_roi(utua2, utua2_ext)

test <- las_clip@data %>% group_by(Classification) %>% summarize(n = n(), .groups = "drop")

# calculate dtm
dtm_tin <- rasterize_terrain(las_clip,
                             res = 1, algorithm = tin())
# plot_dtm3d(dtm_tin, bg = "white") 

# dtm_krg <- rasterize_terrain(las_clip,
#                              res = 1, algorithm = kriging())
# plot_dtm3d(dtm_krg, bg = "white") 

# save dtm_tin for use with our las 
saveRDS(dtm_tin, file = "dtm_UTUA2_USDA2018.rds")

# normalize height
nlas <- normalize_height(las_clip, tin())

# make canopy height model
chm <- rasterize_canopy(nlas, res = 1,
                        algorithm = p2r(
                          subcircle = 0.15, # repl. points w/ 15cm disc
                          na.fill = tin())) # use tin to fill void
col <- height.colors(25)
plot(chm, col = col)
plot(farms, lwd = 3, color = NA, add=TRUE)

# "pit free" algorithm
chm2 <- rasterize_canopy(nlas %>% filter_poi(Classification != 7&Classification != 18), 
                         res = 0.5, 
                         pitfree(thresholds = c(0, 10, 20), max_edge = c(0, 1.5)))

# find trees
ttops <- locate_trees(nlas %>% filter_poi(Classification != 7&Classification != 18),
                      lmf(ws = 5))  # window size = 5m, i.e., 2.5 radius
plot(chm2)
plot(sf::st_geometry(ttops), add = TRUE, pch = 3)
plot(farms, lwd = 3, col = NA, add=TRUE)

x <- plot(nlas %>% filter_poi(Classification != 7&Classification != 18), 
          bg = "white", size = 1)
add_treetops3d(x, ttops)
