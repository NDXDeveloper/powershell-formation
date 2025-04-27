### Solutions des exercices pratiques

#### 1. Exercice de base : Variables avec différentes portées

```powershell
# ScopesDemo.ps1

# Définir une variable globale (accessible partout)
$global:variableGlobale = "Je suis une variable globale"

# Définir une variable de script (accessible uniquement dans ce script)
$script:variableScript = "Je suis une variable de script"

# Définir une variable locale (portée par défaut)
$variableLocale = "Je suis une variable locale"

function Test-Scopes {
    # Variable locale à la fonction
    $variableFonction = "Je suis locale à la fonction"

    # Afficher toutes les variables
    Write-Host "=== Dans la fonction Test-Scopes ===" -ForegroundColor Cyan
    Write-Host "Variable globale : $global:variableGlobale" -ForegroundColor Green
    Write-Host "Variable de script : $script:variableScript" -ForegroundColor Yellow
    Write-Host "Variable locale du script : $variableLocale" -ForegroundColor Magenta
    Write-Host "Variable locale de fonction : $variableFonction" -ForegroundColor Blue

    # Tenter de modifier la variable locale du script
    $variableLocale = "Valeur modifiée dans la fonction"
    Write-Host "Variable locale du script modifiée dans la fonction : $variableLocale" -ForegroundColor Magenta

    # Modifier explicitement la variable de script
    $script:variableScript = "Valeur de script modifiée dans la fonction"
}

# Afficher les variables avant appel de fonction
Write-Host "=== Avant appel de fonction ===" -ForegroundColor Cyan
Write-Host "Variable globale : $global:variableGlobale" -ForegroundColor Green
Write-Host "Variable de script : $script:variableScript" -ForegroundColor Yellow
Write-Host "Variable locale : $variableLocale" -ForegroundColor Magenta

# Appeler la fonction
Test-Scopes

# Afficher les variables après appel de fonction
Write-Host "=== Après appel de fonction ===" -ForegroundColor Cyan
Write-Host "Variable globale : $global:variableGlobale" -ForegroundColor Green
Write-Host "Variable de script : $script:variableScript" -ForegroundColor Yellow
Write-Host "Variable locale : $variableLocale" -ForegroundColor Magenta

# Tenter d'accéder à la variable de fonction
Write-Host "`nTentative d'accès à la variable de fonction : " -NoNewline
if (Test-Path variable:variableFonction) {
    Write-Host "$variableFonction" -ForegroundColor Blue
} else {
    Write-Host "Non accessible (comme prévu)" -ForegroundColor Red
}

# Vérifier dans quel scope existent nos variables
Write-Host "`n=== Informations sur les scopes des variables ===" -ForegroundColor Cyan
foreach ($varName in @("variableGlobale", "variableScript", "variableLocale", "variableFonction")) {
    $varInfo = Get-Variable -Name $varName -Scope Global -ErrorAction SilentlyContinue
    if ($varInfo) {
        Write-Host "$varName existe dans le scope Global" -ForegroundColor Green
    } else {
        Write-Host "$varName n'existe pas dans le scope Global" -ForegroundColor Red
    }

    $varInfo = Get-Variable -Name $varName -Scope Script -ErrorAction SilentlyContinue
    if ($varInfo) {
        Write-Host "$varName existe dans le scope Script" -ForegroundColor Yellow
    } else {
        Write-Host "$varName n'existe pas dans le scope Script" -ForegroundColor Red
    }
}
```

#### 2. Exercice intermédiaire : Fonction avec compteur persistant

```powershell
# CompteurPersistant.ps1

function Invoke-FonctionComptee {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Nom,

        [Parameter()]
        [string]$Message = "Exécution"
    )

    # Vérifier si le dictionnaire des compteurs existe
    if (-not (Test-Path variable:script:compteursFonctions)) {
        $script:compteursFonctions = @{}
        Write-Verbose "Initialisation du dictionnaire de compteurs"
    }

    # Vérifier si un compteur existe pour cette fonction
    if (-not $script:compteursFonctions.ContainsKey($Nom)) {
        $script:compteursFonctions[$Nom] = 0
        Write-Verbose "Initialisation du compteur pour la fonction '$Nom'"
    }

    # Incrémenter le compteur
    $script:compteursFonctions[$Nom]++
    $appelsActuels = $script:compteursFonctions[$Nom]

    # Afficher l'information
    Write-Host "[$Nom] Appel #$appelsActuels : $Message" -ForegroundColor Cyan

    # Retourner un objet avec les détails
    [PSCustomObject]@{
        Fonction = $Nom
        NombreAppels = $appelsActuels
        Message = $Message
        DateExecution = Get-Date
    }
}

function Get-StatistiquesAppels {
    [CmdletBinding()]
    param()

    if (-not (Test-Path variable:script:compteursFonctions)) {
        Write-Warning "Aucune fonction n'a encore été exécutée"
        return
    }

    Write-Host "=== Statistiques d'appels des fonctions ===" -ForegroundColor Magenta

    $script:compteursFonctions.GetEnumerator() | Sort-Object Value -Descending | ForEach-Object {
        $pourcentage = if ($script:compteursFonctions.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum) {
            [Math]::Round(($_.Value / ($script:compteursFonctions.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum)) * 100, 1)
        } else {
            0
        }

        $barLength = [Math]::Round($pourcentage / 2)
        $bar = "#" * $barLength

        Write-Host "$($_.Key): " -NoNewline -ForegroundColor Yellow
        Write-Host "$($_.Value) appels " -NoNewline
        Write-Host "($pourcentage%) " -NoNewline -ForegroundColor Green
        Write-Host "$bar" -ForegroundColor Cyan
    }
}

function Reset-StatistiquesAppels {
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='Medium')]
    param(
        [Parameter()]
        [string]$Fonction
    )

    if (-not (Test-Path variable:script:compteursFonctions)) {
        Write-Warning "Aucune fonction n'a encore été exécutée"
        return
    }

    if ($Fonction) {
        if ($script:compteursFonctions.ContainsKey($Fonction)) {
            if ($PSCmdlet.ShouldProcess("Fonction: $Fonction", "Réinitialiser le compteur")) {
                $script:compteursFonctions[$Fonction] = 0
                Write-Host "Compteur réinitialisé pour la fonction '$Fonction'" -ForegroundColor Green
            }
        } else {
            Write-Warning "La fonction '$Fonction' n'a pas de compteur"
        }
    } else {
        if ($PSCmdlet.ShouldProcess("Tous les compteurs", "Réinitialiser")) {
            $script:compteursFonctions.Clear()
            Write-Host "Tous les compteurs ont été réinitialisés" -ForegroundColor Green
        }
    }
}

# Exemples d'utilisation
Invoke-FonctionComptee -Nom "DemoFonction" -Message "Premier appel"
Invoke-FonctionComptee -Nom "DemoFonction" -Message "Deuxième appel"
Invoke-FonctionComptee -Nom "AutreFonction" -Message "Premier appel d'une autre fonction"
Invoke-FonctionComptee -Nom "DemoFonction" -Message "Troisième appel"

# Afficher les statistiques
Get-StatistiquesAppels

# Réinitialiser un compteur spécifique
Reset-StatistiquesAppels -Fonction "DemoFonction"

# Vérifier que le compteur a été réinitialisé
Get-StatistiquesAppels

# Nouvel appel après réinitialisation
Invoke-FonctionComptee -Nom "DemoFonction" -Message "Premier appel après réinitialisation"
Get-StatistiquesAppels
```

#### 3. Exercice avancé : Module avec configuration interne

Créons un module de journalisation (`AdvancedLogger`) avec une configuration interne :

##### 1. Structure du module

```
AdvancedLogger/
├── AdvancedLogger.psm1  # Fichier principal du module
├── AdvancedLogger.psd1  # Manifeste du module
├── Public/              # Fonctions publiques
│   ├── Write-Log.ps1
│   ├── Get-LogConfig.ps1
│   └── Set-LogConfig.ps1
└── Private/             # Fonctions privées
    ├── Initialize-Logger.ps1
    └── Format-LogMessage.ps1
```

##### 2. Contenu du fichier `AdvancedLogger.psm1`

```powershell
# AdvancedLogger.psm1

# Configuration interne du module - accessible uniquement par les fonctions du module
$script:logConfig = @{
    LogPath = "$env:TEMP\AdvancedLogger.log"
    Level = "INFO"      # DEBUG, INFO, WARNING, ERROR, FATAL
    Format = "{0} [{1}] {2}"  # Date, Level, Message
    MaxSize = 10MB
    KeepLogFiles = 5
    Silent = $false
    IncludeSource = $true
    TimestampFormat = "yyyy-MM-dd HH:mm:ss"
}

# Variables internes pour le fonctionnement du module
$script:logLevels = @{
    DEBUG = 0
    INFO = 1
    WARNING = 2
    ERROR = 3
    FATAL = 4
}

$script:logLevelColors = @{
    DEBUG = "Gray"
    INFO = "White"
    WARNING = "Yellow"
    ERROR = "Red"
    FATAL = "DarkRed"
}

# Importer toutes les fonctions privées
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" | ForEach-Object {
    . $_.FullName
}

# Importer toutes les fonctions publiques
$publicFunctions = @()
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
    . $_.FullName
    $publicFunctions += $_.BaseName
}

# Initialiser le logger au chargement du module
Initialize-Logger

# Exporter uniquement les fonctions publiques
Export-ModuleMember -Function $publicFunctions
```

##### 3. Contenu du fichier `Private\Initialize-Logger.ps1`

```powershell
# Private\Initialize-Logger.ps1

function Initialize-Logger {
    [CmdletBinding()]
    param()

    # Vérifier si le répertoire de log existe
    $logDir = Split-Path -Path $script:logConfig.LogPath -Parent

    if (-not (Test-Path -Path $logDir -PathType Container)) {
        try {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            Write-Verbose "Répertoire de logs créé : $logDir"
        }
        catch {
            Write-Error "Impossible de créer le répertoire de logs: $_"
        }
    }

    # Rotation des logs si nécessaire
    if (Test-Path -Path $script:logConfig.LogPath) {
        $logFileInfo = Get-Item -Path $script:logConfig.LogPath

        if ($logFileInfo.Length -gt $script:logConfig.MaxSize) {
            Rotate-LogFiles
        }
    }

    # Écrire l'en-tête initial du fichier de log s'il n'existe pas
    if (-not (Test-Path -Path $script:logConfig.LogPath)) {
        $header = @"
# AdvancedLogger - Fichier de log
# Créé le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm:ss")
# ------------------------------------------

"@
        $header | Out-File -FilePath $script:logConfig.LogPath -Encoding utf8

        # Premier message de log
        $timestamp = Get-Date -Format $script:logConfig.TimestampFormat
        $message = "Service de journalisation initialisé"
        $formattedMessage = $script:logConfig.Format -f $timestamp, "INFO", $message

        $formattedMessage | Out-File -FilePath $script:logConfig.LogPath -Encoding utf8 -Append
    }
}

function Rotate-LogFiles {
    [CmdletBinding()]
    param()

    $logPath = $script:logConfig.LogPath
    $logDir = Split-Path -Path $logPath -Parent
    $logName = Split-Path -Path $logPath -Leaf
    $logBaseName = [System.IO.Path]::GetFileNameWithoutExtension($logName)
    $logExtension = [System.IO.Path]::GetExtension($logName)

    # Déplacer les anciens fichiers de log
    for ($i = $script:logConfig.KeepLogFiles - 1; $i -ge 1; $i--) {
        $oldLogFile = Join-Path -Path $logDir -ChildPath "$logBaseName.$i$logExtension"
        $newLogFile = Join-Path -Path $logDir -ChildPath "$logBaseName.$($i+1)$logExtension"

        if (Test-Path -Path $oldLogFile) {
            Move-Item -Path $oldLogFile -Destination $newLogFile -Force
        }
    }

    # Renommer le fichier de log actuel
    $newLogFile = Join-Path -Path $logDir -ChildPath "$logBaseName.1$logExtension"
    Move-Item -Path $logPath -Destination $newLogFile -Force

    # Créer un nouveau fichier de log vide
    $header = @"
# AdvancedLogger - Fichier de log
# Créé le $(Get-Date -Format "yyyy-MM-dd") à $(Get-Date -Format "HH:mm:ss")
# Rotation effectuée - Ancien log archivé sous $newLogFile
# ------------------------------------------

"@
    $header | Out-File -FilePath $logPath -Encoding utf8
}
```

##### 4. Contenu du fichier `Private\Format-LogMessage.ps1`

```powershell
# Private\Format-LogMessage.ps1

function Format-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$true)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "FATAL")]
        [string]$Level,

        [Parameter()]
        [string]$Source = ""
    )

    $timestamp = Get-Date -Format $script:logConfig.TimestampFormat

    if ($script:logConfig.IncludeSource -and -not [string]::IsNullOrEmpty($Source)) {
        $formattedLevel = "$Level [$Source]"
    } else {
        $formattedLevel = $Level
    }

    $formattedMessage = $script:logConfig.Format -f $timestamp, $formattedLevel, $Message

    return $formattedMessage
}
```

##### 5. Contenu du fichier `Public\Write-Log.ps1`

```powershell
# Public\Write-Log.ps1

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Message,

        [Parameter(Position=1)]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "FATAL")]
        [string]$Level = "INFO",

        [Parameter()]
        [switch]$NoConsole,

        [Parameter()]
        [string]$Source = ""
    )

    process {
        # Vérifier si le niveau de log est suffisant
        if ($script:logLevels[$Level] -ge $script:logLevels[$script:logConfig.Level]) {
            # Obtenir les informations d'appel si la source n'est pas spécifiée
            if ([string]::IsNullOrEmpty($Source) -and $script:logConfig.IncludeSource) {
                $callStack = Get-PSCallStack
                if ($callStack.Count -gt 1) {
                    $caller = $callStack[1]
                    $Source = if ($caller.Command -eq "<ScriptBlock>") {
                        Split-Path -Leaf $caller.ScriptName
                    } else {
                        $caller.Command
                    }
                }
            }

            # Formater le message
            $formattedMessage = Format-LogMessage -Message $Message -Level $Level -Source $Source

            # Écrire dans le fichier de log
            $formattedMessage | Out-File -FilePath $script:logConfig.LogPath -Encoding utf8 -Append

            # Afficher dans la console si demandé
            if (-not $NoConsole -and -not $script:logConfig.Silent) {
                Write-Host $formattedMessage -ForegroundColor $script:logLevelColors[$Level]
            }

            # Pour les erreurs fatales, générer une véritable erreur PowerShell
            if ($Level -eq "FATAL") {
                throw $Message
            }
        }
    }
}
```

##### 6. Contenu du fichier `Public\Get-LogConfig.ps1`

```powershell
# Public\Get-LogConfig.ps1

function Get-LogConfig {
    [CmdletBinding()]
    param()

    # Retourner une copie de la configuration pour éviter la modification directe
    [PSCustomObject]@{
        LogPath = $script:logConfig.LogPath
        Level = $script:logConfig.Level
        Format = $script:logConfig.Format
        MaxSize = $script:logConfig.MaxSize
        KeepLogFiles = $script:logConfig.KeepLogFiles
        Silent = $script:logConfig.Silent
        IncludeSource = $script:logConfig.IncludeSource
        TimestampFormat = $script:logConfig.TimestampFormat
        CurrentLogSize = if (Test-Path -Path $script:logConfig.LogPath) {
            (Get-Item -Path $script:logConfig.LogPath).Length
        } else {
            0
        }
        AvailableLevels = $script:logLevels.Keys
    }
}
```

##### 7. Contenu du fichier `Public\Set-LogConfig.ps1`

```powershell
# Public\Set-LogConfig.ps1

function Set-LogConfig {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$LogPath,

        [Parameter()]
        [ValidateSet("DEBUG", "INFO", "WARNING", "ERROR", "FATAL")]
        [string]$Level,

        [Parameter()]
        [string]$Format,

        [Parameter()]
        [ValidateScript({$_ -gt 0})]
        [long]$MaxSize,

        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$KeepLogFiles,

        [Parameter()]
        [bool]$Silent,

        [Parameter()]
        [bool]$IncludeSource,

        [Parameter()]
        [string]$TimestampFormat
    )

    # Mettre à jour les paramètres spécifiés
    if ($PSBoundParameters.ContainsKey('LogPath')) {
        $script:logConfig.LogPath = $LogPath

        # Vérifier et créer le répertoire si nécessaire
        $logDir = Split-Path -Path $LogPath -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
    }

    if ($PSBoundParameters.ContainsKey('Level')) { $script:logConfig.Level = $Level }
    if ($PSBoundParameters.ContainsKey('Format')) { $script:logConfig.Format = $Format }
    if ($PSBoundParameters.ContainsKey('MaxSize')) { $script:logConfig.MaxSize = $MaxSize }
    if ($PSBoundParameters.ContainsKey('KeepLogFiles')) { $script:logConfig.KeepLogFiles = $KeepLogFiles }
    if ($PSBoundParameters.ContainsKey('Silent')) { $script:logConfig.Silent = $Silent }
    if ($PSBoundParameters.ContainsKey('IncludeSource')) { $script:logConfig.IncludeSource = $IncludeSource }
    if ($PSBoundParameters.ContainsKey('TimestampFormat')) { $script:logConfig.TimestampFormat = $TimestampFormat }

    # Écrire un message de log pour indiquer le changement de configuration
    if ($PSBoundParameters.Count -gt 0) {
        $changedParams = ($PSBoundParameters.Keys | Where-Object { $_ -ne 'Verbose' -and $_ -ne 'Debug' }) -join ', '
        Write-Log -Message "Configuration du logger modifiée : $changedParams" -Level "INFO"
    }

    # Retourner la configuration mise à jour
    Get-LogConfig
}
```

##### 8. Exemple d'utilisation du module

```powershell
# Importer le module
Import-Module .\AdvancedLogger

# Afficher la configuration actuelle
Get-LogConfig

# Modifier la configuration
Set-LogConfig -Level "DEBUG" -IncludeSource $true

# Écrire des logs à différents niveaux
Write-Log "Ceci est un message d'information" -Level INFO
Write-Log "Attention, quelque chose d'inhabituel s'est produit" -Level WARNING
Write-Log "Une erreur est survenue dans le traitement" -Level ERROR
Write-Log "Détails de débogage" -Level DEBUG -Source "MonScript.ps1"

# Changer le chemin du fichier de log
Set-LogConfig -LogPath "C:\Logs\MonApplication.log"

# Écrire un message avec une source personnalisée
Write-Log "Opération terminée avec succès" -Source "ModuleTraitement"
```

##### 9. Création du manifeste du module

```powershell
# Créer le manifeste du module
New-ModuleManifest -Path ".\AdvancedLogger.psd1" `
                  -RootModule "AdvancedLogger.psm1" `
                  -ModuleVersion "1.0.0" `
                  -Author "Votre Nom" `
                  -Description "Module avancé de journalisation avec configuration interne" `
                  -PowerShellVersion "5.1" `
                  -FunctionsToExport @('Write-Log', 'Get-LogConfig', 'Set-LogConfig') `
                  -Tags @('logging', 'journal', 'debug')
```


