# Module 13-2: PowerShell + Git

## Introduction

Git est un système de contrôle de version essentiel pour tout développeur, y compris ceux qui travaillent avec PowerShell. Cette section vous apprendra comment utiliser PowerShell pour interagir avec Git, vous permettant d'automatiser et de simplifier vos workflows de gestion de code.

## Prérequis

- PowerShell installé (version 5.1 ou PowerShell 7+)
- Git installé sur votre système
  - Téléchargeable sur [git-scm.com](https://git-scm.com/)
  - Vérifiez l'installation avec `git --version` dans PowerShell

## Git natif vs PowerShell avec Git

Vous pouvez utiliser Git de deux façons principales dans PowerShell :

1. **Commandes Git natives** : en exécutant directement les commandes Git dans PowerShell
2. **Modules PowerShell pour Git** : en utilisant des modules spécialisés qui offrent une intégration plus profonde

## Utilisation des commandes Git natives dans PowerShell

Les commandes Git fonctionnent directement dans PowerShell sans configuration supplémentaire :

```powershell
# Vérifier la version de Git
git --version

# Créer un nouveau dépôt
git init

# Vérifier l'état du dépôt
git status

# Ajouter des fichiers au suivi
git add .

# Créer un commit
git commit -m "Message de commit"

# Voir l'historique des commits
git log
```

## Utilisation du module posh-git

`posh-git` est un module PowerShell qui améliore l'expérience Git :

### Installation de posh-git

```powershell
# Installation via PowerShellGet
Install-Module posh-git -Scope CurrentUser -Force

# Importer le module pour la session actuelle
Import-Module posh-git

# Pour charger automatiquement posh-git à chaque démarrage de PowerShell, ajoutez cette ligne à votre profil
"Import-Module posh-git" | Add-Content $PROFILE
```

### Avantages de posh-git

- Affichage du statut Git dans votre prompt PowerShell
- Auto-complétion avancée pour les commandes Git
- Tabulation améliorée pour les noms de branches et autres références Git

## Intégration avec votre profil PowerShell

Pour une meilleure expérience, configurez votre profil PowerShell :

```powershell
# Ouvrir votre profil pour modification
notepad $PROFILE

# Ajoutez ces lignes au fichier
Import-Module posh-git

# Personnalisation optionnelle du prompt Git
$GitPromptSettings.DefaultPromptSuffix = ' > '
$GitPromptSettings.DefaultPromptPath = ''
```

## Fonctions PowerShell utiles pour Git

Voici quelques fonctions PowerShell que vous pouvez ajouter à votre profil pour simplifier vos tâches Git quotidiennes :

```powershell
# Fonction pour créer une nouvelle branche et basculer dessus
function New-GitBranch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BranchName
    )
    git checkout -b $BranchName
}

# Fonction pour pousser une branche vers le dépôt distant
function Push-GitBranch {
    param(
        [string]$BranchName = (git symbolic-ref --short HEAD)
    )
    git push -u origin $BranchName
}

# Fonction pour afficher un résumé Git concis
function Get-GitSummary {
    $branch = git symbolic-ref --short HEAD
    $commits = git rev-list --count HEAD
    $status = git status -s

    Write-Host "Branche actuelle: $branch" -ForegroundColor Cyan
    Write-Host "Total commits: $commits" -ForegroundColor Yellow

    if ($status) {
        Write-Host "Changements non commités:" -ForegroundColor Red
        $status
    } else {
        Write-Host "Répertoire de travail propre" -ForegroundColor Green
    }
}

# Alias courts
New-Alias -Name gb -Value New-GitBranch
New-Alias -Name gps -Value Push-GitBranch
New-Alias -Name gs -Value Get-GitSummary
```

## Automatisation des workflows Git avec PowerShell

Voici un exemple de script PowerShell qui automatise un workflow Git courant :

```powershell
function Sync-GitRepo {
    param(
        [switch]$Pull,
        [switch]$Push
    )

    # Stocker l'état actuel de modification
    $hasChanges = (git status -s).Length -gt 0
    $currentBranch = git symbolic-ref --short HEAD

    if ($hasChanges) {
        Write-Host "Des changements non commités ont été détectés:" -ForegroundColor Yellow
        git status -s

        $commit = Read-Host "Voulez-vous commiter ces changements? (o/n)"
        if ($commit -eq "o") {
            $message = Read-Host "Message de commit"
            git add .
            git commit -m $message
            Write-Host "Changements commités avec succès!" -ForegroundColor Green
        } else {
            Write-Host "Les changements n'ont pas été commités." -ForegroundColor Yellow
            return
        }
    }

    if ($Pull) {
        Write-Host "Récupération des dernières modifications depuis le dépôt distant..." -ForegroundColor Cyan
        git pull origin $currentBranch
    }

    if ($Push) {
        Write-Host "Envoi des commits locaux vers le dépôt distant..." -ForegroundColor Cyan
        git push origin $currentBranch
    }

    Write-Host "Synchronisation terminée!" -ForegroundColor Green
}
```

### Utilisation du script de synchronisation
```powershell
# Récupérer et fusionner les changements distants
Sync-GitRepo -Pull

# Envoyer les commits locaux
Sync-GitRepo -Push

# Effectuer les deux opérations
Sync-GitRepo -Pull -Push
```

## Gérer plusieurs dépôts à la fois

PowerShell est idéal pour gérer plusieurs dépôts Git en parallèle :

```powershell
function Update-AllRepos {
    param(
        [string]$BaseDirectory = "$Home\Projects"
    )

    $originalLocation = Get-Location

    Get-ChildItem -Path $BaseDirectory -Directory | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName '.git')) {
            Write-Host "Mise à jour du dépôt: $($_.Name)" -ForegroundColor Cyan

            Set-Location $_.FullName
            git pull

            if ($LASTEXITCODE -eq 0) {
                Write-Host "Mise à jour réussie pour $($_.Name)" -ForegroundColor Green
            } else {
                Write-Host "Échec de la mise à jour pour $($_.Name)" -ForegroundColor Red
            }
        }
    }

    Set-Location $originalLocation
}
```

## Créer un rapport Git avec PowerShell

Voici comment générer un rapport sur votre activité Git :

```powershell
function Get-GitReport {
    param(
        [int]$Days = 7
    )

    $sinceDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd")

    $commits = git log --since=$sinceDate --format="%h|%an|%ad|%s" --date=short | ForEach-Object {
        $parts = $_ -split '\|'
        [PSCustomObject]@{
            Hash = $parts[0]
            Author = $parts[1]
            Date = $parts[2]
            Message = $parts[3]
        }
    }

    if ($commits) {
        Write-Host "Rapport Git des $Days derniers jours:" -ForegroundColor Cyan
        $commits | Format-Table -AutoSize

        $commitCount = $commits.Count
        $authorsCount = ($commits | Select-Object -ExpandProperty Author -Unique).Count

        Write-Host "Total des commits: $commitCount" -ForegroundColor Yellow
        Write-Host "Nombre d'auteurs: $authorsCount" -ForegroundColor Yellow
    } else {
        Write-Host "Aucun commit trouvé dans les $Days derniers jours." -ForegroundColor Yellow
    }
}
```

## Bonnes pratiques pour PowerShell et Git

1. **Utilisez la journalisation** pour tracer les opérations Git automatisées
2. **Gérez correctement les erreurs** avec try/catch
3. **Validez les entrées utilisateur** avant de les utiliser dans des commandes Git
4. **Créez des alias** pour les commandes fréquemment utilisées
5. **Utilisez le système de modules PowerShell** pour organiser vos fonctions Git

## Exercices pratiques

### Exercice 1: Configuration de base
1. Installez posh-git
2. Personnalisez votre prompt Git
3. Ajoutez la fonction Get-GitSummary à votre profil

### Exercice 2: Automatisation simple
1. Créez une fonction qui clone un dépôt et initialise automatiquement votre configuration préférée
2. Ajoutez une fonction qui nettoie les branches fusionnées localement

### Exercice 3: Intégration avancée
1. Créez un tableau de bord PowerShell qui affiche l'état de tous vos dépôts
2. Écrivez un script qui crée un rapport hebdomadaire de votre activité Git

## Conclusion

En combinant PowerShell et Git, vous pouvez créer des workflows de développement plus efficaces et automatisés. Les possibilités sont infinies grâce à la puissance de PowerShell pour manipuler des données et automatiser des tâches répétitives.

Continuez à explorer et à créer vos propres fonctions pour répondre à vos besoins spécifiques!

## Ressources supplémentaires

- [Documentation de posh-git sur GitHub](https://github.com/dahlbyk/posh-git)
- [Documentation officielle de Git](https://git-scm.com/doc)
- [PowerShell Gallery - Modules liés à Git](https://www.powershellgallery.com/packages?q=git)
