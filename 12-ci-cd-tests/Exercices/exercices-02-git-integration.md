# Solution Exercice 1: Configuration de base

## Objectifs de l'exercice
1. Installer posh-git
2. Personnaliser votre prompt Git
3. Ajouter la fonction Get-GitSummary à votre profil

## Solution complète

Voici un script complet que vous pouvez exécuter pour accomplir tous les objectifs de l'exercice 1 :

```powershell
# Solution Exercice 1: Configuration de base pour PowerShell + Git
# ---------------------------------------------------------------

# 1. Installation de posh-git
# ------------------------------
Write-Host "1. Installation de posh-git..." -ForegroundColor Cyan

# Vérifier si posh-git est déjà installé
$poshGitModule = Get-Module -ListAvailable -Name posh-git
if (-not $poshGitModule) {
    try {
        # Installer posh-git
        Install-Module posh-git -Scope CurrentUser -Force
        Write-Host "   Module posh-git installé avec succès!" -ForegroundColor Green
    }
    catch {
        Write-Host "   Erreur lors de l'installation de posh-git: $_" -ForegroundColor Red
        Write-Host "   Vérifiez que vous avez une connexion Internet et que PowerShellGet est à jour." -ForegroundColor Yellow
        exit 1
    }
} else {
    Write-Host "   Le module posh-git est déjà installé." -ForegroundColor Green
}

# Importer le module pour la session actuelle
Import-Module posh-git

# 2. Personnalisation du prompt Git
# ---------------------------------
Write-Host "2. Personnalisation du prompt Git..." -ForegroundColor Cyan

# Vérifier si le fichier de profil existe
if (-not (Test-Path -Path $PROFILE)) {
    # Créer le dossier parent si nécessaire
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path -Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    # Créer le fichier de profil
    New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    Write-Host "   Fichier de profil PowerShell créé: $PROFILE" -ForegroundColor Green
}

# Configuration de personnalisation
$promptConfig = @"

# Import du module posh-git
Import-Module posh-git

# Personnalisation du prompt Git
`$GitPromptSettings.DefaultPromptPrefix = '[`$(Get-Date -Format "HH:mm:ss")] '
`$GitPromptSettings.DefaultPromptSuffix = '`n`$(">" * (`$nestedPromptLevel + 1)) '
`$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = `$true
`$GitPromptSettings.DefaultPromptPath = '`$(`$PWD.Path | Split-Path -Leaf)'

# Couleurs personnalisées
`$GitPromptSettings.BeforeStatus.ForegroundColor = [ConsoleColor]::Blue
`$GitPromptSettings.BranchColor.ForegroundColor = [ConsoleColor]::Magenta
`$GitPromptSettings.AfterStatus.ForegroundColor = [ConsoleColor]::Blue

"@

# 3. Fonction Get-GitSummary
# --------------------------
Write-Host "3. Ajout de la fonction Get-GitSummary au profil..." -ForegroundColor Cyan

$gitSummaryFunction = @"

# Fonction pour afficher un résumé Git concis
function Get-GitSummary {
    # Vérifier si nous sommes dans un dépôt Git
    if (-not (Test-Path .git)) {
        Write-Host "Le dossier actuel n'est pas un dépôt Git." -ForegroundColor Red
        return
    }

    try {
        # Obtenir les informations Git actuelles
        `$branch = git symbolic-ref --short HEAD 2>$null
        if (`$LASTEXITCODE -ne 0) {
            `$branch = "(HEAD détaché)"
        }

        `$commits = git rev-list --count HEAD 2>$null
        `$status = git status -s 2>$null
        `$remote = git remote -v 2>$null | Select-String "(fetch)" | ForEach-Object { `$_.ToString().Split()[1] }

        # Afficher le résumé
        Write-Host "`n----- RÉSUMÉ GIT -----" -ForegroundColor Cyan
        Write-Host "Branche actuelle: " -NoNewline
        Write-Host "`$branch" -ForegroundColor Magenta

        if (`$remote) {
            Write-Host "Dépôt distant: " -NoNewline
            Write-Host "`$remote" -ForegroundColor Yellow
        }

        Write-Host "Total commits: " -NoNewline
        Write-Host "`$commits" -ForegroundColor Yellow

        `$ahead = git status -sb | Select-String "ahead" | ForEach-Object { `$_.ToString() -match "ahead (\d+)" | Out-Null; `$Matches[1] }
        `$behind = git status -sb | Select-String "behind" | ForEach-Object { `$_.ToString() -match "behind (\d+)" | Out-Null; `$Matches[1] }

        if (`$ahead) {
            Write-Host "Commits en avance sur origin: " -NoNewline
            Write-Host "`$ahead" -ForegroundColor Green
        }

        if (`$behind) {
            Write-Host "Commits en retard sur origin: " -NoNewline
            Write-Host "`$behind" -ForegroundColor Red
        }

        if (`$status) {
            Write-Host "`nChangements non commités:" -ForegroundColor Yellow
            git status -s | ForEach-Object {
                if (`$_ -match "^([MADRCU\?]{1,2})\s+(.+)$") {
                    `$statusCode = `$Matches[1].Trim()
                    `$file = `$Matches[2]

                    `$color = switch -Regex (`$statusCode) {
                        "^M" { "Yellow" }
                        "^A" { "Green" }
                        "^D" { "Red" }
                        "^\?" { "Gray" }
                        default { "White" }
                    }

                    Write-Host "  [`$statusCode]" -NoNewline -ForegroundColor DarkGray
                    Write-Host " `$file" -ForegroundColor `$color
                }
            }
        } else {
            Write-Host "`nRépertoire de travail propre" -ForegroundColor Green
        }

        Write-Host "-----------------------`n" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Erreur lors de l'exécution de Git: $_" -ForegroundColor Red
    }
}

# Alias pour la fonction Git Summary
New-Alias -Name gsum -Value Get-GitSummary -Force

"@

# Combiner toutes les configurations
$profileContent = $promptConfig + $gitSummaryFunction

# Vérifier si la configuration existe déjà dans le profil
$currentProfileContent = Get-Content -Path $PROFILE -Raw -ErrorAction SilentlyContinue

if ($currentProfileContent -and ($currentProfileContent.Contains("posh-git") -or $currentProfileContent.Contains("Get-GitSummary"))) {
    Write-Host "   Attention: Votre profil contient déjà des configurations relatives à Git." -ForegroundColor Yellow
    $confirmation = Read-Host "   Voulez-vous remplacer ces configurations? (o/n)"

    if ($confirmation -eq "o") {
        # Sauvegarder le profil existant
        $backupPath = "$PROFILE.backup-$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item -Path $PROFILE -Destination $backupPath
        Write-Host "   Sauvegarde du profil existant créée: $backupPath" -ForegroundColor Green

        # Écrire le nouveau contenu
        Set-Content -Path $PROFILE -Value $profileContent
        Write-Host "   Profil mis à jour avec succès!" -ForegroundColor Green
    } else {
        # Ajouter au profil existant
        Add-Content -Path $PROFILE -Value "`n# Configuration ajoutée par le script d'exercice PowerShell + Git`n$profileContent"
        Write-Host "   Nouvelles configurations ajoutées à la fin du profil existant." -ForegroundColor Green
    }
} else {
    # Écrire dans le profil s'il n'y a pas de configuration Git existante
    Set-Content -Path $PROFILE -Value $profileContent
    Write-Host "   Profil mis à jour avec succès!" -ForegroundColor Green
}

# Résumé et instructions finales
Write-Host "`nConfiguration terminée!" -ForegroundColor Green
Write-Host "Pour appliquer les modifications:" -ForegroundColor Cyan
Write-Host "1. Redémarrez votre session PowerShell, ou" -ForegroundColor Cyan
Write-Host "2. Exécutez la commande: . `$PROFILE" -ForegroundColor Cyan

Write-Host "`nPour tester la fonction Get-GitSummary:" -ForegroundColor Cyan
Write-Host "1. Naviguez vers un dépôt Git" -ForegroundColor Cyan
Write-Host "2. Exécutez la commande: Get-GitSummary (ou l'alias: gsum)" -ForegroundColor Cyan
```

## Comment exécuter cette solution

1. Copiez le script ci-dessus et enregistrez-le dans un fichier nommé `ConfigureGitProfile.ps1`
2. Ouvrez PowerShell en tant qu'administrateur
3. Naviguez vers le dossier où vous avez enregistré le script
4. Exécutez le script avec la commande : `.\ConfigureGitProfile.ps1`
5. Suivez les instructions affichées à l'écran

## Résultat attendu

Après avoir exécuté ce script et redémarré votre session PowerShell :

1. Le module posh-git sera installé et chargé automatiquement à chaque démarrage de PowerShell
2. Votre prompt PowerShell affichera des informations Git pour les répertoires qui sont des dépôts Git
3. Vous pourrez utiliser la commande `Get-GitSummary` (ou son alias `gsum`) pour afficher un résumé des informations Git pour le dépôt courant

## Notes importantes

- Ce script modifie votre profil PowerShell. Une sauvegarde est créée si le profil contient déjà des configurations Git.
- Assurez-vous que l'exécution de scripts est autorisée sur votre système. Si nécessaire, exécutez `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` avant d'exécuter ce script.
- Si vous rencontrez des erreurs lors de l'installation de posh-git, assurez-vous que vous avez une connexion Internet et que PowerShellGet est à jour. Vous pouvez mettre à jour PowerShellGet avec la commande `Install-Module PowerShellGet -Force`.


# Solution Exercice 2: Automatisation simple

## Objectifs de l'exercice
1. Créer une fonction qui clone un dépôt et initialise automatiquement votre configuration préférée
2. Ajouter une fonction qui nettoie les branches fusionnées localement

## Solution complète

Voici un script complet qui implémente les deux fonctions demandées dans l'exercice 2 :

```powershell
# Solution Exercice 2: Automatisation simple pour PowerShell + Git
# ---------------------------------------------------------------

# Fonction 1: Cloner un dépôt et initialiser votre configuration préférée
# ----------------------------------------------------------------------
function Initialize-GitRepo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, HelpMessage="URL du dépôt Git à cloner")]
        [string]$RepoUrl,

        [Parameter(Mandatory=$false, Position=1, HelpMessage="Dossier local où cloner le dépôt")]
        [string]$DestinationPath,

        [Parameter(Mandatory=$false, HelpMessage="Nom d'utilisateur Git pour ce dépôt")]
        [string]$UserName,

        [Parameter(Mandatory=$false, HelpMessage="Email Git pour ce dépôt")]
        [string]$Email,

        [Parameter(Mandatory=$false, HelpMessage="Branche par défaut à créer")]
        [string]$DefaultBranch = "main",

        [Parameter(Mandatory=$false, HelpMessage="Créer automatiquement une branche de développement")]
        [switch]$CreateDevBranch,

        [Parameter(Mandatory=$false, HelpMessage="Installer les hooks Git")]
        [switch]$InstallHooks,

        [Parameter(Mandatory=$false, HelpMessage="Installer les dépendances si un fichier de projet est détecté")]
        [switch]$InstallDependencies
    )

    try {
        # Déterminer le nom du dépôt à partir de l'URL
        $repoName = [System.IO.Path]::GetFileNameWithoutExtension($RepoUrl.Split('/')[-1])

        # Si aucun chemin de destination n'est spécifié, utiliser le nom du dépôt dans le répertoire courant
        if (-not $DestinationPath) {
            $DestinationPath = Join-Path (Get-Location) $repoName
        }

        # 1. Cloner le dépôt
        Write-Host "Clonage du dépôt $RepoUrl vers $DestinationPath..." -ForegroundColor Cyan
        git clone $RepoUrl $DestinationPath

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Échec du clonage du dépôt. Code de sortie: $LASTEXITCODE"
            return
        }

        # Accéder au répertoire cloné
        Push-Location $DestinationPath

        # 2. Configurer les infos utilisateur locales si spécifiées
        if ($UserName) {
            Write-Host "Configuration du nom d'utilisateur local: $UserName" -ForegroundColor Cyan
            git config user.name $UserName
        }

        if ($Email) {
            Write-Host "Configuration de l'email local: $Email" -ForegroundColor Cyan
            git config user.email $Email
        }

        # 3. Définir la branche par défaut si différente de la branche actuelle
        $currentBranch = git branch --show-current
        if ($currentBranch -ne $DefaultBranch) {
            Write-Host "Renommage de la branche par défaut en '$DefaultBranch'..." -ForegroundColor Cyan
            git branch -m $currentBranch $DefaultBranch
            # Mettre à jour la référence de la branche par défaut pour les futures pushes
            git config branch.$DefaultBranch.merge refs/heads/$DefaultBranch
            git config branch.$DefaultBranch.remote origin
        }

        # 4. Créer une branche de développement si demandé
        if ($CreateDevBranch) {
            $devBranchName = "develop"
            Write-Host "Création de la branche de développement '$devBranchName'..." -ForegroundColor Cyan
            git checkout -b $devBranchName

            # Ajouter un fichier README.md de base si inexistant
            if (-not (Test-Path "README.md")) {
                Write-Host "Création d'un fichier README.md de base..." -ForegroundColor Cyan
                @"
# $repoName

## Description
Projet cloné depuis $RepoUrl.

## Configuration du développement
Ce projet utilise la branche '$DefaultBranch' comme branche principale et '$devBranchName' pour le développement.

## Installation
Clonez ce dépôt et suivez les instructions ci-dessous pour configurer votre environnement.

## Utilisation
[Instructions d'utilisation à ajouter]

## Contributions
1. Créez une branche depuis '$devBranchName'
2. Effectuez vos modifications
3. Soumettez une pull request vers '$devBranchName'
"@ | Out-File -FilePath "README.md" -Encoding utf8

                git add README.md
                git commit -m "Ajout du fichier README.md initial"

                # Push initial de la branche de développement
                Write-Host "Push de la branche $devBranchName vers le dépôt distant..." -ForegroundColor Cyan
                git push -u origin $devBranchName
            }
        }

        # 5. Installer les hooks Git si demandé
        if ($InstallHooks) {
            Write-Host "Installation des hooks Git..." -ForegroundColor Cyan

            # Créer un hook pre-commit pour vérifier la syntaxe PowerShell
            $preCommitHookPath = Join-Path (Get-Location) ".git\hooks\pre-commit"

            @"
#!/bin/sh
# Hook pre-commit pour vérifier la syntaxe PowerShell

# Liste des fichiers PowerShell modifiés
files=\$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(ps1|psm1|psd1)$')

if [ -n "\$files" ]; then
    echo "Vérification de la syntaxe PowerShell..."

    for file in \$files; do
        # Utilisation de pwsh pour vérifier la syntaxe
        powershell -Command "& {
            \$errors = \$null
            \$null = [System.Management.Automation.Language.Parser]::ParseFile('\$file', [ref] \$null, [ref] \$errors)
            if (\$errors.Count -gt 0) {
                Write-Host 'Erreurs de syntaxe dans \$file:' -ForegroundColor Red
                \$errors | ForEach-Object { Write-Host \$_ -ForegroundColor Red }
                exit 1
            }
        }"

        if [ \$? -ne 0 ]; then
            echo "Des erreurs de syntaxe ont été trouvées. Le commit a été annulé."
            exit 1
        fi
    done
fi

exit 0
"@ | Out-File -FilePath $preCommitHookPath -Encoding ascii

            # S'assurer que le hook est exécutable
            if ($IsWindows) {
                # Sous Windows, le fichier doit simplement exister
                Write-Host "Hook pre-commit créé" -ForegroundColor Green
            } else {
                # Sous Linux/macOS, rendre le fichier exécutable
                chmod +x $preCommitHookPath
                Write-Host "Hook pre-commit créé et rendu exécutable" -ForegroundColor Green
            }
        }

        # 6. Installer les dépendances si demandé et si un fichier de projet est détecté
        if ($InstallDependencies) {
            Write-Host "Recherche des fichiers de projet..." -ForegroundColor Cyan

            # Installation pour PowerShell (si un module manifest est trouvé)
            $psdFiles = Get-ChildItem -Path (Get-Location) -Filter "*.psd1" -Recurse
            if ($psdFiles.Count -gt 0) {
                Write-Host "Module PowerShell détecté. Installation des dépendances..." -ForegroundColor Cyan

                # Utiliser PSDepend si disponible, sinon suggérer l'installation
                $psDepend = Get-Module -ListAvailable -Name PSDepend
                if ($psDepend) {
                    Write-Host "Utilisation de PSDepend pour installer les dépendances..." -ForegroundColor Cyan
                    Invoke-PSDepend -Path . -Install -Force
                } else {
                    Write-Host "Module PSDepend non trouvé. Pour une meilleure gestion des dépendances, installez-le avec:" -ForegroundColor Yellow
                    Write-Host "Install-Module PSDepend -Scope CurrentUser -Force" -ForegroundColor Yellow
                }
            }

            # Installation pour Node.js (si package.json est trouvé)
            if (Test-Path "package.json") {
                Write-Host "Projet Node.js détecté. Installation des dépendances..." -ForegroundColor Cyan

                if (Get-Command npm -ErrorAction SilentlyContinue) {
                    npm install
                } else {
                    Write-Host "npm non trouvé. Veuillez installer Node.js pour installer les dépendances." -ForegroundColor Yellow
                }
            }

            # Installation pour .NET (si .csproj ou .fsproj est trouvé)
            $dotnetFiles = Get-ChildItem -Path (Get-Location) -Filter "*.?sproj" -Recurse
            if ($dotnetFiles.Count -gt 0) {
                Write-Host "Projet .NET détecté. Restauration des packages..." -ForegroundColor Cyan

                if (Get-Command dotnet -ErrorAction SilentlyContinue) {
                    dotnet restore
                } else {
                    Write-Host "dotnet CLI non trouvé. Veuillez installer .NET SDK pour restaurer les packages." -ForegroundColor Yellow
                }
            }
        }

        # 7. Résumé et instructions finales
        Write-Host "`nInitialisation du dépôt Git terminée avec succès!" -ForegroundColor Green
        Write-Host "Résumé des opérations:" -ForegroundColor Cyan
        Write-Host "- Dépôt cloné dans: $DestinationPath" -ForegroundColor White

        if ($UserName -or $Email) {
            Write-Host "- Configuration utilisateur locale définie" -ForegroundColor White
        }

        if ($currentBranch -ne $DefaultBranch) {
            Write-Host "- Branche par défaut renommée en '$DefaultBranch'" -ForegroundColor White
        }

        if ($CreateDevBranch) {
            Write-Host "- Branche de développement 'develop' créée" -ForegroundColor White
        }

        if ($InstallHooks) {
            Write-Host "- Hooks Git installés" -ForegroundColor White
        }

        if ($InstallDependencies) {
            Write-Host "- Dépendances installées (si détectées)" -ForegroundColor White
        }

        # Revenir au répertoire d'origine
        Pop-Location

        Write-Host "`nPour commencer à travailler avec ce dépôt:" -ForegroundColor Cyan
        Write-Host "cd $DestinationPath" -ForegroundColor White

        if ($CreateDevBranch) {
            Write-Host "git checkout develop # Pour travailler sur la branche de développement" -ForegroundColor White
        }

        return $DestinationPath
    }
    catch {
        Write-Error "Une erreur s'est produite: $_"

        # Revenir au répertoire d'origine en cas d'erreur
        if ((Get-Location).Path -eq $DestinationPath) {
            Pop-Location
        }
    }
}

# Fonction 2: Nettoyer les branches fusionnées localement
# ------------------------------------------------------
function Remove-MergedBranches {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [Parameter(Mandatory=$false, HelpMessage="Branches à protéger (ne pas supprimer)")]
        [string[]]$ProtectedBranches = @("main", "master", "develop", "staging", "production"),

        [Parameter(Mandatory=$false, HelpMessage="Supprime également les branches distantes fusionnées")]
        [switch]$RemoteCleanup,

        [Parameter(Mandatory=$false, HelpMessage="Affiche uniquement les branches qui seraient supprimées")]
        [switch]$WhatIf,

        [Parameter(Mandatory=$false, HelpMessage="Supprime automatiquement sans demander de confirmation")]
        [switch]$Force
    )

    try {
        # Vérifier que nous sommes dans un dépôt Git
        $isGitRepo = git rev-parse --is-inside-work-tree 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Le répertoire actuel n'est pas un dépôt Git."
            return
        }

        # Mettre à jour les références du dépôt distant
        Write-Host "Mise à jour des références du dépôt distant..." -ForegroundColor Cyan
        git fetch --prune

        # Obtenir la branche actuelle
        $currentBranch = git branch --show-current
        Write-Host "Branche actuelle: $currentBranch" -ForegroundColor Green

        # Ajouter la branche actuelle aux branches protégées si elle n'y est pas déjà
        if ($ProtectedBranches -notcontains $currentBranch) {
            $ProtectedBranches += $currentBranch
        }

        Write-Host "Branches protégées: $($ProtectedBranches -join ', ')" -ForegroundColor Yellow

        # 1. Nettoyage des branches locales fusionnées
        Write-Host "`nRecherche des branches locales fusionnées..." -ForegroundColor Cyan

        # Obtenir toutes les branches fusionnées
        $mergedBranches = git branch --merged | ForEach-Object { $_.Trim() } | Where-Object { $_ -notmatch '^\*' } | Where-Object { $ProtectedBranches -notcontains $_ }

        if ($mergedBranches.Count -eq 0) {
            Write-Host "Aucune branche locale fusionnée à supprimer." -ForegroundColor Green
        } else {
            Write-Host "Branches locales fusionnées à supprimer:" -ForegroundColor Yellow
            $mergedBranches | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }

            if ($Force -or $PSCmdlet.ShouldProcess("branches locales fusionnées", "Supprimer")) {
                $mergedBranches | ForEach-Object {
                    git branch -d $_
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Branche '$_' supprimée." -ForegroundColor Green
                    } else {
                        Write-Warning "Échec de la suppression de la branche '$_'. Elle contient peut-être des changements non fusionnés."
                    }
                }
            }
        }

        # 2. Nettoyage des branches locales dont la référence distante n'existe plus
        Write-Host "`nRecherche des branches locales sans référence distante..." -ForegroundColor Cyan

        # Obtenir toutes les branches locales qui suivent une branche distante qui n'existe plus
        $goneBranches = git branch -vv | Select-String -Pattern ': gone]' | ForEach-Object { $_.ToString().Trim().Split()[0] } | Where-Object { $ProtectedBranches -notcontains $_ }

        if ($goneBranches.Count -eq 0) {
            Write-Host "Aucune branche locale sans référence distante à supprimer." -ForegroundColor Green
        } else {
            Write-Host "Branches locales sans référence distante à supprimer:" -ForegroundColor Yellow
            $goneBranches | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }

            if ($Force -or $PSCmdlet.ShouldProcess("branches locales sans référence distante", "Supprimer")) {
                $goneBranches | ForEach-Object {
                    # Utiliser -D au lieu de -d pour forcer la suppression car ces branches peuvent contenir des changements non fusionnés
                    git branch -D $_
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Branche '$_' supprimée." -ForegroundColor Green
                    } else {
                        Write-Warning "Échec de la suppression de la branche '$_'."
                    }
                }
            }
        }

        # 3. Nettoyage des branches distantes fusionnées (si demandé)
        if ($RemoteCleanup) {
            Write-Host "`nRecherche des branches distantes fusionnées..." -ForegroundColor Cyan

            # Obtenir toutes les branches distantes fusionnées
            $remoteMergedBranches = git branch -r --merged | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^origin/' } | ForEach-Object { $_ -replace '^origin/', '' } | Where-Object { $ProtectedBranches -notcontains $_ }

            if ($remoteMergedBranches.Count -eq 0) {
                Write-Host "Aucune branche distante fusionnée à supprimer." -ForegroundColor Green
            } else {
                Write-Host "Branches distantes fusionnées à supprimer:" -ForegroundColor Yellow
                $remoteMergedBranches | ForEach-Object { Write-Host "  - $_" -ForegroundColor DarkYellow }

                if ($Force -or $PSCmdlet.ShouldProcess("branches distantes fusionnées", "Supprimer")) {
                    $remoteMergedBranches | ForEach-Object {
                        git push origin --delete $_
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "Branche distante '$_' supprimée." -ForegroundColor Green
                        } else {
                            Write-Warning "Échec de la suppression de la branche distante '$_'."
                        }
                    }
                }
            }
        }

        # Résumé final
        Write-Host "`nNettoyage des branches terminé!" -ForegroundColor Green
    }
    catch {
        Write-Error "Une erreur s'est produite: $_"
    }
}

# Exporter les fonctions pour pouvoir les importer dans votre profil
Export-ModuleMember -Function Initialize-GitRepo, Remove-MergedBranches
```

## Comment utiliser ces fonctions

Vous pouvez utiliser ces fonctions de plusieurs façons :

### Option 1 : Exécuter directement le script

1. Copiez le script complet dans un fichier nommé `GitAutomation.ps1`
2. Exécutez-le en utilisant `. .\GitAutomation.ps1` pour charger les fonctions dans votre session PowerShell

### Option 2 : Créer un module PowerShell

1. Copiez le script dans un fichier nommé `GitAutomation.psm1`
2. Créez un dossier nommé `GitAutomation` dans un des emplacements de votre `$env:PSModulePath`
3. Placez le fichier `GitAutomation.psm1` dans ce dossier
4. Importez le module en utilisant `Import-Module GitAutomation`

### Option 3 : Ajouter au profil PowerShell

1. Ajoutez les fonctions directement à votre profil PowerShell (`$PROFILE`)
2. Elles seront disponibles automatiquement à chaque démarrage de PowerShell

## Exemples d'utilisation

### Initialiser un nouveau dépôt Git

```powershell
# Cloner un dépôt avec les paramètres de base
Initialize-GitRepo -RepoUrl "https://github.com/utilisateur/projet.git"

# Cloner avec configuration complète
Initialize-GitRepo -RepoUrl "https://github.com/utilisateur/projet.git" `
                  -DestinationPath "C:\Projets\MonProjet" `
                  -UserName "Votre Nom" `
                  -Email "votre.email@exemple.com" `
                  -DefaultBranch "main" `
                  -CreateDevBranch `
                  -InstallHooks `
                  -InstallDependencies
```

### Nettoyer les branches fusionnées

```powershell
# Nettoyage de base (interactif)
Remove-MergedBranches

# Voir les branches qui seraient supprimées sans les supprimer réellement
Remove-MergedBranches -WhatIf

# Nettoyer également les branches distantes
Remove-MergedBranches -RemoteCleanup

# Nettoyer sans confirmation avec branches protégées personnalisées
Remove-MergedBranches -Force -ProtectedBranches @("main", "develop", "release")
```

## Bonnes pratiques d'utilisation

1. **Testez toujours dans un environnement sûr** avant d'utiliser ces fonctions sur des dépôts importants
2. **Personnalisez les branches protégées** selon les besoins de votre projet
3. **Utilisez l'option -WhatIf** pour voir quelles branches seraient supprimées avant de les supprimer réellement
4. **Ajoutez ces fonctions à votre profil PowerShell** pour un accès facile


# Solution Exercice 3: Intégration avancée

## Objectifs de l'exercice
1. Créer un tableau de bord PowerShell qui affiche l'état de tous vos dépôts
2. Écrire un script qui crée un rapport hebdomadaire de votre activité Git

## Solution complète

Voici un script complet qui implémente les deux fonctionnalités demandées dans l'exercice 3 :

```powershell
# Solution Exercice 3: Intégration avancée pour PowerShell + Git
# -------------------------------------------------------------

# Module pour le tableau de bord Git et le rapport d'activité
# Nécessite PowerShell 5.1 ou supérieur, posh-git installé

# Charger les dépendances
if (-not (Get-Module -ListAvailable -Name posh-git)) {
    Write-Warning "Le module posh-git est nécessaire. Installation..."
    Install-Module posh-git -Scope CurrentUser -Force
}

Import-Module posh-git

#region Configuration

# Paramètres personnalisables
$script:Config = @{
    # Chemins des répertoires à surveiller - ajouter les vôtres ici
    GitReposPaths = @(
        "$HOME\Projects",
        "$HOME\Documents\GitHub",
        "$HOME\Source\Repos"
    )

    # Format de sortie des rapports (HTML, Text, CSV)
    DefaultReportFormat = "HTML"

    # Nombre de jours d'historique à inclure dans les rapports par défaut
    DefaultHistoryDays = 7

    # Couleurs pour la sortie console
    Colors = @{
        Clean      = "Green"
        Modified   = "Yellow"
        Untracked  = "Cyan"
        Conflict   = "Red"
        Header     = "Magenta"
        Subheader  = "Blue"
        Normal     = "White"
    }

    # Chemins d'exportation par défaut
    ExportPaths = @{
        Dashboard = "$HOME\GitDashboard"
        Reports   = "$HOME\GitReports"
    }
}

# Créer les répertoires d'exportation s'ils n'existent pas
if (-not (Test-Path $Config.ExportPaths.Dashboard)) {
    New-Item -ItemType Directory -Path $Config.ExportPaths.Dashboard -Force | Out-Null
}

if (-not (Test-Path $Config.ExportPaths.Reports)) {
    New-Item -ItemType Directory -Path $Config.ExportPaths.Reports -Force | Out-Null
}

#endregion Configuration

#region Fonctions Utilitaires

function Test-IsGitRepository {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    try {
        Push-Location $Path
        $isGitRepo = (git rev-parse --is-inside-work-tree 2>$null)
        $exitCode = $LASTEXITCODE
        Pop-Location

        return ($exitCode -eq 0 -and $isGitRepo -eq "true")
    } catch {
        return $false
    } finally {
        if ((Get-Location).Path -eq $Path) {
            Pop-Location
        }
    }
}

function Find-GitRepositories {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$BasePaths = $Config.GitReposPaths,

        [Parameter(Mandatory=$false)]
        [int]$MaxDepth = 3
    )

    $repos = @()

    foreach ($basePath in $BasePaths) {
        if (-not (Test-Path $basePath)) {
            Write-Warning "Le chemin '$basePath' n'existe pas et sera ignoré."
            continue
        }

        Write-Verbose "Recherche de dépôts Git dans '$basePath'..."

        # Rechercher les dépôts Git directement dans le chemin de base
        if (Test-IsGitRepository $basePath) {
            $repos += $basePath
            continue
        }

        # Rechercher les dépôts Git dans les sous-répertoires jusqu'à MaxDepth
        $directories = @($basePath)

        for ($depth = 0; $depth -lt $MaxDepth; $depth++) {
            $newDirs = @()

            foreach ($dir in $directories) {
                # Obtenir les sous-répertoires directs
                $subDirs = Get-ChildItem -Path $dir -Directory -ErrorAction SilentlyContinue

                foreach ($subDir in $subDirs) {
                    # Si c'est un dépôt Git, l'ajouter à la liste
                    if (Test-IsGitRepository $subDir.FullName) {
                        $repos += $subDir.FullName
                    } else {
                        # Sinon, l'ajouter à la liste des répertoires à explorer au niveau suivant
                        $newDirs += $subDir.FullName
                    }
                }
            }

            $directories = $newDirs

            # Si aucun nouveau répertoire à explorer, sortir de la boucle
            if ($directories.Count -eq 0) {
                break
            }
        }
    }

    return $repos
}

function Get-GitRepositoryStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoPath
    )

    if (-not (Test-IsGitRepository $RepoPath)) {
        Write-Error "Le chemin '$RepoPath' n'est pas un dépôt Git valide."
        return $null
    }

    try {
        Push-Location $RepoPath

        # Récupérer les informations principales du dépôt
        $repoName = Split-Path -Leaf $RepoPath
        $branchName = git branch --show-current
        $remoteUrl = git remote get-url origin 2>$null
        if ($LASTEXITCODE -ne 0) { $remoteUrl = "Pas de remote configuré" }

        # Status du dépôt
        $status = git status --porcelain
        $statusSummary = @{
            Clean = $status.Count -eq 0
            Modified = ($status | Where-Object { $_ -match '^ ?M' }).Count
            Untracked = ($status | Where-Object { $_ -match '^\?\?' }).Count
            Deleted = ($status | Where-Object { $_ -match '^ ?D' }).Count
            Added = ($status | Where-Object { $_ -match '^A' }).Count
            Renamed = ($status | Where-Object { $_ -match '^R' }).Count
            Conflict = ($status | Where-Object { $_ -match '^(DD|AU|UD|UA|DU|AA|UU)' }).Count
        }

        # Informations sur les commits
        $lastCommit = git log -1 --format="%h|%an|%ae|%ad|%s" --date=iso
        if ($LASTEXITCODE -eq 0 -and $lastCommit) {
            $lastCommitParts = $lastCommit -split '\|'
            $lastCommitInfo = @{
                Hash = $lastCommitParts[0]
                Author = $lastCommitParts[1]
                Email = $lastCommitParts[2]
                Date = [DateTime]::Parse($lastCommitParts[3])
                Message = $lastCommitParts[4]
            }
        } else {
            $lastCommitInfo = @{
                Hash = "N/A"
                Author = "N/A"
                Email = "N/A"
                Date = $null
                Message = "Pas de commits"
            }
        }

        # Informations sur le statut par rapport au remote
        $ahead = 0
        $behind = 0

        if ($remoteUrl -ne "Pas de remote configuré") {
            # Mettre à jour les références distantes
            git fetch origin --quiet

            # Récupérer les infos ahead/behind
            $statusInfo = git status -sb | Select-String -Pattern "ahead|behind"
            if ($statusInfo) {
                $aheadMatch = $statusInfo -match "ahead (\d+)"
                if ($Matches -and $Matches[1]) {
                    $ahead = [int]$Matches[1]
                }

                $behindMatch = $statusInfo -match "behind (\d+)"
                if ($Matches -and $Matches[1]) {
                    $behind = [int]$Matches[1]
                }
            }
        }

        # Créer l'objet de statut du dépôt
        $repoStatus = [PSCustomObject]@{
            Name = $repoName
            Path = $RepoPath
            Branch = $branchName
            Remote = $remoteUrl
            IsClean = $statusSummary.Clean
            Modified = $statusSummary.Modified
            Untracked = $statusSummary.Untracked
            Deleted = $statusSummary.Deleted
            Added = $statusSummary.Added
            Renamed = $statusSummary.Renamed
            Conflict = $statusSummary.Conflict
            AheadBy = $ahead
            BehindBy = $behind
            LastCommit = $lastCommitInfo
            StatusSummary = if ($statusSummary.Clean) { "Propre" } elseif ($statusSummary.Conflict -gt 0) { "Conflits" } else { "Modifié" }
        }

        return $repoStatus
    }
    catch {
        Write-Error "Erreur lors de la récupération du statut du dépôt '$RepoPath': $_"
        return $null
    }
    finally {
        # Retourner au répertoire de départ
        Pop-Location
    }
}

function Get-GitActivityStats {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$RepoPath,

        [Parameter(Mandatory=$false)]
        [int]$Days = $Config.DefaultHistoryDays,

        [Parameter(Mandatory=$false)]
        [string]$Author
    )

    if (-not (Test-IsGitRepository $RepoPath)) {
        Write-Error "Le chemin '$RepoPath' n'est pas un dépôt Git valide."
        return $null
    }

    try {
        Push-Location $RepoPath

        $sinceDate = (Get-Date).AddDays(-$Days).ToString("yyyy-MM-dd")
        $authorFilter = if ($Author) { "--author=`"$Author`"" } else { "" }

        # Résumé des commits
        $commits = git log --since=$sinceDate $authorFilter --format="%h|%an|%ae|%ad|%s" --date=iso
        $commitCount = ($commits | Measure-Object).Count

        # Fichiers modifiés
        $fileStats = git diff --stat --since=$sinceDate $authorFilter
        $insertions = 0
        $deletions = 0

        $fileStats | ForEach-Object {
            if ($_ -match '(\d+) insertion') { $insertions += [int]$Matches[1] }
            if ($_ -match '(\d+) deletion') { $deletions += [int]$Matches[1] }
        }

        # Auteurs
        $authors = git log --since=$sinceDate --format="%an" | Sort-Object -Unique
        $authorCount = $authors.Count

        # Activité par jour
        $activityByDay = @{}
        $commits | ForEach-Object {
            $parts = $_ -split '\|'
            $date = [DateTime]::Parse($parts[3]).ToString("yyyy-MM-dd")

            if (-not $activityByDay.ContainsKey($date)) {
                $activityByDay[$date] = 0
            }

            $activityByDay[$date]++
        }

        # Branches actives
        $activeBranches = git branch --format="%(refname:short)" | Where-Object { git log --since=$sinceDate -1 --format="%h" $_ }

        # Créer l'objet d'activité Git
        $activityStats = [PSCustomObject]@{
            RepoName = Split-Path -Leaf $RepoPath
            RepoPath = $RepoPath
            PeriodDays = $Days
            StartDate = $sinceDate
            EndDate = (Get-Date).ToString("yyyy-MM-dd")
            CommitCount = $commitCount
            FileInsertions = $insertions
            FileDeletions = $deletions
            AuthorCount = $authorCount
            Authors = $authors
            DailyActivity = $activityByDay
            ActiveBranches = $activeBranches
            FilteredByAuthor = [bool]$Author
            AuthorFilter = $Author
        }

        return $activityStats
    }
    catch {
        Write-Error "Erreur lors de la récupération des statistiques d'activité du dépôt '$RepoPath': $_"
        return $null
    }
    finally {
        # Retourner au répertoire de départ
        Pop-Location
    }
}

#endregion Fonctions Utilitaires

#region Tableau de Bord

function Show-GitDashboard {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$BasePaths = $Config.GitReposPaths,

        [Parameter(Mandatory=$false)]
        [switch]$ExportToHTML,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath = (Join-Path $Config.ExportPaths.Dashboard "GitDashboard_$(Get-Date -Format 'yyyyMMdd_HHmmss').html")
    )

    Write-Host "Génération du tableau de bord Git..." -ForegroundColor $Config.Colors.Header

    # Trouver tous les dépôts Git
    Write-Host "Recherche des dépôts Git..." -ForegroundColor $Config.Colors.Subheader
    $repositories = Find-GitRepositories -BasePaths $BasePaths

    if ($repositories.Count -eq 0) {
        Write-Warning "Aucun dépôt Git trouvé dans les chemins spécifiés."
        return
    }

    Write-Host "Trouvé $($repositories.Count) dépôts Git." -ForegroundColor $Config.Colors.Normal

    # Récupérer le statut de chaque dépôt
    Write-Host "Analyse du statut des dépôts..." -ForegroundColor $Config.Colors.Subheader
    $repoStatus = @()

    $i = 0
    foreach ($repo in $repositories) {
        $i++
        Write-Progress -Activity "Analyse des dépôts Git" -Status "Dépôt $i sur $($repositories.Count)" -PercentComplete (($i / $repositories.Count) * 100)
        $status = Get-GitRepositoryStatus -RepoPath $repo
        if ($status) {
            $repoStatus += $status
        }
    }

    Write-Progress -Activity "Analyse des dépôts Git" -Completed

    # Afficher le résumé dans la console
    Write-Host "`nÉtat des dépôts Git:" -ForegroundColor $Config.Colors.Header

    $repoStatus | ForEach-Object {
        $statusColor = switch ($_.StatusSummary) {
            "Propre" { $Config.Colors.Clean }
            "Conflits" { $Config.Colors.Conflict }
            default { $Config.Colors.Modified }
        }

        Write-Host "`n[$($_.Name)]" -ForegroundColor $Config.Colors.Subheader
        Write-Host "  Branche: $($_.Branch)" -ForegroundColor $Config.Colors.Normal
        Write-Host "  Statut: $($_.StatusSummary)" -ForegroundColor $statusColor

        if (-not $_.IsClean) {
            if ($_.Modified -gt 0) { Write-Host "  - Fichiers modifiés: $($_.Modified)" -ForegroundColor $Config.Colors.Modified }
            if ($_.Untracked -gt 0) { Write-Host "  - Fichiers non suivis: $($_.Untracked)" -ForegroundColor $Config.Colors.Untracked }
            if ($_.Deleted -gt 0) { Write-Host "  - Fichiers supprimés: $($_.Deleted)" -ForegroundColor $Config.Colors.Modified }
            if ($_.Conflict -gt 0) { Write-Host "  - Conflits: $($_.Conflict)" -ForegroundColor $Config.Colors.Conflict }
        }

        if ($_.AheadBy -gt 0) { Write-Host "  - En avance de $($_.AheadBy) commit(s)" -ForegroundColor $Config.Colors.Modified }
        if ($_.BehindBy -gt 0) { Write-Host "  - En retard de $($_.BehindBy) commit(s)" -ForegroundColor $Config.Colors.Modified }

        Write-Host "  Dernier commit: $($_.LastCommit.Hash) - $($_.LastCommit.Message)" -ForegroundColor $Config.Colors.Normal
        if ($_.LastCommit.Date) {
            $timeSinceCommit = (Get-Date) - $_.LastCommit.Date
            if ($timeSinceCommit.Days -gt 0) {
                Write-Host "  Il y a $($timeSinceCommit.Days) jour(s)" -ForegroundColor $Config.Colors.Normal
            } else {
                Write-Host "  Il y a $($timeSinceCommit.Hours) heure(s)" -ForegroundColor $Config.Colors.Normal
            }
        }
    }

    # Générer le rapport HTML si demandé
    if ($ExportToHTML) {
        $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tableau de Bord Git - $(Get-Date -Format "yyyy-MM-dd")</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .dashboard-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .dashboard-summary {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .repo-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
        }
        .repo-card {
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            background-color: #fff;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .repo-header {
            display: flex;
            justify-content: space-between;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            margin-bottom: 10px;
        }
        .repo-name {
            font-size: 18px;
            font-weight: bold;
            color: #2c3e50;
        }
        .repo-branch {
            color: #7f8c8d;
        }
        .repo-status {
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }
        .status-clean {
            background-color: #dff0d8;
            color: #3c763d;
        }
        .status-modified {
            background-color: #fcf8e3;
            color: #8a6d3b;
        }
        .status-conflict {
            background-color: #f2dede;
            color: #a94442;
        }
        .repo-details {
            margin-top: 10px;
        }
        .repo-details p {
            margin: 5px 0;
        }
        .commits-info {
            display: flex;
            gap: 10px;
            margin-top: 10px;
        }
        .commit-stat {
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 12px;
        }
        .ahead {
            background-color: #d9edf7;
            color: #31708f;
        }
        .behind {
            background-color: #fcf8e3;
            color: #8a6d3b;
        }
        .last-commit {
            margin-top: 10px;
            padding: 10px;
            background-color: #f8f9fa;
            border-radius: 3px;
            font-size: 14px;
        }
        .commit-date {
            color: #7f8c8d;
            font-size: 12px;
        }
        footer {
            margin-top: 30px;
            text-align: center;
            font-size: 12px;
            color: #7f8c8d;
        }
    </style>
</head>
<body>
    <div class="dashboard-header">
        <h1>Tableau de Bord Git</h1>
        <p>Généré le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm")</p>
    </div>

    <div class="dashboard-summary">
        <p><strong>Dépôts trouvés:</strong> $($repoStatus.Count)</p>
        <p><strong>Dépôts propres:</strong> $($repoStatus | Where-Object { $_.IsClean } | Measure-Object).Count</p>
        <p><strong>Dépôts modifiés:</strong> $($repoStatus | Where-Object { -not $_.IsClean -and $_.Conflict -eq 0 } | Measure-Object).Count</p>
        <p><strong>Dépôts avec conflits:</strong> $($repoStatus | Where-Object { $_.Conflict -gt 0 } | Measure-Object).Count</p>
        <p><strong>Dépôts en avance:</strong> $($repoStatus | Where-Object { $_.AheadBy -gt 0 } | Measure-Object).Count</p>
        <p><strong>Dépôts en retard:</strong> $($repoStatus | Where-Object { $_.BehindBy -gt 0 } | Measure-Object).Count</p>
    </div>

    <div class="repo-grid">
"@

        foreach ($repo in $repoStatus) {
            $statusClass = switch ($repo.StatusSummary) {
                "Propre" { "status-clean" }
                "Conflits" { "status-conflict" }
                default { "status-modified" }
            }

            $lastCommitDate = if ($repo.LastCommit.Date) {
                $timeSinceCommit = (Get-Date) - $repo.LastCommit.Date
                if ($timeSinceCommit.Days -gt 0) {
                    "Il y a $($timeSinceCommit.Days) jour(s)"
                } elseif ($timeSinceCommit.Hours -gt 0) {
                    "Il y a $($timeSinceCommit.Hours) heure(s)"
                } else {
                    "Il y a $($timeSinceCommit.Minutes) minute(s)"
                }
            } else {
                "Date inconnue"
            }

            $htmlContent += @"
        <div class="repo-card">
            <div class="repo-header">
                <div class="repo-name">$($repo.Name)</div>
                <div class="repo-status $statusClass">$($repo.StatusSummary)</div>
            </div>
            <div class="repo-branch">Branche: $($repo.Branch)</div>

            <div class="repo-details">
"@

            if (-not $repo.IsClean) {
                if ($repo.Modified -gt 0) { $htmlContent += "<p>Fichiers modifiés: $($repo.Modified)</p>" }
                if ($repo.Untracked -gt 0) { $htmlContent += "<p>Fichiers non suivis: $($repo.Untracked)</p>" }
                if ($repo.Deleted -gt 0) { $htmlContent += "<p>Fichiers supprimés: $($repo.Deleted)</p>" }
                if ($repo.Conflict -gt 0) { $htmlContent += "<p>Conflits: $($repo.Conflict)</p>" }
            }

            $htmlContent += @"
            </div>

            <div class="commits-info">
"@

            if ($repo.AheadBy -gt 0) {
                $htmlContent += "<span class='commit-stat ahead'>En avance: $($repo.AheadBy)</span>"
            }
            if ($repo.BehindBy -gt 0) {
                $htmlContent += "<span class='commit-stat behind'>En retard: $($repo.BehindBy)</span>"
            }

            $htmlContent += @"
            </div>

            <div class="last-commit">
                <div>$($repo.LastCommit.Hash) - $($repo.LastCommit.Message)</div>
                <div class="commit-date">$lastCommitDate</div>
            </div>
        </div>
"@
        }

        $htmlContent += @"
    </div>

    <footer>
        <p>Tableau de bord généré par PowerShell Git Dashboard | $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </footer>
</body>
</html>
"@

        # Exporter le HTML
        $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8
        Write-Host "`nTableau de bord exporté en HTML: $OutputPath" -ForegroundColor $Config.Colors.Subheader

        # Ouvrir le rapport dans le navigateur par défaut
        Start-Process $OutputPath
    }

    # Retourner les données de statut pour utilisation ultérieure
    return $repoStatus
}

#endregion Tableau de Bord

#region Rapport d'Activité

function New-GitActivityReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string[]]$RepositoryPaths,

        [Parameter(Mandatory=$false)]
        [string[]]$BasePaths = $Config.GitReposPaths,

        [Parameter(Mandatory=$false)]
        [int]$Days = $Config.DefaultHistoryDays,

        [Parameter(Mandatory=$false)]
        [string]$Author,

        [Parameter(Mandatory=$false)]
        [ValidateSet("HTML", "Text", "CSV")]
        [string]$Format = $Config.DefaultReportFormat,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath = (Join-Path $Config.ExportPaths.Reports "GitActivityReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').$($Format.ToLower())")
    )

    Write-Host "Génération du rapport d'activité Git..." -ForegroundColor $Config.Colors.Header

    # Déterminer les dépôts à inclure dans le rapport
    if (-not $RepositoryPaths) {
        Write-Host "Recherche des dépôts Git..." -ForegroundColor $Config.Colors.Subheader
        $repositories = Find-GitRepositories -BasePaths $BasePaths
    } else {
        $repositories = $RepositoryPaths | Where-Object { Test-IsGitRepository $_ }
    }

    if ($repositories.Count -eq 0) {
        Write-Warning "Aucun dépôt Git valide trouvé."
        return
    }

    Write-Host "Analyse de l'activité sur $($repositories.Count) dépôts pour les $Days derniers jours..." -ForegroundColor $Config.Colors.Subheader

    # Paramètre d'auteur pour l'affichage
    $authorDisplay = if ($Author) { "pour $Author" } else { "pour tous les auteurs" }

    # Récupérer les statistiques d'activité pour chaque dépôt
    $repoStats = @()
    $totalCommits = 0
    $totalInsertions = 0
    $totalDeletions = 0
    $allAuthors = @{}
    $allDailyActivity = @{}

    $i = 0
    foreach ($repo in $repositories) {
        $i++
        Write-Progress -Activity "Analyse de l'activité Git" -Status "Dépôt $i sur $($repositories.Count)" -PercentComplete (($i / $repositories.Count) * 100)

        $stats = Get-GitActivityStats -RepoPath $repo -Days $Days -Author $Author
        if ($stats) {
            $repoStats += $stats

            # Cumuler les statistiques globales
            $totalCommits += $stats.CommitCount
            $totalInsertions += $stats.FileInsertions
            $totalDeletions += $stats.FileDeletions

            # Cumuler les auteurs
            foreach ($currentAuthor in $stats.Authors) {
                if (-not $allAuthors.ContainsKey($currentAuthor)) {
                    $allAuthors[$currentAuthor] = 0
                }
                $allAuthors[$currentAuthor]++
            }

            # Cumuler l'activité quotidienne
            foreach ($date in $stats.DailyActivity.Keys) {
                if (-not $allDailyActivity.ContainsKey($date)) {
                    $allDailyActivity[$date] = 0
                }
                $allDailyActivity[$date] += $stats.DailyActivity[$date]
            }
        }
    }

    Write-Progress -Activity "Analyse de l'activité Git" -Completed

    # Trier les statistiques pour le rapport
    $sortedRepoStats = $repoStats | Sort-Object -Property CommitCount -Descending
    $sortedAuthors = $allAuthors.GetEnumerator() | Sort-Object -Property Value -Descending
    $sortedDailyActivity = $allDailyActivity.GetEnumerator() | Sort-Object -Property Name

    # Afficher le résumé dans la console
    Write-Host "`nRésumé d'activité Git pour les $Days derniers jours $authorDisplay:" -ForegroundColor $Config.Colors.Header
    Write-Host "  Total des commits: $totalCommits" -ForegroundColor $Config.Colors.Normal
    Write-Host "  Insertions: $totalInsertions" -ForegroundColor $Config.Colors.Normal
    Write-Host "  Suppressions: $totalDeletions" -ForegroundColor $Config.Colors.Normal
    Write-Host "  Nombre d'auteurs: $($allAuthors.Count)" -ForegroundColor $Config.Colors.Normal

    Write-Host "`nActivité par dépôt:" -ForegroundColor $Config.Colors.Subheader
    $sortedRepoStats | ForEach-Object {
        Write-Host "  $($_.RepoName): $($_.CommitCount) commit(s)" -ForegroundColor $Config.Colors.Normal
    }

    if ($sortedAuthors.Count -gt 0) {
        Write-Host "`nContributeurs les plus actifs:" -ForegroundColor $Config.Colors.Subheader
        $sortedAuthors | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.Name): présent dans $($_.Value) dépôt(s)" -ForegroundColor $Config.Colors.Normal
        }
    }

    # Générer le rapport selon le format demandé
    switch ($Format) {
        "HTML" {
            $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Activité Git - $(Get-Date -Format "yyyy-MM-dd")</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .report-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
        }
        .summary-section {
            background-color: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        .stat-card {
            background-color: #fff;
            border-radius: 5px;
            padding: 15px;
            text-align: center;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .stat-value {
            font-size: 24px;
            font-weight: bold;
            color: #3498db;
        }
        .stat-label {
            color: #7f8c8d;
            font-size: 14px;
        }
        .repo-activity {
            margin-bottom: 30px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 8px 12px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .chart-container {
            margin: 20px 0;
            height: 300px;
        }
        .activity-chart {
            display: flex;
            align-items: flex-end;
            height: 200px;
            border-bottom: 1px solid #ddd;
            border-left: 1px solid #ddd;
            padding-top: 20px;
        }
        .chart-bar {
            margin: 0 3px;
            width: 30px;
            background-color: #3498db;
            border-radius: 3px 3px 0 0;
            position: relative;
        }
        .chart-label {
            position: absolute;
            bottom: -25px;
            left: 0;
            right: 0;
            text-align: center;
            font-size: 10px;
            transform: rotate(-45deg);
            transform-origin: top left;
            white-space: nowrap;
        }
        .chart-value {
            position: absolute;
            top: -20px;
            left: 0;
            right: 0;
            text-align: center;
            font-size: 12px;
            font-weight: bold;
        }
        footer {
            margin-top: 30px;
            text-align: center;
            font-size: 12px;
            color: #7f8c8d;
            border-top: 1px solid #eee;
            padding-top: 10px;
        }
    </style>
</head>
<body>
    <div class="report-header">
        <h1>Rapport d'Activité Git</h1>
        <p>Période: $($sortedRepoStats[0].StartDate) au $($sortedRepoStats[0].EndDate)</p>
    </div>

    <div class="summary-section">
        <h2>Résumé de l'activité</h2>
        <p>Ce rapport couvre l'activité Git des $Days derniers jours $authorDisplay sur $($repositories.Count) dépôts.</p>

        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-value">$totalCommits</div>
                <div class="stat-label">Commits</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">$totalInsertions</div>
                <div class="stat-label">Lignes ajoutées</div>
            </div>
            <div class="stat-card">
                <div class="stat-value">$totalDeletions</div>
                <div class="stat-label">Lignes supprimées</div>
            </div>
        </div>
    </div>

    <h2>Activité par dépôt</h2>
    <table>
        <tr>
            <th>Dépôt</th>
            <th>Commits</th>
            <th>Lignes ajoutées</th>
            <th>Lignes supprimées</th>
            <th>Branches actives</th>
        </tr>
"@

            foreach ($stats in $sortedRepoStats) {
                $htmlContent += @"
        <tr>
            <td>$($stats.RepoName)</td>
            <td>$($stats.CommitCount)</td>
            <td>$($stats.FileInsertions)</td>
            <td>$($stats.FileDeletions)</td>
            <td>$($stats.ActiveBranches.Count)</td>
        </tr>
"@
            }

            $htmlContent += @"
    </table>

    <h2>Activité par jour</h2>
    <div class="chart-container">
        <div class="activity-chart">
"@

            foreach ($day in $sortedDailyActivity) {
                $height = if ($allDailyActivity.Values | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum) {
                    $max = ($allDailyActivity.Values | Measure-Object -Maximum).Maximum
                    [Math]::Max(20, [Math]::Round(($day.Value / $max) * 200))
                } else {
                    20
                }

                $dayDisplay = [DateTime]::Parse($day.Name).ToString("dd MMM")

                $htmlContent += @"
            <div class="chart-bar" style="height: ${height}px;">
                <div class="chart-value">$($day.Value)</div>
                <div class="chart-label">$dayDisplay</div>
            </div>
"@
            }

            $htmlContent += @"
        </div>
    </div>

    <h2>Contributeurs</h2>
    <table>
        <tr>
            <th>Contributeur</th>
            <th>Présent dans</th>
        </tr>
"@

            foreach ($author in $sortedAuthors) {
                $htmlContent += @"
        <tr>
            <td>$($author.Name)</td>
            <td>$($author.Value) dépôt(s)</td>
        </tr>
"@
            }

            $htmlContent += @"
    </table>

    <footer>
        <p>Rapport généré par PowerShell Git Activity Report | $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </footer>
</body>
</html>
"@

            # Exporter le HTML
            $htmlContent | Out-File -FilePath $OutputPath -Encoding utf8
            Write-Host "`nRapport exporté en HTML: $OutputPath" -ForegroundColor $Config.Colors.Subheader

            # Ouvrir le rapport dans le navigateur par défaut
            Start-Process $OutputPath
        }

        "Text" {
            $textContent = @"
=======================================================
RAPPORT D'ACTIVITÉ GIT - $(Get-Date -Format "yyyy-MM-dd")
=======================================================

Période: $($sortedRepoStats[0].StartDate) au $($sortedRepoStats[0].EndDate)
Durée: $Days jours
Filtré par auteur: $(if ($Author) { $Author } else { "Non" })

RÉSUMÉ GLOBAL
-------------
Total des commits: $totalCommits
Lignes ajoutées: $totalInsertions
Lignes supprimées: $totalDeletions
Nombre d'auteurs: $($allAuthors.Count)

ACTIVITÉ PAR DÉPÔT
------------------
"@

            foreach ($stats in $sortedRepoStats) {
                $textContent += @"
$($stats.RepoName)
  * Commits: $($stats.CommitCount)
  * Lignes ajoutées: $($stats.FileInsertions)
  * Lignes supprimées: $($stats.FileDeletions)
  * Branches actives: $($stats.ActiveBranches.Count)
  * Branches: $($stats.ActiveBranches -join ", ")

"@
            }

            $textContent += @"

ACTIVITÉ QUOTIDIENNE
-------------------
"@

            foreach ($day in $sortedDailyActivity) {
                $dayDisplay = [DateTime]::Parse($day.Name).ToString("yyyy-MM-dd")
                $textContent += @"
$dayDisplay : $($day.Value) commit(s)
"@
            }

            $textContent += @"

CONTRIBUTEURS
------------
"@

            foreach ($author in $sortedAuthors) {
                $textContent += @"
$($author.Name) : présent dans $($author.Value) dépôt(s)
"@
            }

            $textContent += @"

=======================================================
Rapport généré par PowerShell Git Activity Report
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
=======================================================
"@

            # Exporter le texte
            $textContent | Out-File -FilePath $OutputPath -Encoding utf8
            Write-Host "`nRapport exporté au format texte: $OutputPath" -ForegroundColor $Config.Colors.Subheader

            # Ouvrir le rapport dans notepad
            Start-Process notepad $OutputPath
        }

        "CSV" {
            # Créer un objet CSV combinant les données pour l'export
            $csvData = @()

            # Données par dépôt
            foreach ($stats in $sortedRepoStats) {
                $csvObj = [PSCustomObject]@{
                    Type = "Repository"
                    Name = $stats.RepoName
                    Path = $stats.RepoPath
                    Commits = $stats.CommitCount
                    Insertions = $stats.FileInsertions
                    Deletions = $stats.FileDeletions
                    ActiveBranches = $stats.ActiveBranches.Count
                    Date = ""
                    Value = ""
                }
                $csvData += $csvObj
            }

            # Données par jour
            foreach ($day in $sortedDailyActivity) {
                $csvObj = [PSCustomObject]@{
                    Type = "DailyActivity"
                    Name = ""
                    Path = ""
                    Commits = ""
                    Insertions = ""
                    Deletions = ""
                    ActiveBranches = ""
                    Date = $day.Name
                    Value = $day.Value
                }
                $csvData += $csvObj
            }

            # Données par auteur
            foreach ($author in $sortedAuthors) {
                $csvObj = [PSCustomObject]@{
                    Type = "Author"
                    Name = $author.Name
                    Path = ""
                    Commits = ""
                    Insertions = ""
                    Deletions = ""
                    ActiveBranches = ""
                    Date = ""
                    Value = $author.Value
                }
                $csvData += $csvObj
            }

            # Exporter en CSV
            $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            Write-Host "`nRapport exporté au format CSV: $OutputPath" -ForegroundColor $Config.Colors.Subheader
        }
    }

    # Retourner les statistiques pour utilisation ultérieure
    return $repoStats
}

#endregion Rapport d'Activité

# Exporter les fonctions pour pouvoir les importer dans votre profil
Export-ModuleMember -Function Show-GitDashboard, New-GitActivityReport

# Script principal d'utilisation du module
# ----------------------------------------
<#
.SYNOPSIS
    Module de tableau de bord et de rapport d'activité Git pour PowerShell.
.DESCRIPTION
    Ce script permet de générer un tableau de bord visuel de l'état de tous vos dépôts Git
    et de créer des rapports d'activité hebdomadaires détaillés.
.EXAMPLE
    # Afficher le tableau de bord
    Show-GitDashboard

    # Exporter le tableau de bord en HTML
    Show-GitDashboard -ExportToHTML

    # Générer un rapport d'activité pour les 14 derniers jours
    New-GitActivityReport -Days 14

    # Générer un rapport d'activité au format texte pour un auteur spécifique
    New-GitActivityReport -Author "Votre Nom" -Format Text
#>

# Si exécuté directement, afficher le tableau de bord et générer un rapport
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "Bienvenue dans le module de tableau de bord et de rapport d'activité Git" -ForegroundColor $Config.Colors.Header
    Write-Host "Ce module fournit deux fonctions principales:" -ForegroundColor $Config.Colors.Normal
    Write-Host "  - Show-GitDashboard : Affiche l'état de tous vos dépôts Git" -ForegroundColor $Config.Colors.Normal
    Write-Host "  - New-GitActivityReport : Génère un rapport d'activité Git" -ForegroundColor $Config.Colors.Normal
    Write-Host "`nPour plus d'informations, consultez l'aide avec:" -ForegroundColor $Config.Colors.Normal
    Write-Host "  Get-Help Show-GitDashboard -Full" -ForegroundColor $Config.Colors.Normal
    Write-Host "  Get-Help New-GitActivityReport -Full" -ForegroundColor $Config.Colors.Normal

    # Proposer d'exécuter les fonctions
    $showDashboard = Read-Host "`nVoulez-vous afficher le tableau de bord Git? (o/n)"
    if ($showDashboard -eq "o") {
        Show-GitDashboard -ExportToHTML
    }

    $generateReport = Read-Host "`nVoulez-vous générer un rapport d'activité Git? (o/n)"
    if ($generateReport -eq "o") {
        $days = Read-Host "Nombre de jours à inclure dans le rapport (défaut: $($Config.DefaultHistoryDays))"
        if (-not $days) { $days = $Config.DefaultHistoryDays }

        $format = Read-Host "Format du rapport (HTML, Text, CSV) (défaut: $($Config.DefaultReportFormat))"
        if (-not $format) { $format = $Config.DefaultReportFormat }

        New-GitActivityReport -Days $days -Format $format
    }
}
```

## Comment utiliser ce module

Ce module offre deux fonctionnalités principales :

1. **Tableau de bord Git** : Visualisez l'état de tous vos dépôts Git en un coup d'œil
2. **Rapport d'activité Git** : Générez des rapports détaillés sur votre activité Git récente

### Installation

1. Copiez le script complet dans un fichier nommé `GitDashboard.psm1`
2. Créez un dossier nommé `GitDashboard` dans un des emplacements de votre `$env:PSModulePath`
3. Placez le fichier `GitDashboard.psm1` dans ce dossier
4. Importez le module en utilisant `Import-Module GitDashboard`

Alternativement, vous pouvez exécuter directement le script pour une utilisation ponctuelle.

### Configuration

Avant d'utiliser le module, personnalisez la configuration dans la section `#region Configuration` :

```powershell
$script:Config = @{
    # Ajoutez ici vos propres chemins de dépôts Git
    GitReposPaths = @(
        "$HOME\Projects",
        "$HOME\Documents\GitHub",
        # Ajoutez vos chemins personnalisés
    )

    # Autres paramètres personnalisables...
}
```

### Utilisation du tableau de bord Git

```powershell
# Afficher le tableau de bord dans la console
Show-GitDashboard

# Générer un tableau de bord HTML et l'ouvrir dans votre navigateur
Show-GitDashboard -ExportToHTML

# Spécifier des chemins personnalisés
Show-GitDashboard -BasePaths @("C:\Dev\Projects", "D:\Work\Repos")

# Définir un chemin de sortie personnalisé
Show-GitDashboard -ExportToHTML -OutputPath "C:\Reports\GitDashboard.html"
```

### Génération de rapports d'activité Git

```powershell
# Générer un rapport d'activité pour les 7 derniers jours (par défaut)
New-GitActivityReport

# Rapport pour les 14 derniers jours
New-GitActivityReport -Days 14

# Rapport pour un auteur spécifique
New-GitActivityReport -Author "Votre Nom"

# Définir un format spécifique (HTML, Text, CSV)
New-GitActivityReport -Format Text

# Rapport pour des dépôts spécifiques
New-GitActivityReport -RepositoryPaths @("C:\Projet1", "C:\Projet2")

# Combinaison d'options
New-GitActivityReport -Days 30 -Author "Votre Nom" -Format HTML -OutputPath "C:\Reports\MonRapport.html"
```

## Fonctionnalités avancées

### Intégration avec le profil PowerShell

Ajoutez ces lignes à votre profil PowerShell pour un accès rapide aux fonctions :

```powershell
# Charger le module Git Dashboard
Import-Module GitDashboard

# Créer des alias pour un accès rapide
New-Alias -Name gdb -Value Show-GitDashboard
New-Alias -Name gra -Value New-GitActivityReport

# Fonction pour un rapport hebdomadaire rapide
function Get-WeeklyGitReport {
    $date = Get-Date -Format "yyyy-MM-dd"
    New-GitActivityReport -Days 7 -Format HTML -OutputPath "$HOME\GitReports\Weekly_$date.html"
}
```

### Automatisation des rapports

Vous pouvez utiliser le Planificateur de tâches Windows pour générer automatiquement des rapports hebdomadaires :

1. Créez un script PowerShell `WeeklyGitReport.ps1` :

```powershell
Import-Module GitDashboard
$date = Get-Date -Format "yyyy-MM-dd"
New-GitActivityReport -Days 7 -Format HTML -OutputPath "C:\GitReports\Weekly_$date.html"
```

2. Créez une tâche planifiée qui exécute ce script chaque lundi matin :
   - Programme : `powershell.exe`
   - Arguments : `-ExecutionPolicy Bypass -File "C:\Scripts\WeeklyGitReport.ps1"`

## Conseils d'utilisation

1. **Personnalisez les chemins de recherche** pour inclure tous vos dépôts Git
2. **Ajoutez des fonctions personnalisées** pour des rapports spécifiques à vos projets
3. **Intégrez ces rapports à votre workflow** en les envoyant par email ou en les publiant sur un serveur interne
4. **Utilisez les données de retour** pour alimenter d'autres rapports ou systèmes

## Conclusion

Ce module de tableau de bord Git et de rapport d'activité vous permet de :

- Visualiser rapidement l'état de tous vos dépôts Git
- Identifier les dépôts nécessitant votre attention
- Suivre votre activité de développement sur une période donnée
- Générer des rapports professionnels de votre activité Git
- Automatiser la surveillance et le reporting de votre environnement Git

En intégrant ces outils à votre workflow quotidien, vous améliorerez votre productivité et la visibilité sur votre travail de développement.

N'hésitez pas à personnaliser et étendre ces scripts pour répondre à vos besoins spécifiques !
