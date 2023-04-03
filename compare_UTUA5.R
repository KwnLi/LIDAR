library(lidR)
library(tidyterra)
library(cowplot)

# load data
U5_21_path <- "~/Documents/Local_GIS/LiDAR/LAS/Yao/LAS21/rawdata2021/UTUA5"  
U5_22_path <- "~/Documents/Local_GIS/LiDAR/LAS/Yao/LAS22/rawdata2022/UTUA5"  

U5_21_files <- list.files(U5_21_path)
U5_22_files <- list.files(U5_22_path)

U521_las <- lapply(paste(U5_21_path,U5_21_files,sep="/"), readLAS)
U522_las <- lapply(paste(U5_22_path,U5_22_files,sep="/"), readLAS)

test <- readLAS(paste(U5_21_path,U5_21_files[1],sep="/"), filter = "-keep_scan_angle -20 20")
test2 <- readLAS(paste(U5_21_path,U5_21_files[1],sep="/"))

plot(U521_las[[1]], color = "gpstime")
plot(U522_las[[1]], color = "gpstime")

# calculate intensities
# From: https://r-lidar.github.io/lidRbook/aba.html#aba-applications-density
U521_1_intens <- pixel_metrics(U521_las[[1]], ~length(Z), 1)
U522_1_intens <- pixel_metrics(U522_las[[1]], ~length(Z), 1)

# plot intensities
U521plot <- ggplot() +
  geom_spatraster(data=U521_1_intens) + ggtitle("UTUA5 2021") + coord_sf()

U522plot <- ggplot() +
  geom_spatraster(data=U522_1_intens) + ggtitle("UTUA5 2022") + coord_sf()

bothplots <- plot_grid(
  U521plot + scale_fill_gradientn(colors=rainbow(n=99,end=0.7,rev=TRUE), limits = c(0, 2659)) +
    theme(legend.position="none"),
  U522plot + scale_fill_gradientn(colors=rainbow(n=99,end=0.7,rev=TRUE), limits = c(0, 2659)),
  rel_widths = c(0.75,1)
)

# scan angles
hist(U521_las[[1]]$ScanAngleRank, main = "UTUA5 scan angle 2021", ylim=c(0,1.1e6), xlim=c(-90,90))
hist(U522_las[[1]]$ScanAngleRank, main = "UTUA5 scan angle 2022", ylim=c(0,1.1e6), xlim=c(-90,90))
