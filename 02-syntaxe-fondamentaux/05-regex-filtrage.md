# Module 3 - Section 3-5 : Expressions régulières et filtrage

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 🔍 Introduction aux expressions régulières

Les expressions régulières (ou "regex") sont des motifs de recherche puissants qui vous permettent de trouver, valider et manipuler du texte selon des règles précises. Bien que leur syntaxe puisse paraître complexe au premier abord, elles sont incroyablement utiles pour automatiser des tâches de traitement de texte.

## 🛠️ Opérateurs PowerShell pour les expressions régulières

PowerShell propose plusieurs opérateurs pour travailler avec les expressions régulières :

| Opérateur | Description | Sensible à la casse |
|-----------|-------------|---------------------|
| `-match` | Vérifie si une chaîne correspond au motif | Non |
| `-notmatch` | Vérifie si une chaîne ne correspond pas au motif | Non |
| `-cmatch` | Vérifie si une chaîne correspond au motif | Oui |
| `-cnotmatch` | Vérifie si une chaîne ne correspond pas au motif | Oui |
| `-replace` | Remplace le texte correspondant au motif | Non |
| `-creplace` | Remplace le texte correspondant au motif | Oui |

### Exemples d'utilisation simple

```powershell
# Vérification simple
"PowerShell" -match "shell"      # $true (insensible à la casse)
"PowerShell" -cmatch "shell"     # $false (sensible à la casse)
"PowerShell" -cmatch "Shell"     # $true

# Négation
"PowerShell" -notmatch "bash"    # $true (ne contient pas "bash")

# Remplacement
"Hello World" -replace "World", "PowerShell"  # "Hello PowerShell"
```

## 📋 Syntaxe de base des expressions régulières

### Caractères littéraux

Les caractères normaux se représentent eux-mêmes :

```powershell
"PowerShell 7.0" -match "Shell"  # $true
"PowerShell 7.0" -match "7.0"    # $true
```

### Métacaractères

Les métacaractères ont une signification spéciale :

| Métacaractère | Description | Exemple |
|---------------|-------------|---------|
| `.` | N'importe quel caractère | `"a"` -match `.` |
| `^` | Début de la chaîne | `"PowerShell"` -match `^Power` |
| `$` | Fin de la chaîne | `"PowerShell"` -match `Shell$` |
| `*` | 0 ou plusieurs répétitions | `"aaa"` -match `a*` |
| `+` | 1 ou plusieurs répétitions | `"aaa"` -match `a+` |
| `?` | 0 ou 1 répétition | `"color"` -match `colou?r` |
| `\` | Caractère d'échappement | `"2+2=4"` -match `2\+2` |
| `|` | Alternative (OU) | `"cat"` -match `cat|dog` |
| `[]` | Classe de caractères | `"a"` -match `[aeiou]` |
| `()` | Groupe de capture | `"PowerShell"` -match `(Power)(.*)` |
| `{}` | Nombre précis de répétitions | `"aaa"` -match `a{3}` |

### Exemples pratiques

```powershell
# Début et fin de chaîne
"PowerShell" -match "^Power"      # $true (commence par "Power")
"PowerShell" -match "Shell$"      # $true (termine par "Shell")
"PowerShell" -match "^PowerShell$" # $true (correspond exactement)

# Répétitions
"file.txt" -match "f.*txt"        # $true (f suivi de n'importe quoi, puis txt)
"aaa" -match "a+"                 # $true (un ou plusieurs "a")
"color" -match "colou?r"          # $true (le "u" est optionnel)

# Alternatives
"cat" -match "cat|dog"            # $true (soit "cat" soit "dog")
"dog" -match "cat|dog"            # $true

# Échappement des caractères spéciaux
"5*3=15" -match "5\*3"            # $true (le * est échappé)
```

## 🧩 Classes de caractères et raccourcis

Les classes de caractères vous permettent de définir des ensembles de caractères acceptables.

### Classes de caractères courantes

```powershell
# Plages de caractères
"A" -match "[A-Z]"        # $true (toute lettre majuscule)
"x" -match "[a-z]"        # $true (toute lettre minuscule)
"7" -match "[0-9]"        # $true (tout chiffre)

# Négation avec [^...]
"A" -match "[^a-z]"       # $true (tout sauf une lettre minuscule)
"5" -match "[^0-4]"       # $true (tout sauf les chiffres 0 à 4)

# Ensembles prédéfinis
"9" -match "\d"           # $true (équivalent à [0-9])
"A" -match "\w"           # $true (caractère alphanumerique, [a-zA-Z0-9_])
" " -match "\s"           # $true (espace blanc)

# Négations des ensembles prédéfinis
"!" -match "\D"           # $true (tout sauf un chiffre)
"$" -match "\W"           # $true (tout sauf un caractère alphanumérique)
"A" -match "\S"           # $true (tout sauf un espace blanc)
```

### Raccourcis courants

| Raccourci | Description | Équivalent |
|-----------|-------------|------------|
| `\d` | Chiffre | `[0-9]` |
| `\D` | Non-chiffre | `[^0-9]` |
| `\w` | Caractère alphanumérique | `[a-zA-Z0-9_]` |
| `\W` | Non-alphanumérique | `[^a-zA-Z0-9_]` |
| `\s` | Espace blanc | `[ \t\r\n\f]` |
| `\S` | Non-espace blanc | `[^ \t\r\n\f]` |

## 🔄 Quantificateurs

Les quantificateurs déterminent combien de fois un élément peut apparaître.

| Quantificateur | Description | Exemple |
|----------------|-------------|---------|
| `*` | 0 ou plus | `\d*` (zéro ou plusieurs chiffres) |
| `+` | 1 ou plus | `\d+` (au moins un chiffre) |
| `?` | 0 ou 1 | `\d?` (zéro ou un chiffre) |
| `{n}` | Exactement n | `\d{3}` (exactement 3 chiffres) |
| `{n,}` | Au moins n | `\d{2,}` (2 chiffres ou plus) |
| `{n,m}` | Entre n et m | `\d{2,4}` (entre 2 et 4 chiffres) |

### Exemples pratiques

```powershell
# Validation d'un code postal français
"75001" -match "^\d{5}$"         # $true (exactement 5 chiffres)

# Validation d'un numéro de téléphone (format simple)
"0123456789" -match "^0\d{9}$"   # $true (commence par 0, suivi de 9 chiffres)

# Validation d'un identifiant (lettres, chiffres, underscore)
"user_123" -match "^\w+$"        # $true (uniquement des caractères alphanumériques)

# Validation d'une date au format JJ/MM/AAAA
"31/12/2023" -match "^\d{2}/\d{2}/\d{4}$"  # $true
```

## 📦 Groupes de capture

Les groupes de capture vous permettent d'extraire des parties spécifiques d'une chaîne correspondant à votre motif.

```powershell
# Exemple simple
$texte = "PowerShell 7.1"
if ($texte -match "PowerShell (\d+\.\d+)") {
    $version = $matches[1]  # $version contient "7.1"
    Write-Host "Version trouvée : $version"
}

# Plusieurs groupes
$email = "john.doe@example.com"
if ($email -match "^([^@]+)@([^@]+)$") {
    $utilisateur = $matches[1]  # "john.doe"
    $domaine = $matches[2]      # "example.com"
    Write-Host "Utilisateur : $utilisateur, Domaine : $domaine"
}
```

### La variable automatique `$matches`

Lorsqu'une opération `-match` réussit, PowerShell remplit automatiquement la variable `$matches` :
- `$matches[0]` contient la correspondance complète
- `$matches[1]`, `$matches[2]`, etc. contiennent les groupes de capture

```powershell
$texte = "Le fichier image.jpg pèse 2.5 MB"
if ($texte -match "(\w+\.jpg) pèse (\d+\.\d+) (\w+)") {
    Write-Host "Fichier : $($matches[1])"    # "image.jpg"
    Write-Host "Taille : $($matches[2])"     # "2.5"
    Write-Host "Unité : $($matches[3])"      # "MB"
}
```

### Groupes nommés

Vous pouvez nommer vos groupes pour faciliter leur utilisation :

```powershell
$texte = "Le fichier image.jpg pèse 2.5 MB"
if ($texte -match "(?<fichier>\w+\.jpg) pèse (?<taille>\d+\.\d+) (?<unite>\w+)") {
    Write-Host "Fichier : $($matches.fichier)"  # "image.jpg"
    Write-Host "Taille : $($matches.taille)"    # "2.5"
    Write-Host "Unité : $($matches.unite)"      # "MB"
}
```

## 🔄 L'opérateur `-replace`

L'opérateur `-replace` permet de remplacer du texte en utilisant des expressions régulières.

Syntaxe : `chaîne -replace modèle, remplacement`

```powershell
# Remplacement simple
"Hello World" -replace "World", "PowerShell"  # "Hello PowerShell"

# Avec une expression régulière
"Le prix est 15,99 €" -replace "\d+,\d+", "20"  # "Le prix est 20 €"

# Utilisation des groupes de capture dans le remplacement
"John Smith" -replace "(\w+) (\w+)", "$2, $1"  # "Smith, John"

# Suppression de texte (en remplaçant par une chaîne vide)
"Texte (commentaire)" -replace "\s*\([^)]*\)", ""  # "Texte"
```

## 🧹 Filtrage avec les expressions régulières

Les expressions régulières sont particulièrement utiles pour filtrer des données.

### Filtrage de fichiers

```powershell
# Trouver tous les fichiers image
Get-ChildItem -Path C:\Images | Where-Object { $_.Name -match "\.(?:jpg|png|gif)$" }

# Trouver les fichiers dont le nom contient une date au format AAAA-MM-JJ
Get-ChildItem | Where-Object { $_.Name -match "\d{4}-\d{2}-\d{2}" }
```

### Filtrage de chaînes

```powershell
# Filtrer un tableau de chaînes
$textes = @("info@exemple.com", "contact@entreprise.fr", "pas_un_email", "autre@domaine.com")
$emails = $textes | Where-Object { $_ -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" }
$emails  # Affiche uniquement les adresses email valides
```

### Filtrage d'objets

```powershell
# Rechercher des processus dont le nom commence par "p"
Get-Process | Where-Object { $_.Name -match "^p" }

# Filtrer des utilisateurs par modèle spécifique
Get-LocalUser | Where-Object { $_.Name -match "^admin" -or $_.Description -match "temporaire" }
```

## 📚 Cas d'utilisation courants

### Validation d'entrées

```powershell
# Validation d'adresse email
function Test-Email {
    param([string]$Email)
    return $Email -match "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
}

# Validation de mot de passe (au moins 8 caractères, 1 majuscule, 1 chiffre)
function Test-Password {
    param([string]$Password)
    return $Password -match "^(?=.*[A-Z])(?=.*\d).{8,}$"
}
```

### Extraction de données

```powershell
# Extraire tous les liens d'une page HTML
$html = Get-Content -Path "page.html" -Raw
$pattern = 'href="([^"]+)"'
$liens = [regex]::Matches($html, $pattern) | ForEach-Object { $_.Groups[1].Value }

# Extraire les adresses IP d'un fichier log
$log = Get-Content -Path "system.log"
$pattern = "\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
$ips = $log | ForEach-Object {
    if ($_ -match $pattern) { $matches[0] }
}
$ips = $ips | Sort-Object -Unique  # Éliminer les doublons
```

### Transformation de données

```powershell
# Convertir des noms de variables de camelCase à snake_case
$camelCase = "firstNameLastName"
$snakeCase = $camelCase -replace "([a-z])([A-Z])", '$1_$2' -replace "([A-Z])([A-Z][a-z])", '$1_$2'
$snakeCase = $snakeCase.ToLower()  # "first_name_last_name"

# Formater des numéros de téléphone
$telephones = @("0123456789", "01 23 45 67 89", "+33123456789")
$telephones | ForEach-Object {
    $_ -replace "^(?:\+33|0)(?:\s*)?(\d)(?:\s*)?(\d{2})(?:\s*)?(\d{2})(?:\s*)?(\d{2})(?:\s*)?(\d{2})$", "0$1 $2 $3 $4 $5"
}
```

## 🔎 Astuces pour les expressions régulières

### Utilisation de la classe `[regex]`

PowerShell permet également d'utiliser la classe `[regex]` pour des opérations plus avancées :

```powershell
# Trouver toutes les correspondances (pas seulement la première)
$texte = "Fichiers: image1.jpg, image2.png, document.pdf"
$pattern = "\w+\.(jpg|png|pdf)"
$matches = [regex]::Matches($texte, $pattern)

foreach ($match in $matches) {
    Write-Host "Fichier trouvé : $($match.Value)"
}

# Vérifier si une chaîne correspond exactement à un modèle
$estEmail = [regex]::IsMatch("info@exemple.com", "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
```

### Options des expressions régulières

Vous pouvez modifier le comportement des expressions régulières avec des options :

```powershell
# Recherche insensible à la casse
[regex]::IsMatch("PowerShell", "powershell", "IgnoreCase")

# Plusieurs options
$options = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Multiline
[regex]::IsMatch("Texte sur\nplusieurs lignes", "^Texte", $options)
```

### Déboguer vos expressions régulières

Les expressions régulières peuvent être complexes. Voici quelques astuces pour les déboguer :

1. **Construisez progressivement** : Commencez par un motif simple, puis ajoutez des éléments.
2. **Testez par parties** : Validez chaque partie de votre expression séparément.
3. **Utilisez des sites web** comme regex101.com pour visualiser vos expressions.
4. **Utilisez la commande verbose** pour rendre vos regex plus lisibles :

```powershell
$pattern = @"
(?x)         # Mode verbeux
^            # Début de la chaîne
(\d{2})      # Jour (2 chiffres)
/            # Séparateur
(\d{2})      # Mois (2 chiffres)
/            # Séparateur
(\d{4})      # Année (4 chiffres)
$            # Fin de la chaîne
"@

"31/12/2023" -match $pattern  # $true
```

## ✏️ Exercices pratiques

**Exercice 1: Validation simple**
```powershell
# Créez une fonction qui vérifie si une chaîne est un code postal français valide (5 chiffres)
function Test-CodePostal {
    param([string]$Code)
    # Complétez le code...
}

# Testez avec : "75001", "A1234", "123456"
```

**Exercice 2: Extraction d'informations**
```powershell
# Pour la chaîne suivante, extrayez le nom du fichier, sa taille et son unité
$info = "Le fichier document.xlsx a une taille de 2.5 MB"
# Complétez le code...
```

**Exercice 3: Transformation de données**
```powershell
# Convertissez ces numéros de téléphone au format "XX XX XX XX XX"
$telephones = @("0612345678", "06 87 65 43 21", "+33712345678")
# Complétez le code...
```

**Exercice 4: Filtrage avancé**
```powershell
# Filtrez cette liste pour ne garder que les noms de fichiers valides (lettres, chiffres, extension)
$noms = @("fichier-1.txt", "mon_rapport.docx", "invalid/file.pdf", "script.ps1", "..hidden")
# Complétez le code...
```

**Exercice 5: Validation des entrées**
```powershell
# Créez une fonction qui vérifie si un mot de passe est suffisamment fort:
# - Au moins 8 caractères
# - Au moins une lettre majuscule
# - Au moins une lettre minuscule
# - Au moins un chiffre
# - Au moins un caractère spécial (!@#$%^&*()_+)
function Test-StrongPassword {
    param([string]$Password)
    # Complétez le code...
}
```

---

Dans le prochain cours, nous découvrirons comment créer vos premiers scripts PowerShell `.ps1`, qui vous permettront d'automatiser des tâches complexes en utilisant toutes les notions que nous avons vues jusqu'à présent.

⏭️ [Scripting : premiers scripts `.ps1`](/02-syntaxe-fondamentaux/06-premiers-scripts.md)
