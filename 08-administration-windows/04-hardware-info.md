# Module 9-4. Interrogation du matériel (RAM, CPU, etc.)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

L'un des grands avantages de PowerShell est sa capacité à récupérer des informations détaillées sur le matériel de votre ordinateur. Ces informations peuvent être précieuses pour le dépannage, la surveillance des performances ou simplement pour connaître les spécifications de votre système.

Dans cette section, nous allons découvrir comment interroger différents composants matériels à l'aide de PowerShell.

## Prérequis

- Connaissances de base en PowerShell (variables, pipeline)
- Droits d'administrateur (certaines commandes peuvent nécessiter des privilèges élevés)

## Table des matières

1. Vue d'ensemble des outils disponibles
2. Informations sur le processeur (CPU)
3. Informations sur la mémoire (RAM)
4. Informations sur les disques
5. Informations sur la carte graphique
6. Informations sur la carte mère et le BIOS
7. Création d'un rapport système complet
8. Exercices pratiques

## 1. Vue d'ensemble des outils disponibles

PowerShell dispose de plusieurs approches pour récupérer des informations matérielles :

### 1.1. Get-CimInstance (recommandé)

`Get-CimInstance` est la méthode moderne recommandée pour interroger les informations matérielles :

```powershell
# Syntaxe de base
Get-CimInstance -ClassName <nom_de_classe> [-ComputerName <nom_ordinateur>]
```

> 💡 **Conseil pour débutants** : `Get-CimInstance` remplace l'ancienne commande `Get-WmiObject` qui est dépréciée dans PowerShell 7+.

### 1.2. Get-ComputerInfo (rapide et facile)

Cette commande simple fournit une vue d'ensemble des informations système :

```powershell
Get-ComputerInfo
```

### 1.3. Instructions basées sur .NET

Pour certaines informations spécifiques, nous pouvons utiliser des classes .NET directement :

```powershell
[System.Environment]::ProcessorCount
```

## 2. Informations sur le processeur (CPU)

### 2.1. Informations de base sur le CPU

```powershell
Get-CimInstance -ClassName Win32_Processor
```

Cette commande affiche des informations complètes sur le processeur. Pour un affichage plus concis :

```powershell
Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, L2CacheSize, L3CacheSize
```

### 2.2. Charge CPU en temps réel

Pour connaître l'utilisation actuelle du CPU :

```powershell
Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_Processor -Filter "Name='_Total'" | Select-Object PercentProcessorTime
```

> 🔍 **Explication** : Cette commande affiche le pourcentage d'utilisation global du processeur.

## 3. Informations sur la mémoire (RAM)

### 3.1. Capacité totale de RAM

```powershell
Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | ForEach-Object { "RAM Totale: {0:N2} GB" -f ($_.Sum / 1GB) }
```

### 3.2. Informations détaillées sur les barrettes de RAM

```powershell
Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Tag, Capacity, Speed, Manufacturer | Format-Table -AutoSize
```

### 3.3. Utilisation de la mémoire

```powershell
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object @{Name="MémoireTotale(GB)";Expression={[math]::Round($_.TotalVisibleMemorySize / 1MB, 2)}}, @{Name="MémoireLibre(GB)";Expression={[math]::Round($_.FreePhysicalMemory / 1MB, 2)}}
```

## 4. Informations sur les disques

### 4.1. Disques physiques

```powershell
Get-CimInstance -ClassName Win32_DiskDrive | Select-Object Model, Size, MediaType | Format-Table -AutoSize
```

### 4.2. Volumes et partitions

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{Name="Taille(GB)";Expression={[math]::Round($_.Size / 1GB, 2)}}, @{Name="EspaceLibre(GB)";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}, @{Name="% Libre";Expression={[math]::Round(($_.FreeSpace / $_.Size) * 100, 2)}}
```

> ⚠️ **Attention** : Le filtre `DriveType=3` permet de n'afficher que les disques fixes locaux.

## 5. Informations sur la carte graphique

```powershell
Get-CimInstance -ClassName Win32_VideoController | Select-Object Name, CurrentHorizontalResolution, CurrentVerticalResolution, AdapterRAM, DriverVersion
```

Pour afficher la mémoire vidéo en GB au lieu d'octets :

```powershell
Get-CimInstance -ClassName Win32_VideoController | Select-Object Name, @{Name="VRAM (GB)";Expression={[math]::Round($_.AdapterRAM / 1GB, 2)}}, DriverVersion
```

## 6. Informations sur la carte mère et le BIOS

### 6.1. Informations sur la carte mère

```powershell
Get-CimInstance -ClassName Win32_BaseBoard | Select-Object Manufacturer, Product, SerialNumber
```

### 6.2. Informations sur le BIOS

```powershell
Get-CimInstance -ClassName Win32_BIOS | Select-Object Manufacturer, Name, Version, SerialNumber
```

## 7. Création d'un rapport système complet

Voici un script simple qui génère un rapport HTML des informations principales du système :

```powershell
# Création d'un rapport système complet
$Rapport = [PSCustomObject]@{
    Ordinateur = $env:COMPUTERNAME
    Date = Get-Date -Format "dd/MM/yyyy HH:mm"
    OS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    CPU = (Get-CimInstance -ClassName Win32_Processor).Name
    Coeurs = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
    RAM_GB = [math]::Round((Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    Disques = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{Name="Taille(GB)";Expression={[math]::Round($_.Size / 1GB, 2)}}, @{Name="EspaceLibre(GB)";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}
    GPU = (Get-CimInstance -ClassName Win32_VideoController).Name
}

# Exporter en HTML
$Rapport | ConvertTo-Html -Title "Rapport Système" -Body "<h1>Rapport Système - $($env:COMPUTERNAME)</h1>" | Out-File RapportSysteme.html

# Ouvrir le rapport dans le navigateur par défaut
Invoke-Item RapportSysteme.html
```

> 💡 **Astuce** : Ce script génère un fichier HTML et l'ouvre automatiquement dans votre navigateur.

## 8. Exercices pratiques

### Exercice 1 : Informations basiques

Créez un script qui affiche dans la console :
- Le nom de votre processeur
- Le nombre total de coeurs physiques
- La quantité de RAM en GB
- Le modèle de carte graphique principale

### Exercice 2 : Surveillance de l'espace disque

Créez un script qui vérifie si l'un de vos disques a moins de 20% d'espace libre et affiche un avertissement le cas échéant.

### Exercice 3 : Rapport personnalisé

Modifiez le script de rapport système pour inclure :
- La version du BIOS
- La vitesse des barrettes de RAM
- La température du CPU (nécessite des recherches supplémentaires)

## Conseils pour aller plus loin

1. Explorez toutes les classes WMI disponibles avec cette commande :
   ```powershell
   Get-CimClass -Namespace "root\cimv2" | Where-Object CimClassName -like "Win32_*" | Select-Object CimClassName
   ```

2. Pour un système de surveillance plus avancé, envisagez d'utiliser les compteurs de performance :
   ```powershell
   Get-Counter -ListSet * | Where-Object CounterSetName -like "*processor*"
   ```

3. Documentez-vous sur les outils de diagnostic comme `Get-Diagnostics` (disponible dans PowerShell 7.3+)

## Conclusion

L'interrogation du matériel avec PowerShell vous offre un moyen puissant de collecter des informations détaillées sur votre système. Ces informations sont essentielles pour le diagnostic des problèmes, la surveillance des performances ou simplement pour mieux comprendre la configuration de votre ordinateur.

La maîtrise de ces commandes vous permettra de créer des scripts d'audit, des outils de surveillance ou des rapports personnalisés adaptés à vos besoins spécifiques.

---

⭐ **Pour les plus curieux** : Les commandes présentées dans ce module fonctionnent principalement sous Windows. Si vous utilisez PowerShell sur Linux ou macOS, certaines classes WMI ne seront pas disponibles, mais vous pourrez utiliser d'autres commandes système pour obtenir des informations similaires.
