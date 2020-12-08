#' Procedure d'export des couches SIG des zonages de redevances avec les decoupage sur les ZRE si necessaire.
#'
#' @param annee_n Entier. Represente l'annee etudiee, pour laquelle les zonages doivent etre crees
#' @param d_projetZR Chaine de caracteres. Chemin vers le dossier racine du projet. Attention: mettre des '/' pour le chemin, y compris sous Windows.
#' @param commIGN_ZR_N Data.frame. Donnees contenant la liste des codes INSEE des communes et les zonages affectes a chaque commune
#' @param zre_esu Booleen. Indique si les zonages ZRE ESU sont pris en compte.
#' @param zre_eso Booleen. Indique si les zonages ZRE ESO sont pris en compte.
#' @param d_ZRE Chaine de caracteres. Facultatif. Chemin vers le dossier contant les couches ZRE structurees par type : ESU, ESO
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @export
#'
#' @examples
geometriesZonages <- function(annee_n, d_projetZR, commIGN_ZR_N, zre_esu = TRUE, zre_eso = TRUE, d_ZRE = NULL, verbose = FALSE){
  if(verbose) base::message("Procedure de creation des couches par zonage")
  # Identification du chemin complet vers les ZRE ESU
  if(is.null(d_ZRE)){
    d_ZRE_ESU <- paste0(d_projetZR, "/ZRE/", annee_n, "/ESU")
  } else {
    d_ZRE_ESU <- paste0(d_ZRE, "/ESU")
  }
  # Identification du chemin complet vers les ZRE ESO
  if(is.null(d_ZRE)){
    d_ZRE_ESO <- paste0(d_projetZR, "/ZRE/", annee_n, "/ESO")
  } else {
    d_ZRE_ESO <- paste0(d_ZRE, "/ESO")
  }

  #Verification de l'existence des couches ZRE
  # Si des ZRE ESU sont a prendre en compte
  if(zre_esu == TRUE){
    # Verification de l'existance du dossier
    if(!dir.exists(d_ZRE_ESU)){
      # Si le dossier n'existe pas , il est cree
      dir.create(d_ZRE_ESU, recursive = TRUE, showWarnings = verbose)
      # Le script s'arrete car aucune couche ne sera trouvee
      base::stop(paste("Aucune ZRE ESU trouvee dans",d_ZRE_ESU))
    } else {
      # Si le dossier existe, on liste les fichiers shp
      coucheZRE_ESU <- list.files(path = d_ZRE_ESU, pattern = "\\.shp$")
      if(length(coucheZRE_ESU) != 1){
        # Si aucun ou plusieurs fichiers sont trouves, une erreur est levee
        base::stop(paste("Aucune ou plusieurs couches ZRE ESU ont ete trouvees dans",d_ZRE_ESU))
      }
    }
  }
  # Si des ZRE ESO sont a prendre en compte
  if(zre_eso == TRUE){
    # Verification de l'existance du dossier
    if(!dir.exists(d_ZRE_ESO)){
      # Si le dossier n'existe pas , il est cree
      dir.create(d_ZRE_ESO, recursive = TRUE, showWarnings = verbose)
      # Le script s'arrete car aucune couche ne sera trouvee
      base::stop(paste("Aucune ZRE ESO trouvee dans",d_ZRE_ESO))
    } else {
      # Si le dossier existe, on liste les fichiers shp
      coucheZRE_ESO <- list.files(path = d_ZRE_ESO, pattern = "\\.shp$")
      if(length(coucheZRE_ESO) != 1){
        # Si aucun ou plusieurs fichiers sont trouves, une erreur est levee
        base::stop(paste("Aucune ou plusieurs couches ZRE ESO ont ete trouvees dans",d_ZRE_ESO))
      }
    }
  }

  #Definition du numero unique comme ID des polygones Commune
  commIGN_ZR_N<-sp::spChFIDs(commIGN_ZR_N,as.character(commIGN_ZR_N$ID))
  #Fusion des communes par zonage
  shpZR_POL<-maptools::unionSpatialPolygons(commIGN_ZR_N,commIGN_ZR_N@data$ZR_POLDOM)
  shpZR_ESO<-maptools::unionSpatialPolygons(commIGN_ZR_N,commIGN_ZR_N@data$ZR_PREL_ESO)
  shpZR_ESU<-maptools::unionSpatialPolygons(commIGN_ZR_N,commIGN_ZR_N@data$ZR_PREL_ESU)
  # Verification de l'existance de chaque zonage
  exist_POL_BASE <- "BASE" %in% commIGN_ZR_N@data$ZR_POLDOM
  exist_POL_MOY <- "MOYENNE" %in% commIGN_ZR_N@data$ZR_POLDOM
  exist_POL_REN <- "RENFORCEE" %in% commIGN_ZR_N@data$ZR_POLDOM
  exist_PREL_ESO_BASE <- "BASE" %in% commIGN_ZR_N@data$ZR_PREL_ESO
  exist_PREL_ESO_ZTQ <- "ZTQ" %in% commIGN_ZR_N@data$ZR_PREL_ESO
  exist_PREL_ESU_BASE <- "BASE" %in% commIGN_ZR_N@data$ZR_PREL_ESU
  exist_PREL_ESU_ZTQ <- "ZTQ" %in% commIGN_ZR_N@data$ZR_PREL_ESU
  #Creation des SpatialPolygonsDataFrame par valeur de zonage
  if(exist_POL_BASE) shpZR_POL_Base <- sp::SpatialPolygonsDataFrame(shpZR_POL["BASE",],data = data.frame(value="BASE", row.names="BASE"))
  if(exist_POL_MOY) shpZR_POL_Moy <- sp::SpatialPolygonsDataFrame(shpZR_POL["MOYENNE",],data = data.frame(value="MOYENNE", row.names="MOYENNE"))
  if(exist_POL_REN) shpZR_POL_Ren <- sp::SpatialPolygonsDataFrame(shpZR_POL["RENFORCEE",],data = data.frame(value="RENFORCEE", row.names="RENFORCEE"))
  if(exist_PREL_ESO_BASE) shpZR_ESO_Base <- sp::SpatialPolygonsDataFrame(shpZR_ESO["BASE",],data = data.frame(value="Base", row.names="BASE"))
  if(exist_PREL_ESO_ZTQ) shpZR_ESO_ZTQ <- sp::SpatialPolygonsDataFrame(shpZR_ESO["ZTQ",],data = data.frame(value="ZTQ", row.names="ZTQ"))
  if(exist_PREL_ESU_BASE) shpZR_ESU_Base <- sp::SpatialPolygonsDataFrame(shpZR_ESU["BASE",],data = data.frame(value="Base", row.names="BASE"))
  if(exist_PREL_ESU_ZTQ) shpZR_ESU_ZTQ <- sp::SpatialPolygonsDataFrame(shpZR_ESU["ZTQ",],data = data.frame(value="ZTQ", row.names="ZTQ"))
  #Creation des shp indirectes
  shpLimAdmin <- maptools::unionSpatialPolygons(commIGN_ZR_N,rep(1, length(commIGN_ZR_N)))
  shpLimAdmin <- sp::SpatialPolygonsDataFrame(shpLimAdmin,data = data.frame(value="Limite_AESN", row.names=1))

  dossierResultat <- paste0(d_projetZR,"/RESULTATS/", annee_n)
  dir.create(dossierResultat, showWarnings = verbose)

  #Exportation des fichier SHP
  if(verbose) base::message("Export des zonages sans ZRE")
  rgdal::writeOGR(commIGN_ZR_N, dossierResultat, paste0("COMMUNE_ZR_",annee_n),"ESRI Shapefile", verbose = verbose)
  if(exist_POL_BASE) rgdal::writeOGR(shpZR_POL_Base, dossierResultat, paste0("ZR_Poll_Base_",annee_n),"ESRI Shapefile", verbose = verbose)
  if(exist_POL_MOY) rgdal::writeOGR(shpZR_POL_Moy, dossierResultat, paste0("ZR_Poll_Moyenne_",annee_n),"ESRI Shapefile", verbose = verbose)
  if(exist_POL_REN) rgdal::writeOGR(shpZR_POL_Ren, dossierResultat, paste0("ZR_Poll_Renforcee_",annee_n),"ESRI Shapefile", verbose = verbose)
  if(exist_PREL_ESO_BASE) rgdal::writeOGR(shpZR_ESO_Base, dossierResultat, paste0("ZR_Prel_ESO_Base_",annee_n),"ESRI Shapefile", verbose = verbose)
  if(exist_PREL_ESO_ZTQ) rgdal::writeOGR(shpZR_ESO_ZTQ, dossierResultat, paste0("ZR_Prel_ESO_ZTQ_",annee_n),"ESRI Shapefile", verbose = verbose)
  if(exist_PREL_ESU_BASE) rgdal::writeOGR(shpZR_ESU_Base, dossierResultat, paste0("ZR_Prel_ESU_Base_",annee_n),"ESRI Shapefile", verbose = verbose)
  if(exist_PREL_ESU_ZTQ) rgdal::writeOGR(shpZR_ESU_ZTQ, dossierResultat, paste0("ZR_Prel_ESU_ZTQ_",annee_n),"ESRI Shapefile", verbose = verbose)
  rgdal::writeOGR(sp::spTransform(shpLimAdmin, sp::CRS("+init=epsg:2154")), dossierResultat, paste0("Lim_Admin_",annee_n),"ESRI Shapefile", overwrite_layer = T, verbose = verbose)

  if(zre_esu == TRUE){
    #Chargement des ZRE
    if(verbose) base::message("Chargement des ZRE")
    shpZRE_Sup <- rgdal::readOGR(dsn = d_ZRE_ESU,
                                 layer = tools::file_path_sans_ext(coucheZRE_ESU),
                                 stringsAsFactors = FALSE, verbose = verbose)
    #Decoupage des ZR avec les ZRE
    if(verbose) base::message("Decoupage des zonages avec les ZRE")
    if(exist_PREL_ESU_BASE) shpZR_ESU_Base_hZRE <- rgeos::gDifference(shpZR_ESU_Base, shpZRE_Sup)
    if(exist_PREL_ESU_ZTQ) shpZR_ESU_ZTQ_hZRE <- rgeos::gDifference(shpZR_ESU_ZTQ, shpZRE_Sup, drop_lower_td = T)

    ##Suppression des artefacts avec une surface inferieur à 50000 m²
    if(verbose) base::message("Suppression des artefacts")
    if(exist_PREL_ESU_BASE) shpZR_ESU_Base_hZRE <- suppArtefact(shpZR_ESU_Base_hZRE, 50000)
    if(exist_PREL_ESU_ZTQ) shpZR_ESU_ZTQ_hZRE <- suppArtefact(shpZR_ESU_ZTQ_hZRE, 50000)

    #Creation d'un spatialpolygondataframe pour l'export
    if(exist_PREL_ESU_BASE) shpZR_ESU_Base_hZRE <- sp::SpatialPolygonsDataFrame(shpZR_ESU_Base_hZRE, data = data.frame(value="Base_horsZRE", row.names="1"))
    if(exist_PREL_ESU_ZTQ) shpZR_ESU_ZTQ_hZRE <- sp::SpatialPolygonsDataFrame(shpZR_ESU_ZTQ_hZRE, data = data.frame(value="ZTQ_horsZRE", row.names="1"))
    #Export des couches
    if(verbose) base::message("Export de la couche Prel ESU hors ZRE")
    if(exist_PREL_ESU_BASE) rgdal::writeOGR(shpZR_ESU_Base_hZRE, dossierResultat, paste0("ZR_Prel_ESU_Base_horsZRE_", annee_n), "ESRI Shapefile", overwrite_layer = T)
    if(exist_PREL_ESU_ZTQ) rgdal::writeOGR(shpZR_ESU_ZTQ_hZRE, dossierResultat, paste0("ZR_Prel_ESU_ZTQ_horsZRE_", annee_n), "ESRI Shapefile", overwrite_layer = T)
  }
}
