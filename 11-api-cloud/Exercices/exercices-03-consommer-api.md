# Solutions des exercices - API REST et JSON avec PowerShell

## Exercice : Récupération de la météo pour une ville

Voici une solution complète pour l'exercice proposé dans le tutoriel concernant la récupération des données météorologiques.

### Solution basique

```powershell
<#
.SYNOPSIS
    Récupère et affiche les informations météo pour une ville spécifiée
.DESCRIPTION
    Ce script utilise l'API OpenWeatherMap pour récupérer les informations météo
    actuelles pour une ville donnée et les affiche de façon formatée.
.PARAMETER City
    Nom de la ville pour laquelle récupérer la météo
.PARAMETER ApiKey
    Clé API pour OpenWeatherMap
.EXAMPLE
    .\Get-WeatherInfo.ps1 -City "Paris" -ApiKey "votre_clé_api"
.NOTES
    Nécessite une clé API OpenWeatherMap gratuite : https://openweathermap.org/api
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$City,

    [Parameter(Mandatory=$true)]
    [string]$ApiKey
)

# Construction de l'URL avec les paramètres
$uri = "https://api.openweathermap.org/data/2.5/weather?q=$City&appid=$ApiKey&units=metric&lang=fr"

try {
    # Récupération des données météo
    $weather = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop

    # Formatage et affichage des résultats
    Write-Host "Météo actuelle à $($weather.name) :" -ForegroundColor Cyan
    Write-Host "Température : $($weather.main.temp)°C"
    Write-Host "Ressenti : $($weather.main.feels_like)°C"
    Write-Host "Humidité : $($weather.main.humidity)%"
    Write-Host "Conditions : $($weather.weather[0].description)"
    Write-Host "Vitesse du vent : $($weather.wind.speed) m/s"
}
catch {
    # Gestion des erreurs
    if ($_.Exception.Response.StatusCode.value__) {
        $statusCode = $_.Exception.Response.StatusCode.value__

        switch ($statusCode) {
            401 { Write-Host "Erreur d'authentification : Vérifiez votre clé API" -ForegroundColor Red }
            404 { Write-Host "Ville non trouvée : '$City'" -ForegroundColor Red }
            429 { Write-Host "Limite d'appels API dépassée. Réessayez plus tard." -ForegroundColor Red }
            default { Write-Host "Erreur $statusCode lors de la récupération des données météo" -ForegroundColor Red }
        }
    }
    else {
        Write-Host "Erreur lors de la récupération des données météo : $_" -ForegroundColor Red
    }
    exit 1
}
```

### Solution avancée avec fonctionnalités supplémentaires

```powershell
<#
.SYNOPSIS
    Récupère et affiche les informations météo pour une ou plusieurs villes
.DESCRIPTION
    Ce script utilise l'API OpenWeatherMap pour récupérer les informations météo
    actuelles pour une ou plusieurs villes données et les affiche de façon formatée.
    Il permet également d'exporter les résultats en CSV ou JSON.
.PARAMETER Cities
    Liste des villes pour lesquelles récupérer la météo (séparées par des virgules)
.PARAMETER ApiKey
    Clé API pour OpenWeatherMap
.PARAMETER ExportFormat
    Format d'exportation des résultats (None, CSV, JSON)
.PARAMETER OutputPath
    Chemin où exporter le fichier de résultats (si ExportFormat n'est pas None)
.EXAMPLE
    .\Get-WeatherInfoAdvanced.ps1 -Cities "Paris,Londres,Berlin" -ApiKey "votre_clé_api" -ExportFormat CSV -OutputPath "C:\Temp\meteo.csv"
.EXAMPLE
    .\Get-WeatherInfoAdvanced.ps1 -Cities "Tokyo" -ApiKey "votre_clé_api"
.NOTES
    Nécessite une clé API OpenWeatherMap gratuite : https://openweathermap.org/api
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Cities,

    [Parameter(Mandatory=$true)]
    [string]$ApiKey,

    [Parameter(Mandatory=$false)]
    [ValidateSet("None", "CSV", "JSON")]
    [string]$ExportFormat = "None",

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "$env:USERPROFILE\Documents\WeatherData.csv"
)

# Fonction pour convertir des degrés en direction cardinale
function Convert-DegreesToCardinal {
    param([double]$Degrees)

    $cardinalPoints = @("N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO", "N")
    $index = [math]::Round($Degrees / 22.5)
    return $cardinalPoints[$index]
}

# Fonction pour convertir timestamp Unix en datetime
function Convert-FromUnixTime {
    param([long]$UnixTime)

    [datetime]$origin = '1970-01-01 00:00:00'
    return $origin.AddSeconds($UnixTime).ToLocalTime()
}

# Tableau pour stocker les résultats
$weatherResults = @()

# Pour chaque ville dans la liste
foreach ($city in $Cities -split ',') {
    $city = $city.Trim()

    # Construction de l'URL avec les paramètres
    $uri = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$ApiKey&units=metric&lang=fr"

    try {
        # Récupération des données météo
        $weather = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop

        # Création d'un objet personnalisé avec les informations importantes
        $weatherInfo = [PSCustomObject]@{
            Ville = $weather.name
            Pays = $weather.sys.country
            Temperature = [math]::Round($weather.main.temp, 1)
            Ressenti = [math]::Round($weather.main.feels_like, 1)
            TempMin = [math]::Round($weather.main.temp_min, 1)
            TempMax = [math]::Round($weather.main.temp_max, 1)
            Humidite = $weather.main.humidity
            Pression = $weather.main.pressure
            Conditions = $weather.weather[0].description
            ConditionsID = $weather.weather[0].id
            VitesseVent = $weather.wind.speed
            DirectionVent = Convert-DegreesToCardinal -Degrees $weather.wind.deg
            Nuages = $weather.clouds.all
            Visibilite = [math]::Round($weather.visibility / 1000, 1) # Conversion en km
            Lever = Convert-FromUnixTime -UnixTime $weather.sys.sunrise
            Coucher = Convert-FromUnixTime -UnixTime $weather.sys.sunset
            DateMesure = Convert-FromUnixTime -UnixTime $weather.dt
        }

        # Ajout au tableau de résultats
        $weatherResults += $weatherInfo

        # Affichage formaté
        Write-Host "`nMétéo actuelle à $($weatherInfo.Ville), $($weatherInfo.Pays) :" -ForegroundColor Cyan
        Write-Host "Température : $($weatherInfo.Temperature)°C (Min: $($weatherInfo.TempMin)°C, Max: $($weatherInfo.TempMax)°C)"
        Write-Host "Ressenti : $($weatherInfo.Ressenti)°C"
        Write-Host "Humidité : $($weatherInfo.Humidite)%, Pression : $($weatherInfo.Pression) hPa"
        Write-Host "Conditions : $($weatherInfo.Conditions)"
        Write-Host "Vent : $($weatherInfo.VitesseVent) m/s, direction : $($weatherInfo.DirectionVent)"
        Write-Host "Visibilité : $($weatherInfo.Visibilite) km, Couverture nuageuse : $($weatherInfo.Nuages)%"
        Write-Host "Lever du soleil : $($weatherInfo.Lever.ToString('HH:mm')), Coucher : $($weatherInfo.Coucher.ToString('HH:mm'))"
        Write-Host "Mesure effectuée le : $($weatherInfo.DateMesure.ToString('dd/MM/yyyy HH:mm'))"
    }
    catch {
        # Gestion des erreurs
        if ($_.Exception.Response.StatusCode.value__) {
            $statusCode = $_.Exception.Response.StatusCode.value__

            switch ($statusCode) {
                401 { Write-Host "Erreur d'authentification : Vérifiez votre clé API" -ForegroundColor Red }
                404 { Write-Host "Ville non trouvée : '$city'" -ForegroundColor Red }
                429 { Write-Host "Limite d'appels API dépassée. Réessayez plus tard." -ForegroundColor Red }
                default { Write-Host "Erreur $statusCode lors de la récupération des données pour '$city'" -ForegroundColor Red }
            }
        }
        else {
            Write-Host "Erreur lors de la récupération des données pour '$city' : $_" -ForegroundColor Red
        }
    }
}

# Export des résultats si demandé
if ($ExportFormat -ne "None" -and $weatherResults.Count -gt 0) {
    try {
        switch ($ExportFormat) {
            "CSV" {
                $weatherResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                Write-Host "`nDonnées exportées avec succès vers : $OutputPath" -ForegroundColor Green
            }
            "JSON" {
                $jsonPath = [System.IO.Path]::ChangeExtension($OutputPath, "json")
                $weatherResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding UTF8
                Write-Host "`nDonnées exportées avec succès vers : $jsonPath" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Erreur lors de l'exportation des données : $_" -ForegroundColor Red
    }
}
```

## Exercice supplémentaire : Travailler avec l'API GitHub

Voici un exemple complet montrant comment interagir avec l'API GitHub pour obtenir des informations sur un dépôt et ses problèmes (issues).

```powershell
<#
.SYNOPSIS
    Récupère et affiche des informations sur un dépôt GitHub et ses issues
.DESCRIPTION
    Ce script utilise l'API GitHub pour récupérer des informations sur un dépôt
    spécifié et ses issues ouvertes. Il affiche les statistiques du dépôt et
    les issues les plus récentes.
.PARAMETER Owner
    Propriétaire du dépôt GitHub (utilisateur ou organisation)
.PARAMETER Repository
    Nom du dépôt GitHub
.PARAMETER Token
    Token d'accès personnel GitHub (optionnel pour les dépôts publics)
.EXAMPLE
    .\Get-GitHubRepoInfo.ps1 -Owner "microsoft" -Repository "PowerShell"
.EXAMPLE
    .\Get-GitHubRepoInfo.ps1 -Owner "votre-username" -Repository "votre-repo-privé" -Token "ghp_votre_token"
.NOTES
    Pour les dépôts privés ou pour augmenter les limites d'appels API, créez un token sur:
    https://github.com/settings/tokens
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Owner,

    [Parameter(Mandatory=$true)]
    [string]$Repository,

    [Parameter(Mandatory=$false)]
    [string]$Token = ""
)

# Configuration des en-têtes pour l'API GitHub
$headers = @{
    "Accept" = "application/vnd.github.v3+json"
}

# Ajout du token d'authentification si fourni
if ($Token) {
    $headers["Authorization"] = "token $Token"
}

# Fonction pour faire des appels à l'API GitHub
function Invoke-GitHubApi {
    param(
        [string]$Endpoint
    )

    $baseUri = "https://api.github.com"
    $uri = "$baseUri/$Endpoint"

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
        return $response
    }
    catch {
        if ($_.Exception.Response.StatusCode.value__ -eq 403) {
            Write-Host "Limite d'appels API GitHub atteinte ou accès refusé." -ForegroundColor Red
            Write-Host "Détails: " -ForegroundColor Red -NoNewline

            if ($_.ErrorDetails.Message) {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host $errorDetails.message
            }
            else {
                Write-Host $_.Exception.Message
            }
        }
        elseif ($_.Exception.Response.StatusCode.value__ -eq 404) {
            Write-Host "Dépôt non trouvé: $Owner/$Repository" -ForegroundColor Red
        }
        else {
            Write-Host "Erreur lors de l'appel à l'API GitHub: $_" -ForegroundColor Red
        }

        exit 1
    }
}

# Récupération des informations sur le dépôt
Write-Host "Récupération des informations pour le dépôt $Owner/$Repository..." -ForegroundColor Cyan
$repoInfo = Invoke-GitHubApi -Endpoint "repos/$Owner/$Repository"

# Affichage des informations sur le dépôt
Write-Host "`n📂 INFORMATIONS SUR LE DÉPÔT" -ForegroundColor Yellow
Write-Host "Nom complet    : $($repoInfo.full_name)"
Write-Host "Description    : $($repoInfo.description)"
Write-Host "URL            : $($repoInfo.html_url)"
Write-Host "Langage        : $($repoInfo.language)"
Write-Host "Étoiles        : $($repoInfo.stargazers_count)"
Write-Host "Forks          : $($repoInfo.forks_count)"
Write-Host "Watchers       : $($repoInfo.watchers_count)"
Write-Host "Issues ouvertes: $($repoInfo.open_issues_count)"
Write-Host "Créé le        : $([DateTime]$repoInfo.created_at)"
Write-Host "Dernière mise à jour: $([DateTime]$repoInfo.updated_at)"

# Si le dépôt a des issues ouvertes, les récupérer et les afficher
if ($repoInfo.open_issues_count -gt 0) {
    # Récupération des 10 dernières issues ouvertes
    Write-Host "`nRécupération des issues ouvertes..." -ForegroundColor Cyan
    $issues = Invoke-GitHubApi -Endpoint "repos/$Owner/$Repository/issues?state=open&per_page=10&sort=created&direction=desc"

    Write-Host "`n🐛 ISSUES RÉCENTES" -ForegroundColor Yellow

    foreach ($issue in $issues) {
        # Affichage formaté de chaque issue
        Write-Host "`n#$($issue.number): $($issue.title)" -ForegroundColor Green
        Write-Host "État        : $($issue.state)"
        Write-Host "Créée par   : $($issue.user.login)"
        Write-Host "Créée le    : $([DateTime]$issue.created_at)"
        Write-Host "Commentaires: $($issue.comments)"
        Write-Host "URL         : $($issue.html_url)"

        # Affichage des labels s'il y en a
        if ($issue.labels -and $issue.labels.Count -gt 0) {
            $labelNames = $issue.labels | ForEach-Object { $_.name }
            Write-Host "Labels      : $($labelNames -join ', ')"
        }
    }

    # S'il y a plus de 10 issues, indiquer combien d'autres sont disponibles
    if ($repoInfo.open_issues_count -gt 10) {
        $remaining = $repoInfo.open_issues_count - 10
        Write-Host "`nNote: $remaining autres issues non affichées." -ForegroundColor DarkGray
    }
}
else {
    Write-Host "`nAucune issue ouverte pour ce dépôt." -ForegroundColor DarkGray
}

# Affichage des limites d'appels API restantes
$rateLimit = Invoke-GitHubApi -Endpoint "rate_limit"
$remaining = $rateLimit.rate.remaining
$limit = $rateLimit.rate.limit
$resetTime = [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($rateLimit.rate.reset))

Write-Host "`n📊 LIMITES D'API" -ForegroundColor Yellow
Write-Host "Appels restants: $remaining/$limit"
Write-Host "Réinitialisation: $($resetTime.ToString('dd/MM/yyyy HH:mm:ss'))"
```

## Exercice supplémentaire : Création d'un client Teams avec PowerShell

```powershell
<#
.SYNOPSIS
    Envoie un message à un webhook Microsoft Teams
.DESCRIPTION
    Ce script permet d'envoyer des messages formatés à un canal Microsoft Teams
    via un webhook entrant. Il prend en charge différents types de cartes adaptatives.
.PARAMETER WebhookUrl
    URL du webhook Microsoft Teams
.PARAMETER MessageType
    Type de message à envoyer (Simple, Info, Alerte, Succès)
.PARAMETER Title
    Titre du message
.PARAMETER Message
    Corps du message
.PARAMETER ButtonUrl
    URL optionnelle pour ajouter un bouton d'action
.PARAMETER ButtonText
    Texte optionnel pour le bouton d'action (nécessite ButtonUrl)
.EXAMPLE
    .\Send-TeamsMessage.ps1 -WebhookUrl "https://outlook.office.com/webhook/..." -MessageType "Info" -Title "Déploiement planifié" -Message "Un déploiement est prévu à 15h00."
.EXAMPLE
    .\Send-TeamsMessage.ps1 -WebhookUrl "https://outlook.office.com/webhook/..." -MessageType "Alerte" -Title "Espace disque critique" -Message "Le serveur WEB01 a moins de 5% d'espace disque libre." -ButtonUrl "https://portal.azure.com" -ButtonText "Voir le serveur"
.NOTES
    Pour créer un webhook dans Teams:
    1. Allez dans le canal Teams
    2. Cliquez sur "..." à côté du nom du canal
    3. Sélectionnez "Connecteurs"
    4. Configurez "Incoming Webhook"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$WebhookUrl,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Simple", "Info", "Alerte", "Succès")]
    [string]$MessageType,

    [Parameter(Mandatory=$true)]
    [string]$Title,

    [Parameter(Mandatory=$true)]
    [string]$Message,

    [Parameter(Mandatory=$false)]
    [string]$ButtonUrl = "",

    [Parameter(Mandatory=$false)]
    [string]$ButtonText = ""
)

# Définition des couleurs selon le type de message
$colors = @{
    Simple = "#cccccc"
    Info = "#0078D7"
    Alerte = "#ff0000"
    Succès = "#36a64f"
}

# Construction du corps du message selon le type
switch ($MessageType) {
    "Simple" {
        # Message simple
        $body = @{
            text = $Message
            title = $Title
        }
    }
    default {
        # Message avec carte adaptative
        $sections = @(
            @{
                activityTitle = $Title
                activitySubtitle = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
                text = $Message
                facts = @(
                    @{
                        name = "Type"
                        value = $MessageType
                    },
                    @{
                        name = "Envoyé par"
                        value = $env:COMPUTERNAME
                    },
                    @{
                        name = "Utilisateur"
                        value = $env:USERNAME
                    }
                )
            }
        )

        # Ajout du bouton si l'URL est fournie
        if ($ButtonUrl -and $ButtonText) {
            $potentialActions = @(
                @{
                    "@type" = "ActionCard"
                    name = $ButtonText
                    actions = @(
                        @{
                            "@type" = "OpenUri"
                            name = $ButtonText
                            targets = @(
                                @{
                                    os = "default"
                                    uri = $ButtonUrl
                                }
                            )
                        }
                    )
                }
            )

            $body = @{
                "@type" = "MessageCard"
                "@context" = "http://schema.org/extensions"
                summary = $Title
                themeColor = $colors[$MessageType]
                title = $Title
                sections = $sections
                potentialAction = $potentialActions
            }
        }
        else {
            $body = @{
                "@type" = "MessageCard"
                "@context" = "http://schema.org/extensions"
                summary = $Title
                themeColor = $colors[$MessageType]
                title = $Title
                sections = $sections
            }
        }
    }
}

# Conversion en JSON
$bodyJson = $body | ConvertTo-Json -Depth 4

try {
    # Envoi du message
    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $bodyJson -ContentType "application/json"

    if ($response -eq 1) {
        Write-Host "Message envoyé avec succès à Teams." -ForegroundColor Green
    }
    else {
        Write-Host "L'envoi du message a échoué." -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de l'envoi du message : $_" -ForegroundColor Red

    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Code d'erreur HTTP : $statusCode" -ForegroundColor Red

        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "Détails de l'erreur : $($errorDetails.message)" -ForegroundColor Red
            }
            catch {
                Write-Host "Détails de l'erreur : $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
        }
    }

    exit 1
}
```

## Exercice supplémentaire : Client pour l'API JIRA

```powershell
<#
.SYNOPSIS
    Récupère et affiche les tickets JIRA assignés à l'utilisateur
.DESCRIPTION
    Ce script utilise l'API REST de JIRA pour récupérer les tickets assignés
    à l'utilisateur spécifié et les affiche dans la console.
.PARAMETER JiraUrl
    URL de base de votre instance JIRA (ex: https://votre-entreprise.atlassian.net)
.PARAMETER Username
    Nom d'utilisateur JIRA (généralement l'email)
.PARAMETER ApiToken
    Jeton API pour l'authentification JIRA
    (Générer sur https://id.atlassian.com/manage-profile/security/api-tokens)
.PARAMETER Project
    Code du projet JIRA (optionnel, pour filtrer par projet)
.PARAMETER Status
    Statut des tickets à afficher (optionnel, par défaut "En cours")
.EXAMPLE
    .\Get-JiraTickets.ps1 -JiraUrl "https://votre-entreprise.atlassian.net" -Username "votre.email@domaine.com" -ApiToken "votre_token_api"
.EXAMPLE
    .\Get-JiraTickets.ps1 -JiraUrl "https://votre-entreprise.atlassian.net" -Username "votre.email@domaine.com" -ApiToken "votre_token_api" -Project "PROJ" -Status "À faire"
.NOTES
    Les API Tokens JIRA sont personnels et ne doivent jamais être partagés
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$JiraUrl,

    [Parameter(Mandatory=$true)]
    [string]$Username,

    [Parameter(Mandatory=$true)]
    [string]$ApiToken,

    [Parameter(Mandatory=$false)]
    [string]$Project = "",

    [Parameter(Mandatory=$false)]
    [string]$Status = "En cours"
)

# Création des informations d'authentification
$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${Username}:${ApiToken}"))
$headers = @{
    Authorization = "Basic $base64Auth"
    Accept = "application/json"
}

# Construction de la requête JQL (JIRA Query Language)
$jql = "assignee = currentUser() AND status = '$Status'"

if ($Project) {
    $jql += " AND project = '$Project'"
}

# Encodage de la requête JQL pour l'URL
$encodedJql = [System.Web.HttpUtility]::UrlEncode($jql)

# Construction de l'URL de l'API
$apiPath = "/rest/api/2/search?jql=$encodedJql&fields=summary,status,priority,issuetype,created,updated,project&maxResults=50"
$uri = "$JiraUrl$apiPath"

try {
    # Récupération des tickets
    Write-Host "Récupération des tickets JIRA..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop

    if ($response.issues.Count -eq 0) {
        Write-Host "Aucun ticket ne correspond aux critères." -ForegroundColor Yellow
        exit 0
    }

    # Affichage du nombre de tickets
    Write-Host "`nNombre de tickets trouvés : $($response.issues.Count)" -ForegroundColor Green

    # Création d'un tableau pour formater les tickets
    $issueTable = @()

    foreach ($issue in $response.issues) {
        $created = [DateTime]$issue.fields.created
        $updated = [DateTime]$issue.fields.updated

        $issueObject = [PSCustomObject]@{
            Clé = $issue.key
            Résumé = $issue.fields.summary
            Type = $issue.fields.issuetype.name
            Projet = $issue.fields.project.key
            Statut = $issue.fields.status.name
            Priorité = $issue.fields.priority.name
            Créé = $created.ToString("dd/MM/yyyy")
            "Dernière MAJ" = $updated.ToString("dd/MM/yyyy")
            URL = "$JiraUrl/browse/$($issue.key)"
        }

        $issueTable += $issueObject
    }

    # Affichage des tickets
    $issueTable | Format-Table -Property Clé, Résumé, Type, Statut, Priorité, Créé, "Dernière MAJ" -AutoSize

    # Option pour exporter vers CSV
    $exportToCsv = Read-Host "Voulez-vous exporter ces tickets vers un fichier CSV? (O/N)"

    if ($exportToCsv -eq "O" -or $exportToCsv -eq "o") {
        $csvPath = "$env:USERPROFILE\Documents\JiraTickets_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $issueTable | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Host "Les tickets ont été exportés vers : $csvPath" -ForegroundColor Green
    }
}
catch {
    # Gestion des erreurs
    Write-Host "Erreur lors de la récupération des tickets JIRA :" -ForegroundColor Red

    if ($_.Exception.Response.StatusCode.value__) {
        $statusCode = $_.Exception.Response.StatusCode.value__

        switch ($statusCode) {
            401 { Write-Host "Erreur d'authentification. Vérifiez votre nom d'utilisateur et votre jeton API." -ForegroundColor Red }
            403 { Write-Host "Accès refusé. Vérifiez vos permissions JIRA." -ForegroundColor Red }
            404 { Write-Host "Instance JIRA non trouvée. Vérifiez l'URL de l'instance." -ForegroundColor Red }
            default { Write-Host "Erreur HTTP $statusCode lors de l'appel à l'API JIRA." -ForegroundColor Red }
        }

        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "Message d'erreur JIRA : $($errorDetails.errorMessages -join ', ')" -ForegroundColor Red
            }
            catch {
                Write-Host "Détails de l'erreur : $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    exit 1
}
```

## Exercice supplémentaire : Surveillance de services web avec PowerShell

```powershell
<#
.SYNOPSIS
    Surveille la disponibilité de plusieurs services web et envoie des alertes
.DESCRIPTION
    Ce script vérifie la disponibilité de plusieurs services web définis dans
    un fichier de configuration JSON, et envoie des alertes par email ou webhook
    en cas de panne détectée.
.PARAMETER ConfigFile
    Chemin vers le fichier de configuration JSON
.PARAMETER AlertType
    Type d'alerte à envoyer (Email, Teams, Both, None)
.PARAMETER LogFile
    Chemin vers le fichier de log
.EXAMPLE
    .\Monitor-WebServices.ps1 -ConfigFile ".\config.json" -AlertType Teams
.EXAMPLE
    .\Monitor-WebServices.ps1 -ConfigFile ".\config.json" -AlertType Email -LogFile "C:\Logs\monitoring.log"
.NOTES
    Fichier de configuration JSON exemple:
    {
        "Services": [
            {
                "Name": "Site corporate",
                "URL": "https://www.example.com",
                "ExpectedStatus": 200,
                "TimeoutSeconds": 10,
                "CheckContent": true,
                "ExpectedContent": "Bienvenue"
            },
            {
                "Name": "API clients",
                "URL": "https://api.example.com/health",
                "ExpectedStatus": 200,
                "TimeoutSeconds": 5,
                "CheckContent": false
            }
        ],
        "Email": {
            "SMTPServer": "smtp.example.com",
            "Port": 587,
            "UseSSL": true,
            "From": "monitoring@example.com",
            "To": ["admin@example.com", "support@example.com"],
            "Credentials": {
                "Username": "monitoring@example.com",
                "Password": "CRYPTED:A1B2C3D4E5F6..."
            }
        },
        "Teams": {
            "WebhookURL": "https://outlook.office.com/webhook/..."
        },
        "CheckIntervalMinutes": 5,
        "RetryCount": 3,
        "RetryDelaySeconds": 30
    }
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile,

    [Parameter(Mandatory=$false)]
    [ValidateSet("Email", "Teams", "Both", "None")]
    [string]$AlertType = "None",

    [Parameter(Mandatory=$false)]
    [string]$LogFile = "$PSScriptRoot\WebServiceMonitoring.log"
)

# Fonction pour écrire dans le fichier log
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Affichage dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Gray }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
    }

    # Écriture dans le fichier log
    Add-Content -Path $LogFile -Value $logMessage
}

# Fonction pour envoyer une alerte par email
function Send-EmailAlert {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Subject,

        [Parameter(Mandatory=$true)]
        [string]$Body,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$EmailConfig
    )

    try {
        # Créer un objet de message
        $message = New-Object System.Net.Mail.MailMessage
        $message.From = $EmailConfig.From

        # Ajouter chaque destinataire
        foreach ($recipient in $EmailConfig.To) {
            $message.To.Add($recipient)
        }

        $message.Subject = $Subject
        $message.Body = $Body
        $message.IsBodyHtml = $true

        # Configurer le client SMTP
        $smtp = New-Object System.Net.Mail.SmtpClient
        $smtp.Host = $EmailConfig.SMTPServer
        $smtp.Port = $EmailConfig.Port
        $smtp.EnableSsl = $EmailConfig.UseSSL

        # Configurer les informations d'identification
        if ($EmailConfig.Credentials) {
            $password = $EmailConfig.Credentials.Password

            # Si le mot de passe est crypté, le décrypter
            if ($password.StartsWith("CRYPTED:")) {
                # Remplacer par votre logique de décryptage
                $password = $password.Substring(8) # Exemple simple
            }

            $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
            $credentials = New-Object System.Management.Automation.PSCredential($EmailConfig.Credentials.Username, $securePassword)
            $smtp.Credentials = $credentials.GetNetworkCredential()
        }

        # Envoyer l'email
        $smtp.Send($message)

        Write-Log -Message "Alerte email envoyée avec succès à $($EmailConfig.To -join ', ')" -Level "SUCCESS"
        return $true
    }
    catch {
        Write-Log -Message "Erreur lors de l'envoi de l'email: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour envoyer une alerte Teams
function Send-TeamsAlert {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [string]$WebhookUrl,

        [Parameter(Mandatory=$false)]
        [ValidateSet("default", "warning", "error", "success")]
        [string]$Type = "warning"
    )

    try {
        # Déterminer la couleur selon le type
        $color = switch ($Type) {
            "default" { "#cccccc" }
            "warning" { "#FFA500" }
            "error" { "#FF0000" }
            "success" { "#00FF00" }
        }

        # Créer le corps de la carte
        $body = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "themeColor" = $color
            "summary

```powershell
<#
.SYNOPSIS
    Gestion des produits pour une boutique en ligne via API
.DESCRIPTION
    Ce script permet d'interagir avec une API e-commerce factice pour gérer
    le catalogue produits. Il permet de lister, ajouter, modifier et supprimer
    des produits.
.PARAMETER Action
    Action à effectuer (Get, Add, Update, Delete)
.PARAMETER ApiKey
    Clé API pour l'authentification
.PARAMETER ProductId
    ID du produit pour les actions Update et Delete
.PARAMETER ProductData
    Données du produit pour les actions Add et Update (au format JSON)
.EXAMPLE
    .\Manage-Products.ps1 -Action Get -ApiKey "your_api_key"
.EXAMPLE
    .\Manage-Products.ps1 -Action Add -ApiKey "your_api_key" -ProductData '{"name":"Nouveau Produit","price":29.99,"category":"electronics","description":"Description du produit"}'
.EXAMPLE
    .\Manage-Products.ps1 -Action Update -ApiKey "your_api_key" -ProductId 5 -ProductData '{"name":"Produit Modifié","price":39.99}'
.EXAMPLE
    .\Manage-Products.ps1 -Action Delete -ApiKey "your_api_key" -ProductId 5
.NOTES
    Cette démo utilise l'API fictive fakestoreapi.com pour l'exemple
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Get", "Add", "Update", "Delete")]
    [string]$Action,

    [Parameter(Mandatory=$true)]
    [string]$ApiKey,

    [Parameter(Mandatory=$false)]
    [int]$ProductId = 0,

    [Parameter(Mandatory=$false)]
    [string]$ProductData = ""
)

# Configuration de l'API
$baseUrl = "https://fakestoreapi.com/products"
$headers = @{
    "X-API-Key" = $ApiKey
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

# Fonction pour afficher les produits de façon formatée
function Format-Products {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Products
    )

    $formattedProducts = foreach ($product in $Products) {
        [PSCustomObject]@{
            ID = $product.id
            Nom = $product.title.Substring(0, [Math]::Min(40, $product.title.Length)) + $(if ($product.title.Length -gt 40) {"..."} else {""})
            Prix = "$" + [Math]::Round($product.price, 2)
            Catégorie = $product.category
            Note = "$($product.rating.rate) ★ ($($product.rating.count) avis)"
        }
    }

    return $formattedProducts
}

# Exécution de l'action demandée
try {
    switch ($Action) {
        "Get" {
            Write-Host "Récupération de la liste des produits..." -ForegroundColor Cyan
            $response = Invoke-RestMethod -Uri $baseUrl -Headers $headers -Method Get -ErrorAction Stop

            if ($response.Count -eq 0) {
                Write-Host "Aucun produit trouvé." -ForegroundColor Yellow
            }
            else {
                $formattedProducts = Format-Products -Products $response
                Write-Host "`n$($response.Count) produits trouvés :" -ForegroundColor Green
                $formattedProducts | Format-Table -AutoSize

                # Option pour voir les détails d'un produit
                $viewDetails = Read-Host "Entrez l'ID d'un produit pour voir ses détails (ou appuyez sur Entrée pour quitter)"

                if ($viewDetails -match "^\d+$") {
                    $productId = [int]$viewDetails
                    $product = $response | Where-Object { $_.id -eq $productId }

                    if ($product) {
                        Write-Host "`nDétails du produit $productId :" -ForegroundColor Cyan
                        Write-Host "Nom : $($product.title)" -ForegroundColor White
                        Write-Host "Prix : $($product.price) $" -ForegroundColor White
                        Write-Host "Catégorie : $($product.category)" -ForegroundColor White
                        Write-Host "Description : $($product.description)" -ForegroundColor White
                        Write-Host "Note : $($product.rating.rate)/5 ($($product.rating.count) avis)" -ForegroundColor White
                        Write-Host "Image : $($product.image)" -ForegroundColor White
                    }
                    else {
                        Write-Host "Produit avec l'ID $productId non trouvé." -ForegroundColor Yellow
                    }
                }
            }
        }

        "Add" {
            if (-not $ProductData) {
                Write-Host "Erreur : Les données du produit sont requises pour l'ajout." -ForegroundColor Red
                exit 1
            }

            try {
                # Validation du JSON
                $productObj = $ProductData | ConvertFrom-Json
                Write-Host "Ajout d'un nouveau produit..." -ForegroundColor Cyan

                $response = Invoke-RestMethod -Uri $baseUrl -Headers $headers -Method Post -Body $ProductData -ErrorAction Stop

                Write-Host "`nProduit ajouté avec succès !" -ForegroundColor Green
                Write-Host "ID du nouveau produit : $($response.id)" -ForegroundColor Green
                Write-Host "Nom : $($response.title)" -ForegroundColor White
                Write-Host "Prix : $($response.price) $" -ForegroundColor White
                Write-Host "Catégorie : $($response.category)" -ForegroundColor White
            }
            catch {
                Write-Host "Erreur dans le format JSON des données du produit." -ForegroundColor Red
                exit 1
            }
        }

        "Update" {
            if ($ProductId -eq 0) {
                Write-Host "Erreur : L'ID du produit est requis pour la mise à jour." -ForegroundColor Red
                exit 1
            }

            if (-not $ProductData) {
                Write-Host "Erreur : Les données du produit sont requises pour la mise à jour." -ForegroundColor Red
                exit 1
            }

            try {
                # Validation du JSON
                $productObj = $ProductData | ConvertFrom-Json
                Write-Host "Mise à jour du produit $ProductId..." -ForegroundColor Cyan

                $response = Invoke-RestMethod -Uri "$baseUrl/$ProductId" -Headers $headers -Method Put -Body $ProductData -ErrorAction Stop

                Write-Host "`nProduit mis à jour avec succès !" -ForegroundColor Green
                Write-Host "ID : $($response.id)" -ForegroundColor Green
                Write-Host "Nom : $($response.title)" -ForegroundColor White
                Write-Host "Prix : $($response.price) $" -ForegroundColor White
                Write-Host "Catégorie : $($response.category)" -ForegroundColor White
            }
            catch {
                Write-Host "Erreur dans le format JSON des données du produit." -ForegroundColor Red
                exit 1
            }
        }

        "Delete" {
            if ($ProductId -eq 0) {
                Write-Host "Erreur : L'ID du produit est requis pour la suppression." -ForegroundColor Red
                exit 1
            }

            # Confirmation de suppression
            $confirmation = Read-Host "Êtes-vous sûr de vouloir supprimer le produit $ProductId ? (O/N)"

            if ($confirmation -eq "O" -or $confirmation -eq "o") {
                Write-Host "Suppression du produit $ProductId..." -ForegroundColor Cyan

                $response = Invoke-RestMethod -Uri "$baseUrl/$ProductId" -Headers $headers -Method Delete -ErrorAction Stop

                Write-Host "`nProduit supprimé avec succès !" -ForegroundColor Green
                Write-Host "ID : $($response.id)" -ForegroundColor Green
                Write-Host "Nom : $($response.title)" -ForegroundColor White
            }
            else {
                Write-Host "Suppression annulée." -ForegroundColor Yellow
            }
        }
    }
}
catch {
    Write-Host "Erreur lors de l'opération sur l'API :" -ForegroundColor Red

    if ($_.Exception.Response.StatusCode.value__) {
        $statusCode = $_.Exception.Response.StatusCode.value__

        switch ($statusCode) {
            401 { Write-Host "Erreur d'authentification. Vérifiez votre clé API." -ForegroundColor Red }
            403 { Write-Host "Accès refusé. Vérifiez vos permissions." -ForegroundColor Red }
            404 {
                if ($Action -eq "Update" -or $Action -eq "Delete") {
                    Write-Host "Produit avec l'ID $ProductId non trouvé." -ForegroundColor Red
                }
                else {
                    Write-Host "Ressource non trouvée. Vérifiez l'URL de l'API." -ForegroundColor Red
                }
            }
            default { Write-Host "Erreur HTTP $statusCode lors de l'appel à l'API." -ForegroundColor Red }
        }

        if ($_.ErrorDetails.Message) {
            try {
                $errorDetails = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Host "Message d'erreur de l'API : $($errorDetails.message)" -ForegroundColor Red
            }
            catch {
                Write-Host "Détails de l'erreur : $($_.ErrorDetails.Message)" -ForegroundColor Red
            }
        }
    }
    else {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }

    exit 1
}
```
