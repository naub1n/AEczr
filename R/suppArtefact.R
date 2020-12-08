#' Fonction de suppression des polygons artefacts suite a la découpe des ZRE.
#'
#' @param poly SpatialPolygonsDataFrame. Couche sur laquelle les polygones inferieur à la surface limite seront supprimes.
#' @param limArea Entier. Surface limite des polygones. En dessous de cette limite, tous les polygones sont supprimes.
#'
#' @return SpatialPolygonsDataFrame.
#' @export
#'
#' @examples
suppArtefact <- function(poly, limArea){
  poly_p <- methods::slot(poly, "polygons")
  poly_pP <- sapply(poly_p, methods::slot, "Polygons")
  poly_pP_area <- sapply(poly_pP, methods::slot, "area")
  poly_pP_sommets <- lapply(sapply(poly_pP,methods::slot, "coords"), nrow)
  l_poly_a <- poly_pP_area > limArea
  l_poly_s <- poly_pP_sommets > 2
  poly_final <- sp::Polygons(poly_pP[l_poly_a+l_poly_s==2], "1")
  spoly_final <- sp::SpatialPolygons(list(poly_final), proj4string = sp::CRS(sp::proj4string(poly)))
  return(spoly_final)
}
