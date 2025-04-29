# Module 13-4 : Linting et validation automatique en PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📘 Introduction

Le linting et la validation automatique sont des pratiques essentielles pour garantir la qualité de votre code PowerShell. Ces outils vous aident à identifier les erreurs, maintenir un style cohérent et suivre les bonnes pratiques avant même d'exécuter votre code.

## 🔍 Qu'est-ce que le linting ?

Le **linting** est un processus d'analyse statique du code qui identifie les problèmes potentiels comme :
- Les erreurs de syntaxe
- Les mauvaises pratiques de codage
- Les problèmes de style et de formatage
- Les risques de sécurité

C'est comme avoir un relecteur automatique qui vérifie votre code en temps réel !

## 🛠️ PSScriptAnalyzer : L'outil de linting pour PowerShell

**PSScriptAnalyzer** est l'outil de linting officiel pour PowerShell. Il est développé par Microsoft et permet de vérifier votre code selon les bonnes pratiques.

### Installation de PSScriptAnalyzer

```powershell
# Installation depuis la PowerShell Gallery
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

### Utilisation basique

```powershell
# Analyser un fichier script
Invoke-ScriptAnalyzer -Path .\MonScript.ps1

# Analyser tous les scripts d'un dossier
Invoke-ScriptAnalyzer -Path .\MesFonctions\ -Recurse
```

### Comprendre les résultats

PSScriptAnalyzer renvoie des résultats classés par sévérité :
- **Error** : Problèmes critiques qui doivent être corrigés
- **Warning** : Pratiques déconseillées ou risquées
- **Information** : Suggestions d'amélioration

Exemple de résultat :
```
RuleName                            Severity     Line  Message
--------                            --------     ----  -------
PSAvoidUsingCmdletAliases           Warning      12    'gci' is an alias of 'Get-ChildItem'. Alias can introduce confusion...
PSUseDeclaredVarsMoreThanAssignment Information  25    Variable 'maVariable' is declared but not used.
```

## 🔧 Personnaliser les règles

Vous pouvez sélectionner les règles que vous souhaitez appliquer :

```powershell
# N'appliquer que certaines règles
Invoke-ScriptAnalyzer -Path .\MonScript.ps1 -IncludeRule PSAvoidUsingCmdletAliases, PSUseSingularNouns

# Exclure certaines règles
Invoke-ScriptAnalyzer -Path .\MonScript.ps1 -ExcludeRule PSAvoidUsingWriteHost
```

### Créer un fichier de configuration

Créez un fichier `.psd1` pour définir vos règles personnalisées :

```powershell
# MesRegles.psd1
@{
    # Règles à inclure/exclure
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSUseSingularNouns'
    )

    # Règles à personnaliser
    Rules = @{
        PSAvoidUsingCmdletAliases = @{
            # Autoriser certains alias courants
            AllowedAliases = @('foreach', 'where')
        }
    }
}
```

Puis utilisez-le :

```powershell
Invoke-ScriptAnalyzer -Path .\MonScript.ps1 -Settings .\MesRegles.psd1
```

## 🔄 Intégration avec VS Code

Visual Studio Code peut intégrer PSScriptAnalyzer pour analyser votre code en temps réel :

1. Installez l'extension **PowerShell** pour VS Code
2. La validation est activée par défaut
3. Les problèmes s'affichent avec des soulignements ondulés et dans le panneau "Problèmes"

Pour personnaliser les règles dans VS Code, ajoutez dans vos paramètres :

```json
"powershell.scriptAnalysis.settingsPath": "C:\\Chemin\\vers\\MesRegles.psd1"
```

## 🚀 Validation automatique dans les pipelines CI/CD

Intégrez PSScriptAnalyzer dans vos pipelines CI/CD pour valider automatiquement votre code :

### Exemple pour Azure DevOps

```yaml
steps:
- task: PowerShell@2
  displayName: 'Analyser le code PowerShell'
  inputs:
    targetType: 'inline'
    script: |
      Install-Module -Name PSScriptAnalyzer -Force
      $results = Invoke-ScriptAnalyzer -Path $(Build.SourcesDirectory) -Recurse -Settings PSScriptAnalyzerSettings.psd1
      $errors = $results | Where-Object { $_.Severity -eq 'Error' }

      if ($errors) {
        Write-Error "Des erreurs ont été détectées par PSScriptAnalyzer"
        $errors | Format-Table -AutoSize
        exit 1
      }
```

### Exemple pour GitHub Actions

```yaml
name: PowerShell Linting
on: [push, pull_request]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Analyser le code PowerShell
        shell: pwsh
        run: |
          Install-Module -Name PSScriptAnalyzer -Force
          $results = Invoke-ScriptAnalyzer -Path ./ -Recurse
          $errors = $results | Where-Object { $_.Severity -eq 'Error' }

          if ($errors) {
            Write-Error "Des erreurs ont été détectées par PSScriptAnalyzer"
            $errors | Format-Table -AutoSize
            exit 1
          }
```

## 👨‍💻 Exercice pratique

1. Créez un script PowerShell simple avec quelques erreurs intentionnelles
2. Installez PSScriptAnalyzer
3. Analysez votre script et corrigez les problèmes identifiés
4. Créez un fichier de configuration personnalisé

```powershell
# Script avec des erreurs pour l'exercice (MonExercice.ps1)
function Get-Infos {
    param($computeurs)  # Faute d'orthographe intentionnelle

    # Utilisation d'alias
    gci $computeurs | % {
        # Variable non utilisée
        $resultat = "Données"

        # Utilisation de Write-Host
        Write-Host "Ordinateur: $_"
    }
}

# Fonction avec nom au pluriel
function Get-Users {
    # Code...
}
```

## 📑 Règles courantes à connaître

| Règle | Description | Exemple de correction |
|-------|-------------|----------------------|
| `PSAvoidUsingCmdletAliases` | Éviter les alias de cmdlets | Remplacer `gci` par `Get-ChildItem` |
| `PSUseSingularNouns` | Utiliser des noms au singulier | Renommer `Get-Users` en `Get-User` |
| `PSAvoidUsingWriteHost` | Éviter `Write-Host` | Utiliser `Write-Output` ou `Write-Verbose` |
| `PSUseDeclaredVarsMoreThanAssignment` | Variables déclarées mais non utilisées | Utiliser la variable ou la supprimer |
| `PSAvoidGlobalVars` | Éviter les variables globales | Utiliser des paramètres de fonction |

## 🎯 Conseils pour débutants

- Commencez par corriger les erreurs, puis les avertissements
- N'hésitez pas à désactiver certaines règles si elles ne correspondent pas à vos besoins
- Utilisez VS Code pour voir les problèmes en temps réel
- Intégrez progressivement le linting dans votre workflow

## 🔗 Ressources supplémentaires

- [Documentation officielle de PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- [Guide des bonnes pratiques PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)
- [Style Guide PowerShell](https://poshcode.gitbook.io/powershell-practice-and-style/)

---

Dans le prochain module, nous découvrirons comment publier vos modules PowerShell sur la PowerShell Gallery !

⏭️ [Publication de modules (PSGallery)](/12-ci-cd-tests/05-publishing-modules.md)
