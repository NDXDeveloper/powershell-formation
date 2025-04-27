# Module 7 - Gestion des erreurs en PowerShell

## 7-1. `try/catch/finally`, `throw`, `Write-Error`

Dans le monde idéal, nos scripts PowerShell s'exécuteraient toujours parfaitement, mais en réalité, des erreurs peuvent survenir : fichiers introuvables, permissions manquantes, problèmes réseau, etc. La bonne gestion des erreurs est une compétence essentielle pour créer des scripts robustes.

### Pourquoi gérer les erreurs ?

- ✅ Éviter les arrêts inattendus de vos scripts
- ✅ Fournir des messages d'erreur clairs et utiles
- ✅ Permettre à votre script de "récupérer" après une erreur
- ✅ Nettoyer les ressources même en cas d'erreur

### Les types d'erreurs dans PowerShell

PowerShell distingue deux types d'erreurs :
- **Erreurs terminales** : Elles arrêtent l'exécution (par défaut)
- **Erreurs non-terminales** : Elles génèrent un avertissement mais le script continue

### Structure try/catch/finally

La structure `try/catch/finally` est le principal mécanisme de gestion des erreurs en PowerShell :

```powershell
try {
    # Code qui pourrait générer une erreur
} catch {
    # Code qui s'exécute en cas d'erreur
} finally {
    # Code qui s'exécute TOUJOURS, qu'il y ait eu une erreur ou non
}
```

#### Exemple simple

```powershell
try {
    # Essayons d'ouvrir un fichier qui n'existe pas
    $contenu = Get-Content -Path "C:\fichier-qui-nexiste-pas.txt" -ErrorAction Stop
    Write-Host "Le fichier a été lu avec succès"
} catch {
    Write-Host "Une erreur s'est produite : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host "Cette partie s'exécute toujours" -ForegroundColor Yellow
}
```

> 💡 **Note importante** : Pour que les erreurs déclenchent un bloc `catch`, vous devez souvent ajouter le paramètre `-ErrorAction Stop` à vos cmdlets. Sinon, PowerShell pourrait traiter l'erreur comme non-terminale.

### Attraper des erreurs spécifiques

Vous pouvez avoir plusieurs blocs `catch` pour gérer différents types d'erreurs :

```powershell
try {
    # Code qui pourrait générer différents types d'erreurs
    Get-Content -Path "C:\fichier.txt" -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    Write-Host "Le fichier n'a pas été trouvé" -ForegroundColor Red
} catch [System.UnauthorizedAccessException] {
    Write-Host "Vous n'avez pas les permissions nécessaires" -ForegroundColor Red
} catch {
    # Attrape toute autre erreur
    Write-Host "Une erreur inattendue s'est produite : $($_.Exception.Message)" -ForegroundColor Red
}
```

### Utiliser l'objet d'erreur

Dans un bloc `catch`, la variable `$_` (ou `$PSItem`, c'est équivalent) contient des informations précieuses sur l'erreur :

```powershell
try {
    Get-Content -Path "C:\fichier-inexistant.txt" -ErrorAction Stop
} catch {
    Write-Host "Message d'erreur : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Type d'erreur : $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "Ligne en erreur : $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red

    # Pour voir toutes les informations disponibles :
    # $_ | Format-List * -Force
}
```

### Le bloc `finally`

Le bloc `finally` est très utile pour le nettoyage, car il s'exécute toujours, même si une erreur se produit :

```powershell
$connexion = $null

try {
    # Simulons une connexion à une base de données
    $connexion = "Connexion ouverte"
    Write-Host "Connexion établie" -ForegroundColor Green

    # Simulons une erreur
    throw "Une erreur s'est produite pendant le traitement"

} catch {
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Ce code s'exécute toujours, garantissant que la connexion est fermée
    if ($connexion) {
        Write-Host "Fermeture de la connexion..." -ForegroundColor Yellow
        $connexion = $null
    }
}
```

### Générer vos propres erreurs avec `throw`

L'instruction `throw` permet de générer manuellement une erreur :

```powershell
function Diviser {
    param(
        [int]$numerateur,
        [int]$denominateur
    )

    if ($denominateur -eq 0) {
        throw "Division par zéro impossible"
    }

    return $numerateur / $denominateur
}

try {
    $resultat = Diviser -numerateur 10 -denominateur 0
    Write-Host "Résultat : $resultat"
} catch {
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
}
```

### Utiliser `Write-Error`

Contrairement à `throw` qui génère une erreur terminale, `Write-Error` génère par défaut une erreur non-terminale :

```powershell
function VerifierAge {
    param([int]$age)

    if ($age -lt 18) {
        Write-Error "L'âge doit être d'au moins 18 ans"
        return $false
    }

    return $true
}

# Cette fonction écrit une erreur mais continue l'exécution
$estMajeur = VerifierAge -age 16
Write-Host "La vérification est terminée"

# Pour générer une erreur terminale avec Write-Error :
# Write-Error "Message d'erreur" -ErrorAction Stop
```

### Différence entre `throw` et `Write-Error`

| Caractéristique | `throw` | `Write-Error` |
|----------------|---------|--------------|
| Type d'erreur par défaut | Terminale | Non-terminale |
| Arrête l'exécution | Oui | Non (sauf avec `-ErrorAction Stop`) |
| Passe à `catch` | Oui | Non (sauf avec `-ErrorAction Stop`) |
| Utilisé pour | Erreurs critiques, validation | Avertissements, erreurs mineures |

### Conseils pratiques pour les débutants

1. **Commencez simplement** : Utilisez d'abord `try/catch` autour des opérations qui échouent souvent (accès fichiers, réseau)

2. **N'oubliez pas `-ErrorAction Stop`** : Sans ce paramètre, les erreurs pourraient ne pas être "attrapées"

3. **Utilisez `finally`** pour le nettoyage : Fermeture de fichiers, connexions, etc.

4. **Messages d'erreur clairs** : Avec `throw`, donnez des messages d'erreur explicites

5. **Journalisez les erreurs** : Pensez à enregistrer les erreurs dans un fichier journal

### Exercice pratique

Créez un script qui tente de :
1. Lire un fichier (qui peut ne pas exister)
2. Écrire son contenu dans un nouveau fichier
3. Utiliser `try/catch/finally` pour gérer les erreurs possibles

```powershell
# Chemin des fichiers
$fichierSource = "C:\temp\source.txt"
$fichierDestination = "C:\temp\destination.txt"

try {
    # Vérifier si le dossier existe, sinon le créer
    $dossier = Split-Path -Path $fichierDestination -Parent
    if (-not (Test-Path -Path $dossier)) {
        New-Item -Path $dossier -ItemType Directory -ErrorAction Stop | Out-Null
        Write-Host "Dossier créé : $dossier" -ForegroundColor Green
    }

    # Lire le fichier source
    $contenu = Get-Content -Path $fichierSource -Raw -ErrorAction Stop
    Write-Host "Fichier source lu avec succès" -ForegroundColor Green

    # Écrire dans le fichier destination
    $contenu | Set-Content -Path $fichierDestination -ErrorAction Stop
    Write-Host "Contenu écrit avec succès dans le fichier destination" -ForegroundColor Green

} catch [System.IO.FileNotFoundException] {
    Write-Host "ERREUR : Le fichier source n'existe pas à l'emplacement $fichierSource" -ForegroundColor Red
} catch [System.IO.DirectoryNotFoundException] {
    Write-Host "ERREUR : Un des dossiers du chemin n'existe pas" -ForegroundColor Red
} catch [System.UnauthorizedAccessException] {
    Write-Host "ERREUR : Vous n'avez pas les permissions nécessaires" -ForegroundColor Red
} catch {
    Write-Host "ERREUR INATTENDUE : $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Type : $($_.Exception.GetType().FullName)" -ForegroundColor DarkRed
} finally {
    Write-Host "Opération terminée" -ForegroundColor Yellow
}
```

### Pour aller plus loin

- Explorez `$ErrorActionPreference` qui définit le comportement par défaut des erreurs
- Découvrez comment créer des `trap` pour capturer des erreurs à l'échelle d'un script
- Apprenez à utiliser `$error` pour accéder à l'historique des erreurs

---

N'oubliez pas : La gestion des erreurs peut sembler fastidieuse au début, mais elle rendra vos scripts beaucoup plus robustes et professionnels !
