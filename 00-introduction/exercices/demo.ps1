##############################################################################
#
# 🧠 Formation PowerShell - Script de démonstration Module 1
#
# Ce script illustre les notions abordées dans le Module 1 :
# - Découverte de PowerShell
# - Utilisation de la console et VS Code
# - Utilisation de l'aide intégrée
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

     Module 1 - Script de démonstration
"@

Write-Host $scriptTitle -ForegroundColor Blue
Write-Host "`nCe script interactif démontre les concepts du Module 1" -ForegroundColor White
Write-Host "Suivez les instructions à l'écran pour découvrir PowerShell" -ForegroundColor White
Start-Sleep -Seconds 2

#----------------------------------------------------------
# SECTION 1: Information sur la version de PowerShell
#----------------------------------------------------------
Show-Title "1-3. Versions de PowerShell"

# Récupération et affichage des informations de version
$psVersion = $PSVersionTable.PSVersion
$psEdition = $PSVersionTable.PSEdition
$platform = $PSVersionTable.Platform
$os = $PSVersionTable.OS

Write-Host "`nVotre version de PowerShell :" -ForegroundColor Green
Write-Host "- Version : $psVersion"
Write-Host "- Édition : $psEdition"
Write-Host "- Plateforme : $platform"
Write-Host "- Système d'exploitation : $os"

# Affichage du type d'édition (Windows PowerShell ou PowerShell Core/7+)
if ($psVersion.Major -le 5) {
    Write-Host "`nVous utilisez " -NoNewline
    Write-Host "Windows PowerShell" -ForegroundColor Yellow -NoNewline
    Write-Host ", la version classique de PowerShell qui est spécifique à Windows."
} else {
    Write-Host "`nVous utilisez " -NoNewline
    Write-Host "PowerShell $psVersion" -ForegroundColor Green -NoNewline
    Write-Host ", la version cross-platform open-source."
}

Pause-Demo

#----------------------------------------------------------
# SECTION 2: Exemples d'utilisation de la console
#----------------------------------------------------------
Show-Title "1-5. Utilisation de la console PowerShell"

# Démonstration des commandes de base
Write-Host "`nVoici quelques commandes de base dans PowerShell :" -ForegroundColor Green

Write-Host "`n1. Affichage de la date et l'heure actuelle :" -ForegroundColor Yellow
$currentDate = Get-Date
Write-Host "   La date et l'heure actuelles sont : $currentDate"

Write-Host "`n2. Affichage des processus en cours (top 5 par utilisation CPU) :" -ForegroundColor Yellow
Write-Host "   (Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5)"
Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5 | Format-Table ID, ProcessName, CPU, WorkingSet -AutoSize

Write-Host "`n3. Affichage des services en cours d'exécution (quelques exemples) :" -ForegroundColor Yellow
Write-Host "   (Get-Service | Where-Object Status -eq 'Running' | Select-Object -First 5)"
Get-Service | Where-Object Status -eq 'Running' | Select-Object -First 5 | Format-Table DisplayName, Status -AutoSize

Pause-Demo

#----------------------------------------------------------
# SECTION 3: Démonstration de l'aide intégrée
#----------------------------------------------------------
Show-Title "1-6. Utilisation de l'aide intégrée"

Write-Host "`nPowerShell possède un système d'aide intégré complet." -ForegroundColor Green
Write-Host "Voici une démonstration des 3 commandes essentielles :" -ForegroundColor Green

# Démonstration de Get-Command
Write-Host "`n1. Get-Command - Pour trouver des commandes" -ForegroundColor Yellow
Write-Host "   Exemple : Recherche des commandes contenant 'Process'" -ForegroundColor Gray
Write-Host "   (Get-Command -Name *Process*)" -ForegroundColor Gray

$processCommands = Get-Command -Name *Process* -CommandType Cmdlet
Write-Host "   Résultat : $($processCommands.Count) commandes trouvées"
$processCommands | Select-Object -First 5 | Format-Table Name, CommandType -AutoSize

# Démonstration de Get-Help
Write-Host "`n2. Get-Help - Pour comprendre une commande" -ForegroundColor Yellow
Write-Host "   Exemple : Aide basique pour Get-Process" -ForegroundColor Gray
Write-Host "   (Get-Help Get-Process -Examples | Select-Object -First 2)" -ForegroundColor Gray

$helpExamples = Get-Help Get-Process -Examples
Write-Host "   Résultat : $($helpExamples.Examples.Example.Count) exemples disponibles au total"
Write-Host "   Premier exemple :" -ForegroundColor Gray
Write-Host "   $($helpExamples.Examples.Example[0].Code)" -ForegroundColor White
Write-Host "   $($helpExamples.Examples.Example[0].Remarks.Text)" -ForegroundColor Gray

# Démonstration de Get-Member
Write-Host "`n3. Get-Member - Pour explorer les propriétés et méthodes" -ForegroundColor Yellow
Write-Host "   Exemple : Propriétés d'un processus" -ForegroundColor Gray
Write-Host "   (Get-Process | Get-Member -MemberType Property | Select-Object -First 5)" -ForegroundColor Gray

$processMemberProperties = Get-Process | Get-Member -MemberType Property
Write-Host "   Résultat : $($processMemberProperties.Count) propriétés disponibles"
$processMemberProperties | Select-Object -First 5 | Format-Table Name, Definition -AutoSize

Pause-Demo

#----------------------------------------------------------
# SECTION 4: Exemple de solution avec PowerShell
#----------------------------------------------------------
Show-Title "Application pratique des concepts"

Write-Host "`nVoici un exemple qui combine plusieurs concepts :" -ForegroundColor Green
Write-Host "Création d'un rapport système simple" -ForegroundColor Green

# Collecte d'informations système
Write-Host "`nCollecte des informations système..." -ForegroundColor Yellow
$computerInfo = Get-ComputerInfo | Select-Object CsName, OsName, OsVersion, CsProcessors, CsTotalPhysicalMemory
$diskInfo = Get-PSDrive -PSProvider FileSystem | Where-Object Used -ne $null

# Création du rapport
$reportFolder = "$env:USERPROFILE\Documents\PowerShellDemo"
$reportFile = "$reportFolder\SystemReport.txt"

Write-Host "Création d'un rapport à $reportFile" -ForegroundColor Yellow

# Création du dossier s'il n'existe pas
if (-not (Test-Path -Path $reportFolder)) {
    New-Item -Path $reportFolder -ItemType Directory | Out-Null
    Write-Host "Dossier créé : $reportFolder" -ForegroundColor Gray
}

# Création du rapport
"RAPPORT SYSTÈME GÉNÉRÉ PAR POWERSHELL" | Out-File -FilePath $reportFile
"Date de génération : $(Get-Date)" | Out-File -FilePath $reportFile -Append
"" | Out-File -FilePath $reportFile -Append
"INFORMATIONS SYSTÈME" | Out-File -FilePath $reportFile -Append
"------------------" | Out-File -FilePath $reportFile -Append
"Nom de l'ordinateur : $($computerInfo.CsName)" | Out-File -FilePath $reportFile -Append
"Système d'exploitation : $($computerInfo.OsName)" | Out-File -FilePath $reportFile -Append
"Version : $($computerInfo.OsVersion)" | Out-File -FilePath $reportFile -Append
"Processeur : $($computerInfo.CsProcessors.Name)" | Out-File -FilePath $reportFile -Append
"Mémoire physique : $([math]::Round($computerInfo.CsTotalPhysicalMemory / 1GB, 2)) GB" | Out-File -FilePath $reportFile -Append
"" | Out-File -FilePath $reportFile -Append
"ESPACE DISQUE" | Out-File -FilePath $reportFile -Append
"------------" | Out-File -FilePath $reportFile -Append

foreach ($disk in $diskInfo) {
    $usedSpace = [math]::Round($disk.Used / 1GB, 2)
    $freeSpace = [math]::Round($disk.Free / 1GB, 2)
    $totalSpace = $usedSpace + $freeSpace
    $percentUsed = [math]::Round(($usedSpace / $totalSpace) * 100, 2)

    "Lecteur $($disk.Name) :" | Out-File -FilePath $reportFile -Append
    "  - Espace total : $totalSpace GB" | Out-File -FilePath $reportFile -Append
    "  - Espace utilisé : $usedSpace GB ($percentUsed%)" | Out-File -FilePath $reportFile -Append
    "  - Espace libre : $freeSpace GB" | Out-File -FilePath $reportFile -Append
}

# Top 5 des processus par utilisation mémoire
"" | Out-File -FilePath $reportFile -Append
"TOP 5 DES PROCESSUS (PAR UTILISATION MÉMOIRE)" | Out-File -FilePath $reportFile -Append
"---------------------------------------" | Out-File -FilePath $reportFile -Append

$topProcesses = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5
foreach ($process in $topProcesses) {
    $memoryUsed = [math]::Round($process.WorkingSet / 1MB, 2)
    "$($process.Name) (ID: $($process.Id)) - Mémoire: $memoryUsed MB" | Out-File -FilePath $reportFile -Append
}

# Affichage du contenu du rapport
Write-Host "`nRapport créé avec succès. Voici un aperçu :" -ForegroundColor Green
Get-Content -Path $reportFile | Select-Object -First 15 | ForEach-Object {
    Write-Host "   $_" -ForegroundColor White
}
Write-Host "   [...]" -ForegroundColor Gray

Write-Host "`nRapport complet disponible ici : $reportFile" -ForegroundColor Yellow

#----------------------------------------------------------
# SECTION 5: Fin et résumé
#----------------------------------------------------------
Show-Title "Résumé du Module 1"

Write-Host @"
`nCe script a illustré les concepts clés du Module 1 :

✅ Vérification de la version de PowerShell (1-3)
✅ Utilisation de commandes de base dans la console (1-5)
✅ Utilisation de l'aide intégrée avec Get-Command, Get-Help et Get-Member (1-6)
✅ Application pratique : création d'un rapport système simple

N'hésitez pas à explorer ce script, à le modifier et à l'adapter pour vos besoins !
"@ -ForegroundColor White

Write-Host "`nFin du script de démonstration." -ForegroundColor Green
Write-Host "Au revoir et bonne continuation avec PowerShell!" -ForegroundColor Green
