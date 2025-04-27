# 12-3. Consommer une API REST, envoyer du JSON

## Introduction

Dans ce chapitre, nous allons explorer comment utiliser PowerShell pour interagir avec des API REST et manipuler des données au format JSON. Cette compétence est essentielle pour l'automatisation moderne et l'intégration avec des services web.

## Qu'est-ce qu'une API REST ?

Une API REST (Representational State Transfer) est une interface qui permet à différents systèmes de communiquer sur internet. Elle utilise généralement le protocole HTTP et ses méthodes standard (GET, POST, PUT, DELETE).

Les API REST sont aujourd'hui omniprésentes :
- Applications mobiles
- Sites web
- Services cloud
- Applications d'entreprise

## Pourquoi le format JSON ?

JSON (JavaScript Object Notation) est un format léger d'échange de données facile à lire pour les humains et à analyser pour les machines. Il est devenu le standard pour les API modernes.

En PowerShell, le JSON se transforme facilement en objets que nous pouvons manipuler, et vice-versa.

## Les commandes PowerShell pour les API REST

PowerShell propose deux cmdlets principales pour interagir avec les API REST :

1. `Invoke-RestMethod` : Recommandée pour la plupart des cas
2. `Invoke-WebRequest` : Pour les besoins plus avancés ou spécifiques

## Exemples pratiques

### 1. Récupérer des données avec une API publique

Commençons par un exemple simple pour obtenir des informations sur l'ISS (Station Spatiale Internationale) :

```powershell
# Récupération de la position actuelle de l'ISS
$issPosition = Invoke-RestMethod -Uri "http://api.open-notify.org/iss-now.json" -Method Get

# Affichage du résultat
$issPosition

# Accès aux propriétés spécifiques
$issPosition.iss_position.latitude
$issPosition.iss_position.longitude
```

PowerShell convertit automatiquement la réponse JSON en un objet PowerShell que nous pouvons facilement manipuler.

### 2. Utiliser des paramètres dans une requête

De nombreuses API permettent de filtrer ou personnaliser les résultats via des paramètres :

```powershell
# Récupération des informations sur 5 utilisateurs aléatoires
$params = @{
    results = 5
    nat = "fr"
}

$users = Invoke-RestMethod -Uri "https://randomuser.me/api/" -Method Get -Body $params

# Affichage des noms des utilisateurs
$users.results | ForEach-Object {
    "$($_.name.first) $($_.name.last)"
}
```

### 3. Envoyer des données JSON (POST)

Pour envoyer des données à une API, nous devons souvent créer un objet et le convertir en JSON :

```powershell
# Création d'un objet PowerShell
$newPost = @{
    title = "Apprendre PowerShell"
    body = "Les API REST sont faciles à utiliser avec PowerShell"
    userId = 1
}

# Conversion en JSON
$jsonBody = $newPost | ConvertTo-Json

# Envoi des données
$response = Invoke-RestMethod -Uri "https://jsonplaceholder.typicode.com/posts" -Method Post -Body $jsonBody -ContentType "application/json"

# Affichage de la réponse
$response
```

### 4. Gérer l'authentification

La plupart des API professionnelles nécessitent une authentification. Voici comment gérer les types courants :

#### Authentification basique

```powershell
# Création des identifiants
$secPassword = ConvertTo-SecureString "MotDePasse123" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("utilisateur", $secPassword)

# Requête avec authentification
$response = Invoke-RestMethod -Uri "https://api.exemple.com/donnees" -Credential $credential
```

#### Authentification par jeton (Token)

```powershell
# Définition du jeton d'accès
$token = "votre_token_ici"

# Création de l'en-tête d'authentification
$headers = @{
    "Authorization" = "Bearer $token"
}

# Requête avec jeton d'authentification
$response = Invoke-RestMethod -Uri "https://api.exemple.com/donnees" -Headers $headers
```

## Traitement des réponses

Une fois les données récupérées, PowerShell facilite leur manipulation :

```powershell
# Récupération d'une liste de tâches
$todos = Invoke-RestMethod -Uri "https://jsonplaceholder.typicode.com/todos"

# Filtrage des tâches terminées
$completedTasks = $todos | Where-Object { $_.completed -eq $true }

# Comptage des tâches par utilisateur
$taskCountByUser = $todos | Group-Object userId | Select-Object Name, Count

# Exportation des résultats
$completedTasks | Export-Csv -Path "taches_terminees.csv" -NoTypeInformation
$taskCountByUser | Export-Csv -Path "taches_par_utilisateur.csv" -NoTypeInformation
```

## Gestion des erreurs

Les API peuvent renvoyer des erreurs. Voici comment les gérer :

```powershell
try {
    $response = Invoke-RestMethod -Uri "https://api.exemple.com/ressource_inexistante" -ErrorAction Stop
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $statusDescription = $_.Exception.Response.StatusDescription

    Write-Host "Erreur $statusCode : $statusDescription" -ForegroundColor Red

    # Pour les erreurs avec un corps de réponse
    if ($_.ErrorDetails.Message) {
        $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Host "Détails de l'erreur : $($errorBody.message)" -ForegroundColor Red
    }
}
```

## Exercice pratique

Créez un script qui :
1. Récupère la météo actuelle pour une ville de votre choix via l'API OpenWeatherMap
2. Extrait les informations essentielles (température, humidité, description)
3. Affiche un message formaté avec ces informations

```powershell
# Remplacez YOUR_API_KEY par votre clé API obtenue sur openweathermap.org
$apiKey = "YOUR_API_KEY"
$city = "Paris"

# Construction de l'URL avec les paramètres
$uri = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=fr"

try {
    # Récupération des données météo
    $weather = Invoke-RestMethod -Uri $uri -Method Get

    # Formatage et affichage des résultats
    Write-Host "Météo actuelle à $($weather.name) :" -ForegroundColor Cyan
    Write-Host "Température : $($weather.main.temp)°C"
    Write-Host "Ressenti : $($weather.main.feels_like)°C"
    Write-Host "Humidité : $($weather.main.humidity)%"
    Write-Host "Conditions : $($weather.weather[0].description)"
}
catch {
    Write-Host "Erreur lors de la récupération des données météo : $_" -ForegroundColor Red
}
```

## Bonnes pratiques

1. **Utiliser des paramètres nommés** : Préférez `-Uri` à `http://...` pour plus de clarté
2. **Gérer les erreurs** : Utilisez toujours `try/catch` pour les appels API
3. **Respecter les limites** : Attention aux limites de taux (rate limiting) des API
4. **Stocker les secrets de façon sécurisée** : Ne codez jamais en dur les clés API
5. **Valider les entrées utilisateur** : Surtout si elles sont incluses dans les URL
6. **Utiliser ConvertTo-Json avec -Depth** : Pour les objets complexes, spécifiez `-Depth` pour éviter la troncature

## Conclusion

PowerShell avec `Invoke-RestMethod` et `Invoke-WebRequest` offre une façon simple et efficace d'interagir avec des API REST. Ces compétences vous permettront d'automatiser l'interaction avec de nombreux services web et d'intégrer différentes plateformes dans vos scripts.

Dans le prochain chapitre, nous verrons comment utiliser ces connaissances pour interagir avec des API spécifiques comme GitHub, Azure ou Microsoft Teams.

## Ressources supplémentaires

- [Documentation Microsoft sur Invoke-RestMethod](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-restmethod)
- [Documentation Microsoft sur Invoke-WebRequest](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/invoke-webrequest)
- [JSONPlaceholder](https://jsonplaceholder.typicode.com/) - API de test gratuite
- [Postman](https://www.postman.com/) - Outil utile pour tester les API avant de les utiliser dans PowerShell

