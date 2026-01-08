# src/Core/FileCopy.psm1

function Get-MWDirectorySize {
    [OutputType([int64])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return 0
    }

    $total = 0L

    if (Test-Path -LiteralPath $Path -PathType Container) {
        Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $total += $_.Length
        }
    } else {
        $item = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
        if ($item -and -not $item.PSIsContainer) {
            $total = $item.Length
        }
    }

    return $total
}

function Test-MWSufficientDiskSpace {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [int]$SafetyMarginMB = 500
    )
    <#
        .SYNOPSIS
            Vérifie qu'il y a suffisamment d'espace disque pour la copie.
        .DESCRIPTION
            Calcule la taille des données à copier puis la compare à l'espace
            libre sur le volume cible, avec une marge de sécurité.
    #>

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-MWLogWarning "Source introuvable pour le test d'espace disque : $SourcePath"
        return $false
    }

    $dataSizeBytes = Get-MWDirectorySize -Path $SourcePath

    $targetRoot = [System.IO.Path]::GetPathRoot($TargetPath)
    if (-not $targetRoot) {
        Write-MWLogWarning "Impossible de déterminer le volume cible pour : $TargetPath"
        return $false
    }

    try {
        $driveInfo = New-Object System.IO.DriveInfo($targetRoot)
        $freeBytes = $driveInfo.AvailableFreeSpace
    } catch {
        Write-MWLogWarning ("Erreur lors de la récupération de l'espace libre sur {0} : {1}" -f $targetRoot, $_)
        return $false
    }

    $marginBytes = [int64]$SafetyMarginMB * 1MB
    $required    = $dataSizeBytes + $marginBytes

    if ($freeBytes -lt $required) {
        $neededGB = [math]::Round($required / 1GB, 2)
        $freeGB   = [math]::Round($freeBytes / 1GB, 2)
        Write-MWLogWarning ("Espace disque insuffisant. Requis ~{0} Go (avec marge), disponible {1} Go." -f $neededGB, $freeGB)
        return $false
    }

    Write-MWLogInfo ("Espace disque suffisant pour copier {0} octets depuis '{1}' vers '{2}'." -f $dataSizeBytes, $SourcePath, $TargetPath)
    return $true
}

function Copy-MWPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        [Parameter(Mandatory = $true)]
        [string]$TargetPath,
        [switch]$SkipDiskCheck,
        [switch]$Incremental
    )
    <#
        .SYNOPSIS
            Copie un chemin (fichier ou dossier) avec la logique MigrationWizard.
        .DESCRIPTION
            Utilise Robocopy pour les dossiers.
            Si -Incremental est activé, utilise /MIR pour copier seulement les fichiers
            nouveaux ou modifiés (mode miroir incrémental).
    #>

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        Write-MWLogError "Source introuvable pour la copie : $SourcePath"
        return
    }

    if (-not $SkipDiskCheck) {
        if (-not (Test-MWSufficientDiskSpace -SourcePath $SourcePath -TargetPath $TargetPath)) {
            Write-MWLogError "Copie annulée pour cause d'espace disque insuffisant."
            return
        }
    }

try {
    if (Test-Path -LiteralPath $SourcePath -PathType Container) {
        # Copie de dossier via Robocopy
        if (-not (Test-Path -LiteralPath $TargetPath)) {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
        }

        if ($Incremental) {
            Write-MWLogInfo "Copie INCREMENTALE du dossier '$SourcePath' vers '$TargetPath' (seulement fichiers nouveaux/modifiés)."
        }
        else {
            Write-MWLogInfo "Copie COMPLETE du dossier '$SourcePath' vers '$TargetPath'."
        }

        $robocopyArgs = @(
            "`"$SourcePath`"",
            "`"$TargetPath`""
        )

        # Mode incrémental : /MIR (miroir - copie seulement différences)
        # Mode complet : /E (tous les sous-dossiers)
        if ($Incremental) {
            $robocopyArgs += '/MIR'     # Mode miroir - copie seulement nouveaux/modifiés
        }
        else {
            $robocopyArgs += '/E'       # Tous sous-dossiers, y compris vides
        }

        $robocopyArgs += @(
            '/COPY:DAT',    # Données, Attributs, Timestamps (pas ACL pour éviter les soucis de permissions)
            '/R:1',         # 1 seule tentative en cas d'erreur (plus rapide)
            '/W:2',         # 2 secondes d'attente entre tentatives (au lieu de 5)
            '/MT:16',       # 16 threads au lieu de 8 (beaucoup plus rapide)
            '/NFL',         # Pas de liste de fichiers
            '/NDL',         # Pas de liste de dossiers
            '/NP',          # Pas de pourcentage
            '/NJH',         # Pas de header
            '/NJS',         # Pas de summary
            '/J'            # Mode unbuffered (plus rapide sur gros fichiers)
        )

        # Exclusions par défaut (à enrichir selon besoins)
        $excludeDirs = @('$RECYCLE.BIN', 'System Volume Information')
        foreach ($dir in $excludeDirs) {
            $robocopyArgs += "/XD"
            $robocopyArgs += "`"$dir`""
        }

        $excludeFiles = @('Thumbs.db', 'desktop.ini', '*.tmp', '*.temp')
        foreach ($file in $excludeFiles) {
            $robocopyArgs += "/XF"
            $robocopyArgs += "`"$file`""
        }

        $process = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -PassThru -NoNewWindow
        $exitCode = $process.ExitCode

        # Robocopy exit codes: 0-7 = succès, 8+ = erreur
        if ($exitCode -ge 8) {
            Write-MWLogError ("Robocopy a échoué avec le code {0} pour '{1}' -> '{2}'." -f $exitCode, $SourcePath, $TargetPath)
            throw "Robocopy a échoué avec le code $exitCode"
        } else {
            Write-MWLogInfo ("Copie réussie (code Robocopy: {0})." -f $exitCode)
        }
        
    } else {
        # Copie de fichier simple
        $targetDir = Split-Path -Parent $TargetPath
        if ($targetDir -and -not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        Write-MWLogInfo "Copie du fichier '$SourcePath' vers '$TargetPath'."
        Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force -ErrorAction Stop
    }
} catch {
    Write-MWLogError ("Erreur lors de la copie de '{0}' vers '{1}' : {2}" -f $SourcePath, $TargetPath, $_)
    throw
}}

Export-ModuleMember -Function Test-MWSufficientDiskSpace, Copy-MWPath