# MigrationWizard - Documentation Technique Complète

**Architecture Moteur, Chassie et Composants Internes**

Version : 1.0.23.10
Date : 2025-12-23
Auteur : Jean-Mickael Thomas (Logicia)

---

## TABLE DES MATIERES

1. [Architecture Globale](#1-architecture-globale)
2. [Le Moteur (Core Engine)](#2-le-moteur-core-engine)
3. [Le Châssie (Framework & Infrastructure)](#3-le-châssie-framework--infrastructure)
4. [Les Modules Fonctionnels (Features)](#4-les-modules-fonctionnels-features)
5. [Système de Build et Compilation](#5-système-de-build-et-compilation)
6. [Contraintes PS2EXE et Solutions](#6-contraintes-ps2exe-et-solutions)
7. [Système de Logging](#7-système-de-logging)
8. [Formats de Données et Manifests](#8-formats-de-données-et-manifests)
9. [Gestion des Erreurs et Robustesse](#9-gestion-des-erreurs-et-robustesse)
10. [Optimisations et Performance](#10-optimisations-et-performance)

---

## 1. ARCHITECTURE GLOBALE

### 1.1 Vue d'Ensemble

MigrationWizard suit une **architecture modulaire en couches** :

```
┌─────────────────────────────────────────────────────┐
│         COUCHE PRESENTATION (UI Layer)              │
│  ┌─────────────────────────────────────────────┐   │
│  │   XAML Interface (MigrationWizard.xaml)     │   │
│  │   - Pages WPF (Dashboard, Export, Import)   │   │
│  │   - DataGrid, TreeView, Buttons             │   │
│  │   - Data Binding & Templates                │   │
│  └─────────────────────────────────────────────┘   │
│                       ▲                             │
│                       │ Event Binding               │
│  ┌─────────────────────────────────────────────┐   │
│  │   UI Controllers (UI/)                      │   │
│  │   - MigrationWizard.UI.psm1 (handlers)      │   │
│  │   - UINavigation.psm1 (page switching)      │   │
│  │   - UIValidation.psm1 (input checks)        │   │
│  │   - TreeBuilder.psm1 (folder tree)          │   │
│  │   - DashboardManager.psm1 (stats)           │   │
│  │   - ManifestManager.psm1 (JSON load)        │   │
│  │   - ClientSelector.psm1 (client list)       │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                       ▲
                       │ Function Calls
┌─────────────────────────────────────────────────────┐
│      COUCHE BUSINESS LOGIC (Core Engine)            │
│  ┌─────────────────────────────────────────────┐   │
│  │   ORCHESTRATEUR PRINCIPAL                   │   │
│  │   Profile.psm1                              │   │
│  │   - Export-MWProfile()                      │   │
│  │   - Import-MWProfile()                      │   │
│  │   - Get-MWProfileInfo()                     │   │
│  └─────────────────────────────────────────────┘   │
│                       ▲                             │
│                       │ Delegates to                │
│  ┌─────────────────────────────────────────────┐   │
│  │   MODULES DE FEATURES (Features/)           │   │
│  │   - UserData.psm1 (dossiers utilisateur)    │   │
│  │   - Wifi.psm1 (profils Wi-Fi)               │   │
│  │   - Printers.psm1 (imprimantes)             │   │
│  │   - NetworkDrives.psm1 (lecteurs réseau)    │   │
│  │   - Browsers.psm1 (Chrome/Firefox/Edge)     │   │
│  │   - Outlook.psm1 (PST, signatures)          │   │
│  │   - WallpaperDesktop.psm1 (bureau)          │   │
│  │   - TaskbarStart.psm1 (épinglages)          │   │
│  │   - QuickAccess.psm1 (favoris Explorer)     │   │
│  │   - RDP.psm1 (connexions RDP)               │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │   CORE SERVICES (Core/)                     │   │
│  │   - Export.psm1 (export logic)              │   │
│  │   - FileCopy.psm1 (Robocopy wrapper)        │   │
│  │   - DataFolders.psm1 (folder manifest)      │   │
│  │   - OneDrive.psm1 (KFM path resolution)     │   │
│  │   - Applications.psm1 (app detection)       │   │
│  │   - Bootstrap.psm1 (init globals)           │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                       ▲
                       │ Uses
┌─────────────────────────────────────────────────────┐
│        COUCHE INFRASTRUCTURE (Modules/)             │
│  ┌─────────────────────────────────────────────┐   │
│  │   MW.Logging.psm1 (système de logs)         │   │
│  │   - Write-MWLog(), Write-MWLogSuccess()     │   │
│  │   - Write-MWLogWarning(), Write-MWLogError()│   │
│  │   - Write-MWLogDebug()                      │   │
│  │   - Initialize-MWLogging()                  │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │   BrowserDetection.psm1                     │   │
│  │   - Get-ChromeProfiles()                    │   │
│  │   - Get-FirefoxProfiles()                   │   │
│  │   - Get-EdgeProfiles()                      │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │   SummaryBuilder.psm1                       │   │
│  │   - Build-MWSummary() (résumé export/import)│   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │   SnakeGame.psm1 (Easter Egg)               │   │
│  │   - Start-MWSnakeGame()                     │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
                       ▲
                       │ Persists to
┌─────────────────────────────────────────────────────┐
│           COUCHE DONNEES (Data Layer)               │
│  - Filesystem (C:\Users\...\MigrationWizard\)       │
│  - ExportManifest.json (metadata export)            │
│  - ImportMetadata.json (metadata import)            │
│  - snapshot.json (legacy compatibility)             │
│  - .metadata.json (file/folder metadata)            │
│  - Logs (.log files)                                │
│  - Binary assets (base64 embedded in EXE)           │
└─────────────────────────────────────────────────────┘
```

### 1.2 Principes de Design

1. **Séparation des responsabilités** : UI, Business Logic, Data séparés
2. **Modularité** : Chaque feature est un module indépendant
3. **Réutilisabilité** : Services communs (Logging, FileCopy) partagés
4. **Robustesse** : Gestion d'erreurs à chaque couche avec retry logic
5. **Traçabilité** : Logs exhaustifs de toutes les opérations
6. **Portabilité** : Tout embarqué dans un seul EXE

---

## 2. LE MOTEUR (Core Engine)

### 2.1 Profile.psm1 - L'Orchestrateur Principal

**Rôle** : Point d'entrée central pour toutes les opérations d'export/import.

#### Fonction : Export-MWProfile()

**Signature** :
```powershell
function Export-MWProfile {
    param(
        [hashtable]$Selection,
        [string]$ClientName,
        [string]$PCName,
        [bool]$IsIncremental = $false
    )
}
```

**Pipeline d'exécution** :

```
1. INITIALIZATION
   ├─> Validate inputs (ClientName, PCName, Selection)
   ├─> Create export directory structure
   │   └─> D:\[ClientName]\[PCName]\
   ├─> Initialize logging
   │   └─> MigrationWizard_YYYYMMDD_[HOSTNAME].log
   └─> Log export start (date, user, machine)

2. USER DATA EXPORT
   ├─> Export-MWUserData($Selection)
   │   ├─> Foreach selected folder (Desktop, Documents, etc.)
   │   │   └─> Copy-MWUserDirectory (Robocopy wrapper)
   │   │       ├─> If $IsIncremental → /XO (exclude older)
   │   │       ├─> Else → full copy
   │   │       └─> Retry logic (3 attempts)
   │   ├─> Copy Public folders (if selected)
   │   └─> Copy AppData subfolders (if selected)

3. FEATURES EXPORT (parallel where possible)
   ├─> If $Selection.Wifi → Export-MWWifiProfiles()
   │   └─> netsh wlan export profile folder=[dest]
   ├─> If $Selection.Printers → Export-MWPrinters()
   │   └─> Get-Printer → Export to JSON
   ├─> If $Selection.NetworkDrives → Export-MWNetworkDrives()
   │   └─> Get-PSDrive -PSProvider FileSystem → Export to JSON
   ├─> If $Selection.Rdp → Export-MWRdpConnections()
   │   └─> Registry HKCU:\Software\Microsoft\Terminal Server Client
   ├─> If $Selection.Browsers → Export-MWBrowsers()
   │   ├─> Chrome: Bookmarks, Login Data, Cookies, Preferences
   │   ├─> Firefox: places.sqlite, logins.json, prefs.js
   │   └─> Edge: Bookmarks, Preferences
   ├─> If $Selection.Outlook → Export-MWOutlookData()
   │   ├─> Detect PST files (HKCU registry)
   │   ├─> Copy PST files
   │   ├─> Copy signatures
   │   └─> Export account settings (registry)
   ├─> If $Selection.WallpaperDesktop → Export-WallpaperDesktop()
   │   ├─> Save wallpaper path (registry)
   │   ├─> Copy wallpaper file
   │   ├─> Export DesktopOK positions
   │   └─> Copy desktop content
   ├─> If $Selection.TaskbarStart → Export-TaskbarStart()
   │   └─> Registry: Taskbar pinned items
   └─> If $Selection.QuickAccess → Export-MWQuickAccess()
       └─> Quick Access folders list

4. MANIFEST GENERATION
   ├─> Build ExportManifest.json
   │   ├─> ExportMetadata: Date, User, PCName, ClientName
   │   ├─> Selection: All selected features
   │   ├─> Stats: Total size, file count
   │   └─> Version: MigrationWizard version
   └─> Save-MWExportManifest()

5. FINALIZATION
   ├─> Log export completion
   ├─> Calculate total size/duration
   └─> Return success/failure status
```

**Gestion d'erreurs** :
- Try/Catch à chaque étape
- Rollback partiel si erreur critique
- Logs détaillés des échecs
- Continue si une feature échoue (non-blocking)

#### Fonction : Import-MWProfile()

**Signature** :
```powershell
function Import-MWProfile {
    param(
        [string]$ExportPath,
        [hashtable]$Selection
    )
}
```

**Pipeline d'exécution** :

```
1. INITIALIZATION
   ├─> Validate export directory exists
   ├─> Load ExportManifest.json or snapshot.json
   ├─> Detect source username from export
   │   └─> Parse paths in manifest
   ├─> Initialize logging
   └─> Log import start

2. CRITICAL ORDER IMPORTS (v1.0.23.0+ fix)

   ├─> [STEP 1] Import-WallpaperDesktop() - MUST BE FIRST
   │   ├─> Clear-AllDesktops
   │   │   └─> Delete all files on Desktop and Public\Desktop
   │   ├─> Restore-DesktopContent
   │   │   └─> Copy files from export Desktop\ to current Desktop
   │   ├─> Import-DesktopPositions
   │   │   └─> Execute DesktopOK.exe with saved layout
   │   └─> Add-LogiciaShortcuts
   │       ├─> Extract Espace Client - Logicia.exe (base64)
   │       └─> Extract Telemaintenance Logicia.exe (base64)
   │
   ├─> [STEP 2] Import-MWUserData() - MUST BE SECOND
   │   ├─> Copy Profile\ folders (Documents, Pictures, etc.)
   │   │   └─> Robocopy with /E /R:3 /W:5 /MT:8
   │   ├─> Copy Public\ folders
   │   └─> Copy Additional Options folders
   │       └─> IMPORTANT: These may include shortcuts to Desktop
   │           which would be deleted if Step 1 ran after!
   │
   ├─> [STEP 3] Import features (order doesn't matter)
       ├─> Import-MWWifiProfiles()
       │   └─> netsh wlan add profile filename=[xml]
       ├─> Import-MWPrinters()
       │   └─> Add-Printer -ConnectionName [UNC]
       ├─> Import-MWNetworkDrives()
       │   └─> New-PSDrive -Name X: -PSProvider FileSystem -Root [UNC]
       ├─> Import-MWBrowsers()
       │   ├─> Chrome: Copy profile to %LocalAppData%\Google\Chrome
       │   ├─> Firefox: Copy profile to %AppData%\Mozilla\Firefox
       │   └─> Edge: Copy profile to %LocalAppData%\Microsoft\Edge
       ├─> Import-MWOutlookData()
       │   ├─> Copy PST files to original location
       │   ├─> Restore signatures
       │   └─> Import account settings (registry)
       ├─> Import-TaskbarStart()
       │   └─> Restore pinned items (registry)
       └─> Import-MWQuickAccess()
           └─> Restore Quick Access folders

3. POST-IMPORT FIXES
   ├─> Repair-MWShortcuts()
   │   ├─> Find all .lnk files in imported folders
   │   ├─> Parse Target and WorkingDirectory
   │   ├─> Replace old username with new username
   │   │   Example: C:\Users\OldUser\... → C:\Users\NewUser\...
   │   └─> Update .lnk files
   └─> Create ImportMetadata.json
       ├─> ImportDate
       ├─> SourcePC
       ├─> SourceUser
       ├─> TargetPC
       └─> TargetUser

4. FINALIZATION
   ├─> Log import completion
   ├─> Display summary
   └─> Return success/failure status
```

**Pourquoi cet ordre ?** (Bug critique fixé en v1.0.23.0)

**Problème original** :
- Si `Import-MWUserData` s'exécute **avant** `Import-WallpaperDesktop`
- Alors les fichiers copiés dans "Options Supplémentaires" vers `Public\Desktop`
- Sont **supprimés** par `Clear-AllDesktops` dans `Import-WallpaperDesktop`

**Solution** :
1. `Import-WallpaperDesktop` d'abord → Purge et restaure le bureau
2. `Import-MWUserData` ensuite → Copie les fichiers supplémentaires sans risque

### 2.2 Export.psm1 - Logique d'Export

**Fonctions clés** :

```powershell
function Export-MWUserData {
    # Export dossiers utilisateur (Documents, Desktop, etc.)
    # Gère mode standard vs incrémental
}

function Copy-MWUserDirectory {
    # Wrapper Robocopy avec retry logic
    # Paramètres: Source, Destination, IsIncremental
}

function Save-MWExportManifest {
    # Génère ExportManifest.json avec métadonnées
    # Compatible avec snapshot.json (legacy)
}
```

**Manifest Structure** (ExportManifest.json) :

```json
{
  "ExportMetadata": {
    "Date": "2025-12-23 15:30:00",
    "ComputerName": "PC-JOHN",
    "UserName": "john.doe",
    "ClientName": "Logicia",
    "IsIncremental": false,
    "Version": "1.0.23.10"
  },
  "Selection": {
    "UserDataFolders": ["Desktop", "Documents", "Pictures"],
    "PublicFolders": ["Desktop"],
    "AppDataFolders": ["Firefox", "Thunderbird"],
    "AdditionalOptions": ["C:\\CustomData"],
    "Features": {
      "Wifi": true,
      "Printers": true,
      "NetworkDrives": true,
      "Browsers": true,
      "Outlook": true,
      "WallpaperDesktop": true,
      "TaskbarStart": true,
      "QuickAccess": true,
      "Rdp": false
    }
  },
  "Stats": {
    "TotalSize": 15728640000,
    "FileCount": 45892,
    "Duration": "00:25:30"
  }
}
```

---

## 3. LE CHÂSSIE (Framework & Infrastructure)

### 3.1 Bootstrap.psm1 - Initialisation

**Rôle** : Initialiser l'environnement global de l'application au démarrage.

```powershell
function Initialize-MWEnvironment {
    # 1. Définir variables globales
    $script:MW_VERSION = "1.0.23.10"
    $script:MW_BASE_PATH = "$env:USERPROFILE\MigrationWizard"
    $script:MW_EXPORTS_PATH = "$script:MW_BASE_PATH\Exports"
    $script:MW_LOGS_PATH = "$script:MW_BASE_PATH\Logs"
    $script:MW_TEMP_PATH = "$env:TEMP\MigrationWizard"

    # 2. Créer structure de dossiers
    @($script:MW_BASE_PATH, $script:MW_EXPORTS_PATH,
      $script:MW_LOGS_PATH, $script:MW_TEMP_PATH) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
        }
    }

    # 3. Initialiser logging
    Initialize-MWLogging

    # 4. Extraire binaires embarqués (DesktopOK, etc.)
    if ($script:DESKTOPOK_BASE64) {
        Extract-EmbeddedBinary -Base64 $script:DESKTOPOK_BASE64 `
                               -OutputPath "$script:MW_TEMP_PATH\DesktopOK.exe"
    }

    # 5. Charger clients.json (liste des clients Logicia)
    $clientsFile = "$script:MW_BASE_PATH\clients.json"
    if (Test-Path $clientsFile) {
        $script:MW_CLIENTS = Get-Content $clientsFile | ConvertFrom-Json
    }

    Write-MWLog "Environment initialized (v$script:MW_VERSION)"
}
```

### 3.2 FileCopy.psm1 - Wrapper Robocopy

**Rôle** : Abstraction de Robocopy avec retry logic et logging intégré.

```powershell
function Copy-MWDirectory {
    param(
        [string]$Source,
        [string]$Destination,
        [bool]$IsIncremental = $false,
        [int]$MaxRetries = 3
    )

    $robocopyArgs = @(
        $Source,
        $Destination,
        '/E',              # Copy subdirectories (including empty)
        '/COPYALL',        # Copy all file info (timestamps, attributes, security)
        '/R:3',            # Retry 3 times on failed copies
        '/W:5',            # Wait 5 seconds between retries
        '/MT:8',           # Multi-threaded (8 threads)
        '/NP',             # No progress (% indicator)
        '/NDL',            # No directory list
        '/NFL',            # No file list (reduce log size)
        '/LOG+:' + $script:MW_CURRENT_LOG_FILE
    )

    if ($IsIncremental) {
        $robocopyArgs += '/XO'  # Exclude older files (incremental mode)
    }

    $attempt = 0
    do {
        $attempt++
        Write-MWLog "Robocopy attempt $attempt/$MaxRetries : $Source → $Destination"

        $process = Start-Process -FilePath 'robocopy.exe' `
                                 -ArgumentList $robocopyArgs `
                                 -NoNewWindow -Wait -PassThru

        # Robocopy exit codes: 0-7 = success, 8+ = error
        if ($process.ExitCode -lt 8) {
            Write-MWLogSuccess "Copy successful (exit code: $($process.ExitCode))"
            return $true
        }

        Write-MWLogWarning "Copy failed (exit code: $($process.ExitCode))"

    } while ($attempt -lt $MaxRetries)

    Write-MWLogError "Copy failed after $MaxRetries attempts"
    return $false
}
```

**Exit Codes Robocopy** :
- 0 = No files copied
- 1 = Files copied successfully
- 2 = Extra files/directories detected
- 4 = Mismatched files/directories
- 8 = Copy errors occurred
- 16 = Fatal error

### 3.3 MW.Logging.psm1 - Système de Logs

**Architecture** :

```powershell
# Variables globales
$script:MW_CURRENT_LOG_FILE = ""
$script:MW_LOG_LEVELS = @{
    INFO = "INFO"
    SUCCESS = "SUCCESS"
    WARNING = "WARNING"
    ERROR = "ERROR"
    DEBUG = "DEBUG"
}

function Initialize-MWLogging {
    $date = Get-Date -Format 'yyyyMMdd'
    $hostname = $env:COMPUTERNAME
    $script:MW_CURRENT_LOG_FILE = "$script:MW_LOGS_PATH\MigrationWizard_${date}_${hostname}.log"

    Write-MWLog "=== MigrationWizard v$script:MW_VERSION Started ==="
    Write-MWLog "User: $env:USERNAME"
    Write-MWLog "Machine: $env:COMPUTERNAME"
    Write-MWLog "OS: $((Get-CimInstance Win32_OperatingSystem).Caption)"
}

function Write-MWLog {
    param([string]$Message, [string]$Level = "INFO")

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logLine = "$timestamp [$Level] $Message"

    # Write to file
    Add-Content -Path $script:MW_CURRENT_LOG_FILE -Value $logLine -Encoding UTF8

    # Write to console (color-coded)
    switch ($Level) {
        "SUCCESS" { Write-Host $logLine -ForegroundColor Green }
        "WARNING" { Write-Host $logLine -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logLine -ForegroundColor Red }
        "DEBUG"   { Write-Host $logLine -ForegroundColor Gray }
        default   { Write-Host $logLine -ForegroundColor White }
    }
}

function Write-MWLogSuccess { param([string]$Message); Write-MWLog $Message "SUCCESS" }
function Write-MWLogWarning { param([string]$Message); Write-MWLog $Message "WARNING" }
function Write-MWLogError   { param([string]$Message); Write-MWLog $Message "ERROR" }
function Write-MWLogDebug   { param([string]$Message); Write-MWLog $Message "DEBUG" }
```

**Format des logs** :

```
2025-12-23 15:30:00 [INFO] === MigrationWizard v1.0.23.10 Started ===
2025-12-23 15:30:01 [INFO] User: john.doe
2025-12-23 15:30:01 [INFO] Machine: PC-JOHN
2025-12-23 15:30:05 [INFO] Starting export for client: Logicia
2025-12-23 15:30:10 [SUCCESS] Desktop exported successfully
2025-12-23 15:30:45 [WARNING] Outlook PST file not found: C:\Users\john.doe\Documents\Outlook\archive.pst
2025-12-23 15:31:02 [ERROR] Failed to export Firefox profile: Access denied
2025-12-23 15:35:00 [SUCCESS] Export completed in 00:04:55
```

---

## 4. LES MODULES FONCTIONNELS (Features)

### 4.1 UserData.psm1

**Export** :
```powershell
function Export-MWUserData {
    param([hashtable]$Selection)

    # 1. Export Profile folders (Desktop, Documents, etc.)
    foreach ($folder in $Selection.UserDataFolders) {
        $sourcePath = [Environment]::GetFolderPath($folder)
        $destPath = "$ExportPath\Profile\$folder"
        Copy-MWDirectory -Source $sourcePath -Destination $destPath
    }

    # 2. Export Public folders
    foreach ($folder in $Selection.PublicFolders) {
        $sourcePath = "C:\Users\Public\$folder"
        $destPath = "$ExportPath\Public\$folder"
        Copy-MWDirectory -Source $sourcePath -Destination $destPath
    }

    # 3. Export AppData subfolders
    foreach ($appFolder in $Selection.AppDataFolders) {
        $sourcePath = "$env:APPDATA\$appFolder"
        $destPath = "$ExportPath\AppData\Roaming\$appFolder"
        Copy-MWDirectory -Source $sourcePath -Destination $destPath
    }

    # 4. Export Additional Options (custom paths)
    foreach ($customPath in $Selection.AdditionalOptions) {
        # Preserve directory structure
        $relativePath = $customPath -replace '^[A-Z]:\\', ''
        $destPath = "$ExportPath\AdditionalOptions\$relativePath"
        Copy-MWDirectory -Source $customPath -Destination $destPath
    }
}
```

**Import** :
```powershell
function Import-MWUserData {
    param([string]$ExportPath, [hashtable]$Selection)

    # 1. Import Profile folders
    foreach ($folder in $Selection.UserDataFolders) {
        $sourcePath = "$ExportPath\Profile\$folder"
        $destPath = [Environment]::GetFolderPath($folder)
        Copy-MWDirectory -Source $sourcePath -Destination $destPath
    }

    # 2. Import Public folders
    foreach ($folder in $Selection.PublicFolders) {
        $sourcePath = "$ExportPath\Public\$folder"
        $destPath = "C:\Users\Public\$folder"
        Copy-MWDirectory -Source $sourcePath -Destination $destPath
    }

    # 3. Import AppData
    # ...similar pattern

    # 4. Import Additional Options
    # ...similar pattern
}
```

### 4.2 Wifi.psm1

**Export** :
```powershell
function Export-MWWifiProfiles {
    param([string]$ExportPath)

    $wifiPath = "$ExportPath\Wifi"
    New-Item -Path $wifiPath -ItemType Directory -Force | Out-Null

    # Export all Wi-Fi profiles with passwords
    netsh wlan export profile key=clear folder="$wifiPath"

    $profileCount = (Get-ChildItem -Path $wifiPath -Filter "*.xml").Count
    Write-MWLogSuccess "Exported $profileCount Wi-Fi profiles"
}
```

**Import** :
```powershell
function Import-MWWifiProfiles {
    param([string]$ExportPath)

    $wifiPath = "$ExportPath\Wifi"
    if (-not (Test-Path $wifiPath)) { return }

    $xmlFiles = Get-ChildItem -Path $wifiPath -Filter "*.xml"
    foreach ($xmlFile in $xmlFiles) {
        netsh wlan add profile filename="$($xmlFile.FullName)"
    }

    Write-MWLogSuccess "Imported $($xmlFiles.Count) Wi-Fi profiles"
}
```

### 4.3 Browsers.psm1

**Chrome Export** :
```powershell
function Export-ChromeBrowser {
    param([string]$ExportPath)

    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data"
    if (-not (Test-Path $chromePath)) { return }

    $destPath = "$ExportPath\Browsers\Chrome"

    # Export each Chrome profile
    $profiles = Get-ChromeProfiles  # From BrowserDetection.psm1
    foreach ($profile in $profiles) {
        $profilePath = "$chromePath\$($profile.Name)"
        $profileDest = "$destPath\$($profile.Name)"

        # Copy important files only (not cache)
        @('Bookmarks', 'Cookies', 'History', 'Login Data',
          'Preferences', 'Web Data', 'Extensions') | ForEach-Object {
            $sourceFile = "$profilePath\$_"
            if (Test-Path $sourceFile) {
                Copy-Item -Path $sourceFile -Destination "$profileDest\$_" -Recurse -Force
            }
        }
    }
}
```

**Firefox Export** :
```powershell
function Export-FirefoxBrowser {
    param([string]$ExportPath)

    $firefoxPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (-not (Test-Path $firefoxPath)) { return }

    $destPath = "$ExportPath\Browsers\Firefox"

    # Copy entire Firefox profile folder
    Copy-MWDirectory -Source $firefoxPath -Destination $destPath
}
```

### 4.4 Outlook.psm1

**Export** :
```powershell
function Export-MWOutlookData {
    param([string]$ExportPath)

    $outlookPath = "$ExportPath\Outlook"
    New-Item -Path $outlookPath -ItemType Directory -Force | Out-Null

    # 1. Detect PST files from registry
    $pstPaths = Get-OutlookPstPaths  # Read from HKCU\Software\Microsoft\Office\...\Outlook\Search
    foreach ($pstPath in $pstPaths) {
        if (Test-Path $pstPath) {
            $pstName = Split-Path $pstPath -Leaf
            Copy-Item -Path $pstPath -Destination "$outlookPath\$pstName" -Force
            Write-MWLogSuccess "Exported PST: $pstName"
        }
    }

    # 2. Export signatures
    $signaturesPath = "$env:APPDATA\Microsoft\Signatures"
    if (Test-Path $signaturesPath) {
        Copy-MWDirectory -Source $signaturesPath -Destination "$outlookPath\Signatures"
    }

    # 3. Export account settings (registry)
    $regPath = "HKCU:\Software\Microsoft\Office\16.0\Outlook\Profiles"
    Export-RegistryKey -Path $regPath -OutputFile "$outlookPath\OutlookSettings.reg"
}
```

**Import** :
```powershell
function Import-MWOutlookData {
    param([string]$ExportPath)

    $outlookPath = "$ExportPath\Outlook"
    if (-not (Test-Path $outlookPath)) { return }

    # 1. Import PST files
    $pstFiles = Get-ChildItem -Path $outlookPath -Filter "*.pst"
    foreach ($pst in $pstFiles) {
        # Copy to original location or Documents\Outlook\
        $destPath = "$env:USERPROFILE\Documents\Outlook\$($pst.Name)"
        Copy-Item -Path $pst.FullName -Destination $destPath -Force
    }

    # 2. Import signatures
    $signaturesSource = "$outlookPath\Signatures"
    if (Test-Path $signaturesSource) {
        $signaturesDest = "$env:APPDATA\Microsoft\Signatures"
        Copy-MWDirectory -Source $signaturesSource -Destination $signaturesDest
    }

    # 3. Import account settings
    $regFile = "$outlookPath\OutlookSettings.reg"
    if (Test-Path $regFile) {
        Start-Process -FilePath "regedit.exe" -ArgumentList "/s `"$regFile`"" -Wait
    }
}
```

### 4.5 WallpaperDesktop.psm1

**Export** :
```powershell
function Export-WallpaperDesktop {
    param([string]$ExportPath)

    $desktopPath = "$ExportPath\Desktop"
    New-Item -Path $desktopPath -ItemType Directory -Force | Out-Null

    # 1. Get wallpaper path from registry
    $wallpaperPath = (Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper).Wallpaper
    if ($wallpaperPath -and (Test-Path $wallpaperPath)) {
        $wallpaperName = Split-Path $wallpaperPath -Leaf
        Copy-Item -Path $wallpaperPath -Destination "$desktopPath\$wallpaperName" -Force

        # Save wallpaper path to metadata
        @{ WallpaperPath = $wallpaperPath } | ConvertTo-Json |
            Set-Content "$desktopPath\.wallpaper.json"
    }

    # 2. Export DesktopOK positions
    $desktopOK = "$script:MW_TEMP_PATH\DesktopOK.exe"
    if (Test-Path $desktopOK) {
        & $desktopOK /SavePositions "$desktopPath\DesktopOK.dok"
    }

    # 3. Copy desktop content
    $userDesktop = [Environment]::GetFolderPath('Desktop')
    Copy-MWDirectory -Source $userDesktop -Destination "$desktopPath\UserDesktop"

    $publicDesktop = "C:\Users\Public\Desktop"
    Copy-MWDirectory -Source $publicDesktop -Destination "$desktopPath\PublicDesktop"
}
```

**Import** :
```powershell
function Import-WallpaperDesktop {
    param([string]$ExportPath)

    $desktopPath = "$ExportPath\Desktop"
    if (-not (Test-Path $desktopPath)) { return }

    # STEP 1: Clear all desktops (CRITICAL - must run first!)
    Clear-AllDesktops

    # STEP 2: Restore desktop content
    $userDesktop = [Environment]::GetFolderPath('Desktop')
    Copy-MWDirectory -Source "$desktopPath\UserDesktop" -Destination $userDesktop

    $publicDesktop = "C:\Users\Public\Desktop"
    Copy-MWDirectory -Source "$desktopPath\PublicDesktop" -Destination $publicDesktop

    # STEP 3: Restore wallpaper
    $wallpaperMetadata = Get-Content "$desktopPath\.wallpaper.json" | ConvertFrom-Json
    $wallpaperFile = Get-ChildItem -Path $desktopPath -Filter "*.jpg","*.png","*.bmp" | Select-Object -First 1
    if ($wallpaperFile) {
        # Copy wallpaper to Pictures folder
        $newWallpaperPath = "$env:USERPROFILE\Pictures\$($wallpaperFile.Name)"
        Copy-Item -Path $wallpaperFile.FullName -Destination $newWallpaperPath -Force

        # Set as wallpaper
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name Wallpaper -Value $newWallpaperPath
        rundll32.exe user32.dll, UpdatePerUserSystemParameters
    }

    # STEP 4: Restore DesktopOK positions
    $desktopOK = "$script:MW_TEMP_PATH\DesktopOK.exe"
    $dokFile = "$desktopPath\DesktopOK.dok"
    if ((Test-Path $desktopOK) -and (Test-Path $dokFile)) {
        & $desktopOK /RestorePositions "$dokFile"
    }

    # STEP 5: Add Logicia shortcuts
    Add-LogiciaShortcuts
}

function Clear-AllDesktops {
    $userDesktop = [Environment]::GetFolderPath('Desktop')
    $publicDesktop = "C:\Users\Public\Desktop"

    # Delete all files (keep folder structure)
    Get-ChildItem -Path $userDesktop -File | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path $publicDesktop -File | Remove-Item -Force -ErrorAction SilentlyContinue

    Write-MWLog "Desktops cleared"
}

function Add-LogiciaShortcuts {
    # Extract and place Logicia shortcuts on Public Desktop
    $publicDesktop = "C:\Users\Public\Desktop"

    # Extract Espace Client (base64 embedded)
    if ($script:LOGICIA_ESPACE_CLIENT_BASE64) {
        $bytes = [Convert]::FromBase64String($script:LOGICIA_ESPACE_CLIENT_BASE64)
        [IO.File]::WriteAllBytes("$publicDesktop\Espace Client - Logicia.exe", $bytes)
    }

    # Extract Télémaintenance (base64 embedded)
    if ($script:LOGICIA_TELEMAINTENANCE_BASE64) {
        $bytes = [Convert]::FromBase64String($script:LOGICIA_TELEMAINTENANCE_BASE64)
        [IO.File]::WriteAllBytes("$publicDesktop\Telemaintenance Logicia.exe", $bytes)
    }

    Write-MWLogSuccess "Logicia shortcuts added to Public Desktop"
}
```

---

## 5. SYSTÈME DE BUILD ET COMPILATION

### 5.1 Build-PortableExe.ps1

**Processus de build complet** :

```powershell
# Tools/Build-PortableExe.ps1
param(
    [string]$Version = "1.0.14.0",
    [switch]$IncludeRZGet,
    [switch]$KeepMergedScript
)

# ÉTAPE 1: Lire tous les fichiers source
$modulesOrder = @(
    'src/Modules/MW.Logging.psm1',
    'src/Assets/MW.Logo.Base64.ps1',
    'src/Assets/MW.NyanCat.Base64.ps1',
    'src/Core/Bootstrap.psm1',
    'src/Core/FileCopy.psm1',
    'src/Core/DataFolders.psm1',
    'src/Core/OneDrive.psm1',
    'src/Core/Profile.psm1',
    'src/Core/Export.psm1',
    'src/Features/Applications.psm1',
    'src/Features/UserData.psm1',
    'src/Features/Wifi.psm1',
    'src/Features/Printers.psm1',
    'src/Features/TaskbarStart.psm1',
    'src/Features/WallpaperDesktop.psm1',
    'src/Features/QuickAccess.psm1',
    'src/Features/NetworkDrives.psm1',
    'src/Features/RDP.psm1',
    'src/Features/Browsers.psm1',
    'src/Modules/BrowserDetection.psm1',
    'src/Features/Outlook.psm1',
    'src/UI/ClientSelector.psm1',
    'src/UI/ManifestManager.psm1',
    'src/UI/TreeBuilder.psm1',
    'src/UI/DashboardManager.psm1',
    'src/UI/UINavigation.psm1',
    'src/UI/UIValidation.psm1',
    'src/Modules/SummaryBuilder.psm1',
    'src/Modules/SnakeGame.psm1',
    'src/UI/MigrationWizard.UI.psm1'
)

# ÉTAPE 2: Lire le XAML
$xamlContent = Get-Content 'src/UI/MigrationWizard.xaml' -Raw -Encoding UTF8
$mergedContent = @"
# === XAML INTERFACE EMBEDDED ===
`$script:XAML_CONTENT = @'
$xamlContent
'@
"@

# ÉTAPE 3: Embarquer binaires en base64
$nyanCatPath = 'src/Assets/nyan-cat.jpg'
$nyanCatBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($nyanCatPath))
$mergedContent += @"

# === NYAN CAT JPG EMBEDDED (BASE64) ===
`$script:NYAN_CAT_JPG_BASE64 = '$nyanCatBase64'
"@

if ($IncludeRZGet) {
    $rzgetPath = 'Tools/RZGet.exe'
    $rzgetBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($rzgetPath))
    $mergedContent += @"

# === RZGET.EXE EMBEDDED (BASE64) ===
`$script:RZGET_EXE_BASE64 = '$rzgetBase64'
"@
}

$desktopOKPath = 'Tools/DesktopOK_x64.exe'
$desktopOKBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($desktopOKPath))
$mergedContent += @"

# === DESKTOPOK.EXE EMBEDDED (BASE64) ===
`$script:DESKTOPOK_BASE64 = '$desktopOKBase64'
"@

# Raccourcis Logicia
$espaceClientPath = Get-ChildItem -Path 'Tools' -Filter 'Espace Client*.exe' | Select-Object -First 1
if ($espaceClientPath) {
    $espaceClientBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($espaceClientPath.FullName))
    $mergedContent += @"

# === ESPACE CLIENT LOGICIA EMBEDDED (BASE64) ===
`$script:LOGICIA_ESPACE_CLIENT_BASE64 = '$espaceClientBase64'
"@
}

# Télémaintenance (wildcard pour éviter problèmes encoding)
$telemaintenancePath = Get-ChildItem -Path 'Tools' -Filter '*maintenance Logicia.exe' -File
if ($telemaintenancePath) {
    $telemaintenanceBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($telemaintenancePath.FullName))
    $mergedContent += @"

# === TELEMAINTENANCE LOGICIA EMBEDDED (BASE64) ===
`$script:LOGICIA_TELEMAINTENANCE_BASE64 = '$telemaintenanceBase64'
"@
}

# ÉTAPE 4: Fusionner tous les modules
foreach ($modulePath in $modulesOrder) {
    $moduleContent = Get-Content $modulePath -Raw -Encoding UTF8

    # Supprimer Export-ModuleMember (inutile en mode fusionné)
    $moduleContent = Remove-ExportModuleMember -Content $moduleContent

    $mergedContent += @"

# ================================================================================
# MODULE: $modulePath
# ================================================================================

$moduleContent
"@
}

# ÉTAPE 5: Ajouter le code principal (point d'entrée)
$mergedContent += @'

# ================================================================================
# POINT D'ENTREE PRINCIPAL - MODE PORTABLE
# ================================================================================

# Élévation admin automatique (silencieuse)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs
    exit
}

# Initialiser environnement
Initialize-MWEnvironment

# Charger XAML et lancer UI
Start-MWMainWindow

'@

# ÉTAPE 6: Sauvegarder script fusionné
$mergedScript = "Build/MigrationWizard.Merged.ps1"
[IO.File]::WriteAllText($mergedScript, $mergedContent, [System.Text.UTF8Encoding]::new($false))

# ÉTAPE 7: Compiler avec PS2EXE
Import-Module ps2exe
$exePath = Join-Path (Split-Path -Parent $projectRoot) 'MigrationWizard-Exe\MigrationWizard.exe'

Invoke-ps2exe -inputFile $mergedScript `
              -outputFile $exePath `
              -noConsole `
              -STA `
              -title 'MigrationWizard' `
              -product 'MigrationWizard' `
              -company 'Logicia / Jean-Mickael Thomas' `
              -version $Version `
              -copyright "(c) $(Get-Date -Format 'yyyy') Logicia" `
              -description 'Outil de migration de profils Windows' `
              -iconFile 'logo-logicia2.ico'

# ÉTAPE 8: Nettoyage
if (-not $KeepMergedScript) {
    Remove-Item $mergedScript -Force
}

Write-Host "EXE créé : $exePath ($([math]::Round((Get-Item $exePath).Length / 1MB, 2)) MB)"
```

### 5.2 Fonction Remove-ExportModuleMember

**Problème** : En mode fusionné (tout dans un seul fichier), les `Export-ModuleMember` causent des erreurs car il n'y a plus de modules séparés.

**Solution** : Supprimer automatiquement toutes les lignes `Export-ModuleMember` lors du build.

```powershell
function Remove-ExportModuleMember {
    param([string]$Content)

    # Format 1: Export-ModuleMember -Function @( ... )
    $Content = [regex]::Replace($Content,
        'Export-ModuleMember\s+-Function\s+@\([^)]*\)\s*',
        '',
        [System.Text.RegularExpressions.RegexOptions]::Singleline)

    # Format 2: Export-ModuleMember -Function ` (multi-lignes avec backtick)
    $lines = $Content -split "`r?`n"
    $result = [System.Collections.ArrayList]::new()
    $inExportBlock = $false

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Début d'un bloc Export-ModuleMember avec backtick
        if ($line -match '^\s*Export-ModuleMember\s+-Function\s+`\s*$') {
            $inExportBlock = $true
            continue
        }

        # Ligne dans le bloc Export-ModuleMember
        if ($inExportBlock) {
            # Si la ligne ne termine PAS par backtick, fin du bloc
            if ($line -notmatch '`\s*$') {
                $inExportBlock = $false
            }
            continue
        }

        # Conserver la ligne
        $result.Add($line) | Out-Null
    }

    return $result -join "`n"
}
```

---

## 6. CONTRAINTES PS2EXE ET SOLUTIONS

### 6.1 $PSScriptRoot est vide

**Problème** : En mode compilé, `$PSScriptRoot` est toujours vide.

**Solution** : Utiliser des chemins absolus ou relatifs à `$env:USERPROFILE`.

```powershell
# ❌ MAUVAIS (ne fonctionne pas en EXE)
$configPath = Join-Path $PSScriptRoot 'config.json'

# ✅ BON
$configPath = "$env:USERPROFILE\MigrationWizard\config.json"
```

### 6.2 .ToString() avec format ne fonctionne pas

**Problème** : `$date.ToString("yyyy-MM-dd")` plante en mode compilé.

**Solution** : Utiliser `Get-Date -Format`.

```powershell
# ❌ MAUVAIS
$dateStr = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

# ✅ BON
$dateStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
```

### 6.3 ObservableCollection incompatible

**Problème** : WPF `ObservableCollection` cause des erreurs en PS2EXE.

**Solution** : Utiliser `ArrayList`.

```powershell
# ❌ MAUVAIS
$items = [System.Collections.ObjectModel.ObservableCollection[object]]::new()

# ✅ BON
$items = [System.Collections.ArrayList]::new()
```

### 6.4 Base64 pour binaires embarqués

**Problème** : Impossible d'embarquer des .exe directement.

**Solution** : Convertir en base64, embarquer comme string, extraire à la volée.

```powershell
# Au build
$desktopOKBytes = [IO.File]::ReadAllBytes('Tools/DesktopOK_x64.exe')
$desktopOKBase64 = [Convert]::ToBase64String($desktopOKBytes)
# Injecter $desktopOKBase64 dans le script fusionné

# Au runtime (dans l'EXE)
function Extract-DesktopOK {
    $bytes = [Convert]::FromBase64String($script:DESKTOPOK_BASE64)
    $outputPath = "$env:TEMP\MigrationWizard\DesktopOK.exe"
    [IO.File]::WriteAllBytes($outputPath, $bytes)
    return $outputPath
}
```

### 6.5 Encoding UTF-8 sans BOM

**Problème** : PS2EXE peut avoir des problèmes avec BOM (Byte Order Mark).

**Solution** : Sauvegarder le script fusionné en UTF-8 sans BOM.

```powershell
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($mergedScript, $mergedContent, $utf8NoBom)
```

---

## 7. SYSTÈME DE LOGGING

### 7.1 Architecture du Logging

**Emplacement des logs** :
```
%USERPROFILE%\MigrationWizard\Logs\
└── MigrationWizard_20251223_PC-JOHN.log
```

**Format** :
```
YYYY-MM-DD HH:MM:SS [LEVEL] Message
```

**Niveaux** :
- `INFO` : Informations générales
- `SUCCESS` : Opérations réussies
- `WARNING` : Avertissements (non-bloquants)
- `ERROR` : Erreurs (potentiellement bloquantes)
- `DEBUG` : Informations de débogage (détaillées)

### 7.2 Rotation des Logs

**Stratégie** : Un fichier par jour + hostname.

**Avantage** : Si plusieurs machines exportent vers le même dossier réseau, pas de collision.

**Nettoyage** : Aucun (l'utilisateur peut supprimer manuellement les vieux logs).

---

## 8. FORMATS DE DONNÉES ET MANIFESTS

### 8.1 ExportManifest.json

**Structure complète** :

```json
{
  "ExportMetadata": {
    "Date": "2025-12-23 15:30:00",
    "ComputerName": "PC-JOHN",
    "UserName": "john.doe",
    "ClientName": "Logicia",
    "IsIncremental": false,
    "Version": "1.0.23.10",
    "ExportDuration": "00:25:30"
  },
  "Selection": {
    "UserDataFolders": ["Desktop", "Documents", "Pictures", "Videos", "Music", "Downloads"],
    "PublicFolders": ["Desktop", "Documents"],
    "AppDataFolders": ["Mozilla\\Firefox", "Thunderbird"],
    "AdditionalOptions": ["C:\\CustomData\\MyApp"],
    "Features": {
      "Wifi": true,
      "Printers": true,
      "NetworkDrives": true,
      "Browsers": true,
      "Outlook": true,
      "WallpaperDesktop": true,
      "TaskbarStart": true,
      "QuickAccess": true,
      "Rdp": false
    }
  },
  "Stats": {
    "TotalSize": 15728640000,
    "TotalSizeFormatted": "14.64 GB",
    "FileCount": 45892,
    "Duration": "00:25:30"
  }
}
```

### 8.2 ImportMetadata.json

**Créé après chaque import pour tracking** :

```json
{
  "ImportDate": "2025-12-23 16:00:00",
  "SourcePC": "PC-JOHN",
  "SourceUser": "john.doe",
  "TargetPC": "PC-JANE",
  "TargetUser": "jane.doe",
  "ImportDuration": "00:15:20",
  "RepairedShortcuts": 234,
  "MigrationWizardVersion": "1.0.23.10"
}
```

### 8.3 snapshot.json (Legacy)

**Compatibilité rétroactive** : Anciennes versions créaient `snapshot.json` au lieu de `ExportManifest.json`.

**Détection** : L'import vérifie les deux fichiers.

```powershell
$manifestFile = Join-Path $exportPath 'ExportManifest.json'
$snapshotFile = Join-Path $exportPath 'snapshot.json'

if (Test-Path $manifestFile) {
    $manifest = Get-Content $manifestFile | ConvertFrom-Json
} elseif (Test-Path $snapshotFile) {
    $manifest = Get-Content $snapshotFile | ConvertFrom-Json
} else {
    Write-MWLogError "No manifest found in export folder"
    return $false
}
```

---

## 9. GESTION DES ERREURS ET ROBUSTESSE

### 9.1 Stratégie de Retry

**Robocopy** : 3 tentatives avec 5 secondes d'attente.

```powershell
/R:3    # Retry 3 times
/W:5    # Wait 5 seconds between retries
```

**Copy-MWDirectory** : Boucle de retry au niveau PowerShell.

```powershell
$attempt = 0
do {
    $attempt++
    $success = Start-Robocopy
    if ($success) { return $true }
    Start-Sleep -Seconds 5
} while ($attempt -lt 3)
```

### 9.2 Graceful Degradation

**Principe** : Si une feature échoue, continuer avec les autres.

```powershell
try {
    Export-MWWifiProfiles -ExportPath $exportPath
    Write-MWLogSuccess "Wi-Fi profiles exported"
} catch {
    Write-MWLogError "Failed to export Wi-Fi profiles: $($_.Exception.Message)"
    # Continue avec les autres features
}
```

### 9.3 Logging des Erreurs

**Toutes les erreurs sont loggées avec stack trace** :

```powershell
catch {
    Write-MWLogError "Failed to export Outlook data"
    Write-MWLogError "Exception: $($_.Exception.Message)"
    Write-MWLogError "Stack trace: $($_.ScriptStackTrace)"
}
```

---

## 10. OPTIMISATIONS ET PERFORMANCE

### 10.1 Robocopy Multi-Threaded

**`/MT:8`** : Utilise 8 threads pour paralléliser les copies.

**Impact** : Réduit le temps de copie de ~40% sur gros volumes.

### 10.2 Copie Incrémentale

**`/XO`** : Exclut les fichiers plus anciens (copie uniquement les nouveaux/modifiés).

**Usage** : Mode "Export Incrémental" pour sauvegardes régulières.

### 10.3 Exclusions Robocopy

**Cache et fichiers temporaires exclus** :

```powershell
/XD "Cache" "Temp" "Temporary Internet Files" "~*"
/XF "*.tmp" "*.temp" "Thumbs.db" "desktop.ini"
```

### 10.4 Parallélisation des Features

**Export** : Certaines features peuvent s'exécuter en parallèle (Wi-Fi, Printers, etc.).

**Limitation actuelle** : Séquentiel pour simplifier le logging et le suivi d'erreurs.

**Amélioration future** : Utiliser `Start-Job` pour paralléliser les features indépendantes.

---

## CONCLUSION

Cette documentation technique décrit l'architecture complète de MigrationWizard, du moteur (Core) au châssie (infrastructure) en passant par tous les composants fonctionnels.

**Points clés** :
1. **Architecture en couches** : UI, Business Logic, Infrastructure, Data
2. **Modularité** : 30 modules PowerShell indépendants
3. **Robustesse** : Retry logic, gestion d'erreurs, logging exhaustif
4. **Portabilité** : Un seul EXE de 43 MB avec tout embarqué
5. **Compatibilité PS2EXE** : Solutions aux contraintes de compilation
6. **Ordre d'import critique** : WallpaperDesktop AVANT UserData pour éviter suppression de fichiers

Pour toute question technique ou reprise du développement, consulter également :
- `GUIDE-DEVELOPPEUR.md` : Instructions pour développeurs
- `01-VUE-ENSEMBLE.md` : Vue d'ensemble du projet
- `02-ARCHITECTURE-TECHNIQUE.md` : Détails techniques supplémentaires
- `03-HISTORIQUE-BUGS-FIXES.md` : Bugs corrigés et leçons apprises
- `04-CHANGELOG-DETAILLE.md` : Historique complet des versions

---

**Document créé le** : 2025-12-23
**Auteur** : Claude Code (d'après le code de Jean-Mickael Thomas)
**Version MigrationWizard** : 1.0.23.10
