# Module 13-1 : Introduction à Pester (tests unitaires)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 🔍 Qu'est-ce que Pester ?

Pester est un framework de tests unitaires pour PowerShell. Il vous permet de créer des tests automatisés pour vos scripts et modules PowerShell, garantissant ainsi que votre code fonctionne comme prévu.

## 🤔 Pourquoi utiliser des tests unitaires ?

Les tests unitaires offrent plusieurs avantages :

- Ils vérifient que votre code fonctionne correctement
- Ils vous aident à détecter les régressions (quand une modification casse une fonctionnalité existante)
- Ils servent de documentation sur le comportement attendu de votre code
- Ils facilitent la maintenance et l'évolution de vos scripts

## 📦 Installation de Pester

Pester est préinstallé dans Windows 10/11 et Windows Server 2016+, mais c'est souvent une version ancienne. Pour obtenir la dernière version :

```powershell
# Installer ou mettre à jour Pester
Install-Module -Name Pester -Force -SkipPublisherCheck
```

## 🏗️ Structure d'un test Pester

Un fichier de tests Pester typique utilise cette convention de nommage : `NomDuScript.Tests.ps1`

Voici la structure de base :

```powershell
# Importer le module ou script à tester
. .\MaFonction.ps1  # Le point au début est important !

Describe "Test de MaFonction" {
    Context "Quand la fonction reçoit une entrée valide" {
        It "Devrait renvoyer le résultat attendu" {
            # Arrange (préparer)
            $entree = "test"
            $resultatAttendu = "TEST"

            # Act (exécuter)
            $resultatReel = MaFonction -Texte $entree

            # Assert (vérifier)
            $resultatReel | Should -Be $resultatAttendu
        }
    }
}
```

## 📝 Composants clés de Pester

- **Describe** : Décrit une groupe de tests liés (souvent une fonction ou un comportement)
- **Context** : Groupe les tests par scénario ou condition
- **It** : Définit un test spécifique
- **Should** : Vérifie qu'une condition est remplie

## 🧪 Exemple pratique

Imaginons une fonction simple qui additionne deux nombres :

**Fichier : MathFunctions.ps1**
```powershell
function Add-TwoNumbers {
    param (
        [int]$First,
        [int]$Second
    )

    return $First + $Second
}
```

**Fichier de test : MathFunctions.Tests.ps1**
```powershell
# Importer notre script
. .\MathFunctions.ps1

Describe "Tests des fonctions mathématiques" {
    Context "Fonction Add-TwoNumbers" {
        It "Devrait additionner 2 et 3 pour donner 5" {
            $resultat = Add-TwoNumbers -First 2 -Second 3
            $resultat | Should -Be 5
        }

        It "Devrait gérer les nombres négatifs" {
            $resultat = Add-TwoNumbers -First -5 -Second 3
            $resultat | Should -Be -2
        }
    }
}
```

## ▶️ Exécuter les tests

Pour exécuter vos tests, utilisez la commande `Invoke-Pester` :

```powershell
# Exécuter tous les tests dans le dossier courant
Invoke-Pester

# Exécuter un fichier de test spécifique
Invoke-Pester .\MathFunctions.Tests.ps1
```

## 🛠️ Assertions courantes

Pester offre plusieurs types d'assertions :

```powershell
$valeur | Should -Be 5             # Égalité exacte
$valeur | Should -BeGreaterThan 3  # Supérieur à
$valeur | Should -BeLessThan 10    # Inférieur à
$valeur | Should -Match "pattern"  # Correspond à une regex
$valeur | Should -Exist            # Un fichier/dossier existe
$code | Should -Throw              # Le code lance une exception
$valeur | Should -BeNullOrEmpty    # La valeur est null ou vide
```

## 🎭 Mocks - Simuler des comportements

Les mocks permettent de simuler le comportement de fonctions ou cmdlets :

```powershell
Describe "Test avec mock" {
    It "Devrait appeler Get-Content avec le bon chemin" {
        # Créer un mock pour Get-Content
        Mock Get-Content { return "Contenu simulé" }

        # Appeler notre fonction qui utilise Get-Content
        $resultat = Lire-MonFichier -Chemin "C:\test.txt"

        # Vérifier que Get-Content a été appelé avec le bon paramètre
        Should -Invoke Get-Content -Times 1 -ParameterFilter {
            $Path -eq "C:\test.txt"
        }
    }
}
```

## 🛠️ Mise en place et nettoyage

Pour préparer l'environnement de test et le nettoyer après :

```powershell
Describe "Test avec préparation" {
    BeforeAll {
        # Code exécuté une fois avant tous les tests
        $global:MaVariableTest = "Valeur initiale"
    }

    BeforeEach {
        # Code exécuté avant chaque test
        $script:compteur = 0
    }

    It "Premier test" {
        # Test...
    }

    AfterEach {
        # Code exécuté après chaque test
        Remove-Item -Path ".\temp.txt" -ErrorAction SilentlyContinue
    }

    AfterAll {
        # Code exécuté une fois après tous les tests
        Remove-Variable -Name MaVariableTest -Scope Global
    }
}
```

## 📊 Bonnes pratiques

1. **Tests atomiques** : Chaque test doit vérifier une seule chose
2. **Indépendance** : Les tests ne doivent pas dépendre d'autres tests
3. **Lisibilité** : Utilisez des noms descriptifs pour vos tests
4. **Couverture** : Testez les cas normaux et les cas limites
5. **Isolation** : Utilisez des mocks pour isoler ce que vous testez

## 🔄 Intégration dans un workflow CI/CD

Les tests Pester peuvent être intégrés dans des pipelines d'intégration continue :

```powershell
# Exécuter les tests et générer un rapport XML
$resultat = Invoke-Pester -OutputFormat NUnitXml -OutputFile TestResults.xml -PassThru

# En cas d'échec dans un pipeline CI/CD
if ($resultat.FailedCount -gt 0) {
    throw "Des tests ont échoué !"
}
```

## 🔍 Ressources supplémentaires

- [Documentation officielle de Pester](https://pester.dev)
- [Pester sur GitHub](https://github.com/pester/Pester)
- [Exemples et tutoriels](https://pester.dev/docs/quick-start)

---

## 🧠 Exercice pratique

Créez un script `Calculatrice.ps1` avec des fonctions d'addition, soustraction, multiplication et division, puis écrivez des tests pour chaque fonction, y compris pour les cas spéciaux comme la division par zéro.

Bon test ! 🚀
