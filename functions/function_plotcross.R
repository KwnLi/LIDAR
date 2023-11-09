require(ggplot2)
require(dplyr)
require(cowplot)
require(sf)

# this function plots a cross section and a map of the cross section over the
# bounding polygon(s) of the las or lasCatalog
# colors are automatically assigned to the point classification
plot_cross_class <- function(las,         # can be las file or lasCatalog
                             p1 = NULL,   # starting point of cross section. If NULL, then automatically choose cross section location
                             p2 = NULL,   # ending point of cross section
                             width = 4,   # cross section width
                             title = NULL # plot title
                             )
{
  
  if(any(is.null(c(p1,p2)))){
    if(class(las) == "LAS"){
      p1 <- c(min(las@data$X), mean(las@data$Y))
      p2 <- c(max(las@data$X), mean(las@data$Y))
    }else if(class(las) == "LAScatalog"){
      p1 <- c(min(las@data$Min.X), mean(las@data$Min.Y))
      p2 <- c(max(las@data$Max.X), mean(las@data$Max.Y))
    }
  }
  data_clip <- clip_transect(las, p1, p2, width)
  
  cols <- c("1" = "gray", "2" = "purple", "18" = "orange")
  
  p <- ggplot(data_clip@data %>% mutate(Classification = as.character(Classification)), 
              aes(X,Z, color = Classification)) + 
    geom_point(size = 0.5) + 
    coord_equal() + theme_minimal() +
    scale_color_manual(values = cols) +
    theme(legend.position = c(0.9,0.9))
  
  if(!is.null(title)){
    p <- p + ggtitle(title)
  }
  
  transectline <- matrix(c(p1, p2), byrow = TRUE, ncol = 2,
                         dimnames = list(c("p1", "p2"),c("x","y"))) %>%
    as_tibble() %>% st_as_sf(coords = c("x","y")) %>% 
    mutate(lineid = 1) %>% group_by(lineid) %>% summarize() %>%
    st_cast("LINESTRING") %>% st_set_crs(st_crs(las))
  
  o <- ggplot(las$geometry) + geom_sf() + geom_sf(data = transectline) + theme_minimal()
  
  return(cowplot::plot_grid(p, o, nrow = 2))
}


# simpler version. Not sure if this one works anymore!

plot_crossection <- function(las,
                             p1 = c(min(las@data$X), mean(las@data$Y)),
                             p2 = c(max(las@data$X), mean(las@data$Y)),
                             width = 4, colour_by = NULL)
{
  colour_by <- rlang::enquo(colour_by)
  data_clip <- clip_transect(las, p1, p2, width)
  p <- ggplot(data_clip@data, aes(X,Z)) + geom_point(size = 0.5) + coord_equal() + theme_minimal()
  
  if (!is.null(colour_by)){
    cols <- c("1" = "gray", "2" = "purple", "18" = "orange")
    p <- p + aes(color = !!colour_by) + labs(color = "") +
      scale_color_manual(values = cols)
  }

  
  return(p)
}
