# Solution de l'exercice Pester - Calculatrice

Cette solution comprend deux fichiers : le module de calculatrice (`Calculatrice.ps1`) et ses tests associés (`Calculatrice.Tests.ps1`).

## Fichier 1 : Calculatrice.ps1

```powershell
# Calculatrice.ps1
# Module de fonctions mathématiques de base

function Add-Numbers {
    param (
        [Parameter(Mandatory = $true)]
        [double]$First,

        [Parameter(Mandatory = $true)]
        [double]$Second
    )

    return $First + $Second
}

function Subtract-Numbers {
    param (
        [Parameter(Mandatory = $true)]
        [double]$First,

        [Parameter(Mandatory = $true)]
        [double]$Second
    )

    return $First - $Second
}

function Multiply-Numbers {
    param (
        [Parameter(Mandatory = $true)]
        [double]$First,

        [Parameter(Mandatory = $true)]
        [double]$Second
    )

    return $First * $Second
}

function Divide-Numbers {
    param (
        [Parameter(Mandatory = $true)]
        [double]$Numerator,

        [Parameter(Mandatory = $true)]
        [double]$Denominator
    )

    if ($Denominator -eq 0) {
        throw "Division par zéro impossible"
    }

    return $Numerator / $Denominator
}

# Exporter les fonctions si ce script est importé comme un module
Export-ModuleMember -Function Add-Numbers, Subtract-Numbers, Multiply-Numbers, Divide-Numbers
```

## Fichier 2 : Calculatrice.Tests.ps1

```powershell
# Calculatrice.Tests.ps1
# Tests unitaires pour le module Calculatrice.ps1

# Importer le script à tester
. .\Calculatrice.ps1

Describe "Tests du module Calculatrice" {

    Context "Fonction Add-Numbers" {
        It "Devrait additionner 2 et 3 pour donner 5" {
            $resultat = Add-Numbers -First 2 -Second 3
            $resultat | Should -Be 5
        }

        It "Devrait gérer les nombres négatifs" {
            $resultat = Add-Numbers -First -5 -Second 3
            $resultat | Should -Be -2
        }

        It "Devrait gérer les nombres décimaux" {
            $resultat = Add-Numbers -First 2.5 -Second 3.5
            $resultat | Should -Be 6.0
        }
    }

    Context "Fonction Subtract-Numbers" {
        It "Devrait soustraire 3 de 5 pour donner 2" {
            $resultat = Subtract-Numbers -First 5 -Second 3
            $resultat | Should -Be 2
        }

        It "Devrait gérer les nombres négatifs" {
            $resultat = Subtract-Numbers -First 5 -Second -3
            $resultat | Should -Be 8
        }

        It "Devrait gérer les nombres décimaux" {
            $resultat = Subtract-Numbers -First 5.5 -Second 3.3
            $resultat | Should -BeApproximately 2.2 -Epsilon 0.0001
        }
    }

    Context "Fonction Multiply-Numbers" {
        It "Devrait multiplier 2 par 3 pour donner 6" {
            $resultat = Multiply-Numbers -First 2 -Second 3
            $resultat | Should -Be 6
        }

        It "Devrait gérer les nombres négatifs" {
            $resultat = Multiply-Numbers -First -2 -Second 3
            $resultat | Should -Be -6
        }

        It "Devrait gérer les nombres décimaux" {
            $resultat = Multiply-Numbers -First 2.5 -Second 2
            $resultat | Should -Be 5.0
        }
    }

    Context "Fonction Divide-Numbers" {
        It "Devrait diviser 6 par 3 pour donner 2" {
            $resultat = Divide-Numbers -Numerator 6 -Denominator 3
            $resultat | Should -Be 2
        }

        It "Devrait gérer les nombres négatifs" {
            $resultat = Divide-Numbers -Numerator -6 -Denominator 3
            $resultat | Should -Be -2
        }

        It "Devrait gérer les nombres décimaux" {
            $resultat = Divide-Numbers -Numerator 5 -Denominator 2
            $resultat | Should -Be 2.5
        }

        It "Devrait lancer une exception en cas de division par zéro" {
            { Divide-Numbers -Numerator 5 -Denominator 0 } | Should -Throw "Division par zéro impossible"
        }
    }
}
```

## Comment exécuter la solution

1. Enregistrez les deux fichiers (`Calculatrice.ps1` et `Calculatrice.Tests.ps1`) dans le même dossier
2. Ouvrez PowerShell et naviguez vers ce dossier
3. Exécutez la commande suivante pour lancer les tests :

```powershell
Invoke-Pester .\Calculatrice.Tests.ps1 -Output Detailed
```

## Explications

### Module Calculatrice.ps1
- Contient 4 fonctions mathématiques de base (addition, soustraction, multiplication, division)
- Chaque fonction accepte deux paramètres obligatoires
- La fonction de division inclut une vérification pour éviter la division par zéro
- Les fonctions sont exportées pour permettre l'utilisation en tant que module

### Tests Calculatrice.Tests.ps1
- Organise les tests en contextes, un pour chaque fonction
- Teste les cas standards avec des nombres entiers positifs
- Teste aussi les cas spéciaux :
  - Nombres négatifs
  - Nombres décimaux
  - Division par zéro (doit générer une erreur)
- Utilise différentes assertions :
  - `-Be` pour l'égalité exacte
  - `-BeApproximately` pour les comparaisons de nombres décimaux avec tolérance
  - `-Throw` pour vérifier qu'une exception est bien lancée

Cette solution montre comment créer un ensemble complet de tests unitaires pour un module PowerShell simple, en suivant les bonnes pratiques de test.
