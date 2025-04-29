#===============================================================================
# Module 5 - Gestion des fichiers et du système
# Script de fonctions utilitaires
#===============================================================================

<#
.SYNOPSIS
    Collection de fonctions utilitaires pour la gestion des fichiers et du système.
.DESCRIPTION
    Ce script contient des fonctions utilitaires couvrant les aspects du Module 5:
    - Navigation et gestion des fichiers/dossiers
    - Lecture/écriture de différents formats de fichiers
    - Gestion des permissions NTFS
    - Compression et archivage
    - Manipulation des dates et durées
.NOTES
    Auteur: Formation PowerShell - Du Débutant à l'Expert
    Date: Avril 2025
.EXAMPLE
    # Importer le script
    . .\outils.ps1

    # Utiliser une fonction
    Get-LargestFiles -Path C:\Windows -Count 10
#>

#===============================================================================
# 5-1. Utilitaires pour fichiers, dossiers et chemins
#===============================================================================

function Get-LargestFiles {
    <#
    .SYNOPSIS
        Trouve les fichiers les plus volumineux dans un dossier.
    .PARAMETER Path
        Chemin du dossier à analyser
    .PARAMETER Count
        Nombre de fichiers à retourner (10 par défaut)
    .PARAMETER Recurse
        Indique s'il faut rechercher récursivement dans les sous-dossiers
    #>
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [int]$Count = 10,

        [switch]$Recurse
    )

    $params = @{
        Path = $Path
        File = $true
        ErrorAction = "SilentlyContinue"
    }

    if ($Recurse) {
        $params.Recurse = $true
    }

    Get-ChildItem @params |
        Sort-Object Length -Descending |
        Select-Object -First $Count |
        Select-Object FullName, @{Name="Size(MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}}
}

function Find-EmptyFolders {
    <#
    .SYNOPSIS
        Identifie les dossiers vides dans un chemin donné.
    .PARAMETER Path
        Chemin à analyser
    .PARAMETER DeleteEmpty
        Si spécifié, supprime les dossiers vides trouvés
    #>
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$DeleteEmpty
    )

    $emptyFolders = Get-ChildItem -Path $Path -Directory -Recurse |
        Where-Object { (Get-ChildItem -Path $_.FullName -Force).Count -eq 0 }

    if ($emptyFolders.Count -eq 0) {
        Write-Host "Aucun dossier vide trouvé." -ForegroundColor Green
        return
    }

    if ($DeleteEmpty) {
        foreach ($folder in $emptyFolders) {
            Remove-Item -Path $folder.FullName -Force
            Write-Host "Supprimé: $($folder.FullName)" -ForegroundColor Yellow
        }
    } else {
        $emptyFolders | Select-Object FullName
    }
}

function Get-DuplicateFiles {
    <#
    .SYNOPSIS
        Recherche les fichiers en double basés sur leur taille et contenu.
    .PARAMETER Path
        Chemin du dossier à analyser
    .PARAMETER Recurse
        Indique s'il faut analyser les sous-dossiers également
    #>
    param (
        [Parameter(Mandatory)]
        [string]$Path,

        [switch]$Recurse
    )

    $files = Get-ChildItem -Path $Path -File -Recurse:$Recurse

    # Première étape: regrouper par taille
    $sizeGroups = $files | Group-Object Length | Where-Object { $_.Count -gt 1 }

    $duplicates = @()

    foreach ($sizeGroup in $sizeGroups) {
        # Deuxième étape: pour chaque groupe de même taille, calculer le hash
        $hashGroups = $sizeGroup.Group | ForEach-Object {
            $hash = (Get-FileHash -Path $_.FullName).Hash
            [PSCustomObject]@{
                File = $_
                Hash = $hash
            }
        } | Group-Object Hash

        # Ne garder que les groupes avec des hash identiques (vrais doublons)
        $duplicateGroups = $hashGroups | Where-Object { $_.Count -gt 1 }

        foreach ($group in $duplicateGroups) {
            $duplicates += [PSCustomObject]@{
                Hash = $group.Name
                Size = $group.Group[0].File.Length
                Files = $group.Group.File.FullName
            }
        }
    }

    return $duplicates
}

#===============================================================================
# 5-2. Utilitaires pour lecture/écriture de fichiers
#===============================================================================

function ConvertTo-FlatObject {
    <#
    .SYNOPSIS
        Transforme un objet imbriqué (JSON) en structure plate pour CSV.
    .PARAMETER InputObject
        Objet à aplatir
    .PARAMETER Prefix
        Préfixe à utiliser pour les noms de propriétés
    .EXAMPLE
        $jsonContent = Get-Content -Path "data.json" -Raw | ConvertFrom-Json
        $flatData = ConvertTo-FlatObject -InputObject $jsonContent
        $flatData | Export-Csv -Path "data_flat.csv" -NoTypeInformation
    #>
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$InputObject,

        [string]$Prefix = ""
    )

    process {
        $result = [ordered]@{}

        foreach ($property in $InputObject.PSObject.Properties) {
            $key = if ($Prefix) { "$Prefix.$($property.Name)" } else { $property.Name }

            if ($property.Value -is [System.Management.Automation.PSCustomObject] -or $property.Value -is [hashtable]) {
                # Propriété est un objet imbriqué, appel récursif
                $nested = ConvertTo-FlatObject -InputObject $property.Value -Prefix $key
                $result += $nested
            }
            elseif ($property.Value -is [array]) {
                # Traiter les tableaux
                for ($i = 0; $i -lt $property.Value.Count; $i++) {
                    $arrayValue = $property.Value[$i]

                    if ($arrayValue -is [System.Management.Automation.PSCustomObject] -or $arrayValue -is [hashtable]) {
                        $nested = ConvertTo-FlatObject -InputObject $arrayValue -Prefix "$key[$i]"
                        $result += $nested
                    }
                    else {
                        $result["$key[$i]"] = $arrayValue
                    }
                }
            }
            else {
                # Propriété simple
                $result[$key] = $property.Value
            }
        }

        return [PSCustomObject]$result
    }
}

function Convert-CsvToJson {
    <#
    .SYNOPSIS
        Convertit un fichier CSV en JSON.
    .PARAMETER CsvPath
        Chemin du fichier CSV source
    .PARAMETER JsonPath
        Chemin du fichier JSON de destination
    .PARAMETER Delimiter
        Délimiteur utilisé dans le CSV (par défaut: ',')
    #>
    param (
        [Parameter(Mandatory)]
        [string]$CsvPath,

        [Parameter(Mandatory)]
        [string]$JsonPath,

        [string]$Delimiter = ","
    )

    if (-not (Test-Path -Path $CsvPath)) {
        Write-Error "Le fichier CSV n'existe pas: $CsvPath"
        return
    }

    $csvData = Import-Csv -Path $CsvPath -Delimiter $Delimiter
    $jsonData = $csvData | ConvertTo-Json -Depth 10

    $jsonData | Out-File -FilePath $JsonPath -Encoding utf8

    Write-Host "Conversion terminée. Fichier JSON créé: $JsonPath" -ForegroundColor Green
}

function Convert-XmlToCsv {
    <#
    .SYNOPSIS
        Convertit un fichier XML en CSV.
    .PARAMETER XmlPath
        Chemin du fichier XML source
    .PARAMETER CsvPath
        Chemin du fichier CSV de destination
    .PARAMETER XPath
        Expression XPath pour sélectionner les éléments (ex: "/Racine/Element")
    .PARAMETER Delimiter
        Délimiteur à utiliser dans le CSV (par défaut: ',')
    #>
    param (
        [Parameter(Mandatory)]
        [string]$XmlPath,

        [Parameter(Mandatory)]
        [string]$CsvPath,

        [Parameter(Mandatory)]
        [string]$XPath,

        [string]$Delimiter = ","
    )

    if (-not (Test-Path -Path $XmlPath)) {
        Write-Error "Le fichier XML n'existe pas: $XmlPath"
        return
    }

    [xml]$xml = Get-Content -Path $XmlPath
    $nodes = $xml.SelectNodes($XPath)

    if ($nodes.Count -eq 0) {
        Write-Warning "Aucun nœud trouvé avec l'expression XPath: $XPath"
        return
    }

    # Convertir les nœuds XML en objets PowerShell
    $objects = foreach ($node in $nodes) {
        $obj = [ordered]@{}

        foreach ($attr in $node.Attributes) {
            $obj[$attr.Name] = $attr.Value
        }

        foreach ($child in $node.ChildNodes) {
            if ($child.NodeType -eq "Element") {
                $obj[$child.Name] = $child.InnerText
            }
        }

        [PSCustomObject]$obj
    }

    # Exporter en CSV
    $objects | Export-Csv -Path $CsvPath -NoTypeInformation -Delimiter $Delimiter

    Write-Host "Conversion terminée. Fichier CSV créé: $CsvPath" -ForegroundColor Green
}

#===============================================================================
# 5-3. Utilitaires pour permissions NTFS
#===============================================================================

function Backup-FolderPermissions {
    <#
    .SYNOPSIS
        Sauvegarde les permissions NTFS d'un dossier.
    .PARAMETER FolderPath
        Chemin du dossier à analyser
    .PARAMETER OutputPath
        Chemin du fichier de sauvegarde (CSV)
    #>
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [string]$OutputPath = "permissions_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier n'existe pas: $FolderPath"
        return
    }

    $permissionData = Get-ChildItem -Path $FolderPath -Recurse | ForEach-Object {
        $acl = Get-Acl -Path $_.FullName

        foreach ($access in $acl.Access) {
            [PSCustomObject]@{
                Path = $_.FullName
                IsFolder = $_.PSIsContainer
                IdentityReference = $access.IdentityReference
                AccessControlType = $access.AccessControlType
                FileSystemRights = $access.FileSystemRights
                IsInherited = $access.IsInherited
                InheritanceFlags = $access.InheritanceFlags
                PropagationFlags = $access.PropagationFlags
            }
        }
    }

    $permissionData | Export-Csv -Path $OutputPath -NoTypeInformation

    Write-Host "Permissions sauvegardées dans: $OutputPath" -ForegroundColor Green
    return $OutputPath
}

function Restore-FolderPermissions {
    <#
    .SYNOPSIS
        Restaure les permissions NTFS à partir d'une sauvegarde.
    .PARAMETER BackupPath
        Chemin du fichier de sauvegarde CSV
    .PARAMETER WhatIf
        Mode simulation sans appliquer les changements
    #>
    param (
        [Parameter(Mandatory)]
        [string]$BackupPath,

        [switch]$WhatIf
    )

    if (-not (Test-Path -Path $BackupPath)) {
        Write-Error "Le fichier de sauvegarde n'existe pas: $BackupPath"
        return
    }

    $permissionData = Import-Csv -Path $BackupPath
    $uniquePaths = $permissionData | Select-Object -ExpandProperty Path -Unique

    foreach ($path in $uniquePaths) {
        if (-not (Test-Path -Path $path)) {
            Write-Warning "Chemin non trouvé, ignoré: $path"
            continue
        }

        $acl = New-Object System.Security.AccessControl.FileSystemSecurity
        $pathEntries = $permissionData | Where-Object { $_.Path -eq $path }

        foreach ($entry in $pathEntries) {
            $identity = $entry.IdentityReference
            $rights = [System.Security.AccessControl.FileSystemRights]$entry.FileSystemRights
            $type = [System.Security.AccessControl.AccessControlType]$entry.AccessControlType
            $inheritance = [System.Security.AccessControl.InheritanceFlags]$entry.InheritanceFlags
            $propagation = [System.Security.AccessControl.PropagationFlags]$entry.PropagationFlags

            $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($identity, $rights, $inheritance, $propagation, $type)
            $acl.AddAccessRule($accessRule)

            if (-not $WhatIf) {
                Write-Host "Restauration des permissions pour: $path" -ForegroundColor Cyan
            }
            else {
                Write-Host "[SIMULATION] Restauration des permissions pour: $path" -ForegroundColor Yellow
            }
        }

        if (-not $WhatIf) {
            $acl | Set-Acl -Path $path
        }
    }

    Write-Host "Restauration terminée." -ForegroundColor Green
}

function Grant-UserAccess {
    <#
    .SYNOPSIS
        Accorde des droits à un utilisateur sur un dossier et ses sous-dossiers.
    .PARAMETER FolderPath
        Chemin du dossier
    .PARAMETER Identity
        Nom de l'utilisateur ou du groupe (ex: "DOMAIN\User")
    .PARAMETER Rights
        Droits à accorder (ex: "ReadAndExecute", "Modify", "FullControl")
    #>
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [Parameter(Mandatory)]
        [string]$Identity,

        [Parameter(Mandatory)]
        [ValidateSet("ReadAndExecute", "Modify", "FullControl")]
        [string]$Rights
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier n'existe pas: $FolderPath"
        return
    }

    $acl = Get-Acl -Path $FolderPath

    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Identity,
        $Rights,
        "ContainerInherit,ObjectInherit",
        "None",
        "Allow"
    )

    $acl.AddAccessRule($accessRule)
    $acl | Set-Acl -Path $FolderPath

    Write-Host "Droit '$Rights' accordé à '$Identity' sur le dossier: $FolderPath" -ForegroundColor Green
}

#===============================================================================
# 5-4. Utilitaires pour compression et archivage
#===============================================================================

function Compress-OldFiles {
    <#
    .SYNOPSIS
        Compresse les fichiers plus anciens qu'une certaine date.
    .PARAMETER FolderPath
        Chemin du dossier à analyser
    .PARAMETER DaysOld
        Âge minimum des fichiers en jours
    .PARAMETER ArchivePath
        Chemin de l'archive à créer/mettre à jour
    .PARAMETER DeleteAfterArchive
        Supprime les fichiers après compression
    #>
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [Parameter(Mandatory)]
        [int]$DaysOld,

        [string]$ArchivePath,

        [switch]$DeleteAfterArchive
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier n'existe pas: $FolderPath"
        return
    }

    $dateLimite = (Get-Date).AddDays(-$DaysOld)

    $oldFiles = Get-ChildItem -Path $FolderPath -File -Recurse |
        Where-Object { $_.LastWriteTime -lt $dateLimite }

    if ($oldFiles.Count -eq 0) {
        Write-Host "Aucun fichier plus ancien que $DaysOld jours trouvé." -ForegroundColor Yellow
        return
    }

    if (-not $ArchivePath) {
        $ArchivePath = Join-Path -Path $FolderPath -ChildPath "archive_$(Get-Date -Format 'yyyyMMdd').zip"
    }

    # Vérifier si l'archive existe déjà
    $updateFlag = Test-Path -Path $ArchivePath

    # Utiliser des paramètres différents selon si l'archive existe ou non
    $compressParams = @{
        Path = $oldFiles.FullName
        DestinationPath = $ArchivePath
        CompressionLevel = "Optimal"
    }

    if ($updateFlag) {
        $compressParams.Update = $true
    }

    try {
        Compress-Archive @compressParams
        Write-Host "Compression réussie: $($oldFiles.Count) fichiers dans $ArchivePath" -ForegroundColor Green

        if ($DeleteAfterArchive) {
            $oldFiles | Remove-Item -Force
            Write-Host "Fichiers originaux supprimés." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Error "Erreur lors de la compression: $_"
    }
}

function Expand-ArchiveWithProgress {
    <#
    .SYNOPSIS
        Extrait une archive ZIP avec barre de progression.
    .PARAMETER ArchivePath
        Chemin de l'archive à extraire
    .PARAMETER DestinationPath
        Dossier de destination
    .PARAMETER Force
        Écrase les fichiers existants
    #>
    param (
        [Parameter(Mandatory)]
        [string]$ArchivePath,

        [Parameter(Mandatory)]
        [string]$DestinationPath,

        [switch]$Force
    )

    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Error "L'archive n'existe pas: $ArchivePath"
        return
    }

    # Créer le dossier de destination s'il n'existe pas
    if (-not (Test-Path -Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
    }

    # Obtenir le nombre total d'entrées dans l'archive
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
    $totalEntries = $zip.Entries.Count
    $zip.Dispose()

    if ($totalEntries -eq 0) {
        Write-Warning "L'archive est vide."
        return
    }

    # Préparer les paramètres pour l'extraction
    $expandParams = @{
        Path = $ArchivePath
        DestinationPath = $DestinationPath
        PassThru = $true
    }

    if ($Force) {
        $expandParams.Force = $true
    }

    # Extraire avec progression
    $i = 0
    Expand-Archive @expandParams | ForEach-Object {
        $i++
        $percentComplete = [math]::Round(($i / $totalEntries) * 100)

        Write-Progress -Activity "Extraction de $ArchivePath" `
            -Status "$i sur $totalEntries fichiers ($percentComplete%)" `
            -PercentComplete $percentComplete

        # Retourner les fichiers extraits
        $_
    }

    Write-Progress -Activity "Extraction terminée" -Completed

    Write-Host "Extraction terminée: $totalEntries fichiers extraits vers $DestinationPath" -ForegroundColor Green
}

function Get-ArchiveContent {
    <#
    .SYNOPSIS
        Affiche le contenu d'une archive sans l'extraire.
    .PARAMETER ArchivePath
        Chemin de l'archive à analyser
    .PARAMETER Filter
        Filtre optionnel (ex: "*.txt")
    #>
    param (
        [Parameter(Mandatory)]
        [string]$ArchivePath,

        [string]$Filter
    )

    if (-not (Test-Path -Path $ArchivePath)) {
        Write-Error "L'archive n'existe pas: $ArchivePath"
        return
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)

    try {
        $entries = $zip.Entries

        if ($Filter) {
            $entries = $entries | Where-Object { $_.Name -like $Filter }
        }

        $results = $entries | ForEach-Object {
            [PSCustomObject]@{
                Name = $_.Name
                Path = $_.FullName
                Size = $_.Length
                CompressedSize = $_.CompressedLength
                "Ratio %" = if ($_.Length -gt 0) { [math]::Round(($_.CompressedLength / $_.Length) * 100, 1) } else { 0 }
                LastModified = $_.LastWriteTime
            }
        }

        return $results
    }
    finally {
        $zip.Dispose()
    }
}

#===============================================================================
# 5-5. Utilitaires pour dates et temps
#===============================================================================

function Get-FileAge {
    <#
    .SYNOPSIS
        Calcule l'âge des fichiers dans un dossier.
    .PARAMETER FolderPath
        Chemin du dossier à analyser
    .PARAMETER Recurse
        Indique s'il faut analyser les sous-dossiers
    .PARAMETER MinAgeDays
        Filtre pour l'âge minimum en jours
    #>
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [switch]$Recurse,

        [int]$MinAgeDays = 0
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier n'existe pas: $FolderPath"
        return
    }

    $now = Get-Date

    $files = Get-ChildItem -Path $FolderPath -File -Recurse:$Recurse | ForEach-Object {
        $ageCreation = $now - $_.CreationTime
        $ageModification = $now - $_.LastWriteTime
        $ageAccess = $now - $_.LastAccessTime

        [PSCustomObject]@{
            File = $_.FullName
            "Age (jours)" = [math]::Round($ageCreation.TotalDays, 1)
            "Jours depuis modification" = [math]::Round($ageModification.TotalDays, 1)
            "Jours depuis accès" = [math]::Round($ageAccess.TotalDays, 1)
            "Créé le weekend" = ($_.CreationTime.DayOfWeek -eq "Saturday" -or $_.CreationTime.DayOfWeek -eq "Sunday")
            "Taille (KB)" = [math]::Round($_.Length / 1KB, 1)
            "Date création" = $_.CreationTime
            "Dernière modification" = $_.LastWriteTime
        }
    }

    if ($MinAgeDays -gt 0) {
        $files = $files | Where-Object { $_."Age (jours)" -ge $MinAgeDays }
    }

    return $files
}

function New-DateRangeReport {
    <#
    .SYNOPSIS
        Crée un rapport d'activité par plage de dates.
    .PARAMETER FolderPath
        Chemin du dossier à analyser
    .PARAMETER Start
        Date de début de la plage
    .PARAMETER End
        Date de fin de la plage
    .PARAMETER GroupBy
        Mode de regroupement (Day, Week, Month, Year)
    #>
    param (
        [Parameter(Mandatory)]
        [string]$FolderPath,

        [DateTime]$Start = (Get-Date).AddMonths(-1),

        [DateTime]$End = (Get-Date),

        [ValidateSet("Day", "Week", "Month", "Year")]
        [string]$GroupBy = "Day"
    )

    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Error "Le dossier n'existe pas: $FolderPath"
        return
    }

    $files = Get-ChildItem -Path $FolderPath -File -Recurse |
        Where-Object { $_.LastWriteTime -ge $Start -and $_.LastWriteTime -le $End }

    if ($files.Count -eq 0) {
        Write-Host "Aucun fichier trouvé dans la plage de dates spécifiée." -ForegroundColor Yellow
        return
    }

    # Fonction pour normaliser la date selon le mode de regroupement
    function Get-NormalizedDate {
        param ([DateTime]$Date, [string]$GroupBy)

        switch ($GroupBy) {
            "Day" { return $Date.Date }
            "Week" {
                $startOfWeek = $Date.Date.AddDays(-([int]$Date.DayOfWeek))
                return $startOfWeek
            }
            "Month" { return Get-Date -Year $Date.Year -Month $Date.Month -Day 1 }
            "Year" { return Get-Date -Year $Date.Year -Month 1 -Day 1 }
        }
    }

    # Grouper les fichiers selon la période choisie
    $groupedFiles = $files | ForEach-Object {
        $groupDate = Get-NormalizedDate -Date $_.LastWriteTime -GroupBy $GroupBy
        [PSCustomObject]@{
            File = $_
            GroupDate = $groupDate
        }
    } | Group-Object -Property GroupDate

    # Créer le rapport
    $report = $groupedFiles | ForEach-Object {
        $filesInGroup = $_.Group.File
        $totalSize = ($filesInGroup | Measure-Object -Property Length -Sum).Sum

        [PSCustomObject]@{
            Période = switch ($GroupBy) {
                "Day" { $_.Name }
                "Week" { "Semaine du $($_.Name)" }
                "Month" { (Get-Date -Date $_.Name).ToString("MMMM yyyy") }
                "Year" { (Get-Date -Date $_.Name).ToString("yyyy") }
            }
            "Nombre de fichiers" = $filesInGroup.Count
            "Taille totale (MB)" = [math]::Round($totalSize / 1MB, 2)
            "Plus gros fichier" = ($filesInGroup | Sort-Object Length -Descending | Select-Object -First 1).Name
            "Formats" = ($filesInGroup | Group-Object Extension | Sort-Object Count -Descending |
                Select-Object -First 3 | ForEach-Object { "$($_.Name):$($_.Count)" }) -join ", "
        }
    }

    return $report | Sort-Object -Property Période
}

function Measure-ScriptPerformance {
    <#
    .SYNOPSIS
        Mesure le temps d'exécution d'un script ou d'un bloc de code.
    .PARAMETER ScriptBlock
        Bloc de code à mesurer
    .PARAMETER Iterations
        Nombre d'itérations pour calculer une moyenne
    #>
    param (
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$Iterations = 1
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::New()
    $results = @()

    for ($i = 1; $i -le $Iterations; $i++) {
        $stopwatch.Restart()

        try {
            $output = & $ScriptBlock
            $success = $true
        }
        catch {
            $output = $null
            $success = $false
            $error = $_
        }

        $stopwatch.Stop()

        $results += [PSCustomObject]@{
            Iteration = $i
            "Durée (ms)" = $stopwatch.ElapsedMilliseconds
            "Durée (s)" = [math]::Round($stopwatch.Elapsed.TotalSeconds, 3)
            Réussite = $success
            Erreur = if (-not $success) { $error.ToString() } else { $null }
            Sortie = if ($output) { $output } else { $null }

        }
    }

    # Calcul des statistiques
    $durees = $results | Where-Object { $_.Réussite } | Select-Object -ExpandProperty "Durée (ms)"

    if ($durees.Count -gt 0) {
        $stats = [PSCustomObject]@{
            "Minimum (ms)" = ($durees | Measure-Object -Minimum).Minimum
            "Maximum (ms)" = ($durees | Measure-Object -Maximum).Maximum
            "Moyenne (ms)" = [math]::Round(($durees | Measure-Object -Average).Average, 2)
            "Médiane (ms)" = if ($durees.Count -eq 1) { $durees[0] } else {
                $sorted = $durees | Sort-Object
                $middle = [math]::Floor($sorted.Count / 2)
                if ($sorted.Count % 2) {
                    $sorted[$middle]
                } else {
                    ($sorted[$middle-1] + $sorted[$middle]) / 2
                }
            }
            "Exécutions réussies" = ($results | Where-Object { $_.Réussite }).Count
            "Exécutions échouées" = ($results | Where-Object { -not $_.Réussite }).Count
        }
    } else {
        $stats = [PSCustomObject]@{
            "Minimum (ms)" = 0
            "Maximum (ms)" = 0
            "Moyenne (ms)" = 0
            "Médiane (ms)" = 0
            "Exécutions réussies" = 0
            "Exécutions échouées" = $Iterations
        }
    }

    return [PSCustomObject]@{
        Résultats = $results
        Statistiques = $stats
    }
}

#===============================================================================
# Exportation des fonctions
#===============================================================================

# Exporter toutes les fonctions définies dans ce script
Export-ModuleMember -Function *

# Informations sur l'utilisation du script
Write-Host @"
Module 5 - Outils de gestion des fichiers et du système chargés!

Fonctions disponibles par catégorie:

[Fichiers et dossiers]
- Get-LargestFiles         : Trouve les fichiers les plus volumineux
- Find-EmptyFolders        : Identifie les dossiers vides
- Get-DuplicateFiles       : Recherche les fichiers en double

[Lecture/écriture fichiers]
- ConvertTo-FlatObject     : Transforme un objet imbriqué en structure plate
- Convert-CsvToJson        : Convertit un fichier CSV en JSON
- Convert-XmlToCsv         : Convertit un fichier XML en CSV

[Permissions NTFS]
- Backup-FolderPermissions : Sauvegarde les permissions d'un dossier
- Restore-FolderPermissions: Restaure des permissions sauvegardées
- Grant-UserAccess         : Accorde des droits à un utilisateur

[Compression/Archivage]
- Compress-OldFiles        : Compresse les fichiers anciens
- Expand-ArchiveWithProgress: Extrait une archive avec barre de progression
- Get-ArchiveContent       : Affiche le contenu d'une archive

[Dates et temps]
- Get-FileAge              : Calcule l'âge des fichiers
- New-DateRangeReport      : Crée un rapport par plage de dates
- Measure-ScriptPerformance: Mesure le temps d'exécution d'un script

Pour obtenir de l'aide sur une fonction, utilisez:
Get-Help Nom-Fonction -Detailed
"@ -ForegroundColor Cyan

# Fin du script
