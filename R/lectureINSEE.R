#' Procedure de lecture des donnees INSEE provenant de RADE ou des fichiers de l'INSEE
#'
#' @param annee_n Entier. Annee du referentiel INSEE
#' @param code_bassin Chaine de caracteres. Indique le code SANDRE de la circonscription de bassin souhaitee.
#' @param d_projetZR Chaine de caracteres. Chemin vers le dossier racine du projet. Attention: mettre des '/' pour le chemin, y compris sous Windows.
#' @param type Chaine de caracteres. Indique la source de la donnee. RADE ou INSEE
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return Data.frame
#' @export
#'
#' @examples
lectureINSEE <- function(annee_n, code_bassin, d_projetZR = NULL, type = "RADE", verbose = FALSE){
  if(verbose) base::message("Lecture des donnees INSEE pour l'annee ", annee_n)
  # Lecture des donnees venant de RADE
  if(type == "RADE"){
    # Creation d'un fichier temporaire qui contiendra l'extraction de RADE
    dataRade <- base::tempfile()
    # Envoi d'une requete POST a RADE pour recuperer les liste des communes actives au 1er Janvier
    if(verbose) base::message("Lecture des donnees de RADE")
    httr::POST(url='http://rade.aesn.fr/referentiel/commune/resultats',
               body=list(
                 codeInsee = "",
                 nomEnrichi = "",
                 codeRegion = "-1",
                 codeDepartement = "-1",
                 codeCirconscription = code_bassin,
                 dateEffet = base::paste0(annee_n, "-01-01"),
                 valider = ""
               )
    )
    # Envoi d'une seconde requete POST pour telecharger le fichier Excel
    httr::POST(url='http://rade.aesn.fr/referentiel/commune/export',
         encode = "form", httr::write_disk(dataRade, overwrite = T))
    # Lecture des donnees recuperees
    data <- xlsx::read.xlsx2(dataRade, sheetIndex = 1, startRow = 2, stringsAsFactors = FALSE)
    # Suppression des accents dans les noms de champ
    colnames(data) <-  iconv(colnames(data),to="ASCII//TRANSLIT")
    # Convertion/creation du champs data (format Excel)
    data$Debut.validite <- as.Date(as.integer(data$Debut.validite), origin = "1899-12-30")
    # Creation d'une liste de valeur courte (mode list plus facile a lire et modifier)
    simplChgmt <- list(
      "Commune nouvelle avec déléguée : commune-pôle" = "fusion",
      "Fusion : commune absorbante" = "fusion",
      #"Changement de nom" = "",
      "Commune se séparant" = "scission",
      "Commune nouvelle sans déléguée : commune-pôle" = "fusion",
      "Rétablissement" = "scission"
    )
    # Transformation de la liste en data.frame
    simplChgmt <- data.frame(chgmtLong = names(simplChgmt), chgmtCourt = unlist(unname(simplChgmt)), stringsAsFactors = FALSE)
    # LE FORMAT DES ESPACES PERTURBENT LES COMPARAISON => SUPRESSION DES ESPACES
    # Supression des espaces dans la liste des changements simplifies
    simplChgmt$chgmtLong <- gsub("[[:space:]]", "_", simplChgmt$chgmtLong)
    # Supression des espaces dans la liste des changements de RADE
    data$Motif.de.modification <- gsub("[[:space:]]", "_", data$Motif.de.modification)
    # Ajout de la colonne avec la simplification des changements
    data$chgmt <- apply(data, 1,
                        function(x) {
                          # Identification de la valeur courte
                          chgmt_court <- simplChgmt[simplChgmt$chgmtLong == x[["Motif.de.modification"]],"chgmtCourt"]
                          # S'il n'y a pas de correspondance, affectation d'une valeur vide
                          if(identical(chgmt_court, character(0))) chgmt_court <- ""
                          # Valeur de retour de la fonction
                          return(chgmt_court)
                        })
    # Suppression des DOM/TOM
    data <- data[as.integer(data$Code) < 97000,]
    # Donnees en sortie de la fonction
    return(data)

  } else if(type == "INSEE"){

    # Le tableau de rendu est calque sur celui de RADE
    dossierCOG <- paste0(d_projetZR, "/INSEE/", annee_n, "/COG")
    base::dir.create(dossierCOG, recursive = TRUE, showWarnings = verbose)

    if(annee_n >= 2019){
      fichierCommunesCOG <- paste0(dossierCOG, "/communes", annee_n,".csv")
      zipCommunesCOG <- paste0(dossierCOG, "/communes", annee_n,"-csv.zip")
    } else {
      fichierCommunesCOG <- paste0(dossierCOG, "/comsimp", annee_n,".txt")
      zipCommunesCOG <- paste0(dossierCOG, "/comsimp", annee_n,"-txt.zip")
    }

    if(verbose) base::message("Lecture des donnees du fichier INSEE : ", fichierCommunesCOG)
    # Verification de l'existence du fichier communes COG de l'INSEE
    if(!file.exists(fichierCommunesCOG)){
      # Si non, verification de la version ZIP
      if(file.exists(zipCommunesCOG)){
        # Decompression de la version ZIP
        utils::unzip(zipCommunesCOG, exdir = dossierCOG)
      # Si aucun fichier n'est trouve, une erreur est levee
      } else {
        base::stop(paste("Aucun fichier COG de l'INSEE dans :", fichierCommunesCOG, "\n",
                         "Telechargez les donnees a cette adresse : https://www.insee.fr/fr/information/2560452"))
      }
    }
    # Lecture du fichier TXT ou CSV selon l'annee, toutes les colonnes sont considerees comme du text
    if(annee_n >= 2019){
      data <- utils::read.csv2(fichierCommunesCOG, colClasses = "character", sep = ",", encoding = "UTF-8")
      # Creation de la colonne contenant le code INSEE
      data$Code <- data$com
      # Creation de la colonne Nom (creation d'une nouvelle colonne si par la suite, l'ajout de l'article semble necessaire)
      data$Nom <- data$nccenr
    } else {
      data <- utils::read.delim2(fichierCommunesCOG, colClasses = "character")
      # Concatenation du code departement et commune
      data$Code <- apply(data, 1, function (x) paste0(x["DEP"], x["COM"]))
      # Creation de la colonne Nom (creation d'une nouvelle colonne si par la suite, l'ajout de l'article semble necessaire)
      data$Nom <- data$NCCENR
    }

    ###########################################
    # PARTIE A REVOIR.
    # LE FICHIER DES NOUVELLES COMMUNES DE
    # L'INSEE NE CONTIENT PAS LES FUSIONS.
    # IL FAUT UTILISER LE FICHIER HISTORIQUE
    ###########################################
    # Definition du dossier des nouvelles communes
    dossierNouvellesCommunes <- paste0(d_projetZR, "/INSEE/", annee_n -1 , "/NOUVELLES")
    # Creation du dossier s'il nexiste pas
    base::dir.create(dossierNouvellesCommunes, recursive = TRUE, showWarnings = verbose)
    # Definition du fichier des nouvelles communes
    fichierNouvellesCommunes <- paste0(dossierNouvellesCommunes, "/communes_nouvelles_",annee_n - 1,".xls")
    # Verification de l'existence du fichier des nouvelles de l'INSEE
    if(verbose) base::message("Lecture du fichier des nouvelles de l'INSEE : ", fichierNouvellesCommunes)
    if(!file.exists(fichierNouvellesCommunes)){
      base::stop(paste("Aucun fichier des nouvelles communes de l'INSEE dans :", fichierNouvellesCommunes, "\n",
                       "Telechargez les donnees a cette adresse : https://www.insee.fr/fr/information/2549968"))
    }
    # Lecture du fichier INSEE des nouvelles communes
    nouvellesCommunes <- xlsx::read.xlsx2(fichierNouvellesCommunes, sheetIndex = 1)
    # Liste des codes INSEE des nouvelles communes
    INSEENouvellesCom <- unique(nouvellesCommunes$DepComN)
    # Suppression des valeurs vides
    INSEENouvellesCom <- INSEENouvellesCom[INSEENouvellesCom != "" & !(is.na(INSEENouvellesCom))]

    for(i in 1:length(INSEENouvellesCom)){
      # Definition de la liste des codes INSEE dans anciennes communes
      INSEEAnciennesCom <- nouvellesCommunes[nouvellesCommunes$DepComN == INSEENouvellesCom[i], "DepComA"]
      # S'il n'y a qu'une seule ancienne commune alors c'est une scission sinon c'est une fusion
      typeChangement <- if(length(INSEEAnciennesCom) == 1) "scission" else "fusion"
      # Definition de la date de debut de validite. La premiere date est choisie au cas ou plusieurs ressortiraient (ce qui ne devrait pas etre le cas)
      debutValidite <- unique(nouvellesCommunes[nouvellesCommunes$DepComN == INSEENouvellesCom[i], "Date1"])[1]
      # Formatage de la date
      if(nchar(debutValidite) == 10){
        # Si elle est deja au format date, formatage de l'ordre
        debutValidite <- format(strptime(debutValidite, "%d/%m/%Y"),"%Y-%m-%d")
      } else {
        # Si au format Entier, conversion
        debutValidite <- as.Date(as.integer(debutValidite), origin = "1899-12-30")
      }
      # Ajout du type de changement dans le tableau general des communes COG
      data[data$Code == INSEENouvellesCom[i], "chgmt"] <- typeChangement
      # Ajout des codes INSEE des anciennes communes dans le tableau general des communes COG
      data[data$Code == INSEENouvellesCom[i], "Code.Insee"] <- paste(INSEEAnciennesCom, collapse = " ")
      # Ajout de la date de validite des changements dans le tableau general des communes COG
      data[data$Code == INSEENouvellesCom[i], "Debut.validite"] <- debutValidite
    }
    # Simplification des colonnes au format RADE
    data <- data[,c("Code","Nom","Debut.validite","Code.Insee","chgmt")]
    # Donnees en sortie de la fonction
    return(data)
  } else {
    base::stop(paste("Type de lecture inconnu. Le type peut etre : RADE ou INSEE"))
  }
}

