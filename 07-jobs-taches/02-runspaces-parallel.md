# Module 8 - Jobs, tâches planifiées et parallélisme
## 8-2. Runspaces & ForEach-Object -Parallel (PowerShell 7+)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### Introduction au parallélisme avancé dans PowerShell

Dans la section précédente, nous avons découvert les **Jobs** PowerShell qui permettent d'exécuter des tâches en arrière-plan. Dans cette section, nous allons explorer deux méthodes plus avancées pour exécuter des tâches en parallèle, disponibles dans PowerShell 7 et versions ultérieures :

1. Le paramètre `-Parallel` de la cmdlet `ForEach-Object`
2. Les **Runspaces** (espaces d'exécution)

> **Prérequis** : Pour utiliser ces fonctionnalités, vous devez disposer de PowerShell 7 ou version ultérieure. Si vous utilisez encore Windows PowerShell 5.1, vous devrez vous limiter aux Jobs standard.

### 1. ForEach-Object -Parallel : Boucles en parallèle

Le paramètre `-Parallel` introduit dans PowerShell 7 permet d'exécuter des boucles `ForEach-Object` en parallèle plutôt que séquentiellement, ce qui peut considérablement accélérer le traitement de grandes collections.

#### Syntaxe de base

```powershell
collection | ForEach-Object -Parallel {
    # Code à exécuter en parallèle pour chaque élément
} -ThrottleLimit nombre
```

- **Collection** : Les éléments à traiter (serveurs, fichiers, etc.)
- **Script Block** : Le code qui sera exécuté pour chaque élément
- **ThrottleLimit** : Nombre maximum de tâches parallèles à exécuter simultanément (20 par défaut)

#### Exemple simple : Ping de plusieurs serveurs

```powershell
$serveurs = "google.com", "microsoft.com", "github.com", "amazon.com"

$serveurs | ForEach-Object -Parallel {
    $serveur = $_
    $resultat = Test-Connection -ComputerName $serveur -Count 1 -Quiet

    if ($resultat) {
        [PSCustomObject]@{
            Serveur = $serveur
            Statut = "En ligne"
            Timestamp = Get-Date
        }
    } else {
        [PSCustomObject]@{
            Serveur = $serveur
            Statut = "Hors ligne"
            Timestamp = Get-Date
        }
    }
} -ThrottleLimit 10
```

Dans cet exemple :
- Nous définissons une liste de serveurs à vérifier
- Nous utilisons `ForEach-Object -Parallel` pour pinger chaque serveur simultanément
- Nous limitons à 10 opérations parallèles maximum avec `-ThrottleLimit`
- Nous retournons un objet personnalisé avec le statut de chaque serveur

#### Accéder aux variables externes avec $using:

Une particularité importante : dans un bloc parallèle, vous n'avez pas directement accès aux variables de la session principale. Pour y accéder, vous devez utiliser le préfixe `$using:`.

```powershell
$timeout = 500  # Timeout en millisecondes

$serveurs | ForEach-Object -Parallel {
    $serveur = $_
    # Utilisation d'une variable externe avec $using:
    $resultat = Test-Connection -ComputerName $serveur -Count 1 -TimeoutMilliseconds $using:timeout -Quiet

    # Reste du code...
}
```

#### Capturer les résultats dans une variable

```powershell
$resultats = $serveurs | ForEach-Object -Parallel {
    # Code de traitement...
    return [PSCustomObject]@{
        Serveur = $_
        # Autres propriétés...
    }
}

# Utiliser les résultats ensuite
$resultats | Format-Table
```

### 2. Les Runspaces : Pour les utilisateurs avancés

Les **Runspaces** représentent le mécanisme sous-jacent qui permet l'exécution parallèle dans PowerShell. Ils sont plus complexes à utiliser que `ForEach-Object -Parallel`, mais offrent un contrôle plus fin.

> **Note pour débutants** : Cette partie est plus avancée. Ne vous inquiétez pas si elle semble complexe, vous pouvez commencer par maîtriser `ForEach-Object -Parallel` qui est plus simple à utiliser.

#### Concept de base des Runspaces

Un Runspace est un environnement d'exécution PowerShell isolé avec ses propres variables, fonctions et états. Vous pouvez créer plusieurs Runspaces et les exécuter en parallèle.

#### Exemple simplifié d'utilisation des Runspaces

```powershell
# Créer un pool de runspaces
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 5)  # Min=1, Max=5 runspaces
$runspacePool.Open()

# Liste pour stocker les tâches
$runspaces = New-Object System.Collections.ArrayList

# Pour chaque serveur, créer un runspace
foreach ($serveur in $serveurs) {
    # Créer un PowerShell pour exécuter notre code
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter le script à exécuter
    [void]$powershell.AddScript({
        param($srv)
        $resultat = Test-Connection -ComputerName $srv -Count 1 -Quiet

        if ($resultat) {
            return "$srv est en ligne"
        } else {
            return "$srv est hors ligne"
        }
    })

    # Ajouter le paramètre
    [void]$powershell.AddArgument($serveur)

    # Démarrer l'exécution de manière asynchrone
    $handle = $powershell.BeginInvoke()

    # Stocker les informations
    [void]$runspaces.Add([PSCustomObject]@{
        PowerShell = $powershell
        Handle = $handle
        Serveur = $serveur
    })
}

# Récupérer les résultats
foreach ($runspace in $runspaces) {
    $resultat = $runspace.PowerShell.EndInvoke($runspace.Handle)
    Write-Output $resultat

    # Nettoyer
    $runspace.PowerShell.Dispose()
}

# Fermer le pool
$runspacePool.Close()
$runspacePool.Dispose()
```

Ce code est plus complexe, mais il illustre les concepts de base des Runspaces :
1. Création d'un pool de Runspaces
2. Ajout de tâches au pool
3. Exécution asynchrone
4. Récupération des résultats
5. Nettoyage des ressources

### Comparaison des méthodes de parallélisme

| Méthode | Avantages | Inconvénients | Quand l'utiliser |
|---------|-----------|---------------|------------------|
| **Jobs** | Simple à utiliser, disponible dans toutes les versions | Plus lent, consomme plus de ressources | Pour des tâches simples, compatibilité avec PS 5.1 |
| **ForEach-Object -Parallel** | Facile à utiliser, syntaxe familière, rapide | PowerShell 7+ uniquement | Traitement parallèle de collections, usage quotidien |
| **Runspaces** | Très performant, contrôle fin | Complexe, demande plus de code | Applications avancées, performance critique |

### Bonnes pratiques pour le parallélisme

1. **Limitez le nombre de tâches parallèles** : Plus n'est pas toujours mieux. Un trop grand nombre de tâches parallèles peut saturer votre système.

2. **Attention au partage de ressources** : Les opérations parallèles accédant aux mêmes fichiers ou ressources peuvent causer des problèmes.

3. **Gérez la mémoire** : Les opérations parallèles consomment plus de mémoire. Pour les gros volumes de données, ajustez le ThrottleLimit.

4. **Testez les performances** : Comparez l'exécution séquentielle vs parallèle. Parfois, le parallélisme n'apporte pas d'avantage pour des petites collections.

### Exemple pratique : Traitement de fichiers en parallèle

Voici un exemple concret qui montre comment traiter plusieurs fichiers en parallèle :

```powershell
# Récupérer tous les fichiers log d'un répertoire
$fichiers = Get-ChildItem -Path "C:\Logs" -Filter "*.log"

# Traiter chaque fichier en parallèle
$resultats = $fichiers | ForEach-Object -Parallel {
    $fichier = $_
    $contenu = Get-Content -Path $fichier.FullName

    # Compter le nombre d'erreurs dans chaque fichier
    $nbErreurs = ($contenu | Select-String -Pattern "ERROR" -SimpleMatch).Count

    # Retourner un objet avec les informations
    [PSCustomObject]@{
        Fichier = $fichier.Name
        NombreErreurs = $nbErreurs
        Taille = $fichier.Length
        DerniereMaj = $fichier.LastWriteTime
    }
} -ThrottleLimit 5

# Afficher les résultats
$resultats | Sort-Object -Property NombreErreurs -Descending | Format-Table
```

### Exercice pratique

Essayez de modifier l'exemple précédent pour créer un script qui:
1. Recherche des fichiers dans un répertoire de votre choix
2. Traite ces fichiers en parallèle (par exemple, compte des mots ou recherche un motif)
3. Affiche un résumé des résultats

### Conclusion

Le parallélisme avec PowerShell 7+ via `ForEach-Object -Parallel` offre un moyen simple mais puissant d'accélérer vos scripts et de tirer parti des processeurs multi-cœurs modernes. Pour la plupart des besoins quotidiens, cette méthode est largement suffisante. Les Runspaces offrent plus de contrôle mais sont généralement réservés à des scénarios plus avancés.

Dans la prochaine section, nous verrons comment planifier l'exécution de vos scripts PowerShell à des moments précis grâce au Planificateur de tâches Windows.

⏭️ [Planification via le Planificateur de tâches Windows](/07-jobs-taches/03-planification.md)
