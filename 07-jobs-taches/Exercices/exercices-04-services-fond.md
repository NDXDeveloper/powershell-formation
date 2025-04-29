# Solutions aux exercices - Module 8-4
## Création de services de fond en PowerShell

Voici les solutions détaillées pour les trois exercices proposés dans le module 8-4 concernant la création de services de fond en PowerShell.

### Solution de l'exercice 1: Service d'horodatage

**Objectif**: Créer un service qui écrit la date et l'heure actuelles dans un fichier journal toutes les 5 minutes.

#### Étape 1: Créer le script TimeLogger.ps1

```powershell
# TimeLogger.ps1
# Un service simple qui enregistre la date et l'heure toutes les 5 minutes

# Configuration des chemins
$logFolder = "C:\Logs\TimeLogger"
$dataFolder = "C:\Data\TimeLogger"

# Créer les dossiers nécessaires
foreach ($folder in @($logFolder, $dataFolder)) {
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Démarrer la journalisation du service
Start-Transcript -Path "$logFolder\ServiceLog_$(Get-Date -Format 'yyyyMMdd').log" -Append

Write-Output "Service TimeLogger démarré à $(Get-Date)"

# Fonction pour enregistrer l'horodatage
function Write-TimeStamp {
    $currentTime = Get-Date
    $formattedTime = $currentTime.ToString("yyyy-MM-dd HH:mm:ss")
    $timeStampFile = "$dataFolder\TimeStamp_$(Get-Date -Format 'yyyyMMdd').log"

    # Ajouter l'horodatage au fichier
    "$formattedTime - Le service est actif" | Out-File -FilePath $timeStampFile -Append

    # Journaliser l'action
    Write-Output "Horodatage enregistré à $formattedTime"

    # Nettoyer les anciens fichiers (optionnel, conserve les 7 derniers jours)
    $cutoffDate = (Get-Date).AddDays(-7)
    Get-ChildItem -Path $dataFolder -Filter "TimeStamp_*.log" |
        Where-Object { $_.CreationTime -lt $cutoffDate } |
        Remove-Item -Force
}

# Boucle principale
try {
    while ($true) {
        # Enregistrer l'horodatage actuel
        Write-TimeStamp

        # Attendre 5 minutes (300 secondes)
        Write-Output "En attente de 5 minutes..."
        Start-Sleep -Seconds 300
    }
}
catch {
    # Journaliser toute erreur
    Write-Output "ERREUR : $($_.Exception.Message)"
    Write-Output $_.ScriptStackTrace
}
finally {
    # S'assurer que la journalisation est bien arrêtée
    Write-Output "Service TimeLogger arrêté à $(Get-Date)"
    Stop-Transcript
}
```

#### Étape 2: Créer un fichier batch pour lancer le script

Créez un fichier `LaunchTimeLogger.bat`:

```batch
@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\TimeLogger.ps1"
```

#### Étape 3: Installer le service avec NSSM

Ouvrez une invite de commande en tant qu'administrateur:

```cmd
nssm.exe install "TimeLoggerService" "C:\Scripts\LaunchTimeLogger.bat"
```

Configurez les détails dans l'interface de NSSM:
- **Onglet Application**:
  - Path: `C:\Scripts\LaunchTimeLogger.bat`
  - Startup directory: `C:\Scripts`
- **Onglet Details**:
  - Display name: Service d'Horodatage
  - Description: Enregistre la date et l'heure toutes les 5 minutes
  - Startup type: Automatic
- **Onglet I/O**:
  - Output (stdout): `C:\Logs\TimeLogger\stdout.log`
  - Error (stderr): `C:\Logs\TimeLogger\stderr.log`

Cliquez sur "Install service".

#### Étape 4: Tester le service

Démarrez le service et vérifiez son fonctionnement:

```powershell
# Démarrer le service
Start-Service -Name "TimeLoggerService"

# Vérifier l'état du service
Get-Service -Name "TimeLoggerService"

# Après quelques minutes, vérifier les fichiers créés
Get-ChildItem -Path "C:\Data\TimeLogger"
Get-Content -Path "C:\Data\TimeLogger\TimeStamp_$(Get-Date -Format 'yyyyMMdd').log" -Tail 5
```

---

### Solution de l'exercice 2: Moniteur de ressources système

**Objectif**: Créer un service qui surveille l'utilisation du CPU et de la mémoire et envoie une alerte si l'utilisation dépasse un certain seuil.

#### Étape 1: Créer le script SystemMonitor.ps1

```powershell
# SystemMonitor.ps1
# Service qui surveille l'utilisation du CPU et de la mémoire et génère des alertes

# Configuration
$logFolder = "C:\Logs\SystemMonitor"
$alertFolder = "C:\Alerts\SystemMonitor"
$cpuThreshold = 80  # Seuil d'alerte CPU en pourcentage
$memoryThreshold = 85  # Seuil d'alerte mémoire en pourcentage
$checkInterval = 60  # Intervalle de vérification en secondes
$cooldownPeriod = 300  # Période de refroidissement entre alertes (5 minutes)

# Créer les dossiers nécessaires
foreach ($folder in @($logFolder, $alertFolder)) {
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Démarrer la journalisation
Start-Transcript -Path "$logFolder\ServiceLog_$(Get-Date -Format 'yyyyMMdd').log" -Append

Write-Output "Service de surveillance système démarré à $(Get-Date)"

# Variables pour suivre les alertes
$lastCpuAlert = [DateTime]::MinValue
$lastMemoryAlert = [DateTime]::MinValue

# Fonction pour obtenir l'utilisation CPU
function Get-CpuUsage {
    try {
        $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 1
        $cpuUsage = [math]::Round($cpuCounter.CounterSamples.CookedValue, 2)
        return $cpuUsage
    }
    catch {
        Write-Output "Erreur lors de la récupération de l'utilisation CPU: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour obtenir l'utilisation de la mémoire
function Get-MemoryUsage {
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $usedMemory = $osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory
        $memoryUsage = [math]::Round(($usedMemory / $osInfo.TotalVisibleMemorySize) * 100, 2)
        return $memoryUsage
    }
    catch {
        Write-Output "Erreur lors de la récupération de l'utilisation mémoire: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour créer une alerte
function Create-Alert {
    param (
        [string]$Type,
        [double]$Value,
        [double]$Threshold
    )

    $currentTime = Get-Date
    $alertFileName = "$Type`_Alert_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $alertFilePath = Join-Path $alertFolder $alertFileName

    # Contenu de l'alerte
    $alertContent = @"
ALERTE: Utilisation $Type élevée
----------------------------------------
Date et heure: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Serveur: $env:COMPUTERNAME
Type d'alerte: Utilisation $Type élevée
Valeur actuelle: $Value%
Seuil d'alerte: $Threshold%
----------------------------------------
Informations système:
CPU: $(Get-CpuUsage)%
Mémoire: $(Get-MemoryUsage)%
Uptime: $((Get-Date) - (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime)
"@

    # Enregistrer l'alerte dans un fichier
    $alertContent | Out-File -FilePath $alertFilePath -Encoding UTF8

    Write-Output "ALERTE $Type créée: $alertFilePath (Valeur actuelle: $Value%, Seuil: $Threshold%)"

    # En cas d'implémentation réelle, vous pourriez ajouter ici:
    # - Envoi d'email
    # - Notification SMS
    # - Intégration à un système de monitoring
    # - Écriture dans le journal des événements Windows
}

# Boucle principale
try {
    while ($true) {
        $currentTime = Get-Date
        Write-Output "Vérification des ressources à $(Get-Date -Format 'HH:mm:ss')"

        # Vérifier l'utilisation CPU
        $cpuUsage = Get-CpuUsage
        Write-Output "Utilisation CPU: $cpuUsage%"

        if (($cpuUsage -gt $cpuThreshold) -and (($currentTime - $lastCpuAlert).TotalSeconds -gt $cooldownPeriod)) {
            Create-Alert -Type "CPU" -Value $cpuUsage -Threshold $cpuThreshold
            $lastCpuAlert = $currentTime
        }

        # Vérifier l'utilisation mémoire
        $memoryUsage = Get-MemoryUsage
        Write-Output "Utilisation mémoire: $memoryUsage%"

        if (($memoryUsage -gt $memoryThreshold) -and (($currentTime - $lastMemoryAlert).TotalSeconds -gt $cooldownPeriod)) {
            Create-Alert -Type "Mémoire" -Value $memoryUsage -Threshold $memoryThreshold
            $lastMemoryAlert = $currentTime
        }

        # Enregistrer les données pour l'historique (optionnel)
        $dataLog = "$logFolder\ResourceUsage_$(Get-Date -Format 'yyyyMMdd').csv"

        # Créer l'en-tête du fichier CSV s'il n'existe pas
        if (-not (Test-Path $dataLog)) {
            "Timestamp,CPU_Usage,Memory_Usage" | Out-File -FilePath $dataLog -Encoding UTF8
        }

        # Ajouter les données actuelles
        "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'),$cpuUsage,$memoryUsage" | Out-File -FilePath $dataLog -Append -Encoding UTF8

        # Attendre l'intervalle configuré
        Write-Output "Attente de $checkInterval secondes avant la prochaine vérification..."
        Start-Sleep -Seconds $checkInterval
    }
}
catch {
    Write-Output "ERREUR CRITIQUE: $($_.Exception.Message)"
    Write-Output $_.ScriptStackTrace
}
finally {
    Write-Output "Service de surveillance système arrêté à $(Get-Date)"
    Stop-Transcript
}
```

#### Étape 2: Installer le service avec NSSM

Suivez la même procédure que pour l'exercice 1 mais avec ces spécificités:
- Nom du service: "SystemMonitorService"
- Description: "Surveille l'utilisation CPU et mémoire et génère des alertes"

#### Étape 3: Tester le service avec une charge artificielle

Pour tester le service, vous pouvez créer une charge CPU artificielle:

```powershell
# Script de test pour générer une charge CPU élevée
1..5 | ForEach-Object -Parallel {
    $result = 1
    for ($i = 1; $i -lt 2147483647; $i++) {
        $result *= $i
    }
} -ThrottleLimit 10
```

Ensuite, vérifiez si des alertes ont été générées:

```powershell
# Vérifier les alertes générées
Get-ChildItem -Path "C:\Alerts\SystemMonitor"
```

---

### Solution de l'exercice 3: Surveillance de dossier partagé et traitement d'images

**Objectif**: Créer un service qui surveille un dossier partagé réseau, traite les images entrantes (redimensionnement et optimisation), et les déplace vers un dossier de destination.

#### Étape 1: Installer les modules nécessaires

Avant de créer le script, installez le module PowerShell pour le traitement d'images:

```powershell
# Installer le module pour le traitement d'images
Install-Module -Name ImageMagick -Force
```

#### Étape 2: Créer le script ImageProcessingService.ps1

```powershell
# ImageProcessingService.ps1
# Service qui surveille un dossier réseau et traite automatiquement les images entrantes

# Importation des modules
Import-Module ImageMagick

# Configuration
$watchFolder = "\\SERVEUR\Partage\Images_Entrees"  # Dossier à surveiller (à adapter selon votre environnement)
$processedFolder = "\\SERVEUR\Partage\Images_Traitees"  # Dossier de destination
$errorFolder = "\\SERVEUR\Partage\Images_Erreurs"  # Dossier pour les fichiers en erreur
$logFolder = "C:\Logs\ImageProcessor"  # Dossier local pour les journaux
$tempFolder = "C:\Temp\ImageProcessor"  # Dossier temporaire local

# Paramètres du traitement d'images
$imageWidth = 1200  # Largeur max en pixels
$imageHeight = 800  # Hauteur max en pixels
$imageQuality = 85  # Qualité JPEG (0-100)
$allowedExtensions = @(".jpg", ".jpeg", ".png", ".gif", ".bmp")  # Extensions acceptées

# Vérification des accès réseau - ajustez selon votre environnement
function Test-NetworkAccess {
    try {
        # Tester l'accès au dossier partagé
        if (-not (Test-Path -Path $watchFolder)) {
            Write-Output "ERREUR: Impossible d'accéder au dossier partagé $watchFolder"
            return $false
        }

        return $true
    }
    catch {
        Write-Output "Erreur lors du test d'accès réseau: $($_.Exception.Message)"
        return $false
    }
}

# Créer les dossiers nécessaires localement
foreach ($folder in @($logFolder, $tempFolder)) {
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Créer les dossiers réseau si nécessaire
foreach ($folder in @($watchFolder, $processedFolder, $errorFolder)) {
    try {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
            Write-Output "Dossier créé: $folder"
        }
    }
    catch {
        Write-Output "Impossible de créer le dossier $folder : $($_.Exception.Message)"
    }
}

# Démarrer la journalisation
Start-Transcript -Path "$logFolder\ImageProcessor_$(Get-Date -Format 'yyyyMMdd').log" -Append

Write-Output "Service de traitement d'images démarré à $(Get-Date)"

# Fonction pour traiter une image
function Process-Image {
    param (
        [string]$sourceFilePath
    )

    try {
        $fileName = Split-Path $sourceFilePath -Leaf
        $fileExtension = [System.IO.Path]::GetExtension($fileName).ToLower()

        # Vérifier si l'extension est autorisée
        if ($allowedExtensions -notcontains $fileExtension) {
            Write-Output "Le fichier $fileName n'est pas une image valide (extension non autorisée)"
            return $false
        }

        # Nom de fichier unique pour éviter les collisions
        $processedFileName = [System.IO.Path]::GetFileNameWithoutExtension($fileName) + "_processed_" + (Get-Date -Format 'yyyyMMddHHmmss') + $fileExtension
        $tempFilePath = Join-Path $tempFolder $processedFileName
        $destinationFilePath = Join-Path $processedFolder $processedFileName

        Write-Output "Traitement de l'image: $fileName"

        # Utiliser ImageMagick pour traiter l'image
        $image = New-MagickImage -Path $sourceFilePath

        # Redimensionner l'image tout en préservant les proportions
        $image.Resize($imageWidth, $imageHeight)

        # Optimiser la qualité de l'image
        $image.Quality = $imageQuality

        # Correction automatique des niveaux (optionnel)
        $image.AutoLevel()

        # Enregistrer l'image traitée dans un fichier temporaire local
        $image.Write($tempFilePath)

        # Libérer les ressources
        $image.Dispose()

        # Copier le fichier vers le dossier de destination réseau
        Copy-Item -Path $tempFilePath -Destination $destinationFilePath -Force

        # Supprimer le fichier temporaire
        Remove-Item -Path $tempFilePath -Force

        # Supprimer le fichier source
        Remove-Item -Path $sourceFilePath -Force

        Write-Output "Image traitée avec succès: $destinationFilePath"
        return $true
    }
    catch {
        Write-Output "ERREUR lors du traitement de l'image $sourceFilePath : $($_.Exception.Message)"

        # Déplacer le fichier en erreur
        try {
            $errorFileName = Split-Path $sourceFilePath -Leaf
            $errorFilePath = Join-Path $errorFolder $errorFileName
            Move-Item -Path $sourceFilePath -Destination $errorFilePath -Force
            Write-Output "Fichier déplacé vers: $errorFilePath"
        }
        catch {
            Write-Output "Impossible de déplacer le fichier vers le dossier d'erreur: $($_.Exception.Message)"
        }

        return $false
    }
}

# Fonction pour nettoyer les fichiers temporaires
function Clean-TempFiles {
    try {
        Get-ChildItem -Path $tempFolder -File | Remove-Item -Force
        Write-Output "Nettoyage des fichiers temporaires effectué"
    }
    catch {
        Write-Output "Erreur lors du nettoyage des fichiers temporaires: $($_.Exception.Message)"
    }
}

# Statistiques de traitement
$stats = @{
    ImagesTraitees = 0
    ErreursDuTraitement = 0
    DebutService = Get-Date
}

# Boucle principale
try {
    while ($true) {
        # Vérifier l'accès réseau
        if (-not (Test-NetworkAccess)) {
            Write-Output "Connexion réseau indisponible. Nouvelle tentative dans 60 secondes..."
            Start-Sleep -Seconds 60
            continue
        }

        Write-Output "Recherche d'images dans le dossier $watchFolder..."

        # Obtenir tous les fichiers du dossier surveillé
        $files = Get-ChildItem -Path $watchFolder -File

        if ($files.Count -gt 0) {
            Write-Output "Trouvé $($files.Count) fichier(s) à traiter"

            # Traiter chaque fichier
            foreach ($file in $files) {
                $result = Process-Image -sourceFilePath $file.FullName

                # Mettre à jour les statistiques
                if ($result) {
                    $stats.ImagesTraitees++
                }
                else {
                    $stats.ErreursDuTraitement++
                }
            }

            # Nettoyer les fichiers temporaires après chaque lot
            Clean-TempFiles
        }
        else {
            Write-Output "Aucun fichier à traiter pour le moment"
        }

        # Afficher les statistiques périodiquement
        $timeRunning = (Get-Date) - $stats.DebutService
        Write-Output "Statistiques: $($stats.ImagesTraitees) images traitées, $($stats.ErreursDuTraitement) erreurs | Temps d'exécution: $([math]::Floor($timeRunning.TotalHours))h $($timeRunning.Minutes)m"

        # Attendre avant la prochaine vérification
        Write-Output "En attente de 30 secondes avant la prochaine vérification..."
        Start-Sleep -Seconds 30
    }
}
catch {
    Write-Output "ERREUR CRITIQUE: $($_.Exception.Message)"
    Write-Output $_.ScriptStackTrace
}
finally {
    # Nettoyer et arrêter proprement
    Clean-TempFiles
    Write-Output "Service de traitement d'images arrêté à $(Get-Date)"
    Stop-Transcript
}
```

#### Étape 3: Adapter le script à votre environnement réseau

Modifiez ces paramètres en fonction de votre environnement:
- `$watchFolder` - Remplacez par le chemin de votre dossier partagé
- `$processedFolder` - Dossier de destination
- `$errorFolder` - Dossier pour les erreurs
- `$imageWidth`, `$imageHeight`, `$imageQuality` - Ajustez selon vos besoins

#### Étape 4: Configuration des informations d'identification pour le dossier réseau

Pour que le service accède au dossier réseau, vous pouvez:

1. **Configurer le service pour qu'il s'exécute avec un compte ayant accès au dossier réseau:**

```powershell
# Dans NSSM, configurez l'onglet "Log on" pour utiliser un compte avec les accès appropriés
# OU si vous utilisez SC
sc.exe config "ImageProcessorService" obj= "DOMAIN\utilisateur" password= "mot_de_passe"
```

2. **Ou créer un script de démarrage qui mappe le lecteur réseau:**

```batch
@echo off
REM Mapper le lecteur réseau avec les identifiants
net use Z: \\SERVEUR\Partage /user:DOMAIN\utilisateur mot_de_passe /persistent:yes

REM Lancer PowerShell
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\ImageProcessingService.ps1"
```

#### Étape 5: Installer le service

Installez le service en utilisant NSSM comme dans les exercices précédents:
- Nom du service: "ImageProcessorService"
- Description: "Service de traitement automatique d'images"
- Configurez le compte d'exécution avec les droits nécessaires pour accéder au réseau

#### Étape 6: Tester le service

1. Démarrez le service:

```powershell
Start-Service -Name "ImageProcessorService"
```

2. Placez quelques images dans le dossier surveillé et vérifiez:
   - Qu'elles sont traitées correctement (redimensionnées et optimisées)
   - Qu'elles sont déplacées vers le dossier de destination
   - Que les erreurs sont correctement gérées

3. Vérifiez les journaux:

```powershell
Get-Content -Path "C:\Logs\ImageProcessor\ImageProcessor_$(Get-Date -Format 'yyyyMMdd').log" -Tail 20
```

### Variante avancée: Surveillance asynchrone de dossier avec FileSystemWatcher

Pour une version plus efficace du service de traitement d'images, vous pouvez utiliser `FileSystemWatcher`. Cette approche est plus réactive car elle déclenche des actions dès qu'un fichier est créé plutôt que de vérifier périodiquement.

Voici comment modifier le script pour utiliser cette approche:

```powershell
# Au début du script, après les configurations initiales mais avant la boucle principale
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchFolder
$watcher.IncludeSubdirectories = $false
$watcher.EnableRaisingEvents = $true

# Définir le gestionnaire d'événements pour les nouveaux fichiers
$action = {
    $path = $Event.SourceEventArgs.FullPath
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType

    # Attendre un peu pour s'assurer que le fichier est complètement écrit
    Start-Sleep -Seconds 2

    Write-Output "Fichier $name détecté ($changeType) à $(Get-Date -Format 'HH:mm:ss')"

    # Traiter l'image
    Process-Image -sourceFilePath $path
}

# Enregistrer les événements
$created = Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action

# Remplacer la boucle principale par une boucle d'attente simple
try {
    Write-Output "Service en attente de nouveaux fichiers..."

    # Boucle pour maintenir le service en vie
    while ($true) {
        Start-Sleep -Seconds 60

        # Afficher périodiquement un signal de vie et des statistiques
        $timeRunning = (Get-Date) - $stats.DebutService
        Write-Output "Service actif | Statistiques: $($stats.ImagesTraitees) images traitées, $($stats.ErreursDuTraitement) erreurs | Temps d'exécution: $([math]::Floor($timeRunning.TotalHours))h $($timeRunning.Minutes)m"
    }
}
finally {
    # Nettoyer les événements
    Unregister-Event -SourceIdentifier $created.Name
    $watcher.Dispose()

    # Nettoyage habituel
    Clean-TempFiles
    Write-Output "Service arrêté à $(Get-Date)"
    Stop-Transcript
}
```

### Conseils supplémentaires pour les services PowerShell

1. **Persistence des mots de passe**:
   - Évitez de stocker des mots de passe en clair dans vos scripts
   - Utilisez `ConvertTo-SecureString` et `Export-CliXml` pour sécuriser les identifiants

2. **Surveillance de services**:
   - Envisagez d'implémenter un service de surveillance qui vérifie si vos autres services fonctionnent correctement
   - Utilisez des mécanismes de heartbeat (battement de cœur) pour confirmer que le service est toujours actif

3. **Rotation des journaux**:
   - Ajoutez un mécanisme de rotation des journaux pour éviter qu'ils ne deviennent trop volumineux
   - Exemple: nettoyer les journaux de plus de 30 jours

4. **Haute disponibilité**:
   - Pour les services critiques, envisagez un mécanisme de basculement
   - Stockez l'état dans une base de données ou un fichier partagé pour permettre une reprise

5. **Métriques et surveillance**:
   - Ajoutez des compteurs de performance Windows pour surveiller votre service
   - Intégrez votre service à des solutions de monitoring comme Nagios, Zabbix, ou Azure Monitor

Ces solutions avancées vous permettront de créer des services PowerShell robustes et fiables pour vos besoins d'automatisation en entreprise.
