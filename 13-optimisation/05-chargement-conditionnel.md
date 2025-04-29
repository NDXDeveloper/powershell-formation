# 14-5. Chargement conditionnel de modules

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

Le chargement conditionnel de modules est une technique d'optimisation qui permet à vos scripts PowerShell de ne charger des modules que lorsqu'ils sont réellement nécessaires. Cela peut considérablement améliorer les performances de vos scripts, notamment au démarrage.

## Pourquoi utiliser le chargement conditionnel?

Lorsque vous chargez un module avec `Import-Module`, PowerShell doit:
- Rechercher le module
- Charger tous ses fichiers en mémoire
- Exposer toutes ses commandes

Ces opérations prennent du temps et consomment des ressources. Si votre script n'utilise qu'occasionnellement certains modules, il est plus efficace de les charger uniquement lorsque nécessaire.

## Techniques de chargement conditionnel

### 1. Vérification de l'existence du module avant chargement

```powershell
# Vérifier si le module existe avant de le charger
if (Get-Module -ListAvailable -Name "NomDuModule") {
    Import-Module "NomDuModule"
} else {
    Write-Warning "Le module 'NomDuModule' n'est pas installé. Certaines fonctionnalités ne seront pas disponibles."
}
```

### 2. Chargement dans une fonction

Une technique très efficace consiste à placer l'importation du module à l'intérieur de la fonction qui en a besoin:

```powershell
function Get-UserDetails {
    # Le module n'est chargé que lorsque cette fonction est appelée
    Import-Module ActiveDirectory

    # Utilisation du module
    Get-ADUser -Filter * -Properties *
}
```

Cette approche garantit que le module n'est chargé que si la fonction est réellement appelée.

### 3. Chargement selon une condition

Vous pouvez également charger des modules en fonction de certaines conditions:

```powershell
# Charger un module uniquement si le script s'exécute sur Windows
if ($PSVersionTable.Platform -eq 'Win32NT' -or $null -eq $PSVersionTable.Platform) {
    Import-Module WindowsOnly
}

# Charger un module uniquement si l'utilisateur est administrateur
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Import-Module AdminTools
}
```

### 4. Utilisation de Try/Catch pour gérer les erreurs

```powershell
try {
    Import-Module SpecialModule -ErrorAction Stop
    $moduleLoaded = $true
} catch {
    Write-Warning "Impossible de charger le module SpecialModule: $_"
    $moduleLoaded = $false
}

# Plus tard dans le script
if ($moduleLoaded) {
    # Exécuter du code qui utilise le module
}
```

## Bonnes pratiques

### Vérifier que le module n'est pas déjà chargé

Pour éviter de recharger inutilement un module:

```powershell
if (-not (Get-Module -Name "MonModule")) {
    Import-Module "MonModule"
}
```

### Utiliser des variables pour stocker l'état de chargement

```powershell
$script:modulesDisponibles = @{
    "ActiveDirectory" = $false
    "AzureAD" = $false
}

# Fonction pour charger un module seulement s'il est nécessaire
function Load-ModuleIfNeeded {
    param([string]$ModuleName)

    if (-not $script:modulesDisponibles[$ModuleName]) {
        if (Get-Module -ListAvailable -Name $ModuleName) {
            Import-Module $ModuleName
            $script:modulesDisponibles[$ModuleName] = $true
            return $true
        } else {
            Write-Warning "Le module $ModuleName n'est pas disponible"
            return $false
        }
    }
    return $true
}

# Utilisation
function Do-SomethingWithAD {
    if (Load-ModuleIfNeeded -ModuleName "ActiveDirectory") {
        # Faire quelque chose avec Active Directory
        Get-ADUser -Filter *
    }
}
```

### Charger uniquement les commandes nécessaires

Depuis PowerShell 3.0, vous pouvez importer seulement certaines commandes d'un module:

```powershell
# Au lieu d'importer tout le module
# Import-Module ActiveDirectory

# Importez uniquement les commandes dont vous avez besoin
Import-Module ActiveDirectory -CommandName Get-ADUser, New-ADUser
```

## Exemple concret: Script de maintenance système

Voici un exemple concret où le chargement conditionnel améliore les performances:

```powershell
function Test-NetworkConnectivity {
    # Charge le module DnsClient uniquement si nécessaire
    Import-Module DnsClient
    Test-Connection -ComputerName "google.com" -Count 1 -Quiet
}

function Get-SystemStats {
    # Ne charge le module CimCmdlets que si on l'utilise vraiment
    Import-Module CimCmdlets
    Get-CimInstance -ClassName Win32_OperatingSystem
}

function Backup-UserFiles {
    param($BackupPath)
    # Charge le module de compression uniquement si on fait un backup
    Import-Module Microsoft.PowerShell.Archive
    Compress-Archive -Path "$env:USERPROFILE\Documents" -DestinationPath $BackupPath
}

# Menu principal
$choice = Read-Host "Choisissez une action: 1) Tester réseau, 2) Stats système, 3) Backup"

switch ($choice) {
    "1" { Test-NetworkConnectivity }
    "2" { Get-SystemStats }
    "3" { Backup-UserFiles -BackupPath "C:\Backup\docs.zip" }
    default { Write-Host "Choix non valide" }
}
```

Dans ce script, chaque module n'est chargé que si l'utilisateur sélectionne la fonction correspondante, ce qui rend l'exécution plus rapide.

## Conclusion

Le chargement conditionnel de modules est une technique d'optimisation puissante qui permet à vos scripts PowerShell de:
- Démarrer plus rapidement
- Utiliser moins de mémoire
- S'adapter aux environnements où certains modules pourraient ne pas être disponibles

En ne chargeant les modules que lorsqu'ils sont nécessaires, vous rendez vos scripts plus efficaces et plus robustes.

---

**💡 Astuce pour débutants**: Essayez de mesurer la différence de performance en utilisant `Measure-Command` pour comparer un script qui charge tous les modules au début et un autre qui utilise le chargement conditionnel.

⏭️ [Module 15 – Architecture & design de scripts pro](/14-architecture/README.md)
