# ===========================================================================
# Solution de l'exercice - API OpenWeatherMap avec authentification par clé API
# Module 12-2: Authentification (Basic, Bearer, Token)
# ===========================================================================

<#
.SYNOPSIS
    Script qui récupère et affiche la météo actuelle d'une ville à l'aide de l'API OpenWeatherMap.

.DESCRIPTION
    Ce script utilise l'API OpenWeatherMap pour récupérer les données météorologiques
    d'une ville spécifiée par l'utilisateur. Il démontre l'utilisation de l'authentification
    par clé API dans une requête REST.

.PARAMETER ApiKey
    Clé API OpenWeatherMap. Vous pouvez obtenir une clé gratuite en vous inscrivant sur https://openweathermap.org/api

.PARAMETER Ville
    Nom de la ville dont vous souhaitez connaître la météo.

.EXAMPLE
    .\Get-MeteoVille.ps1 -ApiKey "votre_cle_api" -Ville "Paris"

.NOTES
    Auteur: Formation PowerShell
    Date de création: 27/04/2025
    Exigences: PowerShell 5.1 ou supérieur
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Entrez votre clé API OpenWeatherMap")]
    [string]$ApiKey,

    [Parameter(Mandatory = $false, HelpMessage = "Entrez le nom de la ville")]
    [string]$Ville = "Paris"
)

# Fonction pour formater le timestamp Unix en date/heure lisible
function ConvertFrom-UnixTimestamp {
    param (
        [Parameter(Mandatory = $true)]
        [long]$UnixTimestamp
    )

    return [DateTimeOffset]::FromUnixTimeSeconds($UnixTimestamp).LocalDateTime
}

# Fonction pour convertir la direction du vent en points cardinaux
function ConvertTo-DirectionVent {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Degres
    )

    $directions = @("N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSO", "SO", "OSO", "O", "ONO", "NO", "NNO", "N")
    $index = [Math]::Round($Degres / 22.5)

    return $directions[$index]
}

# Gestion des erreurs avec un bloc try/catch
try {
    # Construction de l'URL avec paramètres de requête et authentification par clé API
    $baseUrl = "https://api.openweathermap.org/data/2.5/weather"
    $requestUrl = "$baseUrl?q=$Ville&units=metric&lang=fr&appid=$ApiKey"

    # Affichage du message de progression
    Write-Verbose "Récupération des données météo pour $Ville..."

    # Appel à l'API avec gestion explicite du timeout (10 secondes)
    $meteoData = Invoke-RestMethod -Uri $requestUrl -Method Get -TimeoutSec 10

    # Vérification que nous avons bien reçu des données
    if ($null -eq $meteoData) {
        throw "Aucune donnée n'a été retournée par l'API."
    }

    # Extraction et préparation des données
    $nomVille = $meteoData.name
    $pays = $meteoData.sys.country
    $temperature = [Math]::Round($meteoData.main.temp, 1)
    $ressenti = [Math]::Round($meteoData.main.feels_like, 1)
    $tempMin = [Math]::Round($meteoData.main.temp_min, 1)
    $tempMax = [Math]::Round($meteoData.main.temp_max, 1)
    $description = $meteoData.weather[0].description
    $humidite = $meteoData.main.humidity
    $vitesseVent = [Math]::Round($meteoData.wind.speed * 3.6, 1)  # Conversion en km/h
    $directionVent = ConvertTo-DirectionVent -Degres $meteoData.wind.deg
    $lever = ConvertFrom-UnixTimestamp -UnixTimestamp $meteoData.sys.sunrise
    $coucher = ConvertFrom-UnixTimestamp -UnixTimestamp $meteoData.sys.sunset

    # Création d'un objet personnalisé pour stocker les résultats
    $meteoResultat = [PSCustomObject]@{
        Ville = $nomVille
        Pays = $pays
        Date = (Get-Date)
        TemperatureActuelle = "$temperature °C"
        TemperatureRessentie = "$ressenti °C"
        TemperatureMin = "$tempMin °C"
        TemperatureMax = "$tempMax °C"
        Description = $description
        Humidite = "$humidite %"
        Vent = "$vitesseVent km/h $directionVent"
        LeverSoleil = $lever.ToString("HH:mm")
        CoucherSoleil = $coucher.ToString("HH:mm")
    }

    # Affichage des résultats avec formatage
    Write-Host "`n========== MÉTÉO ACTUELLE ==========" -ForegroundColor Cyan
    Write-Host "Ville: $($meteoResultat.Ville), $($meteoResultat.Pays)" -ForegroundColor Yellow
    Write-Host "Date: $($meteoResultat.Date.ToString('dd/MM/yyyy HH:mm'))`n" -ForegroundColor Yellow

    Write-Host "Température: $($meteoResultat.TemperatureActuelle) (ressenti $($meteoResultat.TemperatureRessentie))"
    Write-Host "Min/Max: $($meteoResultat.TemperatureMin) / $($meteoResultat.TemperatureMax)"
    Write-Host "Conditions: $($meteoResultat.Description)"
    Write-Host "Humidité: $($meteoResultat.Humidite)"
    Write-Host "Vent: $($meteoResultat.Vent)"
    Write-Host "Soleil: Lever à $($meteoResultat.LeverSoleil), coucher à $($meteoResultat.CoucherSoleil)"
    Write-Host "======================================`n"

    # Retourner l'objet pour l'utiliser dans un pipeline si besoin
    return $meteoResultat
}
catch [System.Net.WebException] {
    # Gestion spécifique des erreurs réseau
    Write-Error "Erreur de connexion à l'API: $_"
    Write-Host "Vérifiez votre connexion Internet et que l'API OpenWeatherMap est accessible." -ForegroundColor Red
}
catch {
    # Gestion des autres erreurs
    if ($_.Exception.Response.StatusCode.value__ -eq 401) {
        Write-Error "Erreur d'authentification: Clé API invalide ou expirée."
        Write-Host "Vérifiez votre clé API sur openweathermap.org" -ForegroundColor Red
    }
    elseif ($_.Exception.Response.StatusCode.value__ -eq 404) {
        Write-Error "Ville non trouvée: La ville '$Ville' n'existe pas dans la base de données."
        Write-Host "Essayez avec un autre nom de ville ou vérifiez l'orthographe." -ForegroundColor Red
    }
    else {
        Write-Error "Erreur inattendue: $_"
    }
}

# ===========================================================================
# Solution bonus - Authentification Basic pour une API personnalisée
# ===========================================================================

<#
.SYNOPSIS
    Script démontrant l'authentification Basic pour accéder à une API REST.

.DESCRIPTION
    Ce script utilise l'authentification Basic (nom d'utilisateur et mot de passe)
    pour accéder à une API REST protégée.

.EXAMPLE
    .\Invoke-BasicAuthAPI.ps1 -Uri "https://api.exemple.com/ressource" -Username "utilisateur" -Password "motdepasse"

.NOTES
    Auteur: Formation PowerShell
    Date de création: 27/04/2025
    Exigences: PowerShell 5.1 ou supérieur
#>

function Invoke-BasicAuthAPI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Password,

        [Parameter(Mandatory = $false)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        [Parameter(Mandatory = $false)]
        [object]$Body = $null
    )

    try {
        # Transformation du mot de passe en SecureString
        $secPassword = ConvertTo-SecureString $Password -AsPlainText -Force

        # Création d'un objet d'identifiants sécurisé
        $credential = New-Object System.Management.Automation.PSCredential($Username, $secPassword)

        # Paramètres de la requête
        $params = @{
            Uri = $Uri
            Method = $Method
            Authentication = "Basic"
            Credential = $credential
            ContentType = "application/json"
            UseBasicParsing = $true
        }

        # Ajout du corps de la requête si fourni
        if ($null -ne $Body) {
            if ($Body -is [string]) {
                $params.Body = $Body
            }
            else {
                $params.Body = $Body | ConvertTo-Json -Depth 10
            }
        }

        # Exécution de la requête
        Write-Verbose "Envoi de la requête $Method à $Uri avec authentification Basic..."
        $response = Invoke-RestMethod @params

        return $response
    }
    catch {
        Write-Error "Erreur lors de l'appel API: $_"

        # Affichage détaillé de l'erreur
        if ($null -ne $_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDescription = $_.Exception.Response.StatusDescription

            Write-Host "Code d'erreur HTTP: $statusCode - $statusDescription" -ForegroundColor Red

            # Si on a des détails d'erreur, les afficher
            if ($null -ne $_.ErrorDetails -and $null -ne $_.ErrorDetails.Message) {
                try {
                    $errorInfo = $_.ErrorDetails.Message | ConvertFrom-Json
                    Write-Host "Détails de l'erreur:" -ForegroundColor Red
                    $errorInfo | Format-List
                }
                catch {
                    Write-Host "Message d'erreur: $($_.ErrorDetails.Message)" -ForegroundColor Red
                }
            }
        }

        throw $_
    }
}

# Exemple d'utilisation (commenté)
<#
# Appel à une API fictive avec authentification Basic
$resultat = Invoke-BasicAuthAPI -Uri "https://api.exemple.com/donnees" `
                               -Username "utilisateur" `
                               -Password "motdepasse" `
                               -Method Get `
                               -Verbose

# Affichage des résultats
$resultat | Format-Table -AutoSize
#>

# ===========================================================================
# Solution bonus - Authentification OAuth/Bearer pour Microsoft Graph API
# ===========================================================================

<#
.SYNOPSIS
    Script qui se connecte à Microsoft Graph API avec authentification OAuth.

.DESCRIPTION
    Ce script obtient un token OAuth pour Microsoft Graph API et l'utilise
    pour effectuer des requêtes. Il démontre l'authentification avec token Bearer.

.EXAMPLE
    .\Connect-MicrosoftGraph.ps1 -ClientId "votre_client_id" -TenantId "votre_tenant_id" -ClientSecret "votre_secret"

.NOTES
    Auteur: Formation PowerShell
    Date de création: 27/04/2025
    Exigences: PowerShell 5.1 ou supérieur
    Nécessite l'enregistrement préalable d'une application dans Azure AD
#>

function Connect-MicrosoftGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    try {
        # Construction de l'URL du point de terminaison d'authentification
        $tokenUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

        # Préparation du corps de la requête pour obtenir le token
        $tokenBody = @{
            client_id     = $ClientId
            scope         = "https://graph.microsoft.com/.default"
            client_secret = $ClientSecret
            grant_type    = "client_credentials"
        }

        Write-Verbose "Obtention du token OAuth pour Microsoft Graph API..."

        # Requête pour obtenir le token
        $tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody -ContentType "application/x-www-form-urlencoded"

        # Création de l'en-tête d'autorisation avec le token obtenu
        $headers = @{
            "Authorization" = "Bearer $($tokenResponse.access_token)"
            "Content-Type"  = "application/json"
        }

        # Création d'un objet session pour stocker les informations d'authentification
        $session = [PSCustomObject]@{
            Token         = $tokenResponse.access_token
            TokenType     = $tokenResponse.token_type
            ExpiresIn     = $tokenResponse.expires_in
            ExpiresAt     = (Get-Date).AddSeconds($tokenResponse.expires_in)
            Headers       = $headers
            ClientId      = $ClientId
            TenantId      = $TenantId
        }

        Write-Host "Connecté avec succès à Microsoft Graph API!" -ForegroundColor Green
        Write-Host "Le token expire le: $($session.ExpiresAt)" -ForegroundColor Yellow

        return $session
    }
    catch {
        Write-Error "Erreur lors de l'authentification à Microsoft Graph API: $_"
        throw $_
    }
}

function Invoke-MicrosoftGraphRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Session,

        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $false)]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

        [Parameter(Mandatory = $false)]
        [object]$Body = $null
    )

    # Vérifier si le token est expiré
    if ((Get-Date) -ge $Session.ExpiresAt) {
        Write-Warning "Le token OAuth est expiré. Veuillez vous reconnecter."
        throw "Token expiré"
    }

    try {
        # Construire l'URL complète si nécessaire
        if (-not $Uri.StartsWith("https://")) {
            $Uri = "https://graph.microsoft.com/v1.0/$Uri"
        }

        # Paramètres de la requête
        $params = @{
            Uri     = $Uri
            Method  = $Method
            Headers = $Session.Headers
        }

        # Ajout du corps de la requête si fourni
        if ($null -ne $Body) {
            if ($Body -is [string]) {
                $params.Body = $Body
            }
            else {
                $params.Body = $Body | ConvertTo-Json -Depth 10
            }
        }

        Write-Verbose "Envoi de la requête $Method à $Uri..."
        $response = Invoke-RestMethod @params

        return $response
    }
    catch {
        Write-Error "Erreur lors de l'appel à Microsoft Graph API: $_"
        throw $_
    }
}

# Exemple d'utilisation (commenté)
<#
# Connexion à Microsoft Graph API
$graphSession = Connect-MicrosoftGraph -ClientId "votre_client_id" `
                                      -TenantId "votre_tenant_id" `
                                      -ClientSecret "votre_client_secret" `
                                      -Verbose

# Obtenir la liste des utilisateurs
$users = Invoke-MicrosoftGraphRequest -Session $graphSession -Uri "users" -Method Get

# Afficher les utilisateurs
$users.value | Select-Object displayName, userPrincipalName, id | Format-Table -AutoSize
#>
