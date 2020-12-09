#' Fonction principale permettant de generer les couches des zonages de revedevances a partir des donnees de RADE ou de l'INSEE.
#'
#' @param annee_n Entier. Represente l'annee etudiee, pour laquelle les zonages doivent etre crees
#' @param d_projetZR Chaine de caracteres. Chemin vers le dossier racine du projet. Attention: mettre des '/' pour le chemin, y compris sous Windows.
#' @param code_bassin Chaine de caracteres. Indique le code SANDRE de la circonscription de bassin souhaitee.
#' @param nouveau_prog Booleen. Indique si un nouveau programme debute a l'annee etudiee. La procedure se basera sur le fichier de communes de l'annee N et non celui de l'annee N-1.
#' @param d_admin_express Chaine de caracteres. Facultatif. Chemin vers le dossier contenant les donnees Admin Express structuree par annee. Attention: mettre des '/' pour le chemin, y compris sous Windows.
#' @param d_ZRE Chaine de caracteres. Facultatif. Chemin vers le dossier contant les couches ZRE structurees par type : ESU, ESO
#' @param zre_esu Booleen. Indique si les ZRE ESU doivent etre prises en compte.
#' @param zre_eso Booleen. Indique si les ZRE ESO doivent etre prises en compte.
#' @param f_commzr_a Chaine de caracteres. Facultatif. Chemin complet vers le fichier des zonages de l'annee precedente. Attention: mettre des '/' pour le chemin, y compris sous Windows.
#' @param insee_source Chaine de caracteres. Facultatif. Defini la source des donnees INSEE. RADE ou INSEE. RADE fait reference au projet de l'AESN. INSEE correspond aux fichiers a disposition sur le site de l'INSEE.
#' @param chgmtsAgence Booleen. Indique si des changements specifiques doivent etre pris en compte. Cela sert notament pour les changements de programme, de communes sortantes ou entrantes. Un fichier specifique est a remplir. Le script va creer un fichier vierge s'il n'existe pas.
#' @param valZR Vecteur. Contient les differentes valeurs attendues de zonages.
#' @param ignoreCoherence Booleen. Indique si la procedure de verification entre les codes INSEE du tableau auquel les fusions et scissions ont ete applique, correspond a la liste des codes INSEE attendus par les donnees INSEE.
#' @param verbose Booleen. Indique si les messages d'information sont affiches.
#'
#' @return un booleen. TRUE si le traitement a reussi.
#'
#' @export
#'
#' @examples
creationZR <- function(annee_n, d_projetZR, code_bassin, nouveau_prog = FALSE, d_admin_express = NULL, d_ZRE = NULL, zre_esu = TRUE, zre_eso = TRUE,
                       f_commzr_a = NULL, insee_source = "RADE", chgmtsAgence = FALSE,
                       valZR = c("BASE", "MOYENNE", "RENFORCEE", "ZTQ"), ignoreCoherence = FALSE, verbose = FALSE){
  # Definition du chemin par defaut vers le fichier des zonages
  if(is.null(f_commzr_a)) {
    if(nouveau_prog == TRUE){
      # S'il s'agit d'un nouveau programme, le fichier des zonage de l'annee en cours est pris en compte. (Les zonages ont ete redefinis)
      f_commzr_a <- paste0(d_projetZR,"/RESULTATS/", annee_n, "/Liste_communes_ZR_", annee_n, ".xlsx")
    } else {
      # Dans le cas contraire, les zonages de l'annee precedente sont utilises
      f_commzr_a <- paste0(d_projetZR,"/RESULTATS/", annee_n - 1, "/Liste_communes_ZR_", annee_n - 1, ".xlsx")
    }
  }
  # Si le fichier des zonages n'existe pas, une erreur est levee
  if(!file.exists(f_commzr_a)){
    # Creation de l'arborescence par defaut pour aider l'utilisateur
    if(nouveau_prog == TRUE){
      dir.create(paste0(d_projetZR,"/RESULTATS/", annee_n - 1), recursive = TRUE, showWarnings = FALSE)
    } else {
      dir.create(paste0(d_projetZR,"/RESULTATS/", annee_n), recursive = TRUE, showWarnings = FALSE)
    }
    # Indication de l'erreur d'acces au fichier
    base::stop(paste('Le fichier', f_commzr_a, "n'existe pas"))
  }
  # Definition du chemin par defaut vers les couches SIG de l'IGN Admin Express COG
  if(is.null(d_admin_express)) d_admin_express <- paste0(d_projetZR,"/IGN_ADMIN_EXPRESS_COG")
  # Si le dossier contenant les donnees IGN n'existe pas, une erreur est levee
  if(!file.exists(d_admin_express)){
    # Creation de l'arborescence par defaut pour aider l'utilisateur
    dir.create(d_admin_express, recursive = TRUE, showWarnings = FALSE)
    # Indication de l'erreur d'acces au fichier
    base::stop(paste('Le dossier', d_admin_express, "n'existe pas"))
  }
  # Lecture du fichier des zonages
  if(verbose) base::message("Lecture du fichier Excel des zonages des communes \n", f_commzr_a)
  commZR_A <- xlsx::read.xlsx2(file = f_commzr_a, sheetIndex = 1)
  # S'il s'agit d'un nouveau programme, les etapes sont simplifiees, le fichiers des communes est deja pret.
  if(nouveau_prog == TRUE){
    if(verbose) base::message("Procedure pour un nouveau programme")
    # Le fichier final correspond deja au fichier d'entree. (Nouveau programme oblige)
    commZR_N_Final <- commZR_A
    # Lecture des donnees INSEE de la nouvelle etudiee pour verifier la coherence du fichier de zonages
    dataINSEE <- lectureINSEE(annee_n = annee_n, code_bassin = code_bassin, d_projetZR = d_projetZR, type = insee_source, verbose = verbose)
  # Dans le cas ou ce n'est pas un nouveau programme, la procedure utilise le fichier des zonages de l'annee precedente et applique les changements de communes.
  } else {
    #Chargement de l'Admin Express COG pour l'annee N-1
    commIGN_A <- lectureAdminExpress(annee = annee_n - 1, d_admin_express = d_admin_express, verbose = verbose)
    # Filtre sur les communes presentes dans le fichier de zonages de l'annee precedente
    commIGN_A <- commIGN_A[commIGN_A@data$INSEE_COM %in% commZR_A$INSEE_COM,]
    # Ajout des infos sur les redevances
    commIGN_ZR_A <- sp::merge(commIGN_A, commZR_A, by.x = "INSEE_COM", by.y = "INSEE_COM")
    # Ajout des surfaces
    commIGN_ZR_A$SURF <- sapply(methods::slot(commIGN_ZR_A, "polygons"), methods::slot, "area")

    # Definition du fichier des changements definis par l'Agence
    if(chgmtsAgence == TRUE){
      # Definition du dossier contenant le fichier des changements
      dossierChgmtsAgence <- paste0(d_projetZR, "/AGENCE/", annee_n)
      # Definition du fichier des changements
      fichierChgmtsAgence <- paste0(dossierChgmtsAgence, "/Changements_Agence_", annee_n, ".xlsx")
      # Creation du dossier contenant les changements s'il n'existe pas
      dir.create(dossierChgmtsAgence, recursive = TRUE, showWarnings = FALSE)
      # Verificatio de l'existence du fichier des changements
      if(!file.exists(fichierChgmtsAgence)){
        # Creation d'un data.frame vide
        dfChgmtsAgence <- data.frame(INSEE_COM = character(), TYPE_CHGMT = character(),
                                     ZR_POLDOM = character(), ZR_PREL_ESU = character(), ZR_PREL_ESO = character())
        # Creation du fichier des changements vide
        xlsx::write.xlsx2(dfChgmtsAgence, fichierChgmtsAgence, row.names = FALSE)
        # Indication de l'absence de fichier de changements
        base::warning(paste("Aucun fichier sur des changements de communes defini par l'Agence n'existe :", fichierChgmtsAgence, "\n",
                            "Un fichier vide a ete cree. Pour ne pas prendre en compte des changements Agence, mettre le parametre",
                            "'chgmtsAgence' a FALSE."))
      }
    } else {
      fichierChgmtsAgence = NULL
    }

    # Lecture des donnees INSEE
    dataINSEE <- lectureINSEE(annee_n = annee_n, code_bassin = code_bassin, d_projetZR = d_projetZR, type = insee_source, verbose = verbose)
    # Identification des changements
    anneeMinChgmt <- as.Date(paste0(annee_n - 1, "-01-02"), format = "%Y-%m-%d")
    chgmtsINSEE <-  dataINSEE[as.Date(dataINSEE$Debut.validite, format = "%Y-%m-%d") >= anneeMinChgmt &
                                !is.na(dataINSEE$Debut.validite),]

    # Traitement des scissions
    commZR_Ns <- ajoutScissions(dataCommIGN_ZR_A = commIGN_ZR_A@data,
                                chgmtsINSEE = chgmtsINSEE,
                                valZR = valZR,
                                fichierChgmtsAgence = fichierChgmtsAgence,
                                verbose = verbose)

    # Ajout du traitement des fusions
    commZR_Nf <- ajoutFusions(dataCommIGN_ZR_A = commZR_Ns, chgmtsINSEE = chgmtsINSEE, valZR = valZR, verbose = verbose)

    # Ajout des information specifiques definies par l'Agence
    commZR_Na <- ajoutInfosAgence(dataCommIGN_ZR_A = commZR_Nf, fichierChgmtsAgence = fichierChgmtsAgence, valZR = valZR, verbose = verbose)

    # Ajout des informations sur les communes qui n'ont pas changees
    commZR_N_Final <- selectionFinaleZR(dataCommIGN_ZR_A = commZR_Na, dataINSEE = dataINSEE, verbose = verbose)
  }

  # PROCEDURE COMMUNE AVEC OU SANS NOUVEAU PROGRAMME

  # Verification de la coherence du nombre de communes
  # ATTENTION : Peut etre le cas lors des changements de bassin
  if(nrow(commZR_N_Final) != nrow(dataINSEE)){
    # Definition du message d'erreur
    msgCoherence <- paste("Incoherence entre les donnees du traitement et l'INSEE sur les communes suivantes: \n",
                          "Communes non presentes dans les donnees de l'INSEE\n",
                          paste(base::setdiff(commZR_N_Final$INSEE_COM, dataINSEE$Code), collapse = " "), "\n",
                          "Communes non presentes dans les donnees de zonages de l'annee n-1\n",
                          paste(base::setdiff( dataINSEE$Code, commZR_N_Final$INSEE_COM), collapse = " "))
    # Indication du message en Warning ou en Error.
    if(ignoreCoherence == TRUE) base::warning(msgCoherence) else base::stop(msgCoherence)
  } else {
    if(verbose) base::message("Nombre de communes coherent : ", nrow(commZR_N_Final), " communes pour l'annee ", annee_n)
  }

  #Filtre sur les communes officielles de l'INSEE de l'annee N
  # TRAITEMENT INUTILE. JE LAISSE AU CAS OU.
  #commZR_N_Final_Filtre <- commZR_N_Final[commZR_N_Final$INSEE_COM %in%  dataINSEE$Code,]
  commZR_N_Final_Filtre <- commZR_N_Final

  # Creation du dossier de resultat de l'annne etudiee
  dir.create(paste0(d_projetZR,"/RESULTATS/", annee_n), recursive = TRUE, showWarnings = FALSE)

  # Dans le cas ou il ne s'agit pas d'un nouveau programme, le fichier des communes est cree
  if(nouveau_prog == FALSE){
    # Definition du fichier final de sortie
    f_commzr_n <- paste0(d_projetZR,"/RESULTATS/", annee_n, "/Liste_communes_ZR_", annee_n, ".xlsx")
    # Export du fichier final
    xlsx::write.xlsx2(commZR_N_Final_Filtre, file = f_commzr_n, sheetName = "communes_ZR", row.names = FALSE)
  }

  # Chargement de l'Admin Express COG pour l'annee N (Utilisation des donnees precises = Non _Carto)
  commIGN_N <- lectureAdminExpress(annee = annee_n, d_admin_express = d_admin_express, carto = FALSE, verbose = verbose)

  # Fusion des donnees de nouveaux zonages et de l'IGN
  commIGN_ZR_N <- sp::merge(commIGN_N, commZR_N_Final_Filtre, by.x = "INSEE_COM", by.y = "INSEE_COM", all.x = FALSE, all.y = TRUE)

  # Traitement geographique
  geometriesZonages(annee_n, d_projetZR, commIGN_ZR_N, zre_esu = zre_esu, zre_eso = zre_eso, d_ZRE = d_ZRE, verbose = verbose)

  return(TRUE)
}

