# Module 3 - Section 3-6 : Scripting : premiers scripts `.ps1`

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📝 Introduction aux scripts PowerShell

Jusqu'à présent, nous avons exécuté des commandes PowerShell directement dans la console. Cependant, pour automatiser des tâches complexes ou réutiliser facilement du code, nous avons besoin de **scripts**. Un script PowerShell est simplement un fichier texte avec l'extension `.ps1` qui contient une série d'instructions PowerShell.

## 🚀 Création de votre premier script

### Étape 1 : Création du fichier

Vous pouvez créer un script PowerShell de plusieurs façons :

**Option 1 : Avec le Bloc-notes (ou un autre éditeur de texte)**
1. Ouvrez le Bloc-notes
2. Écrivez vos commandes PowerShell
3. Enregistrez le fichier avec l'extension `.ps1` (ex: `MonPremierScript.ps1`)

**Option 2 : Avec Visual Studio Code (recommandé)**
1. Installez VS Code et l'extension PowerShell
2. Créez un nouveau fichier (Ctrl+N)
3. Enregistrez-le avec l'extension `.ps1`
4. Profitez de la coloration syntaxique et de l'autocomplétion

**Option 3 : Directement depuis PowerShell**
```powershell
# Créer un fichier script vide
New-Item -Path "C:\Scripts\MonScript.ps1" -ItemType File

# Ouvrir le script dans l'éditeur par défaut
notepad "C:\Scripts\MonScript.ps1"

# Ou avec VS Code si installé
code "C:\Scripts\MonScript.ps1"
```

### Étape 2 : Écriture du script

Voici un exemple de script PowerShell simple :

```powershell
# MonPremierScript.ps1
# Description : Mon premier script PowerShell
# Auteur : Votre Nom
# Date : 26/04/2025

# Afficher un message de bienvenue
Write-Host "Bienvenue dans mon premier script PowerShell !" -ForegroundColor Green

# Récupérer la date actuelle
$date = Get-Date
Write-Host "Nous sommes le $($date.ToShortDateString())"

# Lister les processus qui utilisent le plus de mémoire
Write-Host "Voici les 5 processus qui utilisent le plus de mémoire :" -ForegroundColor Yellow
Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5 |
    Format-Table Name, @{Name="Mémoire (MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}}

# Pause à la fin du script
Write-Host "Appuyez sur une touche pour quitter..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
```

## ▶️ Exécution d'un script PowerShell

### Méthode 1 : Exécution directe depuis PowerShell

```powershell
# Naviguer vers le dossier contenant le script
cd C:\chemin\vers\dossier

# Exécuter le script (en spécifiant le chemin)
.\MonPremierScript.ps1
```

Le `.\` au début est important - il indique à PowerShell d'exécuter le script qui se trouve dans le répertoire courant.

### Méthode 2 : Exécution avec le chemin complet

```powershell
& "C:\chemin\complet\vers\MonPremierScript.ps1"
```

ou

```powershell
Invoke-Expression -Command "C:\chemin\complet\vers\MonPremierScript.ps1"
```

### Méthode 3 : Depuis VS Code

1. Ouvrez le script dans VS Code
2. Appuyez sur F5 ou cliquez sur le bouton de lecture ▶️

## 🔒 Politique d'exécution

Par défaut, Windows restreint l'exécution des scripts PowerShell pour des raisons de sécurité. Vous pourriez rencontrer cette erreur :

```
Le fichier... ne peut pas être chargé car l'exécution de scripts est désactivée sur ce système.
```

Pour vérifier la politique d'exécution actuelle :

```powershell
Get-ExecutionPolicy
```

Pour modifier temporairement la politique d'exécution (pour la session actuelle uniquement) :

```powershell
# Option 1 : Via le bypass
powershell -ExecutionPolicy Bypass -File "C:\chemin\vers\MonScript.ps1"

# Option 2 : Dans la session actuelle
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
```

Pour modifier la politique de façon permanente (nécessite des droits d'administrateur) :

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Les politiques d'exécution les plus courantes sont :
- `Restricted` : Ne permet pas l'exécution de scripts (par défaut)
- `RemoteSigned` : Permet l'exécution des scripts locaux et des scripts téléchargés signés
- `Bypass` : Permet l'exécution de tous les scripts (attention à la sécurité)

> ⚠️ **Important** : Soyez prudent lorsque vous modifiez la politique d'exécution. Ne définissez pas `Bypass` de façon permanente car cela diminue la sécurité de votre système.

## 📊 Structure d'un bon script PowerShell

Un script bien structuré est plus facile à comprendre et à maintenir. Voici une structure recommandée :

```powershell
<#
.SYNOPSIS
    Description brève du script
.DESCRIPTION
    Description détaillée du script
.PARAMETER Param1
    Description du premier paramètre
.EXAMPLE
    .\MonScript.ps1 -Param1 "Valeur"
    Explication de cet exemple
.NOTES
    Nom       : MonScript.ps1
    Auteur    : Votre Nom
    Date      : 26/04/2025
    Version   : 1.0
#>

# Déclaration des paramètres
param(
    [string]$Param1 = "Valeur par défaut",
    [int]$Param2 = 10
)

# Variables globales et constantes
$Global:LogFile = "C:\Logs\MonScript.log"
$MAX_RETRY = 3

# Fonctions
function Write-Log {
    param([string]$Message)
    "$(Get-Date) - $Message" | Out-File -FilePath $Global:LogFile -Append
    Write-Host $Message
}

# Code principal
Write-Log "Script démarré"
Write-Log "Paramètre reçu : $Param1"

# Traitement principal
try {
    # ... Votre code ici ...
    Write-Log "Opération réussie"
}
catch {
    Write-Log "Erreur : $_"
}
finally {
    Write-Log "Script terminé"
}
```

## 📥 Paramètres de script

Les paramètres permettent de passer des valeurs à votre script lors de son exécution.

### Déclaration des paramètres

```powershell
param(
    [string]$Nom = "Monde",
    [int]$Repetitions = 1,
    [switch]$Detaille
)

# Utilisation dans le script
for ($i = 1; $i -le $Repetitions; $i++) {
    Write-Host "Bonjour, $Nom !"
    if ($Detaille) {
        Write-Host "Ceci est le message numéro $i"
    }
}
```

### Appel du script avec des paramètres

```powershell
# Avec des paramètres nommés
.\MonScript.ps1 -Nom "Jean" -Repetitions 3 -Detaille

# Avec des paramètres positionnels (dans l'ordre de déclaration)
.\MonScript.ps1 "Jean" 3 -Detaille

# Avec des paramètres par défaut (on utilise les valeurs par défaut)
.\MonScript.ps1
```

## 🧩 Fonctions dans les scripts

Les fonctions vous permettent d'organiser et de réutiliser votre code.

```powershell
# Définition d'une fonction
function Get-SystemInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME
    )

    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $ComputerName
    $cpu = Get-WmiObject -Class Win32_Processor -ComputerName $ComputerName
    $memory = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName

    # Créer et retourner un objet personnalisé
    [PSCustomObject]@{
        ComputerName = $ComputerName
        OSVersion = $os.Caption
        ServicePack = $os.ServicePackMajorVersion
        FreeMemoryGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        TotalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        CPUName = $cpu.Name
        LastBootTime = $os.ConvertToDateTime($os.LastBootUpTime)
    }
}

# Appel de la fonction dans le script
$info = Get-SystemInfo
Write-Host "Informations système pour $($info.ComputerName) :"
$info | Format-List
```

## 📤 Sortie et retour de valeurs

PowerShell offre plusieurs façons de générer des sorties :

```powershell
# 1. Write-Output (ou simplement écrire la valeur) - devient partie du pipeline
function Get-Double {
    param([int]$Number)
    $Number * 2  # Équivalent à Write-Output ($Number * 2)
}
$resultat = Get-Double 5  # $resultat vaut 10

# 2. Write-Host - affiche à l'écran mais ne peut pas être capturé
Write-Host "Ce message s'affiche à l'écran" -ForegroundColor Green

# 3. Write-Verbose - messages détaillés (visibles seulement avec -Verbose)
Write-Verbose "Information détaillée"  # Ne s'affiche pas par défaut
# Pour voir ces messages : .\MonScript.ps1 -Verbose

# 4. Write-Warning - pour les avertissements
Write-Warning "Attention, cette opération peut prendre du temps"

# 5. Write-Error - pour les erreurs non fatales
Write-Error "Une erreur s'est produite"

# 6. Throw - pour les erreurs fatales (interrompt l'exécution)
throw "Erreur critique, arrêt du script"
```

## 📂 Gestion des chemins dans les scripts

Quelques astuces pour gérer les chemins de fichiers dans vos scripts :

```powershell
# Obtenir le répertoire du script en cours
$scriptPath = $PSScriptRoot
Write-Host "Le script s'exécute depuis: $scriptPath"

# Ou si $PSScriptRoot n'est pas disponible (PowerShell < 3.0)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Combiner des chemins (fonctionne sur tous les OS, y compris Linux/macOS)
$logPath = Join-Path -Path $scriptPath -ChildPath "logs"
$logFile = Join-Path -Path $logPath -ChildPath "script.log"

# Créer un dossier s'il n'existe pas
if (-not (Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory
}
```

## 📋 Bonnes pratiques pour les scripts PowerShell

1. **Commentez votre code** : Documentez votre script avec des commentaires clairs.

2. **Utilisez le bloc d'aide** : Incluez toujours un bloc de commentaires d'aide au début.

3. **Gérez les erreurs** : Utilisez `try/catch` pour traiter les erreurs de manière élégante.

4. **Validez les entrées** : Vérifiez toujours la validité des paramètres reçus.

5. **Nommez clairement vos variables et fonctions** : Utilisez des noms descriptifs.

6. **Évitez les chemins codés en dur** : Préférez les paramètres ou les variables d'environnement.

7. **Utilisez les signatures de scripts** : Pour les environnements d'entreprise, signez vos scripts.

8. **Testez vos scripts** : Vérifiez que votre script fonctionne dans différents scénarios.

9. **Utilisez un style cohérent** : Suivez les conventions de nommage et d'indentation.

10. **Limitez les privilèges** : N'exécutez pas tout en administrateur si ce n'est pas nécessaire.

## 🛠️ Exemples de scripts utiles

### Exemple 1 : Sauvegarde de fichiers

```powershell
<#
.SYNOPSIS
    Script de sauvegarde de fichiers.
.DESCRIPTION
    Ce script copie les fichiers d'un répertoire source vers un répertoire de destination.
.PARAMETER SourcePath
    Chemin du répertoire source.
.PARAMETER DestinationPath
    Chemin du répertoire de destination.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,

    [Parameter(Mandatory=$true)]
    [string]$DestinationPath
)

# Vérifier que les chemins existent
if (-not (Test-Path -Path $SourcePath)) {
    Write-Error "Le répertoire source n'existe pas : $SourcePath"
    exit 1
}

if (-not (Test-Path -Path $DestinationPath)) {
    # Créer le répertoire de destination s'il n'existe pas
    try {
        New-Item -Path $DestinationPath -ItemType Directory -Force
        Write-Host "Répertoire de destination créé : $DestinationPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de créer le répertoire de destination : $_"
        exit 1
    }
}

# Obtenir la date pour le nom du dossier de sauvegarde
$date = Get-Date -Format "yyyy-MM-dd_HH-mm"
$backupFolder = Join-Path -Path $DestinationPath -ChildPath "Backup_$date"

# Créer le dossier de sauvegarde
New-Item -Path $backupFolder -ItemType Directory | Out-Null

# Copier les fichiers
$files = Get-ChildItem -Path $SourcePath -File
$totalFiles = $files.Count
$copiedFiles = 0

foreach ($file in $files) {
    try {
        Copy-Item -Path $file.FullName -Destination $backupFolder
        $copiedFiles++
        Write-Progress -Activity "Copie des fichiers" -Status "$copiedFiles / $totalFiles" -PercentComplete (($copiedFiles / $totalFiles) * 100)
    }
    catch {
        Write-Warning "Impossible de copier le fichier $($file.Name) : $_"
    }
}

Write-Host "Sauvegarde terminée : $copiedFiles fichiers copiés vers $backupFolder" -ForegroundColor Green
```

### Exemple 2 : Surveillance de service

```powershell
<#
.SYNOPSIS
    Surveille et redémarre un service si nécessaire.
.DESCRIPTION
    Ce script vérifie si un service Windows spécifié est en cours d'exécution.
    Si le service est arrêté, le script tente de le démarrer.
.PARAMETER ServiceName
    Nom du service à surveiller.
.PARAMETER LogFile
    Chemin du fichier de log.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ServiceName,

    [string]$LogFile = "C:\Logs\ServiceMonitor.log"
)

function Write-Log {
    param([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host $Message
}

# Vérifier que le dossier de logs existe
$logFolder = Split-Path -Path $LogFile -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

Write-Log "Début de la surveillance du service : $ServiceName"

try {
    $service = Get-Service -Name $ServiceName -ErrorAction Stop

    if ($service.Status -eq "Running") {
        Write-Log "Le service $ServiceName est en cours d'exécution."
    }
    else {
        Write-Log "Le service $ServiceName est à l'état : $($service.Status). Tentative de démarrage..."

        try {
            Start-Service -Name $ServiceName
            Start-Sleep -Seconds 5  # Attendre le démarrage

            $service = Get-Service -Name $ServiceName
            if ($service.Status -eq "Running") {
                Write-Log "Le service $ServiceName a été démarré avec succès."
            }
            else {
                Write-Log "Échec du démarrage du service $ServiceName. Statut actuel : $($service.Status)"
            }
        }
        catch {
            Write-Log "Erreur lors du démarrage du service : $_"
        }
    }
}
catch {
    Write-Log "Erreur lors de la vérification du service : $_"
}

Write-Log "Fin de la surveillance."
```

## ✏️ Exercices pratiques

**Exercice 1 : Script de base**
```powershell
# Créez un script qui affiche :
# - Le nom de votre ordinateur
# - La version de PowerShell
# - La date et l'heure actuelles
# - L'espace disque libre sur le lecteur C:
```

**Exercice 2 : Script avec paramètres**
```powershell
# Créez un script qui accepte deux paramètres :
# - Nom (chaîne)
# - Age (entier)
# Le script doit afficher un message personnalisé et indiquer l'année de naissance approximative.
```

**Exercice 3 : Traitement de fichiers**
```powershell
# Créez un script qui :
# - Accepte un paramètre pour le chemin d'un dossier
# - Compte le nombre de fichiers par extension
# - Affiche un résumé (ex: 10 fichiers .txt, 5 fichiers .jpg, etc.)
```

**Exercice 4 : Automatisation système**
```powershell
# Créez un script qui génère un rapport système incluant :
# - Les 5 processus utilisant le plus de mémoire
# - Les 5 processus utilisant le plus de CPU
# - Les services qui sont arrêtés mais configurés en démarrage automatique
# - Enregistrez ce rapport dans un fichier texte avec la date du jour dans le nom
```

**Exercice 5 : Script avancé**
```powershell
# Créez un script de nettoyage qui :
# - Accepte un paramètre pour le nombre de jours
# - Recherche et affiche tous les fichiers .log, .tmp et .bak plus anciens que le nombre de jours spécifié
# - Demande confirmation avant de les supprimer
# - Journalise les actions dans un fichier de log
```

---

Dans le prochain module, nous allons explorer le modèle objet PowerShell et comment manipuler efficacement les objets pour traiter des données complexes.
