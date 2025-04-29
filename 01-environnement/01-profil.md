# Module 2-1: Fichier de profil ($PROFILE)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Personnalisez votre environnement PowerShell

Imaginez que chaque fois que vous ouvrez PowerShell, vous souhaiteriez avoir:
- Vos alias personnalisés
- Vos fonctions préférées déjà chargées
- Un message d'accueil personnalisé
- Certaines variables prédéfinies

C'est exactement ce que permet le **fichier de profil PowerShell**! Il s'agit d'un script qui s'exécute automatiquement chaque fois que vous démarrez PowerShell, comme votre "configuration personnelle".

## Qu'est-ce que le fichier de profil?

Le fichier de profil est simplement un script PowerShell (fichier `.ps1`) qui s'exécute automatiquement au démarrage de votre session PowerShell. Il fonctionne comme votre "environnement de démarrage personnalisé".

## Où se trouve le fichier de profil?

PowerShell utilise la variable spéciale `$PROFILE` pour stocker l'emplacement de votre fichier de profil. Pour voir où se trouve votre profil, exécutez:

```powershell
$PROFILE
```

Vous verrez un chemin qui ressemble à quelque chose comme:
- Sur Windows: `C:\Users\VotreNom\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
- Sur Linux/macOS: `/home/VotreNom/.config/powershell/Microsoft.PowerShell_profile.ps1`

## Les différents types de profils

En réalité, PowerShell prend en charge plusieurs profils qui s'exécutent dans des contextes différents:

| Type de profil | Description | Emplacement |
|----------------|-------------|-------------|
| **Profil actuel** | S'applique uniquement à l'utilisateur actuel et à l'hôte actuel | `$PROFILE` ou `$PROFILE.CurrentUserCurrentHost` |
| **Profil utilisateur** | S'applique à l'utilisateur actuel, tous hôtes confondus | `$PROFILE.CurrentUserAllHosts` |
| **Profil système** | S'applique à tous les utilisateurs, uniquement pour l'hôte actuel | `$PROFILE.AllUsersCurrentHost` |
| **Profil général** | S'applique à tous les utilisateurs et tous les hôtes | `$PROFILE.AllUsersAllHosts` |

> **Note pour débutants**: Si vous débutez avec PowerShell, concentrez-vous uniquement sur le profil actuel (`$PROFILE`). Les autres sont pour des cas d'utilisation plus avancés.

## Création de votre premier fichier de profil

Par défaut, le fichier de profil n'existe pas! Nous devons le créer. Voici comment:

### Étape 1: Vérifier si le profil existe déjà

```powershell
Test-Path $PROFILE
```

Si la commande renvoie `False`, le fichier n'existe pas encore.

### Étape 2: Créer le dossier parent si nécessaire

```powershell
# Récupère le dossier parent du fichier de profil
$profileParentPath = Split-Path -Path $PROFILE -Parent

# Crée le dossier s'il n'existe pas
if (-not (Test-Path -Path $profileParentPath)) {
    New-Item -Path $profileParentPath -ItemType Directory
}
```

### Étape 3: Créer le fichier de profil vide

```powershell
if (-not (Test-Path -Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File
}
```

### Étape 4: Ouvrir le fichier dans un éditeur

```powershell
# Avec Notepad (sur Windows)
notepad $PROFILE

# Ou avec VS Code (sur toutes les plateformes)
code $PROFILE
```

## Que mettre dans votre fichier de profil?

Voici quelques exemples utiles à ajouter dans votre fichier de profil:

### 1. Message d'accueil personnalisé

```powershell
# Message d'accueil
Write-Host "Bonjour $env:USERNAME! PowerShell est prêt." -ForegroundColor Green
Write-Host "Aujourd'hui: $(Get-Date -Format 'dddd, dd MMMM yyyy')" -ForegroundColor Cyan
```

### 2. Alias personnalisés

```powershell
# Alias pratiques
New-Alias -Name ll -Value Get-ChildItem
New-Alias -Name c -Value Clear-Host
New-Alias -Name open -Value explorer.exe  # Sur Windows uniquement
```

### 3. Fonctions utiles

```powershell
# Fonction pour accéder rapidement à votre dossier de projets
function goto-projects { Set-Location -Path "C:\Projets" }

# Fonction pour rechercher dans l'historique des commandes
function find-history {
    param([string]$filter)
    Get-History | Where-Object { $_.CommandLine -like "*$filter*" }
}

# Fonction pour créer et accéder à un nouveau dossier en une seule commande
function mcd {
    param([string]$newFolder)
    New-Item -Path $newFolder -ItemType Directory
    Set-Location -Path $newFolder
}
```

### 4. Configuration de l'environnement PowerShell

```powershell
# Configuration de l'environnement
$env:EDITOR = "code"  # Définit VS Code comme éditeur par défaut

# Personnalisation de la sortie d'erreur
$PSDefaultParameterValues['Out-Default:OutVariable'] = 'LastResult'

# Configuration de l'historique de commandes
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
```

## Exemple de fichier de profil complet pour débutants

Voici un exemple simple mais utile pour commencer:

```powershell
#----------------------------------------------------------
# Mon profil PowerShell - Configuration personnalisée
#----------------------------------------------------------

# Message d'accueil
$currentTime = Get-Date
if ($currentTime.Hour -lt 12) {
    $greeting = "Bonjour"
} elseif ($currentTime.Hour -lt 18) {
    $greeting = "Bon après-midi"
} else {
    $greeting = "Bonsoir"
}

Write-Host "$greeting $env:USERNAME!" -ForegroundColor Green
Write-Host "PowerShell v$($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host "Aujourd'hui: $(Get-Date -Format 'dddd, dd MMMM yyyy')" -ForegroundColor Cyan
Write-Host "--------------------------------------"

# Alias pratiques
New-Alias -Name l -Value Get-ChildItem
New-Alias -Name c -Value Clear-Host
New-Alias -Name e -Value Exit-PSSession

# Fonctions utiles
function prompt {
    # Personnalisation de l'invite de commande
    $currentDir = $(Get-Location).Path
    "PS $currentDir> "
}

function time {
    # Affiche l'heure actuelle
    Get-Date -Format "HH:mm:ss"
}

function update-profile {
    # Permet de recharger le profil sans redémarrer PowerShell
    . $PROFILE
    Write-Host "Profil rechargé!" -ForegroundColor Green
}

# Raccourcis pour la navigation
function .. { Set-Location .. }
function ... { Set-Location ..\.. }

Write-Host "Profil chargé. Utilisez 'update-profile' pour recharger le profil." -ForegroundColor Yellow
```

## Comment recharger le profil sans redémarrer PowerShell?

Si vous modifiez votre profil, vous n'avez pas besoin de redémarrer PowerShell pour appliquer les changements. Vous pouvez simplement le recharger avec:

```powershell
. $PROFILE
```

Le point suivi d'un espace au début est important! Il indique à PowerShell d'exécuter le script dans le contexte actuel.

## Dépannage des problèmes courants

### "L'exécution de scripts est désactivée sur ce système"

Si vous obtenez cette erreur, vous devez modifier la politique d'exécution de PowerShell:

```powershell
# Pour la session actuelle uniquement
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Pour l'utilisateur actuel (plus permanent)
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

### "Le profil ne se charge pas automatiquement"

Vérifiez que:
1. Le chemin du fichier est correct (utilisez `$PROFILE` pour vérifier)
2. Le fichier est enregistré avec l'extension `.ps1`
3. Vous n'avez pas d'erreurs dans votre script de profil

## Exercices pratiques

### Exercice 1: Créer un profil de base
1. Créez votre fichier de profil s'il n'existe pas
2. Ajoutez un message d'accueil personnalisé
3. Ajoutez un alias pour votre commande préférée
4. Redémarrez PowerShell et vérifiez que tout fonctionne

### Exercice 2: Ajouter une fonction utile
1. Ouvrez votre fichier de profil
2. Ajoutez une fonction qui affiche les 10 fichiers les plus volumineux dans un dossier
3. Rechargez votre profil avec `. $PROFILE`
4. Testez votre nouvelle fonction

### Exercice 3: Personnaliser l'invite de commande
1. Ajoutez une fonction `prompt` à votre profil
2. Personnalisez-la pour afficher l'heure actuelle et le dossier courant
3. Rechargez le profil et admirez votre nouvelle invite!

## Conclusion

Le fichier de profil est comme votre "chez vous" dans PowerShell. Prenez le temps de le personnaliser selon vos besoins et votre style de travail. Au fur et à mesure que vous apprendrez plus de PowerShell, vous enrichirez naturellement votre profil avec des outils qui vous font gagner du temps.

Un profil bien configuré peut transformer votre expérience quotidienne avec PowerShell, en rendant les tâches courantes plus rapides et plus agréables!

Dans la prochaine section, nous verrons comment personnaliser encore plus l'apparence de PowerShell avec des outils comme oh-my-posh et PSReadLine.

⏭️ [Customisation du prompt (oh-my-posh, PSReadLine)](/01-environnement/02-customisation-prompt.md)
