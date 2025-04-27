Voici les solutions détaillées pour les exercices pratiques du tutoriel sur WMI vs CIM :

## Solutions des exercices pratiques

### 1. Exercice débutant : Afficher les informations de base du système

Pour obtenir les informations de base sur votre système (OS, modèle, fabricant, RAM totale), voici la solution étape par étape :

```powershell
# Obtenir les informations sur le matériel (fabricant, modèle et RAM)
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory

# Obtenir les informations sur le système d'exploitation
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber
```

Cette solution utilise deux requêtes distinctes :
- La première utilise la classe `Win32_ComputerSystem` qui contient les informations matérielles
- La seconde utilise la classe `Win32_OperatingSystem` pour les détails du système d'exploitation

Pour améliorer l'affichage de la RAM, vous pourriez modifier la commande pour convertir la valeur en gigaoctets :

```powershell
Get-CimInstance -ClassName Win32_ComputerSystem |
    Select-Object Manufacturer,
                 Model,
                 @{Name="RAM (GB)"; Expression={[math]::Round($_.TotalPhysicalMemory/1GB, 2)}}
```

### 2. Exercice intermédiaire : Rapport des disques avec pourcentage d'espace libre

Pour créer un rapport des disques durs avec leur espace libre en pourcentage :

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
                 @{Name="Size (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}},
                 @{Name="FreeSpace (GB)"; Expression={[math]::Round($_.FreeSpace/1GB, 2)}},
                 @{Name="Free (%)"; Expression={[math]::Round(($_.FreeSpace/$_.Size)*100, 2)}}
```

Explications :
- Le filtre `DriveType=3` limite les résultats aux disques durs fixes uniquement (exclut les lecteurs CD/DVD, réseau, etc.)
- Les calculs sont effectués avec l'objet `[math]` pour formater les valeurs :
  - Division par `1GB` pour convertir les octets en gigaoctets
  - Utilisation de `[math]::Round()` pour limiter à 2 décimales
  - Calcul du pourcentage avec `($_.FreeSpace/$_.Size)*100`

Pour exporter ce rapport dans un fichier CSV, vous pourriez ajouter :

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
                 @{Name="Size (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}},
                 @{Name="FreeSpace (GB)"; Expression={[math]::Round($_.FreeSpace/1GB, 2)}},
                 @{Name="Free (%)"; Expression={[math]::Round(($_.FreeSpace/$_.Size)*100, 2)}} |
    Export-Csv -Path "C:\Rapports\EspaceDisque.csv" -NoTypeInformation
```

### 3. Exercice avancé : Services arrêtés configurés en démarrage automatique

Pour lister tous les services arrêtés qui sont configurés en démarrage automatique :

```powershell
Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto' AND State<>'Running'" |
    Select-Object Name, DisplayName, State, StartMode
```

Explications :
- Cette commande utilise un filtre CIM combiné avec deux conditions :
  - `StartMode='Auto'` : ne sélectionne que les services configurés en démarrage automatique
  - `State<>'Running'` : exclut les services en cours d'exécution
- Le résultat affiche uniquement les services qui devraient démarrer automatiquement mais qui ne sont pas en cours d'exécution

Pour étendre cette solution, vous pourriez également démarrer ces services :

```powershell
# D'abord, identifions les services concernés
$servicesArretes = Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto' AND State<>'Running'"

# Afficher les services qui vont être démarrés
$servicesArretes | Select-Object Name, DisplayName, State, StartMode

# Démarrer chaque service
foreach ($service in $servicesArretes) {
    Write-Host "Démarrage du service $($service.Name)..." -ForegroundColor Yellow
    Invoke-CimMethod -InputObject $service -MethodName StartService
    # Vérifier le nouvel état
    $serviceApres = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($service.Name)'"
    Write-Host "État du service après tentative de démarrage : $($serviceApres.State)" -ForegroundColor Cyan
}
```

Cette solution avancée :
1. Identifie d'abord les services arrêtés configurés en démarrage automatique
2. Les affiche pour information
3. Tente de démarrer chaque service un par un
4. Vérifie et affiche le nouvel état après la tentative de démarrage

Ces solutions démontrent la puissance de CIM pour interroger et gérer les ressources système de manière efficace.
