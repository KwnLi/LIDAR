library(lidR)
library(sf)
library(tidyverse)

plots <- st_read("./data/plots_all.geojson") %>%
  mutate(FARM = str_replace(FARM, 'JAYU2/3', 'JAYU2_3')) %>%
  mutate(clipname = paste0(FARM,"-",year,"-","s",substr(Size,1,2),"-p",plot_num))

st_write(plots, "./data/plots_clipnames.gpkg")

# make clipping polygons
# combine overlapping polygons and buffer by 10
# keep track of which original plots go where 
# This turned out not to reduce the number of clipping plots needed! So not using.
# 
# farms <- st_read("./data/farms.gpkg") %>%
#   mutate(farm_id = str_replace(farm_id, 'JAYU2&3', 'JAYU2/3'))
# 
# plots_u <- st_cast(st_union(plots), "POLYGON") %>% st_sf() %>%
#   st_join(farms %>% st_buffer(20)) %>%
#   st_buffer(10, joinStyle = "MITRE", mitreLimit = 2) %>%
#   group_by(farm_id) %>% mutate(clip_id = paste0(farm_id,"-",letters[row_number(farm_id)]))
# 
# plot_groups.df <- st_intersects(plots, plots_u) %>% as.data.frame()
# 
# plots_clipgroups <- plots %>% 
#   bind_cols(plots_u[plot_groups.df$col.id,] %>% st_drop_geometry()) %>%
#   select(-farm_id)
# 
# st_write(plots_u, "./data/clipgroups.gpkg", append=FALSE)
# st_write(plots_clipgroups, "./data/plots_clipgroups.gpkg")

##### Clip lidar data #####
# cycle through retiled data and clip out plots
datadir <- "~/Documents/Data/Output/retile/"
outdir <- "~/Documents/Data/Output/clip_retile/"
# dir.create(outdir)

for(i in 1:nrow(plots)){
  plot.i <- plots[i,]
  year.i <- plot.i$year
  farm.i <- plot.i$FARM
  name.i <- plot.i$clipname
  
  las.i <- readLAScatalog(
    folder=paste0(datadir,year.i,"/",farm.i,"/")
  )
  
  buf.i <- st_buffer(plot.i, 10, joinStyle = "MITRE", mitreLimit = 2) # square buffer by 10m
  
  las.i.clip <- clip_roi(las.i, buf.i)
  
  writeLAS(las.i.clip, paste0(outdir,name.i,".las"))
}
