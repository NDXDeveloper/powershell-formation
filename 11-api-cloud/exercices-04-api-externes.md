# Solution Exercice 1 - Lister les repositories GitHub non mis à jour depuis plus de 6 mois

## Objectif
Créer un script qui liste tous vos repositories GitHub et affiche ceux qui n'ont pas été mis à jour depuis plus de 6 mois.

## Solution complète
Ci-dessous le script PowerShell complet pour résoudre cet exercice :

```powershell
<#
.SYNOPSIS
    Ce script liste tous vos repositories GitHub et identifie ceux qui n'ont pas été mis à jour depuis plus de 6 mois.

.DESCRIPTION
    Le script se connecte à l'API GitHub, récupère tous les repositories de l'utilisateur,
    puis identifie et affiche ceux qui n'ont pas été mis à jour depuis plus de 6 mois.
    Les résultats sont affichés à l'écran et peuvent optionnellement être exportés en CSV.

.PARAMETER Token
    Token d'accès personnel GitHub (Personal Access Token) avec les droits 'repo'.

.PARAMETER ExportCsv
    Chemin optionnel pour exporter les résultats en CSV.

.EXAMPLE
    .\GitHub-ReposInactifs.ps1 -Token "ghp_votreTOKENpersonnel"

.EXAMPLE
    .\GitHub-ReposInactifs.ps1 -Token "ghp_votreTOKENpersonnel" -ExportCsv "C:\Rapports\repos-inactifs.csv"
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Token,

    [Parameter(Mandatory = $false)]
    [string]$ExportCsv
)

# Configuration pour l'API GitHub
$headers = @{
    Authorization = "token $Token"
    Accept = "application/vnd.github.v3+json"
}

# Date limite (6 mois dans le passé)
$dateLimite = (Get-Date).AddMonths(-6)

try {
    # Récupérer les informations de l'utilisateur connecté
    $user = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers -ErrorAction Stop
    Write-Host "Connecté en tant que: $($user.login)" -ForegroundColor Cyan

    # Récupérer tous les repositories (y compris les privés)
    Write-Host "Récupération des repositories..." -ForegroundColor Yellow
    $allRepos = @()
    $page = 1
    $perPage = 100

    do {
        $repos = Invoke-RestMethod -Uri "https://api.github.com/user/repos?page=$page&per_page=$perPage" -Headers $headers
        $allRepos += $repos
        $page++
    } while ($repos.Count -eq $perPage)

    Write-Host "Total de repositories trouvés: $($allRepos.Count)" -ForegroundColor Green

    # Identifier les repositories non mis à jour depuis plus de 6 mois
    $reposInactifs = $allRepos | Where-Object {
        $lastUpdate = [DateTime]::Parse($_.pushed_at)
        $lastUpdate -lt $dateLimite
    } | Select-Object name, html_url, pushed_at, @{
        Name = "JoursDepuisDerniereMiseAJour"
        Expression = { [math]::Round((New-TimeSpan -Start ([DateTime]::Parse($_.pushed_at)) -End (Get-Date)).TotalDays) }
    }, private, language, description

    # Afficher les résultats
    if ($reposInactifs.Count -eq 0) {
        Write-Host "Aucun repository inactif trouvé!" -ForegroundColor Green
    }
    else {
        Write-Host "`nRepositories inactifs ($($reposInactifs.Count)):" -ForegroundColor Yellow
        $reposInactifs | Sort-Object JoursDepuisDerniereMiseAJour -Descending | Format-Table -AutoSize name, @{
            Label = "Dernière MàJ"
            Expression = { [DateTime]::Parse($_.pushed_at).ToString("yyyy-MM-dd") }
        }, JoursDepuisDerniereMiseAJour, language

        # Exporter en CSV si demandé
        if ($ExportCsv) {
            try {
                $reposInactifs | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
                Write-Host "Résultats exportés vers: $ExportCsv" -ForegroundColor Green
            }
            catch {
                Write-Host "Erreur lors de l'export CSV: $_" -ForegroundColor Red
            }
        }

        # Afficher un résumé détaillé
        Write-Host "`nRésumé:" -ForegroundColor Cyan
        Write-Host "- Repositories totaux: $($allRepos.Count)" -ForegroundColor White
        Write-Host "- Repositories inactifs: $($reposInactifs.Count) ($([math]::Round($reposInactifs.Count * 100 / $allRepos.Count))%)" -ForegroundColor Yellow

        # Repository le plus ancien
        if ($reposInactifs.Count -gt 0) {
            $plusAncien = $reposInactifs | Sort-Object JoursDepuisDerniereMiseAJour -Descending | Select-Object -First 1
            Write-Host "- Repository le plus ancien: $($plusAncien.name) (Dernière MàJ: $([DateTime]::Parse($plusAncien.pushed_at).ToString("yyyy-MM-dd")), $($plusAncien.JoursDepuisDerniereMiseAJour) jours)" -ForegroundColor Yellow
        }
    }
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMessage = $_.ErrorDetails.Message

    if ($statusCode -eq 401) {
        Write-Host "Erreur d'authentification. Vérifiez votre token GitHub." -ForegroundColor Red
    }
    elseif ($statusCode -eq 403) {
        Write-Host "Accès refusé. Vérifiez les permissions de votre token ou les limites d'API." -ForegroundColor Red
    }
    else {
        Write-Host "Erreur ($statusCode): $errorMessage" -ForegroundColor Red
    }
}
```

## Explication du script

1. **Authentification GitHub** : Le script prend en paramètre un token d'accès personnel GitHub pour s'authentifier à l'API.

2. **Récupération des repositories** : Utilise `Invoke-RestMethod` pour interroger l'API GitHub et récupérer tous les repositories de l'utilisateur, y compris les privés.

3. **Pagination** : Le script gère la pagination pour récupérer tous les repositories, même si l'utilisateur en a plus de 100.

4. **Filtrage** : Identifie les repositories qui n'ont pas été mis à jour depuis plus de 6 mois en comparant la date de dernière mise à jour avec la date limite calculée.

5. **Affichage des résultats** : Présente les repositories inactifs triés par ancienneté, avec des informations pertinentes comme le nombre de jours d'inactivité.

6. **Export CSV** : Permet d'exporter les résultats en CSV pour une analyse ultérieure.

7. **Statistiques** : Calcule et affiche des statistiques comme le pourcentage de repositories inactifs et identifie le repository le plus ancien.

8. **Gestion des erreurs** : Inclut une gestion des erreurs robuste avec des messages spécifiques selon le type d'erreur (authentification, limites d'API, etc.).

## Utilisation

Pour utiliser ce script :

1. Créez un token d'accès personnel GitHub avec les droits `repo` via les paramètres de votre compte GitHub.

2. Exécutez le script en fournissant votre token :
   ```powershell
   .\GitHub-ReposInactifs.ps1 -Token "ghp_votreTOKENpersonnel"
   ```

3. Vous pouvez également exporter les résultats en CSV :
   ```powershell
   .\GitHub-ReposInactifs.ps1 -Token "ghp_votreTOKENpersonnel" -ExportCsv "C:\Rapports\repos-inactifs.csv"
   ```

## Notes supplémentaires

- Ce script utilise l'API REST de GitHub, qui a des limites de taux d'utilisation. Si vous avez beaucoup de repositories, vous pourriez atteindre ces limites.
- Il est recommandé de stocker votre token de manière sécurisée et non en clair dans vos scripts pour un usage en production.
- Vous pouvez facilement modifier la période d'inactivité en ajustant la ligne `$dateLimite = (Get-Date).AddMonths(-6)` pour une période différente.


# Solution Exercice 2 - Afficher l'utilisation CPU des machines virtuelles Azure

## Objectif
Écrire un script qui affiche l'utilisation CPU des machines virtuelles Azure de votre abonnement.

## Solution complète
Ci-dessous le script PowerShell complet pour résoudre cet exercice :

```powershell
<#
.SYNOPSIS
    Affiche l'utilisation CPU des machines virtuelles dans votre abonnement Azure.

.DESCRIPTION
    Ce script se connecte à Azure, parcourt toutes les machines virtuelles disponibles
    dans votre abonnement et affiche leur utilisation CPU moyenne des dernières 24 heures.
    Les résultats sont affichés à l'écran et peuvent être exportés en CSV.

.PARAMETER SubscriptionId
    ID de l'abonnement Azure à interroger. Si non spécifié, utilise l'abonnement par défaut.

.PARAMETER ResourceGroupName
    Filtrer par groupe de ressources spécifique (facultatif).

.PARAMETER TimeframeHours
    Nombre d'heures à analyser (défaut: 24 heures).

.PARAMETER ExportCsv
    Chemin optionnel pour exporter les résultats en CSV.

.EXAMPLE
    .\Azure-VMCpuUsage.ps1

.EXAMPLE
    .\Azure-VMCpuUsage.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -ResourceGroupName "Production" -TimeframeHours 48
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $false)]
    [int]$TimeframeHours = 24,

    [Parameter(Mandatory = $false)]
    [string]$ExportCsv
)

# Fonction pour vérifier si le module Az est installé
function Test-AzModule {
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Write-Host "Le module Az n'est pas installé. Installation en cours..." -ForegroundColor Yellow
        try {
            Install-Module -Name Az -Repository PSGallery -Force -AllowClobber
        }
        catch {
            Write-Host "Erreur lors de l'installation du module Az. Veuillez l'installer manuellement avec: Install-Module -Name Az -Repository PSGallery" -ForegroundColor Red
            exit 1
        }
    }
}

# Fonction pour formater l'utilisation CPU avec une barre de progression
function Format-CpuBar {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Percentage
    )

    $barLength = 20
    $filledLength = [math]::Round($Percentage * $barLength / 100)
    $emptyLength = $barLength - $filledLength

    $bar = "[" + "■" * $filledLength + " " * $emptyLength + "]"

    # Couleur basée sur le pourcentage
    if ($Percentage -lt 30) {
        $color = "Green"
    }
    elseif ($Percentage -lt 70) {
        $color = "Yellow"
    }
    else {
        $color = "Red"
    }

    return @{
        Bar = $bar
        Color = $color
    }
}

# Vérifier le module Az
Test-AzModule

# Se connecter à Azure
Write-Host "Connexion à Azure..." -ForegroundColor Cyan
try {
    # Vérifier si déjà connecté
    $context = Get-AzContext -ErrorAction SilentlyContinue
    if (-not $context) {
        Connect-AzAccount -ErrorAction Stop
    }
    else {
        Write-Host "Déjà connecté en tant que: $($context.Account)" -ForegroundColor Green
    }
}
catch {
    Write-Host "Erreur lors de la connexion à Azure: $_" -ForegroundColor Red
    exit 1
}

# Sélectionner l'abonnement
if ($SubscriptionId) {
    try {
        Select-AzSubscription -SubscriptionId $SubscriptionId -ErrorAction Stop
        Write-Host "Abonnement sélectionné: $SubscriptionId" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la sélection de l'abonnement: $_" -ForegroundColor Red
        exit 1
    }
}
else {
    $sub = Get-AzContext
    Write-Host "Utilisation de l'abonnement actuel: $($sub.Subscription.Name) ($($sub.Subscription.Id))" -ForegroundColor Green
}

# Récupérer les machines virtuelles
Write-Host "Récupération des machines virtuelles..." -ForegroundColor Yellow
try {
    if ($ResourceGroupName) {
        $vms = Get-AzVM -ResourceGroupName $ResourceGroupName -Status -ErrorAction Stop
    }
    else {
        $vms = Get-AzVM -Status -ErrorAction Stop
    }

    if ($vms.Count -eq 0) {
        Write-Host "Aucune machine virtuelle trouvée." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Nombre de machines virtuelles trouvées: $($vms.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la récupération des machines virtuelles: $_" -ForegroundColor Red
    exit 1
}

# Préparer les plages de temps pour les métriques
$endTime = Get-Date
$startTime = $endTime.AddHours(-$TimeframeHours)

# Tableau pour stocker les résultats
$results = @()

# Récupérer les métriques CPU pour chaque VM
Write-Host "`nRécupération des métriques CPU pour les dernières $TimeframeHours heures..." -ForegroundColor Yellow
Write-Host "Période analysée: $startTime à $endTime`n" -ForegroundColor Cyan

foreach ($vm in $vms) {
    Write-Host "Traitement de: $($vm.Name)..." -NoNewline

    try {
        # Vérifier si la VM est en cours d'exécution
        $isRunning = $vm.PowerState -eq "VM running"

        if (-not $isRunning) {
            Write-Host " État: $($vm.PowerState) (Pas de métriques disponibles)" -ForegroundColor Gray
            $results += [PSCustomObject]@{
                Name = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                Location = $vm.Location
                Size = $vm.HardwareProfile.VmSize
                PowerState = $vm.PowerState
                OS = if ($vm.StorageProfile.OsDisk.OsType) { $vm.StorageProfile.OsDisk.OsType } else { "N/A" }
                CpuPercent = 0
                Status = "Arrêté"
            }
            continue
        }

        # Obtenir l'ID de ressource pour les métriques
        $resourceId = $vm.Id

        # Récupérer les métriques CPU
        $metrics = Get-AzMetric -ResourceId $resourceId -MetricName "Percentage CPU" `
                              -StartTime $startTime -EndTime $endTime `
                              -TimeGrain 01:00:00 -AggregationType Average `
                              -WarningAction SilentlyContinue

        # Calculer l'utilisation moyenne du CPU
        $cpuValues = $metrics.Data | Where-Object { $_.Average -ne $null } | Select-Object -ExpandProperty Average

        if ($cpuValues -and $cpuValues.Count -gt 0) {
            $avgCpu = [math]::Round(($cpuValues | Measure-Object -Average).Average, 2)
        }
        else {
            $avgCpu = 0
        }

        # Formater la barre de progression CPU
        $cpuBar = Format-CpuBar -Percentage $avgCpu

        # Afficher le résultat pour cette VM
        Write-Host " $($cpuBar.Bar) $avgCpu%" -ForegroundColor $cpuBar.Color

        # Ajouter aux résultats
        $results += [PSCustomObject]@{
            Name = $vm.Name
            ResourceGroup = $vm.ResourceGroupName
            Location = $vm.Location
            Size = $vm.HardwareProfile.VmSize
            PowerState = $vm.PowerState
            OS = if ($vm.StorageProfile.OsDisk.OsType) { $vm.StorageProfile.OsDisk.OsType } else { "N/A" }
            CpuPercent = $avgCpu
            Status = "En cours d'exécution"
        }
    }
    catch {
        Write-Host " Erreur: $_" -ForegroundColor Red
    }
}

# Afficher les résultats
Write-Host "`nRésumé de l'utilisation CPU (triés par utilisation):" -ForegroundColor Cyan
$results | Where-Object { $_.Status -eq "En cours d'exécution" } |
    Sort-Object -Property CpuPercent -Descending |
    Format-Table -Property Name, ResourceGroup, OS, Size, CpuPercent, Location -AutoSize

# Statistiques
$runningVMs = $results | Where-Object { $_.Status -eq "En cours d'exécution" }
if ($runningVMs.Count -gt 0) {
    $avgAllCpu = [math]::Round(($runningVMs.CpuPercent | Measure-Object -Average).Average, 2)
    $highCpuVMs = $runningVMs | Where-Object { $_.CpuPercent -gt 70 }

    Write-Host "Statistiques:" -ForegroundColor Yellow
    Write-Host "- VMs en cours d'exécution: $($runningVMs.Count) sur $($vms.Count)" -ForegroundColor White
    Write-Host "- Utilisation CPU moyenne globale: $avgAllCpu%" -ForegroundColor White
    Write-Host "- Nombre de VMs avec utilisation CPU > 70%: $($highCpuVMs.Count)" -ForegroundColor $(if ($highCpuVMs.Count -gt 0) { "Red" } else { "Green" })
}

# Exporter en CSV si demandé
if ($ExportCsv) {
    try {
        $results | Export-Csv -Path $ExportCsv -NoTypeInformation -Encoding UTF8
        Write-Host "`nRésultats exportés vers: $ExportCsv" -ForegroundColor Green
    }
    catch {
        Write-Host "`nErreur lors de l'export CSV: $_" -ForegroundColor Red
    }
}

Write-Host "`nAnalyse terminée!" -ForegroundColor Green
```

## Explication du script

1. **Vérification et installation des modules** : Le script vérifie d'abord si le module Azure PowerShell est installé et l'installe si nécessaire.

2. **Visualisation améliorée** : La fonction `Format-CpuBar` crée une barre de progression colorée pour visualiser rapidement l'utilisation CPU.

3. **Connexion à Azure** : Le script se connecte à Azure et gère intelligemment les connexions existantes.

4. **Filtrage flexible** : Vous pouvez filtrer par abonnement ou groupe de ressources spécifique.

5. **Détection de l'état des VMs** : Le script vérifie si chaque VM est en cours d'exécution avant d'essayer de récupérer des métriques.

6. **Récupération des métriques** : Utilisation de `Get-AzMetric` pour récupérer les données d'utilisation CPU sur la période définie.

7. **Analyse des données** : Calcul de l'utilisation moyenne du CPU pour chaque VM et pour l'ensemble de l'infrastructure.

8. **Rapports colorés** : Affichage des résultats avec un code couleur selon le niveau d'utilisation (vert pour faible, jaune pour moyen, rouge pour élevé).

9. **Export CSV** : Option pour exporter les résultats en CSV pour une analyse ultérieure.

## Utilisation

Pour utiliser ce script :

1. Assurez-vous d'avoir des droits suffisants sur votre abonnement Azure.

2. Exécutez le script sans paramètres pour analyser toutes les VMs de l'abonnement par défaut :
   ```powershell
   .\Azure-VMCpuUsage.ps1
   ```

3. Ou spécifiez un abonnement et un groupe de ressources particulier :
   ```powershell
   .\Azure-VMCpuUsage.ps1 -SubscriptionId "00000000-0000-0000-0000-000000000000" -ResourceGroupName "Production"
   ```

4. Vous pouvez également modifier la période d'analyse et exporter les résultats :
   ```powershell
   .\Azure-VMCpuUsage.ps1 -TimeframeHours 48 -ExportCsv "C:\Rapports\vm-cpu-usage.csv"
   ```

## Notes supplémentaires

- La collecte des métriques peut prendre du temps si vous avez de nombreuses machines virtuelles.
- Le script utilise l'agrégation horaire pour optimiser les performances, mais vous pouvez ajuster le paramètre `TimeGrain` pour une granularité différente.
- Pour les environnements de production, il est recommandé de configurer une authentification automatisée avec un principal de service plutôt que d'utiliser une connexion interactive.
- Ce script peut être programmé comme tâche planifiée pour surveiller régulièrement l'utilisation des ressources.




# Solution Exercice 3 - Rapport quotidien des activités d'une équipe Teams

## Objectif
Créer un script qui génère un rapport quotidien des activités d'une équipe Teams et l'envoie par email.

## Solution complète
Ci-dessous le script PowerShell complet pour résoudre cet exercice :

```powershell
<#
.SYNOPSIS
    Génère un rapport quotidien des activités d'une équipe Microsoft Teams et l'envoie par email.

.DESCRIPTION
    Ce script se connecte à Microsoft Teams, récupère les activités récentes d'une équipe spécifiée
    (messages, fichiers partagés, réunions), génère un rapport en HTML et l'envoie par email.
    Le rapport inclut des statistiques et des graphiques sur l'activité de l'équipe.

.PARAMETER TeamName
    Nom de l'équipe Teams pour laquelle générer le rapport.

.PARAMETER TeamId
    ID de l'équipe Teams (si le nom n'est pas unique).

.PARAMETER EmailTo
    Adresse(s) email à laquelle envoyer le rapport. Séparez plusieurs adresses par des virgules.

.PARAMETER SmtpServer
    Serveur SMTP à utiliser pour l'envoi de l'email.

.PARAMETER SmtpPort
    Port du serveur SMTP (défaut: 587).

.PARAMETER SmtpUser
    Nom d'utilisateur pour l'authentification SMTP.

.PARAMETER SmtpPassword
    Mot de passe pour l'authentification SMTP.

.PARAMETER UseSecureConnection
    Utiliser une connexion sécurisée pour l'envoi de l'email (SSL/TLS).

.EXAMPLE
    .\Teams-DailyReport.ps1 -TeamName "Projet X" -EmailTo "manager@company.com" -SmtpServer "smtp.company.com" -SmtpUser "reporting@company.com" -SmtpPassword "P@ssw0rd!"

.NOTES
    Requiert les modules MicrosoftTeams et Microsoft Graph SDK
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$TeamName,

    [Parameter(Mandatory = $false)]
    [string]$TeamId,

    [Parameter(Mandatory = $true)]
    [string]$EmailTo,

    [Parameter(Mandatory = $true)]
    [string]$SmtpServer,

    [Parameter(Mandatory = $false)]
    [int]$SmtpPort = 587,

    [Parameter(Mandatory = $true)]
    [string]$SmtpUser,

    [Parameter(Mandatory = $true)]
    [string]$SmtpPassword,

    [Parameter(Mandatory = $false)]
    [switch]$UseSecureConnection
)

#region Fonctions d'aide

# Fonction pour vérifier et installer les modules requis
function Install-RequiredModules {
    $modules = @(
        @{Name = "MicrosoftTeams"; MinVersion = "4.0.0"},
        @{Name = "Microsoft.Graph.Authentication"; MinVersion = "1.0.0"},
        @{Name = "Microsoft.Graph.Teams"; MinVersion = "1.0.0"},
        @{Name = "Microsoft.Graph.Users"; MinVersion = "1.0.0"},
        @{Name = "ImportExcel"; MinVersion = "7.0.0"}
    )

    foreach ($module in $modules) {
        $installedModule = Get-Module -ListAvailable -Name $module.Name |
                           Where-Object { [Version]$_.Version -ge [Version]$module.MinVersion }

        if (-not $installedModule) {
            Write-Host "Installation du module $($module.Name) version $($module.MinVersion) ou supérieure..." -ForegroundColor Yellow
            try {
                Install-Module -Name $module.Name -MinimumVersion $module.MinVersion -Force -AllowClobber -Scope CurrentUser
                Import-Module -Name $module.Name -MinimumVersion $module.MinVersion -Force
                Write-Host "Le module $($module.Name) a été installé." -ForegroundColor Green
            }
            catch {
                Write-Host "Erreur lors de l'installation du module $($module.Name): $_" -ForegroundColor Red
                exit 1
            }
        }
        else {
            Import-Module -Name $module.Name -Force
            Write-Host "Le module $($module.Name) version $($installedModule.Version) est déjà installé." -ForegroundColor Green
        }
    }
}

# Fonction pour générer un graphique en base64 pour l'email HTML
function New-Base64Chart {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ChartTitle,

        [Parameter(Mandatory = $true)]
        [array]$Labels,

        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $false)]
        [string]$ChartType = "bar",

        [Parameter(Mandatory = $false)]
        [string]$BackgroundColor = "#4a86e8"
    )

    # Créer un fichier Excel temporaire avec un graphique
    $excelTempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".xlsx"
    $chartTempFile = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".png"

    try {
        $excel = $Labels | ForEach-Object -Begin { $i = 0 } -Process {
            [PSCustomObject]@{
                Label = $_
                Value = $Data[$i++]
            }
        }

        $excelParams = @{
            Path = $excelTempFile
            WorkSheetName = "Data"
            AutoSize = $true
            TableName = "ChartData"
            TableStyle = "Medium6"
        }

        $excel | Export-Excel @excelParams -PassThru |
            Export-Excel -PassThru -AutoNameRange |
            New-ExcelChart -Title $ChartTitle -ChartType $ChartType `
                -XRange "Label" -YRange "Value" `
                -Width 600 -Height 400 -SeriesHeader "Valeur" -LegendPosition Bottom |
            Export-Excel -Path $excelTempFile

        # Exporter le graphique en image PNG
        $excel = New-Object -ComObject Excel.Application
        $excel.Visible = $false
        $workbook = $excel.Workbooks.Open($excelTempFile)
        $worksheet = $workbook.Worksheets.Item(1)
        $chart = $worksheet.ChartObjects(1).Chart
        $chart.Export($chartTempFile)
        $workbook.Close($false)
        $excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        [System.GC]::Collect()

        # Convertir l'image en base64
        $imgBytes = [System.IO.File]::ReadAllBytes($chartTempFile)
        $base64String = [System.Convert]::ToBase64String($imgBytes)

        return "data:image/png;base64,$base64String"
    }
    catch {
        Write-Host "Erreur lors de la création du graphique: $_" -ForegroundColor Red
        return $null
    }
    finally {
        # Nettoyer les fichiers temporaires
        if (Test-Path $excelTempFile) { Remove-Item -Path $excelTempFile -Force }
        if (Test-Path $chartTempFile) { Remove-Item -Path $chartTempFile -Force }
    }
}

# Fonction pour obtenir le nom d'utilisateur à partir de l'ID utilisateur Graph
function Get-UserDisplayName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UserId
    )

    try {
        $user = Get-MgUser -UserId $UserId -ErrorAction SilentlyContinue
        if ($user) {
            return $user.DisplayName
        }
        else {
            return $UserId
        }
    }
    catch {
        return $UserId
    }
}

# Fonction pour formater l'heure de manière conviviale
function Get-FriendlyTime {
    param(
        [Parameter(Mandatory = $true)]
        [DateTime]$DateTime
    )

    $now = Get-Date
    $timeSpan = $now - $DateTime

    if ($timeSpan.TotalMinutes -lt 2) {
        return "à l'instant"
    }
    elseif ($timeSpan.TotalMinutes -lt 60) {
        return "il y a $([math]::Floor($timeSpan.TotalMinutes)) minutes"
    }
    elseif ($timeSpan.TotalHours -lt 24) {
        return "il y a $([math]::Floor($timeSpan.TotalHours)) heures"
    }
    else {
        return "le $($DateTime.ToString('dd/MM/yyyy à HH:mm'))"
    }
}

#endregion

# Vérifier et installer les modules requis
Install-RequiredModules

# Se connecter à Microsoft Teams et Microsoft Graph
try {
    Write-Host "Connexion à Microsoft Teams et Microsoft Graph..." -ForegroundColor Cyan
    Connect-MicrosoftTeams -ErrorAction Stop
    Connect-MgGraph -Scopes "Team.ReadBasic.All", "Channel.ReadBasic.All", "ChannelMessage.Read.All", "GroupMember.Read.All", "User.Read.All" -ErrorAction Stop
}
catch {
    Write-Host "Erreur lors de la connexion aux services Microsoft: $_" -ForegroundColor Red
    exit 1
}

# Récupérer l'équipe
try {
    Write-Host "Recherche de l'équipe..." -ForegroundColor Yellow

    if ($TeamId) {
        $team = Get-Team -GroupId $TeamId -ErrorAction Stop
    }
    elseif ($TeamName) {
        $teams = Get-Team -DisplayName $TeamName -ErrorAction Stop

        if ($teams.Count -eq 0) {
            Write-Host "Aucune équipe trouvée avec le nom '$TeamName'." -ForegroundColor Red
            exit 1
        }
        elseif ($teams.Count -gt 1) {
            Write-Host "Plusieurs équipes trouvées avec le nom '$TeamName'. Veuillez utiliser le paramètre TeamId." -ForegroundColor Yellow
            $teams | Format-Table DisplayName, GroupId, Description -AutoSize
            exit 1
        }

        $team = $teams
    }
    else {
        Write-Host "Veuillez spécifier un nom d'équipe ou un ID d'équipe." -ForegroundColor Red
        exit 1
    }

    Write-Host "Équipe trouvée: $($team.DisplayName) (ID: $($team.GroupId))" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la recherche de l'équipe: $_" -ForegroundColor Red
    exit 1
}

# Définir la période pour le rapport (dernier jour)
$endTime = Get-Date
$startTime = $endTime.AddDays(-1)

Write-Host "Période du rapport: $($startTime.ToString('dd/MM/yyyy HH:mm')) à $($endTime.ToString('dd/MM/yyyy HH:mm'))" -ForegroundColor Cyan

#region Collecte des données

# Récupérer les membres de l'équipe
Write-Host "Récupération des membres de l'équipe..." -ForegroundColor Yellow
try {
    $teamMembers = Get-MgTeamMember -TeamId $team.GroupId
    Write-Host "Nombre de membres dans l'équipe: $($teamMembers.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la récupération des membres de l'équipe: $_" -ForegroundColor Red
    $teamMembers = @()
}

# Récupérer les canaux de l'équipe
Write-Host "Récupération des canaux de l'équipe..." -ForegroundColor Yellow
try {
    $channels = Get-MgTeamChannel -TeamId $team.GroupId
    Write-Host "Nombre de canaux: $($channels.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la récupération des canaux: $_" -ForegroundColor Red
    $channels = @()
}

# Récupérer les messages récents
Write-Host "Récupération des messages récents..." -ForegroundColor Yellow
$allMessages = @()

foreach ($channel in $channels) {
    try {
        $channelMessages = Get-MgTeamChannelMessage -TeamId $team.GroupId -ChannelId $channel.Id -Top 50 | Where-Object {
            $messageDate = [DateTime]::Parse($_.CreatedDateTime)
            $messageDate -ge $startTime -and $messageDate -le $endTime
        }

        foreach ($message in $channelMessages) {
            $allMessages += [PSCustomObject]@{
                Id = $message.Id
                Content = $message.Body.Content -replace '<[^>]+>', '' # Supprimer les balises HTML
                CreatedDateTime = [DateTime]::Parse($message.CreatedDateTime)
                CreatedBy = Get-UserDisplayName -UserId $message.From.User.Id
                ChannelName = $channel.DisplayName
                MessageType = "Message"
            }

            # Récupérer les réponses
            try {
                $replies = Get-MgTeamChannelMessageReply -TeamId $team.GroupId -ChannelId $channel.Id -ChatMessageId $message.Id | Where-Object {
                    $replyDate = [DateTime]::Parse($_.CreatedDateTime)
                    $replyDate -ge $startTime -and $replyDate -le $endTime
                }

                foreach ($reply in $replies) {
                    $allMessages += [PSCustomObject]@{
                        Id = $reply.Id
                        Content = $reply.Body.Content -replace '<[^>]+>', '' # Supprimer les balises HTML
                        CreatedDateTime = [DateTime]::Parse($reply.CreatedDateTime)
                        CreatedBy = Get-UserDisplayName -UserId $reply.From.User.Id
                        ChannelName = $channel.DisplayName
                        MessageType = "Reply"
                    }
                }
            }
            catch {
                Write-Host "Erreur lors de la récupération des réponses pour le message $($message.Id): $_" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Host "Erreur lors de la récupération des messages pour le canal $($channel.DisplayName): $_" -ForegroundColor Yellow
    }
}

Write-Host "Nombre total de messages et réponses récents: $($allMessages.Count)" -ForegroundColor Green

# Récupérer les réunions récentes
Write-Host "Récupération des réunions récentes..." -ForegroundColor Yellow
try {
    $meetings = Get-MgTeamScheduleEvent -TeamId $team.GroupId -Filter "type eq 'event'" | Where-Object {
        $eventStart = [DateTime]::Parse($_.Start.DateTime)
        $eventEnd = [DateTime]::Parse($_.End.DateTime)

        # Inclure les réunions qui chevauchent la période du rapport
        ($eventStart -ge $startTime -and $eventStart -le $endTime) -or
        ($eventEnd -ge $startTime -and $eventEnd -le $endTime) -or
        ($eventStart -le $startTime -and $eventEnd -ge $endTime)
    }

    Write-Host "Nombre de réunions récentes: $($meetings.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la récupération des réunions: $_" -ForegroundColor Yellow
    $meetings = @()
}

# Récupérer les fichiers récemment partagés
Write-Host "Récupération des fichiers récemment partagés..." -ForegroundColor Yellow
$recentFiles = @()

try {
    foreach ($channel in $channels) {
        $files = Get-MgTeamChannelFileFolder -TeamId $team.GroupId -ChannelId $channel.Id -ErrorAction SilentlyContinue

        if ($files -and $files.Value) {
            foreach ($file in $files.Value) {
                if ($file.LastModifiedDateTime -ge $startTime -and $file.LastModifiedDateTime -le $endTime) {
                    $recentFiles += [PSCustomObject]@{
                        Name = $file.Name
                        Size = [math]::Round($file.Size / 1KB, 2)
                        LastModified = $file.LastModifiedDateTime
                        ChannelName = $channel.DisplayName
                        WebUrl = $file.WebUrl
                    }
                }
            }
        }
    }

    Write-Host "Nombre de fichiers récemment partagés: $($recentFiles.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la récupération des fichiers: $_" -ForegroundColor Yellow
}

#endregion

#region Analyse des données

# Calcul des statistiques
Write-Host "Analyse des données et création des statistiques..." -ForegroundColor Yellow

# Statistiques de messages par jour de la semaine
$messagesByDay = $allMessages | Group-Object { $_.CreatedDateTime.DayOfWeek } | Sort-Object {
    switch ($_.Name) {
        'Monday' { 1 }
        'Tuesday' { 2 }
        'Wednesday' { 3 }
        'Thursday' { 4 }
        'Friday' { 5 }
        'Saturday' { 6 }
        'Sunday' { 0 }
    }
} | ForEach-Object {
    $dayName = switch ($_.Name) {
        'Monday' { 'Lundi' }
        'Tuesday' { 'Mardi' }
        'Wednesday' { 'Mercredi' }
        'Thursday' { 'Jeudi' }
        'Friday' { 'Vendredi' }
        'Saturday' { 'Samedi' }
        'Sunday' { 'Dimanche' }
    }
    [PSCustomObject]@{
        Day = $dayName
        Count = $_.Count
    }
}

# Statistiques de messages par heure
$messagesByHour = $allMessages | Group-Object { $_.CreatedDateTime.Hour } | Sort-Object Name | ForEach-Object {
    [PSCustomObject]@{
        Hour = "$($_.Name)h"
        Count = $_.Count
    }
}

# Statistiques de messages par canal
$messagesByChannel = $allMessages | Group-Object ChannelName | Sort-Object Count -Descending | ForEach-Object {
    [PSCustomObject]@{
        Channel = $_.Name
        Count = $_.Count
    }
}

# Statistiques de messages par utilisateur
$messagesByUser = $allMessages | Group-Object CreatedBy | Sort-Object Count -Descending | Select-Object -First 10 | ForEach-Object {
    [PSCustomObject]@{
        User = $_.Name
        Count = $_.Count
    }
}

# Créer les graphiques
Write-Host "Création des graphiques pour le rapport..." -ForegroundColor Yellow

$chartMessagesByDay = New-Base64Chart -ChartTitle "Messages par jour" -Labels $messagesByDay.Day -Data $messagesByDay.Count -ChartType "bar" -BackgroundColor "#4a86e8"
$chartMessagesByHour = New-Base64Chart -ChartTitle "Messages par heure" -Labels $messagesByHour.Hour -Data $messagesByHour.Count -ChartType "line" -BackgroundColor "#6aa84f"
$chartMessagesByChannel = New-Base64Chart -ChartTitle "Messages par canal" -Labels $messagesByChannel.Channel -Data $messagesByChannel.Count -ChartType "horizontalBar" -BackgroundColor "#e69138"
$chartMessagesByUser = New-Base64Chart -ChartTitle "Top 10 contributeurs" -Labels $messagesByUser.User -Data $messagesByUser.Count -ChartType "pie" -BackgroundColor "#8e7cc3"

#endregion

#region Création du rapport HTML

Write-Host "Création du rapport HTML..." -ForegroundColor Yellow

$date = Get-Date -Format "dd/MM/yyyy"
$reportTitle = "Rapport d'activité Teams - $($team.DisplayName) - $date"

$htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$reportTitle</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 20px; }
        .container { max-width: 1000px; margin: 0 auto; background: #fff; padding: 20px; border-radius: 5px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #0078d4; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #0078d4; margin-top: 30px; }
        h3 { color: #444; }
        .summary { background: #f0f6ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .summary-item { display: inline-block; text-align: center; margin: 10px 20px; }
        .summary-number { font-size: 24px; font-weight: bold; color: #0078d4; display: block; }
        .summary-label { color: #666; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th { background: #0078d4; color: white; padding: 10px; text-align: left; }
        td { padding: 8px 10px; border-bottom: 1px solid #ddd; }
        tr:nth-child(even) { background: #f9f9f9; }
        .chart-container { margin: 30px 0; text-align: center; }
        .chart { max-width: 100%; height: auto; }
        .footer { margin-top: 30px; text-align: center; font-size: 12px; color: #666; }
        .message { background: #f9f9f9; padding: 10px; border-radius: 5px; margin: 10px 0; }
        .message-header { color: #666; font-size: 12px; margin-bottom: 5px; }
        .message-content { margin-left: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>$reportTitle</h1>
        <p>Période du rapport: <strong>$($startTime.ToString('dd/MM/yyyy HH:mm'))</strong> à <strong>$($endTime.ToString('dd/MM/yyyy HH:mm'))</strong></p>
"@

# Résumé des activités
$htmlSummary = @"
        <div class="summary">
            <div class="summary-item">
                <span class="summary-number">$($allMessages.Count)</span>
                <span class="summary-label">Messages</span>
            </div>
            <div class="summary-item">
                <span class="summary-number">$($meetings.Count)</span>
                <span class="summary-label">Réunions</span>
            </div>
            <div class="summary-item">
                <span class="summary-number">$($recentFiles.Count)</span>
                <span class="summary-label">Fichiers</span>
            </div>
            <div class="summary-item">
                <span class="summary-number">$($teamMembers.Count)</span>
                <span class="summary-label">Membres</span>
            </div>
        </div>
"@

# Graphiques
$htmlCharts = @"
        <h2>Analyse de l'activité</h2>

        <div class="chart-container">
            <h3>Distribution des messages par jour</h3>
            <img class="chart" src="$chartMessagesByDay" alt="Messages par jour">
        </div>

        <div class="chart-container">
            <h3>Distribution des messages par heure</h3>
            <img class="chart" src="$chartMessagesByHour" alt="Messages par heure">
        </div>

        <div class="chart-container">
            <h3>Distribution des messages par canal</h3>
            <img class="chart" src="$chartMessagesByChannel" alt="Messages par canal">
        </div>

        <div class="chart-container">
            <h3>Top contributeurs</h3>
            <img class="chart" src="$chartMessagesByUser" alt="Top contributeurs">
        </div>
"@

# Réunions récentes
$htmlMeetings = @"
        <h2>Réunions récentes</h2>
"@

if ($meetings.Count -gt 0) {
    $htmlMeetings += @"
        <table>
            <tr>
                <th>Sujet</th>
                <th>Date/Heure</th>
                <th>Durée</th>
                <th>Organisateur</th>
            </tr>
"@

    foreach ($meeting in $meetings) {
        $startTime = [DateTime]::Parse($meeting.Start.DateTime)
        $endTime = [DateTime]::Parse($meeting.End.DateTime)
        $duration = ($endTime - $startTime).TotalMinutes

        $htmlMeetings += @"
            <tr>
                <td>$($meeting.Subject)</td>
                <td>$($startTime.ToString('dd/MM/yyyy HH:mm'))</td>
                <td>$([math]::Round($duration)) minutes</td>
                <td>$(Get-UserDisplayName -UserId $meeting.Organizer.User.Id)</td>
            </tr>
"@
    }

    $htmlMeetings += @"
        </table>
"@
}
else {
    $htmlMeetings += @"
        <p>Aucune réunion pendant la période du rapport.</p>
"@
}

# Fichiers récents
$htmlFiles = @"
        <h2>Fichiers récemment partagés</h2>
"@

if ($recentFiles.Count -gt 0) {
    $htmlFiles += @"
        <table>
            <tr>
                <th>Nom du fichier</th>
                <th>Canal</th>
                <th>Taille (KB)</th>
                <th>Dernière modification</th>
            </tr>
"@

    foreach ($file in $recentFiles) {
        $htmlFiles += @"
            <tr>
                <td>$($file.Name)</td>
                <td>$($file.ChannelName)</td>
                <td>$($file.Size) KB</td>
                <td>$(Get-FriendlyTime -DateTime $file.LastModified)</td>
            </tr>
"@
    }

    $htmlFiles += @"
        </table>
"@
}
else {
    $htmlFiles += @"
        <p>Aucun fichier partagé pendant la période du rapport.</p>
"@
}

# Messages récents
$htmlMessages = @"
        <h2>Messages récents</h2>
"@

if ($allMessages.Count -gt 0) {
    # Limiter à 20 messages les plus récents pour éviter un email trop long
    $displayedMessages = $allMessages | Sort-Object CreatedDateTime -Descending | Select-Object -First 20

    foreach ($message in $displayedMessages) {
        $friendlyTime = Get-FriendlyTime -DateTime $message.CreatedDateTime
        $messageType = if ($message.MessageType -eq "Reply") { "(Réponse)" } else { "" }

        $htmlMessages += @"
        <div class="message">
            <div class="message-header">
                <strong>$($message.CreatedBy)</strong> dans <strong>$($message.ChannelName)</strong> $messageType - $friendlyTime
            </div>
            <div class="message-content">
                $($message.Content)
            </div>
        </div>
"@
    }

    if ($allMessages.Count -gt 20) {
        $htmlMessages += @"
        <p><em>Affichage des 20 messages les plus récents sur un total de $($allMessages.Count).</em></p>
"@
    }
}
else {
    $htmlMessages += @"
        <p>Aucun message pendant la période du rapport.</p>
"@
}

# Pied de page
$htmlFooter = @"
        <div class="footer">
            <p>Rapport généré automatiquement le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>
        </div>
    </div>
</body>
</html>
"@

# Assembler le rapport complet
$htmlReport = $htmlHeader + $htmlSummary + $htmlCharts + $htmlMeetings + $htmlFiles + $htmlMessages + $htmlFooter

#endregion

#region Envoi du rapport par email

Write-Host "Envoi du rapport par email..." -ForegroundColor Yellow

try {
    # Créer les identifiants SMTP
    $securePassword = ConvertTo-SecureString $SmtpPassword -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential($SmtpUser, $securePassword)

    # Préparer les paramètres pour l'email
    $emailParams = @{
        From = $SmtpUser
        To = $EmailTo.Split(',').Trim()
        Subject = $reportTitle
        Body = $htmlReport
        BodyAsHtml = $true
        SmtpServer = $SmtpServer
        Port = $SmtpPort
        Credential = $credential
    }

    # Ajouter UseSSL si demandé
    if ($UseSecureConnection) {
        $emailParams.Add("UseSSL", $true)
    }

    # Envoyer l'email
    Send-MailMessage @emailParams
    Write-Host "Rapport envoyé avec succès à $EmailTo" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'envoi de l'email: $_" -ForegroundColor Red
}

#endregion

# Déconnexion
Disconnect-MicrosoftTeams -ErrorAction SilentlyContinue
Disconnect-MgGraph -ErrorAction SilentlyContinue

Write-Host "Rapport terminé!" -ForegroundColor Green
```

## Explication du script

Ce script PowerShell crée un rapport quotidien des activités d'une équipe Microsoft Teams et l'envoie par email. Voici les principales fonctionnalités :

1. **Gestion des modules** : Le script vérifie et installe automatiquement les modules PowerShell requis.

2. **Connexion aux services Microsoft** : Utilisation de l'authentification moderne pour se connecter à Microsoft Teams et Microsoft Graph.

3. **Collecte de données** :
   - Récupération des membres de l'équipe
   - Récupération des canaux et messages récents
   - Récupération des réunions de la période
   - Récupération des fichiers partagés récemment

4. **Analyse statistique** :
   - Distribution des messages par jour de la semaine
   - Distribution des messages par heure
   - Distribution des messages par canal
   - Top contributeurs

5. **Visualisation** : Création de graphiques intégrés au rapport HTML grâce à Excel COM et conversion en base64.

6. **Rapport HTML** : Génération d'un rapport structuré comprenant :
   - Résumé des activités
   - Visualisations graphiques
   - Liste des réunions récentes
   - Liste des fichiers partagés
   - Liste des messages récents

7. **Envoi du rapport** : Utilisation de `Send-MailMessage` pour envoyer le rapport par email via SMTP.

## Utilisation

Pour utiliser ce script :

1. Assurez-vous d'avoir les permissions nécessaires pour accéder à l'équipe Teams.

2. Exécutez le script en spécifiant le nom ou l'ID de l'équipe et les paramètres d'email :
   ```powershell
   .\Teams-DailyReport.ps1 -TeamName "Projet X" -EmailTo "manager@company.com" -SmtpServer "smtp.company.com" -SmtpUser "reporting@company.com" -SmtpPassword "P@ssw0rd!"
   ```

3. Pour utiliser une connexion sécurisée lors de l'envoi de l'email :
   ```powershell
   .\Teams-DailyReport.ps1 -TeamName "Projet X" -EmailTo "manager@company.com" -SmtpServer "smtp.company.com" -SmtpUser "reporting@company.com" -SmtpPassword "P@ssw0rd!" -UseSecureConnection
   ```

## Notes supplémentaires

- **Sécurité** : Pour une utilisation en production, il est recommandé de ne pas stocker les mots de passe en clair dans le script. Utilisez plutôt des méthodes sécurisées comme les secrets Azure Key Vault ou le stockage sécurisé des identifiants PowerShell.

- **Programmation** : Ce script peut être configuré comme tâche planifiée pour s'exécuter automatiquement chaque jour.

- **Personnalisation** : Le rapport HTML peut être facilement personnalisé pour inclure des données supplémentaires ou une mise en page différente.

- **Graphiques** : La génération des graphiques nécessite Excel installé sur la machine qui exécute le script. Si Excel n'est pas disponible, vous pouvez adapter le script pour utiliser une bibliothèque de graphiques alternative.

- **Période de rapport** : Par défaut, le script analyse les dernières 24 heures. Vous pouvez modifier cette période en ajustant les variables `$startTime` et `$endTime`.

- **Limitations** : L'API Microsoft Graph a des limites de débit. Si l'équipe a beaucoup d'activité, vous pourriez rencontrer des problèmes de limitation.
