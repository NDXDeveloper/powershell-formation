# Module 6 : Fonctions, modules et structuration
## 6-2. Validation des paramètres (`[ValidateNotNullOrEmpty]`, etc.)

La validation des paramètres est une étape cruciale pour créer des fonctions robustes et fiables. Elle permet de s'assurer que les données reçues par votre fonction sont valides avant de commencer le traitement. PowerShell offre plusieurs attributs de validation intégrés qui vous évitent d'écrire du code de vérification manuel.

### Pourquoi valider les paramètres ?

- 🛡️ **Sécurité** : Évite les erreurs liées à des données incorrectes
- 🚫 **Prévention** : Arrête l'exécution avant qu'un problème ne survienne
- 📝 **Clarté** : Documente implicitement les attentes de votre fonction
- 👨‍💻 **Expérience utilisateur** : Fournit des messages d'erreur clairs et précis

### Les attributs de validation les plus courants

Voici les principales validations que vous pouvez utiliser dans vos fonctions PowerShell :

#### `[ValidateNotNull]` et `[ValidateNotNullOrEmpty]`

Ces attributs vérifient que la valeur n'est pas nulle ou vide :

```powershell
function Test-Validation {
    param(
        [ValidateNotNull()]
        $Parametre1,

        [ValidateNotNullOrEmpty()]
        $Parametre2
    )

    Write-Output "Les deux paramètres sont valides !"
}

# Ceci fonctionnera
Test-Validation -Parametre1 "Valeur1" -Parametre2 "Valeur2"

# Ceci échouera avec une erreur
Test-Validation -Parametre1 $null -Parametre2 "Valeur2"
Test-Validation -Parametre1 "Valeur1" -Parametre2 ""
```

> 📌 **Différence** : `[ValidateNotNull]` accepte les chaînes vides ("") mais pas $null, tandis que `[ValidateNotNullOrEmpty]` n'accepte ni l'un ni l'autre.

#### `[ValidateLength(min, max)]`

Vérifie que la longueur d'une chaîne se situe dans la plage spécifiée :

```powershell
function Set-Password {
    param(
        [ValidateLength(8, 20)]
        [string]$Password
    )

    Write-Output "Mot de passe défini avec succès !"
}

# Fonctionne
Set-Password -Password "MotDePasse123"

# Échoue (trop court)
Set-Password -Password "Court"
```

#### `[ValidateRange(min, max)]`

Vérifie qu'une valeur numérique est dans la plage spécifiée :

```powershell
function Set-VolumeLevel {
    param(
        [ValidateRange(0, 100)]
        [int]$Niveau
    )

    Write-Output "Volume défini à $Niveau%"
}

# Fonctionne
Set-VolumeLevel -Niveau 75

# Échoue
Set-VolumeLevel -Niveau 150
```

#### `[ValidateSet("valeur1", "valeur2", ...)]`

Restreint les entrées à une liste prédéfinie de valeurs (comme une énumération) :

```powershell
function Set-LogLevel {
    param(
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]$Level
    )

    Write-Output "Niveau de journalisation défini à : $Level"
}

# Fonctionne
Set-LogLevel -Level "Warning"

# Échoue
Set-LogLevel -Level "Critical"  # N'est pas dans la liste autorisée
```

#### `[ValidatePattern("regex")]`

Vérifie qu'une chaîne correspond à un modèle d'expression régulière :

```powershell
function Test-Email {
    param(
        [ValidatePattern("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")]
        [string]$EmailAddress
    )

    Write-Output "Adresse e-mail valide : $EmailAddress"
}

# Fonctionne
Test-Email -EmailAddress "utilisateur@exemple.com"

# Échoue
Test-Email -EmailAddress "adresse_invalide"
```

#### `[ValidateScript({script})]`

Permet une validation personnalisée à l'aide d'un script :

```powershell
function Test-FichierExiste {
    param(
        [ValidateScript({
            if (Test-Path $_) {
                $true
            }
            else {
                throw "Le fichier '$_' n'existe pas !"
            }
        })]
        [string]$CheminFichier
    )

    $contenu = Get-Content -Path $CheminFichier
    Write-Output "Le fichier contient $($contenu.Count) lignes"
}

# Fonctionne si le fichier existe
Test-FichierExiste -CheminFichier "C:\fichiers\existant.txt"

# Échoue si le fichier n'existe pas
Test-FichierExiste -CheminFichier "C:\fichiers\inexistant.txt"
```

### Combiner plusieurs validations

Vous pouvez appliquer plusieurs validations à un seul paramètre :

```powershell
function Valider-Utilisateur {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(3, 20)]
        [ValidatePattern("^[a-zA-Z0-9_]+$")]
        [string]$NomUtilisateur
    )

    Write-Output "Nom d'utilisateur valide : $NomUtilisateur"
}

# Fonctionne
Valider-Utilisateur -NomUtilisateur "john_doe123"

# Échoue pour diverses raisons
Valider-Utilisateur -NomUtilisateur ""  # Vide
Valider-Utilisateur -NomUtilisateur "ab"  # Trop court
Valider-Utilisateur -NomUtilisateur "nom@utilisateur"  # Caractères non autorisés
```

### Validation pour les fichiers et dossiers

Pour valider des chemins de fichiers ou de dossiers, utilisez `ValidateScript` avec `Test-Path` :

```powershell
function Get-InfoFichier {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (Test-Path $_ -PathType Leaf) {
                $true
            }
            else {
                throw "Le chemin '$_' n'est pas un fichier ou n'existe pas."
            }
        })]
        [string]$CheminFichier,

        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if (Test-Path $_ -PathType Container) {
                $true
            }
            else {
                throw "Le chemin '$_' n'est pas un dossier ou n'existe pas."
            }
        })]
        [string]$CheminDossier
    )

    Write-Output "Fichier : $CheminFichier"
    Write-Output "Dossier : $CheminDossier"
}
```

### `[ValidateCount(min, max)]` pour les tableaux

Pour valider le nombre d'éléments dans un tableau :

```powershell
function Process-Files {
    param(
        [ValidateCount(1, 5)]
        [string[]]$Fichiers
    )

    Write-Output "Traitement de $($Fichiers.Count) fichiers"
}

# Fonctionne
Process-Files -Fichiers "fichier1.txt", "fichier2.txt"

# Échoue (trop d'éléments)
Process-Files -Fichiers "f1.txt", "f2.txt", "f3.txt", "f4.txt", "f5.txt", "f6.txt"
```

### Exemple de fonction complète avec validation

Voici un exemple concret d'une fonction qui crée un fichier journal avec plusieurs validations :

```powershell
function New-LogFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NomFichier,

        [Parameter()]
        [ValidateScript({
            if (Test-Path $_ -PathType Container) {
                $true
            }
            else {
                throw "Le dossier '$_' n'existe pas."
            }
        })]
        [string]$Dossier = [System.IO.Path]::GetTempPath(),

        [Parameter()]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$NiveauInitial = "INFO",

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$TailleMaxMo = 10
    )

    $cheminComplet = Join-Path -Path $Dossier -ChildPath "$NomFichier.log"

    # Créer l'entrée initiale
    $dateDebut = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $contenuInitial = "[$dateDebut] [$NiveauInitial] Fichier journal créé. Taille max: $TailleMaxMo Mo"

    # Écrire dans le fichier
    $contenuInitial | Out-File -FilePath $cheminComplet -Encoding utf8

    # Retourner un objet avec les informations
    [PSCustomObject]@{
        Chemin = $cheminComplet
        DateCreation = $dateDebut
        NiveauInitial = $NiveauInitial
        TailleMaxMo = $TailleMaxMo
    }
}

# Utilisation
$log = New-LogFile -NomFichier "MonApplication" -Dossier "C:\Logs" -NiveauInitial "INFO" -TailleMaxMo 25
Write-Output "Fichier journal créé : $($log.Chemin)"
```

### 🔄 Exercices pratiques

1. **Exercice de base** : Créez une fonction qui valide un numéro de téléphone avec `[ValidatePattern]`.

2. **Exercice intermédiaire** : Créez une fonction qui accepte un chemin de dossier et vérifie qu'il existe et que l'utilisateur a les droits en écriture.

3. **Exercice avancé** : Créez une fonction qui valide une adresse IP avec `[ValidateScript]`.

### 🌟 Conseils pour une bonne validation

- Utilisez des validations pour **empêcher les erreurs** plutôt que pour les gérer après coup
- Fournissez des **messages d'erreur clairs** qui indiquent comment corriger le problème
- Pensez à la **validation en cascade** : d'abord le type, puis les autres validations
- Utilisez `[ValidateScript]` pour les **validations complexes** ou personnalisées
- Évitez la **survalidation** qui rendrait votre fonction trop restrictive

Dans la prochaine section, nous verrons comment organiser vos fonctions en scripts et modules pour une meilleure réutilisation.
