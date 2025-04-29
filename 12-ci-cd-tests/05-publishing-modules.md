# Module 13 : Tests, CI/CD et DevOps
## 13-5. Publication de modules (PSGallery)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

La **PowerShell Gallery** (PSGallery) est le dépôt officiel de modules PowerShell, comparable à npm pour JavaScript ou PyPI pour Python. Publier votre module sur la PSGallery permet de le partager facilement avec la communauté et facilite son installation via la commande `Install-Module`.

### 🎯 Objectifs

- Comprendre ce qu'est la PowerShell Gallery
- Préparer votre module pour la publication
- Créer un compte NuGet.org et obtenir une clé API
- Publier votre module sur PSGallery
- Mettre à jour votre module existant

### 🔍 Prérequis

- Un module PowerShell fonctionnel avec un manifeste (fichier `.psd1`)
- PowerShellGet installé (installé par défaut depuis PowerShell 5)
- Une connexion Internet

---

### 📦 Qu'est-ce que la PowerShell Gallery ?

La PowerShell Gallery est le référentiel central pour le partage de modules, scripts et ressources PowerShell. Elle permet à n'importe qui de :

- Découvrir des modules PowerShell utiles
- Télécharger et installer ces modules facilement
- Partager ses propres créations avec la communauté

Pour un utilisateur, l'installation d'un module depuis la PSGallery est aussi simple que :

```powershell
Install-Module -Name NomDuModule
```

### 📝 Préparation de votre module

Avant de publier, assurez-vous que votre module est bien structuré :

1. **Structure de fichiers recommandée** :
   ```
   MonModule/
   ├── MonModule.psm1     # Code principal du module
   ├── MonModule.psd1     # Manifeste du module
   ├── Public/            # Fonctions exportées
   ├── Private/           # Fonctions internes
   ├── README.md          # Documentation
   └── LICENSE            # Licence
   ```

2. **Créer un manifeste complet** :

   Si vous n'avez pas encore de manifeste, générez-en un :
   ```powershell
   New-ModuleManifest -Path .\MonModule\MonModule.psd1 -RootModule MonModule.psm1 -Author "Votre Nom" -Description "Description du module" -PowerShellVersion 5.1
   ```

3. **Renseignez les champs importants** du manifeste :

   Éditez votre fichier `.psd1` pour inclure :
   ```powershell
   @{
       # Informations de base
       RootModule           = 'MonModule.psm1'
       ModuleVersion        = '1.0.0'               # Utilisez le versioning sémantique
       GUID                 = 'Nouveau-GUID'        # Générez avec [guid]::NewGuid()
       Author               = 'Votre Nom'
       Description          = 'Description concise et claire'

       # Informations utiles pour la PSGallery
       PowerShellVersion    = '5.1'                 # Version minimale requise
       FunctionsToExport    = @('Fonction1', 'Fonction2')
       CmdletsToExport      = @()
       PrivateData          = @{
           PSData = @{
               Tags         = @('tag1', 'tag2')     # Mots-clés pour la recherche
               LicenseUri   = 'https://github.com/votre-repo/LICENSE'
               ProjectUri   = 'https://github.com/votre-repo'
               ReleaseNotes = 'Notes de version'
           }
       }
   }
   ```

### 🔑 Création d'un compte et obtention d'une clé API

1. **Créez un compte** sur [PowerShell Gallery](https://www.powershellgallery.com/)
   - Inscrivez-vous en utilisant un compte Microsoft

2. **Obtenez votre clé API** :
   - Connectez-vous à votre compte PowerShell Gallery
   - Cliquez sur votre nom d'utilisateur puis "API Keys"
   - Créez une nouvelle clé avec les permissions appropriées

3. **Sécurisez votre clé API** :
   - Ne partagez jamais votre clé API
   - Vous pouvez la stocker temporairement dans une variable :
   ```powershell
   $apiKey = "votre-clé-api-très-longue"
   ```

### 📤 Publication de votre module

1. **Testez votre module localement** :
   ```powershell
   # Importez votre module pour vérifier qu'il fonctionne correctement
   Import-Module .\MonModule -Force -Verbose
   Get-Command -Module MonModule
   ```

2. **Vérifiez que le manifeste est valide** :
   ```powershell
   Test-ModuleManifest -Path .\MonModule\MonModule.psd1
   ```

3. **Publiez sur PSGallery** :
   ```powershell
   Publish-Module -Path .\MonModule -NuGetApiKey $apiKey -Verbose
   ```

4. **Vérifiez votre publication** :
   - Visitez [PowerShell Gallery](https://www.powershellgallery.com/) et recherchez votre module
   - Essayez de l'installer depuis un autre ordinateur :
   ```powershell
   Install-Module -Name MonModule -Verbose
   ```

### 🔄 Mise à jour de votre module

Lorsque vous souhaitez publier une mise à jour :

1. **Modifiez la version** dans le manifeste :
   ```powershell
   # Ouvrez le fichier .psd1 et modifiez :
   ModuleVersion = '1.0.1'  # Incrémentez selon les principes du versioning sémantique
   ```

2. **Ajoutez des notes de version** :
   ```powershell
   # Dans la section PSData du fichier .psd1
   ReleaseNotes = 'Correction de bugs et amélioration des performances'
   ```

3. **Publiez la nouvelle version** :
   ```powershell
   Publish-Module -Path .\MonModule -NuGetApiKey $apiKey -Verbose
   ```

### 💡 Bonnes pratiques

- **Documentation** : Incluez un README.md et des exemples d'utilisation
- **Versioning sémantique** : Utilisez X.Y.Z (Majeur.Mineur.Correctif)
- **Tests** : Incluez des tests Pester pour votre module
- **Licence** : Spécifiez clairement une licence (MIT, GPL, etc.)
- **Continuité** : Maintenez votre module et répondez aux problèmes signalés

### 🚫 Erreurs courantes

- **Version déjà publiée** : Vous ne pouvez pas republier une version existante
- **Manifeste incomplet** : Assurez-vous que tous les champs requis sont remplis
- **Fonctions non exportées** : Vérifiez que `FunctionsToExport` liste correctement vos fonctions
- **Dépendances non déclarées** : Spécifiez les modules requis dans `RequiredModules`

### 🔄 Vérification de l'installation

Pour tester si votre module s'installe correctement :

```powershell
# Supprimer le module s'il existe déjà
if (Get-Module -Name MonModule) { Remove-Module MonModule }
if (Get-InstalledModule -Name MonModule -ErrorAction SilentlyContinue) {
    Uninstall-Module MonModule -Force
}

# Installer le module depuis la galerie
Install-Module -Name MonModule -Force

# Vérifier qu'il fonctionne
Import-Module MonModule
Get-Command -Module MonModule
```

---

### 📚 Ressources supplémentaires

- [Documentation officielle de la PowerShell Gallery](https://docs.microsoft.com/en-us/powershell/scripting/gallery/overview)
- [Guide sur la création de modules PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/writing-a-windows-powershell-module)
- [Versioning sémantique](https://semver.org/lang/fr/)

---

### 🧪 Exercice pratique

1. Créez un petit module simple avec une ou deux fonctions
2. Générez un manifeste de module pour celui-ci
3. Remplissez les champs requis du manifeste
4. Publiez-le sur PowerShell Gallery (ou simulez la publication en utilisant `-WhatIf`)

```powershell
# Exemple pour simuler la publication
Publish-Module -Path .\MonModule -NuGetApiKey $apiKey -WhatIf
```

---

N'oubliez pas : la publication sur la PSGallery est une excellente façon de contribuer à la communauté PowerShell et de faire connaître votre travail !

⏭️ [Module 14 – Performance et optimisation](/13-optimisation/README.md)
