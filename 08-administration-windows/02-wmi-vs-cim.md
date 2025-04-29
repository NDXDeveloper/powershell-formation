# 9-2. WMI vs CIM (`Get-CimInstance`, `Invoke-CimMethod`)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

Dans cette section, nous allons explorer deux technologies essentielles pour l'administration système sous Windows : WMI (Windows Management Instrumentation) et CIM (Common Information Model). Ces outils vous permettent d'obtenir des informations détaillées sur votre système et d'effectuer des opérations d'administration à distance.

## Qu'est-ce que WMI et CIM ?

### WMI (Windows Management Instrumentation)
- **Définition** : Une infrastructure de gestion intégrée à Windows qui donne accès aux informations et aux opérations concernant les ressources d'un système local ou distant.
- **Utilité** : Permet aux administrateurs d'accéder aux données sur la configuration du système, les performances, les applications installées, etc.

### CIM (Common Information Model)
- **Définition** : Un standard ouvert qui définit comment représenter les ressources informatiques gérées.
- **Relation avec WMI** : WMI est l'implémentation Microsoft de CIM. On peut considérer CIM comme le modèle et WMI comme l'implémentation Windows de ce modèle.

## Évolution : De WMI à CIM dans PowerShell

### Dans PowerShell version 1 et 2
- Utilisation des cmdlets `Get-WmiObject`, `Invoke-WmiMethod`, etc.
- Ces cmdlets utilisent le protocole DCOM (Distributed COM) pour communiquer.

### À partir de PowerShell version 3.0
- Introduction des cmdlets CIM : `Get-CimInstance`, `Invoke-CimMethod`, etc.
- Ces cmdlets utilisent le protocole WS-MAN (Web Services for Management), plus moderne et compatible avec les pare-feu.

## Pourquoi préférer CIM à WMI ?

1. **Meilleure performance** : Les cmdlets CIM sont généralement plus rapides.
2. **Compatibilité cross-platform** : CIM fonctionne avec PowerShell Core (7+) sur Windows, Linux et macOS.
3. **Sessions persistantes** : Possibilité de créer des sessions CIM pour réutiliser les connexions.
4. **Protocole moderne** : WS-MAN est plus sécurisé et traverse mieux les pare-feu que DCOM.
5. **Standardisation** : CIM est un standard ouvert adopté par l'industrie.

> ⚠️ **Note importante** : Les cmdlets WMI (`Get-WmiObject`, etc.) sont considérées comme obsolètes à partir de PowerShell 6.0 et ont été supprimées de PowerShell 7+.

## Syntaxe comparative : WMI vs CIM

### Obtenir des informations sur le processeur

**Ancienne méthode (WMI)**:
```powershell
Get-WmiObject -Class Win32_Processor
```

**Nouvelle méthode (CIM)**:
```powershell
Get-CimInstance -ClassName Win32_Processor
```

### Obtenir des informations sur le système d'exploitation

**Ancienne méthode (WMI)**:
```powershell
Get-WmiObject -Class Win32_OperatingSystem
```

**Nouvelle méthode (CIM)**:
```powershell
Get-CimInstance -ClassName Win32_OperatingSystem
```

## Utilisation de `Get-CimInstance`

La cmdlet `Get-CimInstance` est l'équivalent moderne de `Get-WmiObject`. Elle vous permet d'interroger les ressources du système.

### Syntaxe de base
```powershell
Get-CimInstance -ClassName <nom_de_la_classe> [-ComputerName <nom_ordinateur>]
```

### Exemples courants

1. **Obtenir des informations sur la mémoire physique**:
```powershell
Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object Capacity, DeviceLocator, Speed
```

2. **Lister les disques logiques**:
```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, Size, FreeSpace
```

3. **Obtenir la liste des services et leur état**:
```powershell
Get-CimInstance -ClassName Win32_Service | Select-Object Name, DisplayName, State, StartMode
```

4. **Trouver les programmes installés**:
```powershell
Get-CimInstance -ClassName Win32_Product | Select-Object Name, Version, Vendor
```

> 💡 **Astuce** : Le paramètre `-Filter` vous permet de filtrer les résultats directement au niveau WMI/CIM, ce qui est plus efficace que d'utiliser `Where-Object` après coup.

## Utilisation de `Invoke-CimMethod`

La cmdlet `Invoke-CimMethod` permet d'invoquer des méthodes sur les objets CIM, vous permettant ainsi d'effectuer des actions sur le système.

### Syntaxe de base
```powershell
Invoke-CimMethod -ClassName <nom_de_la_classe> -MethodName <nom_de_la_méthode> [-Arguments <hashtable_d_arguments>]
```

### Exemples courants

1. **Redémarrer un ordinateur distant**:
```powershell
Invoke-CimMethod -ClassName Win32_OperatingSystem -ComputerName "PC-DISTANT" -MethodName Reboot
```

2. **Démarrer un service**:
```powershell
$service = Get-CimInstance -ClassName Win32_Service -Filter "Name='Spooler'"
Invoke-CimMethod -InputObject $service -MethodName StartService
```

## Sessions CIM : une amélioration majeure

Un avantage considérable des cmdlets CIM est la possibilité de créer des sessions persistantes, particulièrement utiles pour exécuter plusieurs commandes sur un même ordinateur distant.

### Création et utilisation d'une session CIM

```powershell
# Créer une session CIM
$session = New-CimSession -ComputerName "PC-DISTANT"

# Utiliser la session pour plusieurs opérations
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $session
Get-CimInstance -ClassName Win32_LogicalDisk -CimSession $session
Get-CimInstance -ClassName Win32_Process -CimSession $session

# Fermer la session quand vous avez terminé
Remove-CimSession -CimSession $session
```

### Avantages des sessions CIM
- Établissement d'une seule connexion pour plusieurs opérations
- Économie de ressources réseau
- Performances améliorées pour les opérations répétées

## Classes WMI/CIM utiles à connaître

| Classe | Description | Exemple d'utilisation |
|--------|-------------|------------------------|
| Win32_OperatingSystem | Informations sur le système d'exploitation | Version, date d'installation, dernière mise à jour |
| Win32_ComputerSystem | Informations sur l'ordinateur | Fabricant, modèle, mémoire totale |
| Win32_Process | Processus en cours d'exécution | Liste des processus, consommation mémoire |
| Win32_Service | Services Windows | État des services, démarrage/arrêt |
| Win32_LogicalDisk | Disques logiques | Espace disque, système de fichiers |
| Win32_NetworkAdapter | Adaptateurs réseau | Configurations réseau, adresses MAC |
| Win32_Printer | Imprimantes | État, file d'attente d'impression |
| Win32_Product | Applications installées | Liste des logiciels installés |

## Comment découvrir les classes WMI/CIM disponibles ?

Pour explorer les classes disponibles, vous pouvez utiliser la cmdlet `Get-CimClass` :

```powershell
# Lister toutes les classes commençant par "Win32_"
Get-CimClass -ClassName Win32_* | Select-Object CimClassName

# Rechercher des classes liées au réseau
Get-CimClass -ClassName *Network* | Select-Object CimClassName
```

## Compatibilité avec les systèmes anciens

Si vous devez travailler avec des systèmes qui ne prennent pas en charge WS-MAN (comme Windows XP), vous pouvez utiliser un "DCOM Session Option" :

```powershell
$options = New-CimSessionOption -Protocol Dcom
$session = New-CimSession -ComputerName "PC-Ancien" -SessionOption $options
Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $session
```

## Exercices pratiques

1. **Débutant** : Affichez les informations de base de votre système (OS, modèle, fabricant, RAM totale).
```powershell
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object Manufacturer, Model, TotalPhysicalMemory
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version, BuildNumber
```

2. **Intermédiaire** : Créez un rapport des disques durs avec leur espace libre en pourcentage.
```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
                 @{Name="Size (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}},
                 @{Name="FreeSpace (GB)"; Expression={[math]::Round($_.FreeSpace/1GB, 2)}},
                 @{Name="Free (%)"; Expression={[math]::Round(($_.FreeSpace/$_.Size)*100, 2)}}
```

3. **Avancé** : Listez tous les services arrêtés qui sont configurés en démarrage automatique.
```powershell
Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto' AND State<>'Running'" |
    Select-Object Name, DisplayName, State, StartMode
```

## Conclusion

L'utilisation des cmdlets CIM (`Get-CimInstance`, `Invoke-CimMethod`) représente la façon moderne et recommandée d'interagir avec les ressources système dans PowerShell. Ces cmdlets offrent de meilleures performances, une compatibilité multiplateforme et des fonctionnalités avancées comme les sessions persistantes.

Pour les administrateurs système, maîtriser ces outils est essentiel car ils permettent d'obtenir des informations détaillées sur le système et d'effectuer des tâches d'administration à distance de manière efficace.

---

## Ressources supplémentaires

- Documentation Microsoft sur [Get-CimInstance](https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance)
- Documentation Microsoft sur [Invoke-CimMethod](https://docs.microsoft.com/en-us/powershell/module/cimcmdlets/invoke-cimmethod)
- [Liste des classes WMI](https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-provider) disponibles sous Windows

---

### À retenir

- Préférez `Get-CimInstance` à `Get-WmiObject` (ce dernier étant obsolète)
- Utilisez des sessions CIM pour des opérations multiples sur des machines distantes
- Apprenez à utiliser le paramètre `-Filter` pour des requêtes plus efficaces
- Explorez les nombreuses classes WMI/CIM pour découvrir toutes les informations système accessibles
