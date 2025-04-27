# Module 6 : Fonctions, modules et structuration
## 6-3. Scripts, modules (`.ps1`, `.psm1`), manifestes

Après avoir appris à créer des fonctions avec des paramètres validés, il est temps d'organiser votre code PowerShell de manière professionnelle. Dans cette section, nous allons explorer les différentes façons de structurer votre code pour le rendre réutilisable, maintenable et partageable.

### Les scripts PowerShell (`.ps1`)

Un script PowerShell est simplement un fichier texte avec l'extension `.ps1` qui contient une série de commandes PowerShell. C'est le format de base pour enregistrer et exécuter du code PowerShell.

#### Créer votre premier script

1. Ouvrez un éditeur de texte (Notepad, VS Code, etc.)
2. Écrivez quelques commandes PowerShell
3. Enregistrez le fichier avec l'extension `.ps1`

Exemple de script simple `Bonjour.ps1` :

```powershell
# Mon premier script PowerShell
$nom = Read-Host "Entrez votre nom"
Write-Output "Bonjour $nom ! Bienvenue dans le monde des scripts PowerShell."
Get-Date -Format "Le démarrage a eu lieu le dd/MM/yyyy à HH:mm:ss"
```

#### Exécuter un script

Il existe plusieurs façons d'exécuter un script PowerShell :

1. **Chemin complet** :
   ```powershell
   C:\Chemin\Vers\MonScript.ps1
   ```

2. **Chemin relatif** (si vous êtes dans le même dossier) :
   ```powershell
   .\MonScript.ps1
   ```

3. **Avec l'appel explicite** :
   ```powershell
   & "C:\Chemin avec espaces\MonScript.ps1"
   ```

> 📌 **Note** : Si c'est la première fois que vous exécutez des scripts PowerShell, vous pourriez rencontrer une erreur de sécurité. Par défaut, Windows empêche l'exécution de scripts non signés. Pour autoriser l'exécution de scripts locaux, vous pouvez modifier la politique d'exécution :
> ```powershell
> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

### Les modules PowerShell (`.psm1`)

Un module est un ensemble de fonctions, variables et autres éléments PowerShell regroupés dans un package réutilisable. Les modules permettent de mieux organiser et partager du code.

#### Différence entre `.ps1` et `.psm1`

| Script (.ps1) | Module (.psm1) |
|---------------|----------------|
| Exécute directement une série de commandes | Contient des fonctions à importer et utiliser |
| S'exécute dans le scope actuel | S'exécute dans son propre scope |
| Ne permet pas naturellement d'exporter des fonctions | Permet d'exporter des fonctions spécifiques |
| Utilisé pour les tâches et automatisations | Utilisé pour la réutilisation et le partage de code |

#### Créer un module simple

1. Créez un fichier avec l'extension `.psm1` (par exemple, `MonModule.psm1`)
2. Ajoutez vos fonctions dans ce fichier
3. Utilisez `Export-ModuleMember` pour spécifier quelles fonctions seront visibles

Exemple de module simple `UtilitairesFichiers.psm1` :

```powershell
# Module d'utilitaires pour les fichiers

function Get-TailleDossier {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Chemin
    )

    $taille = (Get-ChildItem -Path $Chemin -Recurse -File | Measure-Object -Property Length -Sum).Sum

    # Convertir en MB pour plus de lisibilité
    $tailleMB = [Math]::Round($taille / 1MB, 2)

    [PSCustomObject]@{
        Dossier = $Chemin
        TailleMB = $tailleMB
    }
}

function New-DossierDatee {
    param (
        [string]$CheminParent = (Get-Location),
        [string]$Prefixe = "Backup"
    )

    $date = Get-Date -Format "yyyy-MM-dd"
    $nomDossier = "$Prefixe-$date"
    $cheminComplet = Join-Path -Path $CheminParent -ChildPath $nomDossier

    New-Item -Path $cheminComplet -ItemType Directory
}

# Fonction interne (privée) qui ne sera pas exportée
function Convertir-OctetsEnFormat {
    param (
        [long]$Octets
    )

    if ($Octets -lt 1KB) { return "$Octets octets" }
    elseif ($Octets -lt 1MB) { return "{0:N2} KB" -f ($Octets / 1KB) }
    elseif ($Octets -lt 1GB) { return "{0:N2} MB" -f ($Octets / 1MB) }
    else { return "{0:N2} GB" -f ($Octets / 1GB) }
}

# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function Get-TailleDossier, New-DossierDatee
```

#### Utiliser un module

Pour utiliser un module, vous devez d'abord l'importer avec `Import-Module` :

```powershell
# Importer un module par son chemin
Import-Module -Path "C:\MesModules\UtilitairesFichiers.psm1"

# Maintenant vous pouvez utiliser les fonctions exportées
Get-TailleDossier -Chemin "C:\Documents"
New-DossierDatee -Prefixe "Archive"
```

#### Structure de dossier d'un module

Pour les modules plus avancés, il est recommandé de suivre une structure standard :

```
MonModule/
│
├── MonModule.psm1          # Fichier principal du module
├── MonModule.psd1          # Manifeste du module (optionnel mais recommandé)
│
├── Public/                 # Dossier pour les fonctions publiques
│   ├── Get-MaFonction1.ps1
│   └── Set-MaFonction2.ps1
│
├── Private/                # Dossier pour les fonctions privées (internes)
│   ├── ConvertTo-Format.ps1
│   └── Validate-Input.ps1
│
└── Data/                   # Dossier pour les données (optionnel)
    └── Config.xml
```

Avec cette structure, votre fichier `.psm1` principal pourrait ressembler à ceci :

```powershell
# Importer toutes les fonctions privées
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" | ForEach-Object {
    . $_.FullName
}

# Importer toutes les fonctions publiques
$fonctionsPubliques = @()
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
    . $_.FullName
    $fonctionsPubliques += $_.BaseName
}

# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function $fonctionsPubliques
```

### Les manifestes de module (`.psd1`)

Un manifeste de module est un fichier qui décrit un module PowerShell. Il contient des métadonnées comme la version, l'auteur, les dépendances et les fonctions exportées. Les manifestes sont essentiels pour les modules professionnels et le partage.

#### Créer un manifeste

Le moyen le plus simple de créer un manifeste est d'utiliser la commande `New-ModuleManifest` :

```powershell
New-ModuleManifest -Path "C:\MesModules\MonModule\MonModule.psd1" `
                   -RootModule "MonModule.psm1" `
                   -Author "Votre Nom" `
                   -Description "Description de mon module" `
                   -ModuleVersion "1.0.0" `
                   -FunctionsToExport "Get-TailleDossier", "New-DossierDatee"
```

#### Exemple de fichier manifeste

Voici à quoi ressemble un fichier manifeste `.psd1` :

```powershell
@{
    # Version du module
    ModuleVersion = '1.0.0'

    # Identifiant unique de ce module
    GUID = '12345678-abcd-1234-efgh-1234567890ab'

    # Auteur de ce module
    Author = 'Votre Nom'

    # Description de la fonctionnalité fournie par ce module
    Description = 'Module avec des utilitaires pour la gestion de fichiers'

    # Fichier de module à charger en premier (*.psm1)
    RootModule = 'UtilitairesFichiers.psm1'

    # Fonctions à exporter depuis ce module
    FunctionsToExport = @('Get-TailleDossier', 'New-DossierDatee')

    # Cmdlets à exporter depuis ce module
    CmdletsToExport = @()

    # Variables à exporter depuis ce module
    VariablesToExport = @()

    # Alias à exporter depuis ce module
    AliasesToExport = @()

    # Modules requis par ce module
    RequiredModules = @()
}
```

#### Avantages d'utiliser un manifeste

- Définit clairement la version de votre module
- Spécifie les dépendances
- Permet de contrôler ce qui est exporté
- Ajoute des métadonnées utiles (auteur, description, etc.)
- Nécessaire pour publier sur la PowerShell Gallery

### Emplacement des modules

PowerShell recherche les modules dans plusieurs dossiers. Pour voir ces emplacements :

```powershell
$env:PSModulePath -split ";"
```

Les emplacements courants sont :

1. **Modules personnels** : `$HOME\Documents\PowerShell\Modules`
2. **Modules système** : `$PSHOME\Modules`
3. **Modules pour tous les utilisateurs** : `C:\Program Files\PowerShell\Modules`

Pour installer votre module, placez son dossier dans l'un de ces emplacements.

### Découvrir les modules

Voici quelques commandes utiles pour explorer les modules :

```powershell
# Lister tous les modules disponibles
Get-Module -ListAvailable

# Lister les modules actuellement importés
Get-Module

# Voir les commandes disponibles dans un module
Get-Command -Module NomDuModule

# Obtenir de l'aide sur un module
Get-Help NomDuModule
```

### Exemples pratiques

#### Exemple 1 : Script de sauvegarde simple

```powershell
# Sauvegarde.ps1
param(
    [string]$SourceFolder,
    [string]$DestinationFolder
)

# Créer le dossier de destination s'il n'existe pas
if (-not (Test-Path -Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory
}

# Copier les fichiers
$date = Get-Date -Format "yyyy-MM-dd_HHmmss"
$destinationWithDate = Join-Path -Path $DestinationFolder -ChildPath "Backup_$date"

Copy-Item -Path $SourceFolder -Destination $destinationWithDate -Recurse

Write-Output "Sauvegarde terminée dans : $destinationWithDate"
```

#### Exemple 2 : Module avec fonctions et manifeste

Structure du module :
```
MesOutils/
├── MesOutils.psm1
├── MesOutils.psd1
├── Public/
│   ├── Get-DiskInfo.ps1
│   └── Test-Connection.ps1
└── Private/
    └── Format-Size.ps1
```

`Public/Get-DiskInfo.ps1` :
```powershell
function Get-DiskInfo {
    [CmdletBinding()]
    param()

    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"

    foreach ($disk in $disks) {
        $used = $disk.Size - $disk.FreeSpace
        $usedPercent = [Math]::Round(($used / $disk.Size) * 100, 1)

        [PSCustomObject]@{
            Drive = $disk.DeviceID
            Label = $disk.VolumeName
            SizeGB = [Math]::Round($disk.Size / 1GB, 1)
            FreeGB = [Math]::Round($disk.FreeSpace / 1GB, 1)
            UsedPercent = $usedPercent
            Status = if ($usedPercent -gt 90) { "Critique" }
                    elseif ($usedPercent -gt 70) { "Attention" }
                    else { "OK" }
        }
    }
}
```

### 🔄 Exercices pratiques

1. **Exercice de base** : Créez un script `.ps1` qui liste tous les fichiers d'un dossier spécifié en paramètre.

2. **Exercice intermédiaire** : Convertissez vos fonctions de l'exercice précédent en un module `.psm1` simple.

3. **Exercice avancé** : Créez un module complet avec structure de dossiers, manifeste et au moins trois fonctions.

### 🌟 Bonnes pratiques

- Utilisez des noms significatifs pour vos scripts et modules
- Documentez vos scripts avec des commentaires
- Structurez les modules complexes avec des dossiers Public/Private
- Créez toujours un manifeste pour les modules que vous partagez
- Versionnez vos modules (Majeur.Mineur.Patch)
- Testez vos modules dans un nouvel environnement avant de les distribuer

Dans la prochaine section, nous explorerons la portée des variables et les différents niveaux de scope en PowerShell.
