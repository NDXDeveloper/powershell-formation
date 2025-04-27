# Module 4 - Objets et traitement de données
## 4-1. Le modèle objet PowerShell

### 📘 Introduction

Contrairement aux shells traditionnels comme CMD ou Bash qui manipulent principalement du texte, PowerShell manipule des **objets**. Cette différence fondamentale est ce qui rend PowerShell si puissant.

### 🔍 Qu'est-ce qu'un objet en PowerShell?

Un objet en PowerShell est une structure de données qui contient:
- Des **propriétés** (données ou attributs)
- Des **méthodes** (actions que l'objet peut effectuer)

C'est comme une boîte bien organisée qui contient à la fois des informations et des outils pour manipuler ces informations.

### 🧩 Comprendre par un exemple simple

Prenons un exemple concret. Exécutez cette commande:

```powershell
Get-Process | Select-Object -First 1
```

Ce que vous voyez à l'écran ressemble à du texte, mais ce n'est pas du texte! C'est la représentation visuelle d'un **objet Process**.

### 🔎 Explorer l'objet

Pour voir ce que contient réellement cet objet, utilisez:

```powershell
Get-Process | Select-Object -First 1 | Get-Member
```

Vous verrez une liste des propriétés et méthodes de l'objet Process. C'est comme une radiographie qui révèle sa structure interne!

### 🏷️ Types d'objets courants

En PowerShell, vous rencontrerez souvent ces types d'objets:

- **Process**: représente un processus en cours d'exécution
- **FileInfo**: représente un fichier
- **DirectoryInfo**: représente un dossier
- **DateTime**: représente une date et heure
- **String**: représente du texte
- **Int32, Double**: représentent des nombres
- **PSCustomObject**: un objet personnalisé que vous pouvez créer

### 💡 Les avantages du modèle objet

1. **Précision**: Accédez exactement à la donnée dont vous avez besoin
2. **Cohérence**: Manipulez différents types de données avec les mêmes commandes
3. **Puissance**: Exploitez les méthodes intégrées pour effectuer des actions complexes
4. **Filtrage avancé**: Filtrez sur des propriétés spécifiques plutôt que sur du texte

### 🛠️ Manipulation de base des objets

#### Accéder aux propriétés d'un objet

Pour accéder à une propriété spécifique:

```powershell
$process = Get-Process | Select-Object -First 1
$process.Name       # Affiche le nom du processus
$process.CPU        # Affiche l'utilisation CPU du processus
```

#### Utiliser les méthodes d'un objet

Pour exécuter une méthode (action):

```powershell
$date = Get-Date
$date.AddDays(7)    # Ajoute 7 jours à la date actuelle
```

### 🌐 Tout est objet en PowerShell!

Même les résultats des commandes sont des objets:

```powershell
$files = Get-ChildItem C:\Windows
$files.Count        # Nombre de fichiers/dossiers
$files | Where-Object { $_.Length -gt 1MB }  # Filtrer les fichiers > 1MB
```

### 🎯 Exercice pratique

1. Exécutez `Get-Service | Get-Member` et identifiez 3 propriétés intéressantes
2. Utilisez `$service = Get-Service | Select-Object -First 1` puis affichez ces propriétés
3. Essayez d'utiliser une méthode sur cet objet service

### 🔑 Points clés à retenir

- PowerShell manipule des **objets**, pas du texte
- Les objets ont des **propriétés** (données) et des **méthodes** (actions)
- `Get-Member` est votre meilleur ami pour explorer un objet
- Le modèle objet permet une manipulation précise et puissante des données
- La syntaxe point (`.`) vous permet d'accéder aux propriétés et méthodes

### 🎓 Pour aller plus loin

Dans les prochaines sections, nous explorerons comment:
- Filtrer et sélectionner des propriétés spécifiques (4-2)
- Créer vos propres objets personnalisés (4-3)
- Grouper et mesurer des objets (4-4)

---

💡 **Astuce de pro**: Utilisez la touche Tab pour l'autocomplétion des propriétés et méthodes! Tapez `$process.` puis appuyez sur Tab pour explorer les options disponibles.
