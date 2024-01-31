
find_tile_area <- function(ctg){
  area = (ctg$Max.X - ctg$Min.X) * (ctg$Max.Y - ctg$Min.Y)
  return(area)
}

check_tile_bounds <- function(ctg){
  x.bounds <- ctg$Max.X
  y.bounds <- ctg$Max.Y
  
  shared.borders <- c()
  for(i in 1:length(x.bounds)){
    
    # difference between each tile's max/min bounds and all other tiles
    x.i.max <- ctg$Max.X[i]-ctg$Min.X[-i]
    x.i.min <- ctg$Min.X[i]-ctg$Max.X[-i]
    
    y.i.max <- ctg$Max.Y[i]-ctg$Min.Y[-i]
    y.i.min <- ctg$Min.Y[i]-ctg$Max.Y[-i]
    
    x.i.shared <- any(abs(c(x.i.max, x.i.min))<1)
    y.i.shared <- any(abs(c(y.i.max, y.i.min))<1)
    
    shared.borders[i] <- x.i.shared|y.i.shared
  }
  
  return(shared.borders)
}

check_tile_size <- function(ctg){
  tile.size <- ctg$Number.of.point.records
  return(tile.size)
}