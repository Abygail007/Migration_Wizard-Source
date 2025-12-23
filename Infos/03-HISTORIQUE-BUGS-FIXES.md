# MigrationWizard - Historique Complet des Bugs et Correctifs

## INTRODUCTION

Ce document liste TOUS les bugs rencontrés pendant le développement de MigrationWizard, leurs causes racines, solutions appliquées, et leçons apprises. Chaque bug est documenté avec :
- Symptômes observés
- Logs/erreurs exactes
- Analyse cause racine
- Solution implémentée
- Fichiers modifiés
- Version de correction

---

## BUG #1 : DesktopOK Export Manquant

**Version** : 1.0.21.0 et antérieures
**Corrigé** : 1.0.22.0
**Gravité** : HAUTE (fonctionnalité cassée)

### Symptômes

Lors de l'import, les positions des icônes du bureau ne sont PAS restaurées. Le bureau est restauré mais toutes les icônes sont alignées en haut à gauche.

### Logs Observés

```
2025-12-18 14:25:10 [WARN] Fichier positions DesktopOK introuvable: D:\reherie\PC-530301654\desktop_positions.dok
2025-12-18 14:25:10 [INFO] Restauration bureau sans positions icônes
```

### Investigation

1. **Vérification dossier export** : Le fichier `desktop_positions.dok` est ABSENT
2. **Vérification logs export** : Aucune erreur visible pendant export
3. **Test DesktopOK manuel** : Fonctionne correctement en ligne de commande
4. **Analyse code** : `Get-EmbeddedDesktopOK()` retourne `$null`

### Analyse Cause Racine

**Fichier** : `src/Features/WallpaperDesktop.psm1`, ligne 323-372

**Code bugué** :
```powershell
function Get-EmbeddedDesktopOK {
    try {
        # Vérifier si exécuté depuis dossier Tools
        if ($PSScriptRoot) {
            $toolsPath = Join-Path $PSScriptRoot '..\Tools\DesktopOK.exe'
            if (Test-Path $toolsPath) {
                Write-MWLogInfo "DesktopOK.exe trouvé: $toolsPath"
                return $toolsPath
            }
        }

        # Sinon, extraire depuis base64...
    }
}
```

**Problème** : En mode compilé PS2EXE, `$PSScriptRoot` est VIDE ! Cette variable n'existe que lors de l'exécution d'un script .ps1, pas dans un EXE compilé.

**Résultat** :
- `if ($PSScriptRoot)` → FALSE (variable vide)
- Saute directement à extraction base64
- MAIS le code base64 avait AUSSI un bug (vérification variable inexistante)
- Fonction retourne `$null`
- Export DesktopOK silencieusement skippé

### Solution Appliquée

**Suppression complète vérification `$PSScriptRoot`** :

```powershell
function Get-EmbeddedDesktopOK {
    try {
        # Mode embarqué uniquement (supprimé vérification fichier local)

        # Vérifier variable base64 existe
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
            Write-MWLogWarning "DesktopOK.exe non embarqué (variable DESKTOPOK_BASE64 absente ou vide)"
            return $null
        }

        # Extraire vers %TEMP%\MigrationWizard\
        $tempDir = Join-Path $env:TEMP 'MigrationWizard'
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        $exePath = Join-Path $tempDir 'DesktopOK.exe'

        if (-not (Test-Path $exePath)) {
            Write-MWLogDebug "Extraction DesktopOK.exe depuis base64..."
            Write-MWLogInfo "DesktopOK.exe extrait vers: $exePath"
            $bytes = [Convert]::FromBase64String($base64Data)
            [System.IO.File]::WriteAllBytes($exePath, $bytes)
        }

        return $exePath
    }
    catch {
        Write-MWLogError "Get-EmbeddedDesktopOK : $($_.Exception.Message)"
        return $null
    }
}
```

**Fichiers modifiés** :
- `src/Features/WallpaperDesktop.psm1:323-372`

**Tests** :
- Export avec nouveau build → `desktop_positions.dok` créé ✅
- Import → Positions icônes restaurées ✅

### Leçon Apprise

**IMPORTANT** : `$PSScriptRoot`, `$PSCommandPath`, `$MyInvocation.MyCommand.Path` sont TOUS VIDES en mode compilé PS2EXE. Ne JAMAIS s'en servir pour détecter l'environnement.

**Alternative** : Utiliser `[System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName` pour obtenir le chemin de l'EXE.

---

## BUG #2 : Raccourcis Logicia Path Vide

**Version** : 1.0.21.0 et antérieures
**Corrigé** : 1.0.22.0
**Gravité** : HAUTE (fonctionnalité cassée)

### Symptômes

Lors de l'import, les raccourcis Logicia ne sont PAS ajoutés au bureau public.

### Logs Observés

```
2025-12-18 14:25:15 [ERROR] Get-EmbeddedFile 'Espace Client - Logicia.exe' : Impossible de lier l'argument au paramètre 'Path', car il s'agit d'une chaîne vide.
```

### Investigation

Même problème que Bug #1 : `$PSScriptRoot` vide dans `Get-EmbeddedFile()`.

### Analyse Cause Racine

**Fichier** : `src/Features/WallpaperDesktop.psm1`, ligne 374-420

**Code bugué** :
```powershell
function Get-EmbeddedFile {
    param([string]$FileName)

    try {
        # Vérifier fichier local d'abord
        if ($PSScriptRoot) {
            $toolsPath = Join-Path $PSScriptRoot "..\Tools\$FileName"
            if (Test-Path $toolsPath) {
                return $toolsPath
            }
        }

        # Extraire depuis base64...
    }
}
```

**Même problème** : `$PSScriptRoot` vide → saute vers base64 → code base64 bugué → retourne string vide → erreur PowerShell "Path vide".

### Solution Appliquée

Identique à Bug #1 : suppression complète vérification `$PSScriptRoot`.

```powershell
function Get-EmbeddedFile {
    param([string]$FileName)

    try {
        # Mode embarqué uniquement

        # Construire nom variable : LOGICIA_ESPACE_CLIENT_LOGICIA_EXE_BASE64
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
                    Write-MWLogInfo "Extraction $FileName → $filePath"
                    $bytes = [Convert]::FromBase64String($base64)
                    [System.IO.File]::WriteAllBytes($filePath, $bytes)
                }

                return $filePath
            }
        }

        Write-MWLogWarning "Fichier '$FileName' non embarqué (variable $varName absente ou vide)"
        return $null
    }
    catch {
        Write-MWLogError "Get-EmbeddedFile '$FileName' : $($_.Exception.Message)"
        return $null
    }
}
```

**Fichiers modifiés** :
- `src/Features/WallpaperDesktop.psm1:374-420`

---

## BUG #3 : Raccourcis Options Supplémentaires Supprimés

**Version** : 1.0.22.0 et antérieures
**Corrigé** : 1.0.23.0
**Gravité** : HAUTE (perte de données)

### Symptômes

Utilisateur copie des raccourcis importants via "Options Supplémentaires" (ex: `C:\Raccourcis\Important.lnk` vers `Public\Desktop`). Après import, les raccourcis ont DISPARU du bureau.

### Scénario Exact

1. **Export** :
   - Utilisateur coche `C:\Raccourcis\Important.lnk` dans TreeView Options Supplémentaires
   - Destination : `Public\Desktop\Important.lnk`
   - Export réussit, fichier copié vers `D:\Client\PC\Profile\Public\Desktop\Important.lnk`

2. **Import** :
   - Import démarre
   - `Import-MWUserData` copie `Profile\Public\Desktop\Important.lnk` → `C:\Users\Public\Desktop\Important.lnk` ✅
   - `Import-WallpaperDesktop` appelle `Clear-AllDesktops`
   - `Clear-AllDesktops` SUPPRIME **TOUT** de `C:\Users\Public\Desktop\` ❌
   - Raccourci perdu !

### Logs Observés

```
2025-12-22 10:30:15 [INFO] Copie Public\Desktop : D:\...\Profile\Public\Desktop → C:\Users\Public\Desktop
2025-12-22 10:30:15 [INFO] Robocopy réussi (code 1)
2025-12-22 10:30:16 [INFO] >>> PURGE TOTALE des bureaux <<<
2025-12-22 10:30:16 [INFO] Purge Bureau Public: C:\Users\Public\Desktop
2025-12-22 10:30:16 [INFO] Purge terminée
```

### Analyse Cause Racine

**Fichier** : `src/Core/Profile.psm1`, lignes 238-410

**Ordre d'import INCORRECT** :

```powershell
function Import-MWProfile {
    # ...

    # 1. Import UserData (copie Options Supplémentaires)
    if ($IncludeUserData) {
        Import-MWUserData -SourceFolder $SourceFolder  # Copie raccourcis ✅
    }

    # ... autres imports ...

    # 2. Import WallpaperDesktop (purge bureau)
    if ($IncludeWallpaper -or $IncludeDesktopLayout) {
        Import-WallpaperDesktop -InRoot $SourceFolder  # SUPPRIME raccourcis ❌
    }
}
```

**Explication** :
- `Clear-AllDesktops` fait une purge TOTALE pour éviter duplication icônes
- Mais il supprime AUSSI ce qui vient d'être copié par `Import-MWUserData`
- C'est "un peu con" (citation utilisateur 😄)

### Solution Appliquée

**Inversion ordre imports** :

```powershell
function Import-MWProfile {
    # ...

    Write-MWLogInfo "=== Début Import-MWProfile depuis '$SourceFolder' ==="

    # IMPORTANT : Importer Desktop AVANT UserData pour éviter que Clear-AllDesktops
    # supprime les raccourcis copiés depuis les "Options supplémentaires"
    if ($IncludeWallpaper -or $IncludeDesktopLayout) {
        try {
            Import-WallpaperDesktop -InRoot $SourceFolder -IncludeWallpaper $IncludeWallpaper -IncludeDesktopLayout $IncludeDesktopLayout
        } catch {
            Write-MWLogError "Import fond d'écran/desktop : $($_.Exception.Message)"
        }
    } else {
        Write-MWLogInfo "Fond d'écran/desktop : import ignoré."
    }

    # Maintenant UserData (APRES purge bureau)
    if ($IncludeUserData) {
        try {
            Import-MWUserData -SourceFolder $SourceFolder
            # ... réparation raccourcis ...
        } catch {
            Write-MWLogError "Import données utilisateur : $($_.Exception.Message)"
        }
    }

    # ... autres imports ...
}
```

**Nouvel ordre logique** :
1. **Import-WallpaperDesktop** :
   - `Clear-AllDesktops` → Purge TOTALE
   - `Restore-DesktopContent` → Restaure depuis `Desktop-User` et `Desktop-Public` **de l'export**
   - `Import-DesktopPositions` → DesktopOK
   - `Add-LogiciaShortcuts` → Raccourcis Logicia

2. **Import-MWUserData** :
   - Copie dossiers Profile (Documents, Images, etc.)
   - Copie dossiers Public (APRES purge, donc pas de conflit)
   - **Copie Options Supplémentaires** (APRES purge, donc préservés)

**Fichiers modifiés** :
- `src/Core/Profile.psm1:267-277` (déplacé Import-WallpaperDesktop avant Import-MWUserData)
- `src/Core/Profile.psm1:376-384` (supprimé ancien appel Import-WallpaperDesktop)

**Tests** :
- Export avec raccourci dans Options Supplémentaires → copié ✅
- Import → Raccourci présent sur bureau ✅

---

## BUG #4 : Dashboard DataGrid Erreur Binding

**Version** : 1.0.23.0-1.0.23.2
**Corrigé** : 1.0.23.3
**Gravité** : CRITIQUE (crash application)

### Symptômes

Au démarrage de l'application, Dashboard affiche erreur :

```
Exception lors de la définition de « ItemsSource » :
« Impossible de convertir la valeur « @{ClientName=reherie; PCName=PC-530301654; Path=D:\reherie\PC-530301654; ...} » du type « System.Management.Automation.PSCustomObject » en type « System.Collections.IEnumerable ».
```

Puis :
```
Le traitement du répartiteur a été suspendu, mais les messages continuent à être traités.
```

### Investigation

**Logs** :
```
2025-12-22 11:15:35 [INFO] Scan exports dans: D:\
2025-12-22 11:15:35 [DEBUG] Export trouvé: D:\reherie\PC-530301654
2025-12-22 11:15:39 [INFO] Trouvé 1 export(s) MigrationWizard
2025-12-22 11:15:39 [INFO] Dashboard rafraîchi: 1 export(s) trouvé(s)
2025-12-22 11:15:39 [INFO] Dashboard initialisé
```

→ Export détecté correctement, mais crash au binding DataGrid.

### Analyse Cause Racine #1 : PowerShell Array Unroll

**Fichier** : `src/UI/MigrationWizard.UI.psm1:692`

**Code bugué** :
```powershell
$exports = Get-MWExportsList
$dgDashExports.ItemsSource = $exports
```

**Problème** : PowerShell a un comportement bizarre appelé "array unrolling". Quand `$exports` contient UN SEUL élément, PowerShell "déroule" le tableau et passe l'objet DIRECTEMENT au lieu du tableau.

**Résultat** :
- WPF DataGrid attend `IEnumerable` (liste)
- Reçoit `PSCustomObject` (objet unique)
- Erreur : "Impossible de convertir PSCustomObject en IEnumerable"

**Solution #1** :
```powershell
$exports = @(Get-MWExportsList)  # Force array même avec 1 élément
```

### Analyse Cause Racine #2 : ObservableCollection Incompatible

Même avec `@()`, erreur persiste. Nouvelle tentative :

**Code tenté** :
```powershell
$observableCollection = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
foreach ($export in $exports) {
    $observableCollection.Add($export)
}
$dgDashExports.ItemsSource = $observableCollection
```

**Résultat** : Même erreur dispatcher suspendu.

**Problème** : PS2EXE ne gère pas bien `ObservableCollection[Object]` en mode compilé.

**Solution #2** :
```powershell
# Utiliser ArrayList au lieu de ObservableCollection
$arrayList = New-Object System.Collections.ArrayList
foreach ($export in $exports) {
    [void]$arrayList.Add($export)
}
$dgDashExports.ItemsSource = $arrayList
```

**Fichiers modifiés** :
- `src/UI/MigrationWizard.UI.psm1:692-716`

---

## BUG #5 : DateTime.ToString() Surcharge Introuvable

**Version** : 1.0.23.3-1.0.23.4
**Corrigé** : 1.0.23.5
**Gravité** : CRITIQUE (crash application)

### Symptômes

Même problème que Bug #4, mais avec erreur différente :

```
Surcharge introuvable pour « ToString » et le nombre d'arguments « 1 ».
```

Puis dispatcher suspendu.

### Investigation

**Fichier** : `src/UI/DashboardManager.psm1:113`

**Code bugué** :
```powershell
$dt = [DateTime]$metadata.ExportDate
$exportDateStr = $dt.ToString('dd/MM/yyyy HH:mm')
```

**Problème** : En PowerShell compilé PS2EXE, `.ToString(format)` n'est PAS SUPPORTE ! La surcharge avec format string n'existe pas dans le contexte compilé.

### Tentative #1 : Format Operator

```powershell
$dt = [DateTime]$metadata.ExportDate
$exportDateStr = "{0:dd/MM/yyyy HH:mm}" -f $dt
```

**Résultat** : Même erreur ! Le `-f` operator ne fonctionne pas non plus dans certains contextes compilés.

### Solution Finale : Get-Date

```powershell
$dt = [DateTime]$metadata.ExportDate
$exportDateStr = Get-Date $dt -Format 'dd/MM/yyyy HH:mm'
```

**Pourquoi ça marche** : `Get-Date` est un cmdlet natif PowerShell, pas une méthode .NET. Il fonctionne dans TOUS les contextes.

**Fichiers modifiés** :
- `src/UI/DashboardManager.psm1:99-139` (toutes les conversions dates)

### Leçon Apprise

**IMPORTANT** : En PowerShell compilé PS2EXE, éviter :
- `.ToString(format)` → Utiliser `Get-Date -Format`
- `"{0:format}" -f $value` → Utiliser `Get-Date -Format`
- Préférer cmdlets natifs PowerShell aux méthodes .NET

---

## BUG #6 : DataGrid StringFormat sur Valeur Null

**Version** : 1.0.23.0-1.0.23.4
**Corrigé** : 1.0.23.5
**Gravité** : MOYENNE (erreur WPF)

### Symptômes

Dispatcher suspendu même après corrections précédentes.

### Investigation

**Fichier** : `src/UI/MigrationWizard.xaml:298`

**XAML bugué** :
```xaml
<DataGridTextColumn Header="Date Import"
                    Binding="{Binding ImportDate, StringFormat='dd/MM/yyyy HH:mm'}"
                    Width="140"/>
```

**Objet créé** :
```powershell
$export = [PSCustomObject]@{
    ImportDate = $null  # Pour exports non importés
}
```

**Problème** : WPF `StringFormat` ne peut PAS gérer `$null`. Erreur de conversion.

### Solution

**Convertir dates en strings AVANT création objet** :

```powershell
# Formater date AVANT
$importDateStr = if ($importMetadata -and $importMetadata.ImportDate) {
    $dt = [DateTime]$importMetadata.ImportDate
    Get-Date $dt -Format 'dd/MM/yyyy HH:mm'
} else {
    ''  # String vide au lieu de $null
}

# Créer objet avec string
$export = [PSCustomObject]@{
    ImportDate = $importDateStr  # String, pas DateTime
}
```

**XAML simplifié** :
```xaml
<DataGridTextColumn Header="Date Import"
                    Binding="{Binding ImportDate}"
                    Width="140"/>
```

**Bonus** : Remplacer TOUS les `$null` par `''` pour éviter problèmes WPF binding.

**Fichiers modifiés** :
- `src/UI/DashboardManager.psm1:110-162` (conversion dates)
- `src/UI/MigrationWizard.xaml:297-298` (suppression StringFormat)

---

## BUG #7 : Colonnes DataGrid Non Redimensionnables

**Version** : 1.0.23.0-1.0.23.4
**Corrigé** : 1.0.23.5
**Gravité** : BASSE (UX)

### Symptômes

Utilisateur ne peut PAS redimensionner colonnes Dashboard en glissant séparateurs. Doit minimiser/maximiser fenêtre pour voir changement.

### Investigation

**Fichier** : `src/UI/MigrationWizard.xaml:277`

**XAML incomplet** :
```xaml
<DataGrid Name="dgDashExports"
          AutoGenerateColumns="False"
          IsReadOnly="True"
          CanUserAddRows="False"
          CanUserDeleteRows="False"
          CanUserResizeRows="False"
          SelectionMode="Single">
```

**Manque** : `CanUserResizeColumns="True"` (par défaut True, mais virtualisation peut casser)

### Solution

**Ajout propriétés WPF** :

```xaml
<DataGrid Name="dgDashExports"
          AutoGenerateColumns="False"
          IsReadOnly="True"
          CanUserAddRows="False"
          CanUserDeleteRows="False"
          CanUserResizeRows="False"
          CanUserResizeColumns="True"              <!-- AJOUTE -->
          ColumnHeaderHeight="32"                  <!-- AJOUTE (facilite clic séparateur) -->
          SelectionMode="Single"
          EnableColumnVirtualization="False"       <!-- AJOUTE (désactive virtualisation) -->
          VirtualizingPanel.IsVirtualizing="False"> <!-- AJOUTE -->
```

**Colonnes** :
```xaml
<DataGridTextColumn Header="Client"
                    Binding="{Binding ClientName}"
                    Width="150"
                    CanUserResize="True"/>  <!-- AJOUTE sur chaque colonne -->
```

**Fichiers modifiés** :
- `src/UI/MigrationWizard.xaml:277-301`

---

## STATISTIQUES BUGS

**Total bugs critiques** : 7
**Bugs cassant application** : 3 (Bug #4, #5, #6)
**Bugs perte données** : 1 (Bug #3)
**Bugs fonctionnalité cassée** : 2 (Bug #1, #2)
**Bugs UX** : 1 (Bug #7)

**Causes principales** :
1. **PS2EXE limitations** : 5 bugs (71%)
   - `$PSScriptRoot` vide
   - `.ToString()` non supporté
   - `-f` operator problématique
   - Collections .NET incompatibles
   - Array unrolling

2. **WPF binding** : 2 bugs (29%)
   - StringFormat sur null
   - Virtualisation colonnes

**Leçons clés** :
- TOUJOURS tester en mode compilé, PAS seulement script .ps1
- Préférer cmdlets PowerShell natifs aux méthodes .NET
- Éviter `$null` dans binding WPF, utiliser `''`
- ArrayList > ObservableCollection pour PS2EXE
- Ordre d'opérations critique (Import Desktop avant UserData)

---

**FIN DU DOCUMENT 03-HISTORIQUE-BUGS-FIXES.md**
