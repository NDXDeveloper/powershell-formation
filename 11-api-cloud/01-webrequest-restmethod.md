# Module 12 - API, Web & Cloud

## 12-1. `Invoke-WebRequest` vs `Invoke-RestMethod`

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### Introduction

Dans le monde connecté d'aujourd'hui, interagir avec des sites web et des API est une compétence essentielle pour tout administrateur système ou développeur. PowerShell offre deux cmdlets puissantes pour communiquer avec le web :
- `Invoke-WebRequest` (alias: `iwr`, `curl`, `wget`)
- `Invoke-RestMethod` (alias: `irm`)

Comprendre leurs différences et savoir quand utiliser l'une plutôt que l'autre vous permettra de travailler efficacement avec des ressources web.

### 📌 Invoke-WebRequest - Vue d'ensemble

`Invoke-WebRequest` est conçu pour interagir avec des pages web et récupérer leur contenu complet, y compris les en-têtes HTTP, les cookies, les formulaires et le code HTML.

**Cas d'utilisation:**
- Télécharger des fichiers
- Scraper des sites web
- Remplir et soumettre des formulaires
- Accéder à des ressources nécessitant une authentification
- Analyser des pages HTML

### 📌 Invoke-RestMethod - Vue d'ensemble

`Invoke-RestMethod` est spécialisé pour travailler avec des API REST et traiter automatiquement les réponses dans des formats comme JSON, XML ou RSS.

**Cas d'utilisation:**
- Appels d'API REST
- Consommation de données JSON/XML
- Intégration avec des services web
- Automatisation des interactions avec les API cloud

### 🔄 Comparaison des deux cmdlets

| Aspect | Invoke-WebRequest | Invoke-RestMethod |
|--------|-------------------|-------------------|
| Objectif principal | Pages web et HTML | API REST et données structurées |
| Format de retour | Objet réponse HTTP complet | Données déjà désérialisées |
| Traitement JSON/XML | Manuel | Automatique |
| Complexité | Plus détaillé | Plus simple pour les API |
| Performances | Peut être plus lourd | Généralement plus léger |

### 💻 Exemples pratiques

#### Exemple 1: Utilisation basique

```powershell
# Avec Invoke-WebRequest
$response = Invoke-WebRequest -Uri "https://jsonplaceholder.typicode.com/todos/1"
$content = $response.Content | ConvertFrom-Json
$content.title

# Avec Invoke-RestMethod (plus simple)
$todo = Invoke-RestMethod -Uri "https://jsonplaceholder.typicode.com/todos/1"
$todo.title
```

#### Exemple 2: Télécharger un fichier

```powershell
# Télécharger un fichier avec Invoke-WebRequest
Invoke-WebRequest -Uri "https://example.com/example.zip" -OutFile "C:\Downloads\example.zip"
```

#### Exemple 3: Naviguer sur un site avec authentification

```powershell
# Créer des informations d'identification
$credentials = Get-Credential

# Se connecter à un site avec authentification
$response = Invoke-WebRequest -Uri "https://monsite.com/login" -Credential $credentials -SessionVariable 'maSession'

# Utiliser la session pour naviguer sur d'autres pages
$pageProtegee = Invoke-WebRequest -Uri "https://monsite.com/page-protegee" -WebSession $maSession
```

#### Exemple 4: Appel d'API REST avec paramètres

```powershell
# Paramètres de requête
$params = @{
    api_key = "votre_clé_api"
    q = "PowerShell"
    format = "json"
}

# Appel d'API avec Invoke-RestMethod
$resultats = Invoke-RestMethod -Uri "https://api.example.com/search" -Body $params
$resultats.items | ForEach-Object { $_.title }
```

### 🛠️ Paramètres communs importants

Les deux cmdlets partagent plusieurs paramètres utiles :

- `-Uri` : URL de la requête
- `-Method` : Méthode HTTP (GET, POST, PUT, DELETE...)
- `-Headers` : En-têtes HTTP personnalisés
- `-Body` : Données à envoyer (formulaire ou JSON)
- `-ContentType` : Type de contenu des données envoyées
- `-UserAgent` : Agent utilisateur personnalisé
- `-TimeoutSec` : Délai d'expiration en secondes

### 🧩 Traitement des réponses

#### Avec Invoke-WebRequest

```powershell
$response = Invoke-WebRequest -Uri "https://exemple.com"

# Propriétés disponibles
$response.StatusCode  # Code HTTP (200, 404, etc.)
$response.Headers     # En-têtes de réponse
$response.Content     # Contenu brut
$response.Links       # Liens dans la page HTML
$response.Forms       # Formulaires dans la page HTML
$response.Images      # Images dans la page HTML

# Pour les réponses JSON
$jsonData = $response.Content | ConvertFrom-Json
```

#### Avec Invoke-RestMethod

```powershell
$data = Invoke-RestMethod -Uri "https://api.exemple.com/data"

# Le résultat est déjà désérialisé
$data.propriete
$data.items | Where-Object { $_.actif -eq $true }
```

### ⚠️ Gestion des erreurs

```powershell
try {
    $response = Invoke-RestMethod -Uri "https://api.exemple.com/ressource-inexistante"
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $message = $_.ErrorDetails.Message

    Write-Host "Erreur $statusCode : $message"
}
```

### 🔐 Authentification et sécurité

Les deux cmdlets supportent différentes méthodes d'authentification :

```powershell
# Authentification Basic
$credentials = Get-Credential
Invoke-RestMethod -Uri "https://api.exemple.com" -Credential $credentials

# Authentification par token (OAuth, JWT, etc.)
$headers = @{
    "Authorization" = "Bearer votre_token_ici"
}
Invoke-RestMethod -Uri "https://api.exemple.com" -Headers $headers
```

### 🚀 Conseils pour débutants

1. **Commencez simple** : Expérimentez d'abord avec des API publiques qui ne nécessitent pas d'authentification
2. **Utilisez les alias** : `iwr` et `irm` sont plus rapides à taper que les noms complets
3. **Inspectez les réponses** : Utilisez `| Format-List -Property *` ou `| Get-Member` pour explorer les propriétés retournées
4. **Pour les API** : Préférez toujours `Invoke-RestMethod`
5. **Pour le web scraping** : Utilisez `Invoke-WebRequest`

### 🔍 Exemple pratique : API météo

```powershell
# Récupérer la météo d'une ville avec une API publique
$ville = "Paris"
$apiKey = "votre_clé_api" # Obtenez une clé gratuite sur OpenWeatherMap

$meteo = Invoke-RestMethod -Uri "https://api.openweathermap.org/data/2.5/weather?q=$ville&units=metric&appid=$apiKey"

Write-Host "Météo à $($meteo.name) :"
Write-Host "Température: $($meteo.main.temp)°C"
Write-Host "Conditions: $($meteo.weather[0].description)"
Write-Host "Humidité: $($meteo.main.humidity)%"
```

### 📚 Pour aller plus loin

- Explorez la documentation complète avec `Get-Help Invoke-WebRequest -Full`
- Testez vos appels API avec des outils comme Postman avant de les implémenter en PowerShell
- Étudiez les formats JSON et XML pour mieux comprendre les réponses d'API
- Apprenez à utiliser le paramètre `-SessionVariable` pour gérer les cookies et les sessions

---

### 💡 Exercice pratique

Créez un script qui :
1. Récupère les derniers articles d'un blog ou d'un site d'actualités via une API ou en analysant le HTML
2. Extrait les titres et les dates
3. Affiche les résultats dans un tableau formaté

**Indice** : Utilisez `Invoke-RestMethod` si le site propose une API ou un flux RSS, sinon utilisez `Invoke-WebRequest` et analysez le HTML.
