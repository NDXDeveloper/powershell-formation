# Module 4 - Objets et traitement de données
## 4-2. Manipulation des objets (`Select-Object`, `Where-Object`, `Sort-Object`)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

Maintenant que vous comprenez ce qu'est un objet PowerShell, découvrons comment manipuler ces objets! PowerShell offre plusieurs cmdlets puissantes qui vous permettent de filtrer, trier et sélectionner les données exactement comme vous le souhaitez.

### 🔍 Les trois cmdlets essentielles

#### 1. `Select-Object` - Choisir les propriétés

Cette cmdlet vous permet de sélectionner uniquement les propriétés qui vous intéressent, comme prendre uniquement certains ingrédients d'une recette.

```powershell
# Afficher seulement le nom et la taille des fichiers
Get-ChildItem | Select-Object Name, Length
```

#### 2. `Where-Object` - Filtrer les objets

Cette cmdlet vous permet de filtrer les objets selon des conditions, comme garder uniquement les ingrédients qui correspondent à vos critères.

```powershell
# Afficher uniquement les processus qui utilisent plus de 100 MB de mémoire
Get-Process | Where-Object { $_.WorkingSet -gt 100MB }
```

#### 3. `Sort-Object` - Trier les objets

Cette cmdlet vous permet d'organiser vos objets dans un ordre spécifique, comme ranger vos ingrédients du plus léger au plus lourd.

```powershell
# Trier les fichiers par taille (du plus petit au plus grand)
Get-ChildItem | Sort-Object Length
```

### 🧠 Comprendre la syntaxe `$_` ou `$PSItem`

Dans les exemples ci-dessus, vous avez peut-être remarqué le `$_`. C'est une variable spéciale qui représente **l'objet courant** dans le pipeline. Vous pouvez aussi utiliser `$PSItem` qui est exactement la même chose.

```powershell
# Ces deux commandes sont identiques
Get-Process | Where-Object { $_.CPU -gt 10 }
Get-Process | Where-Object { $PSItem.CPU -gt 10 }
```

### 🛠️ Techniques avancées de `Select-Object`

#### Sélectionner un nombre limité d'objets

```powershell
# Sélectionner les 5 premiers fichiers
Get-ChildItem | Select-Object -First 5

# Sélectionner les 3 derniers processus
Get-Process | Select-Object -Last 3
```

#### Créer de nouvelles propriétés calculées

```powershell
# Ajouter une propriété qui convertit la taille en MB
Get-ChildItem | Select-Object Name, @{
    Name = 'SizeMB'
    Expression = { $_.Length / 1MB }
}
```

### 🔬 Techniques avancées de `Where-Object`

#### Combiner plusieurs conditions

```powershell
# Processus qui utilisent plus de 100MB ET contiennent "s" dans leur nom
Get-Process | Where-Object { $_.WorkingSet -gt 100MB -and $_.Name -like "*s*" }
```

#### Filtrer sur des propriétés imbriquées

```powershell
# Services avec des dépendances qui contiennent "Windows"
Get-Service | Where-Object { $_.DependentServices.Name -like "*Windows*" }
```

### 📊 Techniques avancées de `Sort-Object`

#### Tri inversé

```powershell
# Trier les fichiers du plus grand au plus petit
Get-ChildItem | Sort-Object Length -Descending
```

#### Tri sur plusieurs propriétés

```powershell
# Trier d'abord par extension, puis par taille
Get-ChildItem | Sort-Object Extension, Length
```

### 🔄 Combiner les cmdlets dans un pipeline

La vraie puissance de PowerShell vient de la possibilité d'enchaîner ces commandes:

```powershell
# Trouver les 5 processus qui consomment le plus de mémoire
Get-Process |
    Where-Object { $_.WorkingSet -gt 50MB } |
    Sort-Object WorkingSet -Descending |
    Select-Object Name, @{
        Name = 'MemoryMB'
        Expression = { [math]::Round($_.WorkingSet / 1MB, 2) }
    } -First 5
```

### 💪 Exercices pratiques

1. Affichez uniquement les services Windows qui sont actuellement en cours d'exécution
2. Trouvez les 3 fichiers les plus volumineux dans votre dossier utilisateur
3. Listez tous les processus qui contiennent la lettre "s" dans leur nom et utilisent plus de 50MB de mémoire

### 🎯 Solutions aux exercices

```powershell
# Exercice 1
Get-Service | Where-Object { $_.Status -eq "Running" }

# Exercice 2
Get-ChildItem -Path $HOME -Recurse -File | Sort-Object Length -Descending | Select-Object -First 3

# Exercice 3
Get-Process | Where-Object { $_.Name -like "*s*" -and $_.WorkingSet -gt 50MB }
```

### 📝 Astuces pour débutants

- Utilisez `-eq` pour "égal à", `-gt` pour "supérieur à", `-lt` pour "inférieur à"
- Utilisez `-like` avec des jokers (`*`) pour les correspondances partielles de texte
- Utilisez `Format-Table` (ou l'alias `ft`) pour afficher les résultats en tableau
- N'oubliez pas les accolades `{ }` autour des conditions dans `Where-Object`

### 🔑 Points clés à retenir

- `Select-Object` : Choisit les propriétés à afficher
- `Where-Object` : Filtre les objets selon des conditions
- `Sort-Object` : Trie les objets selon une ou plusieurs propriétés
- Le pipeline `|` permet d'enchaîner ces commandes pour des opérations complexes
- `$_` représente l'objet courant dans le pipeline

### 🎓 Pour aller plus loin

Dans la prochaine section, nous découvrirons comment créer nos propres objets personnalisés avec `[PSCustomObject]` pour organiser nos données exactement comme nous le souhaitons.

---

💡 **Astuce de pro**: Pour des performances optimales avec de grandes quantités de données, utilisez la syntaxe simplifiée de `Where-Object`:

```powershell
# Ancienne syntaxe
Get-Process | Where-Object { $_.Name -like "*s*" }

# Syntaxe simplifiée (plus rapide)
Get-Process | Where-Object Name -like "*s*"
```
