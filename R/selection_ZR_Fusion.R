#' Fonction permettant de definir le bon zonage de redevance lors d'une fusion de plusieurs commune. Regle : Zonage final = Plus grane surface par zonage.
#'
#' @param dataCommIGN_ZR_A Data.frame. Contient les donnees Admin Express avec les informations sur les zonages
#' @param champ_zr Chaine de caracteres. Indique le champ (= type de zonage) etudie.
#' @param inseeMeres Vecteur. Contient les codes INSEE des communes qui fusionnent
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return Chaine de caracteres.
#' @export
#'
#' @examples
selection_ZR_Fusion <- function(dataCommIGN_ZR_A, champ_zr, inseeMeres, verbose = FALSE){
  if(verbose) base::message("Definition du zonage lors d'un fusion \n",
                            "Champ zonage : ", champ_zr, " ; Communes meres : " , paste(inseeMeres, collapse = " "))
  # Filtre sur les communes concernees par le traitement
  dfFusions <- dataCommIGN_ZR_A[dataCommIGN_ZR_A$INSEE_COM %in% inseeMeres,]
  #Si aucune commune mere n'est presente dans le fichier de zonage ancien, la fonction retourne NA
  if(length(unique(dfFusions[,champ_zr])) == 0){
    return(NA)
  # Si les communes meres ont le meme zonage ...
  } else if(length(unique(dfFusions[,champ_zr])) == 1){
    # ... la fonction retourne directement le zonage
    return(unique(dfFusions[,champ_zr]))
  # Sinon il faut calculer les surfaces de chaque valeur du zonage
  } else {
    # Creation d'un data.frame temporaire qui contiendra la surface cumulee par valeur du zonage
    dfZonage <- data.frame(valeur = unique(dfFusions[,champ_zr]), surf = 0)
    # Calcul de chaque surface cumulée
    dfZonage$surf <- apply(dfZonage, 1, function(x) sum(dfFusions[dfFusions[,champ_zr] == x["valeur"], "SURF"]))
    # Identification de la valeur de zonage avec la plus grande surface
    valeurFusion <- dfZonage[dfZonage$surf == max(dfZonage$surf), "valeur"]
    # Valeur de retour
    return(valeurFusion)
  }
}
