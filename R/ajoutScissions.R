#' Procedure de traitement des scissions de communes definies  par RADE ou l'INSEE ou par le fichier des changements specifique.
#'
#' @param dataCommIGN_ZR_A Data.frame. Contient les donnees Admin Express avec les informations sur les zonages
#' @param chgmtsINSEE Data.frame. Contient l'ensemble des changements INSEE sur les communes.
#' @param valZR Vecteur. Contient les differentes valeurs attendues de zonages.
#' @param fichierChgmtsAgence Chaine de caracteres. Chemin vers le fichier des changements specifiques.
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return Data.frame
#' @export
#'
#' @examples
ajoutScissions <- function(dataCommIGN_ZR_A, chgmtsINSEE, valZR, fichierChgmtsAgence = NULL, verbose = FALSE){
  if(verbose) base::message("Prise en compte des scissions")
  # Chargement du fichier de changement de l'agence de l'eau si il a ete specifie
  if(!is.null(fichierChgmtsAgence)){
    if(!file.exists(fichierChgmtsAgence)){
      base::stop(paste('Le fichier', fichierChgmtsAgence, "n'existe pas"))
    } else {
      dataChgmtsAgence <- xlsx::read.xlsx2(fichierChgmtsAgence, sheetIndex = 1)
      # Filtre sur les donnees de scissions
      dataScissionsAgence <- dataChgmtsAgence[dataChgmtsAgence$TYPE_CHGMT == "SCISSION",]
    }
  } else {
    # Sinon, creation d'un data.frame vide
    dataScissionsAgence <- data.frame(INSEE_COM = character(), TYPE_CHGMT = character())
  }
  # Identification des scissions
  scissions <- chgmtsINSEE[chgmtsINSEE$chgmt == "scission",]
  # Fin de la fonction si aucune scission n'est presente
  if(nrow(scissions) == 0){
    if(verbose) base::message("Aucune scission")
    # Ajout des colonnes vides sur les nouvelles informations pour éviter les erreurs dans la fonction selectionFinaleZR (plantage ajout valeurs par default sur colonnes manquantes)
    listeColonnesNouvelles <- c("ZR_POLDOM_N","ZR_PREL_ESO_N","ZR_PREL_ESU_N","INSEE_N","INFO_N")
    dataCommIGN_ZR_A[listeColonnesNouvelles] <- NA
    # Renvoie du tableau d'origine sans modification
    return(dataCommIGN_ZR_A)
  } else {
    # Identification des nouveaux codes INSEE des communes retablies
    nouvellesCommunes <- scissions[!(scissions$Code %in% scissions$Code.Insee), "Code"]
    # Ajout des communes
    for(i in 1:length(nouvellesCommunes)){
      # Identification de la commune mere
      commMere <- scissions[scissions$Code == nouvellesCommunes[i], "Code.Insee"]
      nouvelIndex <- nrow(dataCommIGN_ZR_A) + 1
      ancienIndex <- rownames(dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM == commMere,])
      # Infos de scission par l'Agence sur la commune
      dataComScissionsAgence <- dataScissionsAgence[dataScissionsAgence$INSEE_COM == nouvellesCommunes[i], ]
      # Definition des nouveaux zonages pour les communes
      # Si aucun changement n'a ete indique par l'agence de l'eau, la commune fille reprend le zonage de la commune mere
      if(nrow(dataComScissionsAgence) == 0){
        # Avertissement de l'utilisateur de l'utilisation de la regle simplifiee
        if(verbose) base::message("Regle simplifiee pour la scission de la commune ", commMere, " ; zonage mere = zonages filles")
        # Identification des zonages de la commune mere
        zrPol_Dom_N <- dataCommIGN_ZR_A[ancienIndex, "ZR_POLDOM"]
        zrPrel_ESO_N <- dataCommIGN_ZR_A[ancienIndex, "ZR_PREL_ESO"]
        zrPrel_ESU_N <- dataCommIGN_ZR_A[ancienIndex, "ZR_PREL_ESU"]
        zrPol_Dom_A <- dataCommIGN_ZR_A[ancienIndex, "ZR_POLDOM"]
        zrPrel_ESO_A <- dataCommIGN_ZR_A[ancienIndex, "ZR_PREL_ESO"]
        zrPrel_ESU_A <- dataCommIGN_ZR_A[ancienIndex, "ZR_PREL_ESU"]
      } else {
        # Avertissement de l'utilisateur de l'utilisation de la regle Agence
        if(verbose) base::message("Regle Agence pour la scission de la commune ", commMere)
        # Identification des zonages specifies par l'Agence
        zrPol_Dom_N <- dataComScissionsAgence[1, "ZR_POLDOM"]
        zrPrel_ESO_N <- dataComScissionsAgence[1, "ZR_PREL_ESO"]
        zrPrel_ESU_N <- dataComScissionsAgence[1, "ZR_PREL_ESU"]
        zrPol_Dom_A <- dataScissionsAgence[dataScissionsAgence$INSEE_COM == commMere, "ZR_POLDOM"]
        zrPrel_ESO_A <- dataScissionsAgence[dataScissionsAgence$INSEE_COM == commMere, "ZR_PREL_ESO"]
        zrPrel_ESU_A <- dataScissionsAgence[dataScissionsAgence$INSEE_COM == commMere, "ZR_PREL_ESU"]
      }
      # Vérification des valeurs de zonage
      if(!(zrPol_Dom_N %in% valZR) ||
         !(zrPrel_ESO_N %in% valZR) ||
         !(zrPrel_ESU_N %in% valZR) ||
         !(zrPol_Dom_A %in% valZR) ||
         !(zrPrel_ESO_A %in% valZR) ||
         !(zrPrel_ESU_A %in% valZR) ||
         identical(zrPol_Dom_N, character(0)) ||
         identical(zrPrel_ESO_N, character(0)) ||
         identical(zrPrel_ESU_N, character(0)) ||
         identical(zrPol_Dom_A, character(0)) ||
         identical(zrPrel_ESO_A, character(0)) ||
         identical(zrPrel_ESU_A, character(0))){
        base::stop(paste('Valeur de zonage non reconnue ou absente pour la commune', nouvellesCommunes[i]))
      }
      # Ajout des valeurs de zonage
      dataCommIGN_ZR_A[nouvelIndex, "ZR_POLDOM_N"] <- zrPol_Dom_N
      dataCommIGN_ZR_A[nouvelIndex, "ZR_PREL_ESO_N"] <- zrPrel_ESO_N
      dataCommIGN_ZR_A[nouvelIndex, "ZR_PREL_ESU_N"] <- zrPrel_ESU_N
      dataCommIGN_ZR_A[ancienIndex, "ZR_POLDOM_N"] <- zrPol_Dom_A
      dataCommIGN_ZR_A[ancienIndex, "ZR_PREL_ESO_N"] <- zrPrel_ESO_A
      dataCommIGN_ZR_A[ancienIndex, "ZR_PREL_ESU_N"] <- zrPrel_ESU_A
      # Ajout du nouveau code INSEE dans une colonne specifique
      dataCommIGN_ZR_A[nouvelIndex, "INSEE_N"] <- nouvellesCommunes[i]
      dataCommIGN_ZR_A[ancienIndex, "INSEE_N"] <- commMere
      # Ajout de l'indication de nouvelle commune
      dataCommIGN_ZR_A[nouvelIndex, "INFO_N"] <- "OUI"
      dataCommIGN_ZR_A[ancienIndex, "INFO_N"] <- "OUI"
      # Ajout de l'ancien INSEE
      dataCommIGN_ZR_A[nouvelIndex, "INSEE_COM"] <- commMere
    }
  }
  return(dataCommIGN_ZR_A)
}

