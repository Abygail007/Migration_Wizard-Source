# ==============================================================================
# DashboardManager.psm1
# Gestion du tableau de bord des exports avec fichier historique centralisé
# ==============================================================================

function Get-MWDashboardHistoryPath {
    <#
    .SYNOPSIS
    Retourne le chemin du fichier d'historique Dashboard
    #>
    $exeFolder = Split-Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Parent
    return Join-Path $exeFolder 'DashboardHistory.json'
}

function Get-MWDashboardHistory {
    <#
    .SYNOPSIS
    Lit l'historique Dashboard depuis le fichier JSON
    .OUTPUTS
    Array de PSCustomObject avec les exports
    #>
    [CmdletBinding()]
    param()

    $historyPath = Get-MWDashboardHistoryPath

    if (-not (Test-Path $historyPath)) {
        Write-MWLogInfo "Aucun historique Dashboard trouvé, création nouveau fichier"
        return @()
    }

    try {
        $json = Get-Content $historyPath -Raw -ErrorAction Stop
        $history = $json | ConvertFrom-Json -ErrorAction Stop

        # Convertir en array si nécessaire
        if ($history -isnot [array]) {
            $history = @($history)
        }

        Write-MWLogInfo "Historique Dashboard chargé: $($history.Count) export(s)"
        return $history
    }
    catch {
        Write-MWLogError "Erreur lecture historique Dashboard: $_"
        return @()
    }
}

function Save-MWDashboardHistory {
    <#
    .SYNOPSIS
    Sauvegarde l'historique Dashboard dans le fichier JSON
    .PARAMETER History
    Array d'objets export à sauvegarder
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$History
    )

    $historyPath = Get-MWDashboardHistoryPath

    try {
        $json = $History | ConvertTo-Json -Depth 10 -Compress:$false
        $json | Out-File -FilePath $historyPath -Encoding UTF8 -Force
        Write-MWLogInfo "Historique Dashboard sauvegardé: $($History.Count) export(s)"
        return $true
    }
    catch {
        Write-MWLogError "Erreur sauvegarde historique Dashboard: $_"
        return $false
    }
}

function Add-MWDashboardExport {
    <#
    .SYNOPSIS
    Ajoute ou met à jour un export dans l'historique Dashboard
    .PARAMETER ClientName
    Nom du client
    .PARAMETER PCName
    Nom du PC
    .PARAMETER ExportType
    Type d'export: 'Principal' ou 'Incrementiel'
    .PARAMETER SizeBytes
    Taille en bytes
    .PARAMETER RelativePath
    Chemin relatif (ex: .\ClientName\PCName)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ClientName,

        [Parameter(Mandatory=$true)]
        [string]$PCName,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Principal', 'Incrementiel')]
        [string]$ExportType,

        [Parameter(Mandatory=$true)]
        [long]$SizeBytes,

        [Parameter(Mandatory=$false)]
        [string]$RelativePath
    )

    try {
        # Charger l'historique existant
        $history = @(Get-MWDashboardHistory)

        # Générer le chemin relatif si non fourni
        if (-not $RelativePath) {
            $RelativePath = ".\$ClientName\$PCName"
        }

        # Chercher si cet export existe déjà
        $existingIndex = -1
        for ($i = 0; $i -lt $history.Count; $i++) {
            if ($history[$i].ClientName -eq $ClientName -and $history[$i].PCName -eq $PCName) {
                $existingIndex = $i
                break
            }
        }

        $now = Get-Date -Format 'dd/MM/yyyy HH:mm'

        if ($existingIndex -ge 0) {
            # Mettre à jour l'export existant
            $history[$existingIndex].ExportType = $ExportType
            $history[$existingIndex].ExportDate = $now
            $history[$existingIndex].SizeBytes = $SizeBytes
            $history[$existingIndex].SizeMB = [Math]::Round($SizeBytes / 1MB, 2)
            $history[$existingIndex].SizeGB = [Math]::Round($SizeBytes / 1GB, 2)

            # Si c'est un export principal, réinitialiser la date d'export incrémentiel
            if ($ExportType -eq 'Principal') {
                $history[$existingIndex].LastPrincipalDate = $now
            } else {
                $history[$existingIndex].LastIncrementalDate = $now
            }

            Write-MWLogInfo "Export mis à jour dans l'historique: $ClientName\$PCName"
        }
        else {
            # Créer nouvel export
            $newExport = [PSCustomObject]@{
                ClientName = $ClientName
                PCName = $PCName
                RelativePath = $RelativePath
                ExportType = $ExportType
                ExportDate = $now
                LastPrincipalDate = if ($ExportType -eq 'Principal') { $now } else { '' }
                LastIncrementalDate = if ($ExportType -eq 'Incrementiel') { $now } else { '' }
                SizeBytes = $SizeBytes
                SizeMB = [Math]::Round($SizeBytes / 1MB, 2)
                SizeGB = [Math]::Round($SizeBytes / 1GB, 2)
                ImportDate = ''
                ImportedBy = ''
                ImportedOnPC = ''
            }

            $history += $newExport
            Write-MWLogInfo "Nouvel export ajouté à l'historique: $ClientName\$PCName"
        }

        # Sauvegarder
        return Save-MWDashboardHistory -History $history
    }
    catch {
        Write-MWLogError "Erreur ajout export Dashboard: $_"
        return $false
    }
}

function Update-MWDashboardImport {
    <#
    .SYNOPSIS
    Met à jour les informations d'import dans l'historique Dashboard
    .PARAMETER ClientName
    Nom du client
    .PARAMETER PCName
    Nom du PC
    .PARAMETER ImportedBy
    Nom d'utilisateur ayant fait l'import
    .PARAMETER ImportedOnPC
    Nom du PC sur lequel l'import a été fait
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ClientName,

        [Parameter(Mandatory=$true)]
        [string]$PCName,

        [Parameter(Mandatory=$false)]
        [string]$ImportedBy = $env:USERNAME,

        [Parameter(Mandatory=$false)]
        [string]$ImportedOnPC = $env:COMPUTERNAME
    )

    try {
        $history = @(Get-MWDashboardHistory)

        # Trouver l'export
        $found = $false
        for ($i = 0; $i -lt $history.Count; $i++) {
            if ($history[$i].ClientName -eq $ClientName -and $history[$i].PCName -eq $PCName) {
                $history[$i].ImportDate = Get-Date -Format 'dd/MM/yyyy HH:mm'
                $history[$i].ImportedBy = $ImportedBy
                $history[$i].ImportedOnPC = $ImportedOnPC
                $found = $true
                Write-MWLogInfo "Import enregistré dans l'historique: $ClientName\$PCName"
                break
            }
        }

        if (-not $found) {
            Write-MWLogWarning "Export non trouvé dans l'historique pour mise à jour import: $ClientName\$PCName"
            return $false
        }

        return Save-MWDashboardHistory -History $history
    }
    catch {
        Write-MWLogError "Erreur mise à jour import Dashboard: $_"
        return $false
    }
}

function Remove-MWDashboardExport {
    <#
    .SYNOPSIS
    Supprime un export physiquement ET dans l'historique Dashboard
    .PARAMETER ClientName
    Nom du client
    .PARAMETER PCName
    Nom du PC
    .OUTPUTS
    Boolean indiquant le succès
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ClientName,

        [Parameter(Mandatory=$true)]
        [string]$PCName
    )

    try {
        $exeFolder = Split-Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Parent

        # Chemin du dossier PC
        $pcPath = Join-Path (Join-Path $exeFolder $ClientName) $PCName

        if (-not (Test-Path $pcPath)) {
            Write-MWLogWarning "Dossier PC inexistant: $pcPath"
        }
        else {
            # Supprimer le dossier PC
            Remove-Item -Path $pcPath -Recurse -Force -ErrorAction Stop
            Write-MWLogInfo "Dossier PC supprimé: $pcPath"
        }

        # Vérifier si le dossier Client est vide
        $clientPath = Join-Path $exeFolder $ClientName
        if (Test-Path $clientPath) {
            $remainingItems = Get-ChildItem -Path $clientPath -ErrorAction SilentlyContinue
            if ($remainingItems.Count -eq 0) {
                Remove-Item -Path $clientPath -Force -ErrorAction Stop
                Write-MWLogInfo "Dossier Client supprimé (vide): $clientPath"
            }
        }

        # Supprimer de l'historique Dashboard
        $history = @(Get-MWDashboardHistory)
        $newHistory = @($history | Where-Object {
            -not ($_.ClientName -eq $ClientName -and $_.PCName -eq $PCName)
        })

        Save-MWDashboardHistory -History $newHistory

        Write-MWLogInfo "Export supprimé avec succès: $ClientName\$PCName"
        return $true
    }
    catch {
        Write-MWLogError "Erreur suppression export: $_"
        return $false
    }
}

function Get-MWDashboardStats {
    <#
    .SYNOPSIS
    Calcule les statistiques pour le dashboard depuis l'historique
    .OUTPUTS
    PSCustomObject avec les stats
    #>
    [CmdletBinding()]
    param()

    try {
        $exports = @(Get-MWDashboardHistory)

        if ($exports.Count -eq 0) {
            return [PSCustomObject]@{
                TotalExports = 0
                TotalSizeGB = 0
                LastExportDate = ''
                LastExportClient = 'Aucun'
                LastImportDate = ''
                LastImportClient = 'Aucun'
                ExportsWithImport = 0
                ExportsWithoutImport = 0
            }
        }

        $totalSize = ($exports | Measure-Object -Property SizeBytes -Sum).Sum

        # Dernier export (plus récent)
        $lastExport = $exports | Sort-Object ExportDate -Descending | Select-Object -First 1

        # Dernier import
        $lastImport = $exports | Where-Object { $_.ImportDate -and $_.ImportDate -ne '' } |
                                 Sort-Object ImportDate -Descending |
                                 Select-Object -First 1

        $stats = [PSCustomObject]@{
            TotalExports = $exports.Count
            TotalSizeBytes = $totalSize
            TotalSizeMB = [Math]::Round($totalSize / 1MB, 2)
            TotalSizeGB = [Math]::Round($totalSize / 1GB, 2)
            LastExportDate = if ($lastExport) { $lastExport.ExportDate } else { '' }
            LastExportClient = if ($lastExport) { "$($lastExport.ClientName) - $($lastExport.PCName)" } else { 'Aucun' }
            LastImportDate = if ($lastImport) { $lastImport.ImportDate } else { '' }
            LastImportClient = if ($lastImport) { "$($lastImport.ClientName) - $($lastImport.PCName)" } else { 'Aucun' }
            ExportsWithImport = ($exports | Where-Object { $_.ImportDate -and $_.ImportDate -ne '' }).Count
            ExportsWithoutImport = ($exports | Where-Object { -not $_.ImportDate -or $_.ImportDate -eq '' }).Count
        }

        return $stats
    }
    catch {
        Write-MWLogError "Erreur calcul stats Dashboard: $_"
        return [PSCustomObject]@{
            TotalExports = 0
            TotalSizeGB = 0
            LastExportDate = ''
            LastExportClient = 'Aucun'
            LastImportDate = ''
            LastImportClient = 'Aucun'
            ExportsWithImport = 0
            ExportsWithoutImport = 0
        }
    }
}

function Get-MWExportSize {
    <#
    .SYNOPSIS
    Calcule la taille d'un export (utile pendant la création d'export)
    .PARAMETER ExportPath
    Chemin du dossier d'export
    .OUTPUTS
    Taille en bytes
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExportPath
    )

    try {
        if (-not (Test-Path $ExportPath)) {
            return 0
        }

        $size = (Get-ChildItem -Path $ExportPath -Recurse -File -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum

        if (-not $size) { $size = 0 }

        return $size
    }
    catch {
        Write-MWLogDebug "Erreur calcul taille export: $_"
        return 0
    }
}

# Export des fonctions
Export-ModuleMember -Function @(
    'Get-MWDashboardHistoryPath',
    'Get-MWDashboardHistory',
    'Save-MWDashboardHistory',
    'Add-MWDashboardExport',
    'Update-MWDashboardImport',
    'Remove-MWDashboardExport',
    'Get-MWDashboardStats',
    'Get-MWExportSize'
)
