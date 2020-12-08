#' Procedure de lecture des donnees Admin Express
#'
#' @param annee Entier. Annee du referentiel Admin Express
#' @param d_admin_express Chaine de caracteres. Chemin vers le dossier contenant les donnees Admin Express structuree par annee. Attention: mettre des '/' pour le chemin, y compris sous Windows.
#' @param carto Booleen. Indique si la fonction privilegie la couche "_CARTO" de l'ADmin Express = version simplifiee des contours des communes
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return SpatialPolygonsDataFrame.
#' @export
#'
#' @examples
lectureAdminExpress <- function(annee, d_admin_express, carto = TRUE, verbose = FALSE){
  if(verbose) base::message("Lecture de l'Admin Express de l'annee ", annee, "\n", d_admin_express)
  # Definition du chemin vers l'annee de la couche souhaitee
  d_commCOG <- paste0(d_admin_express, "/", annee)
  # Creation du dossier de l'anneee s'il n'existe pas (induira ensuite une erreur de lecture des couches)
  base::dir.create(d_commCOG, showWarnings = FALSE)
  # Definition des chemins vers les couches COMMUNE
  # _CARTO etant une simplification geometrique, elle est moins lourde et est donc privilegiee
  shpCommCarto <- paste0(d_commCOG,"/COMMUNE_CARTO.shp")
  shpComm <- paste0(d_commCOG,"/COMMUNE.shp")
  # Verification de l'existance d'une des deux couches
  if(!file.exists(shpCommCarto) && !file.exists(shpComm)){
    # Message d'erreur si aucune n'existe
    base::stop(paste("Le fichier shape de la couche des communes n'existe pas pour l'annee", annee, ":", d_commCOG))
  # Verification en priorite de l'existance de la version _CARTO (simplifiee) si demande en parametre d'entree
  } else if(file.exists(paste0(d_commCOG,"/COMMUNE_CARTO.shp")) && carto == TRUE){
    layer <- "COMMUNE_CARTO"
  }else{
    # Sinon utilisation de la version precise
    layer <- "COMMUNE"
  }
  # Lecture de la donnees cartographique
  shpAdminExpress <- rgdal::readOGR(dsn = d_commCOG,
                 layer = layer,
                 stringsAsFactors = FALSE,
                 verbose = verbose)
  # Valeur de retour de la fonction
  return(shpAdminExpress)
}
