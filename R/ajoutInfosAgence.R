#' Procedure de lecture des changements sur les communes specifiees par l'Agence.
#'
#' @param dataCommIGN_ZR_A Data.frame. Contient les donnees Admin Express avec les informations sur les zonages
#' @param fichierChgmtsAgence Chaine de caracteres. Chemin vers le fichier des changements de l'Agence.
#' @param valZR Vecteur. Contient les differentes valeurs attendues de zonages.
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return Data.frame
#' @export
#'
#' @examples
ajoutInfosAgence <- function(dataCommIGN_ZR_A, fichierChgmtsAgence, valZR, verbose = FALSE){
  if(verbose) base::message("Lecture des changements par commune specifies par l'Agence")
  if(is.null(fichierChgmtsAgence)){
    return(dataCommIGN_ZR_A)
  } else {
    # Chargement du fichier de changement de l'agence de l'eau si il a ete specifie
    if(!file.exists(fichierChgmtsAgence)){
      base::stop(paste('Le fichier', fichierChgmtsAgence, "n'existe pas"))
    } else {
      dataChgmtsAgence <- xlsx::read.xlsx2(fichierChgmtsAgence, sheetIndex = 1)
      # Filtre sur les donnees des communes entrantes et sortantes
      dataBassinAgence <- dataChgmtsAgence[dataChgmtsAgence$TYPE_CHGMT == "SORTIE" || dataChgmtsAgence$TYPE_CHGMT == "ENTREE", ]
      # Filtre sur les donnees des communes entrantes et sortantes
      dataProgrammeAgence <- dataChgmtsAgence[dataChgmtsAgence$TYPE_CHGMT == "PROGRAMME", ]
    }
    if(nrow(dataChgmtsAgence) == 0 || (nrow(dataBassinAgence) == 0 & nrow(dataProgrammeAgence) == 0)){
      if(verbose) base::message("Pas de changement Agence defini")
      return(dataCommIGN_ZR_A)
    } else {
      # simplification de l'ecriture
      data <- dataCommIGN_ZR_A
      # Creation d'un data.frame ne contenant que les donnees des communes entrantes ou liees au changement de programme
      dfZRAgence <- dataChgmtsAgence[dataChgmtsAgence$TYPE_CHGMT == "PROGRAMME" || dataChgmtsAgence$TYPE_CHGMT == "ENTREE", ]
      # Lecteur des valeurs de zonages
      valeurZRAgence <- unique(c(dfZRAgence$ZR_POLDOM, dfZRAgence$ZR_PREL_ESU, dfZRAgence$ZR_PREL_ESO))
      # Verification des valeurs de zonage par rapport aux valeurs attendues
      if(length(valeurZRAgence[!(valeurZRAgence %in% valZR)]) != 0){
        base::stop(paste("Des valeurs de zonage ne sont pas reconnues dans le fichier :", fichierChgmtsAgence, "\n",
                         "Les valeurs doivent etre : ", paste(valZR, collapse = " ")))
      }
      # Verification de communes sortantes
      if(nrow(dataBassinAgence[dataBassinAgence$TYPE_CHGMT == "SORTIE",]) != 0){
        # Si oui, suppression des communes sortantes
        data <- data[!(data$INSEE_COM %in% dataBassinAgence[dataBassinAgence$TYPE_CHGMT == "SORTIE", "INSEE_COM"]), ]
      }
      # Verification de communes entrantes
      if(nrow(dataBassinAgence[dataBassinAgence$TYPE_CHGMT == "ENTREE",]) != 0){
        # Insertion de chaque commune
        for(i in 1:nrow(dataBassinAgence)){
          # Lecture du nouvel index
          nouvelIndex <- nrow(data) + 1
          # Lecture des nouvelles informations
          inseeCom <- dataBassinAgence[i, "INSEE_COM"]
          zrPolDom <- dataBassinAgence[i, "ZR_POLDOM"]
          zrPrelEsu <-dataBassinAgence[i, "ZR_PREL_ESU"]
          zrPrelEso <-dataBassinAgence[i, "ZR_PREL_ESO"]
          # Correction des zonages dans le fichier d'entree
          data[nouvelIndex, c("INSEE_N","ZR_POLDOM_N","ZR_PREL_ESU_N","ZR_PREL_ESO_N","INFO_N")] <- c(inseeCom, zrPolDom, zrPrelEsu, zrPrelEso, "OUI")
        }
      }

      # Verification  de modification Programme a effectuer
      if(nrow(dataProgrammeAgence) != 0){
        # Ajoute des informations liees au programme (Nouvelle definition des zonages)
        for(i in 1:nrow(dataProgrammeAgence)){
          # Lecture des nouvelles informations
          inseeCom <- dataProgrammeAgence[i, "INSEE_COM"]
          zrPolDom <- dataProgrammeAgence[i, "ZR_POLDOM"]
          zrPrelEsu <-dataProgrammeAgence[i, "ZR_PREL_ESU"]
          zrPrelEso <-dataProgrammeAgence[i, "ZR_PREL_ESO"]
          # Correction des zonages dans le fichier d'entree
          data[data$INSEE_COM == inseeCom, c("INSEE_N","ZR_POLDOM","ZR_PREL_ESU","ZR_PREL_ESO")] <- c(inseeCom, zrPolDom, zrPrelEsu, zrPrelEso)
        }
      }
      return(data)
    }
  }
}
