# Module 10 - Active Directory & LDAP
## 10-1. Module RSAT et importation (`Import-Module ActiveDirectory`)

### Introduction

L'administration Active Directory (AD) est l'une des tâches les plus courantes pour les administrateurs systèmes Windows. PowerShell facilite considérablement cette tâche grâce à des modules dédiés. Dans cette section, nous allons découvrir comment installer les outils nécessaires et comment importer le module Active Directory pour commencer à travailler avec votre annuaire.

### Qu'est-ce que RSAT ?

**RSAT** (Remote Server Administration Tools) est un ensemble d'outils Microsoft qui permet d'administrer des serveurs Windows à distance. Parmi ces outils, on trouve le module PowerShell pour l'administration d'Active Directory.

### Installation des outils RSAT

Avant de pouvoir utiliser les commandes PowerShell pour Active Directory, vous devez installer les outils RSAT sur votre poste de travail.

#### Pour Windows 10/11 :

1. Ouvrez le menu **Paramètres** (touche Windows + I)
2. Allez dans **Applications** > **Applications et fonctionnalités** > **Fonctionnalités facultatives**
3. Cliquez sur **Ajouter une fonctionnalité**
4. Recherchez "RSAT" et installez les composants suivants :
   - **Outils d'administration Active Directory DS**
   - **Module Active Directory pour Windows PowerShell**

#### Pour Windows Server :

1. Ouvrez le **Gestionnaire de serveur**
2. Cliquez sur **Ajouter des rôles et fonctionnalités**
3. Suivez l'assistant jusqu'à la page **Fonctionnalités**
4. Développez **Outils d'administration de serveur distant (RSAT)**
5. Développez **Outils d'administration de rôles**
6. Cochez **Outils AD DS et AD LDS** > **Module Active Directory pour Windows PowerShell**
7. Terminez l'installation en cliquant sur **Installer**

#### Alternative via PowerShell (administrateur) :

```powershell
# Pour installer tous les outils RSAT
Install-WindowsFeature RSAT-AD-PowerShell

# Ou spécifiquement pour Active Directory
Add-WindowsCapability -Online -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0
```

### Importation du module Active Directory

Une fois les outils RSAT installés, vous pouvez importer le module Active Directory pour commencer à utiliser les cmdlets de gestion AD.

```powershell
# Importer le module Active Directory
Import-Module ActiveDirectory
```

Pour vérifier que le module est bien chargé :

```powershell
# Afficher les modules chargés
Get-Module

# Ou directement vérifier le module AD
Get-Module -Name ActiveDirectory
```

### Découverte des cmdlets Active Directory

Pour explorer les commandes disponibles dans le module Active Directory :

```powershell
# Lister toutes les commandes du module
Get-Command -Module ActiveDirectory

# Voir les commandes liées aux utilisateurs
Get-Command -Module ActiveDirectory -Name "*user*"

# Afficher l'aide sur une commande spécifique
Get-Help Get-ADUser -Detailed
```

### Tester votre connexion à l'Active Directory

Pour vérifier que votre connexion à l'AD fonctionne, essayez une commande simple :

```powershell
# Récupérer les informations sur l'utilisateur actuellement connecté
Get-ADUser -Identity $env:USERNAME

# Ou récupérer un nombre limité d'utilisateurs
Get-ADUser -Filter * -ResultSetSize 5
```

### Conseils pour les débutants

- **Persistance du module** : Si vous utilisez fréquemment les cmdlets AD, vous pouvez ajouter la ligne `Import-Module ActiveDirectory` à votre profil PowerShell (`$PROFILE`) pour que le module soit automatiquement chargé à chaque démarrage de PowerShell.

- **Vérification des droits** : Assurez-vous d'avoir les droits d'administration suffisants sur l'Active Directory pour exécuter certaines commandes.

- **Utilisation de l'aide** : N'hésitez pas à consulter l'aide avec `Get-Help` pour comprendre les paramètres et options disponibles.

### Dépannage courant

| Problème | Solution |
|----------|----------|
| "Le terme 'Import-Module' n'est pas reconnu" | Vérifiez votre version de PowerShell avec `$PSVersionTable` |
| "Impossible de charger le module ActiveDirectory" | Vérifiez que RSAT est correctement installé |
| "Accès refusé" lors des commandes AD | Vérifiez vos permissions ou exécutez PowerShell en administrateur |

### Dans la prochaine section...

Maintenant que vous savez comment importer et accéder au module Active Directory, nous verrons comment effectuer des requêtes pour récupérer des informations sur les utilisateurs, les groupes et les ordinateurs dans votre domaine.

---

#### Exercice pratique

1. Installez les outils RSAT sur votre poste de travail
2. Importez le module Active Directory
3. Listez 10 utilisateurs de votre domaine avec la commande `Get-ADUser`
4. Utilisez `Get-Help` pour explorer la commande `Get-ADComputer`
