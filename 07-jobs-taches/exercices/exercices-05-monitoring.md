# Solutions des Exercices de Monitoring de Scripts Longue Durée

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Exercice 1 - Service d'horodatage avec monitoring

Cet exercice consiste à modifier un service d'horodatage pour y ajouter des fonctionnalités de monitoring avec journalisation et heartbeat.

```powershell
# Service d'horodatage avec fonctionnalités de monitoring
# Ce script enregistre périodiquement l'heure dans un fichier
# et inclut des fonctionnalités de monitoring: logs et heartbeat

# Configuration
$config = @{
    # Dossier où enregistrer les horodatages
    OutputFolder = "C:\TimeStampService"
    # Dossier des logs
    LogFolder = "C:\TimeStampService\Logs"
    # Fichier de heartbeat
    HeartbeatFile = "C:\TimeStampService\heartbeat.txt"
    # Intervalle d'horodatage (en secondes)
    TimeStampInterval = 60
    # Intervalle de heartbeat (en minutes)
    HeartbeatInterval = 5
    # Durée maximale d'exécution (en heures, 0 = infini)
    MaxRuntime = 24
}

# Créer les dossiers nécessaires s'ils n'existent pas
if (-not (Test-Path $config.OutputFolder)) {
    New-Item -Path $config.OutputFolder -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path $config.LogFolder)) {
    New-Item -Path $config.LogFolder -ItemType Directory -Force | Out-Null
}

# Initialiser le fichier de log
$logFile = Join-Path -Path $config.LogFolder -ChildPath "TimeStamp_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile -Append

# Fonction de journalisation personnalisée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timeStamp] [$Level] $Message"

    # Afficher dans la console avec coloration
    switch ($Level) {
        "ERROR" { Write-Host $formattedMessage -ForegroundColor Red }
        "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
        default { Write-Host $formattedMessage }
    }
}

# Fonction pour mettre à jour le heartbeat
function Update-Heartbeat {
    param (
        [string]$HeartbeatFile = $config.HeartbeatFile
    )

    # Enregistrer l'horodatage actuel
    Get-Date | Out-File -FilePath $HeartbeatFile -Force
    Write-Log "Heartbeat mis à jour: $(Get-Date)" -Level "INFO"
}

# Variable pour suivre le temps d'exécution
$startTime = Get-Date
$lastHeartbeat = Get-Date
$timestampCount = 0

Write-Log "Service d'horodatage démarré" -Level "SUCCESS"

try {
    # Créer un premier heartbeat
    Update-Heartbeat

    while ($true) {
        $currentTime = Get-Date

        # Vérifier si la durée maximale d'exécution est atteinte
        if ($config.MaxRuntime -gt 0 -and ($currentTime - $startTime).TotalHours -ge $config.MaxRuntime) {
            Write-Log "Durée maximale d'exécution atteinte ($($config.MaxRuntime) heures). Arrêt du service." -Level "WARNING"
            break
        }

        # Enregistrer l'horodatage
        $timestampFile = Join-Path -Path $config.OutputFolder -ChildPath "timestamp_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        Get-Date | Out-File -FilePath $timestampFile
        $timestampCount++
        Write-Log "Horodatage #$timestampCount enregistré: $timestampFile" -Level "INFO"

        # Vérifier si c'est le moment de mettre à jour le heartbeat
        if (($currentTime - $lastHeartbeat).TotalMinutes -ge $config.HeartbeatInterval) {
            Update-Heartbeat
            $lastHeartbeat = $currentTime

            # Monitorer les ressources
            $process = Get-Process -Id $PID
            $memoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
            $cpuSeconds = [math]::Round($process.CPU, 2)
            Write-Log "Utilisation des ressources - Mémoire: $memoryMB MB, CPU: $cpuSeconds secondes" -Level "INFO"
        }

        # Nettoyer les anciens fichiers d'horodatage (> 7 jours)
        $oldFiles = Get-ChildItem -Path $config.OutputFolder -Filter "timestamp_*.txt" |
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        if ($oldFiles.Count -gt 0) {
            $oldFiles | Remove-Item -Force
            Write-Log "$($oldFiles.Count) anciens fichiers d'horodatage nettoyés" -Level "INFO"
        }

        # Attendre l'intervalle configuré
        Start-Sleep -Seconds $config.TimeStampInterval
    }
}
catch {
    Write-Log "ERREUR: $($_.Exception.Message)" -Level "ERROR"
    Write-Log $_.ScriptStackTrace -Level "ERROR"
}
finally {
    # Nettoyer et arrêter la journalisation
    Write-Log "Service d'horodatage arrêté. Total des horodatages: $timestampCount" -Level "INFO"
    Stop-Transcript
}
```

## Exercice 2 - Traitement de fichiers avec suivi de progression

Cet exercice consiste à créer un script qui traite un grand nombre de fichiers avec une barre de progression, des points de contrôle et la possibilité de reprendre après une interruption.

```powershell
# Script de traitement de fichiers avec monitoring avancé
# Ce script parcourt des images, les renomme et peut reprendre après une interruption

# Configuration
$config = @{
    # Dossier contenant les images à traiter
    SourceFolder = "C:\Images"
    # Format de renommage (utilise {0} pour le numéro séquentiel)
    RenameFormat = "Image_{0:D5}.jpg"
    # Dossier pour les logs
    LogFolder = "C:\Logs\ImageProcessor"
    # Fichier d'état pour reprendre après interruption
    StateFile = "C:\Logs\ImageProcessor\state.json"
    # Intervalle de sauvegarde de l'état (nombre de fichiers)
    CheckpointInterval = 20
}

# Créer les dossiers nécessaires
if (-not (Test-Path $config.LogFolder)) {
    New-Item -Path $config.LogFolder -ItemType Directory -Force | Out-Null
}

# Initialiser le fichier de log
$logFile = Join-Path -Path $config.LogFolder -ChildPath "ImageRename_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile -Append

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timeStamp] [$Level] $Message"

    # Afficher dans la console avec coloration
    switch ($Level) {
        "ERROR" { Write-Host $formattedMessage -ForegroundColor Red }
        "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
        default { Write-Host $formattedMessage }
    }
}

# Fonction pour sauvegarder l'état
function Save-ProcessingState {
    param($State)

    $State | ConvertTo-Json | Out-File -FilePath $config.StateFile -Force
    Write-Log "État sauvegardé à l'index $($State.LastProcessedIndex)" -Level "INFO"
}

# Vérifier si le dossier source existe
if (-not (Test-Path $config.SourceFolder)) {
    Write-Log "Le dossier source n'existe pas: $($config.SourceFolder)" -Level "ERROR"
    Stop-Transcript
    exit 1
}

# Obtenir tous les fichiers d'images
$imageExtensions = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff")
$allFiles = Get-ChildItem -Path $config.SourceFolder -File |
            Where-Object { $imageExtensions -contains $_.Extension.ToLower() } |
            Sort-Object Name

$totalFiles = $allFiles.Count
Write-Log "Trouvé $totalFiles images à traiter" -Level "INFO"

if ($totalFiles -eq 0) {
    Write-Log "Aucune image à traiter. Fin du script." -Level "WARNING"
    Stop-Transcript
    exit 0
}

# Initialiser ou charger l'état
$state = @{
    StartTime = Get-Date
    LastProcessedIndex = 0
    ProcessedFiles = 0
    SkippedFiles = 0
    ErrorFiles = 0
    LastFileName = ""
}

if (Test-Path $config.StateFile) {
    try {
        $savedState = Get-Content -Path $config.StateFile -Raw | ConvertFrom-Json

        # Vérifier si l'état sauvegardé est récent (moins de 24 heures)
        $lastStateTime = [DateTime]::Parse($savedState.StartTime)
        if ((Get-Date) - $lastStateTime -lt [TimeSpan]::FromHours(24)) {
            $state.LastProcessedIndex = $savedState.LastProcessedIndex
            $state.ProcessedFiles = $savedState.ProcessedFiles
            $state.SkippedFiles = $savedState.SkippedFiles
            $state.ErrorFiles = $savedState.ErrorFiles
            $state.LastFileName = $savedState.LastFileName

            Write-Log "État précédent chargé. Reprise à partir de l'index $($state.LastProcessedIndex)" -Level "INFO"
        }
        else {
            Write-Log "État précédent trop ancien. Démarrage d'un nouveau traitement." -Level "WARNING"
        }
    }
    catch {
        Write-Log "Impossible de charger l'état précédent: $($_.Exception.Message). Démarrage d'un nouveau traitement." -Level "WARNING"
    }
}

$startIndex = $state.LastProcessedIndex
$processedInThisRun = 0

try {
    # Boucle principale de traitement
    for ($i = $startIndex; $i -lt $totalFiles; $i++) {
        $file = $allFiles[$i]

        # Mettre à jour l'état
        $state.LastProcessedIndex = $i
        $state.LastFileName = $file.Name

        # Calculer le nouveau nom
        $newName = $config.RenameFormat -f ($i + 1)
        $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName

        # Afficher la progression
        $percentComplete = ($i / $totalFiles) * 100
        Write-Progress -Activity "Traitement des images" -Status "Image $($i+1) sur $totalFiles" -PercentComplete $percentComplete -CurrentOperation "Traitement de $($file.Name)"

        try {
            # Vérifier si le fichier existe toujours (il pourrait avoir été supprimé)
            if (-not (Test-Path $file.FullName)) {
                Write-Log "Le fichier n'existe plus: $($file.FullName)" -Level "WARNING"
                $state.SkippedFiles++
                continue
            }

            # Vérifier si le nouveau nom existe déjà
            if (Test-Path $newPath) {
                # Si le fichier a déjà été renommé (même taille et date), on le saute
                $existingFile = Get-Item -Path $newPath
                if ($existingFile.Length -eq $file.Length -and
                    [math]::Abs(($existingFile.LastWriteTime - $file.LastWriteTime).TotalSeconds) -lt 2) {
                    Write-Log "Le fichier semble déjà traité (même taille et date): $($file.Name) -> $newName" -Level "INFO"
                    $state.SkippedFiles++
                    continue
                }
                else {
                    # Ajouter un suffixe pour éviter les conflits
                    $newNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($newName)
                    $extension = [System.IO.Path]::GetExtension($newName)
                    $newName = "{0}_duplicate{1}" -f $newNameWithoutExt, $extension
                    $newPath = Join-Path -Path $file.DirectoryName -ChildPath $newName
                    Write-Log "Conflit de nom détecté, utilisation de: $newName" -Level "WARNING"
                }
            }

            # Renommer le fichier
            Rename-Item -Path $file.FullName -NewName $newName -Force
            $state.ProcessedFiles++
            $processedInThisRun++
            Write-Log "Fichier renommé: $($file.Name) -> $newName" -Level "INFO"
        }
        catch {
            Write-Log "ERREUR lors du traitement de $($file.Name): $($_.Exception.Message)" -Level "ERROR"
            $state.ErrorFiles++
        }

        # Sauvegarder l'état à intervalles réguliers
        if ($i % $config.CheckpointInterval -eq 0) {
            Save-ProcessingState -State $state
        }
    }

    # Marquer la progression comme terminée
    Write-Progress -Activity "Traitement des images" -Completed

    # Sauvegarder l'état final
    Save-ProcessingState -State $state

    # Calculer les statistiques
    $duration = (Get-Date) - $state.StartTime
    $durationFormatted = "{0:D2}h {1:D2}m {2:D2}s" -f $duration.Hours, $duration.Minutes, $duration.Seconds
    $filesPerSecond = if ($duration.TotalSeconds -gt 0) { [math]::Round($processedInThisRun / $duration.TotalSeconds, 2) } else { 0 }

    # Générer le rapport final
    $report = @"
RAPPORT DE TRAITEMENT DES IMAGES
===============================
Date et heure de début: $($state.StartTime)
Date et heure de fin: $(Get-Date)
Durée totale: $durationFormatted

STATISTIQUES
-----------
Images traitées: $($state.ProcessedFiles)
Images ignorées: $($state.SkippedFiles)
Erreurs rencontrées: $($state.ErrorFiles)
Performance: $filesPerSecond fichiers/seconde

"@

    Write-Log $report -Level "SUCCESS"
}
catch {
    Write-Log "ERREUR CRITIQUE: $($_.Exception.Message)" -Level "ERROR"
    Write-Log $_.ScriptStackTrace -Level "ERROR"

    # Sauvegarder l'état en cas d'erreur critique
    Save-ProcessingState -State $state
}
finally {
    # Nettoyer et arrêter la journalisation
    Stop-Transcript
}
```

## Exercice 3 - Système de monitoring complet

Cet exercice consiste à développer un système de monitoring complet pour un script longue durée incluant la journalisation, les heartbeats, la surveillance des ressources, les notifications par email et la génération de rapports graphiques.

# Partie 1 : Configuration et fonctions de base du système de monitoring

```powershell
# Système de monitoring complet pour script longue durée
# Ce script simule un traitement de données volumineuses avec un système de monitoring avancé

# Configuration
$config = @{
    # Chemins des fichiers et dossiers
    BaseFolder = "C:\MonitoringSystem"
    LogFolder = "C:\MonitoringSystem\Logs"
    DataFolder = "C:\MonitoringSystem\Data"
    ReportsFolder = "C:\MonitoringSystem\Reports"
    StateFile = "C:\MonitoringSystem\state.json"
    HeartbeatFile = "C:\MonitoringSystem\heartbeat.txt"
    ResourceLogFile = "C:\MonitoringSystem\resource_metrics.csv"

    # Paramètres d'email
    EmailSettings = @{
        To = "admin@exemple.com"
        From = "monitoring@exemple.com"
        SmtpServer = "smtp.exemple.com"
        Port = 25
        UseSSL = $false
        Credential = $null # À définir si nécessaire: (Get-Credential)
    }

    # Intervalles
    HeartbeatInterval = 5    # minutes
    CheckpointInterval = 100 # éléments
    ResourceInterval = 2     # minutes
    ReportInterval = 30      # minutes

    # Données à traiter (simulé)
    TotalDataItems = 5000

    # Seuils d'alerte
    Thresholds = @{
        CpuWarning = 75
        CpuCritical = 90
        MemoryWarning = 75
        MemoryCritical = 90
        DiskWarning = 15    # Go restants
        DiskCritical = 5     # Go restants
    }
}

# Créer les dossiers nécessaires
$folders = @($config.BaseFolder, $config.LogFolder, $config.DataFolder, $config.ReportsFolder)
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Initialiser le fichier de log
$logFile = Join-Path -Path $config.LogFolder -ChildPath "Process_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile -Append

# Fonction de journalisation améliorée
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "CRITICAL", "DEBUG")]
        [string]$Level = "INFO",
        [switch]$NoConsole
    )

    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timeStamp] [$Level] $Message"

    # Déterminer le fichier de log en fonction du niveau
    $levelLogFile = Join-Path -Path $config.LogFolder -ChildPath "$Level.log"

    # Écrire dans le fichier de log spécifique au niveau
    $formattedMessage | Out-File -FilePath $levelLogFile -Append

    # Afficher dans la console avec coloration (sauf si NoConsole est spécifié)
    if (-not $NoConsole) {
        switch ($Level) {
            "ERROR" { Write-Host $formattedMessage -ForegroundColor Red }
            "CRITICAL" { Write-Host $formattedMessage -ForegroundColor Red -BackgroundColor White }
            "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
            "DEBUG" { Write-Host $formattedMessage -ForegroundColor Cyan }
            default { Write-Host $formattedMessage -ForegroundColor White }
        }
    }

    # Envoyer automatiquement un email pour les erreurs critiques
    if ($Level -eq "CRITICAL") {
        Send-EmailAlert -Subject "ALERTE CRITIQUE: Processus de traitement" -Body $Message
    }
}

# Fonction pour envoyer des emails
function Send-EmailAlert {
    param (
        [string]$Subject,
        [string]$Body,
        [string[]]$Attachments = @()
    )

    try {
        $emailParams = @{
            To = $config.EmailSettings.To
            From = $config.EmailSettings.From
            Subject = $Subject
            Body = $Body
            SmtpServer = $config.EmailSettings.SmtpServer
            Port = $config.EmailSettings.Port
            UseSSL = $config.EmailSettings.UseSSL
        }

        if ($config.EmailSettings.Credential) {
            $emailParams.Add("Credential", $config.EmailSettings.Credential)
        }

        if ($Attachments.Count -gt 0) {
            $emailParams.Add("Attachments", $Attachments)
        }

        # En production, décommentez cette ligne
        # Send-MailMessage @emailParams

        # Pour test/démonstration, nous simulons l'envoi
        Write-Log "SIMULATION: Email envoyé: $Subject" -Level "INFO" -NoConsole

        return $true
    }
    catch {
        Write-Log "Échec de l'envoi d'email: $($_.Exception.Message)" -Level "ERROR" -NoConsole
        return $false
    }
}

# Fonction pour mettre à jour le heartbeat
function Update-Heartbeat {
    $heartbeatInfo = [PSCustomObject]@{
        Timestamp = Get-Date
        ProcessID = $PID
        ComputerName = $env:COMPUTERNAME
        Username = $env:USERNAME
        ScriptPath = $MyInvocation.ScriptName
        LastProcessedItem = $state.LastProcessedIndex
    }

    $heartbeatInfo | ConvertTo-Json | Out-File -FilePath $config.HeartbeatFile -Force
    Write-Log "Heartbeat mis à jour" -Level "DEBUG" -NoConsole
}
```

# Partie 2 : Fonctions de surveillance des ressources et de rapports

```powershell
# Fonction pour surveiller les ressources système
function Monitor-Resources {
    # Obtenir l'utilisation CPU
    try {
        $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
        $cpuPercent = [math]::Round($cpuUsage.CounterSamples.CookedValue, 2)
    }
    catch {
        Write-Log "Impossible de récupérer l'utilisation CPU: $($_.Exception.Message)" -Level "WARNING"
        $cpuPercent = 0
    }

    # Obtenir l'utilisation mémoire
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $memoryUsed = $osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory
        $memoryPercent = [math]::Round(($memoryUsed / $osInfo.TotalVisibleMemorySize) * 100, 2)
        $memoryTotalGB = [math]::Round($osInfo.TotalVisibleMemorySize / 1MB, 2)
        $memoryFreeGB = [math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
    }
    catch {
        Write-Log "Impossible de récupérer l'utilisation mémoire: $($_.Exception.Message)" -Level "WARNING"
        $memoryPercent = 0
        $memoryTotalGB = 0
        $memoryFreeGB = 0
    }

    # Obtenir l'utilisation disque
    try {
        $systemDrive = (Get-PSDrive C)
        $diskFreeGB = [math]::Round($systemDrive.Free / 1GB, 2)
        $diskTotalGB = [math]::Round(($systemDrive.Used + $systemDrive.Free) / 1GB, 2)
        $diskPercent = [math]::Round(($systemDrive.Used / ($systemDrive.Used + $systemDrive.Free)) * 100, 2)
    }
    catch {
        Write-Log "Impossible de récupérer l'utilisation disque: $($_.Exception.Message)" -Level "WARNING"
        $diskFreeGB = 0
        $diskTotalGB = 0
        $diskPercent = 0
    }

    # Obtenir la consommation du processus courant
    try {
        $process = Get-Process -Id $PID
        $processMemoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
        $processCPU = [math]::Round($process.CPU, 2)
    }
    catch {
        Write-Log "Impossible de récupérer les informations du processus: $($_.Exception.Message)" -Level "WARNING"
        $processMemoryMB = 0
        $processCPU = 0
    }

    # Créer l'objet de métriques
    $metrics = [PSCustomObject]@{
        Timestamp = Get-Date
        CPU_Percent = $cpuPercent
        Memory_Percent = $memoryPercent
        Memory_Total_GB = $memoryTotalGB
        Memory_Free_GB = $memoryFreeGB
        Disk_Free_GB = $diskFreeGB
        Disk_Total_GB = $diskTotalGB
        Disk_Percent = $diskPercent
        Process_Memory_MB = $processMemoryMB
        Process_CPU = $processCPU
    }

    # Vérifier si le fichier de log des ressources existe
    if (-not (Test-Path $config.ResourceLogFile)) {
        # Créer l'en-tête CSV
        $metrics | Export-Csv -Path $config.ResourceLogFile -NoTypeInformation
    }
    else {
        # Ajouter au fichier existant
        $metrics | Export-Csv -Path $config.ResourceLogFile -NoTypeInformation -Append
    }

    # Vérifier les seuils d'alerte
    $alertMessages = @()

    if ($cpuPercent -ge $config.Thresholds.CpuCritical) {
        $msg = "ALERTE CRITIQUE: Utilisation CPU à $cpuPercent% (seuil: $($config.Thresholds.CpuCritical)%)"
        Write-Log $msg -Level "CRITICAL"
        $alertMessages += $msg
    }
    elseif ($cpuPercent -ge $config.Thresholds.CpuWarning) {
        $msg = "ALERTE: Utilisation CPU élevée à $cpuPercent% (seuil: $($config.Thresholds.CpuWarning)%)"
        Write-Log $msg -Level "WARNING"
        $alertMessages += $msg
    }

    if ($memoryPercent -ge $config.Thresholds.MemoryCritical) {
        $msg = "ALERTE CRITIQUE: Utilisation mémoire à $memoryPercent% (seuil: $($config.Thresholds.MemoryCritical)%)"
        Write-Log $msg -Level "CRITICAL"
        $alertMessages += $msg
    }
    elseif ($memoryPercent -ge $config.Thresholds.MemoryWarning) {
        $msg = "ALERTE: Utilisation mémoire élevée à $memoryPercent% (seuil: $($config.Thresholds.MemoryWarning)%)"
        Write-Log $msg -Level "WARNING"
        $alertMessages += $msg
    }

    if ($diskFreeGB -le $config.Thresholds.DiskCritical) {
        $msg = "ALERTE CRITIQUE: Espace disque critique à $diskFreeGB GB (seuil: $($config.Thresholds.DiskCritical) GB)"
        Write-Log $msg -Level "CRITICAL"
        $alertMessages += $msg
    }
    elseif ($diskFreeGB -le $config.Thresholds.DiskWarning) {
        $msg = "ALERTE: Espace disque faible à $diskFreeGB GB (seuil: $($config.Thresholds.DiskWarning) GB)"
        Write-Log $msg -Level "WARNING"
        $alertMessages += $msg
    }

    # Envoyer un email si plusieurs alertes sont détectées (pour éviter le spam)
    if ($alertMessages.Count -gt 1) {
        $alertBody = "Plusieurs alertes ont été détectées:`n`n" + ($alertMessages -join "`n")
        Send-EmailAlert -Subject "Alertes ressources multiples" -Body $alertBody
    }

    return $metrics
}

# Fonction pour sauvegarder l'état
function Save-ProcessingState {
    param($State)

    $State | ConvertTo-Json | Out-File -FilePath $config.StateFile -Force
    Write-Log "État sauvegardé à l'index $($State.LastProcessedIndex)" -Level "DEBUG" -NoConsole
}

# Fonction pour charger l'état
function Get-ProcessingState {
    if (Test-Path $config.StateFile) {
        try {
            $savedState = Get-Content -Path $config.StateFile -Raw | ConvertFrom-Json

            # Vérifier si l'état sauvegardé est récent (moins de 24 heures)
            $lastStateTime = [DateTime]::Parse($savedState.StartTime)
            if ((Get-Date) - $lastStateTime -lt [TimeSpan]::FromHours(24)) {
                Write-Log "État précédent chargé. Reprise à partir de l'index $($savedState.LastProcessedIndex)" -Level "INFO"
                return $savedState
            }
            else {
                Write-Log "État précédent trop ancien (> 24h). Démarrage d'un nouveau traitement." -Level "WARNING"
                return $null
            }
        }
        catch {
            Write-Log "Impossible de charger l'état précédent: $($_.Exception.Message). Démarrage d'un nouveau traitement." -Level "WARNING"
            return $null
        }
    }
    else {
        Write-Log "Aucun fichier d'état trouvé. Démarrage d'un nouveau traitement." -Level "INFO"
        return $null
    }
}

# Fonction pour générer un rapport HTML
function New-MonitoringReport {
    param(
        [switch]$Final
    )

    $reportTitle = if ($Final) { "Rapport Final de Monitoring" } else { "Rapport Intermédiaire de Monitoring" }
    $reportFile = Join-Path -Path $config.ReportsFolder -ChildPath "Rapport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    try {
        # Charger les données de ressources
        if (Test-Path $config.ResourceLogFile) {
            $resourceData = Import-Csv -Path $config.ResourceLogFile

            # Calculer la durée écoulée
            $duration = (Get-Date) - $state.StartTime
            $durationFormatted = "{0:D2}h {1:D2}m {2:D2}s" -f $duration.Hours, $duration.Minutes, $duration.Seconds

            # Préparer les données pour les graphiques
            $timestamps = $resourceData.Timestamp
            $cpuData = $resourceData.CPU_Percent | ForEach-Object { [double]$_ }
            $memoryData = $resourceData.Memory_Percent | ForEach-Object { [double]$_ }
            $diskFreeData = $resourceData.Disk_Free_GB | ForEach-Object { [double]$_ }
            $processMemoryData = $resourceData.Process_Memory_MB | ForEach-Object { [double]$_ }

            # Calculer les statistiques moyennes
            $avgCPU = if ($cpuData.Count -gt 0) { [math]::Round(($cpuData | Measure-Object -Average).Average, 2) } else { 0 }
            $avgMemory = if ($memoryData.Count -gt 0) { [math]::Round(($memoryData | Measure-Object -Average).Average, 2) } else { 0 }
            $avgDiskFree = if ($diskFreeData.Count -gt 0) { [math]::Round(($diskFreeData | Measure-Object -Average).Average, 2) } else { 0 }
            $avgProcessMemory = if ($processMemoryData.Count -gt 0) { [math]::Round(($processMemoryData | Measure-Object -Average).Average, 2) } else { 0 }

            # Calculer le taux de traitement
            $itemsPerSecond = if ($duration.TotalSeconds -gt 0) { [math]::Round($state.ProcessedItems / $duration.TotalSeconds, 2) } else { 0 }
            $estimatedTimeLeft = if ($itemsPerSecond -gt 0) {
                $itemsLeft = $config.TotalDataItems - $state.LastProcessedIndex
                $secondsLeft = $itemsLeft / $itemsPerSecond
                $timeSpan = [TimeSpan]::FromSeconds($secondsLeft)
                "{0:D2}h {1:D2}m {2:D2}s" -f $timeSpan.Hours, $timeSpan.Minutes, $timeSpan.Seconds
            } else { "N/A" }

            # Générer le contenu HTML pour le rapport
            $htmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$reportTitle</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.9.4/Chart.min.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background-color: white; padding: 20px; border-radius: 5px; box-shadow: 0 2px 5px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 1px solid #ddd; padding-bottom: 10px; }
        h2 { color: #444; margin-top: 30px; }
        .summary-card { background-color: #f9f9f9; border-radius: 5px; padding: 15px; margin-bottom: 20px; }
        .progress-container { margin-top: 20px; background-color: #f0f0f0; border-radius: 5px; height: 30px; overflow: hidden; }
        .progress-bar { height: 100%; background-color: #4CAF50; text-align: center; line-height: 30px; color: white; }
        .chart-container { margin-top: 30px; height: 300px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>$reportTitle</h1>
        <p>Généré le $(Get-Date -Format 'dd/MM/yyyy à HH:mm:ss')</p>

        <div class="summary-card">
            <h2>Résumé de l'Exécution</h2>
            <div>Début d'exécution: $($state.StartTime)</div>
            <div>Temps d'exécution: $durationFormatted</div>
            <div>Éléments traités: $($state.ProcessedItems) / $($config.TotalDataItems)</div>
            <div>Erreurs rencontrées: $($state.Errors)</div>
            <div>Vitesse de traitement: $itemsPerSecond éléments/seconde</div>
            <div>Temps restant estimé: $estimatedTimeLeft</div>
        </div>

        <div class="progress-container">
            <div class="progress-bar" style="width: $(([math]::Round(($state.ProcessedItems / $config.TotalDataItems) * 100, 0)))%;">
                $(([math]::Round(($state.ProcessedItems / $config.TotalDataItems) * 100, 0)))%
            </div>
        </div>

        <h2>Utilisation des Ressources</h2>
        <div class="chart-container">
            <canvas id="resourceChart"></canvas>
        </div>

        <h2>Consommation du Processus</h2>
        <div class="chart-container">
            <canvas id="processChart"></canvas>
        </div>
"@

            # Script JavaScript pour les graphiques
            $jsScript = @"
    <script>
        // Graphique des ressources système
        const resourceCtx = document.getElementById('resourceChart').getContext('2d');
        const resourceChart = new Chart(resourceCtx, {
            type: 'line',
            data: {
                labels: $($timestamps | ConvertTo-Json),
                datasets: [{
                    label: 'CPU (%)',
                    data: $($cpuData | ConvertTo-Json),
                    borderColor: 'rgba(255, 99, 132, 1)',
                    fill: false
                }, {
                    label: 'Mémoire (%)',
                    data: $($memoryData | ConvertTo-Json),
                    borderColor: 'rgba(54, 162, 235, 1)',
                    fill: false
                }, {
                    label: 'Espace Disque Libre (GB)',
                    data: $($diskFreeData | ConvertTo-Json),
                    borderColor: 'rgba(75, 192, 192, 1)',
                    fill: false
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });

        // Graphique de consommation du processus
        const processCtx = document.getElementById('processChart').getContext('2d');
        const processChart = new Chart(processCtx, {
            type: 'line',
            data: {
                labels: $($timestamps | ConvertTo-Json),
                datasets: [{
                    label: 'Mémoire Processus (MB)',
                    data: $($processMemoryData | ConvertTo-Json),
                    borderColor: 'rgba(153, 102, 255, 1)',
                    fill: false
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    </script>
</body>
</html>
"@

            # Ajouter le script JavaScript au contenu HTML
            $htmlContent += $jsScript

            # Écrire le contenu HTML dans un fichier
            $htmlContent | Out-File -FilePath $reportFile -Encoding utf8

            Write-Log "Rapport de monitoring généré: $reportFile" -Level "SUCCESS"

            # Envoyer le rapport par email si demandé
            if ($Final) {
                Send-EmailAlert -Subject "Rapport Final de Monitoring" -Body "Veuillez trouver ci-joint le rapport final de monitoring du traitement de données." -Attachments $reportFile
            }

            return $reportFile
        }
        else {
            Write-Log "Aucune donnée de ressource disponible pour générer le rapport" -Level "WARNING"
            return $null
        }
    }
    catch {
        Write-Log "ERREUR lors de la génération du rapport: $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}
```

# Partie 3 : Script principal et vérification du heartbeat

```powershell
# ===== SCRIPT PRINCIPAL =====

Write-Log "===== DÉMARRAGE DU PROCESSUS DE TRAITEMENT DE DONNÉES =====" -Level "INFO"

# Initialiser ou charger l'état
$state = Get-ProcessingState
if ($null -eq $state) {
    $state = @{
        StartTime = Get-Date
        LastProcessedIndex = 0
        ProcessedItems = 0
        SkippedItems = 0
        Errors = 0
    }
    Write-Log "Nouvel état initialisé" -Level "INFO"
}

# Variables pour le suivi des intervalles
$lastHeartbeat = Get-Date
$lastResourceCheck = Get-Date
$lastReport = Get-Date
$startIndex = $state.LastProcessedIndex

# Créer le premier heartbeat
Update-Heartbeat

# Effectuer la première vérification des ressources
$initialResources = Monitor-Resources
Write-Log "Ressources initiales - CPU: $($initialResources.CPU_Percent)%, Mémoire: $($initialResources.Memory_Percent)%, Disque: $($initialResources.Disk_Free_GB) GB libres" -Level "INFO"

# Simuler un traitement de données volumineuses
try {
    for ($i = $startIndex; $i -lt $config.TotalDataItems; $i++) {
        $currentTime = Get-Date

        # Mettre à jour l'état
        $state.LastProcessedIndex = $i

        # Afficher la progression
        $percentComplete = ($i / $config.TotalDataItems) * 100
        Write-Progress -Activity "Traitement des données" -Status "Élément $($i+1) sur $($config.TotalDataItems)" -PercentComplete $percentComplete

        # Vérifier si c'est le moment de mettre à jour le heartbeat
        if (($currentTime - $lastHeartbeat).TotalMinutes -ge $config.HeartbeatInterval) {
            Update-Heartbeat
            $lastHeartbeat = $currentTime
        }

        # Vérifier si c'est le moment de surveiller les ressources
        if (($currentTime - $lastResourceCheck).TotalMinutes -ge $config.ResourceInterval) {
            Monitor-Resources
            $lastResourceCheck = $currentTime
        }

        # Vérifier si c'est le moment de générer un rapport intermédiaire
        if (($currentTime - $lastReport).TotalMinutes -ge $config.ReportInterval) {
            New-MonitoringReport
            $lastReport = $currentTime
        }

        # Simuler le traitement d'un élément (avec probabilité d'erreur)
        try {
            # Code de traitement simulé
            Write-Log "Traitement de l'élément $($i+1)" -Level "DEBUG" -NoConsole

            # Simuler différents temps de traitement
            $sleepTime = Get-Random -Minimum 10 -Maximum 100
            Start-Sleep -Milliseconds $sleepTime

            # Simuler occasionnellement une erreur (1% de chance)
            if (Get-Random -Minimum 1 -Maximum 101 -eq 100) {
                throw "Erreur simulée pour le test"
            }

            # Incrémenter le compteur de traitement
            $state.ProcessedItems++
        }
        catch {
            Write-Log "ERREUR lors du traitement de l'élément $($i+1): $($_.Exception.Message)" -Level "ERROR"
            $state.Errors++
        }

        # Sauvegarder l'état à intervalles réguliers
        if ($i % $config.CheckpointInterval -eq 0) {
            Save-ProcessingState -State $state
        }
    }

    # Marquer la progression comme terminée
    Write-Progress -Activity "Traitement des données" -Completed

    # Calculer les statistiques finales
    $duration = (Get-Date) - $state.StartTime
    $durationFormatted = "{0:D2}h {1:D2}m {2:D2}s" -f $duration.Hours, $duration.Minutes, $duration.Seconds
    $itemsPerSecond = [math]::Round($state.ProcessedItems / $duration.TotalSeconds, 2)

    # Effectuer une dernière vérification des ressources
    $finalResources = Monitor-Resources

    # Générer le rapport final
    Write-Log "Génération du rapport final..." -Level "INFO"
    $finalReport = New-MonitoringReport -Final

    # Résumé final dans le log
    Write-Log "===== RÉSUMÉ DU TRAITEMENT =====" -Level "SUCCESS"
    Write-Log "Date de début: $($state.StartTime)" -Level "INFO"
    Write-Log "Date de fin: $(Get-Date)" -Level "INFO"
    Write-Log "Durée totale: $durationFormatted" -Level "INFO"
    Write-Log "Éléments traités: $($state.ProcessedItems)" -Level "INFO"
    Write-Log "Erreurs rencontrées: $($state.Errors)" -Level "INFO"
    Write-Log "Performance: $itemsPerSecond éléments/seconde" -Level "INFO"
    Write-Log "Rapport final: $finalReport" -Level "INFO"

    # Envoyer une notification de fin
    Send-EmailAlert -Subject "Traitement de données terminé" -Body "Le traitement est terminé avec $($state.ProcessedItems) éléments traités et $($state.Errors) erreurs. Durée: $durationFormatted"
}
catch {
    Write-Log "ERREUR CRITIQUE: $($_.Exception.Message)" -Level "CRITICAL"
    Write-Log $_.ScriptStackTrace -Level "ERROR"

    # Sauvegarder l'état en cas d'erreur
    Save-ProcessingState -State $state

    # Envoyer une alerte critique
    Send-EmailAlert -Subject "ERREUR CRITIQUE: Traitement interrompu" -Body "Le traitement a été interrompu en raison d'une erreur critique: $($_.Exception.Message)`n`nConsultez le journal pour plus de détails: $logFile"
}
finally {
    # Nettoyer et arrêter la journalisation
    Write-Log "===== FIN DU PROCESSUS =====" -Level "INFO"
    Stop-Transcript
}

# ===== SCRIPT DE VÉRIFICATION DU HEARTBEAT (À EXÉCUTER DANS UNE TÂCHE PLANIFIÉE SÉPARÉE) =====

<#
# Enregistrez ce code dans un fichier séparé pour surveiller le heartbeat depuis une tâche planifiée
# Exemple: Check-Heartbeat.ps1

param (
    [string]$HeartbeatFile = "C:\MonitoringSystem\heartbeat.txt",
    [int]$MaxAgeMinutes = 10,
    [string]$EmailTo = "admin@exemple.com",
    [string]$EmailFrom = "monitoring@exemple.com",
    [string]$SmtpServer = "smtp.exemple.com",
    [int]$SmtpPort = 25
)

# Vérifier si le fichier heartbeat existe
if (-not (Test-Path $HeartbeatFile)) {
    Write-Warning "Le fichier heartbeat n'existe pas: $HeartbeatFile"

    # Envoyer une alerte par email
    $emailParams = @{
        To = $EmailTo
        From = $EmailFrom
        Subject = "ALERTE: Fichier heartbeat introuvable"
        Body = "Le fichier heartbeat n'a pas été trouvé: $HeartbeatFile`n`nLe script est peut-être arrêté ou n'a jamais démarré."
        SmtpServer = $SmtpServer
        Port = $SmtpPort
    }

    try {
        Send-MailMessage @emailParams
    }
    catch {
        Write-Error "Impossible d'envoyer l'email d'alerte: $($_.Exception.Message)"
    }

    exit 1
}

# Lire et parser le fichier heartbeat
try {
    $heartbeatData = Get-Content -Path $HeartbeatFile -Raw | ConvertFrom-Json
    $lastBeat = [DateTime]$heartbeatData.Timestamp
    $processId = $heartbeatData.ProcessID
    $lastItem = $heartbeatData.LastProcessedItem
}
catch {
    Write-Error "Impossible de lire le fichier heartbeat: $($_.Exception.Message)"
    exit 1
}

# Vérifier l'âge du heartbeat
$age = (Get-Date) - $lastBeat
if ($age.TotalMinutes -gt $MaxAgeMinutes) {
    Write-Warning "Le heartbeat est trop ancien: $($age.TotalMinutes) minutes (max: $MaxAgeMinutes minutes)"

    # Vérifier si le processus existe toujours
    $processRunning = Get-Process -Id $processId -ErrorAction SilentlyContinue
    $processStatus = if ($processRunning) { "En cours d'exécution" } else { "Arrêté" }

    # Envoyer une alerte par email
    $emailParams = @{
        To = $EmailTo
        From = $EmailFrom
        Subject = "ALERTE: Script bloqué ou arrêté"
        Body = @"
Le script de traitement semble bloqué ou arrêté.

Informations du heartbeat:
- Dernier battement: $lastBeat
- Âge: $($age.TotalMinutes) minutes
- Processus ID: $processId (État actuel: $processStatus)
- Dernier élément traité: $lastItem

Veuillez vérifier l'état du script.
"@
        SmtpServer = $SmtpServer
        Port = $SmtpPort
    }

    try {
        Send-MailMessage @emailParams
    }
    catch {
        Write-Error "Impossible d'envoyer l'email d'alerte: $($_.Exception.Message)"
    }

    exit 1
}
else {
    Write-Host "Le heartbeat est à jour. Dernier battement il y a $($age.TotalMinutes) minutes."
    exit 0
}
#>
```

Cette solution complète implémente un système de monitoring avancé pour les scripts PowerShell longue durée. Les trois parties ensemble créent une solution robuste qui inclut :

1. **Journalisation multi-niveau** avec différents fichiers de logs par niveau de gravité
2. **Système de heartbeat** pour détecter les blocages ou arrêts
3. **Surveillance des ressources** (CPU, mémoire, disque) avec alertes sur seuils
4. **Points de contrôle** pour reprendre l'exécution après une interruption
5. **Notifications par email** pour les alertes et rapports
6. **Rapports graphiques HTML** utilisant Chart.js pour visualiser les métriques
7. **Métriques de performance** calculant le taux de traitement et estimant le temps restant

Le script principal est accompagné d'un script secondaire de vérification du heartbeat, conçu pour être exécuté comme une tâche planifiée séparée qui surveille l'activité du script principal et envoie des alertes si aucun signe d'activité n'est détecté pendant une période configurable.

Cette solution peut être facilement adaptée à n'importe quel traitement longue durée en remplaçant la partie simulation par votre propre logique de traitement.
