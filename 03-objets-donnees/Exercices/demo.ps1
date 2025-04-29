#===============================================================================
# SCRIPT DE DÉMONSTRATION DU MODULE 4 - OBJETS ET TRAITEMENT DE DONNÉES
# Formation PowerShell – Du Débutant à l'Expert
#===============================================================================

# Créons des fonctions utilitaires pour la clarté de la démo
function Show-DemoSection {
    param ([string]$Title)

    Write-Host "`n`n===========================================" -ForegroundColor Blue
    Write-Host "    $Title" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Blue
}

function Show-DemoStep {
    param ([string]$StepDescription)

    Write-Host "`n>> $StepDescription" -ForegroundColor Yellow
}

function Pause-Demo {
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Créer le dossier de sortie pour les exports
$outputPath = Join-Path -Path $env:TEMP -ChildPath "PowerShellDemo"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

#===============================================================================
# SECTION 1: LE MODÈLE OBJET POWERSHELL
#===============================================================================
Show-DemoSection "4-1. LE MODÈLE OBJET POWERSHELL"

Show-DemoStep "Récupérer un processus et explorer sa structure"
$notepad = Start-Process notepad -PassThru
Start-Sleep -Seconds 1  # Attendre que Notepad démarre complètement

Show-DemoStep "Voyons les propriétés et méthodes du processus avec Get-Member"
$notepad | Get-Member | Select-Object -First 10  # Montrer seulement les 10 premiers pour ne pas surcharger

Show-DemoStep "Accéder à des propriétés spécifiques du processus"
[PSCustomObject]@{
    Nom = $notepad.Name
    PID = $notepad.Id
    "Mémoire (MB)" = [math]::Round($notepad.WorkingSet / 1MB, 2)
    "Temps CPU" = $notepad.CPU
    Chemin = $notepad.Path
}

Show-DemoStep "Utiliser une méthode pour interagir avec l'objet"
$notepad.Kill()  # Terminer notepad
Write-Host "Le processus Notepad a été terminé" -ForegroundColor Green

Pause-Demo

#===============================================================================
# SECTION 2: MANIPULATION DES OBJETS
#===============================================================================
Show-DemoSection "4-2. MANIPULATION DES OBJETS"

Show-DemoStep "Select-Object - Choisir uniquement certaines propriétés"
Get-Service | Select-Object -First 5 Name, Status, StartType | Format-Table

Show-DemoStep "Where-Object - Filtrer selon une condition"
$servicesRunning = Get-Service | Where-Object Status -eq 'Running'
Write-Host "Nombre de services en cours d'exécution: $($servicesRunning.Count)" -ForegroundColor Green
$servicesRunning | Select-Object -First 3 | Format-Table Name, DisplayName

Show-DemoStep "Sort-Object - Trier les objets"
Get-Process | Sort-Object WorkingSet -Descending |
    Select-Object -First 5 Name, Id, @{Name="Mémoire (MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}} |
    Format-Table -AutoSize

Show-DemoStep "Combiner les cmdlets dans un pipeline"
Get-Process |
    Where-Object WorkingSet -gt 100MB |
    Sort-Object CPU -Descending |
    Select-Object -First 3 Name, ID, @{Name="Mémoire (MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}}, CPU

Pause-Demo

#===============================================================================
# SECTION 3: CRÉATION D'OBJETS PERSONNALISÉS
#===============================================================================
Show-DemoSection "4-3. CRÉATION D'OBJETS PERSONNALISÉS"

Show-DemoStep "Créer un objet personnalisé simple"
$serveur = [PSCustomObject]@{
    Nom = "SRV-PROD-01"
    Role = "Serveur Web"
    OS = "Windows Server 2022"
    Uptime = (Get-Random -Minimum 5 -Maximum 150)
    Services = @("IIS", "SQL", "DHCP")
    EnProduction = $true
}

$serveur | Format-List

Show-DemoStep "Créer une collection d'objets personnalisés"
$serveurs = @(
    [PSCustomObject]@{
        Nom = "SRV-PROD-01"
        Role = "Serveur Web"
        OS = "Windows Server 2022"
        Uptime = (Get-Random -Minimum 5 -Maximum 150)
        Services = @("IIS", "SQL", "DHCP")
        EnProduction = $true
    },
    [PSCustomObject]@{
        Nom = "SRV-PROD-02"
        Role = "Serveur de Base de Données"
        OS = "Windows Server 2019"
        Uptime = (Get-Random -Minimum 5 -Maximum 150)
        Services = @("SQL", "DHCP")
        EnProduction = $true
    },
    [PSCustomObject]@{
        Nom = "SRV-DEV-01"
        Role = "Serveur de Développement"
        OS = "Windows Server 2022"
        Uptime = (Get-Random -Minimum 1 -Maximum 30)
        Services = @("IIS", "SQL")
        EnProduction = $false
    }
)

$serveurs | Format-Table

Show-DemoStep "Ajouter une propriété calculée"
$serveurs | Add-Member -MemberType ScriptProperty -Name "UptimeJours" -Value { $this.Uptime } -Force
$serveurs | Add-Member -MemberType ScriptProperty -Name "NombreServices" -Value { $this.Services.Count } -Force

$serveurs | Format-Table Nom, Role, UptimeJours, NombreServices, EnProduction

Show-DemoStep "Ajouter une méthode"
$serveurs | Add-Member -MemberType ScriptMethod -Name "Redemarrer" -Value {
    # Simulation d'un redémarrage
    Write-Host "Redémarrage de $($this.Nom) en cours..." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    $this.Uptime = 0
    Write-Host "$($this.Nom) a été redémarré avec succès!" -ForegroundColor Green
} -Force

# Démonstration de l'appel de méthode
$serveurs[0].Redemarrer()
$serveurs | Format-Table Nom, Role, UptimeJours

Pause-Demo

#===============================================================================
# SECTION 4: GROUPEMENT ET AGRÉGATION
#===============================================================================
Show-DemoSection "4-4. GROUPEMENT ET AGRÉGATION"

Show-DemoStep "Group-Object - Grouper par une propriété"
$processByCompany = Get-Process |
    Where-Object Company |
    Group-Object Company

Write-Host "Nombre de groupes trouvés: $($processByCompany.Count)" -ForegroundColor Green
$processByCompany | Select-Object -First 3 | Format-Table Name, Count

Show-DemoStep "Analyse statistique avec Measure-Object"
$fileStats = Get-ChildItem $env:WINDIR\System32 -File |
    Measure-Object Length -Minimum -Maximum -Average -Sum

[PSCustomObject]@{
    "Nombre de fichiers" = $fileStats.Count
    "Taille totale (MB)" = [math]::Round($fileStats.Sum / 1MB, 2)
    "Taille moyenne (KB)" = [math]::Round($fileStats.Average / 1KB, 2)
    "Plus petit fichier (KB)" = [math]::Round($fileStats.Minimum / 1KB, 2)
    "Plus grand fichier (MB)" = [math]::Round($fileStats.Maximum / 1MB, 2)
} | Format-List

Show-DemoStep "Rapport avancé: Analyse des extensions de fichiers"
$extensionReport = Get-ChildItem $env:WINDIR\System32 -File |
    Group-Object Extension |
    ForEach-Object {
        $stats = $_.Group | Measure-Object Length -Sum -Average
        [PSCustomObject]@{
            Extension = if ($_.Name) { $_.Name } else { "(aucune)" }
            Nombre = $_.Count
            "Taille totale (MB)" = [math]::Round($stats.Sum / 1MB, 2)
            "Taille moyenne (KB)" = [math]::Round($stats.Average / 1KB, 2)
        }
    } |
    Sort-Object "Taille totale (MB)" -Descending |
    Select-Object -First 5

$extensionReport | Format-Table -AutoSize

Pause-Demo

#===============================================================================
# SECTION 5: EXPORT DE DONNÉES
#===============================================================================
Show-DemoSection "4-5. EXPORT DE DONNÉES"

# Préparer des données intéressantes pour l'export
$systemInfo = [PSCustomObject]@{
    ComputerName = $env:COMPUTERNAME
    OSVersion = [System.Environment]::OSVersion.VersionString
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Processeurs = (Get-CimInstance Win32_Processor).Count
    MemoireTotale = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    EspaceDisque = @(
        Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 3 | ForEach-Object {
            [PSCustomObject]@{
                Lecteur = $_.DeviceID
                "Taille(GB)" = [math]::Round($_.Size / 1GB, 2)
                "EspaceLibre(GB)" = [math]::Round($_.FreeSpace / 1GB, 2)
                "PourcentageLibre" = [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
            }
        }
    )
    Applications = @(
        @{Nom = "Navigateur"; Version = "1.0"},
        @{Nom = "Bureautique"; Version = "2.1"},
        @{Nom = "Antivirus"; Version = "3.5"}
    )
    DateRapport = Get-Date
}

Show-DemoStep "1. Export au format CSV (données plates)"
# Pour CSV, on doit aplatir notre structure hiérarchique
$diskInfo = $systemInfo.EspaceDisque | ForEach-Object {
    [PSCustomObject]@{
        ComputerName = $systemInfo.ComputerName
        Lecteur = $_.Lecteur
        "TailleGB" = $_."Taille(GB)"
        "EspaceLibreGB" = $_."EspaceLibre(GB)"
        "PourcentageLibre" = $_.PourcentageLibre
    }
}

$csvPath = Join-Path -Path $outputPath -ChildPath "disques.csv"
$diskInfo | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";"
Write-Host "Fichier CSV créé: $csvPath" -ForegroundColor Green
Import-Csv -Path $csvPath -Delimiter ";" | Format-Table  # Montrer le contenu importé

Show-DemoStep "2. Export au format JSON (préserve la hiérarchie)"
$jsonPath = Join-Path -Path $outputPath -ChildPath "systemInfo.json"
$systemInfo | ConvertTo-Json -Depth 4 | Out-File -FilePath $jsonPath
Write-Host "Fichier JSON créé: $jsonPath" -ForegroundColor Green

# Montrer le contenu importé
$jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
Write-Host "Structure importée depuis JSON:"
$jsonContent | Get-Member -MemberType NoteProperty | Select-Object Name

Show-DemoStep "3. Export au format XML"
$xmlPath = Join-Path -Path $outputPath -ChildPath "systemInfo.xml"
$systemInfo | Export-Clixml -Path $xmlPath
Write-Host "Fichier XML créé: $xmlPath" -ForegroundColor Green

# Import pour démontrer
$xmlContent = Import-Clixml -Path $xmlPath
Write-Host "Contenu importé depuis XML:"
$xmlContent.PSObject.Properties | Select-Object -First a5 Name, TypeNameOfValue

Show-DemoStep "4. Création d'un rapport HTML interactif"
$htmlPath = Join-Path -Path $outputPath -ChildPath "rapport.html"

$htmlHead = @"
<style>
    body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f0f0f0; }
    h1, h2 { color: #0078D7; }
    .container { background-color: white; padding: 20px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th { background-color: #0078D7; color: white; text-align: left; padding: 10px; }
    td { padding: 8px; border-bottom: 1px solid #ddd; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    .warning { background-color: #fff0c0; }
    .critical { background-color: #ffd0d0; }
    .section { margin-top: 20px; }
</style>
<script>
    function toggleSection(id) {
        var section = document.getElementById(id);
        if (section.style.display === 'none') {
            section.style.display = 'block';
        } else {
            section.style.display = 'none';
        }
    }
</script>
"@

# Création du contenu HTML
$htmlContent = @"
<div class="container">
    <h1>Rapport système - $($systemInfo.ComputerName)</h1>
    <p>Généré le $($systemInfo.DateRapport.ToString("dd/MM/yyyy à HH:mm"))</p>

    <h2 onclick="toggleSection('sysinfo')" style="cursor: pointer;">▶ Informations système</h2>
    <div id="sysinfo" class="section">
        <table>
            <tr><td><strong>Ordinateur</strong></td><td>$($systemInfo.ComputerName)</td></tr>
            <tr><td><strong>Système d'exploitation</strong></td><td>$($systemInfo.OSVersion)</td></tr>
            <tr><td><strong>Version PowerShell</strong></td><td>$($systemInfo.PowerShellVersion)</td></tr>
            <tr><td><strong>Utilisateur actuel</strong></td><td>$($systemInfo.CurrentUser)</td></tr>
            <tr><td><strong>Processeurs</strong></td><td>$($systemInfo.Processeurs)</td></tr>
            <tr><td><strong>Mémoire totale (GB)</strong></td><td>$($systemInfo.MemoireTotale)</td></tr>
        </table>
    </div>

    <h2 onclick="toggleSection('diskinfo')" style="cursor: pointer;">▶ Espace disque</h2>
    <div id="diskinfo" class="section">
        <table>
            <tr>
                <th>Lecteur</th>
                <th>Taille (GB)</th>
                <th>Espace libre (GB)</th>
                <th>% Libre</th>
            </tr>
"@

foreach ($disk in $systemInfo.EspaceDisque) {
    $rowClass = ""
    if ($disk.PourcentageLibre -lt 15) {
        $rowClass = "critical"
    } elseif ($disk.PourcentageLibre -lt 25) {
        $rowClass = "warning"
    }

    $htmlContent += @"
            <tr class="$rowClass">
                <td>$($disk.Lecteur)</td>
                <td>$($disk."Taille(GB)")</td>
                <td>$($disk."EspaceLibre(GB)")</td>
                <td>$($disk.PourcentageLibre)%</td>
            </tr>
"@
}

$htmlContent += @"
        </table>
    </div>

    <h2 onclick="toggleSection('appinfo')" style="cursor: pointer;">▶ Applications installées</h2>
    <div id="appinfo" class="section">
        <table>
            <tr>
                <th>Nom</th>
                <th>Version</th>
            </tr>
"@

foreach ($app in $systemInfo.Applications) {
    $htmlContent += @"
            <tr>
                <td>$($app.Nom)</td>
                <td>$($app.Version)</td>
            </tr>
"@
}

$htmlContent += @"
        </table>
    </div>
</div>
"@

# Générer le fichier HTML complet
ConvertTo-Html -Head $htmlHead -Body $htmlContent | Out-File -FilePath $htmlPath
Write-Host "Rapport HTML interactif créé: $htmlPath" -ForegroundColor Green
Write-Host "Pour ouvrir le rapport dans votre navigateur, exécutez: Invoke-Item '$htmlPath'" -ForegroundColor Yellow

#===============================================================================
# FIN DE LA DÉMONSTRATION
#===============================================================================
Show-DemoSection "DÉMONSTRATION TERMINÉE"
Write-Host "Tous les fichiers générés se trouvent dans: $outputPath" -ForegroundColor Green
Write-Host "Merci d'avoir suivi cette démonstration du Module 4 !" -ForegroundColor Cyan
