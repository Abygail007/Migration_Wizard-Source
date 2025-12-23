# Tools/Build-PortableExe.ps1
# Compile MigrationWizard en un EXE portable autonome avec TOUT embarque
# Usage: .\Tools\Build-PortableExe.ps1

[CmdletBinding()]
param(
    [string]$Version = "1.0.14.0",
    [switch]$IncludeRZGet,
    [switch]$KeepMergedScript
)

$ErrorActionPreference = 'Stop'

# === CONFIGURATION ===
$projectRoot = Split-Path -Parent $PSScriptRoot
$buildFolder = Join-Path $projectRoot 'Build'
$mergedScript = Join-Path $buildFolder 'MigrationWizard.Merged.ps1'

# EXE genere dans le depot public MigrationWizard-Exe
# Chemin relatif depuis source vers MigrationWizard-Exe
$exeRepoFolder = Join-Path (Split-Path -Parent $projectRoot) 'MigrationWizard-Exe'
$exePath = Join-Path $exeRepoFolder 'MigrationWizard.exe'
$iconPath = Join-Path $projectRoot 'logo-logicia2.ico'

# Creer dossier Build (pour script temporaire)
if (-not (Test-Path $buildFolder)) {
    New-Item -Path $buildFolder -ItemType Directory -Force | Out-Null
}

# Creer dossier MigrationWizard-Exe si necessaire
if (-not (Test-Path $exeRepoFolder)) {
    New-Item -Path $exeRepoFolder -ItemType Directory -Force | Out-Null
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "         MIGRATION WIZARD - BUILD EXE PORTABLE                  " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# === FONCTION POUR SUPPRIMER EXPORT-MODULEMEMBER ===
function Remove-ExportModuleMember {
    param([string]$Content)
    
    # Format 1: Export-ModuleMember -Function @( ... )
    $Content = [regex]::Replace($Content, 'Export-ModuleMember\s+-Function\s+@\([^)]*\)\s*', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    # Format 2: Export-ModuleMember -Function ` (multi-lignes avec backtick)
    # On supprime ligne par ligne
    $lines = $Content -split "`r?`n"
    $result = [System.Collections.ArrayList]::new()
    $inExportBlock = $false
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Debut d'un bloc Export-ModuleMember avec backtick
        if ($line -match '^\s*Export-ModuleMember\s+-Function\s+`\s*$') {
            $inExportBlock = $true
            continue
        }
        
        # Debut d'un Export-ModuleMember simple (une seule ligne)
        if ($line -match '^\s*Export-ModuleMember\s+-Function\s+[^`@]' -and $line -notmatch '`\s*$') {
            # Ligne simple, on la saute
            continue
        }
        
        # Si on est dans un bloc multi-lignes
        if ($inExportBlock) {
            # Si la ligne se termine par un backtick ou une virgule, on continue a sauter
            if ($line -match '`\s*$' -or $line -match ',\s*$') {
                continue
            }
            # Derniere ligne du bloc (pas de backtick ni virgule a la fin)
            if ($line -match '^\s+\w') {
                $inExportBlock = $false
                continue
            }
            # Ligne vide ou autre = fin du bloc
            $inExportBlock = $false
        }
        
        [void]$result.Add($line)
    }
    
    return ($result -join "`r`n")
}

# === ETAPE 1: LECTURE DES FICHIERS SOURCE ===
Write-Host "[1/8] Lecture des fichiers source..." -ForegroundColor Yellow

$srcPath = Join-Path $projectRoot 'src'
$modulesOrder = @(
    'src\Modules\MW.Logging.psm1',
    'src\Assets\MW.Logo.Base64.ps1',
    'src\Assets\MW.NyanCat.Base64.ps1',
    'src\Core\Bootstrap.psm1',
    'src\Core\FileCopy.psm1',
    'src\Core\DataFolders.psm1',
    'src\Core\OneDrive.psm1',
    'src\Core\Profile.psm1',
    'src\Core\Export.psm1',
    'src\Core\Applications.psm1',
    'src\Features\UserData.psm1',
    'src\Features\Wifi.psm1',
    'src\Features\Printers.psm1',
    'src\Features\TaskbarStart.psm1',
    'src\Features\WallpaperDesktop.psm1',
    'src\Features\QuickAccess.psm1',
    'src\Features\NetworkDrives.psm1',
    'src\Features\RDP.psm1',
    'src\Features\Browsers.psm1',
    'src\Features\BrowserDetection.psm1',
    'src\Features\Outlook.psm1',
    'src\Features\ClientSelector.psm1',
    'src\UI\ManifestManager.psm1',
    'src\UI\TreeBuilder.psm1',
    'src\UI\DashboardManager.psm1',
    'src\UI\UINavigation.psm1',
    'src\UI\UIValidation.psm1',
    'src\UI\SummaryBuilder.psm1',
    'src\UI\SnakeGame.psm1',
    'src\UI\MigrationWizard.UI.psm1'
)

# === ETAPE 2: LIRE LE XAML ===
Write-Host "[2/8] Lecture du XAML..." -ForegroundColor Yellow
$xamlPath = Join-Path $projectRoot 'src\UI\MigrationWizard.xaml'
$xamlContent = Get-Content $xamlPath -Raw -Encoding UTF8

$xamlSizeKB = [int]($xamlContent.Length / 1024)
Write-Host "      OK - XAML lu ($xamlSizeKB KB)" -ForegroundColor Green

# === ETAPE 3: EMBARQUER NYAN CAT JPG (au lieu du GIF) ===
Write-Host "[3/8] Embarquement de Nyan Cat JPG..." -ForegroundColor Yellow
$nyanCatBase64 = $null
$nyanCatPath = Join-Path $projectRoot 'Tools\nyan-cat-gif-1.jpg'
if (Test-Path $nyanCatPath) {
    $nyanBytes = [System.IO.File]::ReadAllBytes($nyanCatPath)
    $nyanCatBase64 = [Convert]::ToBase64String($nyanBytes)
    $nyanSizeKB = [int]($nyanBytes.Length / 1024)
    Write-Host "      OK - Nyan Cat JPG embarque ($nyanSizeKB KB)" -ForegroundColor Green
} else {
    Write-Host "      WARN - Nyan Cat JPG non trouve, ignore" -ForegroundColor DarkYellow
}

# === ETAPE 3.5: OPTIONNEL - EMBARQUER RZGET.EXE ===
$rzgetBase64 = $null
if ($IncludeRZGet) {
    Write-Host "[3.5/8] Embarquement de RZGet.exe..." -ForegroundColor Yellow
    $rzgetPath = Join-Path $projectRoot 'Tools\RZGet.exe'
    if (Test-Path $rzgetPath) {
        $rzgetBytes = [System.IO.File]::ReadAllBytes($rzgetPath)
        $rzgetBase64 = [Convert]::ToBase64String($rzgetBytes)
        $rzgetSizeKB = [int]($rzgetBytes.Length / 1024)
        Write-Host "      OK - RZGet.exe embarque ($rzgetSizeKB KB)" -ForegroundColor Green
    } else {
        Write-Host "      WARN - RZGet.exe non trouve, ignore" -ForegroundColor DarkYellow
    }
} else {
    Write-Host "[3.5/8] RZGet.exe non embarque (utilisez -IncludeRZGet)" -ForegroundColor DarkGray
}

# === ETAPE 3.6: EMBARQUER DESKTOPOK.EXE ===
Write-Host "[3.6/8] Embarquement de DesktopOK.exe..." -ForegroundColor Yellow
$desktopOKBase64 = $null
$desktopOKPath = Join-Path $projectRoot 'Tools\DesktopOK.exe'
if (Test-Path $desktopOKPath) {
    $desktopOKBytes = [System.IO.File]::ReadAllBytes($desktopOKPath)
    $desktopOKBase64 = [Convert]::ToBase64String($desktopOKBytes)
    $desktopOKSizeKB = [int]($desktopOKBytes.Length / 1024)
    Write-Host "      OK - DesktopOK.exe embarque ($desktopOKSizeKB KB)" -ForegroundColor Green
} else {
    Write-Host "      WARN - DesktopOK.exe non trouve, ignore" -ForegroundColor DarkYellow
}

# === ETAPE 3.7: EMBARQUER RACCOURCIS LOGICIA ===
Write-Host "[3.7/8] Embarquement raccourcis Logicia..." -ForegroundColor Yellow
$logiciaEspaceClientBase64 = $null
$logiciaTelemaintenanceBase64 = $null

$espaceClientPath = Join-Path $projectRoot 'Tools\Espace Client - Logicia.exe'
if (Test-Path $espaceClientPath) {
    $espaceClientBytes = [System.IO.File]::ReadAllBytes($espaceClientPath)
    $logiciaEspaceClientBase64 = [Convert]::ToBase64String($espaceClientBytes)
    $espaceClientSizeKB = [int]($espaceClientBytes.Length / 1024)
    Write-Host "      OK - Espace Client - Logicia.exe embarque ($espaceClientSizeKB KB)" -ForegroundColor Green
} else {
    Write-Host "      WARN - Espace Client - Logicia.exe non trouve" -ForegroundColor DarkYellow
}

$telemaintenancePath = Get-ChildItem -Path (Join-Path $projectRoot 'Tools') -Filter '*maintenance Logicia.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1 | ForEach-Object { $_.FullName }
if ($telemaintenancePath -and (Test-Path $telemaintenancePath)) {
    $telemaintenanceBytes = [System.IO.File]::ReadAllBytes($telemaintenancePath)
    $logiciaTelemaintenanceBase64 = [Convert]::ToBase64String($telemaintenanceBytes)
    $telemaintenanceSizeKB = [int]($telemaintenanceBytes.Length / 1024)
    Write-Host "      OK - Telemaintenance Logicia.exe embarque ($telemaintenanceSizeKB KB)" -ForegroundColor Green
} else {
    Write-Host '      WARN - Telemaintenance Logicia.exe non trouve' -ForegroundColor DarkYellow
}

# === ETAPE 4: CONSTRUIRE LE SCRIPT FUSIONNE ===
Write-Host "[4/8] Fusion des modules..." -ForegroundColor Yellow

# Debut du script fusionne
$headerContent = @"
# ================================================================================
# MIGRATIONWIZARD - VERSION PORTABLE
# Ce fichier est genere automatiquement par Build-PortableExe.ps1
# NE PAS MODIFIER MANUELLEMENT
# Version: $Version
# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
# ================================================================================

# === MARQUEUR MODE PORTABLE ===
`$script:IsPortableMode = `$true
`$script:PortableVersion = '$Version'

# === XAML EMBARQUE ===
`$script:EmbeddedXAML = @'
$xamlContent
'@

"@

$mergedContent = $headerContent

# Ajouter Nyan Cat GIF si disponible
if ($nyanCatBase64) {
    $mergedContent += @"

# === NYAN CAT GIF EMBARQUE (BASE64) ===
`$script:NyanCatBase64 = '$nyanCatBase64'

"@
}

# Ajouter RZGet.exe si demande
if ($rzgetBase64) {
    $mergedContent += @"

# === RZGET.EXE EMBARQUE (BASE64) ===
`$Global:MW_RZGET_BASE64 = '$rzgetBase64'

"@
}

# Ajouter DesktopOK.exe si disponible
if ($desktopOKBase64) {
    $mergedContent += @"

# === DESKTOPOK.EXE EMBARQUE (BASE64) ===
`$script:DESKTOPOK_BASE64 = '$desktopOKBase64'

"@
}

# Ajouter raccourcis Logicia si disponibles
if ($logiciaEspaceClientBase64) {
    $mergedContent += @"

# === ESPACE CLIENT LOGICIA EMBARQUE (BASE64) ===
`$script:LOGICIA_ESPACE_CLIENT___LOGICIA_EXE_BASE64 = '$logiciaEspaceClientBase64'

"@
}

if ($logiciaTelemaintenanceBase64) {
    $mergedContent += @"

# === TELEMAINTENANCE LOGICIA EMBARQUE (BASE64) ===
`$script:LOGICIA_T_L_MAINTENANCE_LOGICIA_EXE_BASE64 = '$logiciaTelemaintenanceBase64'

"@
}

# Lire et fusionner chaque module
$moduleCount = 0
foreach ($modulePath in $modulesOrder) {
    $fullPath = Join-Path $projectRoot $modulePath
    if (Test-Path $fullPath) {
        $moduleContent = Get-Content $fullPath -Raw -Encoding UTF8
        
        # Supprimer les Export-ModuleMember (tous les formats)
        $moduleContent = Remove-ExportModuleMember -Content $moduleContent
        
        $moduleName = Split-Path $modulePath -Leaf
        $mergedContent += @"

# ================================================================================
# MODULE: $moduleName
# ================================================================================

$moduleContent

"@
        $moduleCount++
        Write-Host "      + $moduleName" -ForegroundColor DarkGray
    } else {
        Write-Host "      X $modulePath non trouve!" -ForegroundColor Red
    }
}

Write-Host "      OK - $moduleCount modules fusionnes" -ForegroundColor Green

# === ETAPE 5: AJOUTER LE CODE PRINCIPAL ===
Write-Host "[5/8] Ajout du code principal..." -ForegroundColor Yellow

$mainCode = @'

# ================================================================================
# POINT D'ENTREE PRINCIPAL - MODE PORTABLE
# ================================================================================

# ===== ELEVATION ADMIN AUTOMATIQUE (SILENCIEUSE) =====
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    $exePath = [Environment]::GetCommandLineArgs()[0]
    try {
        Start-Process $exePath -Verb RunAs
        exit
    }
    catch {
        # L'utilisateur a refuse l'elevation ou erreur - quitter silencieusement
        exit 1
    }
}

# ===== DETECTION DU DOSSIER RACINE =====
$exePath = [Environment]::GetCommandLineArgs()[0]
$ScriptRoot = Split-Path -Parent $exePath
if (-not $ScriptRoot -or $ScriptRoot -eq '') {
    $ScriptRoot = (Get-Location).Path
}

$Global:MWRootPath = $ScriptRoot
Set-Location $ScriptRoot

# ===== INITIALISATION LOGGING =====
Initialize-MWLogging
Write-MWLogInfo -Message "Demarrage de MigrationWizard (Mode Portable v$script:PortableVersion)"

# ===== INITIALISATION ENVIRONNEMENT =====
Initialize-MWEnvironment

# ===== LANCER L'UI =====
Start-MWMigrationWizardUI
'@

$mergedContent += $mainCode

Write-Host "      OK" -ForegroundColor Green

# === ETAPE 6: SAUVEGARDER LE SCRIPT FUSIONNE ===
Write-Host "[6/8] Sauvegarde du script fusionne..." -ForegroundColor Yellow

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($mergedScript, $mergedContent, $utf8NoBom)

$mergedSize = [int]((Get-Item $mergedScript).Length / 1024)
Write-Host "      OK - $mergedScript ($mergedSize KB)" -ForegroundColor Green

# === ETAPE 7: COMPILATION AVEC PS2EXE ===
Write-Host "[7/8] Compilation avec PS2EXE..." -ForegroundColor Yellow

$ps2exeModule = Get-Module -ListAvailable -Name ps2exe
if (-not $ps2exeModule) {
    Write-Host "      Module ps2exe non installe. Installation..." -ForegroundColor DarkYellow
    try {
        Install-Module -Name ps2exe -Scope CurrentUser -Force
        Import-Module ps2exe
    }
    catch {
        Write-Host "      ERREUR - Impossible d'installer ps2exe: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "      Installation manuelle requise:" -ForegroundColor Yellow
        Write-Host "      Install-Module -Name ps2exe -Scope CurrentUser" -ForegroundColor White
        exit 1
    }
}

Import-Module ps2exe -ErrorAction Stop

if (Test-Path $exePath) {
    Remove-Item $exePath -Force
}

try {
    $ps2exeParams = @{
        inputFile   = $mergedScript
        outputFile  = $exePath
        noConsole   = $true
        STA         = $true
        title       = 'MigrationWizard'
        product     = 'MigrationWizard'
        company     = 'Logicia / Jean-Mickael Thomas'
        version     = $Version
        copyright   = "(c) $(Get-Date -Format 'yyyy') Logicia"
        description = 'Outil de migration de profils Windows'
    }
    
    if (Test-Path $iconPath) {
        $ps2exeParams.iconFile = $iconPath
    }
    
    Invoke-ps2exe @ps2exeParams
    
    Write-Host "      OK - Compilation reussie!" -ForegroundColor Green
}
catch {
    Write-Host "      ERREUR - Compilation: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# === ETAPE 8: NETTOYAGE ===
if (-not $KeepMergedScript) {
    Write-Host "[8/8] Nettoyage..." -ForegroundColor Yellow
    Remove-Item $mergedScript -Force -ErrorAction SilentlyContinue
    Write-Host "      OK - Script temporaire supprime" -ForegroundColor Green
} else {
    Write-Host "[8/8] Script fusionne conserve pour debug" -ForegroundColor DarkGray
    Write-Host "      -> $mergedScript" -ForegroundColor DarkGray
}

# === RESULTAT FINAL ===
Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "                    COMPILATION TERMINEE                        " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

if (Test-Path $exePath) {
    $exeSize = [math]::Round((Get-Item $exePath).Length / 1MB, 2)
    Write-Host "EXE Portable cree: " -NoNewline
    Write-Host $exePath -ForegroundColor Cyan
    Write-Host "Taille: $exeSize MB"
    Write-Host ""
    Write-Host "L'EXE est 100% autonome - aucun fichier supplementaire requis!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "   - Double-clic pour lancer l'interface graphique"
} else {
    Write-Host "ERREUR - L'EXE n'a pas ete cree!" -ForegroundColor Red
}
