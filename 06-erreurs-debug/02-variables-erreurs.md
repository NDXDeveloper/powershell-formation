# Module 7 - Gestion des erreurs en PowerShell

## 7-2. `$?`, `$LASTEXITCODE`, `$ErrorActionPreference`

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Après avoir exploré les structures `try/catch/finally`, nous allons maintenant découvrir trois variables spéciales qui sont essentielles pour la gestion des erreurs en PowerShell. Ces variables vous aideront à vérifier si une commande s'est bien exécutée et à personnaliser la manière dont PowerShell réagit aux erreurs.

### La variable `$?` - Succès ou échec

La variable `$?` est l'une des plus simples mais aussi des plus utiles en PowerShell. Elle contient une valeur booléenne (`$true` ou `$false`) qui indique si la dernière commande s'est exécutée avec succès ou non.

```powershell
# Exemple avec une commande qui réussit
Get-ChildItem C:\Windows
Write-Host "La commande a-t-elle réussi ? $?" -ForegroundColor Cyan
# Affiche : La commande a-t-elle réussi ? True

# Exemple avec une commande qui échoue
Get-ChildItem C:\DossierQuiNexistePas -ErrorAction SilentlyContinue
Write-Host "La commande a-t-elle réussi ? $?" -ForegroundColor Cyan
# Affiche : La commande a-t-elle réussi ? False
```

#### Cas d'utilisation typiques de `$?`

1. **Vérification rapide après une commande critique**

```powershell
Copy-Item "C:\Source\fichier.txt" "D:\Destination\" -ErrorAction SilentlyContinue
if ($?) {
    Write-Host "La copie a réussi !" -ForegroundColor Green
} else {
    Write-Host "La copie a échoué..." -ForegroundColor Red
}
```

2. **Enchaîner des commandes uniquement si la précédente a réussi**

```powershell
New-Item -Path "C:\Temp\MonDossier" -ItemType Directory -ErrorAction SilentlyContinue
if ($?) {
    # Cette partie ne s'exécute que si la création du dossier a réussi
    Copy-Item "C:\Source\fichier.txt" "C:\Temp\MonDossier\"
}
```

> 💡 **Astuce** : Vérifiez toujours `$?` immédiatement après la commande que vous souhaitez évaluer. Sa valeur est écrasée après chaque nouvelle commande, même un simple `Write-Host` !

### La variable `$LASTEXITCODE` - Code de sortie des applications externes

Lorsque vous exécutez des programmes externes (non-PowerShell) comme `ping`, `robocopy` ou d'autres outils en ligne de commande, ces programmes renvoient souvent un code de sortie numérique. Ce code est stocké dans la variable `$LASTEXITCODE`.

- **0** signifie généralement un succès
- **Toute autre valeur** indique habituellement une erreur (mais la signification exacte dépend du programme)

```powershell
# Exemple avec ping (0 = succès, 1 = échec)
ping 127.0.0.1 -n 1 > $null  # On redirige la sortie vers $null pour ne pas l'afficher
Write-Host "Code de sortie de ping : $LASTEXITCODE" -ForegroundColor Cyan

# Exemple avec une adresse qui n'existe probablement pas
ping 1.2.3.4 -n 1 > $null
Write-Host "Code de sortie de ping : $LASTEXITCODE" -ForegroundColor Cyan
```

#### Cas d'utilisation typiques de `$LASTEXITCODE`

1. **Vérifier le résultat d'un programme externe**

```powershell
# Utilisation de robocopy avec vérification du code de sortie
robocopy "C:\Source" "D:\Destination" /E

switch ($LASTEXITCODE) {
    0 { Write-Host "Aucun fichier copié. Source et destination sont synchronisées." -ForegroundColor Green }
    1 { Write-Host "Fichiers copiés avec succès." -ForegroundColor Green }
    2 { Write-Host "Fichiers supplémentaires trouvés dans la destination." -ForegroundColor Yellow }
    4 { Write-Host "Erreurs durant la copie." -ForegroundColor Red }
    8 { Write-Host "Échec de la copie de certains fichiers." -ForegroundColor Red }
    16 { Write-Host "Erreur fatale." -ForegroundColor Red }
    default { Write-Host "Code inattendu : $LASTEXITCODE" -ForegroundColor Magenta }
}
```

2. **Arrêter un script si un programme externe échoue**

```powershell
# Vérifier si un service est accessible via ping
ping -n 1 monserveur.mondomaine.com > $null

if ($LASTEXITCODE -ne 0) {
    Write-Host "Impossible de contacter le serveur !" -ForegroundColor Red
    exit 1  # Quitte le script avec un code d'erreur
}

# Suite du script (ne s'exécute que si le ping a réussi)
Write-Host "Serveur accessible, poursuite du script..." -ForegroundColor Green
```

> 💡 **Important** : Contrairement à `$?`, la variable `$LASTEXITCODE` ne change pas à chaque commande PowerShell, mais uniquement lorsque vous exécutez un programme externe.

### La variable `$ErrorActionPreference` - Comportement par défaut face aux erreurs

La variable `$ErrorActionPreference` est une variable très puissante qui contrôle comment PowerShell réagit par défaut lorsqu'une erreur non-terminale se produit. Elle joue le même rôle que le paramètre `-ErrorAction` que vous pouvez spécifier pour chaque cmdlet.

#### Valeurs possibles pour `$ErrorActionPreference`

| Valeur | Description |
|--------|-------------|
| `Continue` | **Valeur par défaut**. Affiche l'erreur et continue l'exécution |
| `SilentlyContinue` | Ignore l'erreur et continue l'exécution (sans afficher de message) |
| `Stop` | Transforme toutes les erreurs en erreurs terminales (qui arrêtent l'exécution) |
| `Inquire` | Demande à l'utilisateur ce qu'il faut faire à chaque erreur |
| `Ignore` | Supprime complètement l'erreur (n'affecte pas la variable `$?`) |

#### Exemple d'utilisation de `$ErrorActionPreference`

```powershell
# Valeur par défaut
Write-Host "La valeur par défaut de `$ErrorActionPreference est : $ErrorActionPreference" -ForegroundColor Cyan

# Exemple avec Continue (comportement par défaut)
Get-ChildItem C:\DossierInexistant
Write-Host "Le script continue malgré l'erreur..."

# Modification temporaire pour ignorer les erreurs
$ErrorActionPreferenceOriginal = $ErrorActionPreference  # Sauvegarde de la valeur d'origine
$ErrorActionPreference = "SilentlyContinue"

Write-Host "`n$ErrorActionPreference est maintenant défini sur : $ErrorActionPreference" -ForegroundColor Yellow
Get-ChildItem C:\DossierInexistant
Write-Host "Aucune erreur n'est affichée, mais le script continue..."

# Modification pour arrêter le script en cas d'erreur
$ErrorActionPreference = "Stop"
Write-Host "`n$ErrorActionPreference est maintenant défini sur : $ErrorActionPreference" -ForegroundColor Red

# Cette ligne va provoquer l'arrêt du script, sauf si elle est dans un bloc try/catch
try {
    Get-ChildItem C:\DossierInexistant
    Write-Host "Cette ligne ne sera jamais exécutée"
} catch {
    Write-Host "Une erreur s'est produite : $($_.Exception.Message)" -ForegroundColor Red
}

# Restauration de la valeur d'origine
$ErrorActionPreference = $ErrorActionPreferenceOriginal
Write-Host "`n$ErrorActionPreference est revenu à : $ErrorActionPreference" -ForegroundColor Cyan
```

#### Bonnes pratiques avec `$ErrorActionPreference`

1. **Sauvegardez toujours la valeur originale** avant de la modifier
2. **Limitez la portée du changement** au minimum nécessaire
3. **Restaurez la valeur d'origine** à la fin du bloc de code
4. **Préférez utiliser le paramètre `-ErrorAction`** sur les cmdlets individuelles quand c'est possible

```powershell
# Meilleure approche : modifier ErrorAction uniquement pour les commandes spécifiques
Get-ChildItem C:\Windows -ErrorAction Continue
Get-ChildItem C:\DossierInexistant -ErrorAction SilentlyContinue
Get-Content C:\fichier-important.txt -ErrorAction Stop
```

### Combiner ces variables pour une gestion d'erreurs efficace

Ces trois variables fonctionnent très bien ensemble pour créer des scripts robustes. Voici un exemple complet :

```powershell
# Script qui sauvegarde un dossier avec robocopy et vérifie le résultat

function Backup-Folder {
    param (
        [string]$Source,
        [string]$Destination
    )

    # Vérifier si les dossiers existent
    if (-not (Test-Path -Path $Source)) {
        Write-Error "Le dossier source n'existe pas : $Source"
        return $false
    }

    if (-not (Test-Path -Path $Destination)) {
        # Créer le dossier destination s'il n'existe pas
        New-Item -Path $Destination -ItemType Directory -ErrorAction Stop | Out-Null
    }

    # Exécuter robocopy avec les options désirées
    Write-Host "Copie en cours de $Source vers $Destination..." -ForegroundColor Yellow
    robocopy $Source $Destination /MIR /R:3 /W:5 /NFL /NDL

    # Analyser le code de sortie de robocopy
    switch ($LASTEXITCODE) {
        { $_ -ge 8 } {
            Write-Host "ÉCHEC : La sauvegarde a rencontré des erreurs graves." -ForegroundColor Red
            return $false
        }
        { $_ -ge 4 } {
            Write-Host "ATTENTION : Certains fichiers n'ont pas pu être copiés." -ForegroundColor Yellow
            return $true  # On considère que c'est un succès partiel
        }
        default {
            Write-Host "SUCCÈS : Sauvegarde terminée sans erreur critique." -ForegroundColor Green
            return $true
        }
    }
}

# Utilisation de la fonction
try {
    # Définir ErrorActionPreference pour arrêter sur les erreurs graves
    $OriginalEAP = $ErrorActionPreference
    $ErrorActionPreference = "Stop"

    $resultat = Backup-Folder -Source "C:\Documents" -Destination "D:\Backup\Documents"

    if ($resultat -and $?) {
        Write-Host "La sauvegarde s'est terminée avec succès !" -ForegroundColor Green
    } else {
        Write-Host "La sauvegarde a échoué ou s'est terminée avec des avertissements." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Une erreur critique s'est produite : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Toujours restaurer la valeur d'origine
    $ErrorActionPreference = $OriginalEAP
}
```

### Cas pratiques pour débutants

#### 1. Vérifier si une commande a échoué

```powershell
# Tenter de supprimer un fichier
Remove-Item "C:\fichier-a-supprimer.txt" -ErrorAction SilentlyContinue

# Vérifier si la suppression a réussi
if ($?) {
    Write-Host "Le fichier a été supprimé avec succès" -ForegroundColor Green
} else {
    Write-Host "Impossible de supprimer le fichier (peut-être qu'il n'existe pas ?)" -ForegroundColor Yellow
}
```

#### 2. Script d'installation qui vérifie les conditions préalables

```powershell
# Vérifier si un logiciel externe est installé
$logicielExterne = "notepad++.exe"
cmd /c "where $logicielExterne" > $null

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR : $logicielExterne n'est pas installé ou n'est pas dans le PATH" -ForegroundColor Red
    exit 1
}

Write-Host "$logicielExterne est correctement installé, poursuite de l'installation..." -ForegroundColor Green
```

#### 3. Fonction qui teste une connexion réseau

```powershell
function Test-ServerConnection {
    param (
        [string]$ServerName,
        [int]$Port = 80
    )

    try {
        # Sauvegarder et modifier la préférence d'action d'erreur
        $oldPreference = $ErrorActionPreference
        $ErrorActionPreference = "Stop"

        # Tester la connexion
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect($ServerName, $Port)
        $tcpClient.Close()

        return $true
    } catch {
        return $false
    } finally {
        # Restaurer la préférence d'action d'erreur
        $ErrorActionPreference = $oldPreference
    }
}

# Utilisation de la fonction
if (Test-ServerConnection -ServerName "www.google.com" -Port 443) {
    Write-Host "Connexion à Google réussie !" -ForegroundColor Green
} else {
    Write-Host "Impossible de se connecter à Google..." -ForegroundColor Red
}
```

### Résumé des points clés

| Variable | Utilisation | Quand la vérifier |
|----------|-------------|-------------------|
| `$?` | Indique si la dernière commande PowerShell a réussi | Immédiatement après la commande à vérifier |
| `$LASTEXITCODE` | Contient le code de sortie du dernier programme externe exécuté | Après avoir exécuté un programme non-PowerShell |
| `$ErrorActionPreference` | Définit comment PowerShell réagit aux erreurs non-terminales | À définir au début d'un bloc de code qui nécessite un comportement spécifique |

### Conseils pour les débutants

1. **Commencez par `$?`** - C'est la variable la plus simple à utiliser pour vérifier si une commande a fonctionné
2. **Utilisez `-ErrorAction` plutôt que de modifier `$ErrorActionPreference`** - C'est plus sûr et plus ciblé
3. **N'oubliez pas de consulter `$LASTEXITCODE`** quand vous exécutez des programmes externes
4. **Combinez avec `try/catch/finally`** pour une gestion d'erreurs complète
5. **Testez vos scripts** avec des conditions d'erreur intentionnelles pour vous assurer que votre gestion des erreurs fonctionne

---

Avec ces trois variables et les structures `try/catch/finally` vues précédemment, vous disposez maintenant d'un ensemble d'outils puissants pour gérer efficacement les erreurs dans vos scripts PowerShell !
