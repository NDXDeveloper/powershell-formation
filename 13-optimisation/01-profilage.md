# Module 14-1: Profilage (`Measure-Command`, Stopwatch)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📝 Introduction au profilage

Le profilage est une technique essentielle pour mesurer et améliorer les performances de vos scripts PowerShell. Il vous permet de savoir combien de temps prend l'exécution d'une portion de code, ce qui est crucial pour identifier les goulots d'étranglement et optimiser vos scripts.

## 🕒 Pourquoi mesurer les performances ?

- Identifier les parties lentes de votre code
- Comparer différentes approches pour une même tâche
- Vérifier les améliorations après optimisation
- Estimer le temps d'exécution pour les tâches planifiées

## 🔍 Méthode 1: `Measure-Command`

La cmdlet `Measure-Command` est la façon la plus simple de mesurer le temps d'exécution d'un bloc de code PowerShell.

### Syntaxe de base

```powershell
Measure-Command {
    # Votre code à mesurer ici
}
```

### Exemple simple

```powershell
$resultat = Measure-Command {
    Start-Sleep -Seconds 2  # Une opération qui prend 2 secondes
}

Write-Host "L'opération a pris: $($resultat.TotalSeconds) secondes"
```

### Propriétés disponibles

Après l'exécution, `Measure-Command` renvoie un objet `TimeSpan` qui contient plusieurs propriétés utiles:

- `TotalSeconds` - Temps total en secondes (avec décimales)
- `TotalMilliseconds` - Temps total en millisecondes
- `Minutes`, `Seconds` - Minutes et secondes entières
- `Ticks` - Unité de temps la plus précise

### Exemple de comparaison de méthodes

```powershell
# Méthode 1: Utilisation de ForEach-Object (pipeline)
$temps1 = Measure-Command {
    1..1000 | ForEach-Object { $_ * 2 }
}

# Méthode 2: Utilisation d'une boucle foreach
$temps2 = Measure-Command {
    $resultats = @()
    foreach ($nombre in 1..1000) {
        $resultats += $nombre * 2
    }
}

# Affichage des résultats
Write-Host "Méthode 1 (pipeline): $($temps1.TotalMilliseconds) ms"
Write-Host "Méthode 2 (foreach): $($temps2.TotalMilliseconds) ms"
```

## ⏱️ Méthode 2: Classe `Stopwatch`

La classe `Stopwatch` du .NET Framework offre plus de flexibilité pour mesurer des portions spécifiques de code ou des mesures multiples.

### Utilisation de base

```powershell
# Création d'un objet Stopwatch
$chrono = [System.Diagnostics.Stopwatch]::new()

# Démarrage du chronomètre
$chrono.Start()

# Code à mesurer
Start-Sleep -Seconds 1

# Arrêt du chronomètre
$chrono.Stop()

# Affichage du résultat
Write-Host "Temps écoulé: $($chrono.Elapsed.TotalSeconds) secondes"
```

### Points forts de Stopwatch

- **Précision**: Utilise un timer haute résolution
- **Flexibilité**: Possibilité de démarrer/arrêter plusieurs fois
- **Réutilisable**: Le chronomètre peut être reset et réutilisé

### Mesurer plusieurs opérations avec pause

```powershell
$chrono = [System.Diagnostics.Stopwatch]::new()

# Première opération
$chrono.Start()
Start-Sleep -Milliseconds 500
$chrono.Stop()
Write-Host "Opération 1: $($chrono.Elapsed.TotalMilliseconds) ms"

# Deuxième opération (sans reset)
$chrono.Start()
Start-Sleep -Milliseconds 300
$chrono.Stop()
Write-Host "Total après opération 2: $($chrono.Elapsed.TotalMilliseconds) ms"

# Reset et nouvelle mesure
$chrono.Reset()
$chrono.Start()
Start-Sleep -Milliseconds 200
$chrono.Stop()
Write-Host "Nouvelle mesure après reset: $($chrono.Elapsed.TotalMilliseconds) ms"
```

## 🔄 Mesurer des portions spécifiques de code

Pour profiler des sections précises d'un script plus long:

```powershell
$chrono = [System.Diagnostics.Stopwatch]::new()
$chrono.Start()

# Première section - préparation des données
$donnees = 1..10000
$chrono.Stop()
Write-Host "Préparation des données: $($chrono.Elapsed.TotalMilliseconds) ms"

# Reset pour la section suivante
$chrono.Reset()
$chrono.Start()

# Deuxième section - traitement
$resultats = $donnees | Where-Object { $_ % 2 -eq 0 }
$chrono.Stop()
Write-Host "Filtrage des données: $($chrono.Elapsed.TotalMilliseconds) ms"
```

## 📊 Conseils pratiques

1. **Exécutez plusieurs fois** avant de tirer des conclusions (la mise en cache peut affecter les résultats)
2. **Évitez de profiler le code de débogage** (Write-Host, etc.) qui n'existe pas en production
3. **Utilisez des ensembles de données réalistes** pour vos tests
4. **Créez une fonction de test** pour faciliter les comparaisons:

```powershell
function Test-Performance {
    param(
        [scriptblock]$Code,
        [int]$Iterations = 3
    )

    $resultats = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        $temps = Measure-Command $Code
        $resultats += $temps.TotalMilliseconds
        Write-Host "Itération $i : $($temps.TotalMilliseconds) ms"
    }

    $moyenne = ($resultats | Measure-Object -Average).Average
    Write-Host "Moyenne: $moyenne ms" -ForegroundColor Green

    return $moyenne
}

# Utilisation
Test-Performance -Code {
    # Votre code ici
    Start-Sleep -Milliseconds 100
} -Iterations 5
```

## 🚀 Exercice pratique

Comparez les performances des deux méthodes pour créer une liste de 10 000 nombres au carré:

```powershell
# Méthode 1: ForEach-Object avec pipeline
$temps1 = Measure-Command {
    $resultat1 = 1..10000 | ForEach-Object { $_ * $_ }
}

# Méthode 2: Boucle foreach classique
$temps2 = Measure-Command {
    $resultat2 = @()
    foreach ($nombre in 1..10000) {
        $resultat2 += $nombre * $nombre
    }
}

# Méthode 3: Comprehension List avec ForEach
$temps3 = Measure-Command {
    $resultat3 = foreach ($nombre in 1..10000) {
        $nombre * $nombre
    }
}

# Affichage des résultats
Write-Host "Méthode 1 (Pipeline): $($temps1.TotalMilliseconds) ms"
Write-Host "Méthode 2 (Foreach avec +=): $($temps2.TotalMilliseconds) ms"
Write-Host "Méthode 3 (Comprehension): $($temps3.TotalMilliseconds) ms"
```

## 📝 Conclusion

Le profilage est une compétence essentielle pour tout administrateur ou développeur PowerShell. Utilisez `Measure-Command` pour des mesures simples et rapides, et la classe `Stopwatch` pour des scénarios plus complexes ou pour mesurer plusieurs sections de code.

En pratiquant régulièrement le profilage, vous développerez une intuition pour identifier les parties de code qui méritent d'être optimisées, ce qui vous permettra d'écrire des scripts plus performants.

---

### 🔍 Pour aller plus loin

- Explorez le module `ImportExcel` pour créer des graphiques de performance
- Découvrez l'outil `PSProfiler` pour des analyses plus détaillées
- Apprenez à utiliser le logging pour garder une trace des performances dans le temps
