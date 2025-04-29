# Module 9-3 : Gestion des disques, partitions, volumes

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

La gestion des disques est une tâche courante pour les administrateurs système. PowerShell offre un ensemble complet de cmdlets qui vous permettent de gérer facilement vos disques, partitions et volumes sans avoir à utiliser l'interface graphique de Windows. Ce chapitre vous guidera à travers les commandes essentielles pour gérer vos ressources de stockage.

## Prérequis

- PowerShell 5.1 ou version ultérieure
- Droits d'administrateur sur votre système
- Connaissances de base de PowerShell (variables, pipeline)

## 1. Afficher les informations sur les disques

### Lister tous les disques physiques

Pour afficher tous les disques physiques de votre système :

```powershell
Get-Disk
```

Cette commande renvoie des informations telles que :
- Le numéro du disque
- Le statut (Online, Offline)
- La taille totale
- Le type de partition (MBR ou GPT)

Pour obtenir des informations plus détaillées sur un disque spécifique :

```powershell
Get-Disk -Number 0 | Format-List *
```

### Afficher l'espace disponible sur les volumes

Pour voir tous les volumes avec leur lettre, étiquette et espace disponible :

```powershell
Get-Volume
```

Pour filtrer uniquement les lecteurs fixes (pas les lecteurs amovibles) :

```powershell
Get-Volume | Where-Object DriveType -eq 'Fixed'
```

Pour voir les informations en mode plus lisible avec des tailles en GB :

```powershell
Get-Volume | Select-Object DriveLetter, FileSystemLabel,
    @{Name="Size(GB)"; Expression={[math]::Round($_.Size/1GB, 2)}},
    @{Name="FreeSpace(GB)"; Expression={[math]::Round($_.SizeRemaining/1GB, 2)}},
    @{Name="FreePercent"; Expression={[math]::Round($_.SizeRemaining/$_.Size*100, 2)}}
```

## 2. Gérer les partitions

### Lister les partitions existantes

Pour lister toutes les partitions sur tous les disques :

```powershell
Get-Partition
```

Pour lister les partitions d'un disque spécifique :

```powershell
Get-Partition -DiskNumber 0
```

### Créer une nouvelle partition

> ⚠️ **Attention**: Manipuler les partitions peut entraîner une perte de données. Assurez-vous de sauvegarder vos données importantes avant de continuer.

Voici comment créer une nouvelle partition qui utilise tout l'espace disponible sur un disque :

```powershell
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter
```

Pour créer une partition avec une taille spécifique (par exemple 10 Go) :

```powershell
New-Partition -DiskNumber 1 -Size 10GB -AssignDriveLetter
```

### Supprimer une partition

Pour supprimer une partition (soyez très prudent) :

```powershell
Remove-Partition -DiskNumber 1 -PartitionNumber 2 -Confirm:$false
```

> 💡 **Conseil**: Ajoutez toujours `-WhatIf` lors de vos tests pour voir ce qui serait fait sans réellement l'exécuter : `Remove-Partition -DiskNumber 1 -PartitionNumber 2 -WhatIf`

## 3. Travailler avec les volumes

Un volume est une partition qui a été formatée avec un système de fichiers comme NTFS ou FAT32.

### Formater une partition en volume

Pour formater une partition existante en NTFS :

```powershell
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel "DataDrive" -Confirm:$false
```

Ou avec plus d'options :

```powershell
Format-Volume -DriveLetter E -FileSystem NTFS -NewFileSystemLabel "DataDrive" -AllocationUnitSize 4096 -Confirm:$false
```

### Modifier l'étiquette d'un volume

Pour changer l'étiquette d'un volume existant :

```powershell
Set-Volume -DriveLetter C -NewFileSystemLabel "SystèmeWindows"
```

## 4. Workflow complet : Initialiser, partitionner et formater un nouveau disque

Voici un exemple de workflow complet pour un nouveau disque vierge :

```powershell
# 1. Initialiser le disque
Initialize-Disk -Number 1 -PartitionStyle GPT

# 2. Créer une partition avec la taille maximale
$partition = New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter

# 3. Formater la partition en volume NTFS
Format-Volume -DriveLetter $partition.DriveLetter -FileSystem NTFS -NewFileSystemLabel "DataDisk" -Confirm:$false

# 4. Afficher le résultat
Get-Volume -DriveLetter $partition.DriveLetter
```

## 5. Opérations avancées

### Redimensionner une partition

Pour étendre une partition à tout l'espace disponible :

```powershell
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size (Get-PartitionSupportedSize -DiskNumber 0 -PartitionNumber 2).SizeMax
```

Pour réduire une partition à une taille spécifique (par exemple 50 Go) :

```powershell
Resize-Partition -DiskNumber 0 -PartitionNumber 2 -Size 50GB
```

### Mettre un disque hors ligne ou en ligne

Pour mettre un disque hors ligne :

```powershell
Set-Disk -Number 1 -IsOffline $true
```

Pour remettre un disque en ligne :

```powershell
Set-Disk -Number 1 -IsOffline $false
```

### Modifier le statut en lecture seule d'un disque

Pour activer la lecture seule :

```powershell
Set-Disk -Number 1 -IsReadOnly $true
```

Pour désactiver la lecture seule :

```powershell
Set-Disk -Number 1 -IsReadOnly $false
```

## 6. Gestion de disques virtuels (VHD/VHDX)

PowerShell peut également gérer des disques virtuels :

### Créer un nouveau disque virtuel

```powershell
New-VHD -Path "C:\VirtualDisks\MyDisk.vhdx" -SizeBytes 10GB -Dynamic
```

### Monter un disque virtuel existant

```powershell
# Monter le VHD/VHDX
$vdisk = Mount-VHD -Path "C:\VirtualDisks\MyDisk.vhdx" -PassThru

# Initialiser si nécessaire (pour un nouveau VHD)
Initialize-Disk -Number $vdisk.DiskNumber -PartitionStyle GPT

# Créer une partition et formater
New-Partition -DiskNumber $vdisk.DiskNumber -UseMaximumSize -AssignDriveLetter |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "VirtualDisk" -Confirm:$false
```

### Démonter un disque virtuel

```powershell
Dismount-VHD -Path "C:\VirtualDisks\MyDisk.vhdx"
```

## 7. Cas pratiques

### Scénario 1 : Vérifier l'espace disque sur tous les volumes

```powershell
Get-Volume | Where-Object {$_.DriveLetter -ne $null} |
    Sort-Object -Property DriveLetter |
    Select-Object DriveLetter, FileSystemLabel,
        @{Name="Total(GB)"; Expression={[math]::Round($_.Size/1GB, 2)}},
        @{Name="Free(GB)"; Expression={[math]::Round($_.SizeRemaining/1GB, 2)}},
        @{Name="Free%"; Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100, 1)}} |
    Format-Table -AutoSize
```

### Scénario 2 : Créer un rapport d'espace disque

```powershell
$report = Get-Volume | Where-Object {$_.DriveLetter -ne $null -and $_.Size -gt 0} |
    Select-Object DriveLetter, FileSystemLabel,
        @{Name="TotalGB"; Expression={[math]::Round($_.Size/1GB, 2)}},
        @{Name="FreeGB"; Expression={[math]::Round($_.SizeRemaining/1GB, 2)}},
        @{Name="FreePercent"; Expression={[math]::Round(($_.SizeRemaining/$_.Size)*100, 1)}}

# Exporter en CSV
$report | Export-Csv -Path "$env:USERPROFILE\Desktop\DiskReport.csv" -NoTypeInformation

# Afficher un avertissement pour les volumes avec moins de 10% d'espace libre
$report | Where-Object {$_.FreePercent -lt 10} |
    ForEach-Object {
        Write-Warning "Le volume $($_.DriveLetter): n'a plus que $($_.FreePercent)% d'espace libre!"
    }
```

## Résumé

Dans ce module, vous avez appris à :
- Afficher les informations sur les disques, partitions et volumes
- Créer et gérer des partitions
- Formater des volumes
- Redimensionner des partitions
- Gérer des disques virtuels

Ces compétences vous permettront d'automatiser la gestion de vos ressources de stockage sans avoir à utiliser l'interface graphique de Windows.

## Exercices pratiques

1. Listez tous les disques de votre système et identifiez leur type de partition
2. Créez un rapport qui montre les volumes avec moins de 15% d'espace libre
3. Créez un disque virtuel de 5 Go, initialisez-le, créez une partition et formatez-la

> ⚠️ **Important**: Pour les exercices qui impliquent la modification des disques, utilisez toujours `-WhatIf` pour tester vos commandes avant de les exécuter réellement, ou travaillez sur des disques virtuels.

## Pour aller plus loin

- Explorez le module `Storage` qui contient toutes ces cmdlets : `Get-Command -Module Storage`
- Découvrez les cmdlets liées à iSCSI pour la gestion du stockage réseau
- Apprenez à utiliser les Storage Spaces pour créer des pools de stockage avancés
