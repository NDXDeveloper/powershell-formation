# Module 11-2. Découverte réseau (scan, ports, ping, IP)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

La découverte réseau est une compétence fondamentale pour tout administrateur système ou professionnel IT. PowerShell offre de puissants outils pour explorer, analyser et dépanner les réseaux. Dans ce module, nous allons découvrir comment utiliser PowerShell pour scanner des réseaux, vérifier l'état des ports, effectuer des pings et travailler avec des adresses IP.

## Prérequis
- Connaissances de base de PowerShell (variables, boucles, cmdlets)
- Notions élémentaires de réseaux (IP, ports, protocoles)

## 1. Ping et vérification de disponibilité

### Test-Connection : Le "ping" PowerShell

La commande `Test-Connection` est l'équivalent PowerShell de la commande `ping` classique, mais avec des fonctionnalités supplémentaires et une sortie sous forme d'objets.

```powershell
# Ping simple vers google.com
Test-Connection -ComputerName google.com

# Ping avec un nombre limité de paquets
Test-Connection -ComputerName google.com -Count 2

# Vérifier si une machine est en ligne (retourne True/False)
Test-Connection -ComputerName google.com -Count 1 -Quiet

# Ping de plusieurs machines en même temps
Test-Connection -ComputerName google.com, bing.com, 192.168.1.1 -Count 1
```

#### Exemple pratique : Vérification rapide d'un parc de machines
```powershell
$ordinateurs = "serveur1", "serveur2", "192.168.1.25", "poste15"
$resultats = $ordinateurs | ForEach-Object {
    [PSCustomObject]@{
        Ordinateur = $_
        Disponible = Test-Connection -ComputerName $_ -Count 1 -Quiet -ErrorAction SilentlyContinue
    }
}

$resultats | Format-Table -AutoSize
```

## 2. Travailler avec les adresses IP

### Obtenir les configurations IP de l'ordinateur local

```powershell
# Afficher toutes les interfaces réseau et leurs configurations IP
Get-NetIPConfiguration

# Afficher uniquement les interfaces connectées
Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" }

# Obtenir toutes les adresses IP de la machine
Get-NetIPAddress

# Filtrer uniquement les adresses IPv4
Get-NetIPAddress -AddressFamily IPv4

# Obtenir l'adresse IP publique (externe)
Invoke-RestMethod -Uri "https://api.ipify.org?format=json"
```

### Manipuler les adresses IP avec PowerShell

```powershell
# Convertir une chaîne en objet d'adresse IP
$ip = [System.Net.IPAddress]::Parse("192.168.1.100")

# Vérifier si une chaîne est une adresse IP valide
function Est-AdresseIPValide {
    param (
        [string]$AdresseIP
    )

    try {
        $null = [System.Net.IPAddress]::Parse($AdresseIP)
        return $true
    }
    catch {
        return $false
    }
}

# Exemple d'utilisation
Est-AdresseIPValide -AdresseIP "192.168.1.1"    # Retourne: True
Est-AdresseIPValide -AdresseIP "256.1.1.1"      # Retourne: False (256 > 255)
```

## 3. Scanner des plages d'adresses IP

Parfois, vous devez scanner une plage d'adresses IP pour découvrir les machines actives sur un réseau. Voici comment faire avec PowerShell :

```powershell
# Scanner un sous-réseau pour trouver les machines actives
function Scan-Reseau {
    param (
        [string]$Reseau = "192.168.1",
        [int]$DebutPlage = 1,
        [int]$FinPlage = 254,
        [int]$TimeoutMs = 100
    )

    $machines = @()

    Write-Host "Scan du réseau $Reseau.$DebutPlage à $Reseau.$FinPlage en cours..."

    foreach ($i in $DebutPlage..$FinPlage) {
        $ip = "$Reseau.$i"
        $resultat = Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds ($TimeoutMs/1000)

        if ($resultat) {
            Write-Host "Machine trouvée: $ip" -ForegroundColor Green
            $machines += $ip
        }
    }

    Write-Host "Scan terminé. $($machines.Count) machines trouvées."
    return $machines
}

# Exemple d'utilisation:
$machinesTrouvees = Scan-Reseau -Reseau "192.168.1" -DebutPlage 1 -FinPlage 20
```

### Version optimisée avec traitement parallèle (PowerShell 7+)

```powershell
function Scan-ReseauParallele {
    param (
        [string]$Reseau = "192.168.1",
        [int]$DebutPlage = 1,
        [int]$FinPlage = 254,
        [int]$TimeoutMs = 100
    )

    Write-Host "Scan du réseau $Reseau.$DebutPlage à $Reseau.$FinPlage en cours..."

    $machines = $DebutPlage..$FinPlage | ForEach-Object -Parallel {
        $ip = "$using:Reseau.$_"
        $resultat = Test-Connection -ComputerName $ip -Count 1 -Quiet -TimeoutSeconds ($using:TimeoutMs/1000)

        if ($resultat) {
            Write-Host "Machine trouvée: $ip" -ForegroundColor Green
            $ip
        }
    } -ThrottleLimit 50

    Write-Host "Scan terminé. $($machines.Count) machines trouvées."
    return $machines
}
```

## 4. Test de ports et services

La vérification de la disponibilité des ports est essentielle pour diagnostiquer les problèmes de connectivité des services.

### Test-NetConnection : L'outil polyvalent

```powershell
# Tester un port spécifique
Test-NetConnection -ComputerName google.com -Port 443

# Tester un port avec plus d'informations
Test-NetConnection -ComputerName google.com -Port 443 -InformationLevel Detailed

# Vérifier si un port spécifique est ouvert
(Test-NetConnection -ComputerName google.com -Port 443).TcpTestSucceeded
```

### Tester plusieurs ports sur une machine

```powershell
function Test-Ports {
    param (
        [string]$ComputerName,
        [int[]]$Ports
    )

    foreach ($port in $Ports) {
        $result = Test-NetConnection -ComputerName $ComputerName -Port $port -WarningAction SilentlyContinue

        [PSCustomObject]@{
            Machine = $ComputerName
            Port = $port
            Ouvert = $result.TcpTestSucceeded
            ServiceCommun = Get-ServiceCommun -Port $port
        }
    }
}

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
        443 = "HTTPS"
        3389 = "RDP"
        1433 = "SQL Server"
        3306 = "MySQL"
        5432 = "PostgreSQL"
        8080 = "HTTP alternatif"
    }

    if ($servicesCommuns.ContainsKey($Port)) {
        return $servicesCommuns[$Port]
    }
    else {
        return "Inconnu"
    }
}

# Exemple d'utilisation
Test-Ports -ComputerName "exemple.com" -Ports 80, 443, 22, 3389 | Format-Table -AutoSize
```

### Scanner tous les ports d'une machine

⚠️ **Attention** : Le scan de ports peut être considéré comme une activité suspecte par certains systèmes de sécurité. N'utilisez ce code que sur vos propres systèmes ou avec autorisation.

```powershell
function Scan-AllPorts {
    param (
        [string]$ComputerName,
        [int]$PortMin = 1,
        [int]$PortMax = 1024,
        [int]$TimeoutMs = 100
    )

    Write-Host "Scan des ports $PortMin à $PortMax sur $ComputerName..."
    $portsOuverts = @()

    foreach ($port in $PortMin..$PortMax) {
        try {
            $client = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $client.BeginConnect($ComputerName, $port, $null, $null)
            $wait = $asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs)

            if ($wait) {
                $portsOuverts += $port
                Write-Host "Port $port : OUVERT" -ForegroundColor Green

                # Tentative de fermer proprement la connexion
                $client.EndConnect($asyncResult)
            }
            $client.Close()
        }
        catch {
            # Ignorer les erreurs
        }
    }

    Write-Host "Scan terminé. $($portsOuverts.Count) ports ouverts trouvés."
    return $portsOuverts
}

# Exemple d'utilisation (limité aux 100 premiers ports pour la démonstration)
$portsOuverts = Scan-AllPorts -ComputerName "exemple.com" -PortMax 100
```

## 5. Analyse des routes et du routage

PowerShell permet également d'analyser le routage réseau :

```powershell
# Afficher la table de routage
Get-NetRoute

# Afficher uniquement les routes IPv4
Get-NetRoute -AddressFamily IPv4

# Afficher la route pour une destination spécifique
Get-NetRoute -DestinationPrefix "0.0.0.0/0"  # Route par défaut

# Tracer la route vers une destination (équivalent de tracert)
Test-NetConnection -ComputerName google.com -TraceRoute
```

## 6. Mini-projet : Script d'audit réseau

Voici un exemple de script complet que vous pouvez utiliser pour réaliser un audit réseau basique :

```powershell
function Start-AuditReseau {
    [CmdletBinding()]
    param (
        [string]$RapportPath = "$env:USERPROFILE\Desktop\AuditReseau.html"
    )

    # Collecte des informations
    Write-Host "Collecte des informations réseau..." -ForegroundColor Cyan

    # 1. Configuration réseau locale
    $interfaces = Get-NetIPConfiguration | Where-Object { $_.NetAdapter.Status -eq "Up" }

    # 2. Tests de connectivité internet
    $testSites = @("google.com", "microsoft.com", "cloudflare.com")
    $testsInternet = $testSites | ForEach-Object {
        $resultat = Test-Connection -ComputerName $_ -Count 1 -Quiet
        [PSCustomObject]@{
            Site = $_
            Accessible = $resultat
        }
    }

    # 3. Liste des 5 dernières connexions établies
    $connexions = Get-NetTCPConnection -State Established |
                  Select-Object -First 5 LocalAddress, LocalPort, RemoteAddress, RemotePort, State

    # 4. Récupération de l'IP externe
    try {
        $ipExterne = (Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 5).ip
    }
    catch {
        $ipExterne = "Non disponible (vérifiez votre connexion Internet)"
    }

    # 5. Test de latence vers des sites populaires
    $latences = $testSites | ForEach-Object {
        $ping = Test-Connection -ComputerName $_ -Count 3 -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Site = $_
            LatenceMoyenne = if ($ping) { ($ping | Measure-Object -Property ResponseTime -Average).Average } else { "Timeout" }
        }
    }

    # Génération du rapport HTML
    Write-Host "Génération du rapport HTML..." -ForegroundColor Cyan

    $rapport = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'audit réseau PowerShell</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #0066cc; }
        h2 { color: #0099cc; border-bottom: 1px solid #ddd; padding-bottom: 5px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { text-align: left; padding: 8px; border: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Rapport d'audit réseau PowerShell</h1>
    <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>

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

    <h2>Adresse IP externe</h2>
    <p>Votre adresse IP publique est : <strong>$ipExterne</strong></p>

    <h2>Tests de connectivité Internet</h2>
    <table>
        <tr>
            <th>Site</th>
            <th>État</th>
        </tr>
"@

    foreach ($test in $testsInternet) {
        $etat = if ($test.Accessible) { "Accessible" } else { "Non accessible" }
        $classe = if ($test.Accessible) { "success" } else { "error" }
        $rapport += @"
        <tr>
            <td>$($test.Site)</td>
            <td class="$classe">$etat</td>
        </tr>
"@
    }

    $rapport += @"
    </table>

    <h2>Tests de latence</h2>
    <table>
        <tr>
            <th>Site</th>
            <th>Latence moyenne (ms)</th>
        </tr>
"@

    foreach ($latence in $latences) {
        $rapport += @"
        <tr>
            <td>$($latence.Site)</td>
            <td>$($latence.LatenceMoyenne)</td>
        </tr>
"@
    }

    $rapport += @"
    </table>

    <h2>Connexions TCP établies (top 5)</h2>
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
</body>
</html>
"@

    # Sauvegarde du rapport
    $rapport | Out-File -FilePath $RapportPath -Encoding UTF8

    Write-Host "Rapport généré avec succès: $RapportPath" -ForegroundColor Green
    Write-Host "Ouvrez ce fichier dans votre navigateur pour consulter les résultats."

    # Ouverture automatique du rapport si demandé
    $reponse = Read-Host "Souhaitez-vous ouvrir le rapport maintenant? (O/N)"
    if ($reponse -eq "O" -or $reponse -eq "o") {
        Start-Process $RapportPath
    }
}

# Exemple d'utilisation
# Start-AuditReseau
```

## Exercices pratiques

1. **Débutant** : Créez un script qui vérifie si les sites web de votre choix sont accessibles
2. **Intermédiaire** : Modifiez la fonction `Scan-Reseau` pour qu'elle tente de résoudre les noms d'hôtes des machines trouvées
3. **Avancé** : Améliorez le script d'audit réseau pour inclure une carte visuelle de votre réseau local

## Points clés à retenir

- PowerShell offre des commandes natives puissantes pour l'exploration réseau (`Test-Connection`, `Test-NetConnection`, etc.)
- Le traitement d'objets de PowerShell facilite l'analyse et le filtrage des résultats
- Ces outils peuvent être combinés pour créer des scripts d'analyse réseau complets
- Utilisez toujours ces outils de manière responsable et uniquement sur les réseaux que vous êtes autorisé à analyser

## Pour aller plus loin

- Explorez les modules spécialisés comme `NetTCPIP` et `DnsClient`
- Apprenez à utiliser PowerShell pour configurer le pare-feu Windows
- Combinez ces techniques avec des rapports HTML pour créer des tableaux de bord réseau
- Explorez l'utilisation de PowerShell pour la surveillance continue du réseau

---

N'hésitez pas à adapter ces exemples à votre environnement spécifique. La pratique est la clé pour maîtriser ces concepts !

⏭️ [Firewall, pare-feu, et règles Windows Defender](/10-reseau-securite/03-firewall-defender.md)
