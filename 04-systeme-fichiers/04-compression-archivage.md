# Module 5 - Gestion des fichiers et du système
## 5-4. Compression, archivage et extraction

### 📘 Introduction

La compression et l'archivage de fichiers sont des tâches courantes pour tout administrateur système ou développeur. Que ce soit pour économiser de l'espace disque, faciliter le transfert de fichiers ou créer des sauvegardes, PowerShell offre plusieurs méthodes pour manipuler des archives. Dans cette section, nous allons découvrir comment compresser, archiver et extraire des fichiers efficacement.

### 📦 Méthodes disponibles dans PowerShell

PowerShell propose différentes approches pour travailler avec les archives:

1. **Cmdlets intégrées**: Disponibles depuis PowerShell 5.0
2. **Classes .NET**: Pour un contrôle plus précis
3. **Outils externes**: Pour des formats spécifiques ou des fonctionnalités avancées

### 🧰 Cmdlets intégrées pour la compression

Depuis PowerShell 5.0, Microsoft a intégré des cmdlets dédiées à la gestion des archives ZIP:

- `Compress-Archive`: Créer ou mettre à jour des fichiers ZIP
- `Expand-Archive`: Extraire le contenu d'un fichier ZIP
- `Test-Path`: Vérifier si une archive existe

#### Créer une archive ZIP simple

```powershell
# Compresser un seul fichier
Compress-Archive -Path C:\rapports\rapport.docx -DestinationPath C:\archives\rapport.zip

# Compresser plusieurs fichiers
Compress-Archive -Path C:\rapports\*.txt -DestinationPath C:\archives\rapports_texte.zip

# Compresser un dossier entier
Compress-Archive -Path C:\rapports -DestinationPath C:\archives\tous_rapports.zip
```

#### Ajouter des fichiers à une archive existante

```powershell
# Ajouter un nouveau fichier à une archive existante
Compress-Archive -Path C:\rapports\nouveau.xlsx -DestinationPath C:\archives\rapports.zip -Update
```

> 💡 Le paramètre `-Update` permet d'ajouter des fichiers. Sans lui, l'archive serait remplacée.

#### Extraire une archive ZIP

```powershell
# Extraire dans un dossier spécifique
Expand-Archive -Path C:\archives\rapports.zip -DestinationPath C:\extraits

# Forcer l'écrasement des fichiers existants
Expand-Archive -Path C:\archives\rapports.zip -DestinationPath C:\extraits -Force
```

### 🔍 Lister le contenu d'une archive

Pour voir le contenu d'une archive ZIP sans l'extraire, nous pouvons utiliser la classe .NET `System.IO.Compression.ZipFile`:

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ZipContent {
    param (
        [Parameter(Mandatory)]
        [string]$ZipPath
    )

    try {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $zip.Entries | Select-Object Name, Length, LastWriteTime
        $zip.Dispose()
    }
    catch {
        Write-Error "Erreur lors de la lecture de l'archive: $_"
    }
}

# Utilisation
Get-ZipContent -ZipPath C:\archives\rapports.zip
```

### 📊 Comparer la taille avant/après compression

Voyons le taux de compression obtenu:

```powershell
function Measure-CompressionRatio {
    param (
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$ZipPath
    )

    $sourceSize = 0

    if (Test-Path -Path $SourcePath -PathType Container) {
        $sourceSize = (Get-ChildItem -Path $SourcePath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    }
    else {
        $sourceSize = (Get-Item -Path $SourcePath).Length
    }

    $zipSize = (Get-Item -Path $ZipPath).Length

    $ratio = [math]::Round(($zipSize / $sourceSize) * 100, 2)
    $saving = [math]::Round(100 - $ratio, 2)

    [PSCustomObject]@{
        "Taille d'origine (MB)" = [math]::Round($sourceSize / 1MB, 2)
        "Taille compressée (MB)" = [math]::Round($zipSize / 1MB, 2)
        "Ratio de compression" = "$ratio%"
        "Économie d'espace" = "$saving%"
    }
}

# Utilisation
$rapport = Measure-CompressionRatio -SourcePath C:\rapports -ZipPath C:\archives\rapports.zip
$rapport | Format-List
```

### 🚀 Compression en mémoire

Dans certains scénarios, vous pourriez vouloir créer une archive en mémoire sans écrire de fichier temporaire sur le disque:

```powershell
function New-InMemoryZip {
    param (
        [Parameter(Mandatory)]
        [string]$SourcePath
    )

    Add-Type -AssemblyName System.IO.Compression

    # Créer un flux mémoire pour stocker l'archive
    $memoryStream = New-Object System.IO.MemoryStream

    # Créer une nouvelle archive dans le flux mémoire
    $archive = New-Object System.IO.Compression.ZipArchive($memoryStream, [System.IO.Compression.ZipArchiveMode]::Create, $true)

    # Ajouter des fichiers à l'archive
    $files = Get-ChildItem -Path $SourcePath -File

    foreach ($file in $files) {
        # Créer une entrée dans l'archive avec le nom du fichier
        $entry = $archive.CreateEntry($file.Name)

        # Ouvrir un flux pour l'entrée
        $entryStream = $entry.Open()

        # Lire le contenu du fichier source
        $fileContent = [System.IO.File]::ReadAllBytes($file.FullName)

        # Écrire le contenu dans l'entrée
        $entryStream.Write($fileContent, 0, $fileContent.Length)
        $entryStream.Close()
    }

    # Fermer l'archive pour finaliser l'écriture
    $archive.Dispose()

    # Retourner le flux mémoire avec l'archive
    return $memoryStream
}

# Exemple d'utilisation - Envoyer par email
$zipMemory = New-InMemoryZip -SourcePath C:\rapports
$zipMemory.Position = 0  # Repositionner au début du flux

# Ici, vous pourriez utiliser ce flux pour faire autre chose
# Par exemple, l'attacher à un email ou le traiter davantage

# Pour le convertir en fichier
$fileStream = [System.IO.File]::Create("C:\archives\rapports_memoire.zip")
$zipMemory.CopyTo($fileStream)
$fileStream.Close()
$zipMemory.Close()
```

### 📝 Travailler avec d'autres formats d'archive

Les cmdlets intégrées ne prennent en charge que le format ZIP. Pour d'autres formats (7z, RAR, TAR, etc.), vous devrez utiliser des outils externes.

#### Utiliser 7-Zip via PowerShell

```powershell
function Invoke-7Zip {
    param (
        [Parameter(Mandatory)]
        [string]$Command,

        [Parameter(Mandatory)]
        [string]$ArchivePath,

        [string]$TargetPath = "",

        [string]$Options = ""
    )

    # Chemin vers l'exécutable 7-Zip (ajustez selon votre installation)
    $7zPath = "C:\Program Files\7-Zip\7z.exe"

    if (-not (Test-Path -Path $7zPath)) {
        Write-Error "7-Zip n'est pas installé à l'emplacement prévu."
        return
    }

    $arguments = "$Command `"$ArchivePath`""

    if ($TargetPath) {
        $arguments += " `"$TargetPath`""
    }

    if ($Options) {
        $arguments += " $Options"
    }

    Write-Verbose "Exécution de: $7zPath $arguments"

    $process = Start-Process -FilePath $7zPath -ArgumentList $arguments -NoNewWindow -PassThru -Wait

    if ($process.ExitCode -ne 0) {
        Write-Warning "7-Zip a retourné le code d'erreur: $($process.ExitCode)"
    }

    return $process.ExitCode
}

# Exemples d'utilisation

# Créer une archive 7z
Invoke-7Zip -Command "a" -ArchivePath "C:\archives\rapports.7z" -TargetPath "C:\rapports\*" -Options "-mx=9"

# Extraire une archive 7z
Invoke-7Zip -Command "x" -ArchivePath "C:\archives\rapports.7z" -TargetPath "C:\extraits" -Options "-y"

# Lister le contenu d'une archive
Invoke-7Zip -Command "l" -ArchivePath "C:\archives\rapports.7z"
```

### 🔄 Automatiser la rotation des archives

Pour les sauvegardes récurrentes, il est souvent utile de mettre en place un système de rotation des archives:

```powershell
function New-RotatingBackup {
    param (
        [Parameter(Mandatory)]
        [string]$SourcePath,

        [Parameter(Mandatory)]
        [string]$BackupFolder,

        [int]$KeepLastN = 5
    )

    # Créer le dossier de sauvegarde s'il n'existe pas
    if (-not (Test-Path -Path $BackupFolder)) {
        New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
    }

    # Générer un nom de fichier avec horodatage
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $zipName = "backup_$timestamp.zip"
    $zipPath = Join-Path -Path $BackupFolder -ChildPath $zipName

    # Créer la nouvelle archive
    Compress-Archive -Path $SourcePath -DestinationPath $zipPath

    Write-Host "Sauvegarde créée: $zipPath" -ForegroundColor Green

    # Supprimer les archives les plus anciennes si nécessaire
    $existingBackups = Get-ChildItem -Path $BackupFolder -Filter "backup_*.zip" |
        Sort-Object LastWriteTime -Descending

    if ($existingBackups.Count -gt $KeepLastN) {
        $toRemove = $existingBackups | Select-Object -Skip $KeepLastN

        foreach ($oldBackup in $toRemove) {
            Remove-Item -Path $oldBackup.FullName -Force
            Write-Host "Ancienne sauvegarde supprimée: $($oldBackup.Name)" -ForegroundColor Yellow
        }
    }

    # Afficher un résumé
    $currentBackups = Get-ChildItem -Path $BackupFolder -Filter "backup_*.zip" |
        Sort-Object LastWriteTime -Descending

    Write-Host "`nSauvegardes actuelles:" -ForegroundColor Cyan
    $currentBackups | Select-Object Name, @{Name="Taille (MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}}, LastWriteTime |
        Format-Table -AutoSize
}

# Utilisation
New-RotatingBackup -SourcePath "C:\data" -BackupFolder "C:\backups" -KeepLastN 3
```

### 💼 Exemple pratique : Sauvegarde de projets

Voici un exemple plus complet qui sauvegarde automatiquement des projets:

```powershell
function Backup-Projects {
    param (
        [Parameter(Mandatory)]
        [string]$ProjectsFolder,

        [Parameter(Mandatory)]
        [string]$BackupFolder,

        [string[]]$ExcludePatterns = @("bin", "obj", "node_modules", ".git", ".vs"),

        [switch]$IncludeTimestamp
    )

    # Vérifier que le dossier des projets existe
    if (-not (Test-Path -Path $ProjectsFolder -PathType Container)) {
        Write-Error "Le dossier des projets n'existe pas: $ProjectsFolder"
        return
    }

    # Créer le dossier de sauvegarde s'il n'existe pas
    if (-not (Test-Path -Path $BackupFolder)) {
        New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
    }

    # Obtenir tous les projets (dossiers) dans le répertoire source
    $projects = Get-ChildItem -Path $ProjectsFolder -Directory

    foreach ($project in $projects) {
        Write-Host "Sauvegarde du projet: $($project.Name)" -ForegroundColor Cyan

        # Créer un fichier temporaire avec la liste des exclusions
        $excludeFile = [System.IO.Path]::GetTempFileName()
        $ExcludePatterns | Out-File -FilePath $excludeFile

        # Préparer le nom de l'archive
        $archiveName = $project.Name
        if ($IncludeTimestamp) {
            $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
            $archiveName = "$archiveName`_$timestamp"
        }

        $archivePath = Join-Path -Path $BackupFolder -ChildPath "$archiveName.zip"

        # Créer l'archive en excluant les motifs spécifiés
        $files = Get-ChildItem -Path $project.FullName -Recurse -File |
            Where-Object {
                $include = $true
                foreach ($pattern in $ExcludePatterns) {
                    if ($_.FullName -like "*\$pattern\*") {
                        $include = $false
                        break
                    }
                }
                $include
            }

        if ($files.Count -eq 0) {
            Write-Warning "Aucun fichier à sauvegarder dans le projet: $($project.Name)"
            continue
        }

        $files | Compress-Archive -DestinationPath $archivePath -Force

        # Afficher un résumé
        $archiveInfo = Get-Item -Path $archivePath
        [PSCustomObject]@{
            Projet = $project.Name
            "Fichiers sauvegardés" = $files.Count
            "Taille de l'archive (MB)" = [math]::Round($archiveInfo.Length / 1MB, 2)
            "Emplacement de sauvegarde" = $archivePath
        } | Format-List
    }

    Write-Host "Toutes les sauvegardes ont été créées avec succès!" -ForegroundColor Green
}

# Utilisation
Backup-Projects -ProjectsFolder "C:\Développement" -BackupFolder "C:\Sauvegardes\Projets" -IncludeTimestamp
```

### 💪 Exercice pratique

Créez un script qui:
1. Recherche tous les fichiers de logs (`*.log`) datant de plus d'une semaine dans un dossier
2. Les compresse dans une archive ZIP avec un horodatage
3. Supprime les fichiers originaux après avoir vérifié que l'archivage a réussi
4. Crée un fichier de rapport indiquant quels fichiers ont été archivés

### 🎓 Solution de l'exercice

```powershell
function Archive-OldLogs {
    param (
        [Parameter(Mandatory)]
        [string]$LogFolder,

        [string]$ArchiveFolder = (Join-Path -Path $LogFolder -ChildPath "Archives"),

        [int]$DaysToKeep = 7
    )

    # Créer le dossier d'archives s'il n'existe pas
    if (-not (Test-Path -Path $ArchiveFolder)) {
        New-Item -Path $ArchiveFolder -ItemType Directory -Force | Out-Null
    }

    # Calculer la date limite
    $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)

    # Trouver tous les fichiers logs plus anciens que la date limite
    $oldLogFiles = Get-ChildItem -Path $LogFolder -Filter "*.log" -File |
        Where-Object { $_.LastWriteTime -lt $cutoffDate }

    if ($oldLogFiles.Count -eq 0) {
        Write-Host "Aucun fichier log à archiver." -ForegroundColor Yellow
        return
    }

    Write-Host "Trouvé $($oldLogFiles.Count) fichiers logs à archiver." -ForegroundColor Cyan

    # Créer le nom de l'archive avec horodatage
    $timestamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $archiveName = "logs_archive_$timestamp.zip"
    $archivePath = Join-Path -Path $ArchiveFolder -ChildPath $archiveName

    # Créer un rapport
    $reportPath = Join-Path -Path $ArchiveFolder -ChildPath "rapport_archive_$timestamp.txt"
    $reportContent = @"
RAPPORT D'ARCHIVAGE DE LOGS
---------------------------
Date: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Dossier source: $LogFolder
Archive: $archiveName
Nombre de fichiers: $($oldLogFiles.Count)

DÉTAILS DES FICHIERS ARCHIVÉS:
"@

    # Ajouter les détails de chaque fichier au rapport
    foreach ($file in $oldLogFiles) {
        $reportContent += "`n$($file.Name) - $($file.LastWriteTime) - $([math]::Round($file.Length / 1KB, 2)) KB"
    }

    try {
        # Compresser les fichiers
        $oldLogFiles | Compress-Archive -DestinationPath $archivePath -CompressionLevel Optimal

        # Vérifier que l'archive a été créée correctement
        if (Test-Path -Path $archivePath) {
            # Vérifier que tous les fichiers sont dans l'archive
            $archiveContent = Get-ZipContent -ZipPath $archivePath
            $allFilesArchived = $true

            foreach ($file in $oldLogFiles) {
                if ($archiveContent.Name -notcontains $file.Name) {
                    $allFilesArchived = $false
                    Write-Warning "Le fichier $($file.Name) n'a pas été correctement archivé."
                }
            }

            if ($allFilesArchived) {
                # Supprimer les fichiers originaux
                $oldLogFiles | Remove-Item -Force
                $reportContent += "`n`nStatut: Tous les fichiers ont été archivés avec succès et supprimés."
            }
            else {
                $reportContent += "`n`nStatut: ERREUR - Certains fichiers n'ont pas été correctement archivés."
                $reportContent += "`nLes fichiers originaux ont été conservés."
            }
        }
        else {
            $reportContent += "`n`nStatut: ERREUR - L'archive n'a pas été créée correctement."
        }
    }
    catch {
        $reportContent += "`n`nStatut: ERREUR - Exception lors de l'archivage: $_"
    }

    # Enregistrer le rapport
    $reportContent | Out-File -FilePath $reportPath

    Write-Host "Archivage terminé. Rapport disponible: $reportPath" -ForegroundColor Green

    # Définir la fonction Get-ZipContent pour vérifier le contenu de l'archive
    function Get-ZipContent {
        param ([string]$ZipPath)

        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
        $entries = $zip.Entries
        $zip.Dispose()
        return $entries
    }
}

# Utilisation
Archive-OldLogs -LogFolder "C:\Logs" -DaysToKeep 7
```

### 🔑 Points clés à retenir

- `Compress-Archive` et `Expand-Archive` sont les cmdlets natives pour manipuler les fichiers ZIP
- Le paramètre `-Update` permet d'ajouter des fichiers à une archive existante
- Pour d'autres formats (7z, RAR, etc.), vous devez utiliser des outils externes comme 7-Zip
- Les classes .NET `System.IO.Compression` offrent plus de contrôle pour des cas avancés
- La création d'archives en mémoire est utile pour les opérations intermédiaires
- Le système de rotation d'archives permet de conserver un historique tout en limitant l'espace utilisé

### 🔮 Pour aller plus loin

Dans la prochaine section, nous verrons comment manipuler les dates et les durées avec PowerShell, des compétences essentielles pour automatiser des tâches planifiées, gérer des délais et créer des rapports précis.

---

💡 **Astuce de pro**: Pour compresser efficacement de grandes quantités de données, divisez le travail en lots et utilisez `Compress-Archive` avec le paramètre `-CompressionLevel Optimal` pour le meilleur équilibre entre vitesse et taille.
