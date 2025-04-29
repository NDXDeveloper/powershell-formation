# Module 3-1: Cmdlets, alias et pipeline

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Les briques fondamentales de PowerShell

Bienvenue dans ce premier chapitre du Module 3 sur la syntaxe et les fondamentaux de PowerShell. Nous allons explorer trois concepts essentiels qui forment le cœur de PowerShell: les cmdlets, les alias et le pipeline. Comprendre ces éléments est la clé pour maîtriser PowerShell.

## 1. Les cmdlets: les commandes natives de PowerShell

### Qu'est-ce qu'une cmdlet?

Une **cmdlet** (prononcé "command-let") est une commande légère intégrée à PowerShell. Contrairement aux commandes classiques d'autres shells, les cmdlets:

- Sont des objets .NET, pas de simples programmes
- Suivent toujours une structure standard **Verbe-Nom**
- Manipulent des objets, pas juste du texte

### La structure Verbe-Nom

Toutes les cmdlets suivent une structure claire **Verbe-Nom**:

```powershell
Get-Process
Stop-Service
New-Item
```

Les verbes indiquent l'action (que fait la commande?), et les noms indiquent la cible (sur quoi agit la commande?).

#### Verbes communs:

| Verbe | Action |
|-------|--------|
| Get   | Récupère une information |
| Set   | Modifie une configuration |
| New   | Crée un nouvel élément |
| Remove | Supprime un élément |
| Start/Stop | Démarre/arrête une activité ou processus |
| Import/Export | Importe/exporte des données |
| Connect/Disconnect | Établit/ferme une connexion |

#### Exemples concrets:

```powershell
# Récupérer la liste des processus
Get-Process

# Obtenir la date et l'heure actuelles
Get-Date

# Créer un nouveau dossier
New-Item -Path "C:\Temp\NouveauDossier" -ItemType Directory

# Arrêter un service
Stop-Service -Name "wuauserv"  # Service Windows Update
```

### Les paramètres des cmdlets

Les cmdlets acceptent des **paramètres** qui modifient leur comportement:

```powershell
Get-Process -Name "chrome"  # Filtre sur le nom
```

Plusieurs types de paramètres existent:

#### Paramètres nommés (les plus courants)

```powershell
Get-Service -Name "wuauserv" -ComputerName "SERVEUR01"
```

#### Paramètres positionnels (sans spécifier le nom)

```powershell
Get-Service "wuauserv"  # Le premier paramètre est souvent -Name par défaut
```

#### Paramètres commutateurs (switch)

Ces paramètres sont soit présents (activés), soit absents (désactivés):

```powershell
Get-ChildItem -Recurse  # Liste récursivement
```

## 2. Les alias: les raccourcis pour les cmdlets

### Qu'est-ce qu'un alias?

Un **alias** est simplement un nom alternatif plus court pour une cmdlet. Les alias existent pour:

- Accélérer la frappe (moins de caractères)
- Assurer la compatibilité avec d'autres shells (cmd, bash)
- Créer des raccourcis pour vos commandes préférées

### Alias communs

PowerShell inclut de nombreux alias prédéfinis:

| Alias | Cmdlet complète | Origine |
|-------|----------------|---------|
| `ls`, `dir` | `Get-ChildItem` | Bash/CMD |
| `cd` | `Set-Location` | Bash/CMD |
| `pwd` | `Get-Location` | Bash |
| `cat` | `Get-Content` | Bash |
| `ps` | `Get-Process` | Bash |
| `cp` | `Copy-Item` | Bash |
| `mv` | `Move-Item` | Bash |
| `rm` | `Remove-Item` | Bash |
| `echo` | `Write-Output` | Bash/CMD |
| `cls` | `Clear-Host` | CMD |

### Gestion des alias

Vous pouvez:

#### Voir tous les alias disponibles:

```powershell
Get-Alias
```

#### Trouver l'alias d'une cmdlet:

```powershell
Get-Alias -Definition "Get-ChildItem"  # Retourne ls, dir, gci
```

#### Trouver à quelle cmdlet correspond un alias:

```powershell
Get-Alias -Name "ls"  # Retourne Get-ChildItem
```

#### Créer vos propres alias:

```powershell
New-Alias -Name "ll" -Value "Get-ChildItem"
```

> **Note**: Les alias créés avec `New-Alias` ne sont disponibles que pour la session actuelle. Pour les rendre permanents, ajoutez-les à votre profil PowerShell (`$PROFILE`).

## 3. Le pipeline: la puissance de l'enchaînement

### Qu'est-ce que le pipeline?

Le **pipeline** (ou "tuyau" en français) est sans doute la caractéristique la plus puissante de PowerShell. Il permet de:

- Connecter plusieurs cmdlets ensemble
- Faire passer les résultats d'une cmdlet à une autre
- Créer des chaînes de traitement complexes

Le symbole du pipeline est le caractère barre verticale: `|`

### Fonctionnement simple

Dans un pipeline, la sortie d'une commande devient l'entrée de la suivante:

```powershell
Commande1 | Commande2 | Commande3
```

### Exemples concrets

#### Exemple 1: Filtrer des processus et trier le résultat

```powershell
Get-Process | Where-Object { $_.CPU -gt 10 } | Sort-Object CPU -Descending
```

Ce que fait cette commande:
1. `Get-Process` récupère tous les processus en cours
2. `Where-Object { $_.CPU -gt 10 }` filtre pour ne garder que ceux utilisant plus de 10% du CPU
3. `Sort-Object CPU -Descending` trie les résultats par utilisation CPU décroissante

#### Exemple 2: Trouver les 5 fichiers les plus volumineux

```powershell
Get-ChildItem -Path C:\Windows -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 5 Name, Length
```

Ce que fait cette commande:
1. `Get-ChildItem` liste tous les fichiers de C:\Windows (récursivement)
2. `Sort-Object` trie les fichiers par taille décroissante
3. `Select-Object` ne conserve que les 5 premiers et affiche leur nom et taille

### La magie du pipeline: comment ça marche?

Le pipeline passe des **objets** (pas du texte) d'une cmdlet à l'autre. PowerShell détermine comment une cmdlet peut utiliser les objets reçus de trois façons:

1. **Par la valeur** (ByValue): L'objet est passé directement au premier paramètre compatible
2. **Par le nom de propriété** (ByPropertyName): Les propriétés de l'objet sont mappées aux paramètres de même nom
3. **Par entrée personnalisée**: La cmdlet traite spécifiquement les objets du pipeline

Pour savoir comment une cmdlet accepte les entrées du pipeline:

```powershell
Get-Help Sort-Object -Parameter * | Where-Object { $_.PipelineInput -ne 'False' }
```

## 4. Exemples pratiques combinant cmdlets, alias et pipeline

### Exemple 1: Gestion des services

Trouver tous les services arrêtés qui sont configurés pour démarrer automatiquement:

```powershell
Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
```

Ou avec des alias, plus court:

```powershell
gsv | ? { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
```

### Exemple 2: Analyse de fichiers journaux

Trouver toutes les lignes contenant "error" dans un fichier journal:

```powershell
Get-Content -Path "C:\Logs\application.log" | Select-String -Pattern "error"
```

Avec des alias:

```powershell
cat "C:\Logs\application.log" | sls "error"
```

### Exemple 3: Gestion des processus

Arrêter tous les processus Chrome:

```powershell
Get-Process -Name chrome | Stop-Process
```

Alias:

```powershell
ps chrome | kill
```

## 5. Bonnes pratiques

### Pour les débutants

1. **Privilégiez les noms complets des cmdlets** plutôt que les alias dans vos scripts (pour la lisibilité)
2. **Utilisez les alias** uniquement dans la console interactive pour aller plus vite
3. **Construisez vos pipelines progressivement**, testez chaque étape avant d'ajouter la suivante
4. **N'hésitez pas à mettre vos pipelines sur plusieurs lignes** pour plus de clarté:

```powershell
Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object CPU -Descending |
    Format-Table Name, CPU, ID
```

### Pour la maintenance

N'utilisez pas d'alias dans les scripts destinés à être partagés ou maintenus à long terme. Les noms complets des cmdlets sont plus explicites et rendent le code auto-documenté:

```powershell
# Difficile à comprendre pour un débutant
ps | ? { $_.ws -gt 1GB } | ft n, ws

# Beaucoup plus clair
Get-Process | Where-Object { $_.WorkingSet -gt 1GB } | Format-Table Name, WorkingSet
```

## 6. Exercices pratiques

### Exercice 1: Explorer les cmdlets et alias
1. Affichez tous les alias disponibles avec `Get-Alias`
2. Trouvez tous les alias associés à `Get-ChildItem`
3. Trouvez toutes les cmdlets qui commencent par "Get-" avec `Get-Command Get-*`

### Exercice 2: Premiers pipelines
1. Listez tous les processus et triez-les par utilisation mémoire
   ```powershell
   Get-Process | Sort-Object -Property WorkingSet -Descending
   ```

2. Trouvez les 3 dossiers les plus volumineux dans votre répertoire utilisateur
   ```powershell
   Get-ChildItem -Path $HOME -Directory |
       Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue |
       Group-Object -Property DirectoryName |
       Select-Object Name, @{Name="Size";Expression={($_.Group | Measure-Object -Property Length -Sum).Sum}} |
       Sort-Object Size -Descending |
       Select-Object -First 3
   ```

### Exercice 3: Créez vos propres alias
1. Créez un alias `findfile` pour rechercher des fichiers par nom:
   ```powershell
   New-Alias -Name findfile -Value Get-ChildItem
   # Utilisation: findfile -Path C:\ -Recurse -Filter "*.txt"
   ```

2. Pour rendre cet alias permanent, ajoutez-le à votre profil PowerShell:
   ```powershell
   # Ajouter au profil
   Add-Content -Path $PROFILE -Value 'New-Alias -Name findfile -Value Get-ChildItem'
   ```

## Conclusion

Les cmdlets, les alias et le pipeline sont les fondations sur lesquelles repose la puissance de PowerShell:

- Les **cmdlets** fournissent des fonctionnalités cohérentes avec leur structure Verbe-Nom
- Les **alias** offrent des raccourcis pratiques pour accélérer votre travail
- Le **pipeline** vous permet de combiner des commandes pour créer des solutions complexes

En maîtrisant ces trois concepts, vous avez franchi le premier pas vers une utilisation efficace de PowerShell. Dans les prochaines sections, nous explorerons les variables, les types de données et les structures de contrôle qui vous permettront d'écrire des scripts plus sophistiqués.
