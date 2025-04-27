# Solution de l'exercice pratique - PowerShell dans les pipelines

## Objectif de l'exercice

Créer un pipeline simple qui :
1. Vérifie la syntaxe de vos scripts PowerShell
2. Exécute un test unitaire basique
3. Génère un rapport sur les résultats

## Solution complète

Cette solution comprend trois fichiers principaux :
1. Le fichier de workflow GitHub Actions
2. Un script PowerShell à tester
3. Un test unitaire Pester

### 1. Fichier de workflow GitHub Actions - `.github/workflows/test-powershell.yml`

```yaml
name: Test PowerShell Scripts

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: windows-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v3

    - name: Installer les modules requis
      shell: pwsh
      run: |
        Set-PSRepository PSGallery -InstallationPolicy Trusted
        Install-Module -Name PSScriptAnalyzer, Pester -Force -Scope CurrentUser -SkipPublisherCheck

    - name: Vérifier la syntaxe
      shell: pwsh
      run: |
        $ErrorActionPreference = 'Stop'
        $results = Invoke-ScriptAnalyzer -Path "./scripts" -Recurse -ExcludeRule PSAvoidUsingWriteHost

        if ($results) {
          $results | Format-Table -AutoSize
          $errorCount = ($results | Where-Object { $_.Severity -eq 'Error' }).Count

          if ($errorCount -gt 0) {
            Write-Error "❌ $errorCount erreurs de syntaxe ont été trouvées"
            exit 1
          } else {
            Write-Host "⚠️ Des avertissements ont été trouvés, mais aucune erreur critique"
          }
        } else {
          Write-Host "✅ Aucun problème de syntaxe détecté!"
        }

    - name: Exécuter les tests unitaires
      shell: pwsh
      run: |
        $ErrorActionPreference = 'Stop'
        $config = New-PesterConfiguration
        $config.Run.Path = "./tests"
        $config.Output.Verbosity = "Detailed"

        $testResults = Invoke-Pester -Configuration $config -PassThru

        if ($testResults.FailedCount -gt 0) {
          Write-Error "❌ $($testResults.FailedCount) tests ont échoué sur $($testResults.TotalCount) tests"
          exit 1
        } else {
          Write-Host "✅ Tous les tests ($($testResults.PassedCount)/$($testResults.TotalCount)) ont réussi!"
        }

    - name: Générer un rapport
      shell: pwsh
      run: |
        $ErrorActionPreference = 'Stop'

        # Compter les scripts PowerShell
        $scriptCount = (Get-ChildItem -Path "./scripts" -Filter "*.ps1" -Recurse).Count

        # Récupérer les résultats d'analyse
        $analysisResults = Invoke-ScriptAnalyzer -Path "./scripts" -Recurse
        $errorCount = ($analysisResults | Where-Object { $_.Severity -eq 'Error' }).Count
        $warningCount = ($analysisResults | Where-Object { $_.Severity -eq 'Warning' }).Count
        $infoCount = ($analysisResults | Where-Object { $_.Severity -eq 'Information' }).Count

        # Récupérer les résultats des tests
        $config = New-PesterConfiguration
        $config.Run.Path = "./tests"
        $config.Output.Verbosity = "None"
        $testResults = Invoke-Pester -Configuration $config -PassThru

        # Créer le rapport
        $report = [PSCustomObject]@{
          Date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
          EnvironnementCI = "GitHub Actions"
          ScriptsAnalyses = $scriptCount
          ResultatsAnalyse = @{
            Erreurs = $errorCount
            Avertissements = $warningCount
            Informations = $infoCount
          }
          ResultatsTests = @{
            Total = $testResults.TotalCount
            Reussis = $testResults.PassedCount
            Echoues = $testResults.FailedCount
            Ignores = $testResults.SkippedCount
          }
          StatutGeneral = if ($errorCount -eq 0 -and $testResults.FailedCount -eq 0) { "SUCCÈS" } else { "ÉCHEC" }
        }

        # Créer le répertoire de rapports s'il n'existe pas
        if (-not (Test-Path -Path "./reports")) {
          New-Item -Path "./reports" -ItemType Directory | Out-Null
        }

        # Exporter en JSON
        $jsonReport = $report | ConvertTo-Json -Depth 3
        $jsonReport | Out-File -Path "./reports/rapport-qualite.json"
        Write-Host "📊 Rapport JSON généré : ./reports/rapport-qualite.json"

        # Exporter en Markdown
        $markdownReport = @"
# Rapport d'analyse et de tests - $(Get-Date -Format "yyyy-MM-dd")

## Informations générales
- **Date d'exécution :** $($report.Date)
- **Environnement CI :** $($report.EnvironnementCI)
- **Statut général :** $($report.StatutGeneral)

## Analyse de code
- **Scripts analysés :** $($report.ScriptsAnalyses)
- **Erreurs détectées :** $($report.ResultatsAnalyse.Erreurs)
- **Avertissements :** $($report.ResultatsAnalyse.Avertissements)
- **Informations :** $($report.ResultatsAnalyse.Informations)

## Tests unitaires
- **Tests totaux :** $($report.ResultatsTests.Total)
- **Tests réussis :** $($report.ResultatsTests.Reussis)
- **Tests échoués :** $($report.ResultatsTests.Echoues)
- **Tests ignorés :** $($report.ResultatsTests.Ignores)

## Résumé
$($report.StatutGeneral): $($report.ResultatsTests.Reussis)/$($report.ResultatsTests.Total) tests réussis avec $($report.ResultatsAnalyse.Erreurs) erreurs d'analyse.
"@

        $markdownReport | Out-File -Path "./reports/rapport-qualite.md"
        Write-Host "📄 Rapport Markdown généré : ./reports/rapport-qualite.md"

        # Afficher le résumé dans la console
        Write-Host "=== RÉSUMÉ DU RAPPORT ==="
        Write-Host "Scripts analysés: $($report.ScriptsAnalyses)"
        Write-Host "Analyse: $($report.ResultatsAnalyse.Erreurs) erreurs, $($report.ResultatsAnalyse.Avertissements) avertissements"
        Write-Host "Tests: $($report.ResultatsTests.Reussis)/$($report.ResultatsTests.Total) réussis"
        Write-Host "Statut: $($report.StatutGeneral)"

    - name: Publier les rapports
      if: always()
      uses: actions/upload-artifact@v3
      with:
        name: quality-reports
        path: ./reports/
        retention-days: 7
```

### 2. Script PowerShell à tester - `scripts/Convert-Temperature.ps1`

```powershell
<#
.SYNOPSIS
    Convertit les températures entre différentes unités.
.DESCRIPTION
    Cette fonction permet de convertir des températures entre Celsius, Fahrenheit et Kelvin.
.PARAMETER Value
    La valeur de température à convertir.
.PARAMETER From
    L'unité de température source (Celsius, Fahrenheit ou Kelvin).
.PARAMETER To
    L'unité de température cible (Celsius, Fahrenheit ou Kelvin).
.EXAMPLE
    Convert-Temperature -Value 100 -From Celsius -To Fahrenheit
    Convertit 100°C en Fahrenheit (212°F).
.EXAMPLE
    Convert-Temperature -Value 32 -From Fahrenheit -To Celsius
    Convertit 32°F en Celsius (0°C).
.NOTES
    Auteur: VotreNom
    Date:   La date du jour
#>
function Convert-Temperature {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [double]$Value,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Celsius", "Fahrenheit", "Kelvin")]
        [string]$From,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateSet("Celsius", "Fahrenheit", "Kelvin")]
        [string]$To
    )

    # Si les unités sont identiques, retourner la valeur d'origine
    if ($From -eq $To) {
        return $Value
    }

    # Conversion en Celsius comme étape intermédiaire
    $celsiusValue = switch ($From) {
        "Celsius"    { $Value }
        "Fahrenheit" { ($Value - 32) * 5/9 }
        "Kelvin"     { $Value - 273.15 }
    }

    # Conversion de Celsius vers l'unité cible
    $result = switch ($To) {
        "Celsius"    { $celsiusValue }
        "Fahrenheit" { ($celsiusValue * 9/5) + 32 }
        "Kelvin"     { $celsiusValue + 273.15 }
    }

    # Arrondir à 2 décimales pour plus de clarté
    return [Math]::Round($result, 2)
}

# Exporter la fonction pour qu'elle soit disponible dans les tests
Export-ModuleMember -Function Convert-Temperature
```

### 3. Test unitaire Pester - `tests/Convert-Temperature.Tests.ps1`

```powershell
BeforeAll {
    # Charger le script à tester
    $scriptPath = "$PSScriptRoot/../scripts/Convert-Temperature.ps1"

    # Vérifier si le script existe
    if (-not (Test-Path $scriptPath)) {
        throw "Le script à tester n'existe pas: $scriptPath"
    }

    # Dot-sourcer le script pour rendre la fonction disponible
    . $scriptPath
}

Describe "Convert-Temperature" {
    Context "Conversions de Celsius" {
        It "Convertit correctement 0°C en Fahrenheit" {
            Convert-Temperature -Value 0 -From Celsius -To Fahrenheit | Should -Be 32
        }

        It "Convertit correctement 100°C en Fahrenheit" {
            Convert-Temperature -Value 100 -From Celsius -To Fahrenheit | Should -Be 212
        }

        It "Convertit correctement 0°C en Kelvin" {
            Convert-Temperature -Value 0 -From Celsius -To Kelvin | Should -Be 273.15
        }

        It "Retourne la même valeur si From et To sont identiques" {
            Convert-Temperature -Value 25 -From Celsius -To Celsius | Should -Be 25
        }
    }

    Context "Conversions de Fahrenheit" {
        It "Convertit correctement 32°F en Celsius" {
            Convert-Temperature -Value 32 -From Fahrenheit -To Celsius | Should -Be 0
        }

        It "Convertit correctement 212°F en Celsius" {
            Convert-Temperature -Value 212 -From Fahrenheit -To Celsius | Should -Be 100
        }

        It "Convertit correctement 32°F en Kelvin" {
            Convert-Temperature -Value 32 -From Fahrenheit -To Kelvin | Should -Be 273.15
        }
    }

    Context "Conversions de Kelvin" {
        It "Convertit correctement 0K en Celsius" {
            Convert-Temperature -Value 0 -From Kelvin -To Celsius | Should -Be -273.15
        }

        It "Convertit correctement 273.15K en Celsius" {
            Convert-Temperature -Value 273.15 -From Kelvin -To Celsius | Should -Be 0
        }

        It "Convertit correctement 273.15K en Fahrenheit" {
            Convert-Temperature -Value 273.15 -From Kelvin -To Fahrenheit | Should -Be 32
        }
    }

    Context "Gestion des paramètres" {
        It "Accepte les entrées via le pipeline" {
            { 100 | Convert-Temperature -From Celsius -To Fahrenheit } | Should -Not -Throw
        }

        It "Génère une erreur avec une unité non valide" {
            { Convert-Temperature -Value 100 -From "Invalid" -To Celsius } | Should -Throw
        }
    }
}
```

## Comment utiliser cette solution

1. **Structure de répertoires**
   Créez la structure suivante dans votre dépôt :
   ```
   votre-repo/
   ├── .github/
   │   └── workflows/
   │       └── test-powershell.yml
   ├── scripts/
   │   └── Convert-Temperature.ps1
   ├── tests/
   │   └── Convert-Temperature.Tests.ps1
   └── reports/  # Sera créé automatiquement par le workflow
   ```

2. **Exécution locale des tests**
   Pour tester localement avant de pousser vers GitHub :
   ```powershell
   # Installer les modules nécessaires
   Install-Module -Name PSScriptAnalyzer, Pester -Force -Scope CurrentUser

   # Analyser le code
   Invoke-ScriptAnalyzer -Path "./scripts" -Recurse

   # Exécuter les tests
   Invoke-Pester -Path "./tests" -Verbose
   ```

3. **Exécution dans GitHub Actions**
   Une fois que vous avez poussé ces fichiers vers votre dépôt GitHub sur la branche main, le workflow s'exécutera automatiquement.

## Explication de la solution

Cette solution complète :

1. **Vérifie la syntaxe** de vos scripts PowerShell avec PSScriptAnalyzer
   - Identifie les erreurs, avertissements et bonnes pratiques
   - Échoue le pipeline si des erreurs critiques sont trouvées

2. **Exécute des tests unitaires** avec le framework Pester
   - Tests de conversion de température entre différentes unités
   - Vérifie que la fonction gère correctement les cas limites

3. **Génère des rapports détaillés** en formats JSON et Markdown
   - Résumé des analyses de code
   - Résultats des tests unitaires
   - Statut global du projet

4. **Publie les rapports** comme artefacts de build dans GitHub Actions
   - Facilement téléchargeables depuis l'interface GitHub
   - Conservés pendant 7 jours

Cette solution démontre les meilleures pratiques pour intégrer PowerShell dans un pipeline CI/CD, y compris :
- Documentation complète avec des commentaires basés sur aide
- Validation des paramètres
- Tests unitaires robustes
- Génération de rapports détaillés
- Gestion des erreurs appropriée
