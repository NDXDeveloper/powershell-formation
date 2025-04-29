# --------------------------------------------------
# Solution 1: Script de vérification des privilèges administrateur
# Fichier: ExercicePrivileges.ps1
# --------------------------------------------------

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

<#
.SYNOPSIS
    Script qui vérifie les privilèges administrateur, relance avec élévation si nécessaire,
    et effectue une opération administrative.

.DESCRIPTION
    Ce script vérifie s'il s'exécute avec des privilèges administrateur.
    S'il ne possède pas les privilèges nécessaires, il se relance automatiquement en mode administrateur.
    Il effectue ensuite une opération administrative (redémarrage d'un service) et journalise l'action.

.NOTES
    Auteur: Formation PowerShell
    Date de création: 27/04/2025
#>

function Test-Admin {
    <#
    .SYNOPSIS
        Vérifie si le script s'exécute avec des privilèges administrateur
    .OUTPUTS
        [bool] Retourne $true si l'utilisateur actuel a des privilèges administrateur, $false sinon
    #>
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Write-Log {
    <#
    .SYNOPSIS
        Journalise un message dans un fichier log
    .PARAMETER Message
        Le message à journaliser
    .PARAMETER LogFile
        Chemin vers le fichier log (optionnel)
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$LogFile = "$env:TEMP\script_security_log.txt"
    )

    # Création du dossier de log si nécessaire
    $logFolder = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $logFolder)) {
        New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append
}

# Début du script principal
Write-Host "=== Script de gestion de service avec privilèges ===" -ForegroundColor Cyan

# Vérifier les privilèges administrateur
if (-not (Test-Admin)) {
    $message = "Privilèges insuffisants. Redémarrage en mode administrateur..."
    Write-Host $message -ForegroundColor Yellow
    Write-Log $message

    # Relance le script avec élévation des privilèges
    Start-Process PowerShell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# À ce stade, nous avons des privilèges administrateur
$message = "Script exécuté avec privilèges administrateur par $env:USERNAME"
Write-Host $message -ForegroundColor Green
Write-Log $message

# Définir le service à redémarrer
$serviceName = "Spooler"  # Service d'impression Windows

Write-Host "Tentative de redémarrage du service $serviceName..." -ForegroundColor Cyan

try {
    # Récupérer l'état actuel du service
    $serviceStatus = Get-Service -Name $serviceName
    $initialState = $serviceStatus.Status

    $message = "État initial du service $serviceName : $initialState"
    Write-Host $message -ForegroundColor Blue
    Write-Log $message

    # Redémarrer le service
    Restart-Service -Name $serviceName -Force

    # Vérifier le nouvel état
    Start-Sleep -Seconds 2  # Attendre que le service ait le temps de redémarrer
    $newStatus = (Get-Service -Name $serviceName).Status

    $message = "Le service $serviceName a été redémarré avec succès (État: $newStatus)"
    Write-Host $message -ForegroundColor Green
    Write-Log $message
}
catch {
    $errorDetails = $_.Exception.Message
    $message = "Erreur lors du redémarrage du service $serviceName : $errorDetails"
    Write-Host $message -ForegroundColor Red
    Write-Log "ERREUR - $message"
}

Write-Host "Un journal a été créé à : $env:TEMP\script_security_log.txt" -ForegroundColor Magenta
Write-Host "=== Fin de l'exécution du script ===" -ForegroundColor Cyan


# --------------------------------------------------
# Solution 2: Script de gestion sécurisée des identifiants
# Fichier: GestionIdentifiants.ps1
# --------------------------------------------------

<#
.SYNOPSIS
    Script démontrant la gestion sécurisée des identifiants dans PowerShell

.DESCRIPTION
    Ce script montre comment stocker et récupérer des identifiants de manière sécurisée,
    puis les utiliser pour exécuter des commandes à distance sur un serveur.

.NOTES
    Auteur: Formation PowerShell
    Date de création: 27/04/2025
#>

# Définir le chemin du fichier d'identifiants
$credentialFilePath = "$env:USERPROFILE\Documents\SecureCredentials.xml"

function New-SecureCredentials {
    <#
    .SYNOPSIS
        Crée et stocke des identifiants de manière sécurisée
    .PARAMETER Path
        Chemin où stocker le fichier d'identifiants
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # Demander les identifiants à l'utilisateur via une boîte de dialogue
    $credential = Get-Credential -Message "Entrez les identifiants à stocker de manière sécurisée"

    # Vérifier que l'utilisateur a entré des identifiants
    if ($null -eq $credential) {
        Write-Warning "Aucun identifiant n'a été fourni. Opération annulée."
        return $false
    }

    # Créer le dossier parent si nécessaire
    $folder = Split-Path -Path $Path -Parent
    if (-not (Test-Path -Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
    }

    try {
        # Exporter les identifiants vers le fichier (chiffrés avec la clé de l'utilisateur actuel)
        $credential | Export-Clixml -Path $Path -Force
        Write-Host "Identifiants stockés avec succès dans $Path" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Impossible de stocker les identifiants: $_"
        return $false
    }
}

function Get-SecureCredentials {
    <#
    .SYNOPSIS
        Récupère des identifiants stockés de manière sécurisée
    .PARAMETER Path
        Chemin du fichier d'identifiants
    .OUTPUTS
        [PSCredential] Objet contenant les identifiants
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier d'identifiants n'existe pas à l'emplacement spécifié: $Path"
        return $null
    }

    try {
        # Importer les identifiants depuis le fichier
        $credential = Import-Clixml -Path $Path
        return $credential
    }
    catch {
        Write-Error "Impossible de récupérer les identifiants: $_"
        return $null
    }
}

function Test-RemoteConnection {
    <#
    .SYNOPSIS
        Teste une connexion à distance avec les identifiants fournis
    .PARAMETER ComputerName
        Nom de l'ordinateur distant
    .PARAMETER Credential
        Identifiants à utiliser pour la connexion
    .OUTPUTS
        [bool] Retourne $true si la connexion a réussi, $false sinon
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]$Credential
    )

    try {
        # Tester la connexion en récupérant la date du système distant
        $result = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            return @{
                ComputerName = $env:COMPUTERNAME
                Date = Get-Date
                User = [Security.Principal.WindowsIdentity]::GetCurrent().Name
            }
        } -ErrorAction Stop

        # Afficher les informations sur la connexion réussie
        Write-Host "Connexion réussie à $ComputerName" -ForegroundColor Green
        Write-Host "  Nom de l'ordinateur distant: $($result.ComputerName)" -ForegroundColor Cyan
        Write-Host "  Date sur l'ordinateur distant: $($result.Date)" -ForegroundColor Cyan
        Write-Host "  Utilisateur connecté: $($result.User)" -ForegroundColor Cyan

        return $true
    }
    catch {
        Write-Host "Échec de la connexion à $ComputerName : $_" -ForegroundColor Red
        return $false
    }
}

# Script principal
Write-Host "=== Gestion sécurisée des identifiants ===" -ForegroundColor Cyan

# Menu des options
do {
    Write-Host "`nOptions disponibles:" -ForegroundColor Yellow
    Write-Host "1. Créer et stocker des identifiants sécurisés" -ForegroundColor White
    Write-Host "2. Tester une connexion à distance avec les identifiants stockés" -ForegroundColor White
    Write-Host "3. Quitter" -ForegroundColor White

    $choice = Read-Host "`nEntrez votre choix (1-3)"

    switch ($choice) {
        "1" {
            New-SecureCredentials -Path $credentialFilePath
        }
        "2" {
            if (Test-Path -Path $credentialFilePath) {
                $credentials = Get-SecureCredentials -Path $credentialFilePath
                if ($null -ne $credentials) {
                    $remoteComputer = Read-Host "Entrez le nom ou l'adresse IP de l'ordinateur distant"
                    Test-RemoteConnection -ComputerName $remoteComputer -Credential $credentials
                }
            }
            else {
                Write-Warning "Aucun identifiant stocké. Veuillez d'abord créer des identifiants (option 1)."
            }
        }
        "3" {
            Write-Host "Fin du programme" -ForegroundColor Cyan
        }
        default {
            Write-Warning "Option non valide. Veuillez entrer un chiffre entre 1 et 3."
        }
    }
} while ($choice -ne "3")


# --------------------------------------------------
# Solution 3: Script de vérification de signature de code
# Fichier: VerificationSignature.ps1
# --------------------------------------------------

<#
.SYNOPSIS
    Script pour vérifier et créer des signatures de code pour les scripts PowerShell

.DESCRIPTION
    Ce script permet de vérifier si un script est signé et, si nécessaire,
    de créer un certificat auto-signé pour signer des scripts.

.NOTES
    Auteur: Formation PowerShell
    Date de création: 27/04/2025
#>

function Test-ScriptSignature {
    <#
    .SYNOPSIS
        Vérifie la signature d'un script PowerShell
    .PARAMETER FilePath
        Chemin vers le script à vérifier
    .OUTPUTS
        [PSObject] Informations sur la signature du script
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Vérifier l'extension du fichier
    if (-not ($FilePath -match '\.ps1$|\.psm1$|\.psd1$')) {
        Write-Warning "Le fichier ne semble pas être un script PowerShell (.ps1, .psm1 ou .psd1)"
    }

    try {
        # Obtenir les informations de signature
        $signature = Get-AuthenticodeSignature -FilePath $FilePath

        # Afficher les informations
        Write-Host "`nInformations sur la signature du script: $FilePath" -ForegroundColor Cyan
        Write-Host "  Statut: $($signature.Status)" -ForegroundColor Yellow

        # Analyser le statut de la signature
        switch ($signature.Status) {
            "Valid" {
                Write-Host "  Le script est correctement signé" -ForegroundColor Green
                Write-Host "  Signé par: $($signature.SignerCertificate.Subject)" -ForegroundColor Green
                Write-Host "  Émetteur: $($signature.SignerCertificate.Issuer)" -ForegroundColor Green
                Write-Host "  Valide du: $($signature.SignerCertificate.NotBefore) au $($signature.SignerCertificate.NotAfter)" -ForegroundColor Green
            }
            "UnknownError" {
                Write-Host "  Erreur inconnue lors de la vérification de la signature" -ForegroundColor Red
            }
            "NotSigned" {
                Write-Host "  Le script n'est pas signé" -ForegroundColor Red
            }
            "HashMismatch" {
                Write-Host "  Le contenu du script a été modifié après la signature" -ForegroundColor Red
            }
            "NotTrusted" {
                Write-Host "  Le certificat utilisé pour signer le script n'est pas approuvé" -ForegroundColor Red
            }
            "NotSupportedFileFormat" {
                Write-Host "  Le format du fichier n'est pas pris en charge pour la signature" -ForegroundColor Red
            }
            default {
                Write-Host "  Statut inconnu" -ForegroundColor Red
            }
        }

        return $signature
    }
    catch {
        Write-Error "Erreur lors de la vérification de la signature: $_"
        return $null
    }
}

function New-CodeSigningCertificate {
    <#
    .SYNOPSIS
        Crée un nouveau certificat auto-signé pour la signature de code
    .PARAMETER Subject
        Sujet du certificat
    .PARAMETER ValidityDays
        Durée de validité du certificat en jours
    .OUTPUTS
        [System.Security.Cryptography.X509Certificates.X509Certificate2] Le certificat créé
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$Subject = "CN=PowerShell Code Signing $(Get-Date -Format 'yyyy-MM-dd')",

        [Parameter(Mandatory = $false)]
        [int]$ValidityDays = 365
    )

    try {
        # Créer un certificat auto-signé
        $cert = New-SelfSignedCertificate -Subject $Subject -Type CodeSigning -CertStoreLocation Cert:\CurrentUser\My -NotAfter (Get-Date).AddDays($ValidityDays)

        Write-Host "Certificat créé avec succès:" -ForegroundColor Green
        Write-Host "  Sujet: $($cert.Subject)" -ForegroundColor Cyan
        Write-Host "  Empreinte: $($cert.Thumbprint)" -ForegroundColor Cyan
        Write-Host "  Valide jusqu'au: $($cert.NotAfter)" -ForegroundColor Cyan
        Write-Host "  Stocké dans: Cert:\CurrentUser\My\$($cert.Thumbprint)" -ForegroundColor Cyan

        # Avertissement sur l'utilisation de certificats auto-signés
        Write-Host "`nATTENTION:" -ForegroundColor Yellow
        Write-Host "  Ce certificat est auto-signé et ne sera pas automatiquement approuvé." -ForegroundColor Yellow
        Write-Host "  Pour l'utiliser en production, envisagez d'obtenir un certificat auprès d'une autorité de certification reconnue." -ForegroundColor Yellow

        return $cert
    }
    catch {
        Write-Error "Erreur lors de la création du certificat: $_"
        return $null
    }
}

function Set-ScriptSignature {
    <#
    .SYNOPSIS
        Signe un script PowerShell avec un certificat
    .PARAMETER FilePath
        Chemin vers le script à signer
    .PARAMETER Certificate
        Certificat à utiliser pour la signature
    .OUTPUTS
        [bool] $true si la signature a réussi, $false sinon
    #>
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "Le fichier n'existe pas: $FilePath"
        return $false
    }

    try {
        # Signer le script
        $signResult = Set-AuthenticodeSignature -FilePath $FilePath -Certificate $Certificate

        # Vérifier le résultat
        if ($signResult.Status -eq "Valid") {
            Write-Host "Script signé avec succès: $FilePath" -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning "La signature du script n'est pas valide. Statut: $($signResult.Status)"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors de la signature du script: $_"
        return $false
    }
}

# Script principal
Write-Host "=== Vérification et signature de scripts PowerShell ===" -ForegroundColor Cyan

# Menu des options
do {
    Write-Host "`nOptions disponibles:" -ForegroundColor Yellow
    Write-Host "1. Vérifier la signature d'un script" -ForegroundColor White
    Write-Host "2. Créer un certificat auto-signé pour la signature de code" -ForegroundColor White
    Write-Host "3. Signer un script avec un certificat" -ForegroundColor White
    Write-Host "4. Quitter" -ForegroundColor White

    $choice = Read-Host "`nEntrez votre choix (1-4)"

    switch ($choice) {
        "1" {
            $scriptPath = Read-Host "Entrez le chemin complet vers le script à vérifier"
            Test-ScriptSignature -FilePath $scriptPath
        }
        "2" {
            $customSubject = Read-Host "Entrez le sujet du certificat (laissez vide pour la valeur par défaut)"
            $validityDays = Read-Host "Entrez la durée de validité en jours (laissez vide pour 365 jours)"

            # Appliquer les valeurs par défaut si nécessaire
            if ([string]::IsNullOrWhiteSpace($customSubject)) {
                $customSubject = "CN=PowerShell Code Signing $(Get-Date -Format 'yyyy-MM-dd')"
            }
            if ([string]::IsNullOrWhiteSpace($validityDays) -or -not [int]::TryParse($validityDays, [ref]$null)) {
                $validityDays = 365
            }

            $certificate = New-CodeSigningCertificate -Subject $customSubject -ValidityDays ([int]$validityDays)
            $global:lastCertificate = $certificate  # Stocker pour une utilisation ultérieure
        }
        "3" {
            # Vérifier si un certificat a été créé dans cette session
            if ($null -eq $global:lastCertificate) {
                # Demander à l'utilisateur de sélectionner un certificat
                Write-Host "`nAucun certificat créé dans cette session." -ForegroundColor Yellow
                Write-Host "Récupération des certificats de signature de code disponibles..." -ForegroundColor Cyan

                # Récupérer tous les certificats de signature de code
                $certs = Get-ChildItem -Path Cert:\CurrentUser\My -CodeSigningCert

                if ($certs.Count -eq 0) {
                    Write-Warning "Aucun certificat de signature de code trouvé. Veuillez d'abord créer un certificat (option 2)."
                    continue
                }

                # Afficher les certificats disponibles
                Write-Host "`nCertificats disponibles:" -ForegroundColor Cyan
                for ($i = 0; $i -lt $certs.Count; $i++) {
                    Write-Host "  $($i+1). $($certs[$i].Subject) (expire le $($certs[$i].NotAfter))" -ForegroundColor White
                }

                # Demander à l'utilisateur de choisir un certificat
                $certChoice = Read-Host "`nEntrez le numéro du certificat à utiliser"
                if ([int]::TryParse($certChoice, [ref]$null) -and [int]$certChoice -ge 1 -and [int]$certChoice -le $certs.Count) {
                    $selectedCert = $certs[[int]$certChoice - 1]
                }
                else {
                    Write-Warning "Choix invalide."
                    continue
                }
            }
            else {
                $selectedCert = $global:lastCertificate
            }

            # Demander le chemin du script à signer
            $scriptPath = Read-Host "Entrez le chemin complet vers le script à signer"

            # Signer le script
            Set-ScriptSignature -FilePath $scriptPath -Certificate $selectedCert
        }
        "4" {
            Write-Host "Fin du programme" -ForegroundColor Cyan
        }
        default {
            Write-Warning "Option non valide. Veuillez entrer un chiffre entre 1 et 4."
        }
    }
} while ($choice -ne "4")
