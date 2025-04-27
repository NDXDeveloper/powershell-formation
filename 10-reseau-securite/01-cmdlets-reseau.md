# Module 11 - Réseau & Sécurité
## 11-1. Cmdlets réseau : `Test-Connection`, `Test-NetConnection`, `Resolve-DnsName`

Dans ce chapitre, nous allons explorer les cmdlets PowerShell essentielles pour diagnostiquer et travailler avec les connexions réseau. Ces commandes sont des outils précieux pour tout administrateur système ou développeur.

### Introduction aux cmdlets réseau

PowerShell offre plusieurs cmdlets puissantes pour interagir avec le réseau. Ces outils vous permettent de vérifier la connectivité, résoudre des noms de domaines et diagnostiquer des problèmes réseau, le tout depuis la console PowerShell.

### `Test-Connection` - Le ping version PowerShell

La cmdlet `Test-Connection` est l'équivalent PowerShell de la commande `ping` traditionnelle, mais avec des fonctionnalités supplémentaires.

#### Syntaxe de base

```powershell
Test-Connection -TargetName "nom_ou_adresse_ip" [options]
```

#### Exemples d'utilisation

**Ping simple vers un hôte**

```powershell
Test-Connection -TargetName "google.com"
```

Ce qui affichera des résultats similaires à :

```
Source        Destination     IPV4Address      IPV6Address                              Bytes    Time(ms)
------        -----------     -----------      -----------                              -----    --------
LAPTOP-PC     google.com      142.250.201.78                                            32       18
LAPTOP-PC     google.com      142.250.201.78                                            32       20
LAPTOP-PC     google.com      142.250.201.78                                            32       17
LAPTOP-PC     google.com      142.250.201.78                                            32       18
```

**Test avec un nombre spécifique de paquets**

```powershell
Test-Connection -TargetName "google.com" -Count 2
```

**Vérifier si un hôte est accessible (retourne True ou False)**

```powershell
Test-Connection -TargetName "google.com" -Quiet
```

**Tester plusieurs destinations simultanément**

```powershell
Test-Connection -TargetName "google.com", "bing.com", "yahoo.com" -Count 1
```

**Définir un délai d'attente personnalisé (en millisecondes)**

```powershell
Test-Connection -TargetName "google.com" -TimeoutSeconds 1
```

### `Test-NetConnection` - Diagnostics réseau avancés

`Test-NetConnection` est une cmdlet plus récente qui offre des fonctionnalités avancées pour diagnostiquer les problèmes réseau.

#### Syntaxe de base

```powershell
Test-NetConnection -ComputerName "nom_ou_adresse_ip" [options]
```

#### Exemples d'utilisation

**Test simple de connectivité**

```powershell
Test-NetConnection -ComputerName "google.com"
```

Ce qui affichera :

```
ComputerName           : google.com
RemoteAddress          : 142.250.201.78
InterfaceAlias         : Wi-Fi
SourceAddress          : 192.168.1.12
PingSucceeded          : True
PingReplyDetails (RTT) : 20 ms
```

**Tester une connexion sur un port spécifique**

```powershell
Test-NetConnection -ComputerName "google.com" -Port 443
```

Cette commande vérifie si le port 443 (HTTPS) est accessible sur google.com :

```
ComputerName     : google.com
RemoteAddress    : 142.250.201.78
RemotePort       : 443
InterfaceAlias   : Wi-Fi
SourceAddress    : 192.168.1.12
TcpTestSucceeded : True
```

**Effectuer un traceroute**

```powershell
Test-NetConnection -ComputerName "google.com" -TraceRoute
```

Cette commande affiche le chemin que prennent les paquets pour atteindre google.com :

```
ComputerName           : google.com
RemoteAddress          : 142.250.201.78
InterfaceAlias         : Wi-Fi
SourceAddress          : 192.168.1.12
PingSucceeded          : True
PingReplyDetails (RTT) : 20 ms
TraceRoute             : 192.168.1.1
                         82.64.223.254
                         84.37.25.194
                         84.37.25.186
                         72.14.204.232
                         142.250.201.78
```

### `Resolve-DnsName` - Résolution DNS

`Resolve-DnsName` permet de résoudre les noms de domaine en adresses IP ou d'effectuer d'autres types de requêtes DNS.

#### Syntaxe de base

```powershell
Resolve-DnsName -Name "nom_de_domaine" [options]
```

#### Exemples d'utilisation

**Résolution DNS simple**

```powershell
Resolve-DnsName -Name "google.com"
```

Cela affiche les différents enregistrements DNS associés à google.com :

```
Name                                           Type   TTL   Section    IPAddress
----                                           ----   ---   -------    ---------
google.com                                     A      300   Answer     142.250.201.78
google.com                                     AAAA   300   Answer     2a00:1450:4007:80e::200e
```

**Spécifier un type d'enregistrement DNS**

```powershell
Resolve-DnsName -Name "google.com" -Type MX
```

Cette commande recherche spécifiquement les enregistrements MX (Mail Exchange) :

```
Name                                           Type   TTL   Section    NameExchange
----                                           ----   ---   -------    ------------
google.com                                     MX     300   Answer     alt3.aspmx.l.google.com
google.com                                     MX     300   Answer     alt4.aspmx.l.google.com
google.com                                     MX     300   Answer     alt1.aspmx.l.google.com
google.com                                     MX     300   Answer     alt2.aspmx.l.google.com
google.com                                     MX     300   Answer     aspmx.l.google.com
```

**Utiliser un serveur DNS spécifique**

```powershell
Resolve-DnsName -Name "google.com" -Server "8.8.8.8"
```

Cette commande utilise le serveur DNS public de Google (8.8.8.8) pour résoudre google.com.

### Utilisation pratique des cmdlets réseau

#### Vérifier la connectivité réseau de plusieurs serveurs

```powershell
$Serveurs = "google.com", "microsoft.com", "github.com"
$Resultats = foreach ($Serveur in $Serveurs) {
    Test-Connection -TargetName $Serveur -Count 1 -Quiet
    $Statut = if ($?) { "Connecté" } else { "Non connecté" }
    [PSCustomObject]@{
        Serveur = $Serveur
        Statut = $Statut
    }
}
$Resultats | Format-Table -AutoSize
```

#### Vérifier si un site web est accessible (HTTP/HTTPS)

```powershell
function Test-SiteWeb {
    param([string]$URL)
    try {
        $Site = Test-NetConnection -ComputerName $URL -Port 443
        if ($Site.TcpTestSucceeded) {
            Write-Host "Le site $URL est accessible via HTTPS (port 443)" -ForegroundColor Green
        } else {
            Write-Host "Le site $URL n'est pas accessible via HTTPS (port 443)" -ForegroundColor Red
        }
    } catch {
        Write-Host "Erreur lors du test de $URL : $_" -ForegroundColor Red
    }
}

Test-SiteWeb -URL "google.com"
```

### Exercices pratiques

1. **Exercice débutant**: Utilisez `Test-Connection` pour vérifier si "facebook.com" est accessible depuis votre ordinateur.

2. **Exercice intermédiaire**: Créez un script qui teste la connectivité vers 5 sites web populaires et affiche les résultats dans un tableau.

3. **Exercice avancé**: Écrivez une fonction qui combine `Test-NetConnection` et `Resolve-DnsName` pour afficher un rapport complet sur un nom de domaine (adresse IP, temps de réponse, enregistrements MX, etc.).

### Points clés à retenir

- `Test-Connection` remplace la commande `ping` traditionnelle avec des fonctionnalités PowerShell supplémentaires
- `Test-NetConnection` offre des diagnostics réseau plus avancés, comme la vérification de ports et le traceroute
- `Resolve-DnsName` permet d'effectuer des requêtes DNS directement depuis PowerShell
- Ces cmdlets peuvent être intégrées dans des scripts pour automatiser les tâches de surveillance réseau

### Astuces pour débutants

- Commencez par explorer ces cmdlets avec des sites connus comme google.com
- Utilisez le paramètre `-Verbose` pour obtenir plus d'informations sur ce qui se passe
- N'hésitez pas à combiner ces cmdlets avec ce que vous avez appris sur les pipelines PowerShell

---

Dans le prochain chapitre, nous explorerons les techniques de découverte réseau, notamment comment scanner des réseaux, vérifier des ports et effectuer des analyses IP.
