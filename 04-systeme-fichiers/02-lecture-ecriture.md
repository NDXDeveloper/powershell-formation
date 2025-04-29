# Module 5 - Gestion des fichiers et du système
## 5-2. Lecture/écriture de fichiers (TXT, CSV, JSON, XML)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

La lecture et l'écriture de fichiers sont des opérations fondamentales dans tout script PowerShell. Qu'il s'agisse de journaux, de données structurées ou de configurations, PowerShell offre des outils intuitifs pour manipuler différents formats de fichiers.

Dans cette section, nous verrons comment travailler avec les formats les plus courants : texte brut, CSV, JSON et XML.

### 📝 Fichiers texte (TXT)

Les fichiers texte sont les plus simples mais restent très utilisés pour les journaux, les notes ou les configurations basiques.

#### Lecture d'un fichier texte

```powershell
# Lire tout le contenu d'un fichier
$contenu = Get-Content -Path C:\temp\notes.txt

# Lire les 5 premières lignes
$debut = Get-Content -Path C:\temp\journal.log -TotalCount 5

# Lire les 10 dernières lignes
$fin = Get-Content -Path C:\temp\journal.log -Tail 10
```

> 💡 Par défaut, `Get-Content` retourne un tableau avec une ligne par élément.

#### Lecture d'un fichier comme une seule chaîne

```powershell
# Utile pour les fichiers qui contiennent des caractères spéciaux ou du formatage
$contenuBrut = Get-Content -Path C:\temp\config.txt -Raw
```

#### Écriture dans un fichier texte

```powershell
# Créer ou remplacer un fichier
Set-Content -Path C:\temp\nouveau.txt -Value "Bonjour, monde!"

# Ajouter du contenu à un fichier existant
Add-Content -Path C:\temp\journal.log -Value "$(Get-Date) - Opération terminée"
```

#### Exemple pratique : Journal d'événements

```powershell
function Write-Log {
    param (
        [string]$Message,
        [string]$LogFile = "C:\Logs\script.log"
    )

    # Créer le dossier si nécessaire
    $dossierLog = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $dossierLog)) {
        New-Item -Path $dossierLog -ItemType Directory -Force
    }

    # Format: [Date] Message
    $ligneLog = "[$((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))] $Message"

    # Ajouter au fichier
    Add-Content -Path $LogFile -Value $ligneLog
}

# Utilisation
Write-Log -Message "Démarrage du script"
Write-Log -Message "Erreur: fichier introuvable" -LogFile "C:\Logs\erreurs.log"
```

### 📊 Fichiers CSV (Comma-Separated Values)

Les fichiers CSV sont parfaits pour les données tabulaires comme des listes d'utilisateurs, d'inventaires ou de statistiques.

#### Lecture d'un fichier CSV

```powershell
# Importer un fichier CSV
$utilisateurs = Import-Csv -Path C:\Data\utilisateurs.csv

# Accéder aux données
$utilisateurs | ForEach-Object {
    Write-Host "Utilisateur: $($_.Nom), Email: $($_.Email)"
}
```

#### Personnaliser la lecture CSV

```powershell
# Fichier avec séparateur point-virgule (format européen)
$donnees = Import-Csv -Path C:\Data\donnees.csv -Delimiter ";"

# Fichier sans en-têtes
$contacts = Import-Csv -Path C:\Data\contacts.csv -Header "Prénom", "Nom", "Téléphone", "Email"
```

#### Écriture dans un fichier CSV

```powershell
# Créer des objets
$serveurs = @(
    [PSCustomObject]@{
        Nom = "SRV-WEB-01"
        IP = "192.168.1.10"
        Role = "Serveur Web"
        Statut = "En ligne"
    },
    [PSCustomObject]@{
        Nom = "SRV-DB-01"
        IP = "192.168.1.20"
        Role = "Base de données"
        Statut = "En ligne"
    }
)

# Exporter en CSV
$serveurs | Export-Csv -Path C:\Data\serveurs.csv -NoTypeInformation -Delimiter ";"
```

> 💡 L'option `-NoTypeInformation` évite d'ajouter une ligne technique au début du fichier CSV.

#### Exemple pratique : Rapport de taille de dossiers

```powershell
# Obtenir la taille des dossiers dans le répertoire utilisateur
$dossiers = Get-ChildItem -Path $HOME -Directory |
    ForEach-Object {
        $taille = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum

        [PSCustomObject]@{
            Dossier = $_.Name
            "Taille (MB)" = [math]::Round($taille / 1MB, 2)
            "Date de modification" = $_.LastWriteTime
        }
    }

# Exporter le rapport en CSV
$cheminRapport = Join-Path -Path $HOME -ChildPath "rapport_dossiers.csv"
$dossiers | Export-Csv -Path $cheminRapport -NoTypeInformation

Write-Host "Rapport généré: $cheminRapport" -ForegroundColor Green
```

### 📋 Fichiers JSON (JavaScript Object Notation)

JSON est idéal pour les données hiérarchiques et est très utilisé dans les APIs et configurations modernes.

#### Lecture d'un fichier JSON

```powershell
# Lire le contenu du fichier
$jsonContent = Get-Content -Path C:\Data\config.json -Raw

# Convertir de JSON en objet PowerShell
$config = ConvertFrom-Json -InputObject $jsonContent

# Accéder aux données
Write-Host "Serveur: $($config.server)"
Write-Host "Port: $($config.port)"

# Accéder aux données imbriquées
foreach ($user in $config.users) {
    Write-Host "Utilisateur: $($user.name), Role: $($user.role)"
}
```

#### Écriture dans un fichier JSON

```powershell
# Créer un objet complexe
$appConfig = [PSCustomObject]@{
    AppName = "MonApplication"
    Version = "1.0.0"
    Database = @{
        Server = "db.exemple.com"
        Port = 5432
        Name = "MainDB"
        Credentials = @{
            User = "app_user"
            Encrypted = "******"
        }
    }
    Features = @("Reporting", "Analytics", "Export")
    IsProduction = $true
}

# Convertir en JSON et écrire dans un fichier
$appConfig | ConvertTo-Json -Depth 4 | Out-File -FilePath C:\Data\app_config.json
```

> 💡 Le paramètre `-Depth` contrôle le nombre de niveaux de l'objet à convertir (3 par défaut).

#### Exemple pratique : Configuration multi-environnement

```powershell
function Get-EnvironmentConfig {
    param (
        [Parameter(Mandatory)]
        [ValidateSet("Dev", "Test", "Prod")]
        [string]$Environment
    )

    $configPath = Join-Path -Path $PSScriptRoot -ChildPath "config_$Environment.json"

    if (Test-Path -Path $configPath) {
        $jsonContent = Get-Content -Path $configPath -Raw
        return ConvertFrom-Json -InputObject $jsonContent
    }
    else {
        Write-Error "Configuration pour l'environnement '$Environment' introuvable."
        return $null
    }
}

# Utilisation
$config = Get-EnvironmentConfig -Environment "Dev"
Write-Host "Connecté à: $($config.Database.Server)"
```

### 📑 Fichiers XML (eXtensible Markup Language)

XML est un format plus ancien mais encore largement utilisé pour les configurations d'applications et les échanges de données.

#### Lecture d'un fichier XML

```powershell
# Méthode 1: Import-Clixml (pour XML généré par PowerShell)
$donnees = Import-Clixml -Path C:\Data\sauvegarde.xml

# Méthode 2: [xml] (pour XML standard)
[xml]$configXml = Get-Content -Path C:\Data\config.xml

# Accéder aux données avec la méthode 2
$serveurName = $configXml.Configuration.Server.Name
$timeout = $configXml.Configuration.Settings.Timeout
```

#### Écriture dans un fichier XML

```powershell
# Méthode 1: Export-Clixml (format PowerShell)
$processus = Get-Process | Select-Object Name, Id, CPU
$processus | Export-Clixml -Path C:\Data\processus.xml

# Méthode 2: Créer et modifier un document XML standard
[xml]$newXml = New-Object System.Xml.XmlDocument
$racine = $newXml.CreateElement("Configuration")
$newXml.AppendChild($racine) | Out-Null

$serveur = $newXml.CreateElement("Server")
$serveur.SetAttribute("Name", "MainServer")
$serveur.SetAttribute("IP", "192.168.1.100")
$racine.AppendChild($serveur) | Out-Null

$newXml.Save("C:\Data\nouvelle_config.xml")
```

#### Exemple pratique : Sauvegarde et restauration de configuration

```powershell
function Backup-ServiceConfiguration {
    # Récupérer la configuration des services
    $services = Get-Service |
        Where-Object { $_.Name -like "Win*" } |
        Select-Object Name, DisplayName, Status, StartType

    # Sauvegarder en XML
    $backupPath = Join-Path -Path $HOME -ChildPath "services_backup.xml"
    $services | Export-Clixml -Path $backupPath

    Write-Host "Configuration sauvegardée dans: $backupPath" -ForegroundColor Green
    return $backupPath
}

function Restore-ServiceConfiguration {
    param (
        [Parameter(Mandatory)]
        [string]$BackupPath
    )

    if (Test-Path -Path $BackupPath) {
        # Importer la configuration
        $services = Import-Clixml -Path $BackupPath

        foreach ($svc in $services) {
            Write-Host "Restauration de $($svc.Name) vers l'état: $($svc.StartType)" -ForegroundColor Yellow
            # Dans un script réel, vous utiliseriez Set-Service pour restaurer la configuration
        }
    }
    else {
        Write-Error "Fichier de sauvegarde introuvable: $BackupPath"
    }
}

# Utilisation
$backupFile = Backup-ServiceConfiguration
Restore-ServiceConfiguration -BackupPath $backupFile
```

### 💪 Exercice pratique

Créez un script qui:
1. Lit un fichier CSV contenant des informations sur des ordinateurs (Nom, IP, OS)
2. Vérifie si chaque ordinateur est accessible avec `Test-Connection`
3. Crée un rapport au format JSON avec les résultats
4. Sauvegarde également le rapport au format texte pour une lecture rapide

### 🎓 Solution de l'exercice

```powershell
# 1. Création d'un exemple de fichier CSV pour le test
$ordinateursCSV = @"
Nom,IP,OS
PC-DEV-01,192.168.1.10,Windows 10
SRV-WEB-01,192.168.1.20,Windows Server 2019
PC-TEST-02,192.168.1.30,Windows 11
"@
$csvPath = Join-Path -Path $env:TEMP -ChildPath "ordinateurs.csv"
$ordinateursCSV | Out-File -FilePath $csvPath

# 2. Lecture du fichier CSV
$ordinateurs = Import-Csv -Path $csvPath

# 3. Vérification de la connectivité
$resultats = foreach ($pc in $ordinateurs) {
    $pingOk = Test-Connection -ComputerName $pc.IP -Count 1 -Quiet -ErrorAction SilentlyContinue

    [PSCustomObject]@{
        Nom = $pc.Nom
        IP = $pc.IP
        OS = $pc.OS
        Accessible = $pingOk
        DateVerification = Get-Date
    }
}

# 4. Création du rapport JSON
$rapportJson = Join-Path -Path $env:TEMP -ChildPath "rapport_connectivite.json"
$resultats | ConvertTo-Json | Out-File -FilePath $rapportJson
Write-Host "Rapport JSON créé: $rapportJson" -ForegroundColor Green

# 5. Création du rapport texte
$rapportTxt = Join-Path -Path $env:TEMP -ChildPath "rapport_connectivite.txt"
$contenuTxt = @"
RAPPORT DE CONNECTIVITÉ
Date: $(Get-Date -Format "dd/MM/yyyy HH:mm")

RÉSUMÉ
------
Total d'ordinateurs: $($resultats.Count)
Accessibles: $($resultats.Where({$_.Accessible -eq $true}).Count)
Inaccessibles: $($resultats.Where({$_.Accessible -eq $false}).Count)

DÉTAILS
-------
"@

foreach ($resultat in $resultats) {
    $status = if ($resultat.Accessible) { "ACCESSIBLE" } else { "INACCESSIBLE" }
    $contenuTxt += "`n$($resultat.Nom) ($($resultat.IP)) - $status"
}

$contenuTxt | Out-File -FilePath $rapportTxt
Write-Host "Rapport texte créé: $rapportTxt" -ForegroundColor Green

# Ouvrir les rapports
notepad $rapportTxt
```

### 🔑 Points clés à retenir

- Pour les fichiers texte:
  - `Get-Content` et `Set-Content` pour lire et écrire
  - `-Raw` pour lire tout le fichier comme une seule chaîne
  - `Add-Content` pour ajouter sans écraser

- Pour les fichiers CSV:
  - `Import-Csv` et `Export-Csv` avec `-Delimiter` pour spécifier le séparateur
  - `-NoTypeInformation` pour éviter les métadonnées dans le fichier
  - `-Header` pour les fichiers sans en-tête

- Pour les fichiers JSON:
  - `ConvertTo-Json` et `ConvertFrom-Json` pour les conversions
  - `-Depth` pour contrôler les niveaux de profondeur
  - Parfait pour les données hiérarchiques

- Pour les fichiers XML:
  - `Import-Clixml` et `Export-Clixml` pour le format PowerShell
  - `[xml]` pour les fichiers XML standard
  - Plus complexe mais très flexible

### 🔮 Pour aller plus loin

Dans la prochaine section, nous verrons comment gérer les permissions NTFS des fichiers et dossiers, une compétence essentielle pour sécuriser vos données et automatiser la gestion des accès.

---

💡 **Astuce de pro**: Pour manipuler de très gros fichiers texte sans charger tout le contenu en mémoire, utilisez le .NET directement avec `[System.IO.File]::ReadLines()` ou l'option `-ReadCount` de `Get-Content`.

⏭️ [Gestion des permissions NTFS](/04-systeme-fichiers/03-droits-ntfs.md)
