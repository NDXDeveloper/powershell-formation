# Module 9 - Administration Windows
## 9-1. Services, processus, registre, événements

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

L'administration Windows avec PowerShell vous permet de gérer facilement les composants essentiels du système d'exploitation. Dans cette section, nous allons explorer comment manipuler les services, processus, registre et événements - des éléments fondamentaux pour tout administrateur système.

### 📋 Services Windows

Les services sont des programmes qui s'exécutent en arrière-plan et démarrent généralement avec Windows. Ils ne nécessitent pas d'interaction utilisateur et sont essentiels au bon fonctionnement du système.

#### 🔍 Afficher les services

Pour lister tous les services disponibles sur votre système :

```powershell
# Lister tous les services
Get-Service

# Afficher les services en cours d'exécution
Get-Service | Where-Object Status -eq "Running"

# Afficher les services arrêtés
Get-Service | Where-Object Status -eq "Stopped"
```

#### 🔎 Rechercher un service spécifique

```powershell
# Rechercher un service par son nom
Get-Service -Name "wuauserv"  # Service Windows Update

# Rechercher des services dont le nom contient "win"
Get-Service -Name "*win*"

# Rechercher des services par DisplayName
Get-Service -DisplayName "*Windows*"
```

#### ⚙️ Gérer les services

```powershell
# Démarrer un service (nécessite des droits administrateur)
Start-Service -Name "wuauserv"

# Arrêter un service
Stop-Service -Name "wuauserv"

# Redémarrer un service
Restart-Service -Name "wuauserv"

# Mettre en pause un service (si pris en charge)
Suspend-Service -Name "nomduservice"

# Modifier le type de démarrage d'un service
Set-Service -Name "wuauserv" -StartupType Automatic  # Options: Automatic, Manual, Disabled
```

#### ℹ️ Obtenir des informations détaillées

```powershell
# Afficher les propriétés d'un service
Get-Service -Name "wuauserv" | Format-List *

# Obtenir des infos WMI plus détaillées sur un service
Get-CimInstance -ClassName Win32_Service -Filter "Name = 'wuauserv'"
```

### 🖥️ Processus

Les processus sont des instances de programmes en cours d'exécution. PowerShell offre des outils puissants pour les surveiller et les gérer.

#### 🔍 Afficher les processus

```powershell
# Lister tous les processus
Get-Process

# Afficher les processus avec le plus de RAM utilisée
Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 10

# Afficher les processus avec le plus de CPU utilisé
Get-Process | Sort-Object -Property CPU -Descending | Select-Object -First 10
```

#### 🔎 Rechercher un processus spécifique

```powershell
# Rechercher un processus par son nom
Get-Process -Name "chrome"

# Rechercher des processus dont le nom contient certains caractères
Get-Process -Name "*exp*"  # Trouvera explorer.exe, iexplore.exe, etc.
```

#### ⚙️ Gérer les processus

```powershell
# Arrêter un processus (attention : peut causer des pertes de données)
Stop-Process -Name "notepad"

# Arrêter un processus avec son ID
Stop-Process -Id 1234

# Arrêter tous les processus d'une application
Get-Process -Name "chrome" | Stop-Process

# Démarrer un nouveau processus
Start-Process -FilePath "notepad.exe"

# Démarrer un processus avec arguments
Start-Process -FilePath "notepad.exe" -ArgumentList "C:\chemin\vers\fichier.txt"
```

#### ℹ️ Obtenir des informations détaillées

```powershell
# Afficher toutes les propriétés d'un processus
Get-Process -Name "chrome" | Format-List *

# Obtenir les modules chargés par un processus
Get-Process -Name "explorer" | Select-Object -ExpandProperty Modules

# Afficher les threads d'un processus
Get-Process -Name "explorer" | Select-Object -ExpandProperty Threads
```

### 🗄️ Registre Windows

Le registre Windows est une base de données hiérarchique qui stocke les paramètres de configuration pour le système d'exploitation et les applications.

#### 🔍 Naviguer dans le registre

Le registre est organisé en ruches (hives) accessibles via des lecteurs PowerShell :

```powershell
# Lister les lecteurs du registre
Get-PSDrive -PSProvider Registry

# Accéder à une clé de registre (comme un dossier)
cd HKLM:\SOFTWARE\Microsoft\Windows

# Lister les sous-clés d'une clé de registre
Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows"

# Rechercher des clés de registre
Get-ChildItem -Path "HKLM:\SOFTWARE" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*WindowsUpdate*" }
```

> ⚠️ **Attention** : La modification du registre peut rendre votre système instable ou inutilisable. Créez toujours une sauvegarde avant de faire des modifications.

#### 🔎 Lire des valeurs de registre

```powershell
# Lire toutes les valeurs d'une clé
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion"

# Lire une valeur spécifique
Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "ProgramFilesDir"

# Lire une valeur avec un raccourci
(Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion" -Name "ProgramFilesDir").ProgramFilesDir
```

#### ⚙️ Modifier le registre

```powershell
# Créer une clé de registre
New-Item -Path "HKCU:\Software\MonAppli"

# Créer ou modifier une valeur de registre
Set-ItemProperty -Path "HKCU:\Software\MonAppli" -Name "Configuration" -Value "Test" -Type String

# Supprimer une valeur de registre
Remove-ItemProperty -Path "HKCU:\Software\MonAppli" -Name "Configuration"

# Supprimer une clé de registre et toutes ses valeurs
Remove-Item -Path "HKCU:\Software\MonAppli" -Recurse
```

#### 🔄 Types de données du registre

Les principales types de données du registre sont :

- `String` (REG_SZ) : Chaîne de caractères
- `ExpandString` (REG_EXPAND_SZ) : Chaîne avec variables d'environnement
- `Binary` (REG_BINARY) : Données binaires
- `DWord` (REG_DWORD) : Valeur entière 32 bits
- `QWord` (REG_QWORD) : Valeur entière 64 bits
- `MultiString` (REG_MULTI_SZ) : Tableau de chaînes

### 📊 Événements Windows

Les événements Windows sont des enregistrements d'activités générés par le système d'exploitation et les applications. Ils sont essentiels pour le dépannage et la surveillance.

#### 🔍 Consulter les journaux d'événements

```powershell
# Lister les journaux d'événements disponibles
Get-EventLog -List

# Lister les logs Windows plus récents (PowerShell 3.0+)
Get-WinEvent -ListLog * | Where-Object { $_.RecordCount -gt 0 } | Sort-Object RecordCount -Descending
```

#### 🔎 Rechercher des événements spécifiques

```powershell
# Afficher les derniers événements du journal système
Get-EventLog -LogName System -Newest 10

# Filtrer les événements par source
Get-EventLog -LogName System -Source "Disk" -Newest 5

# Filtrer les événements par ID d'événement
Get-EventLog -LogName System -InstanceId 7036 -Newest 5

# Filtrer les événements d'erreur
Get-EventLog -LogName System -EntryType Error -Newest 5

# Rechercher des événements avec un texte spécifique
Get-EventLog -LogName System -Message "*disk*" -Newest 5
```

#### 📆 Filtrer par date

```powershell
# Événements après une date spécifique
$debut = Get-Date -Year 2023 -Month 1 -Day 1
Get-EventLog -LogName System -After $debut -EntryType Error

# Événements dans une plage de dates
$debut = Get-Date -Year 2023 -Month 1 -Day 1
$fin = Get-Date -Year 2023 -Month 1 -Day 31
Get-EventLog -LogName System -After $debut -Before $fin -EntryType Error
```

#### 🔍 Utiliser Get-WinEvent (plus puissant)

```powershell
# Obtenir les événements d'un journal spécifique
Get-WinEvent -LogName "System" -MaxEvents 10

# Utiliser des filtres XPath (puissant mais complexe)
Get-WinEvent -FilterXPath '*[System[EventID=7036]]' -LogName "System" -MaxEvents 10

# Utiliser un filtre hashtable (plus simple)
$filtre = @{
    LogName = 'System'
    ID = 7036
    StartTime = (Get-Date).AddDays(-1)
}
Get-WinEvent -FilterHashtable $filtre
```

#### 📊 Analyser les événements courants

```powershell
# Rechercher les événements de démarrage/arrêt du système
Get-WinEvent -FilterHashtable @{LogName='System'; ID=6005,6006,6008}

# Rechercher les erreurs critiques
Get-WinEvent -FilterHashtable @{LogName='System'; Level=1} -MaxEvents 10

# Rechercher les échecs de connexion
Get-WinEvent -FilterHashtable @{LogName='Security'; ID=4625} -MaxEvents 10
```

### 💡 Exercices pratiques

1. **Services** : Listez tous les services qui démarrent automatiquement et qui sont actuellement arrêtés.
2. **Processus** : Identifiez les 5 processus consommant le plus de mémoire sur votre système.
3. **Registre** : Créez une clé de registre pour votre application fictive et ajoutez-y quelques valeurs de configuration.
4. **Événements** : Trouvez les 10 dernières erreurs critiques dans le journal système.

### 🔑 Points clés à retenir

- Les services Windows peuvent être gérés avec `Get-Service`, `Start-Service`, `Stop-Service`
- Les processus sont manipulés avec `Get-Process`, `Stop-Process`, `Start-Process`
- Le registre est accessible via les lecteurs PowerShell comme `HKLM:` et `HKCU:`
- Les événements Windows peuvent être consultés avec `Get-EventLog` (ancien) ou `Get-WinEvent` (moderne)
- Soyez prudent lors de la modification des services, processus et du registre - ces changements peuvent affecter la stabilité du système

---

Dans la prochaine section, nous explorerons comment utiliser WMI et CIM pour une administration Windows encore plus puissante.

⏭️ [WMI vs CIM (`Get-CimInstance`, `Invoke-CimMethod`)](/08-administration-windows/02-wmi-vs-cim.md)
