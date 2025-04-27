# Solution Exercice 1 - Transformation d'un script en projet organisé

## Énoncé de l'exercice
> Prenez un de vos scripts existants et transformez-le en un projet organisé selon la structure présentée dans le cours. Identifiez quelles parties devraient être des fonctions publiques et lesquelles devraient rester privées.

## Script original (avant transformation)
Imaginons que nous avons ce script simple qui génère un rapport sur l'état des services Windows :

```powershell
# RapportServices.ps1

# Configuration
$OutputPath = "C:\Rapports"
$ServiceList = @("wuauserv", "spooler", "W32Time")
$LogFile = "$OutputPath\log.txt"

# Vérifier si le dossier de sortie existe, sinon le créer
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force
}

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Out-File -FilePath $LogFile -Append
}

# Fonction pour obtenir l'état d'un service
function Get-ServiceStatus {
    param (
        [string]$ServiceName
    )

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($service) {
        return [PSCustomObject]@{
            Name = $service.Name
            DisplayName = $service.DisplayName
            Status = $service.Status
            StartType = (Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'").StartMode
        }
    } else {
        Write-Log "Service $ServiceName introuvable"
        return $null
    }
}

# Fonction pour générer le rapport
function Create-Report {
    $reportDate = Get-Date -Format "yyyy-MM-dd"
    $reportFile = "$OutputPath\Rapport_Services_$reportDate.csv"

    $results = @()

    foreach ($service in $ServiceList) {
        $status = Get-ServiceStatus -ServiceName $service
        if ($status) {
            $results += $status
            Write-Log "Statut vérifié pour $service : $($status.Status)"
        }
    }

    $results | Export-Csv -Path $reportFile -NoTypeInformation -Delimiter ";"
    Write-Log "Rapport généré : $reportFile"

    return $reportFile
}

# Exécution principale
Write-Log "Début de l'exécution du script"
$reportFile = Create-Report
Write-Log "Fin de l'exécution du script"

Write-Host "Rapport généré avec succès : $reportFile" -ForegroundColor Green
```

## Solution : Transformation en projet organisé

### 1. Structure de dossiers à créer

```
ServiceStatusReport/
│
├── src/
│   ├── Public/
│   │   ├── Get-ServiceStatusReport.ps1
│   │   └── Export-ServiceStatusReport.ps1
│   │
│   └── Private/
│       ├── Get-DetailedServiceStatus.ps1
│       └── Write-ServiceLog.ps1
│
├── tests/
│   └── ServiceStatusReport.Tests.ps1
│
├── docs/
│   └── README.md
│
├── examples/
│   └── Generate-DailyReport.ps1
│
├── ServiceStatusReport.psd1
├── ServiceStatusReport.psm1
└── README.md
```

### 2. Fichiers principaux

#### README.md

```markdown
# ServiceStatusReport

Module PowerShell pour générer des rapports sur l'état des services Windows.

## Installation

```powershell
# Installation depuis le dossier local
Import-Module -Path ".\ServiceStatusReport" -Force

# Ou si publié sur PowerShell Gallery:
# Install-Module -Name ServiceStatusReport -Scope CurrentUser
```

## Utilisation

```powershell
# Générer un rapport pour les services Windows Update, Spooler et Time
$report = Get-ServiceStatusReport -ServiceList @("wuauserv", "spooler", "W32Time")

# Exporter le rapport vers un fichier CSV
$report | Export-ServiceStatusReport -Path "C:\Rapports"
```

## Fonctionnalités

- Interroge l'état des services Windows
- Récupère des informations détaillées (état, mode de démarrage)
- Génère des rapports CSV
- Journalisation des opérations
```

#### ServiceStatusReport.psm1

```powershell
# ServiceStatusReport.psm1

# Configuration globale du module
$script:ModuleConfig = @{
    DefaultOutputPath = "$env:USERPROFILE\Documents\ServiceReports"
    LogFile = "$env:TEMP\ServiceStatusReport.log"
}

# Charger les fonctions privées
$privateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\src\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
    }
    catch {
        Write-Error "Échec du chargement de la fonction privée $($function.FullName): $_"
    }
}

# Charger et exporter les fonctions publiques
$publicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\src\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($function in $publicFunctions) {
    try {
        . $function.FullName
        Export-ModuleMember -Function $function.BaseName
    }
    catch {
        Write-Error "Échec du chargement de la fonction publique $($function.FullName): $_"
    }
}

# Exporter les variables si nécessaire
# Export-ModuleMember -Variable ModuleConfig
```

#### ServiceStatusReport.psd1

```powershell
@{
    RootModule = 'ServiceStatusReport.psm1'
    ModuleVersion = '0.1.0'
    GUID = '12345678-1234-1234-1234-123456789012'  # Utiliser New-Guid pour en générer un
    Author = 'Votre Nom'
    CompanyName = 'Votre Entreprise'
    Copyright = '(c) 2025 Votre Nom. Tous droits réservés.'
    Description = 'Module pour générer des rapports sur l\'état des services Windows'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Get-ServiceStatusReport', 'Export-ServiceStatusReport')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Services', 'Reporting', 'Windows')
            LicenseUri = 'https://github.com/username/ServiceStatusReport/blob/main/LICENSE'
            ProjectUri = 'https://github.com/username/ServiceStatusReport'
            ReleaseNotes = 'Version initiale du module.'
        }
    }
}
```

### 3. Fonctions publiques

#### src/Public/Get-ServiceStatusReport.ps1

```powershell
function Get-ServiceStatusReport {
    <#
    .SYNOPSIS
        Génère un rapport sur l'état des services Windows spécifiés.

    .DESCRIPTION
        Cette fonction récupère des informations détaillées sur l'état des services Windows
        spécifiés et renvoie les résultats sous forme d'objets PowerShell.

    .PARAMETER ServiceList
        Liste des noms de services à vérifier.

    .EXAMPLE
        Get-ServiceStatusReport -ServiceList @("wuauserv", "spooler", "W32Time")

        Génère un rapport pour les services Windows Update, Spooler et Service de temps Windows.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ServiceList
    )

    Write-ServiceLog -Message "Début de la génération du rapport de services"

    $results = @()

    foreach ($service in $ServiceList) {
        $status = Get-DetailedServiceStatus -ServiceName $service
        if ($status) {
            $results += $status
            Write-ServiceLog -Message "Statut vérifié pour $service : $($status.Status)"
        }
    }

    Write-ServiceLog -Message "Fin de la génération du rapport de services"

    return $results
}
```

#### src/Public/Export-ServiceStatusReport.ps1

```powershell
function Export-ServiceStatusReport {
    <#
    .SYNOPSIS
        Exporte un rapport de services vers un fichier CSV.

    .DESCRIPTION
        Cette fonction exporte les données de rapport de services générées par
        Get-ServiceStatusReport vers un fichier CSV.

    .PARAMETER ServiceReport
        Les données du rapport de services à exporter.

    .PARAMETER Path
        Chemin vers le dossier où le rapport sera enregistré.
        Par défaut, utilise le dossier configuré dans le module.

    .PARAMETER Delimiter
        Délimiteur à utiliser pour le fichier CSV. Par défaut, c'est le point-virgule (;).

    .EXAMPLE
        $report = Get-ServiceStatusReport -ServiceList @("wuauserv", "spooler")
        $report | Export-ServiceStatusReport -Path "C:\Rapports"

        Exporte le rapport des services spécifiés vers un fichier CSV.

    .OUTPUTS
        System.String
        Le chemin du fichier généré.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$ServiceReport,

        [Parameter()]
        [string]$Path = $script:ModuleConfig.DefaultOutputPath,

        [Parameter()]
        [string]$Delimiter = ";"
    )

    begin {
        # Vérifier si le dossier de sortie existe, sinon le créer
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
            Write-ServiceLog -Message "Dossier de sortie créé : $Path"
        }

        $reportDate = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $reportFile = Join-Path -Path $Path -ChildPath "Rapport_Services_$reportDate.csv"

        $allResults = @()
    }

    process {
        $allResults += $ServiceReport
    }

    end {
        $allResults | Export-Csv -Path $reportFile -NoTypeInformation -Delimiter $Delimiter
        Write-ServiceLog -Message "Rapport exporté : $reportFile"

        return $reportFile
    }
}
```

### 4. Fonctions privées

#### src/Private/Get-DetailedServiceStatus.ps1

```powershell
function Get-DetailedServiceStatus {
    <#
    .SYNOPSIS
        Récupère des informations détaillées sur un service Windows.

    .DESCRIPTION
        Fonction privée utilisée pour obtenir des informations détaillées sur un service Windows.
        Inclut le nom, le nom d'affichage, l'état et le type de démarrage.

    .PARAMETER ServiceName
        Nom du service à vérifier.

    .OUTPUTS
        System.Management.Automation.PSObject ou $null si le service n'est pas trouvé.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

    if ($service) {
        # Utiliser CIM au lieu de WMI pour une meilleure compatibilité et performance
        $cimService = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue

        $startType = if ($cimService) { $cimService.StartMode } else { "Inconnu" }

        return [PSCustomObject]@{
            Name = $service.Name
            DisplayName = $service.DisplayName
            Status = $service.Status
            StartType = $startType
            Description = $service.Description
            DependentServices = ($service.DependentServices | Select-Object -ExpandProperty Name) -join ','
            CheckTime = Get-Date
        }
    } else {
        Write-ServiceLog -Message "Service $ServiceName introuvable" -Level "Warning"
        return $null
    }
}
```

#### src/Private/Write-ServiceLog.ps1

```powershell
function Write-ServiceLog {
    <#
    .SYNOPSIS
        Écrit un message dans le fichier journal du module.

    .DESCRIPTION
        Fonction privée pour journaliser les activités du module.

    .PARAMETER Message
        Message à journaliser.

    .PARAMETER Level
        Niveau de journalisation (Information, Warning, Error).
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("Information", "Warning", "Error")]
        [string]$Level = "Information"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - [$Level] - $Message"

    # Vérifier si le dossier du fichier journal existe
    $logFolder = Split-Path -Path $script:ModuleConfig.LogFile -Parent
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }

    # Écrire dans le journal
    $LogMessage | Out-File -FilePath $script:ModuleConfig.LogFile -Append -Encoding UTF8

    # Afficher dans la console selon le niveau si Verbose est activé
    switch ($Level) {
        "Information" { Write-Verbose $Message }
        "Warning" { Write-Warning $Message }
        "Error" { Write-Error $Message }
    }
}
```

### 5. Exemple d'utilisation

#### examples/Generate-DailyReport.ps1

```powershell
<#
.SYNOPSIS
    Script d'exemple pour générer un rapport quotidien des services critiques.
.DESCRIPTION
    Ce script montre comment utiliser le module ServiceStatusReport pour générer
    un rapport quotidien des services critiques du système.
#>

# Importer le module (assurez-vous qu'il est déjà installé ou dans le chemin)
Import-Module ServiceStatusReport -Force

# Liste des services critiques à surveiller
$criticalServices = @(
    "wuauserv",      # Windows Update
    "spooler",       # Service d'impression
    "W32Time",       # Service de temps Windows
    "LanmanServer",  # Serveur
    "BITS",          # Service de transfert intelligent en arrière-plan
    "wininit",       # Windows Start-Up Application
    "WinDefend"      # Windows Defender
)

# Générer le rapport
$report = Get-ServiceStatusReport -ServiceList $criticalServices -Verbose

# Exporter vers le dossier par défaut avec la date du jour
$reportPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\ServiceReports\Quotidien"
$reportFile = $report | Export-ServiceStatusReport -Path $reportPath

# Afficher un résumé
Write-Host "Rapport des services généré : $reportFile" -ForegroundColor Green
Write-Host "Résumé des statuts :"
$report | Group-Object -Property Status | ForEach-Object {
    $color = switch ($_.Name) {
        "Running" { "Green" }
        "Stopped" { "Red" }
        default { "Yellow" }
    }
    Write-Host "  $($_.Name): $($_.Count) service(s)" -ForegroundColor $color
}

# Recherche des services arrêtés qui devraient être en cours d'exécution
$stoppedCritical = $report | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Auto" }
if ($stoppedCritical) {
    Write-Host "ATTENTION : Les services suivants sont arrêtés mais configurés pour démarrer automatiquement :" -ForegroundColor Red
    $stoppedCritical | ForEach-Object {
        Write-Host "  - $($_.DisplayName) ($($_.Name))" -ForegroundColor Red
    }
}
```

### 6. Test unitaire simple

#### tests/ServiceStatusReport.Tests.ps1

```powershell
# Importer Pester si installé
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne peuvent pas être exécutés."
    return
}

# Chemin vers le module (ajustez selon votre configuration)
$modulePath = Split-Path -Parent $PSScriptRoot
$moduleName = "ServiceStatusReport"

Describe "$moduleName Tests" {
    BeforeAll {
        # Importer le module
        Import-Module "$modulePath\$moduleName.psd1" -Force
    }

    Context "Fonction Get-ServiceStatusReport" {
        It "Devrait renvoyer des résultats pour des services valides" {
            # Prendre un service qui devrait exister sur tous les systèmes Windows
            $result = Get-ServiceStatusReport -ServiceList @("W32Time")
            $result | Should -Not -BeNullOrEmpty
            $result.Name | Should -Be "W32Time"
        }

        It "Devrait gérer correctement un service inexistant" {
            # Utiliser un nom de service qui n'existe probablement pas
            $result = Get-ServiceStatusReport -ServiceList @("NonExistentServiceXYZ")
            $result | Should -BeNullOrEmpty
        }
    }

    Context "Fonction Export-ServiceStatusReport" {
        It "Devrait créer un fichier CSV" {
            # Créer un rapport test
            $tempReport = @(
                [PSCustomObject]@{
                    Name = "TestService"
                    DisplayName = "Service de test"
                    Status = "Running"
                    StartType = "Auto"
                    CheckTime = Get-Date
                }
            )

            # Utiliser le dossier temp pour le test
            $testPath = Join-Path -Path $env:TEMP -ChildPath "PesterTest"

            # Exporter et vérifier
            $reportFile = $tempReport | Export-ServiceStatusReport -Path $testPath
            $reportFile | Should -Exist

            # Nettoyer
            if (Test-Path -Path $reportFile) {
                Remove-Item -Path $reportFile -Force
            }
            if (Test-Path -Path $testPath) {
                Remove-Item -Path $testPath -Force -Recurse
            }
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module $moduleName -ErrorAction SilentlyContinue
    }
}
```

## Explication de la transformation

1. **Organisation structurée** : Le script original a été transformé en un module PowerShell avec une structure claire séparant les fonctions publiques et privées.

2. **Identification des fonctions** :
   - **Fonctions publiques** : `Get-ServiceStatusReport` et `Export-ServiceStatusReport` sont destinées à être utilisées par les utilisateurs du module.
   - **Fonctions privées** : `Get-DetailedServiceStatus` et `Write-ServiceLog` sont des utilitaires internes non exposées.

3. **Améliorations apportées** :
   - Meilleure gestion des erreurs
   - Documentation complète avec commentaires d'aide
   - Utilisation de CIM au lieu de WMI pour une meilleure performance
   - Support du pipeline pour `Export-ServiceStatusReport`
   - Configuration centralisée dans le module
   - Exemples d'utilisation clairs
   - Tests unitaires avec Pester

4. **Avantages de cette organisation** :
   - Réutilisation facile des fonctionnalités
   - Maintenance simplifiée (chaque fonction dans son propre fichier)
   - Extensibilité (ajout facile de nouvelles fonctionnalités)
   - Testabilité (tests unitaires par fonction)
   - Partage simplifié (module complet au lieu d'un script)

## Solution Complète Exercice 2 - Module de monitoring réseau"

Commençons par définir la structure de notre module de monitoring réseau :
# Structure du Module NetworkMonitor

```
NetworkMonitor/
│
├── src/
│   ├── Public/             # Fonctions exportées
│   │   ├── Test-NetworkConnection.ps1
│   │   ├── Get-NetworkStatistics.ps1
│   │   ├── Start-NetworkMonitoring.ps1
│   │   └── Export-MonitoringReport.ps1
│   │
│   └── Private/            # Fonctions internes
│       ├── Write-NetworkLog.ps1
│       └── Format-MonitoringOutput.ps1
│
├── tests/                  # Tests unitaires
│   └── NetworkMonitor.Tests.ps1
│
├── docs/
│   └── README.md           # Documentation du module
│
├── examples/
│   └── BasicMonitoring.ps1 # Exemple d'utilisation
│
├── NetworkMonitor.psd1     # Manifeste du module
├── NetworkMonitor.psm1     # Module principal
└── README.md               # Description du projet
```

Cette structure suit les bonnes pratiques présentées dans le module 15-1 du cours PowerShell.

Maintenant, créons le fichier principal du module NetworkMonitor.psm1 :

# NetworkMonitor.psm1

```powershell
#Requires -Version 5.1

# Variables globales du module
$script:LogPath = "$env:TEMP\NetworkMonitor\Logs"
$script:ResultsPath = "$env:TEMP\NetworkMonitor\Results"

# Création des dossiers de logs et résultats s'ils n'existent pas
if (-not (Test-Path -Path $script:LogPath)) {
    New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $script:ResultsPath)) {
    New-Item -Path $script:ResultsPath -ItemType Directory -Force | Out-Null
}

# Charger les fonctions privées
$privateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\src\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
        Write-Verbose "Fonction privée chargée : $($function.BaseName)"
    }
    catch {
        Write-Error "Échec du chargement de la fonction privée $($function.FullName): $_"
    }
}

# Charger les fonctions publiques et les exporter
$publicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\src\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($function in $publicFunctions) {
    try {
        . $function.FullName
        Export-ModuleMember -Function $function.BaseName
        Write-Verbose "Fonction publique chargée et exportée : $($function.BaseName)"
    }
    catch {
        Write-Error "Échec du chargement de la fonction publique $($function.FullName): $_"
    }
}

# Exporter les variables que l'on souhaite rendre disponibles aux utilisateurs
Export-ModuleMember -Variable 'LogPath', 'ResultsPath'

# Message lors du chargement du module
Write-Host "Module NetworkMonitor chargé. Utilisez Get-Command -Module NetworkMonitor pour voir les commandes disponibles." -ForegroundColor Green
```

Maintenant, créons le manifeste du module NetworkMonitor.psd1 :

# NetworkMonitor.psd1

```powershell
@{
    # Version du module. Utilisez le format sémantique de gestion de versions en tant que chaîne
    # de caractères. Rappelez-vous que la version doit être conforme aux règles de Windows PowerShell.
    ModuleVersion = '1.0.0'

    # ID utilisé pour identifier de manière unique ce module
    GUID = '8d7e5fab-4c5c-45a2-9c5a-b9e3e39f3c4d'

    # Auteur de ce module
    Author = 'Votre Nom'

    # Société ou fournisseur de ce module
    CompanyName = 'Votre Entreprise'

    # Déclaration de copyright pour ce module
    Copyright = '(c) 2025 Votre Nom. Tous droits réservés.'

    # Description de la fonctionnalité fournie par ce module
    Description = 'Module de surveillance réseau permettant de tester les connexions, collecter des statistiques et générer des rapports'

    # Version minimale du moteur Windows PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Modules qui doivent être importés dans l'environnement global préalablement à l'importation de ce module
    RequiredModules = @()

    # Assemblys qui doivent être chargés préalablement à l'importation de ce module
    RequiredAssemblies = @()

    # Fichiers de script (.ps1) exécutés dans l'environnement de l'appelant avant l'importation de ce module
    ScriptsToProcess = @()

    # Fichiers de types (.ps1xml) à charger lors de l'importation de ce module
    TypesToProcess = @()

    # Fichiers de format (.ps1xml) à charger lors de l'importation de ce module
    FormatsToProcess = @()

    # Modules à importer en tant que modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    NestedModules = @()

    # Fonctions à exporter à partir de ce module
    FunctionsToExport = @(
        'Test-NetworkConnection',
        'Get-NetworkStatistics',
        'Start-NetworkMonitoring',
        'Export-MonitoringReport'
    )

    # Applets de commande à exporter à partir de ce module
    CmdletsToExport = @()

    # Variables à exporter à partir de ce module
    VariablesToExport = @('LogPath', 'ResultsPath')

    # Aliases à exporter à partir de ce module
    AliasesToExport = @()

    # Informations privées à transmettre au module spécifié dans RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module. Ils facilitent la découverte de ce module via les modules en ligne
            Tags = @('Network', 'Monitoring', 'Diagnostic')

            # URL vers la page d'accueil de ce projet
            ProjectUri = 'https://github.com/YourName/NetworkMonitor'

            # URL vers une icône représentant ce module
            # IconUri = ''

            # Notes de publication pour ce module
            ReleaseNotes = 'Version initiale du module NetworkMonitor'
        }
    }

    # Module Racine/Traitement du module à son chargement
    RootModule = 'NetworkMonitor.psm1'

    # HelpInfo URI de ce module
    # HelpInfoURI = ''

    # Le préfixe par défaut des commandes exportées à partir de ce module. Remplacez le préfixe par défaut au besoin.
    # DefaultCommandPrefix = ''
}
```

Maintenant, créons les fonctions publiques du module :

# Test-NetworkConnection.ps1

```powershell
function Test-NetworkConnection {
    <#
    .SYNOPSIS
        Teste la connectivité réseau vers une ou plusieurs cibles.

    .DESCRIPTION
        Cette fonction permet de tester la connectivité réseau vers une ou plusieurs cibles
        spécifiées. Elle effectue différents types de tests (ping, port, traceroute) et
        retourne des informations détaillées sur les résultats.

    .PARAMETER Target
        Une ou plusieurs cibles à tester (noms d'hôtes ou adresses IP).

    .PARAMETER TestType
        Type de test à effectuer. Valeurs possibles : Ping, Port, Traceroute.
        Par défaut : Ping

    .PARAMETER Port
        Port à tester lorsque TestType est défini sur Port.

    .PARAMETER Timeout
        Délai d'attente en millisecondes avant d'abandonner le test.
        Par défaut : 2000 (2 secondes)

    .PARAMETER Count
        Nombre de tentatives à effectuer pour chaque test.
        Par défaut : 4

    .PARAMETER LogResults
        Enregistre les résultats dans un fichier journal.

    .EXAMPLE
        Test-NetworkConnection -Target 'google.com', 'bing.com'

        Teste la connectivité par ping vers google.com et bing.com

    .EXAMPLE
        Test-NetworkConnection -Target '192.168.1.1' -TestType Port -Port 80

        Teste la connectivité au port 80 de l'adresse IP 192.168.1.1

    .EXAMPLE
        Test-NetworkConnection -Target 'github.com' -TestType Traceroute

        Effectue un traceroute vers github.com

    .NOTES
        Auteur: Votre Nom
        Date de création: 27/04/2025
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]$Target,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Ping', 'Port', 'Traceroute')]
        [string]$TestType = 'Ping',

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$Port = 80,

        [Parameter(Mandatory = $false)]
        [ValidateRange(100, 60000)]
        [int]$Timeout = 2000,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$Count = 4,

        [Parameter(Mandatory = $false)]
        [switch]$LogResults
    )

    begin {
        Write-Verbose "Démarrage des tests de connectivité réseau ($TestType)"
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $results = @()
    }

    process {
        foreach ($currentTarget in $Target) {
            Write-Verbose "Test de $TestType vers $currentTarget"

            switch ($TestType) {
                'Ping' {
                    try {
                        $pingResults = @()
                        for ($i = 1; $i -le $Count; $i++) {
                            Write-Verbose "Ping $i/$Count vers $currentTarget"
                            $ping = Test-Connection -ComputerName $currentTarget -Count 1 -Quiet:$false -TimeoutSeconds ($Timeout / 1000) -ErrorAction Stop
                            $pingResults += $ping
                        }

                        # Calculer les statistiques
                        $successfulPings = $pingResults | Where-Object { $_ -ne $null -and $_.Status -eq 'Success' }
                        $packetLoss = 100 - (($successfulPings.Count / $Count) * 100)

                        if ($successfulPings.Count -gt 0) {
                            $avgResponseTime = ($successfulPings | Measure-Object -Property ResponseTime -Average).Average
                            $minResponseTime = ($successfulPings | Measure-Object -Property ResponseTime -Minimum).Minimum
                            $maxResponseTime = ($successfulPings | Measure-Object -Property ResponseTime -Maximum).Maximum
                        }
                        else {
                            $avgResponseTime = $minResponseTime = $maxResponseTime = 0
                        }

                        $result = [PSCustomObject]@{
                            Target = $currentTarget
                            TestType = 'Ping'
                            Timestamp = Get-Date
                            Status = if ($successfulPings.Count -gt 0) { 'Success' } else { 'Failed' }
                            SuccessRate = 100 - $packetLoss
                            PacketLoss = $packetLoss
                            AverageResponseTime = $avgResponseTime
                            MinimumResponseTime = $minResponseTime
                            MaximumResponseTime = $maxResponseTime
                            Details = $pingResults
                        }
                    }
                    catch {
                        $result = [PSCustomObject]@{
                            Target = $currentTarget
                            TestType = 'Ping'
                            Timestamp = Get-Date
                            Status = 'Error'
                            SuccessRate = 0
                            PacketLoss = 100
                            AverageResponseTime = 0
                            MinimumResponseTime = 0
                            MaximumResponseTime = 0
                            Details = $_.Exception.Message
                        }
                        Write-Warning "Erreur lors du ping vers $currentTarget : $($_.Exception.Message)"
                    }
                }

                'Port' {
                    try {
                        $portResults = @()
                        for ($i = 1; $i -le $Count; $i++) {
                            Write-Verbose "Test du port $Port ($i/$Count) vers $currentTarget"
                            $tcpClient = New-Object System.Net.Sockets.TcpClient
                            $connectionTask = $tcpClient.ConnectAsync($currentTarget, $Port)

                            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                            $connectionTask.Wait($Timeout)
                            $stopwatch.Stop()

                            $portResult = [PSCustomObject]@{
                                Attempt = $i
                                Connected = $tcpClient.Connected
                                ResponseTime = if ($tcpClient.Connected) { $stopwatch.ElapsedMilliseconds } else { $null }
                            }

                            $portResults += $portResult
                            $tcpClient.Close()
                        }

                        # Calculer les statistiques
                        $successfulConnections = $portResults | Where-Object { $_.Connected -eq $true }
                        $connectionRate = ($successfulConnections.Count / $Count) * 100

                        if ($successfulConnections.Count -gt 0) {
                            $avgResponseTime = ($successfulConnections | Measure-Object -Property ResponseTime -Average).Average
                            $minResponseTime = ($successfulConnections | Measure-Object -Property ResponseTime -Minimum).Minimum
                            $maxResponseTime = ($successfulConnections | Measure-Object -Property ResponseTime -Maximum).Maximum
                        }
                        else {
                            $avgResponseTime = $minResponseTime = $maxResponseTime = 0
                        }

                        $result = [PSCustomObject]@{
                            Target = $currentTarget
                            TestType = 'Port'
                            Port = $Port
                            Timestamp = Get-Date
                            Status = if ($successfulConnections.Count -gt 0) { 'Success' } else { 'Failed' }
                            SuccessRate = $connectionRate
                            AverageResponseTime = $avgResponseTime
                            MinimumResponseTime = $minResponseTime
                            MaximumResponseTime = $maxResponseTime
                            Details = $portResults
                        }
                    }
                    catch {
                        $result = [PSCustomObject]@{
                            Target = $currentTarget
                            TestType = 'Port'
                            Port = $Port
                            Timestamp = Get-Date
                            Status = 'Error'
                            SuccessRate = 0
                            AverageResponseTime = 0
                            MinimumResponseTime = 0
                            MaximumResponseTime = 0
                            Details = $_.Exception.Message
                        }
                        Write-Warning "Erreur lors du test du port $Port vers $currentTarget : $($_.Exception.Message)"
                    }
                }

                'Traceroute' {
                    try {
                        $tracertResults = @()
                        $maxHops = 30

                        for ($hop = 1; $hop -le $maxHops; $hop++) {
                            Write-Verbose "Traceroute hop $hop vers $currentTarget"

                            # Utiliser Test-NetConnection avec les paramètres de trace route
                            $traceResult = Test-Connection -ComputerName $currentTarget -Count 1 -MaxHops $hop -ErrorAction SilentlyContinue

                            if ($traceResult.Status -eq 'Success') {
                                $hopResult = [PSCustomObject]@{
                                    HopNumber = $hop
                                    IPAddress = $traceResult.Address.IPAddressToString
                                    Hostname = try { [System.Net.Dns]::GetHostEntry($traceResult.Address).HostName } catch { $null }
                                    ResponseTime = $traceResult.ResponseTime
                                    Status = 'Success'
                                }
                                $tracertResults += $hopResult

                                # Si on a atteint la destination, on arrête
                                if ($traceResult.Address.IPAddressToString -eq $currentTarget -or
                                    (Test-Connection -ComputerName $currentTarget -Count 1 -Quiet)) {
                                    break
                                }
                            }
                            else {
                                $hopResult = [PSCustomObject]@{
                                    HopNumber = $hop
                                    IPAddress = $null
                                    Hostname = $null
                                    ResponseTime = $null
                                    Status = 'Timeout'
                                }
                                $tracertResults += $hopResult
                            }
                        }

                        $result = [PSCustomObject]@{
                            Target = $currentTarget
                            TestType = 'Traceroute'
                            Timestamp = Get-Date
                            Status = if ($tracertResults[-1].Status -eq 'Success') { 'Success' } else { 'Failed' }
                            HopCount = $tracertResults.Count
                            TotalTime = ($tracertResults | Where-Object { $_.ResponseTime -ne $null } | Measure-Object -Property ResponseTime -Sum).Sum
                            Details = $tracertResults
                        }
                    }
                    catch {
                        $result = [PSCustomObject]@{
                            Target = $currentTarget
                            TestType = 'Traceroute'
                            Timestamp = Get-Date
                            Status = 'Error'
                            HopCount = 0
                            TotalTime = 0
                            Details = $_.Exception.Message
                        }
                        Write-Warning "Erreur lors du traceroute vers $currentTarget : $($_.Exception.Message)"
                    }
                }
            }

            # Journaliser les résultats si demandé
            if ($LogResults) {
                # Utiliser la fonction privée pour la journalisation
                Write-NetworkLog -Result $result
            }

            # Ajouter le résultat à la collection
            $results += $result
        }
    }

    end {
        # Formater la sortie pour l'affichage
        $formattedResults = Format-MonitoringOutput -Results $results -ShowDetails:$false
        return $formattedResults
    }
}
```

# Get-NetworkStatistics.ps1

```powershell
function Get-NetworkStatistics {
    <#
    .SYNOPSIS
        Collecte des statistiques réseau sur un système.

    .DESCRIPTION
        Cette fonction collecte des statistiques réseau détaillées sur le système local
        ou un système distant, y compris les connexions TCP/IP actives, l'utilisation
        de la bande passante, et les statistiques d'interface.

    .PARAMETER ComputerName
        Nom de l'ordinateur sur lequel collecter les statistiques.
        Par défaut : l'ordinateur local

    .PARAMETER InterfaceIndex
        Index de l'interface réseau à surveiller. Si non spécifié, toutes les interfaces
        actives sont analysées.

    .PARAMETER Protocol
        Protocole à analyser. Valeurs possibles : TCP, UDP, Both.
        Par défaut : Both

    .PARAMETER State
        État de connexion à filtrer (pour TCP). Par exemple : Established, Listening.
        Par défaut : tous les états

    .PARAMETER LogResults
        Enregistre les résultats dans un fichier journal.

    .EXAMPLE
        Get-NetworkStatistics

        Collecte toutes les statistiques réseau sur l'ordinateur local.

    .EXAMPLE
        Get-NetworkStatistics -Protocol TCP -State Established

        Collecte uniquement les connexions TCP établies sur l'ordinateur local.

    .EXAMPLE
        Get-NetworkStatistics -InterfaceIndex 12 -LogResults

        Collecte les statistiques pour l'interface avec l'index 12 et enregistre les résultats.

    .NOTES
        Auteur: Votre Nom
        Date de création: 27/04/2025
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [int]$InterfaceIndex,

        [Parameter(Mandatory = $false)]
        [ValidateSet('TCP', 'UDP', 'Both')]
        [string]$Protocol = 'Both',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Closed', 'CloseWait', 'Closing', 'DeleteTCB', 'Established',
                     'FinWait1', 'FinWait2', 'LastAck', 'Listen', 'SynReceived',
                     'SynSent', 'TimeWait')]
        [string]$State,

        [Parameter(Mandatory = $false)]
        [switch]$LogResults
    )

    begin {
        Write-Verbose "Démarrage de la collecte des statistiques réseau sur $ComputerName"
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

        # Vérifier si on peut se connecter à l'ordinateur distant
        if ($ComputerName -ne $env:COMPUTERNAME) {
            if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet)) {
                Write-Error "Impossible de se connecter à l'ordinateur distant : $ComputerName"
                return
            }
        }
    }

    process {
        try {
            # Statistiques d'interfaces réseau
            Write-Verbose "Collecte des statistiques d'interfaces réseau"
            if ($InterfaceIndex) {
                $netAdapters = Get-NetAdapter -InterfaceIndex $InterfaceIndex -ErrorAction Stop
            }
            else {
                $netAdapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
            }

            $interfaceStats = foreach ($adapter in $netAdapters) {
                $stats = $adapter | Get-NetAdapterStatistics

                [PSCustomObject]@{
                    InterfaceIndex = $adapter.InterfaceIndex
                    Name = $adapter.Name
                    Description = $adapter.InterfaceDescription
                    Status = $adapter.Status
                    LinkSpeed = $adapter.LinkSpeed
                    BytesReceived = $stats.ReceivedBytes
                    BytesSent = $stats.SentBytes
                    PacketsReceived = $stats.ReceivedUnicastPackets + $stats.ReceivedMulticastPackets + $stats.ReceivedBroadcastPackets
                    PacketsSent = $stats.SentUnicastPackets + $stats.SentMulticastPackets + $stats.SentBroadcastPackets
                    Timestamp = Get-Date
                }
            }

            # Connexions TCP
            $tcpConnections = @()
            if ($Protocol -eq 'TCP' -or $Protocol -eq 'Both') {
                Write-Verbose "Collecte des connexions TCP"
                $tcpParams = @{}
                if ($State) {
                    $tcpParams.Add('State', $State)
                }

                $tcpConnections = Get-NetTCPConnection @tcpParams | ForEach-Object {
                    # Récupérer le processus associé
                    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue

                    [PSCustomObject]@{
                        Protocol = 'TCP'
                        LocalAddress = $_.LocalAddress
                        LocalPort = $_.LocalPort
                        RemoteAddress = $_.RemoteAddress
                        RemotePort = $_.RemotePort
                        State = $_.State
                        ProcessId = $_.OwningProcess
                        ProcessName = $process.Name
                        CreationTime = $_.CreationTime
                    }
                }
            }

            # Connexions UDP
            $udpConnections = @()
            if ($Protocol -eq 'UDP' -or $Protocol -eq 'Both') {
                Write-Verbose "Collecte des connexions UDP"
                $udpConnections = Get-NetUDPEndpoint | ForEach-Object {
                    # Récupérer le processus associé
                    $process = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue

                    [PSCustomObject]@{
                        Protocol = 'UDP'
                        LocalAddress = $_.LocalAddress
                        LocalPort = $_.LocalPort
                        RemoteAddress = $null
                        RemotePort = $null
                        State = $null
                        ProcessId = $_.OwningProcess
                        ProcessName = $process.Name
                        CreationTime = $_.CreationTime
                    }
                }
            }

            # Statistiques IP
            Write-Verbose "Collecte des statistiques IP"
            $ipStats = Get-NetIPStatistics

            # Statistiques TCP/IP
            Write-Verbose "Collecte des statistiques TCP/IP"
            $tcpStats = Get-NetTCPStatistics
            $udpStats = Get-NetUDPStatistics

            # Assembler tous les résultats
            $networkStats = [PSCustomObject]@{
                ComputerName = $ComputerName
                Timestamp = Get-Date
                InterfaceStatistics = $interfaceStats
                TCPConnections = $tcpConnections
                UDPConnections = $udpConnections
                IPStatistics = $ipStats
                TCPStatistics = $tcpStats
                UDPStatistics = $udpStats
            }

            # Journaliser les résultats si demandé
            if ($LogResults) {
                Write-NetworkLog -Result $networkStats
            }

            # Formater la sortie pour l'affichage
            $formattedResults = Format-MonitoringOutput -Results $networkStats
            return $formattedResults
        }
        catch {
            Write-Error "Erreur lors de la collecte des statistiques réseau : $($_.Exception.Message)"
            return $null
        }
    }

    end {
        Write-Verbose "Collecte des statistiques réseau terminée"
    }
}
```
# Start-NetworkMonitoring.ps1

```powershell
function Start-NetworkMonitoring {
    <#
    .SYNOPSIS
        Démarre une session de surveillance réseau continue.

    .DESCRIPTION
        Cette fonction démarre une session de surveillance réseau continue qui effectue
        des tests de connectivité et collecte des statistiques à intervalles réguliers.
        Les résultats peuvent être affichés en temps réel et/ou enregistrés dans des fichiers.

    .PARAMETER Target
        Une ou plusieurs cibles à surveiller (noms d'hôtes ou adresses IP).

    .PARAMETER MonitoringType
        Type de surveillance à effectuer. Valeurs possibles : Connectivity, Statistics, Both.
        Par défaut : Both

    .PARAMETER Interval
        Intervalle entre chaque cycle de surveillance, en secondes.
        Par défaut : 60 secondes

    .PARAMETER Duration
        Durée totale de la surveillance, en minutes. Si non spécifié, la surveillance
        continue jusqu'à ce que l'utilisateur l'arrête manuellement (Ctrl+C).

    .PARAMETER Port
        Port à surveiller lorsque le test de connectivité est de type Port.
        Par défaut : 80

    .PARAMETER TestType
        Type de test de connectivité à effectuer. Valeurs possibles : Ping, Port, Traceroute.
        Par défaut : Ping

    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de la surveillance.
        Par défaut : $script:ResultsPath

    .PARAMETER NoConsoleOutput
        Si spécifié, les résultats ne sont pas affichés dans la console.

    .EXAMPLE
        Start-NetworkMonitoring -Target 'google.com', 'bing.com' -Interval 30 -Duration 60

        Surveille google.com et bing.com pendant 60 minutes, avec un intervalle de 30 secondes.

    .EXAMPLE
        Start-NetworkMonitoring -Target '192.168.1.1' -MonitoringType Connectivity -TestType Port -Port 443

        Surveille uniquement la connectivité au port 443 de l'adresse IP 192.168.1.1.

    .NOTES
        Auteur: Votre Nom
        Date de création: 27/04/2025
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$Target,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Connectivity', 'Statistics', 'Both')]
        [string]$MonitoringType = 'Both',

        [Parameter(Mandatory = $false)]
        [ValidateRange(5, 3600)]
        [int]$Interval = 60,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10080)]  # Max 1 semaine
        [int]$Duration,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$Port = 80,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Ping', 'Port', 'Traceroute')]
        [string]$TestType = 'Ping',

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = $script:ResultsPath,

        [Parameter(Mandatory = $false)]
        [switch]$NoConsoleOutput
    )

    begin {
        $startTime = Get-Date
        $endTime = if ($Duration) { $startTime.AddMinutes($Duration) } else { $null }
        $sessionId = [guid]::NewGuid().ToString()
        $sessionPath = Join-Path -Path $OutputPath -ChildPath $sessionId

        # Créer le dossier pour cette session de surveillance
        if (-not (Test-Path -Path $sessionPath)) {
            New-Item -Path $sessionPath -ItemType Directory -Force | Out-Null
        }

        # Créer le fichier de métadonnées de la session
        $sessionInfo = [PSCustomObject]@{
            SessionId = $sessionId
            StartTime = $startTime
            ScheduledEndTime = $endTime
            Target = $Target
            MonitoringType = $MonitoringType
            Interval = $Interval
            TestType = $TestType
            Port = if ($TestType -eq 'Port') { $Port } else { $null }
        }

        $sessionInfoPath = Join-Path -Path $sessionPath -ChildPath "SessionInfo.json"
        $sessionInfo | ConvertTo-Json | Out-File -FilePath $sessionInfoPath -Force

        Write-Host "Démarrage de la session de surveillance réseau (ID: $sessionId)" -ForegroundColor Green
        Write-Host "Cibles: $($Target -join ', ')" -ForegroundColor Yellow
        Write-Host "Type: $MonitoringType, Intervalle: $Interval secondes" -ForegroundColor Yellow
        if ($Duration) {
            Write-Host "Durée prévue: $Duration minutes (fin à $($endTime.ToString('HH:mm:ss')))" -ForegroundColor Yellow
        }
        else {
            Write-Host "Durée: indéfinie (jusqu'à interruption manuelle)" -ForegroundColor Yellow
        }
        Write-Host "Résultats sauvegardés dans: $sessionPath" -ForegroundColor Yellow
        Write-Host "Appuyez sur CTRL+C pour arrêter la surveillance..." -ForegroundColor Cyan
        Write-Host ("-" * 80)
    }

    process {
        try {
            # Variable pour suivre le nombre de cycles
            $cycleCount = 0

            # Boucle de surveillance
            do {
                $cycleStartTime = Get-Date
                $cycleCount++

                Write-Verbose "Démarrage du cycle $cycleCount à $($cycleStartTime.ToString('HH:mm:ss'))"

                # Créer un répertoire pour ce cycle
                $cyclePath = Join-Path -Path $sessionPath -ChildPath "Cycle_$cycleCount"
                if (-not (Test-Path -Path $cyclePath)) {
                    New-Item -Path $cyclePath -ItemType Directory -Force | Out-Null
                }

                # Collection des résultats pour ce cycle
                $cycleResults = [PSCustomObject]@{
                    CycleNumber = $cycleCount
                    Timestamp = $cycleStartTime
                    ConnectivityResults = $null
                    StatisticsResults = $null
                }

                # 1. Tests de connectivité si demandé
                if ($MonitoringType -eq 'Connectivity' -or $MonitoringType -eq 'Both') {
                    Write-Verbose "Exécution des tests de connectivité ($TestType)"

                    $connectivityParams = @{
                        Target = $Target
                        TestType = $TestType
                        LogResults = $true
                    }

                    if ($TestType -eq 'Port') {
                        $connectivityParams.Add('Port', $Port)
                    }

                    $connectivityResults = Test-NetworkConnection @connectivityParams
                    $cycleResults.ConnectivityResults = $connectivityResults

                    # Sauvegarder les résultats de connectivité dans un fichier
                    $connectivityPath = Join-Path -Path $cyclePath -ChildPath "Connectivity.json"
                    $connectivityResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $connectivityPath -Force

                    # Afficher les résultats dans la console si demandé
                    if (-not $NoConsoleOutput) {
                        Write-Host "Cycle $cycleCount - Tests de connectivité ($TestType) - $($cycleStartTime.ToString('HH:mm:ss'))" -ForegroundColor Green
                        $connectivityResults | Format-Table -AutoSize
                    }
                }

                # 2. Collecte des statistiques si demandée
                if ($MonitoringType -eq 'Statistics' -or $MonitoringType -eq 'Both') {
                    Write-Verbose "Collecte des statistiques réseau"

                    $statisticsParams = @{
                        LogResults = $true
                    }

                    $statisticsResults = Get-NetworkStatistics @statisticsParams
                    $cycleResults.StatisticsResults = $statisticsResults

                    # Sauvegarder les résultats des statistiques dans un fichier
                    $statisticsPath = Join-Path -Path $cyclePath -ChildPath "Statistics.json"
                    $statisticsResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $statisticsPath -Force

                    # Afficher les résultats dans la console si demandé
                    if (-not $NoConsoleOutput) {
                        Write-Host "Cycle $cycleCount - Statistiques réseau - $($cycleStartTime.ToString('HH:mm:ss'))" -ForegroundColor Green
                        $statisticsResults.InterfaceStatistics | Format-Table -AutoSize

                        Write-Host "Connexions TCP actives :" -ForegroundColor Yellow
                        $statisticsResults.TCPConnections |
                            Where-Object { $_.State -eq 'Established' } |
                            Sort-Object -Property ProcessName |
                            Format-Table -AutoSize
                    }
                }

                # Calculer le temps nécessaire pour ce cycle
                $cycleEndTime = Get-Date
                $cycleDuration = ($cycleEndTime - $cycleStartTime).TotalSeconds

                # Attendre jusqu'au prochain cycle (en tenant compte du temps d'exécution)
                $sleepTime = $Interval - $cycleDuration
                if ($sleepTime -gt 0) {
                    Write-Verbose "Attente de $sleepTime secondes avant le prochain cycle"
                    Start-Sleep -Seconds $sleepTime
                }

                # Vérifier si la durée spécifiée est écoulée
                $shouldContinue = if ($Duration) {
                    (Get-Date) -lt $endTime
                }
                else {
                    $true
                }

            } while ($shouldContinue)
        }
        catch {
            Write-Error "Erreur lors de la surveillance réseau : $($_.Exception.Message)"
        }
        finally {
            # Finaliser la session
            $sessionEndTime = Get-Date

            # Mettre à jour le fichier d'informations de session
            $sessionInfo | Add-Member -MemberType NoteProperty -Name ActualEndTime -Value $sessionEndTime
            $sessionInfo | Add-Member -MemberType NoteProperty -Name TotalCycles -Value $cycleCount
            $sessionInfo | ConvertTo-Json | Out-File -FilePath $sessionInfoPath -Force

            Write-Host ("-" * 80)
            Write-Host "Session de surveillance réseau terminée (ID: $sessionId)" -ForegroundColor Green
            Write-Host "Début: $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
            Write-Host "Fin: $($sessionEndTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
            Write-Host "Durée totale: $(($sessionEndTime - $startTime).ToString('hh\:mm\:ss'))" -ForegroundColor Yellow
            Write-Host "Nombre de cycles: $cycleCount" -ForegroundColor Yellow
            Write-Host "Résultats sauvegardés dans: $sessionPath" -ForegroundColor Yellow

            # Renvoyer l'objet de session pour permettre un traitement ultérieur
            return $sessionInfo
        }
    }
}
```

# Export-MonitoringReport.ps1

```powershell
function Export-MonitoringReport {
    <#
    .SYNOPSIS
        Génère et exporte un rapport de surveillance réseau.

    .DESCRIPTION
        Cette fonction analyse les données collectées lors d'une session de surveillance réseau
        et génère un rapport détaillé au format HTML, CSV ou JSON. Le rapport peut inclure
        des graphiques, des tableaux et des analyses des tendances.

    .PARAMETER SessionPath
        Chemin vers le dossier de la session de surveillance à analyser.

    .PARAMETER ReportType
        Type de rapport à générer. Valeurs possibles : HTML, CSV, JSON, All.
        Par défaut : HTML

    .PARAMETER IncludeRawData
        Si spécifié, inclut les données brutes dans le rapport.

    .PARAMETER DestinationPath
        Dossier où enregistrer le rapport généré.
        Par défaut : le dossier de la session

    .PARAMETER OpenReport
        Si spécifié, ouvre le rapport une fois généré.

    .EXAMPLE
        Export-MonitoringReport -SessionPath "C:\Temp\NetworkMonitor\Results\5a7e9c12-4b3f-4d8a-9f1d-bb65a7e7f123"

        Génère un rapport HTML pour la session spécifiée.

    .EXAMPLE
        Export-MonitoringReport -SessionPath "C:\Temp\NetworkMonitor\Results\5a7e9c12-4b3f-4d8a-9f1d-bb65a7e7f123" -ReportType All -IncludeRawData

        Génère des rapports dans tous les formats disponibles, en incluant les données brutes.

    .NOTES
        Auteur: Votre Nom
        Date de création: 27/04/2025
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SessionPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet('HTML', 'CSV', 'JSON', 'All')]
        [string]$ReportType = 'HTML',

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRawData,

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $false)]
        [switch]$OpenReport
    )

    begin {
        Write-Verbose "Démarrage de la génération du rapport pour la session: $SessionPath"

        # Vérifier que le dossier de session existe
        if (-not (Test-Path -Path $SessionPath -PathType Container)) {
            Write-Error "Le dossier de session spécifié n'existe pas: $SessionPath"
            return
        }

        # Définir le dossier de destination
        if (-not $DestinationPath) {
            $DestinationPath = Join-Path -Path $SessionPath -ChildPath "Reports"
        }

        # Créer le dossier de destination s'il n'existe pas
        if (-not (Test-Path -Path $DestinationPath)) {
            New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        }

        # Charger les informations de session
        $sessionInfoPath = Join-Path -Path $SessionPath -ChildPath "SessionInfo.json"
        if (-not (Test-Path -Path $sessionInfoPath)) {
            Write-Error "Impossible de trouver les informations de session: $sessionInfoPath"
            return
        }

        $sessionInfo = Get-Content -Path $sessionInfoPath -Raw | ConvertFrom-Json

        # Variables pour collecter les données
        $allConnectivityResults = @()
        $allStatisticsResults = @()
    }

    process {
        try {
            # 1. Charger toutes les données des cycles
            Write-Verbose "Chargement des données de tous les cycles..."

            $cycleFolders = Get-ChildItem -Path $SessionPath -Directory | Where-Object { $_.Name -like "Cycle_*" }

            foreach ($cycleFolder in $cycleFolders) {
                $cycleNumber = [int]($cycleFolder.Name -replace "Cycle_", "")

                # Charger les données de connectivité si elles existent
                $connectivityPath = Join-Path -Path $cycleFolder.FullName -ChildPath "Connectivity.json"
                if (Test-Path -Path $connectivityPath) {
                    $connectivityData = Get-Content -Path $connectivityPath -Raw | ConvertFrom-Json

                    # Ajouter le numéro de cycle
                    foreach ($item in $connectivityData) {
                        $item | Add-Member -MemberType NoteProperty -Name CycleNumber -Value $cycleNumber -Force
                    }

                    $allConnectivityResults += $connectivityData
                }

                # Charger les données de statistiques si elles existent
                $statisticsPath = Join-Path -Path $cycleFolder.FullName -ChildPath "Statistics.json"
                if (Test-Path -Path $statisticsPath) {
                    $statisticsData = Get-Content -Path $statisticsPath -Raw | ConvertFrom-Json

                    # Ajouter le numéro de cycle
                    $statisticsData | Add-Member -MemberType NoteProperty -Name CycleNumber -Value $cycleNumber -Force

                    $allStatisticsResults += $statisticsData
                }
            }

            # 2. Analyser les données
            Write-Verbose "Analyse des données collectées..."

            # Analyse de connectivité
            $connectivityAnalysis = @{}
            if ($allConnectivityResults.Count -gt 0) {
                $connectivityAnalysis = @{
                    TotalTests = $allConnectivityResults.Count
                    SuccessfulTests = ($allConnectivityResults | Where-Object { $_.Status -eq 'Success' }).Count
                    FailedTests = ($allConnectivityResults | Where-Object { $_.Status -eq 'Failed' }).Count
                    ErrorTests = ($allConnectivityResults | Where-Object { $_.Status -eq 'Error' }).Count
                    SuccessRate = if ($allConnectivityResults.Count -gt 0) {
                        [math]::Round((($allConnectivityResults | Where-Object { $_.Status -eq 'Success' }).Count / $allConnectivityResults.Count) * 100, 2)
                    } else { 0 }
                    AverageResponseTime = if (($allConnectivityResults | Where-Object { $_.AverageResponseTime -ne $null }).Count -gt 0) {
                        [math]::Round(($allConnectivityResults | Where-Object { $_.AverageResponseTime -ne $null } | Measure-Object -Property AverageResponseTime -Average).Average, 2)
                    } else { 0 }
                    MinResponseTime = if (($allConnectivityResults | Where-Object { $_.MinimumResponseTime -ne $null }).Count -gt 0) {
                        ($allConnectivityResults | Where-Object { $_.MinimumResponseTime -ne $null } | Measure-Object -Property MinimumResponseTime -Minimum).Minimum
                    } else { 0 }
                    MaxResponseTime = if (($allConnectivityResults | Where-Object { $_.MaximumResponseTime -ne $null }).Count -gt 0) {
                        ($allConnectivityResults | Where-Object { $_.MaximumResponseTime -ne $null } | Measure-Object -Property MaximumResponseTime -Maximum).Maximum
                    } else { 0 }
                    TargetResults = @{}
                }

                # Analyser les résultats par cible
                foreach ($target in $sessionInfo.Target) {
                    $targetResults = $allConnectivityResults | Where-Object { $_.Target -eq $target }

                    if ($targetResults.Count -gt 0) {
                        $connectivityAnalysis.TargetResults[$target] = @{
                            TotalTests = $targetResults.Count
                            SuccessfulTests = ($targetResults | Where-Object { $_.Status -eq 'Success' }).Count
                            FailedTests = ($targetResults | Where-Object { $_.Status -eq 'Failed' }).Count
                            ErrorTests = ($targetResults | Where-Object { $_.Status -eq 'Error' }).Count
                            SuccessRate = [math]::Round((($targetResults | Where-Object { $_.Status -eq 'Success' }).Count / $targetResults.Count) * 100, 2)
                            AverageResponseTime = if (($targetResults | Where-Object { $_.AverageResponseTime -ne $null }).Count -gt 0) {
                                [math]::Round(($targetResults | Where-Object { $_.AverageResponseTime -ne $null } | Measure-Object -Property AverageResponseTime -Average).Average, 2)
                            } else { 0 }
                            ResponseTimeTrend = $targetResults | Sort-Object -Property CycleNumber | Select-Object CycleNumber, AverageResponseTime
                        }
                    }
                }
            }

            # Analyse des statistiques réseau
            $statsAnalysis = @{}
            if ($allStatisticsResults.Count -gt 0) {
                # Extraire les données d'interface
                $interfaceData = $allStatisticsResults | ForEach-Object {
                    $cycle = $_.CycleNumber
                    $timestamp = $_.Timestamp

                    foreach ($interface in $_.InterfaceStatistics) {
                        [PSCustomObject]@{
                            CycleNumber = $cycle
                            Timestamp = $timestamp
                            InterfaceIndex = $interface.InterfaceIndex
                            Name = $interface.Name
                            BytesReceived = $interface.BytesReceived
                            BytesSent = $interface.BytesSent
                            PacketsReceived = $interface.PacketsReceived
                            PacketsSent = $interface.PacketsSent
                        }
                    }
                }

                # Grouper par interface
                $interfaceGroups = $interfaceData | Group-Object -Property InterfaceIndex

                $statsAnalysis = @{
                    Interfaces = @{}
                    TCPConnectionsAverage = ($allStatisticsResults | Measure-Object -Property { $_.TCPConnections.Count } -Average).Average
                    UDPConnectionsAverage = ($allStatisticsResults | Measure-Object -Property { $_.UDPConnections.Count } -Average).Average
                    ConnectionsByProcess = @{}
                }

                # Analyser chaque interface
                foreach ($group in $interfaceGroups) {
                    $interface = $group.Group[0]

                    # Calcul du trafic total et des tendances
                    $bytesReceivedStart = ($group.Group | Sort-Object -Property CycleNumber | Select-Object -First 1).BytesReceived
                    $bytesReceivedEnd = ($group.Group | Sort-Object -Property CycleNumber | Select-Object -Last 1).BytesReceived
                    $bytesSentStart = ($group.Group | Sort-Object -Property CycleNumber | Select-Object -First 1).BytesSent
                    $bytesSentEnd = ($group.Group | Sort-Object -Property CycleNumber | Select-Object -Last 1).BytesSent

                    $totalBytesReceived = $bytesReceivedEnd - $bytesReceivedStart
                    $totalBytesSent = $bytesSentEnd - $bytesSentStart

                    $statsAnalysis.Interfaces[$interface.InterfaceIndex] = @{
                        Name = $interface.Name
                        TotalBytesReceived = $totalBytesReceived
                        TotalBytesSent = $totalBytesSent
                        TotalMBReceived = [math]::Round($totalBytesReceived / 1MB, 2)
                        TotalMBSent = [math]::Round($totalBytesSent / 1MB, 2)
                        BytesReceivedTrend = $group.Group | Sort-Object -Property CycleNumber | Select-Object CycleNumber, BytesReceived
                        BytesSentTrend = $group.Group | Sort-Object -Property CycleNumber | Select-Object CycleNumber, BytesSent
                    }
                }

                # Analyser les connexions par processus
                $allConnections = $allStatisticsResults | ForEach-Object {
                    $_.TCPConnections + $_.UDPConnections
                }

                $processCounts = $allConnections | Group-Object -Property ProcessName | Select-Object Name, Count | Sort-Object -Property Count -Descending

                foreach ($process in $processCounts) {
                    if ($process.Name) {
                        $statsAnalysis.ConnectionsByProcess[$process.Name] = $process.Count
                    }
                }
            }

            # 3. Préparer un objet de rapport complet
            $reportData = [PSCustomObject]@{
                SessionInfo = $sessionInfo
                ConnectivityAnalysis = $connectivityAnalysis
                StatisticsAnalysis = $statsAnalysis
                RawData = if ($IncludeRawData) {
                    @{
                        ConnectivityResults = $allConnectivityResults
                        StatisticsResults = $allStatisticsResults
                    }
                } else { $null }
            }

            # 4. Générer les rapports selon le format demandé
            $generatedReports = @()

            # Rapport HTML
            if ($ReportType -eq 'HTML' -or $ReportType -eq 'All') {
                Write-Verbose "Génération du rapport HTML..."
                $htmlReportPath = Join-Path -Path $DestinationPath -ChildPath "NetworkMonitoringReport_$($sessionInfo.SessionId).html"

                # Générer le contenu HTML
                $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Surveillance Réseau</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        .section {
            margin-bottom: 30px;
            padding: 20px;
            background-color: #f9f9f9;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #0066cc;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .success {
            color: green;
        }
        .warning {
            color: orange;
        }
        .error {
            color: red;
        }
        .chart {
            width: 100%;
            height: 300px;
            margin-bottom: 20px;
        }
        .summary {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
        }
        .summary-box {
            flex-basis: 23%;
            padding: 15px;
            background-color: #e9f0f7;
            border-radius: 5px;
            margin-bottom: 15px;
            box-shadow: 0 2px 3px rgba(0,0,0,0.1);
        }
        .summary-box h4 {
            margin-top: 0;
            border-bottom: 1px solid #ccc;
            padding-bottom: 5px;
        }
        .summary-value {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0;
        }
        @media (max-width: 768px) {
            .summary-box {
                flex-basis: 48%;
            }
        }
        @media (max-width: 480px) {
            .summary-box {
                flex-basis: 100%;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de Surveillance Réseau</h1>

        <div class="section">
            <h2>Informations de Session</h2>
            <table>
                <tr>
                    <th>ID de Session</th>
                    <td>$($sessionInfo.SessionId)</td>
                </tr>
                <tr>
                    <th>Date de début</th>
                    <td>$($sessionInfo.StartTime)</td>
                </tr>
                <tr>
                    <th>Date de fin</th>
                    <td>$($sessionInfo.ActualEndTime)</td>
                </tr>
                <tr>
                    <th>Durée</th>
                    <td>$([TimeSpan]::FromTicks(([DateTime]$sessionInfo.ActualEndTime - [DateTime]$sessionInfo.StartTime).Ticks).ToString("hh\:mm\:ss"))</td>
                </tr>
                <tr>
                    <th>Cibles</th>
                    <td>$($sessionInfo.Target -join ', ')</td>
                </tr>
                <tr>
                    <th>Type de surveillance</th>
                    <td>$($sessionInfo.MonitoringType)</td>
                </tr>
                <tr>
                    <th>Intervalle</th>
                    <td>$($sessionInfo.Interval) secondes</td>
                </tr>
                <tr>
                    <th>Nombre de cycles</th>
                    <td>$($sessionInfo.TotalCycles)</td>
                </tr>
            </table>
        </div>
"@

                # Section de connectivité si présente
                if ($connectivityAnalysis.Count -gt 0) {
                    $htmlContent += @"
        <div class="section">
            <h2>Analyse de Connectivité</h2>

            <div class="summary">
                <div class="summary-box">
                    <h4>Taux de Succès</h4>
                    <div class="summary-value $( if ($connectivityAnalysis.SuccessRate -ge 90) { 'success' } elseif ($connectivityAnalysis.SuccessRate -ge 70) { 'warning' } else { 'error' } )">
                        $($connectivityAnalysis.SuccessRate)%
                    </div>
                </div>

                <div class="summary-box">
                    <h4>Tests Réussis</h4>
                    <div class="summary-value success">
                        $($connectivityAnalysis.SuccessfulTests) / $($connectivityAnalysis.TotalTests)
                    </div>
                </div>

                <div class="summary-box">
                    <h4>Temps de Réponse Moyen</h4>
                    <div class="summary-value">
                        $($connectivityAnalysis.AverageResponseTime) ms
                    </div>
                </div>

                <div class="summary-box">
                    <h4>Tests en Échec</h4>
                    <div class="summary-value $( if ($connectivityAnalysis.FailedTests -eq 0) { 'success' } elseif ($connectivityAnalysis.FailedTests -lt ($connectivityAnalysis.TotalTests * 0.3)) { 'warning' } else { 'error' } )">
                        $($connectivityAnalysis.FailedTests) / $($connectivityAnalysis.TotalTests)
                    </div>
                </div>
            </div>

            <h3>Résultats par Cible</h3>
            <table>
                <tr>
                    <th>Cible</th>
                    <th>Taux de Succès</th>
                    <th>Tests Réussis</th>
                    <th>Tests en Échec</th>
                    <th>Temps de Réponse Moyen</th>
                </tr>
"@

                    foreach ($target in $connectivityAnalysis.TargetResults.Keys) {
                        $targetData = $connectivityAnalysis.TargetResults[$target]
                        $htmlContent += @"
                <tr>
                    <td>$target</td>
                    <td class="$( if ($targetData.SuccessRate -ge 90) { 'success' } elseif ($targetData.SuccessRate -ge 70) { 'warning' } else { 'error' } )">
                        $($targetData.SuccessRate)%
                    </td>
                    <td>$($targetData.SuccessfulTests) / $($targetData.TotalTests)</td>
                    <td>$($targetData.FailedTests) / $($targetData.TotalTests)</td>
                    <td>$($targetData.AverageResponseTime) ms</td>
                </tr>
"@
                    }

                    $htmlContent += @"
            </table>
        </div>
"@
                }

                # Section des statistiques réseau si présente
                if ($statsAnalysis.Count -gt 0) {
                    $htmlContent += @"
        <div class="section">
            <h2>Analyse des Statistiques Réseau</h2>

            <h3>Trafic des Interfaces</h3>
            <table>
                <tr>
                    <th>Interface</th>
                    <th>Données Reçues (MB)</th>
                    <th>Données Envoyées (MB)</th>
                    <th>Total (MB)</th>
                </tr>
"@

                    foreach ($interfaceId in $statsAnalysis.Interfaces.Keys) {
                        $interfaceData = $statsAnalysis.Interfaces[$interfaceId]
                        $htmlContent += @"
                <tr>
                    <td>$($interfaceData.Name)</td>
                    <td>$($interfaceData.TotalMBReceived)</td>
                    <td>$($interfaceData.TotalMBSent)</td>
                    <td>$([math]::Round($interfaceData.TotalMBReceived + $interfaceData.TotalMBSent, 2))</td>
                </tr>
"@
                    }

                    $htmlContent += @"
            </table>

            <h3>Connexions par Processus</h3>
            <table>
                <tr>
                    <th>Processus</th>
                    <th>Nombre de Connexions</th>
                </tr>
"@

                    $topProcesses = $statsAnalysis.ConnectionsByProcess.GetEnumerator() |
                        Sort-Object -Property Value -Descending |
                        Select-Object -First 10

                    foreach ($process in $topProcesses) {
                        $htmlContent += @"
                <tr>
                    <td>$($process.Key)</td>
                    <td>$($process.Value)</td>
                </tr>
"@
                    }

                    $htmlContent += @"
            </table>

            <h3>Statistiques de Connexions</h3>
            <div class="summary">
                <div class="summary-box">
                    <h4>Connexions TCP (moyenne)</h4>
                    <div class="summary-value">
                        $([math]::Round($statsAnalysis.TCPConnectionsAverage, 0))
                    </div>
                </div>

                <div class="summary-box">
                    <h4>Connexions UDP (moyenne)</h4>
                    <div class="summary-value">
                        $([math]::Round($statsAnalysis.UDPConnectionsAverage, 0))
                    </div>
                </div>
            </div>
        </div>
"@
                }

                # Pied de page
                $htmlContent += @"
        <div class="section">
            <h2>Informations du Rapport</h2>
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd à HH:mm:ss") avec le module NetworkMonitor.</p>
        </div>
    </div>
</body>
</html>
"@

                # Enregistrer le rapport HTML
                $htmlContent | Out-File -FilePath $htmlReportPath -Force -Encoding UTF8
                $generatedReports += $htmlReportPath
                Write-Verbose "Rapport HTML généré : $htmlReportPath"
            }

            # Rapport CSV
            if ($ReportType -eq 'CSV' -or $ReportType -eq 'All') {
                Write-Verbose "Génération des rapports CSV..."

                # Créer un dossier pour les CSV
                $csvFolderPath = Join-Path -Path $DestinationPath -ChildPath "CSV_$($sessionInfo.SessionId)"
                if (-not (Test-Path -Path $csvFolderPath)) {
                    New-Item -Path $csvFolderPath -ItemType Directory -Force | Out-Null
                }

                # Exporter les résultats de connectivité
                if ($allConnectivityResults.Count -gt 0) {
                    $connectivityCsvPath = Join-Path -Path $csvFolderPath -ChildPath "ConnectivityResults.csv"
                    $allConnectivityResults | Export-Csv -Path $connectivityCsvPath -NoTypeInformation -Force
                    $generatedReports += $connectivityCsvPath
                    Write-Verbose "Rapport CSV de connectivité généré : $connectivityCsvPath"
                }

                # Exporter les statistiques d'interface
                if ($interfaceData.Count -gt 0) {
                    $interfaceCsvPath = Join-Path -Path $csvFolderPath -ChildPath "InterfaceStatistics.csv"
                    $interfaceData | Export-Csv -Path $interfaceCsvPath -NoTypeInformation -Force
                    $generatedReports += $interfaceCsvPath
                    Write-Verbose "Rapport CSV des statistiques d'interface généré : $interfaceCsvPath"
                }

                # Exporter les connexions TCP/UDP
                if ($allConnections.Count -gt 0) {
                    $connectionsCsvPath = Join-Path -Path $csvFolderPath -ChildPath "ConnectionStatistics.csv"
                    $allConnections | Export-Csv -Path $connectionsCsvPath -NoTypeInformation -Force
                    $generatedReports += $connectionsCsvPath
                    Write-Verbose "Rapport CSV des connexions généré : $connectionsCsvPath"
                }

                # Exporter un résumé
                $summaryCsvPath = Join-Path -Path $csvFolderPath -ChildPath "Summary.csv"

                $summaryData = @()

                # Résumé de session
                $summaryData += [PSCustomObject]@{
                    Category = "Session"
                    Item = "ID"
                    Value = $sessionInfo.SessionId
                }

                $summaryData += [PSCustomObject]@{
                    Category = "Session"
                    Item = "StartTime"
                    Value = $sessionInfo.StartTime
                }

                $summaryData += [PSCustomObject]@{
                    Category = "Session"
                    Item = "EndTime"
                    Value = $sessionInfo.ActualEndTime
                }

                $summaryData += [PSCustomObject]@{
                    Category = "Session"
                    Item = "Duration"
                    Value = [TimeSpan]::FromTicks(([DateTime]$sessionInfo.ActualEndTime - [DateTime]$sessionInfo.StartTime).Ticks).ToString("hh\:mm\:ss")
                }

                # Résumé de connectivité
                if ($connectivityAnalysis.Count -gt 0) {
                    $summaryData += [PSCustomObject]@{
                        Category = "Connectivity"
                        Item = "SuccessRate"
                        Value = "$($connectivityAnalysis.SuccessRate)%"
                    }

                    $summaryData += [PSCustomObject]@{
                        Category = "Connectivity"
                        Item = "AverageResponseTime"
                        Value = "$($connectivityAnalysis.AverageResponseTime) ms"
                    }

                    foreach ($target in $connectivityAnalysis.TargetResults.Keys) {
                        $targetData = $connectivityAnalysis.TargetResults[$target]

                        $summaryData += [PSCustomObject]@{
                            Category = "Target"
                            Item = $target
                            Value = "$($targetData.SuccessRate)% success, $($targetData.AverageResponseTime) ms"
                        }
                    }
                }

                # Résumé des statistiques réseau
                if ($statsAnalysis.Count -gt 0) {
                    foreach ($interfaceId in $statsAnalysis.Interfaces.Keys) {
                        $interfaceData = $statsAnalysis.Interfaces[$interfaceId]

                        $summaryData += [PSCustomObject]@{
                            Category = "Interface"
                            Item = $interfaceData.Name
                            Value = "Received: $($interfaceData.TotalMBReceived) MB, Sent: $($interfaceData.TotalMBSent) MB"
                        }
                    }

                    $summaryData += [PSCustomObject]@{
                        Category = "Connections"
                        Item = "TCP Average"
                        Value = [math]::Round($statsAnalysis.TCPConnectionsAverage, 0)
                    }

                    $summaryData += [PSCustomObject]@{
                        Category = "Connections"
                        Item = "UDP Average"
                        Value = [math]::Round($statsAnalysis.UDPConnectionsAverage, 0)
                    }
                }

                $summaryData | Export-Csv -Path $summaryCsvPath -NoTypeInformation -Force
                $generatedReports += $summaryCsvPath
                Write-Verbose "Rapport CSV de résumé généré : $summaryCsvPath"
            }

            # Rapport JSON
            if ($ReportType -eq 'JSON' -or $ReportType -eq 'All') {
                Write-Verbose "Génération du rapport JSON..."

                $jsonReportPath = Join-Path -Path $DestinationPath -ChildPath "NetworkMonitoringReport_$($sessionInfo.SessionId).json"
                $reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Force
                $generatedReports += $jsonReportPath
                Write-Verbose "Rapport JSON généré : $jsonReportPath"
            }

            # 5. Afficher un résumé des rapports générés
            Write-Host "Génération des rapports terminée." -ForegroundColor Green
            Write-Host "Rapports générés :" -ForegroundColor Yellow
            foreach ($report in $generatedReports) {
                Write-Host "  - $report" -ForegroundColor Cyan
            }

            # 6. Ouvrir le rapport si demandé
            if ($OpenReport -and $generatedReports.Count -gt 0) {
                $reportToOpen = $generatedReports[0]

                if ($ReportType -eq 'HTML' -or $ReportType -eq 'All') {
                    $reportToOpen = $generatedReports | Where-Object { $_ -like "*.html" } | Select-Object -First 1
                }

                if ($reportToOpen) {
                    Write-Verbose "Ouverture du rapport : $reportToOpen"
                    Start-Process $reportToOpen
                }
            }

            # Renvoyer les chemins des rapports générés
            return $generatedReports
        }
        catch {
            Write-Error "Erreur lors de la génération du rapport : $($_.Exception.Message)"
            return $null
        }
    }
}
```

Maintenant, créons les fonctions privées nécessaires à notre module de monitoring réseau :

# Write-NetworkLog.ps1

```powershell
function Write-NetworkLog {
    <#
    .SYNOPSIS
        Fonction privée pour journaliser les résultats de surveillance réseau.

    .DESCRIPTION
        Cette fonction enregistre les résultats des tests et statistiques réseau dans des
        fichiers de journalisation pour une utilisation ultérieure. Elle s'occupe de
        déterminer le type de résultat et le format approprié.

    .PARAMETER Result
        L'objet de résultat à journaliser.

    .PARAMETER LogPath
        Chemin où stocker le fichier journal. Par défaut : $script:LogPath

    .NOTES
        Cette fonction est utilisée en interne par les fonctions du module NetworkMonitor.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSObject]$Result,

        [Parameter(Mandatory = $false)]
        [string]$LogPath = $script:LogPath
    )

    # Vérifier que le dossier de logs existe
    if (-not (Test-Path -Path $LogPath)) {
        New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
    }

    # Déterminer le type de résultat en examinant ses propriétés
    $resultType = if ($Result.PSObject.Properties.Name -contains 'TestType') {
        'Connectivity'
    }
    elseif ($Result.PSObject.Properties.Name -contains 'InterfaceStatistics') {
        'Statistics'
    }
    elseif ($Result.PSObject.Properties.Name -contains 'CycleNumber') {
        'CycleResult'
    }
    else {
        'Unknown'
    }

    # Générer un nom de fichier unique basé sur le timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $logFileName = "NetworkMonitor_${resultType}_${timestamp}.json"
    $logFilePath = Join-Path -Path $LogPath -ChildPath $logFileName

    # Enregistrer le résultat au format JSON
    try {
        $Result | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFilePath -Force
        Write-Verbose "Résultat journalisé dans : $logFilePath"
    }
    catch {
        Write-Warning "Impossible de journaliser le résultat : $($_.Exception.Message)"
    }

    # Si le résultat est une erreur, journaliser également dans un fichier d'erreurs séparé
    if ($resultType -eq 'Connectivity' -and $Result.Status -eq 'Error') {
        $errorLogPath = Join-Path -Path $LogPath -ChildPath "Errors"

        if (-not (Test-Path -Path $errorLogPath)) {
            New-Item -Path $errorLogPath -ItemType Directory -Force | Out-Null
        }

        $errorFileName = "Error_${timestamp}.json"
        $errorFilePath = Join-Path -Path $errorLogPath -ChildPath $errorFileName

        $Result | ConvertTo-Json -Depth 10 | Out-File -FilePath $errorFilePath -Force
        Write-Verbose "Erreur journalisée dans : $errorFilePath"
    }

    # Renvoyer le chemin du fichier journal pour référence
    return $logFilePath
}
```

# Format-MonitoringOutput.ps1

```powershell
function Format-MonitoringOutput {
    <#
    .SYNOPSIS
        Fonction privée pour formater les résultats de surveillance réseau avant affichage.

    .DESCRIPTION
        Cette fonction prend les résultats bruts de la surveillance réseau et les formate
        de manière plus lisible pour l'affichage dans la console ou l'exportation.
        Elle détecte automatiquement le type de résultat et applique le formatage approprié.

    .PARAMETER Results
        Les résultats à formater.

    .PARAMETER ShowDetails
        Si spécifié, inclut les détails complets dans la sortie.
        Par défaut : $false

    .NOTES
        Cette fonction est utilisée en interne par les fonctions du module NetworkMonitor.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSObject]$Results,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails = $false
    )

    # Déterminer le type de résultat en examinant ses propriétés
    $resultType = if ($Results -is [Array] -and $Results.Count -gt 0 -and $Results[0].PSObject.Properties.Name -contains 'TestType') {
        'ConnectivityArray'
    }
    elseif ($Results.PSObject.Properties.Name -contains 'TestType') {
        'Connectivity'
    }
    elseif ($Results.PSObject.Properties.Name -contains 'InterfaceStatistics') {
        'Statistics'
    }
    elseif ($Results.PSObject.Properties.Name -contains 'CycleNumber') {
        'CycleResult'
    }
    else {
        'Unknown'
    }

    # Formater selon le type de résultat
    switch ($resultType) {
        'ConnectivityArray' {
            # Créer un tableau de résultats formatés pour les tests de connectivité
            $formattedResults = $Results | ForEach-Object {
                $statusIndicator = switch ($_.Status) {
                    'Success' { '✓' }
                    'Failed' { '✗' }
                    'Error' { '!' }
                    default { '?' }
                }

                # Ajouter des métriques spécifiques au type de test
                $specificMetrics = switch ($_.TestType) {
                    'Ping' {
                        "Perte: $($_.PacketLoss)%, Moy: $($_.AverageResponseTime) ms"
                    }
                    'Port' {
                        "Port: $($_.Port), Succès: $($_.SuccessRate)%, Moy: $($_.AverageResponseTime) ms"
                    }
                    'Traceroute' {
                        "Hops: $($_.HopCount), Temps total: $($_.TotalTime) ms"
                    }
                    default { "" }
                }

                [PSCustomObject]@{
                    Status = "$statusIndicator $($_.Status)"
                    Target = $_.Target
                    Type = $_.TestType
                    Timestamp = Get-Date $_.Timestamp -Format "HH:mm:ss"
                    Métriques = $specificMetrics
                    Détails = if ($ShowDetails) { $_.Details } else { "Utilisez -ShowDetails pour voir les détails" }
                }
            }
        }

        'Connectivity' {
            # Formater un résultat unique de test de connectivité
            $statusIndicator = switch ($Results.Status) {
                'Success' { '✓' }
                'Failed' { '✗' }
                'Error' { '!' }
                default { '?' }
            }

            $specificMetrics = switch ($Results.TestType) {
                'Ping' {
                    "Perte: $($Results.PacketLoss)%, Moy: $($Results.AverageResponseTime) ms"
                }
                'Port' {
                    "Port: $($Results.Port), Succès: $($Results.SuccessRate)%, Moy: $($Results.AverageResponseTime) ms"
                }
                'Traceroute' {
                    "Hops: $($Results.HopCount), Temps total: $($Results.TotalTime) ms"
                }
                default { "" }
            }

            $formattedResults = [PSCustomObject]@{
                Status = "$statusIndicator $($Results.Status)"
                Target = $Results.Target
                Type = $Results.TestType
                Timestamp = Get-Date $Results.Timestamp -Format "HH:mm:ss"
                Métriques = $specificMetrics
                Détails = if ($ShowDetails) { $Results.Details } else { "Utilisez -ShowDetails pour voir les détails" }
            }
        }

        'Statistics' {
            # Formater les statistiques réseau
            # Créer un objet pour chaque interface
            $interfaceStats = $Results.InterfaceStatistics | ForEach-Object {
                [PSCustomObject]@{
                    Interface = "$($_.InterfaceIndex): $($_.Name)"
                    Status = $_.Status
                    "Vitesse de liaison" = $_.LinkSpeed
                    "Reçu (Mo)" = [math]::Round($_.BytesReceived / 1MB, 2)
                    "Envoyé (Mo)" = [math]::Round($_.BytesSent / 1MB, 2)
                    "Paquets Reçus" = $_.PacketsReceived
                    "Paquets Envoyés" = $_.PacketsSent
                }
            }

            # Créer un récapitulatif des connexions TCP
            $tcpSummary = $Results.TCPConnections | Group-Object -Property State |
                Select-Object @{Name="État"; Expression={$_.Name}}, @{Name="Nombre"; Expression={$_.Count}} |
                Sort-Object -Property Nombre -Descending

            # Créer un récapitulatif des connexions par processus
            $processSummary = $Results.TCPConnections | Group-Object -Property ProcessName |
                Select-Object @{Name="Processus"; Expression={$_.Name}}, @{Name="Connexions"; Expression={$_.Count}} |
                Sort-Object -Property Connexions -Descending |
                Select-Object -First 5

            $formattedResults = [PSCustomObject]@{
                "Timestamp" = Get-Date $Results.Timestamp -Format "HH:mm:ss"
                "Ordinateur" = $Results.ComputerName
                "Interfaces" = $interfaceStats
                "Connexions TCP" = $Results.TCPConnections.Count
                "Connexions UDP" = $Results.UDPConnections.Count
                "États TCP" = $tcpSummary
                "Top Processus" = $processSummary
                "Détails" = if ($ShowDetails) {
                    [PSCustomObject]@{
                        "TCPConnections" = $Results.TCPConnections
                        "UDPConnections" = $Results.UDPConnections
                        "IPStatistics" = $Results.IPStatistics
                    }
                } else {
                    "Utilisez -ShowDetails pour voir les connexions détaillées"
                }
            }
        }

        'CycleResult' {
            # Formater le résultat d'un cycle complet de surveillance
            $formattedResults = [PSCustomObject]@{
                "Cycle" = $Results.CycleNumber
                "Timestamp" = Get-Date $Results.Timestamp -Format "HH:mm:ss"
                "Connectivité" = $Results.ConnectivityResults
                "Statistiques" = $Results.StatisticsResults
            }
        }

        default {
            # Si le type de résultat n'est pas reconnu, renvoyer l'objet original
            $formattedResults = $Results
        }
    }

    return $formattedResults
}
```

Pour compléter notre module, créons maintenant un exemple d'utilisation et le README.md :

# BasicMonitoring.ps1

```powershell
<#
.SYNOPSIS
    Script d'exemple montrant l'utilisation du module NetworkMonitor.

.DESCRIPTION
    Ce script montre comment utiliser les principales fonctionnalités du module
    NetworkMonitor pour surveiller le réseau, collecter des statistiques et
    générer des rapports.

.NOTES
    Auteur: Votre Nom
    Date de création: 27/04/2025
#>

# Importer le module (assurez-vous qu'il est installé ou dans le même répertoire)
Import-Module .\NetworkMonitor.psd1 -Force

# 1. Test de connectivité simple
Write-Host "1. Test de connectivité simple" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

# Tester plusieurs cibles avec ping
$pingResults = Test-NetworkConnection -Target "google.com", "github.com", "nonexistentdomain.example"
$pingResults | Format-Table -AutoSize

# Tester une connexion à un port spécifique
$portResults = Test-NetworkConnection -Target "google.com" -TestType Port -Port 443
$portResults | Format-Table -AutoSize

# Effectuer un traceroute
$traceResults = Test-NetworkConnection -Target "microsoft.com" -TestType Traceroute
$traceResults | Format-Table -AutoSize

# 2. Collecter des statistiques réseau
Write-Host "`n2. Statistiques réseau" -ForegroundColor Cyan
Write-Host "--------------------" -ForegroundColor Cyan

# Obtenir les statistiques des interfaces actives
$networkStats = Get-NetworkStatistics
$networkStats.Interfaces | Format-Table -AutoSize

# Afficher le top 5 des processus avec le plus de connexions
$networkStats."Top Processus" | Format-Table -AutoSize

# 3. Surveillance continue sur une courte durée (30 secondes)
Write-Host "`n3. Surveillance continue" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan
Write-Host "Démarrage d'une surveillance de 30 secondes avec intervalle de 10 secondes..."

# Démarrer une session de surveillance pour 30 secondes
$monitoringSession = Start-NetworkMonitoring `
    -Target "google.com", "github.com" `
    -Interval 10 `
    -Duration 0.5 `
    -NoConsoleOutput

# Attendre la fin de la surveillance
Start-Sleep -Seconds 35

# 4. Générer un rapport
Write-Host "`n4. Génération du rapport" -ForegroundColor Cyan
Write-Host "---------------------" -ForegroundColor Cyan

# Générer un rapport HTML et ouvrir automatiquement
$sessionPath = Split-Path -Path $monitoringSession.SessionId -Parent
$reports = Export-MonitoringReport -SessionPath $sessionPath -ReportType HTML -OpenReport

Write-Host "`nRapport généré : $($reports)"
Write-Host "`nDémonstration terminée."
```

# Module NetworkMonitor

Module PowerShell pour surveiller et analyser la connectivité réseau et les statistiques système.

## Description

Le module NetworkMonitor fournit un ensemble d'outils pour tester la connectivité réseau, collecter des statistiques et générer des rapports détaillés. Il est particulièrement utile pour diagnostiquer des problèmes réseau, surveiller les performances et documenter l'état de votre infrastructure.

## Fonctionnalités

- **Tests de connectivité** : Ping, port TCP et traceroute
- **Statistiques réseau** : Interfaces, connexions TCP/UDP, trafic
- **Surveillance continue** : Tests automatisés à intervalles réguliers
- **Rapports détaillés** : Formats HTML, CSV et JSON
- **Journalisation** : Enregistrement des résultats pour analyse ultérieure

## Installation

### Prérequis

- PowerShell 5.1 ou supérieur
- Modules PowerShell standard (aucun module supplémentaire requis)

### Installation manuelle

1. Téléchargez le code source ou clonez le dépôt
2. Copiez le dossier `NetworkMonitor` dans l'un des répertoires de modules PowerShell
   ```powershell
   $env:PSModulePath -split ';'
   ```
3. Importez le module
   ```powershell
   Import-Module NetworkMonitor
   ```

## Utilisation

### Test de connectivité simple

```powershell
# Test de ping vers plusieurs cibles
Test-NetworkConnection -Target "google.com", "github.com"

# Test de port
Test-NetworkConnection -Target "smtp.example.com" -TestType Port -Port 25

# Traceroute
Test-NetworkConnection -Target "microsoft.com" -TestType Traceroute
```

### Statistiques réseau

```powershell
# Obtenir toutes les statistiques
$stats = Get-NetworkStatistics

# Afficher les statistiques d'interface
$stats.Interfaces | Format-Table

# Afficher les connexions TCP établies
$stats.TCPConnections | Where-Object { $_.State -eq 'Established' } | Format-Table
```

### Surveillance continue

```powershell
# Surveiller la connectivité pendant 10 minutes
$session = Start-NetworkMonitoring -Target "192.168.1.1", "8.8.8.8" -Interval 30 -Duration 10

# Surveillance sans limite de temps (jusqu'à Ctrl+C)
Start-NetworkMonitoring -Target "critical-server.local" -Interval 60
```

### Génération de rapports

```powershell
# Générer un rapport HTML et l'ouvrir
Export-MonitoringReport -SessionPath $session.SessionPath -ReportType HTML -OpenReport

# Exporter dans tous les formats avec données brutes
Export-MonitoringReport -SessionPath $session.SessionPath -ReportType All -IncludeRawData
```

## Exemples

Consultez le dossier `examples` pour des scripts d'exemple complets, notamment :

- `BasicMonitoring.ps1` : Démonstration des fonctionnalités de base
- Autres exemples à venir...

## Personnalisation

Vous pouvez personnaliser les chemins de logs et résultats dans le fichier `NetworkMonitor.psm1` :

```powershell
# Chemins par défaut
$script:LogPath = "$env:TEMP\NetworkMonitor\Logs"
$script:ResultsPath = "$env:TEMP\NetworkMonitor\Results"
```

## Documentation

Pour accéder à la documentation de chaque commande :

```powershell
Get-Help Test-NetworkConnection -Full
Get-Help Get-NetworkStatistics -Full
Get-Help Start-NetworkMonitoring -Full
Get-Help Export-MonitoringReport -Full
```

## Dépannage

### Problèmes connus

- Sur certains systèmes, les tests de traceroute peuvent nécessiter des privilèges d'administrateur.
- La surveillance longue durée peut générer un volume important de données.

### Journaux

Les journaux sont enregistrés par défaut dans `$env:TEMP\NetworkMonitor\Logs`.

## Contribuer

Les contributions à ce projet sont les bienvenues :

1. Forkez le dépôt
2. Créez une branche pour votre fonctionnalité (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Committez vos changements (`git commit -am 'Ajout de nouvelle fonctionnalité'`)
4. Poussez vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Créez une Pull Request

## Licence

Ce projet est distribué sous licence MIT. Voir le fichier LICENSE pour plus d'informations.

## Auteur

Votre Nom - [votre@email.com](mailto:votre@email.com)

---

*Ce module a été développé dans le cadre du cours "PowerShell – Du Débutant à l'Expert".*


Et enfin, créons le fichier de test unitaire :

# NetworkMonitor.Tests.ps1

```powershell
<#
.SYNOPSIS
    Tests unitaires pour le module NetworkMonitor.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module NetworkMonitor et de ses fonctions.

.NOTES
    Requiert Pester pour l'exécution des tests unitaires.
    Exécuter avec la commande: Invoke-Pester .\NetworkMonitor.Tests.ps1

    Auteur: Votre Nom
    Date de création: 27/04/2025
#>

# Importer le module à tester
$modulePath = Split-Path -Parent $PSScriptRoot
Import-Module "$modulePath\NetworkMonitor.psd1" -Force

# Tests unitaires avec Pester
Describe "Module NetworkMonitor" {

    # Tests pour les chemins du module
    Context "Configuration du module" {
        It "Le LogPath devrait exister après l'importation" {
            Test-Path $LogPath | Should -Be $true
        }

        It "Le ResultsPath devrait exister après l'importation" {
            Test-Path $ResultsPath | Should -Be $true
        }
    }

    # Tests pour Test-NetworkConnection
    Context "Test-NetworkConnection" {
        It "Devrait retourner un résultat pour un test de ping" {
            $result = Test-NetworkConnection -Target "localhost"
            $result | Should -Not -BeNullOrEmpty
        }

        It "Devrait avoir les propriétés attendues pour un test de ping" {
            $result = Test-NetworkConnection -Target "localhost"
            $result.PSObject.Properties.Name | Should -Contain "Status"
            $result.PSObject.Properties.Name | Should -Contain "Target"
            $result.PSObject.Properties.Name | Should -Contain "AverageResponseTime"
        }

        It "Devrait gérer correctement un nom d'hôte inexistant" {
            $result = Test-NetworkConnection -Target "nonexistenthost.example"
            $result.Status | Should -Not -Be "Success"
        }

        It "Devrait tester correctement un port" {
            # Test du port local où PowerShell ISE ou l'hôte PowerShell est en cours d'exécution
            $result = Test-NetworkConnection -Target "localhost" -TestType Port -Port 80
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain "Port"
        }
    }

    # Tests pour Get-NetworkStatistics
    Context "Get-NetworkStatistics" {
        It "Devrait retourner des statistiques réseau" {
            $result = Get-NetworkStatistics
            $result | Should -Not -BeNullOrEmpty
        }

        It "Devrait contenir des données d'interface" {
            $result = Get-NetworkStatistics
            $result.InterfaceStatistics | Should -Not -BeNullOrEmpty
        }

        It "Devrait contenir des statistiques TCP" {
            $result = Get-NetworkStatistics
            $result.TCPStatistics | Should -Not -BeNullOrEmpty
        }
    }

    # Tests pour fonctions privées
    Context "Format-MonitoringOutput" {
        It "Devrait formater correctement un résultat de connectivité" {
            # Créer un objet de test
            $testObject = [PSCustomObject]@{
                Target = "localhost"
                TestType = "Ping"
                Status = "Success"
                Timestamp = Get-Date
                AverageResponseTime = 1
                MinimumResponseTime = 1
                MaximumResponseTime = 1
                PacketLoss = 0
            }

            # Invoquer la fonction privée
            $formattedResult = & (Get-Module NetworkMonitor) { Format-MonitoringOutput -Results $using:testObject }
            $formattedResult | Should -Not -BeNullOrEmpty
            $formattedResult.PSObject.Properties.Name | Should -Contain "Status"
            $formattedResult.Status | Should -BeLike "*Success"
        }
    }

    # Tests pour Start-NetworkMonitoring et Export-MonitoringReport
    # Ces tests sont plus complexes car ils impliquent des processus asynchrones
    # et la création de fichiers - ils pourraient être désactivés en environnement CI/CD
    Context "Surveillance réseau et génération de rapports" {
        It "Devrait démarrer une session de surveillance" -Skip {
            # Test avec une durée très courte pour éviter d'attendre trop longtemps
            $session = Start-NetworkMonitoring -Target "localhost" -Duration 0.05 -Interval 5 -NoConsoleOutput
            $session | Should -Not -BeNullOrEmpty
            $session.PSObject.Properties.Name | Should -Contain "SessionId"

            # Attendre la fin de la session
            Start-Sleep -Seconds 5

            # Vérifier que les fichiers sont créés
            $sessionPath = Split-Path -Path $session.SessionId -Parent
            Test-Path $sessionPath | Should -Be $true
        }

        It "Devrait générer un rapport HTML" -Skip {
            # Ce test dépend du test précédent
            $session = Start-NetworkMonitoring -Target "localhost" -Duration 0.05 -Interval 5 -NoConsoleOutput
            Start-Sleep -Seconds 5

            $sessionPath = Split-Path -Path $session.SessionId -Parent
            $reports = Export-MonitoringReport -SessionPath $sessionPath -ReportType HTML

            $reports | Should -Not -BeNullOrEmpty
            $reports[0] | Should -BeLike "*.html"
            Test-Path $reports[0] | Should -Be $true
        }
    }
}
```

Voici un résumé de la solution complète pour l'exercice "Solution Complète Exercice 2 - Module de monitoring réseau" :

1. **Structure du module** : J'ai créé une structure de projet PowerShell organisée selon les bonnes pratiques, avec séparation des fonctions publiques et privées, manifeste de module, documentation et tests.

2. **Fonctions publiques** :
   - `Test-NetworkConnection` : Permet de tester la connectivité réseau (ping, port, traceroute)
   - `Get-NetworkStatistics` : Collecte des statistiques réseau sur un système
   - `Start-NetworkMonitoring` : Démarre une session de surveillance réseau continue
   - `Export-MonitoringReport` : Génère et exporte des rapports de surveillance au format HTML, CSV ou JSON

3. **Fonctions privées** :
   - `Write-NetworkLog` : S'occupe de la journalisation des résultats
   - `Format-MonitoringOutput` : Formate les résultats pour l'affichage dans la console

4. **Fichiers additionnels** :
   - `README.md` : Documentation complète du module avec exemples d'utilisation
   - `BasicMonitoring.ps1` : Script d'exemple montrant l'utilisation du module
   - `NetworkMonitor.Tests.ps1` : Tests unitaires pour valider le fonctionnement du module

Cette solution respecte les bonnes pratiques d'organisation de projets PowerShell présentées dans le module 15-1, notamment :
- Séparation claire des fonctions publiques et privées
- Une fonction par fichier avec le même nom
- Documentation complète des fonctions avec des commentaires d'aide
- Tests unitaires pour assurer la qualité
- Manifeste de module avec toutes les métadonnées nécessaires
- Script principal qui charge dynamiquement toutes les fonctions

Le module offre une solution complète pour surveiller la connectivité réseau, collecter des statistiques et générer des rapports détaillés, ce qui en fait un outil utile pour les administrateurs système et les professionnels IT qui ont besoin de diagnostiquer des problèmes réseau ou de documenter l'état de leur infrastructure.

Cette solution peut facilement être étendue avec des fonctionnalités supplémentaires, comme la surveillance de services spécifiques, l'intégration avec des systèmes d'alerte, ou l'ajout de visualisations de données plus avancées dans les rapports.

