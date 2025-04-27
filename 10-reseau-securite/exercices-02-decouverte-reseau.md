# Solutions des exercices de découverte réseau PowerShell

## Exercice 1 (Débutant) : Vérifier l'accessibilité de sites web

**Objectif :** Créer un script qui vérifie si plusieurs sites web de votre choix sont accessibles et affiche un rapport formaté.

```powershell
<#
.SYNOPSIS
    Vérifie l'accessibilité de sites web et génère un rapport.
.DESCRIPTION
    Ce script vérifie si une liste de sites web est accessible en
    testant à la fois le ping et les ports HTTP/HTTPS.
.PARAMETER Sites
    Un tableau de sites web à vérifier.
.EXAMPLE
    .\Verifier-SitesWeb.ps1 -Sites "google.com", "microsoft.com", "siteinexistant.xyz"
#>

param (
    [string[]]$Sites = @("google.com", "microsoft.com", "github.com", "amazon.com", "siteinexistant.xyz")
)

function Test-SiteWeb {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Site
    )

    # Objet pour stocker les résultats
    $resultat = [PSCustomObject]@{
        Site = $Site
        PingReussi = $false
        HTTP = $false
        HTTPS = $false
        TempsReponse = "N/A"
    }

    # Test de ping
    try {
        $ping = Test-Connection -ComputerName $Site -Count 1 -ErrorAction Stop
        $resultat.PingReussi = $true
        $resultat.TempsReponse = "$($ping.ResponseTime) ms"
    }
    catch {
        Write-Verbose "Ping échoué pour $Site : $_"
    }

    # Test du port HTTP (80)
    try {
        $testHTTP = Test-NetConnection -ComputerName $Site -Port 80 -WarningAction SilentlyContinue -ErrorAction Stop
        $resultat.HTTP = $testHTTP.TcpTestSucceeded
    }
    catch {
        Write-Verbose "Test HTTP échoué pour $Site : $_"
    }

    # Test du port HTTPS (443)
    try {
        $testHTTPS = Test-NetConnection -ComputerName $Site -Port 443 -WarningAction SilentlyContinue -ErrorAction Stop
        $resultat.HTTPS = $testHTTPS.TcpTestSucceeded
    }
    catch {
        Write-Verbose "Test HTTPS échoué pour $Site : $_"
    }

    return $resultat
}

# Afficher un en-tête
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "  VÉRIFICATION D'ACCESSIBILITÉ WEB" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Date du test : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`n" -ForegroundColor Gray

# Démarrer le chronomètre pour mesurer le temps total
$chrono = [System.Diagnostics.Stopwatch]::StartNew()

# Tableau pour stocker tous les résultats
$resultats = @()

# Tester chaque site
foreach ($site in $Sites) {
    Write-Host "Vérification de $site..." -NoNewline
    $resultat = Test-SiteWeb -Site $site
    $resultats += $resultat

    # Afficher un indicateur rapide
    if ($resultat.PingReussi -or $resultat.HTTP -or $resultat.HTTPS) {
        Write-Host " Accessible" -ForegroundColor Green
    }
    else {
        Write-Host " Non accessible" -ForegroundColor Red
    }
}

# Arrêter le chronomètre
$chrono.Stop()

# Afficher les résultats détaillés
Write-Host "`nRésultats détaillés :"
$resultats | Format-Table -Property Site, PingReussi, HTTP, HTTPS, TempsReponse -AutoSize

# Statistiques
$accessibles = $resultats | Where-Object { $_.PingReussi -or $_.HTTP -or $_.HTTPS }
Write-Host "Sites accessibles : $($accessibles.Count) sur $($Sites.Count) ($(($accessibles.Count / $Sites.Count).ToString("P0")))"
Write-Host "Temps total de vérification : $($chrono.Elapsed.TotalSeconds.ToString("F2")) secondes"

# Exporter les résultats au format CSV (optionnel)
$cheminFichier = "$env:USERPROFILE\Desktop\Verification_Sites_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$resultats | Export-Csv -Path $cheminFichier -NoTypeInformation -Encoding UTF8

Write-Host "`nLes résultats ont été exportés dans le fichier : $cheminFichier" -ForegroundColor Yellow
```

## Exercice 2 (Intermédiaire) : Scanner un réseau avec résolution de noms

**Objectif :** Modifier la fonction `Scan-Reseau` pour qu'elle tente de résoudre les noms d'hôtes des machines trouvées.

```powershell
<#
.SYNOPSIS
    Scanner un réseau et résoudre les noms d'hôte.
.DESCRIPTION
    Ce script scanne une plage d'adresses IP et tente de résoudre
    les noms d'hôte pour chaque machine active trouvée.
.PARAMETER Reseau
    Le préfixe du réseau à scanner (par exemple "192.168.1").
.PARAMETER DebutPlage
    L'adresse de début de la plage (dernier octet).
.PARAMETER FinPlage
    L'adresse de fin de la plage (dernier octet).
.PARAMETER TimeoutMs
    Le délai d'attente en millisecondes pour chaque test.
.EXAMPLE
    .\Scan-ReseauAvecNoms.ps1 -Reseau "192.168.1" -DebutPlage 1 -FinPlage 50
#>

param (
    [string]$Reseau = "192.168.1",
    [int]$DebutPlage = 1,
    [int]$FinPlage = 254,
    [int]$TimeoutMs = 100
)

function Resolve-HostName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IpAddress
    )

    try {
        # Tentative de résolution inverse DNS
        $result = [System.Net.Dns]::GetHostEntry($IpAddress)
        return $result.HostName
    }
    catch {
        # Tentative de résolution via NetBIOS (Windows uniquement)
        try {
            $computer = Get-WmiObject -Class Win32_PingStatus -Filter "Address='$IpAddress'"
            if ($computer.NameSource -ne $null) {
                return $computer.NameSource
            }
            else {
                return "Non résolu"
            }
        }
        catch {
            return "Non résolu"
        }
    }
}

function Get-MacAddress {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IpAddress
    )

    try {
        # Utiliser ARP pour obtenir l'adresse MAC
        $arpResult = arp -a $IpAddress | Out-String

        if ($arpResult -match "($IpAddress)\s+([0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2}-[0-9A-Fa-f]{2})") {
            return $matches[2]
        }
        else {
            return "Non disponible"
        }
    }
    catch {
        return "Non disponible"
    }
}

function Get-CommonPorts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$IpAddress,
        [int[]]$PortsToCheck = @(22, 80, 443, 3389, 445)
    )

    $services = @{
        22 = "SSH"
        80 = "HTTP"
        443 = "HTTPS"
        3389 = "RDP"
        445 = "SMB"
    }

    $portsOuverts = @()

    foreach ($port in $PortsToCheck) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $tcpClient.BeginConnect($IpAddress, $port, $null, $null)
            $wait = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs)

            if ($wait) {
                $tcpClient.EndConnect($asyncResult)
                $serviceName = if ($services.ContainsKey($port)) { $services[$port] } else { "Inconnu" }
                $portsOuverts += "$port ($serviceName)"
            }

            $tcpClient.Close()
        }
        catch {
            # Ignorer les erreurs
        }
    }

    return $portsOuverts -join ", "
}

function Scan-ReseauAvecNoms {
    param (
        [string]$Reseau = "192.168.1",
        [int]$DebutPlage = 1,
        [int]$FinPlage = 254,
        [int]$TimeoutMs = 100
    )

    $machines = @()
    $total = $FinPlage - $DebutPlage + 1
    $progres = 0

    Write-Host "Scan du réseau $Reseau.$DebutPlage à $Reseau.$FinPlage en cours..."
    Write-Host "Les résultats apparaîtront au fur et à mesure de la découverte."
    Write-Host "-------------------------------------------------------------------"

    foreach ($i in $DebutPlage..$FinPlage) {
        $ip = "$Reseau.$i"

        # Mise à jour de la barre de progression
        $progres++
        $pourcentage = [int](($progres / $total) * 100)
        Write-Progress -Activity "Scan de réseau en cours" -Status "$pourcentage% Terminé" -PercentComplete $pourcentage -CurrentOperation "Test de $ip"

        $resultat = Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds ($TimeoutMs/1000)

        if ($resultat) {
            # Résolution du nom d'hôte
            $nomHote = Resolve-HostName -IpAddress $ip

            # Récupération de l'adresse MAC
            $macAdresse = Get-MacAddress -IpAddress $ip

            # Test des ports communs
            $portsOuverts = Get-CommonPorts -IpAddress $ip

            # Créer un objet avec les informations
            $machineInfo = [PSCustomObject]@{
                IP = $ip
                Nom = $nomHote
                MAC = $macAdresse
                Ports = $portsOuverts
                Ping = $true
            }

            $machines += $machineInfo

            # Afficher directement les informations dans la console
            Write-Host "Machine trouvée: $ip" -ForegroundColor Green -NoNewline
            Write-Host " | Nom: $nomHote | MAC: $macAdresse"
            if ($portsOuverts -ne "") {
                Write-Host "   └─ Ports ouverts: $portsOuverts" -ForegroundColor Cyan
            }
        }
    }

    Write-Progress -Activity "Scan de réseau en cours" -Completed
    Write-Host "-------------------------------------------------------------------"
    Write-Host "Scan terminé. $($machines.Count) machines trouvées."

    # Exporter les résultats au format CSV
    $dateFichier = Get-Date -Format "yyyyMMdd_HHmmss"
    $cheminFichier = "$env:USERPROFILE\Desktop\ScanReseau_$dateFichier.csv"
    $machines | Export-Csv -Path $cheminFichier -NoTypeInformation -Encoding UTF8

    Write-Host "Les résultats ont été exportés dans le fichier : $cheminFichier" -ForegroundColor Yellow

    # Afficher un tableau récapitulatif
    $machines | Format-Table -Property IP, Nom, MAC, Ports -AutoSize

    return $machines
}

# Exécuter la fonction avec les paramètres fournis
Scan-ReseauAvecNoms -Reseau $Reseau -DebutPlage $DebutPlage -FinPlage $FinPlage -TimeoutMs $TimeoutMs
```


Exercice 3 :

function Start-AuditReseauAvance {
    [CmdletBinding()]
    param (
        [string]$RapportPath = "$env:USERPROFILE\Desktop\AuditReseauAvance.html",
        [string]$Reseau = "",
        [int]$DebutPlage = 1,
        [int]$FinPlage = 254,
        [switch]$ScannerPorts,
        [int[]]$PortsAVerifier = @(22, 80, 443, 3389, 445, 139)
    )

    # Si le réseau n'est pas spécifié, déterminer automatiquement le réseau local
    if ([string]::IsNullOrEmpty($Reseau)) {
        $interfacePrincipale = Get-NetIPConfiguration |
                              Where-Object {
                                  $_.NetAdapter.Status -eq "Up" -and
                                  $_.IPv4DefaultGateway -ne $null -and
                                  $_.IPv4Address.IPAddress -match '\d+\.\d+\.\d+\.\d+'
                              } |
                              Select-Object -First 1

        if ($interfacePrincipale) {
            $ip = $interfacePrincipale.IPv4Address.IPAddress
            $octets = $ip -split '\.'
            $Reseau = "$($octets[0]).$($octets[1]).$($octets[2])"
            Write-Host "Réseau détecté automatiquement: $Reseau.0/24" -ForegroundColor Cyan
        }
        else {
            Write-Host "Impossible de déterminer le réseau automatiquement. Veuillez spécifier le paramètre -Reseau." -ForegroundColor Red
            return
        }
    }

    Write-Host "Démarrage de l'audit réseau sur $Reseau.$DebutPlage à $Reseau.$FinPlage..." -ForegroundColor Cyan
    $dateDebut = Get-Date

    # 1. Configuration réseau locale
    Write-Host "Collecte des informations de configuration réseau..." -ForegroundColor Cyan
    $interfaces = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" }

    # 2. Récupération de l'IP externe
    Write-Host "Récupération de l'adresse IP externe..." -ForegroundColor Cyan
    try {
        $ipExterne = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 5).ip
    }
    catch {
        $ipExterne = "Non disponible (vérifiez votre connexion Internet)"
    }

    # 3. Tests de connectivité internet
    Write-Host "Test de connectivité Internet..." -ForegroundColor Cyan
    $testSites = @("google.com", "microsoft.com", "cloudflare.com")
    $testsInternet = $testSites | ForEach-Object {
        $resultat = Test-Connection -ComputerName $_ -Count 1 -Quiet
        [PSCustomObject]@{
            Site = $_
            Accessible = $resultat
        }
    }

    # 4. Test de latence vers des sites populaires
    Write-Host "Test de latence vers des sites populaires..." -ForegroundColor Cyan
    $latences = $testSites | ForEach-Object {
        $ping = Test-Connection -ComputerName $_ -Count 3 -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Site = $_
            LatenceMoyenne = if ($ping) { ($ping | Measure-Object -Property ResponseTime -Average).Average } else { "Timeout" }
        }
    }

    # 5. Scan du réseau local pour trouver les machines actives
    Write-Host "Scan du réseau local pour identifier les machines actives..." -ForegroundColor Cyan

    # Version parallèle pour PowerShell 7+
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        Write-Host "Utilisation du scan parallèle (PowerShell 7+)..." -ForegroundColor Green
        $machinesTrouvees = $DebutPlage..$FinPlage | ForEach-Object -Parallel {
            $ip = "$using:Reseau.$_"
            $resultat = Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds 0.2

            if ($resultat) {
                # Tenter de résoudre le nom d'hôte
                try {
                    $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
                }
                catch {
                    $hostname = "N/A"
                }

                # Déterminer le type d'appareil (estimation basique)
                $estPasSerelle = $ip -eq "$using:Reseau.1" -or $ip -eq "$using:Reseau.254"

                [PSCustomObject]@{
                    IP = $ip
                    DernierOctet = $_
                    Hostname = $hostname
                    Type = if ($estPasSerelle) { "Passerelle" } else { "Hôte" }
                    PortsOuverts = @()
                }
            }
        } -ThrottleLimit 100
    }
    else {
        # Version séquentielle pour PowerShell 5.1
        Write-Host "Utilisation du scan séquentiel (PowerShell 5.1)..." -ForegroundColor Yellow
        $machinesTrouvees = @()

        foreach ($i in $DebutPlage..$FinPlage) {
            $ip = "$Reseau.$i"
            $resultat = Test-Connection -ComputerName $ip -Count 1 -Quiet

            if ($resultat) {
                Write-Host "Machine trouvée: $ip" -ForegroundColor Green

                # Tenter de résoudre le nom d'hôte
                try {
                    $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
                }
                catch {
                    $hostname = "N/A"
                }

                # Déterminer le type d'appareil (estimation basique)
                $estPasSerelle = $ip -eq "$Reseau.1" -or $ip -eq "$Reseau.254"

                $machinesTrouvees += [PSCustomObject]@{
                    IP = $ip
                    DernierOctet = $i
                    Hostname = $hostname
                    Type = if ($estPasSerelle) { "Passerelle" } else { "Hôte" }
                    PortsOuverts = @()
                }
            }
        }
    }

    # Trier les machines trouvées par le dernier octet pour une meilleure lisibilité
    $machinesTrouvees = $machinesTrouvees | Sort-Object -Property DernierOctet

    # 6. Scanner les ports si demandé
    if ($ScannerPorts -and $machinesTrouvees.Count -gt 0) {
        Write-Host "Scan des ports sur les machines trouvées..." -ForegroundColor Cyan

        foreach ($machine in $machinesTrouvees) {
            Write-Host "Scan des ports pour $($machine.IP)..." -ForegroundColor Yellow
            $portsOuverts = @()

            foreach ($port in $PortsAVerifier) {
                try {
                    $tcpClient = New-Object System.Net.Sockets.TcpClient
                    $beginConnect = $tcpClient.BeginConnect($machine.IP, $port, $null, $null)
                    $waitSuccess = $beginConnect.AsyncWaitHandle.WaitOne(200)

                    if ($waitSuccess) {
                        $tcpClient.EndConnect($beginConnect)
                        $portsOuverts += [PSCustomObject]@{
                            Port = $port
                            Service = Get-ServiceCommun -Port $port
                        }
                        Write-Host "  - Port $port ouvert ($((Get-ServiceCommun -Port $port)) )" -ForegroundColor Green
                    }

                    $tcpClient.Close()
                }
                catch {
                    # Ignorer les erreurs
                }
            }

            $machine.PortsOuverts = $portsOuverts
        }
    }

    # 7. Liste des connexions établies
    Write-Host "Collecte des connexions TCP établies..." -ForegroundColor Cyan
    $connexions = Get-NetTCPConnection -State Established |
                  Select-Object -First 10 LocalAddress, LocalPort, RemoteAddress, RemotePort, State |
                  Sort-Object RemoteAddress

    # 8. Informations sur la passerelle par défaut
    $passerelle = $interfaces[0].IPv4DefaultGateway.NextHop
    $passerelleInfo = if ($passerelle) {
        $pingResult = Test-Connection -ComputerName $passerelle -Count 1 -Quiet
        [PSCustomObject]@{
            Adresse = $passerelle
            Accessible = $pingResult
        }
    } else {
        [PSCustomObject]@{
            Adresse = "Non disponible"
            Accessible = $false
        }
    }

    # Calcul du temps écoulé
    $tempsExecution = (Get-Date) - $dateDebut
    $tempsFormate = "{0:mm}:{0:ss}" -f $tempsExecution

    # Génération du rapport HTML avec carte visuelle
    Write-Host "Génération du rapport HTML avec carte visuelle..." -ForegroundColor Cyan

    # Préparation des données pour la carte visuelle
    $nodesJson = "["
    $linksJson = "["

    # Nœud central (votre ordinateur)
    $monIP = ($interfaces[0].IPv4Address.IPAddress)
    $nodesJson += "{ id: 'me', label: 'Cet ordinateur\\n$monIP', shape: 'box', color: '#4CAF50' },"

    # Nœud pour Internet
    $nodesJson += "{ id: 'internet', label: 'Internet\\n$ipExterne', shape: 'cloud', color: '#2196F3' },"

    # Lien vers Internet
    $linksJson += "{ from: 'me', to: 'internet', color: { color: '#2196F3' }, width: 2, arrows: 'to,from' },"

    # Ajout des machines du réseau local
    foreach ($machine in $machinesTrouvees) {
        $nodeId = "ip_" + $machine.DernierOctet
        $label = "$($machine.IP)"
        if ($machine.Hostname -ne "N/A") {
            $label += "\\n$($machine.Hostname)"
        }

        # Couleur selon le type
        $couleur = switch ($machine.Type) {
            "Passerelle" { "#FF9800" } # Orange
            default { "#9C27B0" }      # Violet
        }

        # Forme selon les ports ouverts
        $forme = "ellipse"
        if ($machine.PortsOuverts.Count -gt 0) {
            if ($machine.PortsOuverts.Service -contains "HTTP" -or $machine.PortsOuverts.Service -contains "HTTPS") {
                $forme = "database"
                $label += "\\n(Serveur Web)"
            }
            elseif ($machine.PortsOuverts.Service -contains "SSH") {
                $forme = "box"
                $label += "\\n(SSH)"
            }
            elseif ($machine.PortsOuverts.Service -contains "RDP") {
                $forme = "box"
                $label += "\\n(RDP)"
            }
        }

        $nodesJson += "{ id: '$nodeId', label: '$label', shape: '$forme', color: '$couleur' },"

        # Lien depuis la passerelle ou depuis votre machine
        if ($machine.Type -eq "Passerelle") {
            $linksJson += "{ from: 'me', to: '$nodeId', width: 2, color: {color: '#FF9800'} },"
        }
        else {
            # Si c'est une passerelle connue, on connecte les autres machines à elle
            $passerelleConnue = $machinesTrouvees | Where-Object { $_.Type -eq "Passerelle" } | Select-Object -First 1
            if ($passerelleConnue) {
                $gatewayId = "ip_" + $passerelleConnue.DernierOctet
                $linksJson += "{ from: '$gatewayId', to: '$nodeId', width: 1 },"
            }
            else {
                # Si pas de passerelle trouvée, on connecte directement à votre machine
                $linksJson += "{ from: 'me', to: '$nodeId', width: 1, dashes: true },"
            }
        }
    }

    # Fermeture des structures JSON
    $nodesJson = $nodesJson.TrimEnd(',') + "]"
    $linksJson = $linksJson.TrimEnd(',') + "]"

    # Création du rapport HTML avec la carte
    $rapport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'audit réseau avancé PowerShell</title>
    <meta charset="UTF-8">
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/vis/4.21.0/vis.min.js"></script>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/vis/4.21.0/vis.min.css" rel="stylesheet" type="text/css" />
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f9f9f9; }
        h1 { color: #0066cc; }
        h2 { color: #0099cc; border-bottom: 1px solid #ddd; padding-bottom: 5px; margin-top: 30px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .panel { background-color: white; border-radius: 5px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); padding: 20px; margin-bottom: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { text-align: left; padding: 12px; border: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .success { color: green; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        #network-map { width: 100%; height: 600px; border: 1px solid #ddd; }
        .summary { display: flex; justify-content: space-between; flex-wrap: wrap; }
        .summary-box { background-color: white; border-radius: 5px; box-shadow: 0 1px 3px rgba(0,0,0,0.1); padding: 15px; margin: 10px; flex: 1; min-width: 200px; }
        .summary-title { font-weight: bold; margin-bottom: 10px; color: #0066cc; }
        .badge { display: inline-block; padding: 3px 7px; border-radius: 50px; font-size: 12px; font-weight: bold; }
        .badge-success { background-color: #e8f5e9; color: #2e7d32; }
        .badge-warning { background-color: #fff8e1; color: #f57f17; }
        .badge-info { background-color: #e3f2fd; color: #0d47a1; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        .port-tag { display: inline-block; margin-right: 5px; margin-bottom: 5px; padding: 2px 6px; border-radius: 3px; font-size: 12px; background-color: #e3f2fd; color: #0d47a1; }
    </style>
</head>
<body>
    <div class="container">
        <div class="panel">
            <h1>Rapport d'audit réseau avancé PowerShell</h1>
            <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss") | Durée du scan: $tempsFormate</p>
        </div>

        <div class="summary">
            <div class="summary-box">
                <div class="summary-title">Résumé du réseau</div>
                <p>Réseau analysé: <strong>$Reseau.0/24</strong></p>
                <p>Machines détectées: <strong>$($machinesTrouvees.Count)</strong></p>
                <p>Adresse IP externe: <strong>$ipExterne</strong></p>
            </div>

            <div class="summary-box">
                <div class="summary-title">État Internet</div>
                <p>Connectivité: <span class="badge $( if (($testsInternet | Where-Object {$_.Accessible}).Count -gt 0) { "badge-success" } else { "badge-error" } )">
                    $( if (($testsInternet | Where-Object {$_.Accessible}).Count -gt 0) { "En ligne" } else { "Hors ligne" } )
                </span></p>
                <p>Latence moyenne: <strong>$( if ($latences -and ($latences | Where-Object {$_.LatenceMoyenne -ne "Timeout"}).Count -gt 0) { [math]::Round(($latences | Where-Object {$_.LatenceMoyenne -ne "Timeout"} | Measure-Object -Property LatenceMoyenne -Average).Average, 0) } else { "N/A" } ) ms</strong></p>
            </div>

            <div class="summary-box">
                <div class="summary-title">Passerelle</div>
                <p>Adresse: <strong>$($passerelleInfo.Adresse)</strong></p>
                <p>État: <span class="badge $( if ($passerelleInfo.Accessible) { "badge-success" } else { "badge-error" } )">
                    $( if ($passerelleInfo.Accessible) { "Accessible" } else { "Non accessible" } )
                </span></p>
            </div>
        </div>

        <div class="panel">
            <h2>Carte du réseau</h2>
            <div id="network-map"></div>
        </div>

        <div class="panel">
            <h2>Configuration réseau locale</h2>
            <table>
                <tr>
                    <th>Interface</th>
                    <th>Adresse IP</th>
                    <th>Masque</th>
                    <th>Passerelle</th>
                    <th>DNS</th>
                </tr>
"@

    foreach ($interface in $interfaces) {
        $ipv4 = $interface | Get-NetIPAddress -AddressFamily IPv4
        $rapport += @"
                <tr>
                    <td>$($interface.InterfaceAlias)</td>
                    <td>$($ipv4.IPAddress)</td>
                    <td>$($ipv4.PrefixLength)</td>
                    <td>$($interface.IPv4DefaultGateway.NextHop)</td>
                    <td>$($interface.DNSServer.ServerAddresses -join ', ')</td>
                </tr>
"@
    }

    $rapport += @"
            </table>
        </div>

        <div class="panel">
            <h2>Machines détectées sur le réseau ($($machinesTrouvees.Count))</h2>
            <table>
                <tr>
                    <th>Adresse IP</th>
                    <th>Nom d'hôte</th>
                    <th>Type</th>
                    <th>Ports ouverts</th>
                </tr>
"@

    foreach ($machine in $machinesTrouvees) {
        $portsHtml = ""
        foreach ($port in $machine.PortsOuverts) {
            $portsHtml += "<span class='port-tag'>$($port.Port) ($($port.Service))</span>"
        }
        if ([string]::IsNullOrEmpty($portsHtml)) {
            $portsHtml = "<em>Aucun port vérifié ou ouvert</em>"
        }

        $rapport += @"
                <tr>
                    <td>$($machine.IP)</td>
                    <td>$($machine.Hostname)</td>
                    <td>$($machine.Type)</td>
                    <td>$portsHtml</td>
                </tr>
"@
    }

    $rapport += @"
            </table>
        </div>

        <div class="panel">
            <h2>Tests de connectivité Internet</h2>
            <table>
                <tr>
                    <th>Site</th>
                    <th>État</th>
                    <th>Latence moyenne</th>
                </tr>
"@

    foreach ($site in $testSites) {
        $test = $testsInternet | Where-Object { $_.Site -eq $site }
        $latence = $latences | Where-Object { $_.Site -eq $site }

        $etat = if ($test.Accessible) { "Accessible" } else { "Non accessible" }
        $classe = if ($test.Accessible) { "success" } else { "error" }

        $rapport += @"
                <tr>
                    <td>$site</td>
                    <td class="$classe">$etat</td>
                    <td>$($latence.LatenceMoyenne) ms</td>
                </tr>
"@
    }

    $rapport += @"
            </table>
        </div>

        <div class="panel">
            <h2>Connexions TCP établies (top 10)</h2>
            <table>
                <tr>
                    <th>Adresse locale</th>
                    <th>Port local</th>
                    <th>Adresse distante</th>
                    <th>Port distant</th>
                </tr>
"@

    foreach ($connexion in $connexions) {
        $rapport += @"
                <tr>
                    <td>$($connexion.LocalAddress)</td>
                    <td>$($connexion.LocalPort)</td>
                    <td>$($connexion.RemoteAddress)</td>
                    <td>$($connexion.RemotePort)</td>
                </tr>
"@
    }

    $rapport += @"
            </table>
        </div>

        <div class="footer">
            <p>Rapport généré par PowerShell Audit Réseau Avancé | &copy; $(Get-Date -Format "yyyy")</p>
        </div>
    </div>

    <script type="text/javascript">
        // Création de la carte réseau
        document.addEventListener('DOMContentLoaded', function() {
            // Création des données
            var nodes = new vis.DataSet($nodesJson);
            var edges = new vis.DataSet($linksJson);

            // Configuration de la visualisation
            var container = document.getElementById('network-map');
            var data = {
                nodes: nodes,
                edges: edges
            };
            var options = {
                nodes: {
                    font: {
                        size: 14,
                        face: 'Arial',
                        multi: 'html'
                    }
                },
                edges: {
                    smooth: {
                        type: 'continuous'
                    }
                },
                physics: {
                    stabilization: true,
                    barnesHut: {
                        gravitationalConstant: -5000,
                        centralGravity: 0.1,
                        springLength: 140,
                        springConstant: 0.04,
                        damping: 0.09
                    }
                },
                layout: {
                    improvedLayout: true,
                    hierarchical: {
                        enabled: false
                    }
                },
                interaction: {
                    navigationButtons: true,
                    keyboard: true
                }
            };

            // Initialisation du réseau
            var network = new vis.Network(container, data, options);
        });
    </script>
</body>
</html>
"@

    # Sauvegarde du rapport
    $rapport | Out-File -FilePath $RapportPath -Encoding UTF8

    Write-Host "Rapport généré avec succès: $RapportPath" -ForegroundColor Green
    Write-Host "Ouvrez ce fichier dans votre navigateur pour consulter les résultats."

    # Fonctions utilitaires internes
    function Get-ServiceCommun {
        param([int]$Port)

        $servicesCommuns = @{
            20 = "FTP (données)"
            21 = "FTP (contrôle)"
            22 = "SSH"
            23 = "Telnet"
            25 = "SMTP"
            53 = "DNS"
            80 = "HTTP"
            110 = "POP3"
            143 = "IMAP"
            443 = "HTTPS"
            445 = "SMB"
            1433 = "SQL Server"
            3306 = "MySQL"
            3389 = "RDP"
            5432 = "PostgreSQL"
            8080 = "HTTP alternatif"
            8443 = "HTTPS alternatif"
        }

        if ($servicesCommuns.ContainsKey($Port)) {
            return $servicesCommuns[$Port]
        }
        else {
            return "Port $Port"
        }
    }

    # Ouverture automatique du rapport si demandé
    $reponse = Read-Host "Souhaitez-vous ouvrir le rapport maintenant? (O/N)"
    if ($reponse -eq "O" -or $reponse -eq "o") {
        Start-Process $RapportPath
    }

    # Retourner les données pour une utilisation ultérieure si besoin
    return @{
        Interfaces = $interfaces
        MachinesTrouvees = $machinesTrouvees
        TestsInternet = $testsInternet
        Latences = $latences
        Connexions = $connexions
        IPExterne = $ipExterne
        Passerelle = $passerelleInfo
        RapportPath = $RapportPath
    }
}

# Exemples d'utilisation:
# Start-AuditReseauAvance
# Start-AuditReseauAvance -Reseau "192.168.1" -ScannerPorts
# Start-AuditReseauAvance -ScannerPorts -PortsAVerifier 80,443,22,3389
