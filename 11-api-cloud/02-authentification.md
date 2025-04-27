# Module 12 - API, Web & Cloud
## 12-2. Authentification (Basic, Bearer, Token)

Dans le monde des API et des services web, l'authentification est une étape essentielle pour sécuriser les communications. PowerShell offre plusieurs méthodes pour gérer différents types d'authentification lors de vos requêtes web.

### Pourquoi l'authentification est nécessaire

Lorsque vous interagissez avec des API, la plupart nécessitent une forme d'authentification pour :
- Vérifier votre identité
- Contrôler votre accès aux ressources
- Suivre votre utilisation des services
- Protéger les données sensibles

### Types d'authentification courants

#### 1. Authentification Basic

L'authentification Basic est la forme la plus simple : elle utilise un nom d'utilisateur et un mot de passe.

```powershell
# Préparation des identifiants
$username = "votre_utilisateur"
$password = "votre_mot_de_passe"

# Méthode 1 : Création manuelle de l'en-tête
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${username}:${password}"))
$headers = @{
    Authorization = "Basic $base64AuthInfo"
}

# Méthode 2 : Utilisation d'un objet PSCredential (plus sécurisé)
$secPassword = ConvertTo-SecureString $password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $secPassword)

# Appel API avec authentification Basic
$response = Invoke-RestMethod -Uri "https://api.exemple.com/ressource" -Headers $headers
# OU
$response = Invoke-RestMethod -Uri "https://api.exemple.com/ressource" -Credential $credential -Authentication Basic
```

> ⚠️ **Attention** : L'authentification Basic n'est pas considérée comme très sécurisée si elle n'est pas utilisée avec HTTPS, car les identifiants sont simplement encodés (non chiffrés).

#### 2. Authentification Bearer Token

L'authentification par Bearer Token utilise un jeton d'accès (souvent généré via OAuth) qui est envoyé dans l'en-tête de la requête.

```powershell
# Le token peut provenir d'un processus d'authentification préalable
$token = "votre_token_d_acces"

$headers = @{
    Authorization = "Bearer $token"
}

$response = Invoke-RestMethod -Uri "https://api.exemple.com/ressource" -Headers $headers
```

Exemple plus complet avec OAuth 2.0 (pour obtenir un token d'abord) :

```powershell
# Étape 1 : Obtenir un token
$authBody = @{
    client_id     = "votre_client_id"
    client_secret = "votre_client_secret"
    grant_type    = "client_credentials"
    scope         = "api://votre_api/lecture"
}

$tokenResponse = Invoke-RestMethod -Uri "https://auth.service.com/oauth2/token" -Method Post -Body $authBody

# Étape 2 : Utiliser le token pour les appels API
$headers = @{
    Authorization = "Bearer $($tokenResponse.access_token)"
}

$apiResponse = Invoke-RestMethod -Uri "https://api.service.com/data" -Headers $headers
```

#### 3. API Key Authentication

Certaines API utilisent une clé API, qui peut être envoyée dans l'URL, dans l'en-tête ou dans le corps de la requête.

```powershell
# Dans l'en-tête (méthode recommandée)
$headers = @{
    "X-API-Key" = "votre_cle_api"
}

$response = Invoke-RestMethod -Uri "https://api.exemple.com/ressource" -Headers $headers

# OU dans l'URL (moins sécurisé)
$response = Invoke-RestMethod -Uri "https://api.exemple.com/ressource?api_key=votre_cle_api"
```

### Gestion sécurisée des identifiants

Il est important de ne pas coder en dur vos identifiants dans vos scripts. Voici quelques meilleures pratiques :

```powershell
# Utiliser SecureString pour les mots de passe
$securePassword = Read-Host "Entrez votre mot de passe" -AsSecureString

# Stockage temporaire de mot de passe en mémoire seulement
$credential = Get-Credential

# Utiliser des variables d'environnement
$apiKey = $env:API_KEY

# Utiliser le stockage sécurisé Windows pour les scripts d'automation
$password = Get-StoredCredential -Target "MonAPI" | Select-Object -ExpandProperty Password
```

### Exemple pratique : Appel à l'API GitHub

Voici un exemple concret d'authentification auprès de l'API GitHub :

```powershell
# Créer un token d'accès personnel sur GitHub
# puis l'utiliser pour l'authentification
$token = "ghp_votre_token_personnel"
$headers = @{
    Authorization = "token $token"
    Accept = "application/vnd.github.v3+json"
}

# Obtenir les informations de votre profil
$profile = Invoke-RestMethod -Uri "https://api.github.com/user" -Headers $headers

# Afficher votre nom d'utilisateur
Write-Host "Connecté en tant que: $($profile.login)"

# Lister vos dépôts
$repos = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Headers $headers
$repos | Select-Object -Property name, description, html_url | Format-Table
```

### Résolution des problèmes d'authentification

Si vous rencontrez des problèmes d'authentification, voici quelques conseils de débogage :

```powershell
# Afficher les détails complets de la réponse HTTP
try {
    $response = Invoke-WebRequest -Uri "https://api.exemple.com/ressource" -Headers $headers -ErrorAction Stop
    $response | Format-List StatusCode, StatusDescription, Headers, Content
}
catch {
    Write-Host "Erreur: $_"
    Write-Host "StatusCode: $($_.Exception.Response.StatusCode.value__)"
    # Pour PowerShell 7+
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Host "Détails: $($_.ErrorDetails.Message)"
    }
}
```

### En résumé

1. **Basic Auth** : Nom d'utilisateur + mot de passe encodés en Base64
2. **Bearer Token** : Jeton d'accès (souvent OAuth) dans l'en-tête Authorization
3. **API Key** : Clé API dans l'en-tête, l'URL ou le corps de la requête

L'authentification est une composante critique de la sécurité dans vos scripts PowerShell interagissant avec des API. Choisissez la méthode appropriée selon le service que vous utilisez et suivez toujours les bonnes pratiques pour protéger vos identifiants.

---

**Exercice pratique :**
Créez un script qui récupère la météo d'une ville en utilisant l'API OpenWeatherMap (qui nécessite une clé API). Vous pouvez obtenir une clé gratuite en vous inscrivant sur leur site.

**Solution :**

```powershell
# Remplacez par votre clé API OpenWeatherMap
$apiKey = "votre_cle_api"
$ville = "Paris"

# Appel API avec la clé dans l'URL
$meteo = Invoke-RestMethod -Uri "https://api.openweathermap.org/data/2.5/weather?q=$ville&units=metric&appid=$apiKey"

# Affichage des résultats
Write-Host "Météo actuelle à $($meteo.name):"
Write-Host "Température: $($meteo.main.temp)°C"
Write-Host "Conditions: $($meteo.weather[0].description)"
Write-Host "Humidité: $($meteo.main.humidity)%"
```
