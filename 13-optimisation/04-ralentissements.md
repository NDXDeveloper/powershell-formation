# 14-4. Éviter les ralentissements courants

## Introduction

Même avec PowerShell, un outil puissant pour l'automatisation, certaines pratiques peuvent entraîner des ralentissements significatifs dans vos scripts. Dans cette section, nous explorerons les causes les plus fréquentes de lenteur et comment les éviter.

## Les ralentissements courants en PowerShell

### 1. Manipulation inefficace de chaînes de caractères

```powershell
# ❌ À ÉVITER - Concaténation de chaînes dans une boucle
$result = ""
foreach ($item in 1..1000) {
    $result += "$item, "  # Crée une nouvelle chaîne à chaque itération
}
```

```powershell
# ✅ RECOMMANDÉ - Utiliser un tableau puis joindre à la fin
$items = foreach ($item in 1..1000) {
    "$item"
}
$result = $items -join ", "  # Une seule opération de jointure
```

### 2. Requêtes multiples vers des ressources externes

```powershell
# ❌ À ÉVITER - Requêtes répétées au système de fichiers
foreach ($file in $fileNames) {
    if (Test-Path $file) {  # Chaque appel est coûteux
        # Traitement du fichier
    }
}
```

```powershell
# ✅ RECOMMANDÉ - Requête unique puis filtrage en mémoire
$existingFiles = Get-ChildItem -Path $directoryPath -File |
                 Select-Object -ExpandProperty FullName
foreach ($file in $fileNames) {
    if ($existingFiles -contains $file) {
        # Traitement du fichier
    }
}
```

### 3. Appels excessifs à WMI/CIM

```powershell
# ❌ À ÉVITER - Appels WMI/CIM répétés
foreach ($computerName in $computers) {
    Get-CimInstance -ComputerName $computerName -ClassName Win32_LogicalDisk  # Connexion à chaque fois
    Get-CimInstance -ComputerName $computerName -ClassName Win32_ComputerSystem
    Get-CimInstance -ComputerName $computerName -ClassName Win32_OperatingSystem
}
```

```powershell
# ✅ RECOMMANDÉ - Réutiliser la session CIM
foreach ($computerName in $computers) {
    $session = New-CimSession -ComputerName $computerName

    Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk
    Get-CimInstance -CimSession $session -ClassName Win32_ComputerSystem
    Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem

    Remove-CimSession -CimSession $session
}
```

### 4. Absence de filtrage au niveau de la source

```powershell
# ❌ À ÉVITER - Récupérer toutes les données puis filtrer localement
$allProcesses = Get-Process
$chromeProcesses = $allProcesses | Where-Object { $_.Name -eq "chrome" }
```

```powershell
# ✅ RECOMMANDÉ - Filtrer directement à la source
$chromeProcesses = Get-Process -Name "chrome"
```

### 5. Import de modules inutiles ou trop lourds

```powershell
# ❌ À ÉVITER - Importer des modules complets pour une seule commande
Import-Module ActiveDirectory  # Module très lourd
Get-ADUser -Identity "utilisateur1"
```

```powershell
# ✅ RECOMMANDÉ - Importer uniquement ce dont vous avez besoin
Import-Module ActiveDirectory -CommandName Get-ADUser
Get-ADUser -Identity "utilisateur1"
```

### 6. Collecte excessive de données

```powershell
# ❌ À ÉVITER - Récupérer trop de propriétés
$users = Get-ADUser -Filter * | Select-Object *  # Récupère TOUTES les propriétés
```

```powershell
# ✅ RECOMMANDÉ - Limiter aux propriétés nécessaires
$users = Get-ADUser -Filter * -Properties DisplayName, EmailAddress |
         Select-Object DisplayName, EmailAddress
```

### 7. Utilisation excessive du disque

```powershell
# ❌ À ÉVITER - Écriture sur disque à chaque itération
foreach ($item in 1..1000) {
    Add-Content -Path "log.txt" -Value "Item: $item"  # Ouvre/ferme le fichier à chaque fois
}
```

```powershell
# ✅ RECOMMANDÉ - Accumuler puis écrire en une fois
$content = foreach ($item in 1..1000) {
    "Item: $item"
}
$content | Set-Content -Path "log.txt"  # Une seule opération d'écriture
```

### 8. Manipulation inefficace d'objets

```powershell
# ❌ À ÉVITER - Créer des objets avec Add-Member pour chaque propriété
$obj = New-Object -TypeName PSObject
Add-Member -InputObject $obj -MemberType NoteProperty -Name "Prop1" -Value "Val1"
Add-Member -InputObject $obj -MemberType NoteProperty -Name "Prop2" -Value "Val2"
```

```powershell
# ✅ RECOMMANDÉ - Utiliser [PSCustomObject] avec un hash table
$obj = [PSCustomObject]@{
    Prop1 = "Val1"
    Prop2 = "Val2"
}
```

## Bonnes pratiques pour améliorer les performances

1. **Mesurer avant d'optimiser** : Utilisez `Measure-Command` pour identifier les sections lentes
2. **Préférer les méthodes natives** : Les méthodes .NET sont souvent plus rapides que leurs équivalents PowerShell
3. **Limiter la portée** : Ne récupérez que les données dont vous avez besoin
4. **Réutiliser les connexions** : Pour WMI/CIM, Active Directory, bases de données
5. **Utiliser le pipeline avec parcimonie** : Le pipeline est pratique mais peut être plus lent pour certaines opérations
6. **Précharger les données** : Mettez en cache les résultats des requêtes coûteuses
7. **Augmenter la mémoire disponible** pour les scripts traitant de grands volumes de données

## Exemple pratique : Optimisation d'un script d'inventaire

```powershell
# Version originale lente
function Get-SlowInventory {
    $computers = Get-Content -Path "computers.txt"
    $results = @()

    foreach ($computer in $computers) {
        $disks = Get-CimInstance -ComputerName $computer -ClassName Win32_LogicalDisk
        $os = Get-CimInstance -ComputerName $computer -ClassName Win32_OperatingSystem

        foreach ($disk in $disks) {
            $obj = New-Object -TypeName PSObject
            Add-Member -InputObject $obj -MemberType NoteProperty -Name "ComputerName" -Value $computer
            Add-Member -InputObject $obj -MemberType NoteProperty -Name "OS" -Value $os.Caption
            Add-Member -InputObject $obj -MemberType NoteProperty -Name "DriveLetter" -Value $disk.DeviceID
            Add-Member -InputObject $obj -MemberType NoteProperty -Name "FreeSpace" -Value $disk.FreeSpace
            $results += $obj  # ❌ Inefficace, recrée le tableau à chaque itération
        }

        Add-Content -Path "inventory.csv" -Value ($obj | ConvertTo-Csv -NoTypeInformation)  # ❌ Écrit dans le fichier à chaque ordinateur
    }

    return $results
}

# Version optimisée
function Get-FastInventory {
    $computers = Get-Content -Path "computers.txt"
    $results = [System.Collections.ArrayList]::new()  # Plus efficace pour les ajouts

    foreach ($computer in $computers) {
        try {
            $session = New-CimSession -ComputerName $computer -ErrorAction Stop

            # Récupérer toutes les données en une fois par ordinateur
            $disks = Get-CimInstance -CimSession $session -ClassName Win32_LogicalDisk
            $os = Get-CimInstance -CimSession $session -ClassName Win32_OperatingSystem

            foreach ($disk in $disks) {
                # Création d'objet plus efficace
                $obj = [PSCustomObject]@{
                    ComputerName = $computer
                    OS = $os.Caption
                    DriveLetter = $disk.DeviceID
                    FreeSpace = $disk.FreeSpace
                }
                [void]$results.Add($obj)  # [void] évite l'affichage de l'index retourné
            }

            Remove-CimSession -CimSession $session
        }
        catch {
            Write-Warning "Échec pour l'ordinateur $computer : $_"
        }
    }

    # Exportation en une seule opération
    $results | Export-Csv -Path "inventory.csv" -NoTypeInformation

    return $results
}
```

## À retenir

- Mesurez toujours les performances avant et après optimisation
- Concentrez-vous sur les opérations coûteuses : disque, réseau, mémoire
- Préférez les opérations en bloc aux opérations individuelles répétitives
- Réutilisez les connexions et sessions quand c'est possible
- Filtrez à la source plutôt qu'après récupération

## Exercice pratique

Identifiez les problèmes de performance dans ce script et proposez des optimisations :

```powershell
$logs = @()
foreach ($server in $servers) {
    $eventLogs = Get-EventLog -LogName System -EntryType Error -Newest 100 -ComputerName $server
    foreach ($log in $eventLogs) {
        $logInfo = "" | Select-Object Server, TimeGenerated, Message
        $logInfo.Server = $server
        $logInfo.TimeGenerated = $log.TimeGenerated
        $logInfo.Message = $log.Message
        $logs += $logInfo
        Add-Content -Path "C:\logs\errors.txt" -Value "$server - $($log.TimeGenerated) - $($log.Message)"
    }
}
```

---

Dans le prochain chapitre, nous verrons comment optimiser le chargement de modules pour améliorer encore les performances de vos scripts PowerShell.
