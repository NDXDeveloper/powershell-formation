# Solution de l'exercice - Publication de modules (PSGallery)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Cette solution vous guide étape par étape pour créer un petit module PowerShell et le préparer pour publication sur la PowerShell Gallery.

## Étape 1: Création de la structure du module

```powershell
# Définir le nom du module
$moduleName = "PSFileStats"

# Créer la structure de dossiers
$moduleRoot = New-Item -Path ".\$moduleName" -ItemType Directory -Force
$publicFolder = New-Item -Path "$moduleRoot\Public" -ItemType Directory -Force
$privateFolder = New-Item -Path "$moduleRoot\Private" -ItemType Directory -Force

# Créer les fichiers nécessaires
$null = New-Item -Path "$moduleRoot\README.md" -ItemType File -Force
$null = New-Item -Path "$moduleRoot\LICENSE" -ItemType File -Force
```

## Étape 2: Création d'une fonction publique

```powershell
# Contenu de la fonction principale - Get-FileStats
$functionContent = @'
function Get-FileStats {
    <#
    .SYNOPSIS
        Obtient des statistiques sur les fichiers dans un répertoire.

    .DESCRIPTION
        Cette fonction analyse un répertoire et fournit des statistiques sur les fichiers
        qu'il contient, comme le nombre de fichiers, leur taille totale, et la répartition
        par types de fichiers.

    .PARAMETER Path
        Le chemin du répertoire à analyser. Par défaut, utilise le répertoire courant.

    .PARAMETER Recurse
        Indique si l'analyse doit être récursive (inclure les sous-répertoires).

    .EXAMPLE
        Get-FileStats -Path C:\Documents

        Analyse le dossier C:\Documents et affiche les statistiques des fichiers.

    .EXAMPLE
        Get-FileStats -Recurse

        Analyse le répertoire courant et tous ses sous-répertoires.

    .NOTES
        Auteur: Votre Nom
        Version: 1.0.0
        Date de création: $(Get-Date -Format "yyyy-MM-dd")
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Path = (Get-Location),

        [Parameter()]
        [switch]$Recurse
    )

    begin {
        Write-Verbose "Analyse du répertoire: $Path"
        if (!(Test-Path -Path $Path -PathType Container)) {
            Write-Error "Le chemin spécifié n'est pas un répertoire valide: $Path"
            return
        }
    }

    process {
        try {
            $files = Get-ChildItem -Path $Path -File -Recurse:$Recurse -ErrorAction Stop

            # Calculer les statistiques de base
            $totalFiles = $files.Count
            $totalSize = ($files | Measure-Object -Property Length -Sum).Sum

            # Grouper par extension
            $extensionStats = $files | Group-Object -Property Extension |
                              Sort-Object -Property Count -Descending |
                              Select-Object @{Name="Extension"; Expression={if ($_.Name) {$_.Name} else {"(Sans extension)"}}},
                                           Count,
                                           @{Name="TotalSizeMB"; Expression={[math]::Round(($_.Group | Measure-Object -Property Length -Sum).Sum / 1MB, 2)}}

            # Créer l'objet de résultat
            $result = [PSCustomObject]@{
                Path = $Path
                TotalFiles = $totalFiles
                TotalSizeMB = [math]::Round($totalSize / 1MB, 2)
                LargestFile = $files | Sort-Object -Property Length -Descending | Select-Object -First 1 FullName, @{Name="SizeMB"; Expression={[math]::Round($_.Length / 1MB, 2)}}
                SmallestFile = $files | Sort-Object -Property Length | Select-Object -First 1 FullName, @{Name="SizeKB"; Expression={[math]::Round($_.Length / 1KB, 2)}}
                ExtensionStats = $extensionStats
                AnalysisDate = Get-Date
            }

            return $result
        }
        catch {
            Write-Error "Erreur lors de l'analyse des fichiers: $_"
        }
    }

    end {
        Write-Verbose "Analyse terminée pour: $Path"
    }
}
'@

# Enregistrer la fonction dans un fichier ps1
Set-Content -Path "$publicFolder\Get-FileStats.ps1" -Value $functionContent
```

## Étape 3: Création d'une fonction privée (utilitaire)

```powershell
# Contenu de la fonction privée - Format-FileSize
$privateFunction = @'
function Format-FileSize {
    <#
    .SYNOPSIS
        Convertit une taille en octets en une chaîne formatée avec l'unité appropriée.

    .DESCRIPTION
        Cette fonction interne convertit une taille donnée en octets vers une représentation
        plus lisible avec l'unité appropriée (Ko, Mo, Go, etc.).

    .PARAMETER Bytes
        Le nombre d'octets à convertir.

    .EXAMPLE
        Format-FileSize -Bytes 1024
        Retourne "1 Ko"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )

    if ($Bytes -lt 1KB) {
        return "$Bytes octets"
    }
    elseif ($Bytes -lt 1MB) {
        return "{0:N2} Ko" -f ($Bytes / 1KB)
    }
    elseif ($Bytes -lt 1GB) {
        return "{0:N2} Mo" -f ($Bytes / 1MB)
    }
    elseif ($Bytes -lt 1TB) {
        return "{0:N2} Go" -f ($Bytes / 1GB)
    }
    else {
        return "{0:N2} To" -f ($Bytes / 1TB)
    }
}
'@

# Enregistrer la fonction dans un fichier ps1
Set-Content -Path "$privateFolder\Format-FileSize.ps1" -Value $privateFunction
```

## Étape 4: Création du fichier module principal

```powershell
# Contenu du fichier PSM1 principal
$moduleContent = @'
# Importer les fonctions privées
$privateFiles = Get-ChildItem -Path "$PSScriptRoot\Private" -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $privateFiles) {
    . $file.FullName
}

# Importer et exporter les fonctions publiques
$publicFiles = Get-ChildItem -Path "$PSScriptRoot\Public" -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $publicFiles) {
    . $file.FullName
    Export-ModuleMember -Function $file.BaseName
}
'@

# Enregistrer le contenu dans le fichier PSM1
Set-Content -Path "$moduleRoot\$moduleName.psm1" -Value $moduleContent
```

## Étape 5: Création du manifeste de module

```powershell
# Générer un GUID pour le module
$moduleGuid = [Guid]::NewGuid().ToString()

# Créer le manifeste de module
$manifestParams = @{
    Path = "$moduleRoot\$moduleName.psd1"
    RootModule = "$moduleName.psm1"
    ModuleVersion = "1.0.0"
    Author = "Votre Nom"
    CompanyName = "Votre Entreprise"
    Copyright = "(c) $(Get-Date -Format 'yyyy') Votre Nom. Tous droits réservés."
    Description = "Module qui fournit des statistiques sur les fichiers dans un répertoire"
    PowerShellVersion = "5.1"
    FunctionsToExport = @('Get-FileStats')
    CmdletsToExport = @()
    AliasesToExport = @()
    VariablesToExport = @()
    Tags = @('Files', 'Statistics', 'Utility')
    ProjectUri = "https://github.com/votre-nom/PSFileStats"
    LicenseUri = "https://github.com/votre-nom/PSFileStats/blob/main/LICENSE"
}

New-ModuleManifest @manifestParams
```

## Étape 6: Création du README.md

```powershell
# Contenu du fichier README.md
$readmeContent = @'
# PSFileStats

Un module PowerShell simple pour analyser les statistiques de fichiers dans un répertoire.

## Installation

```powershell
Install-Module -Name PSFileStats
```

## Utilisation

```powershell
# Analyser le répertoire courant
Get-FileStats

# Analyser un répertoire spécifique
Get-FileStats -Path C:\Documents

# Analyser récursivement
Get-FileStats -Path C:\Projects -Recurse
```

## Fonctionnalités

- Calcul du nombre total de fichiers
- Calcul de la taille totale des fichiers
- Statistiques par type de fichier (extension)
- Identification des fichiers les plus grands et les plus petits

## Licence

Ce projet est sous licence MIT.
'@

# Enregistrer le contenu dans le fichier README.md
Set-Content -Path "$moduleRoot\README.md" -Value $readmeContent
```

## Étape 7: Création du fichier LICENSE (License MIT)

```powershell
# Contenu du fichier LICENSE (MIT)
$licenseContent = @"
MIT License

Copyright (c) $(Get-Date -Format "yyyy") Votre Nom

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@

# Enregistrer le contenu dans le fichier LICENSE
Set-Content -Path "$moduleRoot\LICENSE" -Value $licenseContent
```

## Étape 8: Test local du module

```powershell
# Tester l'importation du module
Import-Module "$moduleRoot\$moduleName.psd1" -Force -Verbose

# Vérifier que la fonction est disponible
Get-Command -Module $moduleName

# Tester la fonction
Get-FileStats -Path "$env:USERPROFILE\Documents" -Verbose
```

## Étape 9: Simuler la publication sur PowerShell Gallery

```powershell
# Définir une clé API factice pour la simulation
$apiKey = "XX_VOTRE_CLE_API_XX"

# Simuler la publication avec -WhatIf
Publish-Module -Path "$moduleRoot" -NuGetApiKey $apiKey -WhatIf -Verbose
```

## Étape 10: Instructions pour la publication réelle

Pour publier réellement le module sur PowerShell Gallery :

1. Créez un compte sur [PowerShell Gallery](https://www.powershellgallery.com/)
2. Obtenez votre clé API dans les paramètres de votre compte
3. Exécutez la commande suivante (sans le paramètre `-WhatIf`) :

```powershell
Publish-Module -Path "$moduleRoot" -NuGetApiKey "votre-clé-api-réelle" -Verbose
```

## Résumé

Ce script complet vous a permis de :
1. Créer la structure d'un module PowerShell professionnel
2. Implémenter une fonction publique avec documentation complète
3. Ajouter une fonction utilitaire privée
4. Créer le fichier module principal qui charge correctement les fonctions
5. Générer un manifeste de module complet et bien documenté
6. Préparer les fichiers README et LICENSE nécessaires
7. Tester le module localement
8. Simuler sa publication sur PowerShell Gallery

Vous pouvez maintenant adapter ce script pour créer vos propres modules et les publier sur PowerShell Gallery !
