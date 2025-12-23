# MigrationWizard

**Assistant de Migration de Profils Windows**

Version actuelle : 1.0.23.10

---

## Description

MigrationWizard est un outil professionnel de migration de profils utilisateurs Windows. Il permet d'exporter et d'importer facilement l'intégralité d'un profil utilisateur lors d'un changement d'ordinateur ou d'une réinstallation système.

### Caractéristiques principales

- **Interface graphique intuitive** : Assistant étape par étape avec interface WPF moderne
- **100% portable** : Un seul fichier EXE autonome, aucune installation requise
- **Migration complète** : Fichiers, paramètres, configurations réseau, navigateurs, Outlook
- **Copie robuste** : Basé sur Robocopy avec gestion automatique des erreurs et retry
- **Export incrémental** : Sauvegarde uniquement les fichiers modifiés depuis le dernier export
- **Réparation automatique** : Les raccourcis (.lnk) sont automatiquement mis à jour avec les nouveaux chemins
- **Logs détaillés** : Traçabilité complète de toutes les opérations

---

## Fonctionnalités

### Export de Profil

L'export permet de sauvegarder :

1. **Dossiers utilisateur** : Bureau, Documents, Images, Vidéos, Musique, Téléchargements, Favoris
2. **Dossiers Public** : Bureau public, Documents publics, etc.
3. **AppData** : Sélection d'applications spécifiques (Firefox, Thunderbird, Teams, etc.)
4. **Options supplémentaires** : Arborescence complète du disque C:\ pour données spécifiques
5. **Réseau** : Profils Wi-Fi (avec mots de passe), imprimantes, lecteurs réseau, connexions RDP
6. **Navigateurs** : Chrome, Firefox, Edge (favoris, paramètres, extensions, historique)
7. **Outlook** : Fichiers PST, signatures, règles, comptes
8. **Bureau** : Fond d'écran, positions des icônes
9. **Système** : Épinglages barre des tâches, menu Démarrer, accès rapide Explorateur

### Import de Profil

L'import restaure intelligemment le profil exporté :

- **Détection automatique** du nom d'utilisateur source
- **Réparation des raccourcis** avec mise à jour automatique des chemins
- **Fusion intelligente** avec les données existantes (pas d'écrasement brutal)
- **Ordre d'import optimisé** pour éviter les conflits
- **Tracking** de l'import avec métadonnées (date, machine source, utilisateur)

### Dashboard

Tableau de bord affichant :

- Nombre total d'exports disponibles
- Espace disque utilisé par les exports
- Liste détaillée des exports avec date, machine source, taille
- Accès rapide à l'import d'un export spécifique

---

## Utilisation

### Prérequis

- Windows 10/11 (PowerShell 5.1+)
- Droits administrateur (élévation automatique au lancement)

### Export d'un profil

1. Lancer `MigrationWizard.exe`
2. Cliquer sur "Export"
3. Sélectionner les éléments à exporter via les cases à cocher
4. Choisir le mode Export (Standard ou Incrémental)
5. Cliquer sur "Lancer"
6. Les données sont exportées dans `%USERPROFILE%\MigrationWizard\Exports\[NomPC]\`

### Import d'un profil

1. Copier le dossier d'export vers le nouvel ordinateur dans `%USERPROFILE%\MigrationWizard\Exports\`
2. Lancer `MigrationWizard.exe`
3. Le Dashboard affiche automatiquement les exports disponibles
4. Cliquer sur "Importer" pour l'export souhaité
5. Sélectionner les éléments à importer
6. Cliquer sur "Lancer"

---

## Architecture Technique

### Technologies

- **Langage** : PowerShell 5.1+
- **Interface** : WPF (Windows Presentation Foundation) avec XAML
- **Compilation** : PS2EXE pour générer un exécutable portable standalone
- **Taille** : ~43 MB (incluant tous les binaires embarqués)

### Binaires Embarqués

L'application embarque plusieurs outils en base64 :

- **DesktopOK.exe** (1.6 MB) : Sauvegarde/restauration positions icônes bureau
- **RZGet.exe** (794 KB) : Gestionnaire de téléchargement Logicia
- **Raccourcis Logicia** (30 MB) : Espace Client + Télémaintenance
- **Nyan Cat** (63 KB) : Animation écran de progression

### Logs

Tous les logs sont stockés dans :
```
%USERPROFILE%\MigrationWizard\Logs\MigrationWizard_YYYYMMDD_[HOSTNAME].log
```

Format des logs :
```
YYYY-MM-DD HH:MM:SS [LEVEL] Message
```

Niveaux : INFO, WARNING, ERROR, SUCCESS, DEBUG

---

## Support

### Bugs et Questions

Pour signaler un bug ou poser une question, contacter le support Logicia.

### Développement

Ce projet est développé et maintenu par **Logicia**.

**Auteur** : Jean-Mickael Thomas
**Copyright** : (c) 2025 Logicia

---

## Licence

Propriétaire - Logicia
Tous droits réservés.

---

## Historique des Versions

### v1.0.23.10 (2025-12-23)
- Fix bug XAML : caractères spéciaux dans les boutons de navigation
- Restructuration dépôts GitHub (source séparé de l'EXE)

### v1.0.23.9 (2025-12-23)
- Fix bug XAML : échappement caractères `<` et `>` dans Content des boutons

### v1.0.23.8 (2025-12-22)
- Correction détection exports (ExportManifest.json + snapshot.json)
- Fix dates PS2EXE (.ToString() → Get-Date -Format)
- Fix fonction Write-MWLogWarning
- Fix ComputerName Dashboard
- Fix embarquement Télémaintenance (encoding)

Pour l'historique complet, consulter `CHANGELOG-DETAILLE.md` dans le dépôt source.
