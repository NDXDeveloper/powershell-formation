# 12-4. Appels vers GitHub, Azure, Teams, etc.

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Dans cette section, nous allons explorer comment utiliser PowerShell pour interagir avec des services populaires comme GitHub, Microsoft Azure et Microsoft Teams. Ces interactions vous permettront d'automatiser de nombreuses tâches quotidiennes liées à ces plateformes.

## GitHub

GitHub est une plateforme de développement collaboratif très utilisée qui dispose d'une API REST complète. Voici comment interagir avec elle via PowerShell :

### Authentification avec GitHub

Pour la plupart des opérations GitHub, vous aurez besoin d'un token d'accès personnel :

```powershell
# Définir votre token GitHub (à stocker de façon sécurisée dans un environnement de production)
$token = "votre_token_github"
$headers = @{
    Authorization = "token $token"
    Accept = "application/vnd.github.v3+json"  # Spécifie la version de l'API
}
```

### Obtenir des informations sur un utilisateur GitHub

```powershell
# Récupérer les informations d'un utilisateur
$username = "octocat"  # Remplacez par n'importe quel nom d'utilisateur GitHub
$userInfo = Invoke-RestMethod -Uri "https://api.github.com/users/$username" -Headers $headers
$userInfo | Format-List login, name, location, public_repos
```

### Lister les repositories d'un utilisateur

```powershell
# Lister les repositories publics d'un utilisateur
$repos = Invoke-RestMethod -Uri "https://api.github.com/users/$username/repos" -Headers $headers
$repos | Select-Object name, description, language, stargazers_count | Format-Table -AutoSize
```

### Créer un nouveau repository

```powershell
# Créer un nouveau repository
$newRepoParams = @{
    name = "mon-nouveau-repo"
    description = "Créé avec PowerShell"
    private = $true  # $true pour un repo privé, $false pour public
}

$jsonBody = $newRepoParams | ConvertTo-Json
$newRepo = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $jsonBody -ContentType "application/json"
Write-Host "Repository créé: $($newRepo.html_url)" -ForegroundColor Green
```

## Microsoft Azure

PowerShell est particulièrement puissant pour gérer les ressources Azure. Commençons par installer le module Az si nécessaire :

### Installation du module Az

```powershell
# Vérifier si le module Az est installé
if (-not (Get-Module -ListAvailable -Name Az)) {
    Write-Host "Installation du module Az..." -ForegroundColor Yellow
    Install-Module -Name Az -Repository PSGallery -Force -AllowClobber
}
```

### Connexion à Azure

```powershell
# Se connecter à Azure (ouvre une fenêtre de navigateur pour l'authentification)
Connect-AzAccount

# Ou avec des identifiants en script (pour l'automatisation)
$credential = Get-Credential  # Demande les informations d'identification
Connect-AzAccount -Credential $credential
```

### Lister les ressources Azure

```powershell
# Afficher vos abonnements Azure
Get-AzSubscription | Format-Table Name, Id, State

# Sélectionner un abonnement spécifique
Set-AzContext -SubscriptionId "votre-id-abonnement"

# Lister les groupes de ressources
Get-AzResourceGroup | Format-Table ResourceGroupName, Location

# Lister les machines virtuelles
Get-AzVM | Format-Table Name, ResourceGroupName, Location
```

### Créer une ressource Azure simple

```powershell
# Créer un groupe de ressources
New-AzResourceGroup -Name "MonGroupe" -Location "westeurope"

# Créer un compte de stockage
New-AzStorageAccount -ResourceGroupName "MonGroupe" `
                    -Name "monstockageunique" `
                    -Location "westeurope" `
                    -SkuName "Standard_LRS" `
                    -Kind "StorageV2"
```

## Microsoft Teams

Pour interagir avec Microsoft Teams, vous pouvez utiliser l'API Microsoft Graph ou le module PowerShell MicrosoftTeams :

### Installation du module MicrosoftTeams

```powershell
# Installer le module MicrosoftTeams si nécessaire
if (-not (Get-Module -ListAvailable -Name MicrosoftTeams)) {
    Install-Module -Name MicrosoftTeams -Repository PSGallery -Force
}
```

### Connexion à Teams

```powershell
# Se connecter à Microsoft Teams
Connect-MicrosoftTeams  # Ouvre une fenêtre de navigateur pour l'authentification
```

### Récupérer des informations sur les équipes

```powershell
# Lister toutes les équipes auxquelles vous avez accès
Get-Team | Format-Table DisplayName, GroupId

# Obtenir des détails sur une équipe spécifique
$teamId = "votre-team-id"
Get-Team -GroupId $teamId | Format-List
```

### Envoyer un message Teams via webhook

Une méthode simple pour envoyer des messages dans Teams est d'utiliser un webhook entrant :

```powershell
# Configurer d'abord un webhook entrant dans votre canal Teams et récupérer l'URL

$webhookUrl = "https://outlook.office.com/webhook/votre-webhook-url"
$body = @{
    title = "Message de PowerShell"
    text = "Ce message a été envoyé depuis un script PowerShell!"
} | ConvertTo-Json

Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $body -ContentType "application/json"
```

## Exemple pratique : Surveillance d'un projet GitHub avec notification Teams

Voici un exemple qui combine plusieurs services : vérifier les nouvelles issues GitHub et envoyer une notification dans Teams.

```powershell
# Configuration
$githubToken = "votre-token-github"
$githubHeaders = @{
    Authorization = "token $githubToken"
    Accept = "application/vnd.github.v3+json"
}
$repoOwner = "propriétaire"
$repoName = "nom-du-repo"
$teamsWebhookUrl = "votre-webhook-teams"

# Récupérer les issues créées aujourd'hui
$today = Get-Date -Format "yyyy-MM-dd"
$issues = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoOwner/$repoName/issues?since=$today" -Headers $githubHeaders

# S'il y a des nouvelles issues, envoyer une notification Teams
if ($issues.Count -gt 0) {
    $messageContent = "### Nouvelles issues GitHub aujourd'hui\n\n"
    foreach ($issue in $issues) {
        $messageContent += "- [$($issue.title)]($($issue.html_url)) ouvert par $($issue.user.login)\n"
    }

    $teamsMessage = @{
        "@type" = "MessageCard"
        "@context" = "http://schema.org/extensions"
        "summary" = "Nouvelles issues GitHub"
        "themeColor" = "0078D7"
        "title" = "$($issues.Count) nouvelles issues sur $repoOwner/$repoName"
        "text" = $messageContent
    } | ConvertTo-Json

    Invoke-RestMethod -Uri $teamsWebhookUrl -Method Post -Body $teamsMessage -ContentType "application/json"
}
```

## Conseils pour les API tierces

Lorsque vous travaillez avec des API de services tiers :

1. **Gestion des identifiants** : Évitez de coder en dur les tokens ou mots de passe dans vos scripts. Utilisez plutôt :
   - Des variables d'environnement
   - Le module `Microsoft.PowerShell.SecretManagement`
   - Azure Key Vault pour les environnements d'entreprise

2. **Limites de débit** : La plupart des API ont des limites de débit. Ajoutez des délais entre les requêtes pour éviter d'être bloqué :

```powershell
# Exemple avec délai entre les requêtes
foreach ($item in $itemsToProcess) {
    Invoke-RestMethod -Uri "https://api.example.com/endpoint/$item" -Headers $headers
    Start-Sleep -Seconds 1  # Attendre 1 seconde entre chaque requête
}
```

3. **Gestion des erreurs** : Utilisez try/catch pour gérer les échecs d'API :

```powershell
try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorMessage = $_.ErrorDetails.Message
    Write-Error "Erreur API ($statusCode): $errorMessage"
}
```

## Exercices pratiques

1. Créez un script qui liste tous vos repositories GitHub et affiche ceux qui n'ont pas été mis à jour depuis plus de 6 mois.
2. Écrivez un script qui affiche l'utilisation CPU des machines virtuelles Azure de votre abonnement.
3. Créez un rapport quotidien des activités d'une équipe Teams et envoyez-le par email.

---

Dans cette section, vous avez appris comment PowerShell peut interagir avec des services populaires comme GitHub, Azure et Teams. Ces compétences sont essentielles pour l'automatisation moderne et vous permettront d'intégrer différents systèmes dans vos workflows.

⏭️ [Introduction à PowerShell + Azure / AWS / Google Cloud](/11-api-cloud/05-cloud-intro.md)
