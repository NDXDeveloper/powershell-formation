# Module 10 - Active Directory & LDAP
## 10-5. Audit de l'environnement AD (dernière connexion, comptes inactifs)

L'audit de votre environnement Active Directory est une tâche essentielle pour maintenir la sécurité et l'efficacité de votre infrastructure. PowerShell offre des outils puissants pour identifier les comptes inactifs, vérifier les dernières connexions, et générer des rapports détaillés. Dans cette section, nous allons explorer les commandes et techniques pour auditer efficacement votre AD.

### Pourquoi auditer votre Active Directory ?

- **Sécurité** : Les comptes inactifs ou non utilisés représentent un risque de sécurité
- **Conformité** : De nombreuses normes de sécurité exigent un audit régulier des comptes
- **Optimisation des licences** : Identifier les comptes inutilisés permet de réduire les coûts de licences
- **Nettoyage de l'environnement** : Maintenir un AD propre facilite sa gestion

### Vérifier la dernière connexion des utilisateurs

Pour identifier quand un utilisateur s'est connecté pour la dernière fois, nous pouvons utiliser la propriété `LastLogonDate` :

```powershell
# Obtenir la date de dernière connexion pour tous les utilisateurs
Get-ADUser -Filter * -Properties LastLogonDate |
    Select-Object Name, SamAccountName, LastLogonDate |
    Sort-Object LastLogonDate
```

Vous pouvez filtrer les résultats pour n'afficher que les informations pertinentes :

```powershell
# Afficher uniquement les 10 connexions les plus récentes
Get-ADUser -Filter * -Properties LastLogonDate |
    Select-Object Name, SamAccountName, LastLogonDate |
    Sort-Object LastLogonDate -Descending |
    Select-Object -First 10
```

### Identifier les comptes inactifs

Pour trouver les comptes qui n'ont pas été utilisés depuis un certain temps :

```powershell
# Définir la date limite (par exemple, inactifs depuis 90 jours)
$InactiveDays = 90
$DateLimit = (Get-Date).AddDays(-$InactiveDays)

# Trouver les utilisateurs inactifs
Get-ADUser -Filter {LastLogonDate -lt $DateLimit -and Enabled -eq $true} -Properties LastLogonDate |
    Select-Object Name, SamAccountName, LastLogonDate |
    Sort-Object LastLogonDate
```

> 💡 **Astuce** : Parfois, le champ `LastLogonDate` peut ne pas être complètement à jour à cause de la réplication entre contrôleurs de domaine. Pour une précision maximale, utilisez `LastLogonTimeStamp` ou vérifiez sur tous les contrôleurs de domaine.

### Créer un rapport complet des comptes inactifs

Voici un script plus complet qui génère un rapport CSV des comptes inactifs :

```powershell
# Paramètres configurables
$InactiveDays = 90
$ReportPath = "C:\Reports\InactiveUsers_$(Get-Date -Format 'yyyy-MM-dd').csv"
$DateLimit = (Get-Date).AddDays(-$InactiveDays)

# Créer le dossier de rapport s'il n'existe pas
$ReportFolder = Split-Path -Path $ReportPath -Parent
if (-not (Test-Path -Path $ReportFolder)) {
    New-Item -Path $ReportFolder -ItemType Directory -Force
}

# Récupérer les comptes inactifs avec des propriétés supplémentaires
$InactiveUsers = Get-ADUser -Filter {LastLogonDate -lt $DateLimit -and Enabled -eq $true} -Properties LastLogonDate, Description, Department, Manager, PasswordLastSet |
    Select-Object Name, SamAccountName, LastLogonDate, Description, Department, @{Name="Manager"; Expression={(Get-ADUser $_.Manager -Properties DisplayName).DisplayName}}, PasswordLastSet, DistinguishedName

# Exporter vers CSV
$InactiveUsers | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

Write-Host "Rapport généré : $ReportPath"
Write-Host "Nombre de comptes inactifs trouvés : $($InactiveUsers.Count)"
```

### Vérifier les comptes qui n'ont jamais été utilisés

Pour identifier les comptes qui n'ont jamais été utilisés dans votre environnement :

```powershell
# Trouver les comptes qui n'ont jamais été utilisés
Get-ADUser -Filter {LastLogonDate -notlike "*" -and Enabled -eq $true} -Properties LastLogonDate, WhenCreated |
    Select-Object Name, SamAccountName, WhenCreated |
    Sort-Object WhenCreated
```

### Vérifier les comptes avec mot de passe qui n'expire jamais

Un autre aspect important de l'audit est de repérer les comptes dont le mot de passe n'expire jamais :

```powershell
# Trouver les comptes avec mot de passe qui n'expire jamais
Get-ADUser -Filter {PasswordNeverExpires -eq $true -and Enabled -eq $true} -Properties PasswordNeverExpires |
    Select-Object Name, SamAccountName, PasswordNeverExpires
```

### Détecter les comptes à privilèges inactifs

Les comptes à privilèges inactifs représentent un risque de sécurité particulier :

```powershell
# Définir la date limite
$DateLimit = (Get-Date).AddDays(-30)  # Inactifs depuis 30 jours

# Trouver les membres des groupes admin inactifs
$AdminGroups = @("Domain Admins", "Enterprise Admins", "Schema Admins")

foreach ($Group in $AdminGroups) {
    Write-Host "Vérification des membres inactifs du groupe : $Group" -ForegroundColor Cyan

    Get-ADGroupMember -Identity $Group |
        Where-Object { $_.objectClass -eq "user" } |
        ForEach-Object {
            $User = Get-ADUser $_ -Properties LastLogonDate, Enabled
            if ($User.LastLogonDate -lt $DateLimit -or $null -eq $User.LastLogonDate) {
                $User | Select-Object Name, SamAccountName, LastLogonDate, Enabled, @{Name="AdminGroup"; Expression={$Group}}
            }
        }
}
```

### Actions automatisées suite à l'audit

Une fois les comptes inactifs identifiés, vous pouvez :

1. **Désactiver les comptes** inactifs depuis longtemps :

```powershell
# Désactiver les comptes inactifs depuis plus de 180 jours
$DateLimit = (Get-Date).AddDays(-180)

# Obtenir les comptes et les désactiver
Get-ADUser -Filter {LastLogonDate -lt $DateLimit -and Enabled -eq $true} -Properties LastLogonDate |
    ForEach-Object {
        # Ajouter une description pour garder trace de l'action
        Set-ADUser -Identity $_ -Description "Compte désactivé automatiquement le $(Get-Date -Format 'yyyy-MM-dd') pour inactivité"
        # Désactiver le compte
        Disable-ADAccount -Identity $_
        Write-Host "Compte désactivé : $($_.SamAccountName)" -ForegroundColor Yellow
    }
```

2. **Déplacer les comptes** dans une unité d'organisation spécifique :

```powershell
# Déplacer les comptes inactifs vers une OU spécifique
$InactiveOU = "OU=CompteInactifs,DC=entreprise,DC=local"
$DateLimit = (Get-Date).AddDays(-90)

# Vérifier si l'OU existe et la créer si nécessaire
if (-not (Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $InactiveOU} -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit -Name "CompteInactifs" -Path "DC=entreprise,DC=local"
}

# Obtenir les comptes et les déplacer
Get-ADUser -Filter {LastLogonDate -lt $DateLimit -and Enabled -eq $true} -Properties LastLogonDate |
    ForEach-Object {
        Move-ADObject -Identity $_.DistinguishedName -TargetPath $InactiveOU
        Write-Host "Compte déplacé vers l'OU des inactifs : $($_.SamAccountName)" -ForegroundColor Yellow
    }
```

### Configuration d'un audit régulier avec une tâche planifiée

Pour automatiser l'audit, vous pouvez créer une tâche planifiée :

```powershell
# Définir le chemin du script d'audit
$ScriptPath = "C:\Scripts\AuditAD.ps1"

# Créer une tâche planifiée pour exécuter le script chaque semaine
$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
$Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "08:00"
$Settings = New-ScheduledTaskSettingsSet -RunOnlyIfNetworkAvailable -WakeToRun

Register-ScheduledTask -TaskName "Audit Active Directory Hebdomadaire" -Action $Action -Trigger $Trigger -Settings $Settings -RunLevel Highest -User "SYSTEM"
```

### Points à retenir

- L'audit régulier de votre AD est une pratique essentielle de sécurité et de maintenance
- PowerShell permet d'automatiser ces tâches d'audit avec précision
- Conservez un historique de vos audits pour suivre l'évolution de votre environnement
- N'oubliez pas d'adapter les scripts à votre environnement spécifique (noms de domaines, OUs, etc.)
- Testez toujours vos scripts dans un environnement de test avant de les exécuter en production

### Exercice pratique

1. Créez un script qui génère un rapport des 10 comptes les plus anciennement connectés
2. Modifiez le script pour envoyer automatiquement ce rapport par email à l'administrateur
3. Ajoutez une vérification des comptes créés il y a plus de 30 jours et jamais utilisés

---

Dans le prochain module, nous explorerons les aspects réseau et sécurité avec PowerShell.
