# Solutions aux exercices - Module 8-3
## Planification via le Planificateur de tâches Windows

Voici les solutions détaillées aux exercices proposés dans le module 8-3 concernant la planification de tâches PowerShell.

### Solution de l'exercice 1: "Bonjour Monde" quotidien

**Objectif**: Créer une tâche planifiée qui exécute un script affichant "Bonjour Monde" chaque jour à une heure spécifique.

#### Étape 1: Créer le script HelloWorld.ps1

Créez un fichier nommé `HelloWorld.ps1` dans le dossier de votre choix (exemple: `C:\Scripts\HelloWorld.ps1`).

```powershell
# HelloWorld.ps1
# Un script simple qui affiche un message et enregistre la date et l'heure d'exécution

# Démarrer la journalisation
$logFolder = "C:\Logs\HelloWorld"
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

$logFile = "$logFolder\HelloWorld_$(Get-Date -Format 'yyyyMMdd').log"
$timestamp = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

# Écrire le message
$message = "Bonjour Monde! Exécuté le $timestamp"
$message | Out-File -FilePath $logFile -Append

# Afficher le message (visible uniquement si exécuté manuellement)
Write-Host $message -ForegroundColor Green

# Optionnel: Créer une notification Windows si exécuté en arrière-plan
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.MessageBox]::Show($message, "Message PowerShell", "OK", "Information")
```

#### Étape 2: Méthode via l'interface graphique

1. Ouvrez le Planificateur de tâches (Win+R puis `taskschd.msc`)
2. Dans le panneau Actions (à droite), cliquez sur "Créer une tâche basique..."
3. Nommez votre tâche "HelloWorld_Quotidien" et ajoutez une description
4. Sélectionnez "Quotidiennement" comme déclencheur
5. Choisissez l'heure d'exécution (ex: 09:00)
6. Pour l'action, sélectionnez "Démarrer un programme"
7. Dans Programme/script, entrez: `powershell.exe`
8. Dans Arguments, entrez: `-ExecutionPolicy Bypass -NoProfile -File "C:\Scripts\HelloWorld.ps1"`
9. Finalisez la création de la tâche

#### Étape 3: Méthode via PowerShell

```powershell
# Créer une tâche planifiée pour HelloWorld.ps1
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-ExecutionPolicy Bypass -NoProfile -File "C:\Scripts\HelloWorld.ps1"'

# Déclencher tous les jours à 9h00
$trigger = New-ScheduledTaskTrigger -Daily -At '09:00'

# Créer la tâche planifiée
Register-ScheduledTask -TaskName "HelloWorld_Quotidien" `
    -Action $action `
    -Trigger $trigger `
    -Description "Affiche un message Bonjour Monde quotidiennement" `
    -RunLevel Highest
```

#### Vérification

Pour vérifier si la tâche fonctionne correctement:

```powershell
# Exécuter manuellement la tâche pour tester
Start-ScheduledTask -TaskName "HelloWorld_Quotidien"

# Vérifier que le fichier de log a été créé
Get-Content "C:\Logs\HelloWorld\HelloWorld_$(Get-Date -Format 'yyyyMMdd').log"
```

---

### Solution de l'exercice 2: Nettoyage des fichiers temporaires

**Objectif**: Créer un script qui nettoie les fichiers temporaires de votre système, puis planifier son exécution hebdomadaire.

#### Étape 1: Créer le script CleanTemp.ps1

Créez un fichier nommé `CleanTemp.ps1` dans le dossier de votre choix (exemple: `C:\Scripts\CleanTemp.ps1`).

```powershell
# CleanTemp.ps1
# Script pour nettoyer les fichiers temporaires du système

# Démarrer la journalisation
$logFolder = "C:\Logs\CleanTemp"
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

$logFile = "$logFolder\CleanTemp_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
Start-Transcript -Path $logFile

# Définir les dossiers à nettoyer
$dossiersTempANettoyer = @(
    "$env:TEMP",                                      # Dossier temp de l'utilisateur courant
    "$env:SystemRoot\Temp",                           # Dossier temp Windows
    "$env:SystemRoot\SoftwareDistribution\Download",  # Fichiers de mise à jour Windows téléchargés
    "$env:SystemDrive\Windows.old"                    # Ancienne installation Windows (si elle existe)
)

# Définir l'âge minimum des fichiers à supprimer (7 jours)
$dateMinimum = (Get-Date).AddDays(-7)

# Statistiques de nettoyage
$statistiques = @{
    "DossiersAnalysés" = 0
    "FichiersAnalysés" = 0
    "FichiersSupprimes" = 0
    "TailleRécupérée" = 0
    "ErreursSuppression" = 0
}

# Fonction pour convertir les tailles en format lisible
function Convert-Size {
    param([int64]$Size)

    if ($Size -ge 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
    if ($Size -ge 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
    if ($Size -ge 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
    if ($Size -ge 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }

    return "$Size Octets"
}

# Parcourir chaque dossier
foreach ($dossier in $dossiersTempANettoyer) {
    if (Test-Path -Path $dossier) {
        Write-Host "Nettoyage du dossier: $dossier" -ForegroundColor Cyan
        $statistiques.DossiersAnalysés++

        # Obtenir tous les fichiers plus anciens que la date minimum
        try {
            $fichiers = Get-ChildItem -Path $dossier -Recurse -File -ErrorAction SilentlyContinue |
                        Where-Object { $_.LastWriteTime -lt $dateMinimum }

            $statistiques.FichiersAnalysés += $fichiers.Count

            foreach ($fichier in $fichiers) {
                try {
                    # Calculer la taille avant suppression
                    $statistiques.TailleRécupérée += $fichier.Length

                    # Supprimer le fichier
                    Remove-Item -Path $fichier.FullName -Force -ErrorAction Stop
                    Write-Host "  Supprimé: $($fichier.FullName)" -ForegroundColor Green
                    $statistiques.FichiersSupprimes++
                }
                catch {
                    Write-Warning "  Impossible de supprimer: $($fichier.FullName) - $($_.Exception.Message)"
                    $statistiques.ErreursSuppression++
                }
            }

            # Supprimer les dossiers vides
            Get-ChildItem -Path $dossier -Recurse -Directory -ErrorAction SilentlyContinue |
            Where-Object { (Get-ChildItem -Path $_.FullName -Recurse -File).Count -eq 0 } |
            ForEach-Object {
                try {
                    Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
                    Write-Host "  Dossier vide supprimé: $($_.FullName)" -ForegroundColor Green
                }
                catch {
                    # Ignorer les erreurs sur les dossiers vides
                }
            }
        }
        catch {
            Write-Warning "Erreur lors de l'analyse du dossier $dossier : $($_.Exception.Message)"
        }
    }
    else {
        Write-Warning "Le dossier $dossier n'existe pas. Ignoré."
    }
}

# Afficher les statistiques
Write-Host "`nRésumé du nettoyage:" -ForegroundColor Yellow
Write-Host "Dossiers analysés: $($statistiques.DossiersAnalysés)"
Write-Host "Fichiers analysés: $($statistiques.FichiersAnalysés)"
Write-Host "Fichiers supprimés: $($statistiques.FichiersSupprimes)"
Write-Host "Erreurs de suppression: $($statistiques.ErreursSuppression)"
Write-Host "Espace disque récupéré: $(Convert-Size $statistiques.TailleRécupérée)"

Stop-Transcript

# Créer un résumé court pour un éventuel email
$resumeEmail = @"
Nettoyage des fichiers temporaires effectué le $(Get-Date -Format 'dd/MM/yyyy à HH:mm')
- Dossiers analysés: $($statistiques.DossiersAnalysés)
- Fichiers supprimés: $($statistiques.FichiersSupprimes)
- Espace disque récupéré: $(Convert-Size $statistiques.TailleRécupérée)
- Erreurs rencontrées: $($statistiques.ErreursSuppression)
"@

# Écrire le résumé dans un fichier séparé pour un accès facile
$resumeEmail | Out-File -FilePath "$logFolder\DernierNettoyage.txt" -Force
```

#### Étape 2: Planifier l'exécution hebdomadaire via PowerShell

```powershell
# Créer une tâche planifiée pour le nettoyage hebdomadaire
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "C:\Scripts\CleanTemp.ps1"'

# Déclencher tous les dimanches à 1h00 du matin
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At '01:00'

# Configurer des paramètres avancés
$settings = New-ScheduledTaskSettingsSet `
    -RunOnlyIfIdle $false `
    -StartWhenAvailable $true `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
    -RestartCount 2 `
    -RestartInterval (New-TimeSpan -Minutes 10)

# Créer la tâche planifiée avec des privilèges élevés
Register-ScheduledTask -TaskName "Nettoyage_Fichiers_Temporaires" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Nettoie les fichiers temporaires du système chaque semaine" `
    -User "SYSTEM" `
    -RunLevel Highest
```

#### Vérification

```powershell
# Exécuter manuellement la tâche pour tester
Start-ScheduledTask -TaskName "Nettoyage_Fichiers_Temporaires"

# Attendre un peu et vérifier les logs
Start-Sleep -Seconds 10
Get-ChildItem -Path "C:\Logs\CleanTemp" | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Get-Content
```

---

### Solution de l'exercice 3: Monitoring et redémarrage des services

**Objectif**: Créer un script qui vérifie si certains services Windows sont arrêtés et les redémarre si nécessaire. Planifier l'exécution de ce script toutes les heures.

#### Étape 1: Créer le script MonitorServices.ps1

Créez un fichier nommé `MonitorServices.ps1` dans le dossier de votre choix (exemple: `C:\Scripts\MonitorServices.ps1`).

```powershell
# MonitorServices.ps1
# Script pour surveiller et redémarrer des services Windows critiques

# Démarrer la journalisation
$logFolder = "C:\Logs\ServiceMonitor"
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

$logFile = "$logFolder\ServiceMonitor_$(Get-Date -Format 'yyyyMMdd').log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Fonction pour écrire dans le fichier journal
function Write-Log {
    param (
        [string]$Message,
        [string]$LogLevel = "INFO"
    )

    $logMessage = "[$timestamp] [$LogLevel] $Message"
    $logMessage | Out-File -FilePath $logFile -Append

    # Afficher également dans la console si exécuté manuellement
    switch ($LogLevel) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }
}

# Liste des services importants à surveiller
$servicesACritiques = @(
    "wuauserv",       # Windows Update
    "BITS",           # Background Intelligent Transfer Service
    "Spooler",        # Service d'impression
    "wscsvc",         # Centre de sécurité
    "WinDefend",      # Windows Defender
    "LanmanServer"    # Serveur de fichiers
)

Write-Log "Début de la surveillance des services..."

# Variables pour les statistiques
$servicesArretes = 0
$servicesDemarrages = 0
$servicesEchec = 0

# Vérifier chaque service
foreach ($serviceNom in $servicesACritiques) {
    try {
        $service = Get-Service -Name $serviceNom -ErrorAction Stop

        if ($service.Status -ne 'Running') {
            Write-Log "Le service '$($service.DisplayName)' ($serviceNom) est actuellement $($service.Status)" "WARNING"
            $servicesArretes++

            # Tenter de redémarrer le service
            Write-Log "Tentative de démarrage du service '$serviceNom'..."
            Start-Service -Name $serviceNom -ErrorAction Stop

            # Re-vérifier le statut
            $service = Get-Service -Name $serviceNom
            if ($service.Status -eq 'Running') {
                Write-Log "Service '$($service.DisplayName)' démarré avec succès!" "SUCCESS"
                $servicesDemarrages++
            } else {
                Write-Log "Échec du démarrage du service '$($service.DisplayName)' (Statut: $($service.Status))" "ERROR"
                $servicesEchec++
            }
        } else {
            Write-Log "Service '$($service.DisplayName)' ($serviceNom) fonctionne correctement."
        }
    }
    catch {
        Write-Log "Erreur lors de la vérification/démarrage du service '$serviceNom': $($_.Exception.Message)" "ERROR"
        $servicesEchec++
    }
}

# Résumé
$messageFinal = "Résumé de la surveillance: $servicesArretes services arrêtés, $servicesDemarrages redémarrés avec succès, $servicesEchec échecs"
Write-Log $messageFinal "INFO"

# Vérifier si un rapport d'échec est nécessaire
if ($servicesEchec -gt 0) {
    Write-Log "Des échecs ont été rencontrés. Un rapport serait envoyé ici." "WARNING"

    # Ici, vous pourriez ajouter du code pour envoyer un email ou une notification
    # Exemple:
    # Send-MailMessage -To "admin@exemple.com" -Subject "Échecs de services détectés" -Body $messageFinal
}

Write-Log "Fin de la surveillance des services."
```

#### Étape 2: Planifier l'exécution horaire via PowerShell

```powershell
# Créer une tâche planifiée pour la surveillance horaire des services
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "C:\Scripts\MonitorServices.ps1"'

# Déclencher toutes les heures
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration ([TimeSpan]::MaxValue)

# Configurer des paramètres avancés
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries $true `
    -DontStopIfGoingOnBatteries $true `
    -StartWhenAvailable $true `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 10) `
    -WakeToRun $true

# Créer la tâche planifiée
Register-ScheduledTask -TaskName "Surveillance_Services_Horaire" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Vérifie et redémarre les services Windows critiques toutes les heures" `
    -User "SYSTEM" `
    -RunLevel Highest
```

#### Étape 3: Version avancée avec notification par email

Pour une version plus complète qui envoie des emails en cas de problème, vous pouvez ajouter la fonction suivante au script `MonitorServices.ps1` et configurer les paramètres SMTP :

```powershell
# Configuration des paramètres email - à personnaliser
$emailParams = @{
    SmtpServer = "smtp.exemple.com"
    Port = 587
    UseSSL = $true
    From = "monitoring@exemple.com"
    To = "admin@exemple.com"
    Credential = $null  # Si nécessaire, créez un PSCredential ici
}

# Fonction pour envoyer des emails d'alerte
function Send-AlertEmail {
    param (
        [string]$Subject,
        [string]$Body
    )

    try {
        # Ajouter la date et l'heure au sujet
        $dateHeure = Get-Date -Format "yyyy-MM-dd HH:mm"
        $sujetComplet = "[$dateHeure] $Subject"

        # Créer un corps d'email en HTML plus élaboré
        $htmlBody = @"
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; }
        .header { background-color: #f8f8f8; padding: 10px; border-bottom: 1px solid #ddd; }
        .content { padding: 15px; }
        .footer { font-size: 12px; color: #777; border-top: 1px solid #ddd; padding-top: 10px; }
        .error { color: #cc0000; }
        .success { color: #00aa00; }
        .warning { color: #ff9900; }
    </style>
</head>
<body>
    <div class="header">
        <h2>Alerte de surveillance des services Windows</h2>
        <p>Serveur: $env:COMPUTERNAME | Date: $dateHeure</p>
    </div>
    <div class="content">
        $($Body -replace "`n", "<br/>")
    </div>
    <div class="footer">
        <p>Ce message a été généré automatiquement par le script de surveillance des services.</p>
        <p>Pour arrêter ces notifications, désactivez la tâche planifiée "Surveillance_Services_Horaire".</p>
    </div>
</body>
</html>
"@

        # Envoyer l'email
        Send-MailMessage @emailParams -Subject $sujetComplet -Body $htmlBody -BodyAsHtml -ErrorAction Stop
        Write-Log "Email d'alerte envoyé avec succès à $($emailParams.To)" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Échec de l'envoi de l'email d'alerte: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# À la fin du script, remplacer le commentaire sur l'envoi d'email par:
if ($servicesEchec -gt 0) {
    $corpsMail = @"
Des problèmes ont été détectés avec les services Windows sur $env:COMPUTERNAME.

Résumé:
- Services vérifiés: $($servicesACritiques.Count)
- Services arrêtés détectés: $servicesArretes
- Services redémarrés avec succès: $servicesDemarrages
- Échecs de redémarrage: $servicesEchec

Veuillez consulter le journal complet pour plus de détails:
$logFile
"@

    Send-AlertEmail -Subject "ALERTE: Problèmes de services Windows" -Body $corpsMail
}
```

#### Vérification

```powershell
# Exécuter manuellement la tâche pour tester
Start-ScheduledTask -TaskName "Surveillance_Services_Horaire"

# Attendre un peu et vérifier les logs
Start-Sleep -Seconds 5
Get-Content -Path "C:\Logs\ServiceMonitor\ServiceMonitor_$(Get-Date -Format 'yyyyMMdd').log"
```

### Conseils supplémentaires pour tous les exercices

1. **Sécurité** : Pour les scripts nécessitant des privilèges élevés, assurez-vous que le compte exécutant la tâche dispose des autorisations nécessaires.

2. **Tests** : Testez toujours vos scripts manuellement avant de les planifier, en particulier ceux qui modifient des fichiers système.

3. **Journalisation** :
   - Utilisez `Start-Transcript` pour capturer toute la sortie de votre script
   - Implémentez une rotation des journaux pour éviter qu'ils ne deviennent trop volumineux
   - Incluez des horodatages précis dans vos messages de journal

4. **Gestion des erreurs** :
   - Utilisez toujours des blocs try/catch pour gérer les erreurs
   - Définissez des valeurs par défaut pour les paramètres critiques
   - Vérifiez l'existence des chemins avant de les utiliser

5. **Notifications** :
   - Envisagez d'ajouter des notifications (email, SMS, Teams) pour les tâches critiques
   - Incluez des informations de contexte suffisantes dans vos notifications

Ces solutions peuvent être adaptées à vos besoins spécifiques et constituent une base solide pour automatiser des tâches administratives courantes dans un environnement Windows.
