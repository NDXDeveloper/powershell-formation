# Exercice 1 - Solution: Rapports de services Windows

## Énoncé de l'exercice
Créez un script PowerShell pour générer un rapport des services Windows sur un ou plusieurs ordinateurs. Le script doit avoir une séparation claire entre l'orchestration et la logique métier.

## Solution complète

```powershell
# ServiceReport.ps1
<#
.SYNOPSIS
    Génère un rapport des services Windows sur un ou plusieurs ordinateurs.
.DESCRIPTION
    Ce script crée un rapport au format CSV listant tous les services Windows,
    leur statut, et leur type de démarrage pour les ordinateurs spécifiés.
.PARAMETER ComputerNames
    Liste des noms d'ordinateurs à analyser.
.PARAMETER ReportPath
    Chemin complet où le rapport CSV sera enregistré.
.PARAMETER RunningOnly
    Si spécifié, inclut uniquement les services en cours d'exécution.
.EXAMPLE
    .\ServiceReport.ps1 -ComputerNames "localhost" -ReportPath "C:\Temp\ServiceReport.csv"
.EXAMPLE
    .\ServiceReport.ps1 -ComputerNames "Server1","Server2" -ReportPath "C:\Temp\ServiceReport.csv" -RunningOnly
#>

# Paramètres principaux (orchestration)
param(
    [Parameter(Mandatory=$true)]
    [string[]]$ComputerNames,

    [Parameter(Mandatory=$true)]
    [string]$ReportPath,

    [Parameter(Mandatory=$false)]
    [switch]$RunningOnly
)

#-----------------------------------------------------------
# PARTIE ORCHESTRATION
#-----------------------------------------------------------

function Start-ServiceReport {
    [CmdletBinding()]
    param(
        [string[]]$ComputerNames,
        [string]$ReportPath,
        [switch]$RunningOnly
    )

    Write-Host "Démarrage du rapport de services pour $($ComputerNames.Count) ordinateur(s)..."

    # Création du dossier de destination si nécessaire
    New-ReportFolder -Path $ReportPath

    # Initialisation du rapport
    $allServices = @()

    # Pour chaque ordinateur, collecter les informations
    foreach ($computer in $ComputerNames) {
        Write-Host "Analyse des services sur $computer..." -ForegroundColor Cyan

        try {
            # Vérification de l'accessibilité de l'ordinateur
            if (Test-ComputerConnection -ComputerName $computer) {
                # Récupération des services
                $computerServices = Get-ComputerServices -ComputerName $computer -RunningOnly:$RunningOnly

                # Ajout au rapport global
                $allServices += $computerServices

                Write-Host "  ✓ $($computerServices.Count) services récupérés de $computer" -ForegroundColor Green
            } else {
                Write-Warning "  ✕ Impossible de se connecter à l'ordinateur $computer"
            }
        } catch {
            Write-Error "Erreur lors de l'analyse de $computer : $_"
        }
    }

    # Génération du rapport final
    if ($allServices.Count -gt 0) {
        Export-ServiceReport -Services $allServices -Path $ReportPath
        Write-Host "Rapport généré avec succès : $ReportPath" -ForegroundColor Green
    } else {
        Write-Warning "Aucun service n'a été trouvé. Le rapport n'a pas été généré."
    }
}

#-----------------------------------------------------------
# PARTIE LOGIQUE MÉTIER
#-----------------------------------------------------------

function Test-ComputerConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )

    Write-Verbose "Test de connexion vers $ComputerName"

    if ($ComputerName -eq "localhost" -or $ComputerName -eq $env:COMPUTERNAME) {
        return $true
    }

    $pingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
    return $pingResult
}

function Get-ComputerServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [switch]$RunningOnly
    )

    Write-Verbose "Récupération des services sur $ComputerName"

    try {
        # Paramètres pour Get-Service
        $params = @{
            ComputerName = $ComputerName
            ErrorAction = "Stop"
        }

        # Récupération des services
        $services = Get-Service @params

        # Filtrage si nécessaire
        if ($RunningOnly) {
            $services = $services | Where-Object { $_.Status -eq "Running" }
        }

        # Conversion en objets personnalisés pour le rapport
        $serviceObjects = $services | ForEach-Object {
            # Récupération du type de démarrage (nécessite des droits admin)
            try {
                $wmiService = Get-WmiObject -Class Win32_Service -ComputerName $ComputerName -Filter "Name='$($_.Name)'" -ErrorAction SilentlyContinue
                $startupType = if ($wmiService) { $wmiService.StartMode } else { "Unknown" }
            } catch {
                $startupType = "Access Denied"
            }

            # Création de l'objet de rapport
            [PSCustomObject]@{
                ComputerName = $ComputerName
                ServiceName = $_.Name
                DisplayName = $_.DisplayName
                Status = $_.Status
                StartupType = $startupType
                TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }

        return $serviceObjects
    } catch {
        Write-Error "Erreur lors de la récupération des services sur $ComputerName : $_"
        throw $_
    }
}

function New-ReportFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Write-Verbose "Vérification du dossier de rapport : $Path"

    $reportFolder = Split-Path -Path $Path -Parent

    if (-not (Test-Path -Path $reportFolder)) {
        try {
            $null = New-Item -Path $reportFolder -ItemType Directory -Force
            Write-Verbose "Dossier créé : $reportFolder"
        } catch {
            Write-Error "Impossible de créer le dossier $reportFolder : $_"
            throw $_
        }
    }
}

function Export-ServiceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$Services,

        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Write-Verbose "Exportation du rapport vers $Path"

    try {
        $Services | Export-Csv -Path $Path -NoTypeInformation -Encoding UTF8
        Write-Verbose "Exportation réussie : $Path"
    } catch {
        Write-Error "Erreur lors de l'exportation du rapport : $_"
        throw $_
    }
}

# Exécution de l'orchestration principale
Start-ServiceReport -ComputerNames $ComputerNames -ReportPath $ReportPath -RunningOnly:$RunningOnly
```

## Points clés de la solution

1. **Séparation claire** :
   - **Orchestration** : La fonction `Start-ServiceReport` contrôle le flux général d'exécution
   - **Logique métier** : Fonctions spécifiques pour chaque opération (`Test-ComputerConnection`, `Get-ComputerServices`, etc.)

2. **Gestion des erreurs** :
   - Chaque fonction métier utilise `try/catch` pour gérer ses propres erreurs
   - L'orchestration capture les erreurs de plus haut niveau

3. **Documentation** :
   - Documentation complète avec bloc `.SYNOPSIS`, `.DESCRIPTION`, etc.
   - Commentaires de section pour distinguer l'orchestration de la logique métier

4. **Paramétrage** :
   - Paramètres obligatoires et optionnels clairement définis
   - Utilisation du paramètre `-Verbose` pour faciliter le débogage

5. **Réutilisation** :
   - Les fonctions métier sont conçues pour être réutilisables
   - Séparation des responsabilités (vérification de connexion, récupération des services, export, etc.)

# Exercice 2 - Solution: Gestionnaire de logs applicatifs

## Énoncé de l'exercice
Créez un script PowerShell qui permet d'analyser et d'archiver des fichiers logs d'une application. Le script doit rechercher les erreurs critiques, les résumer, puis archiver les fichiers logs plus anciens qu'une période définie.

## Solution complète

```powershell
# LogManager.ps1
<#
.SYNOPSIS
    Analyse et archive les fichiers logs d'une application.
.DESCRIPTION
    Ce script recherche les erreurs critiques dans les fichiers logs, génère un résumé,
    et archive les fichiers plus anciens qu'une période définie.
.PARAMETER LogPath
    Chemin vers le dossier contenant les fichiers logs.
.PARAMETER ArchivePath
    Chemin où les logs archivés seront stockés.
.PARAMETER ReportPath
    Chemin où le rapport d'erreurs sera enregistré.
.PARAMETER DaysToKeep
    Nombre de jours pendant lesquels conserver les logs avant archivage.
.PARAMETER ErrorKeywords
    Mots-clés pour identifier les erreurs critiques.
.EXAMPLE
    .\LogManager.ps1 -LogPath "C:\App\Logs" -ArchivePath "C:\App\Archives" -ReportPath "C:\App\Reports\ErrorReport.csv" -DaysToKeep 30
.EXAMPLE
    .\LogManager.ps1 -LogPath "C:\App\Logs" -ArchivePath "C:\App\Archives" -ReportPath "C:\App\Reports\ErrorReport.csv" -DaysToKeep 14 -ErrorKeywords "FATAL", "CRITICAL", "EXCEPTION"
#>

# Paramètres principaux (orchestration)
param(
    [Parameter(Mandatory=$true)]
    [string]$LogPath,

    [Parameter(Mandatory=$true)]
    [string]$ArchivePath,

    [Parameter(Mandatory=$true)]
    [string]$ReportPath,

    [Parameter(Mandatory=$false)]
    [int]$DaysToKeep = 30,

    [Parameter(Mandatory=$false)]
    [string[]]$ErrorKeywords = @("ERROR", "FATAL", "CRITICAL", "EXCEPTION")
)

#-----------------------------------------------------------
# PARTIE ORCHESTRATION
#-----------------------------------------------------------

function Start-LogManagement {
    [CmdletBinding()]
    param(
        [string]$LogPath,
        [string]$ArchivePath,
        [string]$ReportPath,
        [int]$DaysToKeep,
        [string[]]$ErrorKeywords
    )

    Write-Host "Démarrage de la gestion des logs..." -ForegroundColor Cyan

    # Vérification des chemins
    if (-not (Test-LogPath -Path $LogPath)) {
        Write-Error "Le chemin des logs n'existe pas: $LogPath"
        return
    }

    # Création des dossiers nécessaires
    New-ArchiveFolder -Path $ArchivePath
    New-ReportFolder -Path $ReportPath

    # Analyse des logs et recherche d'erreurs
    Write-Host "Analyse des logs pour rechercher des erreurs critiques..." -ForegroundColor Cyan
    $errorEntries = Find-LogErrors -LogPath $LogPath -ErrorKeywords $ErrorKeywords

    # Génération du rapport d'erreurs
    if ($errorEntries.Count -gt 0) {
        Write-Host "Génération du rapport d'erreurs..." -ForegroundColor Cyan
        Export-ErrorReport -ErrorEntries $errorEntries -ReportPath $ReportPath
        Write-Host "  ✓ $($errorEntries.Count) erreurs trouvées et exportées" -ForegroundColor Yellow
    } else {
        Write-Host "  ✓ Aucune erreur critique trouvée dans les logs" -ForegroundColor Green
    }

    # Archivage des anciens logs
    Write-Host "Archivage des logs plus anciens que $DaysToKeep jours..." -ForegroundColor Cyan
    $archiveResult = Start-LogArchival -LogPath $LogPath -ArchivePath $ArchivePath -DaysToKeep $DaysToKeep

    # Rapport final
    Write-Host "Opération terminée!" -ForegroundColor Green
    Write-Host "  - Erreurs trouvées: $($errorEntries.Count)"
    Write-Host "  - Fichiers logs archivés: $($archiveResult.ArchivedCount)"
    Write-Host "  - Espace disque libéré: $([math]::Round($archiveResult.SpaceSaved / 1MB, 2)) MB"
    Write-Host "  - Rapport d'erreurs: $ReportPath"
}

#-----------------------------------------------------------
# PARTIE LOGIQUE MÉTIER
#-----------------------------------------------------------

function Test-LogPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Write-Verbose "Vérification du chemin des logs: $Path"
    return (Test-Path -Path $Path -PathType Container)
}

function New-ArchiveFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Write-Verbose "Vérification du dossier d'archive: $Path"

    if (-not (Test-Path -Path $Path)) {
        try {
            $null = New-Item -Path $Path -ItemType Directory -Force
            Write-Verbose "Dossier d'archive créé: $Path"
        } catch {
            Write-Error "Impossible de créer le dossier d'archive: $_"
            throw $_
        }
    }
}

function New-ReportFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    Write-Verbose "Vérification du dossier de rapport: $Path"

    $reportFolder = Split-Path -Path $Path -Parent

    if (-not (Test-Path -Path $reportFolder)) {
        try {
            $null = New-Item -Path $reportFolder -ItemType Directory -Force
            Write-Verbose "Dossier de rapport créé: $reportFolder"
        } catch {
            Write-Error "Impossible de créer le dossier de rapport: $_"
            throw $_
        }
    }
}

function Find-LogErrors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [Parameter(Mandatory=$true)]
        [string[]]$ErrorKeywords
    )

    Write-Verbose "Recherche d'erreurs dans les logs avec les mots-clés: $($ErrorKeywords -join ', ')"

    try {
        # Récupération de tous les fichiers logs
        $logFiles = Get-ChildItem -Path $LogPath -Filter "*.log" -File -Recurse

        $errorEntries = @()
        $keywordPattern = "(" + ($ErrorKeywords -join "|") + ")"

        foreach ($logFile in $logFiles) {
            Write-Verbose "Analyse du fichier: $($logFile.FullName)"

            # Lecture du fichier ligne par ligne
            $lineNumber = 0
            Get-Content -Path $logFile.FullName | ForEach-Object {
                $lineNumber++

                # Recherche des mots-clés d'erreur
                if ($_ -match $keywordPattern) {
                    $errorEntries += [PSCustomObject]@{
                        TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        File = $logFile.Name
                        Path = $logFile.FullName
                        LineNumber = $lineNumber
                        ErrorType = $Matches[1]  # Le mot-clé trouvé
                        Message = $_
                    }
                }
            }
        }

        return $errorEntries
    } catch {
        Write-Error "Erreur lors de la recherche d'erreurs dans les logs: $_"
        throw $_
    }
}

function Export-ErrorReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [array]$ErrorEntries,

        [Parameter(Mandatory=$true)]
        [string]$ReportPath
    )

    Write-Verbose "Exportation du rapport d'erreurs vers: $ReportPath"

    try {
        $ErrorEntries | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
        Write-Verbose "Rapport d'erreurs exporté avec succès"
    } catch {
        Write-Error "Erreur lors de l'exportation du rapport: $_"
        throw $_
    }
}

function Start-LogArchival {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [Parameter(Mandatory=$true)]
        [string]$ArchivePath,

        [Parameter(Mandatory=$true)]
        [int]$DaysToKeep
    )

    Write-Verbose "Archivage des logs plus anciens que $DaysToKeep jours"

    try {
        # Date limite
        $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)

        # Récupération des fichiers logs à archiver
        $logsToArchive = Get-ChildItem -Path $LogPath -Filter "*.log" -File -Recurse |
                        Where-Object { $_.LastWriteTime -lt $cutoffDate }

        $archiveCount = 0
        $spaceSaved = 0

        if ($logsToArchive.Count -gt 0) {
            # Création du nom de l'archive
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $archiveFileName = "LogArchive-$timestamp.zip"
            $archiveFilePath = Join-Path -Path $ArchivePath -ChildPath $archiveFileName

            # Calcul de l'espace à libérer
            $spaceSaved = ($logsToArchive | Measure-Object -Property Length -Sum).Sum

            # Création de l'archive
            Compress-Archive -Path $logsToArchive.FullName -DestinationPath $archiveFilePath -Force

            # Suppression des fichiers archivés
            $logsToArchive | ForEach-Object {
                Remove-Item -Path $_.FullName -Force
                $archiveCount++
            }

            Write-Verbose "Logs archivés dans: $archiveFilePath"
        } else {
            Write-Verbose "Aucun log à archiver"
        }

        return @{
            ArchivedCount = $archiveCount
            SpaceSaved = $spaceSaved
            ArchiveFile = if ($archiveCount -gt 0) { $archiveFilePath } else { $null }
        }
    } catch {
        Write-Error "Erreur lors de l'archivage des logs: $_"
        throw $_
    }
}

# Exécution de l'orchestration principale
Start-LogManagement -LogPath $LogPath -ArchivePath $ArchivePath -ReportPath $ReportPath -DaysToKeep $DaysToKeep -ErrorKeywords $ErrorKeywords
```

## Points clés de la solution

1. **Structure bien définie** :
   - **Orchestration** : Fonction `Start-LogManagement` qui coordonne les opérations
   - **Logique métier** : Fonctions spécifiques pour chaque tâche (vérification des chemins, recherche d'erreurs, archivage)

2. **Gestion des ressources** :
   - Vérification et création des dossiers nécessaires avant traitement
   - Calcul de l'espace libéré lors de l'archivage

3. **Recherche intelligente des erreurs** :
   - Utilisation d'expressions régulières pour rechercher efficacement plusieurs mots-clés
   - Stockage d'informations contextuelles (fichier, numéro de ligne, message)

4. **Rapport complet** :
   - Génération d'un rapport détaillé au format CSV
   - Affichage d'un résumé des opérations en fin d'exécution

5. **Paramétrage flexible** :
   - Possibilité de personnaliser les mots-clés d'erreur
   - Configuration de la période de rétention des logs

# Exercice 3 - Solution: Inventaire système multi-serveurs

## Énoncé de l'exercice
Créez un script PowerShell qui génère un inventaire système complet de plusieurs serveurs. Le script doit collecter des informations sur le matériel, les logiciels installés et les mises à jour système, puis créer un rapport consolidé au format HTML.

## Solution complète

```powershell
# SystemInventory.ps1
<#
.SYNOPSIS
    Génère un inventaire système complet pour plusieurs serveurs.
.DESCRIPTION
    Ce script collecte des informations détaillées sur le matériel, les logiciels installés
    et les mises à jour système pour plusieurs serveurs, puis génère un rapport HTML consolidé.
.PARAMETER Servers
    Liste des serveurs à analyser.
.PARAMETER OutputPath
    Chemin où le rapport HTML sera créé.
.PARAMETER Credential
    Identification à utiliser pour la connexion aux serveurs distants.
.EXAMPLE
    .\SystemInventory.ps1 -Servers "Server1","Server2" -OutputPath "C:\Reports\Inventory.html"
.EXAMPLE
    .\SystemInventory.ps1 -Servers "Server1","Server2" -OutputPath "C:\Reports\Inventory.html" -Credential (Get-Credential)
#>

# Paramètres principaux (orchestration)
param(
    [Parameter(Mandatory=$true)]
    [string[]]$Servers,

    [Parameter(Mandatory=$true)]
    [string]$OutputPath,

    [Parameter(Mandatory=$false)]
    [System.Management.Automation.PSCredential]$Credential
)

#-----------------------------------------------------------
# PARTIE ORCHESTRATION
#-----------------------------------------------------------

function Start-SystemInventory {
    [CmdletBinding()]
    param(
        [string[]]$Servers,
        [string]$OutputPath,
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Host "Démarrage de l'inventaire système pour $($Servers.Count) serveur(s)..." -ForegroundColor Cyan

    # Stockage des résultats
    $inventoryData = @{
        Timestamp = Get-Date
        Servers = @()
    }

    # Vérification du dossier de sortie
    New-OutputFolder -Path $OutputPath

    # Pour chaque serveur, collecter les informations
    foreach ($server in $Servers) {
        Write-Host "Collecte des informations sur $server..." -ForegroundColor Yellow

        try {
            # Vérification de l'accessibilité du serveur
            if (Test-ServerConnection -ServerName $server) {
                $serverData = @{
                    Name = $server
                    Status = "Online"
                    HardwareInfo = $null
                    SoftwareInfo = $null
                    UpdateInfo = $null
                    CollectionErrors = @()
                }

                # Collecte des informations matérielles
                try {
                    Write-Host "  - Collecte des informations matérielles..." -NoNewline
                    $serverData.HardwareInfo = Get-HardwareInventory -ServerName $server -Credential $Credential
                    Write-Host " OK" -ForegroundColor Green
                } catch {
                    $serverData.CollectionErrors += "Erreur matériel: $_"
                    Write-Host " ERREUR" -ForegroundColor Red
                }

                # Collecte des informations logicielles
                try {
                    Write-Host "  - Collecte des logiciels installés..." -NoNewline
                    $serverData.SoftwareInfo = Get-SoftwareInventory -ServerName $server -Credential $Credential
                    Write-Host " OK" -ForegroundColor Green
                } catch {
                    $serverData.CollectionErrors += "Erreur logiciel: $_"
                    Write-Host " ERREUR" -ForegroundColor Red
                }

                # Collecte des informations sur les mises à jour
                try {
                    Write-Host "  - Collecte des mises à jour système..." -NoNewline
                    $serverData.UpdateInfo = Get-UpdateInventory -ServerName $server -Credential $Credential
                    Write-Host " OK" -ForegroundColor Green
                } catch {
                    $serverData.CollectionErrors += "Erreur mises à jour: $_"
                    Write-Host " ERREUR" -ForegroundColor Red
                }

                # Ajout des données du serveur à l'inventaire global
                $inventoryData.Servers += $serverData

            } else {
                Write-Warning "Le serveur $server est inaccessible."
                $inventoryData.Servers += @{
                    Name = $server
                    Status = "Offline"
                    CollectionErrors = @("Le serveur est inaccessible.")
                }
            }
        } catch {
            Write-Error "Erreur lors de la collecte des informations sur $server : $_"
        }
    }

    # Génération du rapport HTML
    Write-Host "Génération du rapport HTML..." -ForegroundColor Cyan
    $htmlReport = New-InventoryReport -InventoryData $inventoryData

    # Sauvegarde du rapport
    try {
        $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        Write-Host "Rapport d'inventaire généré avec succès : $OutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors de la sauvegarde du rapport : $_"
    }
}

#-----------------------------------------------------------
# PARTIE LOGIQUE MÉTIER
#-----------------------------------------------------------

function Test-ServerConnection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName
    )

    Write-Verbose "Test de connexion vers $ServerName"

    if ($ServerName -eq "localhost" -or $ServerName -eq $env:COMPUTERNAME) {
        return $true
    }

    $pingResult = Test-Connection -ComputerName $ServerName -Count 1 -Quiet
    return $pingResult
}

function New-OutputFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    $outputFolder = Split-Path -Path $Path -Parent

    if (-not (Test-Path -Path $outputFolder)) {
        try {
            $null = New-Item -Path $outputFolder -ItemType Directory -Force
            Write-Verbose "Dossier créé : $outputFolder"
        } catch {
            Write-Error "Impossible de créer le dossier $outputFolder : $_"
            throw $_
        }
    }
}

function Get-HardwareInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Verbose "Collecte des informations matérielles sur $ServerName"

    # Préparation des paramètres pour les commandes CIM
    $cimParams = @{
        ComputerName = $ServerName
        ErrorAction = "Stop"
    }

    if ($Credential) {
        $cimParams.Credential = $Credential
    }

    # Collecte des informations
    try {
        # Informations système
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem @cimParams
        $biosInfo = Get-CimInstance -ClassName Win32_BIOS @cimParams
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem @cimParams

        # Processeur
        $processors = Get-CimInstance -ClassName Win32_Processor @cimParams | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Manufacturer = $_.Manufacturer
                Cores = $_.NumberOfCores
                LogicalProcessors = $_.NumberOfLogicalProcessors
                MaxClockSpeed = $_.MaxClockSpeed
                L2CacheSize = $_.L2CacheSize
                L3CacheSize = $_.L3CacheSize
            }
        }

        # Mémoire RAM
        $totalMemoryGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
        $memoryModules = Get-CimInstance -ClassName Win32_PhysicalMemory @cimParams | ForEach-Object {
            [PSCustomObject]@{
                Capacity = [math]::Round($_.Capacity / 1GB, 2)
                Manufacturer = $_.Manufacturer
                Speed = $_.Speed
                DeviceLocator = $_.DeviceLocator
            }
        }

        # Disques
        $disks = Get-CimInstance -ClassName Win32_DiskDrive @cimParams | ForEach-Object {
            $diskPartitions = Get-CimInstance -ClassName Win32_DiskPartition -Filter "DiskIndex=$($_.Index)" @cimParams

            [PSCustomObject]@{
                Model = $_.Model
                InterfaceType = $_.InterfaceType
                Size = [math]::Round($_.Size / 1GB, 2)
                Partitions = $diskPartitions.Count
                SerialNumber = $_.SerialNumber
            }
        }

        # Volumes logiques
        $volumes = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" @cimParams | ForEach-Object {
            [PSCustomObject]@{
                DriveLetter = $_.DeviceID
                VolumeLabel = $_.VolumeName
                Size = [math]::Round($_.Size / 1GB, 2)
                FreeSpace = [math]::Round($_.FreeSpace / 1GB, 2)
                PercentFree = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                FileSystem = $_.FileSystem
            }
        }

        # Interfaces réseau
        $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapter -Filter "PhysicalAdapter=True" @cimParams | ForEach-Object {
            $config = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -Filter "Index=$($_.Index)" @cimParams

            [PSCustomObject]@{
                Name = $_.Name
                AdapterType = $_.AdapterType
                MACAddress = $_.MACAddress
                IPAddresses = $config.IPAddress
                Status = $_.NetConnectionStatus
            }
        }

        # Construction de l'objet de résultat
        return [PSCustomObject]@{
            SystemInfo = [PSCustomObject]@{
                Manufacturer = $computerSystem.Manufacturer
                Model = $computerSystem.Model
                SerialNumber = $biosInfo.SerialNumber
                BIOSVersion = $biosInfo.SMBIOSBIOSVersion
                OSName = $osInfo.Caption
                OSVersion = $osInfo.Version
                OSBuild = $osInfo.BuildNumber
                LastBootUpTime = $osInfo.LastBootUpTime
                InstallDate = $osInfo.InstallDate
            }
            Processors = $processors
            Memory = [PSCustomObject]@{
                TotalGB = $totalMemoryGB
                Modules = $memoryModules
            }
            Storage = [PSCustomObject]@{
                PhysicalDisks = $disks
                LogicalVolumes = $volumes
            }
            Network = $networkAdapters
        }
    } catch {
        Write-Error "Erreur lors de la collecte des informations matérielles : $_"
        throw $_
    }
}

function Get-SoftwareInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Verbose "Collecte des logiciels installés sur $ServerName"

    # Préparation des paramètres pour les commandes CIM/WMI
    $params = @{
        ComputerName = $ServerName
        ErrorAction = "Stop"
    }

    if ($Credential) {
        $params.Credential = $Credential
    }

    try {
        # Logiciels installés (différentes méthodes selon la version de Windows)
        $installedSoftware = @()

        # Méthode 1: Win32_Product (lente mais standard)
        try {
            $installedSoftware += Get-CimInstance -ClassName Win32_Product @params | Select-Object -Property @{
                Name = 'Name'; Expression = {$_.Name}
            }, @{
                Name = 'Version'; Expression = {$_.Version}
            }, @{
                Name = 'Vendor'; Expression = {$_.Vendor}
            }, @{
                Name = 'InstallDate'; Expression = {$_.InstallDate}
            }, @{
                Name = 'Source'; Expression = {'Win32_Product'}
            }
        } catch {
            Write-Warning "Impossible de récupérer les logiciels via Win32_Product: $_"
        }

        # Méthode 2: Registre (plus rapide, mais requiert accès au registre distant)
        $registryPaths = @(
            "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall",
            "SOFTWARE\\Wow6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
        )

        try {
            foreach ($path in $registryPaths) {
                # Utilisation d'une session PowerShell à distance
                $scriptBlock = {
                    param($path)
                    try {
                        $baseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $env:COMPUTERNAME)
                        $subKey = $baseKey.OpenSubKey($path)

                        if ($subKey) {
                            foreach ($keyName in $subKey.GetSubKeyNames()) {
                                $itemKey = $subKey.OpenSubKey($keyName)
                                $displayName = $itemKey.GetValue('DisplayName')

                                if ($displayName) {
                                    [PSCustomObject]@{
                                        Name = $displayName
                                        Version = $itemKey.GetValue('DisplayVersion')
                                        Vendor = $itemKey.GetValue('Publisher')
                                        InstallDate = $itemKey.GetValue('InstallDate')
                                        Source = 'Registry'
                                    }
                                }
                            }
                        }
                    } catch {
                        Write-Warning "Erreur d'accès au registre: $_"
                    }
                }

                $invokeParams = @{
                    ComputerName = $ServerName
                    ScriptBlock = $scriptBlock
                    ArgumentList = $path
                    ErrorAction = 'SilentlyContinue'
                }

                if ($Credential) {
                    $invokeParams.Credential = $Credential
                }

                $registrySoftware = Invoke-Command @invokeParams
                $installedSoftware += $registrySoftware
            }
        } catch {
            Write-Warning "Impossible d'accéder au registre distant: $_"
        }

        # Fonctionnalités Windows
        $windowsFeatures = @()
        try {
            $scriptBlock = {
                # Vérifier si on est sur un serveur ou un poste client
                $isServer = (Get-CimInstance -ClassName Win32_OperatingSystem).ProductType -ne 1

                if ($isServer) {
                    # Pour les serveurs: Get-WindowsFeature
                    if (Get-Command Get-WindowsFeature -ErrorAction SilentlyContinue) {
                        Get-WindowsFeature | Where-Object { $_.Installed -eq $true } | ForEach-Object {
                            [PSCustomObject]@{
                                Name = $_.DisplayName
                                FeatureName = $_.Name
                                Installed = $_.Installed
                                Type = "Server Role/Feature"
                            }
                        }
                    }
                } else {
                    # Pour les postes clients: Get-WindowsOptionalFeature
                    if (Get-Command Get-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
                        Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq "Enabled" } | ForEach-Object {
                            [PSCustomObject]@{
                                Name = $_.FeatureName
                                FeatureName = $_.FeatureName
                                Installed = ($_.State -eq "Enabled")
                                Type = "Windows Optional Feature"
                            }
                        }
                    }
                }
            }

            $invokeParams = @{
                ComputerName = $ServerName
                ScriptBlock = $scriptBlock
                ErrorAction = 'SilentlyContinue'
            }

            if ($Credential) {
                $invokeParams.Credential = $Credential
            }

            $windowsFeatures = Invoke-Command @invokeParams
        } catch {
            Write-Warning "Impossible de récupérer les fonctionnalités Windows: $_"
        }

        # Construction du résultat final
        return [PSCustomObject]@{
            InstalledSoftware = $installedSoftware | Where-Object { $_.Name -ne $null } | Sort-Object -Property Name
            WindowsFeatures = $windowsFeatures
            SoftwareCount = ($installedSoftware | Where-Object { $_.Name -ne $null }).Count
            FeaturesCount = $windowsFeatures.Count
        }
    } catch {
        Write-Error "Erreur lors de la collecte des logiciels installés: $_"
        throw $_
    }
}

function Get-UpdateInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Verbose "Collecte des mises à jour système sur $ServerName"

    try {
        # Utilisation d'une session PowerShell à distance
        $scriptBlock = {
            # Récupération des mises à jour installées via Windows Update API
            try {
                $session = New-Object -ComObject "Microsoft.Update.Session"
                $searcher = $session.CreateUpdateSearcher()
                $historyCount = $searcher.GetTotalHistoryCount()

                # Récupération des 100 dernières mises à jour
                $maxUpdates = 100
                $updateHistory = $searcher.QueryHistory(0, [Math]::Min($historyCount, $maxUpdates))

                $updates = @()
                foreach ($update in $updateHistory) {
                    $updates += [PSCustomObject]@{
                        Title = $update.Title
                        Description = $update.Description
                        Date = $update.Date
                        Operation = switch ($update.Operation) {
                            1 { "Installation" }
                            2 { "Désinstallation" }
                            3 { "Autre" }
                            default { "Inconnu" }
                        }
                        Status = switch ($update.ResultCode) {
                            0 { "Non démarré" }
                            1 { "En cours" }
                            2 { "Réussi" }
                            3 { "Échec" }
                            4 { "Annulé" }
                            5 { "Erreur" }
                            default { "Inconnu" }
                        }
                        HResult = $update.HResult
                        UpdateID = $update.UpdateIdentity.UpdateID
                        RevisionNumber = $update.UpdateIdentity.RevisionNumber
                    }
                }
                $updates
            } catch {
                Write-Warning "Erreur lors de l'accès à l'API Windows Update: $_"
                return $null
            }
        }

        $invokeParams = @{
            ComputerName = $ServerName
            ScriptBlock = $scriptBlock
            ErrorAction = 'Stop'
        }

        if ($Credential) {
            $invokeParams.Credential = $Credential
        }

        $updateHistory = Invoke-Command @invokeParams

        # Informations sur les correctifs de sécurité (hotfixes)
        $hotfixParams = @{
            ComputerName = $ServerName
            ErrorAction = 'SilentlyContinue'
        }

        if ($Credential) {
            $hotfixParams.Credential = $Credential
        }

        $hotfixes = Get-HotFix @hotfixParams | Select-Object HotFixID, Description, InstalledOn, InstalledBy

        # Informations sur les paramètres Windows Update
        $updateConfigScript = {
            try {
                $automaticUpdates = New-Object -ComObject "Microsoft.Update.AutoUpdate"
                $updateSettings = $automaticUpdates.Settings

                [PSCustomObject]@{
                    NotificationLevel = switch ($updateSettings.NotificationLevel) {
                        0 { "Non configuré" }
                        1 { "Jamais vérifier les mises à jour" }
                        2 { "Vérifier mais laisser l'utilisateur choisir" }
                        3 { "Télécharger et notification" }
                        4 { "Installation automatique" }
                        default { "Inconnu" }
                    }
                    UpdateServiceEnabled = $updateSettings.ServiceEnabled
                    IncludeRecommendedUpdates = $updateSettings.IncludeRecommendedUpdates
                    NonAdministratorsElevated = $updateSettings.NonAdministratorsElevated
                    ScheduledInstallationDay = switch ($updateSettings.ScheduledInstallationDay) {
                        0 { "Tous les jours" }
                        1 { "Dimanche" }
                        2 { "Lundi" }
                        3 { "Mardi" }
                        4 { "Mercredi" }
                        5 { "Jeudi" }
                        6 { "Vendredi" }
                        7 { "Samedi" }
                        default { "Non programmé" }
                    }
                    ScheduledInstallationTime = $updateSettings.ScheduledInstallationTime
                }
            } catch {
                Write-Warning "Erreur lors de l'accès aux paramètres Windows Update: $_"
                return $null
            }
        }

        $invokeParamsConfig = @{
            ComputerName = $ServerName
            ScriptBlock = $updateConfigScript
            ErrorAction = 'SilentlyContinue'
        }

        if ($Credential) {
            $invokeParamsConfig.Credential = $Credential
        }

        $updateConfig = Invoke-Command @invokeParamsConfig

        # Construction du résultat final
        return [PSCustomObject]@{
            UpdateHistory = $updateHistory
            Hotfixes = $hotfixes
            UpdateConfiguration = $updateConfig
            LastUpdates = $updateHistory | Sort-Object -Property Date -Descending | Select-Object -First 10
            PendingReboot = Test-PendingReboot -ServerName $ServerName -Credential $Credential
        }
    } catch {
        Write-Error "Erreur lors de la collecte des mises à jour système: $_"
        throw $_
    }
}

function Test-PendingReboot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServerName,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Verbose "Vérification si un redémarrage est en attente sur $ServerName"

    try {
        $scriptBlock = {
            $pendingReboot = $false
            $reasons = @()

            # Component-Based Servicing
            if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
                $pendingReboot = $true
                $reasons += "Component-Based Servicing"
            }

            # Windows Update
            if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
                $pendingReboot = $true
                $reasons += "Windows Update"
            }

            # PendingFileRenameOperations
            if (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) {
                $pendingReboot = $true
                $reasons += "PendingFileRenameOperations"
            }

            # SCCM Client
            try {
                $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
                $status = $util.DetermineIfRebootPending()
                if (($status -ne $null) -and ($status.RebootPending -or $status.IsHardRebootPending)) {
                    $pendingReboot = $true
                    $reasons += "SCCM Client"
                }
            } catch {
                # SCCM client pas installé
            }

            # Retourne le résultat
            [PSCustomObject]@{
                PendingReboot = $pendingReboot
                Reasons = $reasons
            }
        }

        $invokeParams = @{
            ComputerName = $ServerName
            ScriptBlock = $scriptBlock
            ErrorAction = 'Stop'
        }

        if ($Credential) {
            $invokeParams.Credential = $Credential
        }

        return Invoke-Command @invokeParams
    } catch {
        Write-Error "Erreur lors de la vérification du redémarrage en attente: $_"
        return [PSCustomObject]@{
            PendingReboot = $false
            Reasons = @("Erreur de vérification")
        }
    }
}

function New-InventoryReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$InventoryData
    )

    Write-Verbose "Génération du rapport HTML"

    try {
        # Génération du contenu HTML
        $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'inventaire système</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; color: #333; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { color: #2980b9; margin-top: 20px; border-bottom: 1px solid #ddd; padding-bottom: 5px; }
        h3 { color: #3498db; margin-top: 15px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th { background-color: #2980b9; color: white; text-align: left; padding: 8px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .server-card { border: 1px solid #ddd; border-radius: 5px; margin-bottom: 20px; overflow: hidden; }
        .server-header { background-color: #2c3e50; color: white; padding: 10px; }
        .server-content { padding: 15px; }
        .status-online { color: green; font-weight: bold; }
        .status-offline { color: red; font-weight: bold; }
        .error-list { color: #e74c3c; }
        .info-section { margin-bottom: 20px; }
        .scroll-table { overflow-x: auto; }
        .footer { margin-top: 30px; text-align: center; font-size: 0.8em; color: #7f8c8d; }
        .disk-free-low { background-color: #ffcccc; }
        .disk-free-warning { background-color: #ffffcc; }
        .disk-free-ok { background-color: #ccffcc; }
        .collapsible { cursor: pointer; }
        .content { display: none; overflow: hidden; }
    </style>
</head>
<body>
    <h1>Rapport d'inventaire système</h1>
    <p><strong>Date du rapport:</strong> $($InventoryData.Timestamp)</p>
    <p><strong>Nombre de serveurs analysés:</strong> $($InventoryData.Servers.Count)</p>
"@

        # Fonction pour créer une table HTML à partir d'un objet
        function ConvertTo-HtmlTable {
            param (
                [Parameter(Mandatory=$true)]
                $Data,

                [Parameter(Mandatory=$false)]
                [string]$Title,

                [Parameter(Mandatory=$false)]
                [switch]$NoHeader
            )

            if ($Data -eq $null -or ($Data -is [array] -and $Data.Count -eq 0)) {
                return "<p><em>Aucune donnée disponible</em></p>"
            }

            $html = ""
            if ($Title) {
                $html += "<h3>$Title</h3>"
            }

            $html += "<div class='scroll-table'><table>"

            # Entêtes
            if (-not $NoHeader) {
                $properties = $Data | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                $html += "<tr>"
                foreach ($prop in $properties) {
                    $html += "<th>$prop</th>"
                }
                $html += "</tr>"
            }

            # Données
            if ($Data -is [array]) {
                foreach ($item in $Data) {
                    $html += "<tr>"
                    $properties = $item | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                    foreach ($prop in $properties) {
                        $value = $item.$prop

                        # Mise en forme spéciale pour certaines propriétés
                        if ($prop -eq "PercentFree") {
                            if ($value -lt 10) {
                                $html += "<td class='disk-free-low'>$value%</td>"
                            } elseif ($value -lt 20) {
                                $html += "<td class='disk-free-warning'>$value%</td>"
                            } else {
                                $html += "<td class='disk-free-ok'>$value%</td>"
                            }
                        } elseif ($prop -eq "Status" -and $value -eq "Online") {
                            $html += "<td class='status-online'>$value</td>"
                        } elseif ($prop -eq "Status" -and $value -eq "Offline") {
                            $html += "<td class='status-offline'>$value</td>"
                        } elseif ($value -is [array]) {
                            $html += "<td>$(($value | ForEach-Object { "$_" }) -join ", ")</td>"
                        } elseif ($value -is [DateTime]) {
                            $html += "<td>$($value.ToString('yyyy-MM-dd HH:mm:ss'))</td>"
                        } else {
                            $html += "<td>$value</td>"
                        }
                    }
                    $html += "</tr>"
                }
            } else {
                # Si c'est un objet simple et non un tableau
                $html += "<tr>"
                $properties = $Data | Get-Member -MemberType Properties | Select-Object -ExpandProperty Name
                foreach ($prop in $properties) {
                    $value = $Data.$prop
                    $html += "<td>$value</td>"
                }
                $html += "</tr>"
            }

            $html += "</table></div>"
            return $html
        }

        # Génération du contenu pour chaque serveur
        $serversHtml = ""
        foreach ($server in $InventoryData.Servers) {
            $statusClass = if ($server.Status -eq "Online") { "status-online" } else { "status-offline" }

            $serversHtml += @"
    <div class="server-card">
        <div class="server-header">
            <h2>$($server.Name) - <span class="$statusClass">$($server.Status)</span></h2>
        </div>
        <div class="server-content">
"@

            # Si le serveur est hors ligne, afficher seulement les erreurs
            if ($server.Status -eq "Offline") {
                $serversHtml += @"
            <div class="error-list">
                <h3>Erreurs</h3>
                <ul>
"@
                foreach ($error in $server.CollectionErrors) {
                    $serversHtml += "<li>$error</li>"
                }
                $serversHtml += @"
                </ul>
            </div>
"@
            } else {
                # Informations système
                if ($server.HardwareInfo -ne $null) {
                    $serversHtml += @"
            <div class="info-section">
                <h3 class="collapsible">Informations système</h3>
                <div class="content">
"@

                    $systemInfo = $server.HardwareInfo.SystemInfo
                    $systemInfoTable = @"
                    <table>
                        <tr><th>Propriété</th><th>Valeur</th></tr>
                        <tr><td>Fabricant</td><td>$($systemInfo.Manufacturer)</td></tr>
                        <tr><td>Modèle</td><td>$($systemInfo.Model)</td></tr>
                        <tr><td>Numéro de série</td><td>$($systemInfo.SerialNumber)</td></tr>
                        <tr><td>Version BIOS</td><td>$($systemInfo.BIOSVersion)</td></tr>
                        <tr><td>Système d'exploitation</td><td>$($systemInfo.OSName)</td></tr>
                        <tr><td>Version OS</td><td>$($systemInfo.OSVersion)</td></tr>
                        <tr><td>Build OS</td><td>$($systemInfo.OSBuild)</td></tr>
                        <tr><td>Dernier démarrage</td><td>$($systemInfo.LastBootUpTime)</td></tr>
                        <tr><td>Date d'installation</td><td>$($systemInfo.InstallDate)</td></tr>
                    </table>
"@
                    $serversHtml += $systemInfoTable

                    # Processeurs
                    $serversHtml += "<h4>Processeurs</h4>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.HardwareInfo.Processors

                    # Mémoire
                    $serversHtml += "<h4>Mémoire</h4>"
                    $serversHtml += "<p>Total: $($server.HardwareInfo.Memory.TotalGB) GB</p>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.HardwareInfo.Memory.Modules

                    # Stockage
                    $serversHtml += "<h4>Disques physiques</h4>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.HardwareInfo.Storage.PhysicalDisks

                    $serversHtml += "<h4>Volumes logiques</h4>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.HardwareInfo.Storage.LogicalVolumes

                    # Réseau
                    $serversHtml += "<h4>Interfaces réseau</h4>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.HardwareInfo.Network

                    $serversHtml += @"
                </div>
            </div>
"@
                }

                # Logiciels installés
                if ($server.SoftwareInfo -ne $null) {
                    $serversHtml += @"
            <div class="info-section">
                <h3 class="collapsible">Logiciels installés ($($server.SoftwareInfo.SoftwareCount))</h3>
                <div class="content">
"@
                    $serversHtml += ConvertTo-HtmlTable -Data $server.SoftwareInfo.InstalledSoftware

                    $serversHtml += "<h4>Fonctionnalités Windows ($($server.SoftwareInfo.FeaturesCount))</h4>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.SoftwareInfo.WindowsFeatures

                    $serversHtml += @"
                </div>
            </div>
"@
                }

                # Mises à jour
                if ($server.UpdateInfo -ne $null) {
                    $serversHtml += @"
            <div class="info-section">
                <h3 class="collapsible">Mises à jour système</h3>
                <div class="content">
"@

                    # Configuration de Windows Update
                    if ($server.UpdateInfo.UpdateConfiguration -ne $null) {
                        $serversHtml += "<h4>Configuration de Windows Update</h4>"
                        $serversHtml += ConvertTo-HtmlTable -Data $server.UpdateInfo.UpdateConfiguration
                    }

                    # Redémarrage en attente
                    $pendingReboot = $server.UpdateInfo.PendingReboot
                    $rebootStatus = if ($pendingReboot.PendingReboot) {
                        "<span style='color:red;font-weight:bold'>Oui - $($pendingReboot.Reasons -join ", ")</span>"
                    } else {
                        "<span style='color:green;'>Non</span>"
                    }

                    $serversHtml += "<h4>Redémarrage en attente</h4>"
                    $serversHtml += "<p>Statut: $rebootStatus</p>"

                    # 10 dernières mises à jour
                    $serversHtml += "<h4>10 dernières mises à jour</h4>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.UpdateInfo.LastUpdates

                    # Correctifs installés
                    $serversHtml += "<h4>Correctifs de sécurité installés</h4>"
                    $serversHtml += ConvertTo-HtmlTable -Data $server.UpdateInfo.Hotfixes

                    $serversHtml += @"
                </div>
            </div>
"@
                }

                # Erreurs
                if ($server.CollectionErrors.Count -gt 0) {
                    $serversHtml += @"
            <div class="error-list">
                <h3>Erreurs de collecte</h3>
                <ul>
"@
                    foreach ($error in $server.CollectionErrors) {
                        $serversHtml += "<li>$error</li>"
                    }
                    $serversHtml += @"
                </ul>
            </div>
"@
                }
            }

            $serversHtml += @"
        </div>
    </div>
"@
        }

        # Pied de page et script JavaScript
        $htmlFooter = @"
    <div class="footer">
        <p>Rapport généré le $($InventoryData.Timestamp) avec PowerShell</p>
    </div>

    <script>
    // Script pour rendre les sections pliables/dépliables
    var coll = document.getElementsByClassName("collapsible");
    for (var i = 0; i < coll.length; i++) {
        coll[i].addEventListener("click", function() {
            this.classList.toggle("active");
            var content = this.nextElementSibling;
            if (content.style.display === "block") {
                content.style.display = "none";
            } else {
                content.style.display = "block";
            }
        });
    }
    </script>
</body>
</html>
"@

        # Assemblage du rapport complet
        return $htmlHeader + $serversHtml + $htmlFooter
    } catch {
        Write-Error "Erreur lors de la génération du rapport HTML: $_"
        throw $_
    }
}

# Exécution de l'orchestration principale
Start-SystemInventory -Servers $Servers -OutputPath $OutputPath -Credential $Credential
```

## Points clés de la solution

1. **Architecture bien structurée** :
   - **Orchestration** : La fonction `Start-SystemInventory` coordonne toutes les opérations
   - **Logique métier** : Des fonctions spécialisées pour chaque type d'information à collecter

2. **Collecte d'informations complète** :
   - **Matériel** : Processeurs, mémoire, disques, réseau
   - **Logiciels** : Applications installées, fonctionnalités Windows
   - **Mises à jour** : Historique Windows Update, correctifs de sécurité, configuration de mise à jour

3. **Gestion efficace des erreurs** :
   - Traitement des erreurs à plusieurs niveaux
   - Isolation des échecs pour continuer l'inventaire même en cas de problème
   - Rapport des erreurs dans le document final

4. **Compatibilité multi-systèmes** :
   - Adaptation aux environnements serveur et poste de travail
   - Utilisation de techniques alternatives quand une méthode échoue

5. **Rapport HTML interactif** :
   - Design moderne avec sections pliables/dépliables
   - Mise en forme conditionnelle (espace disque critique, serveurs hors ligne)
   - Compatible avec tous les navigateurs modernes

6. **Extensibilité** :
   - Structure modulaire permettant d'ajouter facilement de nouveaux types d'informations
   - Paramétrage flexible pour adapter le script à différents environnements

# Exercice 4 - Solution: Surveillance de ressources avec alertes

## Énoncé de l'exercice
Créez un script PowerShell qui surveille les ressources système (CPU, mémoire, disque, services critiques) et envoie des alertes par email lorsque certains seuils sont dépassés. Le script doit utiliser une séparation claire entre l'orchestration et la logique métier.

## Solution complète

```powershell
# ResourceMonitor.ps1
<#
.SYNOPSIS
    Surveille les ressources système et envoie des alertes par email.
.DESCRIPTION
    Ce script surveille l'utilisation CPU, mémoire, espace disque et l'état des services critiques.
    Il envoie des alertes par email lorsque les seuils définis sont dépassés.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration JSON.
.PARAMETER LogPath
    Chemin où les logs seront enregistrés.
.PARAMETER EmailOnly
    Si spécifié, envoie uniquement les alertes par email sans les afficher dans la console.
.EXAMPLE
    .\ResourceMonitor.ps1 -ConfigPath "C:\Monitoring\config.json" -LogPath "C:\Monitoring\Logs"
.EXAMPLE
    .\ResourceMonitor.ps1 -ConfigPath "C:\Monitoring\config.json" -LogPath "C:\Monitoring\Logs" -EmailOnly
#>

# Paramètres principaux (orchestration)
param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigPath,

    [Parameter(Mandatory=$true)]
    [string]$LogPath,

    [Parameter(Mandatory=$false)]
    [switch]$EmailOnly
)

#-----------------------------------------------------------
# PARTIE ORCHESTRATION
#-----------------------------------------------------------

function Start-ResourceMonitoring {
    [CmdletBinding()]
    param(
        [string]$ConfigPath,
        [string]$LogPath,
        [switch]$EmailOnly
    )

    Write-Host "Démarrage de la surveillance des ressources..." -ForegroundColor Cyan

    # Vérification et chargement de la configuration
    try {
        $config = Import-MonitoringConfig -ConfigPath $ConfigPath
        Write-Host "Configuration chargée avec succès." -ForegroundColor Green
    } catch {
        Write-Error "Erreur lors du chargement de la configuration: $_"
        return
    }

    # Initialisation des logs
    try {
        Initialize-LogFolder -LogPath $LogPath
        $logFilePath = Join-Path -Path $LogPath -ChildPath "ResourceMonitor_$(Get-Date -Format 'yyyyMMdd').log"
        Write-Log -Message "Démarrage de la surveillance des ressources" -LogPath $logFilePath
    } catch {
        Write-Error "Erreur lors de l'initialisation des logs: $_"
        return
    }

    # Afficher les seuils configurés
    if (-not $EmailOnly) {
        Write-Host "Seuils configurés:"
        Write-Host "  - CPU: $($config.Thresholds.CPU)%"
        Write-Host "  - Mémoire: $($config.Thresholds.Memory)%"
        Write-Host "  - Espace disque: $($config.Thresholds.DiskSpace)%"
        Write-Host "  - Services critiques: $($config.CriticalServices -join ', ')"
        Write-Host "  - Intervalle de vérification: $($config.CheckIntervalMinutes) minutes"
        Write-Host "Surveillance en cours..."
    }

    # Boucle principale de surveillance
    try {
        while ($true) {
            $timestamp = Get-Date
            $alerts = @()

            # Surveillance CPU
            try {
                $cpuUsage = Get-CpuUsage
                $cpuStatus = Test-ThresholdExceeded -Value $cpuUsage -Threshold $config.Thresholds.CPU

                if ($cpuStatus.Exceeded) {
                    $alertMessage = "Alerte CPU: Utilisation à $($cpuUsage)% (seuil: $($config.Thresholds.CPU)%)"
                    $alerts += $alertMessage
                    Write-Log -Message $alertMessage -LogPath $logFilePath

                    if (-not $EmailOnly) {
                        Write-Host $alertMessage -ForegroundColor Red
                    }
                } elseif (-not $EmailOnly) {
                    Write-Host "CPU: $cpuUsage% - OK" -ForegroundColor Green
                }
            } catch {
                Write-Log -Message "Erreur lors de la surveillance CPU: $_" -LogPath $logFilePath -Level "ERROR"
            }

            # Surveillance mémoire
            try {
                $memoryUsage = Get-MemoryUsage
                $memoryStatus = Test-ThresholdExceeded -Value $memoryUsage -Threshold $config.Thresholds.Memory

                if ($memoryStatus.Exceeded) {
                    $alertMessage = "Alerte Mémoire: Utilisation à $($memoryUsage)% (seuil: $($config.Thresholds.Memory)%)"
                    $alerts += $alertMessage
                    Write-Log -Message $alertMessage -LogPath $logFilePath

                    if (-not $EmailOnly) {
                        Write-Host $alertMessage -ForegroundColor Red
                    }
                } elseif (-not $EmailOnly) {
                    Write-Host "Mémoire: $memoryUsage% - OK" -ForegroundColor Green
                }
            } catch {
                Write-Log -Message "Erreur lors de la surveillance mémoire: $_" -LogPath $logFilePath -Level "ERROR"
            }

            # Surveillance espace disque
            try {
                $diskAlerts = @()
                $disks = Get-DiskUsage

                foreach ($disk in $disks) {
                    $diskStatus = Test-ThresholdExceeded -Value $disk.PercentUsed -Threshold $config.Thresholds.DiskSpace

                    if ($diskStatus.Exceeded) {
                        $alertMessage = "Alerte Espace Disque: Lecteur $($disk.DriveLetter) à $($disk.PercentUsed)% d'utilisation (seuil: $($config.Thresholds.DiskSpace)%)"
                        $diskAlerts += $alertMessage
                        $alerts += $alertMessage
                        Write-Log -Message $alertMessage -LogPath $logFilePath

                        if (-not $EmailOnly) {
                            Write-Host $alertMessage -ForegroundColor Red
                        }
                    } elseif (-not $EmailOnly) {
                        Write-Host "Disque $($disk.DriveLetter): $($disk.PercentUsed)% utilisé - OK" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Log -Message "Erreur lors de la surveillance des disques: $_" -LogPath $logFilePath -Level "ERROR"
            }

            # Surveillance services critiques
            try {
                $serviceAlerts = @()
                $services = Test-CriticalServices -ServiceNames $config.CriticalServices

                foreach ($service in $services) {
                    if (-not $service.IsRunning) {
                        $alertMessage = "Alerte Service: Le service critique '$($service.Name)' n'est pas en cours d'exécution."
                        $serviceAlerts += $alertMessage
                        $alerts += $alertMessage
                        Write-Log -Message $alertMessage -LogPath $logFilePath

                        if (-not $EmailOnly) {
                            Write-Host $alertMessage -ForegroundColor Red
                        }
                    } elseif (-not $EmailOnly) {
                        Write-Host "Service $($service.Name): En cours d'exécution - OK" -ForegroundColor Green
                    }
                }
            } catch {
                Write-Log -Message "Erreur lors de la surveillance des services: $_" -LogPath $logFilePath -Level "ERROR"
            }

            # Envoi des alertes par email si nécessaire
            if ($alerts.Count -gt 0) {
                $emailBody = "Alertes de surveillance des ressources sur $($env:COMPUTERNAME) à $(Get-Date)`n`n"
                $emailBody += $alerts | ForEach-Object { "- $_`n" }

                try {
                    Send-AlertEmail -To $config.Email.To -Subject "Alerte Ressources Système - $($env:COMPUTERNAME)" -Body $emailBody -SmtpServer $config.Email.SmtpServer -Port $config.Email.Port -UseSsl:$config.Email.UseSsl -Credential $config.Email.Credential
                    Write-Log -Message "Email d'alerte envoyé avec succès" -LogPath $logFilePath
                } catch {
                    Write-Log -Message "Erreur lors de l'envoi de l'email d'alerte: $_" -LogPath $logFilePath -Level "ERROR"
                    if (-not $EmailOnly) {
                        Write-Host "Erreur lors de l'envoi de l'email: $_" -ForegroundColor Red
                    }
                }
            }

            # Attente avant la prochaine vérification
            if (-not $EmailOnly) {
                Write-Host "Prochaine vérification dans $($config.CheckIntervalMinutes) minutes..." -ForegroundColor Gray
            }
            Start-Sleep -Seconds ($config.CheckIntervalMinutes * 60)
        }
    } catch {
        Write-Log -Message "Erreur critique dans la boucle de surveillance: $_" -LogPath $logFilePath -Level "ERROR"
        Write-Error "Erreur critique: $_"
    }
}

#-----------------------------------------------------------
# PARTIE LOGIQUE MÉTIER
#-----------------------------------------------------------

function Import-MonitoringConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigPath
    )

    Write-Verbose "Chargement de la configuration depuis $ConfigPath"

    if (-not (Test-Path -Path $ConfigPath)) {
        throw "Le fichier de configuration n'existe pas: $ConfigPath"
    }

    try {
        $configContent = Get-Content -Path $ConfigPath -Raw
        $config = ConvertFrom-Json -InputObject $configContent

        # Vérification des paramètres obligatoires
        if (-not $config.Thresholds -or -not $config.Thresholds.CPU -or -not $config.Thresholds.Memory -or -not $config.Thresholds.DiskSpace) {
            throw "Configuration incomplète: Les seuils (Thresholds) doivent être définis pour CPU, Memory et DiskSpace."
        }

        if (-not $config.CheckIntervalMinutes) {
            $config | Add-Member -MemberType NoteProperty -Name "CheckIntervalMinutes" -Value 5
        }

        if (-not $config.CriticalServices) {
            $config | Add-Member -MemberType NoteProperty -Name "CriticalServices" -Value @()
        }

        # Création d'identifiants si configurés
        if ($config.Email -and $config.Email.Username -and $config.Email.Password) {
            $securePassword = ConvertTo-SecureString -String $config.Email.Password -AsPlainText -Force
            $credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $config.Email.Username, $securePassword
            $config.Email | Add-Member -MemberType NoteProperty -Name "Credential" -Value $credential
        }

        return $config
    } catch {
        throw "Erreur lors du chargement de la configuration: $_"
    }
}

function Initialize-LogFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogPath
    )

    Write-Verbose "Initialisation du dossier de logs: $LogPath"

    if (-not (Test-Path -Path $LogPath)) {
        try {
            $null = New-Item -Path $LogPath -ItemType Directory -Force
            Write-Verbose "Dossier de logs créé: $LogPath"
        } catch {
            throw "Impossible de créer le dossier de logs: $_"
        }
    }
}

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$LogPath,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    try {
        Add-Content -Path $LogPath -Value $logMessage
    } catch {
        Write-Error "Impossible d'écrire dans le fichier de log: $_"
    }
}

function Get-CpuUsage {
    [CmdletBinding()]
    param()

    Write-Verbose "Récupération de l'utilisation CPU"

    try {
        $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
        $cpuUsage = [math]::Round($cpuLoad.Average, 2)
        return $cpuUsage
    } catch {
        throw "Erreur lors de la récupération de l'utilisation CPU: $_"
    }
}

function Get-MemoryUsage {
    [CmdletBinding()]
    param()

    Write-Verbose "Récupération de l'utilisation mémoire"

    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        $physicalMemory = $os.TotalVisibleMemorySize
        $freeMemory = $os.FreePhysicalMemory
        $usedMemory = $physicalMemory - $freeMemory
        $memoryUsage = [math]::Round(($usedMemory / $physicalMemory) * 100, 2)
        return $memoryUsage
    } catch {
        throw "Erreur lors de la récupération de l'utilisation mémoire: $_"
    }
}

function Get-DiskUsage {
    [CmdletBinding()]
    param()

    Write-Verbose "Récupération de l'utilisation des disques"

    try {
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
            $freeSpacePercent = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
            $usedSpacePercent = 100 - $freeSpacePercent

            [PSCustomObject]@{
                DriveLetter = $_.DeviceID
                VolumeLabel = $_.VolumeName
                TotalSizeGB = [math]::Round($_.Size / 1GB, 2)
                FreeSpaceGB = [math]::Round($_.FreeSpace / 1GB, 2)
                PercentFree = $freeSpacePercent
                PercentUsed = $usedSpacePercent
            }
        }

        return $disks
    } catch {
        throw "Erreur lors de la récupération de l'utilisation des disques: $_"
    }
}

function Test-ThresholdExceeded {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [double]$Value,

        [Parameter(Mandatory=$true)]
        [double]$Threshold
    )

    $exceeded = $Value -ge $Threshold

    return [PSCustomObject]@{
        Value = $Value
        Threshold = $Threshold
        Exceeded = $exceeded
    }
}

function Test-CriticalServices {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$ServiceNames
    )

    Write-Verbose "Vérification des services critiques"

    $results = @()

    foreach ($serviceName in $ServiceNames) {
        try {
            $service = Get-Service -Name $serviceName -ErrorAction Stop

            $results += [PSCustomObject]@{
                Name = $serviceName
                DisplayName = $service.DisplayName
                Status = $service.Status
                IsRunning = $service.Status -eq 'Running'
            }
        } catch {
            $results += [PSCustomObject]@{
                Name = $serviceName
                DisplayName = "Non trouvé"
                Status = "Unknown"
                IsRunning = $false
            }
        }
    }

    return $results
}

function Send-AlertEmail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$To,

        [Parameter(Mandatory=$true)]
        [string]$Subject,

        [Parameter(Mandatory=$true)]
        [string]$Body,

        [Parameter(Mandatory=$true)]
        [string]$SmtpServer,

        [Parameter(Mandatory=$false)]
        [int]$Port = 25,

        [Parameter(Mandatory=$false)]
        [switch]$UseSsl,

        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Verbose "Envoi d'un email d'alerte"

            try {
        $emailParams = @{
            To = $To
            From = if ($Credential) { $Credential.UserName } else { "$($env:COMPUTERNAME)@monitoring.local" }
            Subject = $Subject
            Body = $Body
            SmtpServer = $SmtpServer
            Port = $Port
            UseSsl = $UseSsl
            ErrorAction = 'Stop'
        }

        if ($Credential) {
            $emailParams.Credential = $Credential
        }

        Send-MailMessage @emailParams
    } catch {
        throw "Erreur lors de l'envoi de l'email: $_"
    }
}

# Exécution de l'orchestration principale
Start-ResourceMonitoring -ConfigPath $ConfigPath -LogPath $LogPath -EmailOnly:$EmailOnly
```

## Points clés de la solution

1. **Structure claire et modulaire** :
   - **Orchestration** : La fonction `Start-ResourceMonitoring` gère le flux général d'exécution
   - **Logique métier** : Fonctions spécifiques pour chaque aspect (CPU, mémoire, disque, services)

2. **Configuration externe** :
   - Utilisation d'un fichier JSON pour la configuration
   - Seuils personnalisables pour chaque type de ressource
   - Paramètres d'envoi d'emails configurables

3. **Surveillance complète** :
   - Utilisation CPU via `Win32_Processor`
   - Utilisation mémoire via `Win32_OperatingSystem`
   - Espace disque via `Win32_LogicalDisk`
   - État des services critiques via `Get-Service`

4. **Système de journalisation robuste** :
   - Enregistrement dans un fichier de log avec horodatage
   - Niveaux de log (INFO, WARNING, ERROR)
   - Rotation quotidienne des fichiers de log

5. **Alertes sophistiquées** :
   - Vérification de seuils pour déterminer les conditions d'alerte
   - Emails formatés avec informations détaillées
   - Support SSL et authentification pour l'envoi d'emails

6. **Flexibilité d'exécution** :
   - Mode silencieux avec `-EmailOnly` pour les tâches planifiées
   - Affichage en console avec codes couleur pour l'exécution interactive

## Exemple de fichier de configuration

```json
{
  "Thresholds": {
    "CPU": 85,
    "Memory": 90,
    "DiskSpace": 95
  },
  "CheckIntervalMinutes": 5,
  "CriticalServices": [
    "wuauserv",
    "W3SVC",
    "MSSQLSERVER",
    "BITS"
  ],
  "Email": {
    "To": ["admin@example.com", "support@example.com"],
    "SmtpServer": "smtp.example.com",
    "Port": 587,
    "UseSsl": true,
    "Username": "alerts@example.com",
    "Password": "YourSecretPassword"
  }
}
```

## Bonnes pratiques mises en œuvre

1. **Séparation des responsabilités** :
   - Chaque fonction a une responsabilité unique et bien définie
   - L'orchestration ne contient aucune logique métier directe

2. **Gestion des erreurs** :
   - Structure try/catch à plusieurs niveaux
   - Enregistrement détaillé des erreurs
   - Poursuite de l'exécution malgré les erreurs dans certains composants

3. **Documentation** :
   - Documentation complète avec bloc de commentaires
   - Exemples d'utilisation
   - Descriptions détaillées des paramètres

4. **Performance** :
   - Utilisation de CIM au lieu de WMI pour de meilleures performances
   - Regroupement des interrogations pour minimiser les requêtes système
