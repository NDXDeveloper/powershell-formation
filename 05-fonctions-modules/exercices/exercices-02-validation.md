### Solutions des exercices pratiques

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

#### 1. Exercice de base : Validation d'un numéro de téléphone avec `[ValidatePattern]`

```powershell
function Test-NumeroTelephone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^(\+\d{1,3}\s?)?\(?\d{1,4}\)?[\s.-]?\d{1,4}[\s.-]?\d{1,9}$',
            ErrorMessage = "Le format du numéro de téléphone n'est pas valide. Formats acceptés: +33 1 23 45 67 89, 01.23.45.67.89, (01) 23 45 67 89, etc.")]
        [string]$Numero
    )

    process {
        try {
            # Nettoyer le numéro (enlever les espaces, tirets, parenthèses)
            $NumeroNettoye = $Numero -replace '[^0-9+]', ''

            # Retourner un objet avec le numéro original et nettoyé
            [PSCustomObject]@{
                NumeroOriginal = $Numero
                NumeroNettoye = $NumeroNettoye
                Valide = $true
                NombreChiffres = ($NumeroNettoye -replace '\+', '').Length
            }
        }
        catch {
            Write-Error "Erreur lors du traitement du numéro: $_"
        }
    }
}

# Exemples d'utilisation
Test-NumeroTelephone -Numero "+33 1 23 45 67 89"
Test-NumeroTelephone -Numero "01.23.45.67.89"
Test-NumeroTelephone -Numero "(01) 23 45 67 89"

# Utilisation via pipeline
"06 12 34 56 78", "+44 7911 123456" | Test-NumeroTelephone

# Ces exemples devraient échouer à la validation
try { Test-NumeroTelephone -Numero "pas_un_numero" } catch { Write-Host "Échec attendu: $($_.Exception.Message)" }
try { Test-NumeroTelephone -Numero "123" } catch { Write-Host "Échec attendu: $($_.Exception.Message)" }
```

#### 2. Exercice intermédiaire : Validation d'un chemin de dossier avec droits en écriture

```powershell
function Test-DossierEcriture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateScript({
            # Vérifier si le chemin existe
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw "Le chemin '$_' n'existe pas ou n'est pas un dossier."
            }

            # Vérifier les droits en écriture
            try {
                $testFilePath = Join-Path -Path $_ -ChildPath "test_write_$([Guid]::NewGuid()).tmp"
                $null = New-Item -Path $testFilePath -ItemType File -ErrorAction Stop
                Remove-Item -Path $testFilePath -Force -ErrorAction Stop
                return $true
            }
            catch {
                throw "Le dossier '$_' existe mais vous n'avez pas les droits en écriture: $($_.Exception.Message)"
            }
        }, ErrorMessage = "Erreur de validation du dossier")]
        [string]$CheminDossier
    )

    process {
        try {
            # Obtenir les détails du dossier
            $dossierInfo = Get-Item -Path $CheminDossier

            # Obtenir les informations de sécurité
            $acl = Get-Acl -Path $CheminDossier

            # Retourner un objet avec les informations
            [PSCustomObject]@{
                Chemin = $dossierInfo.FullName
                EstAccessible = $true
                DroitEcriture = $true
                DateCreation = $dossierInfo.CreationTime
                Proprietaire = $acl.Owner
                Taille = Get-ChildItem -Path $CheminDossier -Recurse -File | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
            }

            Write-Host "Le dossier '$CheminDossier' existe et vous avez les droits en écriture." -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors de la vérification du dossier: $_"
        }
    }
}

# Exemples d'utilisation
Test-DossierEcriture -CheminDossier "C:\Temp"
Test-DossierEcriture -CheminDossier $env:USERPROFILE

# Via pipeline
"C:\Windows", "C:\Temp" | Test-DossierEcriture
```

#### 3. Exercice avancé : Validation d'une adresse IP avec `[ValidateScript]`

```powershell
function Test-AdresseIP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateScript({
            # Regex simple pour une IP v4
            $ipv4Regex = '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$'

            # Regex pour IP v6 simplifiée
            $ipv6Regex = '^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::$|^::1$|^([0-9a-fA-F]{1,4}::?){1,7}([0-9a-fA-F]{1,4})?$'

            # Vérifier format général avec regex
            if ($_ -match $ipv4Regex) {
                # Vérifier chaque octet pour IPv4
                $octets = $_ -split '\.'
                foreach ($octet in $octets) {
                    $octetValue = [int]$octet
                    if ($octetValue -lt 0 -or $octetValue -gt 255) {
                        throw "L'adresse IPv4 '$_' n'est pas valide. Chaque octet doit être entre 0 et 255."
                    }
                }
                return $true
            }
            elseif ($_ -match $ipv6Regex) {
                # IPv6 est déjà suffisamment validé par le regex pour notre usage
                return $true
            }
            else {
                throw "L'adresse '$_' n'est pas une adresse IP valide (ni IPv4, ni IPv6)."
            }
        }, ErrorMessage = "L'adresse IP fournie n'est pas valide.")]
        [string]$AdresseIP
    )

    process {
        try {
            # Déterminer le type d'IP
            $typeIP = if ($AdresseIP -match '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$') {
                "IPv4"
            } else {
                "IPv6"
            }

            # Vérifier si l'IP est spéciale
            $estSpeciale = switch -Regex ($AdresseIP) {
                '^127\.' { "Localhost" }
                '^10\.' { "Réseau privé (Classe A)" }
                '^172\.(1[6-9]|2[0-9]|3[0-1])\.' { "Réseau privé (Classe B)" }
                '^192\.168\.' { "Réseau privé (Classe C)" }
                '^169\.254\.' { "APIPA (Auto-configuration)" }
                '^::1$' { "Localhost IPv6" }
                '^[fF][eE]80:' { "Adresse locale de lien IPv6" }
                default { "Standard" }
            }

            # Tenter une résolution DNS inverse si possible
            $nomHote = "Non résolu"
            try {
                $resolution = [System.Net.Dns]::GetHostEntry($AdresseIP)
                if ($resolution -and $resolution.HostName) {
                    $nomHote = $resolution.HostName
                }
            } catch {
                # Ignorer les erreurs de résolution
            }

            # Retourner un objet avec les informations
            [PSCustomObject]@{
                AdresseIP = $AdresseIP
                TypeIP = $typeIP
                Classification = $estSpeciale
                NomHote = $nomHote
                Valide = $true
            }
        }
        catch {
            Write-Error "Erreur lors de l'analyse de l'adresse IP: $_"
        }
    }
}

# Exemples d'utilisation
Test-AdresseIP -AdresseIP "192.168.1.1"
Test-AdresseIP -AdresseIP "127.0.0.1"
Test-AdresseIP -AdresseIP "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
Test-AdresseIP -AdresseIP "::1"

# Via pipeline
"8.8.8.8", "8.8.4.4", "2001:4860:4860::8888" | Test-AdresseIP

# Ces exemples devraient échouer à la validation
try { Test-AdresseIP -AdresseIP "256.256.256.256" } catch { Write-Host "Échec attendu: $($_.Exception.Message)" }
try { Test-AdresseIP -AdresseIP "192.168.1" } catch { Write-Host "Échec attendu: $($_.Exception.Message)" }
try { Test-AdresseIP -AdresseIP "non-ip" } catch { Write-Host "Échec attendu: $($_.Exception.Message)" }
```


