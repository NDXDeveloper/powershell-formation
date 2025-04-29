### Solutions des exercices pratiques

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

#### 1. Exercice de base : Amélioration d'un script existant

Prenons un script mal structuré et améliorons-le selon les bonnes pratiques.

**Script original (mal structuré) :**

```powershell
# Script pour trouver les gros fichiers
$path = "C:\Temp"
$mb = 100
$files = get-childitem $path -recurse | where {$_.length -gt $mb*1024*1024} | sort length -desc
$files | ft name,@{l="Size(MB)";e={[math]::Round($_.length/1MB,2)}},directoryname
$sum = ($files | measure length -sum).sum / 1MB
write-host "Total: $sum MB"
if($files.count -gt 0) {
foreach($f in $files) {
if($f.length -gt 1000000000) {
write-host "Fichier très grand trouvé : $($f.fullname)" -fore red
}
}
}
```

**Script amélioré :**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Recherche les fichiers dépassant une taille spécifiée.
.DESCRIPTION
    Ce script parcourt un répertoire et identifie les fichiers dont la taille
    dépasse un seuil défini. Il affiche un rapport détaillé et met en évidence
    les fichiers particulièrement volumineux.
.PARAMETER Path
    Chemin du dossier à analyser. Par défaut: C:\Temp
.PARAMETER MinSizeMB
    Taille minimale en MB pour qu'un fichier soit inclus dans les résultats. Par défaut: 100 MB
.EXAMPLE
    .\Find-LargeFiles.ps1 -Path "D:\Documents" -MinSizeMB 250
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$Path = "C:\Temp",

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 10000)]
    [int]$MinSizeMB = 100
)

#region Fonctions

function Write-ColorOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [System.ConsoleColor]$ForegroundColor = [System.ConsoleColor]::White
    )

    Write-Host $Message -ForegroundColor $ForegroundColor
}

function Format-FileSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [long]$SizeInBytes
    )

    if ($SizeInBytes -ge 1TB) {
        return "{0:N2} TB" -f ($SizeInBytes / 1TB)
    }
    elseif ($SizeInBytes -ge 1GB) {
        return "{0:N2} GB" -f ($SizeInBytes / 1GB)
    }
    else {
        return "{0:N2} MB" -f ($SizeInBytes / 1MB)
    }
}

#endregion

#region Initialisation

$MinSizeBytes = $MinSizeMB * 1MB
Write-Verbose "Recherche des fichiers de plus de $MinSizeMB MB dans le dossier '$Path'..."

#endregion

#region Traitement principal

try {
    # Recherche des fichiers dépassant la taille spécifiée
    $largeFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction Continue |
                  Where-Object { $_.Length -gt $MinSizeBytes } |
                  Sort-Object Length -Descending

    # Calcul des statistiques
    $totalSize = ($largeFiles | Measure-Object -Property Length -Sum).Sum
    $fileCount = $largeFiles.Count

    # Affichage des résultats
    if ($fileCount -gt 0) {
        Write-ColorOutput "Fichiers trouvés : $fileCount" -ForegroundColor Cyan
        Write-ColorOutput "Taille totale : $(Format-FileSize -SizeInBytes $totalSize)" -ForegroundColor Cyan

        # Création d'un tableau formaté pour l'affichage
        $largeFiles | Select-Object Name,
                               @{Name="Taille"; Expression={Format-FileSize -SizeInBytes $_.Length}},
                               LastWriteTime,
                               @{Name="Dossier"; Expression={$_.DirectoryName}} |
                     Format-Table -AutoSize

        # Mise en évidence des fichiers particulièrement volumineux (> 1 GB)
        $veryLargeFiles = $largeFiles | Where-Object { $_.Length -gt 1GB }
        if ($veryLargeFiles.Count -gt 0) {
            Write-ColorOutput "`nFichiers particulièrement volumineux (> 1 GB) :" -ForegroundColor Yellow

            foreach ($file in $veryLargeFiles) {
                Write-ColorOutput ("• {0} ({1})" -f $file.FullName, (Format-FileSize -SizeInBytes $file.Length)) -ForegroundColor Red
            }
        }
    }
    else {
        Write-ColorOutput "Aucun fichier de plus de $MinSizeMB MB trouvé dans '$Path'." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Une erreur est survenue lors de la recherche des fichiers : $_"
    exit 1
}

#endregion
```

#### 2. Exercice intermédiaire : Conversion de fonctions en module structuré

Voici un exemple de conversion de plusieurs fonctions liées à la gestion des processus en un module bien structuré.

**Structure du module :**

```
ProcessManager/
├── ProcessManager.psd1          # Manifeste du module
├── ProcessManager.psm1          # Fichier principal du module
│
├── Public/                      # Fonctions publiques
│   ├── Get-ProcessDetails.ps1
│   ├── Stop-ProcessSafely.ps1
│   └── Restart-ProcessSafely.ps1
│
├── Private/                     # Fonctions privées
│   ├── Format-ProcessOutput.ps1
│   └── Test-ProcessElevation.ps1
```

**Contenu des fichiers :**

1. **ProcessManager.psm1**

```powershell
# ProcessManager.psm1 - Module principal

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

# Définir la configuration du module avec une variable de script
$script:configProcessManager = @{
    DefaultTimeout = 30
    MaxRetries = 3
    LogLevel = "INFO"
    LogPath = Join-Path -Path $env:TEMP -ChildPath "ProcessManager.log"
}

# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function $publicFunctions
```

2. **Private/Format-ProcessOutput.ps1**

```powershell
# Fonction interne pour formater les informations des processus
function Format-ProcessOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Diagnostics.Process]$Process,

        [Parameter()]
        [switch]$IncludeMemoryDetails,

        [Parameter()]
        [switch]$IncludeTimingInfo
    )

    process {
        # Créer l'objet de base
        $result = [PSCustomObject]@{
            ProcessId = $Process.Id
            Name = $Process.ProcessName
            Status = if ($Process.Responding) { "Responding" } else { "Not Responding" }
            CPUPercent = $null  # Nous pourrions calculer cela avec des mesures supplémentaires
            WindowTitle = $Process.MainWindowTitle
            Path = try { $Process.MainModule.FileName } catch { "N/A (Access Denied)" }
        }

        # Ajouter les détails de mémoire si demandé
        if ($IncludeMemoryDetails) {
            Add-Member -InputObject $result -MemberType NoteProperty -Name "WorkingSetMB" -Value ([Math]::Round($Process.WorkingSet64 / 1MB, 2))
            Add-Member -InputObject $result -MemberType NoteProperty -Name "PrivateMemoryMB" -Value ([Math]::Round($Process.PrivateMemorySize64 / 1MB, 2))
            Add-Member -InputObject $result -MemberType NoteProperty -Name "VirtualMemoryMB" -Value ([Math]::Round($Process.VirtualMemorySize64 / 1MB, 2))
        }

        # Ajouter les informations de temps si demandé
        if ($IncludeTimingInfo) {
            Add-Member -InputObject $result -MemberType NoteProperty -Name "StartTime" -Value (try { $Process.StartTime } catch { Get-Date -Date "01/01/1970" })
            Add-Member -InputObject $result -MemberType NoteProperty -Name "RunTimeMinutes" -Value (try { [Math]::Round(((Get-Date) - $Process.StartTime).TotalMinutes, 1) } catch { 0 })
        }

        return $result
    }
}
```

3. **Private/Test-ProcessElevation.ps1**

```powershell
# Fonction interne pour vérifier si le processus PowerShell actuel est élevé
function Test-ProcessElevation {
    [CmdletBinding()]
    param()

    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    $adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

    return $principal.IsInRole($adminRole)
}
```

4. **Public/Get-ProcessDetails.ps1**

```powershell
<#
.SYNOPSIS
    Récupère des informations détaillées sur les processus en cours d'exécution.
.DESCRIPTION
    Cette fonction retourne des informations détaillées sur les processus spécifiés
    ou sur tous les processus en cours d'exécution sur l'ordinateur local.
.PARAMETER Name
    Nom du processus à rechercher. Accepte les caractères génériques.
.PARAMETER Id
    ID du processus à rechercher.
.PARAMETER IncludeMemoryDetails
    Inclut des détails sur l'utilisation de la mémoire par le processus.
.PARAMETER IncludeTimingInfo
    Inclut des informations sur le temps d'exécution du processus.
.EXAMPLE
    Get-ProcessDetails -Name "chrome" -IncludeMemoryDetails
.EXAMPLE
    Get-ProcessDetails -Id 1234 -IncludeTimingInfo
#>
function Get-ProcessDetails {
    [CmdletBinding(DefaultParameterSetName="ByName")]
    param(
        [Parameter(ParameterSetName="ByName", Position=0)]
        [string[]]$Name = "*",

        [Parameter(ParameterSetName="ById", Mandatory=$true)]
        [int[]]$Id,

        [Parameter()]
        [switch]$IncludeMemoryDetails,

        [Parameter()]
        [switch]$IncludeTimingInfo
    )

    try {
        # Obtenir les processus selon le jeu de paramètres
        $processes = if ($PSCmdlet.ParameterSetName -eq "ByName") {
            Get-Process -Name $Name -ErrorAction Stop
        } else {
            Get-Process -Id $Id -ErrorAction Stop
        }

        # Formater la sortie en utilisant notre fonction interne
        $processes | Format-ProcessOutput -IncludeMemoryDetails:$IncludeMemoryDetails -IncludeTimingInfo:$IncludeTimingInfo
    }
    catch {
        Write-Error "Erreur lors de la récupération des processus : $_"
    }
}
```

5. **Public/Stop-ProcessSafely.ps1**

```powershell
<#
.SYNOPSIS
    Arrête un processus de manière sécurisée.
.DESCRIPTION
    Cette fonction tente d'arrêter un processus de façon gracieuse avant de le forcer
    si nécessaire. Elle inclut des mécanismes de nouvelle tentative et de validation.
.PARAMETER Name
    Nom du processus à arrêter. Accepte les caractères génériques.
.PARAMETER Id
    ID du processus à arrêter.
.PARAMETER Timeout
    Temps d'attente en secondes avant de forcer l'arrêt. Par défaut: 30 secondes.
.PARAMETER Force
    Force l'arrêt du processus sans attendre qu'il se termine naturellement.
.EXAMPLE
    Stop-ProcessSafely -Name "notepad" -Timeout 10
.EXAMPLE
    Stop-ProcessSafely -Id 1234 -Force
#>
function Stop-ProcessSafely {
    [CmdletBinding(DefaultParameterSetName="ByName", SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [Parameter(ParameterSetName="ByName", Position=0, Mandatory=$true)]
        [string[]]$Name,

        [Parameter(ParameterSetName="ById", Mandatory=$true)]
        [int[]]$Id,

        [Parameter()]
        [int]$Timeout = $script:configProcessManager.DefaultTimeout,

        [Parameter()]
        [switch]$Force
    )

    try {
        # Vérifier si nous avons des privilèges administratifs pour certains processus
        $isElevated = Test-ProcessElevation
        if (-not $isElevated) {
            Write-Warning "Le processus PowerShell n'est pas exécuté avec des privilèges élevés. Certains processus pourraient ne pas être arrêtés."
        }

        # Obtenir les processus selon le jeu de paramètres
        $processes = if ($PSCmdlet.ParameterSetName -eq "ByName") {
            Get-Process -Name $Name -ErrorAction Stop
        } else {
            Get-Process -Id $Id -ErrorAction Stop
        }

        # Traiter chaque processus
        foreach ($process in $processes) {
            if ($PSCmdlet.ShouldProcess($process.Name + " (ID: $($process.Id))", "Stop Process")) {
                Write-Verbose "Tentative d'arrêt du processus $($process.Name) (ID: $($process.Id))"

                # Si -Force est utilisé, arrêter le processus immédiatement
                if ($Force) {
                    $process | Stop-Process -Force
                    Write-Verbose "Processus $($process.Name) (ID: $($process.Id)) arrêté de force."
                }
                else {
                    # Essayer de fermer gracieusement
                    if ($process.CloseMainWindow()) {
                        # Attendre que le processus se termine
                        if ($process.WaitForExit($Timeout * 1000)) {
                            Write-Verbose "Processus $($process.Name) (ID: $($process.Id)) arrêté gracieusement."
                        }
                        else {
                            # Si le timeout est atteint, forcer l'arrêt
                            Write-Warning "Le processus $($process.Name) (ID: $($process.Id)) n'a pas répondu dans le délai imparti. Arrêt forcé."
                            $process | Stop-Process -Force
                        }
                    }
                    else {
                        # Si CloseMainWindow échoue ou n'est pas applicable, utiliser Stop-Process
                        Write-Verbose "Impossible d'utiliser CloseMainWindow pour $($process.Name). Utilisation de Stop-Process."
                        $process | Stop-Process
                    }
                }

                # Vérifier si le processus est toujours en cours d'exécution
                try {
                    $stillRunning = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
                    if ($stillRunning) {
                        Write-Error "Impossible d'arrêter le processus $($process.Name) (ID: $($process.Id))"
                    }
                    else {
                        Write-Output "Processus $($process.Name) (ID: $($process.Id)) arrêté avec succès."
                    }
                }
                catch {
                    # Si Get-Process échoue, c'est probablement parce que le processus n'existe plus
                    Write-Output "Processus $($process.Name) (ID: $($process.Id)) arrêté avec succès."
                }
            }
        }
    }
    catch {
        Write-Error "Erreur lors de l'arrêt des processus : $_"
    }
}
```

6. **Public/Restart-ProcessSafely.ps1**

```powershell
<#
.SYNOPSIS
    Redémarre un processus de manière sécurisée.
.DESCRIPTION
    Cette fonction arrête un processus existant, puis le redémarre avec
    les mêmes arguments de ligne de commande si possible.
.PARAMETER Name
    Nom du processus à redémarrer.
.PARAMETER Id
    ID du processus à redémarrer.
.PARAMETER Wait
    Temps d'attente en secondes avant de démarrer le nouveau processus.
.PARAMETER UseOriginalCommandLine
    Tente de redémarrer le processus avec les mêmes arguments de ligne de commande.
.EXAMPLE
    Restart-ProcessSafely -Name "notepad" -Wait 2
.NOTES
    Cette fonction nécessite des privilèges élevés pour certains processus.
#>
function Restart-ProcessSafely {
    [CmdletBinding(DefaultParameterSetName="ByName", SupportsShouldProcess=$true, ConfirmImpact='High')]
    param(
        [Parameter(ParameterSetName="ByName", Position=0, Mandatory=$true)]
        [string]$Name,

        [Parameter(ParameterSetName="ById", Mandatory=$true)]
        [int]$Id,

        [Parameter()]
        [int]$Wait = 2,

        [Parameter()]
        [switch]$UseOriginalCommandLine
    )

    try {
        # Obtenir le processus
        $process = if ($PSCmdlet.ParameterSetName -eq "ByName") {
            Get-Process -Name $Name -ErrorAction Stop
        } else {
            Get-Process -Id $Id -ErrorAction Stop
        }

        # S'il y a plusieurs processus avec le même nom, prendre le premier
        if ($process -is [array]) {
            Write-Warning "Plusieurs processus trouvés avec le nom '$Name'. Utilisation du premier."
            $process = $process[0]
        }

        if ($PSCmdlet.ShouldProcess($process.Name + " (ID: $($process.Id))", "Restart Process")) {
            # Capturer les informations nécessaires avant d'arrêter
            $procPath = try { $process.MainModule.FileName } catch { $null }
            $procCmdLine = $null

            if ($UseOriginalCommandLine) {
                # Tenter d'obtenir la ligne de commande originale
                try {
                    # Cette partie nécessite des modules externes ou WMI
                    # Une approche simplifiée pour l'exercice
                    Write-Warning "La récupération exacte de la ligne de commande n'est pas implémentée dans cet exemple."
                }
                catch {
                    Write-Warning "Impossible de récupérer la ligne de commande originale : $_"
                }
            }

            # Arrêter le processus
            Write-Verbose "Arrêt du processus $($process.Name) (ID: $($process.Id))"
            $process | Stop-Process -Force

            # Attendre qu'il soit terminé
            try {
                $process.WaitForExit()
            }
            catch {
                # Ignorer les erreurs possibles ici
            }

            # Attendre le délai spécifié
            Start-Sleep -Seconds $Wait

            # Redémarrer si nous avons le chemin du processus
            if ($procPath) {
                Write-Verbose "Redémarrage de $procPath"
                Start-Process -FilePath $procPath
                Write-Output "Processus $($process.Name) redémarré avec succès."
            }
            else {
                Write-Error "Impossible de redémarrer le processus : chemin d'exécution non trouvé."
            }
        }
    }
    catch {
        Write-Error "Erreur lors du redémarrage du processus : $_"
    }
}
```

7. **ProcessManager.psd1** (créé avec New-ModuleManifest)

```powershell
# Pour créer le manifeste, exécutez:
New-ModuleManifest -Path "ProcessManager.psd1" `
                  -RootModule "ProcessManager.psm1" `
                  -ModuleVersion "1.0.0" `
                  -Author "Votre Nom" `
                  -Description "Module de gestion des processus Windows" `
                  -PowerShellVersion "5.1" `
                  -FunctionsToExport @("Get-ProcessDetails", "Stop-ProcessSafely", "Restart-ProcessSafely") `
                  -Tags @("processus", "gestion", "windows")
```

#### 3. Exercice avancé : Modèle réutilisable de script et module

Voici un modèle que vous pouvez réutiliser pour vos futurs projets, avec un script d'initialisation pour générer automatiquement la structure.

**Script générateur de modèle (Initialize-PowerShellProject.ps1) :**

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Crée un nouveau projet PowerShell (script ou module) avec une structure standardisée.
.DESCRIPTION
    Ce script génère automatiquement une structure de projet PowerShell selon
    les meilleures pratiques, avec des fichiers modèles déjà configurés.
.PARAMETER Name
    Nom du projet à créer.
.PARAMETER Type
    Type de projet : Script ou Module.
.PARAMETER Path
    Chemin où créer le projet. Par défaut : répertoire courant.
.PARAMETER Author
    Nom de l'auteur pour les métadonnées.
.PARAMETER Description
    Description du projet.
.EXAMPLE
    .\Initialize-PowerShellProject.ps1 -Name "MonProjet" -Type Module -Author "Jean Dupont"
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidatePattern("^[a-zA-Z0-9_-]+$")]
    [string]$Name,

    [Parameter(Mandatory=$true, Position=1)]
    [ValidateSet("Script", "Module")]
    [string]$Type,

    [Parameter()]
    [string]$Path = (Get-Location).Path,

    [Parameter()]
    [string]$Author = "$env:USERNAME",

    [Parameter()]
    [string]$Description = "Projet PowerShell créé avec Initialize-PowerShellProject"
)

#region Modèles de contenu

# Modèle pour script principal
$scriptTemplate = @'
#Requires -Version 5.1
<#
.SYNOPSIS
    Description courte du script.
.DESCRIPTION
    Description détaillée du script.
.PARAMETER Param1
    Description du premier paramètre.
.EXAMPLE
    .\{0}.ps1 -Param1 "Valeur"
.NOTES
    Auteur: {1}
    Date: {2}
    Description: {3}
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Param1 = "Valeur par défaut"
)

#region Fonctions

function Write-Log {{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp [$Level] $Message" | Out-File -FilePath $logFile -Append

    # Affichage console avec couleur
    switch ($Level) {{
        "INFO"    {{ Write-Host "$timestamp [$Level] $Message" -ForegroundColor Green }}
        "WARNING" {{ Write-Host "$timestamp [$Level] $Message" -ForegroundColor Yellow }}
        "ERROR"   {{ Write-Host "$timestamp [$Level] $Message" -ForegroundColor Red }}
    }}
}}

#endregion

#region Initialisation

$script:logFile = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "{0}.log"
Write-Log "Script démarré avec le paramètre : $Param1"

#endregion

#region Traitement principal

try {{
    # Votre code principal ici
    Write-Log "Traitement en cours..."

}}
catch {{
    Write-Log "Erreur lors de l'exécution : $_" -Level "ERROR"
}}
finally {{
    Write-Log "Script terminé"
}}

#endregion
'@

# Modèle pour module principal (.psm1)
$moduleTemplate = @'
# {0}.psm1 - Module principal

#region Configuration interne du module

# Configuration interne avec une variable de script
$script:config{0} = @{{
    DefaultTimeout = 30
    MaxRetries = 3
    LogPath = Join-Path -Path $env:TEMP -ChildPath "{0}.log"
}}

#endregion

#region Chargement des fichiers

# Charger les fonctions privées
$privateFiles = Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue
foreach ($file in $privateFiles) {{
    try {{
        . $file.FullName
        Write-Verbose "Fonction privée chargée : $($file.BaseName)"
    }}
    catch {{
        Write-Error "Impossible de charger la fonction privée $($file.FullName): $_"
    }}
}}

# Charger les fonctions publiques
$publicFiles = Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue
$publicFunctions = @()
foreach ($file in $publicFiles) {{
    try {{
        . $file.FullName
        $publicFunctions += $file.BaseName
        Write-Verbose "Fonction publique chargée : $($file.BaseName)"
    }}
    catch {{
        Write-Error "Impossible de charger la fonction publique $($file.FullName): $_"
    }}
}}

#endregion

# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function $publicFunctions
'@

# Modèle pour fonction publique d'exemple
$publicFunctionTemplate = @'
<#
.SYNOPSIS
    Description courte de la fonction.
.DESCRIPTION
    Description détaillée de cette fonction.
.PARAMETER Param1
    Description du premier paramètre.
.EXAMPLE
    Get-Something -Param1 "Valeur"
.NOTES
    Partie du module {0}
#>
function Get-Something {{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Param1
    )

    Write-Verbose "Exécution de Get-Something avec Param1 = $Param1"

    # Appel d'une fonction interne/privée
    $result = Format-Something -Input $Param1

    # Création et retour d'un objet de résultat
    [PSCustomObject]@{{
        Input = $Param1
        Output = $result
        Timestamp = Get-Date
    }}
}}
'@

# Modèle pour fonction privée d'exemple
$privateFunctionTemplate = @'
# Fonction interne pour le traitement des données
function Format-Something {{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Input
    )

    # Accès à la configuration du module
    $timeout = $script:config{0}.DefaultTimeout

    # Traitement simple pour l'exemple
    return "$Input [Traité avec timeout=$timeout]"
}}
'@

# Modèle de README.md
$readmeTemplate = @'
# {0}

## Description

{1}

## Installation

```powershell
# Clone du dépôt
git clone <url-du-depot>

# Pour un module, importation
Import-Module -Path ".\{0}\{0}.psd1"
```

## Utilisation

```powershell
# Exemple d'utilisation
{2}
```

## Structure du projet

```
{3}
```

## Auteur

{4}

## Licence

Ce projet est sous licence MIT.
'@

# Modèle de tests Pester
$pesterTestTemplate = @'
BeforeAll {{
    # Importer le module ou les fonctions à tester
    $projectRoot = (Split-Path -Parent $PSScriptRoot)

    if (Test-Path -Path "$projectRoot\{0}.psd1") {{
        Import-Module "$projectRoot\{0}.psd1" -Force
    }}
    elseif (Test-Path -Path "$projectRoot\{0}.ps1") {{
        . "$projectRoot\{0}.ps1"
    }}
}}

Describe "{0} Tests" {{
    Context "Fonctionnalités de base" {{
        It "Devrait s'exécuter sans erreur" {{
            # Exemple de test simple
            # Test simple
            $true | Should -Be $true
        }

        It "Devrait renvoyer le résultat attendu" {
            # Remplacer par un test réel de votre fonctionnalité
            $expectedResult = "Résultat attendu"
            $actualResult = "Résultat attendu"  # Remplacer par l'appel à votre fonction

            $actualResult | Should -Be $expectedResult
        }
    }

    Context "Gestion des erreurs" {
        It "Devrait gérer les entrées invalides" {
            # Exemple de test pour la gestion des erreurs
            { throw "Erreur test" } | Should -Throw
        }
    }
}
'@

#endregion

#region Fonctions

function New-ProjectStructure {
    [CmdletBinding()]
    param(
        [string]$ProjectPath,
        [string]$Type
    )

    # Créer le dossier principal du projet
    Write-Verbose "Création du dossier principal : $ProjectPath"
    New-Item -Path $ProjectPath -ItemType Directory -Force | Out-Null

    # Créer les sous-dossiers communs
    New-Item -Path "$ProjectPath\Tests" -ItemType Directory -Force | Out-Null

    # Créer la structure spécifique selon le type de projet
    if ($Type -eq "Module") {
        New-Item -Path "$ProjectPath\Public" -ItemType Directory -Force | Out-Null
        New-Item -Path "$ProjectPath\Private" -ItemType Directory -Force | Out-Null
        New-Item -Path "$ProjectPath\Data" -ItemType Directory -Force | Out-Null
    }

    # Créer le dossier .vscode avec settings
    New-Item -Path "$ProjectPath\.vscode" -ItemType Directory -Force | Out-Null

    return $ProjectPath
}

function New-ScriptFiles {
    [CmdletBinding()]
    param(
        [string]$ProjectPath,
        [string]$Name,
        [string]$Author,
        [string]$Description,
        [string]$Type
    )

    $date = Get-Date -Format "dd/MM/yyyy"

    if ($Type -eq "Script") {
        # Créer le script principal
        $scriptContent = $scriptTemplate -f $Name, $Author, $date, $Description
        $scriptPath = Join-Path -Path $ProjectPath -ChildPath "$Name.ps1"
        Set-Content -Path $scriptPath -Value $scriptContent

        # Créer le fichier de test Pester
        $testContent = $pesterTestTemplate -f $Name
        $testPath = Join-Path -Path "$ProjectPath\Tests" -ChildPath "$Name.Tests.ps1"
        Set-Content -Path $testPath -Value $testContent
    }
    else {
        # Pour un module

        # Créer le module principal (.psm1)
        $moduleContent = $moduleTemplate -f $Name
        $modulePath = Join-Path -Path $ProjectPath -ChildPath "$Name.psm1"
        Set-Content -Path $modulePath -Value $moduleContent

        # Créer le manifeste (.psd1)
        $manifestPath = Join-Path -Path $ProjectPath -ChildPath "$Name.psd1"
        New-ModuleManifest -Path $manifestPath `
                          -RootModule "$Name.psm1" `
                          -ModuleVersion "0.1.0" `
                          -Author $Author `
                          -Description $Description `
                          -PowerShellVersion "5.1" `
                          -FunctionsToExport @("Get-Something") `
                          -Tags @("template", "module")

        # Créer une fonction publique d'exemple
        $publicFuncContent = $publicFunctionTemplate -f $Name
        $publicFuncPath = Join-Path -Path "$ProjectPath\Public" -ChildPath "Get-Something.ps1"
        Set-Content -Path $publicFuncPath -Value $publicFuncContent

        # Créer une fonction privée d'exemple
        $privateFuncContent = $privateFunctionTemplate -f $Name
        $privateFuncPath = Join-Path -Path "$ProjectPath\Private" -ChildPath "Format-Something.ps1"
        Set-Content -Path $privateFuncPath -Value $privateFuncContent

        # Créer le fichier de test Pester
        $testContent = $pesterTestTemplate -f $Name
        $testPath = Join-Path -Path "$ProjectPath\Tests" -ChildPath "$Name.Tests.ps1"
        Set-Content -Path $testPath -Value $testContent
    }
}

function New-VSCodeSettings {
    [CmdletBinding()]
    param(
        [string]$ProjectPath
    )

    # Créer settings.json pour VS Code
    $settingsContent = @'
{
    "editor.formatOnSave": true,
    "powershell.codeFormatting.preset": "OTBS",
    "powershell.codeFormatting.alignPropertyValuePairs": true,
    "powershell.scriptAnalysis.enable": true,
    "powershell.pester.useLegacyCodeLens": false
}
'@

    $settingsPath = Join-Path -Path "$ProjectPath\.vscode" -ChildPath "settings.json"
    Set-Content -Path $settingsPath -Value $settingsContent

    # Créer launch.json pour le débogage
    $launchContent = @'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "PowerShell: Launch Script",
            "type": "PowerShell",
            "request": "launch",
            "script": "${workspaceFolder}\\SCRIPT_NAME.ps1",
            "args": []
        },
        {
            "name": "PowerShell: Interactive Session",
            "type": "PowerShell",
            "request": "launch",
            "cwd": "${workspaceFolder}"
        }
    ]
}
'@

    $launchPath = Join-Path -Path "$ProjectPath\.vscode" -ChildPath "launch.json"
    $launchContent = $launchContent -replace "SCRIPT_NAME", $Name
    Set-Content -Path $launchPath -Value $launchContent
}

function New-ReadmeMd {
    [CmdletBinding()]
    param(
        [string]$ProjectPath,
        [string]$Name,
        [string]$Author,
        [string]$Description,
        [string]$Type
    )

    # Déterminer l'exemple d'utilisation selon le type
    $usageExample = if ($Type -eq "Script") {
        ".\$Name.ps1 -Param1 'Valeur'"
    } else {
        "Import-Module $Name`nGet-Something -Param1 'Valeur'"
    }

    # Déterminer la structure du projet à afficher
    $projectStructure = if ($Type -eq "Script") {
@"
$Name/
├── $Name.ps1
├── Tests/
│   └── $Name.Tests.ps1
└── .vscode/
    ├── settings.json
    └── launch.json
"@
    } else {
@"
$Name/
├── $Name.psm1
├── $Name.psd1
├── Public/
│   └── Get-Something.ps1
├── Private/
│   └── Format-Something.ps1
├── Data/
├── Tests/
│   └── $Name.Tests.ps1
└── .vscode/
    ├── settings.json
    └── launch.json
"@
    }

    # Créer le contenu README.md
    $readmeContent = $readmeTemplate -f $Name, $Description, $usageExample, $projectStructure, $Author
    $readmePath = Join-Path -Path $ProjectPath -ChildPath "README.md"
    Set-Content -Path $readmePath -Value $readmeContent
}

#endregion

#region Traitement principal

try {
    $fullPath = Join-Path -Path $Path -ChildPath $Name

    # Vérifier si le dossier existe déjà
    if (Test-Path -Path $fullPath) {
        $overwrite = Read-Host "Le dossier '$Name' existe déjà. Voulez-vous l'écraser ? (O/N)"
        if ($overwrite -ne "O") {
            Write-Host "Opération annulée." -ForegroundColor Yellow
            exit
        }
    }

    # Créer la structure du projet
    Write-Host "Création de la structure du projet $Type '$Name'..." -ForegroundColor Cyan
    $projectPath = New-ProjectStructure -ProjectPath $fullPath -Type $Type

    # Créer les fichiers du projet
    Write-Host "Génération des fichiers..." -ForegroundColor Cyan
    New-ScriptFiles -ProjectPath $projectPath -Name $Name -Author $Author -Description $Description -Type $Type

    # Créer les fichiers VS Code
    Write-Host "Configuration de l'environnement VS Code..." -ForegroundColor Cyan
    New-VSCodeSettings -ProjectPath $projectPath

    # Créer le README.md
    Write-Host "Création de la documentation..." -ForegroundColor Cyan
    New-ReadmeMd -ProjectPath $projectPath -Name $Name -Author $Author -Description $Description -Type $Type

    # Afficher le résumé
    Write-Host "`nProjet '$Name' créé avec succès dans '$fullPath'`n" -ForegroundColor Green
    Write-Host "Structure du projet :" -ForegroundColor Cyan

    # Afficher l'arborescence du projet créé
    Get-ChildItem -Path $fullPath -Recurse |
        Select-Object FullName |
        ForEach-Object { $_.FullName.Replace($fullPath, $Name) } |
        ForEach-Object { $indent = "  " * ($_.Split("\").Count - 1); "$indent$($_.Split("\")[-1])" }

    Write-Host "`nPour commencer à travailler sur votre projet :" -ForegroundColor Cyan
    Write-Host "cd '$fullPath'" -ForegroundColor Yellow

    if ($Type -eq "Module") {
        Write-Host "Import-Module .\$Name.psd1 -Force" -ForegroundColor Yellow
    }
    else {
        Write-Host "code .\$Name.ps1" -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Erreur lors de la création du projet : $_"
}

#endregion
```

Ce script très complet vous permet de générer automatiquement un projet PowerShell bien structuré, que ce soit pour un script ou un module. Il crée toute l'architecture nécessaire, y compris :

1. La structure de dossiers recommandée
2. Des fichiers modèles avec une structure de base déjà en place
3. Des configurations VS Code pour une expérience de développement optimale
4. Un fichier README.md avec toutes les informations essentielles
5. Une structure de tests Pester prête à l'emploi

### Utilisation du modèle

Pour utiliser ce générateur de modèle :

```powershell
# Création d'un nouveau script
.\Initialize-PowerShellProject.ps1 -Name "MonScript" -Type Script -Author "Jean Dupont" -Description "Script qui automatise une tâche spécifique"

# Création d'un nouveau module
.\Initialize-PowerShellProject.ps1 -Name "MonModule" -Type Module -Author "Jean Dupont" -Description "Module avec fonctions pour gérer des tâches administratives"
```

Les modèles créés respectent toutes les meilleures pratiques abordées dans le cours :
- Convention de nommage Verbe-Nom pour les fonctions
- Commentaires d'aide complets
- Structure claire avec des régions bien définies
- Gestion des erreurs intégrée
- Paramétrage avec validation
- Journalisation et suivi d'exécution
- Organisation modulaire et réutilisable

Ces solutions d'exercices couvrent l'ensemble des concepts présentés dans le module 6-5 sur les meilleures pratiques de structuration et nommage en PowerShell. Elles offrent un point de départ solide pour développer des scripts et modules professionnels, maintenables et bien documentés.
