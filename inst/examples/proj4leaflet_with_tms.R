library(mapview) # for the popupTables
library(sp)

#' ## Example of using EPSG:28892 Projection

#' Helper function to query proj4 strings for an EPSG code.
#'  Not fool proof but works for correct codes.
getEPSG <- function(epsgCode){
  res <- httr::GET(sprintf(
    "http://epsg.io/?q=%s&format=json",epsgCode))
  if(res$status_code==200) {
    return(httr::content(res))
  } else {
    warning(sprintf(
      "Error querying EPSG code %s, Server returned %d:%s",
      epsgCode, res$status_code, httr::content(res)))
      return(NULL)
  }
}

getProj4String <- function(epsgCode) {
  res <- getEPSG(epsgCode)
  if(!is.null(res) && length(res$results)>=1) {
    return(res$results[[1]]$proj4)
  } else {
    return(NULL)
  }
}

proj4def.28992 <- getProj4String('28992')
proj4def.28992
proj4def.4326 <- getProj4String('4326')
proj4def.4326

data(meuse)
coordinates(meuse) <- ~x+y
proj4string(meuse) <- proj4def.28992
meuse.4326 <- spTransform(meuse, proj4def.4326)


#' ### Map + Markers in Spherical Mercator
#' Just to verify that everything is correct in 4326
leaflet() %>% addTiles() %>%
  addCircleMarkers(data=meuse.4326)


#' ## Now in EPSG:28992

minZoom = 0
maxZoom = 13

# lenght of resultions vector needs to correspond to maxZoom+1-minZoom
# I use the 0.42 multiplyer from the resolutions arg found at http://jsfiddle.net/_Tom_/ueRa8/
resolutions <- 0.42*(2^(maxZoom:minZoom))

crs.28992 <- leafletCRS(
  crsClass = "L.Proj.CRS",
  code = 'EPSG:28992',
  proj4def = proj4def.28992,
  resolutions = resolutions)

#' ### Just the markers
#' No need to call setView, leaflet (R package)
#' will auto determine the best initial view based on data.
leaflet(options = leafletOptions(crs = crs.28992,
                                 minZoom = minZoom,
                                 maxZoom = maxZoom)) %>%
  addCircleMarkers(data = meuse.4326, popup = popupTable(meuse))

#' ### Markers + Tiles
#' All this is adapted from http://jsfiddle.net/_Tom_/ueRa8/
#' <br/> We will use TMS http://geodata.nationaalgeoregister.nl

crs.28992.forTiles <- leafletCRS(
  crsClass = "L.Proj.CRS.TMS",
  code = 'EPSG:28992',
  proj4def = proj4def.28992,
  resolutions = resolutions,
  projectedBounds = c(-285401.92, 22598.08, 595401.9199999999, 903401.9199999999))

#' This works but there's a problem when going from Zoom level 9 to 10
#' I've started at zoom level 9, if you zoom out it works perfectly
#' If you zoom in then there's a problem from zoom level 10 onwards
#' but the problem is with the Tile Map Server (TMS) + Proj4 and not the markers.
#' You can verify that with the bottom map which is only tiles
leaflet(options = leafletOptions(crs = crs.28992.forTiles,
                                 minZoom = minZoom,
                                 maxZoom = maxZoom)) %>%
  addCircleMarkers(data = meuse.4326, popup = popupTable(meuse)) %>%
  setView(5.734745, 50.964112, zoom = 9) %>%
  addTiles('http://geodata.nationaalgeoregister.nl/tms/1.0.0/brtachtergrondkaart/{z}/{x}/{y}.png', options = tileOptions(tms=TRUE)) %>%
  htmlwidgets::onRender("function(el,t){ var myMap=this; debugger; }")


#' ### Problem with zooming
#' You can see the problem when zooming from level 9 to 10 below.
leaflet(options = leafletOptions(crs = crs.28992.forTiles,
                                 minZoom = minZoom,
                                 maxZoom = maxZoom)) %>%
  setView(5.734745, 50.964112, zoom = 9) %>%
  addTiles('http://geodata.nationaalgeoregister.nl/tms/1.0.0/brtachtergrondkaart/{z}/{x}/{y}.png', options = tileOptions(tms=TRUE)) %>%
  htmlwidgets::onRender("function(el,t){ var myMap=this; debugger; }")
