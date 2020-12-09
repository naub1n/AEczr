#' Procedure simplifiant les donnes sur les nouvelles communes. Elle permet de definir la structure du fichier des zonages qui sera reutilise l'annee suivante.
#'
#' @param dataCommIGN_ZR_A Data.frame. Contient les donnees Admin Express avec les informations sur les zonages
#' @param dataINSEE Data.frame. Contient les informations de l'INSEE au format RADE pour l'annee etudiee (Resultat de la fonction lectureINSEE()).
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return Data.frame.
#' @export
#'
#' @examples
selectionFinaleZR <- function(dataCommIGN_ZR_A, dataINSEE, verbose = FALSE){
  if(verbose) base::message("Finalisation de la structure et des donnees du tableau des zonages")
  # Simplification de l'écriture
  d <- dataCommIGN_ZR_A
  # Ajout des informations sur les communes qui n'ont pas changee
  # pour chaque zonage
  d[is.na(d$INSEE_N), "ZR_POLDOM_N"] <- d[is.na(d$INSEE_N), "ZR_POLDOM"]
  d[is.na(d$INSEE_N), "ZR_PREL_ESU_N"] <- d[is.na(d$INSEE_N), "ZR_PREL_ESU"]
  d[is.na(d$INSEE_N), "ZR_PREL_ESO_N"] <- d[is.na(d$INSEE_N), "ZR_PREL_ESU"]
  # pour chaque code insee
  d[is.na(d$INSEE_N), "INSEE_N"] <- d[is.na(d$INSEE_N), "INSEE_COM"]
  # sur l'indicatation qu'il ne s'agit pas de communes nouvelles
  d[is.na(d$INSEE_N), "INFO_N"] <- "NON"
  # Ajout du nom des communes
  d$NOM_COM <- apply(d, 1, function(x) dataINSEE[dataINSEE$Code == x["INSEE_N"], "Nom"])
  # Simplification des colonnes
  d <- d[,c("INSEE_N", "NOM_COM","INFO_N","ZR_POLDOM_N","ZR_PREL_ESO_N","ZR_PREL_ESU_N")]
  # Renommage des colonnes
  colnames(d) <- c("INSEE_COM", "NOM_COM","NOUVEAU","ZR_POLDOM","ZR_PREL_ESO","ZR_PREL_ESU")
  # Suppression des doublons
  d <- unique(d)
  # Verification de la coherence des codes INSEE
  VerifDoublons <- duplicated(d$INSEE_N[!(is.na(d$INSEE_N))])

  if(length(VerifDoublons[VerifDoublons == TRUE]) != 0){
    base::stop(paste("Des communes en double ont ete detectees :", paste(d[VerifDoublons, "INSEE_N"], collapse = " "), "\n",
                     "Verifiez le fichier des changements Agence"))
  }
  # Valeur de retour
  return(d)
}
