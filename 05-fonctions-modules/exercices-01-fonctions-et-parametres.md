### Solutions des exercices pratiques

#### 1. Exercice de base : Convertir-CelsiusEnFahrenheit

```powershell
function Convertir-CelsiusEnFahrenheit {
    param(
        [Parameter(Mandatory=$true)]
        [float]$TemperatureCelsius
    )

    # Formule de conversion : °F = (°C × 9/5) + 32
    $TemperatureFahrenheit = ($TemperatureCelsius * 9/5) + 32

    # Arrondir à 2 décimales pour plus de lisibilité
    $TemperatureFahrenheit = [Math]::Round($TemperatureFahrenheit, 2)

    Write-Output "$TemperatureCelsius°C équivaut à $TemperatureFahrenheit°F"

    # Retourner la valeur pour utilisation potentielle dans d'autres calculs
    return $TemperatureFahrenheit
}

# Exemples d'utilisation
Convertir-CelsiusEnFahrenheit -TemperatureCelsius 0
# Résultat: 0°C équivaut à 32°F

Convertir-CelsiusEnFahrenheit -TemperatureCelsius 25
# Résultat: 25°C équivaut à 77°F

Convertir-CelsiusEnFahrenheit -TemperatureCelsius 100
# Résultat: 100°C équivaut à 212°F
```

#### 2. Exercice intermédiaire : Get-FileInfo

```powershell
function Get-FileInfo {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("FullName", "Path")]
        [string]$FilePath
    )

    process {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
            Write-Error "Le fichier '$FilePath' n'existe pas ou n'est pas un fichier."
            return
        }

        # Récupérer les informations du fichier
        $File = Get-Item -Path $FilePath

        # Calculer la taille en format lisible
        $SizeInBytes = $File.Length
        $SizeFormatted = switch ($SizeInBytes) {
            {$_ -lt 1KB} { "$SizeInBytes octets" }
            {$_ -lt 1MB} { "{0:N2} KB" -f ($SizeInBytes / 1KB) }
            {$_ -lt 1GB} { "{0:N2} MB" -f ($SizeInBytes / 1MB) }
            default { "{0:N2} GB" -f ($SizeInBytes / 1GB) }
        }

        # Créer un objet personnalisé avec les informations
        $FileInfo = [PSCustomObject]@{
            Nom = $File.Name
            Extension = $File.Extension
            Taille = $SizeFormatted
            TailleOctets = $SizeInBytes
            DateCreation = $File.CreationTime
            DerniereModification = $File.LastWriteTime
            DernierAcces = $File.LastAccessTime
            AttributsFichier = $File.Attributes
            CheminComplet = $File.FullName
        }

        # Retourner l'objet
        return $FileInfo
    }
}

# Exemples d'utilisation
Get-FileInfo -FilePath "C:\Windows\notepad.exe"

# Via pipeline
Get-ChildItem -Path "C:\Windows\*.exe" -File | Select-Object -First 3 | Get-FileInfo

# Format tableau pour un affichage plus lisible
Get-ChildItem -Path "C:\Windows\*.dll" -File | Select-Object -First 5 | Get-FileInfo | Format-Table -Property Nom, Extension, Taille, DerniereModification
```

#### 3. Exercice avancé : Send-EmailAlert

```powershell
function Send-EmailAlert {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Subject,

        [Parameter(Mandatory=$true)]
        [string]$Body,

        [Parameter(Mandatory=$true)]
        [string[]]$To,

        [Parameter()]
        [string[]]$Cc,

        [Parameter()]
        [string[]]$Bcc,

        [Parameter(Mandatory=$true)]
        [string]$From,

        [Parameter(Mandatory=$true)]
        [string]$SmtpServer,

        [Parameter()]
        [int]$Port = 25,

        [Parameter()]
        [switch]$UseSSL,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter()]
        [string[]]$Attachments,

        [Parameter()]
        [ValidateSet("Normal", "High", "Low")]
        [string]$Priority = "Normal",

        [Parameter()]
        [switch]$HTML
    )

    begin {
        Write-Verbose "Préparation de l'envoi d'un e-mail à : $($To -join ', ')"

        # Créer un objet de message mail
        $EmailParams = @{
            Subject = $Subject
            Body = $Body
            From = $From
            To = $To
            SmtpServer = $SmtpServer
            Port = $Port
        }

        # Ajouter les paramètres optionnels s'ils sont fournis
        if ($Cc) { $EmailParams.Add("Cc", $Cc) }
        if ($Bcc) { $EmailParams.Add("Bcc", $Bcc) }
        if ($UseSSL) { $EmailParams.Add("UseSSL", $true) }
        if ($Credential) { $EmailParams.Add("Credential", $Credential) }
        if ($HTML) { $EmailParams.Add("BodyAsHTML", $true) }

        # Configurer la priorité
        switch ($Priority) {
            "High" { $EmailParams.Add("Priority", "High") }
            "Low" { $EmailParams.Add("Priority", "Low") }
        }
    }

    process {
        try {
            # Ajouter les pièces jointes si elles existent
            if ($Attachments) {
                foreach ($Attachment in $Attachments) {
                    if (Test-Path -Path $Attachment -PathType Leaf) {
                        Write-Verbose "Ajout de la pièce jointe : $Attachment"
                        $EmailParams.Add("Attachments", $Attachment)
                    } else {
                        Write-Warning "La pièce jointe n'existe pas : $Attachment"
                    }
                }
            }

            # Envoyer l'e-mail
            Write-Verbose "Envoi de l'e-mail..."
            Send-MailMessage @EmailParams

            # Retourner un objet de confirmation
            [PSCustomObject]@{
                Statut = "Envoyé"
                Date = Get-Date
                Destinataires = $To
                Sujet = $Subject
                NbPiecesJointes = if ($Attachments) { $Attachments.Count } else { 0 }
            }
        }
        catch {
            Write-Error "Erreur lors de l'envoi de l'e-mail : $_"

            # Retourner un objet d'erreur
            [PSCustomObject]@{
                Statut = "Échec"
                Date = Get-Date
                Destinataires = $To
                Sujet = $Subject
                ErreurMessage = $_.Exception.Message
            }
        }
    }

    end {
        Write-Verbose "Opération d'envoi d'e-mail terminée."
    }
}

# Exemple d'utilisation simple
Send-EmailAlert -Subject "Alerte système" `
                -Body "Le serveur SQL nécessite une intervention" `
                -To "admin@example.com" `
                -From "monitoring@example.com" `
                -SmtpServer "smtp.example.com"

# Exemple d'utilisation avancée avec pièce jointe et HTML
$CredentialsEmail = Get-Credential -Message "Entrez les identifiants SMTP"

Send-EmailAlert -Subject "Rapport hebdomadaire - Serveurs" `
                -Body "<h2>Rapport de performance</h2><p>Veuillez consulter le rapport en pièce jointe.</p>" `
                -To "admin@example.com", "support@example.com" `
                -Cc "manager@example.com" `
                -From "monitoring@example.com" `
                -SmtpServer "smtp.example.com" `
                -Port 587 `
                -UseSSL `
                -Credential $CredentialsEmail `
                -Attachments "C:\Rapports\Rapport_Hebdo.xlsx", "C:\Rapports\Graphiques.pdf" `
                -Priority "High" `
                -HTML `
                -Verbose
```


