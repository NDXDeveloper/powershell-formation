# Module 5 - Gestion des fichiers et du système
## 5-5. Dates et temps (`Get-Date`, manipulation des TimeSpan)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

La manipulation des dates et des temps est essentielle dans de nombreux scripts PowerShell : création de noms de fichiers avec horodatage, calcul d'âge de fichiers, planification de tâches, ou génération de rapports. PowerShell offre des outils puissants pour travailler avec les dates et durées, rendant ces opérations beaucoup plus simples qu'en ligne de commande traditionnelle.

### 🕒 Obtenir la date et l'heure actuelles

La cmdlet `Get-Date` est le point de départ pour travailler avec les dates :

```powershell
# Obtenir la date et l'heure actuelles
Get-Date

# Afficher seulement les propriétés qui vous intéressent
Get-Date | Select-Object Day, Month, Year, Hour, Minute, Second
```

### 📅 Formater les dates

La sortie de `Get-Date` peut être formatée de différentes manières :

```powershell
# Format standard court
Get-Date -Format "dd/MM/yyyy"      # Ex: 15/04/2023

# Format avec l'heure
Get-Date -Format "yyyy-MM-dd HH:mm:ss"  # Ex: 2023-04-15 14:30:45

# Format pour nom de fichier (sans caractères spéciaux)
Get-Date -Format "yyyyMMdd_HHmmss"  # Ex: 20230415_143045
```

#### Formats prédéfinis utiles

```powershell
# Date courte
Get-Date -Format d    # Ex: 15/04/2023

# Date longue
Get-Date -Format D    # Ex: samedi 15 avril 2023

# Heure courte
Get-Date -Format t    # Ex: 14:30

# Heure longue
Get-Date -Format T    # Ex: 14:30:45

# Date et heure complètes
Get-Date -Format f    # Ex: samedi 15 avril 2023 14:30
```

### ⏰ Manipuler les dates

Vous pouvez facilement ajouter ou soustraire des jours, mois, années, etc. :

```powershell
# Date d'hier
$hier = (Get-Date).AddDays(-1)

# Date dans une semaine
$prochaineSemaine = (Get-Date).AddDays(7)

# Le mois prochain
$moisProchain = (Get-Date).AddMonths(1)

# L'année dernière
$anneeDerniere = (Get-Date).AddYears(-1)
```

Vous pouvez également modifier des composants spécifiques :

```powershell
# Début du mois courant
$debutMois = Get-Date -Day 1 -Hour 0 -Minute 0 -Second 0

# Fin du mois courant
$finMois = (Get-Date -Day 1 -Hour 23 -Minute 59 -Second 59).AddMonths(1).AddDays(-1)

# Le premier jour du mois suivant
$premierJourMoisSuivant = (Get-Date -Day 1).AddMonths(1)
```

### 🔍 Extraire des informations d'une date

PowerShell vous permet d'obtenir facilement des informations spécifiques d'une date :

```powershell
$date = Get-Date

$date.DayOfWeek        # Jour de la semaine (ex: Monday)
$date.DayOfYear        # Jour de l'année (ex: 105)
$date.Month            # Mois (ex: 4)
$date.Year             # Année (ex: 2023)
$date.ToUniversalTime() # Convertir en UTC
```

### 📊 Comparer des dates

La comparaison de dates est très intuitive en PowerShell :

```powershell
$date1 = Get-Date
$date2 = $date1.AddDays(-5)

# Est-ce que date1 est plus récente que date2 ?
$date1 -gt $date2      # True

# Est-ce que date1 est plus ancienne que date2 ?
$date1 -lt $date2      # False

# Est-ce que les dates sont égales ?
$date1 -eq $date1      # True
```

### ⏱️ Mesurer des durées avec TimeSpan

`TimeSpan` représente une durée ou un intervalle de temps. C'est très utile pour mesurer des délais ou la durée d'exécution :

```powershell
# Créer un TimeSpan
$duree = New-TimeSpan -Days 2 -Hours 3 -Minutes 30

# Afficher la durée
$duree       # Ex: 2.03:30:00

# Accéder aux propriétés
$duree.Days             # 2
$duree.Hours            # 3
$duree.Minutes          # 30
$duree.TotalHours       # 51.5 (2 jours et 3 heures en heures)
$duree.TotalMinutes     # 3090 (2 jours, 3 heures et 30 minutes en minutes)
$duree.TotalSeconds     # 185400 (la durée totale en secondes)
```

#### Calculer la différence entre deux dates

```powershell
$dateDebut = Get-Date "2023-01-01"
$dateFin = Get-Date "2023-04-15"

$difference = $dateFin - $dateDebut

$difference.Days        # Nombre de jours entre les deux dates
$difference.TotalDays   # Nombre de jours avec décimales
```

#### Mesurer le temps d'exécution d'un script ou d'une commande

```powershell
$chrono = [System.Diagnostics.Stopwatch]::StartNew()

# Exécuter une commande qui prend du temps
Start-Sleep -Seconds 2

$chrono.Stop()
$chrono.Elapsed        # Durée écoulée (TimeSpan)
$chrono.ElapsedMilliseconds  # Durée en millisecondes
```

### 🗓️ Travailler avec les fuseaux horaires

Parfois, vous devez travailler avec différents fuseaux horaires :

```powershell
# Lister tous les fuseaux horaires disponibles
[System.TimeZoneInfo]::GetSystemTimeZones()

# Obtenir le fuseau horaire local
[System.TimeZoneInfo]::Local

# Convertir une date vers un autre fuseau horaire
$dateUTC = [System.DateTime]::UtcNow
$fuseau = [System.TimeZoneInfo]::FindSystemTimeZoneById("Romance Standard Time")  # Fuseau de Paris
[System.TimeZoneInfo]::ConvertTimeFromUtc($dateUTC, $fuseau)
```

### 📈 Exemples pratiques

#### Exemple 1: Nettoyage de fichiers anciens

```powershell
function Remove-OldFiles {
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [Parameter(Mandatory)]
        [int]$DaysToKeep
    )

    # Calculer la date limite
    $dateLimite = (Get-Date).AddDays(-$DaysToKeep)

    # Trouver et supprimer les fichiers plus anciens
    $fichiers = Get-ChildItem -Path $FolderPath -File |
        Where-Object { $_.LastWriteTime -lt $dateLimite }

    if ($fichiers.Count -eq 0) {
        Write-Host "Aucun fichier à supprimer." -ForegroundColor Yellow
        return
    }

    $tailleTotale = ($fichiers | Measure-Object -Property Length -Sum).Sum / 1MB

    Write-Host "Suppression de $($fichiers.Count) fichiers, libérant $([math]::Round($tailleTotale, 2)) MB" -ForegroundColor Cyan

    $fichiers | ForEach-Object {
        Remove-Item -Path $_.FullName -Force
        Write-Host "Supprimé: $($_.Name)" -ForegroundColor Gray
    }
}

# Utilisation
Remove-OldFiles -FolderPath "C:\Logs" -DaysToKeep 30
```

#### Exemple 2: Calculer l'âge à partir de la date de naissance

```powershell
function Get-Age {
    param (
        [Parameter(Mandatory)]
        [DateTime]$DateNaissance
    )

    $aujourd'hui = Get-Date
    $age = $aujourd'hui.Year - $DateNaissance.Year

    # Vérifier si l'anniversaire est déjà passé cette année
    if ($DateNaissance.Month -gt $aujourd'hui.Month -or
        ($DateNaissance.Month -eq $aujourd'hui.Month -and $DateNaissance.Day -gt $aujourd'hui.Day)) {
        $age--  # Réduire l'âge si l'anniversaire n'est pas encore passé
    }

    return $age
}

# Utilisation
$age = Get-Age -DateNaissance (Get-Date "1990-05-15")
Write-Host "Âge: $age ans"
```

#### Exemple 3: Création d'un journal d'activité avec horodatage

```powershell
function Write-ActivityLog {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [string]$LogFile = "C:\Logs\activite.log",

        [ValidateSet("Information", "Warning", "Error")]
        [string]$Level = "Information"
    )

    # Créer le dossier si nécessaire
    $dossierLog = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $dossierLog)) {
        New-Item -Path $dossierLog -ItemType Directory -Force | Out-Null
    }

    # Format: [Date] [Niveau] Message
    $horodatage = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entreeLog = "[$horodatage] [$Level] $Message"

    # Ajouter au fichier
    Add-Content -Path $LogFile -Value $entreeLog

    # Afficher différentes couleurs selon le niveau
    $couleur = switch ($Level) {
        "Information" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
    }

    Write-Host $entreeLog -ForegroundColor $couleur
}

# Utilisation
Write-ActivityLog -Message "Démarrage du script"
Write-ActivityLog -Message "Attention: ressources limitées" -Level Warning
Write-ActivityLog -Message "Erreur fatale détectée!" -Level Error
```

### 🌟 Astuce bonus: Créer un calendrier du mois en cours

```powershell
function Show-Calendar {
    param (
        [int]$Month = (Get-Date).Month,
        [int]$Year = (Get-Date).Year
    )

    $premierJour = Get-Date -Year $Year -Month $Month -Day 1
    $dernierJour = $premierJour.AddMonths(1).AddDays(-1)

    $joursSemaine = @("Di", "Lu", "Ma", "Me", "Je", "Ve", "Sa")
    $nomMois = (Get-Culture).DateTimeFormat.GetMonthName($Month)

    # Titre du calendrier
    Write-Host "`n    $nomMois $Year`n" -ForegroundColor Cyan

    # En-tête des jours de la semaine
    $joursSemaine -join " " | Write-Host -ForegroundColor Yellow

    # Position de départ (décalage pour le premier jour du mois)
    $position = [int]$premierJour.DayOfWeek
    $ligne = " " * 3 * $position

    # Remplir le calendrier
    for ($jour = 1; $jour -le $dernierJour.Day; $jour++) {
        # Ajouter le jour
        $ligne += "{0,2} " -f $jour
        $position++

        # Nouvelle ligne après samedi ou dernier jour
        if ($position -eq 7 -or $jour -eq $dernierJour.Day) {
            Write-Host $ligne
            $ligne = ""
            $position = 0
        }
    }

    Write-Host "`n"
}

# Afficher le calendrier du mois en cours
Show-Calendar
```

### 💪 Exercice pratique

Créez un script qui:
1. Liste tous les fichiers dans un dossier spécifié
2. Calcule pour chaque fichier:
   - Son âge en jours
   - S'il a été créé un jour de semaine ou un weekend
   - Combien de temps s'est écoulé depuis sa dernière modification
3. Génère un rapport qui trie les fichiers par âge et met en évidence ceux qui n'ont pas été modifiés depuis plus de 90 jours

### 🎓 Solution de l'exercice

```powershell
function Get-FileAgeReport {
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [int]$HighlightOlderThan = 90
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier spécifié n'existe pas: $FolderPath"
        return
    }

    $aujourdhui = Get-Date

    $fichiers = Get-ChildItem -Path $FolderPath -File | ForEach-Object {
        # Calculer l'âge et le temps depuis la dernière modification
        $ageJours = ($aujourdhui - $_.CreationTime).Days
        $derniereMaj = ($aujourdhui - $_.LastWriteTime).Days

        # Déterminer si créé en semaine ou weekend
        $jourSemaine = $_.CreationTime.DayOfWeek
        $estWeekend = $jourSemaine -eq "Saturday" -or $jourSemaine -eq "Sunday"

        # Créer un objet personnalisé avec les informations
        [PSCustomObject]@{
            Nom = $_.Name
            Extension = $_.Extension
            "Taille (KB)" = [math]::Round($_.Length / 1KB, 2)
            "Âge (jours)" = $ageJours
            "Jour de création" = $_.CreationTime.DayOfWeek
            "Créé le weekend" = $estWeekend
            "Jours depuis dernière modification" = $derniereMaj
            "Inactif" = $derniereMaj -gt $HighlightOlderThan
            "Date de création" = $_.CreationTime
            "Dernière modification" = $_.LastWriteTime
        }
    }

    # Statistiques générales
    $nbTotal = $fichiers.Count
    $nbInactifs = ($fichiers | Where-Object { $_.Inactif }).Count
    $nbWeekend = ($fichiers | Where-Object { $_."Créé le weekend" }).Count

    # Afficher le rapport
    Write-Host "`nRAPPORT D'ANALYSE DES FICHIERS" -ForegroundColor Cyan
    Write-Host "Dossier: $FolderPath" -ForegroundColor Cyan
    Write-Host "Date du rapport: $($aujourdhui.ToString('dd/MM/yyyy HH:mm'))" -ForegroundColor Cyan
    Write-Host "`nStatistiques:" -ForegroundColor Yellow
    Write-Host "- Nombre total de fichiers: $nbTotal" -ForegroundColor White
    Write-Host "- Fichiers inactifs (>$HighlightOlderThan jours): $nbInactifs" -ForegroundColor $(if ($nbInactifs -gt 0) { "Yellow" } else { "White" })
    Write-Host "- Fichiers créés le weekend: $nbWeekend" -ForegroundColor White

    Write-Host "`nFichiers par âge (du plus récent au plus ancien):" -ForegroundColor Yellow

    $fichiers | Sort-Object "Âge (jours)" | ForEach-Object {
        $couleurLigne = if ($_.Inactif) { "Yellow" } else { "White" }

        # Afficher chaque fichier avec sa couleur appropriée
        Write-Host ("{0,-40} | {1,6} jours | {2,-10} | {3,5} KB" -f
            $_.Nom,
            $_."Âge (jours)",
            $_.Inactif ? "INACTIF" : "Actif",
            $_."Taille (KB)") -ForegroundColor $couleurLigne
    }

    # Retourner les données pour un traitement ultérieur si nécessaire
    return $fichiers
}

# Utilisation
Get-FileAgeReport -FolderPath "C:\Scripts" -HighlightOlderThan 90
```

### 🔑 Points clés à retenir

- `Get-Date` est la cmdlet principale pour obtenir et manipuler les dates
- `-Format` permet de contrôler l'affichage des dates selon vos besoins
- Les méthodes `.AddDays()`, `.AddMonths()`, etc. permettent de modifier facilement les dates
- `TimeSpan` représente une durée et possède des propriétés utiles comme `.TotalDays` ou `.TotalHours`
- La soustraction de dates (`$date1 - $date2`) renvoie un `TimeSpan`
- Les dates peuvent être comparées avec les opérateurs standard (`-gt`, `-lt`, `-eq`)
- `[System.Diagnostics.Stopwatch]` est idéal pour mesurer précisément le temps d'exécution

### 🔮 Pour aller plus loin

Félicitations! Vous avez terminé le Module 5 sur la gestion des fichiers et du système. Vous savez maintenant naviguer dans le système de fichiers, lire et écrire des données dans différents formats, gérer les permissions, compresser des archives et manipuler les dates et durées.

Dans le prochain module, nous explorerons la création de fonctions et la structuration de code pour rendre vos scripts plus modulaires, réutilisables et faciles à maintenir.

---

💡 **Astuce de pro**: Standardisez vos formats de date dans tous vos scripts pour éviter les confusions. Le format ISO (`yyyy-MM-dd`) est idéal car il est reconnu internationalement et permet un tri alphabétique correct.
