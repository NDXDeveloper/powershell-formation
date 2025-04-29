# 11-5. Sécurité des scripts : droits, exécution, sessions à privilèges

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📌 Introduction

La sécurité est un aspect fondamental lors de l'exécution de scripts PowerShell. Dans cette section, nous allons découvrir comment gérer les droits d'exécution, sécuriser vos scripts et utiliser des sessions avec privilèges de manière responsable.

## 📌 Stratégies d'exécution (Execution Policy)

PowerShell utilise des stratégies d'exécution pour déterminer quels scripts peuvent être exécutés et dans quelles conditions.

### Les différentes stratégies d'exécution

```powershell
# Pour afficher la stratégie d'exécution actuelle
Get-ExecutionPolicy

# Pour afficher toutes les stratégies d'exécution actuelles à différents niveaux
Get-ExecutionPolicy -List
```

Voici les principales stratégies :

| Stratégie | Description |
|-----------|-------------|
| `Restricted` | Mode par défaut. Aucun script n'est autorisé à s'exécuter. |
| `AllSigned` | Seuls les scripts signés par un éditeur de confiance peuvent s'exécuter. |
| `RemoteSigned` | Les scripts locaux peuvent s'exécuter. Les scripts téléchargés doivent être signés. |
| `Unrestricted` | Tous les scripts peuvent s'exécuter (avec avertissement pour les scripts téléchargés). |
| `Bypass` | Aucune restriction, aucun avertissement (dangereux). |

### Modifier la stratégie d'exécution

```powershell
# Pour modifier la stratégie (nécessite des droits administrateur)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# Pour modifier la stratégie uniquement pour l'utilisateur actuel
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

> ⚠️ **Attention** : Ne définissez pas la stratégie sur `Unrestricted` ou `Bypass` sans raison valable, car cela pourrait compromettre la sécurité de votre système.

### Contourner temporairement la stratégie d'exécution

Pour exécuter un script ponctuellement sans modifier la stratégie globale :

```powershell
# Exécuter un script en contournant la stratégie d'exécution actuelle
PowerShell -ExecutionPolicy Bypass -File .\MonScript.ps1
```

## 📌 Signature de scripts

La signature de scripts est une méthode sécurisée pour garantir l'intégrité et l'authenticité de vos scripts.

### Créer un certificat auto-signé (à des fins de test)

```powershell
# Créer un certificat auto-signé
$cert = New-SelfSignedCertificate -Subject "CN=PowerShell Code Signing" -Type CodeSigning -CertStoreLocation Cert:\CurrentUser\My
```

### Signer un script

```powershell
# Signer un script avec votre certificat
Set-AuthenticodeSignature -FilePath .\MonScript.ps1 -Certificate $cert
```

### Vérifier la signature d'un script

```powershell
# Vérifier si un script est correctement signé
Get-AuthenticodeSignature -FilePath .\MonScript.ps1
```

## 📌 Élévation de privilèges

Certaines opérations nécessitent des privilèges administrateur. Voici comment gérer cela en PowerShell.

### Détecter si PowerShell s'exécute avec des privilèges élevés

```powershell
# Vérifier si la session actuelle a des privilèges d'administrateur
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (Test-Admin) {
    Write-Host "Session avec privilèges administrateur" -ForegroundColor Green
} else {
    Write-Host "Session standard (non administrateur)" -ForegroundColor Yellow
}
```

### Démarrer un nouveau processus PowerShell avec élévation

Dans un script, vous pouvez redémarrer PowerShell avec élévation si nécessaire :

```powershell
if (-not (Test-Admin)) {
    Write-Host "Redémarrage avec privilèges administrateur..."
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Le reste du script s'exécutera avec des privilèges administrateur
```

## 📌 Sessions à privilèges (RunAs)

Pour exécuter des commandes avec des identifiants spécifiques sans modifier votre session actuelle.

### Créer et utiliser une session avec des identifiants différents

```powershell
# Créer un objet d'identifiants
$credential = Get-Credential -Message "Entrez les identifiants pour cette commande"

# Exécuter une commande avec ces identifiants
Start-Process PowerShell -Credential $credential -ArgumentList "-Command Get-Service"

# Ou pour un script complet
Start-Process PowerShell -Credential $credential -ArgumentList "-File C:\Scripts\MonScript.ps1"
```

### Sessions à distance avec privilèges

```powershell
# Créer une session PowerShell à distance avec des identifiants spécifiques
$session = New-PSSession -ComputerName "ServeurCible" -Credential $credential

# Exécuter des commandes dans cette session
Invoke-Command -Session $session -ScriptBlock {
    # Commandes à exécuter sur le serveur distant avec les privilèges spécifiés
    Get-Service
}

# Fermer la session quand vous avez terminé
Remove-PSSession $session
```

## 📌 Bonnes pratiques de sécurité pour les scripts

1. **Principe du moindre privilège** : Exécutez toujours vos scripts avec les privilèges minimaux nécessaires.

2. **Validez les entrées** : Ne faites jamais confiance aux entrées utilisateur sans les valider.
   ```powershell
   # Mauvaise pratique (vulnérable à l'injection)
   Invoke-Expression "Get-Service $userInput"

   # Bonne pratique
   Get-Service -Name $userInput -ErrorAction SilentlyContinue
   ```

3. **Sécurisez les identifiants** : N'intégrez jamais de mots de passe en clair dans vos scripts.
   ```powershell
   # Utiliser des identifiants chiffrés
   $securePassword = ConvertTo-SecureString "MonMotDePasse" -AsPlainText -Force
   $credential = New-Object System.Management.Automation.PSCredential("Utilisateur", $securePassword)

   # Mieux : stocker les mots de passe de manière sécurisée
   $credential = Get-Credential
   $credential | Export-CliXml -Path "C:\Secure\credentials.xml"

   # Plus tard, charger les identifiants
   $credential = Import-CliXml -Path "C:\Secure\credentials.xml"
   ```

4. **Limitez la portée des variables** : Utilisez des variables locales au lieu de variables globales.

5. **Journalisez les actions sensibles** : Gardez une trace des opérations importantes.
   ```powershell
   # Exemple simple de journalisation
   function Write-Log {
       param($Message)
       $logMessage = "$(Get-Date) - $Message"
       Add-Content -Path "C:\Logs\script.log" -Value $logMessage
   }

   Write-Log "L'utilisateur $env:USERNAME a exécuté l'opération X avec les privilèges Y"
   ```

## 📌 Exercice pratique

Créez un script qui :
1. Vérifie s'il s'exécute avec des privilèges administrateur
2. Se relance avec élévation si nécessaire
3. Effectue une opération administrative (par exemple, démarrer un service)
4. Journalise l'action effectuée

```powershell
# ExercicePrivileges.ps1
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Log {
    param($Message)
    $logFile = "$env:TEMP\script_log.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
}

# Vérifier les privilèges
if (-not (Test-Admin)) {
    Write-Host "Élévation des privilèges nécessaire. Redémarrage en administrateur..." -ForegroundColor Yellow
    Start-Process PowerShell -Verb RunAs -ArgumentList "-File `"$PSCommandPath`""
    exit
}

# Code qui nécessite des privilèges administrateur
$serviceName = "Spooler"  # Service d'impression
Write-Host "Tentative de redémarrage du service $serviceName..." -ForegroundColor Cyan

try {
    Restart-Service -Name $serviceName -Force
    $message = "Le service $serviceName a été redémarré avec succès par $env:USERNAME"
    Write-Host $message -ForegroundColor Green
    Write-Log $message
}
catch {
    $message = "Erreur lors du redémarrage du service $serviceName : $_"
    Write-Host $message -ForegroundColor Red
    Write-Log $message
}

Write-Host "Un journal a été créé à : $env:TEMP\script_log.txt" -ForegroundColor Magenta
```

## 📌 Points clés à retenir

- Utilisez une stratégie d'exécution appropriée selon votre environnement.
- N'octroyez des privilèges élevés que lorsque c'est nécessaire.
- Signez vos scripts dans un environnement professionnel.
- Protégez toujours les identifiants et informations sensibles.
- Validez rigoureusement les entrées utilisateur pour éviter les injections.
- Journalisez les actions administratives importantes.

## 📌 Pour aller plus loin

- Explorez le module `JEA` (Just Enough Administration) pour des environnements sécurisés.
- Découvrez les capacités d'audit PowerShell avec le module `PSScriptAnalyzer`.
- Renseignez-vous sur l'enregistrement avancé avec `Start-Transcript` et la journalisation Windows.

---

Dans le prochain module, nous découvrirons comment utiliser PowerShell avec les API Web et les services cloud.
