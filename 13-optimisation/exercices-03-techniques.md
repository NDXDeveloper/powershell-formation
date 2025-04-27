 
# Solution Exercice 2 - Comparaison de performance

## Énoncé de l'exercice
Écrire un script qui compare la performance entre :
1. Obtenir la taille de tous les fichiers .log dans C:\Windows\Logs avec et sans filtrage natif
2. Obtenir la liste des applications installées via WMI vs via le registre

## Solution complète

```powershell
<#
.SYNOPSIS
    Script de comparaison des performances pour les techniques d'optimisation PowerShell.
.DESCRIPTION
    Ce script mesure et compare les performances de différentes approches pour:
    1. Trouver des fichiers .log (avec et sans filtrage natif)
    2. Obtenir la liste des applications installées (via WMI vs registre)
.NOTES
    Auteur: Formation PowerShell
    Date: 27/04/2025
#>

# Fonction pour afficher les résultats de performance avec formatage
function Show-PerformanceComparison {
    param (
        [Parameter(Mandatory)]
        [string]$Title,

        [Parameter(Mandatory)]
        [TimeSpan]$Method1Time,

        [Parameter(Mandatory)]
        [string]$Method1Name,

        [Parameter(Mandatory)]
        [TimeSpan]$Method2Time,

        [Parameter(Mandatory)]
        [string]$Method2Name
    )

    $difference = [math]::Abs($Method1Time.TotalMilliseconds - $Method2Time.TotalMilliseconds)
    $percentFaster = if ($Method1Time.TotalMilliseconds -gt $Method2Time.TotalMilliseconds) {
        ($difference / $Method1Time.TotalMilliseconds) * 100
    } else {
        ($difference / $Method2Time.TotalMilliseconds) * 100
    }

    $fasterMethod = if ($Method1Time.TotalMilliseconds -lt $Method2Time.TotalMilliseconds) {
        $Method1Name
    } else {
        $Method2Name
    }

    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "$Title" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "$Method1Name : $($Method1Time.TotalMilliseconds) ms" -ForegroundColor Yellow
    Write-Host "$Method2Name : $($Method2Time.TotalMilliseconds) ms" -ForegroundColor Yellow
    Write-Host "-------------------------------------" -ForegroundColor White
    Write-Host "La méthode '$fasterMethod' est environ $('{0:N2}' -f $percentFaster)% plus rapide" -ForegroundColor Green
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host ""
}

#region TEST 1: Fichiers .log - Comparaison des méthodes de filtrage
Write-Host "COMPARAISON 1: Trouver des fichiers .log" -ForegroundColor Magenta
Write-Host "Exécution en cours, veuillez patienter..." -ForegroundColor Yellow

# Méthode 1: Sans filtrage natif (inefficace)
$logFilesNonOptimized = Measure-Command {
    $result1 = Get-ChildItem -Path "C:\Windows\Logs" -Recurse |
               Where-Object { $_.Extension -eq ".log" }

    # Calculer la taille totale
    $totalSize1 = ($result1 | Measure-Object -Property Length -Sum).Sum
}

# Méthode 2: Avec filtrage natif (optimisée)
$logFilesOptimized = Measure-Command {
    $result2 = Get-ChildItem -Path "C:\Windows\Logs" -Filter "*.log" -Recurse

    # Calculer la taille totale
    $totalSize2 = ($result2 | Measure-Object -Property Length -Sum).Sum
}

# Afficher les résultats de la comparaison 1
Show-PerformanceComparison -Title "Recherche de fichiers .log" `
                          -Method1Time $logFilesNonOptimized `
                          -Method1Name "Sans filtrage natif" `
                          -Method2Time $logFilesOptimized `
                          -Method2Name "Avec filtrage natif"
#endregion

#region TEST 2: Applications installées - WMI vs Registre
Write-Host "COMPARAISON 2: Liste des applications installées" -ForegroundColor Magenta
Write-Host "Exécution en cours, veuillez patienter..." -ForegroundColor Yellow

# Méthode 1: Via WMI (plus lent)
$wmiMethod = Measure-Command {
    $appsWMI = Get-CimInstance -ClassName Win32_Product |
              Select-Object Name, Vendor, Version
}

# Méthode 2: Via le registre (plus rapide)
$registryMethod = Measure-Command {
    # Chemins du registre pour les applications installées
    $regPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    # Récupérer les informations des applications depuis le registre
    $appsRegistry = Get-ItemProperty -Path $regPaths |
                  Where-Object { $_.DisplayName -ne $null } |
                  Select-Object DisplayName, Publisher, DisplayVersion
}

# Afficher les résultats de la comparaison 2
Show-PerformanceComparison -Title "Obtention des applications installées" `
                          -Method1Time $wmiMethod `
                          -Method1Name "Via WMI (Get-CimInstance)" `
                          -Method2Time $registryMethod `
                          -Method2Name "Via le registre"
#endregion

#region AFFICHAGE DES RECOMMANDATIONS
Write-Host "RECOMMANDATIONS BASÉES SUR LES RÉSULTATS:" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""

Write-Host "✅ POUR LA RECHERCHE DE FICHIERS:" -ForegroundColor Green
Write-Host "Privilégiez toujours le filtrage natif avec le paramètre -Filter quand c'est possible."
Write-Host "Le filtrage via Where-Object charge tous les fichiers en mémoire avant le filtrage."
Write-Host ""

Write-Host "✅ POUR L'INVENTAIRE DES APPLICATIONS:" -ForegroundColor Green
Write-Host "Préférez utiliser le registre plutôt que WMI/CIM pour lister les applications installées."
Write-Host "Win32_Product est particulièrement lent car il vérifie l'état de chaque application."
Write-Host ""

Write-Host "CONSEIL BONUS: Pour de meilleures performances avec le registre, ciblez uniquement les propriétés nécessaires:" -ForegroundColor Yellow
Write-Host 'Get-ItemProperty -Path $regPaths | Select-Object DisplayName, Publisher -Property DisplayName, Publisher'
Write-Host ""
#endregion

#region RÉSUMÉ DES DIFFÉRENCES DE SYNTAXE
$syntaxTable = @"
+------------------------+----------------------------------------------+-------------------------------------------+
| OPÉRATION              | MÉTHODE NON OPTIMISÉE                        | MÉTHODE OPTIMISÉE                         |
+------------------------+----------------------------------------------+-------------------------------------------+
| Recherche de fichiers  | Get-ChildItem -Path "C:\..." -Recurse |      | Get-ChildItem -Path "C:\..." -Filter      |
|                        | Where-Object { `$_.Extension -eq ".log" }    | "*.log" -Recurse                          |
+------------------------+----------------------------------------------+-------------------------------------------+
| Liste des applications | Get-CimInstance -ClassName Win32_Product |   | Get-ItemProperty -Path "HKLM:\Software\..." |
|                        | Select-Object Name, Vendor, Version          | Select-Object DisplayName, Publisher      |
+------------------------+----------------------------------------------+-------------------------------------------+
"@

Write-Host "AIDE-MÉMOIRE: SYNTAXES OPTIMISÉES VS NON OPTIMISÉES" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host $syntaxTable
#endregion
```

## Explication de la solution

### 1. Comparaison pour la recherche de fichiers .log

#### Méthode non optimisée :
```powershell
Get-ChildItem -Path "C:\Windows\Logs" -Recurse | Where-Object { $_.Extension -eq ".log" }
```
- Récupère **tous** les fichiers et dossiers
- Filtre ensuite avec `Where-Object` (en mémoire)

#### Méthode optimisée :
```powershell
Get-ChildItem -Path "C:\Windows\Logs" -Filter "*.log" -Recurse
```
- Filtre directement au niveau du système de fichiers
- Ne charge en mémoire que les fichiers .log

### 2. Comparaison pour la liste des applications installées

#### Méthode WMI (plus lente) :
```powershell
Get-CimInstance -ClassName Win32_Product | Select-Object Name, Vendor, Version
```
- Utilise WMI/CIM qui est généralement plus lent
- La classe Win32_Product vérifie également l'intégrité des installations

#### Méthode Registre (plus rapide) :
```powershell
$regPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
Get-ItemProperty -Path $regPaths | Where-Object { $_.DisplayName -ne $null }
```
- Accède directement au registre
- Évite le traitement lourd de WMI/CIM

### Points forts de la solution

1. **Fonction de comparaison réutilisable** - Calcule et affiche automatiquement la différence de performance
2. **Format visuel clair** - Utilise des couleurs pour mettre en évidence les résultats importants
3. **Recommandations explicites** - Fournit des conseils basés sur les résultats
4. **Tableau aide-mémoire** - Résume les différences de syntaxe entre méthodes optimisées et non optimisées

Cette solution peut être utilisée comme outil pédagogique pour démontrer concrètement l'impact des techniques d'optimisation sur différents types d'opérations PowerShell.
