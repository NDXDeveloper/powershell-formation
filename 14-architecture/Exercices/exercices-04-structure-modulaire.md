# Solution Exercice 1: Création de la structure du module

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Cet exercice consiste à créer un module simple avec la structure recommandée.

## Structure de répertoires à créer

Voici comment créer la structure complète du module en PowerShell:

```powershell
# Définir le nom du module
$ModuleName = "SysInfoModule"

# Créer la structure de répertoires
$ModuleRoot = New-Item -Path ".\$ModuleName" -ItemType Directory -Force
$PublicFolder = New-Item -Path "$ModuleRoot\Public" -ItemType Directory -Force
$PrivateFolder = New-Item -Path "$ModuleRoot\Private" -ItemType Directory -Force
$TestsFolder = New-Item -Path "$ModuleRoot\Tests" -ItemType Directory -Force
$DocsFolder = New-Item -Path "$ModuleRoot\docs" -ItemType Directory -Force
New-Item -Path "$TestsFolder\Public" -ItemType Directory -Force
New-Item -Path "$TestsFolder\Private" -ItemType Directory -Force
New-Item -Path "$DocsFolder\examples" -ItemType Directory -Force

# Afficher la structure créée
Write-Host "Structure de module créée avec succès:" -ForegroundColor Green
Get-ChildItem $ModuleRoot -Recurse | Select-Object FullName
```

## Explication

1. Nous avons créé un script qui génère automatiquement la structure de base de notre module appelé "SysInfoModule".
2. La structure inclut les répertoires principaux: Public, Private, Tests et docs.
3. À ce stade, nous avons uniquement la structure de répertoires; dans les exercices suivants, nous allons ajouter du contenu à ces répertoires.

## Vérification

Pour vérifier que la structure a été correctement créée, vous devriez voir une arborescence similaire à celle-ci:

```
SysInfoModule/
├── Public/
├── Private/
├── Tests/
│   ├── Public/
│   └── Private/
└── docs/
    └── examples/
```

## Prochaine étape

Dans l'exercice suivant, nous allons ajouter des fonctions publiques et privées à notre module.

# Solution Exercice 2: Ajout de fonctions publiques et privées

Cet exercice consiste à ajouter deux fonctions publiques et une fonction privée helper à notre module SysInfoModule.

## Fonction privée helper

Commençons par créer le fichier pour notre fonction privée:

```powershell
# SysInfoModule/Private/Format-Size.ps1

function Format-Size {
    <#
    .SYNOPSIS
        Convertit une taille en octets en un format plus lisible (KB, MB, GB).
    .DESCRIPTION
        Cette fonction privée convertit un nombre d'octets en une chaîne formatée avec l'unité appropriée.
    .PARAMETER Bytes
        Le nombre d'octets à convertir.
    .EXAMPLE
        Format-Size -Bytes 1024
        Retourne "1 KB"
    .NOTES
        Fonction interne, non exportée.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$Bytes
    )

    $sizes = @('B', 'KB', 'MB', 'GB', 'TB', 'PB')
    $index = 0

    while (($Bytes -ge 1024) -and ($index -lt ($sizes.Count - 1))) {
        $Bytes /= 1024
        $index++
    }

    # Formater avec deux décimales pour les valeurs supérieures à B
    if ($index -eq 0) {
        return "$([Math]::Round($Bytes, 0)) $($sizes[$index])"
    }
    else {
        return "$([Math]::Round($Bytes, 2)) $($sizes[$index])"
    }
}
```

## Première fonction publique

Créons maintenant le fichier pour notre première fonction publique:

```powershell
# SysInfoModule/Public/Get-DiskInfo.ps1

function Get-DiskInfo {
    <#
    .SYNOPSIS
        Récupère des informations sur les disques du système.
    .DESCRIPTION
        Cette fonction renvoie des informations détaillées sur les disques du système,
        y compris l'espace total, utilisé et libre dans un format lisible.
    .PARAMETER ComputerName
        Nom de l'ordinateur à interroger. Par défaut, c'est l'ordinateur local.
    .EXAMPLE
        Get-DiskInfo
        Retourne les informations sur les disques de l'ordinateur local.
    .EXAMPLE
        Get-DiskInfo -ComputerName "Server01"
        Retourne les informations sur les disques de l'ordinateur "Server01".
    .NOTES
        Requiert des privilèges d'administrateur pour les ordinateurs distants.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Récupération des informations de disque pour $ComputerName"
    }

    process {
        try {
            # Récupérer les disques via CIM
            $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3" -ComputerName $ComputerName -ErrorAction Stop

            # Traiter chaque disque
            foreach ($disk in $disks) {
                # Calculer l'espace utilisé
                $usedSpace = $disk.Size - $disk.FreeSpace

                # Utiliser notre fonction privée Format-Size
                $sizeFormatted = Format-Size -Bytes $disk.Size
                $freeSpaceFormatted = Format-Size -Bytes $disk.FreeSpace
                $usedSpaceFormatted = Format-Size -Bytes $usedSpace

                # Calculer le pourcentage d'utilisation
                $usedPercentage = [Math]::Round(($usedSpace / $disk.Size) * 100, 2)

                # Créer un objet personnalisé avec les informations
                [PSCustomObject]@{
                    ComputerName = $ComputerName
                    DriveLetter = $disk.DeviceID
                    DriveLabel = $disk.VolumeName
                    FileSystem = $disk.FileSystem
                    Size = $sizeFormatted
                    FreeSpace = $freeSpaceFormatted
                    UsedSpace = $usedSpaceFormatted
                    UsedPercentage = "$usedPercentage%"
                }
            }
        }
        catch {
            Write-Error "Erreur lors de la récupération des informations de disque: $_"
        }
    }

    end {
        Write-Verbose "Traitement terminé pour $ComputerName"
    }
}
```

## Deuxième fonction publique

Créons maintenant le fichier pour notre deuxième fonction publique:

```powershell
# SysInfoModule/Public/Get-SystemInfo.ps1

function Get-SystemInfo {
    <#
    .SYNOPSIS
        Récupère des informations système de base.
    .DESCRIPTION
        Cette fonction renvoie des informations générales sur le système d'exploitation,
        le processeur, la mémoire et le temps de fonctionnement.
    .PARAMETER ComputerName
        Nom de l'ordinateur à interroger. Par défaut, c'est l'ordinateur local.
    .EXAMPLE
        Get-SystemInfo
        Retourne les informations système de l'ordinateur local.
    .EXAMPLE
        Get-SystemInfo -ComputerName "Server01"
        Retourne les informations système de l'ordinateur "Server01".
    .NOTES
        Requiert des privilèges d'administrateur pour les ordinateurs distants.
    #>
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$ComputerName = $env:COMPUTERNAME
    )

    begin {
        Write-Verbose "Récupération des informations système pour $ComputerName"
    }

    process {
        try {
            # Récupérer les informations du système d'exploitation
            $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName -ErrorAction Stop

            # Récupérer les informations du processeur
            $processor = Get-CimInstance -ClassName Win32_Processor -ComputerName $ComputerName -ErrorAction Stop | Select-Object -First 1

            # Récupérer les informations de la mémoire
            $totalMemory = $os.TotalVisibleMemorySize * 1KB
            $freeMemory = $os.FreePhysicalMemory * 1KB

            # Utiliser notre fonction privée Format-Size
            $totalMemoryFormatted = Format-Size -Bytes $totalMemory
            $freeMemoryFormatted = Format-Size -Bytes $freeMemory
            $usedMemory = $totalMemory - $freeMemory
            $usedMemoryFormatted = Format-Size -Bytes $usedMemory

            # Calculer le pourcentage d'utilisation de la mémoire
            $memoryUsedPercentage = [Math]::Round(($usedMemory / $totalMemory) * 100, 2)

            # Calculer le temps de fonctionnement
            $bootTime = $os.LastBootUpTime
            $uptime = (Get-Date) - $bootTime
            $uptimeFormatted = "{0} jours, {1} heures, {2} minutes" -f $uptime.Days, $uptime.Hours, $uptime.Minutes

            # Créer un objet personnalisé avec les informations système
            [PSCustomObject]@{
                ComputerName = $ComputerName
                OSName = $os.Caption
                OSVersion = $os.Version
                ServicePack = $os.ServicePackMajorVersion
                Architecture = if ($os.OSArchitecture -eq "64-bit") { "x64" } else { "x86" }
                Manufacturer = $os.Manufacturer
                ProcessorName = $processor.Name
                ProcessorCores = $processor.NumberOfCores
                ProcessorLogicalProcessors = $processor.NumberOfLogicalProcessors
                TotalMemory = $totalMemoryFormatted
                FreeMemory = $freeMemoryFormatted
                UsedMemory = $usedMemoryFormatted
                MemoryUsedPercentage = "$memoryUsedPercentage%"
                LastBoot = $bootTime
                Uptime = $uptimeFormatted
            }
        }
        catch {
            Write-Error "Erreur lors de la récupération des informations système: $_"
        }
    }

    end {
        Write-Verbose "Traitement terminé pour $ComputerName"
    }
}
```

## Vérification

Vous devriez maintenant avoir les fichiers suivants dans votre structure de module:

```
SysInfoModule/
├── Public/
│   ├── Get-DiskInfo.ps1
│   └── Get-SystemInfo.ps1
├── Private/
│   └── Format-Size.ps1
├── Tests/
│   ├── Public/
│   └── Private/
└── docs/
    └── examples/
```

## Prochaine étape

Dans l'exercice suivant, nous allons créer le fichier principal `.psm1` et le manifeste du module `.psd1` pour finaliser notre module.

# Solution Exercice 3: Création du manifeste de module

Cet exercice consiste à créer le fichier principal `.psm1` et le manifeste `.psd1` pour notre module SysInfoModule.

## Fichier principal du module (PSM1)

Commençons par créer le fichier principal `SysInfoModule.psm1` qui chargera toutes nos fonctions publiques et privées:

```powershell
# SysInfoModule/SysInfoModule.psm1

# Définir la préférence pour les messages Verbose
$VerbosePreference = 'Continue'

# Charger les fonctions privées
$PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'
if (Test-Path -Path $PrivatePath) {
    Write-Verbose "Chargement des fonctions privées depuis $PrivatePath"
    $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue

    foreach ($Function in $PrivateFunctions) {
        try {
            Write-Verbose "  Chargement de la fonction privée: $($Function.BaseName)"
            . $Function.FullName
        }
        catch {
            Write-Error "Impossible de charger la fonction privée $($Function.BaseName): $_"
        }
    }
}

# Charger les fonctions publiques
$PublicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
if (Test-Path -Path $PublicPath) {
    Write-Verbose "Chargement des fonctions publiques depuis $PublicPath"
    $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse -ErrorAction SilentlyContinue

    foreach ($Function in $PublicFunctions) {
        try {
            Write-Verbose "  Chargement de la fonction publique: $($Function.BaseName)"
            . $Function.FullName
        }
        catch {
            Write-Error "Impossible de charger la fonction publique $($Function.BaseName): $_"
        }
    }

    # Exporter les fonctions publiques pour qu'elles soient disponibles aux utilisateurs
    $FunctionsToExport = $PublicFunctions.BaseName
    Write-Verbose "Exportation des fonctions: $($FunctionsToExport -join ', ')"
    Export-ModuleMember -Function $FunctionsToExport
}

# Réinitialiser la préférence Verbose à sa valeur par défaut
$VerbosePreference = 'SilentlyContinue'

Write-Verbose "Module SysInfoModule chargé avec succès!"
```

## Manifeste du module (PSD1)

Maintenant, créons le fichier manifeste `SysInfoModule.psd1` qui contient les métadonnées de notre module:

```powershell
# SysInfoModule/SysInfoModule.psd1
# Script pour créer le manifeste de module

$ModuleName = "SysInfoModule"
$ModuleVersion = "1.0.0"
$Author = "Votre Nom"
$Description = "Module PowerShell pour récupérer des informations système"

# Récupérer les noms des fonctions publiques
$PublicFunctions = Get-ChildItem -Path ".\$ModuleName\Public" -Filter '*.ps1' -ErrorAction SilentlyContinue |
                  Select-Object -ExpandProperty BaseName

# Créer le manifeste de module
$ManifestParams = @{
    Path = ".\$ModuleName\$ModuleName.psd1"
    RootModule = "$ModuleName.psm1"
    ModuleVersion = $ModuleVersion
    Author = $Author
    CompanyName = 'N/A'
    Description = $Description
    PowerShellVersion = '5.1'
    FunctionsToExport = $PublicFunctions
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    Tags = @('System', 'Information', 'Disks', 'Memory', 'CPU')
    ProjectUri = 'https://github.com/username/SysInfoModule'
    LicenseUri = 'https://github.com/username/SysInfoModule/blob/main/LICENSE'
    ReleaseNotes = 'Version initiale du module SysInfoModule.'
}

# Générer le fichier de manifeste
New-ModuleManifest @ManifestParams

Write-Host "Manifeste de module créé avec succès: $($ManifestParams.Path)" -ForegroundColor Green
```

## Création du fichier README.md

Pour compléter notre module, créons un fichier README.md dans le dossier docs:

```markdown
# SysInfoModule/docs/README.md

# SysInfoModule

Un module PowerShell pour récupérer et afficher des informations système de façon claire et structurée.

## Installation

```powershell
# Installation depuis un répertoire local
Copy-Item -Path ".\SysInfoModule" -Destination "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\" -Recurse -Force

# Vérifier que le module est disponible
Get-Module -Name SysInfoModule -ListAvailable
```

## Fonctions disponibles

### Get-DiskInfo

Récupère des informations détaillées sur les disques du système.

```powershell
# Exemple d'utilisation
Get-DiskInfo

# Pour un ordinateur distant
Get-DiskInfo -ComputerName "Server01"
```

### Get-SystemInfo

Récupère des informations générales sur le système d'exploitation, le processeur, la mémoire et le temps de fonctionnement.

```powershell
# Exemple d'utilisation
Get-SystemInfo

# Pour un ordinateur distant
Get-SystemInfo -ComputerName "Server01"
```

## Exemples

Consultez le dossier `examples` pour des exemples d'utilisation plus détaillés.

## Contribution

Les contributions sont les bienvenues! N'hésitez pas à soumettre des issues ou des pull requests.

## Licence

Ce projet est sous licence MIT.
```

## Exemple d'utilisation

Créons également un exemple d'utilisation dans le dossier examples:

```powershell
# SysInfoModule/docs/examples/Basic-Usage.ps1

# Importer le module
Import-Module SysInfoModule -Force -Verbose

# Obtenir des informations système
Write-Host "`n=== Informations système ===" -ForegroundColor Cyan
$sysInfo = Get-SystemInfo
$sysInfo | Format-List

# Obtenir des informations sur les disques
Write-Host "`n=== Informations sur les disques ===" -ForegroundColor Cyan
$diskInfo = Get-DiskInfo
$diskInfo | Format-Table -AutoSize

# Exemple d'exportation des données
Write-Host "`n=== Exportation des données ===" -ForegroundColor Cyan
$exportPath = "$env:USERPROFILE\Desktop\SystemReport.csv"
$sysInfo | Export-Csv -Path $exportPath -NoTypeInformation
Write-Host "Rapport système exporté vers: $exportPath" -ForegroundColor Green

# Exemple d'utilisation avancée - Filtrer les disques avec peu d'espace libre
Write-Host "`n=== Disques avec moins de 20% d'espace libre ===" -ForegroundColor Yellow
$diskInfo | Where-Object {
    [double]($_.UsedPercentage -replace '%', '') -gt 80
} | Format-Table -AutoSize
```

## Vérification

Vous devriez maintenant avoir les fichiers suivants dans votre structure de module:

```
SysInfoModule/
├── SysInfoModule.psm1    # Fichier principal du module
├── SysInfoModule.psd1    # Manifeste du module
├── Public/
│   ├── Get-DiskInfo.ps1
│   └── Get-SystemInfo.ps1
├── Private/
│   └── Format-Size.ps1
├── Tests/
│   ├── Public/
│   └── Private/
└── docs/
    ├── README.md
    └── examples/
        └── Basic-Usage.ps1
```

## Prochaine étape

Dans l'exercice suivant, nous allons tester le chargement et l'utilisation de notre module.

# Solution Exercice 4: Test du module

Cet exercice consiste à tester le chargement et l'utilisation de notre module SysInfoModule.

## Script de test complet

Voici un script complet pour tester notre module:

```powershell
# Test-SysInfoModule.ps1

# Chemins des répertoires
$ModuleName = "SysInfoModule"
$ModulePath = ".\$ModuleName"
$UserModulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$ModuleName"

# Fonction pour afficher les étapes de test
function Write-TestStep {
    param (
        [string]$Message
    )
    Write-Host "`n[TEST] $Message" -ForegroundColor Cyan
}

# 1. Vérifier la structure du module
Write-TestStep "Vérification de la structure du module"
if (-not (Test-Path -Path $ModulePath)) {
    Write-Error "Le module n'existe pas à l'emplacement $ModulePath"
    return
}

$requiredFiles = @(
    "$ModulePath\$ModuleName.psm1",
    "$ModulePath\$ModuleName.psd1",
    "$ModulePath\Public\Get-DiskInfo.ps1",
    "$ModulePath\Public\Get-SystemInfo.ps1",
    "$ModulePath\Private\Format-Size.ps1"
)

$missingFiles = $requiredFiles | Where-Object { -not (Test-Path $_) }
if ($missingFiles) {
    Write-Error "Les fichiers suivants sont manquants: $($missingFiles -join ', ')"
    return
}

Write-Host "Structure du module vérifiée avec succès!" -ForegroundColor Green

# 2. Installer le module localement
Write-TestStep "Installation du module dans le répertoire utilisateur"
try {
    # Créer le répertoire s'il n'existe pas
    if (-not (Test-Path -Path $UserModulePath)) {
        New-Item -Path $UserModulePath -ItemType Directory -Force | Out-Null
    }

    # Copier les fichiers du module
    Copy-Item -Path "$ModulePath\*" -Destination $UserModulePath -Recurse -Force
    Write-Host "Module copié avec succès dans $UserModulePath" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de la copie du module: $_"
    return
}

# 3. Vérifier que le module est disponible
Write-TestStep "Vérification de la disponibilité du module"
$modules = Get-Module -Name $ModuleName -ListAvailable
if (-not $modules) {
    Write-Error "Le module $ModuleName n'est pas disponible"
    return
}
Write-Host "Module $ModuleName disponible: $($modules.Path)" -ForegroundColor Green

# 4. Importer le module
Write-TestStep "Importation du module"
try {
    Import-Module -Name $ModuleName -Force -Verbose
    Write-Host "Module $ModuleName importé avec succès!" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de l'importation du module: $_"
    return
}

# 5. Vérifier les commandes disponibles
Write-TestStep "Vérification des commandes exportées"
$commands = Get-Command -Module $ModuleName
Write-Host "Commandes disponibles dans le module $ModuleName:" -ForegroundColor Green
$commands | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Green
}

# 6. Tester la fonction Get-SystemInfo
Write-TestStep "Test de la fonction Get-SystemInfo"
try {
    $sysInfo = Get-SystemInfo -Verbose
    Write-Host "Résultat de Get-SystemInfo:" -ForegroundColor Green
    $sysInfo | Format-List
}
catch {
    Write-Error "Erreur lors de l'exécution de Get-SystemInfo: $_"
}

# 7. Tester la fonction Get-DiskInfo
Write-TestStep "Test de la fonction Get-DiskInfo"
try {
    $diskInfo = Get-DiskInfo -Verbose
    Write-Host "Résultat de Get-DiskInfo:" -ForegroundColor Green
    $diskInfo | Format-Table -AutoSize
}
catch {
    Write-Error "Erreur lors de l'exécution de Get-DiskInfo: $_"
}

# 8. Tester l'accès à la fonction privée (doit échouer)
Write-TestStep "Test de l'accès à la fonction privée (doit échouer)"
try {
    Format-Size -Bytes 1024
    Write-Host "ERREUR: La fonction privée Format-Size est accessible depuis l'extérieur du module!" -ForegroundColor Red
}
catch {
    Write-Host "OK: La fonction privée Format-Size n'est pas accessible depuis l'extérieur du module." -ForegroundColor Green
}

# 9. Tester la désinstallation du module
Write-TestStep "Désinstallation du module"
try {
    Remove-Module -Name $ModuleName -Force -ErrorAction Stop
    Write-Host "Module $ModuleName désinstallé avec succès!" -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de la désinstallation du module: $_"
}

Write-Host "`n[TEST TERMINÉ] Tous les tests ont été exécutés avec succès!" -ForegroundColor Cyan
```

## Script de test Pester

Pour une approche plus professionnelle, voici un script de test utilisant le framework Pester:

```powershell
# SysInfoModule/Tests/SysInfoModule.Tests.ps1

Describe "SysInfoModule Tests" {
    BeforeAll {
        # Chemin du module à tester
        $ModuleName = "SysInfoModule"
        $ModulePath = (Get-Item -Path "..\").FullName
        $ManifestPath = Join-Path -Path $ModulePath -ChildPath "$ModuleName.psd1"

        # Importer le module
        Import-Module -Name $ManifestPath -Force
    }

    Context "Module Structure" {
        It "Should have a valid module manifest" {
            Test-Path -Path $ManifestPath | Should -Be $true
        }

        It "Should have a root module file" {
            $moduleInfo = Get-Module -Name $ModuleName
            $moduleInfo.RootModule | Should -Not -BeNullOrEmpty
        }

        It "Should export the expected functions" {
            $exportedFunctions = (Get-Module -Name $ModuleName).ExportedFunctions.Keys
            $exportedFunctions | Should -Contain 'Get-DiskInfo'
            $exportedFunctions | Should -Contain 'Get-SystemInfo'
        }

        It "Should not export private functions" {
            $exportedFunctions = (Get-Module -Name $ModuleName).ExportedFunctions.Keys
            $exportedFunctions | Should -Not -Contain 'Format-Size'
        }
    }

    Context "Function: Get-SystemInfo" {
        $result = Get-SystemInfo

        It "Should return an object" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should have the expected properties" {
            $result | Should -HaveProperty 'ComputerName'
            $result | Should -HaveProperty 'OSName'
            $result | Should -HaveProperty 'OSVersion'
            $result | Should -HaveProperty 'TotalMemory'
            $result | Should -HaveProperty 'Uptime'
        }

        It "Should have non-empty property values" {
            $result.ComputerName | Should -Not -BeNullOrEmpty
            $result.OSName | Should -Not -BeNullOrEmpty
            $result.OSVersion | Should -Not -BeNullOrEmpty
        }
    }

    Context "Function: Get-DiskInfo" {
        $result = Get-DiskInfo

        It "Should return an object" {
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should have the expected properties" {
            $result | Should -HaveProperty 'ComputerName'
            $result | Should -HaveProperty 'DriveLetter'
            $result | Should -HaveProperty 'Size'
            $result | Should -HaveProperty 'FreeSpace'
            $result | Should -HaveProperty 'UsedSpace'
            $result | Should -HaveProperty 'UsedPercentage'
        }

        It "Should have valid disk information" {
            $result.DriveLetter | Should -Match '^[A-Z]:$'
            $result.Size | Should -Match '\d+ [KMG]B'
            $result.UsedPercentage | Should -Match '\d+(\.\d+)?%'
        }
    }

    AfterAll {
        # Nettoyer après les tests
        Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
    }
}
```

## Test d'installation et d'utilisation dans un environnement propre

Voici un script pour tester l'installation et l'utilisation du module dans un environnement propre:

```powershell
# Test-Clean-Installation.ps1

# Définir le nom du module
$ModuleName = "SysInfoModule"

# Chemin vers le module dans le répertoire des modules PowerShell
$targetPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\$ModuleName"

# Vérifier si le module est déjà installé
if (Test-Path $targetPath) {
    Write-Host "Suppression de l'installation précédente..." -ForegroundColor Yellow
    Remove-Item -Path $targetPath -Recurse -Force
}

# Créer le répertoire cible
Write-Host "Création du répertoire d'installation..." -ForegroundColor Cyan
New-Item -Path $targetPath -ItemType Directory -Force | Out-Null

# Copier les fichiers du module
Write-Host "Copie des fichiers du module..." -ForegroundColor Cyan
Copy-Item -Path ".\$ModuleName\*" -Destination $targetPath -Recurse -Force

# Vérifier que le module est disponible
Write-Host "Vérification de la disponibilité du module..." -ForegroundColor Cyan
$availableModule = Get-Module -Name $ModuleName -ListAvailable
if ($availableModule) {
    Write-Host "Module disponible à: $($availableModule.Path)" -ForegroundColor Green
}
else {
    Write-Host "ERREUR: Le module n'est pas disponible après l'installation!" -ForegroundColor Red
    exit 1
}

# Ouvrir une nouvelle session PowerShell pour tester le module
Write-Host "Test du module dans une nouvelle session PowerShell..." -ForegroundColor Cyan
$testScript = @"
Import-Module $ModuleName -Verbose
Write-Host "Module importé avec succès!" -ForegroundColor Green
Write-Host "`nInformations système:" -ForegroundColor Cyan
Get-SystemInfo | Format-List
Write-Host "`nInformations sur les disques:" -ForegroundColor Cyan
Get-DiskInfo | Format-Table -AutoSize
Write-Host "`nModule testé avec succès!" -ForegroundColor Green
pause
"@

# Enregistrer le script de test
$testScriptPath = "$env:TEMP\Test-$ModuleName.ps1"
$testScript | Out-File -FilePath $testScriptPath -Encoding utf8

# Lancer PowerShell avec le script de test
Write-Host "Exécution du test dans une nouvelle fenêtre PowerShell..." -ForegroundColor Cyan
Write-Host "Vérifiez les résultats dans la nouvelle fenêtre." -ForegroundColor Yellow
Start-Process powershell.exe -ArgumentList "-NoExit -ExecutionPolicy Bypass -File `"$testScriptPath`""
```

## Conclusion et résumé

En résumé, cet exercice a permis de mettre en place trois scripts différents pour tester notre module SysInfoModule:

1. **Test-SysInfoModule.ps1** - Un script de test complet qui vérifie la structure du module, l'installe localement, teste les commandes exportées et vérifie le bon fonctionnement des fonctions publiques.

2. **SysInfoModule.Tests.ps1** - Un script de test utilisant le framework Pester, qui offre une approche plus professionnelle et automatisée pour tester notre module.

3. **Test-Clean-Installation.ps1** - Un script qui simule l'installation du module dans un environnement propre et lance une nouvelle session PowerShell pour tester le module.

Ces tests sont essentiels pour garantir que notre module fonctionne correctement avant de le distribuer. Ils vérifient:

- La structure du module
- L'installation et la disponibilité du module
- L'exportation correcte des fonctions publiques
- Le masquage approprié des fonctions privées
- Les fonctionnalités des commandes exportées

En suivant cette approche de test, vous pouvez être sûr que votre module fonctionnera comme prévu pour les utilisateurs finaux.

# Solution Exercice Bonus: Tests unitaires avec Pester

Cet exercice bonus consiste à créer des tests unitaires pour les fonctions du module en utilisant le framework Pester.

## Structure des tests

Pour commencer, nous allons créer une structure de tests correspondant à celle de notre module:

```
SysInfoModule/
└── Tests/
    ├── Public/
    │   ├── Get-DiskInfo.Tests.ps1
    │   └── Get-SystemInfo.Tests.ps1
    └── Private/
        └── Format-Size.Tests.ps1
```

## Test de la fonction privée Format-Size

Commençons par créer les tests pour notre fonction privée Format-Size:

```powershell
# SysInfoModule/Tests/Private/Format-Size.Tests.ps1

BeforeAll {
    # Obtenir le chemin du module et charger la fonction privée pour test
    $ModulePath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $PrivateFunctionPath = Join-Path -Path $ModulePath -ChildPath "Private\Format-Size.ps1"

    # Définir une fonction pour accéder à la fonction privée
    . $PrivateFunctionPath
}

Describe "Format-Size Function Tests" {
    Context "Formatting byte sizes" {
        It "Should format bytes correctly" {
            Format-Size -Bytes 100 | Should -Be "100 B"
        }

        It "Should format kilobytes correctly" {
            Format-Size -Bytes 1024 | Should -Be "1 KB"
        }

        It "Should format megabytes correctly" {
            Format-Size -Bytes 1048576 | Should -Be "1 MB"
        }

        It "Should format gigabytes correctly" {
            Format-Size -Bytes 1073741824 | Should -Be "1 GB"
        }

        It "Should format terabytes correctly" {
            Format-Size -Bytes 1099511627776 | Should -Be "1 TB"
        }

        It "Should handle decimal values correctly" {
            Format-Size -Bytes 1572864 | Should -Be "1.5 MB"
        }

        It "Should round to two decimal places" {
            Format-Size -Bytes (1.1234 * 1024 * 1024) | Should -Be "1.12 MB"
        }
    }

    Context "Parameter validation" {
        It "Should throw when bytes parameter is missing" {
            { Format-Size } | Should -Throw
        }

        It "Should handle zero bytes" {
            Format-Size -Bytes 0 | Should -Be "0 B"
        }

        It "Should handle negative bytes" {
            { Format-Size -Bytes -1024 } | Should -Not -Throw
        }
    }
}
```

## Test de la fonction publique Get-DiskInfo

Maintenant, créons les tests pour la fonction Get-DiskInfo:

```powershell
# SysInfoModule/Tests/Public/Get-DiskInfo.Tests.ps1

BeforeAll {
    # Obtenir le chemin du module
    $ModulePath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModuleManifestPath = Join-Path -Path $ModulePath -ChildPath "SysInfoModule.psd1"

    # Importer le module
    Import-Module $ModuleManifestPath -Force
}

Describe "Get-DiskInfo Function Tests" {
    Context "Basic functionality" {
        # Créer un mock pour Get-CimInstance
        BeforeEach {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        DeviceID = 'C:'
                        VolumeName = 'OSDisk'
                        Size = 107374182400  # 100 GB
                        FreeSpace = 53687091200  # 50 GB
                        FileSystem = 'NTFS'
                    },
                    [PSCustomObject]@{
                        DeviceID = 'D:'
                        VolumeName = 'DataDisk'
                        Size = 214748364800  # 200 GB
                        FreeSpace = 107374182400  # 100 GB
                        FileSystem = 'NTFS'
                    }
                )
            } -ParameterFilter { $ClassName -eq 'Win32_LogicalDisk' }
        }

        It "Should return disk information objects" {
            $result = Get-DiskInfo
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }

        It "Should calculate used space correctly" {
            $result = Get-DiskInfo
            $cDrive = $result | Where-Object { $_.DriveLetter -eq 'C:' }
            $cDrive.UsedPercentage | Should -Be "50%"
        }

        It "Should format disk sizes correctly" {
            $result = Get-DiskInfo
            $cDrive = $result | Where-Object { $_.DriveLetter -eq 'C:' }
            $cDrive.Size | Should -Be "100 GB"
            $cDrive.FreeSpace | Should -Be "50 GB"
        }

        It "Should include all expected properties" {
            $result = Get-DiskInfo
            $result | Should -HaveProperty "ComputerName"
            $result | Should -HaveProperty "DriveLetter"
            $result | Should -HaveProperty "DriveLabel"
            $result | Should -HaveProperty "FileSystem"
            $result | Should -HaveProperty "Size"
            $result | Should -HaveProperty "FreeSpace"
            $result | Should -HaveProperty "UsedSpace"
            $result | Should -HaveProperty "UsedPercentage"
        }
    }

    Context "Remote computer functionality" {
        BeforeEach {
            Mock Get-CimInstance {
                return @(
                    [PSCustomObject]@{
                        DeviceID = 'C:'
                        VolumeName = 'OSDisk'
                        Size = 107374182400  # 100 GB
                        FreeSpace = 53687091200  # 50 GB
                        FileSystem = 'NTFS'
                    }
                )
            } -ParameterFilter { $ComputerName -eq 'RemoteServer' }
        }

        It "Should accept a ComputerName parameter" {
            $result = Get-DiskInfo -ComputerName "RemoteServer"
            $result | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Be "RemoteServer"
        }

        It "Should handle errors gracefully" {
            Mock Get-CimInstance { throw "Connection failed" } -ParameterFilter { $ComputerName -eq 'InvalidServer' }
            { Get-DiskInfo -ComputerName "InvalidServer" -ErrorAction Stop } | Should -Throw
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module SysInfoModule -ErrorAction SilentlyContinue
    }
}
```

## Test de la fonction publique Get-SystemInfo

Enfin, créons les tests pour la fonction Get-SystemInfo:

```powershell
# SysInfoModule/Tests/Public/Get-SystemInfo.Tests.ps1

BeforeAll {
    # Obtenir le chemin du module
    $ModulePath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ModuleManifestPath = Join-Path -Path $ModulePath -ChildPath "SysInfoModule.psd1"

    # Importer le module
    Import-Module $ModuleManifestPath -Force
}

Describe "Get-SystemInfo Function Tests" {
    Context "Basic functionality" {
        BeforeEach {
            # Mock pour Win32_OperatingSystem
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    Caption = "Microsoft Windows 10 Pro"
                    Version = "10.0.19042"
                    OSArchitecture = "64-bit"
                    ServicePackMajorVersion = 0
                    Manufacturer = "Microsoft Corporation"
                    TotalVisibleMemorySize = 16777216  # 16 GB en KB
                    FreePhysicalMemory = 8388608  # 8 GB en KB
                    LastBootUpTime = (Get-Date).AddDays(-1)  # 1 jour d'uptime
                }
            } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' }

            # Mock pour Win32_Processor
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    Name = "Intel(R) Core(TM) i7-10700K CPU @ 3.80GHz"
                    NumberOfCores = 8
                    NumberOfLogicalProcessors = 16
                }
            } -ParameterFilter { $ClassName -eq 'Win32_Processor' }
        }

        It "Should return a system information object" {
            $result = Get-SystemInfo
            $result | Should -Not -BeNullOrEmpty
        }

        It "Should include OS information" {
            $result = Get-SystemInfo
            $result.OSName | Should -Be "Microsoft Windows 10 Pro"
            $result.OSVersion | Should -Be "10.0.19042"
            $result.Architecture | Should -Be "x64"
        }

        It "Should include processor information" {
            $result = Get-SystemInfo
            $result.ProcessorName | Should -Be "Intel(R) Core(TM) i7-10700K CPU @ 3.80GHz"
            $result.ProcessorCores | Should -Be 8
            $result.ProcessorLogicalProcessors | Should -Be 16
        }

        It "Should include memory information" {
            $result = Get-SystemInfo
            $result.TotalMemory | Should -Be "16 GB"
            $result.FreeMemory | Should -Be "8 GB"
            $result.UsedMemory | Should -Be "8 GB"
            $result.MemoryUsedPercentage | Should -Be "50%"
        }

        It "Should calculate uptime correctly" {
            $result = Get-SystemInfo
            $result.Uptime | Should -BeLike "1 jours, * heures, * minutes"
        }

        It "Should include all expected properties" {
            $result = Get-SystemInfo
            $result | Should -HaveProperty "ComputerName"
            $result | Should -HaveProperty "OSName"
            $result | Should -HaveProperty "OSVersion"
            $result | Should -HaveProperty "Architecture"
            $result | Should -HaveProperty "ProcessorName"
            $result | Should -HaveProperty "TotalMemory"
            $result | Should -HaveProperty "Uptime"
        }
    }

    Context "Remote computer functionality" {
        BeforeEach {
            # Mock pour Win32_OperatingSystem sur ordinateur distant
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    Caption = "Microsoft Windows Server 2019"
                    Version = "10.0.17763"
                    OSArchitecture = "64-bit"
                    ServicePackMajorVersion = 0
                    Manufacturer = "Microsoft Corporation"
                    TotalVisibleMemorySize = 33554432  # 32 GB en KB
                    FreePhysicalMemory = 16777216  # 16 GB en KB
                    LastBootUpTime = (Get-Date).AddDays(-7)  # 7 jours d'uptime
                }
            } -ParameterFilter { $ClassName -eq 'Win32_OperatingSystem' -and $ComputerName -eq 'RemoteServer' }

            # Mock pour Win32_Processor sur ordinateur distant
            Mock Get-CimInstance {
                return [PSCustomObject]@{
                    Name = "Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz"
                    NumberOfCores = 16
                    NumberOfLogicalProcessors = 32
                }
            } -ParameterFilter { $ClassName -eq 'Win32_Processor' -and $ComputerName -eq 'RemoteServer' }
        }

        It "Should accept a ComputerName parameter" {
            $result = Get-SystemInfo -ComputerName "RemoteServer"
            $result | Should -Not -BeNullOrEmpty
            $result.ComputerName | Should -Be "RemoteServer"
        }

        It "Should return correct information for remote computer" {
            $result = Get-SystemInfo -ComputerName "RemoteServer"
            $result.OSName | Should -Be "Microsoft Windows Server 2019"
            $result.ProcessorName | Should -Be "Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz"
            $result.TotalMemory | Should -Be "32 GB"
        }

        It "Should handle errors gracefully" {
            Mock Get-CimInstance { throw "Connection failed" } -ParameterFilter { $ComputerName -eq 'InvalidServer' }
            { Get-SystemInfo -ComputerName "InvalidServer" -ErrorAction Stop } | Should -Throw
        }
    }

    AfterAll {
        # Nettoyer
        Remove-Module SysInfoModule -ErrorAction SilentlyContinue
    }
}
```

## Script pour exécuter tous les tests

Pour faciliter l'exécution de tous les tests, créons un script principal:

```powershell
# SysInfoModule/Tests/Run-Tests.ps1

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Le module Pester n'est pas installé. Installation en cours..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
}

# Importer Pester
Import-Module Pester

# Configurer Pester pour un affichage détaillé
$configuration = [PesterConfiguration]::Default
$configuration.Output.Verbosity = 'Detailed'
$configuration.Run.Path = $PSScriptRoot
$configuration.Run.PassThru = $true

# Exécuter les tests
Write-Host "Exécution des tests unitaires Pester pour SysInfoModule..." -ForegroundColor Cyan
$testResults = Invoke-Pester -Configuration $configuration

# Afficher un résumé
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Tests exécutés: $($testResults.TotalCount)" -ForegroundColor White
Write-Host "Tests réussis: $($testResults.PassedCount)" -ForegroundColor Green
Write-Host "Tests échoués: $($testResults.FailedCount)" -ForegroundColor Red
Write-Host "Tests ignorés: $($testResults.SkippedCount)" -ForegroundColor Yellow

# Sortir avec un code d'erreur si des tests ont échoué
if ($testResults.FailedCount -gt 0) {
    Write-Host "`nDes tests ont échoué! Consultez les détails ci-dessus." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
```

## Exécution des tests

Pour exécuter les tests, il suffit de lancer le script `Run-Tests.ps1`:

```powershell
cd SysInfoModule\Tests
.\Run-Tests.ps1
```

## Conclusion

Les tests unitaires sont essentiels pour maintenir la qualité du code et faciliter les modifications futures. Avec Pester, nous pouvons automatiser ces tests et nous assurer que notre module fonctionne comme prévu.

En complétant cette série d'exercices, vous avez créé un module PowerShell professionnel avec une structure modulaire avancée, de bonnes pratiques de conception et une suite de tests unitaires complète!






1. **Solution Exercice 1** : Création de la structure de base du module avec tous les répertoires nécessaires.

2. **Solution Exercice 2** : Ajout de fonctions publiques et privées complètes au module :
   - Une fonction privée `Format-Size` pour formater les tailles en octets
   - Deux fonctions publiques : `Get-DiskInfo` et `Get-SystemInfo`

3. **Solution Exercice 3** : Création du fichier principal `.psm1` et du manifeste `.psd1`, ainsi que du fichier README et d'exemples d'utilisation.

4. **Solution Exercice 4** : Scripts de test pour vérifier l'installation et le fonctionnement du module, comprenant :
   - Un script de vérification de la structure
   - Un script d'installation et de test local
   - Un script pour tester dans un environnement propre

5. **Solution Exercice Bonus** : Tests unitaires avec Pester pour toutes les fonctions du module :
   - Tests pour la fonction privée `Format-Size`
   - Tests pour les fonctions publiques avec des mocks pour simuler les réponses WMI
   - Un script d'exécution de tous les tests

Ces solutions offrent un exemple complet et fonctionnel de création d'un module PowerShell selon les meilleures pratiques de structuration modulaire avancée. Chaque fichier contient des scripts complets et bien commentés qui peuvent être utilisés directement dans un environnement réel.

