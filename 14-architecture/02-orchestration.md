# Module 15-2: Séparation logique (orchestration vs logique métier)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📘 Introduction

Lorsqu'on développe des scripts PowerShell complexes, il devient essentiel d'organiser son code de manière structurée. La séparation logique est une approche fondamentale qui consiste à diviser votre script en différentes parties ayant chacune une responsabilité distincte. Cette organisation améliore la lisibilité, la maintenance et la réutilisation de votre code.

## 🔍 Qu'est-ce que la séparation logique?

La séparation logique consiste à distinguer deux types principaux de code dans vos scripts:

1. **Code d'orchestration**: Contrôle le flux d'exécution général
2. **Code de logique métier**: Contient les fonctionnalités spécifiques à votre domaine

C'est un peu comme si vous sépariez le "chef d'orchestre" (qui décide quand et quoi exécuter) des "musiciens" (qui savent comment jouer chaque partie).

## 💡 Orchestration vs Logique métier

### Orchestration
L'orchestration est la partie qui:
- Définit l'ordre d'exécution des opérations
- Gère les paramètres et arguments principaux
- Contrôle le flux (conditions, boucles principales)
- Gère les erreurs au niveau global
- Coordonne les différentes fonctions métier

### Logique métier
La logique métier est la partie qui:
- Contient le savoir-faire spécifique à votre domaine
- Implémente les fonctionnalités précises
- Manipule les données selon des règles spécifiques
- Est potentiellement réutilisable dans d'autres scripts

## 🌟 Exemple simple

Voici un exemple concret pour illustrer cette séparation:

```powershell
# Script: BackupDatabases.ps1

# --------------------------------------
# PARTIE ORCHESTRATION
# --------------------------------------

# Paramètres principaux du script
param(
    [string]$ServerName = "localhost",
    [string]$BackupPath = "C:\Backups",
    [switch]$SkipLogs = $false
)

# Point d'entrée principal - Orchestration
function Start-DatabaseBackup {
    Write-Host "Démarrage de la sauvegarde des bases de données sur $ServerName"

    # Vérification préalable
    if (-not (Test-ServerConnection -ServerName $ServerName)) {
        Write-Error "Impossible de se connecter au serveur $ServerName"
        return
    }

    # Obtenir la liste des bases à sauvegarder
    $databases = Get-DatabaseList -ServerName $ServerName

    # Créer le dossier de sauvegarde si nécessaire
    if (-not (Test-Path -Path $BackupPath)) {
        New-Item -Path $BackupPath -ItemType Directory -Force
    }

    # Pour chaque base, lancer la sauvegarde
    foreach ($db in $databases) {
        try {
            Backup-SingleDatabase -DatabaseName $db -BackupPath $BackupPath
            if (-not $SkipLogs) {
                Backup-DatabaseLogs -DatabaseName $db -BackupPath $BackupPath
            }
        }
        catch {
            Write-Error "Erreur lors de la sauvegarde de $db : $_"
        }
    }

    Write-Host "Processus de sauvegarde terminé"
}

# --------------------------------------
# PARTIE LOGIQUE MÉTIER
# --------------------------------------

# Fonction métier: Vérifier la connexion au serveur
function Test-ServerConnection {
    param([string]$ServerName)

    Write-Verbose "Test de connexion au serveur $ServerName"
    try {
        # Code spécifique pour tester la connexion
        return $true
    }
    catch {
        return $false
    }
}

# Fonction métier: Récupérer la liste des bases de données
function Get-DatabaseList {
    param([string]$ServerName)

    Write-Verbose "Récupération des bases de données sur $ServerName"
    # Code spécifique pour lister les bases de données
    return @("DB1", "DB2", "DB3")
}

# Fonction métier: Sauvegarder une base de données
function Backup-SingleDatabase {
    param(
        [string]$DatabaseName,
        [string]$BackupPath
    )

    $backupFile = Join-Path -Path $BackupPath -ChildPath "$DatabaseName-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
    Write-Verbose "Sauvegarde de $DatabaseName vers $backupFile"

    # Code spécifique pour sauvegarder la base de données
    # ...

    Write-Host "Base de données $DatabaseName sauvegardée avec succès"
}

# Fonction métier: Sauvegarder les journaux de transactions
function Backup-DatabaseLogs {
    param(
        [string]$DatabaseName,
        [string]$BackupPath
    )

    $logFile = Join-Path -Path $BackupPath -ChildPath "$DatabaseName-log-$(Get-Date -Format 'yyyyMMdd-HHmmss').trn"
    Write-Verbose "Sauvegarde des logs de $DatabaseName vers $logFile"

    # Code spécifique pour sauvegarder les journaux
    # ...

    Write-Host "Journaux de $DatabaseName sauvegardés avec succès"
}

# Lancement de l'orchestration
Start-DatabaseBackup
```

## 🧩 Avantages de la séparation logique

1. **Meilleure lisibilité**: Le code est organisé par responsabilité
2. **Facilité de maintenance**: Vous pouvez modifier la logique métier sans toucher à l'orchestration
3. **Réutilisation simplifiée**: Les fonctions métier peuvent être facilement importées dans d'autres scripts
4. **Tests simplifiés**: Vous pouvez tester séparément l'orchestration et les fonctions métier
5. **Collaboration améliorée**: Différentes personnes peuvent travailler sur différentes parties

## 🚀 Techniques de séparation

### 1. Par fonction
Comme dans l'exemple ci-dessus, définir des fonctions dédiées pour chaque partie.

### 2. Par fichier
Pour les projets plus importants, séparer dans différents fichiers:
```
MonProjet/
  ├── Start-MonProjet.ps1        # Script principal (orchestration)
  ├── Fonctions/                 # Dossier de fonctions (logique métier)
  │   ├── Get-DonneesMetier.ps1
  │   ├── Test-Connexion.ps1
  │   └── ...
  └── Config/                    # Configuration
      └── parametres.json
```

### 3. Par module
Pour les projets professionnels, créer un module pour la logique métier:
```powershell
# Dans le script d'orchestration
Import-Module ./MonModule  # Importe toutes les fonctions métier

# Utilisation des fonctions
$data = Get-DonneesMetier
Process-DonneesMetier -InputData $data
```

## 📝 Bonnes pratiques

1. **Nommage explicite**: Utilisez des noms clairs pour distinguer l'orchestration de la logique métier
2. **Documentation**: Documentez bien l'interface entre les deux parties
3. **Paramètres cohérents**: Utilisez des paramètres similaires dans vos fonctions métier
4. **Gestion d'erreurs appropriée**:
   - Orchestration: capture et décide que faire des erreurs
   - Logique métier: génère des erreurs claires avec `throw`
5. **Évitez les dépendances circulaires**: La logique métier ne devrait pas appeler l'orchestration

## 🎯 Exemple pratique: Transformation simple

Prenons un script "avant/après" pour voir comment appliquer la séparation logique:

### ❌ Avant: Script monolithique

```powershell
# Script qui génère un rapport sur l'espace disque
$computers = "Server1", "Server2", "Server3"
$reportPath = "C:\Reports\DiskSpace.csv"

# Créer le dossier si nécessaire
if (-not (Test-Path -Path (Split-Path -Path $reportPath -Parent))) {
    New-Item -Path (Split-Path -Path $reportPath -Parent) -ItemType Directory -Force
}

# Initialiser le rapport
$report = @()

foreach ($computer in $computers) {
    Write-Host "Analyse de $computer..."

    try {
        $disks = Get-WmiObject -ComputerName $computer -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

        foreach ($disk in $disks) {
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
            $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
            $percentFree = [math]::Round(($freeSpaceGB / $totalSpaceGB) * 100, 2)

            # Ajouter au rapport
            $report += [PSCustomObject]@{
                Computer = $computer
                DriveLetter = $disk.DeviceID
                TotalSpaceGB = $totalSpaceGB
                UsedSpaceGB = $usedSpaceGB
                FreeSpaceGB = $freeSpaceGB
                PercentFree = $percentFree
            }
        }
    }
    catch {
        Write-Error "Erreur lors de l'analyse de $computer : $_"
    }
}

# Exporter le rapport
$report | Export-Csv -Path $reportPath -NoTypeInformation
Write-Host "Rapport généré: $reportPath"
```

### ✅ Après: Script avec séparation logique

```powershell
# Paramètres principaux
param(
    [string[]]$ComputerNames = @("Server1", "Server2", "Server3"),
    [string]$ReportPath = "C:\Reports\DiskSpace.csv"
)

# ORCHESTRATION: Point d'entrée principal
function Start-DiskSpaceReport {
    param(
        [string[]]$ComputerNames,
        [string]$ReportPath
    )

    Write-Host "Démarrage du rapport d'espace disque"

    # S'assurer que le dossier de rapport existe
    New-ReportFolder -Path $ReportPath

    # Collecter les données
    $reportData = @()
    foreach ($computer in $ComputerNames) {
        try {
            $diskInfo = Get-ComputerDiskInfo -ComputerName $computer
            $reportData += $diskInfo
        }
        catch {
            Write-Error "Erreur lors de l'analyse de $computer : $_"
        }
    }

    # Générer le rapport
    Export-DiskReport -Data $reportData -Path $ReportPath

    Write-Host "Rapport généré: $ReportPath"
}

# LOGIQUE MÉTIER: Création du dossier de rapport
function New-ReportFolder {
    param([string]$Path)

    $folder = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Verbose "Dossier créé: $folder"
    }
}

# LOGIQUE MÉTIER: Obtention des informations disque
function Get-ComputerDiskInfo {
    param([string]$ComputerName)

    Write-Verbose "Analyse des disques sur $ComputerName"

    $disks = Get-WmiObject -ComputerName $ComputerName -Class Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

    $diskInfo = @()
    foreach ($disk in $disks) {
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
        $usedSpaceGB = $totalSpaceGB - $freeSpaceGB
        $percentFree = [math]::Round(($freeSpaceGB / $totalSpaceGB) * 100, 2)

        $diskInfo += [PSCustomObject]@{
            Computer = $ComputerName
            DriveLetter = $disk.DeviceID
            TotalSpaceGB = $totalSpaceGB
            UsedSpaceGB = $usedSpaceGB
            FreeSpaceGB = $freeSpaceGB
            PercentFree = $percentFree
        }
    }

    return $diskInfo
}

# LOGIQUE MÉTIER: Export du rapport
function Export-DiskReport {
    param(
        [array]$Data,
        [string]$Path
    )

    Write-Verbose "Exportation des données vers $Path"
    $Data | Export-Csv -Path $Path -NoTypeInformation
}

# Exécuter l'orchestration
Start-DiskSpaceReport -ComputerNames $ComputerNames -ReportPath $ReportPath
```

## 🎓 Conseils pour les débutants

1. **Commencez petit**: D'abord, identifiez simplement les parties orchestration vs logique métier
2. **Refactorisez progressivement**: Transformez un script existant morceau par morceau
3. **Testez à chaque étape**: Assurez-vous que votre script fonctionne toujours après chaque modification
4. **Analysez des exemples**: Étudiez des scripts professionnels pour voir comment ils sont structurés
5. **Pratiquez**: La séparation logique devient plus intuitive avec la pratique

## 🔄 Comment évoluer

Au fur et à mesure que vous progressez:
1. Commencez par séparer en fonctions dans un même fichier
2. Évoluez vers des fichiers distincts
3. Finalement, créez des modules professionnels

## 📚 Conclusion

La séparation logique entre orchestration et logique métier est une pratique fondamentale dans le développement de scripts PowerShell professionnels. Elle permet d'améliorer la qualité, la maintenance et la réutilisation de votre code. Commencez par des séparations simples et progressez vers des architectures plus avancées au fur et à mesure que vos compétences se développent.

N'oubliez pas: un script bien structuré est un investissement pour l'avenir, tant pour vous que pour ceux qui devront maintenir votre code!
