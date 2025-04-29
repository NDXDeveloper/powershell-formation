# Module 10-2 : Requêtes sur les utilisateurs, groupes et ordinateurs dans Active Directory

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📚 Introduction

Dans ce module, nous allons explorer comment utiliser PowerShell pour interroger Active Directory et récupérer des informations sur les utilisateurs, les groupes et les ordinateurs. Active Directory (AD) est un service d'annuaire utilisé dans les environnements Windows pour centraliser la gestion des utilisateurs, des ordinateurs et d'autres ressources réseau.

> ⚠️ **Prérequis** : Assurez-vous d'avoir installé le module Active Directory (voir Module 10-1) et d'être connecté à un domaine.

## 🔍 Requêtes de base sur les utilisateurs

### Obtenir tous les utilisateurs

La commande la plus simple pour lister tous les utilisateurs dans Active Directory est :

```powershell
Get-ADUser -Filter *
```

Cette commande renvoie une liste basique des utilisateurs. Cependant, par défaut, seules quelques propriétés sont affichées.

> 💡 **Astuce** : L'option `-Filter *` signifie "tous les utilisateurs", mais attention, cette requête peut être lente dans un grand environnement.

### Obtenir un utilisateur spécifique

Pour rechercher un utilisateur spécifique par son nom d'utilisateur (SAMAccountName) :

```powershell
Get-ADUser -Identity "jdupont"
```

Ou rechercher par prénom et nom :

```powershell
Get-ADUser -Filter "GivenName -eq 'Jean' -and Surname -eq 'Dupont'"
```

### Afficher plus de propriétés

Par défaut, PowerShell n'affiche que quelques propriétés. Pour voir toutes les propriétés d'un utilisateur :

```powershell
Get-ADUser -Identity "jdupont" -Properties *
```

Pour sélectionner uniquement certaines propriétés :

```powershell
Get-ADUser -Identity "jdupont" -Properties EmailAddress, Department, Title, Manager |
    Select-Object Name, EmailAddress, Department, Title, @{Name="Manager"; Expression={($_.Manager -split ",")[0] -replace "CN="}}
```

### Exemples de filtres courants pour les utilisateurs

Utilisateurs dont le compte n'expire jamais :
```powershell
Get-ADUser -Filter 'AccountExpirationDate -notlike "*"' -Properties AccountExpirationDate
```

Utilisateurs d'un département spécifique :
```powershell
Get-ADUser -Filter 'Department -eq "Marketing"' -Properties Department
```

Comptes désactivés :
```powershell
Get-ADUser -Filter 'Enabled -eq $false'
```

Utilisateurs qui ne se sont pas connectés depuis 90 jours :
```powershell
$date = (Get-Date).AddDays(-90)
Get-ADUser -Filter 'LastLogonDate -lt $date' -Properties LastLogonDate
```

## 👥 Requêtes sur les groupes

### Obtenir tous les groupes

Pour lister tous les groupes dans Active Directory :

```powershell
Get-ADGroup -Filter *
```

### Obtenir un groupe spécifique

```powershell
Get-ADGroup -Identity "Comptabilité"
```

### Lister les membres d'un groupe

```powershell
Get-ADGroupMember -Identity "Comptabilité"
```

Pour obtenir uniquement les utilisateurs (et non les groupes ou ordinateurs) dans un groupe :

```powershell
Get-ADGroupMember -Identity "Comptabilité" | Where-Object {$_.objectClass -eq "user"}
```

### Trouver les groupes d'un utilisateur

```powershell
Get-ADPrincipalGroupMembership -Identity "jdupont" | Select-Object Name
```

### Filtrer les groupes

Groupes de sécurité uniquement :
```powershell
Get-ADGroup -Filter 'GroupCategory -eq "Security"'
```

Groupes globaux :
```powershell
Get-ADGroup -Filter 'GroupScope -eq "Global"'
```

## 💻 Requêtes sur les ordinateurs

### Obtenir tous les ordinateurs

```powershell
Get-ADComputer -Filter *
```

### Filtrer les ordinateurs par nom

```powershell
Get-ADComputer -Filter 'Name -like "PC-MARKETING*"'
```

### Obtenir des propriétés supplémentaires sur les ordinateurs

```powershell
Get-ADComputer -Identity "PC-JEAN" -Properties OperatingSystem, OperatingSystemVersion, LastLogonDate
```

### Trouver les ordinateurs inactifs

```powershell
$date = (Get-Date).AddDays(-90)
Get-ADComputer -Filter 'LastLogonDate -lt $date' -Properties LastLogonDate |
    Select-Object Name, LastLogonDate
```

### Trouver les ordinateurs par système d'exploitation

```powershell
Get-ADComputer -Filter 'OperatingSystem -like "*Windows 10*"' -Properties OperatingSystem |
    Select-Object Name, OperatingSystem
```

## 🔄 Combiner les requêtes

### Trouver les utilisateurs et leurs ordinateurs

```powershell
# Obtenir les utilisateurs du département Marketing
$users = Get-ADUser -Filter 'Department -eq "Marketing"' -Properties SamAccountName

# Pour chaque utilisateur, chercher les ordinateurs associés
foreach ($user in $users) {
    $computers = Get-ADComputer -Filter "ManagedBy -eq '$($user.DistinguishedName)'"
    if ($computers) {
        Write-Host "L'utilisateur $($user.Name) gère les ordinateurs suivants :"
        $computers | ForEach-Object { Write-Host "- $($_.Name)" }
    }
}
```

## 📋 Exporter les résultats

### Exporter en CSV

```powershell
# Exporter la liste des utilisateurs en CSV
Get-ADUser -Filter * -Properties Department, Title |
    Select-Object Name, SamAccountName, Department, Title |
    Export-Csv -Path "C:\Exports\users.csv" -NoTypeInformation -Encoding UTF8
```

### Exporter en Excel (via CSV)

```powershell
# Exporter puis ouvrir dans Excel
$usersFile = "C:\Exports\users.csv"
Get-ADUser -Filter * -Properties Department, Title |
    Select-Object Name, SamAccountName, Department, Title |
    Export-Csv -Path $usersFile -NoTypeInformation -Encoding UTF8

# Ouvrir automatiquement dans Excel (si installé)
Start-Process $usersFile
```

## 🛠️ Exercices pratiques

1. **Exercice débutant** : Listez tous les utilisateurs de votre département.
   ```powershell
   # Remplacez "VotreDepartement" par le nom de votre département
   Get-ADUser -Filter 'Department -eq "VotreDepartement"' -Properties Department |
       Select-Object Name, SamAccountName
   ```

2. **Exercice intermédiaire** : Trouvez tous les utilisateurs membres du groupe "Direction" et exportez leurs informations de contact.
   ```powershell
   Get-ADGroupMember -Identity "Direction" |
       Where-Object {$_.objectClass -eq "user"} |
       ForEach-Object {
           Get-ADUser -Identity $_.SamAccountName -Properties EmailAddress, OfficePhone
       } | Select-Object Name, EmailAddress, OfficePhone |
       Export-Csv -Path "C:\Exports\direction_contacts.csv" -NoTypeInformation
   ```

3. **Exercice avancé** : Créez un rapport des ordinateurs Windows 10 qui n'ont pas été connectés depuis 30 jours, avec le nom de leur propriétaire.

## 📝 Bonnes pratiques

1. **Utilisez des filtres précis** : Évitez `-Filter *` dans les grands environnements pour limiter la charge sur le contrôleur de domaine.

2. **Sélectionnez uniquement les propriétés nécessaires** : N'utilisez `-Properties *` que lorsque c'est vraiment nécessaire.

3. **Gérez la pagination** : Pour les grandes requêtes, utilisez `-ResultSetSize` ou pipeline vers `Select-Object -First X`.

4. **Créez des fonctions réutilisables** pour vos requêtes courantes :
   ```powershell
   function Get-InactiveUsers {
       param(
           [int]$Days = 90
       )
       $date = (Get-Date).AddDays(-$Days)
       Get-ADUser -Filter 'LastLogonDate -lt $date -and Enabled -eq $true' -Properties LastLogonDate |
           Select-Object Name, SamAccountName, LastLogonDate
   }

   # Utilisation
   Get-InactiveUsers -Days 30
   ```

## 🔗 Ressources supplémentaires

- Documentation Microsoft sur le module Active Directory PowerShell
- Livre : "PowerShell for Active Directory" (recommandé pour approfondir)
- Commandes PowerShell utiles : `Get-Help Get-ADUser -Examples`

## 🎯 À retenir

- La syntaxe de filtrage AD est spécifique et diffère du filtrage PowerShell standard
- Utilisez toujours des filtres côté serveur (-Filter) plutôt que côté client (Where-Object) pour de meilleures performances
- Exploitez les propriétés supplémentaires avec le paramètre -Properties
- L'exportation en CSV permet de facilement manipuler les données dans Excel

Dans le prochain module, nous verrons comment créer, modifier et supprimer des objets Active Directory.
