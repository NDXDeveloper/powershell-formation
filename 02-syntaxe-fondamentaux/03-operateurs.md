# Module 3 - Section 3-3 : Opérateurs (logiques, arithmétiques, comparaison)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 🧮 Opérateurs dans PowerShell

Les opérateurs sont des symboles ou des mots-clés qui vous permettent d'effectuer des actions comme des calculs, des comparaisons ou des opérations logiques. PowerShell propose différents types d'opérateurs qui vont vous aider à manipuler vos données.

## 🔢 Opérateurs arithmétiques

Les opérateurs arithmétiques vous permettent d'effectuer des calculs mathématiques de base.

| Opérateur | Description | Exemple | Résultat |
|-----------|-------------|---------|----------|
| `+` | Addition | `5 + 3` | `8` |
| `-` | Soustraction | `7 - 2` | `5` |
| `*` | Multiplication | `4 * 6` | `24` |
| `/` | Division | `10 / 2` | `5` |
| `%` | Modulo (reste de division) | `7 % 3` | `1` |

### Exemples pratiques

```powershell
# Opérations arithmétiques simples
$a = 10
$b = 3

# Addition
$somme = $a + $b       # 13

# Soustraction
$difference = $a - $b  # 7

# Multiplication
$produit = $a * $b     # 30

# Division
$quotient = $a / $b    # 3.33333333333333

# Modulo (reste de la division)
$reste = $a % $b       # 1

# Utilisation dans des expressions
$result = ($a + $b) * 2  # (10 + 3) * 2 = 26
```

### Attention aux types de données

PowerShell effectue automatiquement des conversions de type lors des opérations arithmétiques :

```powershell
# Division avec différents types
10 / 3          # Résultat : 3.33333333333333 (nombre décimal)
[int](10 / 3)   # Résultat : 3 (conversion forcée en entier)

# Addition avec des chaînes
"5" + "3"       # Résultat : "53" (concaténation de chaînes)
[int]"5" + 3    # Résultat : 8 (conversion de "5" en entier puis addition)
```

## 🔍 Opérateurs de comparaison

Les opérateurs de comparaison vous permettent de comparer des valeurs et retournent toujours `$true` ou `$false`.

| Opérateur | Description | Exemple | Résultat |
|-----------|-------------|---------|----------|
| `-eq` | Égal à | `5 -eq 5` | `$true` |
| `-ne` | Non égal à | `5 -ne 3` | `$true` |
| `-gt` | Supérieur à | `7 -gt 3` | `$true` |
| `-ge` | Supérieur ou égal à | `5 -ge 5` | `$true` |
| `-lt` | Inférieur à | `3 -lt 7` | `$true` |
| `-le` | Inférieur ou égal à | `5 -le 5` | `$true` |
| `-like` | Correspondance avec caractères génériques | `"Test" -like "T*"` | `$true` |
| `-notlike` | Pas de correspondance avec caractères génériques | `"Test" -notlike "P*"` | `$true` |
| `-match` | Correspondance avec expression régulière | `"Test" -match "^T.+"` | `$true` |
| `-notmatch` | Pas de correspondance avec expression régulière | `"Test" -notmatch "^P.+"` | `$true` |
| `-contains` | Contient un élément (pour collections) | `@(1,2,3) -contains 2` | `$true` |
| `-notcontains` | Ne contient pas un élément | `@(1,2,3) -notcontains 4` | `$true` |
| `-in` | L'élément est dans la collection | `3 -in @(1,2,3)` | `$true` |
| `-notin` | L'élément n'est pas dans la collection | `4 -notin @(1,2,3)` | `$true` |

### Exemples pratiques

```powershell
# Comparaisons simples
$age = 25

$age -eq 25     # $true (égal)
$age -ne 30     # $true (non égal)
$age -gt 18     # $true (supérieur à)
$age -lt 21     # $false (inférieur à)
$age -ge 25     # $true (supérieur ou égal)
$age -le 30     # $true (inférieur ou égal)

# Comparaisons de chaînes
$nom = "Martin"
$nom -eq "martin"     # $true (insensible à la casse par défaut)
$nom -ceq "martin"    # $false (sensible à la casse avec -ceq)

# Utilisation de -like (caractères génériques)
$fichier = "document.txt"
$fichier -like "*.txt"    # $true
$fichier -like "doc*"     # $true
$fichier -notlike "*.pdf" # $true

# Utilisation de -match (expressions régulières)
$email = "user@example.com"
$email -match "^[a-z]+@[a-z]+\.[a-z]{2,}$"  # $true

# Utilisation avec des collections
$fruits = @("pomme", "banane", "orange")
$fruits -contains "banane"        # $true
"orange" -in $fruits              # $true
$fruits -notcontains "fraise"     # $true
"kiwi" -notin $fruits             # $true
```

### Sensibilité à la casse

Par défaut, les comparaisons de chaînes sont insensibles à la casse. Vous pouvez utiliser des variantes sensibles à la casse en ajoutant "c" :

| Insensible à la casse | Sensible à la casse |
|-----------------------|--------------------|
| `-eq` | `-ceq` |
| `-ne` | `-cne` |
| `-like` | `-clike` |
| `-match` | `-cmatch` |

```powershell
"PowerShell" -eq "powershell"     # $true (insensible à la casse)
"PowerShell" -ceq "powershell"    # $false (sensible à la casse)
```

## 🔄 Opérateurs logiques

Les opérateurs logiques vous permettent de combiner ou d'inverser des conditions logiques.

| Opérateur | Description | Exemple | Résultat |
|-----------|-------------|---------|----------|
| `-and` | ET logique | `$true -and $true` | `$true` |
| `-or` | OU logique | `$true -or $false` | `$true` |
| `-xor` | OU exclusif | `$true -xor $true` | `$false` |
| `-not` | NON logique | `-not $false` | `$true` |
| `!` | NON logique (alternative) | `!$false` | `$true` |

### Exemples pratiques

```powershell
$age = 25
$estEtudiant = $true

# Vérifier si une personne est un étudiant ET a plus de 18 ans
$estEtudiant -and ($age -gt 18)           # $true

# Vérifier si une personne a moins de 18 ans OU plus de 65 ans
($age -lt 18) -or ($age -gt 65)           # $false

# Inverser une condition
-not ($age -lt 18)                         # $true
!($age -lt 18)                            # $true (alternative)

# Combiner plusieurs conditions
($age -ge 18) -and ($age -le 30) -and $estEtudiant  # $true
```

### Table de vérité

Pour mieux comprendre les opérateurs logiques, voici leurs tables de vérité :

**Opérateur -and** :
- `$true -and $true` = `$true`
- `$true -and $false` = `$false`
- `$false -and $true` = `$false`
- `$false -and $false` = `$false`

**Opérateur -or** :
- `$true -or $true` = `$true`
- `$true -or $false` = `$true`
- `$false -or $true` = `$true`
- `$false -or $false` = `$false`

**Opérateur -xor** (vrai si les valeurs sont différentes) :
- `$true -xor $true` = `$false`
- `$true -xor $false` = `$true`
- `$false -xor $true` = `$true`
- `$false -xor $false` = `$false`

**Opérateur -not** :
- `-not $true` = `$false`
- `-not $false` = `$true`

## 🔠 Opérateurs de chaînes

PowerShell propose aussi des opérateurs spécifiques pour manipuler les chaînes de caractères.

| Opérateur | Description | Exemple | Résultat |
|-----------|-------------|---------|----------|
| `+` | Concaténation | `"Hello" + " World"` | `"Hello World"` |
| `-join` | Joindre des éléments | `@("a", "b", "c") -join "-"` | `"a-b-c"` |
| `-split` | Diviser une chaîne | `"a,b,c" -split ","` | `@("a", "b", "c")` |
| `-replace` | Remplacer du texte | `"Hello World" -replace "World", "PowerShell"` | `"Hello PowerShell"` |

### Exemples pratiques

```powershell
# Concaténation
$prenom = "Jean"
$nom = "Dupont"
$nomComplet = $prenom + " " + $nom  # "Jean Dupont"

# Autre méthode de concaténation
$nomComplet = "$prenom $nom"        # "Jean Dupont"

# Joindre un tableau
$fruits = @("pomme", "banane", "orange")
$liste = $fruits -join ", "          # "pomme, banane, orange"

# Diviser une chaîne
$csv = "nom,prenom,age"
$colonnes = $csv -split ","          # @("nom", "prenom", "age")

# Remplacer du texte
$texte = "Bonjour le monde"
$nouveauTexte = $texte -replace "monde", "PowerShell"  # "Bonjour le PowerShell"
```

## 🧩 Opérateurs d'assignation

Les opérateurs d'assignation vous permettent d'attribuer des valeurs à des variables, parfois en effectuant une opération en même temps.

| Opérateur | Description | Exemple | Équivalent |
|-----------|-------------|---------|------------|
| `=` | Assignation simple | `$a = 5` | `$a = 5` |
| `+=` | Addition et assignation | `$a += 2` | `$a = $a + 2` |
| `-=` | Soustraction et assignation | `$a -= 1` | `$a = $a - 1` |
| `*=` | Multiplication et assignation | `$a *= 3` | `$a = $a * 3` |
| `/=` | Division et assignation | `$a /= 2` | `$a = $a / 2` |
| `%=` | Modulo et assignation | `$a %= 3` | `$a = $a % 3` |

### Exemples pratiques

```powershell
# Assignation simple
$compteur = 10

# Incrémentation
$compteur += 5      # $compteur vaut maintenant 15

# Décrémentation
$compteur -= 3      # $compteur vaut maintenant 12

# Multiplication
$compteur *= 2      # $compteur vaut maintenant 24

# Division
$compteur /= 4      # $compteur vaut maintenant 6

# Pour les chaînes
$message = "Hello"
$message += " World"  # $message vaut maintenant "Hello World"
```

## 💡 Utilisation pratique des opérateurs

### Dans les conditions

```powershell
$age = 25
$abonnement = "Premium"

if (($age -ge 18) -and ($abonnement -eq "Premium")) {
    Write-Host "Accès complet autorisé"
} elseif ($age -ge 18) {
    Write-Host "Accès basique autorisé"
} else {
    Write-Host "Accès refusé"
}
```

### Dans les filtres

```powershell
# Filtrer un tableau d'âges
$ages = @(15, 22, 17, 30, 42, 16, 25)
$adultes = $ages | Where-Object { $_ -ge 18 }  # @(22, 30, 42, 25)

# Filtrer des processus
Get-Process | Where-Object { $_.CPU -gt 10 -and $_.WorkingSet -gt 50MB }
```

### Dans les boucles

```powershell
$compteur = 1
while ($compteur -le 5) {
    Write-Host "Itération $compteur"
    $compteur += 1
}
```

## ✏️ Exercices pratiques

**Exercice 1 : Opérateurs arithmétiques**
```powershell
# Calculez l'aire d'un rectangle de longueur 7.5 et de largeur 3.2
# Calculez le périmètre du même rectangle
```

**Exercice 2 : Opérateurs de comparaison**
```powershell
# Créez une variable $temperature avec une valeur de votre choix
# Écrivez une condition qui affiche :
# - "Très froid" si la température est inférieure à 0
# - "Froid" si elle est entre 0 et 15
# - "Agréable" si elle est entre 15 et 25
# - "Chaud" si elle est supérieure à 25
```

**Exercice 3 : Opérateurs logiques**
```powershell
# Créez deux variables $estWeekEnd (booléen) et $heure (nombre de 0 à 23)
# Écrivez une condition qui affiche "Temps libre" si :
# - C'est le weekend, OU
# - Ce n'est pas le weekend mais l'heure est avant 9h ou après 18h
```

---

Dans le prochain cours, nous aborderons les structures de contrôle dans PowerShell, comme les conditions `if`, `switch` et les boucles `for`, `foreach` et `while`.
