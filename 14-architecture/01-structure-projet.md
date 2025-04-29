# Module 15 - Architecture & design de scripts pro
## 15-1. Organisation de projets PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Bienvenue dans cette partie consacrée à l'organisation des projets PowerShell ! Que vous soyez débutant ou que vous commenciez à accumuler des scripts, structurer correctement vos projets est essentiel pour maintenir votre code sur le long terme.

### Pourquoi organiser vos projets PowerShell ?

Lorsque vous débutez avec PowerShell, vous commencez généralement par écrire quelques scripts simples (`.ps1`). Au fil du temps, ces scripts deviennent plus nombreux et plus complexes. Une bonne organisation vous permettra de :

- **Retrouver facilement** vos scripts et fonctions
- **Réutiliser votre code** sans duplication
- **Partager votre travail** avec d'autres personnes
- **Maintenir et faire évoluer** vos scripts plus facilement
- **Tester** individuellement chaque composant

### Structure de base d'un projet PowerShell

Voici une structure de répertoires recommandée pour un projet PowerShell bien organisé :

```
MonProjet/
│
├── src/                    # Code source principal
│   ├── Public/             # Fonctions exportées (accessibles aux utilisateurs)
│   ├── Private/            # Fonctions internes (non exportées)
│   └── Classes/            # Classes PowerShell (si utilisées)
│
├── tests/                  # Tests unitaires (Pester)
│
├── docs/                   # Documentation
│
├── examples/               # Exemples d'utilisation
│
├── output/                 # Dossier pour les fichiers générés
│
├── MonProjet.psd1          # Manifeste du module (métadonnées)
├── MonProjet.psm1          # Module principal
├── README.md               # Description du projet
└── CHANGELOG.md            # Historique des modifications
```

> 💡 **Conseil pour débutants** : Ne vous sentez pas obligé d'utiliser cette structure complète dès le début. Commencez simplement avec un dossier contenant vos scripts, puis évoluez progressivement vers cette organisation.

### Les fichiers clés

#### 1. Le fichier de module (`.psm1`)

Le fichier `.psm1` est le cœur de votre module. Il charge toutes vos fonctions et les expose aux utilisateurs. Voici un exemple simple :

```powershell
# MonProjet.psm1

# Charger toutes les fonctions publiques
$publicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\src\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($function in $publicFunctions) {
    try {
        . $function.FullName
        Export-ModuleMember -Function $function.BaseName
    }
    catch {
        Write-Error "Échec du chargement de la fonction $($function.FullName): $_"
    }
}

# Charger toutes les fonctions privées (sans les exporter)
$privateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\src\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
    }
    catch {
        Write-Error "Échec du chargement de la fonction $($function.FullName): $_"
    }
}
```

#### 2. Le manifeste de module (`.psd1`)

Le fichier `.psd1` contient les métadonnées de votre module (version, auteur, dépendances, etc.). Vous pouvez en créer un facilement avec la commande :

```powershell
New-ModuleManifest -Path ".\MonProjet.psd1" -RootModule "MonProjet.psm1" -Author "Votre Nom" -Description "Description de votre module"
```

### Organisation des fonctions

#### Fonctions publiques vs privées

- **Fonctions publiques** (dossier `Public`) :
  - Accessibles aux utilisateurs de votre module
  - Une fonction par fichier, avec le même nom que le fichier
  - Bien documentées avec des commentaires d'aide

- **Fonctions privées** (dossier `Private`) :
  - Utilisées uniquement en interne par votre module
  - Utilitaires et helpers qui ne devraient pas être exposés

Exemple de fonction publique (`src/Public/Get-ProjectInfo.ps1`) :

```powershell
function Get-ProjectInfo {
    <#
    .SYNOPSIS
        Récupère les informations sur un projet PowerShell.

    .DESCRIPTION
        Cette fonction analyse un dossier de projet PowerShell et retourne
        des informations structurées sur son contenu.

    .PARAMETER Path
        Chemin vers le dossier du projet à analyser.

    .EXAMPLE
        Get-ProjectInfo -Path "C:\MonProjet"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Votre code ici...
    # Utilisation possible de fonctions privées
    $stats = Get-ProjectStats -Path $Path

    return [PSCustomObject]@{
        Name = (Split-Path -Path $Path -Leaf)
        FileCount = $stats.FileCount
        FunctionCount = $stats.FunctionCount
        # ...
    }
}
```

### Comment démarrer un nouveau projet

1. **Créez la structure de base** :
   ```powershell
   # Créer la structure de dossiers
   $projectName = "MonProjet"
   New-Item -Path ".\$projectName" -ItemType Directory
   New-Item -Path ".\$projectName\src\Public" -ItemType Directory -Force
   New-Item -Path ".\$projectName\src\Private" -ItemType Directory -Force
   New-Item -Path ".\$projectName\tests" -ItemType Directory
   New-Item -Path ".\$projectName\docs" -ItemType Directory

   # Créer les fichiers principaux
   New-ModuleManifest -Path ".\$projectName\$projectName.psd1" -RootModule "$projectName.psm1" -Author "Votre Nom"
   New-Item -Path ".\$projectName\$projectName.psm1" -ItemType File
   New-Item -Path ".\$projectName\README.md" -ItemType File
   ```

2. **Ajoutez votre code** en le répartissant entre fonctions publiques et privées

3. **Testez votre module** en l'important avec `Import-Module` :
   ```powershell
   Import-Module .\MonProjet -Force
   Get-Command -Module MonProjet  # Liste les commandes disponibles
   ```

### Bonnes pratiques pour l'organisation

1. **Un fichier = une fonction** : Plus facile à maintenir et à suivre dans un système de contrôle de version comme Git

2. **Nommage cohérent** :
   - Utilisez le format PascalCase pour les noms de fonctions
   - Suivez le modèle Verbe-Nom pour les cmdlets (ex: `Get-ProjectInfo`)
   - Nommez vos fichiers comme vos fonctions

3. **Séparation des préoccupations** :
   - Gardez les fonctions courtes et avec un objectif unique
   - Séparez l'interface utilisateur (affichage) de la logique métier

4. **Documentation** :
   - Documentez chaque fonction publique avec des commentaires d'aide
   - Maintenez un README.md à jour expliquant l'utilisation de votre module

5. **Évolutivité** :
   - Concevez votre structure pour pouvoir grandir avec votre projet
   - Ajoutez des tests unitaires dès que possible

### Pour les projets plus avancés

À mesure que votre projet évolue, vous pourriez envisager d'ajouter :

- Un fichier `build.ps1` pour automatiser la création et les tests
- Un système de gestion des versions
- Une intégration avec des outils CI/CD (comme GitHub Actions)
- Des scripts d'installation

### Conclusion

Une bonne organisation de projet n'est pas seulement une question d'esthétique ou de perfectionnisme. C'est un investissement qui vous fera gagner du temps et des frustrations à long terme.

Commencez simple, puis faites évoluer votre structure au fur et à mesure que votre projet grandit. L'important est de rester cohérent et de documenter vos choix pour que d'autres (ou vous-même dans six mois) puissiez comprendre facilement l'organisation de votre code.

---

**Exercice pratique** : Prenez un de vos scripts existants et transformez-le en un projet organisé selon la structure présentée ci-dessus. Identifiez quelles parties devraient être des fonctions publiques et lesquelles devraient rester privées.

**⏭️ Prochaine section** : [15-2. Séparation logique (orchestration vs logique métier)]


