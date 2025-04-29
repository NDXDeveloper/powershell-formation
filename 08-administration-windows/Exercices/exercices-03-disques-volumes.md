# Solutions des exercices - Module 9-3 : Gestion des disques, partitions, volumes

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Exercice 1 : Lister tous les disques et identifier leur type de partition

### Solution :

```powershell
# Solution simple
Get-Disk | Select-Object Number, FriendlyName, PartitionStyle, Size

# Solution avancée avec formatage amélioré
Get-Disk | Select-Object Number, FriendlyName,
    @{Name="Taille (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}},
    PartitionStyle,
    @{Name="État"; Expression={$_.OperationalStatus}},
    @{Name="En ligne"; Expression={if($_.IsOffline){"Non"}else{"Oui"}}},
    @{Name="Lecture seule"; Expression={if($_.IsReadOnly){"Oui"}else{"Non"}}} |
Format-Table -AutoSize
```

### Explication :

Cette commande liste tous les disques physiques de votre système. La première solution donne une vue simple avec les informations essentielles. La seconde solution offre un rapport plus détaillé et formaté avec :
- Le numéro du disque
- Son nom convivial
- Sa taille en GB (convertie et arrondie)
- Son type de partition (MBR ou GPT)
- Son état opérationnel
- S'il est en ligne ou non
- S'il est en lecture seule ou non

Le résultat est formaté en tableau pour une meilleure lisibilité.

## Exercice 2 : Créer un rapport des volumes avec moins de 15% d'espace libre

### Solution :

```powershell
# Créer le rapport complet
$report = Get-Volume | Where-Object {$_.DriveLetter -ne $null -and $_.Size -gt 0} |
    Select-Object DriveLetter, FileSystemLabel,
        @{Name="TotalGB"; Expression={[math]::Round($_.Size/1GB, 2)}},
        @{Name="FreeGB"; Expression={[math]::Round($_.SizeRemaining/1GB, 2)}},
        @{Name="FreePercent"; Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100, 1)}}

# Filtrer les volumes avec moins de 15% d'espace libre
$lowSpaceVolumes = $report | Where-Object {$_.FreePercent -lt 15}

# Afficher les résultats
$lowSpaceVolumes | Format-Table -AutoSize

# Créer un rapport HTML (optionnel)
$htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'espace disque critique</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .warning { background-color: #ffe6e6; }
        .critical { background-color: #ffcccc; }
        h1 { color: #003366; }
    </style>
</head>
<body>
    <h1>Volumes avec espace disque critique</h1>
    <table>
        <tr>
            <th>Lettre</th>
            <th>Étiquette</th>
            <th>Total (GB)</th>
            <th>Libre (GB)</th>
            <th>% Libre</th>
        </tr>
"@

foreach ($vol in $lowSpaceVolumes) {
    $class = if ($vol.FreePercent -lt 5) { "critical" } else { "warning" }
    $htmlReport += @"
        <tr class="$class">
            <td>$($vol.DriveLetter):</td>
            <td>$($vol.FileSystemLabel)</td>
            <td>$($vol.TotalGB)</td>
            <td>$($vol.FreeGB)</td>
            <td>$($vol.FreePercent)%</td>
        </tr>
"@
}

$htmlReport += @"
    </table>
    <p>Rapport généré le $(Get-Date -Format "dd/MM/yyyy HH:mm")</p>
</body>
</html>
"@

# Sauvegarder le rapport HTML
$htmlReport | Out-File -FilePath "$env:USERPROFILE\Desktop\LowDiskSpaceReport.html"

# Ouvrir le rapport dans le navigateur par défaut (optionnel)
# Invoke-Item "$env:USERPROFILE\Desktop\LowDiskSpaceReport.html"

# Exporter aussi au format CSV pour une utilisation future
$lowSpaceVolumes | Export-Csv -Path "$env:USERPROFILE\Desktop\LowDiskSpaceReport.csv" -NoTypeInformation
```

### Explication :

Cette solution :
1. Collecte d'abord tous les volumes qui ont une lettre de lecteur attribuée et une taille supérieure à 0
2. Calcule l'espace total, l'espace libre et le pourcentage d'espace libre pour chaque volume
3. Filtre les volumes dont l'espace libre est inférieur à 15%
4. Affiche le résultat dans un tableau pour une consultation rapide
5. Crée un rapport HTML formaté avec un code couleur (optionnel)
   - Rouge foncé pour les volumes avec moins de 5% d'espace libre
   - Rouge clair pour les volumes entre 5% et 15% d'espace libre
6. Sauvegarde également les données au format CSV pour une analyse ultérieure

Ce rapport vous permet d'identifier rapidement les volumes qui nécessitent une attention particulière.

## Exercice 3 : Créer un disque virtuel, l'initialiser, créer une partition et la formater

### Solution :

```powershell
# Définir le chemin du disque virtuel
$vhdPath = "$env:USERPROFILE\Documents\Virtual-Disks"
$vhdFile = "TestDisk.vhdx"
$fullPath = Join-Path -Path $vhdPath -ChildPath $vhdFile

# Créer le dossier s'il n'existe pas
if (-not (Test-Path -Path $vhdPath)) {
    New-Item -Path $vhdPath -ItemType Directory
    Write-Host "Dossier créé : $vhdPath" -ForegroundColor Green
}

# Vérifier si le fichier existe déjà
if (Test-Path -Path $fullPath) {
    Write-Warning "Le fichier $vhdFile existe déjà. Voulez-vous le remplacer ? (O/N)"
    $response = Read-Host
    if ($response -ne "O" -and $response -ne "o") {
        Write-Host "Opération annulée." -ForegroundColor Yellow
        return
    }
    # Supprimer l'ancien fichier
    Remove-Item -Path $fullPath -Force
    Write-Host "Ancien fichier supprimé." -ForegroundColor Yellow
}

# 1. Créer le disque virtuel de 5 GB
Write-Host "1. Création du disque virtuel de 5 GB..." -ForegroundColor Cyan
$vhd = New-VHD -Path $fullPath -SizeBytes 5GB -Dynamic
Write-Host "   Disque virtuel créé : $($vhd.Path)" -ForegroundColor Green

# 2. Monter le disque virtuel
Write-Host "2. Montage du disque virtuel..." -ForegroundColor Cyan
$disk = Mount-VHD -Path $fullPath -PassThru
Write-Host "   Disque monté avec le numéro : $($disk.DiskNumber)" -ForegroundColor Green

# 3. Initialiser le disque
Write-Host "3. Initialisation du disque..." -ForegroundColor Cyan
Initialize-Disk -Number $disk.DiskNumber -PartitionStyle GPT
Write-Host "   Disque initialisé avec le style de partition GPT" -ForegroundColor Green

# 4. Créer une partition
Write-Host "4. Création d'une partition..." -ForegroundColor Cyan
$partition = New-Partition -DiskNumber $disk.DiskNumber -UseMaximumSize -AssignDriveLetter
Write-Host "   Partition créée avec la lettre de lecteur : $($partition.DriveLetter)" -ForegroundColor Green

# 5. Formater la partition
Write-Host "5. Formatage de la partition..." -ForegroundColor Cyan
$volume = Format-Volume -DriveLetter $partition.DriveLetter -FileSystem NTFS -NewFileSystemLabel "VirtualDisk" -Confirm:$false
Write-Host "   Partition formatée en NTFS avec l'étiquette 'VirtualDisk'" -ForegroundColor Green

# 6. Afficher les informations sur le volume
Write-Host "`nInformations sur le volume créé :" -ForegroundColor Magenta
Get-Volume -DriveLetter $partition.DriveLetter |
    Select-Object DriveLetter, FileSystemLabel, FileSystem,
        @{Name="Taille (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}},
        @{Name="Espace libre (GB)"; Expression={[math]::Round($_.SizeRemaining/1GB, 2)}} |
    Format-List

# 7. Créer un fichier test sur le nouveau volume
$testFilePath = "$($partition.DriveLetter):\TestFile.txt"
$testContent = "Ceci est un fichier test créé le $(Get-Date)`nCe disque virtuel a été créé par PowerShell!"
$testContent | Out-File -FilePath $testFilePath
Write-Host "Un fichier test a été créé à l'emplacement : $testFilePath" -ForegroundColor Green

Write-Host "`nLe disque virtuel a été correctement créé, monté et formaté." -ForegroundColor Green
Write-Host "Pour démonter le disque, exécutez : Dismount-VHD -Path '$fullPath'" -ForegroundColor Yellow
```

### Explication :

Cette solution complète :

1. **Préparation**
   - Définit les chemins et noms de fichiers
   - Crée un dossier pour stocker les disques virtuels s'il n'existe pas
   - Vérifie si le fichier existe déjà et demande confirmation pour le remplacer

2. **Création et initialisation**
   - Crée un disque virtuel dynamique de 5 GB
   - Monte le disque dans le système
   - Initialise le disque avec le style de partition GPT

3. **Partitionnement et formatage**
   - Crée une partition qui utilise tout l'espace disponible
   - Assigne automatiquement une lettre de lecteur
   - Formate la partition en NTFS avec l'étiquette "VirtualDisk"

4. **Vérification**
   - Affiche les informations détaillées sur le volume créé
   - Crée un fichier test sur le nouveau volume pour vérifier qu'il fonctionne
   - Affiche des instructions pour démonter le disque si nécessaire

Chaque étape est accompagnée de messages colorés pour une meilleure lisibilité, et la solution gère les cas d'erreur les plus courants (comme un fichier déjà existant).

## Bonus : Script de vérification d'état des disques

```powershell
function Test-DiskHealth {
    [CmdletBinding()]
    param()

    process {
        # 1. Vérifier les disques physiques
        Write-Host "=== État des disques physiques ===" -ForegroundColor Cyan
        Get-Disk | ForEach-Object {
            $disk = $_
            $diskStatus = if ($disk.HealthStatus -eq "Healthy") { "OK" } else { "PROBLÈME" }
            $statusColor = if ($disk.HealthStatus -eq "Healthy") { "Green" } else { "Red" }

            Write-Host "Disque $($disk.Number): $($disk.FriendlyName) - État: " -NoNewline
            Write-Host $diskStatus -ForegroundColor $statusColor

            # Vérifier si le disque est en lecture seule ou hors ligne
            if ($disk.IsReadOnly) {
                Write-Host "  ⚠️ Ce disque est en LECTURE SEULE" -ForegroundColor Yellow
            }
            if ($disk.IsOffline) {
                Write-Host "  ⚠️ Ce disque est HORS LIGNE" -ForegroundColor Yellow
            }
        }

        # 2. Vérifier l'espace disque
        Write-Host "`n=== Espace disque disponible ===" -ForegroundColor Cyan
        Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.Size -gt 0 } | ForEach-Object {
            $volume = $_
            $freePercent = [math]::Round(($volume.SizeRemaining / $volume.Size) * 100, 1)
            $freeGB = [math]::Round($volume.SizeRemaining / 1GB, 2)
            $totalGB = [math]::Round($volume.Size / 1GB, 2)

            # Déterminer la couleur en fonction de l'espace libre
            $spaceColor = "Green"
            if ($freePercent -lt 10) { $spaceColor = "Red" }
            elseif ($freePercent -lt 20) { $spaceColor = "Yellow" }

            $volumeLabel = if ([string]::IsNullOrEmpty($volume.FileSystemLabel)) { "(Sans étiquette)" } else { $volume.FileSystemLabel }

            Write-Host "$($volume.DriveLetter): ($volumeLabel) - " -NoNewline
            Write-Host "$freeGB GB libres sur $totalGB GB ($freePercent%)" -ForegroundColor $spaceColor
        }

        # 3. Vérifier les disques virtuels montés
        $mountedVHDs = Get-VHD -ErrorAction SilentlyContinue
        if ($mountedVHDs) {
            Write-Host "`n=== Disques virtuels montés ===" -ForegroundColor Cyan
            foreach ($vhd in $mountedVHDs) {
                Write-Host "$($vhd.Path) - Taille: $([math]::Round($vhd.Size/1GB, 2)) GB - Type: $($vhd.VhdType)" -ForegroundColor Magenta
            }
        }
    }
}

# Exécuter la fonction
Test-DiskHealth
```

Ce script bonus vérifie l'état de santé de tous vos disques, l'espace disponible sur vos volumes et liste les disques virtuels montés. Il utilise un code couleur pour vous alerter des problèmes potentiels.
