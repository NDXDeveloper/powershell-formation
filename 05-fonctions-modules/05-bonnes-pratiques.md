# Module 6 : Fonctions, modules et structuration
## 6-5. Meilleures pratiques de structuration et nommage

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Écrire du code PowerShell qui fonctionne est une chose, mais écrire du code qui est facile à comprendre, à maintenir et à partager en est une autre. Dans cette section, nous allons explorer les meilleures pratiques qui vous aideront à structurer vos scripts et modules de manière professionnelle.

### Pourquoi suivre des bonnes pratiques ?

- 📖 **Lisibilité** : Code plus facile à comprendre pour vous et les autres
- 🔧 **Maintenabilité** : Corrections et améliorations plus simples
- 🧩 **Réutilisabilité** : Code plus facile à adapter à de nouveaux contextes
- 🤝 **Collaboration** : Travail d'équipe plus efficace
- 🐛 **Moins de bugs** : Structure claire = moins d'erreurs

### Convention de nommage

#### 1. Nommage des cmdlets et fonctions

PowerShell utilise la convention **Verbe-Nom** pour les cmdlets et fonctions :

```powershell
# Bon (suit la convention Verbe-Nom)
Get-Process
Set-Location
New-Item
Test-Connection

# À éviter
ProcessInfo
ChangeDirectory
MakeNewFile
Ping
```

**Liste des verbes approuvés** :
- Pour afficher tous les verbes approuvés : `Get-Verb`
- Utilisez ces catégories de verbes standard :

| Catégorie | Exemples de verbes |
|-----------|-------------------|
| Données | `Get`, `Set`, `Add`, `Remove`, `New` |
| Communication | `Connect`, `Disconnect`, `Send`, `Receive` |
| Cycle de vie | `Start`, `Stop`, `Restart`, `Resume` |
| Diagnostic | `Test`, `Trace`, `Debug`, `Measure` |

```powershell
# Vérifier si un verbe est approuvé
Get-Verb | Where-Object { $_.Verb -eq "Get" }
```

> 💡 **Astuce** : Choisissez le verbe qui décrit le mieux l'action de votre fonction. Si vous créez une fonction pour obtenir des informations, utilisez `Get-`. Si elle modifie quelque chose, utilisez `Set-`.

#### 2. Nommage des variables

- Utilisez des noms descriptifs qui indiquent clairement le contenu
- Privilégiez le format PascalCase (première lettre de chaque mot en majuscule)
- Évitez les abréviations obscures

```powershell
# Bon
$UserName
$ServerList
$TotalCount
$ProcessId

# À éviter
$u
$srvlst
$tc
$pid  # $pid est déjà une variable automatique !
```

Pour les collections et tableaux, utilisez le pluriel :

```powershell
$Computers = @("PC1", "PC2", "PC3")
$UserNames = Get-UserNames
```

#### 3. Nommage des paramètres

- Utilisez PascalCase
- Soyez cohérent avec les paramètres des cmdlets standard
- Utilisez des noms descriptifs

```powershell
function Get-UserDetails {
    param(
        [string]$UserName,        # Bon
        [int]$DaysInactive,       # Bon
        [switch]$IncludeDisabled  # Bon
    )
    # Code de la fonction
}

# À éviter
function Get-UserDetails {
    param(
        [string]$un,              # Trop court, peu descriptif
        [int]$days,               # Trop générique
        [switch]$incl_dis         # Utilise un format incohérent
    )
    # Code de la fonction
}
```

### Structuration du code

#### 1. Organisation des scripts

Un bon script suit généralement cette structure :

```powershell
#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Description courte du script
.DESCRIPTION
    Description longue
.PARAMETER Param1
    Description du paramètre 1
.EXAMPLE
    Exemple d'utilisation
.NOTES
    Informations supplémentaires
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$Param1,

    [Parameter()]
    [int]$Param2 = 10
)

# 1. Déclaration des variables globales ou de script
$script:Config = @{
    LogPath = "C:\Logs\MonScript.log"
    MaxItems = 1000
}

# 2. Définition des fonctions internes
function Write-Log {
    param($Message)
    "$(Get-Date) - $Message" | Out-File -FilePath $script:Config.LogPath -Append
}

# 3. Initialisation et vérifications
Write-Log "Script démarré avec le paramètre : $Param1"
if (-not (Test-Path $script:Config.LogPath)) {
    New-Item -Path $script:Config.LogPath -ItemType File -Force
}

# 4. Corps principal du script
try {
    # Logique principale
    Write-Log "Traitement en cours..."
    # ...
}
catch {
    Write-Log "Erreur : $_"
}
finally {
    # 5. Nettoyage
    Write-Log "Script terminé"
}
```

#### 2. Organisation des modules

Pour les modules, structurez vos fichiers comme ceci :

```
MonModule/
│
├── MonModule.psd1          # Manifeste du module
├── MonModule.psm1          # Fichier principal du module
│
├── Public/                 # Fonctions exportées (publiques)
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
│
├── Private/                # Fonctions internes (privées)
│   ├── Helper1.ps1
│   └── Helper2.ps1
│
├── Classes/                # Définitions de classes (PS 5+)
│   └── MyClass.ps1
│
├── Data/                   # Données statiques
│   └── Config.psd1
│
└── Tests/                  # Tests unitaires (Pester)
    └── MonModule.Tests.ps1
```

#### 3. Utilisation des régions

Les régions peuvent aider à organiser les sections de code plus longues :

```powershell
#region Fonctions d'aide
function Helper1 { # ... }
function Helper2 { # ... }
#endregion

#region Traitement principal
# Code principal ici
#endregion

#region Nettoyage
# Code de nettoyage
#endregion
```

> 💡 **Note** : Les régions sont surtout utiles dans les fichiers longs, mais une meilleure approche est souvent de diviser un gros fichier en plusieurs fichiers plus petits et spécialisés.

### Formatage du code

#### 1. Indentation et espacement

- Utilisez 4 espaces pour l'indentation (pas de tabulations)
- Ajoutez des espaces autour des opérateurs
- Utilisez des lignes vides pour séparer les blocs logiques

```powershell
# Bon
function Test-Indentation {
    param(
        [string]$Param1,
        [int]$Param2
    )

    if ($Param1 -eq "Test") {
        $result = $Param2 * 2
        return $result
    }
    else {
        return $Param2
    }
}

# À éviter
function Test-Indentation{
param([string]$Param1,[int]$Param2)
if($Param1-eq"Test"){$result=$Param2*2
return $result}
else{return $Param2}}
```

#### 2. Commentaires et documentation

- Commentez votre code de manière utile
- Utilisez le format de commentaire d'aide pour les fonctions

```powershell
<#
.SYNOPSIS
    Récupère les informations sur l'espace disque.
.DESCRIPTION
    Cette fonction récupère l'espace total, utilisé et libre sur les disques spécifiés.
.PARAMETER ComputerName
    Le nom de l'ordinateur à interroger. Par défaut, l'ordinateur local.
.PARAMETER DriveType
    Type de lecteur à interroger (3 = disque fixe par défaut).
.EXAMPLE
    Get-DiskInfo -ComputerName "SERVER01"
.NOTES
    Auteur: Votre Nom
    Date: 26/04/2025
#>
function Get-DiskInfo {
    [CmdletBinding()]
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [int]$DriveType = 3
    )

    # Récupération des informations de disque via WMI
    Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=$DriveType" -ComputerName $ComputerName |
        Select-Object DeviceID,
                      @{Name="SizeGB";Expression={[math]::Round($_.Size/1GB, 2)}},
                      @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB, 2)}},
                      @{Name="PercentFree";Expression={[math]::Round(($_.FreeSpace/$_.Size)*100, 2)}}
}
```

### Pratiques de programmation

#### 1. Utilisation du pipeline

Privilégiez l'utilisation du pipeline au lieu des boucles quand c'est possible :

```powershell
# Approche avec pipeline (recommandée)
Get-Process | Where-Object { $_.CPU -gt 10 } | Sort-Object CPU -Descending | Select-Object -First 5

# Au lieu de
$processes = Get-Process
$filteredProcesses = @()
foreach ($process in $processes) {
    if ($process.CPU -gt 10) {
        $filteredProcesses += $process
    }
}
$sortedProcesses = $filteredProcesses | Sort-Object CPU -Descending
$result = $sortedProcesses | Select-Object -First 5
```

#### 2. Évitez les chemins en dur

Utilisez des variables ou des paramètres pour les chemins de fichiers :

```powershell
# Bon
$LogPath = Join-Path -Path $env:TEMP -ChildPath "MonApplication\logs\app.log"

# À éviter
$LogPath = "C:\Users\Jean\AppData\Local\Temp\MonApplication\logs\app.log"
```

#### 3. Gestion des erreurs

Implémentez une bonne gestion des erreurs dans vos scripts :

```powershell
# Bon
try {
    $file = Get-Content -Path $FilePath -ErrorAction Stop
    # Traitement du fichier
}
catch [System.IO.FileNotFoundException] {
    Write-Error "Le fichier n'existe pas : $FilePath"
}
catch {
    Write-Error "Erreur lors de la lecture du fichier : $_"
}
finally {
    # Nettoyage
}
```

#### 4. Utilisation de `[CmdletBinding()]`

Ajoutez toujours `[CmdletBinding()]` à vos fonctions avancées :

```powershell
function Get-ImportantData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Source
    )

    # Avec CmdletBinding, vous avez accès à :
    Write-Verbose "Récupération des données depuis $Source"  # -Verbose
    Write-Debug "Détails de débogage"                        # -Debug

    # Corps de la fonction
}
```

### Sécurité et bonnes pratiques

#### 1. Ne stockez jamais de mots de passe en clair

```powershell
# À éviter absolument
$password = "MonMotDePasse123"

# Méthode sécurisée
$securePassword = Read-Host -Prompt "Entrez le mot de passe" -AsSecureString
$credentials = New-Object System.Management.Automation.PSCredential($username, $securePassword)
```

#### 2. Validez les entrées utilisateur

```powershell
function Process-UserInput {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[a-zA-Z0-9_-]+$")]
        [string]$UserInput
    )

    # La validation intégrée garantit que vous recevez des données valides
}
```

#### 3. Limitez la portée des variables

```powershell
# Utilisez $script: pour limiter au script
$script:config = @{ Setting = "Value" }

function Update-Config {
    # Utilisez $private: dans les modules pour des variables très limitées
    $private:tempValue = "SecretValue"

    # Variables locales à la fonction par défaut
    $localVar = "LocalValue"
}
```

### Exemple de script bien structuré

```powershell
#Requires -Version 5.1
#Requires -Modules ActiveDirectory
<#
.SYNOPSIS
    Génère un rapport des comptes utilisateurs inactifs dans Active Directory.
.DESCRIPTION
    Ce script se connecte à Active Directory et génère un rapport CSV des
    comptes utilisateurs qui n'ont pas été utilisés pendant un nombre de jours spécifié.
.PARAMETER DaysInactive
    Nombre de jours d'inactivité pour considérer un compte comme inactif.
.PARAMETER OutputFolder
    Dossier où le rapport CSV sera enregistré.
.EXAMPLE
    .\Get-InactiveADUsers.ps1 -DaysInactive 90 -OutputFolder "C:\Reports"
.NOTES
    Auteur: Formation PowerShell
    Date: 26/04/2025
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 365)]
    [int]$DaysInactive = 90,

    [Parameter(Mandatory=$false)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$OutputFolder = "$env:USERPROFILE\Documents"
)

#region Fonctions

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Afficher sur la console avec couleur
    switch ($Level) {
        "INFO"    { Write-Host $logMessage -ForegroundColor Green }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR"   { Write-Host $logMessage -ForegroundColor Red }
    }

    # Ajouter au fichier log
    $logMessage | Out-File -FilePath $script:LogFile -Append
}

function Get-InactiveUsers {
    [CmdletBinding()]
    param(
        [int]$Days
    )

    Write-Log "Recherche des utilisateurs inactifs depuis plus de $Days jours..."

    try {
        $cutoffDate = (Get-Date).AddDays(-$Days)

        # Filtrer les utilisateurs inactifs
        $inactiveUsers = Get-ADUser -Filter {
            Enabled -eq $true -and LastLogonTimeStamp -lt $cutoffDate
        } -Properties LastLogonTimeStamp, DisplayName, EmailAddress, Department |
        Select-Object SamAccountName, DisplayName, EmailAddress, Department,
            @{Name="LastLogon"; Expression={
                [datetime]::FromFileTime($_.LastLogonTimeStamp)
            }},
            @{Name="DaysInactive"; Expression={
                [math]::Round((New-TimeSpan -Start ([datetime]::FromFileTime($_.LastLogonTimeStamp)) -End (Get-Date)).TotalDays)
            }}

        return $inactiveUsers
    }
    catch {
        Write-Log "Erreur lors de la récupération des utilisateurs inactifs : $_" -Level "ERROR"
        throw $_
    }
}

#endregion

#region Initialisation

# Définir le fichier de log
$script:LogFile = Join-Path -Path $OutputFolder -ChildPath "InactiveUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Définir le fichier de sortie CSV
$csvFile = Join-Path -Path $OutputFolder -ChildPath "InactiveUsers_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

Write-Log "Script démarré - Recherche des comptes inactifs depuis $DaysInactive jours"
Write-Log "Le rapport sera enregistré dans : $csvFile"

#endregion

#region Traitement principal

try {
    # Récupérer les utilisateurs inactifs
    $inactiveUsers = Get-InactiveUsers -Days $DaysInactive

    # Vérifier si des utilisateurs ont été trouvés
    if ($inactiveUsers.Count -eq 0) {
        Write-Log "Aucun utilisateur inactif trouvé." -Level "WARNING"
    }
    else {
        # Exporter vers CSV
        $inactiveUsers | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8

        Write-Log "Rapport généré avec succès. $($inactiveUsers.Count) utilisateurs inactifs trouvés."

        # Afficher un résumé
        Write-Log "Top 5 des utilisateurs les plus inactifs :"
        $inactiveUsers | Sort-Object DaysInactive -Descending | Select-Object -First 5 | ForEach-Object {
            Write-Log "  - $($_.DisplayName) ($($_.SamAccountName)) : $($_.DaysInactive) jours"
        }
    }
}
catch {
    Write-Log "Erreur critique lors de l'exécution du script : $_" -Level "ERROR"
    exit 1
}
finally {
    Write-Log "Script terminé"
}

#endregion
```

### 🔄 Exercices pratiques

1. **Exercice de base** : Prenez un script existant et améliorez sa structure en suivant les bonnes pratiques.

2. **Exercice intermédiaire** : Convertissez plusieurs fonctions liées en un module bien structuré.

3. **Exercice avancé** : Créez un modèle de script et de module que vous pouvez réutiliser pour vos futurs projets.

### 🌟 Résumé des meilleures pratiques

1. **Conventions de nommage**
   - Utilisez Verbe-Nom pour les fonctions
   - Choisissez des noms descriptifs
   - Restez cohérent dans tout votre code

2. **Structure du code**
   - Organisez votre code en sections logiques
   - Utilisez des fonctions pour factoriser
   - Suivez une structure standard pour les scripts et modules

3. **Formatage**
   - Indentez correctement (4 espaces)
   - Utilisez des espaces autour des opérateurs
   - Ajoutez des lignes vides entre les blocs logiques

4. **Documentation**
   - Utilisez des commentaires d'aide pour les fonctions
   - Documentez le but des sections complexes
   - Incluez des exemples d'utilisation

5. **Sécurité et robustesse**
   - Validez toutes les entrées
   - Gérez correctement les erreurs
   - Ne codez jamais d'informations sensibles en dur

Ces bonnes pratiques vous aideront à créer du code PowerShell plus lisible, maintenable et professionnel. Avec le temps, ces pratiques deviendront une seconde nature et amélioreront considérablement la qualité de vos scripts et modules.
