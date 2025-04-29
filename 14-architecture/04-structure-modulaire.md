# Module 15 - Architecture & design de scripts pro

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 15-4. Structuration modulaire avancée

La structuration modulaire est une approche essentielle pour créer des projets PowerShell maintenables et évolutifs. Dans cette section, nous allons découvrir comment organiser votre code de manière professionnelle, même pour les projets complexes.

### Qu'est-ce que la structuration modulaire avancée?

La structuration modulaire avancée consiste à organiser votre code PowerShell en composants distincts et réutilisables, chacun ayant une responsabilité spécifique. Cette approche facilite la maintenance, les tests et le partage de votre code.

### Structure de répertoires recommandée

Voici une structure de répertoires efficace pour un module PowerShell professionnel:

```
MonModule/
│
├── MonModule.psm1          # Point d'entrée principal du module
├── MonModule.psd1          # Manifeste du module
│
├── Public/                 # Fonctions exportées (accessibles aux utilisateurs)
│   ├── Get-MaFonction.ps1
│   ├── Set-MaFonction.ps1
│   └── ...
│
├── Private/                # Fonctions internes (non exportées)
│   ├── Helper1.ps1
│   ├── Helper2.ps1
│   └── ...
│
├── Classes/                # Définitions de classes PowerShell (PS 5+)
│   ├── MaClasse1.ps1
│   └── MaClasse2.ps1
│
├── Configs/                # Fichiers de configuration
│   ├── default.json
│   └── settings.psd1
│
├── Tests/                  # Tests Pester
│   ├── Public
│   │   └── Get-MaFonction.Tests.ps1
│   └── Private
│       └── Helper1.Tests.ps1
│
└── docs/                   # Documentation
    ├── README.md
    ├── CHANGELOG.md
    └── examples/
        └── Exemple1.ps1
```

### Le fichier .psm1 principal

Voici un exemple de fichier `.psm1` qui charge automatiquement toutes les fonctions:

```powershell
# MonModule.psm1

# Charger les classes (doivent être chargées avant les fonctions)
$ClassesPath = Join-Path -Path $PSScriptRoot -ChildPath 'Classes'
if (Test-Path -Path $ClassesPath) {
    $Classes = Get-ChildItem -Path $ClassesPath -Filter '*.ps1' -Recurse
    foreach ($Class in $Classes) {
        Write-Verbose "Chargement de la classe: $($Class.FullName)"
        . $Class.FullName
    }
}

# Charger les fonctions privées
$PrivatePath = Join-Path -Path $PSScriptRoot -ChildPath 'Private'
if (Test-Path -Path $PrivatePath) {
    $PrivateFunctions = Get-ChildItem -Path $PrivatePath -Filter '*.ps1' -Recurse
    foreach ($Function in $PrivateFunctions) {
        Write-Verbose "Chargement de la fonction privée: $($Function.FullName)"
        . $Function.FullName
    }
}

# Charger les fonctions publiques et les exporter
$PublicPath = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
if (Test-Path -Path $PublicPath) {
    $PublicFunctions = Get-ChildItem -Path $PublicPath -Filter '*.ps1' -Recurse

    # Charger chaque fonction
    foreach ($Function in $PublicFunctions) {
        Write-Verbose "Chargement de la fonction publique: $($Function.FullName)"
        . $Function.FullName
    }

    # Exporter les fonctions pour qu'elles soient disponibles aux utilisateurs
    Export-ModuleMember -Function $PublicFunctions.BaseName
}
```

### Création du manifeste de module (.psd1)

Le manifeste de module contient les métadonnées de votre module. Créez-le avec:

```powershell
New-ModuleManifest -Path ".\MonModule\MonModule.psd1" `
                   -RootModule "MonModule.psm1" `
                   -ModuleVersion "1.0.0" `
                   -Author "Votre Nom" `
                   -Description "Description de votre module" `
                   -PowerShellVersion "5.1" `
                   -FunctionsToExport @('*') `
                   -CmdletsToExport @() `
                   -VariablesToExport @() `
                   -AliasesToExport @()
```

> **Astuce**: Remplacez `FunctionsToExport @('*')` par la liste exacte de vos fonctions publiques pour une meilleure pratique.

### Avantages de la structuration modulaire avancée

1. **Organisation claire**: Séparation des responsabilités et meilleure lisibilité du code
2. **Maintenabilité**: Plus facile à déboguer et à mettre à jour
3. **Testabilité**: Structure adaptée aux tests unitaires avec Pester
4. **Réutilisabilité**: Fonctions modulaires utilisables dans différents contextes
5. **Meilleure collaboration**: Plusieurs développeurs peuvent travailler sur différentes parties du module
6. **Facilité de distribution**: Structure prête pour la publication sur PowerShell Gallery

### Les fichiers de fonctions

Chaque fonction doit être placée dans son propre fichier .ps1, avec le même nom que la fonction:

```powershell
# Public/Get-MaFonction.ps1
function Get-MaFonction {
    <#
    .SYNOPSIS
        Description courte de la fonction
    .DESCRIPTION
        Description détaillée de la fonction
    .PARAMETER Param1
        Description du paramètre 1
    .EXAMPLE
        Get-MaFonction -Param1 "Valeur"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Param1
    )

    begin {
        # Code exécuté une fois au début
    }

    process {
        # Code exécuté pour chaque élément du pipeline
        Write-Verbose "Traitement de $Param1"

        # Appel à une fonction privée
        $resultat = Invoke-HelperPrivate -Input $Param1

        # Retourner le résultat
        return $resultat
    }

    end {
        # Code exécuté une fois à la fin
    }
}
```

### Chargement et utilisation de votre module

1. **Installation locale pour les tests**:
   ```powershell
   # Copier votre module dans un des dossiers de $env:PSModulePath
   $moduleDir = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\MonModule"
   Copy-Item -Path ".\MonModule" -Destination $moduleDir -Recurse -Force
   ```

2. **Importation du module**:
   ```powershell
   Import-Module MonModule -Force -Verbose
   ```

3. **Utilisation des fonctions**:
   ```powershell
   Get-MaFonction -Param1 "Test"
   ```

### Bonnes pratiques

1. **Un fichier par fonction**: Facilite la maintenance et le suivi des modifications
2. **Documentation intégrée**: Utilisez l'aide PowerShell pour documenter chaque fonction
3. **Préfixes cohérents**: Utilisez des verbes approuvés par PowerShell (Get-, Set-, New-, etc.)
4. **Gestion des dépendances**: Documentez et vérifiez les modules requis
5. **Gestion des versions**: Suivez la gestion sémantique des versions (MAJOR.MINOR.PATCH)
6. **Tests unitaires**: Créez des tests pour chaque fonction publique
7. **Logging**: Utilisez Write-Verbose, Write-Debug et Write-Error de manière cohérente

### Exemple concret: Module de gestion des logs

Imaginons un petit module pour gérer les logs:

```powershell
# Private/Format-LogMessage.ps1
function Format-LogMessage {
    param (
        [string]$Message,
        [string]$Level,
        [string]$Source
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    return "[$timestamp] [$Level] [$Source] - $Message"
}
```

```powershell
# Public/Write-Log.ps1
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR', 'DEBUG')]
        [string]$Level = 'INFO',

        [Parameter()]
        [string]$LogPath = "$env:TEMP\PowerShell.log",

        [Parameter()]
        [string]$Source = 'PowerShell'
    )

    process {
        # Utiliser notre fonction privée
        $formattedMessage = Format-LogMessage -Message $Message -Level $Level -Source $Source

        # Ajouter au fichier log
        Add-Content -Path $LogPath -Value $formattedMessage

        # Afficher en console avec couleur selon le niveau
        switch ($Level) {
            'ERROR'   { Write-Host $formattedMessage -ForegroundColor Red }
            'WARNING' { Write-Host $formattedMessage -ForegroundColor Yellow }
            'INFO'    { Write-Host $formattedMessage -ForegroundColor Green }
            'DEBUG'   { Write-Host $formattedMessage -ForegroundColor Gray }
        }
    }
}
```

### Conclusion

La structuration modulaire avancée transforme vos scripts PowerShell en véritables projets professionnels. En adoptant ces pratiques, vous créerez du code plus robuste, plus facile à maintenir et prêt pour le partage avec la communauté.

N'oubliez pas que même les projets complexes commencent simplement - vous pouvez débuter avec une structure basique (juste les dossiers Public et Private) et l'étendre au fur et à mesure que votre module grandit.

### Exercice pratique

1. Créez un module simple avec la structure décrite ci-dessus
2. Ajoutez deux fonctions publiques et une fonction privée helper
3. Créez un manifeste de module
4. Testez le chargement et l'utilisation de votre module

---

📚 **Ressources supplémentaires:**
- [PowerShell Gallery](https://www.powershellgallery.com/) - Pour explorer d'autres modules bien structurés
- [Plaster](https://github.com/PowerShellOrg/Plaster) - Un générateur de templates pour créer des structures de modules
- [BuildHelpers](https://github.com/RamblingCookieMonster/BuildHelpers) - Un module pour aider à la création de modules PowerShell
