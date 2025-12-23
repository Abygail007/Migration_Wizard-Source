# ==============================================================================
# DashboardManager.psm1
# Gestion du tableau de bord des exports
# ==============================================================================

function Get-MWExportsList {
    <#
    .SYNOPSIS
    Liste tous les exports MigrationWizard présents sur le disque
    .DESCRIPTION
    Scanne les lecteurs pour trouver les dossiers PCP contenant des exports
    .OUTPUTS
    Array de PSCustomObject avec informations sur chaque export
    #>
    [CmdletBinding()]
    param()

    $exports = @()

    try {
        # Chercher UNIQUEMENT à côté de l'exe (structure: ExeFolder\ClientName\PCName\ExportManifest.json)
        $exeFolder = Split-Path ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName) -Parent
        Write-MWLogInfo "Scan exports dans: $exeFolder"

        # Lister dossiers clients (1er niveau)
        $clientFolders = Get-ChildItem -Path $exeFolder -Directory -ErrorAction SilentlyContinue

        foreach ($clientFolder in $clientFolders) {
            # Skip dossiers système/techniques
            if ($clientFolder.Name -match '^(Tools|Build|Logs|src|\.git)') {
                continue
            }

            # Lister dossiers PC (2ème niveau)
            $pcFolders = Get-ChildItem -Path $clientFolder.FullName -Directory -ErrorAction SilentlyContinue

            foreach ($pcFolder in $pcFolders) {
                $manifestPath = Join-Path $pcFolder.FullName 'ExportManifest.json'

                if (-not (Test-Path $manifestPath)) {
                    continue
                }

                # Simuler $manifestFile pour compatibilité avec le code existant
                $manifestFile = [PSCustomObject]@{
                    FullName = $manifestPath
                    Directory = $pcFolder
                }
                $folder = $manifestFile.Directory
                $manifestPath = $manifestFile.FullName
                $metadataPath = Join-Path $folder.FullName '.metadata.json'

                Write-MWLogDebug "Export trouvé: $($folder.FullName)"

                # Toujours valide si ExportManifest.json existe

                # Lire les métadonnées si elles existent
                $metadata = $null
                if (Test-Path $metadataPath) {
                    try {
                        $metadata = Get-Content $metadataPath -Raw | ConvertFrom-Json
                    }
                    catch {
                        Write-MWLogWarning "Impossible de lire metadata pour $($folder.Name): $($_.Exception.Message)"
                    }
                }

                # Lire ImportMetadata.json si présent
                $importMetadata = $null
                $importMetadataPath = Join-Path $folder.FullName 'ImportMetadata.json'
                if (Test-Path $importMetadataPath) {
                    try {
                        $importMetadata = Get-Content $importMetadataPath -Raw | ConvertFrom-Json
                    }
                    catch {
                        Write-MWLogWarning "Impossible de lire ImportMetadata.json pour $($folder.Name): $($_.Exception.Message)"
                    }
                }

                # Lire le manifest pour obtenir le nom du PC si pas de metadata
                $sourcePC = 'Inconnu'
                if (-not $metadata -or -not $metadata.SourcePC) {
                    try {
                        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                        if ($manifest.ExportMetadata -and $manifest.ExportMetadata.ComputerName) {
                            $sourcePC = $manifest.ExportMetadata.ComputerName
                        }
                    }
                    catch {
                        Write-MWLogDebug "Impossible de lire manifest pour extraire PC: $_"
                    }
                }

                # Calculer la taille du dossier
                $size = 0
                try {
                    $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue |
                             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                }
                catch {
                    Write-MWLogDebug "Erreur calcul taille pour $($folder.Name)"
                }

                # Structure: ExeFolder\ClientName\PCName
                # Ex: D:\MigrationWizard.exe avec D:\JMT\PORT-JMTHOMAS\ExportManifest.json
                # -> ClientName = JMT, PCName = PORT-JMTHOMAS
                $clientName = $clientFolder.Name
                $pcName = $pcFolder.Name

                # Formater les dates en strings pour éviter problèmes WPF binding
                # Utiliser Get-Date pour compatibilité PowerShell compilé
                $exportDateStr = if ($metadata -and $metadata.ExportDate) {
                    try {
                        $dt = [DateTime]$metadata.ExportDate
                        Get-Date $dt -Format 'dd/MM/yyyy HH:mm'
                    } catch {
                        Get-Date $folder.CreationTime -Format 'dd/MM/yyyy HH:mm'
                    }
                } else {
                    Get-Date $folder.CreationTime -Format 'dd/MM/yyyy HH:mm'
                }

                $importDateStr = if ($importMetadata -and $importMetadata.ImportDate) {
                    try {
                        $dt = [DateTime]$importMetadata.ImportDate
                        Get-Date $dt -Format 'dd/MM/yyyy HH:mm'
                    } catch {
                        ''
                    }
                } elseif ($metadata -and $metadata.ImportDate) {
                    try {
                        $dt = [DateTime]$metadata.ImportDate
                        Get-Date $dt -Format 'dd/MM/yyyy HH:mm'
                    } catch {
                        ''
                    }
                } else {
                    ''
                }

                # Créer l'objet export
                $export = [PSCustomObject]@{
                    ClientName = $clientName
                    PCName = $pcName
                    Path = $folder.FullName
                    Drive = $exeFolder.Substring(0, 2)  # Ex: "C:" ou "D:"
                    ExportDate = $exportDateStr
                    ImportDate = $importDateStr
                    ImportedBy = if ($importMetadata -and $importMetadata.ImportedBy) {
                        $importMetadata.ImportedBy
                    } else {
                        ''
                    }
                    ImportedOnPC = if ($importMetadata -and $importMetadata.ImportedOnPC) {
                        $importMetadata.ImportedOnPC
                    } else {
                        ''
                    }
                    SourcePC = if ($metadata -and $metadata.SourcePC) {
                        $metadata.SourcePC
                    } else {
                        $sourcePC
                    }
                    Version = if ($metadata -and $metadata.Version) {
                        $metadata.Version
                    } else {
                        'N/A'
                    }
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

    }
    catch {
        Write-MWLogError "Erreur lors de la recherche des exports: $($_.Exception.Message)"
    }

    return $exports
}

function Save-MWExportMetadata {
    <#
    .SYNOPSIS
    Sauvegarde les métadonnées d'un export
    .PARAMETER ExportPath
    Chemin du dossier d'export
    .PARAMETER Metadata
    Hashtable contenant les métadonnées
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExportPath,

        [Parameter(Mandatory=$true)]
        [hashtable]$Metadata
    )

    try {
        $metadataPath = Join-Path $ExportPath '.metadata.json'

        # Ajouter timestamp si pas présent
        if (-not $Metadata.ContainsKey('ExportDate')) {
            $Metadata['ExportDate'] = (Get-Date -Format 'o')
        }

        # Convertir en JSON et sauvegarder
        $json = $Metadata | ConvertTo-Json -Depth 10
        $json | Out-File -FilePath $metadataPath -Encoding UTF8 -Force

        Write-MWLogDebug "Métadonnées sauvegardées: $metadataPath"

        return $true
    }
    catch {
        Write-MWLogError "Erreur sauvegarde metadata: $($_.Exception.Message)"
        return $false
    }
}

function Update-MWExportMetadata {
    <#
    .SYNOPSIS
    Met à jour les métadonnées d'un export existant
    .PARAMETER ExportPath
    Chemin du dossier d'export
    .PARAMETER Updates
    Hashtable contenant les champs à mettre à jour
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExportPath,

        [Parameter(Mandatory=$true)]
        [hashtable]$Updates
    )

    try {
        $metadataPath = Join-Path $ExportPath '.metadata.json'

        # Lire métadonnées existantes ou créer nouveau
        $metadata = @{}
        if (Test-Path $metadataPath) {
            $existing = Get-Content $metadataPath -Raw | ConvertFrom-Json
            # Convertir en hashtable
            $existing.PSObject.Properties | ForEach-Object { $metadata[$_.Name] = $_.Value }
        }

        # Appliquer les mises à jour
        foreach ($key in $Updates.Keys) {
            $metadata[$key] = $Updates[$key]
        }

        # Sauvegarder
        return Save-MWExportMetadata -ExportPath $ExportPath -Metadata $metadata
    }
    catch {
        Write-MWLogError "Erreur mise à jour metadata: $($_.Exception.Message)"
        return $false
    }
}

function Remove-MWExport {
    <#
    .SYNOPSIS
    Supprime un export du disque
    .PARAMETER ExportPath
    Chemin complet du dossier d'export
    .OUTPUTS
    Boolean indiquant le succès
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExportPath
    )

    try {
        if (-not (Test-Path $ExportPath)) {
            Write-MWLogWarning "Export inexistant: $ExportPath"
            return $false
        }

        # Confirmation implicite si appelé depuis l'UI
        Write-MWLogInfo "Suppression de l'export: $ExportPath"

        Remove-Item -Path $ExportPath -Recurse -Force -ErrorAction Stop

        Write-MWLogInfo "Export supprimé avec succès"
        return $true
    }
    catch {
        Write-MWLogError "Erreur lors de la suppression: $($_.Exception.Message)"
        return $false
    }
}

function Get-MWDashboardStats {
    <#
    .SYNOPSIS
    Calcule les statistiques pour le dashboard
    .PARAMETER Exports
    Liste des exports (de Get-MWExportsList)
    .OUTPUTS
    PSCustomObject avec les stats
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [array]$Exports
    )

    if (-not $Exports) {
        $Exports = @()
    }

    $totalSize = ($Exports | Measure-Object -Property SizeBytes -Sum).Sum

    # Trier par string date (format dd/MM/yyyy HH:mm ne trie pas chronologiquement)
    # On prend juste le premier export trouvé comme "dernier"
    $lastExport = $Exports | Select-Object -First 1
    $lastImport = $Exports | Where-Object { $_.ImportDate -and $_.ImportDate -ne '' } | Select-Object -First 1

    $stats = [PSCustomObject]@{
        TotalExports = $Exports.Count
        TotalSizeBytes = $totalSize
        TotalSizeMB = [Math]::Round($totalSize / 1MB, 2)
        TotalSizeGB = [Math]::Round($totalSize / 1GB, 2)
        LastExportDate = if ($lastExport) { $lastExport.ExportDate } else { '' }
        LastExportClient = if ($lastExport) { $lastExport.ClientName } else { 'Aucun' }
        LastImportDate = if ($lastImport) { $lastImport.ImportDate } else { '' }
        LastImportClient = if ($lastImport) { $lastImport.ClientName } else { 'Aucun' }
        ExportsWithImport = ($Exports | Where-Object { $_.ImportDate -and $_.ImportDate -ne '' }).Count
        ExportsWithoutImport = ($Exports | Where-Object { -not $_.ImportDate -or $_.ImportDate -eq '' }).Count
    }

    return $stats
}

function Format-MWFileSize {
    <#
    .SYNOPSIS
    Formate une taille en bytes en string lisible
    .PARAMETER Bytes
    Taille en bytes
    .OUTPUTS
    String formatée (ex: "1.5 GB")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [long]$Bytes
    )

    if ($Bytes -ge 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    }
    elseif ($Bytes -ge 1MB) {
        return "{0:N2} MB" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -ge 1KB) {
        return "{0:N2} KB" -f ($Bytes / 1KB)
    }
    else {
        return "$Bytes bytes"
    }
}

# Export des fonctions
Export-ModuleMember -Function @(
    'Get-MWExportsList',
    'Save-MWExportMetadata',
    'Update-MWExportMetadata',
    'Remove-MWExport',
    'Get-MWDashboardStats',
    'Format-MWFileSize'
)
