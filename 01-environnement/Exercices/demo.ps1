##############################################################################
#
# 🧠 Formation PowerShell - Script de démonstration Module 2
#
# Ce script illustre les notions abordées dans le Module 2 :
# - Fichier de profil
# - Customisation du prompt
# - Historique des commandes
# - Modules utiles
# - PowerShell Gallery
#
# Auteur: Formation PowerShell Débutant à Expert
# Date: Avril 2025
#
##############################################################################

Clear-Host

# Fonction pour créer un titre de section dans la console
function Show-Title {
    param([string]$Title)

    Write-Host "`n`n============================================================" -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

# Fonction pour faire une pause
function Pause-Demo {
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Clear-Host
}

# Affichage du titre principal du script
$scriptTitle = @"
  _____                       _____ _          _ _
 |  __ \                     / ____| |        | | |
 | |__) |____      _____ _ _| (___ | |__   ___| | |
 |  ___/ _ \ \ /\ / / _ \ '__\___ \| '_ \ / _ \ | |
 | |  | (_) \ V  V /  __/ |  ____) | | | |  __/ | |
 |_|   \___/ \_/\_/ \___|_| |_____/|_| |_|\___|_|_|

     Module 2 - Script de démonstration
"@

Write-Host $scriptTitle -ForegroundColor Blue
Write-Host "`nCe script interactif démontre les concepts du Module 2" -ForegroundColor White
Write-Host "Suivez les instructions à l'écran pour découvrir la personnalisation de PowerShell" -ForegroundColor White
Start-Sleep -Seconds 2

#----------------------------------------------------------
# SECTION 1: Fichier de profil ($PROFILE)
#----------------------------------------------------------
Show-Title "2-1. Fichier de profil (`$PROFILE)"

# Vérifier l'existence du profil
$profileExists = Test-Path -Path $PROFILE
$profileSize = if ($profileExists) { (Get-Item $PROFILE).Length } else { 0 }

Write-Host "`nInformation sur votre profil PowerShell :" -ForegroundColor Green
Write-Host "- Chemin du profil : $PROFILE"
Write-Host "- Le profil existe : " -NoNewline
if ($profileExists) {
    Write-Host "Oui" -ForegroundColor Green
    Write-Host "- Taille : $profileSize octets"
} else {
    Write-Host "Non" -ForegroundColor Red
    Write-Host "- Vous pouvez le créer avec : New-Item -Path `$PROFILE -ItemType File -Force" -ForegroundColor Gray
}

# Afficher les différents types de profils
Write-Host "`nLes différents types de profils disponibles :" -ForegroundColor Green
Write-Host "- Profil utilisateur actuel, hôte actuel : $($PROFILE.CurrentUserCurrentHost)"
Write-Host "- Profil utilisateur actuel, tous hôtes : $($PROFILE.CurrentUserAllHosts)"
Write-Host "- Profil tous utilisateurs, hôte actuel : $($PROFILE.AllUsersCurrentHost)"
Write-Host "- Profil tous utilisateurs, tous hôtes : $($PROFILE.AllUsersAllHosts)"

# Afficher un exemple de contenu pour le profil
Write-Host "`nExemple de contenu pour votre profil :" -ForegroundColor Green
$profileExample = @'
# Mon profil PowerShell personnalisé

# 1. Définir des alias personnalisés
New-Alias -Name ll -Value Get-ChildItem
New-Alias -Name grep -Value Select-String

# 2. Importer des modules utiles
Import-Module PSReadLine
Import-Module Terminal-Icons

# 3. Configurer PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# 4. Fonction pour afficher la date et l'heure
function Get-Timestamp { Get-Date -Format "yyyy-MM-dd HH:mm:ss" }

# 5. Personnaliser le prompt
function prompt {
    $time = Get-Date -Format "HH:mm:ss"
    $location = Get-Location
    $host.UI.RawUI.WindowTitle = "PS $location"
    "[$time] PS $location> "
}

# 6. Message d'accueil
Write-Host "Bonjour $env:USERNAME! PowerShell est prêt." -ForegroundColor Green
Write-Host "Aujourd'hui nous sommes le $(Get-Date -Format 'dddd, dd MMMM yyyy')" -ForegroundColor Cyan
'@

Write-Host $profileExample -ForegroundColor Gray

Pause-Demo

#----------------------------------------------------------
# SECTION 2: Customisation du prompt
#----------------------------------------------------------
Show-Title "2-2. Customisation du prompt (oh-my-posh, PSReadLine)"

# Vérifier si Oh My Posh est installé
$ohMyPoshInstalled = $null -ne (Get-Command -Name 'oh-my-posh' -ErrorAction SilentlyContinue)

Write-Host "`nStatut de Oh My Posh :" -ForegroundColor Green
if ($ohMyPoshInstalled) {
    $ohMyPoshVersion = (oh-my-posh --version).Trim()
    Write-Host "- Oh My Posh est installé (version $ohMyPoshVersion)" -ForegroundColor Green
} else {
    Write-Host "- Oh My Posh n'est pas installé" -ForegroundColor Yellow
    Write-Host "- Vous pouvez l'installer avec : winget install JanDeDobbeleer.OhMyPosh" -ForegroundColor Gray
}

# Démonstration de prompts personnalisés
Write-Host "`nExemples de prompts personnalisés :" -ForegroundColor Green

# Exemple 1: Prompt simple avec heure
$promptExample1 = @'
function prompt {
    $time = Get-Date -Format "HH:mm:ss"
    $location = Get-Location
    "[$time] PS $location> "
}
'@
Write-Host "`n1. Prompt simple avec heure :" -ForegroundColor Yellow
Write-Host $promptExample1 -ForegroundColor Gray
Write-Host "Résultat : " -NoNewline
Write-Host "[14:32:45] PS C:\Users\Utilisateur> " -ForegroundColor DarkGray

# Exemple 2: Prompt avec statut administrateur
$promptExample2 = @'
function prompt {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Write-Host "[ADMIN] " -NoNewLine -ForegroundColor Red
    } else {
        Write-Host "[USER] " -NoNewLine -ForegroundColor Green
    }

    Write-Host "$(Get-Location) " -NoNewLine -ForegroundColor Yellow
    return "$ "
}
'@
Write-Host "`n2. Prompt avec statut administrateur :" -ForegroundColor Yellow
Write-Host $promptExample2 -ForegroundColor Gray
Write-Host "Résultat : " -NoNewline
Write-Host "[USER] " -NoNewline -ForegroundColor Green
Write-Host "C:\Users\Utilisateur " -NoNewline -ForegroundColor Yellow
Write-Host "$ " -ForegroundColor DarkGray

# Exemple 3: Oh My Posh
$promptExample3 = @'
# Dans votre profil PowerShell ($PROFILE)
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\paradox.omp.json" | Invoke-Expression
'@
Write-Host "`n3. Prompt avec Oh My Posh :" -ForegroundColor Yellow
Write-Host $promptExample3 -ForegroundColor Gray
Write-Host "Résultat : Un prompt riche avec icônes, informations Git, etc." -ForegroundColor DarkGray

Pause-Demo

#----------------------------------------------------------
# SECTION 3: Historique et raccourcis clavier
#----------------------------------------------------------
Show-Title "2-3. Historique de commandes et raccourcis clavier"

# Informations sur l'historique
$historyCount = (Get-History).Count
$readlineOptions = if (Get-Module -Name PSReadLine) { Get-PSReadLineOption } else { $null }

Write-Host "`nInformations sur votre historique de commandes :" -ForegroundColor Green
Write-Host "- Nombre de commandes dans l'historique actuel : $historyCount"
if ($readlineOptions) {
    Write-Host "- Taille maximale de l'historique : $($readlineOptions.MaximumHistoryCount)"
    Write-Host "- Historique dupliqué : $($readlineOptions.HistoryNoDuplicates)"
    Write-Host "- Chemin de sauvegarde : $($readlineOptions.HistorySavePath)"
} else {
    Write-Host "- Module PSReadLine non chargé, impossible d'obtenir les options d'historique" -ForegroundColor Yellow
}

# Raccourcis clavier essentiels
$keyboardShortcuts = @(
    @{Shortcut = "Tab"; Action = "Complétion automatique des commandes et chemins"},
    @{Shortcut = "Flèche Haut"; Action = "Naviguer dans l'historique des commandes"},
    @{Shortcut = "Ctrl+r"; Action = "Recherche inverse dans l'historique"},
    @{Shortcut = "Ctrl+l"; Action = "Effacer l'écran"},
    @{Shortcut = "Ctrl+c"; Action = "Annuler la commande en cours"},
    @{Shortcut = "Ctrl+a"; Action = "Aller au début de la ligne"},
    @{Shortcut = "Ctrl+e"; Action = "Aller à la fin de la ligne"},
    @{Shortcut = "Ctrl+←"; Action = "Déplacer le curseur d'un mot vers la gauche"},
    @{Shortcut = "Ctrl+→"; Action = "Déplacer le curseur d'un mot vers la droite"},
    @{Shortcut = "F7"; Action = "Afficher une liste interactive de l'historique"}
)

Write-Host "`nRaccourcis clavier essentiels :" -ForegroundColor Green
$i = 1
foreach ($shortcut in $keyboardShortcuts) {
    Write-Host "$i. " -NoNewline
    Write-Host $shortcut.Shortcut -NoNewline -ForegroundColor Yellow
    Write-Host " : $($shortcut.Action)"
    $i++
}

# Configuration avancée de PSReadLine
$psReadLineConfig = @'
# Configuration de PSReadLine dans votre profil
Import-Module PSReadLine

# Prédiction basée sur l'historique
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# Recherche dans l'historique avec les flèches
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# Effacer l'écran avec Ctrl+l
Set-PSReadLineKeyHandler -Key "Ctrl+l" -Function ClearScreen

# Historique sans doublons
Set-PSReadLineOption -HistoryNoDuplicates

# Sauvegarde de l'historique
$historyFile = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.ps_history'
Set-PSReadLineOption -HistorySavePath $historyFile
'@

Write-Host "`nConfiguration recommandée pour PSReadLine :" -ForegroundColor Green
Write-Host $psReadLineConfig -ForegroundColor Gray

Pause-Demo

#----------------------------------------------------------
# SECTION 4: Modules utiles
#----------------------------------------------------------
Show-Title "2-4. Modules utiles (PSReadLine, posh-git, Terminal-Icons, etc.)"

# Vérifier les modules populaires installés
$popularModules = @(
    "PSReadLine",
    "posh-git",
    "Terminal-Icons",
    "PSScriptAnalyzer",
    "ImportExcel",
    "z"
)

Write-Host "`nVérification des modules populaires sur votre système :" -ForegroundColor Green
foreach ($module in $popularModules) {
    $isInstalled = $null -ne (Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue)
    Write-Host "- $module : " -NoNewline
    if ($isInstalled) {
        $version = (Get-Module -Name $module -ListAvailable).Version | Select-Object -First 1
        Write-Host "Installé (v$version)" -ForegroundColor Green
    } else {
        Write-Host "Non installé" -ForegroundColor Yellow
    }
}

# Description des modules populaires
$moduleDescriptions = @(
    @{Name = "PSReadLine"; Description = "Améliore l'expérience de ligne de commande avec coloration syntaxique, autocomplétion avancée et prédiction."},
    @{Name = "posh-git"; Description = "Intègre des informations Git dans votre prompt et fournit une autocomplétion pour les commandes Git."},
    @{Name = "Terminal-Icons"; Description = "Ajoute des icônes pour les fichiers et dossiers dans l'affichage de Get-ChildItem."},
    @{Name = "PSScriptAnalyzer"; Description = "Analyse statique de code PowerShell pour identifier les problèmes et appliquer les bonnes pratiques."},
    @{Name = "ImportExcel"; Description = "Manipule des fichiers Excel sans avoir besoin d'Excel installé."},
    @{Name = "z"; Description = "Navigation rapide vers les dossiers fréquemment utilisés à l'aide d'un algorithme de fréquence et récence."}
)

Write-Host "`nDescription des modules populaires :" -ForegroundColor Green
foreach ($module in $moduleDescriptions) {
    Write-Host "- " -NoNewline
    Write-Host $module.Name -NoNewline -ForegroundColor Yellow
    Write-Host " : $($module.Description)"
}

# Script d'installation groupée
$installScript = @'
# Script d'installation des modules essentiels
$ModulesEssentiels = @(
    "PSReadLine",
    "Terminal-Icons",
    "posh-git",
    "z"
)

foreach ($Module in $ModulesEssentiels) {
    if (-not (Get-Module -ListAvailable -Name $Module)) {
        Write-Host "Installation du module $Module..." -ForegroundColor Green
        Install-Module -Name $Module -Scope CurrentUser -Force
    } else {
        Write-Host "Le module $Module est déjà installé" -ForegroundColor Yellow
    }
}
'@

Write-Host "`nScript pour installer les modules essentiels :" -ForegroundColor Green
Write-Host $installScript -ForegroundColor Gray

Pause-Demo

#----------------------------------------------------------
# SECTION 5: PowerShell Gallery
#----------------------------------------------------------
Show-Title "2-5. Découverte de la PowerShell Gallery"

# Statistiques de la PowerShell Gallery
$galleryStats = @{
    TotalModules = "10,000+"
    TotalScripts = "5,000+"
    TotalDownloads = "500,000,000+"
    PopularAuthors = "Microsoft, AWS, VMware, communauté..."
}

Write-Host "`nLa PowerShell Gallery en chiffres :" -ForegroundColor Green
Write-Host "- Nombre de modules : $($galleryStats.TotalModules)"
Write-Host "- Nombre de scripts : $($galleryStats.TotalScripts)"
Write-Host "- Téléchargements cumulés : $($galleryStats.TotalDownloads)"
Write-Host "- Principaux auteurs : $($galleryStats.PopularAuthors)"

# Commandes pour interagir avec la PowerShell Gallery
Write-Host "`nCommandes essentielles pour la PowerShell Gallery :" -ForegroundColor Green
Write-Host "1. Recherche de modules :" -ForegroundColor Yellow
Write-Host '   Find-Module -Name "*Azure*"' -ForegroundColor Gray
Write-Host '   Find-Module -Tag "ActiveDirectory"' -ForegroundColor Gray

Write-Host "`n2. Installation de modules :" -ForegroundColor Yellow
Write-Host '   Install-Module -Name "Terminal-Icons" -Scope CurrentUser' -ForegroundColor Gray
Write-Host '   Install-Module -Name "dbatools" -Scope CurrentUser -RequiredVersion 1.0.0' -ForegroundColor Gray

Write-Host "`n3. Mise à jour de modules :" -ForegroundColor Yellow
Write-Host '   Update-Module -Name "PSReadLine"' -ForegroundColor Gray
Write-Host '   Get-InstalledModule | Update-Module' -ForegroundColor Gray

Write-Host "`n4. Recherche de scripts :" -ForegroundColor Yellow
Write-Host '   Find-Script -Name "*backup*"' -ForegroundColor Gray
Write-Host '   Find-Script -Command "Get-SystemInfo"' -ForegroundColor Gray

# Modules populaires par catégorie
$categoryModules = @{
    "Administration système" = @("PSWindowsUpdate", "Carbon", "dbatools")
    "Utilisation quotidienne" = @("ImportExcel", "Posh-SSH", "PSScriptAnalyzer")
    "Cloud" = @("Az", "AWS.Tools", "GoogleCloud", "AzureAD")
    "Sécurité" = @("Pester", "PSRM", "PowerShellProtect", "UniversalDashboard")
}

Write-Host "`nModules populaires par catégorie :" -ForegroundColor Green
foreach ($category in $categoryModules.Keys) {
    Write-Host "`n$category :" -ForegroundColor Yellow
    foreach ($module in $categoryModules[$category]) {
        Write-Host "- $module" -ForegroundColor Gray
    }
}

Pause-Demo

#----------------------------------------------------------
# SECTION 6: Application pratique
#----------------------------------------------------------
Show-Title "Application pratique du Module 2"

Write-Host "`nLet's create a sample customized PowerShell environment!" -ForegroundColor Green
Write-Host "Voici comment appliquer les concepts du Module 2 en pratique :" -ForegroundColor Green

$sampleProfile = @'
# Ce code pourrait être ajouté à votre $PROFILE

# 1. Charger les modules essentiels
$EssentialModules = @("PSReadLine", "Terminal-Icons", "posh-git", "z")
foreach ($Module in $EssentialModules) {
    try {
        Import-Module $Module -ErrorAction Stop
    } catch {
        Write-Warning "Module $Module non trouvé. Utilisez 'Install-Module -Name $Module -Scope CurrentUser' pour l'installer."
    }
}

# 2. Configurer PSReadLine pour une meilleure expérience
if (Get-Module PSReadLine) {
    # Activer prédiction basée sur l'historique (PS 7.1+)
    if ($PSVersionTable.PSVersion.Major -ge 7 -and $PSVersionTable.PSVersion.Minor -ge 1) {
        Set-PSReadLineOption -PredictionSource History
        Set-PSReadLineOption -PredictionViewStyle ListView
    }

    # Recherche intelligente dans l'historique
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

    # Autocomplétion améliorée
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# 3. Définir des alias pratiques
New-Alias -Name ll -Value Get-ChildItem
New-Alias -Name grep -Value Select-String
New-Alias -Name touch -Value New-Item
New-Alias -Name time -Value Measure-Command

# 4. Fonctions utiles
function which($command) {
    Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function weather {
    (Invoke-WebRequest wttr.in).Content
}

function update-profile {
    . $PROFILE
    Write-Host "Profil rechargé !" -ForegroundColor Green
}

# 5. Créer un prompt personnalisé
function prompt {
    # Obtenir l'état de la dernière commande
    $lastSuccess = $?

    # Vérifier si PowerShell est exécuté en tant qu'admin
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    # Obtenir l'heure actuelle
    $time = Get-Date -Format "HH:mm:ss"

    # Mettre à jour le titre de la fenêtre
    $location = Get-Location
    $host.UI.RawUI.WindowTitle = "PS $location"

    # Affichage conditionnel selon le statut
    Write-Host "[$time] " -NoNewline -ForegroundColor Cyan

    if ($isAdmin) {
        Write-Host "[ADMIN] " -NoNewline -ForegroundColor Red
    }

    Write-Host "$location " -NoNewline -ForegroundColor Yellow

    # Afficher un emoji basé sur le succès de la dernière commande
    if ($lastSuccess) {
        Write-Host "✓" -NoNewline -ForegroundColor Green
    } else {
        Write-Host "✗" -NoNewline -ForegroundColor Red
    }

    return " "
}

# 6. Message d'accueil
Write-Host "Bonjour $env:USERNAME!" -ForegroundColor Green
Write-Host "PowerShell v$($PSVersionTable.PSVersion) | $(Get-Date -Format 'dddd, dd MMMM yyyy')" -ForegroundColor Cyan
Write-Host "Type 'help' pour la liste des commandes personnalisées" -ForegroundColor DarkGray
'@

Write-Host "`nVoici un exemple complet de profil personnalisé :" -ForegroundColor Green
Write-Host $sampleProfile -ForegroundColor Gray

#----------------------------------------------------------
# SECTION 7: Fin et résumé
#----------------------------------------------------------
Show-Title "Résumé du Module 2"

Write-Host @"
`nCe script a illustré les concepts clés du Module 2 :

✅ Fichier de profil (`$PROFILE)
✅ Customisation du prompt avec différentes méthodes
✅ Historique de commandes et raccourcis clavier
✅ Modules utiles qui améliorent l'expérience PowerShell
✅ PowerShell Gallery pour installer et mettre à jour des modules

Prochaines étapes recommandées :
1. Créez ou modifiez votre propre profil PowerShell
2. Installez quelques modules utiles
3. Personnalisez votre prompt selon vos préférences
4. Configurez PSReadLine pour une meilleure expérience
5. Explorez la PowerShell Gallery pour découvrir de nouveaux outils

Bonne personnalisation de votre environnement PowerShell !
"@ -ForegroundColor White

Write-Host "`nFin du script de démonstration." -ForegroundColor Green
Write-Host "Au revoir et bonne continuation avec PowerShell!" -ForegroundColor Green
