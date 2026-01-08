# ==============================================================================
# WallpaperDesktop.psm1
# Gestion du fond d'écran et des bureaux avec DesktopOK
# ==============================================================================

function Export-WallpaperDesktop {
    <#
    .SYNOPSIS
    Exporte le fond d'écran, les positions d'icônes (DesktopOK) et tout le contenu des bureaux

    .PARAMETER OutRoot
    Dossier racine de destination pour l'export

    .PARAMETER IncludeWallpaper
    Exporter le fond d'écran

    .PARAMETER IncludeDesktopLayout
    Exporter les positions d'icônes et le contenu des bureaux
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutRoot,

        [bool]$IncludeWallpaper = $true,
        [bool]$IncludeDesktopLayout = $true
    )

    try {
        Write-MWLogInfo "=== Début Export Wallpaper/Desktop ==="

        if ($IncludeWallpaper) {
            Export-WallpaperSimple -OutRoot $OutRoot
        }

        if ($IncludeDesktopLayout) {
            Export-DesktopComplete -OutRoot $OutRoot
        }

        Write-MWLogInfo "=== Export Wallpaper/Desktop terminé ==="
    }
    catch {
        Write-MWLogError "Export Wallpaper/Desktop : $($_.Exception.Message)"
    }
}

function Import-WallpaperDesktop {
    <#
    .SYNOPSIS
    Importe le fond d'écran, restaure les bureaux et les positions d'icônes

    .PARAMETER InRoot
    Dossier racine source pour l'import

    .PARAMETER IncludeWallpaper
    Importer le fond d'écran

    .PARAMETER IncludeDesktopLayout
    Importer les bureaux et positions d'icônes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$InRoot,

        [bool]$IncludeWallpaper = $true,
        [bool]$IncludeDesktopLayout = $true
    )

    try {
        Write-MWLogInfo "=== Début Import Wallpaper/Desktop ==="

        if ($IncludeDesktopLayout) {
            Import-DesktopComplete -InRoot $InRoot
        }

        if ($IncludeWallpaper) {
            Import-WallpaperSimple -InRoot $InRoot
        }

        Write-MWLogInfo "=== Import Wallpaper/Desktop terminé ==="
    }
    catch {
        Write-MWLogError "Import Wallpaper/Desktop : $($_.Exception.Message)"
    }
}

# ==============================================================================
# EXPORT - Bureau complet avec DesktopOK
# ==============================================================================

function Export-DesktopComplete {
    param([string]$OutRoot)

    try {
        Write-MWLogInfo "--- Export complet des bureaux ---"

        # 1) Sauvegarder positions avec DesktopOK
        Export-DesktopPositions -OutRoot $OutRoot

        # 2) Copier contenu bureau utilisateur
        $userDesktop = Get-UserDesktopPath
        if ($userDesktop -and (Test-Path $userDesktop)) {
            $destUser = Join-Path $OutRoot 'Desktop-User'
            Write-MWLogInfo "Copie Bureau User: $userDesktop -> $destUser"
            Copy-FolderContent -Source $userDesktop -Destination $destUser
        } else {
            Write-MWLogWarning "Bureau utilisateur introuvable: $userDesktop"
        }

        # 3) Copier contenu bureau public
        $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
        if ($publicDesktop -and (Test-Path $publicDesktop)) {
            $destPublic = Join-Path $OutRoot 'Desktop-Public'
            Write-MWLogInfo "Copie Bureau Public: $publicDesktop -> $destPublic"
            Copy-FolderContent -Source $publicDesktop -Destination $destPublic
        } else {
            Write-MWLogWarning "Bureau public introuvable: $publicDesktop"
        }

        Write-MWLogInfo "Export bureaux terminé"
    }
    catch {
        Write-MWLogError "Export-DesktopComplete : $($_.Exception.Message)"
    }
}

function Export-DesktopPositions {
    param([string]$OutRoot)

    try {
        # Extraire DesktopOK.exe si embarqué
        $desktopOK = Get-EmbeddedDesktopOK

        if (-not $desktopOK -or -not (Test-Path $desktopOK)) {
            Write-MWLogWarning "DesktopOK.exe introuvable - positions non sauvegardées"
            return
        }

        $saveFile = Join-Path $OutRoot 'desktop_positions.dok'

        Write-MWLogInfo "DesktopOK: Sauvegarde positions -> $saveFile"

        # DesktopOK commande: /save /silent fichier.dok
        $proc = Start-Process -FilePath $desktopOK -ArgumentList "/save /silent `"$saveFile`"" -NoNewWindow -Wait -PassThru

        if ($proc.ExitCode -eq 0 -and (Test-Path $saveFile)) {
            Write-MWLogInfo "DesktopOK: Positions sauvegardées avec succès"
        } else {
            Write-MWLogWarning "DesktopOK: Échec sauvegarde (code $($proc.ExitCode))"
        }
    }
    catch {
        Write-MWLogError "Export-DesktopPositions : $($_.Exception.Message)"
    }
}

# ==============================================================================
# IMPORT - Restauration complète avec purge + DesktopOK + raccourcis Logicia
# ==============================================================================

function Import-DesktopComplete {
    param([string]$InRoot)

    try {
        Write-MWLogInfo "--- Import complet des bureaux ---"

        # 1) PURGE TOTALE des bureaux
        Clear-AllDesktops

        # 2) RESTAURATION EXACTE depuis backup
        Restore-DesktopContent -InRoot $InRoot

        # 3) RESTAURATION POSITIONS avec DesktopOK
        Import-DesktopPositions -InRoot $InRoot

        # 4) AJOUT RACCOURCIS LOGICIA dans bureau public
        Add-LogiciaShortcuts

        Write-MWLogInfo "Import bureaux terminé"
    }
    catch {
        Write-MWLogError "Import-DesktopComplete : $($_.Exception.Message)"
    }
}

function Clear-AllDesktops {
    try {
        Write-MWLogInfo ">>> PURGE TOTALE des bureaux <<<"

        # Bureau utilisateur
        $userDesktop = Get-UserDesktopPath
        if ($userDesktop -and (Test-Path $userDesktop)) {
            Write-MWLogInfo "Purge Bureau User: $userDesktop"
            Clear-FolderContent -Path $userDesktop
        }

        # Bureau public
        $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
        if ($publicDesktop -and (Test-Path $publicDesktop)) {
            Write-MWLogInfo "Purge Bureau Public: $publicDesktop"
            Clear-FolderContent -Path $publicDesktop
        }

        Write-MWLogInfo "Purge terminée"
    }
    catch {
        Write-MWLogError "Clear-AllDesktops : $($_.Exception.Message)"
    }
}

function Restore-DesktopContent {
    param([string]$InRoot)

    try {
        Write-MWLogInfo ">>> RESTAURATION EXACTE des bureaux <<<"

        # Restaurer bureau utilisateur
        $sourceUser = Join-Path $InRoot 'Desktop-User'
        $userDesktop = Get-UserDesktopPath

        if ((Test-Path $sourceUser) -and $userDesktop) {
            Write-MWLogInfo "Restauration Bureau User: $sourceUser -> $userDesktop"
            Copy-FolderContent -Source $sourceUser -Destination $userDesktop
        } else {
            Write-MWLogWarning "Source Desktop-User introuvable ou destination invalide"
        }

        # Restaurer bureau public
        $sourcePublic = Join-Path $InRoot 'Desktop-Public'
        $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')

        if ((Test-Path $sourcePublic) -and $publicDesktop) {
            Write-MWLogInfo "Restauration Bureau Public: $sourcePublic -> $publicDesktop"
            Copy-FolderContent -Source $sourcePublic -Destination $publicDesktop
        } else {
            Write-MWLogWarning "Source Desktop-Public introuvable ou destination invalide"
        }

        Write-MWLogInfo "Restauration contenu terminée"
    }
    catch {
        Write-MWLogError "Restore-DesktopContent : $($_.Exception.Message)"
    }
}

function Import-DesktopPositions {
    param([string]$InRoot)

    try {
        $saveFile = Join-Path $InRoot 'desktop_positions.dok'

        if (-not (Test-Path $saveFile)) {
            Write-MWLogWarning "Fichier positions DesktopOK introuvable: $saveFile"
            return
        }

        # Extraire DesktopOK.exe si embarqué
        $desktopOK = Get-EmbeddedDesktopOK

        if (-not $desktopOK -or -not (Test-Path $desktopOK)) {
            Write-MWLogWarning "DesktopOK.exe introuvable - positions non restaurées"
            return
        }

        Write-MWLogInfo "DesktopOK: Restauration positions depuis $saveFile"

        # DesktopOK commande: /load /silent fichier.dok
        $proc = Start-Process -FilePath $desktopOK -ArgumentList "/load /silent `"$saveFile`"" -NoNewWindow -Wait -PassThru

        if ($proc.ExitCode -eq 0) {
            Write-MWLogInfo "DesktopOK: Positions restaurées avec succès"
        } else {
            Write-MWLogWarning "DesktopOK: Échec restauration (code $($proc.ExitCode))"
        }
    }
    catch {
        Write-MWLogError "Import-DesktopPositions : $($_.Exception.Message)"
    }
}

function Add-LogiciaShortcuts {
    try {
        Write-MWLogInfo ">>> Ajout raccourcis Logicia dans bureau public <<<"

        $publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')

        if (-not $publicDesktop -or -not (Test-Path $publicDesktop)) {
            Write-MWLogWarning "Bureau public introuvable"
            return
        }

        # Liste des raccourcis à ajouter
        $shortcuts = @(
            'Espace Client - Logicia.exe',
            'Télémaintenance Logicia.exe'
        )

        foreach ($shortcut in $shortcuts) {
            # Chercher le fichier embarqué
            $source = Get-EmbeddedFile -FileName $shortcut

            if ($source -and (Test-Path $source)) {
                $dest = Join-Path $publicDesktop $shortcut
                Write-MWLogInfo "Copie raccourci: $shortcut -> Bureau Public"
                Copy-Item -LiteralPath $source -Destination $dest -Force -ErrorAction Stop
            } else {
                Write-MWLogWarning "Raccourci introuvable: $shortcut"
            }
        }

        Write-MWLogInfo "Raccourcis Logicia ajoutés"
    }
    catch {
        Write-MWLogError "Add-LogiciaShortcuts : $($_.Exception.Message)"
    }
}

# ==============================================================================
# UTILITAIRES - Gestion des fichiers embarqués
# ==============================================================================

function Get-EmbeddedDesktopOK {
    <#
    .SYNOPSIS
    Extrait DesktopOK.exe depuis le script embarqué vers un dossier temporaire
    .OUTPUTS
    Chemin complet vers DesktopOK.exe extrait
    #>
    try {
        # Mode embarqué: extraire depuis base64 (vérifier que variable existe)
        $hasDesktopOK = $false
        $base64Data = $null

        if (Get-Variable -Name 'DESKTOPOK_BASE64' -Scope Script -ErrorAction SilentlyContinue) {
            $base64Var = Get-Variable -Name 'DESKTOPOK_BASE64' -Scope Script -ValueOnly -ErrorAction SilentlyContinue
            if ($base64Var -and -not [string]::IsNullOrWhiteSpace($base64Var)) {
                $hasDesktopOK = $true
                $base64Data = $base64Var
            }
        }

        if (-not $hasDesktopOK) {
            Write-MWLogWarning "DesktopOK.exe non embarqué dans le build (variable DESKTOPOK_BASE64 absente ou vide)"
            return $null
        }

        $tempDir = Join-Path $env:TEMP 'MigrationWizard'
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        $exePath = Join-Path $tempDir 'DesktopOK.exe'

        # Extraire seulement si pas déjà présent
        if (-not (Test-Path $exePath)) {
            Write-MWLogDebug "Extraction de DesktopOK.exe depuis base64 embarqué..."
            Write-MWLogInfo "DesktopOK.exe extrait vers: $exePath"
            $bytes = [Convert]::FromBase64String($base64Data)
            [System.IO.File]::WriteAllBytes($exePath, $bytes)
        }
        else {
            Write-MWLogDebug "DesktopOK.exe déjà extrait: $exePath"
        }

        return $exePath
    }
    catch {
        Write-MWLogError "Get-EmbeddedDesktopOK : $($_.Exception.Message)"
        return $null
    }
}

function Get-EmbeddedFile {
    <#
    .SYNOPSIS
    Extrait un fichier embarqué (raccourcis Logicia)
    .PARAMETER FileName
    Nom du fichier à extraire
    .OUTPUTS
    Chemin complet vers le fichier extrait
    #>
    param([string]$FileName)

    try {
        # Mode embarqué: extraire depuis variable base64
        $varName = "LOGICIA_" + ($FileName -replace '[^a-zA-Z0-9]', '_').ToUpper() + "_BASE64"

        if (Get-Variable -Name $varName -Scope Script -ErrorAction SilentlyContinue) {
            $base64 = Get-Variable -Name $varName -Scope Script -ValueOnly -ErrorAction SilentlyContinue

            if ($base64 -and -not [string]::IsNullOrWhiteSpace($base64)) {
                $tempDir = Join-Path $env:TEMP 'MigrationWizard'
                if (-not (Test-Path $tempDir)) {
                    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
                }

                $filePath = Join-Path $tempDir $FileName

                if (-not (Test-Path $filePath)) {
                    Write-MWLogInfo "Extraction $FileName -> $filePath"
                    $bytes = [Convert]::FromBase64String($base64)
                    [System.IO.File]::WriteAllBytes($filePath, $bytes)
                }
                else {
                    Write-MWLogDebug "$FileName déjà extrait: $filePath"
                }

                return $filePath
            }
        }

        Write-MWLogWarning "Fichier '$FileName' non embarqué dans le build (variable $varName absente ou vide)"
        return $null
    }
    catch {
        Write-MWLogError "Get-EmbeddedFile '$FileName' : $($_.Exception.Message)"
        return $null
    }
}

# ==============================================================================
# UTILITAIRES - Chemins et gestion fichiers
# ==============================================================================

function Get-ActiveUser {
    try {
        $cs = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        if ($cs -and $cs.UserName) { return $cs.UserName }
    } catch {}

    try {
        $p = Get-Process -Name explorer -IncludeUserName -ErrorAction Stop | Select-Object -First 1
        if ($p -and $p.UserName) { return $p.UserName }
    } catch {}

    return $env:USERNAME
}

function Get-UserSidFromName {
    param([string]$UserName)
    try {
        $nt = New-Object System.Security.Principal.NTAccount($UserName)
        $sid = $nt.Translate([System.Security.Principal.SecurityIdentifier])
        return $sid.Value
    } catch {
        return $null
    }
}

function Get-ProfilePathFromSid {
    param([string]$Sid)
    $key = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$Sid"
    try {
        $p = (Get-ItemProperty -Path $key -ErrorAction Stop).ProfileImagePath
        if ($p) { return [Environment]::ExpandEnvironmentVariables($p) }
    } catch {}
    return $null
}

function Get-UserDesktopPath {
    try {
        $userName = Get-ActiveUser
        if (-not $userName) {
            Write-MWLogWarning "Utilisateur actif introuvable, utilisation chemin par défaut"
            return [Environment]::GetFolderPath('Desktop')
        }

        $sid = Get-UserSidFromName -UserName $userName
        if (-not $sid) {
            Write-MWLogWarning "SID introuvable pour $userName, utilisation chemin par défaut"
            return [Environment]::GetFolderPath('Desktop')
        }

        $profilePath = Get-ProfilePathFromSid -Sid $sid
        if (-not $profilePath) {
            Write-MWLogWarning "Profil introuvable pour SID $sid, utilisation chemin par défaut"
            return [Environment]::GetFolderPath('Desktop')
        }

        # Essayer de lire le chemin personnalisé depuis le registre
        $reg = "Registry::HKEY_USERS\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
        try {
            $raw = (Get-ItemProperty -Path $reg -ErrorAction Stop).Desktop
            if ($raw) {
                $expanded = $raw -replace '%USERPROFILE%', $profilePath
                $expanded = [Environment]::ExpandEnvironmentVariables($expanded)
                if (Test-Path $expanded) {
                    return $expanded
                }
            }
        } catch {}

        # Fallback: profil\Desktop
        $desktopPath = Join-Path $profilePath 'Desktop'
        if (Test-Path $desktopPath) {
            return $desktopPath
        }

        # Dernier recours
        return [Environment]::GetFolderPath('Desktop')
    }
    catch {
        Write-MWLogError "Get-UserDesktopPath : $($_.Exception.Message)"
        return [Environment]::GetFolderPath('Desktop')
    }
}

function Clear-FolderContent {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-MWLogWarning "Dossier introuvable pour purge: $Path"
        return
    }

    $items = Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    $count = ($items | Measure-Object).Count

    if ($count -eq 0) {
        Write-MWLogInfo "Dossier déjà vide: $Path"
        return
    }

    Write-MWLogInfo "Suppression de $count élément(s) dans $Path"

    foreach ($it in $items) {
        try {
            Remove-Item -LiteralPath $it.FullName -Recurse -Force -ErrorAction Stop
        } catch {
            Write-MWLogWarning "Erreur suppression '$($it.Name)' : $($_.Exception.Message)"
        }
    }
}

function Copy-FolderContent {
    param(
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Write-MWLogWarning "Source introuvable: $Source"
        return
    }

    # Créer destination si nécessaire
    if (-not (Test-Path -LiteralPath $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    $items = Get-ChildItem -LiteralPath $Source -Force -ErrorAction SilentlyContinue
    $count = ($items | Measure-Object).Count

    Write-MWLogInfo "Copie de $count élément(s): $Source -> $Destination"

    foreach ($it in $items) {
        $destPath = Join-Path $Destination $it.Name

        try {
            if ($it.PSIsContainer) {
                Copy-Item -LiteralPath $it.FullName -Destination $destPath -Recurse -Force -ErrorAction Stop
            } else {
                Copy-Item -LiteralPath $it.FullName -Destination $destPath -Force -ErrorAction Stop
            }
        } catch {
            Write-MWLogWarning "Erreur copie '$($it.Name)' : $($_.Exception.Message)"
        }
    }
}

# ==============================================================================
# WALLPAPER - Keep existing logic (works well)
# ==============================================================================

function Export-WallpaperSimple {
    param([string]$OutRoot)

    try {
        $wp = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallPaper -ErrorAction SilentlyContinue).WallPaper

        if (-not $wp -or [string]::IsNullOrWhiteSpace($wp)) {
            $appDataPath = Join-Path $env:APPDATA "Microsoft\Windows\Themes\TranscodedWallpaper"
            if (Test-Path $appDataPath) {
                $wp = $appDataPath
            }
        }

        if (-not $wp -or [string]::IsNullOrWhiteSpace($wp)) {
            Write-MWLogWarning "Fond d'écran : impossible de détecter"
            return
        }

        Write-MWLogInfo "Fond d'écran détecté : $wp"

        $wdir = Join-Path $OutRoot 'Wallpaper'
        New-Item -ItemType Directory -Force -Path $wdir | Out-Null

        $fileName = [System.IO.Path]::GetFileName($wp)
        if ([string]::IsNullOrWhiteSpace($fileName)) {
            $fileName = "TranscodedWallpaper.jpg"
        }

        $dst = Join-Path $wdir $fileName

        Copy-Item -LiteralPath $wp -Destination $dst -Force -ErrorAction Stop
        "$fileName" | Set-Content -Path (Join-Path $wdir 'wallpaper.txt') -Encoding UTF8

        Write-MWLogInfo "Fond d'écran copié → $dst"
    }
    catch {
        Write-MWLogError "Export fond d'écran : $($_.Exception.Message)"
    }
}

function Import-WallpaperSimple {
    param([string]$InRoot)

    try {
        $wpDir = Join-Path $InRoot 'Wallpaper'

        if (-not (Test-Path $wpDir)) {
            Write-MWLogWarning "Dossier Wallpaper absent"
            return
        }

        $txt = Join-Path $wpDir 'wallpaper.txt'
        $fileName = $null

        if (Test-Path $txt) {
            $fileName = (Get-Content $txt -Raw).Trim()
        }

        $img = $null
        if ($fileName) {
            $img = Join-Path $wpDir $fileName
        }
        else {
            $cand = Get-ChildItem $wpDir -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($cand) {
                $img = $cand.FullName
            }
        }

        if ($img -and (Test-Path $img)) {
            Set-WallpaperSafe -ImagePath $img
        }
        else {
            Write-MWLogWarning "Aucune image wallpaper trouvée"
        }
    }
    catch {
        Write-MWLogError "Import fond d'écran : $($_.Exception.Message)"
    }
}

function Set-WallpaperSafe {
    param([Parameter(Mandatory)][string]$ImagePath)

    try {
        if (-not (Test-Path -LiteralPath $ImagePath)) {
            throw "Image introuvable: $ImagePath"
        }

        # Copie sous C:\Logicia\Wallpaper
        $root = 'C:\Logicia\Wallpaper'
        New-Item -ItemType Directory -Force -Path $root | Out-Null

        $dst = Join-Path $root (Split-Path $ImagePath -Leaf)
        Copy-Item -LiteralPath $ImagePath -Destination $dst -Force
        $ImagePath = $dst

        # Tentative DesktopWallpaper COM
        $ok = $false
        try {
            $dw = New-Object -ComObject DesktopWallpaper
            if ($dw) {
                $dw.SetWallpaper('', $ImagePath) | Out-Null
                $ok = $true
                Write-MWLogInfo "Fond d'écran appliqué via DesktopWallpaper"
            }
        }
        catch {
            Write-MWLogWarning "DesktopWallpaper KO : $($_.Exception.Message)"
        }

        # Fallback: SystemParametersInfo
        if (-not $ok) {
            try {
                $sig = @'
using System;
using System.Runtime.InteropServices;
public class WP {
  [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
'@
                if (-not ([type]::GetType('WP'))) {
                    Add-Type $sig -ErrorAction SilentlyContinue
                }

                [WP]::SystemParametersInfo(20, 0, $ImagePath, 3) | Out-Null
                Write-MWLogInfo "Fond d'écran appliqué via SystemParametersInfo"
                $ok = $true
            }
            catch {
                Write-MWLogWarning "SPI KO : $($_.Exception.Message)"
            }
        }

        if (-not $ok) {
            throw "Impossible d'appliquer le fond d'écran"
        }
    }
    catch {
        Write-MWLogError "Set-WallpaperSafe : $($_.Exception.Message)"
    }
}

# ==============================================================================
# EXPORTS
# ==============================================================================

Export-ModuleMember -Function Export-WallpaperDesktop, Import-WallpaperDesktop
