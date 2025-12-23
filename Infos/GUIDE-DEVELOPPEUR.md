# MigrationWizard - Guide Développeur

**Guide complet pour reprendre le développement du projet**

Version : 1.0.23.10
Date : 2025-12-23

---

## TABLE DES MATIERES

1. [Démarrage Rapide](#1-démarrage-rapide)
2. [Structure du Projet](#2-structure-du-projet)
3. [Environnement de Développement](#3-environnement-de-développement)
4. [Workflow de Développement](#4-workflow-de-développement)
5. [Compiler le Projet](#5-compiler-le-projet)
6. [Tester l'Application](#6-tester-lapplication)
7. [Ajouter une Nouvelle Feature](#7-ajouter-une-nouvelle-feature)
8. [Débogage](#8-débogage)
9. [Contraintes et Pièges PS2EXE](#9-contraintes-et-pièges-ps2exe)
10. [Git et Synchronisation GitHub](#10-git-et-synchronisation-github)
11. [Versionning et Releases](#11-versionning-et-releases)
12. [FAQ Développeur](#12-faq-développeur)

---

## 1. DÉMARRAGE RAPIDE

### 1.1 Prérequis

- **Windows 10/11** (64-bit)
- **PowerShell 5.1+** (préinstallé sur Windows 10/11)
- **Visual Studio Code** (recommandé) avec extension PowerShell
- **Git** pour gestion de version
- **Module PS2EXE** pour compilation :
  ```powershell
  Install-Module -Name ps2exe -Scope CurrentUser
  ```

### 1.2 Cloner le Projet

```powershell
cd C:\Users\[VotreNom]\Documents\Creation\MigrationWizard
git clone https://github.com/Abygail007/Migration_Wizard-Source.git source
```

### 1.3 Première Compilation

```powershell
cd C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\source
.\Tools\Build-PortableExe.ps1 -Version "1.0.23.11" -IncludeRZGet
```

L'EXE sera généré dans :
```
C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\MigrationWizard-Exe\MigrationWizard.exe
```

### 1.4 Tester l'EXE

Double-cliquer sur `MigrationWizard.exe` pour lancer l'application.

---

## 2. STRUCTURE DU PROJET

```
C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\
│
├── source\                           ← Dépôt Git privé (toutes les sources)
│   ├── src\                          ← Code source
│   │   ├── Core\                     ← Modules core (moteur)
│   │   │   ├── Bootstrap.psm1        ← Initialisation globale
│   │   │   ├── Profile.psm1          ← Orchestrateur export/import
│   │   │   ├── Export.psm1           ← Logique export
│   │   │   ├── FileCopy.psm1         ← Wrapper Robocopy
│   │   │   ├── DataFolders.psm1      ← Manifest dossiers
│   │   │   ├── OneDrive.psm1         ← Résolution chemins OneDrive
│   │   │   └── Applications.psm1     ← Détection applications
│   │   │
│   │   ├── Features\                 ← Modules fonctionnels
│   │   │   ├── UserData.psm1         ← Export/import dossiers utilisateur
│   │   │   ├── Wifi.psm1             ← Profils Wi-Fi
│   │   │   ├── Printers.psm1         ← Imprimantes
│   │   │   ├── NetworkDrives.psm1    ← Lecteurs réseau
│   │   │   ├── Browsers.psm1         ← Chrome/Firefox/Edge
│   │   │   ├── Outlook.psm1          ← Outlook (PST, signatures)
│   │   │   ├── WallpaperDesktop.psm1 ← Bureau et fond d'écran
│   │   │   ├── TaskbarStart.psm1     ← Barre des tâches et menu Démarrer
│   │   │   ├── QuickAccess.psm1      ← Accès rapide Explorateur
│   │   │   └── RDP.psm1              ← Connexions RDP
│   │   │
│   │   ├── UI\                       ← Interface utilisateur
│   │   │   ├── MigrationWizard.xaml  ← Interface WPF (XML)
│   │   │   ├── MigrationWizard.UI.psm1  ← Event handlers XAML
│   │   │   ├── UINavigation.psm1     ← Navigation entre pages
│   │   │   ├── UIValidation.psm1     ← Validation inputs
│   │   │   ├── TreeBuilder.psm1      ← Arborescence dossiers
│   │   │   ├── DashboardManager.psm1 ← Tableau de bord
│   │   │   ├── ClientSelector.psm1   ← Sélection client
│   │   │   └── ManifestManager.psm1  ← Lecture manifests JSON
│   │   │
│   │   ├── Modules\                  ← Modules transverses
│   │   │   ├── MW.Logging.psm1       ← Système de logs
│   │   │   ├── BrowserDetection.psm1 ← Détection profils navigateurs
│   │   │   ├── SummaryBuilder.psm1   ← Génération résumés
│   │   │   └── SnakeGame.psm1        ← Easter egg (jeu Snake)
│   │   │
│   │   └── Assets\                   ← Assets (images base64)
│   │       ├── MW.Logo.Base64.ps1    ← Logo Logicia (base64)
│   │       └── MW.NyanCat.Base64.ps1 ← Nyan Cat animation (base64)
│   │
│   ├── Tools\                        ← Outils de build
│   │   ├── Build-PortableExe.ps1     ← Script de compilation principal
│   │   ├── DesktopOK_x64.exe         ← Outil DesktopOK (positions icônes)
│   │   ├── RZGet.exe                 ← Gestionnaire téléchargement Logicia
│   │   ├── Espace Client - Logicia.exe  ← Raccourci Espace Client
│   │   └── Telemaintenance Logicia.exe  ← Raccourci Télémaintenance
│   │
│   ├── Infos\                        ← Documentation
│   │   ├── README.md                 ← Description publique
│   │   ├── DOCUMENTATION-TECHNIQUE.md ← Architecture complète
│   │   ├── GUIDE-DEVELOPPEUR.md      ← Ce fichier !
│   │   ├── SYNC_GITHUB.txt           ← Guide synchro GitHub
│   │   ├── 01-VUE-ENSEMBLE.md        ← Vue d'ensemble détaillée
│   │   ├── 02-ARCHITECTURE-TECHNIQUE.md  ← Architecture détaillée
│   │   ├── 03-HISTORIQUE-BUGS-FIXES.md   ← Bugs corrigés
│   │   └── 04-CHANGELOG-DETAILLE.md  ← Historique versions
│   │
│   ├── Build\                        ← Dossier build (temporaire, ignoré par git)
│   │   └── MigrationWizard.Merged.ps1  ← Script fusionné (temporaire)
│   │
│   ├── .gitignore                    ← Ignore Build/ et fichiers temporaires
│   ├── .git\                         ← Dépôt Git local
│   └── logo-logicia2.ico             ← Icône de l'application
│
└── MigrationWizard-Exe\              ← Dépôt Git public (EXE uniquement)
    ├── MigrationWizard.exe           ← Exécutable compilé
    ├── .git\                         ← Dépôt Git séparé
    └── README.md                     ← Instructions utilisateur

```

### 2.1 Rôles des Dossiers

- **`source/`** : Code source complet (dépôt privé GitHub)
- **`source/src/`** : Tout le code PowerShell modulaire
- **`source/Tools/`** : Scripts de build + binaires à embarquer
- **`source/Infos/`** : Documentation complète
- **`source/Build/`** : Fichiers temporaires de compilation (ignorés par git)
- **`MigrationWizard-Exe/`** : Dépôt public GitHub (contient uniquement l'EXE final)

---

## 3. ENVIRONNEMENT DE DÉVELOPPEMENT

### 3.1 Visual Studio Code (Recommandé)

**Extensions recommandées** :
1. **PowerShell** (Microsoft) - Syntax highlighting, IntelliSense, debugging
2. **GitLens** - Visualisation Git avancée
3. **Markdown All in One** - Édition documentation

**Configuration** (`.vscode/settings.json`) :

```json
{
  "powershell.codeFormatting.preset": "OTBS",
  "files.encoding": "utf8",
  "files.eol": "\n",
  "powershell.scriptAnalysis.enable": true,
  "editor.formatOnSave": true
}
```

### 3.2 PowerShell ISE (Alternative)

**Avantages** :
- Préinstallé sur Windows
- Débogage PowerShell intégré

**Inconvénients** :
- Moins moderne que VS Code
- Pas de support Git intégré

### 3.3 Outils de Débogage

**PSScriptAnalyzer** : Linter PowerShell

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
Invoke-ScriptAnalyzer -Path .\src\Core\Profile.psm1
```

---

## 4. WORKFLOW DE DÉVELOPPEMENT

### 4.1 Cycle de Développement Standard

```
1. MODIFICATION DU CODE
   ├─> Éditer les fichiers .psm1 dans src/
   └─> Tester la syntaxe PowerShell

2. COMPILATION
   ├─> Lancer Build-PortableExe.ps1 avec nouveau numéro de version
   └─> Vérifier que l'EXE est créé sans erreur

3. TEST
   ├─> Exécuter l'EXE compilé
   ├─> Tester l'export sur un profil test
   ├─> Tester l'import sur une VM ou machine test
   └─> Vérifier les logs dans %USERPROFILE%\MigrationWizard\Logs\

4. DEBUG (si erreurs)
   ├─> Lire les logs
   ├─> Ajouter des Write-MWLogDebug dans le code
   ├─> Recompiler avec -KeepMergedScript pour inspecter le script fusionné
   └─> Corriger le code

5. COMMIT GIT
   ├─> git add -A
   ├─> git commit -m "Description des changements"
   └─> git push -u source main

6. RELEASE (si version stable)
   ├─> Copier MigrationWizard.exe vers dépôt public
   ├─> Commit et push vers dépôt public
   └─> Créer tag de version sur GitHub
```

### 4.2 Bonnes Pratiques

1. **Commiter souvent** : Petits commits fréquents plutôt que gros commits rares
2. **Messages de commit clairs** : "Fix bug export Wi-Fi" plutôt que "update"
3. **Tester avant de commiter** : Compiler et tester avant chaque commit
4. **Incrémenter la version** : Toujours changer le numéro de version à chaque build
5. **Documenter les changements** : Mettre à jour `04-CHANGELOG-DETAILLE.md`

---

## 5. COMPILER LE PROJET

### 5.1 Compilation Standard

```powershell
cd C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\source
.\Tools\Build-PortableExe.ps1 -Version "1.0.23.11" -IncludeRZGet
```

**Paramètres** :
- `-Version` : Numéro de version (format X.Y.Z.W)
- `-IncludeRZGet` : Inclure RZGet.exe dans l'EXE (optionnel)
- `-KeepMergedScript` : Conserver le script fusionné pour debug (optionnel)

### 5.2 Compilation avec Debug

```powershell
.\Tools\Build-PortableExe.ps1 -Version "1.0.23.11" -IncludeRZGet -KeepMergedScript
```

Le script fusionné sera conservé dans :
```
source\Build\MigrationWizard.Merged.ps1
```

**Utilité** : Inspecter le code fusionné pour détecter des problèmes de fusion ou de syntaxe.

### 5.3 Vérifier la Compilation

```powershell
# Vérifier que l'EXE existe
Test-Path C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\MigrationWizard-Exe\MigrationWizard.exe

# Vérifier la version
(Get-Item C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\MigrationWizard-Exe\MigrationWizard.exe).VersionInfo.FileVersion
```

### 5.4 Erreurs de Compilation Courantes

**Erreur : "ps2exe module not found"**
```powershell
Install-Module -Name ps2exe -Scope CurrentUser
Import-Module ps2exe
```

**Erreur : "Cannot bind parameter 'inputFile'"**
→ Vérifier que le chemin vers `MigrationWizard.Merged.ps1` est correct

**Erreur : "Syntax error in merged script"**
→ Utiliser `-KeepMergedScript` et inspecter `Build\MigrationWizard.Merged.ps1`

---

## 6. TESTER L'APPLICATION

### 6.1 Environnement de Test Recommandé

**VM Windows 10/11** :
- Créer une VM avec Hyper-V ou VirtualBox
- Installer Windows 10/11 fresh
- Créer un profil utilisateur test avec données variées
- Tester export puis import

### 6.2 Scénario de Test Complet

#### Test Export

1. Lancer `MigrationWizard.exe`
2. Cliquer "Export"
3. Sélectionner tous les dossiers utilisateur
4. Cocher toutes les features (Wi-Fi, Printers, Browsers, etc.)
5. Entrer un nom de client et PC
6. Cliquer "Lancer"
7. Vérifier que l'export se termine sans erreur
8. Vérifier les logs dans `%USERPROFILE%\MigrationWizard\Logs\`
9. Vérifier le dossier export dans `D:\[Client]\[PC]\`
10. Vérifier `ExportManifest.json` est bien créé

#### Test Import

1. Copier le dossier export vers une VM ou autre PC
2. Lancer `MigrationWizard.exe`
3. Vérifier que le Dashboard affiche l'export
4. Cliquer "Importer"
5. Sélectionner les éléments à importer
6. Cliquer "Lancer"
7. Vérifier que l'import se termine sans erreur
8. Vérifier que les fichiers sont bien restaurés (Bureau, Documents, etc.)
9. Vérifier que les raccourcis fonctionnent
10. Vérifier que le fond d'écran est restauré
11. Vérifier que les profils Wi-Fi sont ajoutés
12. Vérifier `ImportMetadata.json` est créé

### 6.3 Logs de Test

**Emplacement** :
```
%USERPROFILE%\MigrationWizard\Logs\MigrationWizard_YYYYMMDD_[HOSTNAME].log
```

**Analyser les logs** :
```powershell
# Filtrer les erreurs
Get-Content $env:USERPROFILE\MigrationWizard\Logs\MigrationWizard_*.log | Select-String "ERROR"

# Filtrer les warnings
Get-Content $env:USERPROFILE\MigrationWizard\Logs\MigrationWizard_*.log | Select-String "WARNING"
```

---

## 7. AJOUTER UNE NOUVELLE FEATURE

### 7.1 Étapes

#### 1. Créer le Module

**Fichier** : `src/Features/MaNouvelleFonctionnalite.psm1`

```powershell
# src/Features/MaNouvelleFonctionnalite.psm1

function Export-MWMaFonctionnalite {
    param([string]$ExportPath)

    Write-MWLog "Exporting MaFonctionnalite..."

    try {
        # Logique d'export
        $sourcePath = "C:\MesData\MaFonctionnalite"
        $destPath = "$ExportPath\MaFonctionnalite"

        if (Test-Path $sourcePath) {
            Copy-MWDirectory -Source $sourcePath -Destination $destPath
            Write-MWLogSuccess "MaFonctionnalite exported successfully"
            return $true
        } else {
            Write-MWLogWarning "MaFonctionnalite source path not found"
            return $false
        }
    } catch {
        Write-MWLogError "Failed to export MaFonctionnalite: $($_.Exception.Message)"
        return $false
    }
}

function Import-MWMaFonctionnalite {
    param([string]$ExportPath)

    Write-MWLog "Importing MaFonctionnalite..."

    try {
        # Logique d'import
        $sourcePath = "$ExportPath\MaFonctionnalite"
        $destPath = "C:\MesData\MaFonctionnalite"

        if (Test-Path $sourcePath) {
            Copy-MWDirectory -Source $sourcePath -Destination $destPath
            Write-MWLogSuccess "MaFonctionnalite imported successfully"
            return $true
        } else {
            Write-MWLogWarning "MaFonctionnalite not found in export"
            return $false
        }
    } catch {
        Write-MWLogError "Failed to import MaFonctionnalite: $($_.Exception.Message)"
        return $false
    }
}

Export-ModuleMember -Function Export-MWMaFonctionnalite, Import-MWMaFonctionnalite
```

#### 2. Ajouter à l'Ordre de Build

**Fichier** : `Tools/Build-PortableExe.ps1`

```powershell
$modulesOrder = @(
    # ... modules existants ...
    'src/Features/MaNouvelleFonctionnalite.psm1',  # ← AJOUTER ICI
    # ... autres modules ...
)
```

#### 3. Ajouter UI (Checkbox dans XAML)

**Fichier** : `src/UI/MigrationWizard.xaml`

```xaml
<!-- Ajouter dans la section Features -->
<CheckBox Name="chkMaFonctionnalite" Content="Ma Nouvelle Fonctionnalité" />
```

#### 4. Intégrer dans l'Orchestrateur

**Fichier** : `src/Core/Profile.psm1`

```powershell
function Export-MWProfile {
    # ... code existant ...

    # Ajouter après les autres features
    if ($Selection.MaFonctionnalite) {
        Export-MWMaFonctionnalite -ExportPath $ExportPath
    }
}

function Import-MWProfile {
    # ... code existant ...

    # Ajouter après les autres features
    if ($Selection.MaFonctionnalite) {
        Import-MWMaFonctionnalite -ExportPath $ExportPath
    }
}
```

#### 5. Compiler et Tester

```powershell
.\Tools\Build-PortableExe.ps1 -Version "1.0.24.0" -IncludeRZGet
```

---

## 8. DÉBOGAGE

### 8.1 Logs de Debug

**Ajouter des logs de debug dans le code** :

```powershell
Write-MWLogDebug "Variable \$myVar = $myVar"
Write-MWLogDebug "Entering function Export-MWMaFonctionnalite"
```

### 8.2 Script Fusionné

**Inspecter le script fusionné** :

```powershell
.\Tools\Build-PortableExe.ps1 -Version "1.0.23.11" -IncludeRZGet -KeepMergedScript
code .\Build\MigrationWizard.Merged.ps1
```

**Rechercher** :
- Fonctions dupliquées
- Export-ModuleMember non supprimés
- Erreurs de syntaxe

### 8.3 Tester le Script Fusionné Directement

```powershell
# Lancer le script fusionné sans compiler
powershell -ExecutionPolicy Bypass -File .\Build\MigrationWizard.Merged.ps1
```

**Avantages** :
- Voir les erreurs PowerShell en direct
- Plus rapide que compiler l'EXE

### 8.4 PowerShell Debugger

**VS Code avec extension PowerShell** :

1. Ouvrir un fichier .psm1
2. Mettre des breakpoints (clic dans la marge)
3. Appuyer F5 pour lancer le debugger
4. Inspecter les variables en temps réel

---

## 9. CONTRAINTES ET PIÈGES PS2EXE

### 9.1 $PSScriptRoot est Vide

**❌ Ne fonctionne pas en EXE** :
```powershell
$configPath = Join-Path $PSScriptRoot 'config.json'
```

**✅ Solution** :
```powershell
$configPath = "$env:USERPROFILE\MigrationWizard\config.json"
```

### 9.2 .ToString() avec Format

**❌ Ne fonctionne pas en EXE** :
```powershell
$date = Get-Date
$dateStr = $date.ToString('yyyy-MM-dd HH:mm:ss')
```

**✅ Solution** :
```powershell
$dateStr = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
```

### 9.3 ObservableCollection

**❌ Cause des erreurs en EXE** :
```powershell
$items = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
```

**✅ Solution** :
```powershell
$items = [System.Collections.ArrayList]::new()
```

### 9.4 Encoding UTF-8 sans BOM

**Important** : Le script fusionné doit être en UTF-8 **sans BOM**.

Le script de build gère ça automatiquement :
```powershell
$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($mergedScript, $mergedContent, $utf8NoBom)
```

### 9.5 Binaires Embarqués

**Toujours utiliser base64** pour embarquer des fichiers binaires (.exe, .jpg, etc.).

**Build time** :
```powershell
$bytes = [IO.File]::ReadAllBytes('Tools/DesktopOK_x64.exe')
$base64 = [Convert]::ToBase64String($bytes)
# Injecter $base64 dans le script fusionné
```

**Runtime** :
```powershell
$bytes = [Convert]::FromBase64String($script:DESKTOPOK_BASE64)
[IO.File]::WriteAllBytes("$env:TEMP\DesktopOK.exe", $bytes)
```

---

## 10. GIT ET SYNCHRONISATION GITHUB

### 10.1 Configuration Git

```powershell
git config --global user.name "Votre Nom"
git config --global user.email "votre.email@example.com"
```

### 10.2 Workflow Git Standard

#### Pousser les Sources (Dépôt Privé)

```powershell
cd C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\source

# Vérifier l'état
git status

# Ajouter tous les fichiers modifiés
git add -A

# Committer avec message
git commit -m "Fix bug export Wi-Fi"

# Pousser vers GitHub (dépôt privé)
git push -u source main
```

#### Pousser l'EXE (Dépôt Public)

```powershell
cd C:\Users\[VotreNom]\Documents\Creation\MigrationWizard\MigrationWizard-Exe

# Ajouter l'EXE
git add MigrationWizard.exe

# Committer
git commit -m "Release v1.0.23.11"

# Pousser vers GitHub (dépôt public, force push)
git push -u origin main -f
```

**Note** : Le push forcé (`-f`) est normal pour le dépôt public car on veut uniquement l'EXE, pas l'historique complet.

### 10.3 Configurer les Remotes

**Dépôt source** :
```powershell
cd source
git remote add source https://github.com/Abygail007/Migration_Wizard-Source.git
```

**Dépôt EXE** :
```powershell
cd MigrationWizard-Exe
git remote add origin https://github.com/Abygail007/Migration_Wizard.git
```

### 10.4 .gitignore

**Fichier `source/.gitignore`** :

```
# Build artifacts
Build/
*.Merged.ps1

# Logs
*.log

# VS Code
.vscode/

# Windows
Thumbs.db
desktop.ini
```

**Pourquoi ignorer `Build/`** : Ce dossier contient des fichiers temporaires qui n'ont pas besoin d'être versionnés.

---

## 11. VERSIONNING ET RELEASES

### 11.1 Schéma de Version

**Format** : `X.Y.Z.W`

- **X (Major)** : Changements majeurs incompatibles
- **Y (Minor)** : Nouvelles fonctionnalités compatibles
- **Z (Patch)** : Corrections de bugs
- **W (Build)** : Numéro de build incrémental

**Exemples** :
- `1.0.23.0` → Bug fix (Z incrémenté)
- `1.0.24.0` → Nouvelle feature mineure
- `1.1.0.0` → Nouvelle feature majeure
- `2.0.0.0` → Refonte complète (incompatible avec v1.x)

### 11.2 Créer une Release

1. **Compiler avec nouveau numéro de version** :
   ```powershell
   .\Tools\Build-PortableExe.ps1 -Version "1.0.24.0" -IncludeRZGet
   ```

2. **Tester l'EXE** (export + import complet)

3. **Mettre à jour CHANGELOG** :
   - Éditer `Infos/04-CHANGELOG-DETAILLE.md`
   - Ajouter les changements de cette version

4. **Commit des sources** :
   ```powershell
   git add -A
   git commit -m "Release v1.0.24.0: [Description]"
   git push -u source main
   ```

5. **Créer tag Git** :
   ```powershell
   git tag -a v1.0.24.0 -m "Release v1.0.24.0"
   git push source v1.0.24.0
   ```

6. **Publier l'EXE** :
   ```powershell
   cd MigrationWizard-Exe
   git add MigrationWizard.exe
   git commit -m "Release v1.0.24.0"
   git push -u origin main -f
   ```

7. **Créer Release GitHub** (optionnel) :
   - Aller sur GitHub → Releases → New Release
   - Tag : `v1.0.24.0`
   - Title : `MigrationWizard v1.0.24.0`
   - Description : Copier le changelog
   - Attacher `MigrationWizard.exe`

---

## 12. FAQ DÉVELOPPEUR

### Q1 : Comment ajouter un nouveau binaire embarqué ?

**Réponse** :
1. Placer le fichier dans `Tools/` (ex: `Tools/MonOutil.exe`)
2. Éditer `Tools/Build-PortableExe.ps1` :
   ```powershell
   # Après les autres binaires
   $monOutilPath = 'Tools/MonOutil.exe'
   $monOutilBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($monOutilPath))
   $mergedContent += @"

   # === MON OUTIL EMBEDDED (BASE64) ===
   `$script:MON_OUTIL_BASE64 = '$monOutilBase64'
   "@
   ```
3. Utiliser dans le code :
   ```powershell
   $bytes = [Convert]::FromBase64String($script:MON_OUTIL_BASE64)
   [IO.File]::WriteAllBytes("$env:TEMP\MonOutil.exe", $bytes)
   ```

### Q2 : Comment déboguer un crash au démarrage de l'EXE ?

**Réponse** :
1. Compiler avec `-KeepMergedScript`
2. Lancer le script fusionné directement :
   ```powershell
   powershell -ExecutionPolicy Bypass -File Build\MigrationWizard.Merged.ps1
   ```
3. Lire les erreurs PowerShell affichées
4. Corriger le code source
5. Recompiler

### Q3 : Comment modifier l'interface XAML ?

**Réponse** :
1. Éditer `src/UI/MigrationWizard.xaml` dans VS Code
2. Utiliser un outil XAML Designer (optionnel) :
   - Visual Studio Community (gratuit) avec WPF Designer
   - XAML Viewer online
3. Tester les changements en recompilant l'EXE

**Attention** : Échapper les caractères spéciaux XML :
- `<` → `&lt;`
- `>` → `&gt;`
- `&` → `&amp;`
- `"` → `&quot;`

### Q4 : Pourquoi l'import supprime mes fichiers du bureau ?

**Réponse** : C'est voulu ! `Import-WallpaperDesktop` appelle `Clear-AllDesktops` pour supprimer tout le contenu du bureau avant de restaurer celui de l'export.

**Ordre critique** :
1. `Import-WallpaperDesktop` → Purge + restaure bureau
2. `Import-MWUserData` → Copie fichiers supplémentaires

Si l'ordre est inversé, les fichiers copiés par `Import-MWUserData` seront supprimés par `Clear-AllDesktops`.

### Q5 : Comment ajouter un nouveau type de navigateur ?

**Réponse** :
1. Éditer `src/Modules/BrowserDetection.psm1` :
   ```powershell
   function Get-MonNavigateurProfiles {
       $profilesPath = "$env:LOCALAPPDATA\MonNavigateur\Profiles"
       # Logique de détection
   }
   ```
2. Éditer `src/Features/Browsers.psm1` :
   ```powershell
   function Export-MonNavigateur {
       param([string]$ExportPath)
       # Logique d'export
   }

   function Import-MonNavigateur {
       param([string]$ExportPath)
       # Logique d'import
   }
   ```
3. Intégrer dans `Export-MWBrowsers` et `Import-MWBrowsers`
4. Recompiler et tester

### Q6 : Comment changer le logo de l'application ?

**Réponse** :
1. Remplacer `logo-logicia2.ico` par votre nouveau logo (même nom)
2. Ou éditer `Tools/Build-PortableExe.ps1` :
   ```powershell
   $iconPath = Join-Path $projectRoot 'mon-nouveau-logo.ico'
   ```
3. Recompiler

### Q7 : Où sont stockés les exports par défaut ?

**Réponse** :
- **Export** : `D:\[ClientName]\[PCName]\`
- **Logs** : `%USERPROFILE%\MigrationWizard\Logs\`
- **Binaires extraits** : `%TEMP%\MigrationWizard\`

**Changer le chemin d'export** :
Éditer `src/UI/MigrationWizard.UI.psm1` et modifier la variable `$exportBasePath`.

### Q8 : Comment tester sans compiler à chaque fois ?

**Réponse** :
1. Créer un script de test `test.ps1` :
   ```powershell
   # Charger tous les modules
   Import-Module .\src\Modules\MW.Logging.psm1 -Force
   Import-Module .\src\Core\Bootstrap.psm1 -Force
   Import-Module .\src\Core\FileCopy.psm1 -Force
   # ... etc

   # Initialiser
   Initialize-MWEnvironment

   # Tester une fonction
   Export-MWWifiProfiles -ExportPath "C:\Temp\Test"
   ```
2. Lancer `powershell -ExecutionPolicy Bypass -File test.ps1`

**Note** : Ne fonctionne que pour tester la logique, pas l'UI XAML.

---

## CONCLUSION

Ce guide couvre l'essentiel pour reprendre le développement de MigrationWizard.

**Ressources supplémentaires** :
- `README.md` : Description publique du logiciel
- `DOCUMENTATION-TECHNIQUE.md` : Architecture moteur complète
- `SYNC_GITHUB.txt` : Guide de synchronisation GitHub
- `01-VUE-ENSEMBLE.md` : Vue d'ensemble détaillée
- `03-HISTORIQUE-BUGS-FIXES.md` : Bugs corrigés et leçons apprises
- `04-CHANGELOG-DETAILLE.md` : Historique complet des versions

**Contacts** :
- **Auteur original** : Jean-Mickael Thomas (Logicia)
- **Dépôt privé** : https://github.com/Abygail007/Migration_Wizard-Source
- **Dépôt public** : https://github.com/Abygail007/Migration_Wizard

---

**Bon développement !** 🚀
