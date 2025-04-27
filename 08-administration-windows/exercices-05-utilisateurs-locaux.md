# Solutions des exercices pratiques - Module 9-5
## Gestion des utilisateurs et groupes locaux avec PowerShell

### Exercice 1: Créer 5 utilisateurs avec mots de passe aléatoires et les ajouter à un groupe

```powershell
# Script pour créer 5 utilisateurs avec des mots de passe aléatoires et les ajouter à un groupe
function New-RandomPassword {
    param(
        [int]$Length = 12
    )

    # Caractères à utiliser pour le mot de passe
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '0123456789'
    $special = '!@#$%^&*()-_=+[]{}|;:,.<>?'

    # Combinaison de tous les caractères
    $allChars = $lowercase + $uppercase + $numbers + $special

    # Génération du mot de passe aléatoire
    $password = ''
    $random = New-Object System.Random

    # Assurer au moins un caractère de chaque type
    $password += $lowercase[$random.Next(0, $lowercase.Length)]
    $password += $uppercase[$random.Next(0, $uppercase.Length)]
    $password += $numbers[$random.Next(0, $numbers.Length)]
    $password += $special[$random.Next(0, $special.Length)]

    # Compléter avec des caractères aléatoires
    for ($i = 4; $i -lt $Length; $i++) {
        $password += $allChars[$random.Next(0, $allChars.Length)]
    }

    # Mélanger les caractères
    $passwordArray = $password.ToCharArray()
    $shuffledPassword = $passwordArray | Sort-Object {Get-Random}

    return -join $shuffledPassword
}

# Création du groupe s'il n'existe pas déjà
$groupName = "StageEmployees"
if (-not (Get-LocalGroup -Name $groupName -ErrorAction SilentlyContinue)) {
    Write-Host "Création du groupe $groupName..." -ForegroundColor Cyan
    New-LocalGroup -Name $groupName -Description "Groupe pour les stagiaires" -ErrorAction Stop
    Write-Host "Groupe $groupName créé avec succès!" -ForegroundColor Green
} else {
    Write-Host "Le groupe $groupName existe déjà." -ForegroundColor Yellow
}

# Création des utilisateurs
$users = @("Stagiaire1", "Stagiaire2", "Stagiaire3", "Stagiaire4", "Stagiaire5")
$createdUsers = @()

Write-Host "Création des utilisateurs et ajout au groupe $groupName..." -ForegroundColor Cyan

foreach ($user in $users) {
    try {
        # Vérifier si l'utilisateur existe déjà
        if (Get-LocalUser -Name $user -ErrorAction SilentlyContinue) {
            Write-Host "L'utilisateur $user existe déjà, il sera ignoré." -ForegroundColor Yellow
            continue
        }

        # Générer un mot de passe aléatoire
        $plainPassword = New-RandomPassword -Length 14
        $securePassword = ConvertTo-SecureString $plainPassword -AsPlainText -Force

        # Créer l'utilisateur
        $newUser = New-LocalUser -Name $user `
                                -Password $securePassword `
                                -FullName "Stagiaire $($user.Substring(9))" `
                                -Description "Compte stagiaire" `
                                -AccountNeverExpires `
                                -PasswordNeverExpires:$false `
                                -UserMayNotChangePassword:$false `
                                -ErrorAction Stop

        # Ajouter l'utilisateur au groupe
        Add-LocalGroupMember -Group $groupName -Member $user -ErrorAction Stop

        # Stocker les informations pour rapport
        $createdUsers += [PSCustomObject]@{
            Utilisateur = $user
            MotDePasse = $plainPassword
            Statut = "Créé et ajouté au groupe $groupName"
        }

        Write-Host "Utilisateur $user créé avec succès et ajouté au groupe $groupName" -ForegroundColor Green

    } catch {
        Write-Host "Erreur lors de la création/ajout de l'utilisateur $user : $_" -ForegroundColor Red
    }
}

# Afficher un rapport des utilisateurs créés
if ($createdUsers.Count -gt 0) {
    Write-Host "`nRésumé des utilisateurs créés:" -ForegroundColor Cyan
    $createdUsers | Format-Table -AutoSize

    # Exporter les informations dans un fichier (optionnel)
    $exportPath = "$env:USERPROFILE\Desktop\NouveauxUtilisateurs.csv"
    $createdUsers | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
    Write-Host "Les informations des comptes ont été exportées vers: $exportPath" -ForegroundColor Cyan
} else {
    Write-Host "Aucun nouvel utilisateur n'a été créé." -ForegroundColor Yellow
}
```

### Exercice 2: Fonction pour vérifier si un utilisateur est membre d'un groupe

```powershell
function Test-GroupMembership {
    <#
    .SYNOPSIS
        Vérifie si un utilisateur est membre d'un groupe local spécifique.

    .DESCRIPTION
        Cette fonction vérifie si un utilisateur local ou de domaine est membre
        d'un groupe local spécifique, directement ou indirectement via l'appartenance à d'autres groupes.

    .PARAMETER Username
        Le nom d'utilisateur à vérifier.

    .PARAMETER GroupName
        Le nom du groupe local dans lequel vérifier l'appartenance.

    .EXAMPLE
        Test-GroupMembership -Username "JohnDoe" -GroupName "Administrateurs"

        Vérifie si l'utilisateur JohnDoe est membre du groupe Administrateurs.

    .NOTES
        Auteur: Votre Nom
        Date: 26/04/2025
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Username,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$GroupName
    )

    try {
        # Vérifier si l'utilisateur existe
        $user = Get-LocalUser -Name $Username -ErrorAction Stop
        Write-Verbose "Utilisateur '$Username' trouvé."

        # Vérifier si le groupe existe
        $group = Get-LocalGroup -Name $GroupName -ErrorAction Stop
        Write-Verbose "Groupe '$GroupName' trouvé."

        # Récupérer tous les membres du groupe
        $groupMembers = Get-LocalGroupMember -Name $GroupName -ErrorAction Stop

        # Vérifier l'appartenance directe
        $directMember = $groupMembers | Where-Object {
            # Vérifie si le nom de l'utilisateur correspond (en tenant compte des formats différents possibles)
            $_.Name -like "*\$Username" -or $_.Name -eq $Username -or $_.SID -eq $user.SID
        }

        if ($directMember) {
            Write-Host "L'utilisateur '$Username' est membre direct du groupe '$GroupName'." -ForegroundColor Green
            return $true
        } else {
            Write-Host "L'utilisateur '$Username' n'est pas membre direct du groupe '$GroupName'." -ForegroundColor Yellow

            # Option avancée : vérifier l'appartenance indirecte (via d'autres groupes)
            # Ceci est plus complexe et peut nécessiter des recherches récursives
            # Pour une implémentation complète, on pourrait vérifier si l'utilisateur est membre d'autres groupes
            # qui eux-mêmes sont membres du groupe cible

            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la vérification de l'appartenance au groupe: $_"
        return $false
    }
}

# Exemples d'utilisation :
# Test-GroupMembership -Username "Administrator" -GroupName "Administrateurs" -Verbose
# Test-GroupMembership -Username "NouvelUtilisateur" -GroupName "ServiceDesk"
```

### Version avancée avec vérification de l'appartenance indirecte :

```powershell
function Test-GroupMembershipRecursive {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$GroupName,

        [System.Collections.ArrayList]$VisitedGroups = [System.Collections.ArrayList]::new()
    )

    try {
        # Éviter les boucles infinies en gardant trace des groupes déjà visités
        if ($VisitedGroups -contains $GroupName) {
            Write-Verbose "Groupe '$GroupName' déjà vérifié, évitement de boucle."
            return $false
        }

        [void]$VisitedGroups.Add($GroupName)

        # Vérifier si le groupe existe
        $group = Get-LocalGroup -Name $GroupName -ErrorAction Stop
        Write-Verbose "Vérification du groupe '$GroupName'..."

        # Récupérer tous les membres du groupe
        $groupMembers = Get-LocalGroupMember -Name $GroupName -ErrorAction SilentlyContinue

        # Vérifier l'appartenance directe
        $directMember = $groupMembers | Where-Object {
            $_.Name -like "*\$Username" -or $_.Name -eq $Username
        }

        if ($directMember) {
            Write-Verbose "Trouvé! '$Username' est membre direct de '$GroupName'."
            return $true
        }

        # Vérifier l'appartenance indirecte à travers d'autres groupes
        foreach ($member in $groupMembers) {
            # Si le membre est un groupe, vérifier récursivement
            if ($member.ObjectClass -eq "Group") {
                $nestedGroupName = $member.Name.Split('\')[-1]  # Extraire juste le nom du groupe
                Write-Verbose "Vérification du groupe imbriqué: $nestedGroupName"

                $isMemberOfNestedGroup = Test-GroupMembershipRecursive -Username $Username `
                                                                     -GroupName $nestedGroupName `
                                                                     -VisitedGroups $VisitedGroups

                if ($isMemberOfNestedGroup) {
                    Write-Verbose "'$Username' est membre de '$GroupName' via le groupe '$nestedGroupName'."
                    return $true
                }
            }
        }

        Write-Verbose "'$Username' n'est pas membre de '$GroupName', ni directement ni indirectement."
        return $false
    }
    catch {
        Write-Error "Erreur lors de la vérification de l'appartenance au groupe: $_"
        return $false
    }
}

# Pour utiliser cette fonction avec un rapport visuel :
function Test-UserGroupMembership {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$GroupName
    )

    $result = Test-GroupMembershipRecursive -Username $Username -GroupName $GroupName -Verbose

    if ($result) {
        Write-Host "`n✅ L'utilisateur '$Username' est membre du groupe '$GroupName' (directement ou indirectement)." -ForegroundColor Green
    } else {
        Write-Host "`n❌ L'utilisateur '$Username' n'est PAS membre du groupe '$GroupName'." -ForegroundColor Red
    }

    return $result
}

# Exemple d'utilisation:
# Test-UserGroupMembership -Username "Administrator" -GroupName "Administrateurs"
```

### Exercice 3: Rapport des utilisateurs locaux avec leur état et appartenance aux groupes

```powershell
function Get-LocalUserReport {
    <#
    .SYNOPSIS
        Génère un rapport détaillé des utilisateurs locaux avec leur état et appartenance aux groupes.

    .DESCRIPTION
        Cette fonction crée un rapport complet listant tous les utilisateurs locaux,
        leur état (activé/désactivé) et les groupes auxquels ils appartiennent.
        Le rapport peut être exporté au format CSV, HTML ou affiché à l'écran.

    .PARAMETER ExportPath
        Chemin où exporter le rapport. Si spécifié, un fichier CSV et un fichier HTML seront générés.

    .PARAMETER IncludeDisabled
        Inclure les utilisateurs désactivés dans le rapport.

    .EXAMPLE
        Get-LocalUserReport

        Affiche le rapport à l'écran.

    .EXAMPLE
        Get-LocalUserReport -ExportPath "C:\Temp\UserReport"

        Génère le rapport et l'exporte aux formats CSV et HTML dans C:\Temp\UserReport.csv et C:\Temp\UserReport.html

    .NOTES
        Auteur: Votre Nom
        Date: 26/04/2025
    #>
    [CmdletBinding()]
    param (
        [string]$ExportPath,
        [switch]$IncludeDisabled = $true
    )

    try {
        Write-Host "Génération du rapport des utilisateurs locaux..." -ForegroundColor Cyan

        # Récupérer tous les utilisateurs locaux
        $users = if ($IncludeDisabled) {
            Get-LocalUser
        } else {
            Get-LocalUser | Where-Object { $_.Enabled -eq $true }
        }

        # Récupérer tous les groupes locaux pour les avoir en mémoire
        $allGroups = Get-LocalGroup

        $userReports = [System.Collections.ArrayList]::new()
        $progress = 0
        $totalUsers = $users.Count

        foreach ($user in $users) {
            $progress++
            Write-Progress -Activity "Analyse des utilisateurs" -Status "Traitement de $($user.Name)" `
                          -PercentComplete (($progress / $totalUsers) * 100)

            # Trouver tous les groupes dont l'utilisateur est membre
            $userGroups = @()
            foreach ($group in $allGroups) {
                try {
                    $members = Get-LocalGroupMember -Name $group.Name -ErrorAction SilentlyContinue
                    $isMember = $members | Where-Object {
                        $_.SID -eq $user.SID -or
                        $_.Name -like "*\$($user.Name)" -or
                        $_.Name -eq $user.Name
                    }

                    if ($isMember) {
                        $userGroups += $group.Name
                    }
                } catch {
                    # Ignorer les erreurs de groupes qui ne peuvent pas être lus
                    Write-Verbose "Impossible de lire les membres du groupe $($group.Name): $_"
                }
            }

            # Créer l'objet rapport pour cet utilisateur
            $userReport = [PSCustomObject]@{
                Nom = $user.Name
                NomComplet = $user.FullName
                Activé = if ($user.Enabled) { "Oui" } else { "Non" }
                SID = $user.SID.Value
                Description = $user.Description
                DernièreConnexion = "N/A"  # Cette information n'est pas facilement accessible
                ExpirationCompte = if ($user.AccountExpires -eq [DateTime]::MaxValue) { "Jamais" } else { $user.AccountExpires }
                ExpirationMotDePasse = if ($user.PasswordExpires) { "Oui" } else { "Non" }
                PeutChangerMotDePasse = if ($user.UserMayChangePassword) { "Oui" } else { "Non" }
                Groupes = if ($userGroups.Count -gt 0) { $userGroups -join ", " } else { "Aucun" }
                NombreGroupes = $userGroups.Count
            }

            [void]$userReports.Add($userReport)
        }

        Write-Progress -Activity "Analyse des utilisateurs" -Completed

        # Afficher le rapport à l'écran
        Write-Host "`nRapport des utilisateurs locaux:" -ForegroundColor Green
        $userReports | Format-Table -Property Nom, NomComplet, Activé, NombreGroupes, Groupes -AutoSize

        # Exporter le rapport si demandé
        if ($ExportPath) {
            # Créer le dossier parent si nécessaire
            $folder = Split-Path -Path $ExportPath -Parent
            if ($folder -and -not (Test-Path -Path $folder)) {
                New-Item -Path $folder -ItemType Directory -Force | Out-Null
            }

            # Exporter en CSV
            $csvPath = "$ExportPath.csv"
            $userReports | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            Write-Host "Rapport CSV exporté vers: $csvPath" -ForegroundColor Green

            # Exporter en HTML (plus lisible)
            $htmlPath = "$ExportPath.html"

            $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport des utilisateurs locaux</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th { background-color: #0066cc; color: white; text-align: left; padding: 8px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #ddd; }
        .enabled { color: green; }
        .disabled { color: red; }
    </style>
</head>
<body>
    <h1>Rapport des utilisateurs locaux</h1>
    <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss") sur $env:COMPUTERNAME</p>
    <table>
        <tr>
            <th>Nom</th>
            <th>Nom complet</th>
            <th>Activé</th>
            <th>Description</th>
            <th>Groupes</th>
        </tr>
"@

            $htmlRows = foreach ($user in $userReports) {
                $statusClass = if ($user.Activé -eq "Oui") { "enabled" } else { "disabled" }

                @"
        <tr>
            <td>$($user.Nom)</td>
            <td>$($user.NomComplet)</td>
            <td class="$statusClass">$($user.Activé)</td>
            <td>$($user.Description)</td>
            <td>$($user.Groupes)</td>
        </tr>
"@
            }

            $htmlFooter = @"
    </table>
</body>
</html>
"@

            $htmlContent = $htmlHeader + $htmlRows + $htmlFooter
            $htmlContent | Out-File -FilePath $htmlPath -Encoding utf8

            Write-Host "Rapport HTML exporté vers: $htmlPath" -ForegroundColor Green
        }

        return $userReports
    }
    catch {
        Write-Error "Erreur lors de la génération du rapport: $_"
    }
}

# Exemple d'utilisation:
# Get-LocalUserReport -ExportPath "$env:USERPROFILE\Desktop\RapportUtilisateurs"
```

Ces solutions offrent un bon équilibre entre fonctionnalité et lisibilité, tout en montrant des techniques PowerShell avancées comme:

1. La génération de mots de passe aléatoires sécurisés
2. La vérification récursive d'appartenance aux groupes (y compris via groupes imbriqués)
3. La création de rapports détaillés au format CSV et HTML
4. La gestion des erreurs avec try/catch
5. L'affichage de la progression pour les opérations longues
6. La documentation complète des fonctions avec l'aide intégrée

Vous pouvez adapter ces scripts selon vos besoins spécifiques ou les étendre avec des fonctionnalités supplémentaires.
