# 📄 16-2. Modèles de scripts prêts à l'emploi

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

Bienvenue dans cette section consacrée aux modèles de scripts PowerShell prêts à l'emploi !

Ces modèles sont conçus pour vous faire gagner du temps et vous servir de point de départ pour vos propres scripts. Chaque modèle est accompagné d'explications détaillées pour vous aider à comprendre son fonctionnement et à l'adapter à vos besoins.

---

## Modèle 1 : Script de base avec gestion des erreurs

Ce modèle vous offre une structure de base pour créer des scripts robustes avec une gestion des erreurs appropriée.

```powershell
<#
.SYNOPSIS
    Description courte du script
.DESCRIPTION
    Description détaillée du script
.PARAMETER NomParametre
    Description du paramètre
.EXAMPLE
    .\MonScript.ps1 -NomParametre "Valeur"
.NOTES
    Auteur : Votre nom
    Date de création : JJ/MM/AAAA
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Saisissez une valeur pour ce paramètre")]
    [string]$NomParametre
)

# Définition des variables globales
$ErrorActionPreference = "Stop"  # Arrête le script en cas d'erreur
$logFile = ".\logs\$(Get-Date -Format 'yyyy-MM-dd').log"

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    # Crée le dossier des logs s'il n'existe pas
    if (-not (Test-Path ".\logs")) {
        New-Item -Path ".\logs" -ItemType Directory -Force | Out-Null
    }

    $timeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timeStamp] [$Level] $Message"

    # Écrit dans le fichier journal et dans la console
    Add-Content -Path $logFile -Value $logEntry

    # Ajoute une couleur selon le niveau de log
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }
}

# Bloc principal avec gestion des erreurs
try {
    Write-Log "Démarrage du script avec le paramètre: $NomParametre"

    # Votre code principal ici
    Write-Log "Exécution de la tâche principale..."

    # Exemple de code
    Start-Sleep -Seconds 2  # Simule un traitement

    Write-Log "Tâche terminée avec succès" -Level "SUCCESS"
}
catch {
    Write-Log "Une erreur est survenue: $($_.Exception.Message)" -Level "ERROR"
    Write-Log "Ligne d'erreur: $($_.InvocationInfo.ScriptLineNumber)" -Level "ERROR"
    exit 1  # Quitte avec un code d'erreur
}
finally {
    # Code qui s'exécute toujours, même en cas d'erreur
    Write-Log "Fin du script"
}
```

### Comment utiliser ce modèle :

1. Copiez le code ci-dessus dans un fichier `.ps1`
2. Remplacez les commentaires et les variables par vos propres valeurs
3. Ajoutez votre code dans le bloc `try`
4. Exécutez le script avec un paramètre : `.\MonScript.ps1 -NomParametre "Valeur"`

Ce modèle crée automatiquement un dossier `logs` et y stocke les journaux d'exécution avec horodatage.

---

## Modèle 2 : Script de traitement de fichiers CSV

Ce modèle vous permet de traiter facilement des fichiers CSV, une tâche courante en administration système.

```powershell
<#
.SYNOPSIS
    Traitement de fichiers CSV
.DESCRIPTION
    Ce script lit un fichier CSV, effectue des opérations sur les données et exporte le résultat
.PARAMETER CheminFichierEntree
    Chemin vers le fichier CSV d'entrée
.PARAMETER CheminFichierSortie
    Chemin vers le fichier CSV de sortie
.EXAMPLE
    .\TraitementCSV.ps1 -CheminFichierEntree "C:\Data\entree.csv" -CheminFichierSortie "C:\Data\sortie.csv"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CheminFichierEntree,

    [Parameter(Mandatory = $true)]
    [string]$CheminFichierSortie
)

# Vérifier si le fichier d'entrée existe
if (-not (Test-Path -Path $CheminFichierEntree)) {
    Write-Error "Le fichier d'entrée n'existe pas: $CheminFichierEntree"
    exit 1
}

try {
    # Lire le fichier CSV
    Write-Host "Lecture du fichier CSV: $CheminFichierEntree" -ForegroundColor Cyan
    $donnees = Import-Csv -Path $CheminFichierEntree -Delimiter ";" -Encoding UTF8

    Write-Host "Nombre d'enregistrements trouvés: $($donnees.Count)" -ForegroundColor Green

    # Exemple de traitement: Ajouter une nouvelle colonne avec la date du jour
    $donneesModifiees = $donnees | ForEach-Object {
        $_ | Add-Member -NotePropertyName "DateTraitement" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd") -PassThru

        # Vous pouvez aussi modifier des valeurs existantes
        # $_."NomColonne" = "Nouvelle valeur"

        # Retourner l'objet modifié
        $_
    }

    # Exporter les données modifiées
    Write-Host "Exportation des données vers: $CheminFichierSortie" -ForegroundColor Cyan
    $donneesModifiees | Export-Csv -Path $CheminFichierSortie -Delimiter ";" -Encoding UTF8 -NoTypeInformation

    Write-Host "Traitement terminé avec succès!" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors du traitement: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
```

### Comment utiliser ce modèle :

1. Copiez ce code dans un fichier `.ps1`
2. Exécutez-le en fournissant les chemins des fichiers d'entrée et de sortie
3. Personnalisez le traitement dans le bloc `ForEach-Object` selon vos besoins

Ce modèle lit un fichier CSV, ajoute une colonne avec la date du jour, et enregistre le résultat dans un nouveau fichier.

---

## Modèle 3 : Script d'automatisation de tâches Windows

Ce modèle vous permet d'automatiser des tâches d'administration Windows courantes.

```powershell
<#
.SYNOPSIS
    Automatisation de tâches Windows
.DESCRIPTION
    Ce script effectue plusieurs tâches d'administration Windows : vérification des services,
    nettoyage de disque et rapport d'état
.PARAMETER Services
    Tableau des services à vérifier
.PARAMETER CheminRapport
    Chemin où enregistrer le rapport
.EXAMPLE
    .\TachesWindows.ps1 -Services @("wuauserv", "spooler") -CheminRapport "C:\Rapports"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string[]]$Services = @("wuauserv", "spooler", "WinRM"),

    [Parameter(Mandatory = $false)]
    [string]$CheminRapport = "$env:USERPROFILE\Desktop\RapportSysteme"
)

# Création du dossier de rapport s'il n'existe pas
if (-not (Test-Path -Path $CheminRapport)) {
    New-Item -Path $CheminRapport -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de rapport créé: $CheminRapport" -ForegroundColor Green
}

# Nom du fichier de rapport avec date et heure
$nomFichierRapport = "Rapport_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
$cheminFichierRapport = Join-Path -Path $CheminRapport -ChildPath $nomFichierRapport

# Fonction pour vérifier l'état des services
function Test-Services {
    param (
        [string[]]$ServiceNames
    )

    $resultats = @()

    foreach ($service in $ServiceNames) {
        try {
            $etatService = Get-Service -Name $service -ErrorAction Stop
            $resultats += [PSCustomObject]@{
                Service = $service
                Statut = $etatService.Status
                DemarrageAuto = $etatService.StartType
            }
        }
        catch {
            $resultats += [PSCustomObject]@{
                Service = $service
                Statut = "Non trouvé"
                DemarrageAuto = "N/A"
            }
        }
    }

    return $resultats
}

# Fonction pour obtenir l'espace disque disponible
function Get-EspaceDisque {
    $disques = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    $resultats = @()

    foreach ($disque in $disques) {
        $espaceTotal = [math]::Round($disque.Size / 1GB, 2)
        $espaceLibre = [math]::Round($disque.FreeSpace / 1GB, 2)
        $pourcentageLibre = [math]::Round(($disque.FreeSpace / $disque.Size) * 100, 2)

        $resultats += [PSCustomObject]@{
            Lettre = $disque.DeviceID
            "Espace Total (GB)" = $espaceTotal
            "Espace Libre (GB)" = $espaceLibre
            "% Libre" = $pourcentageLibre
        }
    }

    return $resultats
}

# Fonction pour obtenir des informations système
function Get-InfoSysteme {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $ordinateur = Get-CimInstance -ClassName Win32_ComputerSystem
    $processeur = Get-CimInstance -ClassName Win32_Processor

    return [PSCustomObject]@{
        "Nom Ordinateur" = $env:COMPUTERNAME
        "Système d'exploitation" = $os.Caption
        "Version" = $os.Version
        "Mémoire Totale (GB)" = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
        "Mémoire Libre (GB)" = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
        "Processeur" = $processeur.Name
        "Fabricant" = $ordinateur.Manufacturer
        "Modèle" = $ordinateur.Model
    }
}

# Génération du rapport
try {
    Write-Host "Vérification des services..." -ForegroundColor Cyan
    $rapportServices = Test-Services -ServiceNames $Services

    Write-Host "Analyse de l'espace disque..." -ForegroundColor Cyan
    $rapportDisques = Get-EspaceDisque

    Write-Host "Collecte des informations système..." -ForegroundColor Cyan
    $rapportSysteme = Get-InfoSysteme

    # Création du rapport HTML
    $css = @"
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background-color: #f5f5f5; }
        h1 { color: #003366; border-bottom: 1px solid #003366; padding-bottom: 5px; }
        h2 { color: #0066cc; margin-top: 20px; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th { background-color: #0066cc; color: white; text-align: left; padding: 8px; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .footer { font-size: 0.8em; color: #666; margin-top: 30px; text-align: center; }
    </style>
"@

    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <title>Rapport Système - $(Get-Date -Format 'yyyy-MM-dd')</title>
        $css
    </head>
    <body>
        <h1>Rapport Système - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h1>

        <h2>Informations Système</h2>
        $(($rapportSysteme | ConvertTo-Html -Fragment) -replace "<table>", "<table class='info'>")

        <h2>État des Services</h2>
        $(($rapportServices | ConvertTo-Html -Fragment) -replace "<table>", "<table class='services'>")

        <h2>Espace Disque</h2>
        $(($rapportDisques | ConvertTo-Html -Fragment) -replace "<table>", "<table class='disks'>")

        <div class="footer">
            Rapport généré le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') sur $env:COMPUTERNAME
        </div>
    </body>
    </html>
"@

    # Enregistrement du rapport HTML
    $html | Out-File -FilePath $cheminFichierRapport -Encoding UTF8

    Write-Host "Rapport généré avec succès: $cheminFichierRapport" -ForegroundColor Green

    # Ouvrir le rapport dans le navigateur par défaut
    Invoke-Item $cheminFichierRapport
}
catch {
    Write-Host "Erreur lors de la génération du rapport: $($_.Exception.Message)" -ForegroundColor Red
}
```

### Comment utiliser ce modèle :

1. Copiez ce code dans un fichier `.ps1`
2. Exécutez-le avec les paramètres par défaut ou personnalisés
3. Le script générera un rapport HTML et l'ouvrira automatiquement dans votre navigateur

Ce modèle vérifie l'état des services Windows, analyse l'espace disque et collecte des informations système pour créer un rapport complet.

---

## Modèle 4 : Script d'interaction avec une API REST

Ce modèle vous permet d'interagir facilement avec des API REST en utilisant PowerShell.

```powershell
<#
.SYNOPSIS
    Exemple d'interaction avec une API REST
.DESCRIPTION
    Ce script montre comment effectuer des requêtes GET et POST vers une API REST
    et traiter les réponses JSON
.PARAMETER UrlApi
    URL de base de l'API
.EXAMPLE
    .\AppelAPI.ps1 -UrlApi "https://jsonplaceholder.typicode.com"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$UrlApi = "https://jsonplaceholder.typicode.com"
)

# Configuration de la sécurité pour les connexions HTTPS
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Fonction pour effectuer une requête GET
function Invoke-GetRequest {
    param (
        [string]$Url,
        [hashtable]$Headers = @{}
    )

    try {
        Write-Host "Envoi d'une requête GET à: $Url" -ForegroundColor Cyan

        $response = Invoke-RestMethod -Uri $Url -Method Get -Headers $Headers -ContentType "application/json"
        return $response
    }
    catch {
        Write-Host "Erreur lors de la requête GET: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Fonction pour effectuer une requête POST
function Invoke-PostRequest {
    param (
        [string]$Url,
        [object]$Body,
        [hashtable]$Headers = @{}
    )

    try {
        Write-Host "Envoi d'une requête POST à: $Url" -ForegroundColor Cyan

        # Conversion de l'objet en JSON
        $jsonBody = $Body | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $Url -Method Post -Body $jsonBody -Headers $Headers -ContentType "application/json"
        return $response
    }
    catch {
        Write-Host "Erreur lors de la requête POST: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Exemple d'utilisation des fonctions
try {
    # Configuration des en-têtes HTTP (ajoutez des tokens d'authentification si nécessaire)
    $headers = @{
        "Accept" = "application/json"
        # "Authorization" = "Bearer votre_token_ici"
    }

    # Exemple 1: Requête GET pour obtenir des posts
    $endpointPosts = "$UrlApi/posts"
    Write-Host "Récupération des posts..." -ForegroundColor Yellow
    $posts = Invoke-GetRequest -Url $endpointPosts -Headers $headers

    if ($posts) {
        Write-Host "Nombre de posts récupérés: $($posts.Count)" -ForegroundColor Green

        # Affichage des 3 premiers posts
        Write-Host "Trois premiers posts:" -ForegroundColor Yellow
        $posts | Select-Object -First 3 | Format-Table -Property userId, id, title
    }

    # Exemple 2: Requête GET pour obtenir un post spécifique
    $postId = 1
    $endpointPost = "$UrlApi/posts/$postId"
    Write-Host "Récupération du post #$postId..." -ForegroundColor Yellow
    $post = Invoke-GetRequest -Url $endpointPost -Headers $headers

    if ($post) {
        Write-Host "Détails du post #$postId:" -ForegroundColor Green
        $post | Format-List
    }

    # Exemple 3: Requête POST pour créer un nouveau post
    $nouveauPost = @{
        title = "Nouveau post PowerShell"
        body = "Contenu du post créé via PowerShell"
        userId = 1
    }

    Write-Host "Création d'un nouveau post..." -ForegroundColor Yellow
    $resultatCreation = Invoke-PostRequest -Url $endpointPosts -Body $nouveauPost -Headers $headers

    if ($resultatCreation) {
        Write-Host "Post créé avec succès!" -ForegroundColor Green
        $resultatCreation | Format-List
    }

    Write-Host "Toutes les opérations API terminées" -ForegroundColor Green
}
catch {
    Write-Host "Erreur générale: $($_.Exception.Message)" -ForegroundColor Red
}
```

### Comment utiliser ce modèle :

1. Copiez ce code dans un fichier `.ps1`
2. Exécutez-le avec l'URL de l'API de votre choix
3. Le script effectuera des requêtes GET et POST vers l'API et affichera les résultats

Ce modèle utilise l'API publique JSONPlaceholder pour démontrer les appels d'API, mais vous pouvez facilement l'adapter à n'importe quelle API REST.

---

## Modèle 5 : Script de reporting par email

Ce modèle vous permet de créer et d'envoyer des rapports par email automatiquement.

```powershell
<#
.SYNOPSIS
    Génération et envoi de rapport par email
.DESCRIPTION
    Ce script génère un rapport et l'envoie par email
.PARAMETER Destinataires
    Liste des adresses email destinataires
.PARAMETER ServeurSMTP
    Adresse du serveur SMTP
.EXAMPLE
    .\EnvoiRapport.ps1 -Destinataires "user@example.com" -ServeurSMTP "smtp.example.com"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string[]]$Destinataires,

    [Parameter(Mandatory = $true)]
    [string]$ServeurSMTP,

    [Parameter(Mandatory = $false)]
    [int]$PortSMTP = 25,

    [Parameter(Mandatory = $false)]
    [switch]$UtiliserSSL = $false,

    [Parameter(Mandatory = $false)]
    [string]$Expediteur = "$env:COMPUTERNAME@$env:USERDNSDOMAIN",

    [Parameter(Mandatory = $false)]
    [string]$Sujet = "Rapport automatique - $(Get-Date -Format 'yyyy-MM-dd')",

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential
)

# Fonction pour générer le contenu du rapport
function Get-RapportHTML {
    # Récupération des données pour le rapport
    $infoSysteme = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object CSName, Caption, Version, LastBootUpTime
    $espaceDisque = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
                   Select-Object DeviceID,
                   @{Name='TailleGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
                   @{Name='EspaceLibreGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                   @{Name='PourcentageLibre';Expression={[math]::Round(($_.FreeSpace / $_.Size) * 100, 2)}}

    # Génération du code HTML
    $html = @"
    <!DOCTYPE html>
    <html>
    <head>
        <style>
            body { font-family: Arial, sans-serif; }
            table { border-collapse: collapse; width: 100%; }
            th, td { text-align: left; padding: 8px; border: 1px solid #ddd; }
            th { background-color: #4CAF50; color: white; }
            tr:nth-child(even) { background-color: #f2f2f2; }
            .warning { color: orange; }
            .critical { color: red; }
            .ok { color: green; }
        </style>
    </head>
    <body>
        <h1>Rapport Système du $(Get-Date -Format 'dd/MM/yyyy')</h1>

        <h2>Informations Système</h2>
        <table>
            <tr>
                <th>Nom de l'ordinateur</th>
                <td>$($infoSysteme.CSName)</td>
            </tr>
            <tr>
                <th>Système d'exploitation</th>
                <td>$($infoSysteme.Caption)</td>
            </tr>
            <tr>
                <th>Version</th>
                <td>$($infoSysteme.Version)</td>
            </tr>
            <tr>
                <th>Dernier démarrage</th>
                <td>$($infoSysteme.LastBootUpTime)</td>
            </tr>
        </table>

        <h2>Espace Disque</h2>
        <table>
            <tr>
                <th>Lecteur</th>
                <th>Taille (GB)</th>
                <th>Espace Libre (GB)</th>
                <th>% Libre</th>
                <th>État</th>
            </tr>
"@

    # Ajout des informations de disque
    foreach ($disque in $espaceDisque) {
        $classe = "ok"
        if ($disque.PourcentageLibre -lt 15) {
            $classe = "critical"
        } elseif ($disque.PourcentageLibre -lt 25) {
            $classe = "warning"
        }

        $html += @"
            <tr>
                <td>$($disque.DeviceID)</td>
                <td>$($disque.TailleGB)</td>
                <td>$($disque.EspaceLibreGB)</td>
                <td class="$classe">$($disque.PourcentageLibre)%</td>
                <td class="$classe">$(if($classe -eq 'ok'){"Normal"} elseif($classe -eq 'warning'){"Attention"} else{"Critique"})</td>
            </tr>
"@
    }

    $html += @"
        </table>

        <p>Ce rapport a été généré automatiquement le $(Get-Date -Format 'dd/MM/yyyy à HH:mm') depuis $env:COMPUTERNAME.</p>
    </body>
    </html>
"@

    return $html
}

# Tentative d'envoi du rapport par email
try {
    Write-Host "Génération du rapport..." -ForegroundColor Cyan
    $contenuHtml = Get-RapportHTML

    # Configuration des paramètres d'envoi d'email
    $emailParams = @{
        SmtpServer = $ServeurSMTP
        Port = $PortSMTP
        From = $Expediteur
        To = $Destinataires
        Subject = $Sujet
        Body = $contenuHtml
        BodyAsHtml = $true
        UseSsl = $UtiliserSSL
    }

    # Ajout des identifiants si fournis
    if ($Credential) {
        $emailParams.Add("Credential", $Credential)
    }

    Write-Host "Envoi de l'email à $($Destinataires -join ', ')..." -ForegroundColor Cyan
    Send-MailMessage @emailParams

    Write-Host "Rapport envoyé avec succès!" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'envoi du rapport: $($_.Exception.Message)" -ForegroundColor Red

    # Enregistrement du rapport en local en cas d'échec d'envoi
    $cheminSauvegarde = Join-Path -Path $env:TEMP -ChildPath "Rapport_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    $contenuHtml | Out-File -FilePath $cheminSauvegarde -Encoding UTF8

    Write-Host "Le rapport a été sauvegardé localement à: $cheminSauvegarde" -ForegroundColor Yellow
}
```

### Comment utiliser ce modèle :

1. Copiez ce code dans un fichier `.ps1`
2. Exécutez-le en fournissant les paramètres requis :
   ```powershell
   .\EnvoiRapport.ps1 -Destinataires "utilisateur@example.com" -ServeurSMTP "smtp.example.com"
   ```
3. Pour utiliser l'authentification, ajoutez vos identifiants :
   ```powershell
   $cred = Get-Credential
   .\EnvoiRapport.ps1 -Destinataires "utilisateur@example.com" -ServeurSMTP "smtp.example.com" -Credential $cred -UtiliserSSL
   ```

Ce modèle génère un rapport HTML avec des informations système et l'envoie par email. En cas d'échec, il sauvegarde le rapport localement.

---

## Conseils pour utiliser ces modèles

1. **Sauvegardez les modèles** dans un dossier dédié pour pouvoir les réutiliser facilement.

2. **Personnalisez-les** en fonction de vos besoins spécifiques. Ces modèles sont conçus comme des points de départ.

3. **Commentez votre code** pour vous souvenir de ce que font les différentes parties, surtout après personnalisation.

4. **Utilisez l'aide intégrée** (`Get-Help .\MonScript.ps1`) pour obtenir des informations sur l'utilisation de chaque script.

5. **Testez dans un environnement sûr** avant de déployer en production.

---

## Pour aller plus loin

Vous pouvez combiner ces modèles ou en créer de nouveaux pour répondre à vos besoins spécifiques. N'hésitez pas à explorer le reste de cette formation pour approfondir vos connaissances en PowerShell et améliorer vos compétences en scripting.

PowerShell est un outil puissant pour l'automatisation des tâches administratives, et ces modèles vous donnent une base solide pour commencer à développer vos propres solutions.

---

## 📚 Ressources supplémentaires

- [Microsoft PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [PowerShell Gallery](https://www.powershellgallery.com/) - Pour découvrir et télécharger des modules supplémentaires
- [GitHub PowerShell Community](https://github.com/PowerShell/PowerShell) - Pour les dernières versions et discussions

---

🔄 **N'oubliez pas** : La pratique est la clé pour maîtriser PowerShell ! Essayez de modifier ces modèles et de les adapter à vos propres besoins.
