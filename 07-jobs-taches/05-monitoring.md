# Module 8 - Jobs, tâches planifiées et parallélisme
## 8-5. Monitoring de scripts longue durée

### Introduction au monitoring de scripts

Imaginez que vous avez créé un script PowerShell qui doit s'exécuter pendant plusieurs heures, voire plusieurs jours. Comment savoir s'il fonctionne correctement ? Comment être alerté en cas de problème ? Comment suivre sa progression ? C'est là qu'intervient le **monitoring de scripts longue durée**.

Dans cette section, nous allons découvrir différentes techniques pour surveiller vos scripts PowerShell qui s'exécutent sur de longues périodes, afin de :
- Suivre leur progression en temps réel
- Être alerté en cas d'erreur ou de blocage
- Conserver un historique des exécutions
- Reprendre l'exécution en cas d'interruption

### Pourquoi surveiller les scripts longue durée ?

Les scripts qui s'exécutent pendant longtemps peuvent rencontrer divers problèmes :
- Blocages ou plantages
- Erreurs inattendues
- Consommation excessive de ressources
- Perte de connexion réseau ou d'accès aux ressources
- Interruptions système (redémarrage, mise à jour)

Une bonne stratégie de monitoring vous permet de détecter ces problèmes rapidement et d'y répondre de manière appropriée.

### Techniques de base pour le monitoring

#### 1. Journalisation (logging)

La journalisation est la technique la plus fondamentale pour surveiller un script. Elle consiste à enregistrer les événements, actions et erreurs qui se produisent pendant l'exécution.

##### a) Utiliser Start-Transcript

```powershell
# Au début de votre script
$logPath = "C:\Logs\MonScript"
if (-not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType Directory -Force }
$logFile = "$logPath\Execution_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile -Append

# Votre code ici...

# À la fin de votre script
Stop-Transcript
```

`Start-Transcript` capture toute la sortie de la console PowerShell dans un fichier texte, ce qui vous permet de voir exactement ce qui s'est passé pendant l'exécution.

##### b) Créer une fonction de journalisation personnalisée

```powershell
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogFile = "C:\Logs\MonScript\Execution.log"
    )

    # Créer le dossier de logs s'il n'existe pas
    $logFolder = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }

    # Formater le message de log
    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $formattedMessage = "[$timeStamp] [$Level] $Message"

    # Écrire dans le fichier de log
    $formattedMessage | Out-File -FilePath $LogFile -Append

    # Afficher également dans la console avec un code couleur
    switch ($Level) {
        "ERROR" { Write-Host $formattedMessage -ForegroundColor Red }
        "WARNING" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $formattedMessage -ForegroundColor Green }
        default { Write-Host $formattedMessage }
    }
}

# Exemple d'utilisation
Write-Log "Démarrage du script" -Level "INFO"
Write-Log "Opération réussie" -Level "SUCCESS"
Write-Log "Attention, valeur inhabituelle détectée" -Level "WARNING"
Write-Log "Échec de la connexion à la base de données" -Level "ERROR"
```

Cette fonction vous permet de personnaliser davantage vos logs et d'ajouter des niveaux de gravité (INFO, WARNING, ERROR, etc.).

#### 2. Barre de progression et indicateurs d'avancement

Pour suivre visuellement la progression de votre script, vous pouvez utiliser `Write-Progress` :

```powershell
$totalItems = 1000
for ($i = 1; $i -le $totalItems; $i++) {
    # Calculer le pourcentage d'avancement
    $percentComplete = ($i / $totalItems) * 100

    # Afficher la barre de progression
    Write-Progress -Activity "Traitement des éléments" -Status "Progression: $i sur $totalItems" -PercentComplete $percentComplete

    # Votre code de traitement ici...
    Start-Sleep -Milliseconds 50  # Simuler un traitement

    # Afficher un message de log tous les 100 éléments
    if ($i % 100 -eq 0) {
        Write-Log "Traitement de l'élément $i terminé" -Level "INFO"
    }
}

# Effacer la barre de progression à la fin
Write-Progress -Activity "Traitement des éléments" -Completed
```

Cette technique est particulièrement utile lorsque vous traitez un grand nombre d'éléments et souhaitez voir la progression en temps réel.

#### 3. Notifications par email

Pour être alerté en cas de problème ou lorsque le script se termine, vous pouvez envoyer des emails :

```powershell
function Send-EmailAlert {
    param (
        [string]$Subject,
        [string]$Body,
        [string]$To = "votre.email@exemple.com",
        [string]$From = "alerte.script@votreentreprise.com",
        [string]$SmtpServer = "smtp.votreentreprise.com"
    )

    try {
        $params = @{
            From = $From
            To = $To
            Subject = $Subject
            Body = $Body
            SmtpServer = $SmtpServer
            Port = 25
            UseSSL = $false
        }

        Send-MailMessage @params
        Write-Log "Email d'alerte envoyé: $Subject" -Level "INFO"
        return $true
    }
    catch {
        Write-Log "Échec de l'envoi d'email: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Exemples d'utilisation
Send-EmailAlert -Subject "Script de sauvegarde terminé" -Body "La sauvegarde s'est terminée avec succès à $(Get-Date)"

# En cas d'erreur
try {
    # Votre code ici...
}
catch {
    Send-EmailAlert -Subject "ERREUR: Script de sauvegarde" -Body "Une erreur s'est produite: $($_.Exception.Message)"
}
```

> **Note :** Vous devrez ajuster les paramètres SMTP en fonction de votre environnement. Dans certains cas, vous devrez également fournir des identifiants d'authentification.

### Techniques avancées de monitoring

#### 1. Fichiers de heartbeat (battement de cœur)

Un "heartbeat" est un signal périodique qui indique que votre script est toujours en cours d'exécution. C'est une technique simple mais efficace :

```powershell
function Update-Heartbeat {
    param(
        [string]$HeartbeatFile = "C:\Logs\MonScript\heartbeat.txt"
    )

    # Créer le dossier si nécessaire
    $folder = Split-Path -Path $HeartbeatFile -Parent
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    # Mettre à jour le fichier heartbeat avec l'horodatage actuel
    Get-Date | Out-File -FilePath $HeartbeatFile -Force
    Write-Log "Heartbeat mis à jour à $(Get-Date)" -Level "INFO"
}

# Dans votre boucle principale ou à des points clés de votre script
while ($true) {
    # Mettre à jour le heartbeat toutes les 5 minutes
    Update-Heartbeat

    # Votre code ici...

    Start-Sleep -Seconds 300  # 5 minutes
}
```

Un autre script ou service peut ensuite vérifier régulièrement ce fichier heartbeat et vous alerter si aucune mise à jour n'a été effectuée depuis un certain temps.

#### 2. Fichier d'état et points de contrôle (checkpoints)

Pour les scripts très longs, il est utile de sauvegarder périodiquement l'état d'avancement pour pouvoir reprendre en cas d'interruption :

```powershell
# Configuration
$stateFile = "C:\Logs\MonScript\etat.json"
$items = @(1..1000)  # Éléments à traiter

# Charger l'état précédent s'il existe
$state = @{
    LastProcessedIndex = 0
    StartTime = Get-Date
    ProcessedItems = 0
    Errors = 0
}

if (Test-Path $stateFile) {
    try {
        $savedState = Get-Content -Path $stateFile -Raw | ConvertFrom-Json
        $state.LastProcessedIndex = $savedState.LastProcessedIndex
        $state.StartTime = [DateTime]::Parse($savedState.StartTime)
        $state.ProcessedItems = $savedState.ProcessedItems
        $state.Errors = $savedState.Errors

        Write-Log "État précédent chargé. Reprise à partir de l'index $($state.LastProcessedIndex)" -Level "INFO"
    }
    catch {
        Write-Log "Impossible de charger l'état précédent. Démarrage d'une nouvelle exécution." -Level "WARNING"
    }
}

# Fonction pour sauvegarder l'état
function Save-State {
    param($CurrentState)

    $folder = Split-Path -Path $stateFile -Parent
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    $CurrentState | ConvertTo-Json | Out-File -FilePath $stateFile -Force
    Write-Log "État sauvegardé à l'index $($CurrentState.LastProcessedIndex)" -Level "INFO"
}

# Traiter les éléments à partir du dernier index
$totalItems = $items.Count
for ($i = $state.LastProcessedIndex; $i -lt $totalItems; $i++) {
    try {
        # Afficher la progression
        $percentComplete = ($i / $totalItems) * 100
        Write-Progress -Activity "Traitement des éléments" -Status "Progression: $i sur $totalItems" -PercentComplete $percentComplete

        # Votre code de traitement ici...
        $item = $items[$i]
        Write-Log "Traitement de l'élément $item" -Level "INFO"
        Start-Sleep -Milliseconds 100  # Simuler un traitement

        # Mettre à jour l'état
        $state.LastProcessedIndex = $i + 1
        $state.ProcessedItems++

        # Sauvegarder l'état tous les 50 éléments
        if ($i % 50 -eq 0) {
            Save-State -CurrentState $state
        }
    }
    catch {
        Write-Log "Erreur lors du traitement de l'élément à l'index $i : $($_.Exception.Message)" -Level "ERROR"
        $state.Errors++
    }
}

# Sauvegarder l'état final
Save-State -CurrentState $state

# Calculer les statistiques
$duration = (Get-Date) - $state.StartTime
$itemsPerSecond = $state.ProcessedItems / $duration.TotalSeconds

# Afficher le résumé
Write-Log "Traitement terminé. $($state.ProcessedItems) éléments traités en $($duration.ToString('hh\:mm\:ss'))" -Level "SUCCESS"
Write-Log "Performances: $($itemsPerSecond.ToString('0.00')) éléments/seconde" -Level "INFO"
Write-Log "Nombre d'erreurs rencontrées: $($state.Errors)" -Level "INFO"
```

Cette technique vous permet de reprendre le traitement là où il s'était arrêté en cas d'interruption du script.

#### 3. Surveillance des ressources

Pour les scripts qui consomment beaucoup de ressources, il est important de surveiller l'utilisation du CPU, de la mémoire et du disque :

```powershell
function Get-ResourceUsage {
    # Obtenir l'utilisation CPU
    $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
    $cpuPercent = [math]::Round($cpuUsage.CounterSamples.CookedValue, 2)

    # Obtenir l'utilisation mémoire
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $memoryUsed = $osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory
    $memoryPercent = [math]::Round(($memoryUsed / $osInfo.TotalVisibleMemorySize) * 100, 2)

    # Obtenir l'espace disque
    $driveC = Get-PSDrive C
    $diskFreeGB = [math]::Round($driveC.Free / 1GB, 2)
    $diskTotalGB = [math]::Round(($driveC.Used + $driveC.Free) / 1GB, 2)
    $diskPercent = [math]::Round(($driveC.Used / ($driveC.Used + $driveC.Free)) * 100, 2)

    # Retourner un objet avec les informations
    return [PSCustomObject]@{
        CPU = $cpuPercent
        Memory = $memoryPercent
        DiskFreeGB = $diskFreeGB
        DiskUsagePercent = $diskPercent
        Timestamp = Get-Date
    }
}

# Dans votre script, surveillez périodiquement les ressources
$resourceLog = "C:\Logs\MonScript\ressources.csv"

# Créer l'en-tête du fichier CSV s'il n'existe pas
if (-not (Test-Path $resourceLog)) {
    "Timestamp,CPU,Memory,DiskFreeGB,DiskUsagePercent" | Out-File -FilePath $resourceLog -Force
}

# Boucle principale
while ($true) {
    # Surveiller les ressources
    $resources = Get-ResourceUsage

    # Journaliser les ressources au format CSV
    "$($resources.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')),$($resources.CPU),$($resources.Memory),$($resources.DiskFreeGB),$($resources.DiskUsagePercent)" |
        Out-File -FilePath $resourceLog -Append

    # Vérifier si les ressources sont critiques
    if ($resources.CPU -gt 90) {
        Write-Log "ALERTE: Utilisation CPU élevée ($($resources.CPU)%)" -Level "WARNING"
    }

    if ($resources.Memory -gt 90) {
        Write-Log "ALERTE: Utilisation mémoire élevée ($($resources.Memory)%)" -Level "WARNING"
    }

    if ($resources.DiskFreeGB -lt 5) {
        Write-Log "ALERTE: Espace disque critique ($($resources.DiskFreeGB) GB restants)" -Level "WARNING"
    }

    # Votre code ici...

    # Attendre avant la prochaine vérification
    Start-Sleep -Seconds 300  # Vérifier toutes les 5 minutes
}
```

Ces données peuvent ensuite être utilisées pour créer des graphiques et analyser les performances de votre script.

### Intégration avec des outils de monitoring externes

Pour les environnements d'entreprise, vous pouvez intégrer vos scripts avec des outils de monitoring professionnels :

#### 1. Journaux d'événements Windows

Vous pouvez écrire des événements dans le journal d'événements Windows pour une intégration avec des outils comme SCOM, Nagios, ou SolarWinds :

```powershell
function Write-EventLog {
    param (
        [string]$Message,
        [string]$Source = "MonScriptPowerShell",
        [string]$LogName = "Application",
        [ValidateSet("Information", "Warning", "Error")]
        [string]$EntryType = "Information"
    )

    # Créer la source si elle n'existe pas
    if (-not [System.Diagnostics.EventLog]::SourceExists($Source)) {
        [System.Diagnostics.EventLog]::CreateEventSource($Source, $LogName)
        Write-Log "Source d'événement '$Source' créée" -Level "INFO"
    }

    # Écrire l'événement
    [System.Diagnostics.EventLog]::WriteEntry($Source, $Message, $EntryType)
    Write-Log "Événement écrit dans le journal '$LogName' (Type: $EntryType)" -Level "INFO"
}

# Exemple d'utilisation
Write-EventLog -Message "Le script a démarré normalement" -EntryType "Information"
Write-EventLog -Message "Attention: espace disque inférieur à 10%" -EntryType "Warning"
Write-EventLog -Message "Erreur critique: impossible d'accéder à la base de données" -EntryType "Error"
```

#### 2. API REST pour les systèmes de monitoring

Si vous utilisez des outils comme Prometheus, Grafana ou ELK Stack, vous pouvez envoyer des métriques via API REST :

```powershell
function Send-Metric {
    param (
        [string]$MetricName,
        [double]$Value,
        [hashtable]$Labels = @{},
        [string]$PrometheusUrl = "http://prometheus:9091/metrics/job/powershell_scripts"
    )

    try {
        # Formater les labels Prometheus
        $labelStr = ($Labels.GetEnumerator() | ForEach-Object { "$($_.Key)=`"$($_.Value)`"" }) -join ","
        if ($Labels.Count -gt 0) {
            $labelStr = "{$labelStr}"
        }

        # Construire la ligne de métrique
        $metricLine = "$MetricName$labelStr $Value"

        # Envoyer la métrique
        Invoke-RestMethod -Uri $PrometheusUrl -Method Post -Body $metricLine -ContentType "text/plain"

        Write-Log "Métrique envoyée: $metricLine" -Level "INFO"
        return $true
    }
    catch {
        Write-Log "Échec de l'envoi de la métrique: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Exemple d'utilisation
Send-Metric -MetricName "script_processed_items_total" -Value 150 -Labels @{script_name = "backup_script"; status = "success"}
Send-Metric -MetricName "script_execution_time_seconds" -Value 3600 -Labels @{script_name = "backup_script"}
Send-Metric -MetricName "script_errors_total" -Value 2 -Labels @{script_name = "backup_script"; error_type = "network"}
```

### Bonnes pratiques pour le monitoring de scripts longue durée

1. **Combinez plusieurs méthodes** : Utilisez une combinaison de journalisation, de heartbeats et de notifications pour une surveillance complète.

2. **Planifiez la rotation des journaux** : Les scripts longue durée peuvent générer d'énormes fichiers journaux. Mettez en place une rotation (par date ou par taille) pour éviter de saturer votre disque.

3. **Stratégie de reprise** : Concevez vos scripts pour qu'ils puissent reprendre après une interruption plutôt que de tout recommencer.

4. **Logs structurés** : Utilisez un format structuré (JSON, CSV) pour vos logs afin de faciliter leur analyse automatisée.

5. **Alertes graduées** : Définissez différents niveaux d'alerte pour éviter la "fatigue d'alerte" (trop d'alertes tuent l'alerte).

6. **Surveillance des dépendances** : Surveillez également les systèmes dont dépend votre script (serveurs, bases de données, API, etc.).

7. **Métriques de performance** : Collectez des métriques sur les performances de votre script pour identifier les goulets d'étranglement.

### Exemple complet : Script de sauvegarde avec monitoring

Voici un exemple complet qui illustre les différentes techniques de monitoring dans un script de sauvegarde :

```powershell
#Requires -Version 5.1

# Script de sauvegarde avec monitoring complet
# ============================================

# Configuration
$config = @{
    # Dossiers à sauvegarder
    SourceFolders = @(
        "C:\Important\Documents",
        "C:\Important\Images",
        "D:\Projets"
    )
    # Destination de la sauvegarde
    DestinationFolder = "E:\Backups"
    # Configuration des logs
    LogFolder = "C:\Logs\BackupScript"
    # Configuration des emails
    EmailSettings = @{
        To = "admin@exemple.com"
        From = "backup@exemple.com"
        SmtpServer = "smtp.exemple.com"
        Port = 25
    }
    # Intervalle de heartbeat (en minutes)
    HeartbeatInterval = 15
    # Intervalle de checkpoint (nombre de dossiers)
    CheckpointInterval = 5
}

# Créer les dossiers nécessaires
$logFolder = $config.LogFolder
$stateFile = "$logFolder\backup_state.json"
$heartbeatFile = "$logFolder\heartbeat.txt"
$resourceLogFile = "$logFolder\resources.csv"

# Créer le dossier de logs s'il n'existe pas
if (-not (Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Initialiser la journalisation
$logFile = "$logFolder\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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

    # Déjà écrit dans le transcript, pas besoin de l'écrire dans un fichier séparé
}

# Fonction d'envoi d'email
function Send-EmailAlert {
    param (
        [string]$Subject,
        [string]$Body
    )

    $emailParams = @{
        To = $config.EmailSettings.To
        From = $config.EmailSettings.From
        Subject = $Subject
        Body = $Body
        SmtpServer = $config.EmailSettings.SmtpServer
        Port = $config.EmailSettings.Port
    }

    try {
        Send-MailMessage @emailParams
        Write-Log "Email envoyé: $Subject" -Level "INFO"
        return $true
    }
    catch {
        Write-Log "Échec de l'envoi d'email: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}

# Fonction pour mettre à jour le heartbeat
function Update-Heartbeat {
    Get-Date | Out-File -FilePath $heartbeatFile -Force
    Write-Log "Heartbeat mis à jour" -Level "INFO"
}

# Fonction pour sauvegarder l'état
function Save-BackupState {
    param($CurrentState)

    $CurrentState | ConvertTo-Json | Out-File -FilePath $stateFile -Force
    Write-Log "État de sauvegarde enregistré" -Level "INFO"
}

# Fonction pour surveiller les ressources
function Monitor-Resources {
    # Vérifier si le fichier de log des ressources existe
    if (-not (Test-Path $resourceLogFile)) {
        "Timestamp,CPU,Memory,DiskFreeGB,BackupSizeGB" | Out-File -FilePath $resourceLogFile -Force
    }

    # Obtenir l'utilisation CPU
    $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
    $cpuPercent = [math]::Round($cpuUsage.CounterSamples.CookedValue, 2)

    # Obtenir l'utilisation mémoire
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $memoryUsed = $osInfo.TotalVisibleMemorySize - $osInfo.FreePhysicalMemory
    $memoryPercent = [math]::Round(($memoryUsed / $osInfo.TotalVisibleMemorySize) * 100, 2)

    # Obtenir l'espace disque destination
    $destDrive = (Split-Path -Path $config.DestinationFolder -Qualifier).TrimEnd(":")
    $destDriveInfo = Get-PSDrive $destDrive
    $diskFreeGB = [math]::Round($destDriveInfo.Free / 1GB, 2)

    # Taille actuelle de la sauvegarde
    $backupSizeGB = 0
    if (Test-Path $config.DestinationFolder) {
        $backupSizeGB = [math]::Round((Get-ChildItem -Path $config.DestinationFolder -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
    }

    # Journaliser les ressources
    "$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss')),$cpuPercent,$memoryPercent,$diskFreeGB,$backupSizeGB" |
        Out-File -FilePath $resourceLogFile -Append

    # Vérifier les seuils critiques
    if ($diskFreeGB -lt 10) {
        Write-Log "ALERTE: Espace disque destination critique ($diskFreeGB GB restants)" -Level "WARNING"
        Send-EmailAlert -Subject "ALERTE: Espace disque faible pour la sauvegarde" -Body "Il reste seulement $diskFreeGB GB sur le disque de destination."
    }

    return @{
        CPU = $cpuPercent
        Memory = $memoryPercent
        DiskFreeGB = $diskFreeGB
        BackupSizeGB = $backupSizeGB
    }
}

# Charger l'état précédent s'il existe
$state = @{
    StartTime = Get-Date
    LastFolder = ""
    ProcessedFolders = 0
    SkippedFolders = 0
    TotalSizeGB = 0
    Errors = 0
    CurrentIndex = 0
}

if (Test-Path $stateFile) {
    try {
        $savedState = Get-Content -Path $stateFile -Raw | ConvertFrom-Json
        # Vérifier si l'état sauvegardé date de moins de 24 heures
        $lastStateTime = [DateTime]::Parse($savedState.StartTime)
        if ((Get-Date) - $lastStateTime -lt [TimeSpan]::FromHours(24)) {
            $state.LastFolder = $savedState.LastFolder
            $state.ProcessedFolders = $savedState.ProcessedFolders
            $state.SkippedFolders = $savedState.SkippedFolders
            $state.TotalSizeGB = $savedState.TotalSizeGB
            $state.Errors = $savedState.Errors
            $state.CurrentIndex = $savedState.CurrentIndex

            Write-Log "État précédent chargé. Reprise à partir du dossier $($state.CurrentIndex)" -Level "INFO"
        }
        else {
            Write-Log "État précédent trop ancien. Démarrage d'une nouvelle sauvegarde." -Level "WARNING"
        }
    }
    catch {
        Write-Log "Impossible de charger l'état précédent: $($_.Exception.Message). Démarrage d'une nouvelle sauvegarde." -Level "WARNING"
    }
}

# Créer le dossier de destination s'il n'existe pas
if (-not (Test-Path $config.DestinationFolder)) {
    try {
        New-Item -Path $config.DestinationFolder -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de destination créé: $($config.DestinationFolder)" -Level "INFO"
    }
    catch {
        Write-Log "Impossible de créer le dossier de destination: $($_.Exception.Message)" -Level "ERROR"
        Send-EmailAlert -Subject "ERREUR: Sauvegarde impossible" -Body "Impossible de créer le dossier de destination: $($_.Exception.Message)"
        Stop-Transcript
        exit 1
    }
}

# Variables pour le timing des opérations périodiques
$lastHeartbeat = Get-Date
$lastResourceCheck = Get-Date

# Notifier le début de la sauvegarde
Write-Log "Démarrage de la sauvegarde avec $($config.SourceFolders.Count) dossiers à traiter" -Level "INFO"
Send-EmailAlert -Subject "Démarrage de la sauvegarde" -Body "La sauvegarde a démarré à $(Get-Date)"

# Boucle principale de sauvegarde
try {
    $totalFolders = $config.SourceFolders.Count

    for ($i = $state.CurrentIndex; $i -lt $totalFolders; $i++) {
        $sourceFolder = $config.SourceFolders[$i]
        $folderName = Split-Path -Path $sourceFolder -Leaf
        $destinationPath = Join-Path -Path $config.DestinationFolder -ChildPath $folderName

        # Afficher la progression
        $percentComplete = ($i / $totalFolders) * 100
        Write-Progress -Activity "Sauvegarde en cours" -Status "Dossier: $folderName" -PercentComplete $percentComplete

        # Mettre à jour l'état
        $state.CurrentIndex = $i
        $state.LastFolder = $folderName

        # Vérifier si c'est le moment de mettre à jour le heartbeat
        if ((Get-Date) - $lastHeartbeat -gt [TimeSpan]::FromMinutes($config.HeartbeatInterval)) {
            Update-Heartbeat
            $lastHeartbeat = Get-Date
        }

        # Vérifier si c'est le moment de surveiller les ressources
        if ((Get-Date) - $lastResourceCheck -gt [TimeSpan]::FromMinutes(5)) {
            Monitor-Resources
            $lastResourceCheck = Get-Date
        }

        Write-Log "Traitement du dossier $($i+1)/$totalFolders : $sourceFolder" -Level "INFO"

        try {
            # Vérifier si le dossier source existe
            if (-not (Test-Path $sourceFolder)) {
                Write-Log "Le dossier source n'existe pas: $sourceFolder" -Level "WARNING"
                $state.SkippedFolders++
                continue
            }

            # Vérifier si le dossier destination existe, sinon le créer
            if (-not (Test-Path $destinationPath)) {
                New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
                Write-Log "Dossier de destination créé: $destinationPath" -Level "INFO"
            }

            # Calculer la taille totale à copier
            $sizeToBackupBytes = (Get-ChildItem -Path $sourceFolder -Recurse -File | Measure-Object -Property Length -Sum).Sum
            $sizeToBackupGB = [math]::Round($sizeToBackupBytes / 1GB, 2)

            Write-Log "Taille à sauvegarder: $sizeToBackupGB GB" -Level "INFO"

            # Copier les fichiers avec robocopy (plus fiable pour les grands volumes)
            $robocopyArgs = @(
                """$sourceFolder""",
                """$destinationPath""",
                "/E",         # Copier les sous-dossiers, y compris les vides
                "/COPY:DAT",  # Copier les données, attributs et horodatages
                "/R:3",       # Nombre de tentatives en cas d'échec
                "/W:5",       # Temps d'attente entre les tentatives (en secondes)
                "/LOG+:""$logFolder\robocopy_$folderName.log""",  # Journal de robocopy
                "/NP",        # Pas de progression en pourcentage (trop verbeux)
                "/NDL"        # Pas de liste de répertoires
            )

            Write-Log "Démarrage de la copie avec robocopy..." -Level "INFO"

            $robocopyProcess = Start-Process -FilePath "robocopy" -ArgumentList $robocopyArgs -NoNewWindow -PassThru -Wait

            # Interpréter le code de retour de robocopy
            # (0-7 sont des succès avec différents niveaux de copie)
            if ($robocopyProcess.ExitCode -lt 8) {
                Write-Log "Copie réussie pour le dossier: $folderName (Code: $($robocopyProcess.ExitCode))" -Level "SUCCESS"
                $state.ProcessedFolders++
                $state.TotalSizeGB += $sizeToBackupGB
            }
            else {
                Write-Log "Erreurs lors de la copie du dossier: $folderName (Code: $($robocopyProcess.ExitCode))" -Level "ERROR"
                $state.Errors++
            }

            # Sauvegarder l'état à intervalles réguliers
            if ($i % $config.CheckpointInterval -eq 0) {
                Save-BackupState -CurrentState $state
            }
        }
        catch {
            Write-Log "Exception lors du traitement du dossier $folderName : $($_.Exception.Message)" -Level "ERROR"
            $state.Errors++
        }
    }

    # Marquer la progression comme terminée
    Write-Progress -Activity "Sauvegarde en cours" -Completed

    # Sauvegarder l'état final
    Save-BackupState -CurrentState $state

    # Vérification finale des ressources
    $finalResources = Monitor-Resources

    # Calculer les statistiques
    $duration = (Get-Date) - $state.StartTime
    $durationFormatted = "{0:D2}h {1:D2}m {2:D2}s" -f $duration.Hours, $duration.Minutes, $duration.Seconds

    # Générer le rapport de sauvegarde
    $report = @"
RAPPORT DE SAUVEGARDE
=====================
Date et heure de début: $($state.StartTime)
Date et heure de fin: $(Get-Date)
Durée totale: $durationFormatted

STATISTIQUES
-----------
Dossiers traités: $($state.ProcessedFolders)/$totalFolders
Dossiers ignorés: $($state.SkippedFolders)
Erreurs rencontrées: $($state.Errors)
Taille totale sauvegardée: $($state.TotalSizeGB) GB

ÉTAT DES RESSOURCES
-----------------
CPU: $($finalResources.CPU)%
Mémoire: $($finalResources.Memory)%
Espace disque libre: $($finalResources.DiskFreeGB) GB
Taille de la sauvegarde: $($finalResources.BackupSizeGB) GB

"@

    # Journaliser le rapport
    Write-Log $report -Level "INFO"

    # Déterminer le statut global
    if ($state.Errors -eq 0) {
        Write-Log "Sauvegarde terminée avec succès!" -Level "SUCCESS"
        Send-EmailAlert -Subject "Sauvegarde terminée avec succès" -Body $report
    }
    else {
        Write-Log "Sauvegarde terminée avec $($state.Errors) erreurs" -Level "WARNING"
        Send-EmailAlert -Subject "Sauvegarde terminée avec des erreurs" -Body $report
    }
}
catch {
    Write-Log "ERREUR CRITIQUE: $($_.Exception.Message)" -Level "ERROR"
    Write-Log $_.ScriptStackTrace -Level "ERROR"

    # Sauvegarder l'état pour permettre une reprise
    Save-BackupState -CurrentState $state

    # Envoyer une alerte
    Send-EmailAlert -Subject "ERREUR CRITIQUE: Sauvegarde interrompue" -Body "La sauvegarde a été interrompue en raison d'une erreur critique: $($_.Exception.Message)`n`nConsultez le journal pour plus de détails: $logFile"
}
finally {
    # Nettoyer et arrêter la journalisation
    Stop-Transcript
}
```

Cette exemple complet montre comment :
- Journaliser toutes les actions et erreurs
- Utiliser des mécanismes de heartbeat et de checkpoint
- Surveiller les ressources système
- Envoyer des notifications par email
- Générer un rapport détaillé
- Reprendre après une interruption

### Visualiser les données de monitoring

Une fois que vous avez collecté des données de monitoring, vous pouvez les visualiser pour mieux comprendre le comportement de votre script. Voici un exemple simple pour générer un graphique de l'utilisation des ressources :

```powershell
# Installer le module necessaire si ce n'est pas déjà fait
# Install-Module -Name PSWriteHTML -Force

# Importer le module
Import-Module PSWriteHTML

# Charger les données de ressources
$resourceData = Import-Csv -Path "C:\Logs\BackupScript\resources.csv"

# Convertir les données pour le graphique
$timestamps = $resourceData.Timestamp
$cpuData = $resourceData.CPU | ForEach-Object { [double]$_ }
$memoryData = $resourceData.Memory | ForEach-Object { [double]$_ }
$diskFreeData = $resourceData.DiskFreeGB | ForEach-Object { [double]$_ }

# Générer un rapport HTML avec graphiques
New-HTML -TitleText "Monitoring du Script de Sauvegarde" -FilePath "C:\Logs\BackupScript\rapport.html" {
    New-HTMLSection -HeaderText "Utilisation des Ressources" {
        New-HTMLPanel {
            New-HTMLChart {
                New-ChartToolbar -Download
                New-ChartLegend -Name "CPU (%)", "Mémoire (%)", "Espace Disque Libre (GB)"
                New-ChartAxisX -Name "Temps" -Categories $timestamps
                New-ChartAxisY -Name "Pourcentage / GB" -Show
                New-ChartLine -Name "CPU (%)" -Value $cpuData
                New-ChartLine -Name "Mémoire (%)" -Value $memoryData
                New-ChartLine -Name "Espace Disque Libre (GB)" -Value $diskFreeData
            }
        }
    }
}

# Ouvrir le rapport dans le navigateur
Invoke-Item "C:\Logs\BackupScript\rapport.html"
```

Ce script génère un graphique interactif qui vous permet de visualiser l'évolution de l'utilisation des ressources au fil du temps.

### Conclusion

Le monitoring de scripts longue durée est essentiel pour garantir leur bon fonctionnement et détecter rapidement les problèmes. En combinant différentes techniques (journalisation, heartbeats, points de contrôle, surveillance des ressources et notifications), vous pouvez créer un système de surveillance robuste adapté à vos besoins spécifiques.

N'oubliez pas que le monitoring ne se limite pas à la détection des problèmes, mais vous aide également à comprendre le comportement de vos scripts, à optimiser leurs performances et à planifier les ressources nécessaires.

Dans les modules suivants, nous explorerons d'autres aspects avancés de PowerShell pour vous aider à construire des solutions d'automatisation professionnelles et fiables.

### Exercices pratiques

1. **Exercice simple** : Modifiez le script de l'exercice 1 du module 8-4 (service d'horodatage) pour ajouter une fonctionnalité de monitoring avec journalisation et heartbeat.

2. **Exercice intermédiaire** : Créez un script qui traite un grand nombre de fichiers (par exemple, renomme des images) avec une barre de progression, des points de contrôle et la possibilité de reprendre après une interruption.

3. **Exercice avancé** : Développez un système de monitoring complet pour un script longue durée qui inclut la journalisation, les heartbeats, la surveillance des ressources, les notifications par email et la génération de rapports graphiques.
