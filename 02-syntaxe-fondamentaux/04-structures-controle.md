# Module 3 - Section 3-4 : Structures de contrôle (`if`, `switch`, `for`, `foreach`, `while`)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 🔄 Introduction aux structures de contrôle

Les structures de contrôle sont essentielles dans tout langage de programmation. Elles vous permettent de :
- Exécuter du code conditionnellement (si certaines conditions sont remplies)
- Répéter des opérations (boucles)
- Contrôler le flux d'exécution de vos scripts

PowerShell propose plusieurs structures de contrôle que nous allons explorer dans cette section.

## 🔍 Structures conditionnelles

### La structure `if-else`

La structure `if` vous permet d'exécuter du code uniquement si une condition est remplie (`$true`).

Syntaxe de base :

```powershell
if (condition) {
    # Code exécuté si la condition est vraie ($true)
}
```

Avec une clause `else` :

```powershell
if (condition) {
    # Code exécuté si la condition est vraie
} else {
    # Code exécuté si la condition est fausse
}
```

Avec des conditions multiples :

```powershell
if (condition1) {
    # Code exécuté si condition1 est vraie
} elseif (condition2) {
    # Code exécuté si condition1 est fausse mais condition2 est vraie
} else {
    # Code exécuté si toutes les conditions sont fausses
}
```

#### Exemples pratiques

```powershell
# Exemple simple
$temperature = 25

if ($temperature -gt 30) {
    Write-Host "Il fait très chaud aujourd'hui !"
} elseif ($temperature -gt 20) {
    Write-Host "La température est agréable."
} else {
    Write-Host "Il fait plutôt frais."
}
# Résultat : "La température est agréable."

# Exemple avec opérateurs logiques
$age = 17
$accompagne = $true

if (($age -ge 18) -or ($age -ge 12 -and $accompagne)) {
    Write-Host "Vous pouvez voir ce film."
} else {
    Write-Host "Vous ne pouvez pas voir ce film."
}
# Résultat : "Vous pouvez voir ce film." (car accompagné)
```

### La structure `switch`

Lorsque vous avez plusieurs conditions à vérifier pour une même variable, la structure `switch` est souvent plus lisible qu'une série de `if-elseif`.

Syntaxe de base :

```powershell
switch (expression) {
    valeur1 { # Code si expression = valeur1 }
    valeur2 { # Code si expression = valeur2 }
    valeur3 { # Code si expression = valeur3 }
    default { # Code par défaut si aucune correspondance }
}
```

#### Exemples pratiques

```powershell
# Exemple simple
$jour = "Mardi"

switch ($jour) {
    "Lundi" { Write-Host "Début de semaine" }
    "Mardi" { Write-Host "Deuxième jour" }
    "Mercredi" { Write-Host "Milieu de semaine" }
    "Jeudi" { Write-Host "Avant-dernier jour" }
    "Vendredi" { Write-Host "Fin de semaine" }
    default { Write-Host "C'est le weekend !" }
}
# Résultat : "Deuxième jour"

# Utilisation des caractères génériques avec -wildcard
$fichier = "rapport.txt"

switch -wildcard ($fichier) {
    "*.txt" { Write-Host "Fichier texte" }
    "*.jpg" { Write-Host "Fichier image JPG" }
    "*.pdf" { Write-Host "Document PDF" }
    "rapport*" { Write-Host "C'est un rapport" }
    default { Write-Host "Type de fichier inconnu" }
}
# Résultat : "Fichier texte" puis "C'est un rapport"
# (par défaut, switch continue l'évaluation après une correspondance)

# Utilisation de -regex pour les expressions régulières
$texte = "Mon numéro est 0612345678"

switch -regex ($texte) {
    "^Bonjour" { Write-Host "Le texte commence par 'Bonjour'" }
    "[0-9]{10}$" { Write-Host "Le texte se termine par un numéro à 10 chiffres" }
    "\d{2}:\d{2}" { Write-Host "Le texte contient une heure au format HH:MM" }
    "numéro" { Write-Host "Le texte contient le mot 'numéro'" }
}
# Résultat : "Le texte contient le mot 'numéro'"
```

#### Options de `switch`

- `-wildcard` : Permet d'utiliser des caractères génériques (`*`, `?`) dans les conditions
- `-regex` : Permet d'utiliser des expressions régulières
- `-exact` : Recherche une correspondance exacte (par défaut)
- `-casesensitive` : Sensible à la casse (par défaut insensible)
- `-file` : Traiter chaque ligne d'un fichier comme une entrée distincte

Pour arrêter l'évaluation après la première correspondance, utilisez `break` :

```powershell
switch ($valeur) {
    condition1 {
        # Code pour condition1
        break  # Arrête l'évaluation après cette correspondance
    }
    condition2 { # Code pour condition2 }
}
```

## 🔁 Structures de boucles

Les boucles vous permettent de répéter des opérations plusieurs fois, soit avec un nombre d'itérations défini, soit jusqu'à ce qu'une condition soit satisfaite.

### Boucle `for`

La boucle `for` est idéale quand vous connaissez à l'avance le nombre d'itérations.

Syntaxe :

```powershell
for (initialisation; condition; incrémentation) {
    # Code à répéter
}
```

#### Exemples pratiques

```powershell
# Boucle simple de 1 à 5
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Itération numéro $i"
}
# Affiche : Itération numéro 1 à 5

# Parcourir un tableau avec for
$fruits = @("Pomme", "Banane", "Orange", "Fraise")
for ($i = 0; $i -lt $fruits.Count; $i++) {
    Write-Host "Fruit $($i+1): $($fruits[$i])"
}
# Affiche : Fruit 1: Pomme, Fruit 2: Banane, etc.

# Boucle décrémentale
for ($i = 10; $i -ge 1; $i--) {
    Write-Host "Compte à rebours: $i"
}
# Affiche : Compte à rebours de 10 à 1
```

### Boucle `foreach`

La boucle `foreach` est idéale pour parcourir les éléments d'une collection (tableau, liste, résultats de commande).

Syntaxe :

```powershell
foreach ($élément in $collection) {
    # Code à exécuter pour chaque élément
}
```

#### Exemples pratiques

```powershell
# Parcourir un tableau simple
$couleurs = @("Rouge", "Vert", "Bleu", "Jaune")
foreach ($couleur in $couleurs) {
    Write-Host "Couleur: $couleur"
}
# Affiche : Couleur: Rouge, Couleur: Vert, etc.

# Avec des résultats de commande
foreach ($fichier in Get-ChildItem -Path C:\Temp -Filter *.txt) {
    Write-Host "Fichier texte trouvé: $($fichier.Name)"
}
# Affiche tous les fichiers .txt dans C:\Temp

# Traitement de données
$notes = @(15, 12, 18, 10, 14)
$somme = 0
foreach ($note in $notes) {
    $somme += $note
}
$moyenne = $somme / $notes.Count
Write-Host "La moyenne est de: $moyenne"
# Calcule et affiche la moyenne des notes
```

### Boucle `while`

La boucle `while` répète du code tant qu'une condition reste vraie.

Syntaxe :

```powershell
while (condition) {
    # Code à répéter tant que la condition est vraie
}
```

#### Exemples pratiques

```powershell
# Boucle simple
$compteur = 1
while ($compteur -le 5) {
    Write-Host "Compteur: $compteur"
    $compteur++
}
# Affiche : Compteur: 1 à 5

# Attente conditionnelle
$timeout = 30
$debut = Get-Date
while (((Get-Date) - $debut).TotalSeconds -lt $timeout) {
    # Simulons une vérification
    $service = Get-Service "Spooler"
    if ($service.Status -eq "Running") {
        Write-Host "Le service est démarré !"
        break  # Sort de la boucle
    }
    Write-Host "En attente du démarrage du service..."
    Start-Sleep -Seconds 2
}
```

### Boucle `do-while` et `do-until`

Ces variantes exécutent le code au moins une fois, puis vérifient la condition.

Syntaxe :

```powershell
# do-while : continue tant que la condition est vraie
do {
    # Code à exécuter
} while (condition)

# do-until : continue jusqu'à ce que la condition soit vraie
do {
    # Code à exécuter
} until (condition)
```

#### Exemples pratiques

```powershell
# do-while : s'exécute au moins une fois
$nombre = 1
do {
    Write-Host "Nombre actuel: $nombre"
    $nombre++
} while ($nombre -le 5)
# Affiche : Nombre actuel: 1 à 5

# do-until : s'exécute jusqu'à ce que la condition soit vraie
$essai = 0
do {
    $essai++
    $resultat = Get-Random -Minimum 1 -Maximum 10
    Write-Host "Essai $essai : $resultat"
} until ($resultat -eq 7 -or $essai -ge 10)
# S'arrête quand on obtient 7 ou après 10 essais
```

## 🚩 Contrôle du flux d'exécution

Dans les boucles, vous pouvez utiliser des instructions spéciales pour contrôler l'exécution.

### Instructions `break` et `continue`

- `break` : Sort complètement de la boucle
- `continue` : Passe directement à l'itération suivante

```powershell
# Exemple de break
foreach ($nombre in 1..10) {
    if ($nombre -eq 5) {
        Write-Host "On s'arrête à 5!"
        break  # Sort de la boucle
    }
    Write-Host "Nombre: $nombre"
}
# Affiche : Nombre: 1 à 4, puis "On s'arrête à 5!"

# Exemple de continue
foreach ($nombre in 1..10) {
    if ($nombre % 2 -eq 0) {
        continue  # Passe à l'itération suivante
    }
    Write-Host "Nombre impair: $nombre"
}
# Affiche uniquement les nombres impairs
```

### Boucles imbriquées

Vous pouvez imbriquer des boucles les unes dans les autres.

```powershell
# Table de multiplication
for ($i = 1; $i -le 5; $i++) {
    Write-Host "Table de $i :"
    for ($j = 1; $j -le 10; $j++) {
        $resultat = $i * $j
        Write-Host "$i x $j = $resultat"
    }
    Write-Host "-----------"
}
```

### Étiquettes (labels) et contrôle avancé

Dans les boucles imbriquées, vous pouvez utiliser des étiquettes pour spécifier quelle boucle `break` ou `continue` doit affecter.

```powershell
:boucle_externe foreach ($i in 1..3) {
    :boucle_interne foreach ($j in 1..3) {
        if ($i -eq 2 -and $j -eq 2) {
            Write-Host "Sortie de la boucle externe !"
            break boucle_externe
        }
        Write-Host "i=$i, j=$j"
    }
}
```

## 💡 Conseils et bonnes pratiques

1. **Évitez les boucles infinies** : Assurez-vous toujours que vos conditions de sortie peuvent être satisfaites.

2. **Choisissez la bonne structure** :
   - `for` : Quand vous connaissez le nombre d'itérations
   - `foreach` : Pour parcourir des collections
   - `while` : Quand vous ne savez pas combien d'itérations sont nécessaires

3. **Performances** :
   - `foreach` est généralement plus rapide que `for` pour parcourir des collections
   - Évitez de modifier la collection que vous parcourez dans une boucle `foreach`
   - Pour des performances optimales avec de grandes collections, utilisez le cmdlet `ForEach-Object` avec le pipeline

4. **Lisibilité** :
   - Indentez correctement le code dans les structures
   - Utilisez des commentaires pour expliquer la logique complexe
   - Préférez `switch` à une longue série de `if-elseif` quand c'est possible

## ✏️ Exercices pratiques

**Exercice 1 : Structure if-else**
```powershell
# Créez un script qui demande l'âge de l'utilisateur et affiche un message différent selon les tranches d'âge :
# - Moins de 18 ans : "Vous êtes mineur"
# - Entre 18 et 65 ans : "Vous êtes majeur"
# - Plus de 65 ans : "Vous êtes retraité"

$age = Read-Host "Quel est votre âge ?"
# Complétez le code...
```

**Exercice 2 : Structure switch**
```powershell
# Créez un script qui demande à l'utilisateur un jour de la semaine et affiche si :
# - C'est un jour de semaine (Lundi à Vendredi)
# - C'est le weekend (Samedi et Dimanche)
# - Message spécial pour Mercredi ("Milieu de semaine !")

$jour = Read-Host "Entrez un jour de la semaine"
# Complétez le code...
```

**Exercice 3 : Boucle for**
```powershell
# Écrivez une boucle qui affiche la table de multiplication du nombre de votre choix (de 1 à 10)

$nombre = 7  # Changez ce nombre si vous voulez
# Complétez le code...
```

**Exercice 4 : Boucle foreach**
```powershell
# Créez un tableau de noms de fichiers puis parcourez-le pour afficher :
# - Si le fichier existe sur le disque
# - Sa taille s'il existe

$fichiers = @("C:\Windows\explorer.exe", "C:\fichier_inexistant.txt", "C:\Windows\notepad.exe")
# Complétez le code...
```

**Exercice 5 : Boucle while**
```powershell
# Créez un jeu simple où l'ordinateur génère un nombre aléatoire entre 1 et 100,
# et l'utilisateur doit le deviner. Le script indique si le nombre proposé est trop grand ou trop petit.

$nombreSecret = Get-Random -Minimum 1 -Maximum 101
# Complétez le code...
```

---

Dans le prochain cours, nous aborderons les expressions régulières et le filtrage dans PowerShell, des outils puissants pour manipuler et rechercher du texte.

⏭️ [Expressions régulières et filtrage](/02-syntaxe-fondamentaux/05-regex-filtrage.md)
