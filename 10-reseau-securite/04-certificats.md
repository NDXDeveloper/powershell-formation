# Module 11-4. Gestion des certificats avec PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Introduction

Les certificats numériques jouent un rôle crucial dans la sécurité informatique moderne. Ils permettent d'authentifier l'identité des sites web, de sécuriser les communications et de vérifier l'intégrité des logiciels. PowerShell offre des outils puissants pour gérer ces certificats sur votre système.

## Prérequis
- Connaissances de base de PowerShell
- Compréhension élémentaire de ce qu'est un certificat numérique
- PowerShell 5.1 ou supérieur

## Les magasins de certificats

Dans Windows, les certificats sont stockés dans des "magasins" (certificate stores). Les principaux magasins sont :

- **CurrentUser** : Certificats pour l'utilisateur actuel uniquement
- **LocalMachine** : Certificats pour tous les utilisateurs de l'ordinateur

Chaque magasin contient plusieurs sous-dossiers :
- **My** (ou Personal) : Certificats personnels
- **Root** : Autorités de certification racines approuvées
- **CA** : Autorités de certification intermédiaires
- **TrustedPublisher** : Éditeurs de logiciels approuvés

## Commandes de base pour la gestion des certificats

### 1. Lister les certificats

Pour afficher les certificats dans un magasin spécifique :

```powershell
# Lister tous les certificats de l'utilisateur actuel
Get-ChildItem -Path Cert:\CurrentUser\My

# Lister tous les certificats de la machine locale
Get-ChildItem -Path Cert:\LocalMachine\My
```

💡 **Astuce pour débutant**: Dans PowerShell, `Cert:\` est un lecteur virtuel qui vous permet d'accéder aux certificats comme s'il s'agissait de fichiers dans un système de fichiers.

### 2. Afficher les détails d'un certificat

Pour voir les détails d'un certificat particulier, vous devez d'abord obtenir son empreinte numérique (thumbprint) :

```powershell
# Obtenir un certificat spécifique par son empreinte
$cert = Get-ChildItem -Path Cert:\CurrentUser\My\1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T

# Afficher les détails du certificat
$cert | Format-List *
```

Pour une vue plus lisible :

```powershell
$cert | Select-Object Subject, Issuer, NotBefore, NotAfter, Thumbprint
```

### 3. Filtrer les certificats

Vous pouvez filtrer les certificats selon divers critères :

```powershell
# Trouver les certificats qui expirent dans les 30 prochains jours
$date = (Get-Date).AddDays(30)
Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.NotAfter -le $date }

# Trouver un certificat par son nom
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*example.com*" }
```

### 4. Importer un certificat

Pour importer un certificat à partir d'un fichier :

```powershell
# Importer un certificat .pfx avec mot de passe
$password = ConvertTo-SecureString -String "VotreMotDePasse" -Force -AsPlainText
Import-PfxCertificate -FilePath C:\Certificats\MonCertificat.pfx -CertStoreLocation Cert:\CurrentUser\My -Password $password

# Importer un certificat .cer (sans clé privée)
Import-Certificate -FilePath C:\Certificats\MonCertificat.cer -CertStoreLocation Cert:\CurrentUser\Root
```

⚠️ **Attention** : Soyez prudent avec les mots de passe en clair dans vos scripts. Pour un usage en production, envisagez des méthodes plus sécurisées.

### 5. Exporter un certificat

Pour exporter un certificat vers un fichier :

```powershell
# Exporter un certificat avec sa clé privée (.pfx)
$password = ConvertTo-SecureString -String "NouveauMotDePasse" -Force -AsPlainText
$cert = Get-ChildItem -Path Cert:\CurrentUser\My\1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T
Export-PfxCertificate -Cert $cert -FilePath C:\Certificats\Exported.pfx -Password $password

# Exporter un certificat sans sa clé privée (.cer)
Export-Certificate -Cert $cert -FilePath C:\Certificats\Exported.cer
```

### 6. Supprimer un certificat

Pour supprimer un certificat d'un magasin :

```powershell
# Supprimer un certificat spécifique
$cert = Get-ChildItem -Path Cert:\CurrentUser\My\1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T
Remove-Item -Path $cert.PSPath

# Alternative avec confirmation
Get-ChildItem -Path Cert:\CurrentUser\My\1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T | Remove-Item
```

⚠️ **Attention** : La suppression d'un certificat est irréversible. Assurez-vous de faire une sauvegarde avant toute suppression.

## Cas pratiques

### Vérifier les certificats expirés

Script pour identifier les certificats qui vont bientôt expirer :

```powershell
# Vérifier les certificats qui expirent dans les 60 jours
$dateExpiration = (Get-Date).AddDays(60)
$certificatsExpiration = Get-ChildItem -Path Cert:\LocalMachine\My |
                         Where-Object { $_.NotAfter -le $dateExpiration } |
                         Select-Object Subject, NotAfter, Thumbprint

if ($certificatsExpiration) {
    Write-Host "Certificats qui vont expirer dans les 60 jours :" -ForegroundColor Yellow
    $certificatsExpiration | Format-Table -AutoSize
} else {
    Write-Host "Aucun certificat n'expire dans les 60 prochains jours." -ForegroundColor Green
}
```

### Vérifier la validité d'un certificat pour un site web

```powershell
function Test-CertificateSite {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Hostname,

        [int]$Port = 443
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($Hostname, $Port)

        $sslStream = New-Object System.Net.Security.SslStream(
            $tcpClient.GetStream(),
            $false,
            {param($sender, $certificate, $chain, $errors) return $true}
        )

        $sslStream.AuthenticateAsClient($Hostname)
        $certificate = $sslStream.RemoteCertificate

        $certInfo = [PSCustomObject]@{
            Subject = $certificate.Subject
            Issuer = $certificate.Issuer
            ValidFrom = $certificate.NotBefore
            ValidTo = $certificate.NotAfter
            DaysRemaining = ($certificate.NotAfter - (Get-Date)).Days
            IsValid = (($certificate.NotBefore -le (Get-Date)) -and ($certificate.NotAfter -ge (Get-Date)))
        }

        $sslStream.Close()
        $tcpClient.Close()

        return $certInfo
    }
    catch {
        Write-Host "Erreur lors de la vérification du certificat : $_" -ForegroundColor Red
    }
}

# Exemple d'utilisation
$result = Test-CertificateSite -Hostname "www.microsoft.com"
$result | Format-List
```

## Bonnes pratiques pour la gestion des certificats

1. **Sauvegardez toujours vos certificats importants** avant toute manipulation
2. **Documentez vos certificats** : notez leur usage, date d'expiration, etc.
3. **Évitez de stocker les mots de passe en clair** dans les scripts
4. **Vérifiez régulièrement** les dates d'expiration de vos certificats
5. **Limitez l'accès** aux certificats contenant des clés privées
6. **Utilisez des noms descriptifs** pour faciliter la gestion

## Conclusion

PowerShell offre un ensemble complet d'outils pour gérer efficacement les certificats numériques dans votre environnement Windows. Que ce soit pour lister, importer, exporter ou surveiller vos certificats, ces commandes vous permettent d'automatiser ces tâches de manière simple et efficace.

## Exercices pratiques

1. Listez tous les certificats personnels de votre utilisateur courant
2. Créez un script qui exporte tous les certificats d'un magasin spécifique
3. Écrivez une fonction qui vérifie quotidiennement si des certificats expirent dans les 30 jours

## Resources supplémentaires

- [Documentation officielle Microsoft sur les cmdlets de certificats](https://docs.microsoft.com/fr-fr/powershell/module/pki)
- [Comprendre les certificats X.509](https://docs.microsoft.com/fr-fr/windows/win32/seccertenroll/about-x-509-public-key-certificates)

⏭️ [Sécurité des scripts : droits, exécution, sessions à privilèges](/10-reseau-securite/05-securite-scripts.md)
