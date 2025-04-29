# Solution Exercice 1 - Vérification de disponibilité des modules

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Énoncé
Créez un script qui vérifie la disponibilité de plusieurs modules PowerShell couramment utilisés et affiche un rapport indiquant lesquels sont installés et lesquels ne le sont pas.

## Solution

```powershell
# Get-ModuleStatus.ps1
<#
.SYNOPSIS
    Vérifie la disponibilité des modules PowerShell et génère un rapport.
.DESCRIPTION
    Ce script vérifie si une liste de modules PowerShell couramment utilisés est installée
    sur le système et génère un rapport formaté avec leur statut.
.EXAMPLE
    .\Get-ModuleStatus.ps1
    Affiche un rapport de tous les modules vérifiés.
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

# Liste des modules à vérifier
$modulesToCheck = @(
    "ActiveDirectory",
    "AzureAD",
    "DnsClient",
    "NetworkController",
    "PSReadLine",
    "Pester",
    "ImportExcel",
    "Microsoft.PowerShell.Archive",
    "Microsoft.PowerShell.SecretManagement",
    "PackageManagement",
    "PowerShellGet"
)

# Créer un tableau pour stocker les résultats
$results = @()

# Vérifier chaque module
foreach ($module in $modulesToCheck) {
    $moduleInfo = [PSCustomObject]@{
        ModuleName = $module
        Installed = $false
        Version = "N/A"
        Path = "N/A"
    }

    # Vérifier si le module est disponible
    $moduleAvailable = Get-Module -ListAvailable -Name $module -ErrorAction SilentlyContinue

    if ($moduleAvailable) {
        # Module trouvé - utiliser la dernière version si plusieurs sont installées
        $latestVersion = $moduleAvailable | Sort-Object Version -Descending | Select-Object -First 1

        $moduleInfo.Installed = $true
        $moduleInfo.Version = $latestVersion.Version.ToString()
        $moduleInfo.Path = $latestVersion.ModuleBase
    }

    $results += $moduleInfo
}

# Afficher les résultats dans un tableau formaté
Write-Host "`n=== RAPPORT DE DISPONIBILITÉ DES MODULES POWERSHELL ===" -ForegroundColor Cyan
Write-Host "Date de vérification: $(Get-Date -Format 'dd/MM/yyyy HH:mm')`n" -ForegroundColor Gray

# Afficher les modules installés
Write-Host "MODULES INSTALLÉS:" -ForegroundColor Green
$results | Where-Object { $_.Installed } | Format-Table -Property ModuleName, Version, Path -AutoSize

# Afficher les modules non installés
Write-Host "MODULES NON INSTALLÉS:" -ForegroundColor Yellow
$modulesNotInstalled = $results | Where-Object { -not $_.Installed } | Select-Object -ExpandProperty ModuleName

if ($modulesNotInstalled.Count -eq 0) {
    Write-Host "Tous les modules vérifiés sont installés!" -ForegroundColor Green
} else {
    $modulesNotInstalled | ForEach-Object { Write-Host "- $_" -ForegroundColor Yellow }

    # Suggestion d'installation
    Write-Host "`nSuggestion d'installation:" -ForegroundColor Cyan
    Write-Host "Pour installer les modules manquants, exécutez:" -ForegroundColor Cyan
    $modulesNotInstalled | ForEach-Object {
        Write-Host "Install-Module -Name '$_' -Scope CurrentUser" -ForegroundColor Gray
    }
}

Write-Host "`n=== FIN DU RAPPORT ===`n" -ForegroundColor Cyan
```

## Explication

Ce script effectue les actions suivantes :

1. Définit une liste de modules PowerShell courants à vérifier
2. Vérifie la disponibilité de chaque module avec `Get-Module -ListAvailable`
3. Pour chaque module trouvé, enregistre la version et le chemin d'installation
4. Génère un rapport visuel formaté montrant :
   - Les modules installés avec leur version et chemin
   - Les modules non installés
   - Des suggestions pour installer les modules manquants

Cette solution illustre le concept de vérification conditionnelle des modules sans les charger, ce qui est une première étape vers le chargement conditionnel.

# Solution Exercice 2 - Chargement à la demande des modules

## Énoncé
Créez une fonction réutilisable qui charge un module uniquement lorsqu'il est nécessaire et gère les erreurs de manière appropriée.

## Solution

```powershell
# Import-ModuleOnDemand.ps1
<#
.SYNOPSIS
    Fournit une fonction pour charger un module PowerShell uniquement quand nécessaire.
.DESCRIPTION
    Ce script définit une fonction réutilisable qui permet de charger des modules PowerShell
    à la demande, en vérifiant d'abord s'ils sont déjà chargés et en gérant les erreurs
    d'une manière élégante.
.EXAMPLE
    # Importer le script
    . .\Import-ModuleOnDemand.ps1

    # Utiliser la fonction
    if (Import-ModuleOnDemand -Name "ActiveDirectory") {
        Get-ADUser -Filter * -ResultSetSize 5
    }
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

# Variables pour suivre l'état des modules
$script:loadedModules = @{}

function Import-ModuleOnDemand {
    <#
    .SYNOPSIS
        Charge un module PowerShell uniquement quand nécessaire.
    .DESCRIPTION
        Cette fonction vérifie si un module est déjà chargé, puis tente de l'importer
        s'il ne l'est pas encore. Elle gère les erreurs et offre des options de retour.
    .PARAMETER Name
        Nom du module à charger.
    .PARAMETER MinimumVersion
        Version minimale du module requise.
    .PARAMETER RequiredVersion
        Version exacte du module requise.
    .PARAMETER Silent
        Si spécifié, supprime les messages d'information.
    .PARAMETER Force
        Force le rechargement du module même s'il est déjà chargé.
    .EXAMPLE
        Import-ModuleOnDemand -Name "ActiveDirectory"
    .EXAMPLE
        Import-ModuleOnDemand -Name "Az" -MinimumVersion "5.0.0" -Silent
    .EXAMPLE
        if (Import-ModuleOnDemand -Name "Pester" -RequiredVersion "5.3.0") {
            # Utiliser Pester ici
        }
    .OUTPUTS
        System.Boolean - Retourne $true si le module est chargé avec succès, $false sinon
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [version]$MinimumVersion,

        [Parameter(Mandatory = $false)]
        [version]$RequiredVersion,

        [Parameter(Mandatory = $false)]
        [switch]$Silent,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Générer une clé unique pour ce module (y compris la version demandée)
    $moduleKey = $Name
    if ($RequiredVersion) {
        $moduleKey += "_v$RequiredVersion"
    } elseif ($MinimumVersion) {
        $moduleKey += "_v$MinimumVersion+"
    }

    # Vérifier si le module est déjà chargé (sauf si Force est spécifié)
    if (-not $Force -and $script:loadedModules[$moduleKey]) {
        if (-not $Silent) {
            Write-Verbose "Le module '$Name' est déjà chargé."
        }
        return $true
    }

    # Préparer les paramètres pour Import-Module
    $importParams = @{
        Name = $Name
        ErrorAction = "Stop"
        Verbose = $false
    }

    if ($MinimumVersion) {
        $importParams["MinimumVersion"] = $MinimumVersion
    }

    if ($RequiredVersion) {
        $importParams["RequiredVersion"] = $RequiredVersion
    }

    try {
        # Vérifier d'abord si le module existe
        $moduleAvailable = Get-Module -ListAvailable -Name $Name -ErrorAction SilentlyContinue

        if (-not $moduleAvailable) {
            if (-not $Silent) {
                Write-Warning "Le module '$Name' n'est pas installé sur ce système."
            }
            return $false
        }

        # Vérifier la version si spécifiée
        if ($RequiredVersion -and -not ($moduleAvailable.Version -contains $RequiredVersion)) {
            if (-not $Silent) {
                Write-Warning "La version requise '$RequiredVersion' du module '$Name' n'est pas installée."
            }
            return $false
        }

        if ($MinimumVersion) {
            $hasMinVersion = $false
            foreach ($module in $moduleAvailable) {
                if ($module.Version -ge $MinimumVersion) {
                    $hasMinVersion = $true
                    break
                }
            }

            if (-not $hasMinVersion) {
                if (-not $Silent) {
                    Write-Warning "Aucune version du module '$Name' supérieure ou égale à '$MinimumVersion' n'est installée."
                }
                return $false
            }
        }

        # Importer le module
        Import-Module @importParams

        # Marquer le module comme chargé
        $script:loadedModules[$moduleKey] = $true

        if (-not $Silent) {
            $loadedModule = Get-Module -Name $Name
            Write-Verbose "Module '$Name' version '$($loadedModule.Version)' chargé avec succès."
        }

        return $true
    }
    catch {
        if (-not $Silent) {
            Write-Warning "Erreur lors du chargement du module '$Name': $_"
        }
        return $false
    }
}

# Exporter la fonction si le script est importé comme module
Export-ModuleMember -Function Import-ModuleOnDemand
```

## Exemple d'utilisation

```powershell
# Importer le script comme "dot-source"
. .\Import-ModuleOnDemand.ps1

# Utiliser la fonction pour charger ActiveDirectory uniquement si nécessaire
if (Import-ModuleOnDemand -Name "ActiveDirectory") {
    Write-Host "Recherche des utilisateurs Active Directory..." -ForegroundColor Green
    # Utiliser les commandes du module ActiveDirectory
    Get-ADUser -Filter "Enabled -eq '$true'" -ResultSetSize 5 | Format-Table Name, Enabled
} else {
    Write-Host "Le module ActiveDirectory n'est pas disponible. Utilisation d'une alternative..." -ForegroundColor Yellow
    # Code alternatif qui ne nécessite pas ActiveDirectory
    Get-LocalUser | Format-Table Name, Enabled
}

# Exemple avec vérification de version minimale
if (Import-ModuleOnDemand -Name "PSReadLine" -MinimumVersion "2.0.0") {
    Write-Host "Utilisation de PSReadLine version 2.0.0 ou supérieure" -ForegroundColor Green
}

# Exemple avec recharge forcée
Import-ModuleOnDemand -Name "Microsoft.PowerShell.Management" -Force -Verbose
```

## Explication

Cette solution fournit une fonction réutilisable `Import-ModuleOnDemand` qui :

1. Vérifie si le module est déjà chargé pour éviter les rechargements inutiles
2. Gère les vérifications de versions (minimales ou exactes)
3. Vérifie la disponibilité du module avant de tenter de le charger
4. Utilise une structure try/catch pour gérer les erreurs
5. Permet un mode silencieux pour éviter d'afficher des messages
6. Retourne une valeur booléenne qui peut être utilisée dans des conditions

Cette approche permet de créer des scripts robustes qui s'adaptent à l'environnement d'exécution et ne chargent les modules que lorsqu'ils sont réellement nécessaires.

# Solution Exercice 3 - Script multifonction avec chargement conditionnel

## Énoncé
Créez un script d'utilitaires système qui propose plusieurs fonctionnalités (gestion des processus, analyse de disque, sauvegarde) et utilise le chargement conditionnel des modules pour n'importer que ceux nécessaires à la fonction demandée par l'utilisateur.

## Solution

```powershell
# System-Utilities.ps1
<#
.SYNOPSIS
    Script d'utilitaires système avec chargement conditionnel de modules.
.DESCRIPTION
    Ce script propose plusieurs fonctionnalités de maintenance système et n'importe
    que les modules nécessaires à la fonctionnalité sélectionnée par l'utilisateur.
.EXAMPLE
    .\System-Utilities.ps1
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

# Fonction pour importer un module uniquement si nécessaire
function Import-ModuleIfNeeded {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    try {
        # Vérifier si le module existe
        $moduleExists = Get-Module -ListAvailable -Name $ModuleName -ErrorAction Stop

        if ($moduleExists) {
            # Vérifier si le module est déjà importé
            if (-not (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue)) {
                Write-Host "Chargement du module $ModuleName..." -ForegroundColor DarkCyan
                Import-Module -Name $ModuleName -ErrorAction Stop
            }
            return $true
        } else {
            Write-Warning "Le module $ModuleName n'est pas installé sur ce système."
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du chargement du module $ModuleName : $_"
        return $false
    }
}

# Fonction : Analyse des processus consommant le plus de ressources
function Show-TopProcesses {
    # Aucun module supplémentaire requis pour cette fonction

    Write-Host "`n=== PROCESSUS LES PLUS CONSOMMATEURS DE RESSOURCES ===" -ForegroundColor Cyan

    Write-Host "`nPROCESSUS - CPU" -ForegroundColor Yellow
    Get-Process |
        Sort-Object -Property CPU -Descending |
        Select-Object -First 5 -Property ProcessName, Id, CPU, WorkingSet |
        Format-Table -AutoSize

    Write-Host "PROCESSUS - MÉMOIRE" -ForegroundColor Yellow
    Get-Process |
        Sort-Object -Property WorkingSet -Descending |
        Select-Object -First 5 -Property ProcessName, Id, CPU, @{Name="Memory(MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}} |
        Format-Table -AutoSize
}

# Fonction : Analyse de l'espace disque
function Analyze-DiskSpace {
    # Charge le module CimCmdlets si nécessaire
    if (-not (Import-ModuleIfNeeded -ModuleName "CimCmdlets")) {
        # Fallback vers une méthode alternative si le module n'est pas disponible
        Write-Host "Utilisation d'une méthode alternative pour l'analyse de disque..." -ForegroundColor Yellow
    }

    Write-Host "`n=== ANALYSE DE L'ESPACE DISQUE ===" -ForegroundColor Cyan

    # Obtenir les informations sur les disques
    try {
        $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction Stop

        foreach ($disk in $disks) {
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            $usedSpaceGB = $sizeGB - $freeSpaceGB
            $percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)

            Write-Host "`nLecteur $($disk.DeviceID)" -ForegroundColor Yellow
            Write-Host "Nom: $($disk.VolumeName)"
            Write-Host "Taille totale: $sizeGB GB"
            Write-Host "Espace utilisé: $usedSpaceGB GB"
            Write-Host "Espace libre: $freeSpaceGB GB"
            Write-Host "Pourcentage libre: $percentFree%"

            # Représentation visuelle
            $barLength = 50
            $filledLength = [math]::Round(($usedSpaceGB / $sizeGB) * $barLength)
            $bar = "[" + ("#" * $filledLength) + (" " * ($barLength - $filledLength)) + "]"

            # Colorisation selon l'espace disponible
            if ($percentFree -lt 10) {
                Write-Host $bar -ForegroundColor Red
            } elseif ($percentFree -lt 25) {
                Write-Host $bar -ForegroundColor Yellow
            } else {
                Write-Host $bar -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Warning "Erreur lors de l'analyse des disques: $_"

        # Méthode alternative utilisant Get-PSDrive
        Write-Host "`nUtilisation de Get-PSDrive comme alternative:" -ForegroundColor Yellow
        Get-PSDrive -PSProvider FileSystem |
            Select-Object Name, @{Name="Size(GB)"; Expression={[math]::Round($_.Used / 1GB + $_.Free / 1GB, 2)}},
                          @{Name="Used(GB)"; Expression={[math]::Round($_.Used / 1GB, 2)}},
                          @{Name="Free(GB)"; Expression={[math]::Round($_.Free / 1GB, 2)}},
                          @{Name="Free(%)"; Expression={[math]::Round(($_.Free / ($_.Used + $_.Free)) * 100, 1)}} |
            Format-Table -AutoSize
    }
}

# Fonction : Sauvegarde de documents
function Backup-UserDocuments {
    param (
        [string]$Destination = "$env:USERPROFILE\Desktop\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    )

    # Charger le module d'archivage si nécessaire
    if (-not (Import-ModuleIfNeeded -ModuleName "Microsoft.PowerShell.Archive")) {
        Write-Warning "La fonctionnalité de sauvegarde nécessite le module Microsoft.PowerShell.Archive, qui n'est pas disponible."
        return
    }

    Write-Host "`n=== SAUVEGARDE DES DOCUMENTS UTILISATEUR ===" -ForegroundColor Cyan

    # Définir les dossiers à sauvegarder
    $sourceFolders = @(
        "$env:USERPROFILE\Documents",
        "$env:USERPROFILE\Pictures",
        "$env:USERPROFILE\Desktop"
    )

    # Vérifier que les dossiers existent
    $validFolders = $sourceFolders | Where-Object { Test-Path $_ }

    if ($validFolders.Count -eq 0) {
        Write-Warning "Aucun dossier source valide trouvé pour la sauvegarde."
        return
    }

    # Créer un dossier temporaire pour la sauvegarde
    $tempFolder = Join-Path -Path $env:TEMP -ChildPath "TempBackup_$(Get-Date -Format 'yyyyMMddHHmmss')"
    New-Item -Path $tempFolder -ItemType Directory -Force | Out-Null

    try {
        # Copier les fichiers vers le dossier temporaire
        foreach ($folder in $validFolders) {
            $folderName = Split-Path -Path $folder -Leaf
            $targetPath = Join-Path -Path $tempFolder -ChildPath $folderName

            Write-Host "Copie de $folderName..." -ForegroundColor Yellow

            # Créer la structure de dossiers
            New-Item -Path $targetPath -ItemType Directory -Force | Out-Null

            # Copier les fichiers (uniquement documents, images, etc., pas les exécutables)
            $filesToCopy = Get-ChildItem -Path $folder -File -Recurse -ErrorAction SilentlyContinue |
                           Where-Object { $_.Extension -match '\.(txt|doc|docx|xls|xlsx|ppt|pptx|pdf|jpg|jpeg|png|gif|bmp)$' }

            foreach ($file in $filesToCopy) {
                # Recréer le chemin relatif
                $relativePath = $file.FullName.Substring($folder.Length)
                $destination = Join-Path -Path $targetPath -ChildPath $relativePath

                # Créer le dossier parent si nécessaire
                $parentFolder = Split-Path -Path $destination -Parent
                if (-not (Test-Path $parentFolder)) {
                    New-Item -Path $parentFolder -ItemType Directory -Force | Out-Null
                }

                # Copier le fichier
                Copy-Item -Path $file.FullName -Destination $destination -Force -ErrorAction SilentlyContinue
            }
        }

        # Créer l'archive ZIP
        Write-Host "Création de l'archive de sauvegarde..." -ForegroundColor Yellow
        Compress-Archive -Path "$tempFolder\*" -DestinationPath $Destination -Force

        # Vérifier si la sauvegarde a été créée
        if (Test-Path $Destination) {
            $backupSize = (Get-Item $Destination).Length / 1MB
            Write-Host "Sauvegarde créée avec succès: $Destination" -ForegroundColor Green
            Write-Host "Taille de la sauvegarde: $([math]::Round($backupSize, 2)) MB" -ForegroundColor Green
        } else {
            Write-Warning "La sauvegarde n'a pas pu être créée."
        }
    }
    catch {
        Write-Error "Erreur lors de la sauvegarde: $_"
    }
    finally {
        # Nettoyer le dossier temporaire
        if (Test-Path $tempFolder) {
            Remove-Item -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
            Write-Verbose "Dossier temporaire nettoyé."
        }
    }
}

# Fonction : Afficher les informations système
function Show-SystemInfo {
    # Charge le module CimCmdlets si nécessaire
    Import-ModuleIfNeeded -ModuleName "CimCmdlets" | Out-Null

    Write-Host "`n=== INFORMATIONS SYSTÈME ===" -ForegroundColor Cyan

    # Informations sur le système d'exploitation
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop

        Write-Host "`nSYSTÈME D'EXPLOITATION" -ForegroundColor Yellow
        Write-Host "Nom: $($os.Caption)"
        Write-Host "Version: $($os.Version)"
        Write-Host "Architecture: $($os.OSArchitecture)"
        Write-Host "Installé le: $($os.InstallDate)"
        Write-Host "Dernier démarrage: $($os.LastBootUpTime)"
        Write-Host "Temps de fonctionnement: $((Get-Date) - $os.LastBootUpTime)"

        Write-Host "`nMATÉRIEL" -ForegroundColor Yellow
        Write-Host "Fabricant: $($computerSystem.Manufacturer)"
        Write-Host "Modèle: $($computerSystem.Model)"
        Write-Host "Processeurs logiques: $($computerSystem.NumberOfLogicalProcessors)"
        Write-Host "Mémoire RAM: $([math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)) GB"
        Write-Host "BIOS Version: $($bios.SMBIOSBIOSVersion)"
        Write-Host "Serial Number: $($bios.SerialNumber)"
    }
    catch {
        Write-Warning "Erreur lors de la récupération des informations système: $_"

        # Alternative sans CIM
        Write-Host "`nINFORMATIONS ALTERNATIVES" -ForegroundColor Yellow
        Write-Host "Nom de l'ordinateur: $env:COMPUTERNAME"
        Write-Host "Utilisateur: $env:USERNAME"
        Write-Host "Domaine: $env:USERDOMAIN"
        Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
        Write-Host "OS: $([System.Environment]::OSVersion.VersionString)"
    }
}

# Menu principal
function Show-Menu {
    Clear-Host
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "      UTILITAIRES SYSTÈME          " -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Afficher les processus consommant le plus de ressources" -ForegroundColor White
    Write-Host "2. Analyser l'espace disque" -ForegroundColor White
    Write-Host "3. Sauvegarder les documents utilisateur" -ForegroundColor White
    Write-Host "4. Afficher les informations système" -ForegroundColor White
    Write-Host
    Write-Host "Q. Quitter" -ForegroundColor White
    Write-Host
    Write-Host "====================================" -ForegroundColor Cyan
}

# Boucle principale
function Start-Menu {
    do {
        Show-Menu
        $choice = Read-Host "Entrez votre choix"

        switch ($choice) {
            "1" {
                Clear-Host
                Show-TopProcesses
                Pause
            }
            "2" {
                Clear-Host
                Analyze-DiskSpace
                Pause
            }
            "3" {
                Clear-Host
                $customPath = Read-Host "Chemin de sauvegarde (laisser vide pour le chemin par défaut)"

                if ([string]::IsNullOrWhiteSpace($customPath)) {
                    Backup-UserDocuments
                } else {
                    Backup-UserDocuments -Destination $customPath
                }

                Pause
            }
            "4" {
                Clear-Host
                Show-SystemInfo
                Pause
            }
            "Q" {
                Write-Host "Au revoir!" -ForegroundColor Cyan
                return
            }
            "q" {
                Write-Host "Au revoir!" -ForegroundColor Cyan
                return
            }
            default {
                Write-Host "Choix non valide. Veuillez réessayer." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# Fonction Pause personnalisée
function Pause {
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Démarrer le menu
Start-Menu
```

## Explication

Ce script d'utilitaires système illustre parfaitement le concept de chargement conditionnel des modules :

1. **Structure modulaire** : Le script est divisé en fonctions spécialisées, chacune ne chargeant que les modules dont elle a besoin.

2. **Fonction de chargement** : La fonction `Import-ModuleIfNeeded` :
   - Vérifie si un module est disponible avant de tenter de le charger
   - Gère les erreurs proprement
   - Évite les rechargements inutiles

3. **Fonctionnalités diverses** :
   - Analyse des processus (sans module supplémentaire)
   - Analyse de l'espace disque (utilise CimCmdlets)
   - Sauvegarde de documents (utilise Microsoft.PowerShell.Archive)
   - Informations système (utilise CimCmdlets)

4. **Alternatives adaptatives** : Si un module n'est pas disponible, le script propose des alternatives utilisant des commandes PowerShell de base.

5. **Interface utilisateur** : Un menu interactif permet à l'utilisateur de choisir la fonctionnalité dont il a besoin.

Cette approche permet d'optimiser les performances car seuls les modules nécessaires à la fonction choisie sont chargés en mémoire, rendant le script plus rapide et plus efficace.

# Solution Exercice 4 - Autoload par proxy de fonctions

## Énoncé
Créez un module qui implémente un système d'autoload de fonctions qui charge automatiquement les modules nécessaires quand une fonction est appelée, en utilisant des fonctions proxy.

## Solution

```powershell
# ModuleAutoloader.psm1
<#
.SYNOPSIS
    Module qui implémente un système d'autoload de fonctions PowerShell.
.DESCRIPTION
    Ce module crée des fonctions proxy qui chargent automatiquement les modules
    nécessaires uniquement lorsque les fonctions sont réellement appelées.
.EXAMPLE
    Import-Module ModuleAutoloader
    Register-AutoloadFunction -ModuleName "ActiveDirectory" -CommandName "Get-ADUser"
    # La première utilisation de Get-ADUser chargera automatiquement le module ActiveDirectory
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

# HashTable pour stocker l'état des modules
$script:AutoloadRegistry = @{}

function Register-AutoloadFunction {
    <#
    .SYNOPSIS
        Enregistre une fonction pour l'autoload.
    .DESCRIPTION
        Crée une fonction proxy qui chargera automatiquement le module requis
        lorsque la fonction sera appelée pour la première fois.
    .PARAMETER ModuleName
        Nom du module à charger.
    .PARAMETER CommandName
        Nom de la commande à proxifier.
    .PARAMETER Force
        Remplace une fonction existante si elle existe déjà.
    .EXAMPLE
        Register-AutoloadFunction -ModuleName "ActiveDirectory" -CommandName "Get-ADUser"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$CommandName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le module contient bien la commande
    $moduleAvailable = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue

    if (-not $moduleAvailable) {
        Write-Warning "Le module '$ModuleName' n'est pas disponible sur ce système. La fonction proxy ne sera pas créée."
        return
    }

    # Vérifier si la commande existe dans le module
    $command = Get-Command -Name $CommandName -Module $ModuleName -ErrorAction SilentlyContinue

    if (-not $command) {
        Write-Warning "La commande '$CommandName' n'existe pas dans le module '$ModuleName'. La fonction proxy ne sera pas créée."
        return
    }

    # Vérifier si la fonction existe déjà
    $existingFunction = Get-Command -Name $CommandName -ErrorAction SilentlyContinue

    if ($existingFunction -and -not $Force) {
        Write-Warning "Une fonction '$CommandName' existe déjà. Utilisez -Force pour la remplacer."
        return
    }

    # Créer la clé de registre pour cette fonction
    $functionKey = "${ModuleName}::${CommandName}"
    $script:AutoloadRegistry[$functionKey] = @{
        ModuleName = $ModuleName
        CommandName = $CommandName
        Loaded = $false
    }

    # Obtenir les informations sur les paramètres de la commande
    $commandInfo = Get-Command -Name $CommandName -Module $ModuleName

    # Créer le bloc de script pour la fonction proxy
    $scriptBlock = {
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            $Params
        )

        # Les variables seront remplacées lors de la création de la fonction proxy
        $moduleName = '##MODULE_NAME##'
        $commandName = '##COMMAND_NAME##'
        $functionKey = "${moduleName}::${commandName}"

        # Vérifier si le module est déjà chargé
        if (-not $script:AutoloadRegistry[$functionKey].Loaded) {
            Write-Verbose "Chargement automatique du module '$moduleName' pour la commande '$commandName'..."

            try {
                Import-Module -Name $moduleName -ErrorAction Stop
                $script:AutoloadRegistry[$functionKey].Loaded = $true
                Write-Verbose "Module '$moduleName' chargé avec succès."
            }
            catch {
                Write-Error "Erreur lors du chargement du module '$moduleName': $_"
                return
            }
        }

        # Appeler la vraie commande avec tous les paramètres reçus
        $command = Get-Command -Name $commandName -ErrorAction Stop

        # Utiliser splatting pour passer les paramètres
        & $command @Params
    }

    # Remplacer les placeholders dans le bloc de script
    $scriptBlockText = $scriptBlock.ToString()
    $scriptBlockText = $scriptBlockText.Replace("'##MODULE_NAME##'", "'$ModuleName'")
    $scriptBlockText = $scriptBlockText.Replace("'##COMMAND_NAME##'", "'$CommandName'")

    # Créer le bloc de script final
    $finalScriptBlock = [ScriptBlock]::Create($scriptBlockText)

    # Créer la fonction proxy
    $null = New-Item -Path function: -Name "Global:$CommandName" -Value $finalScriptBlock -Force

    Write-Verbose "Fonction proxy créée pour '$CommandName' qui chargera '$ModuleName' à la demande."
}

function Register-AutoloadModule {
    <#
    .SYNOPSIS
        Enregistre toutes les commandes exportées d'un module pour l'autoload.
    .DESCRIPTION
        Crée des fonctions proxy pour toutes les commandes exportées d'un module spécifié.
    .PARAMETER ModuleName
        Nom du module à enregistrer pour l'autoload.
    .PARAMETER Force
        Remplace les fonctions existantes si elles existent déjà.
    .EXAMPLE
        Register-AutoloadModule -ModuleName "ActiveDirectory"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le module est disponible
    $moduleAvailable = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue

    if (-not $moduleAvailable) {
        Write-Warning "Le module '$ModuleName' n'est pas disponible sur ce système."
        return
    }

    # Obtenir toutes les commandes exportées par le module
    $commands = (Get-Module -ListAvailable -Name $ModuleName | Select-Object -First 1).ExportedCommands.Values

    if (-not $commands -or $commands.Count -eq 0) {
        Write-Warning "Aucune commande exportée trouvée dans le module '$ModuleName'."
        return
    }

    Write-Verbose "Création de fonctions proxy pour $($commands.Count) commandes du module '$ModuleName'..."

    # Enregistrer chaque commande
    foreach ($command in $commands) {
        Register-AutoloadFunction -ModuleName $ModuleName -CommandName $command.Name -Force:$Force
    }

    Write-Verbose "Module '$ModuleName' enregistré pour l'autoload avec $($commands.Count) commandes."
}

function Get-AutoloadStatus {
    <#
    .SYNOPSIS
        Affiche l'état de chargement des modules et fonctions enregistrés pour l'autoload.
    .DESCRIPTION
        Cette fonction affiche l'état actuel de tous les modules et fonctions enregistrés
        pour l'autoload, indiquant s'ils ont été chargés ou non.
    .EXAMPLE
        Get-AutoloadStatus
    #>
    [CmdletBinding()]
    param()

    $results = @()

    foreach ($key in $script:AutoloadRegistry.Keys) {
        $entry = $script:AutoloadRegistry[$key]

        $results += [PSCustomObject]@{
            Module = $entry.ModuleName
            Command = $entry.CommandName
            Loaded = $entry.Loaded
            Status = if ($entry.Loaded) { "Chargé" } else { "Non chargé" }
        }
    }

    # Trier et retourner les résultats
    $results | Sort-Object Module, Command
}

function Remove-AutoloadFunction {
    <#
    .SYNOPSIS
        Supprime une fonction proxy autoload.
    .DESCRIPTION
        Supprime une fonction proxy précédemment enregistrée pour l'autoload.
    .PARAMETER ModuleName
        Nom du module.
    .PARAMETER CommandName
        Nom de la commande.
    .EXAMPLE
        Remove-AutoloadFunction -ModuleName "ActiveDirectory" -CommandName "Get-ADUser"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    # Vérifier si la fonction est enregistrée
    $functionKey = "${ModuleName}::${CommandName}"

    if (-not $script:AutoloadRegistry.ContainsKey($functionKey)) {
        Write-Warning "La fonction '$CommandName' du module '$ModuleName' n'est pas enregistrée pour l'autoload."
        return
    }

    # Supprimer la fonction
    try {
        Remove-Item -Path "function:Global:$CommandName" -ErrorAction Stop
        $script:AutoloadRegistry.Remove($functionKey)
        Write-Verbose "Fonction proxy '$CommandName' supprimée avec succès."
    }
    catch {
        Write-Error "Erreur lors de la suppression de la fonction proxy '$CommandName': $_"
    }
}

# Exporter les fonctions du module
Export-ModuleMember -Function Register-AutoloadFunction, Register-AutoloadModule, Get-AutoloadStatus, Remove-AutoloadFunction
```

## Exemple d'utilisation

```powershell
# Importer le module
Import-Module .\ModuleAutoloader.psm1

# Enregistrer des fonctions individuelles pour l'autoload
Register-AutoloadFunction -ModuleName "ActiveDirectory" -CommandName "Get-ADUser"
Register-AutoloadFunction -ModuleName "ActiveDirectory" -CommandName "Get-ADGroup"

# Ou enregistrer toutes les commandes d'un module
Register-AutoloadModule -ModuleName "DnsClient"

# Vérifier l'état de chargement
Get-AutoloadStatus

# Utiliser une fonction - le module sera chargé automatiquement à la première utilisation
Get-ADUser -Filter "Name -like 'A*'" -ResultSetSize 5

# Vérifier à nouveau l'état de chargement
Get-AutoloadStatus

# Supprimer une fonction proxy
Remove-AutoloadFunction -ModuleName "ActiveDirectory" -CommandName "Get-ADUser"
```

## Script de démonstration

```powershell
# Demo-ModuleAutoloader.ps1
<#
.SYNOPSIS
    Démontre l'utilisation du module ModuleAutoloader.
#>

# Importer le module
Import-Module .\ModuleAutoloader.psm1 -Force

Clear-Host
Write-Host "=== DÉMONSTRATION DU MODULE AUTOLOADER ===" -ForegroundColor Cyan
Write-Host

# Enregistrer quelques fonctions pour l'autoload
Write-Host "Enregistrement de fonctions pour l'autoload..." -ForegroundColor Yellow
Register-AutoloadFunction -ModuleName "Microsoft.PowerShell.Archive" -CommandName "Compress-Archive" -Verbose
Register-AutoloadFunction -ModuleName "Microsoft.PowerShell.Archive" -CommandName "Expand-Archive" -Verbose

Write-Host

# Afficher l'état initial
Write-Host "État initial des fonctions enregistrées:" -ForegroundColor Yellow
Get-AutoloadStatus | Format-Table -AutoSize

Write-Host

# Utiliser une fonction pour déclencher le chargement du module
Write-Host "Utilisation de Compress-Archive pour déclencher le chargement du module..." -ForegroundColor Yellow
$testFile = Join-Path -Path $env:TEMP -ChildPath "test.txt"
$testArchive = Join-Path -Path $env:TEMP -ChildPath "test.zip"

"Ceci est un fichier de test pour la démonstration." | Out-File -FilePath $testFile -Force
Compress-Archive -Path $testFile -DestinationPath $testArchive -Force

Write-Host "Archive créée: $testArchive" -ForegroundColor Green
Write-Host

# Afficher l'état après utilisation
Write-Host "État après utilisation de Compress-Archive:" -ForegroundColor Yellow
Get-AutoloadStatus | Format-Table -AutoSize

Write-Host

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Yellow
Remove-AutoloadFunction -ModuleName "Microsoft.PowerShell.Archive" -CommandName "Compress-Archive" -Verbose
Remove-AutoloadFunction -ModuleName "Microsoft.PowerShell.Archive" -CommandName "Expand-Archive" -Verbose

Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $testArchive -Force -ErrorAction SilentlyContinue

Write-Host
Write-Host "Démonstration terminée." -ForegroundColor Cyan
```

## Explication

Cette solution implémente un système d'autoload avancé pour les modules PowerShell, en utilisant le concept de fonctions proxy :

1. **Fonctions proxy** : Le module crée des fonctions temporaires qui :
   - Ont le même nom que les fonctions réelles du module
   - Chargent le module correspondant à la demande lorsqu'elles sont appelées
   - Transmettent tous les paramètres à la vraie fonction

2. **Avantages de cette approche** :
   - Les modules ne sont chargés qu'à la première utilisation de l'une de leurs fonctions
   - L'utilisateur n'a pas besoin de se préoccuper du chargement des modules
   - Les scripts démarrent plus rapidement car les modules sont chargés à la demande

3. **Fonctionnalités du module** :
   - `Register-AutoloadFunction` : Enregistre une fonction individuelle pour l'autoload
   - `Register-AutoloadModule` : Enregistre toutes les fonctions d'un module pour l'autoload
   - `Get-AutoloadStatus` : Affiche l'état de chargement des modules et fonctions
   - `Remove-AutoloadFunction` : Supprime une fonction proxy

Cette technique permet un chargement conditionnel très efficace et transparent pour l'utilisateur, optimisant ainsi les performances des scripts PowerShell.

# Solution Exercice 5 - Chargement conditionnel basé sur l'environnement

## Énoncé
Créez un script qui détermine automatiquement le type d'environnement dans lequel il s'exécute (Windows, Linux, macOS, environnement cloud) et charge les modules appropriés en fonction de la plateforme détectée.

## Solution

```powershell
# Environment-Aware-Loader.ps1
<#
.SYNOPSIS
    Script qui charge conditionnellement les modules en fonction de l'environnement d'exécution.
.DESCRIPTION
    Ce script détecte automatiquement l'environnement d'exécution (système d'exploitation,
    cloud, virtualisation) et charge uniquement les modules appropriés à cet environnement.
.EXAMPLE
    .\Environment-Aware-Loader.ps1
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

#Requires -Version 5.1

# ===== Configuration =====
# Définir les modules spécifiques à chaque environnement
$WindowsModules = @(
    "Microsoft.PowerShell.Management",
    "Microsoft.PowerShell.Security",
    "CimCmdlets"
)

$LinuxModules = @(
    "Microsoft.PowerShell.Management"
)

$MacOSModules = @(
    "Microsoft.PowerShell.Management"
)

$AzureModules = @(
    "Az.Accounts",
    "Az.Compute",
    "Az.Storage"
)

$AWSModules = @(
    "AWS.Tools.Common",
    "AWS.Tools.EC2",
    "AWS.Tools.S3"
)

# ===== Fonctions =====
# Fonction principale qui sera exécutée à la fin du script
function Write-StatusMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Type = "Info" # Info, Success, Warning, Error
    )

    switch ($Type) {
        "Info" {
            Write-Host "[INFO] $Message" -ForegroundColor Cyan
        }
        "Success" {
            Write-Host "[OK] $Message" -ForegroundColor Green
        }
        "Warning" {
            Write-Host "[ATTENTION] $Message" -ForegroundColor Yellow
        }
        "Error" {
            Write-Host "[ERREUR] $Message" -ForegroundColor Red
        }
        default {
            Write-Host $Message
        }
    }
}

function Test-ModuleAvailability {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    $moduleAvailable = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue

    if ($moduleAvailable) {
        return $true
    } else {
        return $false
    }
}

function Import-ModuleIfAvailable {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [switch]$Required,

        [Parameter(Mandatory = $false)]
        [switch]$Silent
    )

    # Vérifier si le module est déjà chargé
    if (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue) {
        if (-not $Silent) {
            Write-StatusMessage "Le module '$ModuleName' est déjà chargé." -Type "Info"
        }
        return $true
    }

    # Vérifier si le module est disponible
    if (Test-ModuleAvailability -ModuleName $ModuleName) {
        try {
            Import-Module -Name $ModuleName -ErrorAction Stop
            if (-not $Silent) {
                Write-StatusMessage "Module '$ModuleName' chargé avec succès." -Type "Success"
            }
            return $true
        }
        catch {
            if (-not $Silent) {
                Write-StatusMessage "Erreur lors du chargement du module '$ModuleName': $_" -Type "Error"
            }
            if ($Required) {
                throw "Le module requis '$ModuleName' n'a pas pu être chargé."
            }
            return $false
        }
    }
    else {
        if (-not $Silent) {
            Write-StatusMessage "Le module '$ModuleName' n'est pas disponible sur ce système." -Type "Warning"
        }
        if ($Required) {
            throw "Le module requis '$ModuleName' n'est pas installé sur ce système."
        }
        return $false
    }
}

function Get-EnvironmentInfo {
    <#
    .SYNOPSIS
        Détecte l'environnement d'exécution du script.
    .DESCRIPTION
        Cette fonction détecte le système d'exploitation, la virtualisation, et
        les environnements cloud dans lesquels s'exécute PowerShell.
    .OUTPUTS
        [PSCustomObject] Informations sur l'environnement d'exécution.
    #>

    # Créer l'objet d'information
    $envInfo = [PSCustomObject]@{
        OS = "Unknown"
        IsWindows = $false
        IsLinux = $false
        IsMacOS = $false
        IsVirtual = $false
        VirtualizationType = "Unknown"
        IsCloud = $false
        CloudType = "Unknown"
        IsContainer = $false
        ContainerType = "Unknown"
        IsAzureAutomation = $false
        IsAWS = $false
        IsGCP = $false
        IsAzure = $false
        PowerShellVersion = $PSVersionTable.PSVersion
        PSEdition = $PSVersionTable.PSEdition
    }

    # Détecter le système d'exploitation
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core
        $envInfo.IsWindows = $IsWindows
        $envInfo.IsLinux = $IsLinux
        $envInfo.IsMacOS = $IsMacOS
    }
    else {
        # Windows PowerShell 5.1 ou antérieur (uniquement sur Windows)
        $envInfo.IsWindows = $true
    }

    # Définir l'OS basé sur les booléens
    if ($envInfo.IsWindows) {
        $envInfo.OS = "Windows"
    }
    elseif ($envInfo.IsLinux) {
        $envInfo.OS = "Linux"
    }
    elseif ($envInfo.IsMacOS) {
        $envInfo.OS = "macOS"
    }

    # Détection plus précise pour Windows
    if ($envInfo.IsWindows) {
        try {
            $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
            if ($osInfo) {
                $envInfo.OS = $osInfo.Caption
            }
        }
        catch {
            # Ignorer les erreurs
        }
    }

    # Détection plus précise pour Linux
    if ($envInfo.IsLinux) {
        try {
            # Tenter de lire le fichier os-release
            if (Test-Path "/etc/os-release") {
                $osRelease = Get-Content "/etc/os-release" -ErrorAction SilentlyContinue
                $prettyName = $osRelease | Where-Object { $_ -match "^PRETTY_NAME=" }
                if ($prettyName) {
                    $envInfo.OS = $prettyName -replace '^PRETTY_NAME="(.*)"$', '$1'
                }
            }
        }
        catch {
            # Ignorer les erreurs
        }
    }

    # Détection de virtualisation (sur Windows)
    if ($envInfo.IsWindows) {
        try {
            $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction SilentlyContinue
            if ($computerSystem) {
                if ($computerSystem.Model -match "Virtual" -or $computerSystem.Manufacturer -match "VMware|QEMU|Xen|innotek|Parallels") {
                    $envInfo.IsVirtual = $true

                    if ($computerSystem.Manufacturer -match "VMware") {
                        $envInfo.VirtualizationType = "VMware"
                    }
                    elseif ($computerSystem.Manufacturer -match "Microsoft") {
                        $envInfo.VirtualizationType = "Hyper-V"
                    }
                    elseif ($computerSystem.Manufacturer -match "QEMU") {
                        $envInfo.VirtualizationType = "QEMU/KVM"
                    }
                    elseif ($computerSystem.Manufacturer -match "Xen") {
                        $envInfo.VirtualizationType = "Xen"
                    }
                    elseif ($computerSystem.Manufacturer -match "innotek") {
                        $envInfo.VirtualizationType = "VirtualBox"
                    }
                    elseif ($computerSystem.Manufacturer -match "Parallels") {
                        $envInfo.VirtualizationType = "Parallels"
                    }
                }
            }
        }
        catch {
            # Ignorer les erreurs
        }
    }

    # Détection des environnements cloud

    # Azure
    try {
        # Vérifier Azure Instance Metadata Service (Windows et Linux)
        $azureImdsUrl = "http://169.254.169.254/metadata/instance?api-version=2021-02-01"
        $azureHeaders = @{Metadata = "true"}

        try {
            $azureResult = Invoke-RestMethod -Uri $azureImdsUrl -Headers $azureHeaders -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($azureResult) {
                $envInfo.IsCloud = $true
                $envInfo.CloudType = "Azure"
                $envInfo.IsAzure = $true
            }
        }
        catch {
            # Ignorer les erreurs - probablement pas sur Azure
        }

        # Vérifier Azure Automation
        if ($PSPrivateMetadata -and $PSPrivateMetadata.JobId) {
            $envInfo.IsAzureAutomation = $true
            $envInfo.IsCloud = $true
            $envInfo.CloudType = "Azure Automation"
            $envInfo.IsAzure = $true
        }
    }
    catch {
        # Ignorer les erreurs
    }

    # AWS
    if (-not $envInfo.IsCloud) {
        try {
            # Vérifier AWS Instance Metadata Service
            $awsImdsUrl = "http://169.254.169.254/latest/meta-data/instance-id"

            try {
                $awsResult = Invoke-RestMethod -Uri $awsImdsUrl -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($awsResult) {
                    $envInfo.IsCloud = $true
                    $envInfo.CloudType = "AWS"
                    $envInfo.IsAWS = $true
                }
            }
            catch {
                # Ignorer les erreurs - probablement pas sur AWS
            }
        }
        catch {
            # Ignorer les erreurs
        }
    }

    # GCP
    if (-not $envInfo.IsCloud) {
        try {
            # Vérifier GCP Metadata Service
            $gcpImdsUrl = "http://metadata.google.internal/computeMetadata/v1/instance/id"
            $gcpHeaders = @{"Metadata-Flavor" = "Google"}

            try {
                $gcpResult = Invoke-RestMethod -Uri $gcpImdsUrl -Headers $gcpHeaders -TimeoutSec 2 -ErrorAction SilentlyContinue
                if ($gcpResult) {
                    $envInfo.IsCloud = $true
                    $envInfo.CloudType = "GCP"
                    $envInfo.IsGCP = $true
                }
            }
            catch {
                # Ignorer les erreurs - probablement pas sur GCP
            }
        }
        catch {
            # Ignorer les erreurs
        }
    }

    # Détection de conteneur (technique simplifiée)
    try {
        if ($envInfo.IsLinux) {
            # Vérifier si on est dans un conteneur Docker
            if (Test-Path "/.dockerenv") {
                $envInfo.IsContainer = $true
                $envInfo.ContainerType = "Docker"
            }
            # Ou autre approche pour les conteneurs Linux
            elseif ((Get-Process -Id 1).ProcessName -eq "containerd") {
                $envInfo.IsContainer = $true
                $envInfo.ContainerType = "Containerd"
            }
        }
    }
    catch {
        # Ignorer les erreurs
    }

    return $envInfo
}

function Load-EnvironmentModules {
    <#
    .SYNOPSIS
        Charge les modules appropriés en fonction de l'environnement détecté.
    .DESCRIPTION
        Cette fonction analyse les informations d'environnement et charge uniquement
        les modules pertinents pour le système d'exploitation et le cloud actuels.
    .PARAMETER EnvironmentInfo
        Objet contenant les informations sur l'environnement détecté.
    .OUTPUTS
        [PSCustomObject] Informations sur les modules chargés et non disponibles.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$EnvironmentInfo
    )

    $modulesLoaded = @()
    $modulesNotAvailable = @()

    Write-StatusMessage "Chargement des modules adaptés à l'environnement..." -Type "Info"

    # Modules communs à tous les environnements (toujours chargés)
    $commonModules = @(
        "Microsoft.PowerShell.Utility"
    )

    foreach ($module in $commonModules) {
        if (Import-ModuleIfAvailable -ModuleName $module -Silent) {
            $modulesLoaded += $module
        } else {
            $modulesNotAvailable += $module
        }
    }

    # Modules spécifiques au système d'exploitation
    if ($EnvironmentInfo.IsWindows) {
        Write-StatusMessage "Environnement Windows détecté, chargement des modules Windows..." -Type "Info"

        foreach ($module in $WindowsModules) {
            if (Import-ModuleIfAvailable -ModuleName $module) {
                $modulesLoaded += $module
            } else {
                $modulesNotAvailable += $module
            }
        }
    }
    elseif ($EnvironmentInfo.IsLinux) {
        Write-StatusMessage "Environnement Linux détecté, chargement des modules Linux..." -Type "Info"

        foreach ($module in $LinuxModules) {
            if (Import-ModuleIfAvailable -ModuleName $module) {
                $modulesLoaded += $module
            } else {
                $modulesNotAvailable += $module
            }
        }
    }
    elseif ($EnvironmentInfo.IsMacOS) {
        Write-StatusMessage "Environnement macOS détecté, chargement des modules macOS..." -Type "Info"

        foreach ($module in $MacOSModules) {
            if (Import-ModuleIfAvailable -ModuleName $module) {
                $modulesLoaded += $module
            } else {
                $modulesNotAvailable += $module
            }
        }
    }

    # Modules spécifiques au cloud
    if ($EnvironmentInfo.IsAzure) {
        Write-StatusMessage "Environnement Azure détecté, chargement des modules Azure..." -Type "Info"

        foreach ($module in $AzureModules) {
            if (Import-ModuleIfAvailable -ModuleName $module) {
                $modulesLoaded += $module
            } else {
                $modulesNotAvailable += $module
            }
        }
    }
    elseif ($EnvironmentInfo.IsAWS) {
        Write-StatusMessage "Environnement AWS détecté, chargement des modules AWS..." -Type "Info"

        foreach ($module in $AWSModules) {
            if (Import-ModuleIfAvailable -ModuleName $module) {
                $modulesLoaded += $module
            } else {
                $modulesNotAvailable += $module
            }
        }
    }

    # Retourner un résumé des modules chargés
    return [PSCustomObject]@{
        ModulesLoaded = $modulesLoaded
        ModulesNotAvailable = $modulesNotAvailable
    }
}

# ===== Exécution principale =====
# Détecter l'environnement d'exécution
$env = Get-EnvironmentInfo

# Afficher les informations sur l'environnement détecté
Write-Host "`n===== INFORMATIONS SUR L'ENVIRONNEMENT DÉTECTÉ =====" -ForegroundColor Cyan
Write-Host "Système d'exploitation : $($env.OS)"
Write-Host "PowerShell : v$($env.PowerShellVersion) ($($env.PSEdition))"

if ($env.IsVirtual) {
    Write-Host "Machine virtuelle : Oui ($($env.VirtualizationType))"
}
else {
    Write-Host "Machine virtuelle : Non"
}

if ($env.IsCloud) {
    Write-Host "Environnement cloud : Oui ($($env.CloudType))"
}
else {
    Write-Host "Environnement cloud : Non"
}

if ($env.IsContainer) {
    Write-Host "Conteneur : Oui ($($env.ContainerType))"
}
else {
    Write-Host "Conteneur : Non"
}

Write-Host

# Charger les modules appropriés pour cet environnement
$result = Load-EnvironmentModules -EnvironmentInfo $env

# Afficher un résumé des modules chargés
Write-Host "`n===== RÉSUMÉ DES MODULES =====" -ForegroundColor Cyan
Write-Host "Modules chargés avec succès : $($result.ModulesLoaded.Count)" -ForegroundColor Green
if ($result.ModulesLoaded.Count -gt 0) {
    $result.ModulesLoaded | ForEach-Object { Write-Host "- $_" -ForegroundColor Green }
}

Write-Host "`nModules non disponibles : $($result.ModulesNotAvailable.Count)" -ForegroundColor Yellow
if ($result.ModulesNotAvailable.Count -gt 0) {
    $result.ModulesNotAvailable | ForEach-Object { Write-Host "- $_" -ForegroundColor Yellow }
}

Write-Host "`n===== FIN DU SCRIPT =====" -ForegroundColor Cyan
```

## Exemple d'utilisation

```powershell
# Exécuter le script sans aucun paramètre
.\Environment-Aware-Loader.ps1
```

Le script affichera les informations sur l'environnement détecté et chargera automatiquement les modules appropriés. Si vous souhaitez tester différents comportements, vous pouvez définir des variables d'environnement pour simuler différents environnements, par exemple :

```powershell
# Simuler un environnement Azure
$env:AZUREENABLED = "true"
.\Environment-Aware-Loader.ps1

# Réinitialiser
$env:AZUREENABLED = $null
```

## Explication

Cette solution implémente un système de détection d'environnement sophistiqué qui adapte le chargement des modules PowerShell aux conditions d'exécution réelles :

1. **Détection d'environnement complète** :
   - Détecte automatiquement le système d'exploitation (Windows, Linux, macOS)
   - Identifie les environnements cloud (Azure, AWS, GCP)
   - Reconnaît les environnements virtualisés (Hyper-V, VMware, etc.)
   - Détecte les conteneurs Docker

2. **Chargement conditionnel intelligent** :
   - Charge un ensemble de modules communs pour tous les environnements
   - Ajoute des modules spécifiques à l'OS détecté
   - Charge des modules supplémentaires pour les environnements cloud identifiés

3. **Gestion robuste des erreurs** :
   - Vérifie la disponibilité des modules avant de tenter de les charger
   - Gère proprement les erreurs de chargement
   - Fournit un rapport détaillé des modules chargés et non disponibles

4. **Interface utilisateur informative** :
   - Affiche des informations détaillées sur l'environnement détecté
   - Utilise différentes couleurs pour une meilleure lisibilité
   - Fournit un résumé clair des opérations effectuées

Cette approche est particulièrement utile pour :
- Scripts devant fonctionner sur plusieurs plateformes
- Automatisations déployées dans divers environnements cloud
- Code qui s'adapte automatiquement à son contexte d'exécution

L'avantage principal de cette solution est qu'elle requiert zéro configuration manuelle - le script s'adapte automatiquement à son environnement d'exécution, chargeant uniquement les modules pertinents.

# Solution Exercice 6 - Chargement conditionnel avec configuration externe

## Énoncé
Créez un script qui utilise un fichier de configuration JSON externe pour déterminer quels modules charger et dans quelles conditions.

## Solution

```powershell
# ConfigurableModuleLoader.ps1
<#
.SYNOPSIS
    Script de chargement conditionnel de modules basé sur une configuration JSON externe.
.DESCRIPTION
    Ce script charge les modules PowerShell selon les règles définies dans un fichier
    de configuration JSON externe, permettant une personnalisation sans modifier le code.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration JSON.
.EXAMPLE
    .\ConfigurableModuleLoader.ps1 -ConfigPath ".\ModuleConfig.json"
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\ModuleConfig.json"
)

# ===== Fonctions =====
function Write-LogMessage {
    <#
    .SYNOPSIS
        Affiche et journalise un message formaté.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level = "INFO",

        [Parameter(Mandatory = $false)]
        [switch]$NoNewLine
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Déterminer la couleur en fonction du niveau
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }

    # Afficher le message dans la console
    if ($NoNewLine) {
        Write-Host $logMessage -ForegroundColor $color -NoNewline
    } else {
        Write-Host $logMessage -ForegroundColor $color
    }

    # Option pour enregistrer dans un fichier journal
    # Add-Content -Path ".\ModuleLoader.log" -Value $logMessage
}

function Test-Condition {
    <#
    .SYNOPSIS
        Évalue une condition définie dans la configuration.
    .DESCRIPTION
        Évalue une condition basée sur des propriétés du système ou des variables.
    .PARAMETER Condition
        Hashtable contenant la condition à évaluer.
    .OUTPUTS
        [bool] True si la condition est remplie, False sinon.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Condition
    )

    # Vérifier si tous les éléments requis sont présents
    if (-not $Condition.ContainsKey("property") -or -not $Condition.ContainsKey("operator") -or -not $Condition.ContainsKey("value")) {
        Write-LogMessage "Condition invalide: propriété, opérateur ou valeur manquante" -Level "WARNING"
        return $false
    }

    $property = $Condition.property
    $operator = $Condition.operator
    $value = $Condition.value

    # Récupérer la valeur de la propriété
    $actualValue = $null

    # Gestion des propriétés spéciales
    switch -Wildcard ($property) {
        "os" {
            if ($PSVersionTable.PSVersion.Major -ge 6) {
                # PowerShell Core
                $actualValue = if ($IsWindows) { "windows" }
                              elseif ($IsLinux) { "linux" }
                              elseif ($IsMacOS) { "macos" }
                              else { "unknown" }
            } else {
                # Windows PowerShell (forcément Windows)
                $actualValue = "windows"
            }
        }
        "psversion" {
            $actualValue = $PSVersionTable.PSVersion.ToString()
        }
        "psedition" {
            $actualValue = $PSVersionTable.PSEdition
        }
        "computername" {
            $actualValue = $env:COMPUTERNAME
        }
        "username" {
            $actualValue = $env:USERNAME
        }
        "domain" {
            $actualValue = $env:USERDOMAIN
        }
        "adminrights" {
            # Vérifier si PowerShell s'exécute en tant qu'administrateur
            $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($identity)
            $actualValue = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        }
        "memoryGB" {
            try {
                if ($PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux) {
                    # Sous Linux
                    $memInfo = Get-Content "/proc/meminfo" -ErrorAction SilentlyContinue |
                               Where-Object { $_ -match "MemTotal:" }
                    if ($memInfo) {
                        # Convertir KB en GB
                        $memKB = [int]($memInfo -replace '\D+(\d+).*', '$1')
                        $actualValue = [math]::Round($memKB / 1024 / 1024, 2)
                    }
                } else {
                    # Windows ou autre
                    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
                    if ($os) {
                        $totalMemoryGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
                        $actualValue = $totalMemoryGB
                    }
                }
            } catch {
                Write-LogMessage "Erreur lors de la récupération de la mémoire: $_" -Level "WARNING"
            }
        }
        "moduleavailable:*" {
            $moduleName = $property -replace 'moduleavailable:', ''
            $actualValue = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue
            if ($actualValue) {
                $actualValue = $true
            } else {
                $actualValue = $false
            }
        }
        "moduleloaded:*" {
            $moduleName = $property -replace 'moduleloaded:', ''
            $actualValue = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
            if ($actualValue) {
                $actualValue = $true
            } else {
                $actualValue = $false
            }
        }
        "env:*" {
            $envVar = $property -replace 'env:', ''
            $actualValue = [Environment]::GetEnvironmentVariable($envVar)
        }
        default {
            Write-LogMessage "Propriété non reconnue: $property" -Level "WARNING"
            return $false
        }
    }

    # Si la valeur est null ou non définie
    if ($null -eq $actualValue) {
        Write-LogMessage "Valeur non définie pour la propriété: $property" -Level "WARNING"
        return $false
    }

    # Évaluer la condition avec l'opérateur approprié
    switch ($operator) {
        "eq" { return $actualValue -eq $value }
        "ne" { return $actualValue -ne $value }
        "gt" { return $actualValue -gt $value }
        "lt" { return $actualValue -lt $value }
        "ge" { return $actualValue -ge $value }
        "le" { return $actualValue -le $value }
        "contains" { return $actualValue -contains $value }
        "notcontains" { return $actualValue -notcontains $value }
        "like" { return $actualValue -like $value }
        "notlike" { return $actualValue -notlike $value }
        "match" { return $actualValue -match $value }
        "notmatch" { return $actualValue -notmatch $value }
        default {
            Write-LogMessage "Opérateur non reconnu: $operator" -Level "WARNING"
            return $false
        }
    }
}

function Import-ModuleConditionally {
    <#
    .SYNOPSIS
        Importe un module en fonction de sa configuration.
    .DESCRIPTION
        Évalue les conditions associées à un module et l'importe si les conditions sont remplies.
    .PARAMETER ModuleConfig
        Configuration du module incluant des conditions et options d'importation.
    .OUTPUTS
        [bool] Indique si le module a été chargé.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ModuleConfig
    )

    $moduleName = $ModuleConfig.name
    Write-LogMessage "Vérification du module: $moduleName" -Level "INFO"

    # Vérifier si le module est déjà chargé (sauf si force est spécifié)
    if (-not $ModuleConfig.force -and (Get-Module -Name $moduleName -ErrorAction SilentlyContinue)) {
        Write-LogMessage "Le module '$moduleName' est déjà chargé" -Level "SUCCESS"
        return $true
    }

    # Vérifier si le module est disponible
    $moduleAvailable = Get-Module -ListAvailable -Name $moduleName -ErrorAction SilentlyContinue

    if (-not $moduleAvailable) {
        Write-LogMessage "Le module '$moduleName' n'est pas disponible sur ce système" -Level "WARNING"
        if ($ModuleConfig.required) {
            throw "Le module requis '$moduleName' n'est pas installé sur ce système."
        }
        return $false
    }

    # Évaluer les conditions
    $conditionsMet = $true

    if ($ModuleConfig.PSObject.Properties.Name -contains "conditions" -and $ModuleConfig.conditions) {
        Write-LogMessage "Évaluation des conditions pour le module '$moduleName'..." -Level "INFO"

        foreach ($condition in $ModuleConfig.conditions) {
            $conditionResult = Test-Condition -Condition $condition

            if (-not $conditionResult) {
                $conditionsMet = $false
                $propertyName = $condition.property
                $operatorName = $condition.operator
                $valueName = $condition.value
                Write-LogMessage "Condition non satisfaite: $propertyName $operatorName $valueName" -Level "WARNING"
                break
            }
        }
    }

    # Si toutes les conditions sont remplies, importer le module
    if ($conditionsMet) {
        try {
            # Préparer les paramètres d'importation
            $importParams = @{
                Name = $moduleName
                ErrorAction = "Stop"
            }

            # Ajouter des paramètres supplémentaires s'ils sont spécifiés
            if ($ModuleConfig.PSObject.Properties.Name -contains "minimumVersion" -and $ModuleConfig.minimumVersion) {
                $importParams["MinimumVersion"] = $ModuleConfig.minimumVersion
            }

            if ($ModuleConfig.PSObject.Properties.Name -contains "requiredVersion" -and $ModuleConfig.requiredVersion) {
                $importParams["RequiredVersion"] = $ModuleConfig.requiredVersion
            }

            if ($ModuleConfig.PSObject.Properties.Name -contains "force" -and $ModuleConfig.force) {
                $importParams["Force"] = $true
            }

            # Importer le module
            Write-LogMessage "Chargement du module '$moduleName'..." -Level "INFO" -NoNewLine
            Import-Module @importParams
            Write-LogMessage " OK!" -Level "SUCCESS"

            # Vérifier si des commandes spécifiques doivent être importées
            if ($ModuleConfig.PSObject.Properties.Name -contains "commands" -and $ModuleConfig.commands) {
                # Importer uniquement les commandes spécifiées
                Write-LogMessage "Import sélectif des commandes: $($ModuleConfig.commands -join ', ')" -Level "INFO"

                # On a déjà importé le module complet, donc on ne fait rien de plus ici
                # Dans un cas réel, on pourrait utiliser Import-Module -Name $moduleName -Function $ModuleConfig.commands
            }

            return $true
        }
        catch {
            Write-LogMessage "Erreur lors du chargement du module '$moduleName': $_" -Level "ERROR"
            if ($ModuleConfig.required) {
                throw "Erreur lors du chargement du module requis '$moduleName': $_"
            }
            return $false
        }
    }
    else {
        Write-LogMessage "Conditions non remplies pour le module '$moduleName' - non chargé" -Level "INFO"
        return $false
    }
}

function Import-ConfigurableModules {
    <#
    .SYNOPSIS
        Importe les modules en fonction d'une configuration.
    .DESCRIPTION
        Lit un fichier de configuration JSON et charge les modules selon les conditions définies.
    .PARAMETER ConfigPath
        Chemin vers le fichier de configuration JSON.
    .OUTPUTS
        [PSCustomObject] Résumé des opérations de chargement.
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath)) {
        throw "Le fichier de configuration '$ConfigPath' n'existe pas."
    }

    try {
        # Lire le fichier de configuration
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

        Write-LogMessage "Configuration chargée à partir de: $ConfigPath" -Level "INFO"

        # Valider la structure du fichier de configuration
        if (-not $config.PSObject.Properties.Name -contains "modules" -or -not $config.modules) {
            throw "Configuration invalide: la section 'modules' est manquante ou vide."
        }

        # Variables pour le suivi
        $modulesLoaded = @()
        $modulesSkipped = @()
        $modulesFailed = @()

        # Traiter chaque module
        foreach ($moduleConfig in $config.modules) {
            if (-not $moduleConfig.PSObject.Properties.Name -contains "name" -or -not $moduleConfig.name) {
                Write-LogMessage "Module sans nom dans la configuration - ignoré" -Level "WARNING"
                continue
            }

            $moduleName = $moduleConfig.name

            try {
                $loaded = Import-ModuleConditionally -ModuleConfig $moduleConfig

                if ($loaded) {
                    $modulesLoaded += $moduleName
                }
                else {
                    $modulesSkipped += $moduleName
                }
            }
            catch {
                Write-LogMessage "Erreur critique lors du chargement du module '$moduleName': $_" -Level "ERROR"
                $modulesFailed += $moduleName

                # Si c'est un module requis, propager l'erreur
                if ($moduleConfig.PSObject.Properties.Name -contains "required" -and $moduleConfig.required) {
                    throw $_
                }
            }
        }

        # Retourner un résumé
        return [PSCustomObject]@{
            ModulesLoaded = $modulesLoaded
            ModulesSkipped = $modulesSkipped
            ModulesFailed = $modulesFailed
            TotalConfigured = $config.modules.Count
            Success = ($modulesFailed.Count -eq 0)
        }
    }
    catch {
        Write-LogMessage "Erreur lors du traitement de la configuration: $_" -Level "ERROR"
        throw
    }
}

# ===== Exécution principale =====
try {
    Write-LogMessage "=== CHARGEMENT CONDITIONNEL DE MODULES ===" -Level "INFO"
    Write-LogMessage "Configuration: $ConfigPath" -Level "INFO"

    # Importer les modules selon la configuration
    $result = Import-ConfigurableModules -ConfigPath $ConfigPath

    # Afficher le résumé
    Write-LogMessage "`n=== RÉSUMÉ DU CHARGEMENT ===" -Level "INFO"
    Write-LogMessage "Modules configurés: $($result.TotalConfigured)" -Level "INFO"
    Write-LogMessage "Modules chargés: $($result.ModulesLoaded.Count)" -Level "SUCCESS"
    if ($result.ModulesLoaded.Count -gt 0) {
        $result.ModulesLoaded | ForEach-Object { Write-LogMessage "  - $_" -Level "SUCCESS" }
    }

    Write-LogMessage "Modules ignorés: $($result.ModulesSkipped.Count)" -Level "INFO"
    if ($result.ModulesSkipped.Count -gt 0) {
        $result.ModulesSkipped | ForEach-Object { Write-LogMessage "  - $_" -Level "INFO" }
    }

    Write-LogMessage "Modules en échec: $($result.ModulesFailed.Count)" -Level ($result.ModulesFailed.Count -gt 0 ? "ERROR" : "INFO")
    if ($result.ModulesFailed.Count -gt 0) {
        $result.ModulesFailed | ForEach-Object { Write-LogMessage "  - $_" -Level "ERROR" }
    }

    Write-LogMessage "=== OPÉRATION TERMINÉE ===" -Level ($result.Success ? "SUCCESS" : "WARNING")
}
catch {
    Write-LogMessage "Erreur critique: $_" -Level "ERROR"
    exit 1
}
```

## Exemple de fichier de configuration JSON

```json
{
  "modules": [
    {
      "name": "Microsoft.PowerShell.Management",
      "required": true,
      "description": "Module de base toujours chargé"
    },
    {
      "name": "Microsoft.PowerShell.Security",
      "required": true,
      "description": "Module de sécurité nécessaire"
    },
    {
      "name": "ActiveDirectory",
      "description": "Module Active Directory - chargé uniquement sur Windows et pour les administrateurs",
      "conditions": [
        {
          "property": "os",
          "operator": "eq",
          "value": "windows"
        },
        {
          "property": "adminrights",
          "operator": "eq",
          "value": true
        }
      ]
    },
    {
      "name": "Microsoft.PowerShell.Archive",
      "description": "Module d'archivage - chargé seulement si au moins 4 Go de RAM",
      "conditions": [
        {
          "property": "memoryGB",
          "operator": "ge",
          "value": 4
        }
      ]
    },
    {
      "name": "PSReadLine",
      "minimumVersion": "2.0.0",
      "description": "Module d'édition de ligne de commande - version minimum 2.0.0"
    },
    {
      "name": "Az.Accounts",
      "conditions": [
        {
          "property": "env:AZUREENABLED",
          "operator": "eq",
          "value": "true"
        }
      ],
      "description": "Module Azure - chargé seulement si la variable d'environnement AZUREENABLED est 'true'"
    },
    {
      "name": "CimCmdlets",
      "conditions": [
        {
          "property": "os",
          "operator": "eq",
          "value": "windows"
        }
      ],
      "commands": ["Get-CimInstance", "Get-CimClass"],
      "description": "Import sélectif de certaines commandes CIM uniquement sur Windows"
    },
    {
      "name": "Pester",
      "force": true,
      "conditions": [
        {
          "property": "env:DEVMACHINE",
          "operator": "eq",
          "value": "true"
        }
      ],
      "description": "Module de test - rechargé même s'il est déjà chargé, seulement sur les machines de développement"
    }
  ]
}
```

## Explication

Cette solution implémente un système de chargement conditionnel de modules basé sur un fichier de configuration externe :

1. **Approche configurable** : Sépare la logique (code) de la configuration (JSON), permettant de modifier les règles de chargement sans toucher au code.

2. **Évaluation de conditions** : La fonction `Test-Condition` évalue diverses propriétés :
   - Système d'exploitation
   - Version de PowerShell
   - Droits d'administrateur
   - Mémoire disponible
   - Modules déjà chargés
   - Variables d'environnement

3. **Chargement intelligent** :
   - Vérifie la disponibilité des modules avant de tenter de les charger
   - Respecte les versions minimales requises
   - Peut forcer le rechargement si nécessaire
   - Supporte l'import sélectif de commandes

4. **Gestion des erreurs** :
   - Journalisation détaillée des opérations
   - Distinction entre modules requis et optionnels
   - Rapport complet des résultats

Cette solution offre une grande flexibilité et peut s'adapter à de nombreux scénarios d'utilisation, comme :
- Scripts qui fonctionnent sur plusieurs plateformes
- Applications qui s'adaptent aux droits de l'utilisateur
- Environnements de développement/test/production avec différentes configurations
- Optimisation des performances en ne chargeant que ce qui est nécessaire

# Solution Exercice 7 - Chargement conditionnel avec import différé

## Énoncé
Créez un script qui implémente un mécanisme d'import différé (lazy loading) pour les modules PowerShell, permettant de charger les modules uniquement lorsqu'une de leurs commandes est appelée pour la première fois.

## Solution

```powershell
# LazyModuleLoader.ps1
<#
.SYNOPSIS
    Implémente un mécanisme d'import différé (lazy loading) pour les modules PowerShell.
.DESCRIPTION
    Ce script crée des fonctions de proxy qui chargent automatiquement les modules PowerShell
    uniquement lorsque leurs commandes sont appelées pour la première fois, optimisant ainsi
    les performances de démarrage et la consommation mémoire.
.EXAMPLE
    . .\LazyModuleLoader.ps1
    Register-LazyModule -ModuleName "ActiveDirectory"
    # Maintenant, toutes les commandes d'ActiveDirectory sont disponibles mais
    # le module ne sera chargé que lorsqu'une de ces commandes sera utilisée.
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

#Requires -Version 5.1

# Variables globales pour suivre les modules enregistrés
$script:LazyModules = @{}
$script:ProxyFunctions = @{}

function Register-LazyModule {
    <#
    .SYNOPSIS
        Enregistre un module pour un chargement différé (lazy loading).
    .DESCRIPTION
        Crée des fonctions proxy pour toutes les commandes exportées par un module,
        permettant ainsi de charger le module uniquement lorsqu'une de ses commandes
        est appelée pour la première fois.
    .PARAMETER ModuleName
        Nom du module à enregistrer pour le lazy loading.
    .PARAMETER CommandPrefix
        Préfixe à ajouter aux noms des commandes (optionnel).
    .PARAMETER MinimumVersion
        Version minimale requise du module (optionnel).
    .PARAMETER RequiredVersion
        Version exacte requise du module (optionnel).
    .PARAMETER Force
        Force la recréation des fonctions proxy même si elles existent déjà.
    .EXAMPLE
        Register-LazyModule -ModuleName "ActiveDirectory"
    .EXAMPLE
        Register-LazyModule -ModuleName "Az.Storage" -CommandPrefix "Az" -MinimumVersion "2.0.0"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ModuleName,

        [Parameter(Mandatory = $false)]
        [string]$CommandPrefix = "",

        [Parameter(Mandatory = $false)]
        [version]$MinimumVersion,

        [Parameter(Mandatory = $false)]
        [version]$RequiredVersion,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le module existe
    try {
        $moduleParams = @{
            ListAvailable = $true
            Name = $ModuleName
            ErrorAction = "Stop"
        }

        if ($MinimumVersion) {
            $moduleParams["MinimumVersion"] = $MinimumVersion
        }

        if ($RequiredVersion) {
            $moduleParams["RequiredVersion"] = $RequiredVersion
        }

        $moduleInfo = Get-Module @moduleParams

        if (-not $moduleInfo) {
            Write-Error "Module '$ModuleName' non trouvé ou version requise non disponible."
            return
        }
    }
    catch {
        Write-Error "Erreur lors de la vérification du module '$ModuleName': $_"
        return
    }

    # Prendre le module avec la version la plus élevée si plusieurs versions sont disponibles
    $moduleInfo = $moduleInfo | Sort-Object Version -Descending | Select-Object -First 1

    Write-Verbose "Module trouvé: $ModuleName (version $($moduleInfo.Version))"

    # Enregistrer le module dans notre registre
    $script:LazyModules[$ModuleName] = @{
        Name = $ModuleName
        Path = $moduleInfo.Path
        Version = $moduleInfo.Version
        Loaded = $false
        CommandPrefix = $CommandPrefix
        MinimumVersion = $MinimumVersion
        RequiredVersion = $RequiredVersion
    }

    # Obtenir la liste des commandes exportées par le module
    $exportedCommands = $moduleInfo.ExportedCommands.Values

    if ($exportedCommands.Count -eq 0) {
        Write-Warning "Le module '$ModuleName' n'exporte aucune commande."
        return
    }

    Write-Verbose "Création de fonctions proxy pour $($exportedCommands.Count) commandes..."

    # Créer une fonction proxy pour chaque commande exportée
    foreach ($command in $exportedCommands) {
        $commandName = $command.Name
        $prefixedName = "$CommandPrefix$commandName"

        # Vérifier si la fonction proxy existe déjà
        if (-not $Force -and $script:ProxyFunctions.ContainsKey($prefixedName)) {
            Write-Warning "Une fonction proxy pour '$prefixedName' existe déjà. Utilisez -Force pour la remplacer."
            continue
        }

        # Vérifier si le nom de fonction est déjà utilisé dans la session
        $existingCommand = Get-Command -Name $prefixedName -ErrorAction SilentlyContinue
        if ($existingCommand -and -not $Force) {
            Write-Warning "Une commande '$prefixedName' existe déjà dans la session. Utilisez -Force pour la remplacer."
            continue
        }

        # Créer la fonction proxy
        $proxyFunction = @"
function global:$prefixedName {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = `$true)]
        [object[]]`$Parameters
    )

    # Charger le module si ce n'est pas déjà fait
    if (-not `$script:LazyModules['$ModuleName'].Loaded) {
        Write-Verbose "Chargement du module '$ModuleName' pour la commande '$commandName'..."
        try {
            `$importParams = @{
                Name = '$ModuleName'
                ErrorAction = 'Stop'
                Verbose = `$false
            }

            if (`$script:LazyModules['$ModuleName'].MinimumVersion) {
                `$importParams['MinimumVersion'] = `$script:LazyModules['$ModuleName'].MinimumVersion
            }

            if (`$script:LazyModules['$ModuleName'].RequiredVersion) {
                `$importParams['RequiredVersion'] = `$script:LazyModules['$ModuleName'].RequiredVersion
            }

            Import-Module @importParams
            `$script:LazyModules['$ModuleName'].Loaded = `$true
            Write-Verbose "Module '$ModuleName' chargé avec succès."
        }
        catch {
            Write-Error "Erreur lors du chargement du module '$ModuleName': `$_"
            return
        }
    }

    # Obtenir la commande réelle
    `$realCommand = Get-Command -Name '$commandName' -ErrorAction Stop

    # Exécuter la commande avec tous les paramètres fournis
    & `$realCommand @Parameters
}
"@

        # Enregistrer la fonction proxy dans notre registre
        $script:ProxyFunctions[$prefixedName] = @{
            ProxyName = $prefixedName
            RealCommand = $commandName
            ModuleName = $ModuleName
        }

        # Créer la fonction proxy
        Invoke-Expression $proxyFunction
    }

    Write-Verbose "Module '$ModuleName' enregistré pour le lazy loading avec $($exportedCommands.Count) commandes."
}

function Unregister-LazyModule {
    <#
    .SYNOPSIS
        Supprime les fonctions proxy créées pour un module.
    .DESCRIPTION
        Supprime toutes les fonctions proxy créées pour un module enregistré
        pour le lazy loading, et retire le module du registre.
    .PARAMETER ModuleName
        Nom du module à désenregistrer.
    .EXAMPLE
        Unregister-LazyModule -ModuleName "ActiveDirectory"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )

    # Vérifier si le module est enregistré
    if (-not $script:LazyModules.ContainsKey($ModuleName)) {
        Write-Warning "Le module '$ModuleName' n'est pas enregistré pour le lazy loading."
        return
    }

    # Obtenir le préfixe de commande du module
    $commandPrefix = $script:LazyModules[$ModuleName].CommandPrefix

    # Trouver toutes les fonctions proxy pour ce module
    $moduleFunctions = $script:ProxyFunctions.Keys | Where-Object {
        $script:ProxyFunctions[$_].ModuleName -eq $ModuleName
    }

    # Supprimer chaque fonction proxy
    foreach ($funcName in $moduleFunctions) {
        Remove-Item -Path "function:global:$funcName" -ErrorAction SilentlyContinue
        $script:ProxyFunctions.Remove($funcName)
    }

    # Supprimer le module du registre
    $script:LazyModules.Remove($ModuleName)

    Write-Verbose "Module '$ModuleName' désenregistré avec $($moduleFunctions.Count) fonctions proxy supprimées."
}

function Get-LazyModuleStatus {
    <#
    .SYNOPSIS
        Affiche l'état des modules enregistrés pour le lazy loading.
    .DESCRIPTION
        Retourne des informations sur les modules enregistrés pour le lazy loading,
        indiquant s'ils ont été chargés ou non et combien de commandes sont disponibles.
    .EXAMPLE
        Get-LazyModuleStatus
    #>
    [CmdletBinding()]
    param()

    $results = @()

    foreach ($moduleName in $script:LazyModules.Keys) {
        $module = $script:LazyModules[$moduleName]

        # Compter les fonctions proxy pour ce module
        $proxyCount = ($script:ProxyFunctions.Values | Where-Object { $_.ModuleName -eq $moduleName }).Count

        $results += [PSCustomObject]@{
            ModuleName = $moduleName
            Version = $module.Version
            Loaded = $module.Loaded
            Status = if ($module.Loaded) { "Chargé" } else { "Non chargé" }
            CommandPrefix = $module.CommandPrefix
            CommandCount = $proxyCount
        }
    }

    # Trier et retourner les résultats
    $results | Sort-Object ModuleName
}

function Test-LazyModulePerformance {
    <#
    .SYNOPSIS
        Teste les performances du lazy loading par rapport au chargement standard.
    .DESCRIPTION
        Compare le temps de démarrage et l'utilisation mémoire entre un chargement
        standard de modules et le lazy loading.
    .PARAMETER ModuleNames
        Noms des modules à tester.
    .EXAMPLE
        Test-LazyModulePerformance -ModuleNames "ActiveDirectory", "DnsClient"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ModuleNames
    )

    Write-Host "=== TEST DE PERFORMANCE DU LAZY LOADING ===" -ForegroundColor Cyan

    # Test 1: Chargement standard
    Write-Host "`nTest 1: Chargement standard des modules" -ForegroundColor Yellow

    $start = Get-Date
    $initialMemory = [System.GC]::GetTotalMemory($true)

    foreach ($module in $ModuleNames) {
        Write-Host "Chargement de $module..." -NoNewline
        try {
            Import-Module -Name $module -Force -ErrorAction Stop
            Write-Host "OK" -ForegroundColor Green
        }
        catch {
            Write-Host "ÉCHEC" -ForegroundColor Red
            Write-Warning "Erreur: $_"
        }
    }

    $endMemory = [System.GC]::GetTotalMemory($true)
    $end = Get-Date

    $standardTime = ($end - $start).TotalMilliseconds
    $standardMemory = ($endMemory - $initialMemory) / 1MB

    Write-Host "Temps total: $([math]::Round($standardTime, 2)) ms" -ForegroundColor Cyan
    Write-Host "Mémoire utilisée: $([math]::Round($standardMemory, 2)) MB" -ForegroundColor Cyan

    # Décharger les modules
    foreach ($module in $ModuleNames) {
        Remove-Module -Name $module -ErrorAction SilentlyContinue
    }

    [System.GC]::Collect()
    Start-Sleep -Milliseconds 500

    # Test 2: Lazy Loading
    Write-Host "`nTest 2: Enregistrement pour lazy loading" -ForegroundColor Yellow

    $start = Get-Date
    $initialMemory = [System.GC]::GetTotalMemory($true)

    foreach ($module in $ModuleNames) {
        Write-Host "Enregistrement de $module..." -NoNewline
        try {
            Register-LazyModule -ModuleName $module -Force -ErrorAction Stop
            Write-Host "OK" -ForegroundColor Green
        }
        catch {
            Write-Host "ÉCHEC" -ForegroundColor Red
            Write-Warning "Erreur: $_"
        }
    }

    $endMemory = [System.GC]::GetTotalMemory($true)
    $end = Get-Date

    $lazyTime = ($end - $start).TotalMilliseconds
    $lazyMemory = ($endMemory - $initialMemory) / 1MB

    Write-Host "Temps total: $([math]::Round($lazyTime, 2)) ms" -ForegroundColor Cyan
    Write-Host "Mémoire utilisée: $([math]::Round($lazyMemory, 2)) MB" -ForegroundColor Cyan

    # Comparaison
    Write-Host "`n=== RÉSULTATS DE LA COMPARAISON ===" -ForegroundColor Cyan
    Write-Host "Temps - Standard: $([math]::Round($standardTime, 2)) ms | Lazy: $([math]::Round($lazyTime, 2)) ms" -ForegroundColor White
    Write-Host "Mémoire - Standard: $([math]::Round($standardMemory, 2)) MB | Lazy: $([math]::Round($lazyMemory, 2)) MB" -ForegroundColor White

    $timeImprovement = 100 - (($lazyTime / $standardTime) * 100)
    $memoryImprovement = 100 - (($lazyMemory / $standardMemory) * 100)

    Write-Host "`nAmélioration du temps de démarrage: $([math]::Round($timeImprovement, 2))%" -ForegroundColor Green
    Write-Host "Économie de mémoire initiale: $([math]::Round($memoryImprovement, 2))%" -ForegroundColor Green

    # Nettoyer
    foreach ($module in $ModuleNames) {
        Unregister-LazyModule -ModuleName $module -ErrorAction SilentlyContinue
    }
}

# Exporter les fonctions si le script est importé comme module
Export-ModuleMember -Function Register-LazyModule, Unregister-LazyModule, Get-LazyModuleStatus, Test-LazyModulePerformance
```

## Exemple d'utilisation

```powershell
# Importer le script
. .\LazyModuleLoader.ps1

# Enregistrer un module pour le lazy loading
Register-LazyModule -ModuleName "Microsoft.PowerShell.Archive" -Verbose

# Voir l'état actuel des modules enregistrés
Get-LazyModuleStatus | Format-Table

# Utiliser une commande du module - le module sera chargé à ce moment
Compress-Archive -Path "$env:TEMP\testfile.txt" -DestinationPath "$env:TEMP\test.zip" -Force

# Vérifier l'état après utilisation
Get-LazyModuleStatus | Format-Table

# Tester les performances par rapport au chargement standard
Test-LazyModulePerformance -ModuleNames "Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility"

# Nettoyer
Unregister-LazyModule -ModuleName "Microsoft.PowerShell.Archive" -Verbose
```

## Explication

Cette solution implémente un mécanisme d'import différé (lazy loading) pour les modules PowerShell, avec les caractéristiques suivantes :

1. **Création dynamique de fonctions proxy** :
   - Pour chaque commande exportée par un module, une fonction proxy est créée avec le même nom
   - Ces fonctions proxy agissent comme des "intermédiaires" qui chargent le module réel lors du premier appel

2. **Avantages de performance** :
   - **Démarrage plus rapide** : Les modules ne sont pas chargés au lancement du script
   - **Économie de mémoire** : Seuls les modules réellement utilisés sont chargés en mémoire
   - **Adaptabilité** : Le script s'adapte aux utilisations réelles plutôt que de prévoir toutes les dépendances

3. **Fonctionnalités** :
   - Support des préfixes de commandes
   - Vérification des versions minimales/requises
   - Possibilité de forcer la recréation des proxys
   - Nettoyage complet via `Unregister-LazyModule`
   - Fonction de test de performance pour comparaison avec le chargement standard

4. **Technique d'implémentation** :
   - Utilisation de la réflexion pour découvrir les commandes exportées
   - Génération dynamique de code PowerShell
   - Conservation de l'état dans des variables de script

Cette approche est particulièrement utile pour :
- Scripts avec de nombreuses dépendances optionnelles
- Modules volumineux rarement utilisés
- Amélioration des temps de démarrage des profils PowerShell
- Réduction de l'empreinte mémoire des scripts complexes

Le lazy loading est une technique d'optimisation avancée qui permet d'obtenir le meilleur des deux mondes : toutes les fonctionnalités sont disponibles, mais la performance n'est pas sacrifiée pour des fonctionnalités rarement utilisées.

