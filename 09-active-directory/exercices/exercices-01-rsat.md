# Solutions des exercices pratiques - Module 10-1

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Active Directory & LDAP - Module RSAT et importation

### Exercice 1 : Installation des outils RSAT

**Solution :**

Pour Windows 10/11 (via PowerShell en tant qu'administrateur) :
```powershell
# Solution recommandée - Installation du module AD via Windows Capability
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0

# Alternative - Installation de tous les outils RSAT
Get-WindowsCapability -Online | Where-Object Name -like 'Rsat*' | Add-WindowsCapability -Online
```

Pour Windows Server (via PowerShell en tant qu'administrateur) :
```powershell
# Installation du module Active Directory PowerShell
Install-WindowsFeature RSAT-AD-PowerShell

# Vérification de l'installation
Get-WindowsFeature RSAT-AD-PowerShell
```

### Exercice 2 : Importation du module Active Directory

**Solution :**
```powershell
# Importation du module Active Directory
Import-Module ActiveDirectory

# Vérification que le module est bien chargé
Get-Module -Name ActiveDirectory | Format-Table Name, Version, ModuleType
```

### Exercice 3 : Lister 10 utilisateurs de votre domaine

**Solution :**
```powershell
# Solution de base - Récupération de 10 utilisateurs
Get-ADUser -Filter * -ResultSetSize 10

# Solution alternative avec sélection de propriétés spécifiques
Get-ADUser -Filter * -ResultSetSize 10 -Properties DisplayName, EmailAddress |
    Select-Object SamAccountName, DisplayName, EmailAddress

# Solution avec filtrage par propriété (exemple : utilisateurs actifs uniquement)
Get-ADUser -Filter {Enabled -eq $true} -ResultSetSize 10
```

### Exercice 4 : Explorer la commande Get-ADComputer

**Solution :**
```powershell
# Afficher l'aide de base
Get-Help Get-ADComputer

# Afficher l'aide détaillée
Get-Help Get-ADComputer -Detailed

# Afficher des exemples d'utilisation
Get-Help Get-ADComputer -Examples

# Afficher la syntaxe complète avec tous les paramètres
Get-Help Get-ADComputer -Full

# Exemple d'utilisation pratique
Get-ADComputer -Filter * -ResultSetSize 5 | Format-Table Name, DNSHostName, Enabled
```

### Exercice bonus : Trouver les comptes d'ordinateurs inactifs

```powershell
# Récupérer les ordinateurs qui ne se sont pas connectés depuis plus de 90 jours
$date = (Get-Date).AddDays(-90)
Get-ADComputer -Filter {LastLogonDate -lt $date} -Properties LastLogonDate |
    Select-Object Name, LastLogonDate |
    Sort-Object LastLogonDate
```

### Points à vérifier pour valider les exercices :

1. ✅ Les outils RSAT sont correctement installés
2. ✅ Le module ActiveDirectory est correctement importé et visible dans la liste des modules
3. ✅ La commande `Get-ADUser` retourne bien des utilisateurs de votre domaine
4. ✅ Vous avez exploré toutes les sections d'aide de la commande `Get-ADComputer`




# Scripts complets - Solutions des exercices Module 10-1
# Active Directory & LDAP - Module RSAT et importation

#========================================================================
# Exercice 1 : Installation des outils RSAT
#========================================================================

<#
.SYNOPSIS
    Script d'installation des outils RSAT pour Active Directory.
.DESCRIPTION
    Ce script installe les outils d'administration à distance (RSAT)
    nécessaires pour gérer Active Directory via PowerShell.
    Il détecte automatiquement le système d'exploitation et utilise
    la méthode d'installation appropriée.
.NOTES
    Nécessite des privilèges d'administrateur pour l'exécution.
#>

function Install-RsatAdTools {
    # Vérifier si le script est exécuté en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Error "Ce script doit être exécuté en tant qu'administrateur. Veuillez relancer PowerShell en mode administrateur."
        return
    }

    # Détecter le système d'exploitation
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $isServer = $osInfo.ProductType -ne 1

    Write-Host "Détection du système d'exploitation..." -ForegroundColor Cyan
    if ($isServer) {
        Write-Host "Système Windows Server détecté. Installation via WindowsFeature..." -ForegroundColor Yellow

        try {
            # Vérifier si la fonctionnalité est déjà installée
            $feature = Get-WindowsFeature -Name RSAT-AD-PowerShell -ErrorAction Stop

            if ($feature.Installed) {
                Write-Host "Les outils RSAT pour AD sont déjà installés." -ForegroundColor Green
            } else {
                # Installer la fonctionnalité
                Write-Host "Installation des outils RSAT pour Active Directory..." -ForegroundColor Yellow
                $result = Install-WindowsFeature -Name RSAT-AD-PowerShell -IncludeAllSubFeature -IncludeManagementTools

                if ($result.Success) {
                    Write-Host "Installation réussie!" -ForegroundColor Green
                } else {
                    Write-Host "L'installation a échoué." -ForegroundColor Red
                }
            }
        } catch {
            Write-Error "Une erreur est survenue lors de l'installation: $_"
        }
    } else {
        Write-Host "Système Windows 10/11 détecté. Installation via WindowsCapability..." -ForegroundColor Yellow

        try {
            # Vérifier si la fonctionnalité est déjà installée
            $capability = Get-WindowsCapability -Online | Where-Object { $_.Name -like 'Rsat.ActiveDirectory.DS-LDS.Tools*' }

            if ($capability.State -eq "Installed") {
                Write-Host "Les outils RSAT pour AD sont déjà installés." -ForegroundColor Green
            } else {
                # Installer la fonctionnalité
                Write-Host "Installation des outils RSAT pour Active Directory..." -ForegroundColor Yellow
                Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
                Write-Host "Installation réussie!" -ForegroundColor Green
            }
        } catch {
            Write-Error "Une erreur est survenue lors de l'installation: $_"
        }
    }

    # Vérifier que les outils sont bien installés
    Write-Host "Vérification de l'installation..." -ForegroundColor Cyan
    $moduleAvailable = Get-Module -ListAvailable -Name ActiveDirectory

    if ($moduleAvailable) {
        Write-Host "Le module ActiveDirectory est disponible dans le système." -ForegroundColor Green
        Write-Host "Version du module: $($moduleAvailable.Version)" -ForegroundColor Green
    } else {
        Write-Host "Le module ActiveDirectory n'est pas détecté. Veuillez vérifier l'installation." -ForegroundColor Red
    }
}

# Exécuter la fonction d'installation
Install-RsatAdTools

#========================================================================
# Exercice 2 : Importation du module Active Directory
#========================================================================

<#
.SYNOPSIS
    Script d'importation et de vérification du module Active Directory.
.DESCRIPTION
    Ce script importe le module Active Directory et vérifie qu'il a été
    correctement chargé en affichant des informations détaillées.
.NOTES
    S'exécute après l'installation des outils RSAT.
#>

function Import-AdModule {
    Write-Host "Importation du module Active Directory..." -ForegroundColor Cyan

    try {
        # Vérifier si le module est disponible
        $moduleAvailable = Get-Module -ListAvailable -Name ActiveDirectory

        if (-not $moduleAvailable) {
            Write-Error "Le module ActiveDirectory n'est pas installé. Veuillez d'abord installer les outils RSAT."
            return
        }

        # Importer le module
        Import-Module -Name ActiveDirectory -ErrorAction Stop
        Write-Host "Module ActiveDirectory importé avec succès!" -ForegroundColor Green

        # Afficher les informations du module
        Write-Host "`nInformations sur le module ActiveDirectory:" -ForegroundColor Cyan
        $moduleInfo = Get-Module -Name ActiveDirectory | Format-Table Name, Version, ModuleType, Path -AutoSize | Out-String
        Write-Host $moduleInfo

        # Afficher le nombre de commandes disponibles
        $commands = Get-Command -Module ActiveDirectory
        Write-Host "Le module contient $($commands.Count) commandes." -ForegroundColor Green

        # Afficher les catégories de commandes
        $categories = $commands | Group-Object -Property CommandType | Sort-Object -Property Count -Descending
        Write-Host "`nTypes de commandes disponibles:" -ForegroundColor Cyan
        foreach ($category in $categories) {
            Write-Host "$($category.Name): $($category.Count)" -ForegroundColor Yellow
        }

    } catch {
        Write-Error "Une erreur est survenue lors de l'importation du module: $_"
    }
}

# Exécuter la fonction d'importation
Import-AdModule

#========================================================================
# Exercice 3 : Lister 10 utilisateurs de votre domaine
#========================================================================

<#
.SYNOPSIS
    Script pour lister 10 utilisateurs Active Directory avec différentes options.
.DESCRIPTION
    Ce script démontre différentes façons de lister des utilisateurs
    dans Active Directory avec diverses options de filtrage et d'affichage.
.NOTES
    Nécessite que le module Active Directory soit déjà importé.
#>

function Get-Top10ADUsers {
    Write-Host "Récupération des utilisateurs Active Directory..." -ForegroundColor Cyan

    try {
        # Vérifier que le module est chargé
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Host "Importation du module ActiveDirectory..." -ForegroundColor Yellow
            Import-Module -Name ActiveDirectory -ErrorAction Stop
        }

        # Méthode 1: Liste simple des 10 premiers utilisateurs
        Write-Host "`nMéthode 1: Les 10 premiers utilisateurs (information de base)" -ForegroundColor Yellow
        $users1 = Get-ADUser -Filter * -ResultSetSize 10
        $users1 | Format-Table Name, SamAccountName, Enabled -AutoSize

        # Méthode 2: Avec propriétés additionnelles
        Write-Host "`nMéthode 2: Les 10 premiers utilisateurs avec propriétés additionnelles" -ForegroundColor Yellow
        $users2 = Get-ADUser -Filter * -ResultSetSize 10 -Properties DisplayName, EmailAddress, Created, LastLogonDate
        $users2 | Select-Object Name, SamAccountName, DisplayName, EmailAddress,
                  @{Name="CreationDate"; Expression={$_.Created}},
                  @{Name="LastLogon"; Expression={$_.LastLogonDate}} |
                 Format-Table -AutoSize

        # Méthode 3: Utilisateurs actifs uniquement
        Write-Host "`nMéthode 3: Les 10 premiers utilisateurs actifs uniquement" -ForegroundColor Yellow
        $users3 = Get-ADUser -Filter {Enabled -eq $true} -ResultSetSize 10 -Properties DisplayName, LastLogonDate
        $users3 | Select-Object Name, SamAccountName, DisplayName,
                  @{Name="LastLogon"; Expression={$_.LastLogonDate}} |
                 Format-Table -AutoSize

        # Méthode 4: Utilisateurs avec filtrage par pattern de nom
        Write-Host "`nMéthode 4: Utilisateurs avec filtrage par pattern de nom (exemple: admin*)" -ForegroundColor Yellow
        $users4 = Get-ADUser -Filter "Name -like 'admin*'" -ResultSetSize 10
        $users4 | Format-Table Name, SamAccountName, Enabled -AutoSize

        # Statistiques
        Write-Host "`nStatistiques des utilisateurs dans le domaine:" -ForegroundColor Cyan
        $totalUsers = (Get-ADUser -Filter *).Count
        $enabledUsers = (Get-ADUser -Filter {Enabled -eq $true}).Count
        $disabledUsers = (Get-ADUser -Filter {Enabled -eq $false}).Count

        Write-Host "Total des utilisateurs: $totalUsers" -ForegroundColor Green
        Write-Host "Utilisateurs actifs: $enabledUsers" -ForegroundColor Green
        Write-Host "Utilisateurs désactivés: $disabledUsers" -ForegroundColor Green

    } catch {
        Write-Error "Une erreur est survenue lors de la récupération des utilisateurs: $_"
    }
}

# Exécuter la fonction de liste des utilisateurs
Get-Top10ADUsers

#========================================================================
# Exercice 4 : Explorer la commande Get-ADComputer
#========================================================================

<#
.SYNOPSIS
    Script d'exploration de la commande Get-ADComputer avec exemples pratiques.
.DESCRIPTION
    Ce script explore la commande Get-ADComputer et montre des exemples
    d'utilisation pratique pour différents scénarios d'administration AD.
.NOTES
    Nécessite que le module Active Directory soit déjà importé.
#>

function Explore-ADComputerCommand {
    Write-Host "Exploration de la commande Get-ADComputer..." -ForegroundColor Cyan

    try {
        # Vérifier que le module est chargé
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Host "Importation du module ActiveDirectory..." -ForegroundColor Yellow
            Import-Module -Name ActiveDirectory -ErrorAction Stop
        }

        # Afficher l'aide de base
        Write-Host "`n1. Aide de base pour Get-ADComputer" -ForegroundColor Yellow
        Get-Help Get-ADComputer | Select-Object Name, Synopsis | Format-List

        # Afficher la syntaxe
        Write-Host "`n2. Syntaxe de la commande Get-ADComputer" -ForegroundColor Yellow
        Get-Help Get-ADComputer -Parameter * | Select-Object Name, ParameterType, IsMandatory | Format-Table -AutoSize

        # Exemples d'utilisation pratique
        Write-Host "`n3. Exemples pratiques d'utilisation de Get-ADComputer" -ForegroundColor Yellow

        # 3.1 Liste simple des 5 premiers ordinateurs
        Write-Host "`n3.1 Liste simple des 5 premiers ordinateurs" -ForegroundColor Magenta
        Get-ADComputer -Filter * -ResultSetSize 5 | Format-Table Name, DNSHostName, Enabled -AutoSize

        # 3.2 Ordinateurs avec propriétés additionnelles
        Write-Host "`n3.2 Ordinateurs avec propriétés additionnelles" -ForegroundColor Magenta
        Get-ADComputer -Filter * -ResultSetSize 5 -Properties OperatingSystem, OperatingSystemVersion, Created |
            Select-Object Name, DNSHostName, OperatingSystem, OperatingSystemVersion,
                        @{Name="CreationDate"; Expression={$_.Created}} |
            Format-Table -AutoSize

        # 3.3 Ordinateurs par système d'exploitation
        Write-Host "`n3.3 Ordinateurs par système d'exploitation (exemple: Windows 10)" -ForegroundColor Magenta
        Get-ADComputer -Filter "OperatingSystem -like '*Windows 10*'" -ResultSetSize 5 -Properties OperatingSystem |
            Format-Table Name, DNSHostName, OperatingSystem -AutoSize

        # 3.4 Ordinateurs inactifs (plus de 90 jours)
        Write-Host "`n3.4 Ordinateurs inactifs (plus de 90 jours)" -ForegroundColor Magenta
        $date = (Get-Date).AddDays(-90)
        Get-ADComputer -Filter {LastLogonDate -lt $date} -Properties LastLogonDate -ResultSetSize 5 |
            Select-Object Name, DNSHostName, @{Name="LastLogon"; Expression={$_.LastLogonDate}} |
            Format-Table -AutoSize

        # 3.5 Exportation des données
        Write-Host "`n3.5 Exemple d'exportation des données d'ordinateurs (code uniquement)" -ForegroundColor Magenta
        Write-Host @"
# Exportation vers CSV
Get-ADComputer -Filter * -Properties OperatingSystem, LastLogonDate |
    Select-Object Name, DNSHostName, OperatingSystem, LastLogonDate |
    Export-Csv -Path "C:\Temp\ADComputers.csv" -NoTypeInformation

# Exportation vers HTML
Get-ADComputer -Filter * -Properties OperatingSystem, LastLogonDate |
    Select-Object Name, DNSHostName, OperatingSystem, LastLogonDate |
    ConvertTo-Html -Title "Inventaire des ordinateurs AD" -Body "<h1>Inventaire des ordinateurs AD</h1>" |
    Out-File "C:\Temp\ADComputers.html"
"@ -ForegroundColor Gray

        # Résumé des capacités
        Write-Host "`nRésumé des capacités de Get-ADComputer:" -ForegroundColor Cyan
        Write-Host "• Récupération d'ordinateurs avec divers filtres" -ForegroundColor Green
        Write-Host "• Accès à de nombreuses propriétés (OS, dates, statut, etc.)" -ForegroundColor Green
        Write-Host "• Filtrage par critères multiples (état, date, nom)" -ForegroundColor Green
        Write-Host "• Exportation des résultats dans différents formats" -ForegroundColor Green
        Write-Host "• Intégration facile avec d'autres commandes PowerShell" -ForegroundColor Green

    } catch {
        Write-Error "Une erreur est survenue lors de l'exploration de Get-ADComputer: $_"
    }
}

# Exécuter la fonction d'exploration
Explore-ADComputerCommand

#========================================================================
# Exercice Bonus : Analyse complète des ordinateurs du domaine
#========================================================================

<#
.SYNOPSIS
    Script d'analyse complète des ordinateurs du domaine AD.
.DESCRIPTION
    Ce script avancé effectue une analyse complète des ordinateurs du domaine
    et génère un rapport détaillé avec des statistiques et des alertes.
.NOTES
    Script plus avancé démontrant l'utilisation poussée de Get-ADComputer.
#>

function Get-ADComputerReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$InactiveDays = 90,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath = "$env:USERPROFILE\Desktop\ADComputerReport.html"
    )

    Write-Host "Génération du rapport d'analyse des ordinateurs AD..." -ForegroundColor Cyan

    try {
        # Vérifier que le module est chargé
        if (-not (Get-Module -Name ActiveDirectory)) {
            Write-Host "Importation du module ActiveDirectory..." -ForegroundColor Yellow
            Import-Module -Name ActiveDirectory -ErrorAction Stop
        }

        # Récupération de tous les ordinateurs avec leurs propriétés
        Write-Host "Récupération des données des ordinateurs..." -ForegroundColor Yellow
        $computers = Get-ADComputer -Filter * -Properties OperatingSystem, OperatingSystemVersion,
                                              LastLogonDate, Created, Description,
                                              IPv4Address, Enabled

        # Analyse des données
        Write-Host "Analyse des données..." -ForegroundColor Yellow

        # Statistiques générales
        $totalCount = $computers.Count
        $activeCount = ($computers | Where-Object { $_.Enabled -eq $true }).Count
        $inactiveCount = ($computers | Where-Object { $_.Enabled -eq $false }).Count

        # Analyse par système d'exploitation
        $osSummary = $computers |
                     Group-Object -Property OperatingSystem |
                     Select-Object Name, Count, @{Name="Percentage"; Expression={"{0:P2}" -f ($_.Count / $totalCount)}} |
                     Sort-Object -Property Count -Descending

        # Analyse des ordinateurs inactifs
        $inactiveDate = (Get-Date).AddDays(-$InactiveDays)
        $staleComputers = $computers |
                         Where-Object { $_.LastLogonDate -lt $inactiveDate -and $_.Enabled -eq $true } |
                         Select-Object Name, DNSHostName, OperatingSystem, LastLogonDate, Created |
                         Sort-Object -Property LastLogonDate

        $staleCount = $staleComputers.Count

        # Analyse des ordinateurs récemment ajoutés
        $recentDate = (Get-Date).AddDays(-30)
        $recentComputers = $computers |
                          Where-Object { $_.Created -gt $recentDate } |
                          Select-Object Name, DNSHostName, OperatingSystem, Created |
                          Sort-Object -Property Created -Descending

        $recentCount = $recentComputers.Count

        # Création du rapport HTML
        Write-Host "Génération du rapport HTML..." -ForegroundColor Yellow

        $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse des ordinateurs AD</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        h2 { color: #0099cc; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        tr:hover { background-color: #f5f5f5; }
        .summary { display: flex; justify-content: space-between; }
        .summary-box { border: 1px solid #ddd; border-radius: 5px; padding: 15px; margin: 10px; flex: 1; }
        .warning { background-color: #fff3cd; border-color: #ffeeba; }
        .good { background-color: #d4edda; border-color: #c3e6cb; }
        .info { background-color: #d1ecf1; border-color: #bee5eb; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse des ordinateurs Active Directory</h1>
    <p>Rapport généré le $(Get-Date -Format "dd/MM/yyyy HH:mm")</p>

    <div class="summary">
        <div class="summary-box info">
            <h3>Total des ordinateurs</h3>
            <p style="font-size: 24px; text-align: center;">$totalCount</p>
        </div>
        <div class="summary-box good">
            <h3>Ordinateurs actifs</h3>
            <p style="font-size: 24px; text-align: center;">$activeCount</p>
        </div>
        <div class="summary-box warning">
            <h3>Ordinateurs désactivés</h3>
            <p style="font-size: 24px; text-align: center;">$inactiveCount</p>
        </div>
        <div class="summary-box $(if($staleCount -gt 10){"warning"}else{"good"})">
            <h3>Ordinateurs inactifs (+$InactiveDays jours)</h3>
            <p style="font-size: 24px; text-align: center;">$staleCount</p>
        </div>
    </div>
"@

        # Section des systèmes d'exploitation
        $osSection = @"
    <h2>Systèmes d'exploitation</h2>
    <table>
        <tr>
            <th>Système d'exploitation</th>
            <th>Nombre</th>
            <th>Pourcentage</th>
        </tr>
$(
    $osSummary | ForEach-Object {
        if ($_.Name) {
            "<tr><td>$($_.Name)</td><td>$($_.Count)</td><td>$($_.Percentage)</td></tr>"
        } else {
            "<tr><td><i>Non spécifié</i></td><td>$($_.Count)</td><td>$($_.Percentage)</td></tr>"
        }
    } | Out-String
)
    </table>
"@

        # Section des ordinateurs inactifs
        $staleSection = @"
    <h2>Ordinateurs inactifs (+ de $InactiveDays jours)</h2>
$(
    if ($staleCount -gt 0) {
        @"
    <table>
        <tr>
            <th>Nom</th>
            <th>DNS Host Name</th>
            <th>Système d'exploitation</th>
            <th>Dernière connexion</th>
            <th>Date de création</th>
        </tr>
$(
    $staleComputers | Select-Object -First 20 | ForEach-Object {
        "<tr><td>$($_.Name)</td><td>$($_.DNSHostName)</td><td>$($_.OperatingSystem)</td><td>$(if($_.LastLogonDate){Get-Date $_.LastLogonDate -Format 'dd/MM/yyyy'}else{'Jamais'})</td><td>$(Get-Date $_.Created -Format 'dd/MM/yyyy')</td></tr>"
    } | Out-String
)
    </table>
$(if ($staleCount -gt 20) {"<p><i>Affichage limité aux 20 premiers ordinateurs. Total: $staleCount</i></p>"})
"@
    } else {
        "<p>Aucun ordinateur inactif trouvé.</p>"
    }
)
"@

        # Section des ordinateurs récents
        $recentSection = @"
    <h2>Ordinateurs ajoutés récemment (30 derniers jours)</h2>
$(
    if ($recentCount -gt 0) {
        @"
    <table>
        <tr>
            <th>Nom</th>
            <th>DNS Host Name</th>
            <th>Système d'exploitation</th>
            <th>Date de création</th>
        </tr>
$(
    $recentComputers | ForEach-Object {
        "<tr><td>$($_.Name)</td><td>$($_.DNSHostName)</td><td>$($_.OperatingSystem)</td><td>$(Get-Date $_.Created -Format 'dd/MM/yyyy')</td></tr>"
    } | Out-String
)
    </table>
"@
    } else {
        "<p>Aucun nouvel ordinateur ajouté dans les 30 derniers jours.</p>"
    }
)
"@

        # Pied de page du rapport
        $htmlFooter = @"
    <h2>Recommandations</h2>
    <ul>
$(
    if ($staleCount -gt 10) {
        "<li class='warning'>Il y a $staleCount ordinateurs actifs qui n'ont pas été connectés depuis plus de $InactiveDays jours. Considérez les désactiver ou les supprimer.</li>"
    } else {
        "<li class='good'>Le nombre d'ordinateurs inactifs est faible, ce qui est une bonne pratique.</li>"
    }
)
$(
    if ($inactiveCount -gt $activeCount * 0.25) {
        "<li class='warning'>Le nombre d'ordinateurs désactivés ($inactiveCount) est élevé par rapport au total. Envisagez un nettoyage de l'AD.</li>"
    }
)
$(
    $oldOsCount = ($computers | Where-Object { $_.OperatingSystem -match "Windows (7|XP|2003|2008)" -and $_.Enabled -eq $true }).Count
    if ($oldOsCount -gt 0) {
        "<li class='warning'>Il y a $oldOsCount ordinateurs actifs avec des systèmes d'exploitation obsolètes (Windows 7/XP/2003/2008). Ces systèmes représentent un risque de sécurité.</li>"
    } else {
        "<li class='good'>Aucun système d'exploitation obsolète détecté en utilisation active.</li>"
    }
)
    </ul>

    <p style="margin-top: 50px; font-size: 12px; color: #666; text-align: center;">
        Rapport généré par PowerShell ActiveDirectory Module - $(Get-Date -Format "yyyy")
    </p>
</body>
</html>
"@

        # Assemblage complet du rapport
        $fullReport = $htmlHeader + $osSection + $staleSection + $recentSection + $htmlFooter

        # Sauvegarde du rapport
        $fullReport | Out-File -FilePath $OutputPath -Encoding UTF8

        Write-Host "Rapport généré avec succès à: $OutputPath" -ForegroundColor Green
        Write-Host "Statistiques:" -ForegroundColor Cyan
        Write-Host "- Total des ordinateurs: $totalCount" -ForegroundColor Green
        Write-Host "- Ordinateurs actifs: $activeCount" -ForegroundColor Green
        Write-Host "- Ordinateurs désactivés: $inactiveCount" -ForegroundColor Green
        Write-Host "- Ordinateurs inactifs depuis $InactiveDays jours: $staleCount" -ForegroundColor Green
        Write-Host "- Ordinateurs ajoutés ces 30 derniers jours: $recentCount" -ForegroundColor Green

        # Ouverture automatique du rapport (commenté par défaut)
        # Invoke-Item $OutputPath

    } catch {
        Write-Error "Une erreur est survenue lors de la génération du rapport: $_"
    }
}

# Pour exécuter la fonction du rapport (commentée pour éviter l'exécution accidentelle)
# Get-ADComputerReport -InactiveDays 90 -OutputPath "$env:USERPROFILE\Desktop\ADComputerReport.html"
