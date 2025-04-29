# Module 2-2: Customisation du prompt (oh-my-posh, PSReadLine)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Transformez l'apparence de votre PowerShell

Lorsque vous utilisez PowerShell, le **prompt** est cette partie de l'interface qui s'affiche avant que vous ne tapiez une commande — généralement `PS C:\Users\VotreNom>`. C'est un peu comme l'accueil de votre maison PowerShell!

Dans ce module, nous allons apprendre à transformer ce prompt basique en un outil visuel puissant et informatif qui rendra votre expérience PowerShell à la fois plus agréable et plus productive.

## Pourquoi personnaliser votre prompt?

Un prompt personnalisé peut vous aider à:
- **Voir en un coup d'œil** des informations importantes (dossier actuel, statut git, heure, etc.)
- **Éviter les erreurs** en rendant plus visibles certaines informations
- **Naviguer plus facilement** dans vos dossiers et projets
- **Rendre l'utilisation de PowerShell plus agréable** (et même plus fun!)

## Méthodes de personnalisation du prompt

Il existe plusieurs façons de personnaliser votre prompt PowerShell:

1. **Méthode simple**: Modifier la fonction `prompt` dans votre profil PowerShell
2. **Méthode avancée**: Utiliser des modules comme Oh My Posh
3. **Méthode complémentaire**: Configurer PSReadLine pour l'édition de ligne

Nous allons explorer ces trois approches, de la plus simple à la plus sophistiquée.

## 1. Personnalisation basique du prompt

La façon la plus simple de personnaliser votre prompt est de redéfinir la fonction `prompt` dans votre fichier de profil PowerShell.

### Étape 1: Ouvrir votre fichier de profil

```powershell
# Créer le profil s'il n'existe pas
if (-not (Test-Path -Path $PROFILE)) {
    New-Item -Path $PROFILE -ItemType File -Force
}

# Ouvrir le profil dans VS Code (ou votre éditeur préféré)
code $PROFILE
```

### Étape 2: Ajouter une fonction prompt personnalisée

Voici quelques exemples de fonctions prompt que vous pouvez ajouter à votre profil:

#### Exemple 1: Prompt simple avec heure et chemin

```powershell
function prompt {
    # Obtenir l'heure courante et le chemin
    $time = Get-Date -Format "HH:mm:ss"
    $currentPath = $(Get-Location).Path

    # Construire et retourner le prompt
    Write-Host "[$time] " -NoNewline -ForegroundColor Cyan
    Write-Host "$currentPath" -NoNewline -ForegroundColor Yellow
    return "> "
}
```

Ce prompt affichera: `[14:30:45] C:\Users\VotreNom>`

#### Exemple 2: Prompt avec niveau d'élévation (administrateur)

```powershell
function prompt {
    # Vérifier si PowerShell est exécuté en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Afficher un préfixe différent selon les droits d'administrateur
    if ($isAdmin) {
        Write-Host "[ADMIN] " -NoNewline -ForegroundColor Red
    } else {
        Write-Host "[USER] " -NoNewline -ForegroundColor Green
    }

    # Afficher le chemin actuel
    Write-Host "$(Get-Location) " -NoNewline -ForegroundColor Yellow

    # Symbole final du prompt
    return "$ "
}
```

Ce prompt affichera: `[USER] C:\Users\VotreNom $` ou `[ADMIN] C:\Users\VotreNom $` si vous êtes en mode administrateur.

#### Exemple 3: Prompt multilignes

```powershell
function prompt {
    $currentPath = $(Get-Location).Path
    $host.UI.RawUI.WindowTitle = "PowerShell - $currentPath" # Change le titre de la fenêtre

    # Première ligne: nom d'utilisateur et ordinateur
    Write-Host ""  # Ligne vide pour l'espacement
    Write-Host "$env:USERNAME@$env:COMPUTERNAME" -NoNewline -ForegroundColor Green
    Write-Host " in " -NoNewline -ForegroundColor White

    # Chemin actuel
    Write-Host "$currentPath" -ForegroundColor Yellow

    # Seconde ligne: prompt lui-même
    Write-Host "PS>" -NoNewline -ForegroundColor Blue
    return " "
}
```

Ce prompt affichera:
```
marie@DESKTOP-PC in
C:\Users\marie\Documents
PS>
```

### Étape 3: Enregistrer et recharger votre profil

Après avoir ajouté votre fonction prompt personnalisée, enregistrez votre fichier de profil, puis rechargez-le:

```powershell
. $PROFILE
```

## 2. Utilisation de Oh My Posh (méthode avancée)

[Oh My Posh](https://ohmyposh.dev/) est un moteur de thèmes de prompt très puissant qui fonctionne sur PowerShell, Bash, et d'autres shells. Il offre des prompts riches en informations et visuellement attrayants.

### Prérequis: Installer une police Nerd Font

Oh My Posh utilise des icônes spéciales qui nécessitent une police compatible Nerd Font.

1. Visitez [Nerd Fonts](https://www.nerdfonts.com/font-downloads) et téléchargez une police (comme Hack, FiraCode, ou Cascadia Code)
2. Installez la police sur votre système
3. Configurez votre terminal pour utiliser cette police:
   - Dans Windows Terminal: Paramètres > Profil PowerShell > Apparence > Police
   - Dans VS Code: Paramètres > Terminal > Integrated > Font Family

### Étape 1: Installer Oh My Posh

```powershell
# Installer Oh My Posh avec winget (Windows)
winget install JanDeDobbeleer.OhMyPosh -s winget

# Ou avec PowerShell (toutes plateformes)
Install-Module oh-my-posh -Scope CurrentUser
```

### Étape 2: Ajouter Oh My Posh à votre profil

Ouvrez votre fichier de profil PowerShell et ajoutez cette ligne:

```powershell
# Initialiser Oh My Posh avec un thème
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
```

> **Note**: Le chemin peut varier selon la méthode d'installation. Si vous avez installé via le module PowerShell, utilisez plutôt:
> ```powershell
> Import-Module oh-my-posh
> Set-PoshPrompt -Theme paradox
> ```

### Étape 3: Explorer et choisir un thème

Oh My Posh propose de nombreux thèmes préinstallés. Pour voir la liste des thèmes disponibles:

```powershell
Get-PoshThemes
```

Pour essayer un thème différent, remplacez "paradox" dans votre profil par le nom du thème que vous souhaitez utiliser.

### Étape 4: Personnaliser un thème

Vous pouvez créer votre propre thème ou modifier un thème existant:

1. Exportez un thème existant comme base:
   ```powershell
   Export-PoshTheme -FilePath ~\Documents\MyTheme.omp.json
   ```

2. Modifiez ce fichier JSON avec votre éditeur
3. Utilisez votre thème personnalisé:
   ```powershell
   oh-my-posh init pwsh --config ~\Documents\MyTheme.omp.json | Invoke-Expression
   ```

## 3. Configuration de PSReadLine

PSReadLine est le module qui gère l'édition de ligne dans PowerShell. Il permet de configurer la coloration syntaxique, l'autocomplétion, et d'autres fonctionnalités d'édition.

### Étape 1: Installer ou mettre à jour PSReadLine

PSReadLine est généralement préinstallé avec PowerShell, mais vous pouvez le mettre à jour:

```powershell
Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force
```

### Étape 2: Configurer PSReadLine dans votre profil

Ajoutez ces lignes à votre fichier de profil pour une expérience améliorée:

```powershell
# Importer PSReadLine
Import-Module PSReadLine

# Activer la complétion prédictive (PowerShell 7.1+ seulement)
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Configurer la coloration syntaxique
Set-PSReadLineOption -Colors @{
    Command            = 'Cyan'
    Parameter          = 'Green'
    String             = 'Yellow'
    Operator           = 'Magenta'
    Variable           = 'White'
    Number             = 'DarkGreen'
    Member             = 'DarkGreen'
    Type               = 'DarkRed'
    Comment            = 'DarkGray'
}

# Raccourcis clavier
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function Complete
```

Ces paramètres vont:
- Activer des prédictions basées sur votre historique
- Personnaliser les couleurs pour différents éléments syntaxiques
- Configurer les flèches haut/bas pour chercher dans l'historique des commandes similaires à ce que vous avez déjà tapé

## Exemple complet pour débutants

Voici un exemple complet que vous pouvez ajouter à votre fichier de profil pour obtenir un prompt personnalisé et une meilleure expérience d'édition:

```powershell
#----------------------------------------------------------
# Configuration du prompt et de l'interface PowerShell
#----------------------------------------------------------

# 1. Installer les modules nécessaires s'ils sont absents
if (-not (Get-Module -ListAvailable -Name PSReadLine)) {
    Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force
}

if (-not (Get-Module -ListAvailable -Name oh-my-posh)) {
    Install-Module -Name oh-my-posh -Scope CurrentUser -Force
}

# 2. Importer et configurer PSReadLine
Import-Module PSReadLine

# Activer la complétion prédictive (PowerShell 7.1+ seulement)
if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSVersionTable.PSVersion.Minor -ge 1) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
}

# Configurer les raccourcis clavier
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function Complete

# 3. Importer et configurer Oh My Posh
Import-Module oh-my-posh
Set-PoshPrompt -Theme paradox

# 4. Fonction de prompt de secours (au cas où Oh My Posh échoue)
function prompt {
    # Obtenez l'état de la dernière commande
    $lastCommand = $?
    $lastExitCode = $LASTEXITCODE

    # Définissez la couleur en fonction du succès/échec
    if ($lastCommand -and $lastExitCode -eq 0) {
        $promptColor = "Green"
    } else {
        $promptColor = "Red"
    }

    # Afficher le prompt
    Write-Host "PS " -NoNewline -ForegroundColor Blue
    Write-Host "$(Get-Location) " -NoNewline -ForegroundColor Yellow
    return "$(if ($promptColor -eq 'Red') {'✘'} else {'✓'}) "
}

# 5. Message d'information
Write-Host "Prompt et interface PowerShell personnalisés chargés!" -ForegroundColor Cyan
```

## Résolution des problèmes courants

### Les icônes ne s'affichent pas correctement

- **Solution**: Assurez-vous d'avoir installé et configuré une police Nerd Font compatible
- **Vérification**: Vérifiez les paramètres de police de votre terminal

### Oh My Posh ne fonctionne pas

- **Solution**: Vérifiez que le chemin vers le thème est correct
- **Alternative**: Utilisez la fonction prompt de secours fournie dans l'exemple complet

### PSReadLine génère des erreurs

- **Solution**: Vérifiez la version de PowerShell (`$PSVersionTable.PSVersion`)
- **Alternative**: Commentez les lignes liées aux prédictions si vous utilisez PowerShell 7.0 ou inférieur

## Exercices pratiques

### Exercice 1: Créer un prompt personnalisé simple
1. Ajoutez une fonction prompt qui affiche l'heure et le chemin actuel
2. Rechargez votre profil et observez les changements

### Exercice 2: Installer et configurer Oh My Posh
1. Installez Oh My Posh et une police Nerd Font
2. Configurez Oh My Posh dans votre profil avec le thème "agnoster"
3. Redémarrez PowerShell et observez le nouveau prompt

### Exercice 3: Personnaliser PSReadLine
1. Configurez PSReadLine pour utiliser des couleurs qui vous plaisent
2. Ajoutez la recherche dans l'historique avec les flèches
3. Testez la nouvelle configuration en écrivant des commandes

## Conclusion

Personnaliser votre prompt PowerShell est une excellente façon de rendre votre environnement de travail plus agréable et productif. En combinant une fonction prompt personnalisée, Oh My Posh et PSReadLine, vous pouvez créer une expérience PowerShell vraiment adaptée à vos besoins.

N'hésitez pas à expérimenter avec différentes configurations jusqu'à trouver celle qui vous convient le mieux!

Dans le prochain module, nous explorerons comment gérer et utiliser efficacement l'historique des commandes et les raccourcis clavier dans PowerShell.

⏭️ [Historique de commandes et raccourcis clavier](/01-environnement/03-historique-et-raccourcis.md)
