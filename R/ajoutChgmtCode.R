#' Procedure de traitement des changements de codes de communes definies  par RADE ou l'INSEE ou par le fichier des changements specifique.
#'
#' @param dataCommIGN_ZR_A Data.frame. Contient les donnees Admin Express avec les informations sur les zonages
#' @param chgmtsINSEE Data.frame. Contient l'ensemble des changements INSEE sur les communes.
#' @param valZR Vecteur. Contient les differentes valeurs attendues de zonages.
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return Data.frame
#' @export
#'
#' @examples
ajoutChgmtCode <- function(dataCommIGN_ZR_A, chgmtsINSEE, valZR, verbose = FALSE){
  if(verbose) base::message("Prise en compte des changements de codes INSEE")
  # Identification des changements de code
  chgmtCode <- chgmtsINSEE[chgmtsINSEE$chgmt == "code",]
  # Fin de la fonction si aucun changement de code n'est present
  if(nrow(chgmtCode) == 0){
    if(verbose) base::message("Aucune modification de code INSEE")
    # Renvoie du tableau d'origine sans modification
    return(dataCommIGN_ZR_A)
  } else {
    # Pour chaque changement de code ...
    for(i in 1:nrow(chgmtCode)){
      # Identification de la commune Mere et de la commune Fille
      commMere <- chgmtCode[i,]$Code.Insee
      commFille <- chgmtCode[i,]$Code
      #Identification des zonages de la commune mere
      zrPol_Dom_N <- dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "ZR_POLDOM"]
      zrPrel_ESO_N <- dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "ZR_PREL_ESO"]
      zrPrel_ESU_N <- dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "ZR_PREL_ESU"]
      # Vérification des valeurs de zonage
      if(!(zrPol_Dom_N %in% valZR) ||
         !(zrPrel_ESO_N %in% valZR) ||
         !(zrPrel_ESU_N %in% valZR) ||
         identical(zrPol_Dom_N, character(0)) ||
         identical(zrPrel_ESO_N, character(0)) ||
         identical(zrPrel_ESU_N, character(0))){
        base::stop(paste('Valeur de zonage non reconnue ou absente pour la commune', nouvellesCommunes[i]))
      }
      # Console
      if(verbose) base::message(paste("La commune",commMere,"change de code INSEE par",commFille))
      # Ajout du nouveau code INSEE dans une colonne specifique
      dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "INSEE_N"] <- commFille
      # Ajout de l'indication de nouvelle commune
      dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "INFO_N"] <- NA
      # Ajout des valeurs de zonage
      dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "ZR_POLDOM_N"] <- zrPol_Dom_N
      dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "ZR_PREL_ESO_N"] <- zrPrel_ESO_N
      dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere, "ZR_PREL_ESU_N"] <- zrPrel_ESU_N
    }
    return(dataCommIGN_ZR_A)
  }
}
