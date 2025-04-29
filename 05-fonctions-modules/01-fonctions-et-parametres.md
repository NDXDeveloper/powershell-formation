# Module 6 : Fonctions, modules et structuration
## 6-1. Création de fonctions et paramètres

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Les fonctions sont un élément fondamental de PowerShell qui vous permettent de réutiliser du code, d'organiser votre travail et d'éviter les répétitions. Elles sont comme des "mini-scripts" que vous pouvez appeler n'importe quand.

### Pourquoi utiliser des fonctions ?

- 🔄 **Réutilisation** : Écrivez une fois, utilisez partout
- 📦 **Modularité** : Divisez votre code en blocs logiques
- 🧹 **Lisibilité** : Un code plus propre et mieux organisé
- 🛠️ **Maintenabilité** : Facilité à corriger ou modifier une seule fonction

### Structure de base d'une fonction

```powershell
function Nom-DeMaFonction {
    # Le code de votre fonction va ici
    Write-Output "Bonjour depuis ma fonction !"
}
```

Pour exécuter cette fonction, tapez simplement son nom :

```powershell
Nom-DeMaFonction
# Résultat : Bonjour depuis ma fonction !
```

### Fonctions avec paramètres simples

Les paramètres permettent de passer des informations à votre fonction. Ils rendent vos fonctions flexibles et réutilisables dans différents contextes.

```powershell
function Dire-Bonjour {
    param(
        $Nom
    )
    Write-Output "Bonjour $Nom !"
}

# Appel de la fonction avec paramètre
Dire-Bonjour -Nom "Martin"
# Résultat : Bonjour Martin !

# Forme abrégée (sans le nom du paramètre)
Dire-Bonjour "Sophie"
# Résultat : Bonjour Sophie !
```

### Paramètres avec type

Il est fortement recommandé de typer vos paramètres pour éviter les erreurs et clarifier l'intention :

```powershell
function Calculer-Age {
    param(
        [int]$AnneeNaissance
    )

    $AnneeActuelle = (Get-Date).Year
    $Age = $AnneeActuelle - $AnneeNaissance

    Write-Output "Vous avez environ $Age ans."
}

Calculer-Age -AnneeNaissance 1992
# Résultat : Vous avez environ 33 ans. (en 2025)
```

### Paramètres obligatoires

Pour rendre un paramètre obligatoire, utilisez l'attribut `[Parameter]` avec `Mandatory=$true` :

```powershell
function Verifier-Age {
    param(
        [Parameter(Mandatory=$true)]
        [int]$Age
    )

    if ($Age -ge 18) {
        Write-Output "Vous êtes majeur."
    } else {
        Write-Output "Vous êtes mineur."
    }
}

# PowerShell vous demandera de saisir une valeur si vous n'en fournissez pas
Verifier-Age
```

### Paramètres avec valeurs par défaut

```powershell
function Afficher-Message {
    param(
        [string]$Message = "Message par défaut",
        [string]$Couleur = "White"
    )

    Write-Host $Message -ForegroundColor $Couleur
}

# Utilisation des valeurs par défaut
Afficher-Message
# Résultat : "Message par défaut" en blanc

# Spécification de paramètres
Afficher-Message -Message "Attention !" -Couleur "Yellow"
# Résultat : "Attention !" en jaune
```

### Paramètres de pipeline

PowerShell permet de recevoir des objets du pipeline (|) directement dans vos fonctions :

```powershell
function Ajouter-Prefixe {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$Texte,

        [string]$Prefixe = ">> "
    )

    process {
        Write-Output "$Prefixe$Texte"
    }
}

# Utilisation avec le pipeline
"Information importante" | Ajouter-Prefixe
# Résultat : >> Information importante

# Plusieurs éléments via le pipeline
"Ligne 1", "Ligne 2", "Ligne 3" | Ajouter-Prefixe
# Résultat :
# >> Ligne 1
# >> Ligne 2
# >> Ligne 3
```

### Blocs de traitement dans les fonctions

Une fonction PowerShell peut contenir trois blocs spéciaux :

```powershell
function Traiter-Donnees {
    param(
        [Parameter(ValueFromPipeline=$true)]
        [string]$Ligne
    )

    begin {
        # Exécuté une seule fois au début
        Write-Host "Début du traitement..." -ForegroundColor Cyan
        $Compteur = 0
    }

    process {
        # Exécuté pour chaque élément du pipeline
        $Compteur++
        Write-Host "Traitement de : $Ligne" -ForegroundColor Yellow
    }

    end {
        # Exécuté une seule fois à la fin
        Write-Host "Traitement terminé. $Compteur lignes traitées." -ForegroundColor Green
    }
}

"Données A", "Données B", "Données C" | Traiter-Donnees
```

### Fonctions avec multiples paramètres et jeux de paramètres

Vous pouvez définir plusieurs jeux de paramètres pour une même fonction :

```powershell
function Trouver-Fichier {
    [CmdletBinding(DefaultParameterSetName="ParNom")]
    param(
        [Parameter(ParameterSetName="ParNom", Mandatory=$true)]
        [string]$Nom,

        [Parameter(ParameterSetName="ParExtension", Mandatory=$true)]
        [string]$Extension,

        [Parameter(ParameterSetName="ParNom")]
        [Parameter(ParameterSetName="ParExtension")]
        [string]$Dossier = "."
    )

    if ($PSCmdlet.ParameterSetName -eq "ParNom") {
        Get-ChildItem -Path $Dossier -Filter "*$Nom*" -Recurse
    } else {
        Get-ChildItem -Path $Dossier -Filter "*.$Extension" -Recurse
    }
}

# Recherche par nom
Trouver-Fichier -Nom "rapport"

# Recherche par extension
Trouver-Fichier -Extension "txt"
```

### Retourner des valeurs depuis une fonction

En PowerShell, tout ce qui n'est pas capturé par une variable ou redirigé est automatiquement retourné :

```powershell
function Additionner {
    param(
        [int]$a,
        [int]$b
    )

    # Cette valeur sera automatiquement retournée
    $a + $b
}

$Resultat = Additionner -a 5 -b 3
Write-Output "5 + 3 = $Resultat"
# Résultat : 5 + 3 = 8
```

Vous pouvez aussi utiliser `return` pour sortir prématurément d'une fonction :

```powershell
function Diviser {
    param(
        [int]$Numerateur,
        [int]$Denominateur
    )

    if ($Denominateur -eq 0) {
        Write-Error "Division par zéro impossible !"
        return $null
    }

    return $Numerateur / $Denominateur
}

Diviser -Numerateur 10 -Denominateur 2
# Résultat : 5

Diviser -Numerateur 10 -Denominateur 0
# Résultat : Erreur
```

### 🔄 Exercices pratiques

1. **Exercice de base** : Créez une fonction `Convertir-CelsiusEnFahrenheit` qui prend une température en Celsius et la convertit en Fahrenheit.

2. **Exercice intermédiaire** : Créez une fonction `Get-FileInfo` qui affiche des informations sur un fichier (nom, taille, date de création, etc.) et accepte un chemin via le pipeline.

3. **Exercice avancé** : Créez une fonction `Send-EmailAlert` qui envoie un email avec un message personnalisable et des paramètres pour l'objet, les destinataires, etc.

### 🌟 Conseils pour de bonnes fonctions

- Suivez la convention de nommage Verbe-Nom (ex: Get-Process, Set-Content)
- Une fonction doit faire une seule chose, mais la faire bien
- Documentez vos fonctions avec des commentaires ou l'aide intégrée
- Validez les entrées pour éviter les erreurs
- Utilisez des messages d'erreur clairs et utiles

Dans la prochaine section, nous verrons comment valider les paramètres de façon plus avancée pour rendre vos fonctions encore plus robustes.
