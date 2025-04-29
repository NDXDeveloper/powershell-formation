# Solutions des exercices - Module 9-4: Interrogation du matériel

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Exercice 1 : Informations basiques

### Énoncé
Créez un script qui affiche dans la console :
- Le nom de votre processeur
- Le nombre total de coeurs physiques
- La quantité de RAM en GB
- Le modèle de carte graphique principale

### Solution

```powershell
# Script InfoSysteme.ps1
# Ce script affiche les informations basiques sur le matériel du système

# Récupération des informations du processeur
$CPU = Get-CimInstance -ClassName Win32_Processor
$NomCPU = $CPU.Name
$NombreCoeurs = $CPU.NumberOfCores

# Récupération de la quantité totale de RAM
$RAM = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
$RAMenGB = [math]::Round($RAM.Sum / 1GB, 2)

# Récupération des informations de la carte graphique principale
$GPU = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
$ModelGPU = $GPU.Name

# Affichage des informations dans la console
Write-Host "===== INFORMATIONS SYSTÈME =====" -ForegroundColor Cyan
Write-Host "Processeur     : $NomCPU" -ForegroundColor Yellow
Write-Host "Nombre de cœurs: $NombreCoeurs" -ForegroundColor Yellow
Write-Host "Mémoire RAM    : $RAMenGB GB" -ForegroundColor Yellow
Write-Host "Carte graphique: $ModelGPU" -ForegroundColor Yellow
Write-Host "===============================" -ForegroundColor Cyan
```

#### Explications :
1. Nous utilisons `Get-CimInstance` avec la classe `Win32_Processor` pour obtenir les informations du CPU
2. Pour la RAM, nous utilisons `Measure-Object` avec la propriété `Capacity` pour calculer la somme de toutes les barrettes
3. Pour la carte graphique, nous sélectionnons uniquement le premier contrôleur vidéo avec `Select-Object -First 1`
4. Nous utilisons `Write-Host` avec des couleurs pour rendre l'affichage plus lisible

## Exercice 2 : Surveillance de l'espace disque

### Énoncé
Créez un script qui vérifie si l'un de vos disques a moins de 20% d'espace libre et affiche un avertissement le cas échéant.

### Solution

```powershell
# Script SurveillanceDisque.ps1
# Ce script vérifie l'espace libre sur les disques et affiche un avertissement si nécessaire

# Définition du seuil d'alerte (20%)
$SeuilAlerte = 20

# Récupération des informations sur les disques fixes locaux
$Disques = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"

# Vérification de chaque disque
foreach ($Disque in $Disques) {
    # Calcul du pourcentage d'espace libre
    $EspaceTotal = $Disque.Size
    $EspaceLibre = $Disque.FreeSpace
    $PourcentageLibre = [math]::Round(($EspaceLibre / $EspaceTotal) * 100, 2)

    # Formatage des valeurs pour l'affichage
    $DisqueID = $Disque.DeviceID
    $EspaceTotalGB = [math]::Round($EspaceTotal / 1GB, 2)
    $EspaceLibreGB = [math]::Round($EspaceLibre / 1GB, 2)

    # Définition de la couleur en fonction du seuil
    $Couleur = "Green"
    if ($PourcentageLibre -lt $SeuilAlerte) {
        $Couleur = "Red"
    } elseif ($PourcentageLibre -lt 30) {
        $Couleur = "Yellow"
    }

    # Affichage des informations sur le disque
    Write-Host "Disque $DisqueID - $EspaceTotalGB GB total, $EspaceLibreGB GB libre ($PourcentageLibre% libre)" -ForegroundColor $Couleur

    # Affichage d'un avertissement si nécessaire
    if ($PourcentageLibre -lt $SeuilAlerte) {
        Write-Host "⚠️ ATTENTION: Le disque $DisqueID a moins de $SeuilAlerte% d'espace libre!" -ForegroundColor Red -BackgroundColor Yellow

        # Calcul de l'espace à libérer pour atteindre 25% d'espace libre
        $EspaceALiberer = ($SeuilAlerte * $EspaceTotal / 100) - $EspaceLibre
        if ($EspaceALiberer -gt 0) {
            $EspaceALibererGB = [math]::Round($EspaceALiberer / 1GB, 2)
            Write-Host "   Il est recommandé de libérer au moins $EspaceALibererGB GB d'espace sur ce disque." -ForegroundColor Red
        }
    }
}
```

#### Explications :
1. Nous définissons un seuil d'alerte à 20%
2. Nous récupérons tous les disques fixes locaux avec le filtre `DriveType=3`
3. Pour chaque disque, nous calculons le pourcentage d'espace libre
4. Nous utilisons des couleurs conditionnelles : vert (>30%), jaune (entre 20% et 30%), rouge (<20%)
5. Pour les disques sous le seuil d'alerte, nous calculons l'espace à libérer pour atteindre le seuil minimum

## Exercice 3 : Rapport personnalisé

### Énoncé
Modifiez le script de rapport système pour inclure :
- La version du BIOS
- La vitesse des barrettes de RAM
- La température du CPU (nécessite des recherches supplémentaires)

### Solution

```powershell
# Script RapportSystemeAvance.ps1
# Ce script génère un rapport système HTML avancé avec des informations supplémentaires

# Récupération des informations BIOS
$BIOS = Get-CimInstance -ClassName Win32_BIOS
$BIOSVersion = "$($BIOS.Manufacturer) - $($BIOS.Name) - $($BIOS.Version)"

# Récupération des informations sur les barrettes RAM
$BarrettesRAM = Get-CimInstance -ClassName Win32_PhysicalMemory |
    Select-Object @{Name="Emplacement";Expression={$_.DeviceLocator}},
                 @{Name="Capacité (GB)";Expression={[math]::Round($_.Capacity / 1GB, 2)}},
                 @{Name="Vitesse (MHz)";Expression={$_.Speed}},
                 @{Name="Fabricant";Expression={$_.Manufacturer}}

# Pour la température du CPU, nous allons utiliser une approche alternative car il n'existe pas de classe WMI standard
# Note: Cette méthode fonctionne sur certains systèmes, mais pas tous
$TemperatureCPU = "Non disponible"
try {
    # Tentative d'utilisation de la classe MSAcpi_ThermalZoneTemperature
    $Temperature = Get-CimInstance -Namespace "root\wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction Stop |
        Select-Object -First 1

    if ($Temperature) {
        # Conversion de la température (en dixièmes de degrés Kelvin) en Celsius
        $TempCelsius = [math]::Round(($Temperature.CurrentTemperature / 10) - 273.15, 1)
        $TemperatureCPU = "$TempCelsius °C"
    }
} catch {
    # En cas d'erreur, proposer une alternative
    $TemperatureCPU = "Non disponible (installer un logiciel de monitoring comme HWiNFO)"

    # Commentaire dans la console pour l'utilisateur exécutant le script
    Write-Host "Note: La température CPU n'a pas pu être récupérée directement via WMI." -ForegroundColor Yellow
    Write-Host "      Pour obtenir cette information, utilisez un logiciel spécialisé comme HWiNFO, Core Temp, ou Open Hardware Monitor." -ForegroundColor Yellow
}

# Création du rapport complet
$Rapport = [PSCustomObject]@{
    Ordinateur = $env:COMPUTERNAME
    Date = Get-Date -Format "dd/MM/yyyy HH:mm"
    OS = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
    BIOS = $BIOSVersion
    CPU = (Get-CimInstance -ClassName Win32_Processor).Name
    "Température CPU" = $TemperatureCPU
    Coeurs = (Get-CimInstance -ClassName Win32_Processor).NumberOfCores
    "Threads" = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
    RAM_GB = [math]::Round((Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
    "Barrettes RAM" = $BarrettesRAM | ConvertTo-Html -Fragment
    Disques = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID,
        @{Name="Taille(GB)";Expression={[math]::Round($_.Size / 1GB, 2)}},
        @{Name="EspaceLibre(GB)";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
        @{Name="% Libre";Expression={[math]::Round(($_.FreeSpace / $_.Size) * 100, 2)}} |
        ConvertTo-Html -Fragment
    GPU = (Get-CimInstance -ClassName Win32_VideoController).Name
}

# Création du CSS pour améliorer l'apparence du rapport
$CSS = @"
<style>
body { font-family: Arial, sans-serif; margin: 20px; background-color: #f4f4f4; }
h1 { color: #0066cc; border-bottom: 2px solid #0066cc; padding-bottom: 5px; }
table { border-collapse: collapse; width: 100%; margin-top: 20px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
th { background-color: #0066cc; color: white; padding: 10px; text-align: left; }
td { padding: 8px; border-bottom: 1px solid #ddd; }
tr:nth-child(even) { background-color: #f2f2f2; }
tr:hover { background-color: #e9f1fd; }
.section { background-color: white; padding: 15px; margin-bottom: 20px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
</style>
"@

# Création du HTML avec des sections
$HTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport Système Avancé - $($env:COMPUTERNAME)</title>
    $CSS
</head>
<body>
    <h1>Rapport Système Avancé - $($env:COMPUTERNAME)</h1>
    <div class="section">
        <h2>Informations Générales</h2>
        <p><strong>Date du rapport:</strong> $($Rapport.Date)</p>
        <p><strong>Nom de l'ordinateur:</strong> $($Rapport.Ordinateur)</p>
        <p><strong>Système d'exploitation:</strong> $($Rapport.OS)</p>
        <p><strong>Version du BIOS:</strong> $($Rapport.BIOS)</p>
    </div>

    <div class="section">
        <h2>Processeur</h2>
        <p><strong>Modèle:</strong> $($Rapport.CPU)</p>
        <p><strong>Nombre de cœurs:</strong> $($Rapport.Coeurs)</p>
        <p><strong>Nombre de threads:</strong> $($Rapport.Threads)</p>
        <p><strong>Température:</strong> $($Rapport.'Température CPU')</p>
    </div>

    <div class="section">
        <h2>Mémoire RAM</h2>
        <p><strong>Capacité totale:</strong> $($Rapport.RAM_GB) GB</p>
        <h3>Détails des barrettes</h3>
        $($Rapport.'Barrettes RAM')
    </div>

    <div class="section">
        <h2>Stockage</h2>
        $($Rapport.Disques)
    </div>

    <div class="section">
        <h2>Carte Graphique</h2>
        <p><strong>Modèle:</strong> $($Rapport.GPU)</p>
    </div>

    <div class="section">
        <h2>Notes</h2>
        <p>Ce rapport a été généré automatiquement avec PowerShell.</p>
        <p>Pour toute assistance, contactez votre service informatique.</p>
    </div>
</body>
</html>
"@

# Exportation du rapport en HTML
$HTML | Out-File "RapportSystemeAvance.html"

# Ouverture du rapport dans le navigateur par défaut
Invoke-Item "RapportSystemeAvance.html"

Write-Host "Rapport système avancé généré avec succès!" -ForegroundColor Green
Write-Host "Le fichier a été enregistré sous: $((Get-Item "RapportSystemeAvance.html").FullName)" -ForegroundColor Cyan
```

#### Explications :
1. Nous avons ajouté la récupération des informations BIOS complètes
2. Pour les barrettes RAM, nous créons un tableau HTML détaillé avec leur emplacement, capacité et vitesse
3. Pour la température CPU, nous utilisons une approche qui tente d'abord d'utiliser la classe WMI `MSAcpi_ThermalZoneTemperature`
4. En cas d'échec de la récupération de la température, nous informons l'utilisateur des alternatives
5. Nous avons amélioré la présentation du rapport HTML en ajoutant du CSS et en organisant les informations en sections
6. Nous ajoutons un message de confirmation dans la console après la génération du rapport

### Note sur la température CPU

La récupération de la température du CPU via PowerShell est complexe car:
1. Il n'existe pas de classe WMI standard prise en charge sur tous les systèmes
2. Les méthodes varient selon les fabricants de matériel
3. Certains systèmes nécessitent des pilotes spécifiques ou des logiciels tiers

Pour une solution fiable sur tous les systèmes, il est recommandé d'utiliser:
- Des logiciels comme HWiNFO, Core Temp, Open Hardware Monitor
- Des modules PowerShell spécifiques comme "PowerShellCooking"
- L'intégration avec des outils comme "OpenHardwareMonitorLib"

## Bonus: Script d'inventaire matériel pour plusieurs ordinateurs

```powershell
# Script InventaireParc.ps1
# Ce script génère un inventaire matériel pour plusieurs ordinateurs et l'exporte en CSV

param (
    [string[]]$Ordinateurs = $env:COMPUTERNAME,
    [string]$CheminExport = ".\InventaireParc.csv"
)

# Création d'un tableau pour stocker les résultats
$Resultats = @()

foreach ($Ordinateur in $Ordinateurs) {
    Write-Host "Récupération des informations pour $Ordinateur..." -ForegroundColor Cyan

    try {
        # Test de connectivité avant de continuer
        if (Test-Connection -ComputerName $Ordinateur -Count 1 -Quiet) {
            # Récupération des informations système
            $OS = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Ordinateur -ErrorAction Stop
            $CPU = Get-CimInstance -ClassName Win32_Processor -ComputerName $Ordinateur -ErrorAction Stop
            $RAM = Get-CimInstance -ClassName Win32_PhysicalMemory -ComputerName $Ordinateur -ErrorAction Stop |
                   Measure-Object -Property Capacity -Sum
            $Disques = Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $Ordinateur -Filter "DriveType=3" -ErrorAction Stop
            $GPU = Get-CimInstance -ClassName Win32_VideoController -ComputerName $Ordinateur -ErrorAction Stop
            $BIOS = Get-CimInstance -ClassName Win32_BIOS -ComputerName $Ordinateur -ErrorAction Stop
            $Systeme = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $Ordinateur -ErrorAction Stop

            # Calcul de l'espace disque total
            $EspaceTotal = ($Disques | Measure-Object -Property Size -Sum).Sum / 1GB

            # Construction de l'objet résultat
            $Details = [PSCustomObject]@{
                Ordinateur = $Ordinateur
                Modele = $Systeme.Model
                Fabricant = $Systeme.Manufacturer
                OS = $OS.Caption
                Version = $OS.Version
                ServicePack = $OS.ServicePackMajorVersion
                ProcesseurModele = $CPU.Name
                Coeurs = $CPU.NumberOfCores
                ThreadsLogiques = $CPU.NumberOfLogicalProcessors
                RAM_GB = [math]::Round($RAM.Sum / 1GB, 2)
                Disques_GB = [math]::Round($EspaceTotal, 2)
                GPU = ($GPU | Select-Object -First 1).Name
                NumeroSerie = $BIOS.SerialNumber
                DateInstallation = $OS.InstallDate
                DernierRedemarrage = $OS.LastBootUpTime
            }

            # Ajout au tableau de résultats
            $Resultats += $Details

            Write-Host "  ✅ Terminé avec succès." -ForegroundColor Green
        } else {
            Write-Host "  ❌ Impossible de contacter l'ordinateur $Ordinateur." -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Erreur lors de la récupération des informations pour $Ordinateur : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Exportation des résultats en CSV
if ($Resultats.Count -gt 0) {
    $Resultats | Export-Csv -Path $CheminExport -NoTypeInformation -Encoding UTF8
    Write-Host "`nInventaire exporté avec succès vers : $CheminExport" -ForegroundColor Green
    Write-Host "Nombre d'ordinateurs analysés : $($Resultats.Count)"
} else {
    Write-Host "`nAucun résultat à exporter." -ForegroundColor Yellow
}
```

#### Utilisation du script bonus:
- Pour l'ordinateur local seulement: `.\InventaireParc.ps1`
- Pour des ordinateurs spécifiques: `.\InventaireParc.ps1 -Ordinateurs "PC1", "PC2", "SRV1" -CheminExport "C:\Rapports\Inventaire.csv"`
- Pour une liste d'ordinateurs depuis un fichier: `.\InventaireParc.ps1 -Ordinateurs (Get-Content .\listePC.txt)`
