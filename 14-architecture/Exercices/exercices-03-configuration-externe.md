# Exercice 1 - Lecture et modification de configuration JSON

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Énoncé
Créez un script PowerShell qui:
1. Lit un fichier de configuration JSON contenant des paramètres d'application
2. Affiche les valeurs actuelles
3. Modifie certaines valeurs
4. Sauvegarde la configuration mise à jour dans un nouveau fichier

## Solution

```powershell
<#
.SYNOPSIS
    Script de manipulation de fichier de configuration JSON.
.DESCRIPTION
    Ce script lit un fichier de configuration au format JSON, affiche les valeurs,
    modifie certains paramètres et sauvegarde le résultat dans un nouveau fichier.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration JSON source.
.PARAMETER OutputPath
    Chemin vers le fichier de sortie pour la configuration modifiée.
.EXAMPLE
    .\Exercice1-ConfigJSON.ps1 -ConfigPath ".\config.json" -OutputPath ".\config-modified.json"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\config.json",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\config-modified.json"
)

# Vérification de l'existence du fichier de configuration
if (-not (Test-Path -Path $ConfigPath)) {
    # Si le fichier n'existe pas, créer un exemple de configuration
    Write-Host "Le fichier de configuration n'existe pas. Création d'un exemple..." -ForegroundColor Yellow

    $exampleConfig = @{
        Application = @{
            Name = "MonApplication"
            Version = "1.0.0"
            LogLevel = "Information"
            MaxConnections = 10
        }
        Database = @{
            Server = "localhost"
            Port = 1433
            Name = "MaBaseDeDonnees"
            Username = "sa"
            Timeout = 30
        }
        Features = @{
            EnableLogging = $true
            EnableCaching = $true
            CacheTimeoutMinutes = 15
            AllowExport = $false
        }
    }

    # Convertir et sauvegarder la configuration exemple
    $exampleConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $ConfigPath
    Write-Host "Fichier exemple créé: $ConfigPath" -ForegroundColor Green
}

# Lecture du fichier de configuration
try {
    Write-Host "Lecture du fichier de configuration: $ConfigPath" -ForegroundColor Cyan
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json -ErrorAction Stop
    Write-Host "Configuration chargée avec succès." -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de la lecture du fichier JSON: $_"
    exit 1
}

# Affichage des valeurs actuelles
Write-Host "`nValeurs actuelles de la configuration:" -ForegroundColor Cyan
Write-Host "-------------------------------------" -ForegroundColor Cyan

Write-Host "Application:"
Write-Host "  - Nom: $($config.Application.Name)"
Write-Host "  - Version: $($config.Application.Version)"
Write-Host "  - Niveau de journalisation: $($config.Application.LogLevel)"
Write-Host "  - Connexions max: $($config.Application.MaxConnections)"

Write-Host "`nBase de données:"
Write-Host "  - Serveur: $($config.Database.Server)"
Write-Host "  - Port: $($config.Database.Port)"
Write-Host "  - Nom BDD: $($config.Database.Name)"
Write-Host "  - Timeout: $($config.Database.Timeout) secondes"

Write-Host "`nFonctionnalités:"
Write-Host "  - Journalisation activée: $($config.Features.EnableLogging)"
Write-Host "  - Mise en cache activée: $($config.Features.EnableCaching)"
Write-Host "  - Délai d'expiration du cache: $($config.Features.CacheTimeoutMinutes) minutes"
Write-Host "  - Export autorisé: $($config.Features.AllowExport)"

# Modification des valeurs
Write-Host "`nModification des valeurs de configuration..." -ForegroundColor Yellow

# Méthode 1: Modification directe des attributs
$config.Application.Version = "1.1.0"
$config.Application.LogLevel = "Debug"

# Méthode 2: Utilisation de Add-Member pour ajouter de nouvelles propriétés
$config.Application | Add-Member -MemberType NoteProperty -Name "Environment" -Value "Development" -Force
$config.Features | Add-Member -MemberType NoteProperty -Name "EnableNotifications" -Value $true -Force

# Méthode 3: Modification de tableaux/collections
$config.Features.CacheTimeoutMinutes = 30
$config.Features.AllowExport = $true

# Affichage des nouvelles valeurs
Write-Host "`nNouvelles valeurs de configuration:" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan

Write-Host "Application:"
Write-Host "  - Nom: $($config.Application.Name)"
Write-Host "  - Version: $($config.Application.Version) (modifié)"
Write-Host "  - Niveau de journalisation: $($config.Application.LogLevel) (modifié)"
Write-Host "  - Connexions max: $($config.Application.MaxConnections)"
Write-Host "  - Environnement: $($config.Application.Environment) (ajouté)"

Write-Host "`nBase de données:"
Write-Host "  - Serveur: $($config.Database.Server)"
Write-Host "  - Port: $($config.Database.Port)"
Write-Host "  - Nom BDD: $($config.Database.Name)"
Write-Host "  - Timeout: $($config.Database.Timeout) secondes"

Write-Host "`nFonctionnalités:"
Write-Host "  - Journalisation activée: $($config.Features.EnableLogging)"
Write-Host "  - Mise en cache activée: $($config.Features.EnableCaching)"
Write-Host "  - Délai d'expiration du cache: $($config.Features.CacheTimeoutMinutes) minutes (modifié)"
Write-Host "  - Export autorisé: $($config.Features.AllowExport) (modifié)"
Write-Host "  - Notifications activées: $($config.Features.EnableNotifications) (ajouté)"

# Sauvegarde de la configuration mise à jour
try {
    Write-Host "`nSauvegarde de la configuration mise à jour: $OutputPath" -ForegroundColor Yellow
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath
    Write-Host "Configuration sauvegardée avec succès." -ForegroundColor Green
}
catch {
    Write-Error "Erreur lors de la sauvegarde de la configuration: $_"
    exit 1
}

Write-Host "`nComparaison des fichiers:" -ForegroundColor Cyan
Write-Host "Fichier original: $ConfigPath"
Write-Host "Fichier modifié: $OutputPath"
```

## Utilisation

1. Sauvegardez le script ci-dessus dans un fichier nommé `Exercice1-ConfigJSON.ps1`
2. Exécutez le script sans paramètres pour utiliser les noms de fichiers par défaut
3. Vous pouvez aussi spécifier des chemins personnalisés:
   ```
   .\Exercice1-ConfigJSON.ps1 -ConfigPath "C:\Configs\app.json" -OutputPath "C:\Configs\app-new.json"
   ```

## Points d'apprentissage
- Lecture et écriture de fichiers JSON
- Conversion entre objets PowerShell et format JSON
- Affichage formaté des informations de configuration
- Différentes méthodes pour modifier les propriétés d'objets
- Gestion des erreurs avec try/catch

# Exercice 2 - Variables d'environnement pour la configuration

## Énoncé
Créez un script PowerShell qui utilise des variables d'environnement pour configurer le comportement d'une application. Le script doit:
1. Vérifier l'existence de variables d'environnement spécifiques
2. Utiliser des valeurs par défaut si les variables ne sont pas définies
3. Créer des variables d'environnement permanentes au niveau utilisateur
4. Afficher un résumé de la configuration utilisée

## Solution

```powershell
<#
.SYNOPSIS
    Démontre l'utilisation des variables d'environnement pour la configuration.
.DESCRIPTION
    Ce script illustre comment utiliser les variables d'environnement comme mécanisme de configuration
    dans les scripts PowerShell. Il vérifie l'existence de variables spécifiques, utilise des valeurs
    par défaut si nécessaire, et peut créer des variables permanentes au niveau utilisateur.
.PARAMETER SetPermanent
    Indique si les variables d'environnement doivent être définies de façon permanente au niveau utilisateur.
.PARAMETER Reset
    Supprime les variables d'environnement permanentes créées par ce script.
.EXAMPLE
    .\Exercice2-EnvVars.ps1
    Exécute le script avec les paramètres par défaut.
.EXAMPLE
    .\Exercice2-EnvVars.ps1 -SetPermanent
    Définit les variables d'environnement de façon permanente pour l'utilisateur.
.EXAMPLE
    .\Exercice2-EnvVars.ps1 -Reset
    Supprime les variables d'environnement permanentes créées par ce script.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$SetPermanent,

    [Parameter(Mandatory = $false)]
    [switch]$Reset
)

# Définition du préfixe pour nos variables d'environnement
$envPrefix = "APP_"

# Liste des variables de configuration avec leurs valeurs par défaut
$configVars = @{
    "ENVIRONMENT" = "Development"
    "LOG_LEVEL" = "Information"
    "SERVER_PORT" = 8080
    "DATABASE_HOST" = "localhost"
    "DATABASE_PORT" = 3306
    "MAX_CONNECTIONS" = 100
    "TIMEOUT_SECONDS" = 30
    "ENABLE_CACHE" = $true
    "DEBUG_MODE" = $false
}

# Fonction pour obtenir une variable d'environnement ou sa valeur par défaut
function Get-EnvVarOrDefault {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$DefaultValue
    )

    $fullName = "$envPrefix$Name"
    $envValue = [Environment]::GetEnvironmentVariable($fullName)

    if ($null -eq $envValue) {
        return $DefaultValue
    }

    # Conversion selon le type de la valeur par défaut
    try {
        switch ($DefaultValue.GetType().Name) {
            "Boolean" {
                return [bool]::Parse($envValue)
            }
            "Int32" {
                return [int]::Parse($envValue)
            }
            "Double" {
                return [double]::Parse($envValue)
            }
            default {
                return $envValue
            }
        }
    }
    catch {
        Write-Warning "Impossible de convertir la valeur de $fullName. Utilisation de la valeur par défaut."
        return $DefaultValue
    }
}

# Fonction pour définir une variable d'environnement (temporaire ou permanente)
function Set-EnvVar {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [object]$Value,

        [Parameter(Mandatory = $false)]
        [bool]$Permanent = $false
    )

    $fullName = "$envPrefix$Name"

    # Définition de la variable pour la session courante
    Set-Item -Path "env:$fullName" -Value "$Value"

    # Si demandé, définition permanente au niveau utilisateur
    if ($Permanent) {
        [Environment]::SetEnvironmentVariable($fullName, "$Value", "User")
        Write-Host "Variable $fullName définie de façon permanente au niveau utilisateur" -ForegroundColor Green
    }
}

# Traitement de l'option Reset si spécifiée
if ($Reset) {
    Write-Host "Suppression des variables d'environnement permanentes..." -ForegroundColor Yellow

    foreach ($key in $configVars.Keys) {
        $fullName = "$envPrefix$key"
        [Environment]::SetEnvironmentVariable($fullName, $null, "User")
        Write-Host "Variable $fullName supprimée" -ForegroundColor Gray
    }

    Write-Host "Toutes les variables d'environnement permanentes ont été supprimées." -ForegroundColor Green
    exit 0
}

# Lecture ou création des variables d'environnement
$config = @{}

Write-Host "Configuration de l'application:" -ForegroundColor Cyan
Write-Host "----------------------------" -ForegroundColor Cyan

foreach ($key in $configVars.Keys) {
    $defaultValue = $configVars[$key]
    $value = Get-EnvVarOrDefault -Name $key -DefaultValue $defaultValue

    # Stockage dans notre configuration
    $config[$key] = $value

    # Affichage du statut de la variable
    $fullName = "$envPrefix$key"
    $valueExists = [Environment]::GetEnvironmentVariable($fullName) -ne $null
    $statusColor = if ($valueExists) { "Green" } else { "Yellow" }
    $status = if ($valueExists) { "définie" } else { "non définie (valeur par défaut)" }

    Write-Host "$key = $value" -NoNewline
    Write-Host " [$status]" -ForegroundColor $statusColor

    # Si demandé, définition permanente
    if ($SetPermanent) {
        Set-EnvVar -Name $key -Value $value -Permanent $true
    }
}

# Démonstration de l'utilisation des valeurs de configuration
Write-Host "`nUtilisation de la configuration:" -ForegroundColor Cyan
Write-Host "---------------------------" -ForegroundColor Cyan

Write-Host "Application démarrée en environnement $($config.ENVIRONMENT) avec niveau de log $($config.LOG_LEVEL)"
Write-Host "Serveur configuré sur le port $($config.SERVER_PORT) avec $($config.MAX_CONNECTIONS) connexions max"
Write-Host "Base de données: $($config.DATABASE_HOST):$($config.DATABASE_PORT)"
Write-Host "Timeout des requêtes: $($config.TIMEOUT_SECONDS) secondes"

if ($config.ENABLE_CACHE) {
    Write-Host "Cache activé" -ForegroundColor Green
}
else {
    Write-Host "Cache désactivé" -ForegroundColor Yellow
}

if ($config.DEBUG_MODE) {
    Write-Host "Mode DEBUG activé - Affichage d'informations supplémentaires" -ForegroundColor Magenta
    Write-Host "Variables d'environnement complètes:"
    Get-ChildItem env: | Where-Object { $_.Name -like "$envPrefix*" } | Format-Table Name, Value
}

# Instructions pour l'utilisateur
Write-Host "`nInstructions:" -ForegroundColor Cyan
Write-Host "------------" -ForegroundColor Cyan

if ($SetPermanent) {
    Write-Host "Les variables d'environnement ont été définies de façon permanente au niveau utilisateur."
    Write-Host "Pour les supprimer, exécutez: .\Exercice2-EnvVars.ps1 -Reset"
}
else {
    Write-Host "Pour modifier une variable temporairement (session courante uniquement):"
    Write-Host '    $env:APP_LOG_LEVEL = "Debug"'
    Write-Host "Pour définir toutes les variables de façon permanente:"
    Write-Host "    .\Exercice2-EnvVars.ps1 -SetPermanent"
    Write-Host "Pour définir une variable spécifique de façon permanente:"
    Write-Host '    [Environment]::SetEnvironmentVariable("APP_LOG_LEVEL", "Debug", "User")'
}

Write-Host "`nTester avec des valeurs différentes:" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan
Write-Host 'Pour tester avec des valeurs différentes pour cette session:'
Write-Host '    $env:APP_ENVIRONMENT = "Production"'
Write-Host '    $env:APP_DEBUG_MODE = "true"'
Write-Host '    .\Exercice2-EnvVars.ps1'
```

## Utilisation

1. Sauvegardez le script ci-dessus dans un fichier nommé `Exercice2-EnvVars.ps1`
2. Exécutez le script sans paramètres pour voir les valeurs par défaut
3. Modifiez des variables d'environnement et exécutez à nouveau pour voir les différences:
   ```powershell
   $env:APP_ENVIRONMENT = "Production"
   $env:APP_DEBUG_MODE = "true"
   .\Exercice2-EnvVars.ps1
   ```
4. Définissez les variables de façon permanente:
   ```powershell
   .\Exercice2-EnvVars.ps1 -SetPermanent
   ```
5. Si nécessaire, supprimez les variables permanentes:
   ```powershell
   .\Exercice2-EnvVars.ps1 -Reset
   ```

## Points d'apprentissage
- Manipulation des variables d'environnement temporaires et permanentes
- Conversion de types pour les valeurs des variables d'environnement
- Hiérarchie de configuration avec valeurs par défaut
- Affichage formaté des informations de configuration
- Gestion des paramètres de script avec les commutateurs (switches)

# Exercice 3 - Création et utilisation de fichiers INI

## Énoncé
Créez un script PowerShell qui permet de:
1. Créer un fichier de configuration au format INI
2. Lire et interpréter les valeurs d'un fichier INI existant
3. Modifier des valeurs dans le fichier INI
4. Créer une interface simple pour éditer la configuration

## Solution

```powershell
<#
.SYNOPSIS
    Gestion de fichiers de configuration au format INI.
.DESCRIPTION
    Ce script démontre comment créer, lire, et modifier des fichiers de configuration
    au format INI dans PowerShell. Il inclut également une interface simple pour éditer
    les valeurs de configuration.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration INI.
.PARAMETER Action
    Action à effectuer : Create, Read, Update, Edit ou Show.
.EXAMPLE
    .\Exercice3-ConfigINI.ps1 -Action Create
    Crée un fichier INI exemple.
.EXAMPLE
    .\Exercice3-ConfigINI.ps1 -Action Read
    Lit et affiche le contenu du fichier INI.
.EXAMPLE
    .\Exercice3-ConfigINI.ps1 -Action Edit
    Ouvre une interface simple pour éditer les valeurs.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ".\config.ini",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Create", "Read", "Update", "Edit", "Show")]
    [string]$Action = "Show"
)

#region Fonctions pour la gestion des fichiers INI

function Get-IniContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Vérification de l'existence du fichier
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier $FilePath n'existe pas."
        return $null
    }

    $ini = @{}
    $currentSection = "NO_SECTION"
    $ini[$currentSection] = @{}

    # Lecture et traitement du fichier ligne par ligne
    switch -regex -file $FilePath {
        "^\s*\[(.+)\]\s*$" {
            # Nouvelle section trouvée
            $currentSection = $matches[1].Trim()
            if (-not $ini.ContainsKey($currentSection)) {
                $ini[$currentSection] = @{}
            }
            continue
        }
        "^\s*([^#;].*?)\s*=\s*(.*?)\s*$" {
            # Paire clé=valeur trouvée
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()

            # Conversion des valeurs si possible
            if ($value -eq "true") { $value = $true }
            elseif ($value -eq "false") { $value = $false }
            elseif ($value -match "^\d+$") { $value = [int]$value }
            elseif ($value -match "^\d+\.\d+$") { $value = [double]$value }

            $ini[$currentSection][$key] = $value
            continue
        }
        "^\s*;.*$" {
            # Commentaire, ignoré
            continue
        }
    }

    # Suppression de la section par défaut si elle est vide
    if ($ini["NO_SECTION"].Count -eq 0) {
        $ini.Remove("NO_SECTION")
    }

    return $ini
}

function Set-IniContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [hashtable]$Content
    )

    $output = @()

    foreach ($section in $Content.Keys) {
        if ($section -ne "NO_SECTION") {
            $output += "[$section]"
        }

        foreach ($key in $Content[$section].Keys) {
            $value = $Content[$section][$key]
            $output += "$key = $value"
        }

        # Ajouter une ligne vide entre les sections
        $output += ""
    }

    # Écriture du fichier
    $output | Out-File -FilePath $FilePath -Encoding utf8 -Force

    Write-Host "Fichier INI enregistré: $FilePath" -ForegroundColor Green
}

function Update-IniValue {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$IniContent,

        [Parameter(Mandatory = $true)]
        [string]$Section,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [object]$Value
    )

    # Vérification et création de la section si nécessaire
    if (-not $IniContent.ContainsKey($Section)) {
        $IniContent[$Section] = @{}
    }

    # Mise à jour de la valeur
    $IniContent[$Section][$Key] = $Value

    return $IniContent
}

function Format-IniValue {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Value
    )

    # Formatage des valeurs pour l'affichage
    if ($Value -is [bool]) {
        if ($Value) { return "true" } else { return "false" }
    }
    return $Value
}

#endregion

#region Actions du script

function New-ExampleIniFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Création d'un exemple de configuration
    $iniContent = @{
        "Application" = @{
            "Name" = "MonApplication"
            "Version" = "1.0.0"
            "LogLevel" = "Information"
            "MaxConnections" = 10
        }
        "Database" = @{
            "Server" = "localhost"
            "Port" = 1433
            "Name" = "MaBaseDeDonnees"
            "Username" = "utilisateur"
            "Timeout" = 30
        }
        "Features" = @{
            "EnableLogging" = $true
            "EnableCaching" = $true
            "CacheTimeoutMinutes" = 15
            "AllowExport" = $false
        }
        "Paths" = @{
            "LogDirectory" = "C:\Logs"
            "TempDirectory" = "C:\Temp"
            "DataDirectory" = "C:\Data"
        }
    }

    # Enregistrement du fichier INI
    Set-IniContent -FilePath $FilePath -Content $iniContent

    return $iniContent
}

function Show-IniContent {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$IniContent
    )

    Write-Host "Contenu du fichier INI:" -ForegroundColor Cyan
    Write-Host "---------------------" -ForegroundColor Cyan

    foreach ($section in $IniContent.Keys | Sort-Object) {
        Write-Host "`n[$section]" -ForegroundColor Yellow

        foreach ($key in $IniContent[$section].Keys | Sort-Object) {
            $value = Format-IniValue -Value $IniContent[$section][$key]
            $valueType = $IniContent[$section][$key].GetType().Name

            Write-Host "$key = " -NoNewline

            # Coloration selon le type
            switch ($valueType) {
                "Boolean" {
                    $color = if ($value -eq "true") { "Green" } else { "Red" }
                    Write-Host $value -ForegroundColor $color -NoNewline
                }
                "Int32" {
                    Write-Host $value -ForegroundColor Magenta -NoNewline
                }
                "Double" {
                    Write-Host $value -ForegroundColor Blue -NoNewline
                }
                default {
                    Write-Host $value -NoNewline
                }
            }

            # Affichage du type
            Write-Host " ($valueType)" -ForegroundColor Gray
        }
    }
}

function Edit-IniContent {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$IniContent,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $modified = $false

    Write-Host "Éditeur de configuration INI" -ForegroundColor Cyan
    Write-Host "-------------------------" -ForegroundColor Cyan

    # Menu de sélection de section
    $sections = $IniContent.Keys | Sort-Object
    for ($i = 0; $i -lt $sections.Count; $i++) {
        Write-Host "[$i] " -NoNewline
        Write-Host $sections[$i] -ForegroundColor Yellow
    }

    Write-Host "[q] Quitter" -ForegroundColor Gray

    $sectionChoice = Read-Host "`nSélectionnez une section (0-$($sections.Count - 1), q pour quitter)"

    if ($sectionChoice -eq "q") {
        return $false
    }

    # Validation de la sélection de section
    try {
        $sectionIndex = [int]$sectionChoice
        if ($sectionIndex -lt 0 -or $sectionIndex -ge $sections.Count) {
            Write-Host "Sélection invalide." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Sélection invalide." -ForegroundColor Red
        return $false
    }

    $selectedSection = $sections[$sectionIndex]

    # Menu de sélection de clé
    Write-Host "`nSection [$selectedSection]" -ForegroundColor Yellow
    Write-Host "-------------------------" -ForegroundColor Cyan

    $keys = $IniContent[$selectedSection].Keys | Sort-Object
    for ($i = 0; $i -lt $keys.Count; $i++) {
        $key = $keys[$i]
        $value = Format-IniValue -Value $IniContent[$selectedSection][$key]
        $valueType = $IniContent[$selectedSection][$key].GetType().Name

        Write-Host "[$i] " -NoNewline
        Write-Host "$key = " -NoNewline

        # Coloration selon le type
        switch ($valueType) {
            "Boolean" {
                $color = if ($value -eq "true") { "Green" } else { "Red" }
                Write-Host $value -ForegroundColor $color -NoNewline
            }
            "Int32" {
                Write-Host $value -ForegroundColor Magenta -NoNewline
            }
            "Double" {
                Write-Host $value -ForegroundColor Blue -NoNewline
            }
            default {
                Write-Host $value -NoNewline
            }
        }

        # Affichage du type
        Write-Host " ($valueType)" -ForegroundColor Gray
    }

    Write-Host "[q] Retour" -ForegroundColor Gray

    $keyChoice = Read-Host "`nSélectionnez une clé à modifier (0-$($keys.Count - 1), q pour retour)"

    if ($keyChoice -eq "q") {
        return $false
    }

    # Validation de la sélection de clé
    try {
        $keyIndex = [int]$keyChoice
        if ($keyIndex -lt 0 -or $keyIndex -ge $keys.Count) {
            Write-Host "Sélection invalide." -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Sélection invalide." -ForegroundColor Red
        return $false
    }

    $selectedKey = $keys[$keyIndex]
    $currentValue = $IniContent[$selectedSection][$selectedKey]
    $currentType = $currentValue.GetType().Name

    Write-Host "`nModification de la valeur" -ForegroundColor Yellow
    Write-Host "Section: [$selectedSection]" -ForegroundColor Cyan
    Write-Host "Clé: $selectedKey" -ForegroundColor Cyan
    Write-Host "Valeur actuelle: $currentValue ($currentType)" -ForegroundColor Cyan

    # Demande de la nouvelle valeur
    $newValueStr = Read-Host "Nouvelle valeur"

    # Conversion selon le type actuel
    try {
        $newValue = $newValueStr

        switch ($currentType) {
            "Boolean" {
                if ($newValueStr -eq "true" -or $newValueStr -eq "1") {
                    $newValue = $true
                }
                elseif ($newValueStr -eq "false" -or $newValueStr -eq "0") {
                    $newValue = $false
                }
                else {
                    throw "La valeur doit être 'true' ou 'false'"
                }
            }
            "Int32" {
                $newValue = [int]$newValueStr
            }
            "Double" {
                $newValue = [double]$newValueStr
            }
        }

        # Mise à jour de la valeur
        $IniContent[$selectedSection][$selectedKey] = $newValue
        Write-Host "Valeur mise à jour avec succès." -ForegroundColor Green
        $modified = $true
    }
    catch {
        Write-Host "Erreur lors de la conversion de la valeur: $_" -ForegroundColor Red
        return $false
    }

    # Sauvegarde si des modifications ont été effectuées
    if ($modified) {
        Set-IniContent -FilePath $FilePath -Content $IniContent
    }

    return $true
}

function Update-SpecificIniValue {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$IniContent,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$Section,

        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    # Vérification de l'existence de la section
    if (-not $IniContent.ContainsKey($Section)) {
        Write-Error "La section [$Section] n'existe pas dans le fichier INI."
        return $IniContent
    }

    # Vérification de l'existence de la clé
    if (-not $IniContent[$Section].ContainsKey($Key)) {
        Write-Error "La clé '$Key' n'existe pas dans la section [$Section]."
        return $IniContent
    }

    # Détermination du type de la valeur actuelle
    $currentValue = $IniContent[$Section][$Key]
    $currentType = $currentValue.GetType().Name

    # Conversion de la nouvelle valeur selon le type actuel
    try {
        $typedValue = $Value

        switch ($currentType) {
            "Boolean" {
                if ($Value -eq "true" -or $Value -eq "1") {
                    $typedValue = $true
                }
                elseif ($Value -eq "false" -or $Value -eq "0") {
                    $typedValue = $false
                }
                else {
                    throw "La valeur doit être 'true' ou 'false'"
                }
            }
            "Int32" {
                $typedValue = [int]$Value
            }
            "Double" {
                $typedValue = [double]$Value
            }
        }

        # Mise à jour de la valeur
        $IniContent[$Section][$Key] = $typedValue
        Write-Host "Valeur mise à jour: [$Section] $Key = $typedValue" -ForegroundColor Green

        # Sauvegarde du fichier
        Set-IniContent -FilePath $FilePath -Content $IniContent
    }
    catch {
        Write-Error "Erreur lors de la mise à jour de la valeur: $_"
    }

    return $IniContent
}

#endregion

#region Exécution principale

# Vérification de l'action demandée
switch ($Action) {
    "Create" {
        Write-Host "Création d'un fichier INI exemple..." -ForegroundColor Yellow
        $iniContent = New-ExampleIniFile -FilePath $ConfigPath
        Show-IniContent -IniContent $iniContent
    }
    "Read" {
        Write-Host "Lecture du fichier INI..." -ForegroundColor Yellow
        $iniContent = Get-IniContent -FilePath $ConfigPath

        if ($null -ne $iniContent) {
            Show-IniContent -IniContent $iniContent
        }
    }
    "Update" {
        # Exemple de mise à jour d'une valeur spécifique
        Write-Host "Mise à jour d'une valeur spécifique..." -ForegroundColor Yellow

        $section = Read-Host "Section"
        $key = Read-Host "Clé"
        $value = Read-Host "Nouvelle valeur"

        $iniContent = Get-IniContent -FilePath $ConfigPath

        if ($null -ne $iniContent) {
            $iniContent = Update-SpecificIniValue -IniContent $iniContent -FilePath $ConfigPath -Section $section -Key $key -Value $value

            Write-Host "`nContenu mis à jour:" -ForegroundColor Cyan
            Show-IniContent -IniContent $iniContent
        }
    }
    "Edit" {
        Write-Host "Ouverture de l'éditeur de configuration..." -ForegroundColor Yellow

        # Création du fichier s'il n'existe pas
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Host "Le fichier n'existe pas. Création d'un exemple..." -ForegroundColor Yellow
            $iniContent = New-ExampleIniFile -FilePath $ConfigPath
        }
        else {
            $iniContent = Get-IniContent -FilePath $ConfigPath
        }

        if ($null -ne $iniContent) {
            # Interface d'édition interactive
            $editing = $true
            while ($editing) {
                $result = Edit-IniContent -IniContent $iniContent -FilePath $ConfigPath

                # Demande si l'utilisateur souhaite continuer l'édition
                if ($result) {
                    $continue = Read-Host "Continuer l'édition? (O/N)"
                    $editing = ($continue -eq "O" -or $continue -eq "o" -or $continue -eq "Oui" -or $continue -eq "yes" -or $continue -eq "y")
                }
                else {
                    # Si une erreur s'est produite, demander si l'utilisateur souhaite réessayer
                    $retry = Read-Host "Réessayer? (O/N)"
                    $editing = ($retry -eq "O" -or $retry -eq "o" -or $retry -eq "Oui" -or $retry -eq "yes" -or $retry -eq "y")
                }
            }
        }
    }
    "Show" {
        # Affichage du menu principal
        Write-Host "Gestionnaire de configuration INI" -ForegroundColor Cyan
        Write-Host "-----------------------------" -ForegroundColor Cyan
        Write-Host "[1] Créer un fichier INI exemple" -ForegroundColor Yellow
        Write-Host "[2] Lire et afficher un fichier INI" -ForegroundColor Yellow
        Write-Host "[3] Mettre à jour une valeur spécifique" -ForegroundColor Yellow
        Write-Host "[4] Éditer interactivement la configuration" -ForegroundColor Yellow
        Write-Host "[q] Quitter" -ForegroundColor Gray

        $choice = Read-Host "`nChoisissez une action"

        switch ($choice) {
            "1" { & $PSCommandPath -Action Create -ConfigPath $ConfigPath }
            "2" { & $PSCommandPath -Action Read -ConfigPath $ConfigPath }
            "3" { & $PSCommandPath -Action Update -ConfigPath $ConfigPath }
            "4" { & $PSCommandPath -Action Edit -ConfigPath $ConfigPath }
            "q" { Write-Host "Au revoir!" -ForegroundColor Cyan }
            default { Write-Host "Choix invalide." -ForegroundColor Red }
        }
    }
}

#endregion
```

## Utilisation

1. Sauvegardez le script ci-dessus dans un fichier nommé `Exercice3-ConfigINI.ps1`
2. Exécutez le script sans paramètres pour afficher le menu principal:
   ```powershell
   .\Exercice3-ConfigINI.ps1
   ```
3. Créez un fichier INI exemple:
   ```powershell
   .\Exercice3-ConfigINI.ps1 -Action Create
   ```
4. Lisez et affichez un fichier INI existant:
   ```powershell
   .\Exercice3-ConfigINI.ps1 -Action Read
   ```
5. Modifiez une valeur spécifique:
   ```powershell
   .\Exercice3-ConfigINI.ps1 -Action Update
   ```
6. Éditez interactivement la configuration:
   ```powershell
   .\Exercice3-ConfigINI.ps1 -Action Edit
   ```

## Points d'apprentissage
- Création de fonctions pour lire, écrire et modifier des fichiers INI
- Conversion de types entre chaînes de caractères et types natifs PowerShell
- Mise en œuvre d'une interface utilisateur textuelle interactive
- Manipulation de collections complexes (hashtables imbriquées)
- Formatage coloré des sorties pour une meilleure lisibilité
- Structure modulaire d'un script avec sections et fonctions bien organisées

# Exercice 4 - Hiérarchie de configuration multi-sources

## Énoncé
Créez un module PowerShell qui implémente un système de configuration hiérarchique capable de:
1. Charger des paramètres à partir de plusieurs sources (JSON, ENV, arguments)
2. Établir une priorité entre ces sources de configuration
3. Fusionner les configurations selon la hiérarchie définie
4. Fournir une interface simple pour accéder aux paramètres

## Solution

```powershell
<#
.SYNOPSIS
    Module de gestion de configuration hiérarchique.
.DESCRIPTION
    Ce module permet de charger des paramètres de configuration depuis plusieurs sources
    (valeurs par défaut, fichier JSON, variables d'environnement et arguments) et les
    fusionne selon une hiérarchie définie. Il fournit une interface simple pour accéder
    aux paramètres de configuration consolidés.
.EXAMPLE
    # Importation du module
    Import-Module .\ConfigManager.psm1

    # Initialisation avec valeurs par défaut
    Initialize-Config -DefaultConfig @{
        "AppName" = "MonApplication"
        "LogLevel" = "Information"
        "Database" = @{
            "Server" = "localhost"
            "Port" = 1433
        }
    }

    # Chargement d'un fichier JSON
    Add-ConfigSource -JsonPath ".\config.json"

    # Chargement des variables d'environnement
    Add-ConfigSource -Environment -EnvPrefix "APP_"

    # Ajout d'arguments spécifiques
    Add-ConfigSource -Args @{
        "LogLevel" = "Debug"
    }

    # Récupération d'un paramètre
    $logLevel = Get-ConfigValue -Name "LogLevel"
    $dbServer = Get-ConfigValue -Name "Database.Server"
#>

#region Variables globales du module

# Stockage des configurations par source
$script:ConfigSources = @{
    "Default" = @{}     # Valeurs par défaut (priorité la plus basse)
    "Json" = @{}        # Fichier de configuration JSON
    "Environment" = @{} # Variables d'environnement
    "Arguments" = @{}   # Arguments passés directement (priorité la plus haute)
}

# Ordre de priorité (du plus bas au plus haut)
$script:SourcePriority = @("Default", "Json", "Environment", "Arguments")

# Cache de la configuration fusionnée
$script:MergedConfig = $null

# Indique si le module a été initialisé
$script:Initialized = $false

# Préfixe pour les variables d'environnement
$script:EnvPrefix = "APP_"

#endregion

#region Fonctions utilitaires internes

# Fonction pour fusionner deux hashtables récursivement
function script:Merge-Hashtables {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Base,

        [Parameter(Mandatory = $true)]
        [hashtable]$Overlay
    )

    $result = $Base.Clone()

    foreach ($key in $Overlay.Keys) {
        if ($result.ContainsKey($key) -and
            $result[$key] -is [hashtable] -and
            $Overlay[$key] -is [hashtable]) {
            # Fusion récursive pour les sous-hashtables
            $result[$key] = script:Merge-Hashtables -Base $result[$key] -Overlay $Overlay[$key]
        }
        else {
            # Remplacement ou ajout simple
            $result[$key] = $Overlay[$key]
        }
    }

    return $result
}

# Fonction pour convertir un PSCustomObject en hashtable
function script:ConvertTo-Hashtable {
    param (
        [Parameter(Mandatory = $true)]
        [object]$InputObject
    )

    $hashtable = @{}

    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        $properties = Get-Member -InputObject $InputObject -MemberType NoteProperty

        foreach ($property in $properties) {
            $key = $property.Name
            $value = $InputObject.$key

            if ($value -is [System.Management.Automation.PSCustomObject]) {
                $hashtable[$key] = script:ConvertTo-Hashtable -InputObject $value
            }
            elseif ($value -is [System.Collections.IEnumerable] -and $value -isnot [string]) {
                $list = @()
                foreach ($item in $value) {
                    if ($item -is [System.Management.Automation.PSCustomObject]) {
                        $list += script:ConvertTo-Hashtable -InputObject $item
                    }
                    else {
                        $list += $item
                    }
                }
                $hashtable[$key] = $list
            }
            else {
                $hashtable[$key] = $value
            }
        }
    }

    return $hashtable
}

# Fonction pour obtenir une valeur à partir d'un chemin séparé par des points
function script:Get-NestedValue {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Hashtable,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $current = $Hashtable
    $segments = $Path -split '\.'

    foreach ($segment in $segments) {
        if (-not $current.ContainsKey($segment)) {
            return $null
        }

        $current = $current[$segment]

        if (-not ($current -is [hashtable]) -and $segments.IndexOf($segment) -lt $segments.Count - 1) {
            return $null
        }
    }

    return $current
}

# Fonction pour fusionner toutes les sources de configuration selon la priorité
function script:Build-MergedConfig {
    $merged = @{}

    foreach ($source in $script:SourcePriority) {
        if ($script:ConfigSources[$source]) {
            $merged = script:Merge-Hashtables -Base $merged -Overlay $script:ConfigSources[$source]
        }
    }

    return $merged
}

# Fonction pour valider l'initialisation du module
function script:Assert-Initialized {
    if (-not $script:Initialized) {
        throw "Le module de configuration n'a pas été initialisé. Appelez Initialize-Config d'abord."
    }
}

#endregion

#region Fonctions publiques du module

<#
.SYNOPSIS
    Initialise le gestionnaire de configuration avec des valeurs par défaut.
.DESCRIPTION
    Cette fonction doit être appelée avant d'utiliser les autres fonctions du module.
    Elle initialise le gestionnaire avec un ensemble de valeurs par défaut.
.PARAMETER DefaultConfig
    Une hashtable contenant les valeurs de configuration par défaut.
.PARAMETER EnvPrefix
    Préfixe à utiliser pour les variables d'environnement. Par défaut: "APP_".
#>
function Initialize-Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$DefaultConfig,

        [Parameter(Mandatory = $false)]
        [string]$EnvPrefix = "APP_"
    )

    # Réinitialisation des sources de configuration
    $script:ConfigSources = @{
        "Default" = $DefaultConfig.Clone()
        "Json" = @{}
        "Environment" = @{}
        "Arguments" = @{}
    }

    # Définition du préfixe pour les variables d'environnement
    $script:EnvPrefix = $EnvPrefix

    # Invalidation du cache
    $script:MergedConfig = $null

    # Marquer comme initialisé
    $script:Initialized = $true

    Write-Verbose "Configuration initialisée avec $(($DefaultConfig.Keys).Count) paramètres par défaut."
}

<#
.SYNOPSIS
    Ajoute une source de configuration.
.DESCRIPTION
    Ajoute une source de configuration (fichier JSON, variables d'environnement ou arguments).
.PARAMETER JsonPath
    Chemin vers un fichier de configuration JSON à charger.
.PARAMETER Environment
    Indique de charger les variables d'environnement comme source de configuration.
.PARAMETER EnvPrefix
    Préfixe pour les variables d'environnement à prendre en compte.
.PARAMETER Args
    Hashtable d'arguments à utiliser comme source de configuration.
#>
function Add-ConfigSource {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Json")]
        [string]$JsonPath,

        [Parameter(Mandatory = $true, ParameterSetName = "Environment")]
        [switch]$Environment,

        [Parameter(Mandatory = $false, ParameterSetName = "Environment")]
        [string]$EnvPrefix,

        [Parameter(Mandatory = $true, ParameterSetName = "Arguments")]
        [hashtable]$Args
    )

    # Vérification de l'initialisation
    script:Assert-Initialized

    # Traitement selon le type de source
    switch ($PSCmdlet.ParameterSetName) {
        "Json" {
            if (-not (Test-Path -Path $JsonPath)) {
                Write-Error "Le fichier JSON '$JsonPath' n'existe pas."
                return
            }

            try {
                $jsonContent = Get-Content -Path $JsonPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
                $jsonHash = script:ConvertTo-Hashtable -InputObject $jsonContent
                $script:ConfigSources["Json"] = $jsonHash
                Write-Verbose "Configuration JSON chargée depuis '$JsonPath'."
            }
            catch {
                Write-Error "Erreur lors de la lecture du fichier JSON: $_"
            }
        }
        "Environment" {
            if ($EnvPrefix) {
                $script:EnvPrefix = $EnvPrefix
            }

            $envConfig = @{}

            # Récupération de toutes les variables d'environnement avec le préfixe
            $envVars = Get-ChildItem -Path Env: | Where-Object { $_.Name -like "$($script:EnvPrefix)*" }

            foreach ($var in $envVars) {
                $key = $var.Name.Substring($script:EnvPrefix.Length)
                $value = $var.Value

                # Conversion en type approprié
                if ($value -eq "true") { $value = $true }
                elseif ($value -eq "false") { $value = $false }
                elseif ($value -match "^\d+$") { $value = [int]$value }
                elseif ($value -match "^\d+\.\d+$") { $value = [double]$value }

                # Support des chemins séparés par des points (Database.Server)
                $segments = $key -split '\.'

                if ($segments.Count -gt 1) {
                    $current = $envConfig

                    for ($i = 0; $i -lt $segments.Count - 1; $i++) {
                        $segment = $segments[$i]

                        if (-not $current.ContainsKey($segment)) {
                            $current[$segment] = @{}
                        }
                        elseif (-not ($current[$segment] -is [hashtable])) {
                            $current[$segment] = @{}
                        }

                        $current = $current[$segment]
                    }

                    $current[$segments[-1]] = $value
                }
                else {
                    $envConfig[$key] = $value
                }
            }

            $script:ConfigSources["Environment"] = $envConfig
            Write-Verbose "Variables d'environnement chargées avec le préfixe '$($script:EnvPrefix)'."
        }
        "Arguments" {
            $script:ConfigSources["Arguments"] = $Args.Clone()
            Write-Verbose "Arguments de configuration ajoutés."
        }
    }

    # Invalidation du cache
    $script:MergedConfig = $null
}

<#
.SYNOPSIS
    Récupère une valeur de configuration.
.DESCRIPTION
    Récupère une valeur de configuration à partir de son nom. Supporte les chemins hiérarchiques
    séparés par des points (par exemple, "Database.Server").
.PARAMETER Name
    Nom du paramètre à récupérer.
.PARAMETER DefaultValue
    Valeur par défaut à retourner si le paramètre n'est pas trouvé.
#>
function Get-ConfigValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $false, Position = 1)]
        [object]$DefaultValue = $null
    )

    # Vérification de l'initialisation
    script:Assert-Initialized

    # Construction ou récupération de la configuration fusionnée
    if ($null -eq $script:MergedConfig) {
        $script:MergedConfig = script:Build-MergedConfig
    }

    # Récupération de la valeur
    $value = script:Get-NestedValue -Hashtable $script:MergedConfig -Path $Name

    if ($null -eq $value) {
        return $DefaultValue
    }

    return $value
}

<#
.SYNOPSIS
    Affiche la configuration actuelle.
.DESCRIPTION
    Affiche la configuration complète fusionnée ou celle d'une source spécifique.
.PARAMETER Source
    Source spécifique à afficher. Si non spécifié, affiche la configuration fusionnée.
.PARAMETER Format
    Format d'affichage (List ou Object).
#>
function Show-Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Json", "Environment", "Arguments", "Merged")]
        [string]$Source = "Merged",

        [Parameter(Mandatory = $false)]
        [ValidateSet("List", "Object")]
        [string]$Format = "List"
    )

    # Vérification de l'initialisation
    script:Assert-Initialized

    $config = $null

    if ($Source -eq "Merged") {
        if ($null -eq $script:MergedConfig) {
            $script:MergedConfig = script:Build-MergedConfig
        }
        $config = $script:MergedConfig
    }
    else {
        $config = $script:ConfigSources[$Source]
    }

    if ($Format -eq "List") {
        Write-Host "Configuration ($Source):" -ForegroundColor Cyan
        Write-Host "---------------------" -ForegroundColor Cyan

        # Fonction récursive pour afficher les valeurs
        function Show-HashTable {
            param (
                [hashtable]$Table,
                [string]$Prefix = ""
            )

            foreach ($key in $Table.Keys | Sort-Object) {
                $value = $Table[$key]

                if ($value -is [hashtable]) {
                    Write-Host "$Prefix$key:" -ForegroundColor Yellow
                    Show-HashTable -Table $value -Prefix "$Prefix    "
                }
                else {
                    $valueType = $value.GetType().Name
                    $valueStr = $value

                    Write-Host "$Prefix$key = " -NoNewline

                    # Coloration selon le type
                    switch ($valueType) {
                        "Boolean" {
                            $color = if ($value) { "Green" } else { "Red" }
                            Write-Host $valueStr -ForegroundColor $color -NoNewline
                        }
                        "Int32" {
                            Write-Host $valueStr -ForegroundColor Magenta -NoNewline
                        }
                        "Double" {
                            Write-Host $valueStr -ForegroundColor Blue -NoNewline
                        }
                        default {
                            Write-Host $valueStr -NoNewline
                        }
                    }

                    # Affichage du type
                    Write-Host " ($valueType)" -ForegroundColor Gray
                }
            }
        }

        Show-HashTable -Table $config
    }
    else {
        # Affichage sous forme d'objet
        $config | ConvertTo-Json -Depth 10
    }
}

<#
.SYNOPSIS
    Exporte la configuration vers un fichier.
.DESCRIPTION
    Exporte la configuration fusionnée vers un fichier JSON.
.PARAMETER FilePath
    Chemin du fichier de sortie.
.PARAMETER IncludeSource
    Indique si la source de chaque valeur doit être incluse dans le fichier.
#>
function Export-Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSource
    )

    # Vérification de l'initialisation
    script:Assert-Initialized

    # Construction ou récupération de la configuration fusionnée
    if ($null -eq $script:MergedConfig) {
        $script:MergedConfig = script:Build-MergedConfig
    }

    try {
        if ($IncludeSource) {
            # Version détaillée avec information sur la source
            $outputConfig = @{}

            # Fonction récursive pour trouver la source de chaque valeur
            function Get-ValueSource {
                param (
                    [string]$Name
                )

                # Parcourir les sources dans l'ordre inverse de priorité
                foreach ($source in ($script:SourcePriority | Sort-Object -Descending)) {
                    $sourceConfig = $script:ConfigSources[$source]
                    $value = script:Get-NestedValue -Hashtable $sourceConfig -Path $Name

                    if ($null -ne $value) {
                        return $source
                    }
                }

                return "Unknown"
            }

            # Fonction récursive pour construire le résultat avec sources
            function Build-ConfigWithSource {
                param (
                    [hashtable]$Config,
                    [string]$Prefix = ""
                )

                $result = @{}

                foreach ($key in $Config.Keys) {
                    $fullKey = if ($Prefix) { "$Prefix.$key" } else { $key }
                    $value = $Config[$key]

                    if ($value -is [hashtable]) {
                        $result[$key] = Build-ConfigWithSource -Config $value -Prefix $fullKey
                    }
                    else {
                        $source = Get-ValueSource -Name $fullKey
                        $result[$key] = @{
                            "Value" = $value
                            "Source" = $source
                        }
                    }
                }

                return $result
            }

            $outputConfig = Build-ConfigWithSource -Config $script:MergedConfig
        }
        else {
            # Version simple sans information de source
            $outputConfig = $script:MergedConfig
        }

        # Écriture du fichier JSON
        $outputConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $FilePath -Encoding UTF8
        Write-Verbose "Configuration exportée vers $FilePath."
    }
    catch {
        Write-Error "Erreur lors de l'exportation de la configuration: $_"
    }
}

#endregion

# Exportation des fonctions du module
Export-ModuleMember -Function Initialize-Config, Add-ConfigSource, Get-ConfigValue, Show-Config, Export-Config
```

## Exemple d'utilisation

Voici un script d'exemple montrant comment utiliser ce module:

```powershell
<#
.SYNOPSIS
    Démontre l'utilisation du module de configuration hiérarchique.
.DESCRIPTION
    Ce script montre comment utiliser le module ConfigManager.psm1 pour gérer
    des configurations à partir de multiples sources.
#>

# Importer le module (assurez-vous qu'il est dans le même répertoire)
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ConfigManager.psm1"
Import-Module $modulePath -Force

# 1. Initialisation avec des valeurs par défaut
$defaultConfig = @{
    "Application" = @{
        "Name" = "DemoApp"
        "Version" = "1.0.0"
        "Environment" = "Development"
        "LogLevel" = "Information"
    }
    "Database" = @{
        "Server" = "localhost"
        "Port" = 1433
        "Name" = "DemoDB"
        "Username" = "sa"
        "UseIntegratedSecurity" = $true
    }
    "Features" = @{
        "EnableLogging" = $true
        "EnableCaching" = $false
        "CacheTimeoutMinutes" = 15
        "MaxConnections" = 10
    }
}

Write-Host "Initialisation de la configuration avec des valeurs par défaut..." -ForegroundColor Cyan
Initialize-Config -DefaultConfig $defaultConfig

# 2. Affichage de la configuration par défaut
Write-Host "`nConfiguration par défaut:" -ForegroundColor Yellow
Show-Config -Source "Default"

# 3. Création d'un fichier de configuration JSON exemple
$jsonConfig = @{
    "Application" = @{
        "Environment" = "Testing"
        "LogLevel" = "Debug"
    }
    "Database" = @{
        "Server" = "db-server-test"
        "Port" = 1433
    }
    "Features" = @{
        "EnableCaching" = $true
        "CacheTimeoutMinutes" = 30
    }
}

$jsonPath = Join-Path -Path $PSScriptRoot -ChildPath "config.json"
$jsonConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

# 4. Ajout de la source de configuration JSON
Write-Host "`nAjout de la configuration JSON..." -ForegroundColor Cyan
Add-ConfigSource -JsonPath $jsonPath

# 5. Définition de quelques variables d'environnement pour la démonstration
$env:APP_APPLICATION_ENVIRONMENT = "Staging"
$env:APP_DATABASE_NAME = "StagingDB"
$env:APP_FEATURES_MAXCONNECTIONS = "20"

# 6. Ajout de la source de configuration d'environnement
Write-Host "`nAjout des variables d'environnement..." -ForegroundColor Cyan
Add-ConfigSource -Environment

# 7. Ajout de quelques arguments avec la priorité la plus élevée
$args = @{
    "Application" = @{
        "Environment" = "Production"  # Cette valeur aura la priorité la plus élevée
    }
}

Write-Host "`nAjout des arguments..." -ForegroundColor Cyan
Add-ConfigSource -Args $args

# 8. Affichage des configurations par source
Write-Host "`nConfiguration JSON:" -ForegroundColor Yellow
Show-Config -Source "Json"

Write-Host "`nConfiguration depuis les variables d'environnement:" -ForegroundColor Yellow
Show-Config -Source "Environment"

Write-Host "`nConfiguration depuis les arguments:" -ForegroundColor Yellow
Show-Config -Source "Arguments"

# 9. Affichage de la configuration fusionnée finale
Write-Host "`nConfiguration fusionnée finale:" -ForegroundColor Green
Show-Config -Source "Merged"

# 10. Récupération de valeurs spécifiques
$appEnv = Get-ConfigValue -Name "Application.Environment"
$dbServer = Get-ConfigValue -Name "Database.Server"
$maxConn = Get-ConfigValue -Name "Features.MaxConnections"
$debugMode = Get-ConfigValue -Name "Features.DebugMode" -DefaultValue $false

Write-Host "`nValeurs spécifiques:" -ForegroundColor Magenta
Write-Host "- Environnement de l'application: $appEnv"
Write-Host "- Serveur de base de données: $dbServer"
Write-Host "- Connexions maximum: $maxConn"
Write-Host "- Mode debug (valeur par défaut): $debugMode"

# 11. Exportation de la configuration
$exportPath = Join-Path -Path $PSScriptRoot -ChildPath "config-export.json"
Export-Config -FilePath $exportPath
Write-Host "`nConfiguration exportée dans: $exportPath" -ForegroundColor Cyan

# 12. Exportation avec sources
$exportDetailedPath = Join-Path -Path $PSScriptRoot -ChildPath "config-export-detailed.json"
Export-Config -FilePath $exportDetailedPath -IncludeSource
Write-Host "Configuration détaillée exportée dans: $exportDetailedPath" -ForegroundColor Cyan

# Nettoyage des variables d'environnement
Remove-Item -Path "Env:APP_APPLICATION_ENVIRONMENT"
Remove-Item -Path "Env:APP_DATABASE_NAME"
Remove-Item -Path "Env:APP_FEATURES_MAXCONNECTIONS"
```

## Points d'apprentissage
- Création d'un module PowerShell complet et réutilisable
- Gestion de configurations hiérarchiques à partir de plusieurs sources
- Fusion récursive d'objets complexes
- Conversion entre différents formats (objet, hashtable, JSON)
- Accès aux paramètres par notation pointée (chemin hiérarchique)
- Gestion des variables d'environnement pour la configuration
- Exportation de configurations avec métadonnées
- Utilisation de portées de script (`$script:`) dans les modules
- Création d'une API simple et cohérente

# Exercice 5 - Sécurisation des informations sensibles

## Énoncé
Créez un script PowerShell qui permet de:
1. Sécuriser des informations sensibles telles que mots de passe et clés API
2. Chiffrer ces informations dans un fichier externe
3. Déchiffrer et utiliser ces informations de façon sécurisée
4. Gérer un coffre-fort simple pour stocker plusieurs secrets

## Solution

```powershell
<#
.SYNOPSIS
    Gestionnaire de secrets pour PowerShell.
.DESCRIPTION
    Ce script permet de créer un coffre-fort simple pour stocker, chiffrer
    et déchiffrer des informations sensibles telles que mots de passe, clés API,
    et autres secrets. Les informations sont stockées dans un fichier chiffré.
.PARAMETER VaultPath
    Chemin vers le fichier du coffre-fort.
.PARAMETER Action
    Action à effectuer: Create, List, Add, Get, Update, Remove, Test.
.PARAMETER SecretName
    Nom du secret à manipuler.
.PARAMETER SecretValue
    Valeur du secret à ajouter ou mettre à jour.
.EXAMPLE
    # Création d'un nouveau coffre-fort
    .\Exercice5-SecretManager.ps1 -Action Create

    # Ajout d'un secret
    .\Exercice5-SecretManager.ps1 -Action Add -SecretName "ApiKey" -SecretValue "abc123xyz"

    # Récupération d'un secret
    .\Exercice5-SecretManager.ps1 -Action Get -SecretName "ApiKey"

    # Liste de tous les secrets
    .\Exercice5-SecretManager.ps1 -Action List

    # Mise à jour d'un secret existant
    .\Exercice5-SecretManager.ps1 -Action Update -SecretName "ApiKey" -SecretValue "newValue"

    # Suppression d'un secret
    .\Exercice5-SecretManager.ps1 -Action Remove -SecretName "ApiKey"

    # Test d'accès au coffre-fort
    .\Exercice5-SecretManager.ps1 -Action Test
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VaultPath = ".\secrets.vault",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Create", "List", "Add", "Get", "Update", "Remove", "Test", "Menu")]
    [string]$Action = "Menu",

    [Parameter(Mandatory = $false)]
    [string]$SecretName,

    [Parameter(Mandatory = $false)]
    [string]$SecretValue
)

#region Fonctions utilitaires

function Initialize-SecretVault {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VaultPath
    )

    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $VaultPath) {
        Write-Warning "Le coffre-fort existe déjà: $VaultPath"
        $confirm = Read-Host "Voulez-vous le réinitialiser? Toutes les données seront perdues. (O/N)"

        if ($confirm -ne "O" -and $confirm -ne "o" -and $confirm -ne "oui" -and $confirm -ne "yes" -and $confirm -ne "y") {
            Write-Host "Opération annulée." -ForegroundColor Yellow
            return $false
        }
    }

    try {
        # Créer un nouvel objet de coffre-fort
        $vault = @{
            "CreatedAt" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "UpdatedAt" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "Secrets" = @{}
        }

        # Sérialiser et chiffrer
        $vaultJson = ConvertTo-Json -InputObject $vault -Depth 5
        $encryptedContent = Protect-VaultContent -Content $vaultJson

        # Enregistrer dans le fichier
        $encryptedContent | Set-Content -Path $VaultPath -Force

        Write-Host "Coffre-fort initialisé avec succès: $VaultPath" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'initialisation du coffre-fort: $_"
        return $false
    }
}

function Protect-VaultContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    try {
        # Convertir la chaîne en tableau d'octets
        $contentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)

        # Convertir en chaîne sécurisée puis chiffrer
        $secureString = ConvertTo-SecureString -String $Content -AsPlainText -Force
        $encryptedString = ConvertFrom-SecureString -SecureString $secureString

        return $encryptedString
    }
    catch {
        throw "Erreur lors du chiffrement du contenu: $_"
    }
}

function Unprotect-VaultContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$EncryptedContent
    )

    try {
        # Convertir la chaîne chiffrée en SecureString
        $secureString = ConvertTo-SecureString -String $EncryptedContent

        # Convertir SecureString en chaîne en clair
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureString)
        $plainContent = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

        return $plainContent
    }
    catch {
        throw "Erreur lors du déchiffrement du contenu: $_"
    }
}

function Get-Vault {
    param (
        [Parameter(Mandatory = $true)]
        [string]$VaultPath
    )

    if (-not (Test-Path -Path $VaultPath)) {
        throw "Le coffre-fort n'existe pas: $VaultPath"
    }

    try {
        # Lire le contenu chiffré
        $encryptedContent = Get-Content -Path $VaultPath -Raw

        # Déchiffrer le contenu
        $vaultJson = Unprotect-VaultContent -EncryptedContent $encryptedContent

        # Désérialiser en objet
        $vault = ConvertFrom-Json -InputObject $vaultJson

        # Convertir le contenu en hashtable
        $vaultHashtable = @{
            "CreatedAt" = $vault.CreatedAt
            "UpdatedAt" = $vault.UpdatedAt
            "Secrets" = @{}
        }

        foreach ($key in $vault.Secrets.PSObject.Properties.Name) {
            $vaultHashtable.Secrets[$key] = $vault.Secrets.$key
        }

        return $vaultHashtable
    }
    catch {
        throw "Erreur lors de la lecture du coffre-fort: $_"
    }
}

function Save-Vault {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Vault,

        [Parameter(Mandatory = $true)]
        [string]$VaultPath
    )

    try {
        # Mettre à jour la date de modification
        $Vault["UpdatedAt"] = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Sérialiser en JSON
        $vaultJson = ConvertTo-Json -InputObject $Vault -Depth 5

        # Chiffrer le contenu
        $encryptedContent = Protect-VaultContent -Content $vaultJson

        # Enregistrer dans le fichier
        $encryptedContent | Set-Content -Path $VaultPath -Force

        return $true
    }
    catch {
        Write-Error "Erreur lors de l'enregistrement du coffre-fort: $_"
        return $false
    }
}

function Add-Secret {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Vault,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ($Vault.Secrets.ContainsKey($Name)) {
        throw "Un secret avec le nom '$Name' existe déjà. Utilisez Update pour le modifier."
    }

    try {
        # Ajouter le secret avec des métadonnées
        $Vault.Secrets[$Name] = @{
            "Value" = $Value
            "CreatedAt" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "UpdatedAt" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        return $true
    }
    catch {
        throw "Erreur lors de l'ajout du secret: $_"
    }
}

function Update-Secret {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Vault,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if (-not $Vault.Secrets.ContainsKey($Name)) {
        throw "Aucun secret trouvé avec le nom '$Name'."
    }

    try {
        # Mettre à jour la valeur et la date de modification
        $Vault.Secrets[$Name].Value = $Value
        $Vault.Secrets[$Name].UpdatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        return $true
    }
    catch {
        throw "Erreur lors de la mise à jour du secret: $_"
    }
}

function Get-Secret {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Vault,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $Vault.Secrets.ContainsKey($Name)) {
        throw "Aucun secret trouvé avec le nom '$Name'."
    }

    return $Vault.Secrets[$Name]
}

function Remove-Secret {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Vault,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if (-not $Vault.Secrets.ContainsKey($Name)) {
        throw "Aucun secret trouvé avec le nom '$Name'."
    }

    try {
        $Vault.Secrets.Remove($Name)
        return $true
    }
    catch {
        throw "Erreur lors de la suppression du secret: $_"
    }
}

function Show-Secrets {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Vault
    )

    Write-Host "Liste des secrets dans le coffre-fort:" -ForegroundColor Cyan
    Write-Host "-----------------------------------" -ForegroundColor Cyan

    if ($Vault.Secrets.Count -eq 0) {
        Write-Host "Aucun secret dans le coffre-fort." -ForegroundColor Yellow
        return
    }

    $i = 0
    foreach ($name in $Vault.Secrets.Keys | Sort-Object) {
        $secret = $Vault.Secrets[$name]
        $i++

        Write-Host "[$i] " -NoNewline -ForegroundColor White
        Write-Host "$name" -NoNewline -ForegroundColor Yellow
        Write-Host " - Créé le: " -NoNewline
        Write-Host $secret.CreatedAt -NoNewline -ForegroundColor Gray
        Write-Host " - Mis à jour le: " -NoNewline
        Write-Host $secret.UpdatedAt -ForegroundColor Gray
    }
}

function Show-Secret {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [hashtable]$Secret,

        [Parameter(Mandatory = $false)]
        [switch]$MaskValue
    )

    Write-Host "Secret: " -NoNewline -ForegroundColor Cyan
    Write-Host $Name -ForegroundColor Yellow
    Write-Host "---------------------" -ForegroundColor Cyan

    if ($MaskValue) {
        $valueLength = $Secret.Value.Length
        $maskedValue = "●" * [Math]::Min(10, $valueLength)

        if ($valueLength > 10) {
            $maskedValue = $maskedValue + " (longueur totale: $valueLength caractères)"
        }

        Write-Host "Valeur: " -NoNewline
        Write-Host $maskedValue -ForegroundColor Magenta
    }
    else {
        Write-Host "Valeur: " -NoNewline
        Write-Host $Secret.Value -ForegroundColor Green
    }

    Write-Host "Créé le: " -NoNewline
    Write-Host $Secret.CreatedAt -ForegroundColor Gray
    Write-Host "Mis à jour le: " -NoNewline
    Write-Host $Secret.UpdatedAt -ForegroundColor Gray
}

#endregion

#region Actions principales

function Invoke-CreateAction {
    Write-Host "Création d'un nouveau coffre-fort..." -ForegroundColor Cyan
    $result = Initialize-SecretVault -VaultPath $VaultPath

    if ($result) {
        Write-Host "Coffre-fort créé avec succès: $VaultPath" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la création du coffre-fort." -ForegroundColor Red
    }
}

function Invoke-ListAction {
    try {
        $vault = Get-Vault -VaultPath $VaultPath
        Show-Secrets -Vault $vault
    }
    catch {
        Write-Error "Erreur: $_"
    }
}

function Invoke-AddAction {
    if ([string]::IsNullOrEmpty($SecretName)) {
        $SecretName = Read-Host "Nom du secret"
    }

    if ([string]::IsNullOrEmpty($SecretValue)) {
        $secureValue = Read-Host "Valeur du secret" -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
        $SecretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    try {
        $vault = Get-Vault -VaultPath $VaultPath
        $result = Add-Secret -Vault $vault -Name $SecretName -Value $SecretValue

        if ($result) {
            $saved = Save-Vault -Vault $vault -VaultPath $VaultPath

            if ($saved) {
                Write-Host "Secret '$SecretName' ajouté avec succès." -ForegroundColor Green
            }
            else {
                Write-Host "Erreur lors de l'enregistrement du coffre-fort." -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Error "Erreur: $_"
    }

    # Nettoyage des variables sensibles
    $SecretValue = $null
    [System.GC]::Collect()
}

function Invoke-GetAction {
    if ([string]::IsNullOrEmpty($SecretName)) {
        $SecretName = Read-Host "Nom du secret à afficher"
    }

    try {
        $vault = Get-Vault -VaultPath $VaultPath
        $secret = Get-Secret -Vault $vault -Name $SecretName

        # Demander si l'utilisateur veut voir la valeur en clair
        $showClear = Read-Host "Afficher la valeur en clair? (O/N)"
        $mask = -not ($showClear -eq "O" -or $showClear -eq "o" -or $showClear -eq "oui" -or $showClear -eq "yes" -or $showClear -eq "y")

        Show-Secret -Name $SecretName -Secret $secret -MaskValue:$mask

        # Option pour copier la valeur dans le presse-papiers
        if (-not $mask) {
            $copyToClipboard = Read-Host "Copier la valeur dans le presse-papiers? (O/N)"

            if ($copyToClipboard -eq "O" -or $copyToClipboard -eq "o" -or $copyToClipboard -eq "oui" -or $copyToClipboard -eq "yes" -or $copyToClipboard -eq "y") {
                Set-Clipboard -Value $secret.Value
                Write-Host "Valeur copiée dans le presse-papiers." -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Error "Erreur: $_"
    }
}

function Invoke-UpdateAction {
    if ([string]::IsNullOrEmpty($SecretName)) {
        $SecretName = Read-Host "Nom du secret à mettre à jour"
    }

    if ([string]::IsNullOrEmpty($SecretValue)) {
        $secureValue = Read-Host "Nouvelle valeur du secret" -AsSecureString
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
        $SecretValue = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    try {
        $vault = Get-Vault -VaultPath $VaultPath
        $result = Update-Secret -Vault $vault -Name $SecretName -Value $SecretValue

        if ($result) {
            $saved = Save-Vault -Vault $vault -VaultPath $VaultPath

            if ($saved) {
                Write-Host "Secret '$SecretName' mis à jour avec succès." -ForegroundColor Green
            }
            else {
                Write-Host "Erreur lors de l'enregistrement du coffre-fort." -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Error "Erreur: $_"
    }

    # Nettoyage des variables sensibles
    $SecretValue = $null
    [System.GC]::Collect()
}

function Invoke-RemoveAction {
    if ([string]::IsNullOrEmpty($SecretName)) {
        $SecretName = Read-Host "Nom du secret à supprimer"
    }

    try {
        $vault = Get-Vault -VaultPath $VaultPath

        # Demander confirmation
        Write-Host "Vous êtes sur le point de supprimer le secret '$SecretName'." -ForegroundColor Yellow
        $confirm = Read-Host "Êtes-vous sûr? Cette action est irréversible. (O/N)"

        if ($confirm -ne "O" -and $confirm -ne "o" -and $confirm -ne "oui" -and $confirm -ne "yes" -and $confirm -ne "y") {
            Write-Host "Suppression annulée." -ForegroundColor Yellow
            return
        }

        $result = Remove-Secret -Vault $vault -Name $SecretName

        if ($result) {
            $saved = Save-Vault -Vault $vault -VaultPath $VaultPath

            if ($saved) {
                Write-Host "Secret '$SecretName' supprimé avec succès." -ForegroundColor Green
            }
            else {
                Write-Host "Erreur lors de l'enregistrement du coffre-fort." -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Error "Erreur: $_"
    }
}

function Invoke-TestAction {
    try {
        Write-Host "Test d'accès au coffre-fort..." -ForegroundColor Cyan
        $vault = Get-Vault -VaultPath $VaultPath

        Write-Host "Succès! Le coffre-fort est accessible." -ForegroundColor Green
        Write-Host "Créé le: $($vault.CreatedAt)" -ForegroundColor Gray
        Write-Host "Dernière mise à jour: $($vault.UpdatedAt)" -ForegroundColor Gray
        Write-Host "Nombre de secrets: $($vault.Secrets.Count)" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Erreur lors de l'accès au coffre-fort: $_"
    }
}

function Show-Menu {
    Clear-Host
    Write-Host "GESTIONNAIRE DE SECRETS POWERSHELL" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    Write-Host "Coffre-fort: $VaultPath"
    Write-Host
    Write-Host "1. Créer un nouveau coffre-fort" -ForegroundColor Yellow
    Write-Host "2. Lister tous les secrets" -ForegroundColor Yellow
    Write-Host "3. Ajouter un nouveau secret" -ForegroundColor Yellow
    Write-Host "4. Afficher un secret" -ForegroundColor Yellow
    Write-Host "5. Mettre à jour un secret" -ForegroundColor Yellow
    Write-Host "6. Supprimer un secret" -ForegroundColor Yellow
    Write-Host "7. Tester l'accès au coffre-fort" -ForegroundColor Yellow
    Write-Host "Q. Quitter" -ForegroundColor Gray
    Write-Host

    $choice = Read-Host "Choisissez une option"

    switch ($choice) {
        "1" { Invoke-CreateAction }
        "2" { Invoke-ListAction }
        "3" { Invoke-AddAction }
        "4" { Invoke-GetAction }
        "5" { Invoke-UpdateAction }
        "6" { Invoke-RemoveAction }
        "7" { Invoke-TestAction }
        "Q" { return $false }
        "q" { return $false }
        default { Write-Host "Option invalide. Veuillez réessayer." -ForegroundColor Red }
    }

    if ($choice -ne "Q" -and $choice -ne "q") {
        Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return $true
    }

    return $false
}

#endregion

#region Exécution principale

# Exécution de l'action spécifiée
switch ($Action) {
    "Create" { Invoke-CreateAction }
    "List" { Invoke-ListAction }
    "Add" { Invoke-AddAction }
    "Get" { Invoke-GetAction }
    "Update" { Invoke-UpdateAction }
    "Remove" { Invoke-RemoveAction }
    "Test" { Invoke-TestAction }
    "Menu" {
        $continue = $true
        while ($continue) {
            $continue = Show-Menu
        }
    }
}

#endregion
```

## Utilisation

1. Sauvegardez le script ci-dessus dans un fichier nommé `Exercice5-SecretManager.ps1`
2. Exécutez le script sans paramètres pour afficher le menu principal:
   ```powershell
   .\Exercice5-SecretManager.ps1
   ```
3. Pour créer un nouveau coffre-fort:
   ```powershell
   .\Exercice5-SecretManager.ps1 -Action Create
   ```
4. Pour ajouter un secret:
   ```powershell
   .\Exercice5-SecretManager.ps1 -Action Add -SecretName "ApiKey" -SecretValue "ma-clé-api-secrète"
   ```
5. Pour obtenir un secret:
   ```powershell
   .\Exercice5-SecretManager.ps1 -Action Get -SecretName "ApiKey"
   ```

## Exemple d'intégration dans un script

Voici comment vous pourriez utiliser ce gestionnaire de secrets dans un autre script:

```powershell
# Chemin vers le script de gestion de secrets
$secretManagerPath = Join-Path -Path $PSScriptRoot -ChildPath "Exercice5-SecretManager.ps1"
$vaultPath = Join-Path -Path $PSScriptRoot -ChildPath "my-secrets.vault"

# Fonction pour obtenir un secret de façon sécurisée
function Get-SecretValue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SecretName
    )

    try {
        # Exécuter le script en mode silencieux pour obtenir le secret
        $output = & $secretManagerPath -VaultPath $vaultPath -Action Get -SecretName $SecretName

        # Extraire la valeur de la sortie (deuxième ligne après "Valeur: ")
        $valueLineIndex = $output.IndexOf("Valeur: ") + 8
        $valueEndIndex = $output.IndexOf("`n", $valueLineIndex)

        if ($valueEndIndex -eq -1) {
            $valueEndIndex = $output.Length
        }

        $secretValue = $output.Substring($valueLineIndex, $valueEndIndex - $valueLineIndex).Trim()
        return $secretValue
    }
    catch {
        Write-Error "Erreur lors de la récupération du secret '$SecretName': $_"
        return $null
    }
}

# Exemple d'utilisation
$apiKey = Get-SecretValue -SecretName "ApiKey"
$databasePassword = Get-SecretValue -SecretName "DbPassword"

# Utilisation des secrets dans le script
if ($apiKey) {
    Write-Host "Connexion à l'API avec la clé récupérée..."
    # Code de connexion à l'API...
}

if ($databasePassword) {
    Write-Host "Connexion à la base de données..."
    # Code de connexion à la BDD...
}
```

## Points d'apprentissage
- Chiffrement et déchiffrement de données sensibles en PowerShell
- Utilisation des classes `SecureString` pour manipuler les mots de passe en mémoire
- Nettoyage des variables sensibles après utilisation
- Gestion d'un magasin de secrets persistant
- Création d'une interface utilisateur interactive en console
- Organisation structurée d'un script complexe
- Gestion des erreurs avec try/catch
- Bonnes pratiques pour la sécurité des informations sensibles
