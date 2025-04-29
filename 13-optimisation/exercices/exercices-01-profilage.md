# Solution - Exercice de profilage PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Ce script compare les performances de trois méthodes différentes pour créer une liste de 10 000 nombres au carré.

```powershell
# Solution-ProfilagePerformance.ps1
# Description: Comparaison des performances de trois méthodes pour créer une liste de nombres au carré
# Auteur: [Votre Nom]
# Date: 27 avril 2025
# Version: 1.0

# Fonction pour formater les résultats avec des couleurs selon la performance
function Format-ResultatPerformance {
    param (
        [string]$NomMethode,
        [double]$TempsMs,
        [double]$MeilleurTemps
    )

    $ratio = $TempsMs / $MeilleurTemps
    $couleur = switch ($ratio) {
        {$_ -le 1.1} { "Green" }    # Jusqu'à 10% plus lent que le meilleur = vert
        {$_ -le 2.0} { "Yellow" }   # Jusqu'à 2x plus lent = jaune
        default { "Red" }           # Plus de 2x plus lent = rouge
    }

    Write-Host "$NomMethode : " -NoNewline
    Write-Host "$([math]::Round($TempsMs, 2)) ms" -ForegroundColor $couleur
}

# Fonction pour exécuter les tests plusieurs fois et calculer la moyenne
function Test-MethodesCalculCarres {
    param (
        [int]$Iterations = 5,
        [int]$TailleEchantillon = 10000
    )

    Write-Host "Test avec $TailleEchantillon éléments, $Iterations itérations par méthode" -ForegroundColor Cyan

    $resultatsMethode1 = @()
    $resultatsMethode2 = @()
    $resultatsMethode3 = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        Write-Host "Itération $i/$Iterations" -ForegroundColor Gray

        # Méthode 1: Pipeline avec ForEach-Object
        [gc]::Collect()  # Force le garbage collector pour un test plus équitable
        $temps1 = Measure-Command {
            $resultat1 = 1..$TailleEchantillon | ForEach-Object { $_ * $_ }
        }
        $resultatsMethode1 += $temps1.TotalMilliseconds

        # Méthode 2: Boucle foreach avec ajout à un tableau
        [gc]::Collect()
        $temps2 = Measure-Command {
            $resultat2 = @()
            foreach ($nombre in 1..$TailleEchantillon) {
                $resultat2 += $nombre * $nombre
            }
        }
        $resultatsMethode2 += $temps2.TotalMilliseconds

        # Méthode 3: List comprehension
        [gc]::Collect()
        $temps3 = Measure-Command {
            $resultat3 = foreach ($nombre in 1..$TailleEchantillon) {
                $nombre * $nombre
            }
        }
        $resultatsMethode3 += $temps3.TotalMilliseconds

        # Vérification rapide que les résultats sont identiques (même longueur)
        if ($resultat1.Count -ne $resultat2.Count -or $resultat1.Count -ne $resultat3.Count) {
            Write-Warning "Les résultats n'ont pas la même taille!"
        }
    }

    # Calcul des moyennes
    $moyenneM1 = ($resultatsMethode1 | Measure-Object -Average).Average
    $moyenneM2 = ($resultatsMethode2 | Measure-Object -Average).Average
    $moyenneM3 = ($resultatsMethode3 | Measure-Object -Average).Average

    # Déterminer le meilleur temps pour comparer
    $meilleurTemps = [Math]::Min([Math]::Min($moyenneM1, $moyenneM2), $moyenneM3)

    # Affichage des résultats formatés
    Write-Host "`nRésultats (moyennes sur $Iterations itérations):" -ForegroundColor Cyan
    Format-ResultatPerformance -NomMethode "Méthode 1 (Pipeline avec ForEach-Object)" -TempsMs $moyenneM1 -MeilleurTemps $meilleurTemps
    Format-ResultatPerformance -NomMethode "Méthode 2 (Foreach avec ajout via +=)    " -TempsMs $moyenneM2 -MeilleurTemps $meilleurTemps
    Format-ResultatPerformance -NomMethode "Méthode 3 (List comprehension)          " -TempsMs $moyenneM3 -MeilleurTemps $meilleurTemps

    # Conseils d'optimisation
    Write-Host "`nConseils d'optimisation:" -ForegroundColor Cyan
    if ($moyenneM2 -gt $moyenneM1 -and $moyenneM2 -gt $moyenneM3) {
        Write-Host "- Évitez l'opérateur += dans les boucles car il crée un nouveau tableau à chaque itération" -ForegroundColor Yellow
    }
    if ($moyenneM1 -gt $moyenneM3) {
        Write-Host "- Le pipeline est pratique mais moins performant que la list comprehension pour ce type d'opération" -ForegroundColor Yellow
    }
    Write-Host "- Pour les opérations intensives, envisagez d'utiliser [System.Collections.ArrayList] au lieu des tableaux standards" -ForegroundColor Green

    # Création d'un objet avec les résultats pour réutilisation éventuelle
    $resultats = [PSCustomObject]@{
        PipelineMs = $moyenneM1
        ForeachPlusEgalMs = $moyenneM2
        ListComprehensionMs = $moyenneM3
        MeilleureMethode = switch ($meilleurTemps) {
            $moyenneM1 { "Pipeline" }
            $moyenneM2 { "Foreach+=" }
            $moyenneM3 { "ListComprehension" }
        }
    }

    return $resultats
}

# Exécution du test avec les paramètres par défaut
$resultatsTest = Test-MethodesCalculCarres -Iterations 5 -TailleEchantillon 10000

# Démonstration bonus avec différentes tailles d'échantillon pour voir l'impact
Write-Host "`n`nImpact de la taille de l'échantillon:" -ForegroundColor Magenta
$tailles = @(100, 1000, 10000, 50000)
$resultatsParTaille = @()

foreach ($taille in $tailles) {
    Write-Host "`n-------------------------------------------" -ForegroundColor DarkGray
    $res = Test-MethodesCalculCarres -Iterations 3 -TailleEchantillon $taille
    $resultatsParTaille += [PSCustomObject]@{
        Taille = $taille
        ResultatsDetailles = $res
    }
}

# Affichage des conclusions
Write-Host "`n`nConclusion:" -ForegroundColor Magenta
Write-Host "La méthode 3 (List comprehension) est généralement la plus performante pour ce type d'opération."
Write-Host "La méthode 2 (Foreach avec +=) est la moins efficace car elle réalloue la mémoire à chaque itération."
Write-Host "L'écart de performance s'accentue avec la taille de l'échantillon."

# Note explicative
Write-Host "`nNote importante:" -ForegroundColor Cyan
Write-Host "Les résultats peuvent varier selon votre matériel et la charge système."
Write-Host "Pour des scripts de production, testez toujours les performances dans votre environnement spécifique."
```

## 🔍 Explication de la solution

Ce script comprend plusieurs améliorations par rapport à l'exercice original :

1. **Tests multiples** : Chaque méthode est testée plusieurs fois pour obtenir une moyenne fiable
2. **Nettoyage avant test** : Le garbage collector est appelé entre les tests pour des mesures plus équitables
3. **Formatage visuel** : Les résultats sont affichés avec un code couleur selon leur performance relative
4. **Conseils d'optimisation** : Le script fournit des recommandations basées sur les résultats
5. **Test avec différentes tailles** : Démontre comment l'impact des différentes approches varie selon la quantité de données

## 📊 Résultats typiques

Sur un système moderne, vous obtiendrez généralement ces tendances :

1. **List comprehension** (Méthode 3) : La plus rapide car elle utilise efficacement la mémoire
2. **Pipeline avec ForEach-Object** (Méthode 1) : Performance moyenne, le pipeline ajoute une surcharge
3. **Foreach avec +=** (Méthode 2) : La plus lente car elle réalloue un nouveau tableau à chaque itération

L'écart de performance entre ces méthodes devient plus prononcé à mesure que la taille de l'échantillon augmente.

## 🚀 Comment l'utiliser

1. Copiez ce script dans un fichier `.ps1`
2. Exécutez-le dans PowerShell
3. Analysez les résultats pour comprendre les différences de performance
4. Testez avec vos propres tailles d'échantillon en modifiant les paramètres

## 💡 Conseils supplémentaires

Pour des opérations intensives sur des collections, envisagez d'utiliser :
- `[System.Collections.ArrayList]` pour les opérations fréquentes d'ajout/suppression
- `.NET Collections` pour des types de données spécifiques (Dictionary, Queue, etc.)
- Pré-allocation de tableaux de taille fixe quand la taille finale est connue à l'avance
