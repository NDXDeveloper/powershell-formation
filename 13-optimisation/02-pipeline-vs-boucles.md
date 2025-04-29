# 14-2. Pipeline vs Boucles dans PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 🧠 Comprendre la différence

Dans PowerShell, il existe deux approches principales pour traiter plusieurs éléments : **les pipelines** et **les boucles**. Comprendre quand utiliser l'une ou l'autre peut considérablement améliorer les performances de vos scripts.

### Le pipeline (`|`) - La façon "PowerShell"

Le pipeline est l'une des fonctionnalités les plus puissantes de PowerShell. Il vous permet de passer des objets d'une commande à une autre.

```powershell
# Exemple de pipeline
Get-ChildItem -Path C:\Temp | Where-Object { $_.Length -gt 1MB } | Sort-Object -Property Length
```

Dans cet exemple :
1. `Get-ChildItem` récupère tous les fichiers
2. `|` envoie chaque fichier à la commande suivante
3. `Where-Object` filtre les fichiers de plus d'1 Mo
4. `|` envoie les résultats filtrés à la prochaine commande
5. `Sort-Object` trie les fichiers par taille

### Les boucles - La façon "traditionnelle"

Les boucles sont familières pour ceux qui viennent d'autres langages de programmation.

```powershell
# Exemple de boucle ForEach
$files = Get-ChildItem -Path C:\Temp
$largeFiles = @()

foreach ($file in $files) {
    if ($file.Length -gt 1MB) {
        $largeFiles += $file
    }
}
$largeFiles | Sort-Object -Property Length
```

## 🚀 Comparaison des performances

### Quand le pipeline est plus rapide

Le pipeline est généralement plus rapide pour :

- **Traitement de flux** : Les données sont traitées "à la volée" sans stocker l'ensemble complet en mémoire
- **Opérations natives** : Les cmdlets PowerShell sont optimisées pour fonctionner ensemble
- **Grands ensembles de données** : Le pipeline permet un traitement efficace de grandes quantités d'objets

```powershell
# Mesure du temps avec pipeline
Measure-Command {
    Get-Process | Where-Object { $_.WorkingSet -gt 100MB } | Sort-Object CPU -Descending | Select-Object -First 5
}
```

### Quand les boucles sont plus rapides

Les boucles peuvent être plus rapides pour :

- **Opérations complexes** : Logique personnalisée qui ne s'adapte pas bien au pipeline
- **Accumulation variable** : Quand vous devez construire un résultat complexe étape par étape
- **Contrôle de flux avancé** : Utilisation de `break`, `continue`, ou des structures conditionnelles imbriquées

```powershell
# Mesure du temps avec boucle
Measure-Command {
    $processes = Get-Process
    $results = @()
    foreach ($proc in $processes) {
        if ($proc.WorkingSet -gt 100MB) {
            # Logique complexe ici...
            $results += $proc
        }
    }
    $results | Sort-Object CPU -Descending | Select-Object -First 5
}
```

## 🔄 Inconvénients de chaque approche

### Limitations des pipelines

- Moins lisibles pour les opérations très complexes
- Peuvent être difficiles à déboguer (erreurs au milieu du pipeline)
- Certaines optimisations sont impossibles (comme l'arrêt anticipé dans certains cas)

### Limitations des boucles

- Utilisation plus importante de la mémoire (stockage de résultats intermédiaires)
- Souvent plus verbeuses
- Peut être moins performantes pour des opérations simples
- Ne profitent pas des optimisations natives de PowerShell

## 💡 Conseils pratiques pour débutants

### Utilisez le pipeline quand :

1. Vous effectuez des opérations simples d'enchaînement
2. Vous travaillez avec de grandes quantités de données
3. Vous utilisez des cmdlets natives ensemble

```powershell
# Bon usage du pipeline
Get-Service | Where-Object { $_.Status -eq 'Running' } | Select-Object -Property Name, DisplayName
```

### Utilisez les boucles quand :

1. Vous avez besoin d'un contrôle précis du flux d'exécution
2. Vous effectuez des opérations complexes sur chaque élément
3. Vous devez accumuler des résultats de manière personnalisée

```powershell
# Bon usage de boucle
$services = Get-Service
$report = @()

foreach ($service in $services) {
    if ($service.Status -eq 'Running') {
        # Logique complexe et personnalisée ici
        $customObject = [PSCustomObject]@{
            ServiceName = $service.Name
            DisplayName = $service.DisplayName
            RunningTime = (Get-Date) - $service.StartType # Ceci est simpliste, mais illustre l'idée
            Dependencies = $service.DependentServices.Count
        }
        $report += $customObject
    }
}
```

## 🌟 Meilleures pratiques - Approche hybride

En pratique, les meilleurs scripts PowerShell combinent souvent les deux approches :

```powershell
# Approche hybride
$files = Get-ChildItem -Path C:\Temp # Récupère tous les fichiers d'un coup

# Boucle pour un traitement complexe
$processedFiles = foreach ($file in $files) {
    if ($file.Extension -eq '.log') {
        $content = Get-Content $file.FullName

        # Traitement complexe par fichier
        if ($content -match "erreur") {
            [PSCustomObject]@{
                FileName = $file.Name
                Path = $file.FullName
                ErrorCount = ($content | Select-String "erreur").Count
                LastModified = $file.LastWriteTime
            }
        }
    }
}

# Pipeline pour finaliser le traitement
$processedFiles | Where-Object { $_.ErrorCount -gt 5 } | Sort-Object ErrorCount -Descending
```

## 📊 Test de comparaison simple

Voici un petit test que vous pouvez exécuter pour voir la différence de performance vous-même :

```powershell
# Création d'un grand tableau pour le test
$largeArray = 1..100000

# Test avec pipeline
$pipelineTime = Measure-Command {
    $largeArray | Where-Object { $_ % 2 -eq 0 } | ForEach-Object { $_ * 2 }
}

# Test avec boucle
$loopTime = Measure-Command {
    $results = @()
    foreach ($number in $largeArray) {
        if ($number % 2 -eq 0) {
            $results += $number * 2
        }
    }
}

# Affichage des résultats
"Pipeline: $($pipelineTime.TotalMilliseconds) ms"
"Boucle: $($loopTime.TotalMilliseconds) ms"
```

## 🎯 Conclusion

- **Pipeline** : Solution élégante et concise pour des traitements simples à modérés
- **Boucles** : Plus de contrôle et de flexibilité pour des logiques complexes
- **Approche hybride** : Souvent la meilleure solution en pratique

L'expérience vous aidera à déterminer quelle approche est la plus adaptée à chaque situation. N'hésitez pas à tester les deux méthodes sur vos données pour voir laquelle est la plus performante dans votre cas spécifique.

⏭️ [Techniques d'optimisation (filtrage natif, évitement de WMI)](/13-optimisation/03-techniques.md)
