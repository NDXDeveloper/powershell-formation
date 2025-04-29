# Solutions des exercices du Module 3

## Section 3-2 : Variables, typage, tableaux, hashtables

### Exercice 1 : Variables et typage
```powershell
# Créez deux variables typées : une pour votre âge et une pour votre nom
# Affichez une phrase utilisant ces deux variables

[int]$age = 30
[string]$nom = "Jean Dupont"

Write-Host "Bonjour, je m'appelle $nom et j'ai $age ans."
```

### Exercice 2 : Tableaux
```powershell
# Créez un tableau contenant 5 couleurs
# Affichez la première et la dernière couleur
# Ajoutez une nouvelle couleur et affichez le tableau complet

$couleurs = @("Rouge", "Bleu", "Vert", "Jaune", "Orange")

# Affichage de la première et dernière couleur
Write-Host "Première couleur : $($couleurs[0])"
Write-Host "Dernière couleur : $($couleurs[-1])"

# Ajout d'une nouvelle couleur
$couleurs += "Violet"

# Affichage du tableau complet
Write-Host "Tableau complet des couleurs :"
$couleurs
```

### Exercice 3 : Hashtables
```powershell
# Créez une hashtable avec les informations d'un livre (titre, auteur, année)
# Ajoutez une nouvelle propriété "genre"
# Affichez toutes les informations du livre

$livre = @{
    Titre = "Le Petit Prince"
    Auteur = "Antoine de Saint-Exupéry"
    Année = 1943
}

# Ajout d'une nouvelle propriété
$livre["Genre"] = "Conte philosophique"

# Affichage de toutes les informations
Write-Host "Informations sur le livre :"
foreach ($cle in $livre.Keys) {
    Write-Host "$cle : $($livre[$cle])"
}
```

## Section 3-3 : Opérateurs (logiques, arithmétiques, comparaison)

### Exercice 1 : Opérateurs arithmétiques
```powershell
# Calculez l'aire d'un rectangle de longueur 7.5 et de largeur 3.2
# Calculez le périmètre du même rectangle

$longueur = 7.5
$largeur = 3.2

# Calcul de l'aire
$aire = $longueur * $largeur
Write-Host "L'aire du rectangle est de $aire unités carrées."

# Calcul du périmètre
$perimetre = 2 * ($longueur + $largeur)
Write-Host "Le périmètre du rectangle est de $perimetre unités."
```

### Exercice 2 : Opérateurs de comparaison
```powershell
# Créez une variable $temperature avec une valeur de votre choix
# Écrivez une condition qui affiche :
# - "Très froid" si la température est inférieure à 0
# - "Froid" si elle est entre 0 et 15
# - "Agréable" si elle est entre 15 et 25
# - "Chaud" si elle est supérieure à 25

$temperature = 18

if ($temperature -lt 0) {
    Write-Host "Très froid"
} elseif ($temperature -ge 0 -and $temperature -le 15) {
    Write-Host "Froid"
} elseif ($temperature -gt 15 -and $temperature -le 25) {
    Write-Host "Agréable"
} else {
    Write-Host "Chaud"
}
```

### Exercice 3 : Opérateurs logiques
```powershell
# Créez deux variables $estWeekEnd (booléen) et $heure (nombre de 0 à 23)
# Écrivez une condition qui affiche "Temps libre" si :
# - C'est le weekend, OU
# - Ce n'est pas le weekend mais l'heure est avant 9h ou après 18h

$estWeekEnd = $false
$heure = 20

if ($estWeekEnd -or (-not $estWeekEnd -and ($heure -lt 9 -or $heure -gt 18))) {
    Write-Host "Temps libre"
} else {
    Write-Host "Temps de travail"
}
```

## Section 3-4 : Structures de contrôle (if, switch, for, foreach, while)

### Exercice 1 : Structure if-else
```powershell
# Créez un script qui demande l'âge de l'utilisateur et affiche un message différent selon les tranches d'âge :
# - Moins de 18 ans : "Vous êtes mineur"
# - Entre 18 et 65 ans : "Vous êtes majeur"
# - Plus de 65 ans : "Vous êtes retraité"

$age = Read-Host "Quel est votre âge ?"
$age = [int]$age  # Conversion en entier

if ($age -lt 18) {
    Write-Host "Vous êtes mineur"
} elseif ($age -ge 18 -and $age -le 65) {
    Write-Host "Vous êtes majeur"
} else {
    Write-Host "Vous êtes retraité"
}
```

### Exercice 2 : Structure switch
```powershell
# Créez un script qui demande à l'utilisateur un jour de la semaine et affiche si :
# - C'est un jour de semaine (Lundi à Vendredi)
# - C'est le weekend (Samedi et Dimanche)
# - Message spécial pour Mercredi ("Milieu de semaine !")

$jour = Read-Host "Entrez un jour de la semaine"
$jour = $jour.ToLower()  # Conversion en minuscules pour faciliter la comparaison

switch ($jour) {
    "lundi" { Write-Host "C'est un jour de semaine" }
    "mardi" { Write-Host "C'est un jour de semaine" }
    "mercredi" {
        Write-Host "C'est un jour de semaine"
        Write-Host "Milieu de semaine !"
    }
    "jeudi" { Write-Host "C'est un jour de semaine" }
    "vendredi" { Write-Host "C'est un jour de semaine" }
    "samedi" { Write-Host "C'est le weekend" }
    "dimanche" { Write-Host "C'est le weekend" }
    default { Write-Host "Jour non reconnu" }
}
```

### Exercice 3 : Boucle for
```powershell
# Écrivez une boucle qui affiche la table de multiplication du nombre de votre choix (de 1 à 10)

$nombre = 7

Write-Host "Table de multiplication de $nombre :"
for ($i = 1; $i -le 10; $i++) {
    $resultat = $nombre * $i
    Write-Host "$nombre x $i = $resultat"
}
```

### Exercice 4 : Boucle foreach
```powershell
# Créez un tableau de noms de fichiers puis parcourez-le pour afficher :
# - Si le fichier existe sur le disque
# - Sa taille s'il existe

$fichiers = @("C:\Windows\explorer.exe", "C:\fichier_inexistant.txt", "C:\Windows\notepad.exe")

foreach ($fichier in $fichiers) {
    if (Test-Path -Path $fichier) {
        $info = Get-Item -Path $fichier
        $tailleMB = [math]::Round($info.Length / 1MB, 2)
        Write-Host "Le fichier $fichier existe. Taille : $tailleMB MB"
    } else {
        Write-Host "Le fichier $fichier n'existe pas."
    }
}
```

### Exercice 5 : Boucle while
```powershell
# Créez un jeu simple où l'ordinateur génère un nombre aléatoire entre 1 et 100,
# et l'utilisateur doit le deviner. Le script indique si le nombre proposé est trop grand ou trop petit.

$nombreSecret = Get-Random -Minimum 1 -Maximum 101
$essai = 0
$trouve = $false

Write-Host "J'ai pensé à un nombre entre 1 et 100. Devinez-le !"

while (-not $trouve) {
    $essai++

    $proposition = Read-Host "Essai $essai - Votre proposition"
    $proposition = [int]$proposition

    if ($proposition -lt $nombreSecret) {
        Write-Host "Trop petit !"
    } elseif ($proposition -gt $nombreSecret) {
        Write-Host "Trop grand !"
    } else {
        $trouve = $true
        Write-Host "Bravo ! Vous avez trouvé en $essai essais."
    }

    # Option pour limiter le nombre d'essais
    if ($essai -ge 10 -and -not $trouve) {
        Write-Host "Vous avez atteint le nombre maximum d'essais. Le nombre était $nombreSecret."
        break
    }
}
```

## Section 3-5 : Expressions régulières et filtrage

### Exercice 1: Validation simple
```powershell
# Créez une fonction qui vérifie si une chaîne est un code postal français valide (5 chiffres)

function Test-CodePostal {
    param([string]$Code)

    return $Code -match "^\d{5}$"
}

# Tests
$tests = @("75001", "A1234", "123456", "1234", "ABCDE")
foreach ($test in $tests) {
    if (Test-CodePostal -Code $test) {
        Write-Host "$test est un code postal valide."
    } else {
        Write-Host "$test n'est pas un code postal valide."
    }
}
```

### Exercice 2: Extraction d'informations
```powershell
# Pour la chaîne suivante, extrayez le nom du fichier, sa taille et son unité

$info = "Le fichier document.xlsx a une taille de 2.5 MB"

if ($info -match "Le fichier ([\w\.]+) a une taille de (\d+\.?\d*) (\w+)") {
    $fichier = $matches[1]
    $taille = $matches[2]
    $unite = $matches[3]

    Write-Host "Nom du fichier : $fichier"
    Write-Host "Taille : $taille"
    Write-Host "Unité : $unite"
} else {
    Write-Host "Format non reconnu"
}
```

### Exercice 3: Transformation de données
```powershell
# Convertissez ces numéros de téléphone au format "XX XX XX XX XX"

$telephones = @("0612345678", "06 87 65 43 21", "+33712345678")

foreach ($tel in $telephones) {
    # Supprime les espaces et le préfixe international
    $tel = $tel -replace "\s", "" -replace "^\+33", "0"

    # Formatage avec regex
    if ($tel -match "^(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$") {
        $telFormate = "$($matches[1]) $($matches[2]) $($matches[3]) $($matches[4]) $($matches[5])"
        Write-Host "Numéro formaté : $telFormate"
    } else {
        Write-Host "Format invalide : $tel"
    }
}
```

### Exercice 4: Filtrage avancé
```powershell
# Filtrez cette liste pour ne garder que les noms de fichiers valides (lettres, chiffres, extension)

$noms = @("fichier-1.txt", "mon_rapport.docx", "invalid/file.pdf", "script.ps1", "..hidden")

$nomsValides = $noms | Where-Object { $_ -match "^[\w\-\.]+\.\w+$" }

Write-Host "Fichiers valides :"
$nomsValides

Write-Host "`nFichiers invalides :"
$noms | Where-Object { $_ -notin $nomsValides }
```

### Exercice 5: Validation des entrées
```powershell
# Créez une fonction qui vérifie si un mot de passe est suffisamment fort

function Test-StrongPassword {
    param([string]$Password)

    $hasLength = $Password.Length -ge 8
    $hasUpperCase = $Password -cmatch "[A-Z]"
    $hasLowerCase = $Password -cmatch "[a-z]"
    $hasDigit = $Password -match "\d"
    $hasSpecial = $Password -match "[!@#$%^&*()_+]"

    $isStrong = $hasLength -and $hasUpperCase -and $hasLowerCase -and $hasDigit -and $hasSpecial

    if (-not $isStrong) {
        $feedback = "Le mot de passe ne respecte pas les critères suivants :`n"
        if (-not $hasLength) { $feedback += "- Au moins 8 caractères`n" }
        if (-not $hasUpperCase) { $feedback += "- Au moins une lettre majuscule`n" }
        if (-not $hasLowerCase) { $feedback += "- Au moins une lettre minuscule`n" }
        if (-not $hasDigit) { $feedback += "- Au moins un chiffre`n" }
        if (-not $hasSpecial) { $feedback += "- Au moins un caractère spécial (!@#$%^&*()_+)`n" }
        Write-Host $feedback -ForegroundColor Yellow
    }

    return $isStrong
}

# Tests
$passwords = @("password", "Password1", "Pass1!", "p@Ssw0rd!")
foreach ($pwd in $passwords) {
    if (Test-StrongPassword -Password $pwd) {
        Write-Host "Le mot de passe '$pwd' est suffisamment fort." -ForegroundColor Green
    } else {
        Write-Host "Le mot de passe '$pwd' n'est pas suffisamment fort." -ForegroundColor Red
    }
}
```

## Section 3-6 : Scripting : premiers scripts .ps1

### Exercice 1 : Script de base
```powershell
<#
.SYNOPSIS
    Script d'information système de base
.DESCRIPTION
    Ce script affiche des informations de base sur l'ordinateur
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

# Nom de l'ordinateur
$computerName = $env:COMPUTERNAME
Write-Host "Nom de l'ordinateur : $computerName" -ForegroundColor Cyan

# Version de PowerShell
$psVersion = $PSVersionTable.PSVersion
Write-Host "Version de PowerShell : $($psVersion.Major).$($psVersion.Minor).$($psVersion.Build)" -ForegroundColor Cyan

# Date et heure actuelles
$currentDateTime = Get-Date
Write-Host "Date et heure actuelles : $($currentDateTime.ToString('dd/MM/yyyy HH:mm:ss'))" -ForegroundColor Cyan

# Espace disque libre sur le lecteur C:
$diskC = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($diskC.FreeSpace / 1GB, 2)
$totalSpaceGB = [math]::Round($diskC.Size / 1GB, 2)
$freePercent = [math]::Round(($diskC.FreeSpace / $diskC.Size) * 100, 1)

Write-Host "Espace disque libre sur C: : $freeSpaceGB GB / $totalSpaceGB GB ($freePercent%)" -ForegroundColor Cyan
```

### Exercice 2 : Script avec paramètres
```powershell
<#
.SYNOPSIS
    Script de salutation personnalisé
.DESCRIPTION
    Ce script accepte deux paramètres (nom et âge) et affiche un message personnalisé
.PARAMETER Nom
    Le nom de la personne à saluer
.PARAMETER Age
    L'âge de la personne
.EXAMPLE
    .\Exercice2.ps1 -Nom "Marie" -Age 30
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Nom,

    [Parameter(Mandatory=$true)]
    [int]$Age
)

# Affichage du message personnalisé
Write-Host "Bonjour $Nom, ravi de vous rencontrer !" -ForegroundColor Green

# Calcul de l'année de naissance approximative
$anneeActuelle = (Get-Date).Year
$anneeNaissance = $anneeActuelle - $Age

Write-Host "Vous avez $Age ans, donc vous êtes probablement né(e) en $anneeNaissance." -ForegroundColor Yellow

# Message supplémentaire personnalisé selon l'âge
if ($Age -lt 18) {
    Write-Host "Vous êtes encore jeune, profitez de votre jeunesse !" -ForegroundColor Cyan
} elseif ($Age -ge 18 -and $Age -lt 65) {
    Write-Host "Vous êtes dans la fleur de l'âge !" -ForegroundColor Cyan
} else {
    Write-Host "Vous avez acquis beaucoup de sagesse avec les années !" -ForegroundColor Cyan
}
```

### Exercice 3 : Traitement de fichiers
```powershell
<#
.SYNOPSIS
    Script d'analyse d'extensions de fichiers
.DESCRIPTION
    Ce script accepte le chemin d'un dossier et compte le nombre de fichiers par extension
.PARAMETER CheminDossier
    Le chemin du dossier à analyser
.EXAMPLE
    .\Exercice3.ps1 -CheminDossier "C:\Documents"
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path -Path $_ -PathType Container})]
    [string]$CheminDossier
)

# Affichage du dossier analysé
Write-Host "Analyse du dossier : $CheminDossier" -ForegroundColor Cyan

# Récupération de tous les fichiers du dossier
try {
    $fichiers = Get-ChildItem -Path $CheminDossier -File -Recurse -ErrorAction Stop
    Write-Host "Nombre total de fichiers trouvés : $($fichiers.Count)" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de la récupération des fichiers : $_" -ForegroundColor Red
    exit 1
}

# Si aucun fichier n'est trouvé
if ($fichiers.Count -eq 0) {
    Write-Host "Aucun fichier trouvé dans le dossier spécifié." -ForegroundColor Yellow
    exit 0
}

# Comptage des fichiers par extension
$extensions = @{}

foreach ($fichier in $fichiers) {
    $extension = $fichier.Extension.ToLower()

    # Si l'extension est vide
    if ([string]::IsNullOrEmpty($extension)) {
        $extension = "(sans extension)"
    }

    # Incrémentation du compteur pour cette extension
    if ($extensions.ContainsKey($extension)) {
        $extensions[$extension]++
    }
    else {
        $extensions[$extension] = 1
    }
}

# Affichage des résultats
Write-Host "`nRésumé des extensions :" -ForegroundColor Cyan
Write-Host "---------------------" -ForegroundColor Cyan

# Tri des extensions par nombre de fichiers (ordre décroissant)
$extensionsTriees = $extensions.GetEnumerator() | Sort-Object -Property Value -Descending

foreach ($ext in $extensionsTriees) {
    $pourcentage = [math]::Round(($ext.Value / $fichiers.Count) * 100, 1)
    Write-Host "$($ext.Name) : $($ext.Value) fichier(s) ($pourcentage%)" -ForegroundColor White
}

# Affichage des 5 plus gros fichiers
Write-Host "`nLes 5 plus gros fichiers :" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan

$plusGrosFichiers = $fichiers | Sort-Object -Property Length -Descending | Select-Object -First 5

foreach ($fichier in $plusGrosFichiers) {
    $tailleMB = [math]::Round($fichier.Length / 1MB, 2)
    Write-Host "$($fichier.Name) ($tailleMB MB) - $($fichier.FullName)" -ForegroundColor White
}
```

### Exercice 4 : Automatisation système
```powershell
<#
.SYNOPSIS
    Script de rapport système
.DESCRIPTION
    Ce script génère un rapport système incluant les processus et services
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

# Préparation du rapport
$date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$rapportPath = Join-Path -Path (Get-Location) -ChildPath "Rapport_Systeme_$date.txt"

try {
    # Début du rapport
    "=========================================================" | Out-File -FilePath $rapportPath
    "            RAPPORT SYSTÈME - $date" | Out-File -FilePath $rapportPath -Append
    "=========================================================" | Out-File -FilePath $rapportPath -Append
    "" | Out-File -FilePath $rapportPath -Append

    # Informations système
    "INFORMATIONS SYSTÈME" | Out-File -FilePath $rapportPath -Append
    "------------------" | Out-File -FilePath $rapportPath -Append
    "Nom de l'ordinateur : $env:COMPUTERNAME" | Out-File -FilePath $rapportPath -Append
    "Système d'exploitation : $(Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -ExpandProperty Caption)" | Out-File -FilePath $rapportPath -Append
    "Version PowerShell : $($PSVersionTable.PSVersion)" | Out-File -FilePath $rapportPath -Append
    "" | Out-File -FilePath $rapportPath -Append

    # Top 5 des processus par utilisation mémoire
    "TOP 5 DES PROCESSUS PAR UTILISATION MÉMOIRE" | Out-File -FilePath $rapportPath -Append
    "----------------------------------------" | Out-File -FilePath $rapportPath -Append
    $topMemoryProcesses = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5

    foreach ($process in $topMemoryProcesses) {
        $memoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
        "Processus : $($process.Name) (PID : $($process.Id)) - Mémoire : $memoryMB MB" | Out-File -FilePath $rapportPath -Append
    }
    "" | Out-File -FilePath $rapportPath -Append

    # Top 5 des processus par utilisation CPU
    "TOP 5 DES PROCESSUS PAR UTILISATION CPU" | Out-File -FilePath $rapportPath -Append
    "-------------------------------------" | Out-File -FilePath $rapportPath -Append
    $topCPUProcesses = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5

    foreach ($process in $topCPUProcesses) {
        "Processus : $($process.Name) (PID : $($process.Id)) - CPU : $($process.CPU) s" | Out-File -FilePath $rapportPath -Append
    }
    "" | Out-File -FilePath $rapportPath -Append

    # Services arrêtés mais configurés en démarrage automatique
    "SERVICES ARRÊTÉS MAIS CONFIGURÉS EN DÉMARRAGE AUTOMATIQUE" | Out-File -FilePath $rapportPath -Append
    "------------------------------------------------------" | Out-File -FilePath $rapportPath -Append
    $stoppedAutoServices = Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }

    if ($stoppedAutoServices.Count -gt 0) {
        foreach ($service in $stoppedAutoServices) {
            "Service : $($service.DisplayName) ($($service.Name))" | Out-File -FilePath $rapportPath -Append
        }
    } else {
        "Aucun service arrêté configuré en démarrage automatique." | Out-File -FilePath $rapportPath -Append
    }
    "" | Out-File -FilePath $rapportPath -Append

    # Informations disque
    "INFORMATIONS DISQUE" | Out-File -FilePath $rapportPath -Append
    "-----------------" | Out-File -FilePath $rapportPath -Append
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"

    foreach ($disk in $disks) {
        $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB, 2)
        $totalSpaceGB = [math]::Round($disk.Size / 1GB, 2)
        $usedSpaceGB = [math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        $percentFree = [math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)

        "Lecteur : $($disk.DeviceID)" | Out-File -FilePath $rapportPath -Append
        "  - Espace total : $totalSpaceGB GB" | Out-File -FilePath $rapportPath -Append
        "  - Espace utilisé : $usedSpaceGB GB" | Out-File -FilePath $rapportPath -Append
        "  - Espace libre : $freeSpaceGB GB ($percentFree%)" | Out-File -FilePath $rapportPath -Append
    }

    # Fin du rapport
    "=========================================================" | Out-File -FilePath $rapportPath -Append
    "               FIN DU RAPPORT" | Out-File -FilePath $rapportPath -Append
    "=========================================================" | Out-File -FilePath $rapportPath -Append

    # Affichage du succès
    Write-Host "Rapport système généré avec succès : $rapportPath" -ForegroundColor Green
    Write-Host "Ouverture du rapport..."
    Invoke-Item $rapportPath
}
catch {
    Write-Host "Erreur lors de la génération du rapport : $_" -ForegroundColor Red
}
```

### Exercice 5 : Script avancé
```powershell
<#
.SYNOPSIS
    Script de nettoyage de fichiers temporaires
.DESCRIPTION
    Ce script recherche et supprime (avec confirmation) les fichiers temporaires (.log, .tmp et .bak)
    plus anciens qu'un nombre de jours spécifié.
.PARAMETER Jours
    Nombre de jours. Les fichiers plus anciens que ce nombre de jours seront ciblés.
.PARAMETER CheminRecherche
    Chemin où rechercher les fichiers. Par défaut, le dossier temporaire de l'utilisateur.
.EXAMPLE
    .\Exercice5.ps1 -Jours 30
    Recherche les fichiers de plus de 30 jours dans le dossier temporaire.
.EXAMPLE
    .\Exercice5.ps1 -Jours 15 -CheminRecherche "D:\Logs"
    Recherche les fichiers de plus de 15 jours dans le dossier D:\Logs.
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

param(
    [Parameter(Mandatory=$true)]
    [int]$Jours,

    [Parameter(Mandatory=$false)]
    [string]$CheminRecherche = "$env:TEMP"
)

# Création du fichier de log
$logFolder = Join-Path -Path (Get-Location) -ChildPath "Logs"
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

$date = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$logFile = Join-Path -Path $logFolder -ChildPath "Nettoyage_$date.log"

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host $Message
}

# Vérification du chemin de recherche
if (-not (Test-Path -Path $CheminRecherche)) {
    Write-Log "Le chemin de recherche spécifié n'existe pas : $CheminRecherche"
    exit 1
}

# Date limite
$dateLimite = (Get-Date).AddDays(-$Jours)
Write-Log "Recherche des fichiers antérieurs à $($dateLimite.ToString('dd/MM/yyyy'))"
Write-Log "Chemin de recherche : $CheminRecherche"

# Recherche des fichiers
try {
    $extensions = @("*.log", "*.tmp", "*.bak")
    Write-Log "Recherche des fichiers avec les extensions : $($extensions -join ', ')"

    $fichiers = @()
    foreach ($extension in $extensions) {
        $fichiers += Get-ChildItem -Path $CheminRecherche -Filter $extension -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { $_.LastWriteTime -lt $dateLimite }
    }

    $totalCount = $fichiers.Count
    $totalSize = ($fichiers | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)

    Write-Log "Nombre de fichiers trouvés : $totalCount"
    Write-Log "Taille totale : $totalSizeMB MB"

    # Affichage des 10 premiers fichiers pour exemple
    if ($totalCount -gt 0) {
        Write-Log "`nListe des 10 premiers fichiers trouvés :"
        $i = 0
        foreach ($fichier in ($fichiers | Select-Object -First 10)) {
            $i++
            $tailleMB = [math]::Round($fichier.Length / 1MB, 2)
            $age = [math]::Round(((Get-Date) - $fichier.LastWriteTime).TotalDays, 0)
            Write-Log "  $i. $($fichier.FullName) - $tailleMB MB - $age jours"
        }

        if ($totalCount -gt 10) {
            Write-Log "  ... et $($totalCount - 10) autres fichiers."
        }

        # Demande de confirmation
        $confirmation = Read-Host "`nVoulez-vous supprimer ces $totalCount fichiers ? (O/N)"

        if ($confirmation -eq "O" -or $confirmation -eq "o") {
            Write-Log "Suppression des fichiers en cours..."
            $supprimés = 0
            $erreurs = 0

            foreach ($fichier in $fichiers) {
                try {
                    Remove-Item -Path $fichier.FullName -Force
                    $supprimés++

                    # Affichage de la progression tous les 10 fichiers
                    if ($supprimés % 10 -eq 0) {
                        Write-Progress -Activity "Suppression des fichiers" -Status "$supprimés / $totalCount" `
                                      -PercentComplete (($supprimés / $totalCount) * 100)
                    }
                }
                catch {
                    $erreurs++
                    Write-Log "ERREUR : Impossible de supprimer $($fichier.FullName) : $_"
                }
            }

            Write-Progress -Activity "Suppression des fichiers" -Completed

            Write-Log "`nRésumé de la suppression :"
            Write-Log "  - Fichiers supprimés avec succès : $supprimés"
            Write-Log "  - Erreurs de suppression : $erreurs"
            Write-Log "  - Espace libéré : $totalSizeMB MB"
        }
        else {
            Write-Log "Opération annulée par l'utilisateur."
        }
    }
    else {
        Write-Log "Aucun fichier à supprimer correspondant aux critères."
    }
}
catch {
    Write-Log "Erreur lors de la recherche des fichiers : $_"
    exit 1
}

Write-Log "Opération terminée. Journal sauvegardé dans : $logFile"
```

## Notes sur les solutions d'exercices

### Principes appliqués dans les solutions

1. **Structure et organisation** :
   - Tous les scripts avancés incluent un bloc de commentaires d'aide au début (Section 3-6)
   - Utilisation de fonctions pour modulariser le code quand nécessaire
   - Respect des conventions de nommage PowerShell (verbe-nom pour les fonctions)

2. **Gestion des erreurs** :
   - Utilisation de `try/catch` pour capturer et traiter les erreurs
   - Validation des entrées utilisateur
   - Vérification de l'existence des chemins avant de les utiliser

3. **Paramètres et variables** :
   - Utilisation de paramètres avec validation pour rendre les scripts plus flexibles
   - Variables typées quand c'est pertinent pour la clarté
   - Utilisation de variables descriptives

4. **Affichage et retour d'information** :
   - Messages colorés pour une meilleure lisibilité
   - Journalisation dans des fichiers pour les opérations critiques
   - Barre de progression pour les opérations longues

5. **Bonnes pratiques PowerShell** :
   - Utilisation des alias standard de PowerShell dans les exercices simples
   - Préférence pour les noms complets des cmdlets dans les scripts complexes
   - Utilisation des pipelines pour traiter efficacement les données

### Comment adapter ces exemples

Ces exemples peuvent être adaptés à vos besoins spécifiques en :

1. **Modifiant les paramètres** : Ajustez les valeurs par défaut, ajoutez de nouveaux paramètres ou rendez-les optionnels selon vos besoins.

2. **Étendant les fonctionnalités** : Les scripts peuvent servir de base pour des fonctionnalités plus avancées.

3. **Intégrant dans des modules** : Les fonctions peuvent être placées dans des modules PowerShell pour être réutilisées dans plusieurs scripts.

4. **Automatisant avec des tâches planifiées** : Les scripts peuvent être configurés pour s'exécuter automatiquement à des intervalles définis via le Planificateur de tâches Windows.

### Conseils de débogage

Si vous rencontrez des problèmes avec ces scripts :

1. Ajoutez l'option `-Verbose` lors de l'exécution pour voir plus de détails.
2. Utilisez `Write-Debug` pour ajouter des points de débogage dans vos scripts.
3. Testez les scripts sur des petits ensembles de données avant de les utiliser sur de grandes quantités de données.
4. Utilisez VS Code avec l'extension PowerShell pour un débogage plus visuel et interactif.
