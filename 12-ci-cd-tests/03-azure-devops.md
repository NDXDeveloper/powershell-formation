# Module 13-3 : Scripts PowerShell dans les pipelines (Azure DevOps, GitHub Actions)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📘 Introduction

Dans le monde DevOps moderne, les pipelines d'intégration et de déploiement continus (CI/CD) sont essentiels pour automatiser le processus de développement logiciel. PowerShell, grâce à sa puissance et sa flexibilité, s'intègre parfaitement dans ces environnements. Dans cette section, nous allons découvrir comment utiliser des scripts PowerShell dans deux plateformes populaires : Azure DevOps et GitHub Actions.

## 🔍 Qu'est-ce qu'un pipeline CI/CD ?

Avant d'aller plus loin, clarifions quelques concepts :

- **CI (Intégration Continue)** : Processus qui consiste à intégrer fréquemment les modifications de code dans un dépôt partagé, suivi de tests automatisés.
- **CD (Déploiement Continu)** : Processus qui automatise le déploiement des applications dans différents environnements (dev, test, production).
- **Pipeline** : Série d'étapes automatisées qui permettent de transformer le code source en une application déployée.

## 🚀 PowerShell dans Azure DevOps

### Configuration de base

Azure DevOps utilise des fichiers YAML pour définir les pipelines. Voici comment intégrer un script PowerShell :

```yaml
# azure-pipelines.yml
trigger:
- main  # Déclencher le pipeline lorsque des modifications sont faites sur la branche main

pool:
  vmImage: 'windows-latest'  # Utiliser une image Windows

steps:
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      Write-Host "Bonjour depuis PowerShell dans Azure DevOps!"
      $date = Get-Date -Format "dd/MM/yyyy HH:mm"
      Write-Host "La date actuelle est : $date"
```

### Étapes pour créer un pipeline Azure DevOps avec PowerShell :

1. **Connectez-vous** à votre compte Azure DevOps
2. **Sélectionnez votre projet**
3. **Allez dans Pipelines** > **Créer un pipeline**
4. **Choisissez l'emplacement de votre code** (GitHub, Azure Repos, etc.)
5. **Sélectionnez le dépôt** contenant votre code
6. **Configurez votre pipeline** (utilisez l'exemple ci-dessus comme point de départ)
7. **Enregistrez et exécutez** votre pipeline

### Exécuter un script PowerShell externe

Si vous avez un script PowerShell stocké dans votre dépôt, vous pouvez l'exécuter ainsi :

```yaml
steps:
- task: PowerShell@2
  inputs:
    filePath: './scripts/mon-script.ps1'
    arguments: '-Param1 "Valeur1" -Param2 "Valeur2"'
```

## 🌟 PowerShell dans GitHub Actions

GitHub Actions est la solution de CI/CD intégrée à GitHub. Voici comment utiliser PowerShell :

### Configuration de base

```yaml
# .github/workflows/main.yml
name: PowerShell Demo

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v2

    - name: Exécuter PowerShell
      shell: pwsh
      run: |
        Write-Host "Bonjour depuis GitHub Actions!"
        $env:COMPUTERNAME
        Get-Process | Select-Object -First 5
```

### Étapes pour créer un workflow GitHub Actions avec PowerShell :

1. **Accédez à votre dépôt** sur GitHub
2. **Cliquez sur l'onglet "Actions"**
3. **Cliquez sur "New workflow"**
4. **Choisissez "set up a workflow yourself"**
5. **Collez le code YAML** de l'exemple ci-dessus
6. **Cliquez sur "Commit new file"**

### Variables d'environnement et secrets

Pour accéder aux variables d'environnement dans PowerShell :

```yaml
jobs:
  build:
    runs-on: windows-latest
    env:
      MA_VARIABLE: "Valeur de ma variable"

    steps:
    - name: Utiliser des variables
      shell: pwsh
      run: |
        Write-Host "Variable d'environnement : $env:MA_VARIABLE"
        # Pour accéder à un secret
        Write-Host "Secret : $env:MY_SECRET"
      env:
        MY_SECRET: ${{ secrets.MON_SECRET }}
```

## 🧰 Bonnes pratiques pour les scripts PowerShell dans les pipelines

1. **Gestion des erreurs** : Utilisez `$ErrorActionPreference = 'Stop'` pour que votre script s'arrête à la première erreur.

   ```powershell
   $ErrorActionPreference = 'Stop'
   try {
       # Votre code ici
   }
   catch {
       Write-Error "Une erreur s'est produite : $_"
       exit 1  # Code d'erreur pour indiquer un échec
   }
   ```

2. **Sortie propre** : Utilisez les niveaux de sortie appropriés pour faciliter le débogage.

   ```powershell
   Write-Host "Information générale"  # Visible dans la console
   Write-Verbose "Information détaillée" -Verbose  # Pour le débogage
   Write-Warning "Attention !"  # Pour les avertissements
   ```

3. **Paramétrage** : Rendez vos scripts configurables via des paramètres.

   ```powershell
   param(
       [string]$Environnement = "Dev",
       [string]$Version = "1.0.0"
   )

   Write-Host "Déploiement de la version $Version dans l'environnement $Environnement"
   ```

4. **Modularité** : Divisez les tâches complexes en fonctions réutilisables.

## 🔄 Exemples concrets

### Exemple 1 : Vérification de la qualité du code

```yaml
# Dans Azure DevOps ou GitHub Actions
steps:
- task: PowerShell@2
  inputs:
    targetType: 'inline'
    script: |
      $modules = @("PSScriptAnalyzer")
      foreach ($module in $modules) {
          if (-not (Get-Module -ListAvailable -Name $module)) {
              Install-Module -Name $module -Force -Scope CurrentUser
          }
      }

      $results = Invoke-ScriptAnalyzer -Path ".\scripts\" -Recurse
      if ($results) {
          $results | Format-Table -AutoSize
          Write-Error "Des problèmes ont été détectés dans le code. Veuillez les corriger."
          exit 1
      } else {
          Write-Host "Aucun problème détecté dans le code. Bien joué !"
      }
```

### Exemple 2 : Déploiement vers différents environnements

```yaml
# Dans Azure DevOps
stages:
- stage: Dev
  jobs:
  - job: Deploy
    steps:
    - task: PowerShell@2
      inputs:
        filePath: './scripts/deploy.ps1'
        arguments: '-Environnement "Dev"'

- stage: Prod
  dependsOn: Dev
  condition: succeeded()
  jobs:
  - job: Deploy
    steps:
    - task: PowerShell@2
      inputs:
        filePath: './scripts/deploy.ps1'
        arguments: '-Environnement "Production"'
```

## 📝 Exercice pratique

Créez un pipeline simple qui :
1. Vérifie la syntaxe de vos scripts PowerShell
2. Exécute un test unitaire basique
3. Génère un rapport sur les résultats

### Solution :

```yaml
# .github/workflows/test-powershell.yml
name: Test PowerShell Scripts

on:
  push:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest

    steps:
    - uses: actions/checkout@v2

    - name: Installer les modules requis
      shell: pwsh
      run: |
        Install-Module -Name PSScriptAnalyzer, Pester -Force -Scope CurrentUser

    - name: Vérifier la syntaxe
      shell: pwsh
      run: |
        $results = Invoke-ScriptAnalyzer -Path "." -Recurse
        $results | Format-Table -AutoSize
        if ($results.Severity -contains "Error") {
          Write-Error "Des erreurs de syntaxe ont été trouvées"
          exit 1
        }

    - name: Exécuter les tests unitaires
      shell: pwsh
      run: |
        $testResults = Invoke-Pester -Path "./tests" -PassThru
        if ($testResults.FailedCount -gt 0) {
          Write-Error "Des tests ont échoué"
          exit 1
        }

    - name: Générer un rapport
      shell: pwsh
      run: |
        $report = @{
          TotalScripts = (Get-ChildItem -Path "." -Filter "*.ps1" -Recurse).Count
          PassedTests = $testResults.PassedCount
          FailedTests = $testResults.FailedCount
          TotalTests = $testResults.TotalCount
        }

        $report | ConvertTo-Json | Out-File -Path "./rapport.json"
```

## 🔗 Ressources supplémentaires

- [Documentation officielle Azure DevOps](https://docs.microsoft.com/en-us/azure/devops/pipelines/scripts/powershell?view=azure-devops)
- [Documentation GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [PowerShell Gallery](https://www.powershellgallery.com/) pour trouver des modules utiles

## 🎯 À retenir

- PowerShell est un outil puissant pour l'automatisation dans les pipelines CI/CD
- Azure DevOps et GitHub Actions offrent une excellente prise en charge de PowerShell
- Structurez vos scripts pour qu'ils soient réutilisables et maintenables
- Pensez à la gestion des erreurs et à la sortie
- Utilisez des modules comme PSScriptAnalyzer pour garantir la qualité de votre code

Dans le prochain module, nous explorerons comment effectuer des tests unitaires avancés avec Pester pour vos scripts PowerShell.

⏭️ [Linting et validation automatique](/12-ci-cd-tests/04-linting.md)
