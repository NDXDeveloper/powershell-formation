 # Solution de l'exercice de linting PowerShell

## Rappel de l'exercice

Dans le tutoriel sur le linting et la validation automatique, l'exercice consistait à :
1. Créer un script PowerShell avec des erreurs intentionnelles
2. Installer PSScriptAnalyzer
3. Analyser le script et corriger les problèmes identifiés
4. Créer un fichier de configuration personnalisé

## Script initial avec erreurs

Voici le script initial contenant plusieurs erreurs et mauvaises pratiques :

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

## Problèmes identifiés par PSScriptAnalyzer

En exécutant PSScriptAnalyzer sur ce script :

```powershell
Invoke-ScriptAnalyzer -Path .\MonExercice.ps1
```

On obtiendrait probablement les résultats suivants :

- **PSAvoidUsingCmdletAliases** : Utilisation des alias `gci` et `%`
- **PSUseSingularNouns** : La fonction `Get-Users` utilise un nom au pluriel
- **PSAvoidUsingWriteHost** : Utilisation de `Write-Host` au lieu d'alternatives plus adaptées
- **PSUseDeclaredVarsMoreThanAssignment** : La variable `$resultat` est déclarée mais non utilisée

## Script corrigé

Voici le script corrigé, conforme aux bonnes pratiques recommandées par PSScriptAnalyzer :

```powershell
<#
.SYNOPSIS
    Récupère des informations sur les ordinateurs spécifiés.
.DESCRIPTION
    Cette fonction prend un chemin vers des ordinateurs et affiche des informations à leur sujet.
.PARAMETER ComputerPath
    Le chemin où se trouvent les informations sur les ordinateurs.
.EXAMPLE
    Get-Info -ComputerPath "C:\Computers"
    Récupère les informations des ordinateurs dans le dossier spécifié.
#>
function Get-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerPath
    )

    # Utilisation du nom complet du cmdlet au lieu de l'alias
    Get-ChildItem -Path $ComputerPath | ForEach-Object {
        # Utilisation de Write-Output au lieu de Write-Host
        Write-Output "Ordinateur: $_"

        # Alternative avec journalisation appropriée
        Write-Verbose "Traitement de l'ordinateur: $_"
    }
}

<#
.SYNOPSIS
    Récupère des informations sur un utilisateur.
.DESCRIPTION
    Cette fonction est un exemple de fonction avec nom au singulier.
.PARAMETER Identity
    L'identité de l'utilisateur à récupérer.
.EXAMPLE
    Get-User -Identity "jdupont"
    Récupère les informations de l'utilisateur spécifié.
#>
function Get-User {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    # Code d'exemple
    Write-Output "Informations pour l'utilisateur: $Identity"
}
```

## Fichier de configuration personnalisé

Voici un exemple de fichier de configuration personnalisé pour PSScriptAnalyzer :

```powershell
# MesReglesPersonnalisees.psd1
@{
    # Règles à inclure - nous sélectionnons les plus importantes
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSUseSingularNouns',
        'PSAvoidUsingWriteHost',
        'PSUseDeclaredVarsMoreThanAssignment',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSProvideCommentHelp'
    )

    # Personnalisation des règles
    Rules = @{
        # Autoriser certains alias très courants
        PSAvoidUsingCmdletAliases = @{
            AllowedAliases = @('select', 'where')
        }

        # Configuration de l'indentation
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            Kind = 'space'
        }

        # Configuration des espaces
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }

        # Commentaires d'aide requis
        PSProvideCommentHelp = @{
            Enable = $true
            Placement = 'begin'
            ExportedOnly = $false
        }
    }

    # Sévérité personnalisée pour certaines règles
    Severity = @(
        @{ Rule = 'PSAvoidUsingWriteHost'; Severity = 'Warning' },
        @{ Rule = 'PSUseSingularNouns'; Severity = 'Warning' }
    )
}
```

## Utilisation de la configuration personnalisée

Pour utiliser cette configuration avec PSScriptAnalyzer :

```powershell
# Analyse du script avec la configuration personnalisée
Invoke-ScriptAnalyzer -Path .\MonExercice.ps1 -Settings .\MesReglesPersonnalisees.psd1

# Pour intégrer dans VS Code, ajouter dans settings.json :
# "powershell.scriptAnalysis.settingsPath": "C:\\Chemin\\vers\\MesReglesPersonnalisees.psd1"
```

## Conclusion

Cette solution démontre comment :
1. Identifier les problèmes courants avec PSScriptAnalyzer
2. Corriger ces problèmes selon les bonnes pratiques PowerShell
3. Améliorer la qualité du code (ajout de commentaires d'aide, paramètres nommés)
4. Personnaliser les règles d'analyse selon vos besoins

Le script corrigé est désormais plus lisible, mieux documenté et conforme aux bonnes pratiques de la communauté PowerShell.



MonExercice-Corrige.ps1 : Le script PowerShell corrigé qui résout tous les problèmes identifiés dans l'exercice. J'ai :

Renommé les fonctions pour utiliser des noms au singulier
Remplacé les alias par des cmdlets complets
Ajouté une documentation d'aide complète
Utilisé les bonnes pratiques pour la déclaration des paramètres
Remplacé Write-Host par Write-Output et Write-Verbose


MesReglesPersonnalisees.psd1 : Un fichier de configuration personnalisé pour PSScriptAnalyzer avec :

Une sélection des règles les plus importantes
Des personnalisations pour certaines règles (comme l'autorisation de certains alias)
Des configurations d'indentation et d'espaces uniformes
Des niveaux de sévérité personnalisés


Analyse-Exercice.ps1 : Un script d'analyse qui démontre comment :

Installer PSScriptAnalyzer s'il n'est pas déjà présent
Analyser le script original avec erreurs
Analyser le script corrigé
Appliquer une configuration personnalisée
Afficher des statistiques sur les problèmes détectés



Ces trois scripts constituent ensemble une solution complète à l'exercice pratique proposé dans le tutoriel sur le linting et la validation automatique en PowerShell. Ils illustrent non seulement les corrections nécessaires, mais aussi comment automatiser le processus d'analyse et comment personnaliser les règles selon vos besoins.

```powershell
# MonExercice-Corrige.ps1
<#
.SYNOPSIS
    Récupère des informations sur les ordinateurs spécifiés.
.DESCRIPTION
    Cette fonction prend un chemin vers des ordinateurs et affiche des informations à leur sujet.
    Elle suit les bonnes pratiques recommandées par PSScriptAnalyzer.
.PARAMETER ComputerPath
    Le chemin où se trouvent les informations sur les ordinateurs.
.EXAMPLE
    Get-Info -ComputerPath "C:\Computers"
    Récupère les informations des ordinateurs dans le dossier spécifié.
.NOTES
    Version:        1.0
    Author:         Votre Nom
    Creation Date:  27/04/2025
    Purpose/Change: Solution de l'exercice de linting PowerShell
#>
function Get-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerPath
    )

    # Utilisation du nom complet du cmdlet au lieu de l'alias
    Get-ChildItem -Path $ComputerPath | ForEach-Object {
        # Utilisation de Write-Output au lieu de Write-Host
        Write-Output "Ordinateur: $_"

        # Alternative avec journalisation appropriée
        Write-Verbose "Traitement de l'ordinateur: $_"
    }
}

<#
.SYNOPSIS
    Récupère des informations sur un utilisateur.
.DESCRIPTION
    Cette fonction est un exemple de fonction avec nom au singulier.
.PARAMETER Identity
    L'identité de l'utilisateur à récupérer.
.EXAMPLE
    Get-User -Identity "jdupont"
    Récupère les informations de l'utilisateur spécifié.
#>
function Get-User {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    # Code d'exemple
    Write-Output "Informations pour l'utilisateur: $Identity"
}

# Test des fonctions
if ($MyInvocation.InvocationName -ne '.') {
    Write-Verbose "Exécution du script comme un script principal..."

    # Exemple d'utilisation
    Get-Info -ComputerPath "C:\Temp" -Verbose
    Get-User -Identity "jdupont"
}
```

```powershell
# MesReglesPersonnalisees.psd1
# Configuration personnalisée pour PSScriptAnalyzer
@{
    # Règles à inclure - nous sélectionnons les plus importantes
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSUseSingularNouns',
        'PSAvoidUsingWriteHost',
        'PSUseDeclaredVarsMoreThanAssignment',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSProvideCommentHelp'
    )

    # Personnalisation des règles
    Rules = @{
        # Autoriser certains alias très courants
        PSAvoidUsingCmdletAliases = @{
            AllowedAliases = @('select', 'where')
        }

        # Configuration de l'indentation
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            Kind = 'space'
        }

        # Configuration des espaces
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }

        # Commentaires d'aide requis
        PSProvideCommentHelp = @{
            Enable = $true
            Placement = 'begin'
            ExportedOnly = $false
        }
    }

    # Sévérité personnalisée pour certaines règles
    Severity = @(
        @{ Rule = 'PSAvoidUsingWriteHost'; Severity = 'Warning' },
        @{ Rule = 'PSUseSingularNouns'; Severity = 'Warning' }
    )
}
```

```powershell
# Analyse-Exercice.ps1
<#
.SYNOPSIS
    Script d'analyse de l'exercice de linting PowerShell.
.DESCRIPTION
    Ce script démontre comment analyser un script PowerShell avec PSScriptAnalyzer
    et affiche les résultats de l'analyse avant et après correction.
.NOTES
    Version:        1.0
    Author:         Votre Nom
    Creation Date:  27/04/2025
#>

# Vérifier si PSScriptAnalyzer est installé, sinon l'installer
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Output "Installation de PSScriptAnalyzer..."
    Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
}

# Contenu du script avec erreurs
$scriptAvecErreurs = @'
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
'@

# Enregistrer le script avec erreurs dans un fichier temporaire
$fichierAvecErreurs = Join-Path -Path $env:TEMP -ChildPath "ScriptAvecErreurs.ps1"
$scriptAvecErreurs | Out-File -FilePath $fichierAvecErreurs -Encoding utf8

# Contenu du script corrigé
$scriptCorrige = @'
<#
.SYNOPSIS
    Récupère des informations sur les ordinateurs spécifiés.
.DESCRIPTION
    Cette fonction prend un chemin vers des ordinateurs et affiche des informations à leur sujet.
    Elle suit les bonnes pratiques recommandées par PSScriptAnalyzer.
.PARAMETER ComputerPath
    Le chemin où se trouvent les informations sur les ordinateurs.
.EXAMPLE
    Get-Info -ComputerPath "C:\Computers"
    Récupère les informations des ordinateurs dans le dossier spécifié.
#>
function Get-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerPath
    )

    # Utilisation du nom complet du cmdlet au lieu de l'alias
    Get-ChildItem -Path $ComputerPath | ForEach-Object {
        # Utilisation de Write-Output au lieu de Write-Host
        Write-Output "Ordinateur: $_"

        # Alternative avec journalisation appropriée
        Write-Verbose "Traitement de l'ordinateur: $_"
    }
}

<#
.SYNOPSIS
    Récupère des informations sur un utilisateur.
.DESCRIPTION
    Cette fonction est un exemple de fonction avec nom au singulier.
.PARAMETER Identity
    L'identité de l'utilisateur à récupérer.
.EXAMPLE
    Get-User -Identity "jdupont"
    Récupère les informations de l'utilisateur spécifié.
#>
function Get-User {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )

    # Code d'exemple
    Write-Output "Informations pour l'utilisateur: $Identity"
}
'@

# Enregistrer le script corrigé dans un fichier temporaire
$fichierCorrige = Join-Path -Path $env:TEMP -ChildPath "ScriptCorrige.ps1"
$scriptCorrige | Out-File -FilePath $fichierCorrige -Encoding utf8

# Contenu du fichier de configuration personnalisée
$configPersonnalisee = @'
# Configuration personnalisée pour PSScriptAnalyzer
@{
    # Règles à inclure - nous sélectionnons les plus importantes
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSUseSingularNouns',
        'PSAvoidUsingWriteHost',
        'PSUseDeclaredVarsMoreThanAssignment',
        'PSUseConsistentIndentation',
        'PSUseConsistentWhitespace',
        'PSProvideCommentHelp'
    )

    # Personnalisation des règles
    Rules = @{
        # Autoriser certains alias très courants
        PSAvoidUsingCmdletAliases = @{
            AllowedAliases = @('select', 'where')
        }

        # Configuration de l'indentation
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            Kind = 'space'
        }

        # Configuration des espaces
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckSeparator = $true
        }

        # Commentaires d'aide requis
        PSProvideCommentHelp = @{
            Enable = $true
            Placement = 'begin'
            ExportedOnly = $false
        }
    }

    # Sévérité personnalisée pour certaines règles
    Severity = @(
        @{ Rule = 'PSAvoidUsingWriteHost'; Severity = 'Warning' },
        @{ Rule = 'PSUseSingularNouns'; Severity = 'Warning' }
    )
}
'@

# Enregistrer la configuration personnalisée dans un fichier temporaire
$fichierConfig = Join-Path -Path $env:TEMP -ChildPath "MesReglesPersonnalisees.psd1"
$configPersonnalisee | Out-File -FilePath $fichierConfig -Encoding utf8

# Importer le module PSScriptAnalyzer
Import-Module PSScriptAnalyzer

# Analyser le script avec erreurs
Write-Output "`n== ANALYSE DU SCRIPT AVEC ERREURS =="
Write-Output "==================================="
$resultatAvecErreurs = Invoke-ScriptAnalyzer -Path $fichierAvecErreurs
$resultatAvecErreurs | Format-Table -AutoSize

# Analyser le script corrigé
Write-Output "`n== ANALYSE DU SCRIPT CORRIGÉ =="
Write-Output "==============================="
$resultatCorrige = Invoke-ScriptAnalyzer -Path $fichierCorrige
$resultatCorrige | Format-Table -AutoSize

# Analyser le script corrigé avec la configuration personnalisée
Write-Output "`n== ANALYSE AVEC CONFIGURATION PERSONNALISÉE =="
Write-Output "==========================================="
$resultatAvecConfig = Invoke-ScriptAnalyzer -Path $fichierCorrige -Settings $fichierConfig
$resultatAvecConfig | Format-Table -AutoSize

# Statistiques
Write-Output "`n== STATISTIQUES =="
Write-Output "================="
Write-Output "Problèmes trouvés dans le script avec erreurs: $($resultatAvecErreurs.Count)"
Write-Output "Problèmes trouvés dans le script corrigé: $($resultatCorrige.Count)"
Write-Output "Problèmes trouvés avec la configuration personnalisée: $($resultatAvecConfig.Count)"

# Nettoyage
Remove-Item -Path $fichierAvecErreurs, $fichierCorrige, $fichierConfig -Force

```
