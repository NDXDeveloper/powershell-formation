# Solution Exercice 1 - Comparaison Pipeline vs Boucle pour filtrage de fichiers

## Énoncé
Créez deux scripts PowerShell qui analysent les fichiers dans le dossier C:\Windows\System32, trouvent tous les fichiers .dll de plus de 1 Mo, et les affichent triés par taille. Utilisez une approche avec pipeline dans le premier script et une approche avec boucle dans le second, puis comparez les performances.

## Solution avec Pipeline

```powershell
# Fichier: Exercise1-Pipeline.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Utilisation du pipeline pour filtrer les fichiers .dll > 1Mo et les trier par taille
$resultsPipeline = Get-ChildItem -Path C:\Windows\System32 -Filter *.dll |
    Where-Object { $_.Length -gt 1MB } |
    Sort-Object -Property Length -Descending |
    Select-Object Name, @{Name="SizeMB"; Expression={"{0:N2}" -f ($_.Length / 1MB)}}

# Arrêt du chronomètre
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Pipeline - Top 10 des fichiers .dll les plus volumineux:" -ForegroundColor Cyan
$resultsPipeline | Select-Object -First 10 | Format-Table -AutoSize

Write-Host "Nombre total de fichiers trouvés: $($resultsPipeline.Count)" -ForegroundColor Yellow
Write-Host "Temps d'exécution: $pipelineTime ms" -ForegroundColor Green
```

## Solution avec Boucle

```powershell
# Fichier: Exercise1-Loop.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Récupération de tous les fichiers .dll
$allFiles = Get-ChildItem -Path C:\Windows\System32 -Filter *.dll

# Utilisation d'une boucle pour filtrer les fichiers
$resultsLoop = @()
foreach ($file in $allFiles) {
    if ($file.Length -gt 1MB) {
        $resultsLoop += [PSCustomObject]@{
            Name = $file.Name
            SizeMB = "{0:N2}" -f ($file.Length / 1MB)
        }
    }
}

# Tri des résultats
$resultsLoop = $resultsLoop | Sort-Object -Property {[double]$_.SizeMB} -Descending

# Arrêt du chronomètre
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Boucle - Top 10 des fichiers .dll les plus volumineux:" -ForegroundColor Cyan
$resultsLoop | Select-Object -First 10 | Format-Table -AutoSize

Write-Host "Nombre total de fichiers trouvés: $($resultsLoop.Count)" -ForegroundColor Yellow
Write-Host "Temps d'exécution: $loopTime ms" -ForegroundColor Green
```

## Script de comparaison

```powershell
# Fichier: Exercise1-Comparison.ps1

Write-Host "Comparaison des performances: Pipeline vs Boucle" -ForegroundColor Magenta
Write-Host "=================================================" -ForegroundColor Magenta

# Test de l'approche Pipeline
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$resultsPipeline = Get-ChildItem -Path C:\Windows\System32 -Filter *.dll |
    Where-Object { $_.Length -gt 1MB } |
    Sort-Object -Property Length -Descending |
    Select-Object Name, @{Name="SizeMB"; Expression={"{0:N2}" -f ($_.Length / 1MB)}}
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Test de l'approche Boucle
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$allFiles = Get-ChildItem -Path C:\Windows\System32 -Filter *.dll
$resultsLoop = @()
foreach ($file in $allFiles) {
    if ($file.Length -gt 1MB) {
        $resultsLoop += [PSCustomObject]@{
            Name = $file.Name
            SizeMB = "{0:N2}" -f ($file.Length / 1MB)
        }
    }
}
$resultsLoop = $resultsLoop | Sort-Object -Property {[double]$_.SizeMB} -Descending
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats de la comparaison
Write-Host "Résultats de la comparaison:" -ForegroundColor Cyan
Write-Host "Temps d'exécution Pipeline: $pipelineTime ms" -ForegroundColor Green
Write-Host "Temps d'exécution Boucle: $loopTime ms" -ForegroundColor Yellow
Write-Host "Différence: $('{0:N2}' -f ($loopTime - $pipelineTime)) ms" -ForegroundColor Magenta

if ($pipelineTime -lt $loopTime) {
    Write-Host "Le pipeline est plus rapide de $('{0:N2}' -f (($loopTime - $pipelineTime) / $loopTime * 100))%" -ForegroundColor Cyan
} else {
    Write-Host "La boucle est plus rapide de $('{0:N2}' -f (($pipelineTime - $loopTime) / $pipelineTime * 100))%" -ForegroundColor Cyan
}

# Vérification que les deux approches donnent les mêmes résultats
$pipelineCount = $resultsPipeline.Count
$loopCount = $resultsLoop.Count

Write-Host "`nVérification des résultats:" -ForegroundColor Cyan
Write-Host "Nombre de fichiers trouvés (Pipeline): $pipelineCount" -ForegroundColor Green
Write-Host "Nombre de fichiers trouvés (Boucle): $loopCount" -ForegroundColor Yellow

if ($pipelineCount -eq $loopCount) {
    Write-Host "Les deux approches ont trouvé le même nombre de fichiers." -ForegroundColor Green
} else {
    Write-Host "Les deux approches ont trouvé un nombre différent de fichiers!" -ForegroundColor Red
}
```

## Analyse des résultats

Dans cet exercice, vous pouvez observer plusieurs choses intéressantes:

1. **Performance**: Généralement, le pipeline sera plus rapide pour cette tâche car:
   - Le filtrage se fait "à la volée"
   - PowerShell optimise ce genre d'opérations chaînées
   - Moins d'objets intermédiaires sont créés

2. **Syntaxe**:
   - L'approche avec pipeline est beaucoup plus concise
   - L'approche avec boucle est plus explicite et plus facile à déboguer

3. **Mémoire**:
   - L'approche avec boucle consomme potentiellement plus de mémoire car elle crée une liste temporaire

4. **Lisibilité**:
   - Pour des opérations simples comme celle-ci, le pipeline est non seulement plus performant mais aussi plus lisible

Si vous exécutez ce script dans un environnement avec beaucoup de fichiers .dll, vous devriez constater une différence de performance significative entre les deux approches.


# Solution Exercice 2 - Traitement de données CSV avec Pipeline vs Boucle

## Énoncé
Créez deux scripts PowerShell qui traitent un fichier CSV contenant des informations d'utilisateurs (Nom, Prénom, Email, Département, Salaire). Le script doit calculer le salaire moyen par département et afficher les résultats triés du département ayant le salaire moyen le plus élevé au plus bas. Utilisez une approche avec pipeline dans le premier script et une approche avec boucle dans le second, puis comparez les performances.

## Données de test
Vous pouvez d'abord créer un fichier CSV pour tester:

```powershell
# Fichier: Create-TestData.ps1

# Création d'un CSV de test avec 1000 utilisateurs
$departments = @('IT', 'RH', 'Marketing', 'Finance', 'Production', 'R&D', 'Commercial', 'Juridique')
$users = @()

for ($i = 1; $i -le 1000; $i++) {
    $users += [PSCustomObject]@{
        Nom = "Nom$i"
        Prenom = "Prenom$i"
        Email = "utilisateur$i@entreprise.com"
        Departement = $departments[(Get-Random -Minimum 0 -Maximum $departments.Count)]
        Salaire = Get-Random -Minimum 30000 -Maximum 100000
    }
}

$users | Export-Csv -Path ".\Utilisateurs.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Fichier CSV de test créé avec 1000 utilisateurs."
```

## Solution avec Pipeline

```powershell
# Fichier: Exercise2-Pipeline.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Lecture du fichier CSV
$users = Import-Csv -Path ".\Utilisateurs.csv"

# Calcul des moyennes par département avec le pipeline
$resultsPipeline = $users |
    Group-Object -Property Departement |
    ForEach-Object {
        [PSCustomObject]@{
            Departement = $_.Name
            NombreEmployes = $_.Count
            SalaireMoyen = [math]::Round(($_.Group | Measure-Object -Property Salaire -Average).Average, 2)
        }
    } |
    Sort-Object -Property SalaireMoyen -Descending

# Arrêt du chronomètre
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Pipeline - Salaire moyen par département:" -ForegroundColor Cyan
$resultsPipeline | Format-Table -AutoSize

Write-Host "Temps d'exécution: $pipelineTime ms" -ForegroundColor Green
```

## Solution avec Boucle

```powershell
# Fichier: Exercise2-Loop.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Lecture du fichier CSV
$users = Import-Csv -Path ".\Utilisateurs.csv"

# Préparation des variables pour l'analyse
$departments = @{}

# Utilisation d'une boucle pour calculer les totaux par département
foreach ($user in $users) {
    $dept = $user.Departement
    $salaire = [double]$user.Salaire

    if (-not $departments.ContainsKey($dept)) {
        $departments[$dept] = @{
            Total = 0
            Count = 0
        }
    }

    $departments[$dept].Total += $salaire
    $departments[$dept].Count++
}

# Calcul des moyennes et création des objets résultats
$resultsLoop = @()
foreach ($dept in $departments.Keys) {
    $resultsLoop += [PSCustomObject]@{
        Departement = $dept
        NombreEmployes = $departments[$dept].Count
        SalaireMoyen = [math]::Round(($departments[$dept].Total / $departments[$dept].Count), 2)
    }
}

# Tri des résultats
$resultsLoop = $resultsLoop | Sort-Object -Property SalaireMoyen -Descending

# Arrêt du chronomètre
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Boucle - Salaire moyen par département:" -ForegroundColor Cyan
$resultsLoop | Format-Table -AutoSize

Write-Host "Temps d'exécution: $loopTime ms" -ForegroundColor Yellow
```

## Script de comparaison

```powershell
# Fichier: Exercise2-Comparison.ps1

Write-Host "Comparaison des performances: Pipeline vs Boucle pour traitement CSV" -ForegroundColor Magenta
Write-Host "==============================================================" -ForegroundColor Magenta

# Vérification de l'existence du fichier CSV
if (-not (Test-Path -Path ".\Utilisateurs.csv")) {
    Write-Host "Fichier CSV non trouvé. Création d'un fichier de test..." -ForegroundColor Yellow

    # Création d'un CSV de test
    $departments = @('IT', 'RH', 'Marketing', 'Finance', 'Production', 'R&D', 'Commercial', 'Juridique')
    $users = @()

    for ($i = 1; $i -le 1000; $i++) {
        $users += [PSCustomObject]@{
            Nom = "Nom$i"
            Prenom = "Prenom$i"
            Email = "utilisateur$i@entreprise.com"
            Departement = $departments[(Get-Random -Minimum 0 -Maximum $departments.Count)]
            Salaire = Get-Random -Minimum 30000 -Maximum 100000
        }
    }

    $users | Export-Csv -Path ".\Utilisateurs.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "Fichier CSV de test créé avec 1000 utilisateurs." -ForegroundColor Green
}

# Test de l'approche Pipeline
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$users = Import-Csv -Path ".\Utilisateurs.csv"
$resultsPipeline = $users |
    Group-Object -Property Departement |
    ForEach-Object {
        [PSCustomObject]@{
            Departement = $_.Name
            NombreEmployes = $_.Count
            SalaireMoyen = [math]::Round(($_.Group | Measure-Object -Property Salaire -Average).Average, 2)
        }
    } |
    Sort-Object -Property SalaireMoyen -Descending
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Test de l'approche Boucle
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$users = Import-Csv -Path ".\Utilisateurs.csv"
$departments = @{}
foreach ($user in $users) {
    $dept = $user.Departement
    $salaire = [double]$user.Salaire

    if (-not $departments.ContainsKey($dept)) {
        $departments[$dept] = @{
            Total = 0
            Count = 0
        }
    }

    $departments[$dept].Total += $salaire
    $departments[$dept].Count++
}
$resultsLoop = @()
foreach ($dept in $departments.Keys) {
    $resultsLoop += [PSCustomObject]@{
        Departement = $dept
        NombreEmployes = $departments[$dept].Count
        SalaireMoyen = [math]::Round(($departments[$dept].Total / $departments[$dept].Count), 2)
    }
}
$resultsLoop = $resultsLoop | Sort-Object -Property SalaireMoyen -Descending
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats de la comparaison
Write-Host "`nRésultats de la comparaison:" -ForegroundColor Cyan
Write-Host "Temps d'exécution Pipeline: $pipelineTime ms" -ForegroundColor Green
Write-Host "Temps d'exécution Boucle: $loopTime ms" -ForegroundColor Yellow
Write-Host "Différence: $('{0:N2}' -f ($loopTime - $pipelineTime)) ms" -ForegroundColor Magenta

if ($pipelineTime -lt $loopTime) {
    Write-Host "Le pipeline est plus rapide de $('{0:N2}' -f (($loopTime - $pipelineTime) / $loopTime * 100))%" -ForegroundColor Cyan
} else {
    Write-Host "La boucle est plus rapide de $('{0:N2}' -f (($pipelineTime - $loopTime) / $pipelineTime * 100))%" -ForegroundColor Cyan
}

# Affichage des résultats pour vérification
Write-Host "`nRésultats de l'analyse:" -ForegroundColor Cyan
$resultsPipeline | Format-Table -AutoSize
```

## Analyse des résultats

Cet exercice illustre un cas où la méthode avec boucle peut être plus performante que le pipeline:

1. **Performance**:
   - La boucle est souvent plus rapide ici car elle ne fait qu'une seule passe sur les données
   - Le pipeline utilise `Group-Object` suivi de `Measure-Object` pour chaque groupe, ce qui peut être moins efficace

2. **Utilisation mémoire**:
   - L'approche avec boucle utilise une table de hachage pour accumuler les résultats, ce qui est très efficace
   - Le pipeline crée des objets intermédiaires à chaque étape

3. **Approche**:
   - La méthode avec boucle utilise une approche algorithmique classique: accumuler des totaux en une passe
   - La méthode avec pipeline utilise des cmdlets spécialisées qui sont plus expressives mais peuvent être moins efficaces pour ce cas précis

4. **Lisibilité**:
   - Le pipeline est plus concis et reflète mieux l'intention
   - La boucle est plus explicite sur ce qui se passe à chaque étape

Cette comparaison montre qu'il est important de tester les performances dans votre contexte spécifique plutôt que de supposer qu'une approche est toujours meilleure.

# Solution Exercice 3 - Traitement avancé de logs avec Pipeline vs Boucle

## Énoncé
Créez deux scripts PowerShell qui analysent un fichier de logs (format texte) contenant des entrées d'erreurs et d'avertissements. Le script doit extraire toutes les erreurs, les grouper par type d'erreur, compter leur occurrence, et afficher les 5 erreurs les plus fréquentes avec leur message complet. Utilisez une approche avec pipeline dans le premier script et une approche avec boucle dans le second, puis comparez les performances.

## Création d'un fichier de logs de test

Voici d'abord un script pour générer un fichier de logs de test :

```powershell
# Fichier: Create-TestLogs.ps1

# Définition des types d'erreurs et d'avertissements
$errorTypes = @(
    "ERROR: Database connection failed",
    "ERROR: Invalid user credentials",
    "ERROR: File not found",
    "ERROR: Access denied",
    "ERROR: Timeout exceeded",
    "ERROR: Memory allocation failed",
    "ERROR: Network connection lost",
    "ERROR: Invalid configuration",
    "ERROR: Service unavailable",
    "ERROR: API rate limit exceeded"
)

$warningTypes = @(
    "WARNING: High memory usage",
    "WARNING: Slow response time",
    "WARNING: Disk space low",
    "WARNING: Cache invalidated",
    "WARNING: Certificate expiring soon"
)

$infoTypes = @(
    "INFO: User logged in",
    "INFO: Operation completed",
    "INFO: Service started",
    "INFO: Configuration loaded",
    "INFO: Backup completed"
)

# Création du fichier de logs avec 10000 entrées
$logEntries = @()
$date = Get-Date

for ($i = 1; $i -le 10000; $i++) {
    # Détermine quel type d'entrée générer (60% info, 30% warning, 10% error)
    $random = Get-Random -Minimum 1 -Maximum 101

    if ($random -le 10) {
        # Entrée d'erreur (10%)
        $errorType = $errorTypes[(Get-Random -Minimum 0 -Maximum $errorTypes.Count)]
        $details = " - Details: " + (New-Guid).ToString().Substring(0, 8)
        $logEntries += "$($date.AddSeconds(-$i).ToString('yyyy-MM-dd HH:mm:ss')) [$($i.ToString('D5'))] $errorType$details"
    }
    elseif ($random -le 40) {
        # Entrée d'avertissement (30%)
        $warningType = $warningTypes[(Get-Random -Minimum 0 -Maximum $warningTypes.Count)]
        $logEntries += "$($date.AddSeconds(-$i).ToString('yyyy-MM-dd HH:mm:ss')) [$($i.ToString('D5'))] $warningType"
    }
    else {
        # Entrée d'information (60%)
        $infoType = $infoTypes[(Get-Random -Minimum 0 -Maximum $infoTypes.Count)]
        $logEntries += "$($date.AddSeconds(-$i).ToString('yyyy-MM-dd HH:mm:ss')) [$($i.ToString('D5'))] $infoType"
    }
}

# Écriture du fichier de logs
$logEntries | Out-File -FilePath ".\application.log" -Encoding utf8
Write-Host "Fichier de logs de test créé avec 10000 entrées." -ForegroundColor Green
```

## Solution avec Pipeline

```powershell
# Fichier: Exercise3-Pipeline.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Lecture du fichier de logs
$logContent = Get-Content -Path ".\application.log"

# Utilisation du pipeline pour extraire et analyser les erreurs
$errorAnalysisPipeline = $logContent |
    Where-Object { $_ -match "ERROR:" } |
    ForEach-Object {
        # Extraction de la date et du message d'erreur
        if ($_ -match "^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(\d+)\] (ERROR:[^-]+)(.*)$") {
            [PSCustomObject]@{
                DateTime = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                ID = $Matches[2]
                ErrorType = $Matches[3].Trim()
                Details = $Matches[4]
                FullMessage = $_
            }
        }
    } |
    Group-Object -Property ErrorType |
    ForEach-Object {
        [PSCustomObject]@{
            ErrorType = $_.Name
            Count = $_.Count
            Messages = $_.Group.FullMessage
            FirstOccurrence = ($_.Group | Sort-Object DateTime)[0].DateTime
            LastOccurrence = ($_.Group | Sort-Object DateTime -Descending)[0].DateTime
        }
    } |
    Sort-Object -Property Count -Descending

# Arrêt du chronomètre
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Pipeline - Top 5 erreurs les plus fréquentes:" -ForegroundColor Cyan
$errorAnalysisPipeline | Select-Object -First 5 | Format-Table ErrorType, Count, FirstOccurrence, LastOccurrence

# Affichage des exemples de messages pour les 5 erreurs les plus fréquentes
foreach ($error in ($errorAnalysisPipeline | Select-Object -First 5)) {
    Write-Host "`nType d'erreur: $($error.ErrorType) (Occurrences: $($error.Count))" -ForegroundColor Yellow
    Write-Host "Premier exemple: $($error.Messages[0])" -ForegroundColor Gray
}

Write-Host "`nTemps d'exécution: $pipelineTime ms" -ForegroundColor Green
```

## Solution avec Boucle

```powershell
# Fichier: Exercise3-Loop.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Lecture du fichier de logs
$logContent = Get-Content -Path ".\application.log"

# Utilisation d'une boucle pour extraire et analyser les erreurs
$errorDictionary = @{}

foreach ($line in $logContent) {
    # Vérification si la ligne contient une erreur
    if ($line -match "ERROR:") {
        # Extraction de la date et du message d'erreur
        if ($line -match "^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(\d+)\] (ERROR:[^-]+)(.*)$") {
            $dateTime = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null)
            $id = $Matches[2]
            $errorType = $Matches[3].Trim()
            $details = $Matches[4]

            # Création ou mise à jour de l'entrée dans le dictionnaire
            if (-not $errorDictionary.ContainsKey($errorType)) {
                $errorDictionary[$errorType] = @{
                    Count = 0
                    Messages = @()
                    FirstOccurrence = $dateTime
                    LastOccurrence = $dateTime
                }
            }

            $errorDictionary[$errorType].Count++
            $errorDictionary[$errorType].Messages += $line

            # Mise à jour des dates d'occurrence
            if ($dateTime -lt $errorDictionary[$errorType].FirstOccurrence) {
                $errorDictionary[$errorType].FirstOccurrence = $dateTime
            }
            if ($dateTime -gt $errorDictionary[$errorType].LastOccurrence) {
                $errorDictionary[$errorType].LastOccurrence = $dateTime
            }
        }
    }
}

# Conversion du dictionnaire en liste d'objets
$errorAnalysisLoop = @()
foreach ($key in $errorDictionary.Keys) {
    $errorAnalysisLoop += [PSCustomObject]@{
        ErrorType = $key
        Count = $errorDictionary[$key].Count
        Messages = $errorDictionary[$key].Messages
        FirstOccurrence = $errorDictionary[$key].FirstOccurrence
        LastOccurrence = $errorDictionary[$key].LastOccurrence
    }
}

# Tri des résultats par nombre d'occurrences
$errorAnalysisLoop = $errorAnalysisLoop | Sort-Object -Property Count -Descending

# Arrêt du chronomètre
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Boucle - Top 5 erreurs les plus fréquentes:" -ForegroundColor Cyan
$errorAnalysisLoop | Select-Object -First 5 | Format-Table ErrorType, Count, FirstOccurrence, LastOccurrence

# Affichage des exemples de messages pour les 5 erreurs les plus fréquentes
foreach ($error in ($errorAnalysisLoop | Select-Object -First 5)) {
    Write-Host "`nType d'erreur: $($error.ErrorType) (Occurrences: $($error.Count))" -ForegroundColor Yellow
    Write-Host "Premier exemple: $($error.Messages[0])" -ForegroundColor Gray
}

Write-Host "`nTemps d'exécution: $loopTime ms" -ForegroundColor Green
```

## Script de comparaison

```powershell
# Fichier: Exercise3-Comparison.ps1

Write-Host "Comparaison des performances: Pipeline vs Boucle pour l'analyse de logs" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

# Vérification de l'existence du fichier de logs
if (-not (Test-Path -Path ".\application.log")) {
    Write-Host "Fichier de logs non trouvé. Exécutez d'abord Create-TestLogs.ps1" -ForegroundColor Yellow
    exit
}

# Test de l'approche Pipeline
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$logContent = Get-Content -Path ".\application.log"
$errorAnalysisPipeline = $logContent |
    Where-Object { $_ -match "ERROR:" } |
    ForEach-Object {
        if ($_ -match "^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(\d+)\] (ERROR:[^-]+)(.*)$") {
            [PSCustomObject]@{
                DateTime = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null)
                ID = $Matches[2]
                ErrorType = $Matches[3].Trim()
                Details = $Matches[4]
                FullMessage = $_
            }
        }
    } |
    Group-Object -Property ErrorType |
    ForEach-Object {
        [PSCustomObject]@{
            ErrorType = $_.Name
            Count = $_.Count
            Messages = $_.Group.FullMessage
            FirstOccurrence = ($_.Group | Sort-Object DateTime)[0].DateTime
            LastOccurrence = ($_.Group | Sort-Object DateTime -Descending)[0].DateTime
        }
    } |
    Sort-Object -Property Count -Descending
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Test de l'approche Boucle
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$logContent = Get-Content -Path ".\application.log"
$errorDictionary = @{}

foreach ($line in $logContent) {
    if ($line -match "ERROR:") {
        if ($line -match "^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(\d+)\] (ERROR:[^-]+)(.*)$") {
            $dateTime = [DateTime]::ParseExact($Matches[1], "yyyy-MM-dd HH:mm:ss", $null)
            $id = $Matches[2]
            $errorType = $Matches[3].Trim()
            $details = $Matches[4]

            if (-not $errorDictionary.ContainsKey($errorType)) {
                $errorDictionary[$errorType] = @{
                    Count = 0
                    Messages = @()
                    FirstOccurrence = $dateTime
                    LastOccurrence = $dateTime
                }
            }

            $errorDictionary[$errorType].Count++
            $errorDictionary[$errorType].Messages += $line

            if ($dateTime -lt $errorDictionary[$errorType].FirstOccurrence) {
                $errorDictionary[$errorType].FirstOccurrence = $dateTime
            }
            if ($dateTime -gt $errorDictionary[$errorType].LastOccurrence) {
                $errorDictionary[$errorType].LastOccurrence = $dateTime
            }
        }
    }
}

$errorAnalysisLoop = @()
foreach ($key in $errorDictionary.Keys) {
    $errorAnalysisLoop += [PSCustomObject]@{
        ErrorType = $key
        Count = $errorDictionary[$key].Count
        Messages = $errorDictionary[$key].Messages
        FirstOccurrence = $errorDictionary[$key].FirstOccurrence
        LastOccurrence = $errorDictionary[$key].LastOccurrence
    }
}

$errorAnalysisLoop = $errorAnalysisLoop | Sort-Object -Property Count -Descending
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats de la comparaison
Write-Host "`nRésultats de la comparaison:" -ForegroundColor Cyan
Write-Host "Temps d'exécution Pipeline: $pipelineTime ms" -ForegroundColor Green
Write-Host "Temps d'exécution Boucle: $loopTime ms" -ForegroundColor Yellow
Write-Host "Différence: $('{0:N2}' -f ($loopTime - $pipelineTime)) ms" -ForegroundColor Magenta

if ($pipelineTime -lt $loopTime) {
    Write-Host "Le pipeline est plus rapide de $('{0:N2}' -f (($loopTime - $pipelineTime) / $loopTime * 100))%" -ForegroundColor Cyan
} else {
    Write-Host "La boucle est plus rapide de $('{0:N2}' -f (($pipelineTime - $loopTime) / $pipelineTime * 100))%" -ForegroundColor Cyan
}

# Affichage des top 5 erreurs
Write-Host "`nTop 5 erreurs trouvées:" -ForegroundColor Cyan
$errorAnalysisPipeline | Select-Object -First 5 | Format-Table ErrorType, Count

# Tests de cohérence des résultats
$pipelineResults = $errorAnalysisPipeline | Select-Object -First 5 | ForEach-Object { "$($_.ErrorType): $($_.Count)" }
$loopResults = $errorAnalysisLoop | Select-Object -First 5 | ForEach-Object { "$($_.ErrorType): $($_.Count)" }

$areEqual = @(Compare-Object $pipelineResults $loopResults).Length -eq 0

Write-Host "`nLes deux approches donnent-elles les mêmes résultats? $areEqual" -ForegroundColor $(if ($areEqual) { "Green" } else { "Red" })
```

## Analyse des résultats

Cet exercice illustre un scénario plus complexe de traitement de données :

1. **Performance**:
   - Pour ce type de traitement avec expressions régulières et manipulation de dates, la boucle est souvent plus rapide
   - Le pipeline crée de nombreux objets intermédiaires et effectue plusieurs passes sur les données
   - La boucle permet d'optimiser en ne faisant qu'une seule passe sur les données et en accumulant les résultats efficacement

2. **Complexité du code**:
   - Le pipeline est plus concis mais peut être moins lisible pour les opérations complexes
   - La boucle est plus verbeuse mais rend le flux de travail plus explicite
   - Le traitement avec des expressions régulières est similaire dans les deux approches

3. **Algorithme**:
   - La boucle permet plus de contrôle sur l'algorithme exact utilisé
   - Le pipeline délègue l'implémentation à des cmdlets comme `Group-Object` et `Sort-Object`

4. **Flexibilité**:
   - L'approche avec boucle est plus facile à étendre pour des analyses plus complexes
   - L'approche avec pipeline est plus déclarative et s'adapte bien aux transformations en chaîne

Cet exercice montre que pour des analyses complexes de logs, où plusieurs traitements sont nécessaires (filtrage, extraction, groupement, agrégation), la boucle peut parfois offrir de meilleures performances en raison du contrôle plus fin sur le traitement des données.

# Solution Exercice 4 - Monitoring de processus avec Pipeline vs Boucle

## Énoncé
Créez deux scripts PowerShell qui surveillent les processus en cours d'exécution, identifient les 10 processus qui consomment le plus de mémoire, calculent leur utilisation totale, moyenne, et pourcentage par rapport à la mémoire totale. Le script doit également vérifier si le processus est un processus système et le catégoriser (système/utilisateur). Utilisez une approche avec pipeline dans le premier script et une approche avec boucle dans le second, puis comparez les performances.

## Solution avec Pipeline

```powershell
# Fichier: Exercise4-Pipeline.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Obtenir la mémoire totale du système en MB
$totalMemoryMB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB

# Définition des processus système connus
$systemProcessNames = @(
    "System", "Registry", "smss", "csrss", "wininit", "services", "svchost",
    "lsass", "winlogon", "fontdrvhost", "dwm", "runtimebroker", "taskhostw"
)

# Utilisation du pipeline pour analyser les processus
$processesPipeline = Get-Process |
    Select-Object Name, ID, @{Name="MemoryMB"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}},
                  @{Name="PercentMemory"; Expression={[math]::Round(($_.WorkingSet / 1MB) / $totalMemoryMB * 100, 2)}},
                  @{Name="ProcessType"; Expression={
                      if ($systemProcessNames -contains $_.Name) {"System"} else {"User"}
                  }} |
    Sort-Object -Property MemoryMB -Descending |
    Select-Object -First 10

# Calcul de statistiques supplémentaires
$totalMemoryUsed = ($processesPipeline | Measure-Object -Property MemoryMB -Sum).Sum
$averageMemoryUsed = ($processesPipeline | Measure-Object -Property MemoryMB -Average).Average
$percentOfTotalMemory = [math]::Round($totalMemoryUsed / $totalMemoryMB * 100, 2)

# Arrêt du chronomètre
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Pipeline - Top 10 processus par consommation mémoire:" -ForegroundColor Cyan
$processesPipeline | Format-Table -AutoSize

Write-Host "Statistiques:" -ForegroundColor Yellow
Write-Host "Mémoire totale du système: $([math]::Round($totalMemoryMB, 2)) MB" -ForegroundColor Gray
Write-Host "Mémoire utilisée par les 10 principaux processus: $totalMemoryUsed MB ($percentOfTotalMemory% du total)" -ForegroundColor Gray
Write-Host "Utilisation moyenne par processus (top 10): $([math]::Round($averageMemoryUsed, 2)) MB" -ForegroundColor Gray

Write-Host "`nTemps d'exécution: $pipelineTime ms" -ForegroundColor Green
```

## Solution avec Boucle

```powershell
# Fichier: Exercise4-Loop.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Obtenir la mémoire totale du système en MB
$totalMemoryMB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB

# Définition des processus système connus
$systemProcessNames = @(
    "System", "Registry", "smss", "csrss", "wininit", "services", "svchost",
    "lsass", "winlogon", "fontdrvhost", "dwm", "runtimebroker", "taskhostw"
)

# Récupération de tous les processus
$allProcesses = Get-Process

# Utilisation d'une boucle pour créer des objets personnalisés pour chaque processus
$processObjects = @()
foreach ($process in $allProcesses) {
    $memoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
    $percentMemory = [math]::Round(($process.WorkingSet / 1MB) / $totalMemoryMB * 100, 2)
    $processType = if ($systemProcessNames -contains $process.Name) {"System"} else {"User"}

    $processObjects += [PSCustomObject]@{
        Name = $process.Name
        ID = $process.Id
        MemoryMB = $memoryMB
        PercentMemory = $percentMemory
        ProcessType = $processType
    }
}

# Tri des processus et sélection des 10 principaux
$processesLoop = $processObjects | Sort-Object -Property MemoryMB -Descending | Select-Object -First 10

# Calcul de statistiques supplémentaires
$totalMemoryUsed = 0
foreach ($process in $processesLoop) {
    $totalMemoryUsed += $process.MemoryMB
}

$averageMemoryUsed = $totalMemoryUsed / $processesLoop.Count
$percentOfTotalMemory = [math]::Round($totalMemoryUsed / $totalMemoryMB * 100, 2)

# Arrêt du chronomètre
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Boucle - Top 10 processus par consommation mémoire:" -ForegroundColor Cyan
$processesLoop | Format-Table -AutoSize

Write-Host "Statistiques:" -ForegroundColor Yellow
Write-Host "Mémoire totale du système: $([math]::Round($totalMemoryMB, 2)) MB" -ForegroundColor Gray
Write-Host "Mémoire utilisée par les 10 principaux processus: $([math]::Round($totalMemoryUsed, 2)) MB ($percentOfTotalMemory% du total)" -ForegroundColor Gray
Write-Host "Utilisation moyenne par processus (top 10): $([math]::Round($averageMemoryUsed, 2)) MB" -ForegroundColor Gray

Write-Host "`nTemps d'exécution: $loopTime ms" -ForegroundColor Green
```

## Script de comparaison

```powershell
# Fichier: Exercise4-Comparison.ps1

Write-Host "Comparaison des performances: Pipeline vs Boucle pour l'analyse de processus" -ForegroundColor Magenta
Write-Host "=====================================================================" -ForegroundColor Magenta

# Test de l'approche Pipeline
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$totalMemoryMB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB
$systemProcessNames = @(
    "System", "Registry", "smss", "csrss", "wininit", "services", "svchost",
    "lsass", "winlogon", "fontdrvhost", "dwm", "runtimebroker", "taskhostw"
)

$processesPipeline = Get-Process |
    Select-Object Name, ID, @{Name="MemoryMB"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}},
                  @{Name="PercentMemory"; Expression={[math]::Round(($_.WorkingSet / 1MB) / $totalMemoryMB * 100, 2)}},
                  @{Name="ProcessType"; Expression={
                      if ($systemProcessNames -contains $_.Name) {"System"} else {"User"}
                  }} |
    Sort-Object -Property MemoryMB -Descending |
    Select-Object -First 10

$totalMemoryUsedPipeline = ($processesPipeline | Measure-Object -Property MemoryMB -Sum).Sum
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Test de l'approche Boucle
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$totalMemoryMB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1MB
$systemProcessNames = @(
    "System", "Registry", "smss", "csrss", "wininit", "services", "svchost",
    "lsass", "winlogon", "fontdrvhost", "dwm", "runtimebroker", "taskhostw"
)

$allProcesses = Get-Process
$processObjects = @()
foreach ($process in $allProcesses) {
    $memoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
    $percentMemory = [math]::Round(($process.WorkingSet / 1MB) / $totalMemoryMB * 100, 2)
    $processType = if ($systemProcessNames -contains $process.Name) {"System"} else {"User"}

    $processObjects += [PSCustomObject]@{
        Name = $process.Name
        ID = $process.Id
        MemoryMB = $memoryMB
        PercentMemory = $percentMemory
        ProcessType = $processType
    }
}

$processesLoop = $processObjects | Sort-Object -Property MemoryMB -Descending | Select-Object -First 10
$totalMemoryUsedLoop = 0
foreach ($process in $processesLoop) {
    $totalMemoryUsedLoop += $process.MemoryMB
}
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats de la comparaison
Write-Host "`nRésultats de la comparaison:" -ForegroundColor Cyan
Write-Host "Temps d'exécution Pipeline: $pipelineTime ms" -ForegroundColor Green
Write-Host "Temps d'exécution Boucle: $loopTime ms" -ForegroundColor Yellow
Write-Host "Différence: $('{0:N2}' -f ($loopTime - $pipelineTime)) ms" -ForegroundColor Magenta

if ($pipelineTime -lt $loopTime) {
    Write-Host "Le pipeline est plus rapide de $('{0:N2}' -f (($loopTime - $pipelineTime) / $loopTime * 100))%" -ForegroundColor Cyan
} else {
    Write-Host "La boucle est plus rapide de $('{0:N2}' -f (($pipelineTime - $loopTime) / $pipelineTime * 100))%" -ForegroundColor Cyan
}

# Affichage des principaux processus
Write-Host "`nTop processus utilisant le plus de mémoire:" -ForegroundColor Cyan
$processesPipeline | Format-Table Name, ID, MemoryMB, ProcessType -AutoSize

# Comparaison des résultats
Write-Host "`nVérification de la cohérence des résultats:" -ForegroundColor Yellow
Write-Host "Mémoire totale utilisée (Pipeline): $totalMemoryUsedPipeline MB" -ForegroundColor Green
Write-Host "Mémoire totale utilisée (Boucle): $([math]::Round($totalMemoryUsedLoop, 2)) MB" -ForegroundColor Yellow

$difference = [math]::Abs($totalMemoryUsedPipeline - $totalMemoryUsedLoop)
if ($difference -lt 0.01) {
    Write-Host "Les deux approches calculent les mêmes résultats." -ForegroundColor Green
} else {
    Write-Host "Différence dans les calculs: $difference MB" -ForegroundColor Red
}
```

## Analyse des résultats

Cette solution d'exercice illustre un cas d'utilisation courant en administration système:

1. **Performance**:
   - L'approche avec pipeline est généralement plus rapide pour cette tâche car:
     - Les cmdlets PowerShell comme `Get-Process` sont optimisées pour fonctionner dans un pipeline
     - La création des propriétés calculées via `Select-Object` est efficace
   - L'approche avec boucle implique:
     - Une manipulation manuelle des objets
     - Une création explicite de chaque nouvel objet
     - Un tri séparé qui doit être appliqué à la liste complète

2. **Avantages de chaque approche**:
   - **Pipeline**:
     - Code plus concis et déclaratif
     - Plus facile à maintenir et à lire pour des calculs simples
     - Plus performant pour ce type d'opération
   - **Boucle**:
     - Plus de contrôle sur le traitement individuel
     - Possibilité d'ajouter des traitements conditionnels plus complexes
     - Plus facile à déboguer étape par étape

3. **Particularités de cet exemple**:
   - L'utilisation de propriétés calculées (`@{Name=...; Expression=...}`) est très puissante dans le pipeline
   - Le pipeline peut utiliser des cmdlets comme `Measure-Object` pour les statistiques
   - La boucle est plus verbeuse mais son fonctionnement est plus explicite

4. **Cas d'utilisation réelle**:
   - Ce type de script est utile pour:
     - Monitoring système
     - Détection de fuites mémoire
     - Audit des processus en cours d'exécution
     - Optimisation des performances système

La préférence pour l'une ou l'autre approche dépendra du contexte spécifique, mais pour un monitoring simple, le pipeline offre un excellent équilibre entre concision, performance et lisibilité.


# Solution Exercice 5 - Traitement parallèle avec Pipeline vs Boucle

## Énoncé
Créez deux scripts PowerShell qui testent la connectivité (ping) vers une liste de serveurs ou d'adresses IP. Le script doit enregistrer le temps de réponse, déterminer si le serveur est joignable, et générer un rapport. Utilisez une approche avec pipeline et parallélisme dans le premier script et une approche avec boucle et parallélisme dans le second, puis comparez les performances.

> **Note**: Cet exercice requiert PowerShell 7+ pour l'utilisation de `ForEach-Object -Parallel`.

## Création d'une liste de serveurs de test

```powershell
# Fichier: Create-ServerList.ps1

# Création d'une liste de serveurs/sites populaires pour les tests
$servers = @(
    "google.com",
    "microsoft.com",
    "amazon.com",
    "cloudflare.com",
    "github.com",
    "stackoverflow.com",
    "youtube.com",
    "facebook.com",
    "wikipedia.org",
    "twitter.com",
    "instagram.com",
    "apple.com",
    "netflix.com",
    "linkedin.com",
    "adobe.com",
    "spotify.com",
    "reddit.com",
    "twitch.tv",
    "discord.com",
    "dropbox.com"
)

# Ajout de quelques adresses qui ne répondront probablement pas
$servers += @(
    "server-does-not-exist.com",
    "invalid-domain-123456.org",
    "192.168.123.250",
    "172.16.254.254"
)

# Écriture dans un fichier
$servers | Out-File -FilePath ".\servers.txt" -Encoding utf8
Write-Host "Liste de serveurs créée avec $(($servers).Count) entrées." -ForegroundColor Green
```

## Solution avec Pipeline et Parallélisme

```powershell
# Fichier: Exercise5-Pipeline.ps1
#
# Requiert PowerShell 7+ pour ForEach-Object -Parallel
#

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Définition du nombre maximum de traitements parallèles
$maxParallelJobs = 10

# Lecture de la liste de serveurs
$servers = Get-Content -Path ".\servers.txt"

# Utilisation du pipeline avec parallélisme
$results = $servers | ForEach-Object -ThrottleLimit $maxParallelJobs -Parallel {
    $server = $_
    $pingResult = Test-Connection -ComputerName $server -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue

    if ($pingResult) {
        [PSCustomObject]@{
            Server = $server
            Status = "Online"
            ResponseTime = $pingResult.Latency
            IPAddress = $pingResult.Address.IPAddressToString
            Timestamp = Get-Date
        }
    } else {
        [PSCustomObject]@{
            Server = $server
            Status = "Offline"
            ResponseTime = $null
            IPAddress = $null
            Timestamp = Get-Date
        }
    }
}

# Tri des résultats
$sortedResults = $results | Sort-Object -Property Status, ResponseTime

# Calcul des statistiques
$onlineCount = ($results | Where-Object { $_.Status -eq "Online" }).Count
$offlineCount = ($results | Where-Object { $_.Status -eq "Offline" }).Count
$totalCount = $results.Count
$onlinePercentage = [math]::Round(($onlineCount / $totalCount) * 100, 2)

$averageResponseTime = $null
if ($onlineCount -gt 0) {
    $averageResponseTime = [math]::Round(($results | Where-Object { $_.Status -eq "Online" } | Measure-Object -Property ResponseTime -Average).Average, 0)
}

# Arrêt du chronomètre
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Pipeline avec parallélisme - Test de connectivité:" -ForegroundColor Cyan
$sortedResults | Format-Table -AutoSize

Write-Host "Statistiques:" -ForegroundColor Yellow
Write-Host "Total de serveurs testés: $totalCount" -ForegroundColor Gray
Write-Host "Serveurs en ligne: $onlineCount ($onlinePercentage%)" -ForegroundColor Green
Write-Host "Serveurs hors ligne: $offlineCount" -ForegroundColor Red
if ($averageResponseTime) {
    Write-Host "Temps de réponse moyen: $averageResponseTime ms" -ForegroundColor Gray
}

Write-Host "`nTemps d'exécution total: $pipelineTime ms" -ForegroundColor Magenta

# Export des résultats en CSV
$sortedResults | Export-Csv -Path ".\PipelineResults.csv" -NoTypeInformation
Write-Host "Résultats exportés dans PipelineResults.csv" -ForegroundColor Gray
```

## Solution avec Boucle et Parallélisme

```powershell
# Fichier: Exercise5-Loop.ps1
#
# Requiert PowerShell 7+ pour les runspaces
#

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Définition du nombre maximum de traitements parallèles
$maxParallelJobs = 10

# Lecture de la liste de serveurs
$servers = Get-Content -Path ".\servers.txt"

# Création d'un tableau pour stocker les résultats
$results = @()
$lock = [System.Threading.Mutex]::new($false)

# Création d'un pool de runspaces
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxParallelJobs)
$runspacePool.Open()

# Préparation des jobs
$jobs = @()

foreach ($server in $servers) {
    $scriptBlock = {
        param ($serverName, $resultArray, $mutex)

        $pingResult = Test-Connection -ComputerName $serverName -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue

        $result = if ($pingResult) {
            [PSCustomObject]@{
                Server = $serverName
                Status = "Online"
                ResponseTime = $pingResult.Latency
                IPAddress = $pingResult.Address.IPAddressToString
                Timestamp = Get-Date
            }
        } else {
            [PSCustomObject]@{
                Server = $serverName
                Status = "Offline"
                ResponseTime = $null
                IPAddress = $null
                Timestamp = Get-Date
            }
        }

        # Ajout du résultat au tableau partagé (mutex pour éviter les conflits)
        $mutex.WaitOne() | Out-Null
        $resultArray.Add($result)
        $mutex.ReleaseMutex()
    }

    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($server).AddArgument([System.Collections.ArrayList]$results).AddArgument($lock)
    $powershell.RunspacePool = $runspacePool

    $jobs += [PSCustomObject]@{
        PowerShell = $powershell
        Handle = $powershell.BeginInvoke()
    }
}

# Attente de la fin de tous les jobs
foreach ($job in $jobs) {
    $job.PowerShell.EndInvoke($job.Handle)
    $job.PowerShell.Dispose()
}

# Fermeture du pool de runspaces
$runspacePool.Close()
$runspacePool.Dispose()

# Tri des résultats
$sortedResults = $results | Sort-Object -Property Status, ResponseTime

# Calcul des statistiques
$onlineCount = ($results | Where-Object { $_.Status -eq "Online" }).Count
$offlineCount = ($results | Where-Object { $_.Status -eq "Offline" }).Count
$totalCount = $results.Count
$onlinePercentage = [math]::Round(($onlineCount / $totalCount) * 100, 2)

$averageResponseTime = $null
if ($onlineCount -gt 0) {
    $averageResponseTime = [math]::Round(($results | Where-Object { $_.Status -eq "Online" } | Measure-Object -Property ResponseTime -Average).Average, 0)
}

# Arrêt du chronomètre
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Boucle avec Runspaces - Test de connectivité:" -ForegroundColor Cyan
$sortedResults | Format-Table -AutoSize

Write-Host "Statistiques:" -ForegroundColor Yellow
Write-Host "Total de serveurs testés: $totalCount" -ForegroundColor Gray
Write-Host "Serveurs en ligne: $onlineCount ($onlinePercentage%)" -ForegroundColor Green
Write-Host "Serveurs hors ligne: $offlineCount" -ForegroundColor Red
if ($averageResponseTime) {
    Write-Host "Temps de réponse moyen: $averageResponseTime ms" -ForegroundColor Gray
}

Write-Host "`nTemps d'exécution total: $loopTime ms" -ForegroundColor Magenta

# Export des résultats en CSV
$sortedResults | Export-Csv -Path ".\LoopResults.csv" -NoTypeInformation
Write-Host "Résultats exportés dans LoopResults.csv" -ForegroundColor Gray
```

## Script de comparaison

```powershell
# Fichier: Exercise5-Comparison.ps1
#
# Requiert PowerShell 7+ pour les fonctionnalités de parallélisme
#

Write-Host "Comparaison des performances: Pipeline vs Boucle avec parallélisme" -ForegroundColor Magenta
Write-Host "=================================================================" -ForegroundColor Magenta

# Vérification de l'existence du fichier de serveurs
if (-not (Test-Path -Path ".\servers.txt")) {
    Write-Host "Fichier de serveurs non trouvé. Création d'une liste de test..." -ForegroundColor Yellow

    # Création d'une liste de serveurs/sites populaires pour les tests
    $servers = @(
        "google.com",
        "microsoft.com",
        "amazon.com",
        "cloudflare.com",
        "github.com",
        "stackoverflow.com",
        "youtube.com",
        "facebook.com",
        "wikipedia.org",
        "twitter.com"
    )

    # Ajout de quelques adresses qui ne répondront probablement pas
    $servers += @(
        "server-does-not-exist.com",
        "invalid-domain-123456.org"
    )

    # Écriture dans un fichier
    $servers | Out-File -FilePath ".\servers.txt" -Encoding utf8
    Write-Host "Liste de serveurs créée avec $(($servers).Count) entrées." -ForegroundColor Green
}

# Définition du nombre maximum de traitements parallèles
$maxParallelJobs = 10

# Test de l'approche Pipeline avec parallélisme
Write-Host "`nTest de l'approche Pipeline..." -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$servers = Get-Content -Path ".\servers.txt"
$resultsPipeline = $servers | ForEach-Object -ThrottleLimit $maxParallelJobs -Parallel {
    $server = $_
    $pingResult = Test-Connection -ComputerName $server -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue

    if ($pingResult) {
        [PSCustomObject]@{
            Server = $server
            Status = "Online"
            ResponseTime = $pingResult.Latency
            IPAddress = $pingResult.Address.IPAddressToString
            Timestamp = Get-Date
        }
    } else {
        [PSCustomObject]@{
            Server = $server
            Status = "Offline"
            ResponseTime = $null
            IPAddress = $null
            Timestamp = Get-Date
        }
    }
}
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Test de l'approche Boucle avec Runspaces
Write-Host "`nTest de l'approche Boucle avec Runspaces..." -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$servers = Get-Content -Path ".\servers.txt"
$resultsLoop = @()
$lock = [System.Threading.Mutex]::new($false)

$runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxParallelJobs)
$runspacePool.Open()

$jobs = @()
foreach ($server in $servers) {
    $scriptBlock = {
        param ($serverName, $resultArray, $mutex)

        $pingResult = Test-Connection -ComputerName $serverName -Count 1 -TimeoutSeconds 2 -ErrorAction SilentlyContinue

        $result = if ($pingResult) {
            [PSCustomObject]@{
                Server = $serverName
                Status = "Online"
                ResponseTime = $pingResult.Latency
                IPAddress = $pingResult.Address.IPAddressToString
                Timestamp = Get-Date
            }
        } else {
            [PSCustomObject]@{
                Server = $serverName
                Status = "Offline"
                ResponseTime = $null
                IPAddress = $null
                Timestamp = Get-Date
            }
        }

        $mutex.WaitOne() | Out-Null
        $resultArray.Add($result)
        $mutex.ReleaseMutex()
    }

    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($server).AddArgument([System.Collections.ArrayList]$resultsLoop).AddArgument($lock)
    $powershell.RunspacePool = $runspacePool

    $jobs += [PSCustomObject]@{
        PowerShell = $powershell
        Handle = $powershell.BeginInvoke()
    }
}

foreach ($job in $jobs) {
    $job.PowerShell.EndInvoke($job.Handle)
    $job.PowerShell.Dispose()
}

$runspacePool.Close()
$runspacePool.Dispose()
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats de la comparaison
Write-Host "`nRésultats de la comparaison:" -ForegroundColor Cyan
Write-Host "Temps d'exécution Pipeline avec ForEach-Object -Parallel: $pipelineTime ms" -ForegroundColor Green
Write-Host "Temps d'exécution Boucle avec Runspaces: $loopTime ms" -ForegroundColor Yellow
Write-Host "Différence: $('{0:N2}' -f ($loopTime - $pipelineTime)) ms" -ForegroundColor Magenta

if ($pipelineTime -lt $loopTime) {
    Write-Host "Le pipeline est plus rapide de $('{0:N2}' -f (($loopTime - $pipelineTime) / $loopTime * 100))%" -ForegroundColor Cyan
} else {
    Write-Host "La boucle est plus rapide de $('{0:N2}' -f (($pipelineTime - $loopTime) / $pipelineTime * 100))%" -ForegroundColor Cyan
}

# Vérification des résultats
$pipelineOnlineCount = ($resultsPipeline | Where-Object { $_.Status -eq "Online" }).Count
$loopOnlineCount = ($resultsLoop | Where-Object { $_.Status -eq "Online" }).Count

Write-Host "`nVérification des résultats:" -ForegroundColor Yellow
Write-Host "Serveurs en ligne trouvés (Pipeline): $pipelineOnlineCount" -ForegroundColor Green
Write-Host "Serveurs en ligne trouvés (Boucle): $loopOnlineCount" -ForegroundColor Yellow

if ($pipelineOnlineCount -eq $loopOnlineCount) {
    Write-Host "Les deux approches ont trouvé le même nombre de serveurs en ligne." -ForegroundColor Green
} else {
    Write-Host "Les deux approches ont trouvé un nombre différent de serveurs en ligne!" -ForegroundColor Red

    # Affichage des différences si nécessaire
    $pipelineOnlineServers = ($resultsPipeline | Where-Object { $_.Status -eq "Online" }).Server
    $loopOnlineServers = ($resultsLoop | Where-Object { $_.Status -eq "Online" }).Server

    $onlyInPipeline = Compare-Object -ReferenceObject $pipelineOnlineServers -DifferenceObject $loopOnlineServers | Where-Object { $_.SideIndicator -eq "<=" } | Select-Object -ExpandProperty InputObject
    $onlyInLoop = Compare-Object -ReferenceObject $pipelineOnlineServers -DifferenceObject $loopOnlineServers | Where-Object { $_.SideIndicator -eq "=>" } | Select-Object -ExpandProperty InputObject

    if ($onlyInPipeline.Count -gt 0) {
        Write-Host "Serveurs trouvés en ligne uniquement par Pipeline: $($onlyInPipeline -join ', ')" -ForegroundColor Yellow
    }

    if ($onlyInLoop.Count -gt 0) {
        Write-Host "Serveurs trouvés en ligne uniquement par Boucle: $($onlyInLoop -join ', ')" -ForegroundColor Yellow
    }
}
```

## Analyse des résultats

Cet exercice illustre l'utilisation du parallélisme dans PowerShell, qui est essentiel pour les opérations intensives ou les traitements réseau:

1. **Approches de parallélisme**:
   - **Pipeline**: Utilise `ForEach-Object -Parallel` (PowerShell 7+)
   - **Boucle**: Utilise les Runspaces pour un contrôle plus fin

2. **Performance**:
   - Les deux approches offrent une amélioration significative par rapport à l'exécution séquentielle
   - `ForEach-Object -Parallel` est généralement plus simple à utiliser
   - Les Runspaces offrent plus de contrôle mais sont plus complexes à mettre en œuvre

3. **Différences techniques**:
   - Le pipeline avec `-Parallel` gère automatiquement la synchronisation
   - La solution avec Runspaces nécessite un mutex explicite pour protéger les accès concurrents
   - Les Runspaces sont légèrement plus rapides mais nécessitent plus de code

4. **Cas d'utilisation**:
   - Tests de connectivité réseau
   - Inventaire d'infrastructure
   - Surveillance de serveurs
   - Opérations intensives sur plusieurs ressources

5. **Considérations importantes**:
   - Limiter le nombre de tâches parallèles pour éviter la surcharge du système
   - Gérer correctement les exceptions dans le code parallèle
   - Protéger les ressources partagées (tableaux, fichiers, etc.)

Cette comparaison montre que PowerShell 7+ offre des mécanismes puissants pour paralléliser les tâches. Pour des scripts simples, `ForEach-Object -Parallel` est souvent le meilleur choix en raison de sa simplicité. Pour des scénarios plus complexes ou des performances optimales, l'utilisation directe des Runspaces peut être préférable.


# Solution Exercice 6 - Traitement de fichiers XML avec Pipeline vs Boucle

## Énoncé
Créez deux scripts PowerShell qui traitent un fichier XML contenant des informations sur des produits (nom, catégorie, prix, stock). Les scripts doivent extraire tous les produits, calculer la valeur totale de l'inventaire par catégorie, et identifier les produits à réapprovisionner (stock < 10). Utilisez une approche avec pipeline dans le premier script et une approche avec boucle dans le second, puis comparez les performances.

## Création d'un fichier XML de test

```powershell
# Fichier: Create-ProductsXML.ps1

# Définition des catégories
$categories = @("Électronique", "Informatique", "Vêtements", "Alimentation", "Maison", "Jardin", "Sports", "Jouets")

# Création du document XML
$xmlDoc = New-Object System.Xml.XmlDocument
$declaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
$xmlDoc.AppendChild($declaration) | Out-Null

# Création de l'élément racine
$root = $xmlDoc.CreateElement("Inventaire")
$xmlDoc.AppendChild($root) | Out-Null

# Génération de 200 produits
for ($i = 1; $i -le 200; $i++) {
    # Création d'un élément produit
    $product = $xmlDoc.CreateElement("Produit")
    $product.SetAttribute("id", $i)

    # Ajout des éléments enfants
    $name = $xmlDoc.CreateElement("Nom")
    $name.InnerText = "Produit $i"
    $product.AppendChild($name) | Out-Null

    $category = $xmlDoc.CreateElement("Categorie")
    $category.InnerText = $categories[Get-Random -Minimum 0 -Maximum $categories.Count]
    $product.AppendChild($category) | Out-Null

    $price = $xmlDoc.CreateElement("Prix")
    $price.InnerText = [math]::Round((Get-Random -Minimum 5 -Maximum 500) + (Get-Random -Minimum 0 -Maximum 100) / 100, 2)
    $product.AppendChild($price) | Out-Null

    $stock = $xmlDoc.CreateElement("Stock")
    # Assurer quelques produits à faible stock pour le réapprovisionnement
    if ($i % 7 -eq 0) {
        $stock.InnerText = Get-Random -Minimum 1 -Maximum 10
    } else {
        $stock.InnerText = Get-Random -Minimum 10 -Maximum 100
    }
    $product.AppendChild($stock) | Out-Null

    $dateAdded = $xmlDoc.CreateElement("DateAjout")
    $dateAdded.InnerText = (Get-Date).AddDays(-1 * (Get-Random -Minimum 0 -Maximum 365)).ToString("yyyy-MM-dd")
    $product.AppendChild($dateAdded) | Out-Null

    # Ajout du produit à la racine
    $root.AppendChild($product) | Out-Null
}

# Sauvegarde du document XML
$xmlDoc.Save(".\produits.xml")
Write-Host "Fichier XML créé avec 200 produits." -ForegroundColor Green
```

## Solution avec Pipeline

```powershell
# Fichier: Exercise6-Pipeline.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Chargement du fichier XML
$xmlData = [xml](Get-Content -Path ".\produits.xml")

# Utilisation du pipeline pour analyser les produits
$productsPipeline = $xmlData.Inventaire.Produit |
    ForEach-Object {
        [PSCustomObject]@{
            ID = $_.id
            Nom = $_.Nom
            Categorie = $_.Categorie
            Prix = [double]$_.Prix
            Stock = [int]$_.Stock
            DateAjout = [DateTime]::Parse($_.DateAjout)
            ValeurTotale = [double]$_.Prix * [int]$_.Stock
            NecessiteReapprovisionnement = [int]$_.Stock -lt 10
        }
    }

# Calcul de la valeur d'inventaire par catégorie
$inventaireParCategorie = $productsPipeline |
    Group-Object -Property Categorie |
    ForEach-Object {
        [PSCustomObject]@{
            Categorie = $_.Name
            NombreProduits = $_.Count
            ValeurTotale = [math]::Round(($_.Group | Measure-Object -Property ValeurTotale -Sum).Sum, 2)
            StockMoyen = [math]::Round(($_.Group | Measure-Object -Property Stock -Average).Average, 1)
        }
    } |
    Sort-Object -Property ValeurTotale -Descending

# Identification des produits à réapprovisionner
$produitsAReapprovisionner = $productsPipeline |
    Where-Object { $_.NecessiteReapprovisionnement } |
    Sort-Object -Property Stock, Categorie

# Arrêt du chronomètre
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Pipeline - Analyse des produits XML:" -ForegroundColor Cyan
Write-Host "`nValeur d'inventaire par catégorie:" -ForegroundColor Yellow
$inventaireParCategorie | Format-Table -AutoSize

Write-Host "`nProduits à réapprovisionner (stock < 10):" -ForegroundColor Yellow
$produitsAReapprovisionner | Format-Table ID, Nom, Categorie, Prix, Stock, ValeurTotale -AutoSize

# Statistiques générales
$totalProducts = $productsPipeline.Count
$totalValue = [math]::Round(($productsPipeline | Measure-Object -Property ValeurTotale -Sum).Sum, 2)
$lowStockCount = $produitsAReapprovisionner.Count
$lowStockPercentage = [math]::Round(($lowStockCount / $totalProducts) * 100, 1)

Write-Host "`nStatistiques générales:" -ForegroundColor Yellow
Write-Host "Nombre total de produits: $totalProducts" -ForegroundColor Gray
Write-Host "Valeur totale de l'inventaire: $totalValue €" -ForegroundColor Gray
Write-Host "Produits à réapprovisionner: $lowStockCount ($lowStockPercentage%)" -ForegroundColor Gray

Write-Host "`nTemps d'exécution: $pipelineTime ms" -ForegroundColor Green
```

## Solution avec Boucle

```powershell
# Fichier: Exercise6-Loop.ps1

# Début du chronomètre
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Chargement du fichier XML
$xmlData = [xml](Get-Content -Path ".\produits.xml")

# Utilisation d'une boucle pour analyser les produits
$productsLoop = @()
$categorySummary = @{}

foreach ($product in $xmlData.Inventaire.Produit) {
    # Conversion des données
    $id = $product.id
    $name = $product.Nom
    $category = $product.Categorie
    $price = [double]$product.Prix
    $stock = [int]$product.Stock
    $dateAdded = [DateTime]::Parse($product.DateAjout)
    $totalValue = $price * $stock
    $needsRestock = $stock -lt 10

    # Création d'un objet produit
    $productObject = [PSCustomObject]@{
        ID = $id
        Nom = $name
        Categorie = $category
        Prix = $price
        Stock = $stock
        DateAjout = $dateAdded
        ValeurTotale = $totalValue
        NecessiteReapprovisionnement = $needsRestock
    }

    # Ajout du produit à la liste
    $productsLoop += $productObject

    # Mise à jour des statistiques par catégorie
    if (-not $categorySummary.ContainsKey($category)) {
        $categorySummary[$category] = @{
            NombreProduits = 0
            ValeurTotale = 0
            StockTotal = 0
        }
    }

    $categorySummary[$category].NombreProduits++
    $categorySummary[$category].ValeurTotale += $totalValue
    $categorySummary[$category].StockTotal += $stock
}

# Transformation du dictionnaire en objets pour l'inventaire par catégorie
$inventaireParCategorie = @()
foreach ($category in $categorySummary.Keys) {
    $inventaireParCategorie += [PSCustomObject]@{
        Categorie = $category
        NombreProduits = $categorySummary[$category].NombreProduits
        ValeurTotale = [math]::Round($categorySummary[$category].ValeurTotale, 2)
        StockMoyen = [math]::Round($categorySummary[$category].StockTotal / $categorySummary[$category].NombreProduits, 1)
    }
}

# Tri de l'inventaire par valeur décroissante
$inventaireParCategorie = $inventaireParCategorie | Sort-Object -Property ValeurTotale -Descending

# Identification des produits à réapprovisionner
$produitsAReapprovisionner = @()
foreach ($product in $productsLoop) {
    if ($product.NecessiteReapprovisionnement) {
        $produitsAReapprovisionner += $product
    }
}

# Tri des produits à réapprovisionner
$produitsAReapprovisionner = $produitsAReapprovisionner | Sort-Object -Property Stock, Categorie

# Arrêt du chronomètre
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats
Write-Host "Approche Boucle - Analyse des produits XML:" -ForegroundColor Cyan
Write-Host "`nValeur d'inventaire par catégorie:" -ForegroundColor Yellow
$inventaireParCategorie | Format-Table -AutoSize

Write-Host "`nProduits à réapprovisionner (stock < 10):" -ForegroundColor Yellow
$produitsAReapprovisionner | Format-Table ID, Nom, Categorie, Prix, Stock, ValeurTotale -AutoSize

# Statistiques générales
$totalProducts = $productsLoop.Count
$totalValue = [math]::Round(($productsLoop | Measure-Object -Property ValeurTotale -Sum).Sum, 2)
$lowStockCount = $produitsAReapprovisionner.Count
$lowStockPercentage = [math]::Round(($lowStockCount / $totalProducts) * 100, 1)

Write-Host "`nStatistiques générales:" -ForegroundColor Yellow
Write-Host "Nombre total de produits: $totalProducts" -ForegroundColor Gray
Write-Host "Valeur totale de l'inventaire: $totalValue €" -ForegroundColor Gray
Write-Host "Produits à réapprovisionner: $lowStockCount ($lowStockPercentage%)" -ForegroundColor Gray

Write-Host "`nTemps d'exécution: $loopTime ms" -ForegroundColor Green
```

## Script de comparaison

```powershell
# Fichier: Exercise6-Comparison.ps1

Write-Host "Comparaison des performances: Pipeline vs Boucle pour le traitement XML" -ForegroundColor Magenta
Write-Host "==================================================================" -ForegroundColor Magenta

# Vérification de l'existence du fichier XML
if (-not (Test-Path -Path ".\produits.xml")) {
    Write-Host "Fichier XML non trouvé. Exécutez d'abord Create-ProductsXML.ps1" -ForegroundColor Yellow
    exit
}

# Test de l'approche Pipeline
Write-Host "`nTest de l'approche Pipeline..." -ForegroundColor Cyan
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$xmlData = [xml](Get-Content -Path ".\produits.xml")
$productsPipeline = $xmlData.Inventaire.Produit |
    ForEach-Object {
        [PSCustomObject]@{
            ID = $_.id
            Nom = $_.Nom
            Categorie = $_.Categorie
            Prix = [double]$_.Prix
            Stock = [int]$_.Stock
            DateAjout = [DateTime]::Parse($_.DateAjout)
            ValeurTotale = [double]$_.Prix * [int]$_.Stock
            NecessiteReapprovisionnement = [int]$_.Stock -lt 10
        }
    }

$inventairePipelineParCategorie = $productsPipeline |
    Group-Object -Property Categorie |
    ForEach-Object {
        [PSCustomObject]@{
            Categorie = $_.Name
            NombreProduits = $_.Count
            ValeurTotale = [math]::Round(($_.Group | Measure-Object -Property ValeurTotale -Sum).Sum, 2)
        }
    }

$restockPipeline = ($productsPipeline | Where-Object { $_.NecessiteReapprovisionnement }).Count
$stopwatch.Stop()
$pipelineTime = $stopwatch.Elapsed.TotalMilliseconds

# Test de l'approche Boucle
Write-Host "`nTest de l'approche Boucle..." -ForegroundColor Yellow
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$xmlData = [xml](Get-Content -Path ".\produits.xml")
$productsLoop = @()
$categorySummary = @{}

foreach ($product in $xmlData.Inventaire.Produit) {
    $id = $product.id
    $name = $product.Nom
    $category = $product.Categorie
    $price = [double]$product.Prix
    $stock = [int]$product.Stock
    $dateAdded = [DateTime]::Parse($product.DateAjout)
    $totalValue = $price * $stock
    $needsRestock = $stock -lt 10

    $productObject = [PSCustomObject]@{
        ID = $id
        Nom = $name
        Categorie = $category
        Prix = $price
        Stock = $stock
        DateAjout = $dateAdded
        ValeurTotale = $totalValue
        NecessiteReapprovisionnement = $needsRestock
    }

    $productsLoop += $productObject

    if (-not $categorySummary.ContainsKey($category)) {
        $categorySummary[$category] = @{
            NombreProduits = 0
            ValeurTotale = 0
        }
    }

    $categorySummary[$category].NombreProduits++
    $categorySummary[$category].ValeurTotale += $totalValue
}

$inventaireLoopParCategorie = @()
foreach ($category in $categorySummary.Keys) {
    $inventaireLoopParCategorie += [PSCustomObject]@{
        Categorie = $category
        NombreProduits = $categorySummary[$category].NombreProduits
        ValeurTotale = [math]::Round($categorySummary[$category].ValeurTotale, 2)
    }
}

$restockLoop = ($productsLoop | Where-Object { $_.NecessiteReapprovisionnement }).Count
$stopwatch.Stop()
$loopTime = $stopwatch.Elapsed.TotalMilliseconds

# Affichage des résultats de la comparaison
Write-Host "`nRésultats de la comparaison:" -ForegroundColor Cyan
Write-Host "Temps d'exécution Pipeline: $pipelineTime ms" -ForegroundColor Green
Write-Host "Temps d'exécution Boucle: $loopTime ms" -ForegroundColor Yellow
Write-Host "Différence: $('{0:N2}' -f ($loopTime - $pipelineTime)) ms" -ForegroundColor Magenta

if ($pipelineTime -lt $loopTime) {
    Write-Host "Le pipeline est plus rapide de $('{0:N2}' -f (($loopTime - $pipelineTime) / $loopTime * 100))%" -ForegroundColor Cyan
} else {
    Write-Host "La boucle est plus rapide de $('{0:N2}' -f (($pipelineTime - $loopTime) / $pipelineTime * 100))%" -ForegroundColor Cyan
}

# Vérification des résultats
Write-Host "`nVérification des résultats:" -ForegroundColor Yellow
Write-Host "Nombre total de produits: $($productsPipeline.Count)" -ForegroundColor Gray
Write-Host "Nombre de produits à réapprovisionner (Pipeline): $restockPipeline" -ForegroundColor Green
Write-Host "Nombre de produits à réapprovisionner (Boucle): $restockLoop" -ForegroundColor Yellow

$pipelineCategories = $inventairePipelineParCategorie | ForEach-Object { "$($_.Categorie): $($_.ValeurTotale)" }
$loopCategories = $inventaireLoopParCategorie | ForEach-Object { "$($_.Categorie): $($_.ValeurTotale)" }

$categoriesDiff = Compare-Object -ReferenceObject $pipelineCategories -DifferenceObject $loopCategories

if ($categoriesDiff) {
    Write-Host "`nDifférences trouvées dans les valeurs par catégorie:" -ForegroundColor Red
    $categoriesDiff | Format-Table -AutoSize
} else {
    Write-Host "`nLes deux approches ont calculé les mêmes valeurs d'inventaire par catégorie." -ForegroundColor Green
}

# Affichage d'un résumé des inventaires
Write-Host "`nRésumé de l'inventaire par catégorie:" -ForegroundColor Cyan
$inventairePipelineParCategorie | Format-Table -AutoSize
```

## Analyse des résultats

Cette comparaison de traitement XML illustre plusieurs points importants:

1. **Performance**:
   - Pour le traitement XML, la boucle est souvent plus rapide car:
     - Elle ne crée qu'une seule structure de données pour les statistiques par catégorie
     - Elle ne fait qu'une seule passe sur les données XML
   - Le pipeline est plus déclaratif mais crée plusieurs objets intermédiaires

2. **Structure du code**:
   - L'approche pipeline est plus concise et utilise des cmdlets spécialisées comme `Group-Object`
   - L'approche avec boucle utilise un dictionnaire pour accumuler les résultats, ce qui est efficace
   - Les deux approches nécessitent une conversion des types de données (string → double, int, DateTime)

3. **Lisibilité et maintenabilité**:
   - Le pipeline exprime plus clairement l'intention de l'analyse
   - La boucle permet un contrôle plus fin de la logique d'accumulation

4. **Cas d'utilisation réels**:
   - L'analyse d'inventaire est courante dans les environnements de commerce électronique
   - Le traitement XML est fréquent pour les interfaces avec d'autres systèmes
   - Les deux approches permettent de produire des rapports détaillés et des alertes

5. **Points d'optimisation**:
   - Pour des fichiers XML très volumineux, l'utilisation d'un parseur de flux (streaming) serait préférable aux deux approches
   - Le pré-filtrage des données XML avant la conversion en objets peut améliorer les performances
   - L'utilisation de XPath pour des requêtes ciblées peut être plus efficace que le traitement complet

Dans ce scénario, bien que les deux approches puissent traiter efficacement des données XML de taille modérée, la boucle offre généralement de meilleures performances pour les calculs d'agrégation comme la valeur d'inventaire par catégorie, car elle peut accumuler ces données en une seule passe.

# Synthèse des exercices - Pipeline vs Boucles dans PowerShell

## Résumé des exercices

Les six exercices présentés couvrent différents aspects de la comparaison entre le pipeline PowerShell et les boucles traditionnelles:

1. **Exercice 1 - Filtrage de fichiers**: Analyse des fichiers DLL dans un dossier système
   - Concepts: Filtrage, tri, calcul de propriétés
   - Résultat typique: Le pipeline est généralement plus rapide et plus concis

2. **Exercice 2 - Traitement de données CSV**: Calcul de statistiques à partir de données CSV
   - Concepts: Groupement, agrégation, calcul de moyennes
   - Résultat typique: La boucle est souvent plus performante pour les agrégations

3. **Exercice 3 - Traitement de logs**: Analyse de fichiers de logs avec expressions régulières
   - Concepts: Expressions régulières, extraction de motifs, analyse temporelle
   - Résultat typique: La boucle permet un meilleur contrôle et de meilleures performances

4. **Exercice 4 - Monitoring de processus**: Analyse des processus en cours d'exécution
   - Concepts: Interrogation système, calcul de pourcentages, rapports
   - Résultat typique: Le pipeline est plus performant pour les requêtes système simples

5. **Exercice 5 - Traitement parallèle**: Tests de connectivité réseau parallélisés
   - Concepts: Parallélisme, runspaces, optimisation des tâches I/O
   - Résultat typique: Les deux approches offrent des avantages spécifiques en environnement parallèle

6. **Exercice 6 - Traitement XML**: Analyse d'inventaire à partir de données XML
   - Concepts: Manipulation XML, calculs d'inventaire, agrégation
   - Résultat typique: La boucle est souvent plus efficace pour le traitement XML complexe

## Leçons clés à retenir

### Quand favoriser le pipeline

1. **Manipulation de collections simples**
   - Filtrage, tri, sélection d'un sous-ensemble d'objets
   - Transformations simples d'objets

2. **Opérations séquentielles claires**
   - Quand les étapes peuvent être représentées comme une chaîne d'opérations
   - Traitement de données "en flux"

3. **Utilisation de cmdlets natives**
   - Lorsque vous travaillez avec des commandes PowerShell optimisées
   - Pour des opérations système (processus, services, fichiers)

4. **Lisibilité et maintenabilité**
   - Quand l'intention du code doit être claire
   - Pour des scripts partagés en équipe

### Quand favoriser les boucles

1. **Logique complexe ou conditionnelle**
   - Lorsque vous avez besoin de contrôle de flux avancé (break, continue)
   - Conditions imbriquées ou logique complexe

2. **Accumulation efficace de résultats**
   - Utilisation de dictionnaires ou hashtables pour agréger des données
   - Calculs qui nécessitent une seule passe sur les données

3. **Contrôle précis des exceptions**
   - Gestion fine des erreurs à chaque étape
   - Journalisation détaillée du traitement

4. **Opérations personnalisées complexes**
   - Algorithmes spécifiques qui ne s'adaptent pas bien au modèle de pipeline
   - Logique métier avancée

## Approche hybride recommandée

Dans la pratique, une approche hybride est souvent la plus efficace:

```powershell
# Exemple d'approche hybride
# 1. Utilisation du pipeline pour la récupération et le filtrage initial
$donnees = Get-SomeData | Where-Object { $_.Condition } | Select-Object -First 100

# 2. Traitement complexe avec une boucle
$resultats = @{}
foreach ($item in $donnees) {
    # Logique complexe, accumulation, etc.
    if (!$resultats.ContainsKey($item.Categorie)) {
        $resultats[$item.Categorie] = 0
    }
    $resultats[$item.Categorie] += $item.Valeur
}

# 3. Utilisation du pipeline pour le formatage final
$resultats.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    Select-Object -First 10 |
    Format-Table -AutoSize
```

## Conseils pour l'optimisation des performances

1. **Mesurer avant d'optimiser**
   - Utilisez `Measure-Command` pour comparer objectivement les approches
   - Ne présumez pas qu'une approche est toujours meilleure

2. **Considérer la taille des données**
   - Pour de petits ensembles de données, privilégiez la lisibilité
   - Pour de grands ensembles, testez les deux approches

3. **Pré-filtrage des données**
   - Filtrez les données le plus tôt possible dans la chaîne de traitement
   - Utilisez les capacités de filtrage natif des sources (SQL, API, etc.)

4. **Mémoire vs CPU**
   - Les boucles peuvent être plus économes en mémoire mais plus intensives en CPU
   - Le pipeline crée généralement plus d'objets intermédiaires

5. **Parallélisme intelligent**
   - Utilisez `ForEach-Object -Parallel` (PowerShell 7+) pour des tâches indépendantes
   - Limitez le nombre de tâches parallèles à un niveau raisonnable

## Conclusion

Le choix entre pipeline et boucles dans PowerShell dépend du contexte et des exigences spécifiques:

- **Le pipeline** offre une syntaxe élégante et expressive, idéale pour les transformations de données en chaîne et l'administration système quotidienne.

- **Les boucles** offrent plus de contrôle et sont souvent plus performantes pour l'agrégation de données et les logiques complexes.

- **L'approche hybride** combine le meilleur des deux mondes et représente souvent la solution optimale dans des scénarios réels.

La maîtrise des deux approches est essentielle pour tout administrateur ou développeur PowerShell, permettant de choisir la meilleure technique selon le scénario et les besoins de performance.

