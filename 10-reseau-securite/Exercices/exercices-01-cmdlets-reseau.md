# Solutions des exercices - Cmdlets réseau PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Voici les solutions complètes pour les exercices proposés dans le module 11-1 sur les cmdlets réseau.

## Exercice 1 (Débutant)
### Utiliser `Test-Connection` pour vérifier si "facebook.com" est accessible

```powershell
# Solution Exercice 1 - Test simple avec Test-Connection
# Fichier: Exercice1-TestFacebook.ps1

# Affichage d'un message d'information
Write-Host "Vérification de la connectivité vers facebook.com..." -ForegroundColor Cyan

# Test de connexion vers facebook.com
$resultat = Test-Connection -TargetName "facebook.com" -Count 4

# Affichage du résultat
if ($?) {
    Write-Host "facebook.com est accessible!" -ForegroundColor Green
    Write-Host "Détails de la connexion:" -ForegroundColor Green
    $resultat | Format-Table -Property Source, Destination, IPV4Address, "Time(ms)"
} else {
    Write-Host "Impossible de se connecter à facebook.com." -ForegroundColor Red
}

# Version alternative utilisant le paramètre -Quiet
$estAccessible = Test-Connection -TargetName "facebook.com" -Quiet -Count 2
if ($estAccessible) {
    Write-Host "facebook.com est accessible (version -Quiet)!" -ForegroundColor Green
} else {
    Write-Host "facebook.com n'est pas accessible (version -Quiet)." -ForegroundColor Red
}
```

## Exercice 2 (Intermédiaire)
### Script qui teste la connectivité vers 5 sites web populaires

```powershell
# Solution Exercice 2 - Tester plusieurs sites web
# Fichier: Exercice2-TestMultiplesSites.ps1

# Définition d'une liste de sites web populaires à tester
$sitesList = @(
    "google.com",
    "microsoft.com",
    "amazon.com",
    "facebook.com",
    "youtube.com"
)

# Affichage d'un message d'introduction
Write-Host "Test de connectivité vers plusieurs sites web populaires" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan

# Création d'un tableau pour stocker les résultats
$resultats = @()

# Test de chaque site et ajout des résultats au tableau
foreach ($site in $sitesList) {
    Write-Host "Test de $site en cours..." -NoNewline

    try {
        $startTime = Get-Date
        $ping = Test-Connection -TargetName $site -Count 1 -ErrorAction Stop
        $endTime = Get-Date
        $responseTime = [math]::Round(($endTime - $startTime).TotalMilliseconds)

        # Création d'un objet personnalisé avec les informations de connectivité
        $resultats += [PSCustomObject]@{
            'Site Web' = $site
            'Status' = "Connecté"
            'Adresse IP' = $ping.Address.IPAddressToString
            'Temps (ms)' = $ping.Latency
            'Date/Heure' = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        Write-Host " OK!" -ForegroundColor Green
    }
    catch {
        # En cas d'erreur, ajout d'une entrée avec un statut d'échec
        $resultats += [PSCustomObject]@{
            'Site Web' = $site
            'Status' = "Échec"
            'Adresse IP' = "N/A"
            'Temps (ms)' = "N/A"
            'Date/Heure' = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }

        Write-Host " Échec!" -ForegroundColor Red
    }
}

# Affichage des résultats dans un tableau formaté
Write-Host "`nRésultats des tests de connectivité:" -ForegroundColor Cyan
$resultats | Format-Table -AutoSize

# Export des résultats dans un fichier CSV (optionnel)
$dateNow = Get-Date -Format "yyyyMMdd_HHmmss"
$csvPath = "$PSScriptRoot\ConnectivityTest_$dateNow.csv"
$resultats | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";"

Write-Host "Les résultats ont été exportés dans le fichier: $csvPath" -ForegroundColor Yellow
```

## Exercice 3 (Avancé)
### Fonction combinant `Test-NetConnection` et `Resolve-DnsName` pour un rapport complet

```powershell
# Solution Exercice 3 - Rapport complet d'un domaine
# Fichier: Exercice3-RapportDomaine.ps1

function Get-DomainReport {
    <#
    .SYNOPSIS
        Génère un rapport complet sur un nom de domaine.

    .DESCRIPTION
        Cette fonction combine Test-NetConnection et Resolve-DnsName pour afficher
        un rapport détaillé sur un nom de domaine, incluant son adresse IP, temps de
        réponse, enregistrements DNS (A, MX, NS, TXT) et connectivité sur les ports
        courants.

    .PARAMETER DomainName
        Le nom de domaine à analyser. Exemple: google.com, microsoft.com

    .PARAMETER ShowAllRecords
        Indique si tous les types d'enregistrements DNS doivent être affichés.
        Par défaut, seuls les enregistrements A, MX, NS et TXT sont affichés.

    .EXAMPLE
        Get-DomainReport -DomainName "google.com"

    .EXAMPLE
        Get-DomainReport -DomainName "microsoft.com" -ShowAllRecords
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$DomainName,

        [Parameter(Mandatory = $false)]
        [switch]$ShowAllRecords
    )

    # Création d'un objet pour stocker toutes les informations
    $rapport = [PSCustomObject]@{
        Domaine = $DomainName
        DateRapport = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ConnectiviteIP = $null
        AdressesIP = @()
        PortsOuverts = @()
        EnregistrementsA = @()
        EnregistrementsAAAA = @()
        EnregistrementsMX = @()
        EnregistrementsNS = @()
        EnregistrementsTXT = @()
        TraceRoute = @()
        Whois = $null
    }

    Write-Host "Génération du rapport pour le domaine: $DomainName" -ForegroundColor Cyan
    Write-Host "=================================================" -ForegroundColor Cyan

    # Test de connectivité IP
    try {
        Write-Host "Test de connectivité IP..." -NoNewline
        $pingTest = Test-Connection -TargetName $DomainName -Count 2 -ErrorAction Stop

        $rapport.ConnectiviteIP = [PSCustomObject]@{
            Succes = $true
            TempsReponse = "$($pingTest[0].Latency) ms / $($pingTest[1].Latency) ms"
            Source = $pingTest[0].Source
        }

        Write-Host " OK!" -ForegroundColor Green
    }
    catch {
        $rapport.ConnectiviteIP = [PSCustomObject]@{
            Succes = $false
            TempsReponse = "N/A"
            Source = $env:COMPUTERNAME
        }

        Write-Host " Échec!" -ForegroundColor Red
    }

    # Résolution DNS - Adresses IP
    try {
        Write-Host "Résolution des adresses IP..." -NoNewline

        # Enregistrements A (IPv4)
        $recordsA = Resolve-DnsName -Name $DomainName -Type A -ErrorAction SilentlyContinue
        if ($recordsA) {
            foreach ($record in $recordsA | Where-Object { $_.Type -eq 'A' }) {
                $rapport.EnregistrementsA += [PSCustomObject]@{
                    Type = 'A'
                    Valeur = $record.IPAddress
                    TTL = $record.TTL
                }
                $rapport.AdressesIP += $record.IPAddress
            }
        }

        # Enregistrements AAAA (IPv6)
        $recordsAAAA = Resolve-DnsName -Name $DomainName -Type AAAA -ErrorAction SilentlyContinue
        if ($recordsAAAA) {
            foreach ($record in $recordsAAAA | Where-Object { $_.Type -eq 'AAAA' }) {
                $rapport.EnregistrementsAAAA += [PSCustomObject]@{
                    Type = 'AAAA'
                    Valeur = $record.IPAddress
                    TTL = $record.TTL
                }
            }
        }

        Write-Host " OK!" -ForegroundColor Green
    }
    catch {
        Write-Host " Échec!" -ForegroundColor Red
    }

    # Enregistrements MX
    try {
        Write-Host "Résolution des enregistrements MX..." -NoNewline
        $recordsMX = Resolve-DnsName -Name $DomainName -Type MX -ErrorAction SilentlyContinue

        if ($recordsMX) {
            foreach ($record in $recordsMX | Where-Object { $_.Type -eq 'MX' }) {
                $rapport.EnregistrementsMX += [PSCustomObject]@{
                    Preference = $record.Preference
                    Exchange = $record.NameExchange
                    TTL = $record.TTL
                }
            }
            Write-Host " OK!" -ForegroundColor Green
        }
        else {
            Write-Host " Aucun trouvé" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " Échec!" -ForegroundColor Red
    }

    # Enregistrements NS
    try {
        Write-Host "Résolution des enregistrements NS..." -NoNewline
        $recordsNS = Resolve-DnsName -Name $DomainName -Type NS -ErrorAction SilentlyContinue

        if ($recordsNS) {
            foreach ($record in $recordsNS | Where-Object { $_.Type -eq 'NS' }) {
                $rapport.EnregistrementsNS += [PSCustomObject]@{
                    NameServer = $record.NameHost
                    TTL = $record.TTL
                }
            }
            Write-Host " OK!" -ForegroundColor Green
        }
        else {
            Write-Host " Aucun trouvé" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " Échec!" -ForegroundColor Red
    }

    # Enregistrements TXT
    try {
        Write-Host "Résolution des enregistrements TXT..." -NoNewline
        $recordsTXT = Resolve-DnsName -Name $DomainName -Type TXT -ErrorAction SilentlyContinue

        if ($recordsTXT) {
            foreach ($record in $recordsTXT | Where-Object { $_.Type -eq 'TXT' }) {
                $rapport.EnregistrementsTXT += [PSCustomObject]@{
                    Texte = $record.Strings -join ""
                    TTL = $record.TTL
                }
            }
            Write-Host " OK!" -ForegroundColor Green
        }
        else {
            Write-Host " Aucun trouvé" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " Échec!" -ForegroundColor Red
    }

    # Test des ports courants
    $portsToTest = @(80, 443, 21, 22, 25, 53, 3389)
    Write-Host "Test des ports courants ($($portsToTest -join ", "))..." -ForegroundColor Cyan

    foreach ($port in $portsToTest) {
        Write-Host "  Test du port $port..." -NoNewline

        try {
            $portTest = Test-NetConnection -ComputerName $DomainName -Port $port -WarningAction SilentlyContinue -ErrorAction Stop -InformationLevel Quiet

            if ($portTest.TcpTestSucceeded) {
                $rapport.PortsOuverts += [PSCustomObject]@{
                    Port = $port
                    Ouvert = $true
                    Service = switch ($port) {
                        80 { "HTTP" }
                        443 { "HTTPS" }
                        21 { "FTP" }
                        22 { "SSH" }
                        25 { "SMTP" }
                        53 { "DNS" }
                        3389 { "RDP" }
                        default { "Inconnu" }
                    }
                }
                Write-Host " Ouvert!" -ForegroundColor Green
            }
            else {
                Write-Host " Fermé" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host " Erreur lors du test" -ForegroundColor Red
        }
    }

    # Traceroute
    try {
        Write-Host "Exécution du traceroute..." -NoNewline
        $trace = Test-NetConnection -ComputerName $DomainName -TraceRoute -WarningAction SilentlyContinue

        if ($trace.TraceRoute) {
            $hopNumber = 1
            foreach ($hop in $trace.TraceRoute) {
                $rapport.TraceRoute += [PSCustomObject]@{
                    Hop = $hopNumber
                    Adresse = $hop
                }
                $hopNumber++
            }
            Write-Host " OK!" -ForegroundColor Green
        }
        else {
            Write-Host " Pas de résultats" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " Échec!" -ForegroundColor Red
    }

    # Afficher le rapport
    Write-Host "`nRapport complet pour $DomainName" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan

    Write-Host "`n[CONNECTIVITÉ]" -ForegroundColor Yellow
    Write-Host "Statut: $(if ($rapport.ConnectiviteIP.Succes) { "Connecté" } else { "Non connecté" })"
    Write-Host "Temps de réponse: $($rapport.ConnectiviteIP.TempsReponse)"

    Write-Host "`n[ADRESSES IP]" -ForegroundColor Yellow
    if ($rapport.AdressesIP.Count -gt 0) {
        $rapport.AdressesIP | ForEach-Object { Write-Host "- $_" }
    } else {
        Write-Host "Aucune adresse IP trouvée"
    }

    Write-Host "`n[PORTS]" -ForegroundColor Yellow
    if ($rapport.PortsOuverts.Count -gt 0) {
        $rapport.PortsOuverts | Format-Table -Property Port, Service
    } else {
        Write-Host "Aucun port ouvert trouvé"
    }

    Write-Host "`n[ENREGISTREMENTS DNS]" -ForegroundColor Yellow

    Write-Host "`nEnregistrements A:"
    if ($rapport.EnregistrementsA.Count -gt 0) {
        $rapport.EnregistrementsA | Format-Table -Property Valeur, TTL
    } else {
        Write-Host "Aucun enregistrement A trouvé"
    }

    Write-Host "`nEnregistrements AAAA:"
    if ($rapport.EnregistrementsAAAA.Count -gt 0) {
        $rapport.EnregistrementsAAAA | Format-Table -Property Valeur, TTL
    } else {
        Write-Host "Aucun enregistrement AAAA trouvé"
    }

    Write-Host "`nEnregistrements MX:"
    if ($rapport.EnregistrementsMX.Count -gt 0) {
        $rapport.EnregistrementsMX | Format-Table -Property Preference, Exchange, TTL
    } else {
        Write-Host "Aucun enregistrement MX trouvé"
    }

    Write-Host "`nEnregistrements NS:"
    if ($rapport.EnregistrementsNS.Count -gt 0) {
        $rapport.EnregistrementsNS | Format-Table -Property NameServer, TTL
    } else {
        Write-Host "Aucun enregistrement NS trouvé"
    }

    Write-Host "`nEnregistrements TXT:"
    if ($rapport.EnregistrementsTXT.Count -gt 0) {
        foreach ($txt in $rapport.EnregistrementsTXT) {
            Write-Host "- $($txt.Texte)"
        }
    } else {
        Write-Host "Aucun enregistrement TXT trouvé"
    }

    Write-Host "`n[TRACEROUTE]" -ForegroundColor Yellow
    if ($rapport.TraceRoute.Count -gt 0) {
        $rapport.TraceRoute | Format-Table -Property Hop, Adresse
    } else {
        Write-Host "Pas de données de traceroute disponibles"
    }

    # Retourne l'objet rapport complet
    return $rapport
}

# Test de la fonction
Write-Host "DÉMONSTRATION DE LA FONCTION GET-DOMAINREPORT" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

# Demande à l'utilisateur de saisir un nom de domaine ou utilise l'exemple par défaut
$domainToTest = Read-Host "Entrez un nom de domaine à analyser (ou appuyez sur Entrée pour utiliser 'example.com')"
if ([string]::IsNullOrWhiteSpace($domainToTest)) {
    $domainToTest = "example.com"
}

# Exécution de la fonction
$rapportComplet = Get-DomainReport -DomainName $domainToTest

# Export des résultats (optionnel)
$dateNow = Get-Date -Format "yyyyMMdd_HHmmss"
$exportPath = "$PSScriptRoot\DomainReport_${domainToTest}_$dateNow.xml"
$rapportComplet | Export-Clixml -Path $exportPath

Write-Host "`nRapport complet exporté au format XML: $exportPath" -ForegroundColor Yellow
Write-Host "Pour recharger le rapport ultérieurement: Import-Clixml -Path `"$exportPath`"" -ForegroundColor Yellow
```

## Comment utiliser ces scripts

1. **Pour l'exercice 1 (débutant)**:
   - Copiez le code dans un fichier nommé `Exercice1-TestFacebook.ps1`
   - Exécutez-le dans PowerShell en tapant `.\Exercice1-TestFacebook.ps1`

2. **Pour l'exercice 2 (intermédiaire)**:
   - Copiez le code dans un fichier nommé `Exercice2-TestMultiplesSites.ps1`
   - Exécutez-le dans PowerShell en tapant `.\Exercice2-TestMultiplesSites.ps1`
   - Le script créera un fichier CSV avec les résultats dans le même dossier

3. **Pour l'exercice 3 (avancé)**:
   - Copiez le code dans un fichier nommé `Exercice3-RapportDomaine.ps1`
   - Exécutez-le dans PowerShell en tapant `.\Exercice3-RapportDomaine.ps1`
   - Vous pouvez également importer la fonction dans votre session PowerShell avec `. .\Exercice3-RapportDomaine.ps1`
   - Utilisez ensuite la fonction avec `Get-DomainReport -DomainName "google.com"`

## Points d'apprentissage

Ces scripts illustrent plusieurs concepts PowerShell importants:

1. **Gestion des erreurs** avec `try/catch`
2. **Création d'objets personnalisés** avec `[PSCustomObject]@{}`
3. **Formatage des sorties** avec `Format-Table`
4. **Export de données** avec `Export-Csv` et `Export-Clixml`
5. **Documentation avancée** avec les commentaires `.SYNOPSIS`, `.DESCRIPTION`, etc.
6. **Paramètres de fonctions** et validation avec `[Parameter()]` et `[ValidateNotNullOrEmpty()]`
7. **Affichage coloré** avec `Write-Host -ForegroundColor`
8. **Opérateurs de pipeline** pour traiter les collections d'objets

Vous pouvez modifier ces scripts selon vos besoins spécifiques et les adapter à votre environnement réseau.
