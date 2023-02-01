library(lidR)
library(tidyverse)
library(fs)
library(sf)
library(terra)

# farm vector data
farms <- readRDS("~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.rds")

utua2_poly <- farms %>% filter(farm_id == "UTUA2")
utua2_buf <- st_buffer(utua2_poly, dist = 30)
utua2_ext <- utua2_buf %>% st_bbox() %>% st_as_sfc()

# read in dtm from USDA data
utua2_usda <- readLAS("~/Documents/Local_GIS/LiDAR/LAS/2018/UTUA2/USGS_LPC_PR_PRVI_D_2018_19QGA64004950.laz")
utua2_usda_clip <- utua2_usda %>% clip_roi(utua2_ext %>% st_transform(st_crs(utua2_usda)))
rm(utua2_usda)
gc()

# calculate dtm
dtm_tin <- rasterize_terrain(utua2_usda_clip %>% filter_poi(Classification==2),
                             res = .1, algorithm = tin())
rm(utua2_usda_clip)
gc()

# Select target farm and year
farm_yr <- 2021       # year of target farm data
farm_name <- "UTUA2"  # name of target farm data

# directory setup
laspath <- "~/Documents/Local_GIS/LiDAR"  # working directory
tempfold <- "./tempfiles/"                 # temp directory
setwd(laspath)

# read in las files as LAScatalog
las_ctg <- readLAScatalog(paste("./LAS/output/classified_ground", farm_name, farm_yr, sep = "/"))
# las_20 <- readLAS(paste("./LAS", farm_yr, farm_name, sep = "/"))

# clip las catalog
las_clip <- clip_roi(las_ctg, utua2_ext)

# segment shapes now
# las_clip_shp <- segment_shapes(las_clip, algorithm = shp_hplane())

# normalize height
# opt_output_files(las_ctg) <- paste0(tempfold, "{*}_temp") # set the temporary output file location
nlas <- normalize_height(las_clip, tin(), dtm = dtm_tin) # only works when tin is read in and processed in same session

test <- nlas@data %>% group_by(Classification) %>% summarize(n = n(), .groups = "drop")

# redo the outlier classification
nlas_noise <- classify_noise(nlas, ivf())
test2 <- nlas_noise@data %>% group_by(Classification) %>% summarize(n = n(), .groups = "drop")

# segment buildings DOESN'T WORK
# nlas_bld <- segment_shapes(nlas_noise, filter = ~Classification != 18, algorithm = shp_vline())

# normalize using original home classified ground

nlas2 <- normalize_height(las_clip, tin()) 

# "pit free" algorithm
chm2 <- rasterize_canopy(nlas2 %>% filter_poi(Classification != 18), 
                         res = 0.1, 
                         pitfree(thresholds = c(0, 10, 20), max_edge = c(0, 1.5)))

writeRaster(chm2, "UTUA2_chm.tif")
# find trees
ttops_5m <- locate_trees(nlas2 %>% filter_poi(Classification != 18),
                      lmf(ws = 5))  # window size = 5m
# ttops_2m <- locate_trees(nlas %>% filter_poi(Classification != 18),
#                          lmf(ws = 2))  # window size = 5m
# window size function of height
f <- function(x) {
  y <- 2.6 * (-(exp(-0.08*(x-2)) - 1)) + 3
  y[x < 2] <- 3
  y[x > 20] <- 5
  return(y)
}

heights <- seq(-5,30,0.5)
ws <- f(heights)
plot(heights, ws, type = "l",  ylim = c(0,5))

ttops_dyn <- locate_trees(nlas2 %>% filter_poi(Classification != 18),
                         lmf(f))  # window size dynamic

plot(chm2)
plot(sf::st_geometry(ttops_dyn), add = TRUE, pch = 3)
plot(farms, lwd = 3, col = NA, add=TRUE)

x <- plot(nlas2 %>% filter_poi(Classification != 18), 
          bg = "white", size = 1)
add_treetops3d(x, ttops_5m)

# segmentation
algo_dp <- dalponte2016(chm = chm2, treetops = ttops_5m)
algo_slv <- silva2016(chm=chm2, treetops = ttops_5m)
seg_las <- segment_trees(nlas2 %>% filter_poi(Classification != 18), algorithm = algo_dp)
seg_las2 <- segment_trees(nlas2 %>% filter_poi(Classification != 18), algorithm = algo_slv)

plot(seg_las2, bg = "white", size = 4, color = "treeID") # visualize trees

# segmentation dynamic
algo_slv_dyn <- silva2016(chm = chm2, treetops = ttops_dyn)
seg_las_dyn <- segment_trees(nlas %>% filter_poi(Classification != 18), algorithm = algo_slv_dyn)

# crowns
m <- ~list(avgZ = mean(Z), sdZ = sd(Z), avgI = mean(Intensity))
crowns <- crown_metrics(seg_las2, func = m, geom = "convex")

st_write(crowns, "UTUA2_crowns.shp")

# crowns dynamic
crowns_dyn <- crown_metrics(seg_las_dyn, func = m, geom = "convex")

# doesn't classify the big tree as well

# st_write(crowns_dyn, "UTUA2_crowns_dyn.shp")

# plot(seg_las %>% filter_poi(is.na(treeID)))

# crown from the chm
crowns_ras <- algo_slv()
plot(crowns_ras)

# use zonal statistics to calculate average height
crown_htmax <- zonal(x=chm2, z=crowns_ras, as.raster=TRUE, fun=max)

writeRaster(crown_htmax, "UTUA2_crownhtmax.tif", overwrite=TRUE)

# try to find subcanopy
hist(nlas2$Z, xlim = c(-10, 10), breaks=600)

las2m <- nlas2 %>% filter_poi(Classification != 18 & Z <=2)

# subcanopy height model
schm <- rasterize_canopy(las2m, 
                         res = 0.1, 
                         pitfree(thresholds = c(0, 10, 20), max_edge = c(0, 1.5)))

subcanopy_2m <- locate_trees(las2m,
                         lmf(ws = 1.5, hmin = 1))  # window size = 2m

plot(schm)
plot(sf::st_geometry(subcanopy_2m), add = TRUE, pch = 3)
plot(farms, lwd = 3, col = NA, add=TRUE)

x <- plot(las2m,
          bg = "white", color = "Classification", size = 1)
add_treetops3d(x, subcanopy_2m, radius=0.5)

# segment subcanopy
algo_slv_sub <- silva2016(chm=schm, treetops = subcanopy_2m)
seg_sub <- segment_trees(las2m, algorithm = algo_slv_sub)

sub_crowns <- crown_metrics(seg_sub, func = m, geom = "convex")
subcrowns_ras <- algo_slv_sub()

# use zonal statistics to calculate average height
subcrown_htmax <- zonal(x=schm, z=subcrowns_ras, as.raster=TRUE, fun=max)

writeRaster(subcrown_htmax, "UTUA2_subcanopHtmax.tif", overwrite=TRUE)
