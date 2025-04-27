# 📁 Module 16-1 : Mini-projets PowerShell

## Introduction

Bienvenue dans la section des mini-projets PowerShell ! Ces projets sont conçus pour vous permettre d'appliquer les connaissances acquises tout au long de cette formation. Chaque projet est autonome et peut être réalisé à votre rythme, en fonction de votre niveau de compétence.

## Mini-Projet 1 : Inventaire Réseau

### Objectif
Créer un script qui scanne votre réseau local et génère un rapport des appareils connectés.

### Niveau de difficulté
⭐⭐☆☆☆ (Débutant+)

### Compétences utilisées
- Commandes réseau
- Génération de rapports
- Manipulation d'objets

### Instructions

1. Créez un nouveau fichier nommé `Inventaire-Reseau.ps1`.
2. Commencez par définir la plage d'adresses IP à scanner :

```powershell
# Définir la plage d'adresses IP
$reseauBase = "192.168.1"  # Modifiez selon votre réseau
$plageDebut = 1
$plageFin = 254
```

3. Créez une fonction pour scanner chaque adresse IP :

```powershell
function Test-Appareil {
    param (
        [string]$AdresseIP
    )

    $resultatPing = Test-Connection -ComputerName $AdresseIP -Count 1 -Quiet

    if ($resultatPing) {
        try {
            $nomHote = [System.Net.Dns]::GetHostEntry($AdresseIP).HostName
        }
        catch {
            $nomHote = "Inconnu"
        }

        [PSCustomObject]@{
            AdresseIP = $AdresseIP
            EnLigne = $true
            NomHote = $nomHote
            DateScan = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}
```

4. Utilisez cette fonction pour scanner toutes les adresses et générer un rapport :

```powershell
# Créer un tableau pour stocker les résultats
$resultats = @()

# Afficher une barre de progression
Write-Host "Scan du réseau en cours..."
$compteur = 0
$total = $plageFin - $plageDebut + 1

# Scanner chaque adresse IP
for ($i = $plageDebut; $i -le $plageFin; $i++) {
    $adresseIP = "$reseauBase.$i"

    # Afficher la progression
    $compteur++
    $pourcentage = [math]::Round(($compteur / $total) * 100)
    Write-Progress -Activity "Scan du réseau" -Status "$pourcentage% Complet" -PercentComplete $pourcentage -CurrentOperation "Vérification de $adresseIP"

    # Tester l'appareil
    $resultat = Test-Appareil -AdresseIP $adresseIP
    if ($resultat) {
        $resultats += $resultat
    }
}

# Masquer la barre de progression
Write-Progress -Activity "Scan du réseau" -Completed

# Afficher les résultats
$resultats | Format-Table -AutoSize

# Exporter les résultats
$cheminFichier = "$env:USERPROFILE\Desktop\Inventaire-Reseau-$(Get-Date -Format 'yyyy-MM-dd').csv"
$resultats | Export-Csv -Path $cheminFichier -NoTypeInformation -Encoding UTF8

Write-Host "Rapport généré avec succès : $cheminFichier" -ForegroundColor Green
```

### Améliorations possibles
- Ajouter des informations réseau supplémentaires (MAC, fabricant)
- Implémenter un scan de ports pour identifier les services
- Créer une interface graphique simple pour visualiser les résultats

---

## Mini-Projet 2 : Backup Automatique

### Objectif
Créer un script de sauvegarde automatique qui peut être programmé pour s'exécuter régulièrement.

### Niveau de difficulté
⭐⭐☆☆☆ (Débutant+)

### Compétences utilisées
- Gestion de fichiers
- Compression
- Journalisation
- Planification de tâches

### Instructions

1. Créez un nouveau fichier nommé `Backup-Auto.ps1`.
2. Définissez les paramètres de sauvegarde :

```powershell
param (
    [string]$SourcePath = "$env:USERPROFILE\Documents",
    [string]$BackupPath = "$env:USERPROFILE\Backups",
    [switch]$CompressBackup = $true
)

# Créer un dossier de sauvegarde s'il n'existe pas
if (-not (Test-Path -Path $BackupPath)) {
    New-Item -Path $BackupPath -ItemType Directory | Out-Null
    Write-Host "Dossier de sauvegarde créé : $BackupPath" -ForegroundColor Yellow
}

# Démarrer la journalisation
$logFile = "$BackupPath\backup_log_$(Get-Date -Format 'yyyy-MM-dd').txt"
Start-Transcript -Path $logFile -Append

# Afficher les informations de démarrage
Write-Host "===== BACKUP AUTOMATIQUE =====" -ForegroundColor Cyan
Write-Host "Date : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "Source : $SourcePath" -ForegroundColor Cyan
Write-Host "Destination : $BackupPath" -ForegroundColor Cyan
Write-Host "============================" -ForegroundColor Cyan
```

3. Ajoutez la logique de sauvegarde :

```powershell
# Créer le nom du fichier de sauvegarde
$dateStamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$backupFileName = "Backup_$dateStamp"
$backupFullPath = Join-Path -Path $BackupPath -ChildPath $backupFileName

# Copier les fichiers
try {
    if ($CompressBackup) {
        # Créer une archive compressée
        Write-Host "Création d'une archive compressée..." -ForegroundColor Blue
        Compress-Archive -Path $SourcePath -DestinationPath "$backupFullPath.zip" -CompressionLevel Optimal -Force
        $resultatBackup = "$backupFullPath.zip"
    }
    else {
        # Copier les fichiers sans compression
        Write-Host "Copie des fichiers en cours..." -ForegroundColor Blue
        $resultatBackup = "$backupFullPath"
        New-Item -Path $resultatBackup -ItemType Directory | Out-Null
        Copy-Item -Path "$SourcePath\*" -Destination $resultatBackup -Recurse -Force
    }

    Write-Host "Sauvegarde terminée avec succès !" -ForegroundColor Green
    Write-Host "Fichiers sauvegardés dans : $resultatBackup" -ForegroundColor Green
}
catch {
    Write-Host "ERREUR lors de la sauvegarde : $_" -ForegroundColor Red
}

# Nettoyer les anciennes sauvegardes (garder seulement les 5 plus récentes)
Write-Host "Nettoyage des anciennes sauvegardes..." -ForegroundColor Blue
$toutesLesSauvegardes = Get-ChildItem -Path $BackupPath | Where-Object { $_.Name -like "Backup_*" } | Sort-Object -Property LastWriteTime -Descending
if ($toutesLesSauvegardes.Count -gt 5) {
    $sauvegardesASupprimer = $toutesLesSauvegardes | Select-Object -Skip 5
    foreach ($sauvegarde in $sauvegardesASupprimer) {
        Remove-Item -Path $sauvegarde.FullName -Force -Recurse
        Write-Host "Suppression de l'ancienne sauvegarde : $($sauvegarde.Name)" -ForegroundColor Yellow
    }
}

# Arrêter la journalisation
Stop-Transcript
```

4. Pour planifier l'exécution de ce script, vous pouvez utiliser le Planificateur de tâches Windows. Voici une commande PowerShell qui crée une tâche planifiée qui s'exécute quotidiennement à 22h00 :

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$env:USERPROFILE\Scripts\Backup-Auto.ps1`""
$trigger = New-ScheduledTaskTrigger -Daily -At "22:00"
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "BackupQuotidien" -Description "Sauvegarde quotidienne des documents" -RunLevel Highest
```

### Améliorations possibles
- Ajouter une rotation des sauvegardes (quotidiennes, hebdomadaires, mensuelles)
- Envoyer un e-mail de confirmation après chaque sauvegarde
- Ajouter des options de restauration

---

## Mini-Projet 3 : API Météo

### Objectif
Créer un script qui consulte une API météo et affiche les prévisions pour une ville donnée.

### Niveau de difficulté
⭐⭐⭐☆☆ (Intermédiaire)

### Compétences utilisées
- Appels API REST
- Traitement JSON
- Formatage des données

### Instructions

1. Créez un nouveau fichier nommé `Get-MeteoVille.ps1`.
2. Inscrivez-vous sur [OpenWeatherMap](https://openweathermap.org/api) pour obtenir une clé API gratuite.
3. Implémentez le script pour récupérer les données météo :

```powershell
function Get-MeteoVille {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Ville,

        [Parameter(Mandatory = $true)]
        [string]$CleAPI
    )

    # Construire l'URL de l'API
    $url = "https://api.openweathermap.org/data/2.5/weather?q=$Ville&appid=$CleAPI&units=metric&lang=fr"

    try {
        # Appeler l'API
        $reponse = Invoke-RestMethod -Uri $url -Method Get

        # Formater les données reçues
        $meteo = [PSCustomObject]@{
            Ville = $reponse.name
            Pays = $reponse.sys.country
            Description = $reponse.weather[0].description
            Temperature = "$($reponse.main.temp) °C"
            TemperatureRessentie = "$($reponse.main.feels_like) °C"
            TempMin = "$($reponse.main.temp_min) °C"
            TempMax = "$($reponse.main.temp_max) °C"
            Humidite = "$($reponse.main.humidity) %"
            VitesseVent = "$($reponse.wind.speed) m/s"
            DirectionVent = "$($reponse.wind.deg)°"
            Pression = "$($reponse.main.pressure) hPa"
            Nuages = "$($reponse.clouds.all) %"
            LeverSoleil = (Get-Date -UnixTimeSeconds $reponse.sys.sunrise).ToString("HH:mm")
            CoucherSoleil = (Get-Date -UnixTimeSeconds $reponse.sys.sunset).ToString("HH:mm")
            DateHeure = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }

        return $meteo
    }
    catch {
        Write-Error "Erreur lors de la récupération des données météo : $_"
    }
}
```

4. Ajoutez une interface utilisateur simple :

```powershell
# Script principal
Clear-Host
Write-Host "📊 APPLICATION MÉTÉO POWERSHELL 📊" -ForegroundColor Cyan
Write-Host "====================================`n" -ForegroundColor Cyan

# Saisie de la clé API (à faire une seule fois)
$cheminCleAPI = "$env:USERPROFILE\meteo_api_key.txt"
if (Test-Path $cheminCleAPI) {
    $cleAPI = Get-Content $cheminCleAPI
}
else {
    $cleAPI = Read-Host "Veuillez entrer votre clé API OpenWeatherMap"
    $cleAPI | Out-File -FilePath $cheminCleAPI
}

# Demander la ville
$ville = Read-Host "Entrez le nom d'une ville"

# Obtenir les données météo
try {
    $meteo = Get-MeteoVille -Ville $ville -CleAPI $cleAPI

    # Afficher les résultats
    Write-Host "`n🌤️  MÉTÉO ACTUELLE: $($meteo.Ville), $($meteo.Pays)" -ForegroundColor Yellow
    Write-Host "----------------------------------------------" -ForegroundColor Yellow
    Write-Host "📝 Conditions : $($meteo.Description)"
    Write-Host "🌡️  Température : $($meteo.Temperature) (ressentie : $($meteo.TemperatureRessentie))"
    Write-Host "🔼 Max : $($meteo.TempMax) | 🔽 Min : $($meteo.TempMin)"
    Write-Host "💧 Humidité : $($meteo.Humidite)"
    Write-Host "💨 Vent : $($meteo.VitesseVent) (direction : $($meteo.DirectionVent))"
    Write-Host "☁️  Nuages : $($meteo.Nuages)"
    Write-Host "☀️  Lever du soleil : $($meteo.LeverSoleil) | 🌙 Coucher : $($meteo.CoucherSoleil)"
    Write-Host "⏱️  Dernière mise à jour : $($meteo.DateHeure)`n"

    # Proposer d'exporter les données
    $exporter = Read-Host "Voulez-vous exporter ces données dans un fichier CSV? (O/N)"
    if ($exporter -eq "O" -or $exporter -eq "o") {
        $cheminExport = "$env:USERPROFILE\Desktop\Meteo_$($meteo.Ville)_$(Get-Date -Format 'yyyy-MM-dd').csv"
        $meteo | Export-Csv -Path $cheminExport -NoTypeInformation -Encoding UTF8
        Write-Host "Données exportées dans : $cheminExport" -ForegroundColor Green
    }
}
catch {
    Write-Host "Impossible de récupérer les données météo. Vérifiez le nom de la ville et votre connexion Internet." -ForegroundColor Red
}
```

### Améliorations possibles
- Ajouter les prévisions sur plusieurs jours
- Créer une interface graphique avec une représentation visuelle
- Ajouter un système de favoris pour les villes fréquemment consultées

---

## Mini-Projet 4 : Moniteur de Performance Système

### Objectif
Créer un outil de surveillance qui collecte et analyse les performances du système.

### Niveau de difficulté
⭐⭐⭐☆☆ (Intermédiaire)

### Compétences utilisées
- Collecte de métriques système
- Manipulation d'objets
- Visualisation des données
- Planification

### Instructions

1. Créez un nouveau fichier nommé `Monitor-Systeme.ps1`.
2. Implémentez la collecte des métriques :

```powershell
function Get-MetriquesSysteme {
    # Récupérer les métriques CPU
    $cpuUtilisation = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3
    $cpuMoyen = ($cpuUtilisation.CounterSamples.CookedValue | Measure-Object -Average).Average

    # Récupérer les métriques mémoire
    $memoireTotale = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $memoireDisponible = (Get-Counter '\Memory\Available MBytes' -SampleInterval 1 -MaxSamples 1).CounterSamples.CookedValue / 1024
    $memoireUtilisee = $memoireTotale - $memoireDisponible
    $pourcentageMemoire = [math]::Round(($memoireUtilisee / $memoireTotale) * 100, 2)

    # Récupérer les métriques disque
    $disques = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $espaceTotal = $_.Size / 1GB
        $espaceLibre = $_.FreeSpace / 1GB
        $espaceUtilise = $espaceTotal - $espaceLibre
        $pourcentageUtilisation = [math]::Round(($espaceUtilise / $espaceTotal) * 100, 2)

        [PSCustomObject]@{
            Lecteur = $_.DeviceID
            EspaceTotal = [math]::Round($espaceTotal, 2)
            EspaceLibre = [math]::Round($espaceLibre, 2)
            EspaceUtilise = [math]::Round($espaceUtilise, 2)
            PourcentageUtilisation = $pourcentageUtilisation
        }
    }

    # Récupérer les processus les plus consommateurs
    $topProcessusCPU = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5 | ForEach-Object {
        [PSCustomObject]@{
            Nom = $_.Name
            ID = $_.Id
            CPU = [math]::Round($_.CPU, 2)
            MemoryMB = [math]::Round($_.WorkingSet / 1MB, 2)
        }
    }

    $topProcessusMemoire = Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5 | ForEach-Object {
        [PSCustomObject]@{
            Nom = $_.Name
            ID = $_.Id
            CPU = [math]::Round($_.CPU, 2)
            MemoryMB = [math]::Round($_.WorkingSet / 1MB, 2)
        }
    }

    # Créer l'objet de rapport
    $rapport = [PSCustomObject]@{
        Horodatage = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Ordinateur = $env:COMPUTERNAME
        CPU = [math]::Round($cpuMoyen, 2)
        MemoireTotaleGB = [math]::Round($memoireTotale, 2)
        MemoireUtiliseeGB = [math]::Round($memoireUtilisee, 2)
        PourcentageMemoire = $pourcentageMemoire
        Disques = $disques
        TopProcessusCPU = $topProcessusCPU
        TopProcessusMemoire = $topProcessusMemoire
    }

    return $rapport
}
```

3. Ajoutez l'affichage et l'enregistrement des données :

```powershell
# Dossier de sortie pour les rapports
$dossierRapports = "$env:USERPROFILE\SystemMonitor"
if (-not (Test-Path -Path $dossierRapports)) {
    New-Item -Path $dossierRapports -ItemType Directory | Out-Null
}

# Fichier CSV pour l'historique
$dateAujourdhui = Get-Date -Format "yyyy-MM-dd"
$fichierCSV = "$dossierRapports\SystemMonitor_$dateAujourdhui.csv"

# Mode d'exécution (instantané ou surveillance continue)
param (
    [switch]$Surveiller,
    [int]$Intervalle = 60,  # secondes
    [int]$Duree = 60        # minutes
)

# Fonction pour afficher le rapport
function Show-Rapport {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Rapport
    )

    Clear-Host
    Write-Host "📊 MONITEUR DE PERFORMANCE SYSTÈME 📊" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "Ordinateur : $($Rapport.Ordinateur)" -ForegroundColor White
    Write-Host "Date/Heure : $($Rapport.Horodatage)" -ForegroundColor White
    Write-Host "=======================================" -ForegroundColor Cyan

    # Afficher CPU
    $cpuCouleur = switch ($Rapport.CPU) {
        {$_ -lt 60} { "Green" }
        {$_ -lt 85} { "Yellow" }
        default { "Red" }
    }
    Write-Host "`n🔄 CPU : " -NoNewline
    Write-Host "$($Rapport.CPU)%" -ForegroundColor $cpuCouleur

    # Afficher Mémoire
    $memoireCouleur = switch ($Rapport.PourcentageMemoire) {
        {$_ -lt 60} { "Green" }
        {$_ -lt 85} { "Yellow" }
        default { "Red" }
    }
    Write-Host "`n💾 MÉMOIRE : " -NoNewline
    Write-Host "$($Rapport.PourcentageMemoire)%" -ForegroundColor $memoireCouleur
    Write-Host "   Utilisée : $($Rapport.MemoireUtiliseeGB) GB / $($Rapport.MemoireTotaleGB) GB"

    # Afficher Disques
    Write-Host "`n💿 DISQUES :"
    foreach ($disque in $Rapport.Disques) {
        $disqueCouleur = switch ($disque.PourcentageUtilisation) {
            {$_ -lt 70} { "Green" }
            {$_ -lt 90} { "Yellow" }
            default { "Red" }
        }

        Write-Host "   $($disque.Lecteur) : " -NoNewline
        Write-Host "$($disque.PourcentageUtilisation)%" -ForegroundColor $disqueCouleur
        Write-Host "      Espace : $($disque.EspaceUtilise) GB / $($disque.EspaceTotal) GB"
    }

    # Top Processus
    Write-Host "`n⚡ TOP 5 PROCESSUS (CPU) :"
    $Rapport.TopProcessusCPU | Format-Table -Property Nom, ID, CPU, MemoryMB -AutoSize

    Write-Host "⚡ TOP 5 PROCESSUS (MÉMOIRE) :"
    $Rapport.TopProcessusMemoire | Format-Table -Property Nom, ID, CPU, MemoryMB -AutoSize
}

# Exécution principale
if (-not $Surveiller) {
    # Mode instantané
    $rapport = Get-MetriquesSysteme
    Show-Rapport -Rapport $rapport

    # Sauvegarder dans le CSV
    $rapportCSV = [PSCustomObject]@{
        Horodatage = $rapport.Horodatage
        Ordinateur = $rapport.Ordinateur
        CPU = $rapport.CPU
        MemoireUtiliseeGB = $rapport.MemoireUtiliseeGB
        MemoireTotaleGB = $rapport.MemoireTotaleGB
        PourcentageMemoire = $rapport.PourcentageMemoire
    }

    # Ajouter les métriques des disques
    foreach ($disque in $rapport.Disques) {
        $rapportCSV | Add-Member -NotePropertyName "Disque_$($disque.Lecteur)_Pct" -NotePropertyValue $disque.PourcentageUtilisation
    }

    $rapportCSV | Export-Csv -Path $fichierCSV -Append -NoTypeInformation
}
else {
    # Mode surveillance continue
    $iterations = ($Duree * 60) / $Intervalle
    $compteur = 0

    while ($compteur -lt $iterations) {
        $rapport = Get-MetriquesSysteme
        Show-Rapport -Rapport $rapport

        # Sauvegarder dans le CSV (même logique que ci-dessus)
        $rapportCSV = [PSCustomObject]@{
            Horodatage = $rapport.Horodatage
            Ordinateur = $rapport.Ordinateur
            CPU = $rapport.CPU
            MemoireUtiliseeGB = $rapport.MemoireUtiliseeGB
            MemoireTotaleGB = $rapport.MemoireTotaleGB
            PourcentageMemoire = $rapport.PourcentageMemoire
        }

        foreach ($disque in $rapport.Disques) {
            $rapportCSV | Add-Member -NotePropertyName "Disque_$($disque.Lecteur)_Pct" -NotePropertyValue $disque.PourcentageUtilisation
        }

        $rapportCSV | Export-Csv -Path $fichierCSV -Append -NoTypeInformation

        $compteur++

        if ($compteur -lt $iterations) {
            Write-Host "`nProchaine mise à jour dans $Intervalle secondes... (Ctrl+C pour quitter)" -ForegroundColor Gray
            Start-Sleep -Seconds $Intervalle
        }
    }
}

Write-Host "`nRapport enregistré dans : $fichierCSV" -ForegroundColor Green
```

### Comment utiliser le script
- Pour un rapport instantané : `.\Monitor-Systeme.ps1`
- Pour une surveillance continue : `.\Monitor-Systeme.ps1 -Surveiller -Intervalle 30 -Duree 120` (toutes les 30 secondes pendant 2 heures)

### Améliorations possibles
- Ajouter des graphiques pour visualiser les tendances
- Envoyer des alertes par e-mail en cas de dépassement de seuil
- Ajouter des métriques réseau

---

## Mini-Projet 5 : Gestionnaire de Notes

### Objectif
Créer une application simple de prise de notes en PowerShell.

### Niveau de difficulté
⭐⭐☆☆☆ (Débutant+)

### Compétences utilisées
- Persistance des données
- Manipulation de fichiers JSON
- Interface utilisateur en console

### Instructions

1. Créez un nouveau fichier nommé `Notes-Manager.ps1`.
2. Implémentez les fonctions de base :

```powershell
# Configuration initiale
$dossierNotes = "$env:USERPROFILE\PowerShellNotes"
$fichierNotes = "$dossierNotes\notes.json"

# Créer le dossier s'il n'existe pas
if (-not (Test-Path -Path $dossierNotes)) {
    New-Item -Path $dossierNotes -ItemType Directory | Out-Null
}

# Créer le fichier JSON s'il n'existe pas
if (-not (Test-Path -Path $fichierNotes)) {
    @{
        Notes = @()
    } | ConvertTo-Json | Out-File -FilePath $fichierNotes -Encoding utf8
}

# Fonction pour charger les notes
function Get-Notes {
    $contenu = Get-Content -Path $fichierNotes -Raw | ConvertFrom-Json
    return $contenu.Notes
}

# Fonction pour sauvegarder les notes
function Save-Notes {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Notes
    )

    @{
        Notes = $Notes
    } | ConvertTo-Json | Out-File -FilePath $fichierNotes -Encoding utf8
}

# Fonction pour ajouter une note
function Add-Note {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Titre,

        [Parameter(Mandatory = $true)]
        [string]$Contenu,

        [string]$Categorie = "Général"
    )

    $notes = Get-Notes

    $nouvelleNote = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Titre = $Titre
        Contenu = $Contenu
        Categorie = $Categorie
        DateCreation = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        DateModification = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $notes += $nouvelleNote
    Save-Notes -Notes $notes

    return $nouvelleNote
}

# Fonction pour afficher une note
function Show-Note {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    $notes = Get-Notes
    $note = $notes | Where-Object { $_.Id -eq $Id }

    if ($note) {
        Clear-Host
        Write-Host "📝 $($note.Titre)" -ForegroundColor Yellow
        Write-Host "Catégorie: $($note.Categorie)" -ForegroundColor Cyan
        Write-Host "Créée le: $($note.DateCreation)" -ForegroundColor Gray
        Write-Host "Modifiée le: $($note.DateModification)" -ForegroundColor Gray
        Write-Host "----------------------------------------" -ForegroundColor Yellow
        Write-Host $note.Contenu
        Write-Host "----------------------------------------" -ForegroundColor Yellow
    }
    else {
        Write-Host "Note non trouvée!" -ForegroundColor Red
    }
}

# Fonction pour modifier une note
function Edit-Note {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [string]$Titre,
        [string]$Contenu,
        [string]$Categorie
    )

    $notes = Get-Notes
    $noteIndex = 0
    $noteFound = $false

    foreach ($note in $notes) {
        if ($note.Id -eq $Id) {
            $noteFound = $true
            break
        }
        $noteIndex++
    }

    if ($noteFound) {
        if ($Titre) {
            $notes[$noteIndex].Titre = $Titre
        }

        if ($Contenu) {
            $notes[$noteIndex].Contenu = $Contenu
        }

        if ($Categorie) {
            $notes[$noteIndex].Categorie = $Categorie
        }

        $notes[$noteIndex].DateModification = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        Save-Notes -Notes $notes
        return $notes[$noteIndex]
    }
    else {
        Write-Host "Note non trouvée!" -ForegroundColor Red
        return $null
    }
}

# Fonction pour supprimer une note
function Remove-NoteItem {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    $notes = Get-Notes
    $notesFiltrées = $notes | Where-Object { $_.Id -ne $Id }

    if ($notes.Count -ne $notesFiltrées.Count) {
        Save-Notes -Notes $notesFiltrées
        Write-Host "Note supprimée avec succès!" -ForegroundColor Green
        return $true
    }
    else {
        Write-Host "Note non trouvée!" -ForegroundColor Red
        return $false
    }
}

# Interface utilisateur en console
function Show-Menu {
    Clear-Host
    Write-Host "📒 GESTIONNAIRE DE NOTES POWERSHELL 📒" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host "1. Afficher toutes les notes" -ForegroundColor White
    Write-Host "2. Ajouter une nouvelle note" -ForegroundColor White
    Write-Host "3. Voir le détail d'une note" -ForegroundColor White
    Write-Host "4. Modifier une note" -ForegroundColor White
    Write-Host "5. Supprimer une note" -ForegroundColor White
    Write-Host "6. Rechercher des notes" -ForegroundColor White
    Write-Host "0. Quitter" -ForegroundColor White
    Write-Host "=====================================" -ForegroundColor Cyan

    $choix = Read-Host "Votre choix"
    return $choix
}

# Boucle principale du programme
function Start-NotesManager {
    $continuer = $true

    while ($continuer) {
        $choix = Show-Menu

        switch ($choix) {
            "1" {
                # Afficher toutes les notes
                Clear-Host
                Write-Host "📋 LISTE DES NOTES" -ForegroundColor Cyan
                Write-Host "=================" -ForegroundColor Cyan

                $notes = Get-Notes
                if ($notes.Count -eq 0) {
                    Write-Host "Aucune note trouvée." -ForegroundColor Yellow
                }
                else {
                    $notes | ForEach-Object -Begin {$i = 1} -Process {
                        Write-Host "$i. " -NoNewline -ForegroundColor White
                        Write-Host "$($_.Titre)" -NoNewline -ForegroundColor Yellow
                        Write-Host " [$($_.Categorie)]" -ForegroundColor Cyan
                        $i++
                    }
                }

                Write-Host "`nAppuyez sur une touche pour continuer..."
                [Console]::ReadKey($true) | Out-Null
            }
            "2" {
                # Ajouter une note
                Clear-Host
                Write-Host "➕ AJOUTER UNE NOTE" -ForegroundColor Cyan
                Write-Host "=================" -ForegroundColor Cyan

                $titre = Read-Host "Titre"
                $categorie = Read-Host "Catégorie (laissez vide pour 'Général')"
                if ([string]::IsNullOrWhiteSpace($categorie)) {
                    $categorie = "Général"
                }

                Write-Host "Contenu (terminez par une ligne vide) :"
                $lignes = @()
                $ligne = Read-Host
                while ($ligne -ne "") {
                    $lignes += $ligne
                    $ligne = Read-Host
                }
                $contenu = $lignes -join "`n"

                $nouvelleNote = Add-Note -Titre $titre -Contenu $contenu -Categorie $categorie
                Write-Host "Note ajoutée avec succès!" -ForegroundColor Green

                Write-Host "`nAppuyez sur une touche pour continuer..."
                [Console]::ReadKey($true) | Out-Null
            }
            "3" {
                # Voir une note
                Clear-Host
                Write-Host "👁️ VOIR UNE NOTE" -ForegroundColor Cyan
                Write-Host "=============" -ForegroundColor Cyan

                $notes = Get-Notes
                if ($notes.Count -eq 0) {
                    Write-Host "Aucune note trouvée." -ForegroundColor Yellow
                }
                else {
                    $notes | ForEach-Object -Begin {$i = 1} -Process {
                        Write-Host "$i. " -NoNewline -ForegroundColor White
                        Write-Host "$($_.Titre)" -ForegroundColor Yellow
                        $i++
                    }

                    $selection = Read-Host "`nEntrez le numéro de la note à afficher"
                    $index = [int]$selection - 1

                    if ($index -ge 0 -and $index -lt $notes.Count) {
                        Show-Note -Id $notes[$index].Id
                    }
                    else {
                        Write-Host "Sélection invalide!" -ForegroundColor Red
                    }
                }

                Write-Host "`nAppuyez sur une touche pour continuer..."
                [Console]::ReadKey($true) | Out-Null
            }
            "4" {
                # Modifier une note
                Clear-Host
                Write-Host "✏️ MODIFIER UNE NOTE" -ForegroundColor Cyan
                Write-Host "=================" -ForegroundColor Cyan

                $notes = Get-Notes
                if ($notes.Count -eq 0) {
                    Write-Host "Aucune note trouvée." -ForegroundColor Yellow
                }
                else {
                    $notes | ForEach-Object -Begin {$i = 1} -Process {
                        Write-Host "$i. " -NoNewline -ForegroundColor White
                        Write-Host "$($_.Titre)" -ForegroundColor Yellow
                        $i++
                    }

                    $selection = Read-Host "`nEntrez le numéro de la note à modifier"
                    $index = [int]$selection - 1

                    if ($index -ge 0 -and $index -lt $notes.Count) {
                        $note = $notes[$index]
                        Write-Host "`nLaissez vide pour conserver la valeur actuelle"

                        $titre = Read-Host "Titre [$($note.Titre)]"
                        if ([string]::IsNullOrWhiteSpace($titre)) {
                            $titre = $null
                        }

                        $categorie = Read-Host "Catégorie [$($note.Categorie)]"
                        if ([string]::IsNullOrWhiteSpace($categorie)) {
                            $categorie = $null
                        }

                        Write-Host "Contenu actuel :"
                        Write-Host $note.Contenu
                        Write-Host "`nNouveau contenu (terminez par une ligne vide, ou entrez '.' pour conserver) :"

                        $contenu = $null
                        $premiereLigne = Read-Host

                        if ($premiereLigne -ne ".") {
                            $lignes = @($premiereLigne)
                            $ligne = Read-Host
                            while ($ligne -ne "") {
                                $lignes += $ligne
                                $ligne = Read-Host
                            }
                            $contenu = $lignes -join "`n"
                        }

                        Edit-Note -Id $note.Id -Titre $titre -Contenu $contenu -Categorie $categorie
                        Write-Host "Note modifiée avec succès!" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Sélection invalide!" -ForegroundColor Red
                    }
                }

                Write-Host "`nAppuyez sur une touche pour continuer..."
                [Console]::ReadKey($true) | Out-Null
            }
            "5" {
                # Supprimer une note
                Clear-Host
                Write-Host "❌ SUPPRIMER UNE NOTE" -ForegroundColor Cyan
                Write-Host "==================" -ForegroundColor Cyan

                $notes = Get-Notes
                if ($notes.Count -eq 0) {
                    Write-Host "Aucune note trouvée." -ForegroundColor Yellow
                }
                else {
                    $notes | ForEach-Object -Begin {$i = 1} -Process {
                        Write-Host "$i. " -NoNewline -ForegroundColor White
                        Write-Host "$($_.Titre)" -ForegroundColor Yellow
                        $i++
                    }

                    $selection = Read-Host "`nEntrez le numéro de la note à supprimer"
                    $index = [int]$selection - 1

                    if ($index -ge 0 -and $index -lt $notes.Count) {
                        $confirmation = Read-Host "Êtes-vous sûr de vouloir supprimer cette note? (O/N)"

                        if ($confirmation -eq "O" -or $confirmation -eq "o") {
                            Remove-NoteItem -Id $notes[$index].Id
                        }
                        else {
                            Write-Host "Suppression annulée." -ForegroundColor Yellow
                        }
                    }
                    else {
                        Write-Host "Sélection invalide!" -ForegroundColor Red
                    }
                }

                Write-Host "`nAppuyez sur une touche pour continuer..."
                [Console]::ReadKey($true) | Out-Null
            }
            "6" {
                # Rechercher des notes
                Clear-Host
                Write-Host "🔍 RECHERCHER DES NOTES" -ForegroundColor Cyan
                Write-Host "===================" -ForegroundColor Cyan

                $termeRecherche = Read-Host "Entrez un terme à rechercher"

                $notes = Get-Notes
                $resultats = $notes | Where-Object {
                    $_.Titre -like "*$termeRecherche*" -or
                    $_.Contenu -like "*$termeRecherche*" -or
                    $_.Categorie -like "*$termeRecherche*"
                }

                if ($resultats.Count -eq 0) {
                    Write-Host "Aucun résultat trouvé pour '$termeRecherche'." -ForegroundColor Yellow
                }
                else {
                    Write-Host "`nRésultats de recherche pour '$termeRecherche' :" -ForegroundColor Yellow
                    $resultats | ForEach-Object -Begin {$i = 1} -Process {
                        Write-Host "$i. " -NoNewline -ForegroundColor White
                        Write-Host "$($_.Titre)" -NoNewline -ForegroundColor Yellow
                        Write-Host " [$($_.Categorie)]" -ForegroundColor Cyan
                        $i++
                    }

                    $voirDetail = Read-Host "`nVoulez-vous voir le détail d'une note? (numéro ou N)"

                    if ($voirDetail -ne "N" -and $voirDetail -ne "n") {
                        $index = [int]$voirDetail - 1

                        if ($index -ge 0 -and $index -lt $resultats.Count) {
                            Show-Note -Id $resultats[$index].Id
                        }
                        else {
                            Write-Host "Sélection invalide!" -ForegroundColor Red
                        }
                    }
                }

                Write-Host "`nAppuyez sur une touche pour continuer..."
                [Console]::ReadKey($true) | Out-Null
            }
            "0" {
                # Quitter
                Clear-Host
                Write-Host "Merci d'avoir utilisé le Gestionnaire de Notes PowerShell!" -ForegroundColor Cyan
                $continuer = $false
            }
            default {
                Write-Host "Option invalide. Veuillez réessayer." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Lancer l'application
Start-NotesManager
```

### Améliorations possibles
- Ajouter des fonctionnalités d'exportation (PDF, HTML)
- Implémenter un système de tags/étiquettes
- Ajouter une synchronisation avec un service cloud
- Créer une interface graphique WPF

---

# Mini-Projet 6 : Dashboard Admin Système

## Objectif
Créer un tableau de bord pour administrateur système qui affiche les informations essentielles dans une interface web.

## Niveau de difficulté
⭐⭐⭐⭐☆ (Avancé)

## Compétences utilisées
- Collecte de données système
- Hébergement web PowerShell
- HTML/CSS dynamique
- Automatisation

## Instructions

1. Créez un nouveau fichier nommé `Admin-Dashboard.ps1`.
2. Implémentez les fonctions de collecte de données :

```powershell
function Get-SystemSummary {
    # Infos système
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $bios = Get-CimInstance -ClassName Win32_BIOS
    $computer = Get-CimInstance -ClassName Win32_ComputerSystem

    # Uptime
    $bootTime = $os.LastBootUpTime
    $uptime = (Get-Date) - $bootTime

    # Mémoire
    $memoireTotaleGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $memoireDisponibleGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $pourcentageMemoire = [math]::Round(($memoireDisponibleGB / $memoireTotaleGB) * 100, 2)

    # CPU
    $cpuUtilisation = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3).CounterSamples
    $cpuMoyen = [math]::Round(($cpuUtilisation | Measure-Object -Property CookedValue -Average).Average, 2)

    # Disques
    $disques = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $espaceTotal = [math]::Round($_.Size / 1GB, 2)
        $espaceLibre = [math]::Round($_.FreeSpace / 1GB, 2)
        $pourcentageUtilisation = [math]::Round((($espaceTotal - $espaceLibre) / $espaceTotal) * 100, 2)

        [PSCustomObject]@{
            Lecteur = $_.DeviceID
            EspaceTotal = $espaceTotal
            EspaceLibre = $espaceLibre
            PourcentageUtilisation = $pourcentageUtilisation
        }
    }

    # Top processus
    $topProcessus = Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 5 | ForEach-Object {
        [PSCustomObject]@{
            Nom = $_.Name
            ID = $_.Id
            CPU = [math]::Round($_.CPU, 2)
            MemoireMB = [math]::Round($_.WorkingSet / 1MB, 2)
        }
    }

    # Services critiques
    $servicesCritiques = @(
        "wuauserv",      # Windows Update
        "WinDefend",     # Windows Defender
        "wscsvc",        # Security Center
        "BITS",          # Background Intelligent Transfer
        "Spooler",       # Print Spooler
        "LanmanServer"   # File and Printer Sharing
    )

    $etatsServices = foreach ($service in $servicesCritiques) {
        $serviceObj = Get-Service -Name $service -ErrorAction SilentlyContinue
        if ($serviceObj) {
            [PSCustomObject]@{
                Nom = $serviceObj.DisplayName
                Etat = $serviceObj.Status
                Description = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$service'").Description
            }
        }
    }

    # Récupérer les derniers logs système
    $derniersLogs = Get-EventLog -LogName System -EntryType Error,Warning -Newest 10 | ForEach-Object {
        [PSCustomObject]@{
            Temps = $_.TimeGenerated
            Source = $_.Source
            Type = $_.EntryType
            ID = $_.EventID
            Message = $_.Message.Split("`n")[0]  # Première ligne uniquement
        }
    }

    # Résumé des mises à jour
    $miseAJour = New-Object -ComObject Microsoft.Update.Session
    $chercheur = $miseAJour.CreateUpdateSearcher()
    $requeteMaj = "IsInstalled=0 and Type='Software'"

    try {
        $resultats = $chercheur.Search($requeteMaj)
        $nbMisesAJour = $resultats.Updates.Count
    }
    catch {
        $nbMisesAJour = "Erreur lors de la vérification"
    }

    # Assembler le résultat
    $resultat = [PSCustomObject]@{
        ComputerName = $env:COMPUTERNAME
        OSInfo = "$($os.Caption) - $($os.Version)"
        Manufacturer = $computer.Manufacturer
        Model = $computer.Model
        Uptime = "$($uptime.Days) jours, $($uptime.Hours) heures, $($uptime.Minutes) minutes"
        LastBoot = $bootTime
        BIOSVersion = $bios.Version
        CPU = $cpuMoyen
        MemoryTotalGB = $memoireTotaleGB
        MemoryAvailableGB = $memoireDisponibleGB
        MemoryPercentFree = $pourcentageMemoire
        Disks = $disques
        TopProcesses = $topProcessus
        CriticalServices = $etatsServices
        RecentEvents = $derniersLogs
        PendingUpdates = $nbMisesAJour
    }

    return $resultat
}
```

3. Créez une fonction pour générer le tableau de bord HTML :

```powershell
function New-DashboardHTML {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SystemData
    )

    $htmlTemplate = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PowerShell Admin Dashboard</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .dashboard {
            max-width: 1200px;
            margin: 0 auto;
        }
        header {
            background-color: #0078d7;
            color: white;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .refresh-time {
            font-size: 0.8em;
        }
        .card {
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            padding: 15px;
            margin-bottom: 20px;
        }
        h1, h2, h3 {
            margin-top: 0;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
        }
        .full-width {
            grid-column: 1 / -1;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid #ddd;
        }
        th, td {
            padding: 10px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:nth-child(even) {
            background-color: #f9f9f9;
        }
        .status {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 5px;
        }
        .status-running {
            background-color: #4CAF50;
        }
        .status-stopped {
            background-color: #f44336;
        }
        .status-other {
            background-color: #ff9800;
        }
        .progress-bar {
            height: 10px;
            background-color: #e0e0e0;
            border-radius: 5px;
            margin-top: 5px;
        }
        .progress-fill {
            height: 100%;
            border-radius: 5px;
        }
        .progress-fill-normal {
            background-color: #4CAF50;
        }
        .progress-fill-warning {
            background-color: #ff9800;
        }
        .progress-fill-danger {
            background-color: #f44336;
        }
        .hidden {
            display: none;
        }
        .tabs {
            display: flex;
            margin-bottom: 15px;
        }
        .tab {
            padding: 10px 15px;
            background-color: #ddd;
            border-radius: 5px 5px 0 0;
            margin-right: 5px;
            cursor: pointer;
        }
        .tab.active {
            background-color: white;
            border-bottom: 2px solid #0078d7;
        }
        .tab-content {
            display: none;
        }
        .tab-content.active {
            display: block;
        }
    </style>
</head>
<body>
    <div class="dashboard">
        <header>
            <h1>PowerShell Admin Dashboard</h1>
            <div class="refresh-time">
                Dernière mise à jour: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
                <button onclick="location.reload()">Actualiser</button>
            </div>
        </header>

        <div class="grid">
            <!-- Infos Système -->
            <div class="card">
                <h2>🖥️ Informations Système</h2>
                <table>
                    <tr>
                        <td><strong>Nom</strong></td>
                        <td>$($SystemData.ComputerName)</td>
                    </tr>
                    <tr>
                        <td><strong>OS</strong></td>
                        <td>$($SystemData.OSInfo)</td>
                    </tr>
                    <tr>
                        <td><strong>Fabricant</strong></td>
                        <td>$($SystemData.Manufacturer)</td>
                    </tr>
                    <tr>
                        <td><strong>Modèle</strong></td>
                        <td>$($SystemData.Model)</td>
                    </tr>
                    <tr>
                        <td><strong>BIOS</strong></td>
                        <td>$($SystemData.BIOSVersion)</td>
                    </tr>
                    <tr>
                        <td><strong>Uptime</strong></td>
                        <td>$($SystemData.Uptime)</td>
                    </tr>
                    <tr>
                        <td><strong>Démarré le</strong></td>
                        <td>$($SystemData.LastBoot)</td>
                    </tr>
                    <tr>
                        <td><strong>Mises à jour</strong></td>
                        <td>$($SystemData.PendingUpdates) en attente</td>
                    </tr>
                </table>
            </div>

            <!-- Performance CPU/RAM -->
            <div class="card">
                <h2>📊 Performance</h2>
                <h3>CPU: $($SystemData.CPU)%</h3>
                <div class="progress-bar">
                    <div class="progress-fill $('progress-fill-normal', 'progress-fill-warning', 'progress-fill-danger')[$($SystemData.CPU -gt 85) + ($SystemData.CPU -gt 60)]" style="width: $($SystemData.CPU)%;"></div>
                </div>

                <h3>Mémoire: $($SystemData.MemoryPercentFree)% libre</h3>
                <p>$($SystemData.MemoryAvailableGB) GB / $($SystemData.MemoryTotalGB) GB disponible</p>
                <div class="progress-bar">
                    <div class="progress-fill $('progress-fill-danger', 'progress-fill-warning', 'progress-fill-normal')[$($SystemData.MemoryPercentFree -gt 40) + ($SystemData.MemoryPercentFree -gt 20)]" style="width: $(100 - $SystemData.MemoryPercentFree)%;"></div>
                </div>
            </div>

            <!-- Disques -->
            <div class="card">
                <h2>💿 Disques</h2>
                <table>
                    <tr>
                        <th>Lecteur</th>
                        <th>Utilisation</th>
                        <th>Espace</th>
                    </tr>
"@

    foreach ($disque in $SystemData.Disks) {
        $classeRemplissage = 'progress-fill-normal'
        if ($disque.PourcentageUtilisation -gt 85) {
            $classeRemplissage = 'progress-fill-danger'
        }
        elseif ($disque.PourcentageUtilisation -gt 70) {
            $classeRemplissage = 'progress-fill-warning'
        }

        $htmlTemplate += @"
                    <tr>
                        <td>$($disque.Lecteur)</td>
                        <td>
                            <div class="progress-bar">
                                <div class="progress-fill $classeRemplissage" style="width: $($disque.PourcentageUtilisation)%;"></div>
                            </div>
                            $($disque.PourcentageUtilisation)%
                        </td>
                        <td>$($disque.EspaceLibre) GB libres / $($disque.EspaceTotal) GB</td>
                    </tr>
"@
    }

    $htmlTemplate += @"
                </table>
            </div>

            <!-- Services -->
            <div class="card">
                <h2>⚙️ Services Critiques</h2>
                <table>
                    <tr>
                        <th>Service</th>
                        <th>Statut</th>
                    </tr>
"@

    foreach ($service in $SystemData.CriticalServices) {
        $statusClass = 'status-other'
        if ($service.Etat -eq 'Running') {
            $statusClass = 'status-running'
        }
        elseif ($service.Etat -eq 'Stopped') {
            $statusClass = 'status-stopped'
        }

        $htmlTemplate += @"
                    <tr>
                        <td title="$($service.Description)">$($service.Nom)</td>
                        <td><span class="status $statusClass"></span> $($service.Etat)</td>
                    </tr>
"@
    }

    $htmlTemplate += @"
                </table>
            </div>

            <!-- Top Processus -->
            <div class="card full-width">
                <h2>🔄 Top Processus</h2>
                <table>
                    <tr>
                        <th>Nom</th>
                        <th>PID</th>
                        <th>CPU</th>
                        <th>Mémoire (MB)</th>
                    </tr>
"@

    foreach ($process in $SystemData.TopProcesses) {
        $htmlTemplate += @"
                    <tr>
                        <td>$($process.Nom)</td>
                        <td>$($process.ID)</td>
                        <td>$($process.CPU)</td>
                        <td>$($process.MemoireMB)</td>
                    </tr>
"@
    }

    $htmlTemplate += @"
                </table>
            </div>

            <!-- Événements récents -->
            <div class="card full-width">
                <h2>📝 Événements récents</h2>
                <table>
                    <tr>
                        <th>Date/Heure</th>
                        <th>Type</th>
                        <th>Source</th>
                        <th>ID</th>
                        <th>Message</th>
                    </tr>
"@

    foreach ($event in $SystemData.RecentEvents) {
        $eventClass = "normal"
        if ($event.Type -eq "Error") {
            $eventClass = "danger"
        }
        elseif ($event.Type -eq "Warning") {
            $eventClass = "warning"
        }

        $htmlTemplate += @"
                    <tr class="$eventClass">
                        <td>$($event.Temps)</td>
                        <td>$($event.Type)</td>
                        <td>$($event.Source)</td>
                        <td>$($event.ID)</td>
                        <td>$($event.Message)</td>
                    </tr>
"@
    }

    $htmlTemplate += @"
                </table>
            </div>
        </div>
    </div>

    <script>
        // Auto refresh every 5 minutes
        setTimeout(() => {
            location.reload();
        }, 300000);

        // Toggle tabs
        function openTab(evt, tabName) {
            const tabcontent = document.getElementsByClassName("tab-content");
            for (let i = 0; i < tabcontent.length; i++) {
                tabcontent[i].style.display = "none";
            }

            const tablinks = document.getElementsByClassName("tab");
            for (let i = 0; i < tablinks.length; i++) {
                tablinks[i].className = tablinks[i].className.replace(" active", "");
            }

            document.getElementById(tabName).style.display = "block";
            evt.currentTarget.className += " active";
        }
    </script>
</body>
</html>
"@

    return $htmlTemplate
}
```

4. Créez une fonction pour démarrer le serveur web :

```powershell
function Start-AdminDashboard {
    param (
        [int]$Port = 8080,
        [int]$RefreshInterval = 60  # Secondes
    )

    # Vérifie les droits d'administrateur
    $estAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $estAdmin) {
        Write-Warning "Ce script nécessite des droits d'administrateur pour certaines opérations."
        Write-Warning "Certaines informations peuvent ne pas être disponibles."
    }

    # Créer le dossier pour stocker les données
    $dossierDashboard = "$env:USERPROFILE\AdminDashboard"
    if (-not (Test-Path -Path $dossierDashboard)) {
        New-Item -Path $dossierDashboard -ItemType Directory | Out-Null
        Write-Host "Dossier créé : $dossierDashboard" -ForegroundColor Yellow
    }

    # Chemin du fichier HTML
    $cheminHTML = "$dossierDashboard\dashboard.html"

    # Générer les données système et le HTML
    $donneesSysteme = Get-SystemSummary
    $html = New-DashboardHTML -SystemData $donneesSysteme
    $html | Out-File -FilePath $cheminHTML -Encoding utf8

    Write-Host "Dashboard généré à : $cheminHTML" -ForegroundColor Green

    # Démarrer le serveur HTTP
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()

    Write-Host "Serveur HTTP démarré sur http://localhost:$Port/" -ForegroundColor Green
    Write-Host "Appuyez sur Ctrl+C pour arrêter le serveur." -ForegroundColor Yellow

    # Planifier la mise à jour des données
    $timer = New-Object System.Timers.Timer
    $timer.Interval = $RefreshInterval * 1000
    $timer.AutoReset = $true

    $updateAction = {
        try {
            $donneesSysteme = Get-SystemSummary
            $html = New-DashboardHTML -SystemData $donneesSysteme
            $html | Out-File -FilePath $cheminHTML -Encoding utf8

            Write-Host "Dashboard mis à jour à $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
        }
        catch {
            Write-Host "Erreur lors de la mise à jour : $_" -ForegroundColor Red
        }
    }

    $timer.Elapsed.Add($updateAction)
    $timer.Start()

    # Traiter les demandes HTTP
    try {
        while ($listener.IsListening) {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response

            # Chemin demandé
            $requestUrl = $request.Url.LocalPath

            # Préparer la réponse
            if ($requestUrl -eq "/" -or $requestUrl -eq "/index.html") {
                $content = [System.IO.File]::ReadAllBytes($cheminHTML)
                $response.ContentType = "text/html"
                $response.ContentLength64 = $content.Length
                $response.OutputStream.Write($content, 0, $content.Length)
            }
            else {
                $response.StatusCode = 404
            }

            $response.Close()
        }
    }
    finally {
        # Nettoyer les ressources
        $timer.Stop()
        $timer.Dispose()
        $listener.Stop()
        Write-Host "Serveur HTTP arrêté." -ForegroundColor Yellow
    }
}
```

5. Ajoutez le code principal pour exécuter le dashboard :

```powershell
# Vérifier les arguments
param (
    [int]$Port = 8080,
    [int]$RefreshInterval = 60,
    [switch]$GenerateOnly
)

# Si -GenerateOnly est spécifié, générer uniquement le HTML sans démarrer le serveur
if ($GenerateOnly) {
    $donneesSysteme = Get-SystemSummary
    $html = New-DashboardHTML -SystemData $donneesSysteme
    $cheminHTML = "$env:USERPROFILE\AdminDashboard\dashboard.html"

    # Créer le dossier si nécessaire
    $dossierDashboard = "$env:USERPROFILE\AdminDashboard"
    if (-not (Test-Path -Path $dossierDashboard)) {
        New-Item -Path $dossierDashboard -ItemType Directory | Out-Null
    }

    $html | Out-File -FilePath $cheminHTML -Encoding utf8
    Write-Host "Dashboard généré à : $cheminHTML" -ForegroundColor Green
}
else {
    # Démarrer le dashboard interactif
    Write-Host "Démarrage du Dashboard Admin..." -ForegroundColor Cyan
    Start-AdminDashboard -Port $Port -RefreshInterval $RefreshInterval
}
```

## Comment utiliser le script

1. Pour générer un fichier HTML statique : `.\Admin-Dashboard.ps1 -GenerateOnly`
2. Pour démarrer le serveur web avec auto-rafraîchissement : `.\Admin-Dashboard.ps1`
3. Pour personnaliser le port et l'intervalle : `.\Admin-Dashboard.ps1 -Port 8090 -RefreshInterval 30`

## Comment accéder au dashboard

1. Exécutez le script avec les droits d'administrateur pour de meilleurs résultats.
2. Ouvrez votre navigateur et accédez à `http://localhost:8080/` (ou au port que vous avez spécifié).
3. Le dashboard se rafraîchira automatiquement selon l'intervalle configuré.

## Améliorations possibles

- Ajouter une authentification pour sécuriser l'accès
- Créer des graphiques historiques pour les performances
- Implémenter des alertes par e-mail en cas de problèmes détectés
- Ajouter la possibilité de redémarrer des services depuis l'interface
- Intégrer des informations sur les ordinateurs du réseau local
- Ajouter des fonctionnalités de surveillance réseau

---

