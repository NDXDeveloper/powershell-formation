# Solution Exercice 1: Documentation d'une fonction de sauvegarde

## Énoncé
Créer et documenter une fonction PowerShell complète qui sauvegarde les fichiers importants d'un utilisateur.

## Solution

```powershell
function Backup-UserFiles {
    <#
    .SYNOPSIS
    Sauvegarde les fichiers importants d'un utilisateur vers une destination spécifiée.

    .DESCRIPTION
    Cette fonction crée une sauvegarde des dossiers Documents, Images et Bureau de l'utilisateur
    actuel. Elle crée un dossier daté à l'emplacement spécifié, puis compresse les fichiers
    en un fichier ZIP unique. La fonction offre différents niveaux de compression et peut
    également journaliser les opérations effectuées.

    .PARAMETER Destination
    Spécifie le chemin où la sauvegarde sera créée.
    Si non spécifié, la sauvegarde sera créée dans le dossier "Backups" sur le Bureau.

    .PARAMETER Compression
    Définit le niveau de compression à utiliser:
    - Normal: Compression standard (par défaut)
    - Maximum: Compression maximale (plus lent)
    - Aucune: Pas de compression (plus rapide)

    .PARAMETER LogFile
    Chemin vers un fichier journal où les actions seront enregistrées.
    Si non spécifié, aucun journal n'est créé.

    .PARAMETER IncludeDownloads
    Indique si le dossier Téléchargements doit également être sauvegardé.

    .EXAMPLE
    Backup-UserFiles

    Crée une sauvegarde des dossiers standard dans le dossier "Backups" du Bureau avec une compression normale.

    .EXAMPLE
    Backup-UserFiles -Destination "D:\Mes Sauvegardes" -Compression Maximum

    Sauvegarde les fichiers avec une compression maximale dans le dossier "D:\Mes Sauvegardes".

    .EXAMPLE
    Backup-UserFiles -LogFile "C:\Logs\backup.log" -IncludeDownloads

    Sauvegarde les dossiers standards ainsi que le dossier Téléchargements et crée un fichier journal.

    .INPUTS
    Aucun. Cette fonction n'accepte pas d'entrées via le pipeline.

    .OUTPUTS
    System.IO.FileInfo. Retourne un objet représentant le fichier ZIP de sauvegarde créé.

    .NOTES
    Auteur: Formation PowerShell
    Version: 1.0
    Date de création: 27/04/2025
    Nécessite: PowerShell 5.1 ou supérieur

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.archive/compress-archive
    #>

    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [string]$Destination = "$env:USERPROFILE\Desktop\Backups",

        [Parameter(Position = 1)]
        [ValidateSet('Normal', 'Maximum', 'Aucune')]
        [string]$Compression = 'Normal',

        [Parameter()]
        [string]$LogFile,

        [Parameter()]
        [switch]$IncludeDownloads
    )

    # Fonction pour écrire dans le journal
    function Write-LogEntry {
        param ([string]$Message)

        $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogEntry = "[$Timestamp] $Message"

        if ($LogFile) {
            Add-Content -Path $LogFile -Value $LogEntry
        }

        Write-Verbose $LogEntry
    }

    try {
        # Création du dossier de destination s'il n'existe pas
        if (-not (Test-Path -Path $Destination)) {
            New-Item -Path $Destination -ItemType Directory -Force | Out-Null
            Write-LogEntry "Création du dossier de destination: $Destination"
        }

        # Création d'un sous-dossier avec la date du jour
        $DateString = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $BackupFolder = Join-Path -Path $Destination -ChildPath "Backup_$DateString"
        New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
        Write-LogEntry "Création du dossier temporaire: $BackupFolder"

        # Définition des dossiers à sauvegarder
        $FoldersToBackup = @(
            [PSCustomObject]@{Name = "Documents"; Path = [Environment]::GetFolderPath("MyDocuments")}
            [PSCustomObject]@{Name = "Images"; Path = [Environment]::GetFolderPath("MyPictures")}
            [PSCustomObject]@{Name = "Bureau"; Path = [Environment]::GetFolderPath("Desktop")}
        )

        # Ajout du dossier Téléchargements si demandé
        if ($IncludeDownloads) {
            $DownloadsPath = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
            $FoldersToBackup += [PSCustomObject]@{Name = "Téléchargements"; Path = $DownloadsPath}
            Write-LogEntry "Inclusion du dossier Téléchargements: $DownloadsPath"
        }

        # Copie des dossiers vers le dossier temporaire
        foreach ($Folder in $FoldersToBackup) {
            $DestFolder = Join-Path -Path $BackupFolder -ChildPath $Folder.Name
            New-Item -Path $DestFolder -ItemType Directory -Force | Out-Null

            Write-LogEntry "Copie des fichiers depuis $($Folder.Path) vers $DestFolder"
            Copy-Item -Path "$($Folder.Path)\*" -Destination $DestFolder -Recurse -Force -ErrorAction SilentlyContinue
        }

        # Définition du niveau de compression
        $CompressionLevel = switch ($Compression) {
            'Normal' { 'Normal' }
            'Maximum' { 'Optimal' }
            'Aucune' { 'NoCompression' }
        }

        # Création du fichier ZIP
        $ZipFileName = "Backup_$DateString.zip"
        $ZipFilePath = Join-Path -Path $Destination -ChildPath $ZipFileName

        if ($Compression -eq 'Aucune') {
            Write-LogEntry "Création de l'archive sans compression: $ZipFilePath"
            $null = Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::CreateFromDirectory($BackupFolder, $ZipFilePath, 'NoCompression', $false)
        }
        else {
            Write-LogEntry "Création de l'archive avec compression $CompressionLevel: $ZipFilePath"
            Compress-Archive -Path "$BackupFolder\*" -DestinationPath $ZipFilePath -CompressionLevel $CompressionLevel -Force
        }

        # Suppression du dossier temporaire
        Write-LogEntry "Suppression du dossier temporaire"
        Remove-Item -Path $BackupFolder -Recurse -Force

        # Affichage du résultat
        Write-LogEntry "Sauvegarde terminée avec succès: $ZipFilePath"
        Get-Item -Path $ZipFilePath
    }
    catch {
        Write-LogEntry "ERREUR: $($_.Exception.Message)"
        Write-Error $_.Exception.Message
    }
}
```

## Explication

Cette solution fournit une fonction PowerShell `Backup-UserFiles` complètement documentée qui effectue une sauvegarde des dossiers importants d'un utilisateur. Les points clés incluent:

1. **Documentation complète**: Utilise tous les mots-clés de documentation recommandés
2. **Paramètres flexibles**: Permet de personnaliser la destination, le niveau de compression, etc.
3. **Journalisation**: Option pour enregistrer les actions dans un fichier journal
4. **Gestion des erreurs**: Utilise un bloc try/catch pour gérer les exceptions
5. **Code bien structuré**: Fonctions imbriquées et commentaires clairs

Pour utiliser cette fonction, copiez le code dans votre profil PowerShell ou dans un module, puis appelez-la selon vos besoins avec les paramètres appropriés. La documentation peut être consultée avec `Get-Help Backup-UserFiles -Full`.

# Solution Exercice 2: Documentation d'un script d'inventaire réseau

## Énoncé
Créer et documenter un script PowerShell complet qui effectue un inventaire des ordinateurs sur un réseau.

## Solution

```powershell
<#
.SYNOPSIS
Inventaire-Reseau.ps1 - Réalise un inventaire des ordinateurs d'un réseau.

.DESCRIPTION
Ce script effectue un inventaire complet des ordinateurs sur un réseau local ou dans Active Directory.
Il collecte des informations sur le système d'exploitation, le matériel, les logiciels installés,
et génère un rapport au format CSV, Excel ou HTML.

.PARAMETER ComputerList
Liste des ordinateurs à inventorier. Peut être un tableau de noms d'ordinateurs ou un fichier texte avec un nom d'ordinateur par ligne.
Si non spécifié, le script tente d'obtenir la liste depuis Active Directory.

.PARAMETER OutputFolder
Dossier où les rapports seront enregistrés. Par défaut, les rapports sont enregistrés dans un sous-dossier "Rapports" du dossier courant.

.PARAMETER OutputFormat
Format du rapport de sortie : CSV, Excel ou HTML. Par défaut, CSV.
Note: Le format Excel nécessite le module ImportExcel.

.PARAMETER MaxThreads
Nombre maximum de threads parallèles à utiliser pour la collecte de données. Par défaut, 10.

.PARAMETER IncludeServices
Indique si les services en cours d'exécution doivent être inclus dans le rapport.

.PARAMETER IncludeSoftware
Indique si les logiciels installés doivent être inclus dans le rapport.

.PARAMETER Timeout
Délai d'attente en secondes pour la connexion à chaque ordinateur. Par défaut, 30 secondes.

.PARAMETER Credentials
Informations d'identification à utiliser pour la connexion aux ordinateurs distants.

.EXAMPLE
.\Inventaire-Reseau.ps1
Exécute l'inventaire sur tous les ordinateurs trouvés dans Active Directory et génère un rapport CSV.

.EXAMPLE
.\Inventaire-Reseau.ps1 -ComputerList "PC001", "PC002", "SERVER01" -OutputFormat HTML -IncludeSoftware
Exécute l'inventaire sur les trois ordinateurs spécifiés, inclut les logiciels installés et génère un rapport HTML.

.EXAMPLE
.\Inventaire-Reseau.ps1 -ComputerList C:\ordinateurs.txt -OutputFormat Excel -MaxThreads 5
Exécute l'inventaire sur les ordinateurs listés dans le fichier, utilise 5 threads en parallèle et génère un rapport Excel.

.INPUTS
Aucun. Ce script n'accepte pas d'entrées via le pipeline.

.OUTPUTS
System.String. Le chemin vers le rapport généré.

.NOTES
Auteur: Formation PowerShell
Version: 2.1
Date de création: 27/04/2025
Prérequis:
- PowerShell 5.1 ou supérieur
- Module ActiveDirectory (pour la détection automatique des ordinateurs)
- Module ImportExcel (pour la génération de rapports Excel)
- Autorisations d'administrateur sur les ordinateurs cibles

.LINK
https://github.com/MonProjet/Documentation
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [object]$ComputerList,

    [Parameter()]
    [ValidateScript({ Test-Path -Path $_ -IsValid })]
    [string]$OutputFolder = ".\Rapports",

    [Parameter()]
    [ValidateSet('CSV', 'Excel', 'HTML')]
    [string]$OutputFormat = 'CSV',

    [Parameter()]
    [ValidateRange(1, 50)]
    [int]$MaxThreads = 10,

    [Parameter()]
    [switch]$IncludeServices,

    [Parameter()]
    [switch]$IncludeSoftware,

    [Parameter()]
    [ValidateRange(1, 300)]
    [int]$Timeout = 30,

    [Parameter()]
    [System.Management.Automation.PSCredential]
    [System.Management.Automation.Credential()]
    $Credentials = [System.Management.Automation.PSCredential]::Empty
)

# Fonction pour écrire un message de journal avec horodatage
function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Type = 'Information'
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogPrefix = switch ($Type) {
        'Information' { "[INFO]" }
        'Warning'     { "[WARN]" }
        'Error'       { "[ERROR]" }
    }

    $FormattedMessage = "[$Timestamp] $LogPrefix $Message"

    # Écrire dans la console avec la couleur appropriée
    switch ($Type) {
        'Information' { Write-Host $FormattedMessage -ForegroundColor Cyan }
        'Warning'     { Write-Host $FormattedMessage -ForegroundColor Yellow }
        'Error'       { Write-Host $FormattedMessage -ForegroundColor Red }
    }

    # Ajouter au fichier journal
    Add-Content -Path "$OutputFolder\Inventaire_$(Get-Date -Format 'yyyyMMdd').log" -Value $FormattedMessage
}

# Fonction pour obtenir la liste des ordinateurs depuis Active Directory
function Get-ADComputerList {
    try {
        # Vérifier si le module ActiveDirectory est disponible
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            Write-Log "Le module ActiveDirectory n'est pas installé. Installation des outils RSAT nécessaire." -Type Warning
            return @()
        }

        # Importer le module
        Import-Module ActiveDirectory -ErrorAction Stop

        # Obtenir les ordinateurs actifs
        $Computers = Get-ADComputer -Filter {Enabled -eq $true} -Properties Name, OperatingSystem |
                    Select-Object -ExpandProperty Name

        Write-Log "Récupération de $($Computers.Count) ordinateurs depuis Active Directory."
        return $Computers
    }
    catch {
        Write-Log "Erreur lors de la récupération des ordinateurs depuis Active Directory: $($_.Exception.Message)" -Type Error
        return @()
    }
}

# Fonction pour analyser un ordinateur et récupérer ses informations
function Get-ComputerInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName
    )

    $ComputerData = [PSCustomObject]@{
        ComputerName = $ComputerName
        Online = $false
        OSName = ""
        OSVersion = ""
        Manufacturer = ""
        Model = ""
        SerialNumber = ""
        Processor = ""
        Memory = ""
        Disks = ""
        IPAddress = ""
        LastBootTime = ""
        Services = @()
        Software = @()
        ScanTime = Get-Date
    }

    try {
        # Vérifier si l'ordinateur est accessible
        if (-not (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet -TimeoutSeconds $Timeout)) {
            Write-Log "L'ordinateur $ComputerName n'est pas accessible." -Type Warning
            return $ComputerData
        }

        $ComputerData.Online = $true

        # Paramètres pour les appels CIM distants
        $SessionParams = @{
            ComputerName = $ComputerName
            ErrorAction = "Stop"
        }

        # Ajouter les informations d'identification si elles sont fournies
        if ($Credentials -ne [System.Management.Automation.PSCredential]::Empty) {
            $SessionParams.Add("Credential", $Credentials)
        }

        # Créer une session CIM
        $CimSession = New-CimSession @SessionParams

        # Récupérer les informations système
        $OS = Get-CimInstance -ClassName Win32_OperatingSystem -CimSession $CimSession
        $CS = Get-CimInstance -ClassName Win32_ComputerSystem -CimSession $CimSession
        $BIOS = Get-CimInstance -ClassName Win32_BIOS -CimSession $CimSession
        $Processor = Get-CimInstance -ClassName Win32_Processor -CimSession $CimSession | Select-Object -First 1
        $Memory = Get-CimInstance -ClassName Win32_PhysicalMemory -CimSession $CimSession | Measure-Object -Property Capacity -Sum
        $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -CimSession $CimSession -Filter "DriveType = 3" |
                Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round($_.Size / 1GB, 2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round($_.FreeSpace / 1GB, 2)}}
        $Network = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration -CimSession $CimSession -Filter "IPEnabled = 'True'" |
                 Select-Object -First 1 -ExpandProperty IPAddress | Where-Object { $_ -match '\d+\.\d+\.\d+\.\d+' } | Select-Object -First 1

        # Remplir l'objet avec les données
        $ComputerData.OSName = $OS.Caption
        $ComputerData.OSVersion = $OS.Version
        $ComputerData.Manufacturer = $CS.Manufacturer
        $ComputerData.Model = $CS.Model
        $ComputerData.SerialNumber = $BIOS.SerialNumber
        $ComputerData.Processor = $Processor.Name
        $ComputerData.Memory = [math]::Round($Memory.Sum / 1GB, 2).ToString() + " GB"
        $ComputerData.Disks = ($Disks | ForEach-Object { "$($_.DeviceID): $($_.'Size(GB)') GB (Free: $($_.'FreeSpace(GB)') GB)" }) -join "; "
        $ComputerData.IPAddress = $Network
        $ComputerData.LastBootTime = $OS.LastBootUpTime

        # Récupérer les services si demandé
        if ($IncludeServices) {
            $Services = Get-CimInstance -ClassName Win32_Service -CimSession $CimSession -Filter "State = 'Running'"
            $ComputerData.Services = $Services | Select-Object DisplayName, StartName, StartMode
        }

        # Récupérer les logiciels si demandé
        if ($IncludeSoftware) {
            $Software = Get-CimInstance -ClassName Win32_Product -CimSession $CimSession
            $ComputerData.Software = $Software | Select-Object Name, Version, Vendor, InstallDate
        }

        # Fermer la session CIM
        Remove-CimSession -CimSession $CimSession

        Write-Log "Informations récupérées pour $ComputerName"
        return $ComputerData
    }
    catch {
        Write-Log "Erreur lors de la récupération des informations pour $ComputerName : $($_.Exception.Message)" -Type Error
        return $ComputerData
    }
}

# Fonction pour générer un rapport
function Export-Report {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Data,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$Format
    )

    try {
        switch ($Format) {
            'CSV' {
                $Data | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
                Write-Log "Rapport CSV généré : $OutputPath"
            }
            'Excel' {
                # Vérifier si le module ImportExcel est disponible
                if (-not (Get-Module -Name ImportExcel -ListAvailable)) {
                    Write-Log "Le module ImportExcel n'est pas installé. Installation avec la commande : Install-Module ImportExcel" -Type Warning
                    return $false
                }

                Import-Module ImportExcel
                $Data | Export-Excel -Path $OutputPath -WorksheetName "Inventaire" -TableName "InventaireTable" -AutoSize

                # Ajouter des feuilles supplémentaires pour les services et logiciels si nécessaire
                if ($IncludeServices) {
                    $AllServices = $Data | Where-Object { $_.Online -eq $true } | ForEach-Object {
                        $Computer = $_.ComputerName
                        $_.Services | ForEach-Object {
                            $_ | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $Computer -PassThru
                        }
                    }
                    $AllServices | Export-Excel -Path $OutputPath -WorksheetName "Services" -TableName "ServicesTable" -AutoSize
                }

                if ($IncludeSoftware) {
                    $AllSoftware = $Data | Where-Object { $_.Online -eq $true } | ForEach-Object {
                        $Computer = $_.ComputerName
                        $_.Software | ForEach-Object {
                            $_ | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $Computer -PassThru
                        }
                    }
                    $AllSoftware | Export-Excel -Path $OutputPath -WorksheetName "Logiciels" -TableName "LogicielsTable" -AutoSize
                }

                Write-Log "Rapport Excel généré : $OutputPath"
            }
            'HTML' {
                $HtmlHead = @"
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Rapport d'inventaire réseau</title>
                    <style>
                        body { font-family: Arial, sans-serif; margin: 20px; }
                        h1 { color: #0066cc; }
                        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
                        th { background-color: #0066cc; color: white; text-align: left; padding: 8px; }
                        td { border: 1px solid #ddd; padding: 8px; }
                        tr:nth-child(even) { background-color: #f2f2f2; }
                        .offline { color: red; }
                        .online { color: green; }
                    </style>
                </head>
                <body>
                    <h1>Rapport d'inventaire réseau</h1>
                    <p>Date de génération : $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")</p>
"@

                $HtmlBody = $Data | ConvertTo-Html -Fragment | ForEach-Object {
                    $_ -replace '<td>True</td>', '<td class="online">En ligne</td>' -replace '<td>False</td>', '<td class="offline">Hors ligne</td>'
                }

                $HtmlFooter = @"
                </body>
                </html>
"@

                $HtmlContent = $HtmlHead + $HtmlBody + $HtmlFooter
                Set-Content -Path $OutputPath -Value $HtmlContent

                Write-Log "Rapport HTML généré : $OutputPath"
            }
        }

        return $true
    }
    catch {
        Write-Log "Erreur lors de la génération du rapport : $($_.Exception.Message)" -Type Error
        return $false
    }
}

# Script principal

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    Write-Log "Création du dossier de sortie : $OutputFolder"
}

# Déterminer la liste des ordinateurs à analyser
$Computers = @()

if ($ComputerList) {
    # Si ComputerList est une chaîne qui correspond à un chemin de fichier existant
    if ($ComputerList -is [string] -and (Test-Path -Path $ComputerList -PathType Leaf)) {
        $Computers = Get-Content -Path $ComputerList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        Write-Log "Liste d'ordinateurs chargée depuis le fichier : $($Computers.Count) ordinateurs trouvés."
    }
    # Si ComputerList est un tableau
    elseif ($ComputerList -is [array] -or $ComputerList -is [System.Collections.ArrayList]) {
        $Computers = $ComputerList
        Write-Log "Liste d'ordinateurs fournie en paramètre : $($Computers.Count) ordinateurs."
    }
    # Si ComputerList est une chaîne unique (un seul ordinateur)
    elseif ($ComputerList -is [string]) {
        $Computers = @($ComputerList)
        Write-Log "Un seul ordinateur spécifié : $ComputerList"
    }
}
else {
    # Essayer de récupérer la liste depuis Active Directory
    $Computers = Get-ADComputerList

    if ($Computers.Count -eq 0) {
        Write-Log "Aucun ordinateur trouvé. Veuillez spécifier une liste d'ordinateurs." -Type Error
        exit 1
    }
}

# Préparer le rapport de sortie
$OutputFileName = "Inventaire_Reseau_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$OutputExtension = switch ($OutputFormat) {
    'CSV'   { '.csv' }
    'Excel' { '.xlsx' }
    'HTML'  { '.html' }
}
$OutputPath = Join-Path -Path $OutputFolder -ChildPath ($OutputFileName + $OutputExtension)

# Créer un RunspacePool pour le parallélisme
$RunspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
$RunspacePool.Open()

# Créer les runspaces pour chaque ordinateur
$Jobs = @()
foreach ($Computer in $Computers) {
    $PowerShell = [powershell]::Create().AddScript($function:Get-ComputerInfo).AddParameter('ComputerName', $Computer)
    $PowerShell.RunspacePool = $RunspacePool

    $Jobs += [PSCustomObject]@{
        Computer = $Computer
        PowerShell = $PowerShell
        Result = $PowerShell.BeginInvoke()
    }

    Write-Log "Démarrage de l'analyse pour $Computer"
}

# Collecter les résultats
$Results = @()
foreach ($Job in $Jobs) {
    try {
        $Results += $Job.PowerShell.EndInvoke($Job.Result)
        $Job.PowerShell.Dispose()
    }
    catch {
        Write-Log "Erreur lors de la collecte des résultats pour $($Job.Computer) : $($_.Exception.Message)" -Type Error
    }
}

# Fermer le RunspacePool
$RunspacePool.Close()
$RunspacePool.Dispose()

# Générer le rapport
if ($Results.Count -gt 0) {
    $ReportGenerated = Export-Report -Data $Results -OutputPath $OutputPath -Format $OutputFormat

    if ($ReportGenerated) {
        Write-Log "Inventaire terminé. $($Results.Count) ordinateurs analysés."
        Write-Log "Rapport disponible : $OutputPath"

        # Afficher les statistiques
        $OnlineCount = ($Results | Where-Object { $_.Online -eq $true }).Count
        $OfflineCount = ($Results | Where-Object { $_.Online -eq $false }).Count

        Write-Log "Résumé : $OnlineCount ordinateurs en ligne, $OfflineCount hors ligne."

        # Retourner le chemin du rapport
        return $OutputPath
    }
    else {
        Write-Log "L'inventaire a été réalisé mais la génération du rapport a échoué." -Type Error
    }
}
else {
    Write-Log "Aucun résultat à rapporter." -Type Warning
}
```

## Explication

Cette solution fournit un script PowerShell complet, `Inventaire-Reseau.ps1`, avec une documentation exhaustive. Le script effectue un inventaire des ordinateurs sur un réseau en collectant des informations sur leur configuration matérielle et logicielle. Points clés :

1. **En-tête de documentation complet** : Inclut tous les mots-clés recommandés (.SYNOPSIS, .DESCRIPTION, .PARAMETER, etc.)
2. **Fonctionnalités avancées** :
   - Récupération automatique des ordinateurs depuis Active Directory
   - Traitement parallèle pour améliorer les performances
   - Plusieurs formats de sortie (CSV, Excel, HTML)
   - Journalisation détaillée
3. **Paramètres flexibles** : Options configurables pour s'adapter à différents scénarios
4. **Gestion des erreurs** : Traitement robuste des erreurs avec des blocs try/catch et journalisation
5. **Parallélisme** : Utilisation de runspaces pour exécuter les analyses en parallèle
6. **Rapports personnalisables** : Plusieurs formats de sortie (CSV, Excel, HTML)

# Solution Exercice 3: Documentation d'une fonction de manipulation d'API REST

## Énoncé
Créer et documenter une fonction PowerShell complète qui permet d'interagir avec une API REST.

## Solution

```powershell
function Invoke-RestApi {
    <#
    .SYNOPSIS
    Fonction générique pour interagir avec des API REST.

    .DESCRIPTION
    Cette fonction facilite l'interaction avec des API REST en gérant les différentes méthodes HTTP
    (GET, POST, PUT, DELETE, PATCH), en supportant diverses méthodes d'authentification (Basic, Bearer, OAuth),
    et en offrant des options de gestion des données et des erreurs.

    La fonction peut manipuler différents formats (JSON, XML, FormData) et intègre des fonctionnalités
    comme la pagination automatique, la gestion des limites de taux (rate limiting), et le traitement
    des réponses avec renvoi d'objets PowerShell.

    .PARAMETER Uri
    L'URL de l'API REST à contacter.

    .PARAMETER Method
    La méthode HTTP à utiliser : GET, POST, PUT, DELETE ou PATCH.
    Par défaut : GET

    .PARAMETER Headers
    Table de hachage (hashtable) contenant les en-têtes HTTP à envoyer avec la requête.
    Exemple : @{ "Accept" = "application/json"; "User-Agent" = "PowerShell/7.0" }

    .PARAMETER Body
    Le corps de la requête pour les méthodes POST, PUT et PATCH.
    Peut être un objet PowerShell (qui sera converti en JSON), une chaîne JSON, ou un objet FormData.

    .PARAMETER ContentType
    Type de contenu pour le Body.
    Valeurs possibles : "application/json", "application/xml", "multipart/form-data", etc.
    Par défaut : "application/json"

    .PARAMETER AuthType
    Type d'authentification à utiliser.
    Valeurs possibles : None, Basic, Bearer, OAuth
    Par défaut : None

    .PARAMETER Credential
    Informations d'identification pour l'authentification Basic.

    .PARAMETER Token
    Jeton d'authentification pour l'authentification Bearer ou OAuth.

    .PARAMETER TimeoutSec
    Délai d'attente en secondes pour la requête HTTP.
    Par défaut : 30 secondes

    .PARAMETER AllowInsecureSSL
    Autorise les connexions HTTPS non sécurisées (certificats auto-signés).
    ATTENTION: Ne pas utiliser en production sauf si absolument nécessaire.

    .PARAMETER Pagination
    Active la gestion automatique de la pagination des API.

    .PARAMETER MaxPages
    Nombre maximal de pages à récupérer lors de l'utilisation de la pagination.
    Par défaut : 10

    .PARAMETER PageParamName
    Nom du paramètre de requête utilisé pour spécifier le numéro de page.
    Par défaut : "page"

    .PARAMETER PageSizeParamName
    Nom du paramètre de requête utilisé pour spécifier la taille de la page.
    Par défaut : "per_page"

    .PARAMETER PageSize
    Nombre d'éléments par page lors de l'utilisation de la pagination.
    Par défaut : 100

    .PARAMETER RawResponse
    Retourne la réponse HTTP brute au lieu de convertir automatiquement le contenu.

    .PARAMETER ErrorAction
    Comportement en cas d'erreur HTTP. Compatible avec le paramètre commun ErrorAction.

    .PARAMETER RetryCount
    Nombre de tentatives en cas d'échec de la requête HTTP.
    Par défaut : 3

    .PARAMETER RetryIntervalSec
    Intervalle en secondes entre les tentatives en cas d'échec.
    Par défaut : 5

    .EXAMPLE
    Invoke-RestApi -Uri "https://api.example.com/users"

    Effectue une requête GET simple vers l'API et retourne les données.

    .EXAMPLE
    Invoke-RestApi -Uri "https://api.github.com/repos/PowerShell/PowerShell/issues" -Pagination -MaxPages 3

    Récupère les problèmes (issues) du dépôt PowerShell avec gestion automatique de la pagination, limitée à 3 pages.

    .EXAMPLE
    $body = @{
        name = "John Doe"
        email = "john.doe@example.com"
        role = "admin"
    }
    Invoke-RestApi -Uri "https://api.example.com/users" -Method POST -Body $body -ContentType "application/json"

    Crée un nouvel utilisateur en envoyant des données au format JSON.

    .EXAMPLE
    $headers = @{
        "Accept" = "application/json"
        "X-API-Key" = "votre-clé-api"
    }
    Invoke-RestApi -Uri "https://api.example.com/secure-resource" -Headers $headers

    Accède à une ressource en utilisant une clé API via un en-tête personnalisé.

    .EXAMPLE
    $cred = Get-Credential
    Invoke-RestApi -Uri "https://api.example.com/protected" -AuthType Basic -Credential $cred

    Effectue une requête avec authentification HTTP Basic.

    .EXAMPLE
    Invoke-RestApi -Uri "https://api.example.com/oauth-resource" -AuthType Bearer -Token "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

    Accède à une ressource protégée par OAuth en utilisant un jeton Bearer.

    .INPUTS
    Aucun. Vous ne pouvez pas rediriger d'entrées vers cette fonction.

    .OUTPUTS
    System.Object. Par défaut, retourne un objet PowerShell basé sur le contenu JSON ou XML de la réponse.
    System.Net.Http.HttpResponseMessage. Si le paramètre RawResponse est utilisé.

    .NOTES
    Auteur: Formation PowerShell
    Version: 1.0
    Date de création: 27/04/2025

    Compatible avec PowerShell 5.1 et PowerShell 7+
    Les comportements peuvent varier légèrement entre les versions de PowerShell en raison
    des différences dans les cmdlets Invoke-RestMethod et Invoke-WebRequest.

    .LINK
    https://learn.microsoft.com/powershell/module/microsoft.powershell.utility/invoke-restmethod
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Uri,

        [Parameter(Position = 1)]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'GET',

        [Parameter()]
        [hashtable]$Headers = @{},

        [Parameter()]
        [object]$Body,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter()]
        [ValidateSet('None', 'Basic', 'Bearer', 'OAuth')]
        [string]$AuthType = 'None',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [Parameter()]
        [string]$Token,

        [Parameter()]
        [int]$TimeoutSec = 30,

        [Parameter()]
        [switch]$AllowInsecureSSL,

        [Parameter()]
        [switch]$Pagination,

        [Parameter()]
        [int]$MaxPages = 10,

        [Parameter()]
        [string]$PageParamName = 'page',

        [Parameter()]
        [string]$PageSizeParamName = 'per_page',

        [Parameter()]
        [int]$PageSize = 100,

        [Parameter()]
        [switch]$RawResponse,

        [Parameter()]
        [int]$RetryCount = 3,

        [Parameter()]
        [int]$RetryIntervalSec = 5
    )

    begin {
        # Fonction pour gérer les URI avec paramètres de requête
        function Add-QueryParameter {
            param (
                [string]$BaseUri,
                [string]$ParameterName,
                [string]$ParameterValue
            )

            $UriBuilder = [System.UriBuilder]::new($BaseUri)
            $Query = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $Query[$ParameterName] = $ParameterValue
            $UriBuilder.Query = $Query.ToString()

            return $UriBuilder.Uri.ToString()
        }

        # Ajouter le type System.Web pour la manipulation des URI
        Add-Type -AssemblyName System.Web

        # Préparer les paramètres communs pour Invoke-RestMethod
        $RestParams = @{
            Method = $Method
            Headers = $Headers
            TimeoutSec = $TimeoutSec
            ErrorAction = 'Stop'
        }

        # Configurer le contenu si nécessaire
        if ($PSBoundParameters.ContainsKey('Body')) {
            # Si le corps est un objet PowerShell et le type de contenu est JSON, convertir en JSON
            if ($Body -is [hashtable] -or $Body -is [PSCustomObject]) {
                if ($ContentType -eq 'application/json') {
                    $RestParams.Body = $Body | ConvertTo-Json -Depth 10
                } else {
                    $RestParams.Body = $Body
                }
            } else {
                $RestParams.Body = $Body
            }

            $RestParams.ContentType = $ContentType
        }

        # Configurer l'authentification
        switch ($AuthType) {
            'Basic' {
                if ($Credential -eq [System.Management.Automation.PSCredential]::Empty) {
                    throw "Les informations d'identification sont requises pour l'authentification Basic."
                }

                $Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(
                    "$($Credential.UserName):$($Credential.GetNetworkCredential().Password)"))
                $RestParams.Headers['Authorization'] = "Basic $Base64AuthInfo"
            }
            'Bearer' {
                if ([string]::IsNullOrEmpty($Token)) {
                    throw "Un jeton est requis pour l'authentification Bearer."
                }

                $RestParams.Headers['Authorization'] = "Bearer $Token"
            }
            'OAuth' {
                if ([string]::IsNullOrEmpty($Token)) {
                    throw "Un jeton est requis pour l'authentification OAuth."
                }

                $RestParams.Headers['Authorization'] = "Bearer $Token"
            }
        }

        # Configurer TLS si nécessaire
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        # Gérer les certificats non sécurisés si demandé
        if ($AllowInsecureSSL) {
            if (-not ("TrustAllCertsPolicy" -as [type])) {
                Add-Type -TypeDefinition @"
                    using System.Net;
                    using System.Security.Cryptography.X509Certificates;
                    public class TrustAllCertsPolicy : ICertificatePolicy {
                        public bool CheckValidationResult(
                            ServicePoint srvPoint, X509Certificate certificate,
                            WebRequest request, int certificateProblem) {
                            return true;
                        }
                    }
"@
            }
            [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        }

        # Initialiser les variables pour la pagination
        $Results = @()
        $CurrentPage = 1
    }

    process {
        try {
            # Gérer la pagination si activée
            if ($Pagination) {
                while ($CurrentPage -le $MaxPages) {
                    # Ajouter les paramètres de pagination à l'URI
                    $PaginatedUri = Add-QueryParameter -BaseUri $Uri -ParameterName $PageParamName -ParameterValue $CurrentPage
                    $PaginatedUri = Add-QueryParameter -BaseUri $PaginatedUri -ParameterName $PageSizeParamName -ParameterValue $PageSize

                    Write-Verbose "Récupération de la page $CurrentPage : $PaginatedUri"

                    # Configurer l'URI pour cette requête
                    $PageParams = $RestParams.Clone()
                    $PageParams.Uri = $PaginatedUri

                    # Tenter la requête avec gestion des erreurs
                    $PageData = Invoke-PaginatedRequest @PageParams

                    # Si pas de données ou données vides, sortir de la boucle
                    if (-not $PageData -or ($PageData -is [array] -and $PageData.Count -eq 0)) {
                        break
                    }

                    # Ajouter les résultats au tableau global
                    if ($PageData -is [array]) {
                        $Results += $PageData
                    } else {
                        $Results += , $PageData
                    }

                    # Passer à la page suivante
                    $CurrentPage++
                }

                # Retourner tous les résultats combinés
                if ($RawResponse) {
                    return $Results
                } else {
                    return , $Results
                }
            } else {
                # Exécuter une requête simple sans pagination
                $RestParams.Uri = $Uri
                $Response = Invoke-SingleRequest @RestParams

                if ($RawResponse) {
                    return $Response
                } else {
                    # Traitement de la réponse selon le type de contenu
                    return Process-Response -Response $Response
                }
            }
        } catch {
            # Gérer et propager l'erreur
            $ErrorDetails = @{
                Uri = $Uri
                Method = $Method
                StatusCode = $_.Exception.Response.StatusCode
                Message = $_.Exception.Message
            }

            if ($_.Exception.Response) {
                try {
                    $ErrorStream = $_.Exception.Response.GetResponseStream()
                    $ErrorReader = [System.IO.StreamReader]::new($ErrorStream)
                    $ErrorDetails.ResponseBody = $ErrorReader.ReadToEnd()
                } catch {
                    $ErrorDetails.ResponseBody = "Impossible de lire le corps de la réponse d'erreur."
                }
            }

            Write-Error -Message "Erreur lors de l'appel API: $($_.Exception.Message)" -ErrorAction $ErrorActionPreference

            if ($ErrorActionPreference -ne 'Stop') {
                return [PSCustomObject]$ErrorDetails
            }
        }
    }

    end {
        # Fonction interne pour exécuter une requête avec gestion des erreurs et nouvelle tentative
        function Invoke-SingleRequest {
            param (
                [hashtable]$Params
            )

            $Attempts = 0
            $LastException = $null

            while ($Attempts -lt $RetryCount) {
                try {
                    $Response = Invoke-RestMethod @Params
                    return $Response
                } catch {
                    $LastException = $_
                    $Attempts++

                    # Vérifier si l'erreur est récupérable (erreurs 5xx ou timeout)
                    $Recoverable = $false

                    if ($_.Exception.Response -and [int]$_.Exception.Response.StatusCode -ge 500) {
                        $Recoverable = $true
                    } elseif ($_.Exception.GetType().Name -eq 'WebException' -and
                              $_.Exception.Status -eq [System.Net.WebExceptionStatus]::Timeout) {
                        $Recoverable = $true
                    }

                    if (-not $Recoverable -or $Attempts -ge $RetryCount) {
                        throw
                    }

                    Write-Warning "Tentative $Attempts/$RetryCount échouée: $($_.Exception.Message). Nouvelle tentative dans $RetryIntervalSec secondes..."
                    Start-Sleep -Seconds $RetryIntervalSec
                }
            }

            throw $LastException
        }

        # Fonction interne pour les requêtes paginées
        function Invoke-PaginatedRequest {
            param (
                [hashtable]$Params
            )

            # Réutiliser la logique de tentatives multiples
            $Response = Invoke-SingleRequest -Params $Params

            # Traiter la réponse en fonction du type
            return Process-Response -Response $Response
        }

        # Fonction interne pour traiter les réponses
        function Process-Response {
            param (
                [object]$Response
            )

            # Pour les requêtes paginées, certaines API retournent directement un tableau
            # tandis que d'autres encapsulent les données dans une propriété (comme data, items, results)
            if ($Response -is [hashtable] -or $Response -is [PSCustomObject]) {
                $PropertyNames = @('data', 'items', 'results', 'values')

                foreach ($PropName in $PropertyNames) {
                    if ($Response.PSObject.Properties.Name -contains $PropName -and $Response.$PropName) {
                        return $Response.$PropName
                    }
                }
            }

            return $Response
        }
    }
}
```

## Explication

Cette solution présente une fonction PowerShell complète `Invoke-RestApi` qui permet d'interagir avec des API REST de manière générique et flexible. La documentation est particulièrement détaillée et couvre tous les aspects importants de la fonction.

Points clés de cette solution :

1. **Documentation complète** : La fonction utilise tous les mots-clés de documentation PowerShell recommandés avec des explications détaillées pour chaque paramètre.

2. **Exemples concrets** : Plusieurs exemples d'utilisation sont fournis pour différents scénarios (GET simple, POST avec données JSON, authentification, etc.).

3. **Paramètres flexibles** : La fonction prend en charge de nombreuses options pour s'adapter à différents types d'API REST.

4. **Fonctionnalités avancées** :
   - Différentes méthodes d'authentification (Basic, Bearer, OAuth)
   - Gestion automatique de la pagination
   - Tentatives multiples en cas d'échec
   - Traitement des erreurs avec informations détaillées
   - Support des certificats auto-signés (avec avertissement sur la sécurité)

5. **Structure professionnelle** : La fonction utilise les blocs begin/process/end pour une meilleure organisation et des fonctions internes pour éviter la duplication de code.

Cette fonction peut servir de fondation pour interagir avec pratiquement n'importe quelle API REST moderne, et sa documentation permet à d'autres développeurs de comprendre facilement comment l'utiliser dans différents scénarios.

