# Module 15 - Architecture & design de scripts pro
## 15-3. Gestion de la configuration externe (JSON, ENV, INI)

Dans le développement de scripts PowerShell professionnels, il est essentiel de séparer le code et la configuration. Cette approche offre plusieurs avantages :

- **Flexibilité** : Modification des paramètres sans toucher au code
- **Sécurité** : Stockage des informations sensibles en dehors du code source
- **Portabilité** : Adaptation facile à différents environnements
- **Maintenabilité** : Centralisation des paramètres pour une gestion simplifiée

Dans ce module, nous allons explorer les différentes méthodes pour gérer la configuration externe dans vos scripts PowerShell.

### 1. Fichiers JSON

Le format JSON (JavaScript Object Notation) est l'un des formats les plus utilisés pour la configuration externe grâce à sa simplicité et sa lisibilité.

#### Création d'un fichier de configuration JSON

Voici un exemple de fichier `config.json` :

```json
{
    "Application": {
        "Name": "MonApplication",
        "Version": "1.0.0",
        "LogLevel": "Information"
    },
    "Database": {
        "Server": "localhost",
        "Port": 1433,
        "Name": "MaBaseDeDonnees",
        "Timeout": 30
    },
    "API": {
        "Endpoint": "https://api.exemple.com",
        "UseAuthentication": true,
        "RetryAttempts": 3
    }
}
```

#### Lecture d'un fichier JSON en PowerShell

```powershell
# Lecture du fichier de configuration
$configPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

# Accès aux valeurs
$applicationName = $config.Application.Name
$databaseServer = $config.Database.Server
$apiEndpoint = $config.API.Endpoint

Write-Host "Application: $applicationName"
Write-Host "Serveur de base de données: $databaseServer"
Write-Host "Point de terminaison API: $apiEndpoint"
```

#### Modification et sauvegarde d'un fichier JSON

```powershell
# Modification d'une valeur
$config.API.RetryAttempts = 5

# Sauvegarde des modifications
$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
```

### 2. Variables d'environnement (ENV)

Les variables d'environnement sont particulièrement utiles pour:
- Stocker des informations sensibles (comme des mots de passe ou des clés API)
- Configurer des valeurs spécifiques à un environnement (développement, test, production)
- Partager des configurations entre différents scripts ou applications

#### Utilisation des variables d'environnement

```powershell
# Accès aux variables d'environnement existantes
$homePath = $env:USERPROFILE
$tempPath = $env:TEMP

Write-Host "Répertoire utilisateur: $homePath"
Write-Host "Répertoire temporaire: $tempPath"

# Création ou modification de variables d'environnement (pour la session courante)
$env:APP_ENVIRONMENT = "Development"
$env:API_KEY = "ma-clé-secrète"

# Lecture des variables d'environnement personnalisées
$environment = $env:APP_ENVIRONMENT
$apiKey = $env:API_KEY

Write-Host "Environnement: $environment"
Write-Host "Clé API: $apiKey"
```

#### Variables d'environnement permanentes

Pour créer des variables d'environnement permanentes (au niveau système ou utilisateur) :

```powershell
# Au niveau utilisateur
[Environment]::SetEnvironmentVariable("APP_ENVIRONMENT", "Production", "User")

# Au niveau système (nécessite des droits administrateur)
[Environment]::SetEnvironmentVariable("APP_ENVIRONMENT", "Production", "Machine")

# Pour supprimer une variable d'environnement permanente
[Environment]::SetEnvironmentVariable("APP_ENVIRONMENT", $null, "User")
```

### 3. Fichiers INI

Les fichiers INI sont un format de configuration simple, organisé en sections avec des paires clé-valeur.

#### Exemple de fichier INI (app.ini)

```ini
[Application]
Name=MonApplication
Version=1.0.0
LogLevel=Information

[Database]
Server=localhost
Port=1433
Name=MaBaseDeDonnees
Timeout=30

[API]
Endpoint=https://api.exemple.com
UseAuthentication=true
RetryAttempts=3
```

#### Lecture de fichiers INI en PowerShell

PowerShell n'a pas de fonctions intégrées pour les fichiers INI, mais nous pouvons créer nos propres fonctions :

```powershell
function Get-IniContent {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $ini = @{}
    switch -regex -file $FilePath {
        "^\[(.+)\]" {
            # Section
            $section = $matches[1]
            $ini[$section] = @{}
        }
        "(.+?)=(.+)" {
            # Clé-Valeur
            if ($section) {
                $name, $value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
    }

    return $ini
}

# Utilisation
$iniPath = Join-Path -Path $PSScriptRoot -ChildPath "app.ini"
$config = Get-IniContent -FilePath $iniPath

# Accès aux valeurs
$applicationName = $config.Application.Name
$databaseServer = $config.Database.Server
$apiEndpoint = $config.API.Endpoint

Write-Host "Application: $applicationName"
Write-Host "Serveur de base de données: $databaseServer"
Write-Host "Point de terminaison API: $apiEndpoint"
```

#### Modification et sauvegarde de fichiers INI

```powershell
function Set-IniContent {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath,
        [Parameter(Mandatory)]
        [hashtable]$IniData
    )

    $content = @()
    foreach ($section in $IniData.Keys) {
        $content += "[$section]"
        foreach ($key in $IniData[$section].Keys) {
            $value = $IniData[$section][$key]
            $content += "$key=$value"
        }
        $content += ""  # Ligne vide entre les sections
    }

    $content | Set-Content -Path $FilePath
}

# Modification d'une valeur
$config.API.RetryAttempts = 5

# Sauvegarde des modifications
Set-IniContent -FilePath $iniPath -IniData $config
```

### 4. Meilleures pratiques

#### Hiérarchie de configuration

Créez une hiérarchie de précédence pour vos configurations :

1. **Paramètres par défaut codés en dur** (fallback)
2. **Fichiers de configuration** (JSON, INI)
3. **Variables d'environnement** (peuvent remplacer les valeurs des fichiers)
4. **Arguments de ligne de commande** (priorité la plus élevée)

Exemple d'implémentation :

```powershell
function Get-ConfigValue {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [object]$ConfigFile,
        [string]$Section,
        [string]$EnvPrefix = "APP_",
        [object]$DefaultValue = $null
    )

    # 1. Vérification des arguments de ligne de commande (via une variable globale)
    if ($Global:CommandLineArgs -and $Global:CommandLineArgs.ContainsKey($Name)) {
        return $Global:CommandLineArgs[$Name]
    }

    # 2. Vérification des variables d'environnement
    $envName = "$EnvPrefix$($Name.ToUpper())"
    if ([Environment]::GetEnvironmentVariable($envName)) {
        return [Environment]::GetEnvironmentVariable($envName)
    }

    # 3. Vérification du fichier de configuration
    if ($ConfigFile) {
        if ($ConfigFile -is [System.Management.Automation.PSCustomObject]) {
            # Format JSON
            if ($Section) {
                if (Get-Member -InputObject $ConfigFile -Name $Section) {
                    $sectionObj = $ConfigFile.$Section
                    if (Get-Member -InputObject $sectionObj -Name $Name) {
                        return $sectionObj.$Name
                    }
                }
            } elseif (Get-Member -InputObject $ConfigFile -Name $Name) {
                return $ConfigFile.$Name
            }
        } elseif ($ConfigFile -is [hashtable]) {
            # Format INI
            if ($Section -and $ConfigFile.ContainsKey($Section)) {
                if ($ConfigFile[$Section].ContainsKey($Name)) {
                    return $ConfigFile[$Section][$Name]
                }
            } elseif ($ConfigFile.ContainsKey($Name)) {
                return $ConfigFile[$Name]
            }
        }
    }

    # 4. Valeur par défaut
    return $DefaultValue
}

# Exemple d'utilisation
$jsonConfig = Get-Content -Path "config.json" -Raw | ConvertFrom-Json
$serverName = Get-ConfigValue -Name "Server" -Section "Database" -ConfigFile $jsonConfig -DefaultValue "localhost"
$logLevel = Get-ConfigValue -Name "LogLevel" -Section "Application" -ConfigFile $jsonConfig -DefaultValue "Information"
```

#### Sécurisation des informations sensibles

Pour les informations sensibles comme les mots de passe ou les clés API :

```powershell
# Chiffrement d'une chaîne en texte sécurisé
function Protect-ConfigValue {
    param (
        [Parameter(Mandatory)]
        [string]$Value,
        [string]$OutputPath
    )

    $secureString = ConvertTo-SecureString -String $Value -AsPlainText -Force
    $encrypted = ConvertFrom-SecureString -SecureString $secureString

    if ($OutputPath) {
        $encrypted | Set-Content -Path $OutputPath
        return $OutputPath
    } else {
        return $encrypted
    }
}

# Déchiffrement d'une chaîne sécurisée
function Unprotect-ConfigValue {
    param (
        [Parameter(Mandatory, ParameterSetName="Value")]
        [string]$EncryptedValue,

        [Parameter(Mandatory, ParameterSetName="File")]
        [string]$InputPath
    )

    if ($InputPath) {
        $EncryptedValue = Get-Content -Path $InputPath
    }

    $secureString = ConvertTo-SecureString -String $EncryptedValue
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
    $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

    return $plainText
}

# Exemple d'utilisation
$apiKeyEncrypted = Protect-ConfigValue -Value "ma-clé-secrète" -OutputPath "api-key.enc"
$apiKey = Unprotect-ConfigValue -InputPath "api-key.enc"
```

### 5. Exemple concret : Script modulaire avec configuration externe

Voici un exemple plus complet montrant comment structurer un script avec configuration externe :

```powershell
# Script principal: backup-databases.ps1
[CmdletBinding()]
param (
    [string]$ConfigPath = "config.json",
    [string]$Environment = "Development"
)

# Charger la configuration
$configFullPath = Join-Path -Path $PSScriptRoot -ChildPath $ConfigPath
if (-not (Test-Path -Path $configFullPath)) {
    Write-Error "Fichier de configuration non trouvé: $configFullPath"
    exit 1
}

$config = Get-Content -Path $configFullPath -Raw | ConvertFrom-Json

# Définir les variables d'environnement pour cet environnement spécifique
$envConfigProperty = "$($Environment)Config"
if (Get-Member -InputObject $config -Name $envConfigProperty) {
    $envConfig = $config.$envConfigProperty

    # Appliquer les configurations d'environnement
    foreach ($property in $envConfig.PSObject.Properties) {
        $envVarName = "BACKUP_$($property.Name.ToUpper())"
        $env:$envVarName = $property.Value
    }
}

# Fonctions utilitaires pour obtenir la configuration
function Get-AppSetting {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [object]$DefaultValue = $null
    )

    $envVarName = "BACKUP_$($Name.ToUpper())"

    if ($env:$envVarName) {
        return $env:$envVarName
    }

    if (Get-Member -InputObject $config.Settings -Name $Name) {
        return $config.Settings.$Name
    }

    return $DefaultValue
}

# Récupérer les paramètres
$backupPath = Get-AppSetting -Name "BackupPath" -DefaultValue "C:\Backups"
$retentionDays = Get-AppSetting -Name "RetentionDays" -DefaultValue 7
$databases = $config.Databases

# Exécuter les sauvegardes
foreach ($db in $databases) {
    $dbName = $db.Name
    $dbServer = $db.Server

    Write-Host "Sauvegarde de la base de données: $dbName sur $dbServer"

    # Logique de sauvegarde ici
    # ...
}

# Nettoyage des anciennes sauvegardes
$retentionDate = (Get-Date).AddDays(-$retentionDays)
Get-ChildItem -Path $backupPath -Filter "*.bak" |
    Where-Object { $_.LastWriteTime -lt $retentionDate } |
    ForEach-Object {
        Write-Host "Suppression de l'ancienne sauvegarde: $($_.Name)"
        Remove-Item -Path $_.FullName -Force
    }
```

Avec un fichier de configuration correspondant :

```json
{
    "Settings": {
        "BackupPath": "D:\\Backups",
        "RetentionDays": 14,
        "Compression": true,
        "NotificationEmail": "admin@exemple.com"
    },
    "DevelopmentConfig": {
        "BackupPath": "C:\\Dev\\Backups",
        "RetentionDays": 3
    },
    "ProductionConfig": {
        "BackupPath": "\\\\BackupServer\\SqlBackups",
        "RetentionDays": 30
    },
    "Databases": [
        {
            "Name": "ApplicationDB",
            "Server": "SQL01",
            "Type": "Full"
        },
        {
            "Name": "ReportingDB",
            "Server": "SQL02",
            "Type": "Differential"
        }
    ]
}
```

### Conclusion

La gestion de la configuration externe est un élément fondamental pour développer des scripts PowerShell robustes et professionnels. En séparant le code de la configuration, vous rendez vos scripts plus flexibles, plus sécurisés et plus faciles à maintenir.

Points clés à retenir :
- Utilisez **JSON** pour des configurations structurées et complexes
- Utilisez les **variables d'environnement** pour des paramètres sensibles ou spécifiques à l'environnement
- Utilisez les fichiers **INI** pour des configurations simples et lisibles
- Établissez une hiérarchie claire pour la résolution des paramètres
- Protégez les informations sensibles à l'aide du chiffrement

En maîtrisant ces techniques, vous pourrez créer des solutions PowerShell adaptables et évolutives, prêtes à être déployées dans des environnements professionnels.
