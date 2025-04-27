# Solution de l'exercice 1 : Liste des utilisateurs d'un département

<#
.SYNOPSIS
    Liste tous les utilisateurs d'un département spécifique.
.DESCRIPTION
    Ce script recherche dans Active Directory tous les utilisateurs appartenant
    à un département spécifié et affiche leurs noms et identifiants.
.PARAMETER Department
    Le nom du département à rechercher.
.EXAMPLE
    .\Get-DepartmentUsers.ps1 -Department "Marketing"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Department
)

# Vérifier que le module AD est chargé
if (-not (Get-Module -Name ActiveDirectory)) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "Module Active Directory chargé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de charger le module Active Directory. Vérifiez qu'il est installé."
        exit 1
    }
}

# Rechercher les utilisateurs du département spécifié
try {
    $users = Get-ADUser -Filter "Department -eq '$Department'" -Properties Department |
        Select-Object Name, SamAccountName, Department

    # Vérifier si des utilisateurs ont été trouvés
    if ($users.Count -eq 0) {
        Write-Host "Aucun utilisateur trouvé dans le département '$Department'." -ForegroundColor Yellow
    }
    else {
        Write-Host "Utilisateurs du département '$Department':" -ForegroundColor Cyan
        $users | Format-Table -AutoSize

        # Afficher le nombre total d'utilisateurs
        Write-Host "Nombre total d'utilisateurs : $($users.Count)" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "Une erreur s'est produite lors de la recherche des utilisateurs: $_"
    exit 1
}

# Solution de l'exercice 2 : Exporter les informations de contact des membres du groupe Direction

<#
.SYNOPSIS
    Exporte les informations de contact des membres du groupe Direction.
.DESCRIPTION
    Ce script identifie tous les utilisateurs membres du groupe "Direction",
    récupère leurs informations de contact et les exporte dans un fichier CSV.
.PARAMETER GroupName
    Le nom du groupe à analyser (par défaut : "Direction").
.PARAMETER OutputPath
    Le chemin du fichier CSV de sortie.
.EXAMPLE
    .\Export-DirectionContacts.ps1 -OutputPath "C:\Exports\direction_contacts.csv"
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$GroupName = "Direction",

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\Exports\direction_contacts.csv"
)

# Vérifier que le module AD est chargé
if (-not (Get-Module -Name ActiveDirectory)) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "Module Active Directory chargé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de charger le module Active Directory. Vérifiez qu'il est installé."
        exit 1
    }
}

# Créer le dossier de destination si nécessaire
$outputFolder = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputFolder)) {
    try {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé : $outputFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de créer le dossier $outputFolder : $_"
        exit 1
    }
}

try {
    # Vérifier si le groupe existe
    if (-not (Get-ADGroup -Filter "Name -eq '$GroupName'")) {
        Write-Error "Le groupe '$GroupName' n'existe pas dans Active Directory."
        exit 1
    }

    # Obtenir les membres du groupe qui sont des utilisateurs
    Write-Host "Récupération des membres du groupe '$GroupName'..." -ForegroundColor Cyan
    $userMembers = Get-ADGroupMember -Identity $GroupName |
        Where-Object {$_.objectClass -eq "user"}

    # Vérifier si des utilisateurs ont été trouvés
    if ($userMembers.Count -eq 0) {
        Write-Host "Aucun utilisateur trouvé dans le groupe '$GroupName'." -ForegroundColor Yellow
        exit 0
    }

    # Récupérer les informations détaillées pour chaque utilisateur
    Write-Host "Récupération des informations de contact..." -ForegroundColor Cyan
    $contactInfo = $userMembers | ForEach-Object {
        Get-ADUser -Identity $_.SamAccountName -Properties EmailAddress, OfficePhone, Mobile, Title, Department
    } | Select-Object Name, EmailAddress, OfficePhone, Mobile, Title, Department

    # Exporter vers CSV
    $contactInfo | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Host "Informations exportées avec succès vers : $OutputPath" -ForegroundColor Green
    Write-Host "Nombre d'utilisateurs exportés : $($contactInfo.Count)" -ForegroundColor Cyan

    # Ouvrir le fichier automatiquement
    if (Test-Path -Path $OutputPath) {
        Write-Host "Ouverture du fichier CSV..." -ForegroundColor Cyan
        Start-Process $OutputPath
    }
}
catch {
    Write-Error "Une erreur s'est produite : $_"
    exit 1
}

# Solution de l'exercice 3 : Rapport des ordinateurs Windows 10 inactifs avec propriétaires

<#
.SYNOPSIS
    Génère un rapport des ordinateurs Windows 10 inactifs.
.DESCRIPTION
    Ce script identifie tous les ordinateurs sous Windows 10 qui n'ont pas été connectés
    depuis un nombre spécifié de jours, puis recherche leurs propriétaires dans Active Directory.
    Les résultats sont exportés dans un fichier CSV et peuvent être envoyés par email.
.PARAMETER InactiveDays
    Le nombre de jours d'inactivité (par défaut : 30).
.PARAMETER OutputPath
    Le chemin du fichier CSV de sortie.
.PARAMETER SendEmail
    Indique si un email doit être envoyé avec le rapport.
.PARAMETER EmailTo
    L'adresse email du destinataire du rapport.
.EXAMPLE
    .\Get-InactiveWin10Computers.ps1 -InactiveDays 30 -OutputPath "C:\Rapports\Ordinateurs_Inactifs.csv"
.EXAMPLE
    .\Get-InactiveWin10Computers.ps1 -InactiveDays 60 -SendEmail -EmailTo "admin@entreprise.com"
#>

param(
    [Parameter(Mandatory=$false)]
    [int]$InactiveDays = 30,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "C:\Rapports\Ordinateurs_Win10_Inactifs.csv",

    [Parameter(Mandatory=$false)]
    [switch]$SendEmail,

    [Parameter(Mandatory=$false)]
    [string]$EmailTo = ""
)

# Vérifier que le module AD est chargé
if (-not (Get-Module -Name ActiveDirectory)) {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Host "Module Active Directory chargé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de charger le module Active Directory. Vérifiez qu'il est installé."
        exit 1
    }
}

# Créer le dossier de destination si nécessaire
$outputFolder = Split-Path -Path $OutputPath -Parent
if (-not (Test-Path -Path $outputFolder)) {
    try {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
        Write-Host "Dossier créé : $outputFolder" -ForegroundColor Green
    }
    catch {
        Write-Error "Impossible de créer le dossier $outputFolder : $_"
        exit 1
    }
}

try {
    # Calculer la date limite pour l'inactivité
    $cutoffDate = (Get-Date).AddDays(-$InactiveDays)
    Write-Host "Recherche des ordinateurs Windows 10 inactifs depuis le $($cutoffDate.ToString('dd/MM/yyyy'))..." -ForegroundColor Cyan

    # Rechercher les ordinateurs Windows 10 inactifs
    $inactiveComputers = Get-ADComputer -Filter {
        OperatingSystem -like "*Windows 10*" -and LastLogonDate -lt $cutoffDate
    } -Properties OperatingSystem, LastLogonDate, Description, ManagedBy |
    Select-Object Name, OperatingSystem, LastLogonDate, Description, @{
        Name = "DaysSinceLastLogon";
        Expression = { [math]::Round((New-TimeSpan -Start $_.LastLogonDate -End (Get-Date)).TotalDays) }
    }, @{
        Name = "ManagedBy";
        Expression = { $_.ManagedBy }
    }

    # Vérifier si des ordinateurs ont été trouvés
    if ($inactiveComputers.Count -eq 0) {
        Write-Host "Aucun ordinateur Windows 10 inactif depuis $InactiveDays jours." -ForegroundColor Yellow
        exit 0
    }

    # Ajouter les informations sur les propriétaires
    Write-Host "Récupération des informations sur les propriétaires..." -ForegroundColor Cyan
    $computersWithOwners = $inactiveComputers | ForEach-Object {
        $computer = $_

        # Tentative de récupération du propriétaire depuis l'attribut ManagedBy
        $ownerName = "Non spécifié"
        $ownerEmail = "Non spécifié"
        $ownerDepartment = "Non spécifié"

        if ($computer.ManagedBy) {
            try {
                $owner = Get-ADUser -Identity $computer.ManagedBy.Replace('CN=', '').Split(',')[0] -Properties DisplayName, EmailAddress, Department
                $ownerName = $owner.DisplayName
                $ownerEmail = $owner.EmailAddress
                $ownerDepartment = $owner.Department
            }
            catch {
                # Propriétaire introuvable, on garde les valeurs par défaut
            }
        }

        # Créer un nouvel objet avec toutes les propriétés
        [PSCustomObject]@{
            ComputerName = $computer.Name
            OperatingSystem = $computer.OperatingSystem
            LastLogonDate = $computer.LastLogonDate
            DaysSinceLastLogon = $computer.DaysSinceLastLogon
            Description = $computer.Description
            Owner = $ownerName
            OwnerEmail = $ownerEmail
            OwnerDepartment = $ownerDepartment
        }
    }

    # Exporter vers CSV
    $computersWithOwners | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

    Write-Host "Rapport généré avec succès : $OutputPath" -ForegroundColor Green
    Write-Host "Nombre d'ordinateurs inactifs trouvés : $($computersWithOwners.Count)" -ForegroundColor Cyan

    # Résumé par département
    $departmentSummary = $computersWithOwners | Group-Object -Property OwnerDepartment |
        Select-Object Name, Count | Sort-Object -Property Count -Descending

    Write-Host "`nRésumé par département :" -ForegroundColor Cyan
    $departmentSummary | Format-Table -AutoSize

    # Envoyer un email si demandé
    if ($SendEmail -and $EmailTo) {
        try {
            $emailSubject = "Rapport d'ordinateurs Windows 10 inactifs - $((Get-Date).ToString('dd/MM/yyyy'))"
            $emailBody = "Bonjour,`n`nVeuillez trouver ci-joint le rapport des ordinateurs Windows 10 inactifs depuis plus de $InactiveDays jours.`n`n"
            $emailBody += "Nombre total d'ordinateurs inactifs : $($computersWithOwners.Count)`n`n"
            $emailBody += "Ce rapport a été généré automatiquement le $((Get-Date).ToString('dd/MM/yyyy à HH:mm')).`n`n"
            $emailBody += "Cordialement,`nService informatique"

            Send-MailMessage -From "rapports@entreprise.com" -To $EmailTo -Subject $emailSubject -Body $emailBody -Attachments $OutputPath -SmtpServer "smtp.entreprise.com"
            Write-Host "Email envoyé avec succès à : $EmailTo" -ForegroundColor Green
        }
        catch {
            Write-Warning "Impossible d'envoyer l'email : $_"
        }
    }

    # Ouvrir le fichier automatiquement
    if (Test-Path -Path $OutputPath) {
        Write-Host "Ouverture du fichier CSV..." -ForegroundColor Cyan
        Start-Process $OutputPath
    }
}
catch {
    Write-Error "Une erreur s'est produite : $_"
    exit 1
}
