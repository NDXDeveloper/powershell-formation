<#
.SYNOPSIS
    Script récapitulatif des concepts du Module 3 de la formation PowerShell.
.DESCRIPTION
    Ce script présente et utilise les différents concepts abordés dans le Module 3 :
    - Variables, typage, tableaux, hashtables
    - Opérateurs (logiques, arithmétiques, comparaison)
    - Structures de contrôle (if, switch, for, foreach, while)
    - Expressions régulières et filtrage
    - Paramètres et fonctions
.PARAMETER Path
    Chemin du dossier à analyser.
.PARAMETER Days
    Nombre de jours pour le filtrage par date.
.PARAMETER LogExtensions
    Tableau des extensions de fichiers à considérer comme logs.
.PARAMETER GenerateReport
    Indique si un rapport doit être généré.
.EXAMPLE
    .\Module3_Recap.ps1 -Path "C:\Windows\Logs" -Days 7 -GenerateReport
.NOTES
    Auteur: Formation PowerShell
    Date  : 26/04/2025
    Version: 1.0
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$Path,

    [Parameter(Mandatory=$false)]
    [int]$Days = 30,

    [Parameter(Mandatory=$false)]
    [string[]]$LogExtensions = @(".log", ".txt", ".evt"),

    [Parameter(Mandatory=$false)]
    [switch]$GenerateReport
)

# ============================================
# SECTION 1: Variables, tableaux et hashtables
# ============================================

# Variables simples avec typage explicite
[string]$scriptName = "Module3_Recap.ps1"
[datetime]$startTime = Get-Date
[int]$fileCount = 0
[double]$totalSizeMB = 0

# Tableau pour stocker les résultats
$fileAnalysis = @()

# Hashtable pour regrouper par extension
$extensionStats = @{}

# Hashtable des mois en français pour le rapport
$monthNames = @{
    1 = "Janvier"; 2 = "Février"; 3 = "Mars"; 4 = "Avril";
    5 = "Mai"; 6 = "Juin"; 7 = "Juillet"; 8 = "Août";
    9 = "Septembre"; 10 = "Octobre"; 11 = "Novembre"; 12 = "Décembre"
}

# ============================================
# SECTION 2: Fonctions
# ============================================

function Write-ColorOutput {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ConsoleColor]$ForegroundColor = [ConsoleColor]::White
    )

    $originalColor = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    Write-Output $Message
    $host.UI.RawUI.ForegroundColor = $originalColor
}

function Get-FileSizeInMB {
    param([long]$SizeInBytes)

    return [math]::Round($SizeInBytes / 1MB, 2)
}

function Test-FileAge {
    param(
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory=$true)]
        [int]$Days
    )

    $cutoffDate = (Get-Date).AddDays(-$Days)
    return $File.LastWriteTime -gt $cutoffDate
}

function Format-FileDate {
    param([datetime]$Date)

    $day = $Date.Day
    $month = $monthNames[$Date.Month]
    $year = $Date.Year

    return "$day $month $year"
}

# ============================================
# SECTION 3: Script principal avec structures de contrôle
# ============================================

Write-ColorOutput "======================================================" -ForegroundColor Cyan
Write-ColorOutput "  ANALYSE DE FICHIERS - RÉCAPITULATIF MODULE 3" -ForegroundColor Cyan
Write-ColorOutput "======================================================" -ForegroundColor Cyan
Write-ColorOutput "Démarrage: $startTime" -ForegroundColor Gray
Write-ColorOutput "Dossier analysé: $Path" -ForegroundColor Yellow
Write-ColorOutput "Période d'analyse: $Days jours" -ForegroundColor Yellow
Write-ColorOutput "Extensions de log: $($LogExtensions -join ', ')" -ForegroundColor Yellow
Write-ColorOutput "======================================================" -ForegroundColor Cyan

# Vérification préliminaire
if (-not (Test-Path -Path $Path)) {
    Write-ColorOutput "Le dossier spécifié n'existe pas: $Path" -ForegroundColor Red
    exit 1
}

# Obtenir tous les fichiers du dossier et sous-dossiers
try {
    $allFiles = Get-ChildItem -Path $Path -Recurse -File -ErrorAction Stop
    Write-ColorOutput "Nombre total de fichiers trouvés: $($allFiles.Count)" -ForegroundColor Green
}
catch {
    Write-ColorOutput "Erreur lors de la récupération des fichiers: $_" -ForegroundColor Red
    exit 1
}

# Filtre des fichiers par date et extension (SECTION 3: Opérateurs et filtrage)
$recentFiles = $allFiles | Where-Object {
    (Test-FileAge -File $_ -Days $Days) -and
    ($_.Extension -in $LogExtensions -or $LogExtensions.Count -eq 0)
}

if ($recentFiles.Count -eq 0) {
    Write-ColorOutput "Aucun fichier ne correspond aux critères de recherche." -ForegroundColor Yellow
    exit 0
}

# Analyse des fichiers avec différentes structures de boucle
# SECTION 3: Structures de contrôle

# 1. Analyse avec foreach
Write-ColorOutput "`nAnalyse des fichiers en cours..." -ForegroundColor Cyan
$fileCount = $recentFiles.Count
$processedCount = 0

foreach ($file in $recentFiles) {
    # Mise à jour du compteur et affichage de la progression
    $processedCount++
    $progress = [math]::Round(($processedCount / $fileCount) * 100, 0)

    Write-Progress -Activity "Analyse des fichiers" -Status "$processedCount / $fileCount fichiers" `
                  -PercentComplete $progress

    # Calculs sur le fichier
    $extension = $file.Extension.ToLower()
    $sizeMB = Get-FileSizeInMB -SizeInBytes $file.Length
    $totalSizeMB += $sizeMB

    # Mise à jour des statistiques par extension (use hashtable)
    if ($extensionStats.ContainsKey($extension)) {
        $extensionStats[$extension].Count++
        $extensionStats[$extension].TotalSize += $sizeMB
    }
    else {
        $extensionStats[$extension] = @{
            Count = 1
            TotalSize = $sizeMB
        }
    }

    # Analyse du contenu pour les fichiers texte (SECTION 3: Expressions régulières)
    $contentSummary = ""
    $errorCount = 0

    if ($file.Extension -match "\.(log|txt)$" -and $file.Length -lt 1MB) {
        try {
            $content = Get-Content -Path $file.FullName -ErrorAction Stop

            # Recherche de mots-clés avec regex
            $errorMatch = $content | Select-String -Pattern "(error|exception|fail)" -CaseSensitive:$false
            $errorCount = $errorMatch.Count

            # Récupère la première ligne d'erreur s'il y en a
            if ($errorCount -gt 0) {
                $firstError = $errorMatch[0].Line
                $contentSummary = $firstError.Substring(0, [Math]::Min(50, $firstError.Length)) + "..."
            }
        }
        catch {
            $contentSummary = "Impossible de lire le fichier"
        }
    }

    # Ajout des informations du fichier à notre tableau d'analyse
    $fileAnalysis += [PSCustomObject]@{
        Name = $file.Name
        Path = $file.DirectoryName
        Extension = $extension
        SizeMB = $sizeMB
        LastModified = $file.LastWriteTime
        ErrorCount = $errorCount
        ContentSummary = $contentSummary
    }
}

# Fin de la barre de progression
Write-Progress -Activity "Analyse des fichiers" -Completed

# Affichage des résultats avec switch
Write-ColorOutput "`nRésultats de l'analyse:" -ForegroundColor Green
Write-ColorOutput "Nombre de fichiers analysés: $fileCount" -ForegroundColor White
Write-ColorOutput "Taille totale: $([math]::Round($totalSizeMB, 2)) MB" -ForegroundColor White

# Utilisation de switch pour les catégories de taille
Write-ColorOutput "`nRépartition par taille:" -ForegroundColor Magenta

$sizeCategories = @{
    "Très petits (< 0.1 MB)" = 0
    "Petits (0.1 - 1 MB)" = 0
    "Moyens (1 - 10 MB)" = 0
    "Grands (10 - 100 MB)" = 0
    "Très grands (> 100 MB)" = 0
}

foreach ($file in $fileAnalysis) {
    switch ($file.SizeMB) {
        {$_ -lt 0.1} { $sizeCategories["Très petits (< 0.1 MB)"]++; break }
        {$_ -lt 1} { $sizeCategories["Petits (0.1 - 1 MB)"]++; break }
        {$_ -lt 10} { $sizeCategories["Moyens (1 - 10 MB)"]++; break }
        {$_ -lt 100} { $sizeCategories["Grands (10 - 100 MB)"]++; break }
        default { $sizeCategories["Très grands (> 100 MB)"]++ }
    }
}

foreach ($category in $sizeCategories.Keys) {
    $count = $sizeCategories[$category]
    $percentage = [math]::Round(($count / $fileCount) * 100, 1)
    Write-ColorOutput "  $category : $count fichiers ($percentage%)" -ForegroundColor White
}

# Utilisation de for pour afficher les extensions
Write-ColorOutput "`nRépartition par extension:" -ForegroundColor Magenta

$sortedExtensions = $extensionStats.Keys | Sort-Object
for ($i = 0; $i -lt $sortedExtensions.Count; $i++) {
    $extension = $sortedExtensions[$i]
    $count = $extensionStats[$extension].Count
    $size = [math]::Round($extensionStats[$extension].TotalSize, 2)
    $percentage = [math]::Round(($count / $fileCount) * 100, 1)

    Write-ColorOutput "  $extension : $count fichiers ($percentage%) - $size MB" -ForegroundColor White
}

# Utilisation de while pour afficher les fichiers avec erreurs
Write-ColorOutput "`nFichiers contenant des erreurs:" -ForegroundColor Magenta

$errorFiles = $fileAnalysis | Where-Object { $_.ErrorCount -gt 0 } | Sort-Object -Property ErrorCount -Descending
$i = 0
$maxDisplay = [Math]::Min(5, $errorFiles.Count)

while ($i -lt $maxDisplay) {
    $file = $errorFiles[$i]
    Write-ColorOutput "  $($file.Name) - $($file.ErrorCount) erreurs - $($file.ContentSummary)" -ForegroundColor Yellow
    $i++
}

if ($errorFiles.Count -gt $maxDisplay) {
    Write-ColorOutput "  ... et $($errorFiles.Count - $maxDisplay) autres fichiers avec erreurs." -ForegroundColor Yellow
}
elseif ($errorFiles.Count -eq 0) {
    Write-ColorOutput "  Aucun fichier avec erreurs détecté." -ForegroundColor Green
}

# Génération du rapport (paramètre switch)
if ($GenerateReport) {
    $reportPath = Join-Path -Path (Get-Location) -ChildPath "Rapport_Fichiers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

    try {
        $fileAnalysis | Export-Csv -Path $reportPath -NoTypeInformation -Delimiter ";" -Encoding UTF8
        Write-ColorOutput "`nRapport généré avec succès: $reportPath" -ForegroundColor Green
    }
    catch {
        Write-ColorOutput "`nErreur lors de la génération du rapport: $_" -ForegroundColor Red
    }
}

# Affichage du temps d'exécution
$executionTime = (Get-Date) - $startTime
Write-ColorOutput "`nTemps d'exécution: $($executionTime.Minutes) min $($executionTime.Seconds) sec" -ForegroundColor Gray

# Utilisation d'une expression régulière avancée pour trouver les fichiers avec datestamps dans leur nom
Write-ColorOutput "`nFichiers avec dates dans leur nom:" -ForegroundColor Magenta
$datePattern = "\d{4}[-_]?\d{2}[-_]?\d{2}"
$filesWithDates = $fileAnalysis | Where-Object { $_.Name -match $datePattern }

if ($filesWithDates.Count -gt 0) {
    foreach ($file in ($filesWithDates | Select-Object -First 5)) {
        if ($file.Name -match $datePattern) {
            $dateInName = $matches[0]
            Write-ColorOutput "  $($file.Name) - Date trouvée: $dateInName" -ForegroundColor White
        }
    }

    if ($filesWithDates.Count -gt 5) {
        Write-ColorOutput "  ... et $($filesWithDates.Count - 5) autres fichiers avec dates." -ForegroundColor White
    }
}
else {
    Write-ColorOutput "  Aucun fichier avec date dans le nom trouvé." -ForegroundColor White
}

Write-ColorOutput "`n======================================================" -ForegroundColor Cyan
Write-ColorOutput "  ANALYSE TERMINÉE" -ForegroundColor Cyan
Write-ColorOutput "======================================================" -ForegroundColor Cyan
