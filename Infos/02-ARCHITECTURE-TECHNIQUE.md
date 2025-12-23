# MigrationWizard - Architecture Technique Détaillée

## 1. ARCHITECTURE GLOBALE

### 1.1 Pattern Architectural

MigrationWizard suit une **architecture modulaire en couches** :

```
┌─────────────────────────────────────────────────────┐
│              PRESENTATION LAYER (UI)                 │
│  ┌─────────────────────────────────────────────┐   │
│  │   XAML (MigrationWizard.xaml)               │   │
│  │   - Pages WPF                               │   │
│  │   - DataGrid, TreeView, Buttons, etc.       │   │
│  └─────────────────────────────────────────────┘   │
│                       ▲                             │
│                       │ Data Binding                │
│  ┌─────────────────────────────────────────────┐   │
│  │   UI LOGIC (MigrationWizard.UI.psm1)        │   │
│  │   - Event Handlers                          │   │
│  │   - Navigation (UINavigation.psm1)          │   │
│  │   - Validation (UIValidation.psm1)          │   │
│  │   - TreeBuilder, DashboardManager           │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                       ▲
                       │ Function Calls
┌─────────────────────────────────────────────────────┐
│            BUSINESS LOGIC LAYER (Core)              │
│  ┌─────────────────────────────────────────────┐   │
│  │   ORCHESTRATION (Profile.psm1)              │   │
│  │   - Export-MWProfile()                      │   │
│  │   - Import-MWProfile()                      │   │
│  └─────────────────────────────────────────────┘   │
│                       ▲                             │
│                       │ Delegates to                │
│  ┌─────────────────────────────────────────────┐   │
│  │   FEATURE MODULES (Features/)               │   │
│  │   - UserData.psm1                           │   │
│  │   - Wifi.psm1, Printers.psm1, etc.          │   │
│  │   - WallpaperDesktop.psm1                   │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                       ▲
                       │ Uses
┌─────────────────────────────────────────────────────┐
│           MODULE LAYER (Modules/)                    │
│  ┌─────────────────────────────────────────────┐   │
│  │   MW.Logging.psm1 (Logs, a cote de l exe)                    │   │
│  │   FileCopy.psm1 (Robocopy wrapper)          │   │
│  │   Bootstrap.psm1 (Init)                     │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                       ▲
                       │ Reads/Writes
┌─────────────────────────────────────────────────────┐
│              DATA LAYER (Filesystem)                │
│  - ExportManifest.json                              │
│  - ImportMetadata.json                              │
│  - .metadata.json                                   │
│  - Fichiers utilisateur (Documents, Desktop, etc.)  │
│  - Configurations système (XML, JSON, Registry)     │
└─────────────────────────────────────────────────────┘
```

### 1.2 Flux de Données Export

```
User clicks "Export"
    │
    ├─> UI: Collect selections (folders, features)
    │       │
    │       ├─> TreeView → $selectedFolders array
    │       ├─> Checkboxes → $features hashtable
    │       └─> TextBoxes → $clientName, $pcName
    │
    ├─> UI: Validate inputs
    │       └─> UIValidation.psm1
    │
    ├─> UI: Show progress page
    │       └─> Nyan Cat animation + ProgressBar
    │
    ├─> Core: Export-MWProfile() called
    │       │
    │       ├─> Create destination folder structure
    │       │   └─> D:\ClientName\PCName\
    │       │
    │       ├─> Export user data
    │       │   └─> Export-MWUserData()
    │       │       ├─> For each selected folder:
    │       │       │   └─> Copy-MWUserDirectory (Robocopy)
    │       │       └─> Profile\ directory created
    │       │
    │       ├─> Export features (parallel où possible)
    │       │   ├─> if $features.Wifi → Export-MWWifiProfiles()
    │       │   ├─> if $features.Printers → Export-MWPrinters()
    │       │   ├─> if $features.NetworkDrives → Export-MWNetworkDrives()
    │       │   ├─> if $features.Rdp → Export-MWRdpConnections()
    │       │   ├─> if $features.Browsers → Export-MWBrowsers()
    │       │   ├─> if $features.Outlook → Export-MWOutlookData()
    │       │   ├─> if $features.WallpaperDesktop → Export-WallpaperDesktop()
    │       │   ├─> if $features.TaskbarStart → Export-TaskbarStart()
    │       │   └─> if $features.QuickAccess → Export-MWQuickAccess()
    │       │
    │       ├─> Generate ExportManifest.json
    │       │   └─> Save-MWExportManifest()
    │       │
    │       └─> Return success/failure
    │
    └─> UI: Show completion message
            └─> Return to Dashboard
```

### 1.3 Flux de Données Import

```
User selects export + clicks "Import"
    │
    ├─> UI: Load export metadata
    │       └─> Read ExportManifest.json
    │
    ├─> UI: Show confirmation page
    │       └─> Display: Source PC → Target PC
    │
    ├─> User confirms → Import starts
    │
    ├─> Core: Import-MWProfile() called
    │       │
    │       ├─> CRITICAL ORDER (fixed v1.0.23.0):
    │       │
    │       ├─> 1. Import-WallpaperDesktop() FIRST
    │       │      ├─> Clear-AllDesktops (purge)
    │       │      ├─> Restore-DesktopContent (from export)
    │       │      ├─> Import-DesktopPositions (DesktopOK)
    │       │      └─> Add-LogiciaShortcuts
    │       │
    │       ├─> 2. Import-MWUserData() SECOND
    │       │      ├─> Copy Profile folders
    │       │      ├─> Copy Public folders
    │       │      └─> Copy Additional Options folders
    │       │
    │       ├─> 3. Import features
    │       │      ├─> Import-MWWifiProfiles()
    │       │      ├─> Import-MWPrinters()
    │       │      ├─> Import-MWNetworkDrives()
    │       │      ├─> Import-MWBrowsers()
    │       │      ├─> Import-MWOutlookData()
    │       │      ├─> Import-TaskbarStart()
    │       │      └─> Import-MWQuickAccess()
    │       │
    │       ├─> 4. Repair-MWShortcuts()
    │       │      └─> Fix .lnk paths (old username → new)
    │       │
    │       ├─> 5. Create ImportMetadata.json
    │       │      └─> Track import date, user, PC
    │       │
    │       └─> Return success/failure
    │
    └─> UI: Show completion + return Dashboard
```

---

## 2. MODULES CORE DETAILLES

### 2.1 Profile.psm1 (Orchestrateur)

**Rôle** : Chef d'orchestre des exports/imports

**Fonctions principales** :

#### Export-MWProfile

```powershell
function Export-MWProfile {
    param(
        [string]$DestinationFolder,       # Ex: D:\ClientName\PCName
        [bool]$IncludeUserData = $true,
        [string[]]$SelectedFolders = @(), # Dossiers sélectionnés TreeView
        [bool]$IncludeWifi = $true,
        [bool]$IncludePrinters = $true,
        # ... autres features ...
        [bool]$IncrementalMode = $false   # Mode différentiel
    )
}
```

**Processus** :
1. Créer dossier destination si inexistant
2. Générer `ProfileInfo.json` (metadata basique)
3. Si `$IncludeUserData` :
   - Appeler `Export-MWUserData` avec `$SelectedFolders` et `$IncrementalMode`
4. Pour chaque feature activée :
   - Try-Catch autour de chaque fonction
   - Logs INFO/ERROR selon succès/échec
   - Continue même si une feature échoue (non-bloquant)
5. Update UI progress bar (`Update-ProgressUI`)
6. Générer `ExportManifest.json` complet
7. Return résultat

**Gestion erreurs** :
- Erreur bloquante : Dossier destination inaccessible → throw exception
- Erreur non-bloquante : Wi-Fi échoue → log ERROR + continue

#### Import-MWProfile

```powershell
function Import-MWProfile {
    param(
        [string]$SourceFolder,            # Dossier export source
        [bool]$IncludeUserData = $true,
        [bool]$IncludeWifi = $true,
        # ... mêmes features qu'export ...
    )
}
```

**Ordre critique (FIX v1.0.23.0)** :
```powershell
# AVANT (BUGUE) :
Import-MWUserData          # Copie Options Supplémentaires
Import-WallpaperDesktop    # Clear-AllDesktops SUPPRIME ce qui vient d'être copié

# APRES (CORRIGE) :
Import-WallpaperDesktop    # Purge + restaure bureau AVANT
Import-MWUserData          # Copie Options Supplémentaires APRES
```

**Réparation raccourcis** :
```powershell
# Lecture ExportManifest.json pour récupérer ancien username
$manifest = Get-Content (Join-Path $SourceFolder 'ExportManifest.json') | ConvertFrom-Json
$oldUserName = $manifest.ExportMetadata.UserName

if ($oldUserName -ne $env:USERNAME) {
    Repair-MWShortcuts -OldUserName $oldUserName -NewUserName $env:USERNAME
}
```

**Création ImportMetadata.json (NEW v1.0.23.0)** :
```powershell
$importMetadata = @{
    ImportDate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    ImportedBy = $env:USERNAME
    ImportedOnPC = $env:COMPUTERNAME
    ImportedOnDomain = $env:USERDOMAIN
}
$importMetadata | ConvertTo-Json | Set-Content (Join-Path $SourceFolder 'ImportMetadata.json')
```

### 2.2 Export.psm1 (Gestion Manifests)

**Fonctions** :

#### Save-MWExportManifest

Génère `ExportManifest.json` complet avec :
- Métadonnées : PC, user, date, OS
- Liste dossiers exportés
- Features activées
- Statistiques (taille, durée, nb fichiers)

```powershell
$manifest = @{
    Version = "1.0"
    ExportMetadata = @{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        OsVersion = [System.Environment]::OSVersion.VersionString
        ExportType = if ($IncrementalMode) { "Incremental" } else { "Complete" }
        ReferenceExportPath = $ReferenceExportPath  # Si incrémental
    }
    DataFolders = $selectedFoldersMetadata
    Features = $featuresEnabled
    Statistics = $stats
}
```

---

## 3. MODULES FEATURES DETAILLES

### 3.1 UserData.psm1

**Variables globales** :
```powershell
$script:MWUserDataFolders = @(
    @{ Label = 'Bureau';          Relative = 'Desktop';   SpecialFolder = 'Desktop' }
    @{ Label = 'Documents';       Relative = 'Documents'; SpecialFolder = 'MyDocuments' }
    @{ Label = 'Images';          Relative = 'Pictures';  SpecialFolder = 'MyPictures' }
    @{ Label = 'Vidéos';          Relative = 'Videos';    SpecialFolder = 'MyVideos' }
    @{ Label = 'Musique';         Relative = 'Music';     SpecialFolder = 'MyMusic' }
    @{ Label = 'Téléchargements'; Relative = 'Downloads'; SpecialFolder = $null }
    @{ Label = 'Favoris';         Relative = 'Favorites'; SpecialFolder = 'Favorites' }
    @{ Label = 'Liens';           Relative = 'Links';     SpecialFolder = $null }
)
```

#### Export-MWUserData

```powershell
function Export-MWUserData {
    param(
        [string]$DestinationFolder,
        [string[]]$SelectedFolders = @(),
        [bool]$IncrementalMode = $false
    )

    $profileRoot = Get-MWUserProfileRoot  # C:\Users\USERNAME
    $profileDestRoot = Join-Path $DestinationFolder 'Profile'

    foreach ($folder in $script:MWUserDataFolders) {
        # Skip si pas sélectionné
        if ($SelectedFolders -notcontains $folder.Relative) { continue }

        $source = Join-Path $profileRoot $folder.Relative
        $dest = Join-Path $profileDestRoot $folder.Relative

        if (Test-Path $source) {
            if ($IncrementalMode) {
                # Robocopy avec /MIR (miroir différentiel)
                Copy-MWUserDirectory -Source $source -Destination $dest -Mirror
            } else {
                # Copie complète
                Copy-MWUserDirectory -Source $source -Destination $dest
            }
        }
    }

    # Export dossiers Public si sélectionnés
    # Export AppData si sélectionné
    # Export Options Supplémentaires (C:\...) si sélectionnées
}
```

#### Import-MWUserData

```powershell
function Import-MWUserData {
    param([string]$SourceFolder)

    $profileRoot = Get-MWUserProfileRoot
    $profileSrcRoot = Join-Path $SourceFolder 'Profile'

    foreach ($folder in $script:MWUserDataFolders) {
        # SKIP Desktop car géré par WallpaperDesktop
        if ($folder.Relative -eq 'Desktop') { continue }

        $src = Join-Path $profileSrcRoot $folder.Relative
        $dest = Join-Path $profileRoot $folder.Relative

        if (Test-Path $src) {
            Copy-MWUserDirectory -Source $src -Destination $dest
        }
    }

    # Import dossiers Public
    # Import AppData
    # Import Options Supplémentaires
}
```

#### Repair-MWShortcuts

**Objectif** : Réparer les raccourcis (.lnk) qui pointent vers l'ancien chemin utilisateur

```powershell
function Repair-MWShortcuts {
    param(
        [string]$OldUserName,
        [string]$NewUserName
    )

    # Trouver tous les .lnk dans le profil
    $shortcuts = Get-ChildItem -Path $env:USERPROFILE -Filter *.lnk -Recurse

    foreach ($shortcut in $shortcuts) {
        $shell = New-Object -ComObject WScript.Shell
        $link = $shell.CreateShortcut($shortcut.FullName)

        # Remplacer C:\Users\OldUser par C:\Users\NewUser
        if ($link.TargetPath -like "*$OldUserName*") {
            $link.TargetPath = $link.TargetPath -replace $OldUserName, $NewUserName
            $link.Save()
            Write-MWLogInfo "Raccourci réparé : $($shortcut.Name)"
        }
    }
}
```

### 3.2 WallpaperDesktop.psm1

**Composants critiques** :

#### Export-WallpaperDesktop

```powershell
function Export-WallpaperDesktop {
    param([string]$OutRoot)

    # 1. Exporter fond d'écran (registry)
    Export-CurrentWallpaper -OutRoot $OutRoot

    # 2. Sauvegarder positions icônes avec DesktopOK
    $desktopOKPath = Get-EmbeddedDesktopOK
    if ($desktopOKPath) {
        $dokFile = Join-Path $OutRoot 'desktop_positions.dok'
        & $desktopOKPath /SaveDesktop $dokFile
    }

    # 3. Backup complet bureaux (User + Public)
    $desktopUserSrc = Get-UserDesktopPath
    $desktopUserDest = Join-Path $OutRoot 'Desktop-User'
    Copy-FolderContent -Source $desktopUserSrc -Destination $desktopUserDest

    $publicDesktopSrc = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $publicDesktopDest = Join-Path $OutRoot 'Desktop-Public'
    Copy-FolderContent -Source $publicDesktopSrc -Destination $publicDesktopDest
}
```

#### Import-WallpaperDesktop / Import-DesktopComplete

```powershell
function Import-DesktopComplete {
    param([string]$InRoot)

    # 1. PURGE TOTALE des bureaux (User + Public)
    Clear-AllDesktops

    # 2. RESTAURATION depuis backup export
    Restore-DesktopContent -InRoot $InRoot

    # 3. RESTAURATION positions avec DesktopOK
    Import-DesktopPositions -InRoot $InRoot

    # 4. AJOUT raccourcis Logicia
    Add-LogiciaShortcuts
}

function Clear-AllDesktops {
    # Supprime TOUT de Desktop User
    $userDesktop = Get-UserDesktopPath
    Clear-FolderContent -Path $userDesktop

    # Supprime TOUT de Desktop Public
    $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
    Clear-FolderContent -Path $publicDesktop
}

function Restore-DesktopContent {
    param([string]$InRoot)

    # Copier Desktop-User → Desktop User
    $sourceUser = Join-Path $InRoot 'Desktop-User'
    $destUser = Get-UserDesktopPath
    Copy-FolderContent -Source $sourceUser -Destination $destUser

    # Copier Desktop-Public → Desktop Public
    $sourcePublic = Join-Path $InRoot 'Desktop-Public'
    $destPublic = [Environment]::GetFolderPath('CommonDesktopDirectory')
    Copy-FolderContent -Source $sourcePublic -Destination $destPublic
}

function Import-DesktopPositions {
    param([string]$InRoot)

    $dokFile = Join-Path $InRoot 'desktop_positions.dok'
    if (Test-Path $dokFile) {
        $desktopOKPath = Get-EmbeddedDesktopOK
        if ($desktopOKPath) {
            & $desktopOKPath /RestoreDesktop $dokFile
            Write-MWLogInfo "Positions icônes restaurées avec DesktopOK"
        }
    }
}
```

#### Get-EmbeddedDesktopOK (FIX v1.0.22.0)

**Problème** : `$PSScriptRoot` est vide en mode compilé PS2EXE

```powershell
# AVANT (BUGUE)
function Get-EmbeddedDesktopOK {
    if ($PSScriptRoot) {
        $toolsPath = Join-Path $PSScriptRoot '..\Tools\DesktopOK.exe'
        if (Test-Path $toolsPath) {
            return $toolsPath
        }
    }
    # Extraction base64...
}

# APRES (CORRIGE v1.0.22.0)
function Get-EmbeddedDesktopOK {
    # Supprimé vérification $PSScriptRoot complètement

    # Vérifier variable base64 existe
    if (Get-Variable -Name 'DESKTOPOK_BASE64' -Scope Script -ErrorAction SilentlyContinue) {
        $base64Data = Get-Variable -Name 'DESKTOPOK_BASE64' -Scope Script -ValueOnly

        if ($base64Data -and -not [string]::IsNullOrWhiteSpace($base64Data)) {
            # Extraire vers %TEMP%
            $tempDir = Join-Path $env:TEMP 'MigrationWizard'
            if (-not (Test-Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
            }

            $exePath = Join-Path $tempDir 'DesktopOK.exe'

            if (-not (Test-Path $exePath)) {
                Write-MWLogDebug "Extraction DesktopOK.exe depuis base64..."
                $bytes = [Convert]::FromBase64String($base64Data)
                [System.IO.File]::WriteAllBytes($exePath, $bytes)
            }

            return $exePath
        }
    }

    Write-MWLogWarning "DesktopOK.exe non embarqué"
    return $null
}
```

#### Get-EmbeddedFile (FIX v1.0.22.0)

Même correction pour raccourcis Logicia

```powershell
function Get-EmbeddedFile {
    param([string]$FileName)

    # Nom variable : LOGICIA_ESPACE_CLIENT_LOGICIA_EXE_BASE64
    $varName = "LOGICIA_" + ($FileName -replace '[^a-zA-Z0-9]', '_').ToUpper() + "_BASE64"

    if (Get-Variable -Name $varName -Scope Script -ErrorAction SilentlyContinue) {
        $base64 = Get-Variable -Name $varName -Scope Script -ValueOnly

        if ($base64 -and -not [string]::IsNullOrWhiteSpace($base64)) {
            $tempDir = Join-Path $env:TEMP 'MigrationWizard'
            $filePath = Join-Path $tempDir $FileName

            if (-not (Test-Path $filePath)) {
                $bytes = [Convert]::FromBase64String($base64)
                [System.IO.File]::WriteAllBytes($filePath, $bytes)
            }

            return $filePath
        }
    }

    Write-MWLogWarning "Fichier '$FileName' non embarqué"
    return $null
}
```

### 3.3 Wifi.psm1

#### Export-MWWifiProfiles

```powershell
function Export-MWWifiProfiles {
    param([string]$DestinationFolder)

    $wifiDir = Join-Path $DestinationFolder 'Wifi'
    New-Item -ItemType Directory -Path $wifiDir -Force | Out-Null

    # Lister profils Wi-Fi
    $profiles = netsh wlan show profiles | Select-String "Profil Tous les utilisateurs"

    foreach ($profile in $profiles) {
        $ssid = ($profile -split ':')[1].Trim()

        # Exporter avec clé en clair (REQUIS ADMIN)
        $xmlFile = Join-Path $wifiDir "$ssid.xml"
        netsh wlan export profile name="$ssid" key=clear folder="$wifiDir"

        Write-MWLogInfo "Profil Wi-Fi exporté : $ssid"
    }
}
```

#### Import-MWWifiProfiles

```powershell
function Import-MWWifiProfiles {
    param([string]$SourceFolder)

    $wifiDir = Join-Path $SourceFolder 'Wifi'
    if (-not (Test-Path $wifiDir)) { return }

    $xmlFiles = Get-ChildItem -Path $wifiDir -Filter *.xml

    foreach ($xmlFile in $xmlFiles) {
        # Importer profil
        netsh wlan add profile filename="$($xmlFile.FullName)"

        Write-MWLogInfo "Profil Wi-Fi importé : $($xmlFile.BaseName)"
    }
}
```

### 3.4 Browsers.psm1

**Navigateurs supportés** : Chrome, Firefox, Edge

#### Export-MWBrowsers

```powershell
function Export-MWBrowsers {
    param(
        [string]$DestinationFolder,
        [string[]]$BrowsersToExport = @('Chrome', 'Firefox', 'Edge')
    )

    $browsersDir = Join-Path $DestinationFolder 'Browsers'

    foreach ($browser in $BrowsersToExport) {
        switch ($browser) {
            'Chrome' {
                Export-ChromeData -DestinationFolder (Join-Path $browsersDir 'Chrome')
            }
            'Firefox' {
                Export-FirefoxData -DestinationFolder (Join-Path $browsersDir 'Firefox')
            }
            'Edge' {
                Export-EdgeData -DestinationFolder (Join-Path $browsersDir 'Edge')
            }
        }
    }
}
```

#### Export-ChromeData

```powershell
function Export-ChromeData {
    param([string]$DestinationFolder)

    $chromePath = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'
    if (-not (Test-Path $chromePath)) { return }

    # Copier profil Default
    $defaultProfile = Join-Path $chromePath 'Default'
    $destProfile = Join-Path $DestinationFolder 'Default'

    # Fichiers importants
    $filesToCopy = @(
        'Bookmarks',               # Favoris
        'Preferences',             # Préférences
        'Login Data',              # Mots de passe (chiffré)
        'Cookies',                 # Cookies
        'History',                 # Historique
        'Favicons',                # Icônes favoris
        'Extensions\*'             # Extensions
    )

    foreach ($file in $filesToCopy) {
        $source = Join-Path $defaultProfile $file
        $dest = Join-Path $destProfile $file

        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $dest -Recurse -Force
        }
    }
}
```

#### Export-FirefoxData

```powershell
function Export-FirefoxData {
    param([string]$DestinationFolder)

    $firefoxPath = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
    if (-not (Test-Path $firefoxPath)) { return }

    # Firefox utilise profils avec noms aléatoires (xxxxxxxx.default-release)
    $profiles = Get-ChildItem -Path $firefoxPath -Directory

    foreach ($profile in $profiles) {
        # Copier profil COMPLET (plus simple que sélection fichiers)
        $dest = Join-Path $DestinationFolder $profile.Name
        Copy-Item -Path $profile.FullName -Destination $dest -Recurse -Force

        Write-MWLogInfo "Profil Firefox copié : $($profile.Name)"
    }
}
```

---

## 4. MODULES UI DETAILLES

### 4.1 MigrationWizard.UI.psm1

**Rôle** : Initialisation UI + Event Handlers

#### Initialize-MigrationWizardUI

```powershell
function Initialize-MigrationWizardUI {
    # 1. Charger XAML
    $xaml = Get-EmbeddedXAML  # Base64 → String
    $reader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
    $script:Window = [Windows.Markup.XamlReader]::Load($reader)

    # 2. Récupérer tous les contrôles nommés
    $script:UI = @{}
    $xaml -split "`n" | ForEach-Object {
        if ($_ -match 'Name="(.+?)"') {
            $name = $matches[1]
            $script:UI[$name] = $script:Window.FindName($name)
        }
    }

    # 3. Initialiser handlers
    Initialize-EventHandlers

    # 4. Initialiser données
    Initialize-UIData

    # 5. Initialiser Dashboard
    Initialize-Dashboard

    # 6. Afficher page 0 (Dashboard)
    Show-UIPage -PageNumber 0 -Window $script:Window

    # 7. Afficher fenêtre
    $script:Window.ShowDialog()
}
```

#### Initialize-EventHandlers

**Handlers principaux** :

```powershell
# Boutons Next/Previous
$btnNext.Add_Click({
    Handle-NextClick
})

$btnPrevious.Add_Click({
    Handle-PreviousClick
})

# Radio buttons Export/Import
$rbExport.Add_Checked({
    $script:IsExport = $true
    $script:IncrementalMode = $false
    $script:ExistingExportPath = $null
    Reset-ImportVisibility -UIControls $script:UI
})

$rbImport.Add_Checked({
    $script:IsExport = $false
    Reset-ExportVisibility -UIControls $script:UI
})

# TreeView folders
$treeViewFolders.Add_Checked({
    param($sender, $e)
    # Propagation parent→enfants
})

# Dashboard
$btnDashRefresh.Add_Click({
    & $refreshDashboard
})

$btnDashStart.Add_Click({
    Show-UIPage -PageNumber 1 -Window $script:Window
})
```

### 4.2 UINavigation.psm1

#### Show-UIPage

```powershell
function Show-UIPage {
    param(
        [int]$PageNumber,
        [System.Windows.Window]$Window
    )

    # Cacher toutes les pages
    foreach ($page in $script:AllPages) {
        $page.Visibility = 'Collapsed'
    }

    # Afficher page demandée
    $currentPage = $Window.FindName("page$PageNumber")
    $currentPage.Visibility = 'Visible'

    # Gérer visibilité boutons Next/Previous
    Update-NavigationButtons -PageNumber $PageNumber

    # Appeler événement OnPageShown si défini
    if ($script:PageEvents["OnPageShown$PageNumber"]) {
        & $script:PageEvents["OnPageShown$PageNumber"]
    }

    $script:CurrentPage = $PageNumber
}
```

#### Handle-NextClick

**Validation par page** :

```powershell
function Handle-NextClick {
    $currentPage = $script:CurrentPage

    switch ($currentPage) {
        0 {  # Dashboard
            Show-UIPage -PageNumber 1 -Window $script:Window
        }
        1 {  # Choix Export/Import
            if ($script:IsExport) {
                # Vérifier si export client existant
                $clientName = $txtClientName.Text
                $existingExports = Get-ExistingExports -ClientName $clientName

                if ($existingExports.Count -gt 0) {
                    # Afficher page 11 (détection)
                    Populate-ExistingExportsComboBox -Exports $existingExports
                    Show-UIPage -PageNumber 11 -Window $script:Window
                } else {
                    # Pas d'export existant → page 2 directement
                    Show-UIPage -PageNumber 2 -Window $script:Window
                }
            } else {
                # Import → page 21
                Show-UIPage -PageNumber 21 -Window $script:Window
            }
        }
        11 {  # Page 1b (export existant détecté)
            if ($rbNewComplete.IsChecked) {
                # Nouvel export complet
                $script:IncrementalMode = $false
                $script:ExistingExportPath = $null
            } else {
                # Export incrémental
                $script:IncrementalMode = $true
                $script:ExistingExportPath = $cmbExistingExports.SelectedItem.Path

                # Valider sélection
                if (-not $script:ExistingExportPath) {
                    [System.Windows.MessageBox]::Show("Veuillez sélectionner un export de référence")
                    return
                }

                # Valider dossier existe encore
                if (-not (Test-Path $script:ExistingExportPath)) {
                    [System.Windows.MessageBox]::Show("Export sélectionné introuvable")
                    return
                }
            }

            Show-UIPage -PageNumber 2 -Window $script:Window
        }
        2 {  # Sélection dossiers
            # Extraire dossiers cochés
            $script:SelectedFolders = Get-TreeViewCheckedPaths -TreeView $treeViewFolders

            if ($script:SelectedFolders.Count -eq 0) {
                [System.Windows.MessageBox]::Show("Veuillez sélectionner au moins un dossier")
                return
            }

            Show-UIPage -PageNumber 20 -Window $script:Window
        }
        20 {  # Sélection features
            # Rien à valider (features optionnelles)

            # Lancer export
            Show-UIPage -PageNumber 3 -Window $script:Window
            Start-ExportProcess
        }
        21 {  # Sélection export source (import)
            if ($cmbImportSource.SelectedIndex -eq -1) {
                [System.Windows.MessageBox]::Show("Veuillez sélectionner un export")
                return
            }

            $script:ImportSourcePath = $cmbImportSource.SelectedItem.Path
            Show-UIPage -PageNumber 22 -Window $script:Window
        }
        22 {  # Confirmation import
            Show-UIPage -PageNumber 3 -Window $script:Window
            Start-ImportProcess
        }
    }
}
```

### 4.3 TreeBuilder.psm1

#### Build-FolderTreeView

**Construction arborescence** :

```powershell
function Build-FolderTreeView {
    param(
        [System.Windows.Controls.TreeView]$TreeView,
        [switch]$ExportMode
    )

    $TreeView.Items.Clear()

    # 1. Dossiers utilisateur standard (cochés par défaut)
    foreach ($folder in $script:MWUserDataFolders) {
        $path = Get-UserFolderPath -FolderName $folder.Relative
        $node = New-TreeNode -Path $path -Label $folder.Label -IsChecked $true
        $TreeView.Items.Add($node)
    }

    # 2. Bureau Public (coché par défaut)
    $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
    $nodePubDesk = New-TreeNode -Path $publicDesktop -Label 'Public\Desktop' -IsChecked $true
    $TreeView.Items.Add($nodePubDesk)

    # 3. AppData\Local (décoché, lazy load sous-dossiers)
    $localAppData = Join-Path $env:USERPROFILE 'AppData\Local'
    $nodeLocal = New-TreeNode -Path $localAppData -Label 'AppData\Local' -IsChecked $false
    $nodeLocal.Items.Add($null)  # Dummy pour afficher ">"
    $nodeLocal.Add_Expanded({
        param($sender, $e)
        Expand-TreeNode -Node $sender
    })
    $TreeView.Items.Add($nodeLocal)

    # 4. AppData\Roaming (idem)
    $roamingAppData = Join-Path $env:USERPROFILE 'AppData\Roaming'
    $nodeRoaming = New-TreeNode -Path $roamingAppData -Label 'AppData\Roaming' -IsChecked $false
    $nodeRoaming.Items.Add($null)
    $nodeRoaming.Add_Expanded({
        param($sender, $e)
        Expand-TreeNode -Node $sender
    })
    $TreeView.Items.Add($nodeRoaming)

    # 5. C:\ complet (décoché, lazy load)
    $nodeC = New-TreeNode -Path 'C:\' -Label 'C:\ (Racine - Attention!)' -IsChecked $false
    $nodeC.Items.Add($null)
    $nodeC.Add_Expanded({
        param($sender, $e)
        Expand-TreeNode -Node $sender
    })
    $TreeView.Items.Add($nodeC)
}
```

#### New-TreeNode

```powershell
function New-TreeNode {
    param(
        [string]$Path,
        [string]$Label,
        [bool]$IsChecked = $false
    )

    $node = New-Object System.Windows.Controls.TreeViewItem
    $node.Header = $Label
    $node.Tag = $Path  # Stocke chemin complet
    $node.IsChecked = $IsChecked

    # Style checkbox
    $checkBox = New-Object System.Windows.Controls.CheckBox
    $checkBox.Content = $Label
    $checkBox.IsChecked = $IsChecked
    $checkBox.Add_Checked({
        param($sender, $e)
        # Cocher tous les enfants
        Set-ChildrenChecked -Node $node -IsChecked $true
    })
    $checkBox.Add_Unchecked({
        param($sender, $e)
        # Décocher tous les enfants
        Set-ChildrenChecked -Node $node -IsChecked $false
    })

    $node.Header = $checkBox
    return $node
}
```

#### Expand-TreeNode (Lazy Loading)

```powershell
function Expand-TreeNode {
    param($Node)

    # Si déjà chargé, return
    if ($Node.Items.Count -gt 0 -and $Node.Items[0] -ne $null) {
        return
    }

    # Vider dummy
    $Node.Items.Clear()

    $path = $Node.Tag
    if (-not (Test-Path $path)) { return }

    # Lister sous-dossiers
    $subFolders = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue

    foreach ($subFolder in $subFolders) {
        # Skip dossiers système cachés
        if ($subFolder.Attributes -match 'Hidden|System') { continue }

        $childNode = New-TreeNode -Path $subFolder.FullName -Label $subFolder.Name -IsChecked $Node.IsChecked

        # Vérifier si a des sous-dossiers
        $hasSubFolders = (Get-ChildItem -Path $subFolder.FullName -Directory -ErrorAction SilentlyContinue).Count -gt 0
        if ($hasSubFolders) {
            $childNode.Items.Add($null)  # Dummy
            $childNode.Add_Expanded({
                param($sender, $e)
                Expand-TreeNode -Node $sender
            })
        }

        $Node.Items.Add($childNode)
    }
}
```

### 4.4 DashboardManager.psm1

#### Get-MWExportsList (FIX v1.0.23.5)

**Scan exports depuis exe folder** :

```powershell
function Get-MWExportsList {
    $exports = @()

    $exeFolder = Split-Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Parent
    Write-MWLogInfo "Scan exports dans: $exeFolder"

    # Structure: ExeFolder\ClientName\PCName\ExportManifest.json
    $clientFolders = Get-ChildItem -Path $exeFolder -Directory -ErrorAction SilentlyContinue

    foreach ($clientFolder in $clientFolders) {
        # Skip dossiers système
        if ($clientFolder.Name -match '^(Tools|Build|Logs|src|\.git)') { continue }

        $pcFolders = Get-ChildItem -Path $clientFolder.FullName -Directory

        foreach ($pcFolder in $pcFolders) {
            $manifestPath = Join-Path $pcFolder.FullName 'ExportManifest.json'
            if (-not (Test-Path $manifestPath)) { continue }

            # Lire .metadata.json (optionnel)
            $metadataPath = Join-Path $pcFolder.FullName '.metadata.json'
            $metadata = $null
            if (Test-Path $metadataPath) {
                $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
            }

            # Lire ImportMetadata.json (optionnel, NEW v1.0.23.0)
            $importMetadataPath = Join-Path $pcFolder.FullName 'ImportMetadata.json'
            $importMetadata = $null
            if (Test-Path $importMetadataPath) {
                $importMetadata = Get-Content $importMetadataPath -Raw | ConvertFrom-Json
            }

            # Lire ExportManifest.json pour PC source
            $sourcePC = 'Inconnu'
            if (-not $metadata -or -not $metadata.SourcePC) {
                $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                if ($manifest.ComputerName) {
                    $sourcePC = $manifest.ComputerName
                }
            }

            # Calculer taille
            $size = (Get-ChildItem -Path $pcFolder.FullName -Recurse -File |
                     Measure-Object -Property Length -Sum).Sum

            # Formater dates en strings (FIX v1.0.23.5)
            $exportDateStr = if ($metadata -and $metadata.ExportDate) {
                try {
                    $dt = [DateTime]$metadata.ExportDate
                    Get-Date $dt -Format 'dd/MM/yyyy HH:mm'
                } catch {
                    Get-Date $pcFolder.CreationTime -Format 'dd/MM/yyyy HH:mm'
                }
            } else {
                Get-Date $pcFolder.CreationTime -Format 'dd/MM/yyyy HH:mm'
            }

            $importDateStr = if ($importMetadata -and $importMetadata.ImportDate) {
                try {
                    $dt = [DateTime]$importMetadata.ImportDate
                    Get-Date $dt -Format 'dd/MM/yyyy HH:mm'
                } catch {
                    ''
                }
            } else {
                ''
            }

            # Créer objet export
            $export = [PSCustomObject]@{
                ClientName = $clientFolder.Name
                PCName = $pcFolder.Name
                Path = $pcFolder.FullName
                Drive = $exeFolder.Substring(0, 2)
                ExportDate = $exportDateStr
                ImportDate = $importDateStr
                ImportedBy = if ($importMetadata) { $importMetadata.ImportedBy } else { '' }
                ImportedOnPC = if ($importMetadata) { $importMetadata.ImportedOnPC } else { '' }
                SourcePC = if ($metadata) { $metadata.SourcePC } else { $sourcePC }
                Version = if ($metadata) { $metadata.Version } else { 'N/A' }
                SizeBytes = $size
                SizeMB = [Math]::Round($size / 1MB, 2)
                SizeGB = [Math]::Round($size / 1GB, 2)
                HasMetadata = (Test-Path $metadataPath)
                HasImportMetadata = (Test-Path $importMetadataPath)
            }

            $exports += $export
        }
    }

    Write-MWLogInfo "Trouvé $($exports.Count) export(s) MigrationWizard"
    return $exports
}
```

#### Initialize-Dashboard (FIX v1.0.23.5)

```powershell
function Initialize-Dashboard {
    $refreshDashboard = {
        Write-MWLogInfo "Rafraîchissement du Dashboard..."

        # Force array (évite PowerShell unroll)
        $exports = @(Get-MWExportsList)

        if ($exports.Count -eq 0) {
            # Aucun export
            $dgDashExports.Visibility = 'Collapsed'
            $txtDashNoExports.Visibility = 'Visible'
            # Stats à zéro
        } else {
            # Créer ArrayList pour WPF DataGrid (FIX v1.0.23.1)
            $arrayList = New-Object System.Collections.ArrayList
            foreach ($export in $exports) {
                [void]$arrayList.Add($export)
            }
            $dgDashExports.ItemsSource = $arrayList
            $dgDashExports.Visibility = 'Visible'
            $txtDashNoExports.Visibility = 'Collapsed'

            # Calculer stats
            $stats = Get-MWDashboardStats -Exports $exports
            $txtDashTotalExports.Text = $stats.TotalExports
            $txtDashTotalSize.Text = "{0:N2} GB" -f $stats.TotalSizeGB
            $txtDashLastExport.Text = $stats.LastExportClient
            $txtDashLastExportDate.Text = $stats.LastExportDate
            $txtDashLastImport.Text = $stats.LastImportClient
            $txtDashLastImportDate.Text = $stats.LastImportDate
        }

        Write-MWLogInfo "Dashboard rafraîchi: $($exports.Count) export(s) trouvé(s)"
    }

    # Bouton Actualiser
    $btnDashRefresh.Add_Click($refreshDashboard)

    # Bouton Supprimer (handler sur chaque ligne)
    $dgDashExports.Add_LoadingRow({
        # Trouver bouton Supprimer dans ligne
        # Ajouter event handler pour suppression
    })

    # Rafraîchir au démarrage
    & $refreshDashboard
}
```

---

## 5. UTILS DETAILLES

### 5.1 MW.Logging.psm1

**Variables** :
```powershell
$script:LogFilePath = $null  # Défini dynamiquement
$script:LogLevel = 'INFO'
```

**Fonctions** :

```powershell
function Initialize-MWLogging {
    param([string]$LogDirectory = 'Logs')

    if (-not (Test-Path $LogDirectory)) {
        New-Item -ItemType Directory -Path $LogDirectory -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd'
    $hostname = $env:COMPUTERNAME
    $logFileName = "MigrationWizard_${timestamp}_${hostname}.log"
    $script:LogFilePath = Join-Path $LogDirectory $logFileName

    Write-MWLogInfo "=== Démarrage MigrationWizard ==="
}

function Write-MWLogDebug {
    param([string]$Message)
    Write-MWLog -Level 'DEBUG' -Message $Message
}

function Write-MWLogInfo {
    param([string]$Message)
    Write-MWLog -Level 'INFO' -Message $Message
}

function Write-MWLogWarning {
    param([string]$Message)
    Write-MWLog -Level 'WARN' -Message $Message
}

function Write-MWLogError {
    param([string]$Message)
    Write-MWLog -Level 'ERROR' -Message $Message
}

function Write-MWLog {
    param(
        [string]$Level,
        [string]$Message
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp [$Level] $Message"

    # Écrire fichier
    if ($script:LogFilePath) {
        Add-Content -Path $script:LogFilePath -Value $logEntry
    }

    # Écrire console (si non compilé)
    if ($PSCommandPath) {
        Write-Host $logEntry -ForegroundColor (Get-LogColor -Level $Level)
    }

    # Écrire UI TextBox (si disponible)
    if ($script:UI -and $script:UI.txtProgress) {
        $script:UI.txtProgress.Dispatcher.Invoke([Action]{
            $script:UI.txtProgress.AppendText("$logEntry`n")
            $script:UI.txtProgress.ScrollToEnd()
        })
    }
}
```

### 5.2 FileCopy.psm1

#### Copy-MWUserDirectory

```powershell
function Copy-MWUserDirectory {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Mirror,         # Mode miroir (/MIR pour incrémental)
        [string]$FolderName = '' # Pour logs
    )

    if (-not (Test-Path $Source)) {
        Write-MWLogWarning "Source inexistante : $Source"
        return
    }

    # Créer destination
    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    Write-MWLogInfo "Copie : $Source → $Destination"

    # Utiliser Robocopy pour performance
    $robocopyArgs = @(
        $Source,
        $Destination,
        '/E',         # Sous-répertoires y compris vides
        '/R:3',       # 3 tentatives en cas d'échec
        '/W:5',       # 5 secondes entre tentatives
        '/NP',        # Pas de pourcentage progression
        '/NDL',       # Pas de liste répertoires
        '/NFL'        # Pas de liste fichiers (trop verbeux)
    )

    if ($Mirror) {
        $robocopyArgs += '/MIR'  # Mode miroir (supprime fichiers destination absents source)
    }

    # Exclusions
    $robocopyArgs += '/XF'  # Exclure fichiers
    $robocopyArgs += 'thumbs.db', 'desktop.ini', '*.tmp', '*.temp'
    $robocopyArgs += '/XD'  # Exclure dossiers
    $robocopyArgs += '$RECYCLE.BIN', 'System Volume Information'

    # Exécuter Robocopy
    $result = & robocopy @robocopyArgs 2>&1

    # Robocopy exit codes : 0-7 = success, 8+ = error
    if ($LASTEXITCODE -ge 8) {
        Write-MWLogError "Robocopy échoué (code $LASTEXITCODE) : $Source"
        Write-MWLogError "Détails : $result"

        # Fallback : Copy-Item
        Write-MWLogWarning "Tentative Copy-Item..."
        try {
            Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force -ErrorAction Stop
            Write-MWLogInfo "Copy-Item réussi (fallback)"
        } catch {
            Write-MWLogError "Copy-Item échoué aussi : $($_.Exception.Message)"
            throw
        }
    } else {
        Write-MWLogInfo "Robocopy réussi (code $LASTEXITCODE)"
    }
}
```

---

**FIN DU DOCUMENT 02-ARCHITECTURE-TECHNIQUE.md**

*Suite à créer :*
- 03-REFERENCE-API.md (toutes les fonctions documentées)
- 04-FORMAT-DONNEES.md (JSON schemas, XML, Registry)
- 05-GUIDE-DEVELOPPEUR.md (comment contribuer)
- 06-TROUBLESHOOTING.md (problèmes connus + solutions)
