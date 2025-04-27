# Module 11-3: Firewall, pare-feu, et règles Windows Defender

## 🔍 Vue d'ensemble

Windows Defender Firewall est un composant essentiel de la sécurité Windows qui contrôle le trafic réseau entrant et sortant de votre ordinateur. PowerShell offre des cmdlets puissantes pour gérer ce pare-feu, ce qui vous permet d'automatiser la création, la modification et la suppression des règles de sécurité.

## 📋 Prérequis

- PowerShell 5.1 ou PowerShell 7+
- Droits d'administration sur le système
- Module NetSecurity chargé (généralement préinstallé)

## 🛠️ Concepts fondamentaux

### Qu'est-ce qu'un pare-feu?

Un pare-feu (ou firewall) agit comme un gardien entre votre ordinateur et le réseau. Il filtre le trafic réseau selon des règles prédéfinies pour protéger votre système contre les accès non autorisés.

### Types de règles de pare-feu

Dans Windows, les règles de pare-feu se divisent en deux catégories principales:

- **Règles entrantes** - Contrôlent le trafic qui tente d'accéder à votre ordinateur
- **Règles sortantes** - Contrôlent le trafic qui quitte votre ordinateur vers le réseau

## 🧰 Cmdlets essentiels pour gérer le pare-feu

PowerShell dispose du module `NetSecurity` qui contient les cmdlets nécessaires pour travailler avec le pare-feu Windows. Voici les plus importantes:

```powershell
# Afficher toutes les cmdlets liées au pare-feu
Get-Command -Module NetSecurity

# Les plus couramment utilisées
Get-NetFirewallRule          # Liste les règles de pare-feu
New-NetFirewallRule          # Crée une nouvelle règle
Set-NetFirewallRule          # Modifie une règle existante
Remove-NetFirewallRule       # Supprime une règle
Enable-NetFirewallRule       # Active une règle
Disable-NetFirewallRule      # Désactive une règle
Get-NetFirewallProfile       # Affiche les profils de pare-feu
Set-NetFirewallProfile       # Configure les paramètres du profil
```

## 📚 Utilisation pratique du pare-feu

### 1. Afficher les règles existantes

Commençons par explorer les règles de pare-feu actuellement configurées:

```powershell
# Afficher toutes les règles (attention: il y en a beaucoup!)
Get-NetFirewallRule

# Filtrer les règles pour une meilleure lisibilité
Get-NetFirewallRule | Where-Object Enabled -eq 'True' | Format-Table Name, DisplayName, Direction, Action -AutoSize

# Rechercher une règle spécifique (par exemple pour PowerShell)
Get-NetFirewallRule -DisplayName "*PowerShell*"
```

### 2. Les profils de pare-feu

Windows utilise trois profils de pare-feu différents selon le type de réseau:

```powershell
# Afficher l'état des profils
Get-NetFirewallProfile | Format-Table Name, Enabled

# Les trois profils sont:
# - Domain: utilisé lorsque l'ordinateur est connecté à un domaine
# - Private: utilisé pour les réseaux domestiques ou de confiance
# - Public: utilisé pour les réseaux publics (cafés, aéroports...)
```

### 3. Créer une règle de pare-feu

Créons une règle simple pour autoriser une application:

```powershell
# Créer une règle pour autoriser une application (exemple avec Notepad)
New-NetFirewallRule -DisplayName "Autoriser Notepad" `
                    -Direction Inbound `
                    -Program "%SystemRoot%\system32\notepad.exe" `
                    -Action Allow `
                    -Profile Domain,Private

# Créer une règle pour autoriser un port spécifique
New-NetFirewallRule -DisplayName "Autoriser le port 8080" `
                    -Direction Inbound `
                    -LocalPort 8080 `
                    -Protocol TCP `
                    -Action Allow
```

#### Paramètres importants pour `New-NetFirewallRule`:

| Paramètre | Description |
|-----------|-------------|
| `-DisplayName` | Nom convivial pour identifier la règle |
| `-Direction` | `Inbound` (entrante) ou `Outbound` (sortante) |
| `-Program` | Chemin de l'application concernée |
| `-LocalPort` | Port(s) à autoriser/bloquer |
| `-Protocol` | Protocole (TCP, UDP, ICMP, etc.) |
| `-Action` | `Allow` (autoriser) ou `Block` (bloquer) |
| `-Profile` | `Domain`, `Private`, `Public` ou une combinaison |
| `-Enabled` | `True` ou `False` pour activer/désactiver |

### 4. Modifier une règle existante

Vous pouvez facilement modifier les paramètres d'une règle:

```powershell
# Modifier une règle existante (par exemple pour ajouter un profil)
Get-NetFirewallRule -DisplayName "Autoriser Notepad" |
    Set-NetFirewallRule -Profile Domain,Private,Public

# Désactiver temporairement une règle
Disable-NetFirewallRule -DisplayName "Autoriser Notepad"

# Réactiver une règle
Enable-NetFirewallRule -DisplayName "Autoriser Notepad"
```

### 5. Supprimer une règle

Si vous n'avez plus besoin d'une règle, vous pouvez la supprimer:

```powershell
# Supprimer une règle par son nom
Remove-NetFirewallRule -DisplayName "Autoriser Notepad"

# Attention: soyez prudent avant de supprimer des règles système!
```

## 🔄 Scénarios pratiques

### Scénario 1: Autoriser une application à communiquer sur le réseau

```powershell
# Exemple: Autoriser l'application MyApp.exe à communiquer sur le réseau
New-NetFirewallRule -DisplayName "Mon Application" `
                    -Direction Inbound `
                    -Program "C:\Program Files\MyApp\MyApp.exe" `
                    -Action Allow `
                    -Profile Domain,Private `
                    -Description "Permet à MyApp de recevoir des connexions"
```

### Scénario 2: Bloquer un port spécifique

```powershell
# Exemple: Bloquer le port 3389 (RDP) sur les réseaux publics
New-NetFirewallRule -DisplayName "Bloquer RDP Public" `
                    -Direction Inbound `
                    -LocalPort 3389 `
                    -Protocol TCP `
                    -Action Block `
                    -Profile Public `
                    -Description "Bloque les connexions RDP sur les réseaux publics"
```

### Scénario 3: Configurer les paramètres globaux du pare-feu

```powershell
# Désactiver toutes les connexions entrantes sur le profil Public (maximum de sécurité)
Set-NetFirewallProfile -Profile Public -DefaultInboundAction Block -DefaultOutboundAction Allow -NotifyOnListen True

# Voir l'état actuel de tous les profils
Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction
```

## 🔍 Vérification des règles

Pour vérifier si vos règles sont bien configurées:

```powershell
# Vérifier si une application est autorisée
$app = "C:\Program Files\MyApp\MyApp.exe"
Get-NetFirewallRule |
    Where-Object { $_.Enabled -eq 'True' -and $_.Direction -eq 'Inbound' } |
    Get-NetFirewallApplicationFilter |
    Where-Object { $_.Program -eq $app } |
    Select-Object -ExpandProperty Program

# Tester si un port est ouvert
Test-NetConnection -ComputerName localhost -Port 8080
```

## ⚠️ Bonnes pratiques et sécurité

1. **Principe du moindre privilège**: N'autorisez que ce qui est nécessaire
2. **Documentation**: Ajoutez toujours une description à vos règles (`-Description`)
3. **Nommage**: Utilisez des noms clairs et descriptifs (`-DisplayName`)
4. **Sauvegarde**: Avant de faire des modifications importantes:
   ```powershell
   # Exporter la configuration actuelle du pare-feu
   $date = Get-Date -Format "yyyyMMdd"
   $backupFile = "C:\Backup\FirewallRules_$date.wfw"

   # Nécessite des droits d'administration
   netsh advfirewall export $backupFile
   ```
5. **Test**: Testez vos modifications pour vous assurer qu'elles fonctionnent comme prévu

## 💻 Exercices pratiques

### Exercice 1: Lister toutes vos règles actives
```powershell
# Affichez toutes les règles actives triées par direction (entrante/sortante)
Get-NetFirewallRule |
    Where-Object Enabled -eq 'True' |
    Sort-Object Direction |
    Format-Table DisplayName, Direction, Action -GroupBy Direction -AutoSize
```

### Exercice 2: Créer une règle pour votre application préférée
```powershell
# Remplacez le chemin par celui de votre application
$application = "C:\Chemin\Vers\MonApplication.exe"

New-NetFirewallRule -DisplayName "Mon application préférée" `
                   -Direction Inbound `
                   -Program $application `
                   -Action Allow `
                   -Profile Private,Domain
```

## 📚 Pour aller plus loin

- Explorez les fonctionnalités avancées comme les filtres d'adresses IP (`-RemoteAddress`)
- Apprenez à gérer les règles par groupe (`-Group`)
- Découvrez comment automatiser la configuration du pare-feu à l'aide de scripts

## 📝 Récapitulatif

Dans ce module, vous avez appris:
- Les bases du pare-feu Windows Defender
- Comment afficher, créer, modifier et supprimer des règles de pare-feu
- Comment gérer les profils de pare-feu
- Des scénarios pratiques pour sécuriser votre système

N'oubliez pas que la gestion du pare-feu est une tâche critique pour la sécurité. Prenez toujours des précautions et testez vos modifications dans un environnement contrôlé avant de les appliquer à des systèmes de production.

## 🔗 Ressources supplémentaires

- Documentation Microsoft: [NetSecurity Module](https://docs.microsoft.com/en-us/powershell/module/netsecurity/)
- Blog Microsoft: [Sécuriser Windows avec PowerShell](https://devblogs.microsoft.com/scripting/)
