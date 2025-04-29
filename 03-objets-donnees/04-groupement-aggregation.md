# Module 4 - Objets et traitement de données
## 4-4. Groupement, agrégation (`Group-Object`, `Measure-Object`)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

Lorsque vous travaillez avec de grandes quantités de données dans PowerShell, il devient essentiel de pouvoir les organiser et les analyser efficacement. C'est là que les cmdlets `Group-Object` et `Measure-Object` entrent en jeu! Ces outils puissants vous aideront à transformer des informations brutes en connaissances utiles.

### 🔍 Grouper des données avec `Group-Object`

#### Concept de base

`Group-Object` est comme un tri de courrier qui organise vos lettres par expéditeur ou par code postal. Il prend une collection d'objets et les regroupe selon une ou plusieurs propriétés.

#### Syntaxe simple

```powershell
Get-ChildItem | Group-Object Extension
```

Cette commande liste tous les fichiers du répertoire courant et les regroupe par extension.

#### Comprendre la sortie

La sortie de `Group-Object` contient trois informations principales:
- **Count** : nombre d'éléments dans ce groupe
- **Name** : valeur de la propriété utilisée pour grouper
- **Group** : collection d'objets appartenant à ce groupe

```powershell
# Exemple de sortie
Count Name   Group
----- ----   -----
    5 .txt   {note.txt, todo.txt, log.txt...}
    3 .ps1   {script1.ps1, backup.ps1, test.ps1}
    2 .csv   {data.csv, users.csv}
```

#### Exemples pratiques

1. **Grouper les services par statut**

```powershell
Get-Service | Group-Object Status
```

2. **Grouper les processus par priorité**

```powershell
Get-Process | Group-Object PriorityClass
```

3. **Grouper les fichiers par année de création**

```powershell
Get-ChildItem | Group-Object { $_.CreationTime.Year }
```

> 💡 Notez l'utilisation des accolades `{ }` - cela vous permet de grouper selon une expression et pas seulement une propriété directe.

#### Groupement sur plusieurs propriétés

Vous pouvez grouper selon plusieurs critères:

```powershell
Get-ChildItem | Group-Object Extension, { $_.Length -gt 1MB }
```

Cette commande groupe les fichiers d'abord par extension, puis par taille (supérieure ou non à 1 Mo).

### 📊 Mesurer des données avec `Measure-Object`

#### Concept de base

`Measure-Object` est comme une calculatrice qui analyse vos données et fournit des statistiques. Il peut compter, additionner, calculer des moyennes, trouver des minimums et maximums.

#### Syntaxe de base

```powershell
Get-ChildItem | Measure-Object Length
```

Cette commande calcule des statistiques sur la taille des fichiers du répertoire courant.

#### Options de mesure

Vous pouvez spécifier les statistiques que vous souhaitez calculer:

```powershell
Get-ChildItem | Measure-Object Length -Average -Sum -Maximum -Minimum
```

Cette commande affiche la taille moyenne, totale, maximale et minimale des fichiers.

#### Exemples pratiques

1. **Compter le nombre de fichiers**

```powershell
Get-ChildItem | Measure-Object
```

2. **Calculer l'espace disque utilisé**

```powershell
Get-ChildItem -Recurse | Measure-Object Length -Sum |
    Select-Object @{Name="TailleTotal(MB)"; Expression={[math]::Round($_.Sum / 1MB, 2)}}
```

3. **Analyser l'utilisation CPU des processus**

```powershell
Get-Process | Measure-Object CPU -Average -Maximum -Minimum
```

4. **Compter les mots dans un fichier texte**

```powershell
Get-Content .\document.txt | Measure-Object -Word
```

### 🔄 Combiner groupement et mesure

La vraie puissance vient de la combinaison de ces cmdlets!

#### Analyser l'espace disque par extension

```powershell
Get-ChildItem -Recurse |
    Group-Object Extension |
    ForEach-Object {
        $tailleGroupe = $_.Group | Measure-Object Length -Sum
        [PSCustomObject]@{
            Extension = if ($_.Name) { $_.Name } else { "(aucune)" }
            "Nombre de fichiers" = $_.Count
            "Taille totale (MB)" = [math]::Round($tailleGroupe.Sum / 1MB, 2)
        }
    } | Sort-Object "Taille totale (MB)" -Descending
```

Ce script:
1. Liste tous les fichiers récursivement
2. Les groupe par extension
3. Calcule la taille totale pour chaque groupe
4. Crée un objet personnalisé avec les informations importantes
5. Trie par taille décroissante

#### Analyser les processus par utilisateur

```powershell
Get-Process |
    Group-Object -Property Company |
    Select-Object Name, Count, @{
        Name = "MemoireTotale(MB)"
        Expression = {
            ($_.Group | Measure-Object WorkingSet -Sum).Sum / 1MB
        }
    } | Sort-Object -Property "MemoireTotale(MB)" -Descending
```

### 🎭 Cas d'usage avancés

#### Trouver les doublons

```powershell
Get-ChildItem |
    Group-Object Length |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object { $_.Group | Select-Object Name, Length }
```

#### Rapport d'utilisation par extension

```powershell
$rapport = Get-ChildItem -Recurse |
    Group-Object Extension |
    ForEach-Object {
        $stats = $_.Group | Measure-Object Length -Sum -Average -Maximum -Minimum
        [PSCustomObject]@{
            Extension = if ($_.Name) { $_.Name } else { "(aucune)" }
            "Nombre" = $_.Count
            "Total(MB)" = [math]::Round($stats.Sum / 1MB, 2)
            "Moyenne(KB)" = [math]::Round($stats.Average / 1KB, 2)
            "Max(MB)" = [math]::Round($stats.Maximum / 1MB, 2)
            "Min(KB)" = [math]::Round($stats.Minimum / 1KB, 2)
        }
    }

$rapport | Format-Table -AutoSize
```

### 💪 Exercice pratique

Créez un script qui:
1. Liste tous les processus en cours d'exécution
2. Les groupe par leur propriété `Company`
3. Calcule pour chaque groupe:
   - Le nombre de processus
   - L'utilisation totale de mémoire
   - L'utilisation moyenne de CPU
4. Affiche les 5 compagnies qui utilisent le plus de mémoire

### 🎓 Solution de l'exercice

```powershell
Get-Process |
    Where-Object Company |
    Group-Object Company |
    ForEach-Object {
        $memoire = $_.Group | Measure-Object WorkingSet -Sum
        $cpu = $_.Group | Measure-Object CPU -Average
        [PSCustomObject]@{
            Compagnie = $_.Name
            "Nombre de processus" = $_.Count
            "Mémoire totale (MB)" = [math]::Round($memoire.Sum / 1MB, 2)
            "CPU moyen" = [math]::Round($cpu.Average, 2)
        }
    } | Sort-Object "Mémoire totale (MB)" -Descending |
    Select-Object -First 5 |
    Format-Table -AutoSize
```

### 🔑 Points clés à retenir

- `Group-Object` organise vos données en groupes selon une ou plusieurs propriétés
- `Measure-Object` calcule des statistiques comme la somme, la moyenne, le minimum et le maximum
- La combinaison de ces cmdlets permet d'analyser efficacement de grandes quantités de données
- Les expressions scriptblocks `{ }` permettent des groupements avancés sur des propriétés calculées
- Ces techniques sont essentielles pour l'analyse de données et la création de rapports

### 🔮 Pour aller plus loin

Dans la prochaine section, nous verrons comment exporter ces données structurées vers différents formats comme CSV, JSON et XML, ce qui vous permettra de partager facilement vos analyses ou de les utiliser dans d'autres systèmes.

---

💡 **Astuce de pro**: Pour des visualisations encore plus élaborées de vos données groupées, vous pouvez utiliser `ConvertTo-Html` avec des styles CSS pour créer des rapports HTML colorés:

```powershell
$rapport |
    ConvertTo-Html -Title "Analyse des fichiers" -PreContent "<h1>Rapport d'utilisation disque</h1>" |
    Set-Content rapport.html

Invoke-Item rapport.html  # Ouvre le rapport dans votre navigateur
```
