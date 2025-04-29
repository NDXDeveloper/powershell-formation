# Solutions des exercices - Gestion des certificats PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Exercice 1 : Lister tous les certificats personnels de l'utilisateur courant

```powershell
# Exercice1-ListeCertificatsPersonnels.ps1
#
# Description : Script pour lister tous les certificats personnels
# de l'utilisateur courant avec leurs informations principales
# et un indicateur de statut visuel.
#
# Usage : .\Exercice1-ListeCertificatsPersonnels.ps1

# Définir les en-têtes pour une sortie plus claire
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  LISTE DES CERTIFICATS PERSONNELS DE L'UTILISATEUR" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Récupérer les certificats et les afficher dans un format lisible
Get-ChildItem -Path Cert:\CurrentUser\My |
    Select-Object @{Name="Sujet"; Expression={
        # Nettoyer le format du sujet pour le rendre plus lisible
        if ($_.Subject -match "CN=([^,]+)") {
            $matches[1]
        } else {
            $_.Subject
        }
    }},
    @{Name="Émetteur"; Expression={
        # Nettoyer le format de l'émetteur
        if ($_.Issuer -match "CN=([^,]+)") {
            $matches[1]
        } else {
            $_.Issuer
        }
    }},
    @{Name="Valide depuis"; Expression={$_.NotBefore.ToString("dd/MM/yyyy")}},
    @{Name="Valide jusqu'au"; Expression={$_.NotAfter.ToString("dd/MM/yyyy")}},
    @{Name="Jours restants"; Expression={
        $jours = ($_.NotAfter - (Get-Date)).Days
        if ($jours -lt 0) {
            "Expiré"
        } else {
            $jours
        }
    }},
    @{Name="Statut"; Expression={
        if ($_.NotAfter -lt (Get-Date)) {
            "❌ Expiré"
        } elseif (($_.NotAfter - (Get-Date)).Days -lt 30) {
            "⚠️ Expire bientôt"
        } else {
            "✅ Valide"
        }
    }},
    @{Name="Empreinte"; Expression={$_.Thumbprint}} |
    Format-Table -AutoSize

# Afficher un résumé
$totalCerts = (Get-ChildItem -Path Cert:\CurrentUser\My).Count
$expiredCerts = (Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.NotAfter -lt (Get-Date) }).Count
$soonExpiringCerts = (Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object {
    ($_.NotAfter -gt (Get-Date)) -and ($_.NotAfter -lt (Get-Date).AddDays(30))
}).Count

Write-Host "Résumé:" -ForegroundColor Green
Write-Host "- Total des certificats: $totalCerts" -ForegroundColor White
Write-Host "- Certificats expirés: $expiredCerts" -ForegroundColor $(if($expiredCerts -gt 0){"Red"}else{"White"})
Write-Host "- Certificats expirant dans 30 jours: $soonExpiringCerts" -ForegroundColor $(if($soonExpiringCerts -gt 0){"Yellow"}else{"White"})

# Sauvegarde optionnelle dans un fichier CSV
$saveToFile = Read-Host "Voulez-vous sauvegarder ces informations dans un fichier CSV? (O/N)"
if ($saveToFile -eq "O" -or $saveToFile -eq "o") {
    $csvPath = Join-Path -Path $env:USERPROFILE -ChildPath "Documents\CertificatsPersonnels_$(Get-Date -Format 'yyyyMMdd').csv"
    Get-ChildItem -Path Cert:\CurrentUser\My |
        Select-Object Subject, Issuer, NotBefore, NotAfter,
                   @{Name="DaysRemaining"; Expression={($_.NotAfter - (Get-Date)).Days}},
                   Thumbprint |
        Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Informations sauvegardées dans: $csvPath" -ForegroundColor Green
}
```

## Exercice 2 : Créer un script qui exporte tous les certificats d'un magasin spécifique

```powershell
# Exercice2-ExportCertificatsStore.ps1
#
# Description : Script pour exporter tous les certificats
# d'un magasin spécifique vers un dossier
#
# Usage :
# Pour certificats sans clé privée (format .cer):
#   .\Exercice2-ExportCertificatsStore.ps1 -StoreLocation CurrentUser -StoreName Root -ExportPath C:\Temp\ExportCerts
#
# Pour certificats avec clé privée (format .pfx):
#   .\Exercice2-ExportCertificatsStore.ps1 -StoreLocation CurrentUser -StoreName My -ExportPath C:\Temp\ExportCerts -ExportPrivateKeys -PasswordForPfx "MonMotDePasse"

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("CurrentUser", "LocalMachine")]
    [string]$StoreLocation,

    [Parameter(Mandatory=$true)]
    [ValidateSet("My", "Root", "CA", "TrustedPublisher")]
    [string]$StoreName,

    [Parameter(Mandatory=$true)]
    [string]$ExportPath,

    [Parameter(Mandatory=$false)]
    [switch]$ExportPrivateKeys,

    [Parameter(Mandatory=$false)]
    [string]$PasswordForPfx
)

# Fonction pour créer un nom de fichier valide à partir du sujet du certificat
function Get-ValidFileName {
    param (
        [string]$name
    )

    # Remplacer les caractères invalides pour un nom de fichier
    $invalidChars = [IO.Path]::GetInvalidFileNameChars()
    $result = $name
    foreach ($char in $invalidChars) {
        $result = $result.Replace($char, '_')
    }

    # Limiter la longueur et remplacer les espaces
    $result = $result.Replace(' ', '_').Substring(0, [Math]::Min(50, $result.Length))

    return $result
}

# Créer le dossier d'export s'il n'existe pas
if (-not (Test-Path -Path $ExportPath)) {
    Write-Host "Création du dossier d'export: $ExportPath" -ForegroundColor Yellow
    New-Item -Path $ExportPath -ItemType Directory -Force | Out-Null
}

# Définir le chemin du magasin
$storePath = "Cert:\$StoreLocation\$StoreName"

# Vérifier si le magasin existe
if (-not (Test-Path -Path $storePath)) {
    Write-Host "❌ Erreur: Le magasin de certificats '$storePath' n'existe pas." -ForegroundColor Red
    exit 1
}

# Récupérer les certificats
$certificates = Get-ChildItem -Path $storePath

if ($certificates.Count -eq 0) {
    Write-Host "⚠️ Aucun certificat trouvé dans le magasin '$storePath'." -ForegroundColor Yellow
    exit 0
}

Write-Host "Début de l'exportation de $($certificates.Count) certificat(s) du magasin '$storePath'..." -ForegroundColor Cyan
$exportCount = 0
$errorCount = 0

# Créer un fichier de log
$logFile = Join-Path -Path $ExportPath -ChildPath "export_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
"Date d'exportation: $(Get-Date)" | Out-File -FilePath $logFile
"Magasin: $storePath" | Out-File -FilePath $logFile -Append

# Si on exporte des clés privées, vérifier et préparer le mot de passe
$securePassword = $null
if ($ExportPrivateKeys) {
    if (-not $PasswordForPfx) {
        $securePassword = Read-Host "Entrez un mot de passe pour protéger les clés privées" -AsSecureString
    } else {
        $securePassword = ConvertTo-SecureString -String $PasswordForPfx -Force -AsPlainText
    }
}

# Parcourir tous les certificats et les exporter
foreach ($cert in $certificates) {
    try {
        # Obtenir les informations du certificat pour le nom du fichier
        $subject = $cert.Subject
        if ($subject -match "CN=([^,]+)") {
            $subject = $matches[1]
        }

        $fileName = Get-ValidFileName -name $subject
        $fileName = "$fileName-$($cert.Thumbprint.Substring(0, 8))"

        # Déterminer le type d'export
        if ($ExportPrivateKeys -and $cert.HasPrivateKey) {
            # Export PFX (avec clé privée)
            $exportPath = Join-Path -Path $ExportPath -ChildPath "$fileName.pfx"
            Export-PfxCertificate -Cert $cert -FilePath $exportPath -Password $securePassword | Out-Null
            Write-Host "✅ Certificat exporté (avec clé privée): $fileName.pfx" -ForegroundColor Green
            "EXPORT PFX: $($cert.Subject) -> $fileName.pfx" | Out-File -FilePath $logFile -Append
        } else {
            # Export CER (certificat public uniquement)
            $exportPath = Join-Path -Path $ExportPath -ChildPath "$fileName.cer"
            Export-Certificate -Cert $cert -FilePath $exportPath | Out-Null
            Write-Host "✅ Certificat exporté: $fileName.cer" -ForegroundColor Green
            "EXPORT CER: $($cert.Subject) -> $fileName.cer" | Out-File -FilePath $logFile -Append
        }

        $exportCount++
    }
    catch {
        Write-Host "❌ Erreur lors de l'exportation du certificat: $($cert.Subject)" -ForegroundColor Red
        Write-Host "   Détail: $_" -ForegroundColor Red
        "ERREUR: $($cert.Subject) - $_" | Out-File -FilePath $logFile -Append
        $errorCount++
    }
}

# Afficher le résumé
Write-Host "`nExportation terminée!" -ForegroundColor Cyan
Write-Host "- Certificats exportés avec succès: $exportCount" -ForegroundColor Green
if ($errorCount -gt 0) {
    Write-Host "- Erreurs d'exportation: $errorCount" -ForegroundColor Red
}
Write-Host "- Chemin d'exportation: $ExportPath" -ForegroundColor White
Write-Host "- Fichier de log: $logFile" -ForegroundColor White

# Ouvrir le dossier d'exportation
$openFolder = Read-Host "Voulez-vous ouvrir le dossier contenant les certificats exportés? (O/N)"
if ($openFolder -eq "O" -or $openFolder -eq "o") {
    Start-Process explorer.exe -ArgumentList $ExportPath
}
```

## Exercice 3 : Fonction qui vérifie quotidiennement si des certificats expirent dans les 30 jours

```powershell
# Exercice3-SurveillanceCertificatsExpiration.ps1
#
# Description : Script pour surveiller quotidiennement les certificats qui expirent
# dans les 30 prochains jours et envoyer des alertes par email
#
# Usage :
# 1. Configurer les paramètres email au début du script
# 2. Exécuter manuellement : .\Exercice3-SurveillanceCertificatsExpiration.ps1
# 3. Pour planifier une tâche quotidienne, exécuter avec le paramètre -CreerTachePlanifiee :
#    .\Exercice3-SurveillanceCertificatsExpiration.ps1 -CreerTachePlanifiee

param (
    [switch]$CreerTachePlanifiee,
    [int]$JoursAvantExpiration = 30,
    [switch]$EnvoyerEmail,
    [string]$EmailFrom = "surveillance@votreentreprise.com",
    [string]$EmailTo = "admin@votreentreprise.com",
    [string]$SmtpServer = "smtp.votreentreprise.com",
    [int]$SmtpPort = 25
)

# Fonction principale : vérification des certificats expirant prochainement
function Test-CertificatsExpiration {
    param (
        [int]$JoursAvantExpiration = 30
    )

    # Initialiser les tableaux pour stocker les résultats
    $certificatsExpirants = @()
    $magasinsACertifier = @(
        @{Location="LocalMachine"; Store="My"; Description="Machine - Personnel"},
        @{Location="LocalMachine"; Store="WebHosting"; Description="Machine - Hébergement Web"},
        @{Location="CurrentUser"; Store="My"; Description="Utilisateur - Personnel"}
    )

    # Obtenir la date limite
    $dateLimite = (Get-Date).AddDays($JoursAvantExpiration)

    # Vérifier chaque magasin de certificats
    foreach ($magasin in $magasinsACertifier) {
        $chemin = "Cert:\$($magasin.Location)\$($magasin.Store)"

        # Vérifier si le magasin existe
        if (Test-Path -Path $chemin) {
            Write-Host "Vérification du magasin: $($magasin.Description)" -ForegroundColor Cyan

            # Récupérer les certificats qui expirent bientôt
            $certificatsMagasin = Get-ChildItem -Path $chemin | Where-Object {
                # Ne pas afficher les certificats déjà expirés
                ($_.NotAfter -gt (Get-Date)) -and
                # Afficher ceux qui expirent avant la date limite
                ($_.NotAfter -le $dateLimite)
            } | Select-Object @{
                Name="Magasin";
                Expression={$magasin.Description}
            }, @{
                Name="Sujet";
                Expression={
                    if ($_.Subject -match "CN=([^,]+)") {
                        $matches[1]
                    } else {
                        $_.Subject
                    }
                }
            }, @{
                Name="Émetteur";
                Expression={
                    if ($_.Issuer -match "CN=([^,]+)") {
                        $matches[1]
                    } else {
                        $_.Issuer
                    }
                }
            }, @{
                Name="Expiration";
                Expression={$_.NotAfter}
            }, @{
                Name="JoursRestants";
                Expression={($_.NotAfter - (Get-Date)).Days}
            }, @{
                Name="Empreinte";
                Expression={$_.Thumbprint}
            }

            # Ajouter à la liste globale
            $certificatsExpirants += $certificatsMagasin
        }
    }

    return $certificatsExpirants
}

# Fonction pour créer un rapport HTML
function New-CertificatsExpirationReport {
    param (
        [array]$Certificats
    )

    # Préparer l'en-tête HTML
    $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport d'expiration des certificats</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #003366; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; }
        th { background-color: #f2f2f2; text-align: left; }
        .expireSoon { background-color: #FFEB9C; }
        .expireVerySoon { background-color: #FFC7CE; color: #9C0006; }
        .footer { margin-top: 20px; font-size: 12px; color: #666; }
    </style>
</head>
<body>
    <h1>Rapport d'expiration des certificats</h1>
    <p>Date du rapport: $(Get-Date -Format "dd/MM/yyyy HH:mm")</p>
    <p>Certificats expirant dans les prochains $JoursAvantExpiration jours: <strong>$($Certificats.Count)</strong></p>
"@

    # Si aucun certificat n'expire bientôt
    if ($Certificats.Count -eq 0) {
        $htmlBody = "<p style='color: green; font-weight: bold;'>Aucun certificat n'expire dans les $JoursAvantExpiration prochains jours.</p>"
    } else {
        # Créer le tableau HTML
        $htmlBody = @"
    <table>
        <tr>
            <th>Magasin</th>
            <th>Sujet</th>
            <th>Émetteur</th>
            <th>Date d'expiration</th>
            <th>Jours restants</th>
        </tr>
"@

        # Ajouter chaque certificat au tableau
        foreach ($cert in ($Certificats | Sort-Object JoursRestants)) {
            $rowClass = ""
            if ($cert.JoursRestants -lt 7) {
                $rowClass = "expireVerySoon"
            } elseif ($cert.JoursRestants -lt 14) {
                $rowClass = "expireSoon"
            }

            $htmlBody += @"
        <tr class="$rowClass">
            <td>$($cert.Magasin)</td>
            <td>$($cert.Sujet)</td>
            <td>$($cert.Émetteur)</td>
            <td>$($cert.Expiration.ToString("dd/MM/yyyy"))</td>
            <td>$($cert.JoursRestants)</td>
        </tr>
"@
        }

        # Fermer le tableau
        $htmlBody += "</table>"
    }

    # Ajouter le pied de page
    $htmlFooter = @"
    <div class="footer">
        <p>Ce rapport a été généré automatiquement par le script SurveillanceCertificatsExpiration.ps1</p>
        <p>Ordinateur: $env:COMPUTERNAME | Utilisateur: $env:USERNAME</p>
    </div>
</body>
</html>
"@

    # Assembler le rapport complet
    $htmlReport = $htmlHeader + $htmlBody + $htmlFooter
    return $htmlReport
}

# Fonction pour envoyer un email
function Send-CertificatsExpirationEmail {
    param (
        [string]$HtmlContent,
        [int]$NombreCertificats
    )

    # Créer l'objet pour l'email
    $messageSubject = "[$env:COMPUTERNAME] "
    if ($NombreCertificats -eq 0) {
        $messageSubject += "Aucun certificat en expiration"
    } else {
        $messageSubject += "ALERTE: $NombreCertificats certificat(s) expirent bientôt"
    }

    # Paramètres de l'email
    $mailParams = @{
        From = $EmailFrom
        To = $EmailTo
        Subject = $messageSubject
        Body = $HtmlContent
        BodyAsHtml = $true
        SmtpServer = $SmtpServer
        Port = $SmtpPort
        # Décommentez les lignes suivantes si l'authentification SMTP est nécessaire
        # Credential = (Get-Credential -Message "Entrez les informations d'identification SMTP")
        # UseSSL = $true
    }

    try {
        # Envoyer l'email
        Send-MailMessage @mailParams
        Write-Host "✅ Email envoyé avec succès à $EmailTo" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Erreur lors de l'envoi de l'email: $_" -ForegroundColor Red
        return $false
    }
}

# Fonction pour créer une tâche planifiée Windows
function New-CertificatsExpirationTask {
    $scriptPath = $MyInvocation.MyCommand.Path
    $taskName = "SurveillanceCertificatsExpiration"
    $description = "Vérifie quotidiennement les certificats qui vont expirer et envoie des alertes"

    # Créer l'action de la tâche (exécuter ce script)
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" -EnvoyerEmail"

    # Déclencheur (tous les jours à 8h du matin)
    $trigger = New-ScheduledTaskTrigger -Daily -At 8am

    # Paramètres (s'exécuter que l'utilisateur soit connecté ou non)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    # Enregistrer la tâche
    try {
        # Vérifier si la tâche existe déjà
        $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

        if ($existingTask) {
            # Mettre à jour la tâche existante
            Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description $description
            Write-Host "✅ Tâche planifiée '$taskName' mise à jour avec succès." -ForegroundColor Green
        } else {
            # Créer une nouvelle tâche
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description $description -User "SYSTEM"
            Write-Host "✅ Tâche planifiée '$taskName' créée avec succès." -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Host "❌ Erreur lors de la création de la tâche planifiée: $_" -ForegroundColor Red
        return $false
    }
}

# LOGIQUE PRINCIPALE DU SCRIPT

# Si l'option de création de tâche planifiée est activée
if ($CreerTachePlanifiee) {
    Write-Host "Création d'une tâche planifiée pour la surveillance des certificats..." -ForegroundColor Cyan
    New-CertificatsExpirationTask
    exit
}

# Exécution de la vérification des certificats
Write-Host "Vérification des certificats expirant dans les $JoursAvantExpiration prochains jours..." -ForegroundColor Cyan
$certificatsExpirants = Test-CertificatsExpiration -JoursAvantExpiration $JoursAvantExpiration

# Afficher les résultats dans la console
if ($certificatsExpirants.Count -eq 0) {
    Write-Host "`n✅ Aucun certificat n'expire dans les $JoursAvantExpiration prochains jours." -ForegroundColor Green
} else {
    Write-Host "`n⚠️ $($certificatsExpirants.Count) certificat(s) expirent dans les $JoursAvantExpiration prochains jours :" -ForegroundColor Yellow
    $certificatsExpirants | Sort-Object JoursRestants | Format-Table -AutoSize
}

# Générer le rapport HTML
$htmlReport = New-CertificatsExpirationReport -Certificats $certificatsExpirants

# Sauvegarder le rapport dans un fichier
$reportPath = Join-Path -Path $env:TEMP -ChildPath "CertificatsExpiration_$(Get-Date -Format 'yyyyMMdd').html"
$htmlReport | Out-File -FilePath $reportPath -Encoding utf8
Write-Host "Rapport sauvegardé: $reportPath" -ForegroundColor Cyan

# Ouvrir le rapport
Start-Process $reportPath

# Envoyer par email si demandé
if ($EnvoyerEmail) {
    Write-Host "Envoi du rapport par email..." -ForegroundColor Cyan
    Send-CertificatsExpirationEmail -HtmlContent $htmlReport -NombreCertificats $certificatsExpirants.Count
}
```

## Utilisation pratique des solutions

Voici comment vous pouvez utiliser les scripts fournis dans un contexte professionnel :

### 1. Script d'inventaire de certificats (Exercice 1)

Utilisez ce script pour :
- Faire un audit rapide des certificats installés sur votre machine
- Générer un rapport avant une intervention ou une migration
- Identifier les certificats périmés qui pourraient causer des problèmes

Exemple d'exécution :
```powershell
# Lancer le script et rediriger la sortie vers un fichier texte
.\Exercice1-ListeCertificatsPersonnels.ps1 > CertificatsInventaire.txt

# Ou l'utiliser en combinaison avec d'autres commandes
.\Exercice1-ListeCertificatsPersonnels.ps1 | Where-Object { $_.Statut -like "*Expire*" }
```

### 2. Script d'exportation de certificats (Exercice 2)

Ce script est particulièrement utile pour :
- Sauvegarder tous les certificats d'un serveur avant une migration
- Créer une archive de certificats pour une analyse externe
- Transférer des certificats entre environnements

Exemple d'utilisation :
```powershell
# Exporter tous les certificats personnels de la machine
.\Exercice2-ExportCertificatsStore.ps1 -StoreLocation LocalMachine -StoreName My -ExportPath C:\Backup\Certificats

# Exporter des certificats racines avec un nom explicite
.\Exercice2-ExportCertificatsStore.ps1 -StoreLocation CurrentUser -StoreName Root -ExportPath "C:\Backup\Certificats\Racines_$(Get-Date -Format 'yyyyMMdd')"
```

### 3. Script de surveillance des certificats (Exercice 3)

Idéal pour :
- Éviter les interruptions de service dues à des certificats expirés
- Configurer une surveillance proactive sur des serveurs critiques
- Documenter automatiquement l'état des certificats

Pour l'installer comme une tâche planifiée :
```powershell
# Configurer la surveillance avec des alertes par email
.\Exercice3-SurveillanceCertificatsExpiration.ps1 -CreerTachePlanifiee

# Exécuter manuellement pour vérifier immédiatement
.\Exercice3-SurveillanceCertificatsExpiration.ps1 -JoursAvantExpiration 60
```

    # Enregistrer la tâche
try {
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        # Mettre à jour la tâche existante
        Set-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description $taskDescription
        Write-Host "✅ Tâche planifiée '$taskName' mise à jour avec succès." -ForegroundColor Green
    } else {
        # Créer une nouvelle tâche
        Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description $taskDescription -User "SYSTEM"
        Write-Host "✅ Tâche planifiée '$taskName' créée avec succès." -ForegroundColor Green
    }
}
catch {
    Write-Host "❌ Erreur lors de la création de la tâche planifiée: $_" -ForegroundColor Red
}

# Exécuter le script immédiatement pour vérifier son bon fonctionnement
Write-Host "`nExécution immédiate du script de surveillance..." -ForegroundColor Cyan
try {
    & $targetScript -JoursAvantExpiration $configParams.JoursAvantExpiration
    Write-Host "✅ Test d'exécution réussi." -ForegroundColor Green
}
catch {
    Write-Host "❌ Erreur lors de l'exécution du script: $_" -ForegroundColor Red
}

Write-Host "`n=== Installation terminée ===" -ForegroundColor Cyan
Write-Host "La surveillance des certificats est maintenant configurée pour :" -ForegroundColor White
Write-Host "- Vérifier les certificats expirant dans les $($configParams.JoursAvantExpiration) prochains jours" -ForegroundColor White
Write-Host "- Exécution automatique tous les jours à 8h00" -ForegroundColor White

if ($configParams.EnvoyerEmail) {
    Write-Host "- Envoi d'alertes par email à $($configParams.EmailTo)" -ForegroundColor White
}

Write-Host "`nPour modifier la configuration, exécutez à nouveau ce script d'installation." -ForegroundColor White
Write-Host "Pour exécuter manuellement une vérification, lancez: $targetScript" -ForegroundColor White
