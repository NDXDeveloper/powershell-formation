# Solutions aux exercices - Module 8-2

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Runspaces & ForEach-Object -Parallel (PowerShell 7+)

Dans cette section, nous allons explorer plusieurs solutions à l'exercice proposé dans le module 8-2, qui consistait à :
1. Rechercher des fichiers dans un répertoire de votre choix
2. Traiter ces fichiers en parallèle (par exemple, compter des mots ou rechercher un motif)
3. Afficher un résumé des résultats

### Solution 1 : Recherche de mots-clés dans des fichiers texte

Cette solution recherche des mots-clés spécifiques dans tous les fichiers texte d'un répertoire.

```powershell
# Définir les paramètres
$cheminDossier = "C:\Documents"  # Modifiez ce chemin selon votre environnement
$extension = "*.txt"
$motsCles = @("important", "urgent", "bug", "erreur")

# Récupérer tous les fichiers correspondant au filtre
$fichiers = Get-ChildItem -Path $cheminDossier -Filter $extension -Recurse

Write-Host "Traitement de $($fichiers.Count) fichiers en parallèle..." -ForegroundColor Cyan

# Traiter chaque fichier en parallèle
$resultats = $fichiers | ForEach-Object -Parallel {
    $fichier = $_
    $motsClesARechercher = $using:motsCles
    $resultatsMotsCles = @{}

    # Initialiser le compteur pour chaque mot-clé
    foreach ($motCle in $motsClesARechercher) {
        $resultatsMotsCles[$motCle] = 0
    }

    # Vérifier que le fichier existe et n'est pas vide
    if (Test-Path $fichier.FullName -PathType Leaf) {
        try {
            # Lire le contenu du fichier
            $contenu = Get-Content -Path $fichier.FullName -ErrorAction Stop

            # Pour chaque mot-clé, compter les occurrences
            foreach ($motCle in $motsClesARechercher) {
                $occurrences = ($contenu | Select-String -Pattern $motCle -SimpleMatch -AllMatches).Matches.Count
                $resultatsMotsCles[$motCle] = $occurrences
            }

            # Calculer le nombre total de lignes et de mots
            $nombreLignes = $contenu.Count
            $nombreMots = ($contenu | Measure-Object -Word).Words

            # Créer et retourner un objet avec les résultats
            [PSCustomObject]@{
                Fichier = $fichier.Name
                Chemin = $fichier.FullName
                NombreLignes = $nombreLignes
                NombreMots = $nombreMots
                MotsCles = $resultatsMotsCles
                TotalOccurrences = ($resultatsMotsCles.Values | Measure-Object -Sum).Sum
                Taille = $fichier.Length
                DerniereMaj = $fichier.LastWriteTime
            }
        }
        catch {
            # En cas d'erreur, retourner un objet avec des informations sur l'erreur
            [PSCustomObject]@{
                Fichier = $fichier.Name
                Chemin = $fichier.FullName
                Erreur = $_.Exception.Message
                Taille = $fichier.Length
                DerniereMaj = $fichier.LastWriteTime
            }
        }
    }
} -ThrottleLimit 10  # Limiter à 10 tâches parallèles

# Afficher un résumé des résultats
$fichiersSansErreur = $resultats | Where-Object { -not $_.Erreur }

Write-Host "`nRésumé des résultats :" -ForegroundColor Green
Write-Host "Nombre total de fichiers traités : $($resultats.Count)" -ForegroundColor Yellow
Write-Host "Fichiers traités avec succès : $($fichiersSansErreur.Count)" -ForegroundColor Yellow
Write-Host "Fichiers avec erreurs : $($resultats.Count - $fichiersSansErreur.Count)" -ForegroundColor Yellow

# Afficher les fichiers avec le plus d'occurrences des mots-clés
Write-Host "`nTop 5 des fichiers avec le plus d'occurrences des mots-clés :" -ForegroundColor Green
$fichiersSansErreur |
    Sort-Object -Property TotalOccurrences -Descending |
    Select-Object -First 5 |
    Format-Table -Property Fichier, NombreLignes, NombreMots, TotalOccurrences

# Afficher le nombre d'occurrences par mot-clé
Write-Host "`nOccurrences par mot-clé :" -ForegroundColor Green
$statistiquesMotsCles = @{}

# Initialiser le compteur pour chaque mot-clé
foreach ($motCle in $motsCles) {
    $statistiquesMotsCles[$motCle] = 0
}

# Calculer le total pour chaque mot-clé
foreach ($resultat in $fichiersSansErreur) {
    foreach ($motCle in $motsCles) {
        $statistiquesMotsCles[$motCle] += $resultat.MotsCles[$motCle]
    }
}

# Afficher les statistiques par mot-clé
$statistiquesMotsCles.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    ForEach-Object {
        Write-Host "$($_.Key): $($_.Value) occurrences" -ForegroundColor Yellow
    }

# Afficher les erreurs éventuelles
$fichiersAvecErreur = $resultats | Where-Object { $_.Erreur }
if ($fichiersAvecErreur) {
    Write-Host "`nFichiers avec erreurs :" -ForegroundColor Red
    $fichiersAvecErreur | Format-Table -Property Fichier, Erreur
}
```

### Solution 2 : Analyse statistique de logs en parallèle

Cette solution analyse des fichiers de logs pour extraire des statistiques sur différents types d'événements.

```powershell
# Définir les paramètres
$cheminLogs = "C:\Logs"  # Modifiez ce chemin selon votre environnement
$extension = "*.log"
$typesEvenements = @("INFO", "WARNING", "ERROR", "CRITICAL")

# Récupérer tous les fichiers de logs
$fichiers = Get-ChildItem -Path $cheminLogs -Filter $extension -Recurse

Write-Host "Analyse de $($fichiers.Count) fichiers logs en parallèle..." -ForegroundColor Cyan

# Analyser chaque fichier en parallèle
$resultats = $fichiers | ForEach-Object -Parallel {
    $fichier = $_
    $typesEvenements = $using:typesEvenements
    $statistiques = @{}

    # Initialiser les compteurs
    foreach ($type in $typesEvenements) {
        $statistiques[$type] = 0
    }

    try {
        # Utiliser un tableau pour stocker les dates
        $premiereDate = $null
        $derniereDate = $null
        $datesErreurs = @()

        # Lire le contenu du fichier
        $contenu = Get-Content -Path $fichier.FullName -ErrorAction Stop

        # Analyser chaque ligne
        foreach ($ligne in $contenu) {
            # Vérifier chaque type d'événement
            foreach ($type in $typesEvenements) {
                if ($ligne -match $type) {
                    $statistiques[$type]++

                    # Si c'est une erreur ou critique, essayer d'extraire la date
                    if ($type -eq "ERROR" -or $type -eq "CRITICAL") {
                        if ($ligne -match '\[(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\]') {
                            $dateMatch = [datetime]::ParseExact($Matches[1], 'yyyy-MM-dd HH:mm:ss', $null)
                            $datesErreurs += $dateMatch

                            # Mettre à jour première/dernière date
                            if ($null -eq $premiereDate -or $dateMatch -lt $premiereDate) {
                                $premiereDate = $dateMatch
                            }
                            if ($null -eq $derniereDate -or $dateMatch -gt $derniereDate) {
                                $derniereDate = $dateMatch
                            }
                        }
                    }

                    break  # Sortir de la boucle foreach car on a trouvé un type
                }
            }
        }

        # Calculer des statistiques sur les erreurs
        $totalErreurs = $statistiques["ERROR"] + $statistiques["CRITICAL"]

        # Créer et retourner un objet avec les résultats
        [PSCustomObject]@{
            Fichier = $fichier.Name
            Chemin = $fichier.FullName
            NombreLignes = $contenu.Count
            Statistiques = $statistiques
            TotalEvents = ($statistiques.Values | Measure-Object -Sum).Sum
            TotalErreurs = $totalErreurs
            PremiereErreur = $premiereDate
            DerniereErreur = $derniereDate
            PeriodeErreurs = if ($premiereDate -and $derniereDate) {
                ($derniereDate - $premiereDate).ToString()
            } else {
                "N/A"
            }
            Taille = $fichier.Length
            DerniereMaj = $fichier.LastWriteTime
        }
    }
    catch {
        # En cas d'erreur, retourner un objet avec des informations sur l'erreur
        [PSCustomObject]@{
            Fichier = $fichier.Name
            Chemin = $fichier.FullName
            Erreur = $_.Exception.Message
            Taille = $fichier.Length
            DerniereMaj = $fichier.LastWriteTime
        }
    }
} -ThrottleLimit 8  # Limiter à 8 tâches parallèles

# Afficher un résumé des résultats
$fichiersSansErreur = $resultats | Where-Object { -not $_.Erreur }

Write-Host "`nRésumé de l'analyse des logs :" -ForegroundColor Green
Write-Host "Nombre total de fichiers analysés : $($resultats.Count)" -ForegroundColor Yellow
Write-Host "Fichiers analysés avec succès : $($fichiersSansErreur.Count)" -ForegroundColor Yellow
Write-Host "Fichiers avec erreurs : $($resultats.Count - $fichiersSansErreur.Count)" -ForegroundColor Yellow

# Afficher les totaux par type d'événement
$totauxParType = @{}
foreach ($type in $typesEvenements) {
    $totauxParType[$type] = 0
}

foreach ($resultat in $fichiersSansErreur) {
    foreach ($type in $typesEvenements) {
        $totauxParType[$type] += $resultat.Statistiques[$type]
    }
}

Write-Host "`nTotaux par type d'événement :" -ForegroundColor Green
$totauxParType.GetEnumerator() |
    Sort-Object -Property Value -Descending |
    ForEach-Object {
        Write-Host "$($_.Key): $($_.Value) occurrences" -ForegroundColor Yellow
    }

# Afficher les fichiers avec le plus d'erreurs
Write-Host "`nTop 5 des fichiers avec le plus d'erreurs :" -ForegroundColor Green
$fichiersSansErreur |
    Sort-Object -Property TotalErreurs -Descending |
    Select-Object -First 5 |
    Format-Table -Property Fichier, TotalErreurs, PremiereErreur, DerniereErreur, PeriodeErreurs

# Afficher les erreurs éventuelles
$fichiersAvecErreur = $resultats | Where-Object { $_.Erreur }
if ($fichiersAvecErreur) {
    Write-Host "`nFichiers avec erreurs lors de l'analyse :" -ForegroundColor Red
    $fichiersAvecErreur | Format-Table -Property Fichier, Erreur
}
```

### Solution 3 : Recherche et modification de fichiers en parallèle

Cette solution combine recherche et modification de fichiers (avec sauvegarde) pour remplacer des chaînes de caractères spécifiques.

```powershell
# Définir les paramètres
$cheminDossier = "C:\Scripts"  # Modifiez ce chemin selon votre environnement
$extension = "*.ps1"           # Extension à rechercher
$chaineRecherche = "# TODO:"   # Chaîne à rechercher
$chaineRemplacement = "# COMPLETED:" # Chaîne de remplacement
$creerBackup = $true           # Créer une sauvegarde avant modification?

# Récupérer tous les fichiers de scripts
$fichiers = Get-ChildItem -Path $cheminDossier -Filter $extension -Recurse

Write-Host "Analyse et modification potentielle de $($fichiers.Count) fichiers en parallèle..." -ForegroundColor Cyan

# Traiter chaque fichier en parallèle
$resultats = $fichiers | ForEach-Object -Parallel {
    $fichier = $_
    $recherche = $using:chaineRecherche
    $remplacement = $using:chaineRemplacement
    $avecBackup = $using:creerBackup

    try {
        # Vérifier si le fichier contient la chaîne recherchée
        $contenu = Get-Content -Path $fichier.FullName -ErrorAction Stop
        $contientChaine = $contenu | Select-String -Pattern ([regex]::Escape($recherche)) -SimpleMatch

        # Compter les occurrences
        $nombreOccurrences = ($contenu | Select-String -Pattern ([regex]::Escape($recherche)) -SimpleMatch -AllMatches).Matches.Count

        $modifie = $false

        # Si des occurrences sont trouvées, effectuer le remplacement
        if ($nombreOccurrences -gt 0) {
            # Créer une sauvegarde si demandé
            if ($avecBackup) {
                $cheminBackup = "$($fichier.FullName).backup"
                Copy-Item -Path $fichier.FullName -Destination $cheminBackup -Force
            }

            # Effectuer le remplacement et sauvegarder
            $nouveauContenu = $contenu -replace [regex]::Escape($recherche), $remplacement
            $nouveauContenu | Set-Content -Path $fichier.FullName -Force
            $modifie = $true
        }

        # Retourner un objet avec les résultats
        [PSCustomObject]@{
            Fichier = $fichier.Name
            Chemin = $fichier.FullName
            ContientRecherche = $nombreOccurrences -gt 0
            NombreOccurrences = $nombreOccurrences
            Modifie = $modifie
            BackupCree = $modifie -and $avecBackup
            CheminBackup = if ($modifie -and $avecBackup) { $cheminBackup } else { $null }
            NombreLignes = $contenu.Count
            Taille = $fichier.Length
            DerniereMaj = $fichier.LastWriteTime
        }
    }
    catch {
        # En cas d'erreur, retourner un objet avec des informations sur l'erreur
        [PSCustomObject]@{
            Fichier = $fichier.Name
            Chemin = $fichier.FullName
            Erreur = $_.Exception.Message
            ContientRecherche = $false
            NombreOccurrences = 0
            Modifie = $false
            BackupCree = $false
            Taille = $fichier.Length
            DerniereMaj = $fichier.LastWriteTime
        }
    }
} -ThrottleLimit 5  # Limiter à 5 tâches parallèles pour éviter les problèmes I/O

# Afficher un résumé des résultats
$fichiersSansErreur = $resultats | Where-Object { -not $_.Erreur }
$fichiersModifies = $resultats | Where-Object { $_.Modifie }

Write-Host "`nRésumé des modifications :" -ForegroundColor Green
Write-Host "Nombre total de fichiers analysés : $($resultats.Count)" -ForegroundColor Yellow
Write-Host "Fichiers contenant la chaîne recherchée : $(($fichiersSansErreur | Where-Object { $_.ContientRecherche }).Count)" -ForegroundColor Yellow
Write-Host "Fichiers modifiés : $($fichiersModifies.Count)" -ForegroundColor Yellow
Write-Host "Nombre total d'occurrences trouvées : $(($fichiersSansErreur | Measure-Object -Property NombreOccurrences -Sum).Sum)" -ForegroundColor Yellow

# Afficher les fichiers modifiés
if ($fichiersModifies.Count -gt 0) {
    Write-Host "`nFichiers modifiés :" -ForegroundColor Green
    $fichiersModifies | Format-Table -Property Fichier, NombreOccurrences, BackupCree, CheminBackup
}

# Afficher les erreurs éventuelles
$fichiersAvecErreur = $resultats | Where-Object { $_.Erreur }
if ($fichiersAvecErreur) {
    Write-Host "`nFichiers avec erreurs :" -ForegroundColor Red
    $fichiersAvecErreur | Format-Table -Property Fichier, Erreur
}
```

### Solution 4 : Utilisation de runspaces pour l'analyse de fichiers

Cette solution utilise les runspaces au lieu de ForEach-Object -Parallel pour montrer une approche alternative plus avancée.

```powershell
# Importation des namespaces nécessaires
Add-Type -AssemblyName System.Threading

# Définir les paramètres
$cheminDossier = "C:\Data"     # Modifiez ce chemin selon votre environnement
$extension = "*.csv"           # Extension à rechercher
$maxRunspaces = 10             # Nombre maximum de runspaces

# Récupérer tous les fichiers correspondant au filtre
$fichiers = Get-ChildItem -Path $cheminDossier -Filter $extension -Recurse

Write-Host "Analyse de $($fichiers.Count) fichiers CSV en utilisant des runspaces..." -ForegroundColor Cyan

# Créer un pool de runspaces
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $maxRunspaces)
$runspacePool.Open()

# Liste pour stocker les runspaces et leurs résultats
$runspaces = New-Object System.Collections.ArrayList

# Script block pour analyser un fichier CSV
$scriptBlock = {
    param($fichier)

    try {
        # Vérifier que le fichier est bien un CSV
        $contenu = Import-Csv -Path $fichier.FullName -ErrorAction Stop

        # Calculer des statistiques sur le fichier CSV
        $nombreLignes = $contenu.Count
        $nombreColonnes = 0

        if ($nombreLignes -gt 0) {
            # Obtenir le nombre de colonnes à partir de la première ligne
            $nombreColonnes = ($contenu[0] | Get-Member -MemberType NoteProperty).Count
        }

        # Obtenir les noms des colonnes
        $nomsColonnes = @()
        if ($nombreLignes -gt 0) {
            $nomsColonnes = ($contenu[0] | Get-Member -MemberType NoteProperty).Name
        }

        # Vérifier les valeurs nulles ou vides dans chaque colonne
        $colonnesStats = @{}
        foreach ($colonne in $nomsColonnes) {
            $valeursNonVides = ($contenu.$colonne | Where-Object { $_ -ne $null -and $_ -ne "" }).Count
            $colonnesStats[$colonne] = @{
                Total = $nombreLignes
                NonVides = $valeursNonVides
                PourcentageRempli = if ($nombreLignes -gt 0) { [math]::Round(($valeursNonVides / $nombreLignes) * 100, 2) } else { 0 }
            }
        }

        # Retourner un objet avec les résultats
        [PSCustomObject]@{
            Fichier = $fichier.Name
            Chemin = $fichier.FullName
            NombreLignes = $nombreLignes
            NombreColonnes = $nombreColonnes
            NomsColonnes = $nomsColonnes
            StatistiquesColonnes = $colonnesStats
            Taille = $fichier.Length
            DerniereMaj = $fichier.LastWriteTime
            Erreur = $null
        }
    }
    catch {
        # En cas d'erreur, retourner un objet avec des informations sur l'erreur
        [PSCustomObject]@{
            Fichier = $fichier.Name
            Chemin = $fichier.FullName
            NombreLignes = 0
            NombreColonnes = 0
            NomsColonnes = @()
            StatistiquesColonnes = @{}
            Taille = $fichier.Length
            DerniereMaj = $fichier.LastWriteTime
            Erreur = $_.Exception.Message
        }
    }
}

# Pour chaque fichier, créer et démarrer un runspace
foreach ($fichier in $fichiers) {
    # Créer un PowerShell pour exécuter notre code
    $powershell = [powershell]::Create().AddScript($scriptBlock).AddArgument($fichier)
    $powershell.RunspacePool = $runspacePool

    # Démarrer l'exécution de manière asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter à notre liste de suivi
    [void]$runspaces.Add([PSCustomObject]@{
        PowerShell = $powershell
        Handle = $handle
        Fichier = $fichier
    })
}

Write-Host "Tous les runspaces ont été démarrés. Attente des résultats..." -ForegroundColor Cyan

# Liste pour stocker les résultats
$resultats = @()

# Récupérer les résultats de chaque runspace
foreach ($runspace in $runspaces) {
    $resultat = $runspace.PowerShell.EndInvoke($runspace.Handle)
    $resultats += $resultat

    # Nettoyer les ressources
    $runspace.PowerShell.Dispose()
}

# Fermer et nettoyer le pool de runspaces
$runspacePool.Close()
$runspacePool.Dispose()

# Afficher un résumé des résultats
$fichiersSansErreur = $resultats | Where-Object { $null -eq $_.Erreur }

Write-Host "`nRésumé de l'analyse des fichiers CSV :" -ForegroundColor Green
Write-Host "Nombre total de fichiers analysés : $($resultats.Count)" -ForegroundColor Yellow
Write-Host "Fichiers analysés avec succès : $($fichiersSansErreur.Count)" -ForegroundColor Yellow
Write-Host "Fichiers avec erreurs : $($resultats.Count - $fichiersSansErreur.Count)" -ForegroundColor Yellow

# Afficher les fichiers avec le plus de lignes
Write-Host "`nTop 5 des fichiers par nombre de lignes :" -ForegroundColor Green
$fichiersSansErreur |
    Sort-Object -Property NombreLignes -Descending |
    Select-Object -First 5 |
    Format-Table -Property Fichier, NombreLignes, NombreColonnes, Taille

# Afficher un résumé global des statistiques des colonnes
if ($fichiersSansErreur.Count -gt 0) {
    Write-Host "`nRésumé de la qualité des données par colonne (moyenne sur tous les fichiers) :" -ForegroundColor Green

    # Récupérer toutes les colonnes uniques
    $toutesColonnes = @()
    foreach ($resultat in $fichiersSansErreur) {
        $toutesColonnes += $resultat.NomsColonnes
    }
    $colonnesUniques = $toutesColonnes | Sort-Object | Get-Unique

    # Pour chaque colonne unique, calculer des statistiques moyennes
    foreach ($colonne in $colonnesUniques) {
        $fichiersAvecColonne = $fichiersSansErreur | Where-Object { $_.NomsColonnes -contains $colonne }

        if ($fichiersAvecColonne.Count -gt 0) {
            $moyennePourcentageRempli = ($fichiersAvecColonne | ForEach-Object { $_.StatistiquesColonnes[$colonne].PourcentageRempli } | Measure-Object -Average).Average

            Write-Host "$colonne : présent dans $($fichiersAvecColonne.Count) fichiers, rempli à $('{0:F2}' -f $moyennePourcentageRempli)% en moyenne" -ForegroundColor Yellow
        }
    }
}

# Afficher les erreurs éventuelles
$fichiersAvecErreur = $resultats | Where-Object { $null -ne $_.Erreur }
if ($fichiersAvecErreur) {
    Write-Host "`nFichiers avec erreurs :" -ForegroundColor Red
    $fichiersAvecErreur | Format-Table -Property Fichier, Erreur
}
```

### Conseils pour adapter ces exemples à vos besoins

1. **Modifiez les chemins** : Remplacez les chemins de dossiers utilisés dans les exemples par vos propres chemins.

2. **Adaptez les filtres** : Changez les extensions de fichiers (`.txt`, `.log`, `.ps1`, `.csv`) selon vos besoins.

3. **Ajustez le ThrottleLimit** : Si vous avez beaucoup de RAM et de CPU, vous pouvez augmenter le nombre de tâches parallèles. À l'inverse, réduisez-le si votre système est limité en ressources.

4. **Personnalisez les critères de recherche** : Modifiez les mots-clés, les motifs de recherche ou les chaînes à remplacer selon votre cas d'usage.

5. **Améliorez l'affichage des résultats** : Vous pouvez exporter les résultats dans un fichier CSV ou HTML pour une analyse ultérieure.

### Points d'attention

- Testez d'abord vos scripts sur un petit échantillon de fichiers avant de les exécuter sur un grand nombre de fichiers.
- Pour les modifications de fichiers (solution 3), assurez-vous de créer des sauvegardes et de tester votre script sur des copies.
- Surveillez l'utilisation des ressources (CPU, mémoire) pendant l'exécution de scripts parallèles intensifs.
- Pour des fichiers très volumineux, vous devrez peut-être adapter les solutions pour les traiter en blocs ou utiliser des approches d'analyse en streaming.

Ces solutions montrent la puissance du traitement parallèle dans PowerShell 7+ et vous donnent un point de départ pour développer vos propres scripts d'analyse et de traitement de fichiers en parallèle.
