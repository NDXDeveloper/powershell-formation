# Module 5 - Gestion des fichiers et du système
## 5-3. Gestion des permissions NTFS

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

La gestion des permissions NTFS est une compétence essentielle pour tout administrateur système Windows. Avec PowerShell, vous pouvez automatiser ces tâches répétitives et potentiellement fastidieuses. Dans cette section, nous verrons comment visualiser, comprendre et modifier les permissions NTFS des fichiers et dossiers.

### 🔑 Comprendre les permissions NTFS

#### Qu'est-ce que NTFS?

NTFS (New Technology File System) est le système de fichiers moderne de Windows qui permet un contrôle précis des accès aux fichiers et dossiers.

#### Différence entre partage et permissions NTFS

- **Permissions de partage**: Contrôlent l'accès réseau aux dossiers partagés
- **Permissions NTFS**: Contrôlent l'accès au niveau du système de fichiers, qu'il s'agisse d'un accès local ou réseau

> 💡 Les permissions de partage et NTFS fonctionnent ensemble. La règle la plus restrictive l'emporte !

#### Types de permissions NTFS courantes

| Permission | Description |
|------------|-------------|
| Lecture | Afficher les fichiers et dossiers |
| Écriture | Créer de nouveaux fichiers et dossiers |
| Lecture et exécution | Lire et exécuter des programmes |
| Modification | Lire, écrire et supprimer |
| Contrôle total | Toutes les permissions, y compris la modification des autorisations |

### 🔍 Afficher les permissions NTFS

PowerShell utilise principalement la cmdlet `Get-Acl` pour accéder aux listes de contrôle d'accès (ACL).

#### Obtenir les permissions d'un fichier ou dossier

```powershell
# Afficher toutes les permissions d'un dossier
Get-Acl -Path C:\Documents | Format-List

# Afficher seulement les règles d'accès (plus lisible)
(Get-Acl -Path C:\Documents).Access
```

#### Format plus lisible pour les permissions

```powershell
Get-Acl -Path C:\Documents |
    Select-Object -ExpandProperty Access |
    Format-Table IdentityReference, FileSystemRights, AccessControlType, IsInherited
```

#### Exemple pratique : Vérifier les permissions d'un groupe de dossiers

```powershell
function Get-FolderPermission {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$FolderPath
    )

    process {
        $folder = Get-Item -Path $FolderPath -ErrorAction SilentlyContinue

        if (-not $folder) {
            Write-Warning "Le dossier n'existe pas: $FolderPath"
            return
        }

        $acl = Get-Acl -Path $folder.FullName

        [PSCustomObject]@{
            Dossier = $folder.FullName
            Propriétaire = $acl.Owner
            Permissions = $acl.Access | ForEach-Object {
                [PSCustomObject]@{
                    Utilisateur = $_.IdentityReference
                    Droits = $_.FileSystemRights
                    Type = $_.AccessControlType
                    Hérité = $_.IsInherited
                }
            }
        }
    }
}

# Exemple d'utilisation
$dossiers = @(
    "C:\Users\Public",
    "C:\Program Files",
    "C:\Temp"
)

$dossiers | Get-FolderPermission | ForEach-Object {
    Write-Host "Dossier: $($_.Dossier)" -ForegroundColor Cyan
    Write-Host "Propriétaire: $($_.Propriétaire)" -ForegroundColor Yellow
    Write-Host "Permissions:" -ForegroundColor Magenta

    $_.Permissions | Format-Table Utilisateur, Droits, Type, Hérité
    Write-Host "---------------------------------"
}
```

### ✏️ Modifier les permissions NTFS

Pour modifier les permissions, nous utilisons également `Set-Acl` et créons ou modifions des règles d'accès.

#### Copier les permissions d'un dossier à un autre

```powershell
# Obtenir l'ACL source
$aclSource = Get-Acl -Path C:\DossierSource

# Appliquer à la destination
Set-Acl -Path C:\DossierDestination -AclObject $aclSource
```

#### Ajouter une permission à un dossier

```powershell
# Étape 1: Obtenir l'ACL actuelle
$acl = Get-Acl -Path C:\Documents

# Étape 2: Créer une nouvelle règle
$permission = "DOMAIN\Utilisateur", "Modify", "Allow"
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission

# Étape 3: Ajouter la règle à l'ACL
$acl.AddAccessRule($accessRule)

# Étape 4: Appliquer l'ACL modifiée
$acl | Set-Acl -Path C:\Documents
```

#### Supprimer une permission

```powershell
# Obtenir l'ACL
$acl = Get-Acl -Path C:\Documents

# Trouver et supprimer la règle spécifique
$accessRuleToRemove = $acl.Access | Where-Object {
    $_.IdentityReference -eq "DOMAIN\Utilisateur" -and
    $_.FileSystemRights -eq "Modify" -and
    $_.AccessControlType -eq "Allow"
}

if ($accessRuleToRemove) {
    $acl.RemoveAccessRule($accessRuleToRemove)
    $acl | Set-Acl -Path C:\Documents
    Write-Host "Permission supprimée avec succès"
}
else {
    Write-Host "Permission non trouvée"
}
```

#### Remplacer toutes les permissions

```powershell
# Obtenir l'ACL
$acl = Get-Acl -Path C:\Documents

# Vider toutes les règles d'accès existantes
$acl.SetAccessRuleProtection($true, $false)  # Désactiver l'héritage et supprimer les règles héritées
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

# Ajouter de nouvelles règles
$accessRule1 = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "Allow")
$accessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrateurs", "FullControl", "Allow")
$accessRule3 = New-Object System.Security.AccessControl.FileSystemAccessRule("DOMAIN\Utilisateur", "Modify", "Allow")

$acl.AddAccessRule($accessRule1)
$acl.AddAccessRule($accessRule2)
$acl.AddAccessRule($accessRule3)

# Appliquer les changements
$acl | Set-Acl -Path C:\Documents
```

### 👥 Gestion des propriétaires

Le propriétaire d'un fichier ou dossier a toujours la possibilité de modifier les permissions.

#### Voir le propriétaire actuel

```powershell
(Get-Acl -Path C:\Documents).Owner
```

#### Changer le propriétaire

```powershell
# Obtenir l'ACL
$acl = Get-Acl -Path C:\Documents

# Définir le nouveau propriétaire
$utilisateur = New-Object System.Security.Principal.NTAccount("DOMAIN\NouveauPropriétaire")
$acl.SetOwner($utilisateur)

# Appliquer les changements
$acl | Set-Acl -Path C:\Documents
```

### 🔄 Héritage des permissions

L'héritage permet aux dossiers enfants d'hériter automatiquement des permissions des dossiers parents.

#### Vérifier si l'héritage est activé

```powershell
$acl = Get-Acl -Path C:\Documents
$acl.AreAccessRulesProtected  # Retourne $true si l'héritage est désactivé
```

#### Désactiver l'héritage et conserver les permissions héritées

```powershell
$acl = Get-Acl -Path C:\Documents
$acl.SetAccessRuleProtection($true, $true)  # $true = désactiver l'héritage, $true = conserver les règles héritées
$acl | Set-Acl -Path C:\Documents
```

#### Désactiver l'héritage et supprimer les permissions héritées

```powershell
$acl = Get-Acl -Path C:\Documents
$acl.SetAccessRuleProtection($true, $false)  # $true = désactiver l'héritage, $false = supprimer les règles héritées
$acl | Set-Acl -Path C:\Documents
```

#### Réactiver l'héritage

```powershell
$acl = Get-Acl -Path C:\Documents
$acl.SetAccessRuleProtection($false, $true)  # $false = activer l'héritage
$acl | Set-Acl -Path C:\Documents
```

### 🛠️ Scénarios pratiques

#### Exemple 1: Audit des permissions des partages

```powershell
function Get-SharePermission {
    param (
        [Parameter(Mandatory)]
        [string]$ShareName
    )

    # Trouver le chemin du partage
    $share = Get-WmiObject -Class Win32_Share -Filter "Name='$ShareName'"

    if (-not $share) {
        Write-Warning "Partage non trouvé: $ShareName"
        return
    }

    $sharePath = $share.Path

    # Récupérer les permissions
    $ntfsPermissions = Get-Acl -Path $sharePath |
        Select-Object -ExpandProperty Access |
        Select-Object IdentityReference, FileSystemRights, AccessControlType, IsInherited

    [PSCustomObject]@{
        Partage = $ShareName
        Chemin = $sharePath
        PermissionsNTFS = $ntfsPermissions
    }
}

# Utilisation
Get-SharePermission -ShareName "Partage1"
```

#### Exemple 2: Réinitialiser les permissions d'un dossier de projet

```powershell
function Reset-ProjectFolderPermissions {
    param (
        [Parameter(Mandatory)]
        [string]$ProjectPath,

        [Parameter(Mandatory)]
        [string]$ProjectOwner,

        [string[]]$TeamMembers
    )

    # Vérifier que le dossier existe
    if (-not (Test-Path -Path $ProjectPath -PathType Container)) {
        Write-Error "Le dossier du projet n'existe pas: $ProjectPath"
        return
    }

    # Obtenir l'ACL
    $acl = Get-Acl -Path $ProjectPath

    # Désactiver l'héritage et supprimer les règles héritées
    $acl.SetAccessRuleProtection($true, $false)

    # Ajouter les permissions de base
    $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrateurs", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule("SYSTEM", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
    $ownerRule = New-Object System.Security.AccessControl.FileSystemAccessRule($ProjectOwner, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")

    $acl.AddAccessRule($adminRule)
    $acl.AddAccessRule($systemRule)
    $acl.AddAccessRule($ownerRule)

    # Ajouter les membres de l'équipe avec accès Modification
    foreach ($member in $TeamMembers) {
        $memberRule = New-Object System.Security.AccessControl.FileSystemAccessRule($member, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($memberRule)
    }

    # Appliquer les changements
    try {
        $acl | Set-Acl -Path $ProjectPath
        Write-Host "Permissions réinitialisées avec succès pour: $ProjectPath" -ForegroundColor Green

        # Liste des permissions appliquées
        Write-Host "`nPermissions appliquées:" -ForegroundColor Cyan
        (Get-Acl -Path $ProjectPath).Access | Format-Table IdentityReference, FileSystemRights -AutoSize
    }
    catch {
        Write-Error "Erreur lors de l'application des permissions: $_"
    }
}

# Utilisation
Reset-ProjectFolderPermissions -ProjectPath "C:\Projets\NouveauProjet" `
                             -ProjectOwner "DOMAIN\ChefProjet" `
                             -TeamMembers @("DOMAIN\Equipe1", "DOMAIN\Equipe2")
```

### 💪 Exercice pratique

Créez un script qui:
1. Recherche tous les fichiers `.log` dans un dossier spécifié
2. Vérifie si le groupe "Utilisateurs" a accès en lecture à ces fichiers
3. Génère un rapport détaillant les fichiers qui doivent être corrigés
4. (Bonus) Ajoute automatiquement la permission de lecture pour le groupe "Utilisateurs" aux fichiers qui en ont besoin

### 🎓 Solution de l'exercice

```powershell
function Test-LogFilesPermissions {
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [switch]$FixPermissions
    )

    # Vérifier si le dossier existe
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier spécifié n'existe pas: $FolderPath"
        return
    }

    # Rechercher tous les fichiers .log
    $logFiles = Get-ChildItem -Path $FolderPath -Filter *.log -Recurse -File

    Write-Host "Trouvé $($logFiles.Count) fichiers .log à analyser..." -ForegroundColor Cyan

    $results = @()
    $correctedFiles = 0

    foreach ($file in $logFiles) {
        $acl = Get-Acl -Path $file.FullName

        # Vérifier si "Utilisateurs" a accès en lecture
        $userAccess = $acl.Access | Where-Object {
            $_.IdentityReference -like "*\Utilisateurs" -or
            $_.IdentityReference -like "*\Users"
        }

        $hasReadAccess = $userAccess | Where-Object {
            $_.FileSystemRights -match "Read" -or
            $_.FileSystemRights -match "Lecture"
        }

        $needsFixing = ($hasReadAccess -eq $null)

        # Ajouter au rapport
        $results += [PSCustomObject]@{
            Fichier = $file.FullName
            PermissionOK = -not $needsFixing
            Propriétaire = $acl.Owner
        }

        # Corriger les permissions si demandé
        if ($needsFixing -and $FixPermissions) {
            try {
                # Créer une règle pour l'accès en lecture
                $userReadRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "Utilisateurs",    # ou "Users" selon la langue du système
                    "Read",
                    "Allow"
                )

                # Ajouter la règle et appliquer
                $acl.AddAccessRule($userReadRule)
                $acl | Set-Acl -Path $file.FullName

                $correctedFiles++
                $results[-1].PermissionOK = $true  # Mettre à jour le résultat
            }
            catch {
                Write-Warning "Erreur lors de la correction des permissions pour: $($file.FullName)"
                Write-Warning $_.Exception.Message
            }
        }
    }

    # Rapport
    Write-Host "`nRÉSULTATS DE L'ANALYSE:" -ForegroundColor Green
    Write-Host "Total de fichiers .log: $($logFiles.Count)" -ForegroundColor Cyan
    Write-Host "Fichiers avec permissions correctes: $(($results | Where-Object { $_.PermissionOK }).Count)" -ForegroundColor Green
    Write-Host "Fichiers nécessitant correction: $(($results | Where-Object { -not $_.PermissionOK }).Count)" -ForegroundColor Yellow

    if ($FixPermissions) {
        Write-Host "Fichiers corrigés: $correctedFiles" -ForegroundColor Magenta
    }

    # Afficher les fichiers qui doivent encore être corrigés
    $filesToFix = $results | Where-Object { -not $_.PermissionOK }

    if ($filesToFix.Count -gt 0) {
        Write-Host "`nFichiers nécessitant encore une correction:" -ForegroundColor Yellow
        $filesToFix | Format-Table -AutoSize
    }

    return $results
}

# Utilisation
$rapport = Test-LogFilesPermissions -FolderPath "C:\Logs" -FixPermissions
```

### 🔑 Points clés à retenir

- `Get-Acl` et `Set-Acl` sont les cmdlets principales pour gérer les permissions NTFS
- Les permissions NTFS s'appliquent indépendamment des permissions de partage
- Les objets ACL contiennent toutes les informations sur les permissions
- L'héritage permet d'appliquer automatiquement les permissions aux sous-dossiers
- Pour ajouter une permission, créez une règle d'accès et utilisez `AddAccessRule()`
- Pour supprimer une permission, trouvez la règle existante et utilisez `RemoveAccessRule()`
- Le propriétaire d'un fichier peut toujours en modifier les permissions

### 🔮 Pour aller plus loin

Dans la prochaine section, nous découvrirons comment compresser, archiver et extraire des fichiers pour optimiser l'espace disque et faciliter le partage de données.

---

💡 **Astuce de pro**: Utilisez `-Recurse` avec `Get-ChildItem` pour récupérer tous les fichiers d'un dossier et sous-dossiers, puis passez-les à un pipeline avec `ForEach-Object { Set-Acl ... }` pour appliquer les mêmes permissions à un grand nombre de fichiers en une seule opération.
