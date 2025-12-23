# MigrationWizard - Vue d'Ensemble du Projet

## 1. DESCRIPTION GENERALE

**MigrationWizard** est un assistant de migration Windows développé en PowerShell avec interface graphique WPF. Il permet d'exporter et d'importer des profils utilisateurs complets entre ordinateurs Windows, incluant fichiers, paramètres système, configurations réseau, navigateurs, et bien plus.

### Objectif Principal
Automatiser et simplifier la migration de profils utilisateurs lors du changement d'ordinateur ou de la réinstallation de Windows, tout en préservant l'intégrité des données et configurations.

### Type d'Application
- **Langage** : PowerShell 5.1+
- **Interface** : WPF (Windows Presentation Foundation) avec XAML
- **Compilation** : PS2EXE pour générer un exécutable portable standalone
- **Architecture** : Modulaire avec séparation UI/Business Logic
- **Déploiement** : Fichier EXE unique (~4MB) sans dépendances externes

---

## 2. CARACTERISTIQUES TECHNIQUES

### 2.1 Architecture Modulaire

Le projet est structuré en modules PowerShell (.psm1) organisés hiérarchiquement :

```
src/
|-- Core/                 # Logique metier centrale
|   |-- Profile.psm1       # Orchestration export/import
|   |-- Export.psm1        # Gestion des exports
|   |-- FileCopy.psm1      # Copie de fichiers robuste
|   |-- DataFolders.psm1   # Manifest des dossiers utilisateur
|   |-- OneDrive.psm1      # KFM/OneDrive (resolution chemins)
|   |-- Applications.psm1  # Analyse des apps
|   |-- Bootstrap.psm1     # Initialisation application
|-- Features/             # Fonctionnalites
|   |-- UserData.psm1
|   |-- Wifi.psm1
|   |-- Printers.psm1
|   |-- NetworkDrives.psm1
|   |-- Browsers.psm1
|   |-- Outlook.psm1
|   |-- WallpaperDesktop.psm1
|   |-- TaskbarStart.psm1
|   |-- QuickAccess.psm1
|   |-- RDP.psm1
|-- UI/                   # Interface utilisateur
|   |-- MigrationWizard.UI.psm1
|   |-- UINavigation.psm1
|   |-- TreeBuilder.psm1
|   |-- DashboardManager.psm1
|   |-- ClientSelector.psm1
|   |-- ManifestManager.psm1
|-- Modules/              # Modules transverses
|   |-- MW.Logging.psm1
|-- Assets/               # Base64 (logo, nyan cat)
```

### 2.2 Technologies Embarquées

L'application embarque plusieurs binaires en base64 :

1. **DesktopOK.exe** (1558 KB)
   - Outil tiers pour sauvegarder/restaurer positions des icônes bureau
   - Encodé en base64 dans le script fusionné
   - Extrait à la volée dans `%TEMP%\MigrationWizard\`

2. **RZGet.exe** (794 KB)
   - Gestionnaire de téléchargement Logicia
   - Usage optionnel (paramètre `-IncludeRZGet` lors de la compilation)

3. **Raccourcis Logicia** (192 KB)
   - Espace Client - Logicia.exe
   - Télémaintenance Logicia.exe (optionnel)
   - Extraits lors de l'import pour ajout au bureau public

4. **Nyan Cat JPG** (63 KB)
   - Image d'animation pour l'écran de progression
   - Affichée pendant les opérations longues

### 2.3 Système de Compilation

**Outil** : PS2EXE-GUI v0.5.0.33 by Ingo Karstein & Markus Scholtes

**Processus de build** (`Tools/Build-PortableExe.ps1`) :

1. **Lecture des sources** : Tous les fichiers .psm1 sont chargés
2. **Fusion XAML** : Interface embarquée dans le script
3. **Embarquement binaires** : Conversion base64 des .exe et images
4. **Fusion modules** : 30 modules PowerShell concaténés
5. **Injection code principal** : Point d'entrée + handlers
6. **Compilation PS2EXE** : Génération de l'EXE portable
7. **Nettoyage** : Suppression des fichiers temporaires

**Paramètres de compilation** :
```powershell
-Version "X.Y.Z.W"       # Version sémantique
-IncludeRZGet            # Inclure RZGet.exe
-KeepMergedScript        # Conserver le script fusionné pour debug
```

---

## 3. FONCTIONNALITES PRINCIPALES

### 3.1 Export de Profil

**Mode Standard** : Export complet des données utilisateur
**Mode Incrémental** : Export différentiel (uniquement modifications depuis dernier export)

**Données exportées** :

1. **Dossiers Utilisateur**
   - Bureau (Desktop)
   - Documents
   - Images (Pictures)
   - Vidéos (Videos)
   - Musique (Music)
   - Téléchargements (Downloads)
   - Favoris (Favorites)
   - Liens (Links)

2. **Dossiers Public** (optionnel)
   - Public\Desktop
   - Public\Documents
   - Public\Pictures
   - etc.

3. **AppData** (optionnel avec arborescence)
   - AppData\Local (sélection sous-dossiers)
   - AppData\Roaming (sélection sous-dossiers)
   - Exemples : Firefox, Thunderbird, Teams, etc.

4. **Options Supplémentaires** (TreeView avancé)
   - Arborescence complète C:\ navigable
   - Sélection fichiers/dossiers arbitraires
   - Utilisé pour données spécifiques (logiciels métier, bases de données locales, etc.)

5. **Paramètres Réseau**
   - Profils Wi-Fi avec mots de passe (export XML via `netsh`)
   - Imprimantes réseau et locales
   - Lecteurs réseau mappés (drives Z:, Y:, etc.)
   - Connexions RDP sauvegardées

6. **Navigateurs Web**
   - Chrome : Favoris, mots de passe*, cookies, extensions, historique
   - Firefox : Profil complet (places.sqlite, logins.json, etc.)
   - Edge : Favoris, paramètres
   - *Note : Mots de passe navigateurs nécessitent export manuel utilisateur*

7. **Applications Microsoft**
   - Outlook : Fichiers .PST, signatures, règles, comptes
   - Configuration bureau : Fond d'écran, positions icônes (DesktopOK)
   - Barre des tâches : Épinglages, ordre
   - Menu Démarrer : Épinglages
   - Accès rapide : Dossiers favoris Explorateur

### 3.2 Import de Profil

**Restauration intelligente** avec :
- Détection automatique de l'ancien nom d'utilisateur
- Réparation des raccourcis (.lnk) avec nouveau chemin utilisateur
- Préservation de la structure de dossiers
- Fusion avec données existantes (pas d'écrasement brutal)

**Ordonnancement critique** (corrigé version 1.0.23.x) :
```
1. Import-WallpaperDesktop (AVANT UserData)
   └── Clear-AllDesktops (purge totale bureau)
   └── Restore-DesktopContent (restaure depuis export)
   └── Import-DesktopPositions (DesktopOK)
   └── Add-LogiciaShortcuts (raccourcis Logicia)

2. Import-MWUserData
   └── Copie dossiers Profile (Documents, Images, etc.)
   └── Copie dossiers Public
   └── Copie Options Supplémentaires

3. Import-MWWifiProfiles
4. Import-MWPrinters
5. Import-MWNetworkDrives
6. Import-MWBrowsers
7. Import-MWOutlookData
8. Import-TaskbarStart
9. Import-MWQuickAccess
10. Repair-MWShortcuts (réparation finale)
11. Création ImportMetadata.json (tracking)
```

**Pourquoi cet ordre ?**
- Si `Import-MWUserData` était avant `Import-WallpaperDesktop`, les fichiers copiés dans "Options Supplémentaires" (ex: raccourcis vers Public\Desktop) seraient supprimés par `Clear-AllDesktops`
- Solution : Purger/restaurer AVANT de copier les fichiers supplémentaires

### 3.3 Dashboard (Tableau de Bord)

**Page d'accueil** affichant :

1. **Statistiques globales**
   - Nombre total d'exports détectés
   - Espace disque utilisé
   - Dernier export effectué
   - Dernier import effectué

2. **Liste des exports** (DataGrid)
   - Client (nom organisation)
   - PC Source (nom ordinateur origine)
   - Lecteur (D:, E:, etc.)
   - Date Export
   - Date Import (si importé)
   - Taille (GB)
   - Actions : Bouton Supprimer

3. **Détection automatique**
   - Scan des dossiers `ExeFolder\ClientName\PCName\ExportManifest.json`
   - Lecture métadonnées `.metadata.json` et `ImportMetadata.json`
   - Calcul taille récursif

---

## 4. FLUX DE TRAVAIL UTILISATEUR

### 4.1 Scénario Export

```
[Page 0 - Dashboard]
  ↓ Clic "Commencer"
[Page 1 - Choix Export/Import]
  ↓ Sélection "Export" + Informations système affichées
  ↓ Clic "Suivant"
[Page 1b - Détection export existant] (si export client existant)
  ↓ Choix : "Nouvel export complet" OU "Export incrémental"
  ↓ Si incrémental : Sélection export de référence
  ↓ Clic "Suivant"
[Page 2 - Sélection dossiers]
  ↓ Cocher dossiers utilisateur (Documents, Bureau, etc.)
  ↓ Cocher AppData (arborescence Local/Roaming)
  ↓ Cocher Options Supplémentaires (arborescence C:\)
  ↓ Clic "Suivant"
[Page 20 - Sélection fonctionnalités]
  ↓ Cocher : Wi-Fi, Imprimantes, Lecteurs réseau, RDP
  ↓ Cocher : Chrome, Firefox, Edge, Outlook
  ↓ Cocher : Bureau, Barre des tâches, Accès rapide
  ↓ Clic "Suivant"
[Page 3 - Progression]
  ↓ Affichage Nyan Cat + barre progression
  ↓ Logs temps réel
  ↓ Export en cours...
  ↓ Création ExportManifest.json
  ↓ Fin : Message succès
  ↓ Retour Dashboard
```

### 4.2 Scénario Import

```
[Page 0 - Dashboard]
  ↓ Clic "Commencer"
[Page 1 - Choix Export/Import]
  ↓ Sélection "Import"
  ↓ Clic "Suivant"
[Page 21 - Sélection export source]
  ↓ Liste déroulante des exports détectés
  ↓ OU Parcourir manuellement
  ↓ Affichage métadonnées export sélectionné
  ↓ Clic "Suivant"
[Page 22 - Confirmation import]
  ↓ Résumé : PC source → PC cible
  ↓ Liste fonctionnalités détectées dans l'export
  ↓ Avertissements si applicable
  ↓ Clic "Importer"
[Page 3 - Progression]
  ↓ Nyan Cat + barre progression
  ↓ Import en cours...
  ↓ Création ImportMetadata.json
  ↓ Fin : Message succès
  ↓ Retour Dashboard
```

---

## 5. STRUCTURE DE DONNEES

### 5.1 Arborescence Export

```
D:\                                    # Lecteur de stockage
└── ClientName\                        # Ex: "LogiciaInfo"
    └── PCName\                        # Ex: "PC-530301654"
        ├── ExportManifest.json        # Métadonnées export (OBLIGATOIRE)
        ├── ImportMetadata.json        # Métadonnées import (si importé)
        ├── .metadata.json             # Métadonnées Dashboard (optionnel)
        ├── Profile\                   # Dossiers utilisateur
        │   ├── Desktop\
        │   ├── Documents\
        │   ├── Pictures\
        │   ├── Downloads\
        │   ├── AppData\
        │   │   ├── Local\
        │   │   └── Roaming\
        │   └── Public\                # Dossiers publics
        │       ├── Desktop\
        │       └── Documents\
        ├── Desktop-User\              # Backup bureau utilisateur
        ├── Desktop-Public\            # Backup bureau public
        ├── desktop_positions.dok      # Positions icônes DesktopOK
        ├── Wifi\                      # Profils Wi-Fi
        │   ├── SSID1.xml
        │   └── SSID2.xml
        ├── Printers\                  # Imprimantes
        │   └── printers.json
        ├── NetworkDrives\             # Lecteurs réseau
        │   └── drives.json
        ├── RDP\                       # Connexions RDP
        │   └── rdp_connections.json
        ├── Browsers\                  # Navigateurs
        │   ├── Chrome\
        │   ├── Firefox\
        │   └── Edge\
        ├── Outlook\                   # Outlook
        │   ├── *.pst
        │   └── Signatures\
        ├── Taskbar\                   # Barre des tâches
        │   └── taskbar.json
        └── QuickAccess\               # Accès rapide
            └── quickaccess.json
```

### 5.2 Format ExportManifest.json

```json
{
  "ExportMetadata": {
    "ComputerName": "PC-530301654",
    "UserName": "jmthomas",
    "Domain": "WORKGROUP",
    "Date": "2025-12-22 10:30:15",
    "OsVersion": "Microsoft Windows NT 10.0.19045.0"
  },
  "ExportedItems": {
    "UserData": true,
    "SelectedFolders": [
      "Documents",
      "Desktop"
    ],
    "Wifi": true,
    "Printers": true,
    "NetworkDrives": true,
    "Rdp": true,
    "Chrome": false,
    "Edge": false,
    "Firefox": true,
    "Outlook": true,
    "Wallpaper": true,
    "DesktopLayout": true,
    "TaskbarStart": true,
    "QuickAccess": true
  },
  "Applications": [
    {
      "DisplayName": "7-Zip",
      "WingetId": "7zip.7zip"
    }
  ]
}
```

### 5.3 Format ImportMetadata.json (Nouveau - v1.0.23.x)

```json
{
  "ImportDate": "2025-12-22 14:25:10",
  "ImportedBy": "admin",
  "ImportedOnPC": "PC-NEW-789456",
  "ImportedOnDomain": "DOMAIN"
}
```

**Objectif** : Tracker quels exports ont été importés, quand, par qui, et sur quel PC.

---

## 6. COMPOSANTS CRITIQUES

### 6.1 Système de Logs

**Fichier** : `src/Modules/MW.Logging.psm1`

**Niveaux** :
- DEBUG : Informations techniques détaillées
- INFO : Opérations normales
- WARN : Avertissements non bloquants
- ERROR : Erreurs bloquantes

**Destinations** :
1. **Console PowerShell** (si non-compilé)
2. **Fichier log** : `Logs\MigrationWizard_YYYY-MM-DD_HOSTNAME.log`
3. **UI TextBox** (affichage temps réel sur Page 3)

**Fonctions** :
```powershell
Write-MWLogDebug "Message debug"
Write-MWLogInfo "Message info"
Write-MWLogWarning "Message warning"
Write-MWLogError "Message erreur"
```

### 6.2 Copie de Fichiers Robuste

**Fichier** : `src/Core/FileCopy.psm1`

**Fonction** : `Copy-MWUserDirectory`

**Mécanisme** :
1. **Robocopy** pour copie bulk avec retry
2. **Options** : `/MIR` (mode miroir pour incrémental), `/R:3` (3 tentatives), `/W:5` (5 sec entre tentatives)
3. **Filtres** : Exclusion fichiers système, temporaires, caches
4. **Logs** : Capture stdout/stderr Robocopy
5. **Fallback** : Copy-Item si Robocopy échoue

**Mode Incrémental** :
- Utilise `/MIR` de Robocopy
- Compare dates de modification
- Copie uniquement fichiers nouveaux/modifiés
- Gain temps + espace disque considérable

### 6.3 TreeView de Sélection

**Fichier** : `src/UI/TreeBuilder.psm1`

**Fonctionnalité** : Arborescence de dossiers avec cases à cocher

**Construction** :
1. **Dossiers utilisateur standard** : Documents, Bureau, etc. (cochés par défaut)
2. **AppData** :
   - AppData\Local (décoché, sous-dossiers navigables)
   - AppData\Roaming (décoché, sous-dossiers navigables)
3. **C:\ complet** :
   - Racine C:\ (décoché)
   - Tous sous-dossiers navigables (Program Files, Users, Windows, etc.)
   - Expansion lazy (chargement à la demande)

**Gestion état** :
- Checkbox tri-state : Coché, Décoché, Indéterminé
- Propagation parent→enfants et enfants→parent
- Événements `Checked`, `Unchecked`, `Expanded`

**Extraction sélection** :
```powershell
$selectedPaths = @()
foreach ($node in $treeView.Items) {
    if ($node.IsChecked) {
        $selectedPaths += $node.Tag  # Tag contient le chemin complet
    }
}
```

### 6.4 Système de Navigation

**Fichier** : `src/UI/UINavigation.psm1`

**Pages** :
- Page 0 : Dashboard
- Page 1 : Choix Export/Import
- Page 11 (1b) : Détection export existant (mode incrémental)
- Page 2 : Sélection dossiers
- Page 20 : Sélection fonctionnalités
- Page 21 : Sélection export source (import)
- Page 22 : Confirmation import
- Page 3 : Progression

**Fonction** : `Show-UIPage`
```powershell
Show-UIPage -PageNumber 2 -Window $script:Window
```

**Validation** :
- Chaque page a des règles de validation
- Bouton "Suivant" désactivé si validation échoue
- Messages d'erreur contextuels

---

## 7. PROBLEMES RESOLUS (Historique Débogage)

### 7.1 DesktopOK Export Manquant (v1.0.22.0)

**Symptôme** : `WARN Fichier positions DesktopOK introuvable: D:\...\desktop_positions.dok`

**Cause** : Dans `Get-EmbeddedDesktopOK`, vérification `$PSScriptRoot` qui est VIDE en mode compilé PS2EXE

**Solution** :
```powershell
# AVANT (bugué)
if ($PSScriptRoot) {
    $toolsPath = Join-Path $PSScriptRoot '..\Tools\DesktopOK.exe'
    if (Test-Path $toolsPath) {
        return $toolsPath
    }
}

# APRES (corrigé)
# Supprimé vérification $PSScriptRoot
# Utilise uniquement extraction depuis $script:DESKTOPOK_BASE64
```

**Fichier** : `src/Features/WallpaperDesktop.psm1:323-372`

### 7.2 Raccourcis Logicia Path Vide (v1.0.22.0)

**Symptôme** : `ERROR Impossible de lier l'argument au paramètre 'Path', car il s'agit d'une chaîne vide`

**Cause** : Même problème `$PSScriptRoot` vide dans `Get-EmbeddedFile`

**Solution** : Supprimé vérification fichier local, utilise uniquement base64 embarqué

**Fichier** : `src/Features/WallpaperDesktop.psm1:374-420`

### 7.3 Raccourcis Options Supplémentaires Supprimés (v1.0.23.0)

**Symptôme** : Raccourcis copiés dans "Options Supplémentaires" (ex: vers Public\Desktop) disparaissent après import

**Cause** : Ordre d'import incorrect
```
1. Import-MWUserData → Copie raccourcis vers Public\Desktop
2. Import-WallpaperDesktop → Clear-AllDesktops SUPPRIME tout
```

**Solution** : Inversé l'ordre dans `Import-MWProfile`
```powershell
# NOUVEL ORDRE
1. Import-WallpaperDesktop  # Purge + restaure bureau AVANT
2. Import-MWUserData        # Copie Options Supplémentaires APRÈS
```

**Fichier** : `src/Core/Profile.psm1:267-277`

### 7.4 Dashboard DataGrid Erreur Binding (v1.0.23.1-23.5)

**Symptôme** : "Exception lors de la définition de « ItemsSource » : Impossible de convertir @{ClientName=...}"

**Causes multiples** :

1. **PowerShell array unroll** : Tableau à 1 élément "déroulé" en objet
   - Solution : `$exports = @(Get-MWExportsList)` pour forcer array

2. **ObservableCollection incompatible** : PowerShell compilé ne gère pas bien `ObservableCollection[Object]`
   - Solution : Utiliser `System.Collections.ArrayList` à la place

3. **DateTime.ToString() non supporté** : `.ToString('dd/MM/yyyy HH:mm')` échoue en mode compilé
   - Solution : `Get-Date $dt -Format 'dd/MM/yyyy HH:mm'`

4. **StringFormat sur valeur $null** : WPF DataGrid binding échoue sur `ImportDate` = `$null`
   - Solution : Convertir dates en strings AVANT création objet, utiliser '' au lieu de $null

**Fichiers** :
- `src/UI/MigrationWizard.UI.psm1:688-716` (ArrayList)
- `src/UI/DashboardManager.psm1:110-138` (Get-Date formatting)
- `src/UI/MigrationWizard.xaml:297-298` (Binding sans StringFormat)

### 7.5 Colonnes DataGrid Non Redimensionnables (v1.0.23.5)

**Symptôme** : Impossible de redimensionner colonnes Dashboard en temps réel

**Solution** : Ajout propriétés WPF
```xaml
<DataGrid CanUserResizeColumns="True"
          ColumnHeaderHeight="32"
          EnableColumnVirtualization="False"
          VirtualizingPanel.IsVirtualizing="False">
```

**Fichier** : `src/UI/MigrationWizard.xaml:277-297`

---

## 8. SECURITE ET BONNES PRATIQUES

### 8.1 Mots de Passe

**Wi-Fi** : Exportés avec clé (nécessite admin)
```powershell
netsh wlan export profile key=clear
```

**Navigateurs** :
- Chrome/Edge : Base de données chiffrée copiée telle quelle (utilisateur doit être le même OU export manuel)
- Firefox : Fichiers `logins.json` + `key4.db` copiés

**IMPORTANT** : MigrationWizard ne déchiffre JAMAIS les mots de passe. Il copie les bases chiffrées. Le déchiffrement se fait par le navigateur sur le PC cible avec les identifiants utilisateur Windows.

### 8.2 Élévation de Privilèges

L'application NÉCESSITE des droits administrateur pour :
- Export profils Wi-Fi avec clés
- Configuration imprimantes système
- Accès à certains dossiers système
- Modification registre (RDP, Taskbar, etc.)

**Vérification** :
```powershell
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Droits administrateur requis"
}
```

### 8.3 Validation Entrées

- Paths : `Test-Path -LiteralPath` pour éviter injections
- Noms clients/PC : Regex `^[a-zA-Z0-9_-]+$` (pas de caractères spéciaux)
- Taille max fichiers : Avertissement si >50GB
- Espace disque : Vérification avant export

### 8.4 Gestion Erreurs

**Principe** : Try-Catch systématique avec logs

```powershell
try {
    Export-MWWifiProfiles -DestinationFolder $dest
} catch {
    Write-MWLogError "Export Wi-Fi échoué : $($_.Exception.Message)"
    # Continuer avec autres fonctionnalités (non bloquant)
}
```

**Erreurs bloquantes** :
- Dossier destination inaccessible
- Droits insuffisants sur source critique
- Corruption manifest

**Erreurs non-bloquantes** :
- Wi-Fi échoue → Continue avec Imprimantes
- Un navigateur absent → Continue avec autres
- DesktopOK échoue → Bureau restauré sans positions

---

## 9. VERSIONING

**Format** : X.Y.Z.W (Sémantique adaptée)

- **X (Major)** : Changements architecture majeurs, ruptures compatibilité
- **Y (Minor)** : Nouvelles fonctionnalités, ajouts modules
- **Z (Patch)** : Corrections bugs, améliorations mineures
- **W (Build)** : Numéro de build automatique

**Versions clés** :

- **1.0.0.0** : Version initiale fonctionnelle
- **1.0.10.0** : Ajout Firefox Local+Roaming, Thunderbird
- **1.0.20.0** : TreeView Options Supplémentaires avec C:\
- **1.0.21.0** : Export incrémental avec détection page 1b
- **1.0.22.0** : Fix DesktopOK + Logicia (problème $PSScriptRoot)
- **1.0.23.0** : Import JSON tracking + Dashboard dates import
- **1.0.23.5** : Fix Dashboard DataGrid complet (ArrayList + Get-Date + colonnes)

**Changelog** : Voir `CHANGELOG.md` (à créer)

---

## 10. COMPILATION ET DEPLOIEMENT

### 10.1 Prérequis

- Windows 10/11 ou Windows Server 2016+
- PowerShell 5.1 minimum
- PS2EXE-GUI installé (`Install-Module ps2exe`)
- Droits admin pour compilation

### 10.2 Commande de Build

```powershell
.\Tools\Build-PortableExe.ps1 -Version "1.0.23.5" -IncludeRZGet
```

**Options** :
- `-Version` : Numéro de version (obligatoire)
- `-IncludeRZGet` : Inclure RZGet.exe (optionnel)
- `-KeepMergedScript` : Conserver le script fusionné pour debug

### 10.3 Étapes Build

1. Lecture 30 modules sources (.psm1)
2. Lecture XAML (43 KB)
3. Embarquement Nyan Cat JPG (63 KB)
4. Embarquement RZGet.exe (794 KB) - optionnel
5. Embarquement DesktopOK.exe (1558 KB)
6. Embarquement raccourcis Logicia (192 KB)
7. Fusion modules → `Build/MigrationWizard.Merged.ps1` (4109 KB)
8. Compilation PS2EXE → `Build/MigrationWizard.exe` (4.05 MB)
9. Nettoyage fichiers temporaires

**Durée** : ~20-30 secondes

### 10.4 Distribution

**Fichier unique** : `MigrationWizard.exe` (4.05 MB)

**Déploiement** :
1. Copier .exe sur clé USB / lecteur réseau
2. Double-clic pour lancer (demande élévation UAC)
3. Interface WPF s'ouvre
4. Utilisation normale

**Pas de dépendances** :
- .NET Framework déjà présent sur Windows 10/11
- Pas d'installation requise
- Pas de registry
- Pas de fichiers config externes

---

## 11. LIMITATIONS CONNUES

1. **PowerShell 5.1 requis** : Ne fonctionne pas avec PowerShell Core 7.x (WPF partiellement supporté)

2. **Windows uniquement** : Pas de support Linux/Mac (évident mais à noter)

3. **Taille exports** : Exports >100GB peuvent être lents (Robocopy optimisé mais limité par I/O disque)

4. **Mots de passe navigateurs** : Nécessite même compte Windows ou export manuel utilisateur

5. **Applications installées** : Ne migre PAS les logiciels installés, uniquement données/configs

6. **Registre** : Migration partielle (RDP, Taskbar), pas de migration complète registre

7. **Permissions NTFS** : Peuvent être perdues si export vers FAT32/exFAT (recommandé : NTFS)

8. **OneDrive** : Support partiel (KFM détecté, chemins résolus). Pas de sync/hydratation automatique globale.

9. **Comptes utilisateurs** : Ne crée pas de comptes, assume compte cible existe

10. **Langue** : Interface en français uniquement (internationalisation TODO)

---

## 12. ROADMAP FUTURE

### 12.1 Fonctionnalités Planifiées

- [ ] Améliorer OneDrive (sync/hydratation automatique)
- [ ] Migration Microsoft Store apps
- [ ] Export/Import paramètres Windows (thème, confidentialité, etc.)
- [ ] Support PowerShell 7.x
- [ ] Mode ligne de commande (CLI) pour scripts automatisés
- [ ] Chiffrement exports (AES-256)
- [ ] Compression exports (ZIP/7z)
- [ ] Upload cloud (Azure, AWS S3, etc.)
- [ ] Planification automatique (tâches planifiées)
- [ ] Interface multilingue (EN, FR, DE, ES)
- [ ] Mode serveur (exports centralisés en entreprise)

### 12.2 Améliorations Techniques

- [ ] Tests unitaires (Pester framework)
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Signature code (certificat Authenticode)
- [ ] Telemetry anonyme (opt-in)
- [ ] Auto-update depuis GitHub releases
- [ ] Documentation utilisateur (PDF)
- [ ] Vidéos tutoriels
- [ ] Mode debug avancé (traces détaillées)

---

## 13. SUPPORT ET CONTRIBUTION

### 13.1 Contact

**Développeur** : JMThomas (Logicia Informatique)
**Email** : [À remplir]
**GitHub** : [À remplir]

### 13.2 Reporting Bugs

1. Vérifier logs : `Logs\MigrationWizard_YYYY-MM-DD_HOSTNAME.log`
2. Capturer screenshots erreurs
3. Noter version exacte (affichée en bas dashboard)
4. Décrire étapes de reproduction
5. Joindre ExportManifest.json si pertinent (anonymisé)

### 13.3 Contribution Code

**Convention PowerShell** :
- PascalCase pour fonctions : `Export-MWProfile`
- camelCase pour variables : `$exportPath`
- Verbes approuvés PowerShell : Get-, Set-, New-, Remove-, Export-, Import-
- Commentaires en français (code en anglais acceptable)
- Pas de tabulations (4 espaces)

**Structure commit** :
```
[Type] Courte description (max 72 chars)

Description détaillée si nécessaire.

Fixes #123
```

Types : `[Feature]`, `[Fix]`, `[Refactor]`, `[Docs]`, `[Test]`

---

**FIN DU DOCUMENT 01-VUE-ENSEMBLE.md**

---

*Prochains documents à créer :*
- 02-ARCHITECTURE-TECHNIQUE.md
- 03-REFERENCE-API.md
- 04-GUIDE-DEVELOPPEUR.md
- 05-TROUBLESHOOTING.md
