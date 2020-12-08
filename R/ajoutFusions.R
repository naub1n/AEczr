#' Procedure de traitement des fusions de communes definies  par RADE ou l'INSEE.
#'
#' @param dataCommIGN_ZR_A Data.frame. Contient les donnees Admin Express avec les informations sur les zonages
#' @param chgmtsINSEE Data.frame. Contient l'ensemble des changements INSEE sur les communes.
#' @param valZR Vecteur. Contient les differentes valeurs attendues de zonages.
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return Data.frame.
#' @export
#'
#' @examples
ajoutFusions <- function(dataCommIGN_ZR_A, chgmtsINSEE, valZR, verbose = FALSE){
  if(verbose) base::message("Prise en compte des fusions")
  # Identification des scissions
  fusions <- chgmtsINSEE[chgmtsINSEE$chgmt == "fusion",]
  # Fin de la fonction si aucune scission n'est presente
  if(nrow(fusions) == 0){
    if(verbose) base::message("Aucune fusion")
    # Renvoie du tableau d'origine sans modification
    return(dataCommIGN_ZR_A)
  } else {
    # Traitement de chaque fusion
    for(i in 1:nrow(fusions)){
      inseeMeres <- unlist(strsplit(fusions[i, "Code.Insee"], " ", fixed = TRUE))
      inseeFille <- fusions[i, "Code"]
      maxPolDom <- selection_ZR_Fusion(dataCommIGN_ZR_A, "ZR_POLDOM", inseeMeres, verbose = verbose)
      maxPrelESO <- selection_ZR_Fusion(dataCommIGN_ZR_A, "ZR_PREL_ESO", inseeMeres, verbose = verbose)
      maxPrelESU <- selection_ZR_Fusion(dataCommIGN_ZR_A, "ZR_PREL_ESU", inseeMeres, verbose = verbose)
      for(y in 1:length(inseeMeres)){
        # Ajout des valeurs de zonage
        dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == inseeMeres[y], "ZR_POLDOM_N"] <- maxPolDom
        dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == inseeMeres[y], "ZR_PREL_ESO_N"] <- maxPrelESO
        dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == inseeMeres[y], "ZR_PREL_ESU_N"] <- maxPrelESU
        # Ajout du nouveau code INSEE dans une colonne specifique
        dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == inseeMeres[y], "INSEE_N"] <- inseeFille
        # Ajout de l'indication de nouvelle commune
        dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == inseeMeres[y], "INFO_N"] <- "OUI"
      }
    }
    return(dataCommIGN_ZR_A)
  }
}
