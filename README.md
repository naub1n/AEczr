# 1. AEczr

Le paquet AEczr a été créé pour répondre à la problèmatique de l'évolution des zonages de redevances des Agences de l'eau. Ces évolutions sont induites par deux processus:

* L'évolution du référentiel administratif par l'INSEE.
* Le passage à un nouveau Programme Agence de l'eau.

Les zonages sont créés pour une année donnée, en tenant compte du référentiel Administratif au 01 Janvier de l'année considérée.

La création de ces zonage est donc tributaires de plusieurs éléments:

* La diffusion du référentiel administratif COG, qui intervient en général à la fin du premier trimestre. 
* La diffusion de l'Admin Express COG par l'IGN, qui intervient quelques mois après la diffusion des données INSEE.

# 2. Source de données

Les données permettant de définir les nouveaux zonages peuvent provenir de plusieurs sources

## 2.1. RADE (Choix 1)

L'Agence de l'eau Seine-Normandie a developpé un réferentiel permettant de diffuser plus simplement les données de l'INSEE, en se bassant sur un fichier annuel des communes (1999) et les fichiers d'historique des communes. Cette application permet ainsi de consulter le référentiel administratif et de l'interroger par des Webservices.
L'application prend également en charge l'information sur la circonscription de bassin des communes.
Le code source de ce référentiel est disponible ici : https://github.com/https-github-com-RadeTeam/rade

## 2.2. INSEE (Choix 2 - Pas totalement opérationnel)

Les données de l'INSEE peuvent être utilisées pour identifier les changements administratifs. Il faudra cependant télécharger manuellement les fichiers et les placer dans les bons dossiers. Le paquet AEczr utilise deux fichiers de l'INSEE:

* Le fichier COG annuel : https://www.insee.fr/fr/information/2560452
* Le fichier des nouvelles communes : https://www.insee.fr/fr/information/2549968

*ATTENTION : L'utilisation du fichier des changements n'est pas toujours conforme à la réalité et il ne semble pas contenir les scissions. L'utilisation du fichier d'historique, comme le fait RADE, est préférable mais n'est pas encore implémenté dans ce scipt.*

*L'INSEE ayant également changé sont format de fichier pour l'année 2019. la modificatio du code est d'autant plus complexifiée. RADE prend déjà en charge ces changements.*

*La définition des circonscriptions de bassin du SANDRE n'est également pas pris en charge actuellement. La fonction de recherche des communes ne filtre donc pas sur le bassin souhaité*

## 2.3. Agence de l'eau

### 2.3.1. Fichier des zonages de l'année précédente

Le fichier des zonages de l'année précédente est obligatoire si le travail sur les zonages ne rentre pas dans le cadre d'un changement de programme. Dans ce cas, ce fichier est utilisé pour établir les zonages des nouvelles communes, en utilisant la règle de la surface du zonage le plus élevée.
Ce fichier a normalement été généré automatiquement par ce paquet l'année précédente.

Exemple : 

* Communes A - 30 Km² - Zonage Pollution BASE
* Communes B - 10 Km² - Zonage Pollution MOYENNE

=> Si les communes A et B fusionnent, le nouveau zonage pollution sera BASE.

### 2.3.2. Fichier des zonages pour l'année étudiée

ce fichier est similaire au précédent, sauf qu'il contient déja le référentiel administratif pour l'année étudiée. Ce fichier est utlisé dans le cadre d'un changement de Programme de l'Agence de l'eau, qui peut induire une refonte complète des zonages de redevance. Aucune évolution de communes ne sera appliquée à ce fichier. Il sera simplement comparé au référentiel administratif (RADE ou INSEE) pour vérifier la cohérence du nombre de communes.

### 2.3.3. Fichier des changements Agence

Ce fichier permet de spécifier des changements particuliers à appliquer aux communes. Il sert notamment :

* en cas de scission pour définir le zonage des communes filles. 
* en cas de changement de circonscription de bassin, pour faire rentrer ou sortir une commune.
* afin de forcer le changement de zonage sur une commune spécifique.

# 3. Installation

L'installation du paquet se fait à l'aide de **devtools** :

    devtools::install_github("naub1n/AEczr")
    
# 4. Structuration du dossier de travail

Le dossier de travail est indiqué dans la variable `d_projetZR`.
Ce dossier de travail doit avoir une arbrescence particulière comme suit :

*Pour des raison de simplification, les autres fichiers de définitions des couches SIG autres que le fichier .shp ne sont pas représentés mais doivent être présents.*

```bash
Dossier de travail
├── AGENCE
│   ├── 2017
│       └── Changements_Agence_2017.xlsx
│   └── 2018
├── IGN_ADMIN_EXPRESS_COG
│   ├── 2017
│   │   ├── COMMUNE.shp (Obligatoire)
│   │   └── COMMUNE_CARTO.shp (facultatif mais conseillé pour accélérer la lecture des données)
│   └── 2018
├── INSEE
│   ├── 2017
│   │   ├── COG
│   │   │   └── comsimp2017-txt.zip
│   │   └── NOUVELLES
│   │       └── communes_nouvelles_2017.xls
│   ├── 2018
│   ├── 2019
│   └── 2020
│       ├── COG
│       │   └── communes2020-csv.zip 
│       └── NOUVELLES
├── RESULTATS
│   ├── 2017
│   |   ├── COMMUNE_ZR_2017.shp
│   |   ├── Lim_Admin_2017.shp
│   |   ├── Liste_communes_ZR_2017.xlsx
│   |   ├── ZR_Poll_Base_2017.shp
│   |   ├── ZR_Poll_Moyenne_2017.shp
│   |   ├── ZR_Poll_Renforcee_2017.shp
│   |   ├── ZR_Prel_ESO_Base_2017.shp
│   |   ├── ZR_Prel_ESO_ZTQ_2017.shp
│   |   ├── ZR_Prel_ESU_Base_2017.shp
│   |   ├── ZR_Prel_ESU_Base_horsZRE_2017.shp
│   |   ├── ZR_Prel_ESU_ZTQ_2017.shp
│   |   └── ZR_Prel_ESU_ZTQ_horsZRE_2017.shp
│   └── 2018
└── ZRE
    ├── 2017
    |   ├── ESO
    |   |   └── *********.shp (Le nom n'a pas d'importance)
    |   └── ESU
    |       └── *********.shp (Le nom n'a pas d'importance)
    └── 2018
```

Le script indiquera un message d'erreur avec la donnée manquante ou le dossier manquant si besoin.

# 5. Strucutration des fichiers d'entrée

## 5.1 Fichier des zonages : Liste_communes_ZR_XXXX.xlsx

```bash
| INSEE_COM | NOM_COM | ZR_POLDOM | ZR_PREL_ESO | ZR_PREL_ESU |
|-----------|---------|-----------|-------------|-------------|
|           |         |           |             |             |
|           |         |           |             |             |
```

La colonne ZR_POLDOM peut prendre les valeurs suivantes :

* BASE
* MOYENNE
* RENFORCEE

Les colonnes ZR_PREL_ESO et ZR_PREL_ESU peut prendre les valeurs suivantes :

* BASE
* ZTQ

## 5.2 Fichier des changements Agence : Changements_Agence_XXXX.xlsx

```bash
| INSEE_COM | TYPE_CHGMT | ZR_POLDOM | ZR_PREL_ESU | ZR_PREL_ESO |
|-----------|------------|-----------|-------------|-------------|
|           |            |           |             |             |
|           |            |           |             |             |
```

La colonne TYPE_CHGMT peut prendre les valeurs suivantes :

* SCISSION -> permet de définir les zonages des communes filles
* ENTREE -> Permet de faire entrer une nouvelles communes avec ces zonages
* SORTIE -> Permet de faire sortir une commune
* PROGRAMME -> Permet de changer les zonages d'une commune

# 6. Comment utiliser le paquet

Une seule fonction est utile pour créer les nouveaux zonages : `AEczr::creationZR()`

## 6.1. Cas de la prise en compte des changements de communes en cours de Programme Agence de l'eau

Avant d'exectuer la fonction, certaines données sont nécessaires. Le script indiquera un message d'erreur avec la donnée manquante si besoin.

* Admin Express COG de l'année N
* Admin Express COG de l'année N-1
* Un accès à l'application RADE (si RADE est défini comme source INSEE = choix par défaut)
* Le fichier INSEE COG de l'année N (Si INSEE est défini comme source INSEE. ATTENTION voir chapître "Source de données")
* Le fichier des nouvelles communes de l'année N-1 (Si INSEE est défini comme source INSEE. ATTENTION voir chapître "Source de données")
* La couche SIG des ZRE ESO
* La couche SIG des ZRE ESU

`AEczr::creationZR(annee_n = 2020, d_projetZR = "D:/REDEVANCES/TEST", code_bassin = "03", zre_eso = FALSE)`

## 6.2. Cas d'un nouveau Programme

Avant d'exectuer la fonction, certaines données sont nécessaires. Le script indiquera un message d'erreur avec la donnée manquante si besoin.

* Admin Express COG de l'année N
* Un accès à l'application RADE (si RADE est défini comme source INSEE = choix par défaut)
* Le fichier INSEE COG de l'année N (Si INSEE est défini comme source INSEE. ATTENTION voir chapître "Source de données")
* Le fichier des nouvelles communes de l'année N-1 (Si INSEE est défini comme source INSEE. ATTENTION voir chapître "Source de données").

`AEczr::creationZR(annee_n = 2020, d_projetZR = "D:/REDEVANCES/TEST", code_bassin = "03", zre_eso = FALSE, nouveau_prog = TRUE)`

# 6.3 Prise en compte des ZRE

Les zones de répartition des eaux (ZRE) viennent se substituer aux zonages de prélèvement. Un découpage des zonages de prélèvement est réalisé si la prise en compte des ZRE a été indiquée dans les variables `zre_esu` et `zre_eso`. Par défaut, ces ZRE sont prises en compte. Cependant, dans le cadre des besoins de l'Agence de l'eau Seine-Normandie, les zonages pour le prélèvement en eaux souterraines ne sont pas découpés car cette information n'est pas utilisée dans son SI.
Si les ZRE n'ont pas évoluées, il faut les duppliquer dans les dossiers de l'année étudiée.

# 6.4 Circonscriptions de bassin

RADE possède, pour l'instant, des circonscriptions de bassin figées (les dernières valides).
Rejouer des créations de zonages avant l'année de mise en place de ces nouvelles circonscriptions peut poser problème dans le résultat final.
Mettre la variable `ignoreCoherence` sur `TRUE` pour continuer le traitement.

Les circonscriptions de bassin ne sont pas prises en charge quand `insee_source = "INSEE"`.

# 6.5 Informations complémentaires

D'autres variables sont paramètrables. Lire l'aide du paquet AEczr pour plus d'informations.

La vérification de la cohérence entre le traitement réalisé et l'INSEE peut bloquer le processus. Pour ne pas rendre cette vérification bloquante, mettre la variable `ignoreCoherence` sur `TRUE`.

# 7. A faire

* Ajouter la prise en charge des fichiers d'historique INSEE quand `insee_source = "INSEE"`
* Ajouter la prise en charge des données de circonscription de bassin du SANDRE quand `insee_source = "INSEE"`
* Ajouter le découpage des zonages sur les prélèvements ESO avec les ZRE ESO.
