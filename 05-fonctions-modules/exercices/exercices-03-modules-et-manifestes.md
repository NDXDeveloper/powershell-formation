### Solutions des exercices pratiques

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

#### 1. Exercice de base : Script .ps1 qui liste les fichiers d'un dossier

```powershell
# Liste-Fichiers.ps1
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$Dossier,

    [Parameter()]
    [switch]$Recursif,

    [Parameter()]
    [string]$Filtre = "*"
)

# Message d'introduction
Write-Host "Liste des fichiers dans le dossier: $Dossier" -ForegroundColor Cyan
if ($Recursif) { Write-Host "Mode récursif activé" -ForegroundColor Yellow }

# Paramètres pour Get-ChildItem
$getParams = @{
    Path = $Dossier
    File = $true
    Filter = $Filtre
}

if ($Recursif) { $getParams.Add("Recurse", $true) }

# Récupérer et afficher les fichiers
$fichiers = Get-ChildItem @getParams

if ($fichiers.Count -eq 0) {
    Write-Host "Aucun fichier trouvé." -ForegroundColor Red
}
else {
    Write-Host "Total: $($fichiers.Count) fichier(s)" -ForegroundColor Green

    # Créer un tableau formaté pour l'affichage
    $fichiers | Select-Object Name,
                         @{Name="Taille (KB)"; Expression={[math]::Round($_.Length / 1KB, 2)}},
                         LastWriteTime,
                         @{Name="Type"; Expression={$_.Extension}} |
        Format-Table -AutoSize
}

# Suggestions pour l'utilisateur
Write-Host "`nExemples d'utilisation:" -ForegroundColor Magenta
Write-Host ".\Liste-Fichiers.ps1 -Dossier 'C:\Temp'" -ForegroundColor DarkGray
Write-Host ".\Liste-Fichiers.ps1 -Dossier 'C:\Documents' -Recursif" -ForegroundColor DarkGray
Write-Host ".\Liste-Fichiers.ps1 -Dossier 'C:\Code' -Filtre '*.ps1'" -ForegroundColor DarkGray
```

#### 2. Exercice intermédiaire : Conversion en module .psm1

```powershell
# GestionFichiers.psm1

function Get-ListeFichiers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$Dossier,

        [Parameter()]
        [switch]$Recursif,

        [Parameter()]
        [string]$Filtre = "*"
    )

    # Paramètres pour Get-ChildItem
    $getParams = @{
        Path = $Dossier
        File = $true
        Filter = $Filtre
    }

    if ($Recursif) { $getParams.Add("Recurse", $true) }

    # Récupérer les fichiers
    $fichiers = Get-ChildItem @getParams

    # Retourner les résultats sous forme d'objets
    foreach ($fichier in $fichiers) {
        [PSCustomObject]@{
            Nom = $fichier.Name
            CheminComplet = $fichier.FullName
            TailleKB = [math]::Round($fichier.Length / 1KB, 2)
            DateModification = $fichier.LastWriteTime
            Type = $fichier.Extension
            Attributs = $fichier.Attributes
        }
    }
}

function Get-TopFichiers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$Dossier,

        [Parameter()]
        [int]$Nombre = 5,

        [Parameter()]
        [ValidateSet("Taille", "DateModification", "Nom")]
        [string]$TriPar = "Taille"
    )

    $fichiers = Get-ChildItem -Path $Dossier -File -Recurse

    switch ($TriPar) {
        "Taille" { $fichiers = $fichiers | Sort-Object -Property Length -Descending | Select-Object -First $Nombre }
        "DateModification" { $fichiers = $fichiers | Sort-Object -Property LastWriteTime -Descending | Select-Object -First $Nombre }
        "Nom" { $fichiers = $fichiers | Sort-Object -Property Name | Select-Object -First $Nombre }
    }

    foreach ($fichier in $fichiers) {
        [PSCustomObject]@{
            Nom = $fichier.Name
            CheminComplet = $fichier.FullName
            TailleKB = [math]::Round($fichier.Length / 1KB, 2)
            DateModification = $fichier.LastWriteTime
            Type = $fichier.Extension
        }
    }
}

function Test-ExtensionFichier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$CheminFichier,

        [Parameter(Position=1)]
        [string[]]$ExtensionsAutorisees = @(".txt", ".log", ".csv", ".xml", ".json", ".ps1", ".psm1")
    )

    process {
        if (-not (Test-Path -Path $CheminFichier -PathType Leaf)) {
            Write-Error "Le fichier '$CheminFichier' n'existe pas."
            return $false
        }

        $extension = [System.IO.Path]::GetExtension($CheminFichier).ToLower()

        $estAutorise = $extension -in $ExtensionsAutorisees

        [PSCustomObject]@{
            Fichier = $CheminFichier
            Extension = $extension
            EstAutorise = $estAutorise
        }
    }
}

# Exporter seulement les fonctions publiques
Export-ModuleMember -Function Get-ListeFichiers, Get-TopFichiers, Test-ExtensionFichier
```

#### 3. Exercice avancé : Module complet avec structure et manifeste

Structure du module :
```
FichierManager/
├── FichierManager.psm1
├── FichierManager.psd1
├── Public/
│   ├── Get-FileSummary.ps1
│   ├── Find-Duplicates.ps1
│   └── Start-FileMonitor.ps1
├── Private/
│   ├── Calculate-Hash.ps1
│   └── Format-FileSize.ps1
└── Data/
    └── FileExtensions.json
```

##### 1. Contenu de `FichierManager.psm1`

```powershell
# FichierManager.psm1
# Module principal qui charge les fonctions privées et publiques

# Charger les fonctions privées
$privateFiles = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $privateFiles) {
    try {
        . $file.FullName
        Write-Verbose "Fonction privée chargée : $($file.BaseName)"
    }
    catch {
        Write-Error "Impossible de charger la fonction privée $($file.FullName): $_"
    }
}

# Charger les fonctions publiques
$publicFiles = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
$publicFunctions = @()
foreach ($file in $publicFiles) {
    try {
        . $file.FullName
        $publicFunctions += $file.BaseName
        Write-Verbose "Fonction publique chargée : $($file.BaseName)"
    }
    catch {
        Write-Error "Impossible de charger la fonction publique $($file.FullName): $_"
    }
}

# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function $publicFunctions
```

##### 2. Contenu de `Private/Calculate-Hash.ps1`

```powershell
function Calculate-Hash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter()]
        [ValidateSet("MD5", "SHA1", "SHA256")]
        [string]$Algorithm = "SHA256"
    )

    try {
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas."
            return $null
        }

        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $hashAlgorithm = [System.Security.Cryptography.HashAlgorithm]::Create($Algorithm)
        $hashBytes = $hashAlgorithm.ComputeHash($fileStream)
        $hashString = [BitConverter]::ToString($hashBytes) -replace '-', ''

        $fileStream.Close()
        $fileStream.Dispose()

        return $hashString
    }
    catch {
        Write-Error "Erreur lors du calcul du hash pour '$FilePath': $_"
        return $null
    }
}
```

##### 3. Contenu de `Private/Format-FileSize.ps1`

```powershell
function Format-FileSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [long]$SizeInBytes
    )

    if ($SizeInBytes -lt 1KB) {
        return "$SizeInBytes octets"
    }
    elseif ($SizeInBytes -lt 1MB) {
        return "{0:N2} KB" -f ($SizeInBytes / 1KB)
    }
    elseif ($SizeInBytes -lt 1GB) {
        return "{0:N2} MB" -f ($SizeInBytes / 1MB)
    }
    elseif ($SizeInBytes -lt 1TB) {
        return "{0:N2} GB" -f ($SizeInBytes / 1GB)
    }
    else {
        return "{0:N2} TB" -f ($SizeInBytes / 1TB)
    }
}
```

##### 4. Contenu de `Public/Get-FileSummary.ps1`

```powershell
function Get-FileSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$FolderPath,

        [Parameter()]
        [switch]$IncludeSubfolders,

        [Parameter()]
        [string[]]$ExcludeExtensions
    )

    # Paramètres pour Get-ChildItem
    $getParams = @{
        Path = $FolderPath
        File = $true
    }

    if ($IncludeSubfolders) {
        $getParams.Add("Recurse", $true)
    }

    # Récupérer tous les fichiers
    $allFiles = Get-ChildItem @getParams

    # Filtrer les extensions exclues si spécifiées
    if ($ExcludeExtensions) {
        $allFiles = $allFiles | Where-Object {
            $extension = [System.IO.Path]::GetExtension($_.Name).ToLower()
            $extension -notin $ExcludeExtensions
        }
    }

    # Calculer les statistiques
    $totalFiles = $allFiles.Count
    $totalSize = ($allFiles | Measure-Object -Property Length -Sum).Sum

    # Grouper par extension
    $extensionGroups = $allFiles | Group-Object -Property Extension |
                       Select-Object Name, Count,
                                    @{Name="TotalSize"; Expression={($_.Group | Measure-Object -Property Length -Sum).Sum}}

    # Trouver les fichiers les plus récents et les plus anciens
    $newestFile = $allFiles | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1
    $oldestFile = $allFiles | Sort-Object -Property LastWriteTime | Select-Object -First 1

    # Trouver les fichiers les plus gros
    $largestFiles = $allFiles | Sort-Object -Property Length -Descending | Select-Object -First 5

    # Créer l'objet de résumé
    $summary = [PSCustomObject]@{
        FolderPath = $FolderPath
        IncludesSubfolders = $IncludeSubfolders
        TotalFiles = $totalFiles
        TotalSize = Format-FileSize -SizeInBytes $totalSize
        TotalSizeBytes = $totalSize
        ExtensionSummary = $extensionGroups | ForEach-Object {
            [PSCustomObject]@{
                Extension = if ($_.Name) { $_.Name } else { "(Sans extension)" }
                Count = $_.Count
                TotalSize = Format-FileSize -SizeInBytes $_.TotalSize
            }
        }
        NewestFile = if ($newestFile) {
            [PSCustomObject]@{
                Name = $newestFile.Name
                Path = $newestFile.FullName
                LastModified = $newestFile.LastWriteTime
                Size = Format-FileSize -SizeInBytes $newestFile.Length
            }
        } else { $null }
        OldestFile = if ($oldestFile) {
            [PSCustomObject]@{
                Name = $oldestFile.Name
                Path = $oldestFile.FullName
                LastModified = $oldestFile.LastWriteTime
                Size = Format-FileSize -SizeInBytes $oldestFile.Length
            }
        } else { $null }
        LargestFiles = $largestFiles | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
                Size = Format-FileSize -SizeInBytes $_.Length
                SizeBytes = $_.Length
                LastModified = $_.LastWriteTime
            }
        }
    }

    return $summary
}
```

##### 5. Contenu de `Public/Find-Duplicates.ps1`

```powershell
function Find-Duplicates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$FolderPath,

        [Parameter()]
        [switch]$IncludeSubfolders,

        [Parameter()]
        [ValidateSet("Name", "Size", "Content")]
        [string]$CompareBy = "Content",

        [Parameter()]
        [ValidateSet("MD5", "SHA1", "SHA256")]
        [string]$HashAlgorithm = "MD5"
    )

    Write-Verbose "Recherche de doublons dans $FolderPath (CompareBy: $CompareBy)"

    # Paramètres pour Get-ChildItem
    $getParams = @{
        Path = $FolderPath
        File = $true
    }

    if ($IncludeSubfolders) {
        $getParams.Add("Recurse", $true)
    }

    # Récupérer tous les fichiers
    $allFiles = Get-ChildItem @getParams

    Write-Verbose "Nombre total de fichiers trouvés: $($allFiles.Count)"

    # Trouver les doublons selon la méthode choisie
    $duplicates = @()

    switch ($CompareBy) {
        "Name" {
            # Grouper par nom de fichier uniquement
            $groups = $allFiles | Group-Object -Property Name | Where-Object { $_.Count -gt 1 }

            foreach ($group in $groups) {
                $duplicates += [PSCustomObject]@{
                    Value = $group.Name
                    Type = "Nom"
                    Files = $group.Group | ForEach-Object {
                        [PSCustomObject]@{
                            Path = $_.FullName
                            Size = $_.Length
                            LastModified = $_.LastWriteTime
                        }
                    }
                }
            }
        }

        "Size" {
            # Grouper par taille
            $groups = $allFiles | Group-Object -Property Length | Where-Object { $_.Count -gt 1 }

            foreach ($group in $groups) {
                $duplicates += [PSCustomObject]@{
                    Value = Format-FileSize -SizeInBytes $group.Name
                    Type = "Taille"
                    Files = $group.Group | ForEach-Object {
                        [PSCustomObject]@{
                            Path = $_.FullName
                            Name = $_.Name
                            LastModified = $_.LastWriteTime
                        }
                    }
                }
            }
        }

        "Content" {
            # Première étape : filtrer par taille
            $sizeGroups = $allFiles | Group-Object -Property Length | Where-Object { $_.Count -gt 1 }

            foreach ($sizeGroup in $sizeGroups) {
                $files = $sizeGroup.Group
                $hashGroups = @{}

                # Calculer le hash pour chaque fichier de même taille
                foreach ($file in $files) {
                    $hash = Calculate-Hash -FilePath $file.FullName -Algorithm $HashAlgorithm

                    if ($hash) {
                        if (-not $hashGroups.ContainsKey($hash)) {
                            $hashGroups[$hash] = @()
                        }

                        $hashGroups[$hash] += $file
                    }
                }

                # Ajouter les groupes avec des doublons
                foreach ($hashKey in $hashGroups.Keys) {
                    if ($hashGroups[$hashKey].Count -gt 1) {
                        $duplicates += [PSCustomObject]@{
                            Value = $hashKey
                            Type = "Hash $HashAlgorithm"
                            Files = $hashGroups[$hashKey] | ForEach-Object {
                                [PSCustomObject]@{
                                    Path = $_.FullName
                                    Name = $_.Name
                                    Size = $_.Length
                                    LastModified = $_.LastWriteTime
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return $duplicates
}
```

##### 6. Contenu de `Public/Start-FileMonitor.ps1`

```powershell
function Start-FileMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$FolderPath,

        [Parameter()]
        [string]$Filter = "*",

        [Parameter()]
        [switch]$IncludeSubfolders,

        [Parameter()]
        [ValidateSet("Created", "Changed", "Deleted", "Renamed", "All")]
        [string[]]$EventsToMonitor = "All",

        [Parameter()]
        [int]$DurationSeconds = 60
    )

    try {
        # Configurer les types de changements à surveiller
        $changeTypes = @()

        if ($EventsToMonitor -contains "All") {
            $changeTypes = [System.IO.WatcherChangeTypes]::Created,
                           [System.IO.WatcherChangeTypes]::Changed,
                           [System.IO.WatcherChangeTypes]::Deleted,
                           [System.IO.WatcherChangeTypes]::Renamed
        }
        else {
            foreach ($event in $EventsToMonitor) {
                $changeTypes += [System.IO.WatcherChangeTypes]::$event
            }
        }

        # Créer le FileSystemWatcher
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $FolderPath
        $watcher.Filter = $Filter
        $watcher.IncludeSubdirectories = $IncludeSubfolders

        foreach ($changeType in $changeTypes) {
            $watcher.NotifyFilter = $watcher.NotifyFilter -bor $changeType
        }

        # Tableau pour stocker les événements détectés
        $events = @()

        # Créer les actions pour chaque type d'événement
        $onCreated = Register-ObjectEvent -InputObject $watcher -EventName Created -Action {
            $global:events += [PSCustomObject]@{
                TimeStamp = Get-Date
                Type = "Création"
                Path = $Event.SourceEventArgs.FullPath
                Name = $Event.SourceEventArgs.Name
            }
            Write-Host "Fichier créé: $($Event.SourceEventArgs.FullPath)" -ForegroundColor Green
        }

        $onChanged = Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
            $global:events += [PSCustomObject]@{
                TimeStamp = Get-Date
                Type = "Modification"
                Path = $Event.SourceEventArgs.FullPath
                Name = $Event.SourceEventArgs.Name
            }
            Write-Host "Fichier modifié: $($Event.SourceEventArgs.FullPath)" -ForegroundColor Yellow
        }

        $onDeleted = Register-ObjectEvent -InputObject $watcher -EventName Deleted -Action {
            $global:events += [PSCustomObject]@{
                TimeStamp = Get-Date
                Type = "Suppression"
                Path = $Event.SourceEventArgs.FullPath
                Name = $Event.SourceEventArgs.Name
            }
            Write-Host "Fichier supprimé: $($Event.SourceEventArgs.FullPath)" -ForegroundColor Red
        }

        $onRenamed = Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action {
            $global:events += [PSCustomObject]@{
                TimeStamp = Get-Date
                Type = "Renommage"
                OldPath = $Event.SourceEventArgs.OldFullPath
                OldName = $Event.SourceEventArgs.OldName
                NewPath = $Event.SourceEventArgs.FullPath
                NewName = $Event.SourceEventArgs.Name
            }
            Write-Host "Fichier renommé: $($Event.SourceEventArgs.OldFullPath) -> $($Event.SourceEventArgs.FullPath)" -ForegroundColor Blue
        }

        # Activer le FileSystemWatcher
        $watcher.EnableRaisingEvents = $true

        Write-Host "Surveillance du dossier '$FolderPath' démarrée pour $DurationSeconds secondes..." -ForegroundColor Cyan

        # Attendre la durée spécifiée
        Start-Sleep -Seconds $DurationSeconds

        # Arrêter la surveillance
        $watcher.EnableRaisingEvents = $false

        # Nettoyer les événements enregistrés
        $onCreated | Unregister-Event
        $onChanged | Unregister-Event
        $onDeleted | Unregister-Event
        $onRenamed | Unregister-Event

        # Libérer les ressources
        $watcher.Dispose()

        Write-Host "Surveillance terminée. $($events.Count) événements détectés." -ForegroundColor Cyan

        # Retourner les événements détectés
        return $events
    }
    catch {
        Write-Error "Erreur lors de la surveillance du dossier: $_"

        # Nettoyage en cas d'erreur
        if ($watcher) {
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
        }
    }
}
```

##### 7. Création du fichier manifeste `FichierManager.psd1`

```powershell
# Pour créer le manifeste, exécutez:
New-ModuleManifest -Path "FichierManager.psd1" `
                  -RootModule "FichierManager.psm1" `
                  -ModuleVersion "1.0.0" `
                  -Author "Votre Nom" `
                  -Description "Module de gestion de fichiers avancé pour PowerShell" `
                  -CompanyName "Votre Entreprise" `
                  -Copyright "(c) 2025 Votre Nom. Tous droits réservés." `
                  -PowerShellVersion "5.1" `
                  -FunctionsToExport @("Get-FileSummary", "Find-Duplicates", "Start-FileMonitor") `
                  -CmdletsToExport @() `
                  -VariablesToExport @() `
                  -AliasesToExport @() `
                  -Tags @("fichiers", "gestion", "duplication", "surveillance") `
                  -ProjectUri "https://github.com/VotreNom/FichierManager" `
                  -LicenseUri "https://github.com/VotreNom/FichierManager/blob/main/LICENSE"
```

##### 8. Contenu de `Data/FileExtensions.json`

```json
{
  "categories": [
    {
      "name": "Documents",
      "extensions": [".doc", ".docx", ".pdf", ".txt", ".rtf", ".odt", ".md"],
      "description": "Fichiers de documents texte"
    },
    {
      "name": "Images",
      "extensions": [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".svg", ".webp"],
      "description": "Fichiers d'images"
    },
    {
      "name": "Audio",
      "extensions": [".mp3", ".wav", ".ogg", ".flac", ".aac", ".m4a", ".wma"],
      "description": "Fichiers audio"
    },
    {
      "name": "Video",
      "extensions": [".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm"],
      "description": "Fichiers vidéo"
    },
    {
      "name": "Archives",
      "extensions": [".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".tgz"],
      "description": "Fichiers d'archives compressées"
    },
    {
      "name": "Code",
      "extensions": [".ps1", ".psm1", ".psd1", ".js", ".py", ".html", ".css", ".json", ".xml", ".cs", ".java"],
      "description": "Fichiers de code et scripts"
    },
    {
      "name": "Data",
      "extensions": [".csv", ".xlsx", ".xls", ".json", ".xml", ".mdb", ".accdb", ".db", ".sqlite"],
      "description": "Fichiers de données"
    }
  ]
}
```


