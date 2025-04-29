# Module 9-5: Gestion des utilisateurs et groupes locaux avec PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

La gestion des utilisateurs et des groupes locaux est une tâche administrative courante que PowerShell peut grandement simplifier. Dans cette section, nous allons découvrir comment PowerShell vous permet de créer, modifier, supprimer et interroger les comptes utilisateurs et les groupes sur une machine locale.

## Prérequis
- PowerShell 5.1 ou PowerShell 7+
- Droits d'administrateur sur votre machine

## Les modules utilisés

PowerShell utilise principalement deux modules pour gérer les utilisateurs et groupes locaux :

1. **Microsoft.PowerShell.LocalAccounts** (PowerShell 5.1+)
2. **CIM/WMI** (méthode alternative fonctionnant sur toutes les versions)

## Vérifier si le module LocalAccounts est disponible

```powershell
# Vérifier si le module est disponible
Get-Module -Name Microsoft.PowerShell.LocalAccounts -ListAvailable

# Importer le module si nécessaire
Import-Module -Name Microsoft.PowerShell.LocalAccounts
```

## 1. Gestion des utilisateurs locaux

### Lister tous les utilisateurs locaux

```powershell
# Avec le module LocalAccounts
Get-LocalUser

# Alternative avec WMI
Get-WmiObject -Class Win32_UserAccount -Filter "LocalAccount=True"
# Ou avec CIM (recommandé)
Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount=True"
```

### Obtenir des informations sur un utilisateur spécifique

```powershell
# Par nom d'utilisateur
Get-LocalUser -Name "JohnDoe"

# Afficher les utilisateurs actifs
Get-LocalUser | Where-Object {$_.Enabled -eq $true}

# Afficher les utilisateurs désactivés
Get-LocalUser | Where-Object {$_.Enabled -eq $false}
```

### Créer un nouvel utilisateur local

```powershell
# Méthode simple
$Password = Read-Host -AsSecureString -Prompt "Entrez le mot de passe"
New-LocalUser -Name "NouvelUtilisateur" -Password $Password -FullName "Nouvel Utilisateur" -Description "Description du compte"

# Option: Créer un utilisateur qui doit changer son mot de passe à la prochaine connexion
New-LocalUser -Name "Temporaire" -Password $Password -PasswordNeverExpires:$false -UserMayNotChangePassword:$false -AccountNeverExpires:$true -PasswordChangeRequired:$true
```

### Modifier un utilisateur existant

```powershell
# Changer la description
Set-LocalUser -Name "NouvelUtilisateur" -Description "Nouvelle description"

# Désactiver un compte
Disable-LocalUser -Name "NouvelUtilisateur"

# Réactiver un compte
Enable-LocalUser -Name "NouvelUtilisateur"

# Changer le mot de passe
$NouveauPassword = Read-Host -AsSecureString -Prompt "Entrez le nouveau mot de passe"
Set-LocalUser -Name "NouvelUtilisateur" -Password $NouveauPassword
```

### Supprimer un utilisateur

```powershell
# Supprimer un utilisateur
Remove-LocalUser -Name "NouvelUtilisateur"

# Avec confirmation
Remove-LocalUser -Name "NouvelUtilisateur" -Confirm
```

## 2. Gestion des groupes locaux

### Lister tous les groupes locaux

```powershell
# Avec le module LocalAccounts
Get-LocalGroup

# Alternative avec WMI
Get-WmiObject -Class Win32_Group -Filter "LocalAccount=True"
```

### Obtenir des informations sur un groupe spécifique

```powershell
# Récupérer un groupe par son nom
Get-LocalGroup -Name "Administrateurs"
```

### Créer un nouveau groupe local

```powershell
# Créer un groupe simple
New-LocalGroup -Name "ServiceDesk" -Description "Équipe du service d'assistance"
```

### Modifier un groupe

```powershell
# Changer la description d'un groupe
Set-LocalGroup -Name "ServiceDesk" -Description "Nouvelle description"
```

### Supprimer un groupe

```powershell
# Supprimer un groupe
Remove-LocalGroup -Name "ServiceDesk"
```

## 3. Gestion des membres de groupes

### Lister les membres d'un groupe

```powershell
# Afficher tous les membres d'un groupe
Get-LocalGroupMember -Name "Administrateurs"

# Filtrer par type de membre (utilisateur ou groupe)
Get-LocalGroupMember -Name "Administrateurs" | Where-Object {$_.ObjectClass -eq "User"}
```

### Ajouter un utilisateur à un groupe

```powershell
# Ajouter un utilisateur local à un groupe
Add-LocalGroupMember -Group "ServiceDesk" -Member "NouvelUtilisateur"

# Ajouter plusieurs utilisateurs en même temps
Add-LocalGroupMember -Group "ServiceDesk" -Member "Utilisateur1", "Utilisateur2"
```

### Supprimer un utilisateur d'un groupe

```powershell
# Retirer un utilisateur d'un groupe
Remove-LocalGroupMember -Group "ServiceDesk" -Member "NouvelUtilisateur"
```

## 4. Cas pratiques et exemples

### Exemple 1: Créer un utilisateur et l'ajouter à un groupe

```powershell
# Création d'un utilisateur avec mot de passe
$MdP = ConvertTo-SecureString "MotDePasse123!" -AsPlainText -Force
New-LocalUser -Name "TechSupport" -Password $MdP -FullName "Support Technique" -Description "Compte pour le support technique" -AccountNeverExpires

# Création d'un groupe s'il n'existe pas
if (-not (Get-LocalGroup -Name "Support" -ErrorAction SilentlyContinue)) {
    New-LocalGroup -Name "Support" -Description "Groupe de support technique"
}

# Ajout de l'utilisateur au groupe
Add-LocalGroupMember -Group "Support" -Member "TechSupport"

Write-Host "L'utilisateur TechSupport a été créé et ajouté au groupe Support" -ForegroundColor Green
```

### Exemple 2: Audit des comptes - Trouver les utilisateurs inactifs

```powershell
# Cette fonction nécessite l'accès aux événements de sécurité
function Get-LastLogon {
    param (
        [string]$Username
    )

    $user = Get-LocalUser -Name $Username
    $sid = $user.SID

    # Recherche dans les journaux d'événements de connexion
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4624  # Événement de connexion réussie
    } -MaxEvents 1000 -ErrorAction SilentlyContinue

    $lastLogin = $events | Where-Object {$_.Properties[4].Value -eq $Username} | Select-Object -First 1

    if ($lastLogin) {
        return $lastLogin.TimeCreated
    } else {
        return "Aucune connexion récente trouvée"
    }
}

# Exemple d'utilisation
$utilisateurs = Get-LocalUser | Where-Object {$_.Enabled -eq $true}
$rapport = foreach ($user in $utilisateurs) {
    [PSCustomObject]@{
        Nom = $user.Name
        CompletName = $user.FullName
        Enabled = $user.Enabled
        LastLogon = Get-LastLogon -Username $user.Name
    }
}

$rapport | Format-Table -AutoSize
```

### Exemple 3: Supprimer tous les utilisateurs d'un groupe

```powershell
# Supprimer tous les membres d'un groupe spécifique
function Clear-GroupMembers {
    param (
        [Parameter(Mandatory=$true)]
        [string]$GroupName
    )

    try {
        $membres = Get-LocalGroupMember -Name $GroupName -ErrorAction Stop

        foreach ($membre in $membres) {
            Write-Host "Suppression de $($membre.Name) du groupe $GroupName..."
            Remove-LocalGroupMember -Group $GroupName -Member $membre.Name -ErrorAction Stop
        }

        Write-Host "Tous les membres ont été supprimés du groupe $GroupName" -ForegroundColor Green
    }
    catch {
        Write-Error "Erreur: $_"
    }
}

# Utilisation
# Clear-GroupMembers -GroupName "Support"
```

## Bonnes pratiques

1. **Sécurité des mots de passe** : Toujours utiliser `Read-Host -AsSecureString` ou `ConvertTo-SecureString` pour manipuler les mots de passe.

2. **Gestion des erreurs** : Utilisez toujours des blocs `try/catch` pour gérer les erreurs potentielles, surtout lors de modifications critiques des comptes.

3. **Journalisation** : Documentez vos actions, surtout lors de modifications en masse.

4. **Confirmation** : Pour les opérations destructives, utilisez `-Confirm` ou `-WhatIf` pour éviter les erreurs.

5. **Privilèges** : N'oubliez pas que ces opérations nécessitent des droits d'administrateur.

## Résolution des problèmes courants

| Problème | Solution |
|----------|----------|
| "Accès refusé" | Vérifiez que vous exécutez PowerShell en tant qu'administrateur |
| Module manquant | `Install-Module -Name Microsoft.PowerShell.LocalAccounts` ou utilisez les cmdlets WMI/CIM |
| Utilisateur non trouvé | Vérifiez l'orthographe du nom et utilisez `-ErrorAction SilentlyContinue` |
| Compte verrouillé | `Unlock-LocalUser -Name "Utilisateur"` |

## Conclusion

PowerShell offre des outils puissants pour gérer les utilisateurs et groupes locaux, vous permettant d'automatiser des tâches qui seraient fastidieuses manuellement. Ces commandes peuvent être utilisées individuellement ou combinées dans des scripts pour gérer efficacement votre environnement Windows.

## Exercices pratiques

1. Créez un script qui crée 5 utilisateurs avec des mots de passe aléatoires et les ajoute à un nouveau groupe.
2. Écrivez une fonction qui vérifie si un utilisateur est membre d'un groupe spécifique.
3. Créez un rapport de tous les utilisateurs locaux avec leur état (activé/désactivé) et leur appartenance aux groupes.

---

**Astuce** : Pour les environnements d'entreprise avec plusieurs machines, envisagez d'utiliser les cmdlets PowerShell pour Active Directory (Module 10) plutôt que de gérer les utilisateurs locaux machine par machine.

⏭️ [Module 10 – Active Directory & LDAP](/09-active-directory/README.md)
