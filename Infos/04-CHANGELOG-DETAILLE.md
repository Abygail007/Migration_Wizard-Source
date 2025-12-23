# MigrationWizard - Changelog Détaillé

## Version 1.0.23.5 (2025-12-22) - ACTUELLE

### Correctifs Critiques

#### Dashboard DataGrid Fix Complet
- **FIX** : Utilisation `Get-Date -Format` au lieu de `.ToString()` pour compatibilité PS2EXE
- **FIX** : ArrayList au lieu d'ObservableCollection pour binding WPF
- **FIX** : Conversion dates en strings AVANT création objets (évite StringFormat sur null)
- **FIX** : Toutes propriétés utilisent `''` au lieu de `$null`
- **Fichiers** : `src/UI/DashboardManager.psm1:99-162`, `src/UI/MigrationWizard.UI.psm1:692-716`, `src/UI/MigrationWizard.xaml:297-298`

#### Dashboard UX
- **AMELIORATION** : Colonnes DataGrid redimensionnables en temps réel
- **AMELIORATION** : Ajout `CanUserResizeColumns="True"`, `ColumnHeaderHeight="32"`
- **AMELIORATION** : Désactivation virtualisation (`EnableColumnVirtualization="False"`)
- **AMELIORATION** : Largeurs colonnes ajustées : Client (150px), PC Source (180px), Date Export/Import (150px)
- **Fichier** : `src/UI/MigrationWizard.xaml:277-301`

### Fichiers Modifiés
- src/UI/DashboardManager.psm1
- src/UI/MigrationWizard.UI.psm1
- src/UI/MigrationWizard.xaml

---

## Version 1.0.23.4 (2025-12-22)

### Correctifs
- **FIX** : Tentative `.ToString('format')` → `"{0:format}" -f $dt`
- **PROBLEME** : Toujours échec (format operator incompatible PS2EXE)
- **Fichier** : `src/UI/DashboardManager.psm1:99-139`

### Fichiers Modifiés
- src/UI/DashboardManager.psm1
- src/UI/MigrationWizard.xaml

### Note
Version abandonnée rapidement (erreur persiste).

---

## Version 1.0.23.3 (2025-12-22)

### Correctifs
- **FIX** : DataGrid binding avec ArrayList
- **FIX** : Tentative utilisation ObservableCollection (échec)
- **FIX** : Suppression StringFormat XAML sur colonnes dates
- **Fichiers** : `src/UI/MigrationWizard.UI.psm1:692-716`, `src/UI/MigrationWizard.xaml:297-298`

### Fichiers Modifiés
- src/UI/MigrationWizard.UI.psm1
- src/UI/MigrationWizard.xaml

### Note
Version intermédiaire, erreur ToString() découverte.

---

## Version 1.0.23.2 (2025-12-22)

### Correctifs
- **FIX** : Force array avec `@(Get-MWExportsList)`
- **FIX** : Utilisation ObservableCollection pour WPF DataGrid
- **Fichier** : `src/UI/MigrationWizard.UI.psm1:692-716`

### Fichiers Modifiés
- src/UI/MigrationWizard.UI.psm1

### Note
Version intermédiaire, ObservableCollection incompatible PS2EXE.

---

## Version 1.0.23.1 (2025-12-22)

### Correctifs
- **FIX** : Tentative DataGrid binding avec ArrayList simple
- **Fichier** : `src/UI/MigrationWizard.UI.psm1:692-716`

### Fichiers Modifiés
- src/UI/MigrationWizard.UI.psm1

### Note
Première tentative correction Dashboard, insuffisante.

---

## Version 1.0.23.0 (2025-12-22) - MAJEURE

### Nouvelles Fonctionnalités

#### Import JSON Tracking
- **NOUVEAU** : Création `ImportMetadata.json` à la fin de chaque import
- **Contenu** : Date import, utilisateur, PC cible, domaine
- **Objectif** : Tracker quels exports ont été importés et quand
- **Fichier** : `src/Core/Profile.psm1:406-419`

#### Dashboard Import Tracking
- **NOUVEAU** : Lecture `ImportMetadata.json` dans Dashboard
- **NOUVEAU** : Colonne "Date Import" dans DataGrid exports
- **NOUVEAU** : Affichage utilisateur + PC cible dans tooltip (TODO)
- **Fichiers** : `src/UI/DashboardManager.psm1:68-162`, `src/UI/MigrationWizard.xaml:298`

### Correctifs Critiques

#### Raccourcis Options Supplémentaires Supprimés
- **FIX** : Inversion ordre import (Desktop AVANT UserData)
- **Raison** : `Clear-AllDesktops` supprimait fichiers copiés par `Import-MWUserData`
- **Solution** : Purge bureau AVANT copie Options Supplémentaires
- **Fichiers** : `src/Core/Profile.psm1:267-277`, `src/Core/Profile.psm1:376-384` (suppression ancien appel)

### Fichiers Modifiés
- src/Core/Profile.psm1
- src/UI/DashboardManager.psm1
- src/UI/MigrationWizard.xaml

### Fichiers Créés
- ImportMetadata.json (généré lors imports)

---

## Version 1.0.22.0 (2025-12-18) - MAJEURE

### Correctifs Critiques

#### DesktopOK Export Manquant
- **FIX** : `Get-EmbeddedDesktopOK` - Suppression vérification `$PSScriptRoot` (vide en mode compilé)
- **FIX** : Utilisation uniquement extraction base64 depuis `$script:DESKTOPOK_BASE64`
- **FIX** : Ajout validation variable existe + non-vide avant extraction
- **Fichier** : `src/Features/WallpaperDesktop.psm1:323-372`

#### Raccourcis Logicia Path Vide
- **FIX** : `Get-EmbeddedFile` - Suppression vérification `$PSScriptRoot`
- **FIX** : Construction nom variable base64 : `LOGICIA_[FILENAME]_BASE64`
- **FIX** : Extraction vers `%TEMP%\MigrationWizard\`
- **Fichier** : `src/Features/WallpaperDesktop.psm1:374-420`

### Fichiers Modifiés
- src/Features/WallpaperDesktop.psm1

### Note
Version critique corrigeant 2 bugs majeurs causés par `$PSScriptRoot` vide en PS2EXE.

---

## Version 1.0.21.0 (2025-12-16) - MAJEURE

### Nouvelles Fonctionnalités

#### Export Incrémental avec Détection
- **NOUVEAU** : Page 1b (page11) pour détecter exports clients existants
- **NOUVEAU** : Choix utilisateur : "Nouvel export complet" OU "Export incrémental"
- **NOUVEAU** : ComboBox sélection export de référence pour mode incrémental
- **NOUVEAU** : Mode miroir Robocopy (`/MIR`) pour copie différentielle
- **Fichiers** : `src/UI/UINavigation.psm1:Handle-NextClick`, `src/UI/MigrationWizard.xaml` (page11), `src/Core/Profile.psm1` (paramètre IncrementalMode)

#### TreeView C:\ Racine
- **NOUVEAU** : Ajout C:\ complet dans "Options supplémentaires"
- **NOUVEAU** : Arborescence navigable lazy load pour tout le disque C:\
- **ATTENTION** : Décoché par défaut (peut copier des GB de données)
- **Fichier** : `src/UI/TreeBuilder.psm1:Build-FolderTreeView`

### Fichiers Modifiés
- src/UI/UINavigation.psm1
- src/UI/TreeBuilder.psm1
- src/UI/MigrationWizard.xaml
- src/Core/Profile.psm1
- src/Core/FileCopy.psm1

### Fichiers Créés
- Page 11 (1b) XAML dans MigrationWizard.xaml

---

## Version 1.0.20.0 (2025-12-14)

### Nouvelles Fonctionnalités

#### TreeView Options Supplémentaires
- **NOUVEAU** : Arborescence AppData\Local avec sous-dossiers navigables
- **NOUVEAU** : Arborescence AppData\Roaming avec sous-dossiers navigables
- **NOUVEAU** : Lazy loading pour performance (expansion à la demande)
- **NOUVEAU** : Propagation état checkbox parent↔enfants
- **Fichier** : `src/UI/TreeBuilder.psm1`

### Améliorations
- **AMELIORATION** : Performance copie fichiers (Robocopy optimisé)
- **AMELIORATION** : Logs plus détaillés pour TreeView sélections

### Fichiers Modifiés
- src/UI/TreeBuilder.psm1
- src/Features/UserData.psm1

---

## Version 1.0.10.0 (2025-12-10)

### Nouvelles Fonctionnalités

#### Firefox Support Complet
- **NOUVEAU** : Export Firefox Local (`AppData\Local\Mozilla\Firefox`)
- **NOUVEAU** : Export Firefox Roaming (`AppData\Roaming\Mozilla\Firefox`)
- **NOUVEAU** : Détection automatique profils Firefox (`*.default-release`)
- **Fichier** : `src/Features/Browsers.psm1:Export-FirefoxData`

#### Thunderbird Support
- **NOUVEAU** : Export Thunderbird (`AppData\Roaming\Thunderbird`)
- **NOUVEAU** : Export profils emails complets
- **Fichier** : `src/Features/Browsers.psm1:Export-ThunderbirdData`

### Fichiers Modifiés
- src/Features/Browsers.psm1

---

## Version 1.0.5.0 (2025-12-05)

### Nouvelles Fonctionnalités

#### Dashboard Initial
- **NOUVEAU** : Page 0 Dashboard avec statistiques
- **NOUVEAU** : DataGrid liste exports détectés
- **NOUVEAU** : Bouton Supprimer pour chaque export
- **NOUVEAU** : Scan automatique exports dans dossier exe
- **Fichiers** : `src/UI/DashboardManager.psm1`, `src/UI/MigrationWizard.UI.psm1:Initialize-Dashboard`

#### ClientSelector
- **NOUVEAU** : ComboBox sélection client existant
- **NOUVEAU** : TextBox saisie nouveau client
- **NOUVEAU** : Validation noms (regex alphanumérique + tirets)
- **Fichier** : `src/UI/ClientSelector.psm1`

### Fichiers Créés
- src/UI/DashboardManager.psm1
- src/UI/ClientSelector.psm1

---

## Version 1.0.0.0 (2025-11-30) - INITIALE

### Fonctionnalités Principales

#### Orchestration
- **NOUVEAU** : `Export-MWProfile` - Orchestrateur export complet
- **NOUVEAU** : `Import-MWProfile` - Orchestrateur import complet
- **Fichier** : `src/Core/Profile.psm1`

#### UserData
- **NOUVEAU** : Export/Import dossiers utilisateur (Documents, Bureau, Images, etc.)
- **NOUVEAU** : Support dossiers Public
- **NOUVEAU** : Robocopy pour performance
- **Fichier** : `src/Features/UserData.psm1`

#### Wi-Fi
- **NOUVEAU** : Export profils Wi-Fi avec clés (netsh)
- **NOUVEAU** : Import profils Wi-Fi
- **Fichier** : `src/Features/Wifi.psm1`

#### Imprimantes
- **NOUVEAU** : Export/Import imprimantes réseau et locales
- **Fichier** : `src/Features/Printers.psm1`

#### Lecteurs Réseau
- **NOUVEAU** : Export/Import lecteurs réseau mappés
- **Fichier** : `src/Features/NetworkDrives.psm1`

#### RDP
- **NOUVEAU** : Export/Import connexions Bureau à distance
- **Fichier** : `src/Features/RDP.psm1`

#### Navigateurs
- **NOUVEAU** : Chrome - Export favoris, mots de passe, cookies, historique
- **NOUVEAU** : Edge - Export favoris, paramètres
- **Fichier** : `src/Features/Browsers.psm1`

#### Outlook
- **NOUVEAU** : Export fichiers PST
- **NOUVEAU** : Export signatures
- **Fichier** : `src/Features/Outlook.psm1`

#### Bureau
- **NOUVEAU** : Export/Import fond d'écran
- **NOUVEAU** : Export/Import positions icônes (DesktopOK)
- **NOUVEAU** : Backup complet Desktop User + Public
- **Fichier** : `src/Features/WallpaperDesktop.psm1`

#### Barre des Tâches
- **NOUVEAU** : Export/Import épinglages barre des tâches
- **NOUVEAU** : Export/Import épinglages menu Démarrer
- **Fichier** : `src/Features/TaskbarStart.psm1`

#### Accès Rapide
- **NOUVEAU** : Export/Import dossiers favoris Explorateur
- **Fichier** : `src/Features/QuickAccess.psm1`

#### Interface WPF
- **NOUVEAU** : Interface graphique complète (XAML)
- **NOUVEAU** : Navigation multi-pages
- **NOUVEAU** : Barre progression avec Nyan Cat
- **NOUVEAU** : TreeView sélection dossiers
- **Fichiers** : `src/UI/MigrationWizard.UI.psm1`, `src/UI/MigrationWizard.xaml`, `src/UI/UINavigation.psm1`, `src/UI/TreeBuilder.psm1`

#### Utilitaires
- **NOUVEAU** : Système logs (fichier + console + UI)
- **NOUVEAU** : Copie robuste Robocopy avec fallback
- **NOUVEAU** : Bootstrap initialisation
- **Fichiers** : `src/Modules/MW.Logging.psm1`, `src/Core/FileCopy.psm1`, `src/Core/Bootstrap.psm1`

#### Build System
- **NOUVEAU** : Script compilation PS2EXE
- **NOUVEAU** : Embarquement binaires (DesktopOK, RZGet)
- **NOUVEAU** : Embarquement images (Nyan Cat)
- **NOUVEAU** : Fusion 30 modules PowerShell
- **Fichier** : `Tools/Build-PortableExe.ps1`

### Fichiers Créés (Total: 30 modules)
- src/Core/Profile.psm1
- src/Core/Export.psm1
- src/Features/UserData.psm1
- src/Features/Wifi.psm1
- src/Features/Printers.psm1
- src/Features/NetworkDrives.psm1
- src/Features/RDP.psm1
- src/Features/Browsers.psm1
- src/Features/BrowserDetection.psm1
- src/Features/Outlook.psm1
- src/Features/WallpaperDesktop.psm1
- src/Features/TaskbarStart.psm1
- src/Features/QuickAccess.psm1
- src/UI/MigrationWizard.UI.psm1
- src/UI/MigrationWizard.xaml
- src/UI/UINavigation.psm1
- src/UI/UIValidation.psm1
- src/UI/TreeBuilder.psm1
- src/UI/SummaryBuilder.psm1
- src/UI/SnakeGame.psm1
- src/Modules/MW.Logging.psm1
- src/Core/FileCopy.psm1
- src/Core/Bootstrap.psm1
- src/Assets/MW.Logo.Base64.ps1
- src/Assets/MW.NyanCat.Base64.ps1
- src/Core/DataFolders.psm1
- src/Core/OneDrive.psm1
- src/Core/Applications.psm1
- src/UI/ManifestManager.psm1
- Tools/Build-PortableExe.ps1

---

## STATISTIQUES GLOBALES

**Versions totales** : 13
**Versions majeures** : 4 (1.0.0.0, 1.0.21.0, 1.0.22.0, 1.0.23.0)
**Versions patches** : 9

**Modules PowerShell** : 30
**Lignes de code (estimation)** : ~15 000
**Taille compilée** : 4.05 MB
**Binaires embarqués** : 3 (DesktopOK, RZGet, Logicia shortcuts)

**Bugs critiques corrigés** : 7
**Fonctionnalités ajoutées** : 25+
**Navigateurs supportés** : 3 (Chrome, Firefox, Edge)
**Dossiers utilisateur** : 8 (Documents, Desktop, Pictures, etc.)

---

**FIN DU DOCUMENT 04-CHANGELOG-DETAILLE.md**
