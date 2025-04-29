# Solutions des exercices pratiques d'audit Active Directory

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Exercice 1 : Rapport des 10 comptes les plus anciennement connectés

```powershell
<#
.SYNOPSIS
    Génère un rapport des 10 comptes utilisateurs les plus anciennement connectés dans Active Directory.
.DESCRIPTION
    Ce script identifie et liste les 10 comptes utilisateurs actifs dont la dernière connexion est la plus ancienne.
    Le rapport est enregistré au format CSV dans le dossier spécifié.
.NOTES
    Nom du fichier : Get-OldestLogonAccounts.ps1
    Auteur : [Votre Nom]
    Date de création : [Date]
    Requis : Module ActiveDirectory, droits d'administrateur pour interroger AD
#>

# Vérifier que le module ActiveDirectory est disponible
if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Write-Error "Le module ActiveDirectory n'est pas installé. Veuillez installer les outils RSAT."
    exit 1
}

# Importer le module si nécessaire
Import-Module ActiveDirectory

# Définir le chemin pour le rapport
$ReportFolder = "C:\Reports"
$ReportName = "OldestLogonAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
$ReportPath = Join-Path -Path $ReportFolder -ChildPath $ReportName

# Créer le dossier de rapport s'il n'existe pas
if (-not (Test-Path -Path $ReportFolder)) {
    try {
        New-Item -Path $ReportFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de rapport créé : $ReportFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de créer le dossier de rapport : $_"
        exit 1
    }
}

try {
    # Obtenir tous les utilisateurs actifs avec leur date de dernière connexion
    Write-Host "Récupération des données utilisateurs depuis Active Directory..." -ForegroundColor Cyan

    $OldestLogons = Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate, Department, Title, Manager, EmailAddress, Created |
        Where-Object { $_.LastLogonDate -ne $null } |
        Select-Object Name, SamAccountName,
                      @{Name="LastLogonDate"; Expression={$_.LastLogonDate}},
                      @{Name="DaysSinceLastLogon"; Expression={(New-TimeSpan -Start $_.LastLogonDate -End (Get-Date)).Days}},
                      Department, Title,
                      @{Name="Manager"; Expression={
                          if ($_.Manager) {
                              (Get-ADUser -Identity $_.Manager -Properties DisplayName).DisplayName
                          } else {
                              "Non défini"
                          }
                      }},
                      EmailAddress,
                      @{Name="AccountCreated"; Expression={$_.Created}},
                      @{Name="AccountAge"; Expression={(New-TimeSpan -Start $_.Created -End (Get-Date)).Days}} |
        Sort-Object LastLogonDate |
        Select-Object -First 10

    # Exporter vers CSV
    $OldestLogons | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

    # Afficher un résumé
    Write-Host "`nRapport des 10 comptes les plus anciennement connectés :" -ForegroundColor Green
    $OldestLogons | Format-Table -Property Name, SamAccountName, LastLogonDate, DaysSinceLastLogon -AutoSize

    Write-Host "`nRapport complet généré : $ReportPath" -ForegroundColor Green
    Write-Host "Nombre total de comptes analysés : $($OldestLogons.Count)" -ForegroundColor Green
}
catch {
    Write-Error "Une erreur s'est produite lors de la génération du rapport : $_"
    exit 1
}
```

## Exercice 2 : Rapport envoyé automatiquement par email

```powershell
<#
.SYNOPSIS
    Génère un rapport des 10 comptes les plus anciennement connectés et l'envoie par email.
.DESCRIPTION
    Ce script identifie les 10 comptes utilisateurs actifs dont la dernière connexion est la plus ancienne,
    crée un rapport CSV et l'envoie automatiquement par email à l'administrateur spécifié.
.NOTES
    Nom du fichier : Send-OldestLogonReport.ps1
    Auteur : [Votre Nom]
    Date de création : [Date]
    Requis : Module ActiveDirectory, accès à un serveur SMTP
#>

# Configuration des paramètres email
$EmailParams = @{
    SmtpServer = "smtp.entreprise.com"
    Port = 25
    From = "rapports-ad@entreprise.com"
    To = "admin@entreprise.com"
    Subject = "Rapport AD - 10 comptes les plus anciennement connectés $(Get-Date -Format 'yyyy-MM-dd')"
    Priority = "Normal"
    BodyAsHtml = $true
}

# Vérifier que le module ActiveDirectory est disponible
if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Write-Error "Le module ActiveDirectory n'est pas installé. Veuillez installer les outils RSAT."
    exit 1
}

# Importer le module si nécessaire
Import-Module ActiveDirectory

# Définir le chemin pour le rapport
$ReportFolder = "C:\Reports"
$ReportName = "OldestLogonAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
$ReportPath = Join-Path -Path $ReportFolder -ChildPath $ReportName

# Créer le dossier de rapport s'il n'existe pas
if (-not (Test-Path -Path $ReportFolder)) {
    try {
        New-Item -Path $ReportFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de rapport créé : $ReportFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de créer le dossier de rapport : $_"
        exit 1
    }
}

try {
    # Obtenir tous les utilisateurs actifs avec leur date de dernière connexion
    Write-Host "Récupération des données utilisateurs depuis Active Directory..." -ForegroundColor Cyan

    $OldestLogons = Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate, Department, Title, Manager, EmailAddress, Created |
        Where-Object { $_.LastLogonDate -ne $null } |
        Select-Object Name, SamAccountName,
                      @{Name="LastLogonDate"; Expression={$_.LastLogonDate}},
                      @{Name="DaysSinceLastLogon"; Expression={(New-TimeSpan -Start $_.LastLogonDate -End (Get-Date)).Days}},
                      Department, Title,
                      @{Name="Manager"; Expression={
                          if ($_.Manager) {
                              (Get-ADUser -Identity $_.Manager -Properties DisplayName).DisplayName
                          } else {
                              "Non défini"
                          }
                      }},
                      EmailAddress,
                      @{Name="AccountCreated"; Expression={$_.Created}},
                      @{Name="AccountAge"; Expression={(New-TimeSpan -Start $_.Created -End (Get-Date)).Days}} |
        Sort-Object LastLogonDate |
        Select-Object -First 10

    # Exporter vers CSV
    $OldestLogons | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

    # Créer un tableau HTML pour le corps de l'email
    $HtmlHeader = @"
<style>
    table {
        border-collapse: collapse;
        width: 100%;
        font-family: Arial, sans-serif;
    }
    th, td {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
    }
    th {
        background-color: #f2f2f2;
    }
    tr:nth-child(even) {
        background-color: #f9f9f9;
    }
    .warning {
        background-color: #ffcc00;
    }
    .critical {
        background-color: #ff6666;
    }
</style>
"@

    $HtmlData = $OldestLogons | ConvertTo-Html -Property Name, SamAccountName, LastLogonDate, DaysSinceLastLogon, Department -Head $HtmlHeader -PreContent "<h2>Rapport des 10 comptes les plus anciennement connectés</h2><p>Date du rapport: $(Get-Date -Format 'dd/MM/yyyy HH:mm')</p>"

    # Ajouter une analyse des résultats
    $OldAccounts90Days = $OldestLogons | Where-Object { $_.DaysSinceLastLogon -gt 90 }
    $Summary = @"
<h3>Résumé du rapport</h3>
<ul>
    <li>Nombre total de comptes analysés : $($OldestLogons.Count)</li>
    <li>Comptes non connectés depuis plus de 90 jours : $($OldAccounts90Days.Count)</li>
    <li>Connexion la plus ancienne : $($OldestLogons[0].LastLogonDate) (il y a $($OldestLogons[0].DaysSinceLastLogon) jours)</li>
</ul>
<p>Le rapport complet est disponible en pièce jointe.</p>
"@

    $HtmlBody = $HtmlData + $Summary

    # Envoyer l'email avec le rapport en pièce jointe
    Send-MailMessage @EmailParams -Body $HtmlBody -Attachments $ReportPath

    Write-Host "`nRapport envoyé par email à $($EmailParams.To)" -ForegroundColor Green
    Write-Host "Rapport complet enregistré : $ReportPath" -ForegroundColor Green
}
catch {
    $ErrorMsg = "Une erreur s'est produite lors de la génération ou de l'envoi du rapport : $_"
    Write-Error $ErrorMsg

    # Envoyer un email de notification d'erreur
    $EmailParams.Subject = "ERREUR - Rapport AD des comptes inactifs"
    $EmailParams.Body = "<h3>Une erreur s'est produite</h3><p>$ErrorMsg</p>"

    try {
        Send-MailMessage @EmailParams
    }
    catch {
        Write-Error "Impossible d'envoyer l'email de notification d'erreur : $_"
    }

    exit 1
}
```

## Exercice 3 : Vérification des comptes créés il y a plus de 30 jours et jamais utilisés

```powershell
<#
.SYNOPSIS
    Identifie les comptes créés il y a plus de 30 jours et jamais utilisés dans Active Directory.
.DESCRIPTION
    Ce script recherche tous les comptes utilisateurs actifs qui ont été créés il y a plus de 30 jours
    et qui n'ont jamais été utilisés (sans date de dernière connexion). Le rapport est exporté au format CSV
    et envoyé par email à l'administrateur.
.NOTES
    Nom du fichier : Get-UnusedAccounts.ps1
    Auteur : [Votre Nom]
    Date de création : [Date]
    Requis : Module ActiveDirectory, accès à un serveur SMTP
#>

# Configuration des paramètres email
$EmailParams = @{
    SmtpServer = "smtp.entreprise.com"
    Port = 25
    From = "rapports-ad@entreprise.com"
    To = "admin@entreprise.com"
    Subject = "ALERTE - Comptes AD jamais utilisés $(Get-Date -Format 'yyyy-MM-dd')"
    Priority = "High"
    BodyAsHtml = $true
}

# Vérifier que le module ActiveDirectory est disponible
if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
    Write-Error "Le module ActiveDirectory n'est pas installé. Veuillez installer les outils RSAT."
    exit 1
}

# Importer le module si nécessaire
Import-Module ActiveDirectory

# Définir le chemin pour le rapport
$ReportFolder = "C:\Reports"
$ReportName = "NeverUsedAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
$ReportPath = Join-Path -Path $ReportFolder -ChildPath $ReportName

# Définir la date limite (créés il y a plus de 30 jours)
$DateLimit = (Get-Date).AddDays(-30)

# Créer le dossier de rapport s'il n'existe pas
if (-not (Test-Path -Path $ReportFolder)) {
    try {
        New-Item -Path $ReportFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de rapport créé : $ReportFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de créer le dossier de rapport : $_"
        exit 1
    }
}

try {
    # Récupérer les comptes qui n'ont jamais été utilisés et qui ont été créés il y a plus de 30 jours
    Write-Host "Recherche des comptes jamais utilisés..." -ForegroundColor Cyan

    # Récupérer les comptes qui n'ont jamais eu de connexion
    $NeverUsedAccounts = Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate, whenCreated, Department, Title, Manager, Description |
        Where-Object {
            ($null -eq $_.LastLogonDate) -and
            ($_.whenCreated -lt $DateLimit)
        } |
        Select-Object Name, SamAccountName,
                      @{Name="Created"; Expression={$_.whenCreated}},
                      @{Name="AccountAge"; Expression={(New-TimeSpan -Start $_.whenCreated -End (Get-Date)).Days}},
                      Department, Title, Description,
                      @{Name="Manager"; Expression={
                          if ($_.Manager) {
                              (Get-ADUser -Identity $_.Manager -Properties DisplayName).DisplayName
                          } else {
                              "Non défini"
                          }
                      }},
                      DistinguishedName |
        Sort-Object AccountAge -Descending

    # Exporter vers CSV
    $NeverUsedAccounts | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

    # Créer un tableau HTML pour le corps de l'email
    $HtmlHeader = @"
<style>
    table {
        border-collapse: collapse;
        width: 100%;
        font-family: Arial, sans-serif;
    }
    th, td {
        border: 1px solid #dddddd;
        text-align: left;
        padding: 8px;
    }
    th {
        background-color: #f2f2f2;
    }
    tr:nth-child(even) {
        background-color: #f9f9f9;
    }
    .critical {
        background-color: #ff6666;
    }
    .warning {
        background-color: #ffcc00;
    }
</style>
"@

    $HtmlData = $NeverUsedAccounts | ConvertTo-Html -Property Name, SamAccountName, Created, AccountAge, Department, Title -Head $HtmlHeader -PreContent "<h2>Rapport des comptes jamais utilisés</h2><p>Date du rapport: $(Get-Date -Format 'dd/MM/yyyy HH:mm')</p>"

    # Analyser les comptes par ancienneté
    $VeryOldAccounts = $NeverUsedAccounts | Where-Object { $_.AccountAge -gt 90 }
    $ByDepartment = $NeverUsedAccounts | Group-Object -Property Department | Select-Object Name, Count

    $Summary = @"
<h3>Résumé du rapport</h3>
<ul>
    <li>Nombre total de comptes jamais utilisés : $($NeverUsedAccounts.Count)</li>
    <li>Comptes créés il y a plus de 90 jours et jamais utilisés : $($VeryOldAccounts.Count)</li>
    <li>Compte le plus ancien jamais utilisé : $($NeverUsedAccounts[0].Created) (il y a $($NeverUsedAccounts[0].AccountAge) jours)</li>
</ul>

<h3>Répartition par département</h3>
<table>
    <tr>
        <th>Département</th>
        <th>Nombre de comptes</th>
    </tr>
"@

    foreach ($Dept in $ByDepartment) {
        $DeptName = if ([string]::IsNullOrEmpty($Dept.Name)) { "Non spécifié" } else { $Dept.Name }
        $Summary += "<tr><td>$DeptName</td><td>$($Dept.Count)</td></tr>"
    }

    $Summary += @"
</table>

<h3>Actions recommandées</h3>
<ol>
    <li>Vérifier si ces comptes sont encore nécessaires</li>
    <li>Désactiver les comptes inutiles</li>
    <li>Documenter la raison de la conservation des comptes qui doivent rester actifs</li>
</ol>

<p>Le rapport complet est disponible en pièce jointe.</p>
"@

    $HtmlBody = $HtmlData + $Summary

    # Envoyer l'email uniquement s'il y a des comptes trouvés
    if ($NeverUsedAccounts.Count -gt 0) {
        Send-MailMessage @EmailParams -Body $HtmlBody -Attachments $ReportPath
        Write-Host "`nRapport envoyé par email à $($EmailParams.To)" -ForegroundColor Green
    } else {
        Write-Host "`nAucun compte inactif trouvé - pas d'email envoyé" -ForegroundColor Green
    }

    # Afficher un résumé à l'écran
    Write-Host "`nComptes jamais utilisés (créés il y a plus de 30 jours) :" -ForegroundColor Cyan
    Write-Host "Nombre total : $($NeverUsedAccounts.Count)" -ForegroundColor Yellow

    if ($NeverUsedAccounts.Count -gt 0) {
        $NeverUsedAccounts | Format-Table -Property Name, SamAccountName, Created, AccountAge -AutoSize
    }

    Write-Host "Rapport complet enregistré : $ReportPath" -ForegroundColor Green

    # Optionnel : Proposer de désactiver les comptes très anciens
    if ($VeryOldAccounts.Count -gt 0) {
        Write-Host "`nATTENTION : $($VeryOldAccounts.Count) comptes ont été créés il y a plus de 90 jours et n'ont jamais été utilisés." -ForegroundColor Red
        Write-Host "Considérez leur désactivation avec la commande suivante :" -ForegroundColor Yellow
        Write-Host "Get-Content -Path '$ReportPath' | ConvertFrom-Csv | Where-Object { [int]`$_.AccountAge -gt 90 } | ForEach-Object { Disable-ADAccount -Identity `$_.SamAccountName }" -ForegroundColor DarkYellow
    }
}
catch {
    $ErrorMsg = "Une erreur s'est produite lors de la génération du rapport : $_"
    Write-Error $ErrorMsg

    # Envoyer un email de notification d'erreur
    $EmailParams.Subject = "ERREUR - Rapport AD des comptes jamais utilisés"
    $EmailParams.Body = "<h3>Une erreur s'est produite</h3><p>$ErrorMsg</p>"

    try {
        Send-MailMessage @EmailParams
    }
    catch {
        Write-Error "Impossible d'envoyer l'email de notification d'erreur : $_"
    }

    exit 1
}

# Fonction optionnelle pour désactiver les comptes très anciens
function Disable-OldUnusedAccounts {
    param (
        [Parameter(Mandatory=$true)]
        [string]$CsvPath,

        [Parameter(Mandatory=$false)]
        [int]$AgeThreshold = 90,

        [Parameter(Mandatory=$false)]
        [switch]$WhatIf
    )

    if (-not (Test-Path -Path $CsvPath)) {
        Write-Error "Le fichier CSV spécifié n'existe pas : $CsvPath"
        return
    }

    try {
        $Accounts = Import-Csv -Path $CsvPath | Where-Object { [int]$_.AccountAge -gt $AgeThreshold }

        foreach ($Account in $Accounts) {
            Write-Host "Traitement du compte : $($Account.SamAccountName) (créé il y a $($Account.AccountAge) jours)" -ForegroundColor Cyan

            if ($WhatIf) {
                Write-Host "WhatIf : Le compte $($Account.SamAccountName) serait désactivé" -ForegroundColor Yellow
            } else {
                # Ajouter une description pour garder trace de l'action
                Set-ADUser -Identity $Account.SamAccountName -Description "Compte désactivé automatiquement le $(Get-Date -Format 'yyyy-MM-dd') car jamais utilisé depuis sa création"

                # Désactiver le compte
                Disable-ADAccount -Identity $Account.SamAccountName
                Write-Host "Compte désactivé : $($Account.SamAccountName)" -ForegroundColor Green
            }
        }

        Write-Host "`nTraitement terminé. $($Accounts.Count) comptes traités." -ForegroundColor Green
    }
    catch {
        Write-Error "Une erreur s'est produite lors de la désactivation des comptes : $_"
    }
}

# Exemple d'utilisation de la fonction (en commentaire)
# Disable-OldUnusedAccounts -CsvPath $ReportPath -AgeThreshold 90 -WhatIf
```

## Script bonus : Module complet d'audit Active Directory

```powershell
<#
.SYNOPSIS
    Module d'audit complet pour Active Directory.
.DESCRIPTION
    Ce module fournit des fonctions pour réaliser différents types d'audits sur Active Directory.
    Il permet de générer des rapports sur les comptes inactifs, jamais utilisés, expirés, etc.
.NOTES
    Nom du fichier : ADAuditModule.psm1
    Auteur : [Votre Nom]
    Date de création : [Date]
    Version : 1.0
#>

# Configuration globale
$Global:ADAuditConfig = @{
    ReportFolder = "C:\Reports\AD-Audit"
    EmailSettings = @{
        SmtpServer = "smtp.entreprise.com"
        Port = 25
        From = "rapports-ad@entreprise.com"
        To = "admin@entreprise.com"
    }
}

# Fonction pour initialiser l'environnement
function Initialize-ADAudit {
    [CmdletBinding()]
    param()

    # Vérifier que le module ActiveDirectory est disponible
    if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
        Write-Error "Le module ActiveDirectory n'est pas installé. Veuillez installer les outils RSAT."
        return $false
    }

    # Importer le module si nécessaire
    Import-Module ActiveDirectory

    # Créer le dossier de rapport s'il n'existe pas
    if (-not (Test-Path -Path $Global:ADAuditConfig.ReportFolder)) {
        try {
            New-Item -Path $Global:ADAuditConfig.ReportFolder -ItemType Directory -Force | Out-Null
            Write-Host "Dossier de rapport créé : $($Global:ADAuditConfig.ReportFolder)" -ForegroundColor Green
        }
        catch {
            Write-Error "Impossible de créer le dossier de rapport : $_"
            return $false
        }
    }

    return $true
}

# Fonction pour obtenir les comptes inactifs
function Get-ADInactiveAccounts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$InactiveDays = 90,

        [Parameter(Mandatory=$false)]
        [switch]$ExportCsv,

        [Parameter(Mandatory=$false)]
        [switch]$SendEmail
    )

    if (-not (Initialize-ADAudit)) {
        return
    }

    $DateLimit = (Get-Date).AddDays(-$InactiveDays)
    $ReportPath = Join-Path -Path $Global:ADAuditConfig.ReportFolder -ChildPath "InactiveAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"

    try {
        Write-Host "Recherche des comptes inactifs depuis plus de $InactiveDays jours..." -ForegroundColor Cyan

        $InactiveUsers = Get-ADUser -Filter {Enabled -eq $true -and LastLogonDate -lt $DateLimit} -Properties LastLogonDate, Description, Department, Manager, PasswordLastSet |
            Select-Object Name, SamAccountName, LastLogonDate,
                          @{Name="DaysSinceLastLogon"; Expression={(New-TimeSpan -Start $_.LastLogonDate -End (Get-Date)).Days}},
                          Description, Department,
                          @{Name="Manager"; Expression={
                              if ($_.Manager) {
                                  (Get-ADUser -Identity $_.Manager -Properties DisplayName).DisplayName
                              } else {
                                  "Non défini"
                              }
                          }},
                          PasswordLastSet, DistinguishedName |
            Sort-Object LastLogonDate

        if ($ExportCsv) {
            $InactiveUsers | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
            Write-Host "Rapport enregistré : $ReportPath" -ForegroundColor Green
        }

        if ($SendEmail -and $InactiveUsers.Count -gt 0) {
            $EmailParams = $Global:ADAuditConfig.EmailSettings.Clone()
            $EmailParams.Subject = "Rapport AD - Comptes inactifs depuis $InactiveDays jours ($(Get-Date -Format 'yyyy-MM-dd'))"
            $EmailParams.Priority = "Normal"
            $EmailParams.BodyAsHtml = $true

            $HtmlHeader = @"
<style>
    table { border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; }
    th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .warning { background-color: #ffcc00; }
    .critical { background-color: #ff6666; }
</style>
"@

            $HtmlData = $InactiveUsers | ConvertTo-Html -Property Name, SamAccountName, LastLogonDate, DaysSinceLastLogon, Department -Head $HtmlHeader -PreContent "<h2>Rapport des comptes inactifs</h2><p>Date du rapport: $(Get-Date -Format 'dd/MM/yyyy HH:mm')</p>"

            $Summary = @"
<h3>Résumé du rapport</h3>
<ul>
    <li>Nombre total de comptes inactifs : $($InactiveUsers.Count)</li>
    <li>Période d'inactivité : Plus de $InactiveDays jours</li>
</ul>
<p>Le rapport complet est disponible en pièce jointe.</p>
"@

            $HtmlBody = $HtmlData + $Summary

            Send-MailMessage @EmailParams -Body $HtmlBody -Attachments $ReportPath
            Write-Host "Rapport envoyé par email à $($EmailParams.To)" -ForegroundColor Green
        }

        return $InactiveUsers
    }
    catch {
        Write-Error "Une erreur s'est produite : $_"
    }
}

# Fonction pour obtenir les comptes jamais utilisés
function Get-ADNeverUsedAccounts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$CreatedDaysAgo = 30,

        [Parameter(Mandatory=$false)]
        [switch]$ExportCsv,

        [Parameter(Mandatory=$false)]
        [switch]$SendEmail
    )

    if (-not (Initialize-ADAudit)) {
        return
    }

    $DateLimit = (Get-Date).AddDays(-$CreatedDaysAgo)
    $ReportPath = Join-Path -Path $Global:ADAuditConfig.ReportFolder -ChildPath "NeverUsedAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"

    try {
        Write-Host "Recherche des comptes créés il y a plus de $CreatedDaysAgo jours et jamais utilisés..." -ForegroundColor Cyan

        $NeverUsedAccounts = Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate, whenCreated, Department, Title, Manager, Description |
            Where-Object {
                ($null -eq $_.LastLogonDate) -and
                ($_.whenCreated -lt $DateLimit)
            } |
            Select-Object Name, SamAccountName,
                          @{Name="Created"; Expression={$_.whenCreated}},
                          @{Name="AccountAge"; Expression={(New-TimeSpan -Start $_.whenCreated -End (Get-Date)).Days}},
                          Department, Title, Description,
                          @{Name="Manager"; Expression={
                              if ($_.Manager) {
                                  (Get-ADUser -Identity $_.Manager -Properties DisplayName).DisplayName
                              } else {
                                  "Non défini"
                              }
                          }},
                          DistinguishedName |
            Sort-Object AccountAge -Descending

        if ($ExportCsv) {
            $NeverUsedAccounts | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
            Write-Host "Rapport enregistré : $ReportPath" -ForegroundColor Green
        }

        if ($SendEmail -and $NeverUsedAccounts.Count -gt 0) {
            $EmailParams = $Global:ADAuditConfig.EmailSettings.Clone()
            $EmailParams.Subject = "ALERTE - Comptes AD jamais utilisés $(Get-Date -Format 'yyyy-MM-dd')"
            $EmailParams.Priority = "High"
            $EmailParams.BodyAsHtml = $true

            $HtmlHeader = @"
<style>
    table { border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; }
    th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .critical { background-color: #ff6666; }
    .warning { background-color: #ffcc00; }
</style>
"@

            $HtmlData = $NeverUsedAccounts | ConvertTo-Html -Property Name, SamAccountName, Created, AccountAge, Department, Title -Head $HtmlHeader -PreContent "<h2>Rapport des comptes jamais utilisés</h2><p>Date du rapport: $(Get-Date -Format 'dd/MM/yyyy HH:mm')</p>"

            $VeryOldAccounts = $NeverUsedAccounts | Where-Object { $_.AccountAge -gt 90 }

            $Summary = @"
<h3>Résumé du rapport</h3>
<ul>
    <li>Nombre total de comptes jamais utilisés : $($NeverUsedAccounts.Count)</li>
    <li>Comptes créés il y a plus de 90 jours et jamais utilisés : $($VeryOldAccounts.Count)</li>
    <li>Ces comptes ont été créés il y a plus de $CreatedDaysAgo jours et n'ont jamais été utilisés</li>
</ul>
<p>Le rapport complet est disponible en pièce jointe.</p>
"@

            $HtmlBody = $HtmlData + $Summary

            Send-MailMessage @EmailParams -Body $HtmlBody -Attachments $ReportPath
            Write-Host "Rapport envoyé par email à $($EmailParams.To)" -ForegroundColor Green
        }

        return $NeverUsedAccounts
    }
    catch {
        Write-Error "Une erreur s'est produite : $_"
    }
}

# Fonction pour obtenir les comptes avec mot de passe qui n'expire jamais
function Get-ADNonExpiringPasswordAccounts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$AdminsOnly,

        [Parameter(Mandatory=$false)]
        [switch]$ExportCsv,

        [Parameter(Mandatory=$false)]
        [switch]$SendEmail
    )

    if (-not (Initialize-ADAudit)) {
        return
    }

    $ReportPath = Join-Path -Path $Global:ADAuditConfig.ReportFolder -ChildPath "NonExpiringPasswordAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"

    try {
        Write-Host "Recherche des comptes avec mot de passe qui n'expire jamais..." -ForegroundColor Cyan

        $Filter = {PasswordNeverExpires -eq $true -and Enabled -eq $true}

        $NonExpiringPasswordAccounts = Get-ADUser -Filter $Filter -Properties PasswordNeverExpires, whenCreated, Department, Title, Manager, Description, LastLogonDate |
            Select-Object Name, SamAccountName,
                          @{Name="Created"; Expression={$_.whenCreated}},
                          @{Name="LastLogon"; Expression={$_.LastLogonDate}},
                          Department, Title, Description,
                          @{Name="Manager"; Expression={
                              if ($_.Manager) {
                                  (Get-ADUser -Identity $_.Manager -Properties DisplayName).DisplayName
                              } else {
                                  "Non défini"
                              }
                          }},
                          @{Name="IsAdmin"; Expression={
                              $isAdmin = $false
                              foreach ($Group in @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators")) {
                                  if (Get-ADGroupMember -Identity $Group -Recursive | Where-Object {$_.SamAccountName -eq $_.SamAccountName}) {
                                      $isAdmin = $true
                                      break
                                  }
                              }
                              $isAdmin
                          }},
                          DistinguishedName

        # Filtrer uniquement les admins si demandé
        if ($AdminsOnly) {
            $NonExpiringPasswordAccounts = $NonExpiringPasswordAccounts | Where-Object { $_.IsAdmin -eq $true }
        }

        if ($ExportCsv) {
            $NonExpiringPasswordAccounts | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
            Write-Host "Rapport enregistré : $ReportPath" -ForegroundColor Green
        }

        if ($SendEmail -and $NonExpiringPasswordAccounts.Count -gt 0) {
            $EmailParams = $Global:ADAuditConfig.EmailSettings.Clone()
            $EmailParams.Subject = "Rapport AD - Comptes avec mot de passe qui n'expire jamais $(Get-Date -Format 'yyyy-MM-dd')"
            $EmailParams.Priority = "Normal"
            $EmailParams.BodyAsHtml = $true

            $HtmlHeader = @"
<style>
    table { border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; }
    th, td { border: 1px solid #dddddd; text-align: left; padding: 8px; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .admin { background-color: #ffcc00; }
</style>
"@

            $HtmlData = $NonExpiringPasswordAccounts | ConvertTo-Html -Property Name, SamAccountName, Department, Title, IsAdmin -Head $HtmlHeader -PreContent "<h2>Rapport des comptes avec mot de passe qui n'expire jamais</h2><p>Date du rapport: $(Get-Date -Format 'dd/MM/yyyy HH:mm')</p>"

            $AdminAccounts = $NonExpiringPasswordAccounts | Where-Object { $_.IsAdmin -eq $true }

            $Summary = @"
<h3>Résumé du rapport</h3>
<ul>
    <li>Nombre total de comptes avec mot de passe qui n'expire jamais : $($NonExpiringPasswordAccounts.Count)</li>
    <li>Dont comptes administrateurs : $($AdminAccounts.Count)</li>
</ul>
<p>Le rapport complet est disponible en pièce jointe.</p>
"@

            $HtmlBody = $HtmlData + $Summary

            Send-MailMessage @EmailParams -Body $HtmlBody -Attachments $ReportPath
            Write-Host "Rapport envoyé par email à $($EmailParams.To)" -ForegroundColor Green
        }

        return $NonExpiringPasswordAccounts
    }
    catch {
        Write-Error "Une erreur s'est produite : $_"
    }
}

# Fonction pour générer un rapport complet
function Invoke-ADFullAudit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$SendEmail,

        [Parameter(Mandatory=$false)]
        [int]$InactiveDays = 90,

        [Parameter(Mandatory=$false)]
        [int]$CreatedDaysAgo = 30
    )

    if (-not (Initialize-ADAudit)) {
        return
    }

    # Créer un dossier pour cette exécution
    $ExecutionFolder = Join-Path -Path $Global:ADAuditConfig.ReportFolder -ChildPath "FullAudit_$(Get-Date -Format 'yyyy-MM-dd_HHmmss')"
    New-Item -Path $ExecutionFolder -ItemType Directory -Force | Out-Null

    # Démarrer un transcript pour logger toutes les actions
    $TranscriptPath = Join-Path -Path $ExecutionFolder -ChildPath "Audit_Transcript.txt"
    Start-Transcript -Path $TranscriptPath

    try {
        Write-Host "Démarrage de l'audit complet Active Directory..." -ForegroundColor Cyan
        Write-Host "Date d'exécution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor Cyan
        Write-Host "Dossier des rapports : $ExecutionFolder" -ForegroundColor Cyan

        # 1. Rapports des comptes inactifs
        $InactiveUsers = Get-ADInactiveAccounts -InactiveDays $InactiveDays -ExportCsv
        $InactiveUsersPath = Join-Path -Path $Global:ADAuditConfig.ReportFolder -ChildPath "InactiveAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
        Copy-Item -Path $InactiveUsersPath -Destination $ExecutionFolder

        # 2. Rapports des comptes jamais utilisés
        $NeverUsedAccounts = Get-ADNeverUsedAccounts -CreatedDaysAgo $CreatedDaysAgo -ExportCsv
        $NeverUsedAccountsPath = Join-Path -Path $Global:ADAuditConfig.ReportFolder -ChildPath "NeverUsedAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
        Copy-Item -Path $NeverUsedAccountsPath -Destination $ExecutionFolder

        # 3. Rapports des comptes avec mot de passe qui n'expire jamais
        $NonExpiringPasswordAccounts = Get-ADNonExpiringPasswordAccounts -ExportCsv
        $NonExpiringPasswordAccountsPath = Join-Path -Path $Global:ADAuditConfig.ReportFolder -ChildPath "NonExpiringPasswordAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
        Copy-Item -Path $NonExpiringPasswordAccountsPath -Destination $ExecutionFolder

        # 4. Rapport sur les comptes administrateurs récemment modifiés
        $AdminModifiedReport = Join-Path -Path $ExecutionFolder -ChildPath "AdminAccountsModified_$(Get-Date -Format 'yyyy-MM-dd').csv"
        $DaysToCheck = 30
        $AdminGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins", "Administrators")

        $AdminAccounts = foreach ($Group in $AdminGroups) {
            Get-ADGroupMember -Identity $Group -Recursive | Where-Object { $_.objectClass -eq "user" } | Get-ADUser
        } | Select-Object -Unique

        $ModifiedAdminAccounts = foreach ($Admin in $AdminAccounts) {
            $UserInfo = Get-ADUser -Identity $Admin -Properties whenChanged, whenCreated, Modified, PasswordLastSet
            if ($UserInfo.whenChanged -gt (Get-Date).AddDays(-$DaysToCheck) -or
                $UserInfo.Modified -gt (Get-Date).AddDays(-$DaysToCheck) -or
                $UserInfo.PasswordLastSet -gt (Get-Date).AddDays(-$DaysToCheck)) {

                [PSCustomObject]@{
                    Name = $UserInfo.Name
                    SamAccountName = $UserInfo.SamAccountName
                    WhenCreated = $UserInfo.whenCreated
                    LastModified = if ($UserInfo.Modified) { $UserInfo.Modified } else { $UserInfo.whenChanged }
                    PasswordChanged = $UserInfo.PasswordLastSet
                    DaysSinceModified = if ($UserInfo.Modified) {
                        (New-TimeSpan -Start $UserInfo.Modified -End (Get-Date)).Days
                    } else {
                        (New-TimeSpan -Start $UserInfo.whenChanged -End (Get-Date)).Days
                    }
                }
            }
        }

        $ModifiedAdminAccounts | Export-Csv -Path $AdminModifiedReport -NoTypeInformation -Encoding UTF8

        # 5. Créer un rapport de synthèse
        $SummaryReport = Join-Path -Path $ExecutionFolder -ChildPath "AuditSummary.txt"

        $SummaryContent = @"
==============================================
   RAPPORT D'AUDIT ACTIVE DIRECTORY
==============================================
Date d'exécution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')

RÉSUMÉ DES RÉSULTATS :
---------------------
* Comptes inactifs (>$InactiveDays jours) : $($InactiveUsers.Count)
* Comptes jamais utilisés (créés il y a >$CreatedDaysAgo jours) : $($NeverUsedAccounts.Count)
* Comptes avec mot de passe qui n'expire jamais : $($NonExpiringPasswordAccounts.Count)
* Comptes administrateurs modifiés ces $DaysToCheck derniers jours : $($ModifiedAdminAccounts.Count)

RECOMMANDATIONS :
----------------
1. Examiner et désactiver les comptes inactifs
2. Vérifier les comptes jamais utilisés
3. Réviser la politique de mot de passe pour les comptes à mot de passe permanent
4. Vérifier les modifications récentes sur les comptes administrateurs

==============================================
"@

        $SummaryContent | Out-File -FilePath $SummaryReport -Encoding UTF8

        # 6. Envoyer un email avec tous les rapports si demandé
        if ($SendEmail) {
            $EmailParams = $Global:ADAuditConfig.EmailSettings.Clone()
            $EmailParams.Subject = "Rapport d'audit complet Active Directory $(Get-Date -Format 'yyyy-MM-dd')"
            $EmailParams.Priority = "Normal"
            $EmailParams.BodyAsHtml = $true

            $HtmlBody = @"
<h1>Rapport d'audit complet Active Directory</h1>
<p>Date d'exécution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</p>

<h2>Résumé des résultats</h2>
<ul>
    <li>Comptes inactifs (>$InactiveDays jours) : $($InactiveUsers.Count)</li>
    <li>Comptes jamais utilisés (créés il y a >$CreatedDaysAgo jours) : $($NeverUsedAccounts.Count)</li>
    <li>Comptes avec mot de passe qui n'expire jamais : $($NonExpiringPasswordAccounts.Count)</li>
    <li>Comptes administrateurs modifiés ces $DaysToCheck derniers jours : $($ModifiedAdminAccounts.Count)</li>
</ul>

<h2>Recommandations</h2>
<ol>
    <li>Examiner et désactiver les comptes inactifs</li>
    <li>Vérifier les comptes jamais utilisés</li>
    <li>Réviser la politique de mot de passe pour les comptes à mot de passe permanent</li>
    <li>Vérifier les modifications récentes sur les comptes administrateurs</li>
</ol>

<p>Les rapports détaillés sont disponibles en pièces jointes.</p>
"@

            # Préparer les pièces jointes
            $Attachments = @(
                Join-Path -Path $ExecutionFolder -ChildPath "InactiveAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
                Join-Path -Path $ExecutionFolder -ChildPath "NeverUsedAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
                Join-Path -Path $ExecutionFolder -ChildPath "NonExpiringPasswordAccounts_$(Get-Date -Format 'yyyy-MM-dd').csv"
                $AdminModifiedReport
                $SummaryReport
            )

            Send-MailMessage @EmailParams -Body $HtmlBody -Attachments $Attachments
            Write-Host "Rapport d'audit complet envoyé par email à $($EmailParams.To)" -ForegroundColor Green
        }

        Write-Host "`nAudit complet terminé. Les rapports sont disponibles dans : $ExecutionFolder" -ForegroundColor Green
        Write-Host "Consultez le fichier de synthèse : $SummaryReport" -ForegroundColor Green
    }
    catch {
        Write-Error "Une erreur s'est produite lors de l'audit complet : $_"
    }
    finally {
        Stop-Transcript
    }
}

# Exporter les fonctions du module
Export-ModuleMember -Function Get-ADInactiveAccounts, Get-ADNeverUsedAccounts, Get-ADNonExpiringPasswordAccounts, Invoke-ADFullAudit

# Exemple d'utilisation du module :
<#
# Importer le module
Import-Module .\ADAuditModule.psm1

# Configurer le dossier de rapport et les paramètres email si nécessaire
$Global:ADAuditConfig.ReportFolder = "D:\AD-Audit-Reports"
$Global:ADAuditConfig.EmailSettings.SmtpServer = "mail.entreprise.com"
$Global:ADAuditConfig.EmailSettings.To = "admin@entreprise.com"

# Exécuter un audit complet
Invoke-ADFullAudit -SendEmail

# Ou exécuter des audits spécifiques
Get-ADInactiveAccounts -InactiveDays 60 -ExportCsv -SendEmail
Get-ADNeverUsedAccounts -CreatedDaysAgo 45 -ExportCsv -SendEmail
Get-ADNonExpiringPasswordAccounts -AdminsOnly -ExportCsv -SendEmail
#>
