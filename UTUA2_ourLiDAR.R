library(lidR)
library(tidyverse)
library(fs)
library(sf)

# farm vector data
farms <- readRDS("~/Documents/Local_GIS/LiDAR/rworking/Data/FARMSSHP/all_farms.rds")

utua2_poly <- farms %>% filter(farm_id == "UTUA2")
utua2_buf <- st_buffer(utua2_poly, dist = 30)
utua2_ext <- utua2_buf %>% st_bbox() %>% st_as_sfc()

# read in dtm from USDA data
utua2_usda <- readLAS("~/Documents/Local_GIS/LiDAR/LAS/2018/UTUA2/USGS_LPC_PR_PRVI_D_2018_19QGA64004950.laz")
utua2_usda_clip <- utua2_usda %>% clip_roi(utua2_ext %>% st_transform(st_crs(utua2_usda)))

# calculate dtm
dtm_tin <- rasterize_terrain(utua2_usda_clip,
                             res = 1, algorithm = tin())

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

# normalize height
# opt_output_files(las_ctg) <- paste0(tempfold, "{*}_temp") # set the temporary output file location
nlas <- normalize_height(las_clip, tin(), dtm = dtm_tin) # only works when tin is read in and processed in same session

test <- nlas@data %>% group_by(Classification) %>% summarize(n = n(), .groups = "drop")

# "pit free" algorithm
chm2 <- rasterize_canopy(nlas %>% filter_poi(Classification != 18), 
                         res = 0.5, 
                         pitfree(thresholds = c(0, 10, 20), max_edge = c(0, 1.5)))

# find trees
ttops_5m <- locate_trees(nlas %>% filter_poi(Classification != 18),
                      lmf(ws = 5))  # window size = 5m
ttops_2m <- locate_trees(nlas %>% filter_poi(Classification != 18),
                         lmf(ws = 2))  # window size = 5m
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

ttops_dyn <- locate_trees(nlas %>% filter_poi(Classification != 18),
                         lmf(f))  # window size dynamic

plot(chm2)
plot(sf::st_geometry(ttops_dyn), add = TRUE, pch = 3)
plot(farms, lwd = 3, col = NA, add=TRUE)

x <- plot(nlas %>% filter_poi(Classification != 18), 
          bg = "white", size = 1)
add_treetops3d(x, ttops_5m)

# segmentation
algo_dp <- dalponte2016(chm = chm2, treetops = ttops_5m)
seg_las <- segment_trees(nlas %>% filter_poi(Classification != 18), algorithm = algo_dp)

plot(seg_las, bg = "white", size = 4, color = "treeID") # visualize trees

# crowns
crowns <- crown_metrics(seg_las, func = .stdtreemetrics, geom = "convex")

plot(seg_las %>% filter_poi(is.na(treeID)))

# try to find subcanopy
subcanopy_5m <- locate_trees(seg_las %>% filter_poi(is.na(treeID)),
                         lmf(ws = 2))  # window size = 2m

x <- plot(seg_las %>% filter_poi(is.na(treeID)),
          bg = "white", size = 1)
add_treetops3d(x, subcanopy_5m)
