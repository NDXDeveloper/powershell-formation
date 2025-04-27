# 10-3. Création, modification, suppression d'objets AD

## Introduction

Dans ce chapitre, nous allons apprendre à créer, modifier et supprimer différents objets dans Active Directory à l'aide de PowerShell. Ces opérations sont essentielles pour l'administration quotidienne d'un domaine Windows.

> ⚠️ **Attention** : Les commandes présentées ici modifient réellement votre environnement Active Directory. Testez-les d'abord dans un environnement de développement ou utilisez le paramètre `-WhatIf` pour simuler l'exécution.

## Prérequis

- Module Active Directory installé (`Import-Module ActiveDirectory`)
- Droits suffisants pour modifier des objets AD
- Connexion à un contrôleur de domaine

```powershell
# Vérification que le module AD est chargé
Import-Module ActiveDirectory -ErrorAction SilentlyContinue
if (!(Get-Module ActiveDirectory)) {
    Write-Error "Le module ActiveDirectory n'est pas disponible. Installez les outils RSAT."
    exit
}
```

## 1. Création d'objets AD

### 1.1 Création d'un utilisateur

La création d'un utilisateur se fait avec la cmdlet `New-ADUser`. Voici un exemple simple :

```powershell
# Création d'un utilisateur basique
New-ADUser -Name "Jean Dupont" `
           -GivenName "Jean" `
           -Surname "Dupont" `
           -SamAccountName "jdupont" `
           -UserPrincipalName "jdupont@mondomaine.local" `
           -Path "OU=Utilisateurs,DC=mondomaine,DC=local" `
           -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
           -Enabled $true `
           -ChangePasswordAtLogon $true
```

#### Explication des paramètres principaux :
- `-Name` : Nom complet de l'utilisateur (affiché dans AD)
- `-GivenName` : Prénom
- `-Surname` : Nom de famille
- `-SamAccountName` : Nom de connexion (compatible Windows ancien)
- `-UserPrincipalName` : Format email pour la connexion
- `-Path` : Emplacement dans l'AD où créer l'utilisateur
- `-AccountPassword` : Mot de passe initial (doit être sécurisé)
- `-Enabled` : Active immédiatement le compte
- `-ChangePasswordAtLogon` : Force le changement du mot de passe à la première connexion

### 1.2 Création d'un groupe

Pour créer un groupe, utilisez la cmdlet `New-ADGroup` :

```powershell
# Création d'un groupe de sécurité global
New-ADGroup -Name "Service Marketing" `
            -SamAccountName "Marketing" `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName "Service Marketing" `
            -Path "OU=Groupes,DC=mondomaine,DC=local" `
            -Description "Membres du service marketing"
```

#### Types de groupes principaux :
- **GroupCategory** : `Security` (pour les autorisations) ou `Distribution` (pour les emails)
- **GroupScope** :
  - `DomainLocal` : Utilisé pour attribuer des permissions dans le domaine
  - `Global` : Contient des utilisateurs du domaine actuel
  - `Universal` : Peut contenir des membres de n'importe quel domaine de la forêt

### 1.3 Création d'une unité d'organisation (OU)

Les unités d'organisation aident à structurer votre AD. Créez-les avec `New-ADOrganizationalUnit` :

```powershell
# Création d'une OU
New-ADOrganizationalUnit -Name "Département IT" `
                         -Path "DC=mondomaine,DC=local" `
                         -Description "Personnel informatique" `
                         -ProtectedFromAccidentalDeletion $true
```

Le paramètre `-ProtectedFromAccidentalDeletion` est important car il empêche la suppression accidentelle de l'OU et de son contenu.

### 1.4 Création d'un ordinateur

Pour ajouter un ordinateur à l'AD :

```powershell
# Création d'un objet ordinateur
New-ADComputer -Name "PC-MARKETING-01" `
               -SamAccountName "PC-MARKETING-01" `
               -Path "OU=Ordinateurs,DC=mondomaine,DC=local" `
               -Enabled $true `
               -Description "PC du service marketing"
```

## 2. Modification d'objets AD

### 2.1 Modification d'un utilisateur

La cmdlet `Set-ADUser` permet de modifier un utilisateur existant :

```powershell
# Mise à jour des informations d'un utilisateur
Set-ADUser -Identity "jdupont" `
           -Title "Responsable Marketing" `
           -Department "Marketing" `
           -Company "Ma Société" `
           -OfficePhone "+33 1 23 45 67 89" `
           -EmailAddress "jean.dupont@masociete.com" `
           -Office "Paris"
```

#### Autres modifications courantes :

```powershell
# Désactiver un compte utilisateur
Set-ADUser -Identity "jdupont" -Enabled $false

# Définir une date d'expiration du compte
Set-ADUser -Identity "jdupont" -AccountExpirationDate "31/12/2023"

# Réinitialiser le mot de passe
Set-ADAccountPassword -Identity "jdupont" `
                      -Reset `
                      -NewPassword (ConvertTo-SecureString "Nouveau@P@ss123" -AsPlainText -Force)
```

### 2.2 Modification d'un groupe

Vous pouvez modifier les propriétés d'un groupe avec `Set-ADGroup` :

```powershell
# Modifier la description d'un groupe
Set-ADGroup -Identity "Marketing" `
            -Description "Équipe marketing internationale" `
            -DisplayName "Équipe Marketing"
```

### 2.3 Ajouter/Supprimer des membres d'un groupe

Pour gérer les membres d'un groupe, utilisez `Add-ADGroupMember` et `Remove-ADGroupMember` :

```powershell
# Ajouter un utilisateur à un groupe
Add-ADGroupMember -Identity "Marketing" -Members "jdupont"

# Ajouter plusieurs utilisateurs à un groupe
Add-ADGroupMember -Identity "Marketing" -Members "jdupont", "mmartinez", "ldubois"

# Supprimer un membre d'un groupe
Remove-ADGroupMember -Identity "Marketing" -Members "ldubois" -Confirm:$false
```

Le paramètre `-Confirm:$false` évite la demande de confirmation pour chaque utilisateur.

### 2.4 Déplacement d'objets AD

Pour déplacer un objet AD vers une autre OU :

```powershell
# Déplacer un utilisateur vers une autre OU
Move-ADObject -Identity "CN=Jean Dupont,OU=Utilisateurs,DC=mondomaine,DC=local" `
              -TargetPath "OU=Marketing,OU=Départements,DC=mondomaine,DC=local"
```

## 3. Suppression d'objets AD

### 3.1 Suppression d'un utilisateur

Pour supprimer un utilisateur :

```powershell
# Supprimer un utilisateur
Remove-ADUser -Identity "jdupont" -Confirm:$false
```

### 3.2 Suppression d'un groupe

Pour supprimer un groupe :

```powershell
# Supprimer un groupe
Remove-ADGroup -Identity "Marketing" -Confirm:$false
```

### 3.3 Suppression d'une OU

Les OUs sont protégées par défaut. Pour supprimer une OU, vous devez d'abord désactiver cette protection :

```powershell
# Désactiver la protection contre la suppression
Set-ADOrganizationalUnit -Identity "OU=Département IT,DC=mondomaine,DC=local" `
                         -ProtectedFromAccidentalDeletion $false

# Supprimer l'OU
Remove-ADOrganizationalUnit -Identity "OU=Département IT,DC=mondomaine,DC=local" `
                           -Confirm:$false
```

### 3.4 Suppression récursive

Pour supprimer une OU et tout son contenu de manière récursive :

```powershell
# Fonction pour supprimer récursivement une OU et son contenu
function Remove-ADOURecursive {
    param (
        [Parameter(Mandatory=$true)]
        [string]$OUPath
    )

    # Désactiver la protection sur l'OU et ses enfants
    Get-ADOrganizationalUnit -Filter * -SearchBase $OUPath |
        Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion $false

    # Supprimer les sous-OUs récursivement
    Get-ADOrganizationalUnit -Filter * -SearchBase $OUPath -SearchScope OneLevel |
        ForEach-Object {
            Remove-ADOURecursive -OUPath $_.DistinguishedName
        }

    # Supprimer tous les objets non-OU dans l'OU actuelle
    Get-ADObject -Filter {ObjectClass -ne 'organizationalUnit'} -SearchBase $OUPath |
        Remove-ADObject -Recursive -Confirm:$false

    # Supprimer l'OU elle-même
    Remove-ADOrganizationalUnit -Identity $OUPath -Confirm:$false
}

# Exemple d'utilisation
# Remove-ADOURecursive -OUPath "OU=Temporaire,DC=mondomaine,DC=local"
```

> ⚠️ **Attention** : Cette fonction supprime définitivement des données. Utilisez-la avec précaution.

## 4. Bonnes pratiques

### 4.1 Utiliser -WhatIf pour vérifier les modifications

Le paramètre `-WhatIf` simule l'exécution sans appliquer les modifications :

```powershell
# Vérifier ce qui serait fait sans l'exécuter
Remove-ADUser -Identity "jdupont" -WhatIf
```

### 4.2 Sauvegarde avant modification

Exportez l'état actuel d'un objet avant de le modifier :

```powershell
# Sauvegarde d'un utilisateur avant modifications
Get-ADUser -Identity "jdupont" -Properties * |
    Export-Clixml -Path "C:\Backup\jdupont_$(Get-Date -Format 'yyyyMMdd').xml"
```

### 4.3 Utiliser des scripts paramétrés

Pour la création en masse, utilisez des paramètres et CSV :

```powershell
# Exemple de script pour créer des utilisateurs à partir d'un CSV
function New-ADUsersFromCSV {
    param (
        [Parameter(Mandatory=$true)]
        [string]$CSVPath
    )

    $users = Import-Csv -Path $CSVPath

    foreach ($user in $users) {
        $securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force

        New-ADUser -Name $user.Name `
                  -GivenName $user.FirstName `
                  -Surname $user.LastName `
                  -SamAccountName $user.Username `
                  -UserPrincipalName "$($user.Username)@mondomaine.local" `
                  -Path $user.OUPath `
                  -AccountPassword $securePassword `
                  -Enabled $true

        Write-Host "Utilisateur $($user.Name) créé avec succès" -ForegroundColor Green
    }
}

# Format attendu du CSV:
# Name,FirstName,LastName,Username,Password,OUPath
# "Jean Dupont","Jean","Dupont","jdupont","P@ssw0rd123","OU=Utilisateurs,DC=mondomaine,DC=local"
```

## Conclusion

Vous savez maintenant comment créer, modifier et supprimer les principaux objets Active Directory avec PowerShell. Ces compétences sont essentielles pour l'administration efficace d'un domaine Windows.

Pour aller plus loin, explorez les cmdlets suivantes :
- `Get-Command -Module ActiveDirectory` : liste toutes les commandes AD
- `Get-Help New-ADUser -Full` : documentation détaillée des cmdlets
- `Get-ADObject` : recherche générique d'objets AD

---

## Exercices pratiques

1. Créez un utilisateur nommé "Pierre Martin" dans l'OU "Stagiaires"
2. Ajoutez cet utilisateur au groupe "Lecteurs PDF"
3. Modifiez son titre en "Stagiaire Marketing"
4. Déplacez l'utilisateur vers l'OU "Marketing"
5. Créez un script qui désactive tous les comptes utilisateurs qui n'ont pas été utilisés depuis plus de 90 jours
