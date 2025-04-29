# Solution Exercice 12.5.1 - Inventaire détaillé des machines virtuelles Azure

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Énoncé de l'exercice

Créez un script PowerShell qui:
1. Se connecte à votre compte Azure
2. Récupère l'ensemble des machines virtuelles de tous vos abonnements
3. Pour chaque VM, collecte les informations suivantes:
   - Nom de la VM
   - Groupe de ressources
   - Région
   - Taille (SKU)
   - Système d'exploitation
   - Adresses IP
   - État (running, stopped, etc.)
   - Tags
4. Exporte ces informations dans un fichier CSV
5. Affiche un résumé statistique (nombre de VMs par état, par région, etc.)

## Solution complète

```powershell
#####################################################################
# Script: Get-AzureVMDetailedInventory.ps1
# Description: Génère un inventaire détaillé des machines virtuelles Azure
#              dans tous les abonnements accessibles.
# Auteur: Formation PowerShell
# Date: 27/04/2025
#####################################################################

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "$env:USERPROFILE\Documents",

    [Parameter(Mandatory = $false)]
    [switch]$ExportToCSV = $true,

    [Parameter(Mandatory = $false)]
    [switch]$ShowStatistics = $true
)

#region Functions
function Write-LogMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Severity = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Severity] $Message"

    switch ($Severity) {
        'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
    }
}
#endregion Functions

#region Main Script
try {
    # Vérifier si le module Az est installé
    if (-not (Get-Module -ListAvailable -Name Az.Compute)) {
        Write-LogMessage "Le module Az.Compute n'est pas installé. Installation en cours..." -Severity Warning
        Install-Module -Name Az.Compute -Scope CurrentUser -Force
    }

    # Importer le module Az si nécessaire
    if (-not (Get-Module -Name Az.Compute)) {
        Import-Module Az.Compute
    }

    # Vérifier la connexion à Azure
    $context = Get-AzContext
    if (-not $context) {
        Write-LogMessage "Non connecté à Azure. Connexion en cours..." -Severity Info
        Connect-AzAccount
    }
    else {
        Write-LogMessage "Déjà connecté à Azure en tant que: $($context.Account.Id)" -Severity Info
    }

    # Récupérer tous les abonnements
    $subscriptions = Get-AzSubscription
    Write-LogMessage "Nombre d'abonnements trouvés: $($subscriptions.Count)" -Severity Info

    # Préparer la collection pour stocker les informations des VMs
    $vmCollection = @()

    # Date du jour pour le nom du fichier
    $dateStamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $outputFile = Join-Path -Path $OutputFolder -ChildPath "AzureVMInventory-$dateStamp.csv"

    # Parcourir chaque abonnement
    foreach ($subscription in $subscriptions) {
        Write-LogMessage "Traitement de l'abonnement: $($subscription.Name) ($($subscription.Id))" -Severity Info

        # Définir le contexte sur l'abonnement actuel
        Set-AzContext -SubscriptionId $subscription.Id | Out-Null

        # Récupérer toutes les VMs dans l'abonnement actuel
        $vms = Get-AzVM -Status
        Write-LogMessage "Nombre de VMs trouvées dans cet abonnement: $($vms.Count)" -Severity Info

        # Traiter chaque VM
        foreach ($vm in $vms) {
            Write-LogMessage "Traitement de la VM: $($vm.Name)" -Severity Info

            # Récupérer les interfaces réseau associées à la VM
            $networkInterfaces = @()
            foreach ($nic in $vm.NetworkProfile.NetworkInterfaces) {
                $nicResource = Get-AzNetworkInterface -ResourceId $nic.Id
                $privateIPs = $nicResource.IpConfigurations | ForEach-Object { $_.PrivateIpAddress }
                $publicIPs = @()

                # Récupérer les IPs publiques associées
                foreach ($ipConfig in $nicResource.IpConfigurations) {
                    if ($ipConfig.PublicIpAddress) {
                        $publicIPResource = Get-AzPublicIpAddress -ResourceId $ipConfig.PublicIpAddress.Id
                        if ($publicIPResource.IpAddress -ne "Not Assigned") {
                            $publicIPs += $publicIPResource.IpAddress
                        }
                    }
                }

                $networkInterfaces += [PSCustomObject]@{
                    Name = $nicResource.Name
                    PrivateIPs = $privateIPs -join ', '
                    PublicIPs = $publicIPs -join ', '
                }
            }

            # Déterminer le système d'exploitation
            $osType = if ($vm.StorageProfile.OsDisk.OsType) {
                $vm.StorageProfile.OsDisk.OsType
            } else {
                "Inconnu"
            }

            # Récupérer la version/image de l'OS si disponible
            $osVersion = "Inconnu"
            if ($osType -eq "Windows" -and $vm.StorageProfile.ImageReference) {
                $osVersion = "$($vm.StorageProfile.ImageReference.Offer) $($vm.StorageProfile.ImageReference.Sku)"
            } elseif ($osType -eq "Linux" -and $vm.StorageProfile.ImageReference) {
                $osVersion = "$($vm.StorageProfile.ImageReference.Offer) $($vm.StorageProfile.ImageReference.Sku)"
            }

            # Formater les tags en chaîne de caractères
            $tagString = if ($vm.Tags.Count -gt 0) {
                ($vm.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '
            } else {
                "Aucun"
            }

            # Créer un objet personnalisé pour cette VM
            $vmInfo = [PSCustomObject]@{
                SubscriptionName = $subscription.Name
                SubscriptionId = $subscription.Id
                ResourceGroupName = $vm.ResourceGroupName
                VMName = $vm.Name
                Location = $vm.Location
                Size = $vm.HardwareProfile.VmSize
                OSType = $osType
                OSVersion = $osVersion
                PowerState = $vm.PowerState
                PrivateIPs = ($networkInterfaces.PrivateIPs | Where-Object { $_ }) -join '; '
                PublicIPs = ($networkInterfaces.PublicIPs | Where-Object { $_ }) -join '; '
                Tags = $tagString
                ProvisioningState = $vm.ProvisioningState
                LicenseType = $vm.LicenseType
                AvailabilitySet = if ($vm.AvailabilitySetReference) { $vm.AvailabilitySetReference.Id.Split('/')[-1] } else { "Aucun" }
                CreationDate = $vm.TimeCreated
            }

            # Ajouter à la collection
            $vmCollection += $vmInfo
        }
    }

    # Exporter vers CSV si demandé
    if ($ExportToCSV -and $vmCollection.Count -gt 0) {
        $vmCollection | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
        Write-LogMessage "Inventaire exporté avec succès vers: $outputFile" -Severity Info
    }

    # Afficher les statistiques si demandé
    if ($ShowStatistics) {
        Write-LogMessage "`n----- STATISTIQUES DE L'INVENTAIRE -----" -Severity Info

        # Nombre total de VMs
        Write-LogMessage "Nombre total de machines virtuelles: $($vmCollection.Count)" -Severity Info

        # VMs par système d'exploitation
        $osSummary = $vmCollection | Group-Object -Property OSType | Select-Object Name, Count
        Write-LogMessage "`nRépartition par système d'exploitation:" -Severity Info
        $osSummary | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count) VM(s)" -ForegroundColor Cyan
        }

        # VMs par état d'alimentation
        $powerSummary = $vmCollection | Group-Object -Property PowerState | Select-Object Name, Count
        Write-LogMessage "`nRépartition par état d'alimentation:" -Severity Info
        $powerSummary | ForEach-Object {
            $color = switch ($_.Name) {
                "VM running" { "Green" }
                "VM deallocated" { "Gray" }
                "VM stopped" { "Yellow" }
                default { "Cyan" }
            }
            Write-Host "  $($_.Name): $($_.Count) VM(s)" -ForegroundColor $color
        }

        # VMs par région
        $regionSummary = $vmCollection | Group-Object -Property Location | Select-Object Name, Count | Sort-Object -Property Count -Descending
        Write-LogMessage "`nRépartition par région:" -Severity Info
        $regionSummary | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count) VM(s)" -ForegroundColor Cyan
        }

        # VMs par taille
        $sizeSummary = $vmCollection | Group-Object -Property Size | Select-Object Name, Count | Sort-Object -Property Count -Descending
        Write-LogMessage "`nTop 5 des tailles de VM:" -Severity Info
        $sizeSummary | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.Name): $($_.Count) VM(s)" -ForegroundColor Cyan
        }
    }

    # Retourner la collection pour utilisation ultérieure si nécessaire
    return $vmCollection

} catch {
    Write-LogMessage "Une erreur est survenue: $($_.Exception.Message)" -Severity Error
    Write-LogMessage "Détails: $($_.Exception.StackTrace)" -Severity Error
}
#endregion Main Script
```

## Explication du script

### Structure générale
- Le script utilise le modèle de commande avancée avec `[CmdletBinding()]`
- Des paramètres permettent de personnaliser l'exécution
- Une fonction de journalisation `Write-LogMessage` améliore la lisibilité

### Fonctionnalités clés
1. **Vérification des prérequis**
   - Vérifie si le module Az.Compute est installé
   - S'assure qu'une connexion Azure active existe

2. **Collecte des données**
   - Parcourt tous les abonnements accessibles
   - Pour chaque VM, collecte des informations détaillées:
     - Données de base (nom, groupe, région)
     - Configuration réseau (IPs privées et publiques)
     - Détails du système d'exploitation
     - État d'alimentation et de provisionnement
     - Tags et métadonnées

3. **Exportation et reporting**
   - Exporte l'inventaire complet au format CSV avec horodatage
   - Génère des statistiques par OS, état, région et taille

### Comment l'exécuter

```powershell
# Exécution simple
.\Get-AzureVMDetailedInventory.ps1

# Exécution avec paramètres personnalisés
.\Get-AzureVMDetailedInventory.ps1 -OutputFolder "C:\Rapports" -ShowStatistics -ExportToCSV
```

### Résultat attendu
- Un fichier CSV avec l'inventaire complet des VMs
- Un affichage en console des statistiques principales
- La collection d'objets VM est également retournée pour une utilisation dans d'autres scripts

## Astuces et bonnes pratiques illustrées

1. **Gestion des erreurs** avec des blocs try/catch
2. **Journalisation colorée** pour une meilleure lisibilité
3. **Paramètres optionnels** pour plus de flexibilité
4. **Documentation du code** avec des commentaires et régions
5. **Formatage des données** pour une meilleure présentation
6. **Gestion des valeurs nulles ou vides** pour éviter les erreurs




# Solution Exercice 12.5.2 - Sauvegarde automatique vers AWS S3

## Énoncé de l'exercice

Créez un script PowerShell qui effectue les opérations suivantes :
1. Se connecte à AWS avec un profil spécifique
2. Sauvegarde un dossier local (avec tous ses sous-dossiers) vers un bucket S3
3. Applique des règles de rétention (supprime les sauvegardes plus anciennes que X jours)
4. Génère un rapport de sauvegarde
5. Envoie une notification par email en cas de succès ou d'échec

## Solution complète

```powershell
#####################################################################
# Script: Backup-ToAWSS3.ps1
# Description: Sauvegarde un dossier local vers un bucket AWS S3
#              avec rotation des sauvegardes et notification par email
# Auteur: Formation PowerShell
# Date: 27/04/2025
#####################################################################

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$SourceFolder,

    [Parameter(Mandatory = $true)]
    [string]$S3BucketName,

    [Parameter(Mandatory = $false)]
    [string]$S3Prefix = "backups/$(Get-Date -Format 'yyyy-MM-dd')/",

    [Parameter(Mandatory = $false)]
    [string]$AWSProfileName = "default",

    [Parameter(Mandatory = $false)]
    [string]$AWSRegion = "eu-west-1",

    [Parameter(Mandatory = $false)]
    [int]$RetentionDays = 30,

    [Parameter(Mandatory = $false)]
    [string]$LogFolder = "$env:USERPROFILE\Documents\S3Backups\Logs",

    [Parameter(Mandatory = $false)]
    [string]$SmtpServer = "smtp.votreentreprise.com",

    [Parameter(Mandatory = $false)]
    [string]$EmailFrom = "backups@votreentreprise.com",

    [Parameter(Mandatory = $false)]
    [string[]]$EmailTo = @("admin@votreentreprise.com"),

    [Parameter(Mandatory = $false)]
    [switch]$EnableEmail = $false
)

#region Functions
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    # Créer le dossier de logs s'il n'existe pas
    if (-not (Test-Path -Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }

    # Nom du fichier de log avec la date du jour
    $logFile = Join-Path -Path $LogFolder -ChildPath "S3Backup_$(Get-Date -Format 'yyyyMMdd').log"

    # Format du message de log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Écrire dans le fichier de log
    Add-Content -Path $logFile -Value $logEntry

    # Afficher aussi dans la console avec la couleur appropriée
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
        default   { 'White' }
    }

    Write-Host $logEntry -ForegroundColor $color
}

function Send-EmailNotification {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subject,

        [Parameter(Mandatory = $true)]
        [string]$Body,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Success', 'Failure')]
        [string]$Status = 'Success'
    )

    if (-not $EnableEmail) {
        Write-Log "Envoi d'email désactivé. Notification ignorée." -Level INFO
        return
    }

    try {
        $emailParams = @{
            SmtpServer = $SmtpServer
            From       = $EmailFrom
            To         = $EmailTo
            Subject    = $Subject
            Body       = $Body
            BodyAsHtml = $true
        }

        Send-MailMessage @emailParams
        Write-Log "Email de notification envoyé avec succès" -Level INFO
    }
    catch {
        Write-Log "Échec de l'envoi de l'email de notification: $($_.Exception.Message)" -Level ERROR
    }
}

function Get-FileHash256 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    return (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
}

function New-BackupReport {
    param (
        [Parameter(Mandatory = $true)]
        [DateTime]$StartTime,

        [Parameter(Mandatory = $true)]
        [DateTime]$EndTime,

        [Parameter(Mandatory = $true)]
        [int]$TotalFiles,

        [Parameter(Mandatory = $true)]
        [long]$TotalSize,

        [Parameter(Mandatory = $true)]
        [int]$UploadedFiles,

        [Parameter(Mandatory = $false)]
        [int]$DeletedFiles = 0,

        [Parameter(Mandatory = $false)]
        [string[]]$Errors = @()
    )

    $duration = $EndTime - $StartTime
    $durationFormatted = "{0:D2}h:{1:D2}m:{2:D2}s" -f $duration.Hours, $duration.Minutes, $duration.Seconds
    $totalSizeMB = [math]::Round($TotalSize / 1MB, 2)

    $statusColor = if ($Errors.Count -eq 0) { "green" } else { "red" }
    $status = if ($Errors.Count -eq 0) { "SUCCÈS" } else { "ÉCHEC PARTIEL" }

    $reportHtml = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de sauvegarde S3</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0066cc; color: white; padding: 10px; }
        .summary { margin: 15px 0; padding: 10px; border: 1px solid #ddd; }
        .status { font-weight: bold; color: $statusColor; }
        .details { margin: 15px 0; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .errors { background-color: #ffeeee; border: 1px solid #ffcccc; padding: 10px; margin: 15px 0; }
        .footer { margin-top: 20px; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h2>Rapport de sauvegarde AWS S3</h2>
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>
    </div>

    <div class="summary">
        <h3>Résumé de la sauvegarde</h3>
        <p><strong>Statut:</strong> <span class="status">$status</span></p>
        <p><strong>Dossier source:</strong> $SourceFolder</p>
        <p><strong>Bucket S3:</strong> $S3BucketName</p>
        <p><strong>Préfixe S3:</strong> $S3Prefix</p>
        <p><strong>Heure de début:</strong> $($StartTime.ToString("dd/MM/yyyy HH:mm:ss"))</p>
        <p><strong>Heure de fin:</strong> $($EndTime.ToString("dd/MM/yyyy HH:mm:ss"))</p>
        <p><strong>Durée totale:</strong> $durationFormatted</p>
    </div>

    <div class="details">
        <h3>Détails de la sauvegarde</h3>
        <table>
            <tr>
                <th>Métrique</th>
                <th>Valeur</th>
            </tr>
            <tr>
                <td>Fichiers analysés</td>
                <td>$TotalFiles</td>
            </tr>
            <tr>
                <td>Taille totale</td>
                <td>$totalSizeMB MB</td>
            </tr>
            <tr>
                <td>Fichiers téléversés</td>
                <td>$UploadedFiles</td>
            </tr>
            <tr>
                <td>Anciennes sauvegardes supprimées</td>
                <td>$DeletedFiles</td>
            </tr>
            <tr>
                <td>Règle de rétention</td>
                <td>$RetentionDays jours</td>
            </tr>
        </table>
    </div>
"@

    # Ajouter la section des erreurs si nécessaire
    if ($Errors.Count -gt 0) {
        $errorList = $Errors | ForEach-Object { "<li>$_</li>" }
        $reportHtml += @"
    <div class="errors">
        <h3>Erreurs rencontrées ($($Errors.Count))</h3>
        <ul>
            $errorList
        </ul>
    </div>
"@
    }

    # Ajouter le pied de page
    $reportHtml += @"
    <div class="footer">
        <p>Ce rapport a été généré automatiquement par le script de sauvegarde PowerShell.</p>
        <p>Profil AWS utilisé: $AWSProfileName | Région: $AWSRegion</p>
    </div>
</body>
</html>
"@

    # Créer le dossier de rapports s'il n'existe pas
    $reportFolder = Join-Path -Path $LogFolder -ChildPath "Reports"
    if (-not (Test-Path -Path $reportFolder)) {
        New-Item -Path $reportFolder -ItemType Directory -Force | Out-Null
    }

    # Sauvegarder le rapport
    $reportFile = Join-Path -Path $reportFolder -ChildPath "S3Backup_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $reportHtml | Out-File -FilePath $reportFile -Encoding UTF8

    return $reportFile
}
#endregion Functions

#region Main Script
try {
    # Variables pour le suivi
    $startTime = Get-Date
    $fileCount = 0
    $totalSize = 0
    $uploadedCount = 0
    $errors = @()
    $deletedCount = 0

    # Vérifier si le dossier source existe
    if (-not (Test-Path -Path $SourceFolder)) {
        throw "Le dossier source n'existe pas: $SourceFolder"
    }

    Write-Log "Démarrage de la sauvegarde depuis '$SourceFolder' vers le bucket S3 '$S3BucketName/$S3Prefix'" -Level INFO

    # Vérifier si le module AWS est installé
    if (-not (Get-Module -ListAvailable -Name AWSPowerShell)) {
        Write-Log "Le module AWSPowerShell n'est pas installé. Installation en cours..." -Level WARNING
        Install-Module -Name AWSPowerShell -Scope CurrentUser -Force
    }

    # Importer le module AWS
    Import-Module AWSPowerShell

    # Définir la région et le profil AWS
    Set-AWSCredential -ProfileName $AWSProfileName
    Set-DefaultAWSRegion -Region $AWSRegion

    # Vérifier que le bucket existe
    try {
        Write-Log "Vérification de l'existence du bucket '$S3BucketName'..." -Level INFO
        $bucket = Get-S3Bucket -BucketName $S3BucketName
        Write-Log "Bucket '$S3BucketName' trouvé." -Level INFO
    }
    catch {
        Write-Log "Le bucket '$S3BucketName' n'existe pas ou n'est pas accessible avec le profil '$AWSProfileName'" -Level ERROR
        throw "Accès au bucket impossible: $($_.Exception.Message)"
    }

    # Récupérer tous les fichiers à sauvegarder
    Write-Log "Analyse du dossier source '$SourceFolder'..." -Level INFO
    $files = Get-ChildItem -Path $SourceFolder -Recurse -File
    $fileCount = $files.Count
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum

    Write-Log "Nombre total de fichiers à traiter: $fileCount ($([math]::Round($totalSize / 1MB, 2)) MB)" -Level INFO

    # Téléverser chaque fichier vers S3
    foreach ($file in $files) {
        try {
            # Calculer le chemin relatif
            $relativePath = $file.FullName.Substring($SourceFolder.Length)
            if ($relativePath.StartsWith("\") -or $relativePath.StartsWith("/")) {
                $relativePath = $relativePath.Substring(1)
            }

            # Chemin complet dans S3
            $s3Key = "$S3Prefix$($relativePath.Replace('\', '/'))"

            Write-Log "Téléversement de '$($file.Name)' vers 's3://$S3BucketName/$s3Key'..." -Level INFO

            # Téléverser le fichier
            $writeS3ObjectParams = @{
                BucketName  = $S3BucketName
                Key         = $s3Key
                File        = $file.FullName
                ContentType = [System.Web.MimeMapping]::GetMimeMapping($file.Name)
                Metadata    = @{
                    "x-amz-meta-original-path" = $file.FullName
                    "x-amz-meta-backup-date"   = (Get-Date).ToString("o")
                    "x-amz-meta-file-hash"     = (Get-FileHash256 -FilePath $file.FullName)
                }
            }

            Write-S3Object @writeS3ObjectParams
            $uploadedCount++

            Write-Log "Fichier '$($file.Name)' téléversé avec succès" -Level SUCCESS
        }
        catch {
            $errorMsg = "Échec du téléversement de '$($file.Name)': $($_.Exception.Message)"
            Write-Log $errorMsg -Level ERROR
            $errors += $errorMsg
        }
    }

    # Suppression des anciennes sauvegardes selon la règle de rétention
    if ($RetentionDays -gt 0) {
        Write-Log "Application de la règle de rétention: suppression des sauvegardes antérieures à $RetentionDays jours" -Level INFO

        try {
            # Calculer la date limite
            $cutoffDate = (Get-Date).AddDays(-$RetentionDays)

            # Obtenir tous les objets dans le bucket qui commencent par 'backups/'
            $allBackups = Get-S3Object -BucketName $S3BucketName -KeyPrefix "backups/" |
                Where-Object { $_.LastModified -lt $cutoffDate }

            if ($allBackups.Count -gt 0) {
                Write-Log "Trouvé $($allBackups.Count) objets à supprimer selon la règle de rétention" -Level INFO

                foreach ($backupObject in $allBackups) {
                    Write-Log "Suppression de l'objet obsolète: $($backupObject.Key)" -Level INFO
                    Remove-S3Object -BucketName $S3BucketName -Key $backupObject.Key -Force
                    $deletedCount++
                }

                Write-Log "$deletedCount objets obsolètes supprimés avec succès" -Level SUCCESS
            }
            else {
                Write-Log "Aucun objet obsolète à supprimer" -Level INFO
            }
        }
        catch {
            $errorMsg = "Erreur lors de l'application de la règle de rétention: $($_.Exception.Message)"
            Write-Log $errorMsg -Level ERROR
            $errors += $errorMsg
        }
    }

    # Finalisation et rapport
    $endTime = Get-Date
    Write-Log "Sauvegarde terminée. Durée totale: $(($endTime - $startTime).ToString())" -Level INFO
    Write-Log "Fichiers traités: $fileCount | Téléversés: $uploadedCount | Supprimés: $deletedCount | Erreurs: $($errors.Count)" -Level INFO

    # Génération du rapport
    $reportFile = New-BackupReport -StartTime $startTime -EndTime $endTime -TotalFiles $fileCount `
        -TotalSize $totalSize -UploadedFiles $uploadedCount -DeletedFiles $deletedCount -Errors $errors

    Write-Log "Rapport de sauvegarde généré: $reportFile" -Level INFO

    # Envoi de la notification par email
    if ($EnableEmail) {
        $emailSubject = if ($errors.Count -eq 0) {
            "✅ Sauvegarde S3 réussie - $S3BucketName/$S3Prefix"
        }
        else {
            "⚠️ Sauvegarde S3 avec erreurs - $S3BucketName/$S3Prefix"
        }

        $emailBody = Get-Content -Path $reportFile -Raw
        $emailStatus = if ($errors.Count -eq 0) { "Success" } else { "Failure" }

        Send-EmailNotification -Subject $emailSubject -Body $emailBody -Status $emailStatus
    }

    # Retourner un résumé
    return [PSCustomObject]@{
        StartTime     = $startTime
        EndTime       = $endTime
        Duration      = $endTime - $startTime
        FilesTotal    = $fileCount
        FilesUploaded = $uploadedCount
        FilesDeleted  = $deletedCount
        TotalSizeMB   = [math]::Round($totalSize / 1MB, 2)
        ErrorCount    = $errors.Count
        Status        = if ($errors.Count -eq 0) { "Successful" } else { "PartialFailure" }
        ReportFile    = $reportFile
    }
}
catch {
    $errorMsg = "ERREUR CRITIQUE: $($_.Exception.Message)"
    Write-Log $errorMsg -Level ERROR

    if ($EnableEmail) {
        $emailSubject = "❌ ÉCHEC de la sauvegarde S3 - $S3BucketName/$S3Prefix"
        $emailBody = @"
<html>
<body style="font-family: Arial, sans-serif;">
<h2 style="color: red;">Échec de la sauvegarde vers AWS S3</h2>
<p><strong>Date:</strong> $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
<p><strong>Erreur critique:</strong> $($_.Exception.Message)</p>
<p><strong>Dossier source:</strong> $SourceFolder</p>
<p><strong>Destination:</strong> $S3BucketName/$S3Prefix</p>
<hr>
<p>Veuillez vérifier les journaux pour plus de détails.</p>
</body>
</html>
"@

        Send-EmailNotification -Subject $emailSubject -Body $emailBody -Status "Failure"
    }

    throw
}
#endregion Main Script
```


# Solution Exercice 12.5.3 - Rapport multi-cloud de ressources

## Énoncé de l'exercice

Développez un script PowerShell qui :
1. Se connecte à la fois à Microsoft Azure et AWS
2. Récupère les informations sur les ressources de calcul (VMs, instances) dans les deux plateformes
3. Collecte les données sur les coûts estimés ou réels de ces ressources
4. Génère un rapport unifié au format HTML qui compare les ressources entre les deux clouds
5. Identifie les potentielles optimisations de coûts

## Solution complète

```powershell
#####################################################################
# Script: Get-MultiCloudReport.ps1
# Description: Génère un rapport unifié des ressources Azure et AWS
#              avec analyse des coûts et recommandations d'optimisation
# Auteur: Formation PowerShell
# Date: 27/04/2025
#####################################################################

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$AzureSubscriptionId = "",

    [Parameter(Mandatory = $false)]
    [string]$AWSProfileName = "default",

    [Parameter(Mandatory = $false)]
    [string]$AWSRegion = "eu-west-1",

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "$env:USERPROFILE\Documents\CloudReports",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeCostData = $true,

    [Parameter(Mandatory = $false)]
    [int]$InactiveThresholdDays = 30,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReportWhenDone = $true
)

#region Variables
# Dictionnaire des familles d'instances et coûts estimés pour AWS
$awsInstanceCosts = @{
    "t2.micro"    = @{ vCPU = 1;  RAM = 1;   CostPerHour = 0.0116 }
    "t2.small"    = @{ vCPU = 1;  RAM = 2;   CostPerHour = 0.023 }
    "t2.medium"   = @{ vCPU = 2;  RAM = 4;   CostPerHour = 0.0464 }
    "t2.large"    = @{ vCPU = 2;  RAM = 8;   CostPerHour = 0.0928 }
    "t3.micro"    = @{ vCPU = 2;  RAM = 1;   CostPerHour = 0.0104 }
    "t3.small"    = @{ vCPU = 2;  RAM = 2;   CostPerHour = 0.0208 }
    "t3.medium"   = @{ vCPU = 2;  RAM = 4;   CostPerHour = 0.0416 }
    "m5.large"    = @{ vCPU = 2;  RAM = 8;   CostPerHour = 0.096 }
    "m5.xlarge"   = @{ vCPU = 4;  RAM = 16;  CostPerHour = 0.192 }
    "m5.2xlarge"  = @{ vCPU = 8;  RAM = 32;  CostPerHour = 0.384 }
    "c5.large"    = @{ vCPU = 2;  RAM = 4;   CostPerHour = 0.085 }
    "c5.xlarge"   = @{ vCPU = 4;  RAM = 8;   CostPerHour = 0.17 }
    "r5.large"    = @{ vCPU = 2;  RAM = 16;  CostPerHour = 0.126 }
    "r5.xlarge"   = @{ vCPU = 4;  RAM = 32;  CostPerHour = 0.252 }
    # Valeurs par défaut pour les instances non listées
    "default"     = @{ vCPU = 2;  RAM = 4;   CostPerHour = 0.05 }
}

# Dictionnaire des familles de VMs et coûts estimés pour Azure
$azureVMCosts = @{
    "Standard_B1s"    = @{ vCPU = 1;  RAM = 1;   CostPerHour = 0.0104 }
    "Standard_B1ms"   = @{ vCPU = 1;  RAM = 2;   CostPerHour = 0.0208 }
    "Standard_B2s"    = @{ vCPU = 2;  RAM = 4;   CostPerHour = 0.0416 }
    "Standard_B2ms"   = @{ vCPU = 2;  RAM = 8;   CostPerHour = 0.0832 }
    "Standard_D2s_v3" = @{ vCPU = 2;  RAM = 8;   CostPerHour = 0.11 }
    "Standard_D4s_v3" = @{ vCPU = 4;  RAM = 16;  CostPerHour = 0.22 }
    "Standard_D8s_v3" = @{ vCPU = 8;  RAM = 32;  CostPerHour = 0.44 }
    "Standard_E2s_v3" = @{ vCPU = 2;  RAM = 16;  CostPerHour = 0.146 }
    "Standard_E4s_v3" = @{ vCPU = 4;  RAM = 32;  CostPerHour = 0.292 }
    "Standard_F2s_v2" = @{ vCPU = 2;  RAM = 4;   CostPerHour = 0.085 }
    "Standard_F4s_v2" = @{ vCPU = 4;  RAM = 8;   CostPerHour = 0.17 }
    # Valeurs par défaut pour les VMs non listées
    "default"         = @{ vCPU = 2;  RAM = 8;   CostPerHour = 0.1 }
}

# Date du rapport
$reportDate = Get-Date
$monthlyHours = 730 # Moyenne d'heures par mois pour les calculs de coûts
#endregion Variables

#region Functions
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    # Format du message de log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
        default   { 'White' }
    }

    Write-Host $logEntry -ForegroundColor $color
}

function Get-AzureVMResources {
    Write-Log "Récupération des ressources de machines virtuelles Azure..." -Level INFO

    try {
        # Configurer le contexte d'abonnement si spécifié
        if ($AzureSubscriptionId) {
            Set-AzContext -SubscriptionId $AzureSubscriptionId | Out-Null
            Write-Log "Contexte défini sur l'abonnement: $AzureSubscriptionId" -Level INFO
        }

        # Récupérer toutes les VMs avec leur état
        $azureVMs = Get-AzVM -Status
        Write-Log "Nombre de VMs Azure trouvées: $($azureVMs.Count)" -Level SUCCESS

        $vmCollection = @()

        foreach ($vm in $azureVMs) {
            # Déterminer le statut
            $powerState = ($vm.Statuses | Where-Object { $_.Code -match 'PowerState/' }).Code
            $powerState = $powerState -replace 'PowerState/', ''

            # Calculer le coût estimé
            $vmSize = $vm.HardwareProfile.VmSize
            $costInfo = $azureVMCosts[$vmSize]

            # Si la taille n'est pas dans notre dictionnaire, utiliser la valeur par défaut
            if (-not $costInfo) {
                $costInfo = $azureVMCosts["default"]
            }

            # Estimer le coût mensuel
            $costPerHour = $costInfo.CostPerHour
            $monthlyCost = $costPerHour * $monthlyHours

            # Calculer le coût avec réduction si la VM est arrêtée (approximatif pour disques, etc.)
            $adjustedMonthlyCost = if ($powerState -eq "running") {
                $monthlyCost
            }
            else {
                $monthlyCost * 0.15 # 15% du coût pour le stockage et autres frais maintenus même si arrêtée
            }

            # Obtenir l'OS
            $osType = if ($vm.StorageProfile.OsDisk.OsType) {
                $vm.StorageProfile.OsDisk.OsType
            }
            else {
                "Inconnu"
            }

            # Obtenir les adresses IP
            $networkInterfaces = @()
            foreach ($nic in $vm.NetworkProfile.NetworkInterfaces) {
                $nicResource = Get-AzNetworkInterface -ResourceId $nic.Id
                $privateIPs = $nicResource.IpConfigurations | ForEach-Object { $_.PrivateIpAddress }
                $publicIPs = @()

                foreach ($ipConfig in $nicResource.IpConfigurations) {
                    if ($ipConfig.PublicIpAddress) {
                        $publicIPResource = Get-AzPublicIpAddress -ResourceId $ipConfig.PublicIpAddress.Id
                        if ($publicIPResource.IpAddress -ne "Not Assigned") {
                            $publicIPs += $publicIPResource.IpAddress
                        }
                    }
                }

                $networkInterfaces += [PSCustomObject]@{
                    PrivateIPs = $privateIPs
                    PublicIPs = $publicIPs
                }
            }

            # Créer un objet personnalisé pour cette VM
            $vmInfo = [PSCustomObject]@{
                Name = $vm.Name
                ResourceGroup = $vm.ResourceGroupName
                Location = $vm.Location
                OS = $osType
                Size = $vmSize
                vCPU = $costInfo.vCPU
                RAM_GB = $costInfo.RAM
                Status = $powerState
                PrivateIP = ($networkInterfaces.PrivateIPs | Where-Object { $_ }) -join ', '
                PublicIP = ($networkInterfaces.PublicIPs | Where-Object { $_ }) -join ', '
                CostPerHour = $costPerHour
                MonthlyCost = $adjustedMonthlyCost
                Platform = "Azure"
                Id = $vm.Id
                Tags = if ($vm.Tags.Count -gt 0) { ($vm.Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; ' } else { "" }
                OptimizationCandidate = ($powerState -ne "running" -and $powerState -ne "deallocated")
            }

            $vmCollection += $vmInfo
        }

        return $vmCollection
    }
    catch {
        Write-Log "Erreur lors de la récupération des VMs Azure: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Get-AWSInstanceResources {
    Write-Log "Récupération des instances EC2 AWS..." -Level INFO

    try {
        # Définir le profil et la région AWS
        Set-AWSCredential -ProfileName $AWSProfileName
        Set-DefaultAWSRegion -Region $AWSRegion

        # Récupérer toutes les instances EC2
        $ec2Instances = Get-EC2Instance

        Write-Log "Nombre d'instances EC2 trouvées: $($ec2Instances.Count)" -Level SUCCESS

        $instanceCollection = @()

        foreach ($reservation in $ec2Instances.Reservations) {
            foreach ($instance in $reservation.Instances) {
                # Récupérer le nom depuis les tags
                $nameTag = $instance.Tags | Where-Object { $_.Key -eq "Name" }
                $name = if ($nameTag) { $nameTag.Value } else { $instance.InstanceId }

                # Calculer le coût estimé
                $instanceType = $instance.InstanceType
                $costInfo = $awsInstanceCosts[$instanceType]

                # Si le type n'est pas dans notre dictionnaire, utiliser la valeur par défaut
                if (-not $costInfo) {
                    $costInfo = $awsInstanceCosts["default"]
                }

                # Estimer le coût mensuel
                $costPerHour = $costInfo.CostPerHour
                $monthlyCost = $costPerHour * $monthlyHours

                # Calculer le coût avec réduction si l'instance est arrêtée
                $adjustedMonthlyCost = if ($instance.State.Name -eq "running") {
                    $monthlyCost
                }
                else {
                    $monthlyCost * 0.15 # Approximation pour EBS et autres coûts persistants
                }

                # Déterminer l'OS
                $platform = if ($instance.Platform) {
                    $instance.Platform
                }
                elseif ($instance.ImageId -match "^ami-") {
                    "Linux/Unix" # Supposition basée sur l'AMI
                }
                else {
                    "Inconnu"
                }

                # Extraire tous les tags sous forme de chaîne
                $tags = if ($instance.Tags.Count -gt 0) {
                    ($instance.Tags | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '; '
                }
                else {
                    ""
                }

                # Créer un objet personnalisé pour cette instance
                $instanceInfo = [PSCustomObject]@{
                    Name = $name
                    ResourceGroup = "N/A" # AWS n'a pas d'équivalent direct aux groupes de ressources
                    Location = $instance.Placement.AvailabilityZone
                    OS = $platform
                    Size = $instanceType
                    vCPU = $costInfo.vCPU
                    RAM_GB = $costInfo.RAM
                    Status = $instance.State.Name
                    PrivateIP = $instance.PrivateIpAddress
                    PublicIP = $instance.PublicIpAddress
                    CostPerHour = $costPerHour
                    MonthlyCost = $adjustedMonthlyCost
                    Platform = "AWS"
                    Id = $instance.InstanceId
                    Tags = $tags
                    OptimizationCandidate = ($instance.State.Name -ne "running" -and $instance.State.Name -ne "stopped")
                }

                $instanceCollection += $instanceInfo
            }
        }

        return $instanceCollection
    }
    catch {
        Write-Log "Erreur lors de la récupération des instances EC2: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function New-OptimizationRecommendations {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Resources
    )

    $recommendations = @()

    # 1. Instances arrêtées depuis longtemps
    $stoppedInstances = $Resources | Where-Object {
        ($_.Status -eq "stopped" -or $_.Status -eq "deallocated")
    }

    if ($stoppedInstances.Count -gt 0) {
        $stoppedCost = ($stoppedInstances | Measure-Object -Property MonthlyCost -Sum).Sum
        $recommendations += [PSCustomObject]@{
            Type = "Suppression des ressources inutilisées"
            Description = "Supprimer ou archiver $($stoppedInstances.Count) ressources actuellement arrêtées"
            Impact = "Économie mensuelle estimée: $([math]::Round($stoppedCost, 2)) USD"
            Resources = ($stoppedInstances | Select-Object Name, Platform) | ConvertTo-Html -Fragment
            Priorité = "Haute"
        }
    }

    # 2. Optimisation de taille (surutilisées)
    $oversizedInstances = $Resources | Where-Object {
        $_.Status -eq "running" -and (
            ($_.Platform -eq "Azure" -and $_.Size -match "(Standard_D|Standard_E|Standard_G)" -and $_.vCPU -gt 4) -or
            ($_.Platform -eq "AWS" -and $_.Size -match "\.(xlarge|2xlarge|4xlarge)" -and $_.vCPU -gt 4)
        )
    }

    if ($oversizedInstances.Count -gt 0) {
        $potentialSavings = ($oversizedInstances | Measure-Object -Property MonthlyCost -Sum).Sum * 0.35 # ~35% d'économie en moyenne
        $recommendations += [PSCustomObject]@{
            Type = "Redimensionnement des ressources"
            Description = "Évaluer et redimensionner $($oversizedInstances.Count) ressources potentiellement surprovisionnées"
            Impact = "Économie mensuelle estimée: $([math]::Round($potentialSavings, 2)) USD"
            Resources = ($oversizedInstances | Select-Object Name, Platform, Size) | ConvertTo-Html -Fragment
            Priorité = "Moyenne"
        }
    }

    # 3. Instances sans tags appropriés
    $untaggedInstances = $Resources | Where-Object { -not $_.Tags -or $_.Tags.Length -eq 0 }

    if ($untaggedInstances.Count -gt 0) {
        $recommendations += [PSCustomObject]@{
            Type = "Gouvernance et organisation"
            Description = "Appliquer des tags (environnement, projet, propriétaire, etc.) à $($untaggedInstances.Count) ressources non étiquetées"
            Impact = "Amélioration de la gouvernance et allocation précise des coûts"
            Resources = ($untaggedInstances | Select-Object Name, Platform) | ConvertTo-Html -Fragment
            Priorité = "Basse"
        }
    }

    return $recommendations
}

function New-MultiCloudReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$AzureResources,

        [Parameter(Mandatory = $true)]
        [array]$AWSResources,

        [Parameter(Mandatory = $true)]
        [array]$Recommendations
    )

    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }

    # Calculer les statistiques
    $allResources = $AzureResources + $AWSResources
    $totalResources = $allResources.Count
    $runningResources = ($allResources | Where-Object { $_.Status -eq "running" }).Count
    $stoppedResources = $totalResources - $runningResources
    $azureCost = ($AzureResources | Measure-Object -Property MonthlyCost -Sum).Sum
    $awsCost = ($AWSResources | Measure-Object -Property MonthlyCost -Sum).Sum
    $totalCost = $azureCost + $awsCost

    # Formater les données pour les graphiques
    $statusData = @"
[
    { "name": "En cours d'exécution", "value": $runningResources, "color": "#4CAF50" },
    { "name": "Arrêtées", "value": $stoppedResources, "color": "#F44336" }
]
"@

    $platformData = @"
[
    { "name": "Azure", "value": $($AzureResources.Count), "color": "#0078D4" },
    { "name": "AWS", "value": $($AWSResources.Count), "color": "#FF9900" }
]
"@

    $costData = @"
[
    { "name": "Azure", "value": $azureCost, "color": "#0078D4" },
    { "name": "AWS", "value": $awsCost, "color": "#FF9900" }
]
"@

    # Créer la page HTML
    $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport Multi-Cloud - $(Get-Date -Format "dd/MM/yyyy")</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #0078D4 0%, #83B9F9 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .card {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            padding: 20px;
        }
        .card h3 {
            margin-top: 0;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            color: #0078D4;
        }
        .summary-flex {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 20px;
        }
        .summary-box {
            flex: 1;
            min-width: 180px;
            background-color: white;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
        }
        .summary-box h4 {
            margin: 0;
            font-size: 14px;
            color: #666;
        }
        .summary-box p {
            margin: 10px 0 0;
            font-size: 24px;
            font-weight: bold;
        }
        .azure { color: #0078D4; }
        .aws { color: #FF9900; }
        .chart-container {
            position: relative;
            height: 300px;
            margin: 20px 0;
        }
        .chart-row {
            display: flex;
            gap: 20px;
            margin-bottom: 20px;
        }
        .chart-box {
            flex: 1;
            background-color: white;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
            font-weight: 600;
        }
        tr:hover {
            background-color: #f9f9f9;
        }
        .recommendation {
            background-color: #f9f9f9;
            border-left: 4px solid #0078D4;
            margin-bottom: 15px;
            padding: 15px;
        }
        .high-priority { border-left-color: #F44336; }
        .medium-priority { border-left-color: #FB8C00; }
        .low-priority { border-left-color: #0078D4; }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: #666;
            font-size: 12px;
        }
        @media print {
            body { background-color: white; }
            .card { box-shadow: none; border: 1px solid #ddd; }
            .summary-box { box-shadow: none; border: 1px solid #ddd; }
            .chart-box { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Rapport Multi-Cloud - Ressources et Coûts</h1>
            <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>
        </div>

        <div class="card">
            <h3>Résumé des ressources</h3>
            <div class="summary-flex">
                <div class="summary-box">
                    <h4>Ressources totales</h4>
                    <p>$totalResources</p>
                </div>
                <div class="summary-box">
                    <h4>Azure VMs</h4>
                    <p class="azure">$($AzureResources.Count)</p>
                </div>
                <div class="summary-box">
                    <h4>AWS EC2</h4>
                    <p class="aws">$($AWSResources.Count)</p>
                </div>
                <div class="summary-box">
                    <h4>En exécution</h4>
                    <p style="color: #4CAF50;">$runningResources</p>
                </div>
                <div class="summary-box">
                    <h4>Arrêtées</h4>
                    <p style="color: #F44336;">$stoppedResources</p>
                </div>
            </div>
        </div>

        <div class="chart-row">
            <div class="chart-box">
                <h3>Répartition par plateforme</h3>
                <canvas id="platformChart"></canvas>
            </div>
            <div class="chart-box">
                <h3>Répartition par état</h3>
                <canvas id="statusChart"></canvas>
            </div>
        </div>

        <div class="card">
            <h3>Analyse des coûts</h3>
            <div class="summary-flex">
                <div class="summary-box">
                    <h4>Coût mensuel total</h4>
                    <p>$([Math]::Round($totalCost, 2)) USD</p>
                </div>
                <div class="summary-box">
                    <h4>Azure</h4>
                    <p class="azure">$([Math]::Round($azureCost, 2)) USD</p>
                </div>
                <div class="summary-box">
                    <h4>AWS</h4>
                    <p class="aws">$([Math]::Round($awsCost, 2)) USD</p>
                </div>
                <div class="summary-box">
                    <h4>Coût moyen par ressource</h4>
                    <p>$([Math]::Round($totalCost / $totalResources, 2)) USD</p>
                </div>
            </div>

            <div class="chart-container">
                <canvas id="costChart"></canvas>
            </div>
        </div>

        <div class="card">
            <h3>Recommandations d'optimisation</h3>

            $(foreach ($rec in $Recommendations) {
                $priorityClass = switch ($rec.Priorité) {
                    "Haute" { "high-priority" }
                    "Moyenne" { "medium-priority" }
                    "Basse" { "low-priority" }
                    default { "" }
                }

                @"
                <div class="recommendation $priorityClass">
                    <h4>$($rec.Type) - Priorité: $($rec.Priorité)</h4>
                    <p><strong>Description:</strong> $($rec.Description)</p>
                    <p><strong>Impact:</strong> $($rec.Impact)</p>
                    <details>
                        <summary>Ressources concernées</summary>
                        $($rec.Resources)
                    </details>
                </div>
"@
            })
        </div>

        <div class="card">
            <h3>Détails des ressources Azure</h3>
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Groupe de ressources</th>
                        <th>Région</th>
                        <th>Taille</th>
                        <th>État</th>
                        <th>Coût mensuel (USD)</th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($vm in $AzureResources) {
                        $statusColor = switch ($vm.Status) {
                            "running" { "color: #4CAF50;" }
                            "deallocated" { "color: #F44336;" }
                            default { "color: #FB8C00;" }
                        }

                        @"
                        <tr>
                            <td>$($vm.Name)</td>
                            <td>$($vm.ResourceGroup)</td>
                            <td>$($vm.Location)</td>
                            <td>$($vm.Size)</td>
                            <td style="$statusColor">$($vm.Status)</td>
                            <td>$([Math]::Round($vm.MonthlyCost, 2))</td>
                        </tr>
"@
                    })
                </tbody>
            </table>
        </div>

        <div class="card">
            <h3>Détails des ressources AWS</h3>
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Zone de disponibilité</th>
                        <th>Type d'instance</th>
                        <th>État</th>
                        <th>Coût mensuel (USD)</th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($instance in $AWSResources) {
                        $statusColor = switch ($instance.Status) {
                            "running" { "color: #4CAF50;" }
                            "stopped" { "color: #F44336;" }
                            default { "color: #FB8C00;" }
                        }

                        @"
                        <tr>
                            <td>$($instance.Name)</td>
                            <td>$($instance.Location)</td>
                            <td>$($instance.Size)</td>
                            <td style="$statusColor">$($instance.Status)</td>
                            <td>$([Math]::Round($instance.MonthlyCost, 2))</td>
                        </tr>
"@
                    })
                </tbody>
            </table>
        </div>

        <div class="footer">
            <p>Ce rapport a été généré automatiquement avec PowerShell par le script Get-MultiCloudReport.ps1</p>
            <p>Formation PowerShell – Du Débutant à l'Expert | Module 12 - API, Web & Cloud</p>
        </div>
    </div>

    <script>
        // Charger les données
        const statusData = $statusData;
        const platformData = $platformData;
        const costData = $costData;

        // Créer les graphiques
        window.onload = function() {
            // Graphique de répartition par plateforme
            new Chart(document.getElementById('platformChart'), {
                type: 'pie',
                data: {
                    labels: platformData.map(item => item.name),
                    datasets: [{
                        data: platformData.map(item => item.value),
                        backgroundColor: platformData.map(item => item.color)
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    plugins: {
                        legend: {
                            position: 'right'
                        }
                    }
                }
            });

            // Graphique de répartition par état
            new Chart(document.getElementById('statusChart'), {
                type: 'pie',
                data: {
                    labels: statusData.map(item => item.name),
                    datasets: [{
                        data: statusData.map(item => item.value),
                        backgroundColor: statusData.map(item => item.color)
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    plugins: {
                        legend: {
                            position: 'right'
                        }
                    }
                }
            });

            // Graphique des coûts
            new Chart(document.getElementById('costChart'), {
                type: 'bar',
                data: {
                    labels: costData.map(item => item.name),
                    datasets: [{
                        label: 'Coût mensuel (USD)',
                        data: costData.map(item => item.value),
                        backgroundColor: costData.map(item => item.color)
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: true,
                    scales: {
                        y: {
                            beginAtZero: true,
                            title: {
                                display: true,
                                text: 'USD'
                            }
                        }
                    }
                }
            });
        };
    </script>
</body>
</html>
"@

    # Définir le chemin du fichier de sortie
    $outputFile = Join-Path -Path $OutputFolder -ChildPath "MultiCloudReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"

    # Enregistrer le rapport HTML
    $htmlReport | Out-File -FilePath $outputFile -Encoding UTF8

    Write-Log "Rapport généré avec succès: $outputFile" -Level SUCCESS

    # Ouvrir le rapport si demandé
    if ($OpenReportWhenDone) {
        Start-Process $outputFile
    }

    return $outputFile
}
#endregion Functions

#region Main Script
try {
    Write-Log "Démarrage de la génération du rapport multi-cloud..." -Level INFO

    # Vérification des modules requis
    $modulesOK = $true

    # Vérifier le module Az
    if (-not (Get-Module -ListAvailable -Name Az.Compute)) {
        Write-Log "Le module Az.Compute n'est pas installé. Impossible de collecter les données Azure." -Level WARNING
        $modulesOK = $false
    }

    # Vérifier le module AWS
    if (-not (Get-Module -ListAvailable -Name AWSPowerShell)) {
        Write-Log "Le module AWSPowerShell n'est pas installé. Impossible de collecter les données AWS." -Level WARNING
        $modulesOK = $false
    }

    if (-not $modulesOK) {
        $installModules = Read-Host "Voulez-vous installer les modules manquants maintenant? (O/N)"
        if ($installModules -eq "O" -or $installModules -eq "o") {
            if (-not (Get-Module -ListAvailable -Name Az.Compute)) {
                Write-Log "Installation du module Az.Compute..." -Level INFO
                Install-Module -Name Az.Compute -Scope CurrentUser -Force
            }

            if (-not (Get-Module -ListAvailable -Name AWSPowerShell)) {
                Write-Log "Installation du module AWSPowerShell..." -Level INFO
                Install-Module -Name AWSPowerShell -Scope CurrentUser -Force
            }
        }
        else {
            Write-Log "L'opération ne peut pas continuer sans les modules requis." -Level ERROR
            return
        }
    }

    # Se connecter à Azure si nécessaire
    if (-not (Get-AzContext)) {
        Write-Log "Connexion à Azure requise..." -Level INFO
        Connect-AzAccount
    }

    # Obtenir les ressources Azure
    $azureVMs = Get-AzureVMResources

    # Obtenir les ressources AWS
    $awsInstances = Get-AWSInstanceResources

    # Toutes les ressources combinées
    $allResources = $azureVMs + $awsInstances

    # Si aucune ressource n'est trouvée
    if ($allResources.Count -eq 0) {
        Write-Log "Aucune ressource cloud n'a été trouvée. Vérifiez vos identifiants et abonnements." -Level WARNING
        return
    }

    # Générer les recommandations
    Write-Log "Génération des recommandations d'optimisation..." -Level INFO
    $recommendations = New-OptimizationRecommendations -Resources $allResources

    # Créer le rapport HTML
    Write-Log "Création du rapport final..." -Level INFO
    $reportFile = New-MultiCloudReport -AzureResources $azureVMs -AWSResources $awsInstances -Recommendations $recommendations

    # Retourner le chemin du rapport
    return $reportFile
}
catch {
    Write-Log "Erreur lors de la création du rapport: $($_.Exception.Message)" -Level ERROR
    Write-Log "Détails: $($_.Exception.StackTrace)" -Level ERROR
}
#endregion Main Script
```

## Explication du script

### Vue d'ensemble

Ce script crée un rapport complet qui compare les ressources de calcul entre Azure et AWS, y compris:
1. Inventaire détaillé des VMs et instances
2. Analyse des coûts et métriques
3. Visualisations graphiques avec Chart.js
4. Recommandations d'optimisation personnalisées

### Fonctionnalités principales

#### 1. Collecte de données
- Connexion aux deux plateformes cloud
- Récupération des machines virtuelles Azure et des instances EC2 AWS
- Collecte d'informations détaillées: spécifications, état, coûts, etc.

#### 2. Analyse de coûts
- Estimation des coûts horaires et mensuels basée sur une base de données de prix
- Ajustement des coûts en fonction de l'état des ressources
- Comparaison des dépenses entre les plateformes

#### 3. Recommandations d'optimisation
- Identification des ressources inutilisées
- Détection des instances potentiellement surprovisionnées
- Vérification de la gouvernance (tags, etc.)

#### 4. Rapport HTML interactif
- Présentation visuelle des données avec graphiques
- Tableaux détaillés des ressources
- Recommandations d'optimisation priorisées
- Formatage adapté à l'impression

### Comment l'exécuter

```powershell
# Exécution simple
.\Get-MultiCloudReport.ps1

# Exécution avec paramètres personnalisés
.\Get-MultiCloudReport.ps1 -AWSProfileName "prod" -AzureSubscriptionId "12345-67890-abcde" -IncludeCostData -OpenReportWhenDone
```

## Points importants à noter

1. **Base de données de coûts**
   - Le script utilise une base de données intégrée de coûts estimés
   - Ces valeurs peuvent être ajustées si nécessaire pour correspondre à vos tarifs négociés

2. **Connexion multi-cloud**
   - Nécessite une authentification préalable pour Azure et AWS
   - Utilise les profils AWS pour une gestion sécurisée des identifiants

3. **Recommandations intelligentes**
   - Analyse les ressources selon plusieurs critères d'optimisation
   - Suggère des améliorations avec priorités et impact estimé

4. **Rapport autonome**
   - Le fichier HTML généré est autonome avec toutes les visualisations
   - Fonctionne hors ligne et peut être partagé facilement

Ce script constitue un excellent point de départ pour créer un tableau de bord multi-cloud de gestion des coûts et ressources.



# Solution Exercice 12.5.4 - Gestion des Buckets Google Cloud Storage

## Énoncé de l'exercice

Créez un script PowerShell qui permet de :
1. Lister tous les buckets Google Cloud Storage dans un projet spécifique
2. Créer un nouveau bucket avec les paramètres appropriés (région, classe de stockage, etc.)
3. Télécharger des fichiers locaux vers le bucket
4. Appliquer des règles de gestion du cycle de vie (lifecycle)
5. Générer un rapport sur l'utilisation du stockage

## Solution complète

```powershell
#####################################################################
# Script: Manage-GCPStorage.ps1
# Description: Interface PowerShell pour gérer les buckets Google Cloud Storage
# Auteur: Formation PowerShell
# Date: 27/04/2025
#####################################################################

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectId,

    [Parameter(Mandatory = $false)]
    [string]$CredentialsFile = "$env:USERPROFILE\gcp-credentials.json",

    [Parameter(Mandatory = $false)]
    [ValidateSet("List", "Create", "Upload", "SetLifecycle", "Report")]
    [string]$Action = "List",

    [Parameter(Mandatory = $false)]
    [string]$BucketName,

    [Parameter(Mandatory = $false)]
    [string]$Region = "europe-west1",

    [Parameter(Mandatory = $false)]
    [ValidateSet("STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE")]
    [string]$StorageClass = "STANDARD",

    [Parameter(Mandatory = $false)]
    [string]$LocalFilePath,

    [Parameter(Mandatory = $false)]
    [string]$DestinationPath,

    [Parameter(Mandatory = $false)]
    [int]$LifecycleDays = 30,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "$env:USERPROFILE\Documents\GCPReports"
)

#region Functions
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    # Format du message de log
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        'INFO'    { 'White' }
        'WARNING' { 'Yellow' }
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
        default   { 'White' }
    }

    Write-Host $logEntry -ForegroundColor $color
}

function Initialize-GCPAuthentication {
    param (
        [Parameter(Mandatory = $true)]
        [string]$CredentialsFilePath
    )

    if (-not (Test-Path -Path $CredentialsFilePath)) {
        throw "Le fichier d'identifiants GCP spécifié n'existe pas: $CredentialsFilePath"
    }

    try {
        # Définir la variable d'environnement pour l'authentification GCP
        $env:GOOGLE_APPLICATION_CREDENTIALS = $CredentialsFilePath
        Write-Log "Fichier d'identifiants GCP configuré: $CredentialsFilePath" -Level INFO

        # Vérifier si gcloud CLI est installé
        $gcloudExists = Get-Command gcloud -ErrorAction SilentlyContinue
        if (-not $gcloudExists) {
            throw "gcloud CLI n'est pas installé ou n'est pas dans le PATH. Veuillez l'installer depuis https://cloud.google.com/sdk/docs/install"
        }

        # Authentifier avec les identifiants définis
        $auth = Invoke-Expression "gcloud auth activate-service-account --key-file=$CredentialsFilePath" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Échec de l'authentification GCP: $auth"
        }

        Write-Log "Authentification GCP réussie" -Level SUCCESS

        # Si le ProjectId n'est pas spécifié, tenter de l'extraire du fichier d'identifiants
        if (-not $ProjectId) {
            $credentialsContent = Get-Content -Path $CredentialsFilePath -Raw | ConvertFrom-Json
            $script:ProjectId = $credentialsContent.project_id
            Write-Log "ProjectId extrait du fichier d'identifiants: $ProjectId" -Level INFO
        }

        return $true
    }
    catch {
        Write-Log "Erreur lors de l'initialisation de l'authentification GCP: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Get-GCSBuckets {
    try {
        Write-Log "Récupération de la liste des buckets pour le projet $ProjectId..." -Level INFO

        $buckets = Invoke-Expression "gcloud storage ls --project=$ProjectId" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la récupération des buckets: $buckets"
        }

        # Formater les résultats
        $formattedBuckets = @()
        foreach ($bucket in $buckets) {
            # Extraire le nom du bucket (supprimer "gs://")
            $bucketName = $bucket -replace "gs://", "" -replace "/", ""

            if (-not [string]::IsNullOrWhiteSpace($bucketName)) {
                # Obtenir des détails supplémentaires pour ce bucket
                $bucketDetails = Invoke-Expression "gcloud storage buckets describe gs://$bucketName --project=$ProjectId --format=json" | ConvertFrom-Json

                $formattedBuckets += [PSCustomObject]@{
                    Name = $bucketName
                    Location = $bucketDetails.location
                    StorageClass = $bucketDetails.storageClass
                    TimeCreated = $bucketDetails.timeCreated
                    Updated = $bucketDetails.updated
                    VersioningEnabled = $bucketDetails.versioning.enabled
                    Link = "gs://$bucketName"
                }
            }
        }

        Write-Log "Nombre de buckets trouvés: $($formattedBuckets.Count)" -Level SUCCESS
        return $formattedBuckets
    }
    catch {
        Write-Log "Erreur lors de la récupération des buckets: $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function New-GCSBucket {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Location,

        [Parameter(Mandatory = $true)]
        [string]$StorageClass
    )

    try {
        Write-Log "Création du bucket '$Name' dans la région '$Location' avec la classe de stockage '$StorageClass'..." -Level INFO

        $result = Invoke-Expression "gcloud storage buckets create gs://$Name --project=$ProjectId --location=$Location --default-storage-class=$StorageClass" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la création du bucket: $result"
        }

        Write-Log "Bucket '$Name' créé avec succès" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Erreur lors de la création du bucket: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Send-FileToGCS {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$BucketName,

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath = ""
    )

    try {
        if (-not (Test-Path -Path $SourcePath)) {
            throw "Le fichier ou dossier source n'existe pas: $SourcePath"
        }

        # Construire le chemin de destination complet
        $destination = "gs://$BucketName"
        if (-not [string]::IsNullOrWhiteSpace($DestinationPath)) {
            $destination = "$destination/$DestinationPath"
        }

        Write-Log "Téléversement de '$SourcePath' vers '$destination'..." -Level INFO

        # Si le chemin source est un dossier, téléverser de manière récursive
        $recursiveFlag = ""
        if ((Get-Item $SourcePath) -is [System.IO.DirectoryInfo]) {
            $recursiveFlag = "-r"
        }

        $result = Invoke-Expression "gcloud storage cp $recursiveFlag '$SourcePath' '$destination' --project=$ProjectId" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors du téléversement: $result"
        }

        Write-Log "Téléversement vers '$destination' réussi" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Erreur lors du téléversement: $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Set-GCSLifecyclePolicy {
    param (
        [Parameter(Mandatory = $true)]
        [string]$BucketName,

        [Parameter(Mandatory = $true)]
        [int]$AgeDays,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Delete", "SetStorageClass")]
        [string]$Action = "Delete",

        [Parameter(Mandatory = $false)]
        [ValidateSet("NEARLINE", "COLDLINE", "ARCHIVE")]
        [string]$NewStorageClass = "NEARLINE"
    )

    try {
        # Créer le fichier de configuration du cycle de vie temporaire
        $tempFile = [System.IO.Path]::GetTempFileName() -replace ".tmp", ".json"

        if ($Action -eq "Delete") {
            $lifecycleConfig = @"
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "age": $AgeDays
        }
      }
    ]
  }
}
"@
        }
        else {
            $lifecycleConfig = @"
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "SetStorageClass",
          "storageClass": "$NewStorageClass"
        },
        "condition": {
          "age": $AgeDays
        }
      }
    ]
  }
}
"@
        }

        # Enregistrer la configuration dans le fichier temporaire
        $lifecycleConfig | Out-File -FilePath $tempFile -Encoding UTF8

        Write-Log "Application de la règle de cycle de vie au bucket '$BucketName' (action: $Action, âge: $AgeDays jours)..." -Level INFO

        $result = Invoke-Expression "gcloud storage buckets update gs://$BucketName --lifecycle-file='$tempFile' --project=$ProjectId" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de l'application de la règle de cycle de vie: $result"
        }

        # Supprimer le fichier temporaire
        if (Test-Path -Path $tempFile) {
            Remove-Item -Path $tempFile -Force
        }

        Write-Log "Règle de cycle de vie appliquée avec succès au bucket '$BucketName'" -Level SUCCESS
        return $true
    }
    catch {
        Write-Log "Erreur lors de l'application de la règle de cycle de vie: $($_.Exception.Message)" -Level ERROR

        # Supprimer le fichier temporaire en cas d'erreur
        if (Test-Path -Path $tempFile) {
            Remove-Item -Path $tempFile -Force
        }

        return $false
    }
}

function Get-GCSBucketSize {
    param (
        [Parameter(Mandatory = $true)]
        [string]$BucketName
    )

    try {
        Write-Log "Récupération des informations de taille pour le bucket '$BucketName'..." -Level INFO

        $result = Invoke-Expression "gcloud storage du -s gs://$BucketName --project=$ProjectId" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de la récupération de la taille du bucket: $result"
        }

        # Analyser la sortie pour extraire la taille
        $sizeInfo = $result | Select-String -Pattern "(\d+(\.\d+)?)\s+(\w+)\s+TOTAL" -AllMatches

        if ($sizeInfo.Matches.Count -gt 0) {
            $size = $sizeInfo.Matches[0].Groups[1].Value
            $unit = $sizeInfo.Matches[0].Groups[3].Value
            return "$size $unit"
        }
        else {
            return "0 B"
        }
    }
    catch {
        Write-Log "Erreur lors de la récupération de la taille du bucket: $($_.Exception.Message)" -Level ERROR
        return "Erreur"
    }
}

function Get-GCSBucketObjectCount {
    param (
        [Parameter(Mandatory = $true)]
        [string]$BucketName
    )

    try {
        Write-Log "Comptage des objets dans le bucket '$BucketName'..." -Level INFO

        $result = Invoke-Expression "gcloud storage ls gs://$BucketName --project=$ProjectId --recursive" 2>&1

        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors du comptage des objets: $result"
        }

        $count = ($result | Measure-Object).Count
        return $count
    }
    catch {
        Write-Log "Erreur lors du comptage des objets: $($_.Exception.Message)" -Level ERROR
        return 0
    }
}

function New-GCSReport {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Buckets
    )

    try {
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputFolder)) {
            New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        }

        $reportDate = Get-Date -Format "yyyy-MM-dd_HHmmss"
        $reportFile = Join-Path -Path $OutputFolder -ChildPath "GCS_Report_$reportDate.html"

        Write-Log "Génération du rapport pour $($Buckets.Count) buckets..." -Level INFO

        # Collecter des données détaillées pour chaque bucket
        $enrichedBuckets = @()
        foreach ($bucket in $Buckets) {
            $size = Get-GCSBucketSize -BucketName $bucket.Name
            $objectCount = Get-GCSBucketObjectCount -BucketName $bucket.Name

            $enrichedBuckets += [PSCustomObject]@{
                Name = $bucket.Name
                Location = $bucket.Location
                StorageClass = $bucket.StorageClass
                Size = $size
                ObjectCount = $objectCount
                TimeCreated = $bucket.TimeCreated
                VersioningEnabled = $bucket.VersioningEnabled
            }
        }

        # Créer le rapport HTML
        $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport Google Cloud Storage - $ProjectId</title>
    <style>
        body {
            font-family: 'Roboto', 'Segoe UI', Arial, sans-serif;
            margin: 0;
            padding: 20px;
            color: #202124;
            background-color: #f8f9fa;
        }
        .header {
            background: linear-gradient(135deg, #4285F4 0%, #34A853 100%);
            color: white;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .card {
            background-color: white;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            margin-bottom: 20px;
            padding: 20px;
        }
        .card h3 {
            margin-top: 0;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
            color: #4285F4;
        }
        .summary {
            display: flex;
            flex-wrap: wrap;
            gap: 15px;
            margin-bottom: 20px;
        }
        .summary-box {
            flex: 1;
            min-width: 200px;
            background-color: white;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            text-align: center;
        }
        .summary-box h4 {
            margin: 0;
            font-size: 14px;
            color: #5f6368;
        }
        .summary-box p {
            margin: 10px 0 0;
            font-size: 24px;
            font-weight: bold;
            color: #4285F4;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            text-align: left;
            padding: 12px;
            border-bottom: 1px solid #eee;
        }
        th {
            background-color: #f8f9fa;
            font-weight: 500;
            color: #5f6368;
        }
        tr:hover {
            background-color: #f8f9fa;
        }
        .footer {
            text-align: center;
            margin-top: 40px;
            color: #5f6368;
            font-size: 12px;
        }
        .storage-class {
            display: inline-block;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 500;
        }
        .standard { background-color: #e8f0fe; color: #1a73e8; }
        .nearline { background-color: #e6f4ea; color: #137333; }
        .coldline { background-color: #e8eaed; color: #444746; }
        .archive { background-color: #fce8e6; color: #c5221f; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Rapport Google Cloud Storage</h1>
            <p>Projet: $ProjectId | Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>
        </div>

        <div class="card">
            <h3>Résumé du stockage</h3>
            <div class="summary">
                <div class="summary-box">
                    <h4>Nombre de buckets</h4>
                    <p>$($enrichedBuckets.Count)</p>
                </div>
                <div class="summary-box">
                    <h4>Régions</h4>
                    <p>$($enrichedBuckets.Location | Select-Object -Unique | Measure-Object).Count</p>
                </div>
                <div class="summary-box">
                    <h4>Classes de stockage utilisées</h4>
                    <p>$($enrichedBuckets.StorageClass | Select-Object -Unique | Measure-Object).Count</p>
                </div>
                <div class="summary-box">
                    <h4>Total objets stockés</h4>
                    <p>$($enrichedBuckets.ObjectCount | Measure-Object -Sum).Sum</p>
                </div>
            </div>
        </div>

        <div class="card">
            <h3>Détails des buckets</h3>
            <table>
                <thead>
                    <tr>
                        <th>Nom</th>
                        <th>Région</th>
                        <th>Classe de stockage</th>
                        <th>Taille</th>
                        <th>Objets</th>
                        <th>Date de création</th>
                        <th>Versioning</th>
                    </tr>
                </thead>
                <tbody>
                    $(foreach ($bucket in $enrichedBuckets) {
                        $storageClassStyle = switch ($bucket.StorageClass) {
                            "STANDARD" { "standard" }
                            "NEARLINE" { "nearline" }
                            "COLDLINE" { "coldline" }
                            "ARCHIVE" { "archive" }
                            default { "standard" }
                        }

                        $versioningStatus = if ($bucket.VersioningEnabled) { "Activé" } else { "Désactivé" }

                        @"
                        <tr>
                            <td><strong>$($bucket.Name)</strong></td>
                            <td>$($bucket.Location)</td>
                            <td><span class="storage-class $storageClassStyle">$($bucket.StorageClass)</span></td>
                            <td>$($bucket.Size)</td>
                            <td>$($bucket.ObjectCount)</td>
                            <td>$($bucket.TimeCreated)</td>
                            <td>$versioningStatus</td>
                        </tr>
"@
                    })
                </tbody>
            </table>
        </div>

        <div class="card">
            <h3>Recommandations</h3>
            <ul>
                $(
                # Buckets avec la classe STANDARD qui pourraient être optimisés
                $standardBuckets = $enrichedBuckets | Where-Object { $_.StorageClass -eq "STANDARD" }
                if ($standardBuckets.Count -gt 0) {
                    "<li>Considérez utiliser une classe de stockage plus économique (NEARLINE, COLDLINE) pour les $($standardBuckets.Count) buckets actuellement en STANDARD si les données sont rarement accédées.</li>"
                }

                # Buckets sans versioning
                $nonVersionedBuckets = $enrichedBuckets | Where-Object { -not $_.VersioningEnabled }
                if ($nonVersionedBuckets.Count -gt 0) {
                    "<li>Activez le versionnement pour les $($nonVersionedBuckets.Count) buckets qui ne l'ont pas actuellement afin de protéger contre les suppressions accidentelles.</li>"
                }

                # Recommandation générale sur les règles de cycle de vie
                "<li>Configurez des règles de cycle de vie pour automatiser la transition entre les classes de stockage et réduire les coûts.</li>"

                # Recommandation sur la localisation
                "<li>Pour optimiser les performances et réduire la latence, assurez-vous que vos buckets sont dans les régions proches de vos utilisateurs.</li>"
                )
            </ul>
        </div>

        <div class="footer">
            <p>Ce rapport a été généré automatiquement avec PowerShell par le script Manage-GCPStorage.ps1</p>
            <p>Formation PowerShell – Du Débutant à l'Expert | Module 12 - API, Web & Cloud</p>
        </div>
    </div>
</body>
</html>
"@

        # Enregistrer le rapport HTML
        $htmlReport | Out-File -FilePath $reportFile -Encoding UTF8

        Write-Log "Rapport généré avec succès: $reportFile" -Level SUCCESS

        return $reportFile
    }
    catch {
        Write-Log "Erreur lors de la génération du rapport: $($_.Exception.Message)" -Level ERROR
        return $null
    }
}
#endregion Functions

#region Main Script
try {
    # Vérifier si le ProjectId est spécifié ou sera extrait du fichier d'identifiants
    if (-not $ProjectId -and -not $CredentialsFile) {
        throw "Vous devez spécifier soit un ProjectId, soit un fichier d'identifiants contenant les informations du projet."
    }

    # Initialiser l'authentification GCP
    $authSuccess = Initialize-GCPAuthentication -CredentialsFilePath $CredentialsFile

    if (-not $authSuccess) {
        throw "Impossible de s'authentifier auprès de Google Cloud. Vérifiez votre fichier d'identifiants."
    }

    # Exécuter l'action demandée
    switch ($Action) {
        "List" {
            $buckets = Get-GCSBuckets
            $buckets | Format-Table -AutoSize
            return $buckets
        }

        "Create" {
            if (-not $BucketName) {
                throw "Le paramètre BucketName est requis pour créer un bucket."
            }

            $result = New-GCSBucket -Name $BucketName -Location $Region -StorageClass $StorageClass

            if ($result) {
                Write-Log "Bucket '$BucketName' créé avec succès dans la région '$Region' avec la classe de stockage '$StorageClass'" -Level SUCCESS
            }
            else {
                Write-Log "Échec de la création du bucket '$BucketName'" -Level ERROR
            }

            return $result
        }

        "Upload" {
            if (-not $BucketName) {
                throw "Le paramètre BucketName est requis pour téléverser des fichiers."
            }

            if (-not $LocalFilePath) {
                throw "Le paramètre LocalFilePath est requis pour téléverser des fichiers."
            }

            $result = Send-FileToGCS -SourcePath $LocalFilePath -BucketName $BucketName -DestinationPath $DestinationPath

            if ($result) {
                Write-Log "Téléversement réussi vers le bucket '$BucketName'" -Level SUCCESS
            }
            else {
                Write-Log "Échec du téléversement vers le bucket '$BucketName'" -Level ERROR
            }

            return $result
        }

        "SetLifecycle" {
            if (-not $BucketName) {
                throw "Le paramètre BucketName est requis pour configurer le cycle de vie."
            }

            $result = Set-GCSLifecyclePolicy -BucketName $BucketName -AgeDays $LifecycleDays -Action "Delete"

            if ($result) {
                Write-Log "Règle de cycle de vie appliquée avec succès au bucket '$BucketName'" -Level SUCCESS
            }
            else {
                Write-Log "Échec de l'application de la règle de cycle de vie au bucket '$BucketName'" -Level ERROR
            }

            return $result
        }

        "Report" {
            $buckets = Get-GCSBuckets
            $reportFile = New-GCSReport -Buckets $buckets

            if ($reportFile) {
                Write-Log "Rapport généré avec succès: $reportFile" -Level SUCCESS
                # Ouvrir le rapport dans le navigateur par défaut
                Start-Process $reportFile
            }
            else {
                Write-Log "Échec de la génération du rapport" -Level ERROR
            }

            return $reportFile
        }
    }
}
catch {
    Write-Log "Erreur lors de l'exécution du script: $($_.Exception.Message)" -Level ERROR
    Write-Log "Détails: $($_.Exception.StackTrace)" -Level ERROR
}
#endregion Main Script
```

## Explication du script

### Vue d'ensemble

Ce script fournit une interface PowerShell complète pour gérer les buckets Google Cloud Storage, permettant de réaliser les opérations courantes sans avoir à mémoriser les commandes gcloud complexes.

### Fonctionnalités principales

#### 1. Gestion des buckets
- Lister tous les buckets d'un projet GCP
- Créer de nouveaux buckets avec paramètres personnalisés
- Appliquer des règles de cycle de vie (suppression automatique ou changement de classe)
- Générer des rapports détaillés sur l'utilisation du stockage

#### 2. Gestion des objets
- Téléverser des fichiers ou dossiers entiers vers un bucket
- Obtenir des statistiques sur les objets stockés (nombre, taille totale)

#### 3. Authentification
- Support de l'authentification basée sur un fichier de compte de service
- Intégration avec gcloud CLI pour des opérations plus complexes

#### 4. Reporting
- Génération de rapports HTML interactifs et visuellement attrayants
- Calcul automatique des métriques d'utilisation
- Recommandations d'optimisation basées sur l'analyse des buckets

### Comment utiliser le script

```powershell
# Configuration du fichier d'identifiants (à faire une seule fois)
$credFile = "C:\path\to\your-service-account.json"

# Lister tous les buckets
.\Manage-GCPStorage.ps1 -CredentialsFile $credFile -Action List

# Créer un nouveau bucket
.\Manage-GCPStorage.ps1 -CredentialsFile $credFile -Action Create -BucketName "mon-bucket-unique" -Region "europe-west1" -StorageClass "STANDARD"

# Téléverser un fichier
.\Manage-GCPStorage.ps1 -CredentialsFile $credFile -Action Upload -BucketName "mon-bucket-unique" -LocalFilePath "C:\path\to\file.txt" -DestinationPath "dossier/fichier.txt"

# Configurer une règle de cycle de vie (supprimer après 90 jours)
.\Manage-GCPStorage.ps1 -CredentialsFile $credFile -Action SetLifecycle -BucketName "mon-bucket-unique" -LifecycleDays 90

# Générer un rapport d'utilisation
.\Manage-GCPStorage.ps1 -CredentialsFile $credFile -Action Report -OutputFolder "C:\Rapports"
```

### Points importants

1. **Prérequis**
   - Google Cloud SDK (gcloud CLI) doit être installé
   - Un compte de service GCP avec les permissions appropriées est nécessaire

2. **Authentification**
   - Utilise les mécanismes standards de GCP avec un fichier de clé JSON
   - Permet d'extraire automatiquement l'ID du projet depuis le fichier d'identifiants

3. **Intégration**
   - Combine PowerShell et gcloud CLI de manière transparente
   - Traite les résultats JSON pour les rendre facilement manipulables en PowerShell

4. **Bonnes pratiques**
   - Journalisation détaillée des opérations
   - Gestion appropriée des erreurs
   - Paramètres avec validation pour éviter les erreurs courantes
