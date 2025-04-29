# Module 7 - Gestion des erreurs en PowerShell

## 7-5. Gestion des exceptions réseau, fichiers, API

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Lorsque vos scripts PowerShell interagissent avec des ressources externes comme les fichiers, les réseaux ou les API web, vous devez vous préparer à gérer différents types d'erreurs spécifiques. Dans cette section, nous allons explorer comment identifier et gérer efficacement ces exceptions pour créer des scripts robustes.

### Pourquoi les exceptions externes sont-elles particulières ?

Les opérations sur les ressources externes sont souvent sujettes à des erreurs pour des raisons indépendantes de votre script :

- 🔌 **Réseau** : Pannes, délais d'attente, problèmes DNS
- 📂 **Fichiers** : Permissions refusées, fichiers verrouillés, espace disque insuffisant
- 🌐 **API** : Services indisponibles, limites de taux dépassées, changements d'API

Un bon script doit anticiper ces problèmes et y répondre correctement !

### Les bases de la gestion des erreurs externes

Commençons par une approche simple pour gérer ces exceptions :

```powershell
try {
    # Tentative d'opération externe
    $contenuFichier = Get-Content -Path "C:\Chemin\vers\fichier.txt" -ErrorAction Stop
} catch {
    # Gestion de l'erreur
    Write-Host "Erreur lors de la lecture du fichier : $($_.Exception.Message)" -ForegroundColor Red
}
```

Le point clé est l'utilisation de `-ErrorAction Stop` qui transforme les erreurs non-terminales en erreurs terminales, permettant au bloc `catch` de les capturer.

### Identifier le type d'exception

Pour gérer différemment chaque type d'erreur, vous devez d'abord identifier le type d'exception :

```powershell
try {
    $contenuFichier = Get-Content -Path "C:\Fichier\inexistant.txt" -ErrorAction Stop
} catch {
    # Afficher le type d'exception
    Write-Host "Type d'erreur : $($_.Exception.GetType().FullName)"
    Write-Host "Message d'erreur : $($_.Exception.Message)"
}
```

### Gestion des exceptions pour les fichiers

Les opérations sur les fichiers peuvent générer plusieurs types d'exceptions. Voici comment les gérer :

```powershell
function Lire-FichierSecurise {
    param(
        [string]$Chemin
    )

    try {
        # Vérifier si le fichier existe avant d'essayer de le lire
        if (-not (Test-Path -Path $Chemin)) {
            throw [System.IO.FileNotFoundException]::new("Le fichier n'existe pas : $Chemin")
        }

        # Tentative de lecture
        $contenu = Get-Content -Path $Chemin -ErrorAction Stop
        return $contenu

    } catch [System.IO.FileNotFoundException] {
        # Gestion spécifique pour fichier non trouvé
        Write-Host "ERREUR : Le fichier n'a pas été trouvé à l'emplacement $Chemin" -ForegroundColor Red
        return $null

    } catch [System.UnauthorizedAccessException] {
        # Gestion spécifique pour problème de permissions
        Write-Host "ERREUR : Vous n'avez pas les permissions nécessaires pour accéder à $Chemin" -ForegroundColor Red
        return $null

    } catch [System.IO.IOException] {
        # Gestion spécifique pour problème d'entrée/sortie
        Write-Host "ERREUR : Problème d'accès au fichier $Chemin. Le fichier est peut-être utilisé par un autre processus." -ForegroundColor Red
        return $null

    } catch {
        # Capture des autres exceptions non prévues
        Write-Host "ERREUR INATTENDUE : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Type : $($_.Exception.GetType().FullName)" -ForegroundColor DarkRed
        return $null
    }
}

# Utilisation de la fonction
$donnees = Lire-FichierSecurise -Chemin "C:\MesDonnees.txt"
if ($donnees) {
    Write-Host "Lecture réussie ! Le fichier contient $($donnees.Count) lignes."
}
```

#### Types d'erreurs courantes avec les fichiers

| Type d'exception | Description | Cause possible |
|------------------|-------------|----------------|
| `System.IO.FileNotFoundException` | Fichier non trouvé | Chemin incorrect ou fichier supprimé |
| `System.UnauthorizedAccessException` | Accès refusé | Permissions insuffisantes |
| `System.IO.IOException` | Erreur d'entrée/sortie | Fichier verrouillé ou utilisé par un autre processus |
| `System.IO.DirectoryNotFoundException` | Répertoire non trouvé | Chemin de dossier incorrect |
| `System.IO.PathTooLongException` | Chemin trop long | Chemin dépassant la limite de caractères |

### Gestion des exceptions pour les opérations réseau

Les exceptions réseau sont particulièrement importantes à gérer, car les problèmes réseau sont fréquents.

```powershell
function Test-ConnexionServeur {
    param(
        [string]$Serveur,
        [int]$Port = 80,
        [int]$Timeout = 5000  # 5 secondes
    )

    try {
        # Créer un client TCP
        $tcpClient = New-Object System.Net.Sockets.TcpClient

        # Tentative de connexion avec timeout
        $connexionAsync = $tcpClient.BeginConnect($Serveur, $Port, $null, $null)
        $attente = $connexionAsync.AsyncWaitHandle.WaitOne($Timeout, $false)

        if (-not $attente) {
            # Délai d'attente dépassé
            $tcpClient.Close()
            Write-Host "ERREUR : Délai d'attente dépassé lors de la connexion à $Serveur:$Port" -ForegroundColor Yellow
            return $false
        }

        # Finaliser la connexion
        try {
            $tcpClient.EndConnect($connexionAsync)
            Write-Host "Connexion réussie à $Serveur:$Port" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "ERREUR : Impossible de se connecter à $Serveur:$Port - $($_.Exception.Message)" -ForegroundColor Red
            return $false
        } finally {
            $tcpClient.Close()
        }

    } catch [System.Net.Sockets.SocketException] {
        # Gestion des erreurs de socket
        $codeErreur = $_.Exception.ErrorCode
        $message = "ERREUR : Problème de connexion à $Serveur:$Port"

        switch ($codeErreur) {
            10060 { $message += " - Délai d'attente dépassé" }
            10061 { $message += " - Connexion refusée (le service est-il en cours d'exécution ?)" }
            11001 { $message += " - Hôte introuvable (vérifiez le nom ou l'adresse IP)" }
            default { $message += " - Code d'erreur socket : $codeErreur" }
        }

        Write-Host $message -ForegroundColor Red
        return $false

    } catch {
        # Autres erreurs
        Write-Host "ERREUR INATTENDUE : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Tester la connexion à différents serveurs
Test-ConnexionServeur -Serveur "www.google.com" -Port 443
Test-ConnexionServeur -Serveur "serveur-inexistant.local" -Port 80
Test-ConnexionServeur -Serveur "localhost" -Port 12345  # Port probablement fermé
```

#### Types d'erreurs courantes avec le réseau

| Type d'exception | Description | Cause possible |
|------------------|-------------|----------------|
| `System.Net.Sockets.SocketException` | Erreur de socket | Diverses erreurs réseau (voir codes d'erreur) |
| `System.Net.WebException` | Erreur web | Erreurs HTTP, délais d'attente |
| `System.Net.NameResolutionFailureException` | Échec de résolution de nom | Problème DNS, nom d'hôte incorrect |
| `System.TimeoutException` | Délai d'attente | Réseau lent ou service inaccessible |

### Gestion des exceptions pour les appels API

Les appels vers des API externes sont sujets à divers types d'erreurs, y compris les codes d'état HTTP.

```powershell
function Invoke-APISecurisee {
    param(
        [string]$URL,
        [string]$Methode = "GET",
        [hashtable]$Entetes = @{},
        [object]$Corps = $null,
        [int]$TentativesMax = 3,
        [int]$DelaiEntreTentatives = 2
    )

    $tentative = 1
    $succes = $false
    $resultat = $null

    # Ajouter un agent utilisateur par défaut
    if (-not $Entetes.ContainsKey("User-Agent")) {
        $Entetes["User-Agent"] = "PowerShell/7.0"
    }

    while (-not $succes -and $tentative -le $TentativesMax) {
        try {
            $params = @{
                Uri = $URL
                Method = $Methode
                Headers = $Entetes
                ContentType = "application/json"
                ErrorAction = "Stop"
                TimeoutSec = 30
            }

            # Ajouter le corps de la requête si présent
            if ($Corps) {
                $params.Body = $Corps | ConvertTo-Json -Depth 10
            }

            # Appel API
            $resultat = Invoke-RestMethod @params
            $succes = $true

        } catch [System.Net.WebException] {
            # Gérer les réponses HTTP d'erreur
            $webResponse = $_.Exception.Response

            if ($webResponse) {
                $statusCode = [int]$webResponse.StatusCode
                $statusDescription = $webResponse.StatusDescription

                # Traiter différemment selon le code d'état
                switch ($statusCode) {
                    401 {
                        Write-Host "ERREUR API : Non autorisé (401) - Vérifiez vos identifiants" -ForegroundColor Red
                        # Échec immédiat pour les erreurs d'authentification
                        return $null
                    }
                    404 {
                        Write-Host "ERREUR API : Ressource non trouvée (404) - Vérifiez l'URL" -ForegroundColor Red
                        return $null
                    }
                    429 {
                        # Limite de taux dépassée, attendre plus longtemps
                        $attente = $DelaiEntreTentatives * $tentative
                        Write-Host "ERREUR API : Limite de taux dépassée (429) - Nouvelle tentative dans $attente secondes..." -ForegroundColor Yellow
                        Start-Sleep -Seconds $attente
                    }
                    500 {
                        Write-Host "ERREUR API : Erreur serveur interne (500) - Tentative $tentative sur $TentativesMax" -ForegroundColor Yellow
                        Start-Sleep -Seconds $DelaiEntreTentatives
                    }
                    503 {
                        Write-Host "ERREUR API : Service indisponible (503) - Tentative $tentative sur $TentativesMax" -ForegroundColor Yellow
                        Start-Sleep -Seconds $DelaiEntreTentatives
                    }
                    default {
                        Write-Host "ERREUR API : HTTP $statusCode - $statusDescription - Tentative $tentative sur $TentativesMax" -ForegroundColor Yellow
                        Start-Sleep -Seconds $DelaiEntreTentatives
                    }
                }
            } else {
                # Erreur réseau sans réponse HTTP
                Write-Host "ERREUR RÉSEAU : $($_.Exception.Message) - Tentative $tentative sur $TentativesMax" -ForegroundColor Yellow
                Start-Sleep -Seconds $DelaiEntreTentatives
            }

        } catch [System.Net.Http.HttpRequestException] {
            # Erreurs de connexion HTTP
            Write-Host "ERREUR HTTP : $($_.Exception.Message) - Tentative $tentative sur $TentativesMax" -ForegroundColor Yellow
            Start-Sleep -Seconds $DelaiEntreTentatives

        } catch [System.TimeoutException] {
            # Délai d'attente dépassé
            Write-Host "ERREUR : Délai d'attente dépassé - Tentative $tentative sur $TentativesMax" -ForegroundColor Yellow
            Start-Sleep -Seconds $DelaiEntreTentatives

        } catch {
            # Autres erreurs
            Write-Host "ERREUR INATTENDUE : $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Type : $($_.Exception.GetType().FullName)" -ForegroundColor DarkRed
            return $null
        }

        $tentative++
    }

    if ($succes) {
        return $resultat
    } else {
        Write-Host "ÉCHEC : Toutes les tentatives d'appel API ont échoué." -ForegroundColor Red
        return $null
    }
}

# Exemple d'utilisation
$resultatAPI = Invoke-APISecurisee -URL "https://api.github.com/users/microsoft/repos" -Methode "GET"
if ($resultatAPI) {
    Write-Host "Succès ! Nombre de dépôts récupérés : $($resultatAPI.Count)" -ForegroundColor Green
}
```

#### Types d'erreurs courantes avec les API

| Code HTTP | Description | Stratégie recommandée |
|-----------|-------------|----------------------|
| 400 | Requête incorrecte | Vérifier les paramètres envoyés |
| 401/403 | Non autorisé/Interdit | Vérifier les identifiants |
| 404 | Non trouvé | Vérifier l'URL |
| 429 | Trop de requêtes | Réessayer avec un délai plus long |
| 500 | Erreur serveur interne | Réessayer plus tard |
| 503 | Service indisponible | Réessayer plus tard |

### Techniques avancées : combiner les types d'exceptions

Dans un script réel, vous devrez souvent combiner la gestion de plusieurs types d'exceptions. Voici un exemple plus complet :

```powershell
function Synchroniser-DonneesAPI {
    param(
        [string]$URLApi,
        [string]$CheminFichier,
        [string]$Cle
    )

    # Créer le dossier si nécessaire
    try {
        $dossier = Split-Path -Path $CheminFichier -Parent
        if (-not (Test-Path -Path $dossier)) {
            New-Item -Path $dossier -ItemType Directory -Force | Out-Null
        }
    } catch {
        Write-Host "ERREUR : Impossible de créer le dossier de destination : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }

    # Récupérer les données de l'API
    try {
        $entetes = @{
            "Authorization" = "Bearer $Cle"
            "Accept" = "application/json"
        }

        Write-Host "Récupération des données depuis l'API..." -ForegroundColor Cyan
        $donnees = Invoke-RestMethod -Uri $URLApi -Headers $entetes -ErrorAction Stop

        # Enregistrer les données dans un fichier
        try {
            Write-Host "Enregistrement des données dans le fichier..." -ForegroundColor Cyan
            $donnees | ConvertTo-Json -Depth 10 | Set-Content -Path $CheminFichier -Force -ErrorAction Stop
            Write-Host "Synchronisation réussie !" -ForegroundColor Green
            return $true
        } catch [System.UnauthorizedAccessException] {
            Write-Host "ERREUR : Accès refusé lors de l'écriture du fichier. Vérifiez les permissions." -ForegroundColor Red
            return $false
        } catch [System.IO.IOException] {
            Write-Host "ERREUR : Problème lors de l'écriture du fichier. Il est peut-être utilisé par un autre processus." -ForegroundColor Red
            return $false
        } catch {
            Write-Host "ERREUR : Impossible d'écrire les données dans le fichier : $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }

    } catch [System.Net.WebException] {
        $statusCode = [int]$_.Exception.Response.StatusCode

        if ($statusCode -eq 401) {
            Write-Host "ERREUR : Authentification refusée. Vérifiez votre clé API." -ForegroundColor Red
        } elseif ($statusCode -eq 404) {
            Write-Host "ERREUR : API introuvable. Vérifiez l'URL." -ForegroundColor Red
        } else {
            Write-Host "ERREUR : Problème de connexion à l'API (Code HTTP : $statusCode)" -ForegroundColor Red
        }
        return $false

    } catch [System.Net.Http.HttpRequestException] {
        Write-Host "ERREUR : Problème de connexion HTTP : $($_.Exception.Message)" -ForegroundColor Red
        return $false

    } catch [System.UriFormatException] {
        Write-Host "ERREUR : Format d'URL incorrect : $URLApi" -ForegroundColor Red
        return $false

    } catch {
        Write-Host "ERREUR INATTENDUE : $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Type : $($_.Exception.GetType().FullName)" -ForegroundColor DarkRed
        return $false
    }
}

# Exemple d'utilisation
$resultat = Synchroniser-DonneesAPI -URLApi "https://api.github.com/users/microsoft" `
                                   -CheminFichier "C:\Temp\donnees_github.json" `
                                   -Cle "votre_token_github"
```

### Stratégies de nouvelle tentative (retry)

Pour les opérations réseau et API, il est souvent judicieux d'implémenter une stratégie de nouvelle tentative :

```powershell
function Executer-AvecNouvelleTentative {
    param(
        [scriptblock]$Action,
        [int]$TentativesMax = 3,
        [int]$DelaiBase = 2,  # secondes
        [switch]$DelaiExponentiel
    )

    $tentative = 1
    $erreurFinale = $null

    while ($tentative -le $TentativesMax) {
        try {
            # Exécuter l'action
            $resultat = & $Action
            # Si on arrive ici, c'est un succès
            return $resultat

        } catch {
            $erreurFinale = $_
            $message = $_.Exception.Message
            $typeErreur = $_.Exception.GetType().Name

            # Calculer le délai (exponentiel ou linéaire)
            if ($DelaiExponentiel) {
                $delai = $DelaiBase * [Math]::Pow(2, ($tentative - 1))
            } else {
                $delai = $DelaiBase
            }

            Write-Host "Tentative $tentative échouée : [$typeErreur] $message" -ForegroundColor Yellow

            if ($tentative -lt $TentativesMax) {
                Write-Host "Nouvelle tentative dans $delai secondes..." -ForegroundColor Yellow
                Start-Sleep -Seconds $delai
            }

            $tentative++
        }
    }

    # Si on arrive ici, toutes les tentatives ont échoué
    Write-Host "ÉCHEC : Toutes les tentatives ont échoué après $($TentativesMax) essais" -ForegroundColor Red
    throw $erreurFinale
}

# Exemple d'utilisation pour un appel API
try {
    $data = Executer-AvecNouvelleTentative -Action {
        Invoke-RestMethod -Uri "https://api.exemple.com/donnees" -ErrorAction Stop
    } -TentativesMax 5 -DelaiExponentiel

    Write-Host "Données récupérées avec succès !" -ForegroundColor Green
} catch {
    Write-Host "Impossible de récupérer les données après plusieurs tentatives" -ForegroundColor Red
}
```

Le délai exponentiel est particulièrement utile pour les API car il permet d'attendre de plus en plus longtemps entre les tentatives, donnant ainsi au service le temps de récupérer.

### Bonnes pratiques pour la gestion des exceptions externes

1. **Validez avant d'essayer** :
   ```powershell
   # Vérifier avant de tenter l'opération
   if (Test-Path $fichier) {
       Get-Content $fichier
   }
   ```

2. **Utilisez des timeouts appropriés** :
   ```powershell
   # Ajouter un timeout pour éviter les blocages
   Invoke-RestMethod -Uri $url -TimeoutSec 30
   ```

3. **Journalisez les détails de l'erreur** :
   ```powershell
   catch {
       # Journaliser les détails pour le débogage
       Write-Error "Erreur : $($_.Exception.Message)`nPile : $($_.ScriptStackTrace)"
   }
   ```

4. **Implémentez une logique de repli (fallback)** :
   ```powershell
   try {
       $donnees = Invoke-RestMethod -Uri $urlPrimaire
   } catch {
       Write-Warning "Serveur primaire inaccessible, utilisation du serveur de secours"
       $donnees = Invoke-RestMethod -Uri $urlSecondaire
   }
   ```

5. **Nettoyez les ressources dans `finally`** :
   ```powershell
   $connexion = $null
   try {
       $connexion = Nouvelle-Connexion
       # Opérations...
   } finally {
       if ($connexion) { $connexion.Dispose() }
   }
   ```

### Exercice pratique : Application robuste de vérification de sites

Voici un exemple complet qui combine la gestion des exceptions pour les fichiers, le réseau et les API :

```powershell
# Vérificateur de site web avec stockage de résultats et notification
function Test-SitesWeb {
    param(
        [string]$CheminFichierSites = "C:\Temp\sites.txt",
        [string]$CheminResultats = "C:\Temp\resultats_sites.csv",
        [int]$Timeout = 10  # secondes
    )

    # 1. Vérifier et créer les dossiers nécessaires
    try {
        $dossierResultats = Split-Path -Path $CheminResultats -Parent
        if (-not (Test-Path -Path $dossierResultats)) {
            New-Item -Path $dossierResultats -ItemType Directory -Force | Out-Null
            Write-Host "Dossier de résultats créé : $dossierResultats" -ForegroundColor Green
        }
    } catch {
        Write-Host "ERREUR : Impossible de créer le dossier de résultats : $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # 2. Lire la liste des sites
    try {
        if (-not (Test-Path -Path $CheminFichierSites)) {
            throw "Le fichier de sites n'existe pas : $CheminFichierSites"
        }

        $sites = Get-Content -Path $CheminFichierSites -ErrorAction Stop

        if (-not $sites -or $sites.Count -eq 0) {
            throw "Le fichier de sites est vide ou ne contient pas de données valides"
        }

        Write-Host "Fichier de sites chargé : $($sites.Count) sites à vérifier" -ForegroundColor Green
    } catch {
        Write-Host "ERREUR lors du chargement des sites : $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # 3. Préparer le tableau de résultats
    $resultats = @()
    $dateVerification = Get-Date

    # 4. Vérifier chaque site
    foreach ($site in $sites) {
        # Ignorer les lignes vides ou commentées
        if ([string]::IsNullOrWhiteSpace($site) -or $site.Trim().StartsWith("#")) {
            continue
        }

        $site = $site.Trim()
        Write-Host "Vérification de $site..." -NoNewline

        $resultat = [PSCustomObject]@{
            URL = $site
            Statut = "Inconnu"
            CodeHTTP = $null
            TempsReponse = $null
            Message = ""
            DateVerification = $dateVerification
        }

        try {
            # Mesurer le temps de réponse
            $chrono = [System.Diagnostics.Stopwatch]::StartNew()

            # Vérifier si l'URL commence par http:// ou https://
            if (-not ($site -match "^https?://")) {
                $site = "https://$site"
            }

            # Faire la requête avec un timeout
            $reponse = Invoke-WebRequest -Uri $site -UseBasicParsing -TimeoutSec $Timeout -ErrorAction Stop

            $chrono.Stop()
            $tempsReponse = $chrono.ElapsedMilliseconds

            # Enregistrer les résultats
            $resultat.Statut = "En ligne"
            $resultat.CodeHTTP = $reponse.StatusCode
            $resultat.TempsReponse = $tempsReponse
            $resultat.Message = "OK"

            Write-Host " En ligne (HTTP $($reponse.StatusCode), $tempsReponse ms)" -ForegroundColor Green

        } catch [System.Net.WebException] {
            $chrono.Stop()

            # Obtenir la réponse HTTP si disponible
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
                $resultat.CodeHTTP = $statusCode
                $resultat.Statut = "Erreur"
                $resultat.Message = "HTTP $statusCode : $($_.Exception.Message)"

                Write-Host " Erreur (HTTP $statusCode)" -ForegroundColor Red
            } else {
                $resultat.Statut = "Inaccessible"
                $resultat.Message = $_.Exception.Message

                if ($_.Exception.Message -like "*délai d'attente*" -or $_.Exception.Message -like "*timeout*") {
                    Write-Host " Timeout dépassé" -ForegroundColor Yellow
                } else {
                    Write-Host " Inaccessible : $($_.Exception.Message)" -ForegroundColor Red
                }
            }

        } catch {
            $chrono.Stop()
            $resultat.Statut = "Erreur"
            $resultat.Message = $_.Exception.Message

            Write-Host " Erreur : $($_.Exception.Message)" -ForegroundColor Red
        }

        # Ajouter au tableau de résultats
        $resultats += $resultat
    }

    # 5. Enregistrer les résultats dans un CSV
    try {
        $resultats | Export-Csv -Path $CheminResultats -NoTypeInformation -Encoding UTF8 -Force
        Write-Host "`nRésultats enregistrés dans : $CheminResultats" -ForegroundColor Green
    } catch {
        Write-Host "`nERREUR lors de l'enregistrement des résultats : $($_.Exception.Message)" -ForegroundColor Red
    }

    # 6. Résumé
    $enligne = ($resultats | Where-Object { $_.Statut -eq "En ligne" }).Count
    $erreurs = ($resultats | Where-Object { $_.Statut -ne "En ligne" }).Count

    Write-Host "`n=== RÉSUMÉ ===" -ForegroundColor Cyan
    Write-Host "Sites vérifiés : $($resultats.Count)" -ForegroundColor Cyan
    Write-Host "En ligne : $enligne" -ForegroundColor $(if ($enligne -gt 0) { "Green" } else { "Gray" })
    Write-Host "Problèmes : $erreurs" -ForegroundColor $(if ($erreurs -gt 0) { "Red" } else { "Gray" })

    return $resultats
}

# Exemple d'utilisation
# 1. Créer un fichier de sites à vérifier
@"
# Liste des sites à vérifier
www.google.com
www.microsoft.com
www.sitequinexistepas123456.com
"@ | Out-File -FilePath "C:\Temp\sites.txt" -Encoding utf8

# 2. Exécuter la vérification
Test-SitesWeb -CheminFichierSites "C:\Temp\sites.txt" -CheminResultats "C:\Temp\resultats_sites.csv"
```

### Résumé : approche par étapes pour la gestion des exceptions

1. **Identifier les types d'erreurs** possibles pour chaque opération externe
2. **Utiliser des blocs try/catch spécifiques** pour chaque type d'erreur
3. **Implémenter des stratégies de nouvelle tentative** pour les erreurs temporaires
4. **Prévoir des alternatives ou replis** quand c'est possible
5. **Toujours nettoyer les ressources** avec des blocs finally
6. **Journaliser les détails** pour faciliter le débogage ultérieur

### Techniques avancées pour les débutants

#### 1. Créer des classes d'exception personnalisées

Vous pouvez créer vos propres types d'exceptions pour des erreurs spécifiques à votre application :

```powershell
# Définir une classe d'exception personnalisée
class ConfigurationException : System.Exception {
    ConfigurationException([string]$message) : base($message) {}
}

# Utiliser l'exception personnalisée
function Charger-Configuration {
    param([string]$Chemin)

    if (-not (Test-Path $Chemin)) {
        throw [ConfigurationException]::new("Fichier de configuration introuvable : $Chemin")
    }

    try {
        $config = Get-Content $Chemin -Raw | ConvertFrom-Json
        return $config
    } catch {
        throw [ConfigurationException]::new("Format de configuration invalide : $($_.Exception.Message)")
    }
}

# Attraper l'exception personnalisée
try {
    $config = Charger-Configuration -Chemin "C:\config.json"
} catch [ConfigurationException] {
    Write-Host "Erreur de configuration : $($_.Exception.Message)" -ForegroundColor Red
} catch {
    Write-Host "Erreur inattendue : $($_.Exception.Message)" -ForegroundColor Red
}
```

#### 2. Journalisation avancée des erreurs

Pour un débogage plus facile, créez une fonction de journalisation d'erreurs détaillée :

```powershell
function Write-ErrorLog {
    param(
        [System.Management.Automation.ErrorRecord]$Error,
        [string]$FichierLog = "C:\Logs\erreurs.log",
        [switch]$Console
    )

    # Créer le dossier de logs si nécessaire
    $dossierLog = Split-Path -Path $FichierLog -Parent
    if (-not (Test-Path -Path $dossierLog)) {
        New-Item -Path $dossierLog -ItemType Directory -Force | Out-Null
    }

    # Formater les détails de l'erreur
    $message = @"
[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] ERREUR
Message     : $($Error.Exception.Message)
Type        : $($Error.Exception.GetType().FullName)
Script      : $($Error.InvocationInfo.ScriptName)
Ligne       : $($Error.InvocationInfo.ScriptLineNumber)
Commande    : $($Error.InvocationInfo.Line)
Position    : $($Error.InvocationInfo.PositionMessage)
StackTrace  : $($Error.ScriptStackTrace)
"@

    # Ajouter au fichier de log
    $message | Out-File -FilePath $FichierLog -Append -Encoding utf8

    # Afficher dans la console si demandé
    if ($Console) {
        Write-Host $message -ForegroundColor Red
    }
}

# Utilisation
try {
    # Votre code ici
    Get-Content "C:\fichier-inexistant.txt" -ErrorAction Stop
} catch {
    Write-ErrorLog -Error $_ -Console
}
```

#### 3. Manipulation sécurisée des API JSON avec validation

La validation des données reçues d'une API est cruciale :

```powershell
function Get-DonneesUtilisateur {
    param([int]$UserId)

    try {
        $url = "https://jsonplaceholder.typicode.com/users/$UserId"
        $utilisateur = Invoke-RestMethod -Uri $url -ErrorAction Stop

        # Valider la structure attendue
        if (-not $utilisateur.id -or -not $utilisateur.name -or -not $utilisateur.email) {
            throw "Structure de données utilisateur invalide"
        }

        # Créer un objet avec uniquement les propriétés dont nous avons besoin
        $utilisateurValide = [PSCustomObject]@{
            Id = $utilisateur.id
            Nom = $utilisateur.name
            Email = $utilisateur.email
            Telephone = $utilisateur.phone
            SiteWeb = $utilisateur.website
        }

        return $utilisateurValide

    } catch [System.Net.WebException] {
        $statusCode = [int]$_.Exception.Response.StatusCode

        if ($statusCode -eq 404) {
            Write-Warning "Utilisateur avec ID $UserId non trouvé"
            return $null
        } else {
            throw "Erreur API ($statusCode) : $($_.Exception.Message)"
        }
    }
}

# Test avec gestion d'erreur
try {
    $user = Get-DonneesUtilisateur -UserId 1
    if ($user) {
        Write-Host "Utilisateur trouvé : $($user.Nom) <$($user.Email)>"
    }
} catch {
    Write-Host "Erreur lors de la récupération de l'utilisateur : $($_.Exception.Message)" -ForegroundColor Red
}
```

### Exemples de cas réels

#### Exemple 1 : Sauvegarde de fichiers avec vérification d'intégrité

```powershell
function Backup-FichierSecurise {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Force
    )

    if (-not (Test-Path -Path $Source)) {
        throw [System.IO.FileNotFoundException]::new("Fichier source introuvable : $Source")
    }

    # Vérifier si le fichier destination existe déjà
    if ((Test-Path -Path $Destination) -and -not $Force) {
        throw "Le fichier destination existe déjà. Utilisez -Force pour l'écraser."
    }

    try {
        # Calculer le hash MD5 du fichier source
        $hashSource = Get-FileHash -Path $Source -Algorithm MD5 -ErrorAction Stop

        # Copier le fichier
        Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction Stop

        # Vérifier le hash du fichier copié
        $hashDestination = Get-FileHash -Path $Destination -Algorithm MD5 -ErrorAction Stop

        # Comparer les hash pour vérifier l'intégrité
        if ($hashSource.Hash -ne $hashDestination.Hash) {
            Remove-Item -Path $Destination -Force -ErrorAction SilentlyContinue
            throw "Échec de la vérification d'intégrité. La copie a été supprimée."
        }

        return [PSCustomObject]@{
            Source = $Source
            Destination = $Destination
            Hash = $hashSource.Hash
            DateCopie = Get-Date
            Taille = (Get-Item -Path $Source).Length
            Succes = $true
        }

    } catch [System.UnauthorizedAccessException] {
        throw "Accès refusé. Vérifiez vos permissions pour les fichiers source et destination."
    } catch [System.IO.IOException] {
        throw "Erreur d'E/S lors de la copie : $($_.Exception.Message)"
    } catch {
        throw "Erreur lors de la sauvegarde : $($_.Exception.Message)"
    }
}

# Exemple d'utilisation
try {
    $resultat = Backup-FichierSecurise -Source "C:\Important\document.docx" -Destination "D:\Backup\document.docx" -Force
    Write-Host "Sauvegarde réussie !" -ForegroundColor Green
    Write-Host "Hash MD5 : $($resultat.Hash)"
    Write-Host "Taille : $($resultat.Taille) octets"
} catch {
    Write-Host "ERREUR : $($_.Exception.Message)" -ForegroundColor Red
}
```

#### Exemple 2 : Téléchargement de fichier avec barre de progression et reprises

```powershell
function Download-FichierAvecReprise {
    param(
        [string]$URL,
        [string]$CheminDestination,
        [int]$TentativesMax = 3,
        [int]$TimeoutSec = 30
    )

    $nomFichier = Split-Path -Path $CheminDestination -Leaf
    $dossier = Split-Path -Path $CheminDestination -Parent

    # Créer le dossier de destination si nécessaire
    if (-not (Test-Path -Path $dossier)) {
        New-Item -Path $dossier -ItemType Directory -Force | Out-Null
    }

    $tentative = 1
    $succes = $false

    while (-not $succes -and $tentative -le $TentativesMax) {
        try {
            Write-Host "Téléchargement de $nomFichier... (tentative $tentative sur $TentativesMax)" -ForegroundColor Cyan

            # Créer une requête Web
            $webClient = New-Object System.Net.WebClient

            # Ajouter un gestionnaire d'événement pour la progression
            $eventId = [guid]::NewGuid().ToString()
            $progressEvent = Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -SourceIdentifier $eventId -Action {
                $percent = $event.SourceArgs.ProgressPercentage
                $downloaded = [Math]::Round($event.SourceArgs.BytesReceived / 1MB, 2)
                $total = [Math]::Round($event.SourceArgs.TotalBytesToReceive / 1MB, 2)

                Write-Progress -Activity "Téléchargement" -Status "$downloaded MB sur $total MB" -PercentComplete $percent
            }

            # Définir un timeout
            $webClient.Timeout = $TimeoutSec * 1000

            # Télécharger le fichier
            $webClient.DownloadFile($URL, $CheminDestination)

            # Arrêter de montrer la progression
            Write-Progress -Activity "Téléchargement" -Completed

            # Marquer comme réussi
            $succes = $true
            Write-Host "Téléchargement réussi : $CheminDestination" -ForegroundColor Green

        } catch [System.Net.WebException] {
            Write-Host "Erreur de téléchargement : $($_.Exception.Message)" -ForegroundColor Yellow

            if ($tentative -lt $TentativesMax) {
                $delai = 2 * $tentative
                Write-Host "Nouvelle tentative dans $delai secondes..." -ForegroundColor Yellow
                Start-Sleep -Seconds $delai
            }

        } catch {
            Write-Host "Erreur inattendue : $($_.Exception.Message)" -ForegroundColor Red
            throw

        } finally {
            # Nettoyer l'événement de progression
            if ($progressEvent) {
                Unregister-Event -SourceIdentifier $eventId -ErrorAction SilentlyContinue
                Remove-Job -Name $eventId -ErrorAction SilentlyContinue
            }

            # Disposer du WebClient
            if ($webClient) {
                $webClient.Dispose()
            }
        }

        $tentative++
    }

    if (-not $succes) {
        throw "Échec du téléchargement après $TentativesMax tentatives."
    }

    return $CheminDestination
}

# Exemple d'utilisation
try {
    $fichier = Download-FichierAvecReprise -URL "https://speed.hetzner.de/100MB.bin" -CheminDestination "C:\Temp\test100MB.bin"
    Write-Host "Fichier téléchargé : $fichier"
} catch {
    Write-Host "Impossible de télécharger le fichier : $($_.Exception.Message)" -ForegroundColor Red
}
```

### Conclusion

La gestion des exceptions pour les opérations sur les fichiers, le réseau et les API est essentielle pour créer des scripts PowerShell robustes et fiables. En suivant les principes et les techniques présentés dans ce tutoriel, vous pourrez :

- ✅ Anticiper et gérer les erreurs spécifiques aux ressources externes
- ✅ Implémenter des stratégies de nouvelle tentative pour les erreurs temporaires
- ✅ Fournir des messages d'erreur clairs et utiles
- ✅ Créer des logs détaillés pour le débogage
- ✅ Nettoyer correctement les ressources après utilisation

Même en tant que débutant, l'adoption de ces bonnes pratiques dès le début vous aidera à développer des scripts plus professionnels et fiables.

### Pour aller plus loin

- Explorez les cmdlets `Measure-Command` pour mesurer les performances de vos opérations réseau
- Utilisez `Write-Progress` pour afficher la progression des opérations de longue durée
- Apprenez à utiliser `PowerShell Workflows` pour les opérations pouvant être interrompues et reprises
- Découvrez les modules `ThreadJob` et `PSFramework` pour des fonctionnalités avancées de gestion des erreurs

---

N'oubliez pas : un script robuste n'est pas celui qui ne rencontre jamais d'erreurs, mais celui qui les gère correctement lorsqu'elles surviennent !
