# Module 3 - Section 3-2 : Variables, typage, tableaux, hashtables

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📝 Variables et typage dans PowerShell

### Introduction aux variables

Dans PowerShell, les variables vous permettent de stocker des informations temporairement pour une utilisation ultérieure. Elles sont toujours précédées du symbole `$` et peuvent contenir des lettres, des chiffres et des caractères spéciaux.

```powershell
# Création d'une variable simple
$nom = "Jean"
$age = 30

# Affichage des variables
Write-Host "Bonjour $nom, vous avez $age ans."
```

### Le typage dans PowerShell

PowerShell est un langage à typage dynamique, ce qui signifie qu'il détermine automatiquement le type de données stockées dans une variable. Cependant, vous pouvez également définir explicitement le type.

```powershell
# Typage automatique
$nombre = 10      # PowerShell reconnaît que c'est un entier
$texte = "Bonjour"  # PowerShell reconnaît que c'est une chaîne

# Vérification du type
$nombre.GetType().Name  # Retourne "Int32"
$texte.GetType().Name   # Retourne "String"

# Typage explicite
[int]$age = 30
[string]$prenom = "Marie"
[datetime]$naissance = "01/01/1990"
```

### Types de données courants

PowerShell prend en charge de nombreux types de données :

- `[string]` : chaînes de caractères
- `[int]` : entiers
- `[decimal]` ou `[double]` : nombres à virgule flottante
- `[bool]` : valeurs booléennes (True/False)
- `[datetime]` : dates et heures
- `[array]` : tableaux
- `[hashtable]` : tables de hachage

```powershell
[string]$message = "Bonjour"
[int]$compteur = 42
[bool]$estActif = $true
[datetime]$date = Get-Date
```

## 📚 Tableaux (Arrays)

Les tableaux permettent de stocker plusieurs valeurs dans une seule variable.

### Création de tableaux

```powershell
# Méthode 1 : création avec des valeurs initiales
$fruits = "Pomme", "Banane", "Orange", "Fraise"

# Méthode 2 : création avec @()
$nombres = @(1, 2, 3, 4, 5)

# Tableau de types différents
$divers = @("texte", 42, $true, (Get-Date))

# Tableau vide
$tableau_vide = @()
```

### Accès aux éléments du tableau

```powershell
# Accès par index (les index commencent à 0)
$fruits[0]    # Retourne "Pomme" (premier élément)
$fruits[2]    # Retourne "Orange" (troisième élément)

# Accès au dernier élément
$fruits[-1]   # Retourne "Fraise" (dernier élément)

# Sélection de plusieurs éléments
$fruits[1..3] # Retourne "Banane", "Orange", "Fraise"
```

### Modification des tableaux

```powershell
# Modification d'un élément
$fruits[1] = "Kiwi"   # Remplace "Banane" par "Kiwi"

# Ajout d'éléments à un tableau
$fruits += "Mangue"   # Ajoute "Mangue" à la fin du tableau

# Taille du tableau
$fruits.Count         # Nombre d'éléments dans le tableau

# Parcourir un tableau
foreach ($fruit in $fruits) {
    Write-Host "Fruit : $fruit"
}
```

## 🔑 Hashtables (Tables de hachage)

Les hashtables sont des structures de données qui stockent des paires clé-valeur, similaires aux dictionnaires dans d'autres langages.

### Création de hashtables

```powershell
# Création d'une hashtable
$personne = @{
    Nom = "Dupont"
    Prenom = "Pierre"
    Age = 35
    Ville = "Paris"
}

# Hashtable vide
$params = @{}
```

### Accès aux valeurs d'une hashtable

```powershell
# Accès par clé
$personne["Nom"]      # Retourne "Dupont"
$personne.Prenom      # Retourne "Pierre" (notation avec point)

# Vérification de l'existence d'une clé
$personne.ContainsKey("Age")    # Retourne $true
```

### Modification d'une hashtable

```powershell
# Ajout d'une nouvelle paire clé-valeur
$personne["Email"] = "pierre.dupont@example.com"
$personne.Telephone = "0123456789"

# Modification d'une valeur existante
$personne["Age"] = 36

# Suppression d'une entrée
$personne.Remove("Ville")
```

### Parcourir une hashtable

```powershell
# Parcourir les clés
foreach ($cle in $personne.Keys) {
    Write-Host "$cle : $($personne[$cle])"
}

# Parcourir les paires clé-valeur
foreach ($item in $personne.GetEnumerator()) {
    Write-Host "$($item.Key) : $($item.Value)"
}
```

## 🔄 Conversion entre types

PowerShell peut généralement convertir automatiquement entre les types, mais vous pouvez aussi le faire explicitement :

```powershell
# Conversion de chaîne en entier
$nombre_texte = "42"
[int]$nombre = $nombre_texte    # Conversion explicite

# Conversion d'entier en chaîne
$age = 30
$age_texte = $age.ToString()

# Conversion de tableau en chaîne
$fruits -join ", "    # Retourne "Pomme, Kiwi, Orange, Fraise, Mangue"
```

## 💡 Conseils pratiques

1. Utilisez des noms de variables descriptifs qui reflètent leur contenu
2. Privilégiez le typage explicite pour les scripts complexes
3. Pour les débutants, afficher le type d'une variable peut aider à comprendre :
   ```powershell
   $variable = "texte"
   $variable.GetType().FullName
   ```
4. Les hashtables sont parfaites pour stocker des configurations ou des paramètres
5. Utilisez les tableaux quand vous avez une collection d'éléments similaires

## ✏️ Exercices pratiques

**Exercice 1 : Variables et typage**
```powershell
# Créez deux variables typées : une pour votre âge et une pour votre nom
# Affichez une phrase utilisant ces deux variables
```

**Exercice 2 : Tableaux**
```powershell
# Créez un tableau contenant 5 couleurs
# Affichez la première et la dernière couleur
# Ajoutez une nouvelle couleur et affichez le tableau complet
```

**Exercice 3 : Hashtables**
```powershell
# Créez une hashtable avec les informations d'un livre (titre, auteur, année)
# Ajoutez une nouvelle propriété "genre"
# Affichez toutes les informations du livre
```

---

Dans le prochain cours, nous aborderons les opérateurs logiques, arithmétiques et de comparaison dans PowerShell.
