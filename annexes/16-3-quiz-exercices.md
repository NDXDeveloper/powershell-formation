# 16-3. Quiz et exercices corrigés par niveau

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📚 Introduction

Cette section contient une série de quiz et d'exercices pratiques pour vous aider à assimiler les connaissances acquises tout au long de cette formation PowerShell. Les exercices sont organisés par niveau de difficulté (débutant, intermédiaire et avancé) pour vous permettre de progresser à votre rythme.

Chaque exercice est accompagné de sa correction détaillée avec des explications. N'hésitez pas à essayer de résoudre les exercices par vous-même avant de consulter les solutions !

---

## 🟢 Niveau Débutant

### Quiz 1 : Les bases de PowerShell

1. **Question**: Quelle commande permet d'obtenir de l'aide sur une cmdlet PowerShell ?
   - A) `Help-Get`
   - B) `Get-Help`
   - C) `Show-Help`
   - D) `Find-Help`

   **Réponse**: B) `Get-Help`

   **Explication**: `Get-Help` est la cmdlet qui vous permet d'accéder à l'aide intégrée de PowerShell. Vous pouvez l'utiliser pour obtenir des informations sur n'importe quelle cmdlet, par exemple : `Get-Help Get-Process` ou simplement `help Get-Process`.

2. **Question**: Quelle est la convention de nommage des cmdlets PowerShell ?
   - A) Action-Objet
   - B) Objet-Action
   - C) Verbe-Nom
   - D) Nom-Verbe

   **Réponse**: C) Verbe-Nom

   **Explication**: Les cmdlets PowerShell suivent une convention de nommage Verbe-Nom. Par exemple, `Get-Process` (obtenir des processus), `Start-Service` (démarrer un service), etc. Cette convention rend les commandes plus intuitives et prévisibles.

3. **Question**: Quel caractère est utilisé pour le pipeline en PowerShell ?
   - A) `>`
   - B) `|`
   - C) `>>`
   - D) `/`

   **Réponse**: B) `|`

   **Explication**: Le caractère `|` (pipe) permet de passer la sortie d'une commande comme entrée à une autre commande. Par exemple : `Get-Process | Sort-Object CPU`.

### Exercice 1 : Premiers pas avec PowerShell

**Objectif**: Créer un script simple qui affiche les 5 processus consommant le plus de mémoire sur votre système.

**Instructions**:
1. Créez un nouveau fichier avec l'extension `.ps1`
2. Écrivez le code pour obtenir la liste des processus
3. Triez ces processus par utilisation de mémoire (RAM)
4. Limitez l'affichage aux 5 premiers
5. Affichez uniquement le nom du processus et la mémoire utilisée

**Solution**:
```powershell
# top-memory-processes.ps1
Get-Process |
    Sort-Object -Property WorkingSet -Descending |
    Select-Object -First 5 -Property Name, @{Name="MemoryMB"; Expression={$_.WorkingSet / 1MB -as [int]}} |
    Format-Table -AutoSize
```

**Explication**:
- `Get-Process` retourne tous les processus en cours d'exécution
- `Sort-Object -Property WorkingSet -Descending` trie les processus par consommation mémoire (WorkingSet) du plus grand au plus petit
- `Select-Object -First 5` limite la sortie aux 5 premiers résultats
- L'expression calculée `@{Name="MemoryMB"; Expression={$_.WorkingSet / 1MB -as [int]}}` convertit la mémoire de bytes en mégabytes
- `Format-Table -AutoSize` améliore l'affichage en console

### Exercice 2 : Manipulation de fichiers

**Objectif**: Créer un script qui liste tous les fichiers `.log` dans un répertoire spécifique, affiche leur taille et leur date de dernière modification.

**Instructions**:
1. Créez un nouveau fichier `.ps1`
2. Écrivez le code pour rechercher tous les fichiers `.log` dans le répertoire `C:\Logs` (ou créez ce répertoire s'il n'existe pas)
3. Pour chaque fichier, affichez son nom, sa taille en KB et sa date de dernière modification

**Solution**:
```powershell
# list-log-files.ps1

# Créer le répertoire s'il n'existe pas
$logPath = "C:\Logs"
if (-not (Test-Path -Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory
    # Créons quelques fichiers de test
    "Test log content" | Out-File -FilePath "$logPath\test1.log"
    "Another log file" | Out-File -FilePath "$logPath\test2.log"
    "Third log entry" | Out-File -FilePath "$logPath\application.log"
}

# Obtenir et afficher les fichiers log
Get-ChildItem -Path $logPath -Filter "*.log" |
    Select-Object Name,
                 @{Name="Size (KB)"; Expression={"{0:N2}" -f ($_.Length / 1KB)}},
                 LastWriteTime |
    Format-Table -AutoSize
```

**Explication**:
- `Test-Path` vérifie si le répertoire existe
- `New-Item` crée le répertoire s'il n'existe pas
- `Get-ChildItem` avec le filtre `*.log` trouve tous les fichiers .log
- L'expression calculée convertit la taille en KB et la formate avec 2 décimales
- `Format-Table` améliore l'affichage des résultats

---

## 🟠 Niveau Intermédiaire

### Quiz 2 : Structures et objets PowerShell

1. **Question**: Quelle instruction permet de créer un objet personnalisé en PowerShell ?
   - A) `New-Object -TypeName PSObject`
   - B) `[PSCustomObject]@{}`
   - C) `Create-PSObject`
   - D) `New-PSCustomObject`

   **Réponse**: B) `[PSCustomObject]@{}`

   **Explication**: La syntaxe `[PSCustomObject]@{}` est la méthode moderne et privilégiée pour créer des objets personnalisés en PowerShell. À l'intérieur des accolades, vous pouvez définir les propriétés et leurs valeurs.

2. **Question**: Comment récupérer uniquement les propriétés spécifiques d'un objet ?
   - A) `Get-Properties`
   - B) `Filter-Object`
   - C) `Select-Object`
   - D) `Where-Object`

   **Réponse**: C) `Select-Object`

   **Explication**: `Select-Object` permet de choisir les propriétés spécifiques d'un objet que vous souhaitez conserver. Par exemple : `Get-Process | Select-Object Name, CPU, WorkingSet`.

3. **Question**: Quelle méthode permet de filtrer des objets selon une condition en PowerShell ?
   - A) `Filter-Object`
   - B) `Where-Object`
   - C) `Select-Where`
   - D) `Find-Object`

   **Réponse**: B) `Where-Object`

   **Explication**: `Where-Object` (souvent abrégé en `where` ou `?`) permet de filtrer des objets selon une condition. Par exemple : `Get-Service | Where-Object {$_.Status -eq "Running"}`.

### Exercice 3 : Traitement par lots de fichiers

**Objectif**: Créer un script qui recherche tous les fichiers image (jpg, png, gif) dans un dossier et ses sous-dossiers, puis crée un rapport sur leur nombre, taille totale et types.

**Instructions**:
1. Créez un script qui accepte un paramètre pour le chemin du dossier à analyser
2. Recherchez récursivement tous les fichiers avec les extensions .jpg, .png et .gif
3. Créez un rapport avec:
   - Nombre total de fichiers par type
   - Taille totale par type d'image
   - Les 5 plus gros fichiers avec leur chemin complet

**Solution**:
```powershell
# image-analyzer.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath
)

# Vérifier si le chemin existe
if (-not (Test-Path -Path $FolderPath)) {
    Write-Error "Le dossier spécifié n'existe pas: $FolderPath"
    exit 1
}

# Récupérer tous les fichiers images
$imageFiles = Get-ChildItem -Path $FolderPath -Include "*.jpg","*.png","*.gif" -Recurse -File

# Si aucun fichier trouvé
if ($imageFiles.Count -eq 0) {
    Write-Output "Aucun fichier image trouvé dans le dossier spécifié."
    exit 0
}

# Grouper par extension
$groupedByType = $imageFiles | Group-Object -Property Extension

# Créer le rapport
Write-Output "=== RAPPORT D'ANALYSE DES IMAGES ==="
Write-Output "Dossier analysé: $FolderPath"
Write-Output "Date d'analyse: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Output ""
Write-Output "=== RÉSUMÉ PAR TYPE ==="

foreach ($group in $groupedByType) {
    $totalSize = ($group.Group | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Output "$($group.Name): $($group.Count) fichiers - Taille totale: $("{0:N2}" -f $totalSize) MB"
}

Write-Output ""
Write-Output "=== LES 5 PLUS GROS FICHIERS ==="

$imageFiles |
    Sort-Object -Property Length -Descending |
    Select-Object -First 5 -Property FullName, @{Name="Size (MB)"; Expression={"{0:N2}" -f ($_.Length / 1MB)}} |
    Format-Table -AutoSize
```

**Explication**:
- Le paramètre `$FolderPath` est obligatoire grâce à l'attribut `[Parameter(Mandatory=$true)]`
- `Get-ChildItem` avec `-Recurse` analyse les sous-dossiers
- `-Include` filtre uniquement les extensions spécifiées
- `Group-Object` regroupe les fichiers par extension
- `Measure-Object` avec `-Sum` calcule la taille totale
- Le formatage convertit les tailles en MB avec 2 décimales

### Exercice 4 : Fonctions et paramètres

**Objectif**: Créer une fonction avancée qui génère des mots de passe aléatoires selon des critères spécifiés.

**Instructions**:
1. Créez une fonction nommée `New-RandomPassword`
2. Ajoutez les paramètres suivants:
   - `Length`: longueur du mot de passe (par défaut: 12)
   - `IncludeSpecialChars`: si des caractères spéciaux doivent être inclus (par défaut: $true)
   - `IncludeNumbers`: si des chiffres doivent être inclus (par défaut: $true)
   - `IncludeUppercase`: si des majuscules doivent être inclues (par défaut: $true)
3. La fonction doit retourner un mot de passe aléatoire respectant les critères

**Solution**:
```powershell
# password-generator.ps1

function New-RandomPassword {
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateRange(8, 128)]
        [int]$Length = 12,

        [Parameter()]
        [switch]$IncludeSpecialChars = $true,

        [Parameter()]
        [switch]$IncludeNumbers = $true,

        [Parameter()]
        [switch]$IncludeUppercase = $true
    )

    # Définir les ensembles de caractères
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '0123456789'
    $special = '!@#$%^&*()-_=+[]{}|;:,.<>?/~'

    # Commencer avec les lettres minuscules (toujours incluses)
    $chars = $lowercase

    # Ajouter les autres ensembles selon les paramètres
    if ($IncludeUppercase) { $chars += $uppercase }
    if ($IncludeNumbers) { $chars += $numbers }
    if ($IncludeSpecialChars) { $chars += $special }

    # Générer le mot de passe
    $password = ''
    $random = New-Object System.Random

    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[$random.Next(0, $chars.Length)]
    }

    # Vérifier que le mot de passe respecte tous les critères demandés
    $hasLower = $password -cmatch '[a-z]'
    $hasUpper = $password -cmatch '[A-Z]'
    $hasDigit = $password -cmatch '[0-9]'
    $hasSpecial = $password -match '[^a-zA-Z0-9]'

    # Si un critère n'est pas respecté, générer un nouveau mot de passe
    if (($IncludeUppercase -and -not $hasUpper) -or
        ($IncludeNumbers -and -not $hasDigit) -or
        ($IncludeSpecialChars -and -not $hasSpecial) -or
        -not $hasLower) {
        return New-RandomPassword -Length $Length -IncludeSpecialChars:$IncludeSpecialChars -IncludeNumbers:$IncludeNumbers -IncludeUppercase:$IncludeUppercase
    }

    return $password
}

# Exemples d'utilisation
Write-Output "Mot de passe par défaut (12 caractères, tous les types): $(New-RandomPassword)"
Write-Output "Mot de passe de 16 caractères: $(New-RandomPassword -Length 16)"
Write-Output "Mot de passe sans caractères spéciaux: $(New-RandomPassword -IncludeSpecialChars:$false)"
Write-Output "Mot de passe avec uniquement des minuscules et des chiffres: $(New-RandomPassword -IncludeUppercase:$false -IncludeSpecialChars:$false)"
```

**Explication**:
- `[CmdletBinding()]` transforme la fonction en une fonction avancée
- `[ValidateRange(8, 128)]` limite la longueur du mot de passe entre 8 et 128 caractères
- Les paramètres de type `[switch]` permettent une utilisation simplifiée
- La vérification récursive assure que tous les critères sont respectés
- La sortie montre différentes options d'utilisation de la fonction

---

## 🔴 Niveau Avancé

### Quiz 3 : Concepts avancés PowerShell

1. **Question**: Quelle technique PowerShell permet d'exécuter des tâches en parallèle dans PowerShell 7+ ?
   - A) `Start-Parallel`
   - B) `Invoke-Parallel`
   - C) `ForEach-Object -Parallel`
   - D) `Start-ThreadJob`

   **Réponse**: C) `ForEach-Object -Parallel`

   **Explication**: Dans PowerShell 7+, le paramètre `-Parallel` a été ajouté à `ForEach-Object` pour permettre l'exécution en parallèle. Par exemple : `1..10 | ForEach-Object -Parallel { Start-Sleep -Seconds 1; $_ } -ThrottleLimit 5`.

2. **Question**: Quelle est la meilleure approche pour accéder aux propriétés WMI/CIM sous PowerShell moderne ?
   - A) `Get-WmiObject`
   - B) `Get-CimInstance`
   - C) `Invoke-WmiMethod`
   - D) `New-CimSession`

   **Réponse**: B) `Get-CimInstance`

   **Explication**: `Get-CimInstance` est la méthode recommandée car elle utilise le nouveau standard CIM (Common Information Model) qui est plus sécurisé et compatible avec les systèmes non-Windows. `Get-WmiObject` est considéré comme obsolète.

3. **Question**: Quelle construction permet de capturer et gérer les erreurs en PowerShell ?
   - A) `on-error`
   - B) `try/catch/finally`
   - C) `error-handling`
   - D) `begin/process/end`

   **Réponse**: B) `try/catch/finally`

   **Explication**: Le bloc `try/catch/finally` permet de capturer et gérer les exceptions en PowerShell. Le code susceptible de générer une erreur est placé dans le bloc `try`, la gestion des erreurs se fait dans le bloc `catch`, et le code qui doit s'exécuter quoi qu'il arrive va dans le bloc `finally`.

### Exercice 5 : Monitoring de services avec logging

**Objectif**: Créer un script avancé qui surveille l'état des services Windows critiques et envoie des alertes en cas de problème.

**Instructions**:
1. Créez un script qui:
   - Accepte une liste de services à surveiller depuis un fichier JSON
   - Vérifie périodiquement l'état de ces services
   - Journalise tous les événements dans un fichier de log
   - Tente de redémarrer les services arrêtés
   - Envoie une alerte (simulation par Write-Host) en cas d'échec du redémarrage

**Solution**:
```powershell
# service-monitor.ps1

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigPath,

    [Parameter()]
    [string]$LogPath = "C:\Logs\ServiceMonitor.log",

    [Parameter()]
    [int]$CheckIntervalSeconds = 60
)

# Fonction de journalisation
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Severity = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Severity] $Message"

    # Écrire dans la console avec couleur selon la sévérité
    switch ($Severity) {
        'INFO'    { Write-Host $logEntry -ForegroundColor Cyan }
        'WARNING' { Write-Host $logEntry -ForegroundColor Yellow }
        'ERROR'   { Write-Host $logEntry -ForegroundColor Red }
    }

    # Écrire dans le fichier log
    Add-Content -Path $LogPath -Value $logEntry
}

# Créer le dossier de logs s'il n'existe pas
$logFolder = Split-Path -Path $LogPath -Parent
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory | Out-Null
    Write-Log "Dossier de logs créé: $logFolder"
}

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $ConfigPath)) {
    Write-Log "Le fichier de configuration n'existe pas: $ConfigPath" -Severity ERROR

    # Créer un exemple de fichier de configuration
    $exampleConfig = @{
        Services = @(
            @{
                Name = "Spooler"
                Critical = $true
                AutoRestart = $true
                MaxRestartAttempts = 3
            },
            @{
                Name = "wuauserv"
                Critical = $false
                AutoRestart = $true
                MaxRestartAttempts = 2
            }
        )
    }

    $exampleConfig | ConvertTo-Json -Depth 3 | Out-File -FilePath "example_config.json"
    Write-Log "Un exemple de fichier de configuration a été créé: example_config.json" -Severity WARNING
    exit 1
}

try {
    # Charger la configuration
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
    Write-Log "Configuration chargée depuis: $ConfigPath"

    # Variables pour suivre les tentatives de redémarrage
    $restartAttempts = @{}

    # Boucle principale de surveillance
    Write-Log "Démarrage de la surveillance des services. Intervalle: $CheckIntervalSeconds secondes."

    while ($true) {
        foreach ($serviceConfig in $config.Services) {
            $serviceName = $serviceConfig.Name

            try {
                $service = Get-Service -Name $serviceName -ErrorAction Stop
                $status = $service.Status

                # Journaliser l'état actuel
                Write-Log "Service '$serviceName' - État actuel: $status"

                # Vérifier si le service est arrêté et doit être redémarré
                if ($status -ne 'Running' -and $serviceConfig.AutoRestart) {
                    # Initialiser le compteur de tentatives si nécessaire
                    if (-not $restartAttempts.ContainsKey($serviceName)) {
                        $restartAttempts[$serviceName] = 0
                    }

                    # Vérifier si le nombre maximum de tentatives est atteint
                    if ($restartAttempts[$serviceName] -lt $serviceConfig.MaxRestartAttempts) {
                        $restartAttempts[$serviceName]++

                        Write-Log "Tentative de redémarrage du service '$serviceName' (#$($restartAttempts[$serviceName]))" -Severity WARNING

                        try {
                            Start-Service -Name $serviceName -ErrorAction Stop
                            Write-Log "Service '$serviceName' redémarré avec succès" -Severity INFO
                            $restartAttempts[$serviceName] = 0  # Réinitialiser le compteur en cas de succès
                        }
                        catch {
                            Write-Log "Échec du redémarrage du service '$serviceName': $($_.Exception.Message)" -Severity ERROR

                            # Simuler l'envoi d'une alerte si le service est critique
                            if ($serviceConfig.Critical) {
                                Write-Log "ALERTE! Le service critique '$serviceName' ne peut pas être redémarré!" -Severity ERROR
                                # Dans un scénario réel, on pourrait envoyer un email ou une notification
                                # Send-MailMessage -To "admin@example.com" -Subject "Service critique en panne" ...
                            }
                        }
                    }
                    else {
                        Write-Log "Nombre maximum de tentatives de redémarrage atteint pour le service '$serviceName'" -Severity ERROR
                    }
                }
                elseif ($status -eq 'Running') {
                    # Réinitialiser le compteur si le service fonctionne
                    $restartAttempts[$serviceName] = 0
                }
            }
            catch {
                Write-Log "Erreur lors de la récupération du service '$serviceName': $($_.Exception.Message)" -Severity ERROR
            }
        }

        # Attendre avant la prochaine vérification
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
}
catch {
    Write-Log "Erreur critique: $($_.Exception.Message)" -Severity ERROR
    exit 1
}
```

**Explication**:
- Le script utilise un fichier JSON pour la configuration des services à surveiller
- Une fonction de journalisation personnalisée enregistre les événements avec horodatage et niveau de sévérité
- Le traitement des erreurs est géré avec des blocs try/catch
- Un système de tentatives de redémarrage limitées évite les boucles infinies
- Le script s'exécute en continu avec des intervalles configurables

## 🔴 Niveau Avancé (suite)

### Exercice 6 : Module d'inventaire réseau

**Objectif**: Créer un module PowerShell complet qui découvre et documente les équipements réseau.

**Instructions**:
1. Créez un module nommé `NetworkInventory` avec:
   - Une fonction pour scanner une plage d'adresses IP
   - Une fonction pour récupérer des informations détaillées sur chaque hôte actif
   - Une fonction pour exporter les résultats au format CSV, JSON et HTML
   - Une documentation complète et des exemples d'utilisation

**Solution**:
```powershell
# NetworkInventory.psm1

#Requires -Version 5.1

<#
.SYNOPSIS
    Module d'inventaire réseau pour PowerShell
.DESCRIPTION
    Ce module permet de découvrir et documenter les équipements réseau dans un environnement local.
    Il fournit des fonctions pour scanner les adresses IP, collecter des informations sur les hôtes
    et exporter les résultats dans différents formats.
.NOTES
    Version:        1.0.0
    Author:         [Votre nom]
    Creation Date:  [Date]
#>

# Variables privées du module
$script:defaultTimeout = 1000  # millisecondes
$script:defaultExportPath = "$env:USERPROFILE\Documents\NetworkInventory"

#region Functions

function Test-IPAddress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$IPAddress
    )

    $regexIPv4 = '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'

    if ($IPAddress -match $regexIPv4) {
        $octets = $IPAddress -split '\.'

        foreach ($octet in $octets) {
            $octetValue = [int]$octet
            if ($octetValue -lt 0 -or $octetValue -gt 255) {
                return $false
            }
        }
        return $true
    }

    return $false
}

function Get-IPRange {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$StartIP,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$EndIP
    )

    process {
        # Vérifier que les adresses IP sont valides
        if (-not (Test-IPAddress -IPAddress $StartIP) -or -not (Test-IPAddress -IPAddress $EndIP)) {
            throw "Adresse IP invalide. Veuillez spécifier des adresses IPv4 valides."
        }

        # Convertir les adresses IP en entiers pour faciliter la comparaison
        $startIPBytes = ([System.Net.IPAddress]::Parse($StartIP)).GetAddressBytes()
        [Array]::Reverse($startIPBytes)
        $startIPInt = [System.BitConverter]::ToUInt32($startIPBytes, 0)

        $endIPBytes = ([System.Net.IPAddress]::Parse($EndIP)).GetAddressBytes()
        [Array]::Reverse($endIPBytes)
        $endIPInt = [System.BitConverter]::ToUInt32($endIPBytes, 0)

        # Vérifier que l'adresse de fin est supérieure à l'adresse de début
        if ($endIPInt -lt $startIPInt) {
            throw "L'adresse IP de fin doit être supérieure à l'adresse IP de début."
        }

        # Générer la plage d'adresses IP
        $ipRange = for ($i = $startIPInt; $i -le $endIPInt; $i++) {
            $bytes = [System.BitConverter]::GetBytes($i)
            [Array]::Reverse($bytes)
            [System.Net.IPAddress]::new($bytes).ToString()
        }

        return $ipRange
    }
}

function Invoke-NetworkScan {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ParameterSetName="Range")]
        [string]$StartIP,

        [Parameter(Mandatory=$true, ParameterSetName="Range")]
        [string]$EndIP,

        [Parameter(Mandatory=$true, ParameterSetName="CIDR")]
        [string]$CIDRNotation,

        [Parameter()]
        [int]$Timeout = $script:defaultTimeout,

        [Parameter()]
        [switch]$ResolveHostnames
    )

    begin {
        Write-Verbose "Démarrage du scan réseau..."
        $results = [System.Collections.ArrayList]::new()
    }

    process {
        # Déterminer la plage d'adresses IP à scanner
        $ipAddresses = @()

        if ($PSCmdlet.ParameterSetName -eq "Range") {
            $ipAddresses = Get-IPRange -StartIP $StartIP -EndIP $EndIP
        }
        elseif ($PSCmdlet.ParameterSetName -eq "CIDR") {
            if ($CIDRNotation -match '^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/(\d{1,2})$') {
                $baseIP = $matches[1]
                $prefix = [int]$matches[2]

                if ($prefix -lt 0 -or $prefix -gt 32) {
                    throw "Préfixe CIDR invalide. Doit être entre 0 et 32."
                }

                # Calculer la plage d'adresses IP à partir de la notation CIDR
                $baseIPBytes = ([System.Net.IPAddress]::Parse($baseIP)).GetAddressBytes()
                [Array]::Reverse($baseIPBytes)
                $baseIPInt = [System.BitConverter]::ToUInt32($baseIPBytes, 0)

                $mask = (-bnot 0) -shl (32 - $prefix)
                $networkAddressInt = $baseIPInt -band $mask
                $broadcastAddressInt = $networkAddressInt -bor (-bnot $mask)

                # Si le préfixe est 31 ou 32, on n'a pas d'adresse réseau ou broadcast à exclure
                $start = $networkAddressInt
                $end = $broadcastAddressInt

                if ($prefix -lt 31) {
                    # Exclure l'adresse réseau et l'adresse broadcast
                    $start = $networkAddressInt + 1
                    $end = $broadcastAddressInt - 1
                }

                $ipAddresses = for ($i = $start; $i -le $end; $i++) {
                    $bytes = [System.BitConverter]::GetBytes($i)
                    [Array]::Reverse($bytes)
                    [System.Net.IPAddress]::new($bytes).ToString()
                }
            }
            else {
                throw "Format CIDR invalide. Doit être au format 'IP/Prefix'."
            }
        }

        $totalIPs = $ipAddresses.Count
        $currentIP = 0

        # Scanner chaque adresse IP en parallèle (PowerShell 7+)
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $ipAddresses | ForEach-Object -Parallel {
                $ip = $_
                $timeout = $using:Timeout
                $resolveHostnames = $using:ResolveHostnames

                try {
                    # Tester si l'hôte répond au ping
                    $ping = Test-Connection -TargetName $ip -Count 1 -Quiet -TimeoutSeconds ($timeout / 1000)

                    if ($ping) {
                        $hostInfo = [PSCustomObject]@{
                            IPAddress = $ip
                            Status = "Online"
                            ResponseTime = [int](Test-Connection -TargetName $ip -Count 1).ResponseTime
                            Hostname = if ($resolveHostnames) {
                                try {
                                    ([System.Net.Dns]::GetHostEntry($ip)).HostName
                                }
                                catch {
                                    "Unknown"
                                }
                            } else {
                                "N/A"
                            }
                            ScanTime = Get-Date
                        }

                        return $hostInfo
                    }
                }
                catch {
                    Write-Warning "Erreur lors du scan de l'adresse IP $ip : $($_.Exception.Message)"
                }
            } -ThrottleLimit 100 | ForEach-Object {
                [void]$results.Add($_)
            }
        }
        else {
            # Utiliser les jobs pour PowerShell 5.1
            $jobs = @()

            foreach ($ip in $ipAddresses) {
                $currentIP++
                Write-Progress -Activity "Scan du réseau" -Status "Adresse IP: $ip" -PercentComplete (($currentIP / $totalIPs) * 100)

                $jobs += Start-Job -ScriptBlock {
                    param($ip, $timeout, $resolveHostnames)

                    try {
                        # Tester si l'hôte répond au ping
                        $ping = Test-Connection -ComputerName $ip -Count 1 -Quiet -ErrorAction SilentlyContinue

                        if ($ping) {
                            $responseTime = (Test-Connection -ComputerName $ip -Count 1).ResponseTime

                            $hostInfo = [PSCustomObject]@{
                                IPAddress = $ip
                                Status = "Online"
                                ResponseTime = [int]$responseTime
                                Hostname = if ($resolveHostnames) {
                                    try {
                                        ([System.Net.Dns]::GetHostEntry($ip)).HostName
                                    }
                                    catch {
                                        "Unknown"
                                    }
                                } else {
                                    "N/A"
                                }
                                ScanTime = Get-Date
                            }

                            return $hostInfo
                        }
                    }
                    catch {
                        Write-Warning "Erreur lors du scan de l'adresse IP $ip : $($_.Exception.Message)"
                    }
                } -ArgumentList $ip, $Timeout, $ResolveHostnames

                # Limiter le nombre de jobs simultanés
                if ($jobs.Count -ge 100) {
                    $completedJob = $jobs | Wait-Job -Any
                    $jobResult = $completedJob | Receive-Job
                    if ($jobResult) {
                        [void]$results.Add($jobResult)
                    }
                    $completedJob | Remove-Job
                    $jobs = $jobs | Where-Object { $_.State -ne "Completed" }
                }
            }

            # Attendre la fin des jobs restants
            $jobs | Wait-Job | ForEach-Object {
                $jobResult = $_ | Receive-Job
                if ($jobResult) {
                    [void]$results.Add($jobResult)
                }
                $_ | Remove-Job
            }
        }
    }

    end {
        Write-Verbose "Scan réseau terminé. $($results.Count) hôtes en ligne."
        return $results
    }
}

function Get-HostDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$IPAddress,

        [Parameter()]
        [int]$Timeout = $script:defaultTimeout,

        [Parameter()]
        [switch]$IncludeOpenPorts,

        [Parameter()]
        [int[]]$CommonPorts = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 443, 445, 1433, 3306, 3389, 5985, 5986, 8080)
    )

    begin {
        Add-Type -AssemblyName System.DirectoryServices
    }

    process {
        try {
            # Vérifier si l'hôte est accessible
            Write-Verbose "Récupération des détails pour l'hôte $IPAddress"
            $isOnline = Test-Connection -TargetName $IPAddress -Count 1 -Quiet -ErrorAction SilentlyContinue

            if (-not $isOnline) {
                Write-Warning "L'hôte $IPAddress n'est pas accessible."
                return
            }

            # Récupérer les informations de base
            $hostname = try {
                ([System.Net.Dns]::GetHostEntry($IPAddress)).HostName
            } catch {
                "Inconnu"
            }

            # Essayer de récupérer les informations système via WMI/CIM
            $osInfo = $null
            $computerSystem = $null
            $networkAdapters = $null

            try {
                if ($hostname -ne "Inconnu") {
                    $targetName = $hostname
                } else {
                    $targetName = $IPAddress
                }

                $sessionOption = New-CimSessionOption -Protocol Dcom
                $cimSession = New-CimSession -ComputerName $targetName -SessionOption $sessionOption -ErrorAction Stop

                $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $cimSession -ErrorAction Stop
                $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -CimSession $cimSession -ErrorAction Stop
                $networkAdapters = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -CimSession $cimSession -Filter "IPEnabled = 'True'" -ErrorAction Stop

                $processors = Get-CimInstance -ClassName Win32_Processor -CimSession $cimSession -ErrorAction Stop
                $disks = Get-CimInstance -ClassName Win32_LogicalDisk -CimSession $cimSession -Filter "DriveType = 3" -ErrorAction Stop

                $lastBootTime = $osInfo.LastBootUpTime
                $uptime = (Get-Date) - $lastBootTime

                Remove-CimSession -CimSession $cimSession
            } catch {
                Write-Verbose "Impossible de récupérer les informations WMI/CIM : $($_.Exception.Message)"
            }

            # Scanner les ports si demandé
            $openPorts = @()

            if ($IncludeOpenPorts) {
                Write-Verbose "Scan des ports communs pour $IPAddress"

                foreach ($port in $CommonPorts) {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient

                    try {
                        $result = $tcpClient.BeginConnect($IPAddress, $port, $null, $null)
                        $wait = $result.AsyncWaitHandle.WaitOne($Timeout, $false)

                        if ($wait -and $tcpClient.Connected) {
                            $serviceName = switch ($port) {
                                21 { "FTP" }
                                22 { "SSH" }
                                23 { "Telnet" }
                                25 { "SMTP" }
                                53 { "DNS" }
                                80 { "HTTP" }
                                110 { "POP3" }
                                135 { "RPC" }
                                139 { "NetBIOS" }
                                443 { "HTTPS" }
                                445 { "SMB" }
                                1433 { "MSSQL" }
                                3306 { "MySQL" }
                                3389 { "RDP" }
                                5985 { "WinRM-HTTP" }
                                5986 { "WinRM-HTTPS" }
                                8080 { "HTTP-Alt" }
                                default { "Unknown" }
                            }

                            $openPorts += [PSCustomObject]@{
                                Port = $port
                                Service = $serviceName
                                Status = "Open"
                            }
                        }
                    } catch {
                        # Ignorer les erreurs de connexion
                    } finally {
                        $tcpClient.Close()
                    }
                }
            }

            # Construire l'objet résultat
            $hostDetails = [PSCustomObject]@{
                IPAddress = $IPAddress
                Hostname = $hostname
                Status = "Online"
                ResponseTime = [int](Test-Connection -TargetName $IPAddress -Count 1).ResponseTime
                ScanTime = Get-Date
                MACAddress = ($networkAdapters | Where-Object { $_.IPAddress -contains $IPAddress }).MACAddress
                OSName = $osInfo.Caption
                OSVersion = $osInfo.Version
                OSArchitecture = $osInfo.OSArchitecture
                LastBootTime = $lastBootTime
                Uptime = $uptime
                Manufacturer = $computerSystem.Manufacturer
                Model = $computerSystem.Model
                Processors = @($processors | ForEach-Object { $_.Name }) -join ", "
                NumCPU = $processors.Count
                TotalCores = ($processors | Measure-Object -Property NumberOfCores -Sum).Sum
                TotalMemoryGB = [math]::Round($computerSystem.TotalPhysicalMemory / 1GB, 2)
                Disks = @($disks | ForEach-Object {
                    "$(($_.DeviceID)) - $(($_.Size / 1GB).ToString('N2')) GB ($(($_.FreeSpace / 1GB).ToString('N2')) GB libre)"
                }) -join ", "
                OpenPorts = $openPorts
            }

            return $hostDetails
        }
        catch {
            Write-Error "Erreur lors de la récupération des détails pour l'hôte $IPAddress : $($_.Exception.Message)"
        }
    }
}

function Export-NetworkInventory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSObject[]]$InputObject,

        [Parameter()]
        [ValidateSet("CSV", "JSON", "HTML", "All")]
        [string]$Format = "All",

        [Parameter()]
        [string]$Path = $script:defaultExportPath,

        [Parameter()]
        [string]$Filename = "NetworkInventory_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    )

    begin {
        $data = [System.Collections.ArrayList]::new()

        # Créer le dossier s'il n'existe pas
        if (-not (Test-Path -Path $Path)) {
            New-Item -Path $Path -ItemType Directory -Force | Out-Null
        }
    }

    process {
        foreach ($item in $InputObject) {
            [void]$data.Add($item)
        }
    }

    end {
        if ($data.Count -eq 0) {
            Write-Warning "Aucune donnée à exporter."
            return
        }

        # Déterminer les formats d'export
        $exportFormats = @()

        if ($Format -eq "All") {
            $exportFormats = @("CSV", "JSON", "HTML")
        }
        else {
            $exportFormats = @($Format)
        }

        # Chemins des fichiers d'export
        $exportPaths = @{}

        foreach ($fmt in $exportFormats) {
            $extension = $fmt.ToLower()
            $exportPaths[$fmt] = Join-Path -Path $Path -ChildPath "$Filename.$extension"
        }

        # Exporter dans les formats demandés
        foreach ($fmt in $exportFormats) {
            $outputPath = $exportPaths[$fmt]

            switch ($fmt) {
                "CSV" {
                    $data | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
                    Write-Verbose "Export CSV terminé : $outputPath"
                }

                "JSON" {
                    $data | ConvertTo-Json -Depth 5 | Out-File -FilePath $outputPath -Encoding UTF8
                    Write-Verbose "Export JSON terminé : $outputPath"
                }

                "HTML" {
                    # Créer un rapport HTML plus élaboré
                    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'inventaire réseau</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { color: #2980b9; margin-top: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; color: #333; font-weight: bold; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f1f1; }
        .online { color: green; }
        .offline { color: red; }
        .summary { background-color: #eef8fb; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .timestamp { font-style: italic; color: #7f8c8d; margin-bottom: 20px; }
        .port-table { width: auto; margin-left: 20px; }
        .port-open { color: green; }
    </style>
</head>
<body>
    <h1>Rapport d'inventaire réseau</h1>
    <div class="timestamp">Généré le $(Get-Date -Format 'dd/MM/yyyy à HH:mm:ss')</div>
    <div class="summary">
        <h2>Résumé</h2>
        <p>Nombre total d'hôtes scannés: $($data.Count)</p>
        <p>Hôtes en ligne: $($data.Where({$_.Status -eq 'Online'}).Count)</p>
    </div>
"@

                    $htmlFooter = @"
</body>
</html>
"@

                    $htmlBody = ""

                    foreach ($host in $data) {
                        $statusClass = if ($host.Status -eq "Online") { "online" } else { "offline" }

                        $htmlBody += @"
    <h2>$($host.IPAddress) - $($host.Hostname)</h2>
    <table>
        <tr>
            <th>Propriété</th>
            <th>Valeur</th>
        </tr>
        <tr>
            <td>Statut</td>
            <td class="$statusClass">$($host.Status)</td>
        </tr>
        <tr>
            <td>Temps de réponse</td>
            <td>$($host.ResponseTime) ms</td>
        </tr>
"@

                        # Ajouter des propriétés supplémentaires si disponibles
                        $additionalProps = @(
                            "MACAddress", "OSName", "OSVersion", "OSArchitecture",
                            "Manufacturer", "Model", "NumCPU", "TotalCores",
                            "TotalMemoryGB", "LastBootTime", "Uptime"
                        )

                        foreach ($prop in $additionalProps) {
                            if ($null -ne $host.$prop) {
                                $htmlBody += @"
        <tr>
            <td>$prop</td>
            <td>$($host.$prop)</td>
        </tr>
"@
                            }
                        }

                        $htmlBody += @"
    </table>
"@

                        # Ajouter des informations sur les ports ouverts si disponibles
                        if ($null -ne $host.OpenPorts -and $host.OpenPorts.Count -gt 0) {
                            $htmlBody += @"
    <h3>Ports ouverts</h3>
    <table class="port-table">
        <tr>
            <th>Port</th>
            <th>Service</th>
        </tr>
"@

                            foreach ($port in $host.OpenPorts) {
                                $htmlBody += @"
        <tr>
            <td>$($port.Port)</td>
            <td>$($port.Service)</td>
        </tr>
"@
                            }

                            $htmlBody += @"
    </table>
"@
                        }
                    }

                    $htmlContent = $htmlHeader + $htmlBody + $htmlFooter
                    $htmlContent | Out-File -FilePath $outputPath -Encoding UTF8
                    Write-Verbose "Export HTML terminé : $outputPath"
                }
            }
        }

        # Retourner les chemins des fichiers exportés
        return $exportPaths
    }
}

#endregion

#region Module Exports
Export-ModuleMember -Function Invoke-NetworkScan, Get-HostDetails, Export-NetworkInventory
#endregion
```

**Manifeste du module** (NetworkInventory.psd1):
```powershell
@{
    RootModule = 'NetworkInventory.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'  # Remplacer par un GUID unique
    Author = '[Votre Nom]'
    CompanyName = '[Votre Entreprise]'
    Copyright = '(c) 2025 [Votre Nom]. Tous droits réservés.'
    Description = 'Module d''inventaire réseau pour PowerShell'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Invoke-NetworkScan', 'Get-HostDetails', 'Export-NetworkInventory')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Réseau', 'Inventaire', 'Scan')
            LicenseUri = 'https://example.com/license'
            ProjectUri = 'https://example.com/project'
            ReleaseNotes = 'Version initiale du module NetworkInventory'
        }
    }
}
```

**Exemple d'utilisation**:
```powershell
# Importer le module
Import-Module .\NetworkInventory.psd1

# Scan d'une plage d'adresses IP (format plage)
$results = Invoke-NetworkScan -StartIP "192.168.1.1" -EndIP "192.168.1.254" -ResolveHostnames

# Scan d'une plage d'adresses IP (format CIDR)
$results = Invoke-NetworkScan -CIDRNotation "192.168.1.0/24" -ResolveHostnames

# Obtenir des détails pour les hôtes en ligne
$detailedInventory = $results | Get-HostDetails -IncludeOpenPorts

# Exporter les résultats en CSV, JSON et HTML
$exportPaths = $detailedInventory | Export-NetworkInventory -Format All -Path "C:\Rapports"

# Ouvrir le rapport HTML
Start-Process $exportPaths["HTML"]
```

**Explication**:
- Le module suit les bonnes pratiques de PowerShell (commentaires, documentation intégrée, validation des paramètres)
- La fonction `Invoke-NetworkScan` utilise `-Parallel` si PowerShell 7+ est disponible, sinon utilise des jobs pour PowerShell 5.1
- `Get-HostDetails` récupère des informations WMI/CIM détaillées et peut scanner les ports ouverts
- `Export-NetworkInventory` permet d'exporter dans différents formats (CSV, JSON et un rapport HTML interactif)
- Le module gère les erreurs et valide les entrées pour éviter les problèmes d'exécution
- Une documentation et des exemples d'utilisation sont fournis

---

# 16-3. Quiz et exercices corrigés par niveau (suite)

## ⚪ Challenge Final - Projet complet

### Quiz 4 : Tour d'horizon PowerShell

1. **Question**: Quelle est la différence principale entre PowerShell et PowerShell Core ?
   - A) PowerShell est limité à Windows, PowerShell Core est multiplateforme
   - B) PowerShell utilise .NET Framework, PowerShell Core utilise .NET Core
   - C) PowerShell est plus ancien et a moins de fonctionnalités
   - D) Les réponses A et B sont correctes

   **Réponse**: D) Les réponses A et B sont correctes

   **Explication**: PowerShell (Windows PowerShell) est construit sur .NET Framework et fonctionne uniquement sur Windows. PowerShell Core (maintenant simplement appelé PowerShell 7+) est construit sur .NET Core (maintenant .NET 5+) et est multiplateforme, fonctionnant sur Windows, Linux et macOS.

2. **Question**: Quelle fonction aide à mesurer le temps d'exécution d'un script ?
   - A) `Get-ExecutionTime`
   - B) `Measure-Command`
   - C) `Time-Script`
   - D) `Test-Performance`

   **Réponse**: B) `Measure-Command`

   **Explication**: `Measure-Command` est utilisée pour mesurer le temps nécessaire à l'exécution d'un bloc de code PowerShell. Par exemple : `Measure-Command { Get-ChildItem -Recurse }`.

3. **Question**: Quel est l'avantage principal de l'utilisation de classes PowerShell par rapport aux fonctions traditionnelles ?
   - A) Les classes sont plus rapides à exécuter
   - B) Les classes supportent l'héritage et le polymorphisme
   - C) Les classes fonctionnent sur toutes les versions de PowerShell
   - D) Les classes utilisent moins de mémoire

   **Réponse**: B) Les classes supportent l'héritage et le polymorphisme

   **Explication**: Les classes PowerShell (introduites dans PowerShell 5.0) permettent une programmation orientée objet avec héritage, constructeurs, méthodes et propriétés. Elles offrent une approche plus structurée pour créer des types personnalisés complexes.

4. **Question**: Quelle est la meilleure pratique pour gérer les erreurs dans PowerShell ?
   - A) Utiliser `$ErrorActionPreference = 'SilentlyContinue'` globalement
   - B) Toujours utiliser des blocs try/catch pour chaque opération
   - C) Utiliser des blocs try/catch pour les opérations susceptibles d'échouer et définir des paramètres `-ErrorAction` appropriés
   - D) Ne pas gérer les erreurs et laisser l'utilisateur les traiter

   **Réponse**: C) Utiliser des blocs try/catch pour les opérations susceptibles d'échouer et définir des paramètres `-ErrorAction` appropriés

   **Explication**: La meilleure pratique consiste à utiliser des blocs try/catch autour du code susceptible de générer des erreurs, tout en définissant des paramètres `-ErrorAction` appropriés pour les cmdlets individuelles. Cette approche offre un équilibre entre la gestion des erreurs et la lisibilité du code.

5. **Question**: Quelle est la méthode recommandée pour documenter vos fonctions PowerShell ?
   - A) Ajouter des commentaires en ligne avec le préfixe `#`
   - B) Utiliser des commentaires basés sur .SYNOPSIS, .DESCRIPTION, etc.
   - C) Créer un fichier README séparé
   - D) Ne pas documenter, le code doit être explicite

   **Réponse**: B) Utiliser des commentaires basés sur .SYNOPSIS, .DESCRIPTION, etc.

   **Explication**: La méthode recommandée pour documenter les fonctions PowerShell est d'utiliser des commentaires d'aide basés sur XML, avec des sections comme .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE, etc. Cette méthode permet d'accéder à l'aide via Get-Help et est conforme aux standards de la communauté PowerShell.

### Challenge : Outil de surveillance système complet

**Objectif**: Créer un outil complet de surveillance système qui collecte des métriques de performance, analyse l'état des serveurs et génère des rapports automatisés.

**Instructions**:
1. Créez un module PowerShell structuré avec les composants suivants:
   - Configuration via fichier JSON
   - Collecte de métriques système (CPU, RAM, disque, réseau)
   - Surveillance des services Windows critiques
   - Analyse des journaux d'événements
   - Génération de rapports HTML avec graphiques
   - Système d'alertes par email
   - Documentation complète et exemples d'utilisation

**Solution**:

Voici un exemple de solution complète sous forme d'un module PowerShell structuré. Le module s'appelle "SystemMonitor" et implémente toutes les fonctionnalités demandées.

#### Structure du projet:

```
SystemMonitor/
│
├── SystemMonitor.psd1         # Manifeste du module
├── SystemMonitor.psm1         # Module principal (chargeur)
│
├── Config/
│   └── default-config.json    # Configuration par défaut
│
├── Public/                    # Fonctions publiques (exportées)
│   ├── Start-SystemMonitor.ps1
│   ├── Get-SystemMetrics.ps1
│   ├── New-SystemReport.ps1
│   └── Set-MonitorConfig.ps1
│
└── Private/                   # Fonctions privées (internes)
    ├── Get-CPUMetrics.ps1
    ├── Get-MemoryMetrics.ps1
    ├── Get-DiskMetrics.ps1
    ├── Get-EventLogAlerts.ps1
    ├── Send-AlertEmail.ps1
    ├── Write-MonitorLog.ps1
    └── New-HTMLReport.ps1
```

#### Fichier de manifeste (SystemMonitor.psd1):

```powershell
@{
    RootModule = 'SystemMonitor.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'bf9ec48d-3a8e-4da0-a5e1-b006424c3a4a'
    Author = 'Votre Nom'
    CompanyName = 'Votre Entreprise'
    Copyright = '(c) 2025 Votre Nom. Tous droits réservés.'
    Description = 'Module de surveillance système avancé pour PowerShell'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Start-SystemMonitor',
        'Get-SystemMetrics',
        'New-SystemReport',
        'Set-MonitorConfig'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Monitoring', 'System', 'Performance', 'Reporting')
            LicenseUri = 'https://github.com/votrenom/SystemMonitor/LICENSE'
            ProjectUri = 'https://github.com/votrenom/SystemMonitor'
            ReleaseNotes = 'Version initiale du module SystemMonitor.'
        }
    }
}
```

#### Module principal (SystemMonitor.psm1):

```powershell
#Requires -Version 5.1
<#
.SYNOPSIS
    Module de surveillance système pour PowerShell.
.DESCRIPTION
    Ce module permet de surveiller les performances système,
    d'analyser les journaux d'événements et de générer des rapports détaillés.
.NOTES
    Version:        1.0.0
    Auteur:         Votre Nom
    Date création:  2025-04-27
#>

# Variables du module
$script:ModuleRoot = $PSScriptRoot
$script:ConfigPath = Join-Path -Path $ModuleRoot -ChildPath "Config\default-config.json"
$script:LogPath = Join-Path -Path $env:TEMP -ChildPath "SystemMonitor\Logs"
$script:ReportPath = Join-Path -Path $env:TEMP -ChildPath "SystemMonitor\Reports"

# Créer les dossiers nécessaires s'ils n'existent pas
$foldersToCreate = @($script:LogPath, $script:ReportPath)
foreach ($folder in $foldersToCreate) {
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }
}

# Charger la configuration par défaut
if (Test-Path -Path $script:ConfigPath) {
    try {
        $script:Config = Get-Content -Path $script:ConfigPath -Raw | ConvertFrom-Json
        Write-Verbose "Configuration chargée depuis $script:ConfigPath"
    }
    catch {
        Write-Warning "Impossible de charger la configuration par défaut: $_"
        $script:Config = [PSCustomObject]@{
            General = @{
                ScanIntervalMinutes = 15
                ReportRetentionDays = 30
                LogRetentionDays = 14
            }
            Alerts = @{
                Enabled = $true
                EmailRecipients = @()
                CPUThreshold = 90
                MemoryThreshold = 90
                DiskThreshold = 90
            }
            Servers = @('localhost')
            ServicesToMonitor = @('spooler', 'wuauserv', 'W32Time')
        }
    }
}
else {
    Write-Warning "Fichier de configuration non trouvé: $script:ConfigPath"
    # Créer une configuration par défaut
    $script:Config = [PSCustomObject]@{
        General = @{
            ScanIntervalMinutes = 15
            ReportRetentionDays = 30
            LogRetentionDays = 14
        }
        Alerts = @{
            Enabled = $true
            EmailRecipients = @()
            CPUThreshold = 90
            MemoryThreshold = 90
            DiskThreshold = 90
        }
        Servers = @('localhost')
        ServicesToMonitor = @('spooler', 'wuauserv', 'W32Time')
    }
}

# Importer les fonctions privées
$privateFiles = Get-ChildItem -Path "$ModuleRoot\Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $privateFiles) {
    try {
        . $file.FullName
        Write-Verbose "Importé: $($file.FullName)"
    }
    catch {
        Write-Error "Échec de l'importation: $($file.FullName). Erreur: $_"
    }
}

# Importer et exporter les fonctions publiques
$publicFiles = Get-ChildItem -Path "$ModuleRoot\Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
foreach ($file in $publicFiles) {
    try {
        . $file.FullName
        Write-Verbose "Importé: $($file.FullName)"
        Export-ModuleMember -Function $file.BaseName
    }
    catch {
        Write-Error "Échec de l'importation: $($file.FullName). Erreur: $_"
    }
}

# Initialisation du journal
Write-MonitorLog -Message "Module SystemMonitor chargé" -Level Info
```

#### Configuration par défaut (default-config.json):

```json
{
    "General": {
        "ScanIntervalMinutes": 15,
        "ReportRetentionDays": 30,
        "LogRetentionDays": 14,
        "DefaultReportPath": "%TEMP%\\SystemMonitor\\Reports"
    },
    "Alerts": {
        "Enabled": true,
        "SMTPServer": "smtp.votreentreprise.com",
        "SMTPPort": 25,
        "UseSSL": true,
        "From": "monitoring@votreentreprise.com",
        "To": ["admin@votreentreprise.com"],
        "Thresholds": {
            "CPU": 90,
            "Memory": 85,
            "Disk": 90,
            "EventLogLevel": "Error"
        }
    },
    "Servers": [
        {
            "Name": "SERVEUR01",
            "Type": "Windows",
            "Description": "Serveur principal"
        },
        {
            "Name": "SERVEUR02",
            "Type": "Windows",
            "Description": "Serveur de backup"
        }
    ],
    "ServicesToMonitor": [
        "spooler",
        "wuauserv",
        "W32Time",
        "MSSQLSERVER",
        "IIS"
    ],
    "EventLogFilters": [
        {
            "LogName": "System",
            "Level": "Error,Critical",
            "HoursBack": 24
        },
        {
            "LogName": "Application",
            "Level": "Error,Critical",
            "HoursBack": 24
        }
    ]
}
```

#### Exemple de fonction principale (Start-SystemMonitor.ps1):

```powershell
function Start-SystemMonitor {
    <#
    .SYNOPSIS
        Démarre la surveillance du système selon la configuration.
    .DESCRIPTION
        Cette fonction lance la surveillance des serveurs définis dans la configuration,
        collecte des métriques de performance, vérifie l'état des services et génère des rapports.
    .PARAMETER ConfigPath
        Chemin vers un fichier de configuration JSON personnalisé.
    .PARAMETER Servers
        Liste de serveurs à surveiller (remplace ceux définis dans la configuration).
    .PARAMETER RunOnce
        Effectue une seule exécution au lieu d'une surveillance continue.
    .PARAMETER GenerateReport
        Génère un rapport HTML après la collecte des métriques.
    .PARAMETER ReportPath
        Chemin où enregistrer le rapport (par défaut: répertoire temporaire).
    .EXAMPLE
        Start-SystemMonitor -RunOnce -GenerateReport
        Effectue une collecte ponctuelle et génère un rapport HTML.
    .EXAMPLE
        Start-SystemMonitor -Servers 'SERVEUR01','SERVEUR02' -ConfigPath 'C:\MonConfig.json'
        Surveille les serveurs spécifiés en utilisant une configuration personnalisée.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$ConfigPath,

        [Parameter()]
        [string[]]$Servers,

        [Parameter()]
        [switch]$RunOnce,

        [Parameter()]
        [switch]$GenerateReport,

        [Parameter()]
        [string]$ReportPath
    )

    begin {
        # Charger la configuration personnalisée si spécifiée
        if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
            try {
                $newConfig = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
                $script:Config = $newConfig
                Write-MonitorLog -Message "Configuration personnalisée chargée: $ConfigPath" -Level Info
            }
            catch {
                Write-MonitorLog -Message "Erreur lors du chargement de la configuration: $_" -Level Error
                return
            }
        }

        # Remplacer les serveurs si spécifiés
        if ($Servers -and $Servers.Count -gt 0) {
            $serversToMonitor = $Servers
            Write-MonitorLog -Message "Surveillance des serveurs spécifiés: $($Servers -join ', ')" -Level Info
        }
        else {
            $serversToMonitor = $script:Config.Servers | ForEach-Object { $_.Name }
            Write-MonitorLog -Message "Surveillance des serveurs de la configuration: $($serversToMonitor -join ', ')" -Level Info
        }

        # Déterminer le chemin du rapport
        if (-not $ReportPath) {
            $ReportPath = $script:ReportPath
        }

        # Créer le dossier de rapport s'il n'existe pas
        if (-not (Test-Path -Path $ReportPath)) {
            New-Item -Path $ReportPath -ItemType Directory -Force | Out-Null
        }

        # Stocker les résultats
        $allResults = @{}
    }

    process {
        # Définir la boucle de surveillance
        $scanInterval = $script:Config.General.ScanIntervalMinutes

        do {
            $scanStartTime = Get-Date
            Write-MonitorLog -Message "Démarrage d'un cycle de surveillance..." -Level Info

            # Pour chaque serveur à surveiller
            foreach ($server in $serversToMonitor) {
                Write-MonitorLog -Message "Collecte des métriques pour $server" -Level Info

                # Vérifier la connexion au serveur
                if (-not (Test-Connection -ComputerName $server -Count 1 -Quiet)) {
                    Write-MonitorLog -Message "Le serveur $server ne répond pas" -Level Warning
                    $allResults[$server] = @{
                        ServerName = $server
                        Status = "Offline"
                        TimeStamp = Get-Date
                    }
                    continue
                }

                try {
                    # Créer une session PSRemoting si le serveur n'est pas local
                    $useRemoting = $server -ne "localhost" -and $server -ne $env:COMPUTERNAME
                    $session = $null

                    if ($useRemoting) {
                        $session = New-PSSession -ComputerName $server -ErrorAction Stop
                    }

                    # Collecter les métriques
                    $cpuMetrics = Get-CPUMetrics -ComputerName $server -Session $session
                    $memoryMetrics = Get-MemoryMetrics -ComputerName $server -Session $session
                    $diskMetrics = Get-DiskMetrics -ComputerName $server -Session $session
                    $servicesStatus = Get-ServicesStatus -ComputerName $server -Session $session -Services $script:Config.ServicesToMonitor
                    $eventLogAlerts = Get-EventLogAlerts -ComputerName $server -Session $session -Filters $script:Config.EventLogFilters

                    # Fermer la session si elle a été créée
                    if ($session) {
                        Remove-PSSession -Session $session -ErrorAction SilentlyContinue
                    }

                    # Stocker les résultats
                    $allResults[$server] = @{
                        ServerName = $server
                        Status = "Online"
                        TimeStamp = Get-Date
                        CPU = $cpuMetrics
                        Memory = $memoryMetrics
                        Disk = $diskMetrics
                        Services = $servicesStatus
                        Events = $eventLogAlerts
                    }

                    # Vérifier les seuils d'alerte
                    if ($script:Config.Alerts.Enabled) {
                        # Vérifier CPU
                        if ($cpuMetrics.UsagePercent -gt $script:Config.Alerts.Thresholds.CPU) {
                            $alertMessage = "Alerte CPU élevé: $server - $($cpuMetrics.UsagePercent)%"
                            Write-MonitorLog -Message $alertMessage -Level Warning
                            Send-AlertEmail -Subject "Alerte CPU: $server" -Body $alertMessage
                        }

                        # Vérifier mémoire
                        if ($memoryMetrics.UsagePercent -gt $script:Config.Alerts.Thresholds.Memory) {
                            $alertMessage = "Alerte Mémoire élevée: $server - $($memoryMetrics.UsagePercent)%"
                            Write-MonitorLog -Message $alertMessage -Level Warning
                            Send-AlertEmail -Subject "Alerte Mémoire: $server" -Body $alertMessage
                        }

                        # Vérifier disque
                        foreach ($disk in $diskMetrics) {
                            if ($disk.UsagePercent -gt $script:Config.Alerts.Thresholds.Disk) {
                                $alertMessage = "Alerte Espace disque faible: $server - Disque $($disk.Drive) - $($disk.UsagePercent)%"
                                Write-MonitorLog -Message $alertMessage -Level Warning
                                Send-AlertEmail -Subject "Alerte Disque: $server" -Body $alertMessage
                            }
                        }

                        # Vérifier services
                        $stoppedServices = $servicesStatus | Where-Object { $_.Status -ne 'Running' }
                        if ($stoppedServices -and $stoppedServices.Count -gt 0) {
                            $alertMessage = "Services arrêtés sur $server : $($stoppedServices.Name -join ', ')"
                            Write-MonitorLog -Message $alertMessage -Level Warning
                            Send-AlertEmail -Subject "Alerte Services: $server" -Body $alertMessage
                        }

                        # Vérifier événements critiques
                        if ($eventLogAlerts -and $eventLogAlerts.Count -gt 0) {
                            $alertMessage = "Événements critiques sur $server : $($eventLogAlerts.Count) événements détectés"
                            Write-MonitorLog -Message $alertMessage -Level Warning
                            Send-AlertEmail -Subject "Alerte Événements: $server" -Body $alertMessage
                        }
                    }
                }
                catch {
                    Write-MonitorLog -Message "Erreur lors de la surveillance de $server : $_" -Level Error
                    $allResults[$server] = @{
                        ServerName = $server
                        Status = "Error"
                        ErrorMessage = $_.Exception.Message
                        TimeStamp = Get-Date
                    }
                }
            }

            # Générer un rapport si demandé
            if ($GenerateReport) {
                $reportFile = Join-Path -Path $ReportPath -ChildPath "SystemMonitor_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
                New-HTMLReport -Data $allResults -Path $reportFile
                Write-MonitorLog -Message "Rapport généré: $reportFile" -Level Info
            }

            # Si on ne fait qu'une exécution, sortir de la boucle
            if ($RunOnce) {
                break
            }

            # Calculer le temps d'attente avant la prochaine exécution
            $scanEndTime = Get-Date
            $scanDuration = ($scanEndTime - $scanStartTime).TotalMinutes
            $waitTime = [Math]::Max(1, $scanInterval - $scanDuration)

            Write-MonitorLog -Message "Cycle de surveillance terminé. Prochaine exécution dans $waitTime minutes" -Level Info
            Start-Sleep -Seconds ($waitTime * 60)

        } while (-not $RunOnce)
    }

    end {
        Write-MonitorLog -Message "Surveillance terminée" -Level Info

        # Retourner les résultats
        return $allResults
    }
}
```

#### Exemple de fonction de collecte de métriques (Get-CPUMetrics.ps1):

```powershell
function Get-CPUMetrics {
    <#
    .SYNOPSIS
        Collecte les métriques d'utilisation CPU d'un serveur.
    .DESCRIPTION
        Cette fonction collecte l'utilisation CPU actuelle ainsi que
        des informations sur les processeurs du système cible.
    .PARAMETER ComputerName
        Nom du serveur à surveiller.
    .PARAMETER Session
        Session PSRemoting existante à utiliser.
    .EXAMPLE
        Get-CPUMetrics -ComputerName "SERVEUR01"
        Collecte les métriques CPU du serveur SERVEUR01.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,

        [Parameter()]
        [System.Management.Automation.Runspaces.PSSession]$Session
    )

    # Fonction à exécuter sur l'ordinateur distant
    $scriptBlock = {
        try {
            # Obtenir l'utilisation CPU avec Get-Counter
            $cpuCounter = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 3
            $cpuUsage = ($cpuCounter.CounterSamples.CookedValue | Measure-Object -Average).Average

            # Obtenir les informations sur les processeurs
            $cpuInfo = Get-CimInstance -ClassName Win32_Processor

            # Calculer le nombre total de cœurs et processeurs logiques
            $totalCores = ($cpuInfo | Measure-Object -Property NumberOfCores -Sum).Sum
            $totalLogicalProcessors = ($cpuInfo | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum

            # Créer l'objet résultat
            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                UsagePercent = [math]::Round($cpuUsage, 2)
                Model = $cpuInfo[0].Name
                PhysicalProcessors = $cpuInfo.Count
                TotalCores = $totalCores
                TotalLogicalProcessors = $totalLogicalProcessors
                TimeStamp = Get-Date
            }
        }
        catch {
            Write-Error "Erreur lors de la collecte des métriques CPU: $_"
            return $null
        }
    }

    try {
        if ($Session) {
            # Utiliser la session existante
            Invoke-Command -Session $Session -ScriptBlock $scriptBlock
        }
        elseif ($ComputerName -eq "localhost" -or $ComputerName -eq $env:COMPUTERNAME) {
            # Exécuter localement
            & $scriptBlock
        }
        else {
            # Créer une nouvelle session
            Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock
        }
    }
    catch {
        Write-MonitorLog -Message "Erreur lors de la collecte des métriques CPU pour $ComputerName : $_" -Level Error
        return [PSCustomObject]@{
            ComputerName = $ComputerName
            UsagePercent = 0
            Model = "Inconnu"
            PhysicalProcessors = 0
            TotalCores = 0
            TotalLogicalProcessors = 0
            Error = $_.Exception.Message
            TimeStamp = Get-Date
        }
    }
}
```

#### Exemple de fonction pour générer un rapport HTML (New-HTMLReport.ps1):

```powershell
function New-HTMLReport {
    <#
    .SYNOPSIS
        Génère un rapport HTML à partir des données de surveillance.
    .DESCRIPTION
        Cette fonction prend les données collectées par les fonctions de surveillance
        et génère un rapport HTML interactif avec des graphiques.
    .PARAMETER Data
        Données de surveillance à inclure dans le rapport.
    .PARAMETER Path
        Chemin où enregistrer le rapport HTML.
    .EXAMPLE
        New-HTMLReport -Data $results -Path "C:\Rapport\SystemMonitor.html"
        Génère un rapport HTML à partir des résultats de surveillance.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$Data,

        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    try {
        # Générer le timestamp pour le rapport
        $reportDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
        $reportTitle = "Rapport de surveillance système - $reportDate"

        # Créer l'en-tête HTML avec CSS et JavaScript (Chart.js)
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$reportTitle</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f9f9f9;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #fff;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
            border-radius: 5px;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #2980b9;
            margin-top: 30px;
        }
        h3 {
            color: #3498db;
            margin-top: 20px;
        }
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .card {
            border: 1px solid #ddd;
            border-radius: 4px;
            padding: 15px;
            margin-bottom: 20px;
            background-color: #fff;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            margin-bottom: 10px;
        }
        .metric-name {
            font-weight: bold;
        }
        .metric-value {
            text-align: right;
        }
        .chart-container {
            position: relative;
            height: 300px;
            margin-bottom: 30px;
        }
        .status-indicator {
            display: inline-block;
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 5px;
        }
        .status-online {
            background-color: #2ecc71;
        }
        .status-offline {
            background-color: #e74c3c;
        }
        .status-warning {
            background-color: #f39c12;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 0.8em;
            color: #7f8c8d;
        }
        .gauge-container {
            width: 200px;
            height: 200px;
            display: inline-block;
            margin: 10px;
        }
        .summary-stats {
            display: flex;
            flex-wrap: wrap;
            justify-content: space-between;
            margin-bottom: 20px;
        }
        .summary-stat {
            flex: 0 0 30%;
            padding: 15px;
            background-color: #ecf0f1;
            border-radius: 5px;
            margin-bottom: 10px;
            text-align: center;
        }
        .summary-stat h3 {
            margin-top: 0;
            color: #7f8c8d;
        }
        .summary-stat p {
            font-size: 24px;
            font-weight: bold;
            margin: 10px 0;
            color: #2c3e50;
        }
        .accordion {
            background-color: #f4f4f4;
            color: #444;
            cursor: pointer;
            padding: 18px;
            width: 100%;
            text-align: left;
            border: none;
            outline: none;
            transition: 0.4s;
            margin-bottom: 1px;
            font-size: 16px;
            font-weight: bold;
        }
        .active, .accordion:hover {
            background-color: #ddd;
        }
        .panel {
            padding: 0 18px;
            background-color: white;
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.2s ease-out;
        }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@3.7.1/dist/chart.min.js"></script>
</head>
<body>
    <div class="container">
        <h1>$reportTitle</h1>
        <p>Ce rapport présente une analyse des performances système et de l'état des serveurs surveillés.</p>
"@

        # Résumé global
        $totalServers = $Data.Count
        $onlineServers = ($Data.Values | Where-Object { $_.Status -eq "Online" }).Count
        $offlineServers = ($Data.Values | Where-Object { $_.Status -eq "Offline" }).Count
        $errorServers = ($Data.Values | Where-Object { $_.Status -eq "Error" }).Count

        $html += @"
        <h2>Résumé</h2>
        <div class="summary-stats">
            <div class="summary-stat">
                <h3>Total Serveurs</h3>
                <p>$totalServers</p>
            </div>
            <div class="summary-stat">
                <h3>En ligne</h3>
                <p style="color: #2ecc71;">$onlineServers</p>
            </div>
            <div class="summary-stat">
                <h3>Hors ligne</h3>
                <p style="color: #e74c3c;">$offlineServers</p>
            </div>
        </div>

        <h2>État des serveurs</h2>
        <table>
            <tr>
                <th>Serveur</th>
                <th>État</th>
                <th>CPU (%)</th>
                <th>Mémoire (%)</th>
                <th>Disque (%)</th>
                <th>Services arrêtés</th>
                <th>Événements critiques</th>
            </tr>
"@

        # Tableau des serveurs
        foreach ($server in $Data.Keys) {
            $serverData = $Data[$server]
            $statusClass = switch ($serverData.Status) {
                "Online" { "status-online" }
                "Offline" { "status-offline" }
                default { "status-warning" }
            }

            $cpuUsage = if ($serverData.Status -eq "Online" -and $serverData.CPU) {
                [math]::Round($serverData.CPU.UsagePercent, 1)
            } else { "N/A" }

            $memoryUsage = if ($serverData.Status -eq "Online" -and $serverData.Memory) {
                [math]::Round($serverData.Memory.UsagePercent, 1)
            } else { "N/A" }

            $diskUsage = if ($serverData.Status -eq "Online" -and $serverData.Disk) {
                $highestUsage = ($serverData.Disk | Measure-Object -Property UsagePercent -Maximum).Maximum
                [math]::Round($highestUsage, 1)
            } else { "N/A" }

            $stoppedServices = if ($serverData.Status -eq "Online" -and $serverData.Services) {
                $stopped = @($serverData.Services | Where-Object { $_.Status -ne "Running" })
                $stopped.Count
            } else { "N/A" }

            $criticalEvents = if ($serverData.Status -eq "Online" -and $serverData.Events) {
                $serverData.Events.Count
            } else { "N/A" }

            $html += @"
            <tr>
                <td>$server</td>
                <td><span class="status-indicator $statusClass"></span>$($serverData.Status)</td>
                <td>$cpuUsage</td>
                <td>$memoryUsage</td>
                <td>$diskUsage</td>
                <td>$stoppedServices</td>
                <td>$criticalEvents</td>
            </tr>
"@
        }

        $html += @"
        </table>

        <h2>Détails des serveurs</h2>
"@

        # Détails pour chaque serveur
        foreach ($server in $Data.Keys) {
            $serverData = $Data[$server]

            $html += @"
        <button class="accordion">$server - $($serverData.Status)</button>
        <div class="panel">
"@

            if ($serverData.Status -eq "Online") {
                # CPU
                $html += @"
            <h3>CPU</h3>
            <div class="card">
                <div class="metric">
                    <span class="metric-name">Utilisation CPU</span>
                    <span class="metric-value">$([math]::Round($serverData.CPU.UsagePercent, 1))%</span>
                </div>
                <div class="metric">
                    <span class="metric-name">Modèle</span>
                    <span class="metric-value">$($serverData.CPU.Model)</span>
                </div>
                <div class="metric">
                    <span class="metric-name">Cœurs physiques</span>
                    <span class="metric-value">$($serverData.CPU.TotalCores)</span>
                </div>
                <div class="metric">
                    <span class="metric-name">Processeurs logiques</span>
                    <span class="metric-value">$($serverData.CPU.TotalLogicalProcessors)</span>
                </div>
                <div class="chart-container">
                    <canvas id="cpu-chart-$server"></canvas>
                </div>
            </div>

            <h3>Mémoire</h3>
            <div class="card">
                <div class="metric">
                    <span class="metric-name">Utilisation mémoire</span>
                    <span class="metric-value">$([math]::Round($serverData.Memory.UsagePercent, 1))%</span>
                </div>
                <div class="metric">
                    <span class="metric-name">Total</span>
                    <span class="metric-value">$([math]::Round($serverData.Memory.TotalGB, 1)) GB</span>
                </div>
                <div class="metric">
                    <span class="metric-name">Utilisée</span>
                    <span class="metric-value">$([math]::Round($serverData.Memory.UsedGB, 1)) GB</span>
                </div>
                <div class="metric">
                    <span class="metric-name">Libre</span>
                    <span class="metric-value">$([math]::Round($serverData.Memory.FreeGB, 1)) GB</span>
                </div>
                <div class="chart-container">
                    <canvas id="memory-chart-$server"></canvas>
                </div>
            </div>

            <h3>Disques</h3>
            <div class="card">
                <table>
                    <tr>
                        <th>Lecteur</th>
                        <th>Total (GB)</th>
                        <th>Utilisé (GB)</th>
                        <th>Libre (GB)</th>
                        <th>Utilisation (%)</th>
                    </tr>
"@

                foreach ($disk in $serverData.Disk) {
                    $html += @"
                    <tr>
                        <td>$($disk.Drive)</td>
                        <td>$([math]::Round($disk.TotalGB, 1))</td>
                        <td>$([math]::Round($disk.UsedGB, 1))</td>
                        <td>$([math]::Round($disk.FreeGB, 1))</td>
                        <td>$([math]::Round($disk.UsagePercent, 1))%</td>
                    </tr>
"@
                }

                $html += @"
                </table>
                <div class="chart-container">
                    <canvas id="disk-chart-$server"></canvas>
                </div>
            </div>

            <h3>Services</h3>
            <div class="card">
                <table>
                    <tr>
                        <th>Nom</th>
                        <th>État</th>
                        <th>Type de démarrage</th>
                    </tr>
"@

                foreach ($service in $serverData.Services) {
                    $statusColor = if ($service.Status -eq "Running") { "color: #2ecc71;" } else { "color: #e74c3c;" }

                    $html += @"
                    <tr>
                        <td>$($service.DisplayName)</td>
                        <td style="$statusColor">$($service.Status)</td>
                        <td>$($service.StartType)</td>
                    </tr>
"@
                }

                $html += @"
                </table>
            </div>
"@

                # Si des événements critiques existent
                if ($serverData.Events -and $serverData.Events.Count -gt 0) {
                    $html += @"
            <h3>Événements critiques</h3>
            <div class="card">
                <table>
                    <tr>
                        <th>Journal</th>
                        <th>ID</th>
                        <th>Source</th>
                        <th>Niveau</th>
                        <th>Heure</th>
                        <th>Message</th>
                    </tr>
"@

                    foreach ($event in $serverData.Events) {
                        $html += @"
                    <tr>
                        <td>$($event.LogName)</td>
                        <td>$($event.EventID)</td>
                        <td>$($event.ProviderName)</td>
                        <td>$($event.LevelDisplayName)</td>
                        <td>$($event.TimeCreated)</td>
                        <td>$($event.Message.Substring(0, [Math]::Min(100, $event.Message.Length)))...</td>
                    </tr>
"@
                    }

                    $html += @"
                </table>
            </div>
"@
                }
            }
            elseif ($serverData.Status -eq "Error") {
                $html += @"
            <div class="card">
                <div class="metric">
                    <span class="metric-name">Erreur</span>
                    <span class="metric-value">$($serverData.ErrorMessage)</span>
                </div>
            </div>
"@
            }
            else {
                $html += @"
            <div class="card">
                <div class="metric">
                    <span class="metric-name">État</span>
                    <span class="metric-value">Serveur hors ligne</span>
                </div>
            </div>
"@
            }

            $html += @"
        </div>
"@
        }

        # JavaScript pour les graphiques et l'accordion
        $html += @"
        <script>
            // Activer l'accordion
            var acc = document.getElementsByClassName("accordion");
            for (var i = 0; i < acc.length; i++) {
                acc[i].addEventListener("click", function() {
                    this.classList.toggle("active");
                    var panel = this.nextElementSibling;
                    if (panel.style.maxHeight) {
                        panel.style.maxHeight = null;
                    } else {
                        panel.style.maxHeight = panel.scrollHeight + "px";
                    }
                });
            }

            // Créer les graphiques pour chaque serveur
"@

        foreach ($server in $Data.Keys) {
            $serverData = $Data[$server]

            if ($serverData.Status -eq "Online") {
                # Graphique CPU
                $html += @"
            // CPU Chart pour $server
            var cpuCtx = document.getElementById('cpu-chart-$server').getContext('2d');
            var cpuChart = new Chart(cpuCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Utilisé', 'Libre'],
                    datasets: [{
                        data: [$($serverData.CPU.UsagePercent), ${(100 - $serverData.CPU.UsagePercent)}],
                        backgroundColor: ['#3498db', '#ecf0f1'],
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    cutout: '70%',
                    plugins: {
                        title: {
                            display: true,
                            text: 'Utilisation CPU'
                        },
                        legend: {
                            position: 'bottom'
                        }
                    }
                }
            });

            // Memory Chart pour $server
            var memCtx = document.getElementById('memory-chart-$server').getContext('2d');
            var memChart = new Chart(memCtx, {
                type: 'doughnut',
                data: {
                    labels: ['Utilisé', 'Libre'],
                    datasets: [{
                        data: [$($serverData.Memory.UsedGB), $($serverData.Memory.FreeGB)],
                        backgroundColor: ['#e74c3c', '#ecf0f1'],
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    cutout: '70%',
                    plugins: {
                        title: {
                            display: true,
                            text: 'Utilisation Mémoire'
                        },
                        legend: {
                            position: 'bottom'
                        }
                    }
                }
            });

            // Disk Chart pour $server
            var diskCtx = document.getElementById('disk-chart-$server').getContext('2d');
            var diskLabels = [$(($serverData.Disk | ForEach-Object { "'$($_.Drive)'" }) -join ', ')];
            var diskData = [$(($serverData.Disk | ForEach-Object { $_.UsagePercent }) -join ', ')];
            var diskChart = new Chart(diskCtx, {
                type: 'bar',
                data: {
                    labels: diskLabels,
                    datasets: [{
                        label: 'Utilisation (%)',
                        data: diskData,
                        backgroundColor: '#2980b9',
                        borderWidth: 0
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Utilisation des disques'
                        },
                        legend: {
                            display: false
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true,
                            max: 100,
                            title: {
                                display: true,
                                text: 'Utilisation (%)'
                            }
                        },
                        x: {
                            title: {
                                display: true,
                                text: 'Lecteurs'
                            }
                        }
                    }
                }
            });
"@
            }
        }

        # Fermeture du HTML
        $html += @"
        </script>
    </div>
    <div class="footer">
        <p>Rapport généré le $reportDate</p>
        <p>SystemMonitor v1.0</p>
    </div>
</body>
</html>
"@

        # Enregistrer le rapport HTML dans le fichier
        $html | Out-File -FilePath $Path -Encoding UTF8

        Write-Verbose "Rapport HTML généré avec succès: $Path"
        return $Path
    }
    catch {
        Write-Error "Erreur lors de la génération du rapport HTML: $_"
        return $null
    }
}
```

### Exemple d'utilisation du module complet:

```powershell
# Importer le module
Import-Module .\SystemMonitor

# Configuration personnalisée
$configPath = "C:\MonitConfig\config.json"

# Démarrer la surveillance avec une exécution unique et génération de rapport
$results = Start-SystemMonitor -ConfigPath $configPath -RunOnce -GenerateReport

# Créer un tableau de bord automatisé planifié
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"Import-Module C:\Modules\SystemMonitor; Start-SystemMonitor -RunOnce -GenerateReport`""
$trigger = New-ScheduledTaskTrigger -Daily -At "08:00 AM"
Register-ScheduledTask -TaskName "SystemMonitoring" -Action $action -Trigger $trigger -Description "Exécute la surveillance système quotidienne"

# Vérifier l'état des services critiques uniquement
$serviceStatus = Get-ServicesStatus -ComputerName "SERVEUR01" -Services "MSSQLSERVER", "IIS", "Exchange"

# Générer un rapport personnalisé de performances disque
$diskReport = Get-SystemMetrics -MetricType Disk -ComputerName "SERVEUR01", "SERVEUR02" |
    Where-Object { $_.UsagePercent -gt 85 } |
    New-SystemReport -ReportTitle "Disques critiques" -Path "C:\Rapports\DisquesCritiques.html"
```

## Conclusion et bonnes pratiques

Pour conclure ce module sur les quiz et exercices, voici quelques conseils et bonnes pratiques pour vos scripts PowerShell:

1. **Structure et organisation**:
   - Utilisez une structure modulaire pour vos scripts complexes
   - Séparez les fonctions, la configuration et le code principal
   - Suivez des conventions de nommage cohérentes (Verbe-Nom pour les fonctions)

2. **Documentation**:
   - Documentez toujours vos fonctions avec les commentaires d'aide PowerShell
   - Incluez des exemples d'utilisation dans la documentation
   - Commentez les sections complexes du code

3. **Gestion des erreurs**:
   - Utilisez try/catch pour capturer et gérer les erreurs
   - Définissez des valeurs par défaut appropriées
   - Journalisez les erreurs pour faciliter le dépannage

4. **Performance**:
   - Évitez les requêtes WMI/CIM répétitives
   - Utilisez le traitement parallèle pour les tâches indépendantes
   - Mesurez les performances avec `Measure-Command`

5. **Sécurité**:
   - Ne stockez jamais de mots de passe en clair dans les scripts
   - Utilisez des mécanismes sécurisés comme `Get-Credential` ou `SecureString`
   - Appliquez le principe du moindre privilège

6. **Maintenabilité**:
   - Utilisez des fonctions paramétrées au lieu de variables globales
   - Évitez les chemins codés en dur dans les scripts
   - Testez vos scripts avec Pester

En appliquant ces principes, vous créerez des scripts PowerShell robustes, efficaces et faciles à maintenir, qui vous serviront bien dans votre carrière d'administrateur ou de développeur PowerShell.

---

Les quiz et exercices de cette section vous ont permis de mettre en pratique les concepts abordés tout au long de cette formation PowerShell. N'hésitez pas à modifier et adapter ces exercices pour créer vos propres solutions personnalisées. La pratique régulière est la clé pour maîtriser PowerShell !
