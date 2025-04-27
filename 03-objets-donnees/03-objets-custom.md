# Module 4 - Objets et traitement de données
## 4-3. Création d'objets personnalisés (`[PSCustomObject]`)

### 📘 Introduction

Jusqu'à présent, nous avons appris à manipuler des objets créés par PowerShell. Mais que faire si vous souhaitez créer vos propres objets avec exactement les propriétés dont vous avez besoin? C'est là qu'intervient `[PSCustomObject]`!

### 🏗️ Qu'est-ce qu'un PSCustomObject?

Un `PSCustomObject` est comme une boîte à compartiments que vous pouvez concevoir vous-même. Vous décidez du nombre de compartiments (propriétés) et de ce que chacun contient.

### 🛠️ Création d'un objet personnalisé simple

La syntaxe la plus courante pour créer un objet personnalisé est la suivante:

```powershell
$monOrdinateur = [PSCustomObject]@{
    Nom = "PC-DEV01"
    Marque = "Dell"
    Processeur = "Intel i7"
    RAM = "16GB"
    Allumé = $true
}
```

Voilà! Vous avez créé un objet personnalisé avec 5 propriétés. Pour afficher cet objet:

```powershell
$monOrdinateur
```

### 🔍 Accéder aux propriétés

Vous pouvez accéder aux propriétés individuelles exactement comme pour n'importe quel autre objet:

```powershell
$monOrdinateur.Nom        # Affiche "PC-DEV01"
$monOrdinateur.RAM        # Affiche "16GB"
```

### 📚 Créer plusieurs objets

Vous pouvez créer plusieurs objets et les stocker dans un tableau:

```powershell
$ordinateurs = @(
    [PSCustomObject]@{
        Nom = "PC-DEV01"
        Marque = "Dell"
        RAM = "16GB"
    },
    [PSCustomObject]@{
        Nom = "PC-DEV02"
        Marque = "HP"
        RAM = "8GB"
    }
)
```

Vous pouvez ensuite manipuler ce tableau comme n'importe quelle collection d'objets:

```powershell
$ordinateurs | Where-Object { $_.RAM -eq "16GB" }
```

### 🧩 Ajouter des propriétés dynamiquement

Vous pouvez aussi ajouter des propriétés après la création de l'objet:

```powershell
$utilisateur = [PSCustomObject]@{
    Nom = "Dupont"
    Prénom = "Jean"
}

# Ajouter une propriété Email
$utilisateur | Add-Member -MemberType NoteProperty -Name "Email" -Value "jean.dupont@exemple.fr"

# Ajouter une propriété calculée
$utilisateur | Add-Member -MemberType ScriptProperty -Name "NomComplet" -Value { "$($this.Prénom) $($this.Nom)" }
```

> 💡 Dans une propriété calculée (ScriptProperty), `$this` fait référence à l'objet lui-même.

### 🔄 Convertir des données en objets personnalisés

#### Convertir un CSV en objets

Imaginez que vous ayez un fichier CSV comme celui-ci:

```
Nom,Age,Ville
Alice,28,Paris
Bob,35,Lyon
Claire,42,Marseille
```

PowerShell convertit automatiquement chaque ligne en `PSCustomObject`:

```powershell
$personnes = Import-Csv -Path "personnes.csv"
$personnes[0].Nom    # Affiche "Alice"
```

#### Convertir une sortie texte en objets

Vous pouvez même transformer du texte structuré en objets:

```powershell
$texte = @"
Nom:Alice|Age:28|Ville:Paris
Nom:Bob|Age:35|Ville:Lyon
"@

$personnes = $texte -split "`n" | ForEach-Object {
    $propriétés = @{}
    $_.Split('|') | ForEach-Object {
        $clé, $valeur = $_ -split ':'
        $propriétés[$clé] = $valeur
    }
    [PSCustomObject]$propriétés
}

$personnes[0].Nom    # Affiche "Alice"
```

### 🎭 Cas d'usage pratiques

#### 1. Rapport personnalisé

```powershell
$espaceDisques = Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object {
    [PSCustomObject]@{
        Lecteur = $_.DriveLetter
        NomVolume = $_.FileSystemLabel
        "Capacité (GB)" = [math]::Round($_.Size / 1GB, 2)
        "Espace Libre (GB)" = [math]::Round($_.SizeRemaining / 1GB, 2)
        "% Libre" = [math]::Round(($_.SizeRemaining / $_.Size) * 100, 1)
    }
}

$espaceDisques | Format-Table -AutoSize
```

#### 2. Inventaire d'applications

```powershell
$applications = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Where-Object DisplayName |
    ForEach-Object {
        [PSCustomObject]@{
            Nom = $_.DisplayName
            Version = $_.DisplayVersion
            Éditeur = $_.Publisher
            DateInstallation = $_.InstallDate
        }
    }

$applications | Sort-Object Nom | Format-Table -AutoSize
```

### 🛣️ Bonnes pratiques

1. **Utilisez des noms de propriétés significatifs** - Préférez `NomUtilisateur` à `NU`
2. **Respectez la casse Pascal** - Utilisez `NomUtilisateur` plutôt que `nomutilisateur`
3. **Groupez les propriétés logiquement** - Mettez ensemble les propriétés liées
4. **Évitez les caractères spéciaux** dans les noms de propriétés
5. **Ajoutez une propriété d'ID unique** si vous manipulez beaucoup de données

### 🎯 Exercice pratique

Créez un objet personnalisé qui représente un employé avec:
- Prénom, Nom
- Poste
- AnneesExperience
- Competences (un tableau de compétences)
- Une méthode `Description` qui retourne un résumé de l'employé

### 🎓 Solution de l'exercice

```powershell
$employe = [PSCustomObject]@{
    Prenom = "Marie"
    Nom = "Martin"
    Poste = "Développeuse PowerShell"
    AnneesExperience = 5
    Competences = @("PowerShell", "Azure", "Active Directory")
}

# Ajouter une méthode Description
$employe | Add-Member -MemberType ScriptMethod -Name "Description" -Value {
    "$($this.Prenom) $($this.Nom) est $($this.Poste) avec $($this.AnneesExperience) ans d'expérience. " +
    "Compétences: $($this.Competences -join ', ')"
}

# Utiliser la méthode
$employe.Description()
```

### 🔑 Points clés à retenir

- `[PSCustomObject]` permet de créer des objets personnalisés adaptés à vos besoins
- La syntaxe de base est `[PSCustomObject]@{ Propriété1 = Valeur1; Propriété2 = Valeur2 }`
- Les objets personnalisés peuvent être manipulés comme n'importe quel autre objet PowerShell
- Vous pouvez ajouter des propriétés et méthodes après la création avec `Add-Member`
- Les objets personnalisés sont parfaits pour structurer vos données et créer des rapports

### 🔮 Pour aller plus loin

Dans la prochaine section, nous découvrirons comment regrouper et agréger des données avec `Group-Object` et `Measure-Object`, ce qui vous permettra d'analyser efficacement vos collections d'objets!

---

💡 **Astuce de pro**: Pour un affichage personnalisé de vos objets dans la console, explorez les fonctions `Format-Table`, `Format-List` et les fichiers de format personnalisés `.ps1xml`.
