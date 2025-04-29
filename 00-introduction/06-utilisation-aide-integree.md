# Module 1-6: Utilisation de l'aide intégrée (Get-Help, Get-Command, Get-Member)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Découvrir l'aide intégrée dans PowerShell

L'un des plus grands atouts de PowerShell est son système d'aide intégré extrêmement complet. Contrairement à d'autres interfaces en ligne de commande, vous n'avez pas besoin de chercher constamment sur Internet pour comprendre comment fonctionne une commande. PowerShell propose trois outils essentiels pour découvrir et comprendre les commandes:

- `Get-Help`: Pour comprendre comment utiliser une commande
- `Get-Command`: Pour trouver les commandes disponibles
- `Get-Member`: Pour explorer les propriétés et méthodes des objets

Maîtriser ces trois commandes vous permettra d'apprendre PowerShell de manière autonome et efficace!

## 📚 Get-Help: Votre manuel PowerShell intégré

### Mise à jour de l'aide (à faire avant tout)

La première fois que vous utilisez PowerShell, il est recommandé de mettre à jour les fichiers d'aide:

```powershell
# Cette commande doit être exécutée en tant qu'administrateur
Update-Help -Force
```

Si vous obtenez une erreur d'accès, lancez PowerShell en tant qu'administrateur et réessayez.

### Utilisation basique de Get-Help

Pour obtenir de l'aide sur n'importe quelle commande, utilisez simplement:

```powershell
Get-Help Get-Process
```

Cette commande affiche:
- Une description de la commande
- La syntaxe (différentes façons de l'utiliser)
- Une explication des paramètres communs

### Options utiles de Get-Help

Get-Help propose plusieurs paramètres pour vous donner exactement l'information dont vous avez besoin:

#### Exemples d'utilisation (-Examples)

```powershell
Get-Help Get-Process -Examples
```

Cette option affiche des exemples concrets d'utilisation de la commande - souvent le moyen le plus rapide d'apprendre!

#### Aide détaillée (-Detailed)

```powershell
Get-Help Get-Process -Detailed
```

Fournit une description plus complète et détaille tous les paramètres.

#### Aide complète (-Full)

```powershell
Get-Help Get-Process -Full
```

Affiche absolument tout sur la commande, y compris des informations techniques.

#### Aide en ligne (-Online)

```powershell
Get-Help Get-Process -Online
```

Ouvre la documentation Microsoft la plus récente dans votre navigateur web.

#### Recherche par mot-clé

Vous ne savez pas quelle commande utiliser? Recherchez par mot-clé:

```powershell
Get-Help -Name process
```

Cette commande affichera toutes les aides contenant le mot "process".

### Astuces pour les débutants avec Get-Help

- Utilisez `Get-Help *keyword*` avec des astérisques pour une recherche plus large
- Si l'aide est trop longue pour l'écran, ajoutez | `Out-Host -Paging` pour paginer l'affichage:
  ```powershell
  Get-Help Get-Process -Full | Out-Host -Paging
  ```
- Pour obtenir de l'aide sur un concept plutôt qu'une commande:
  ```powershell
  Get-Help about_Arrays
  ```

## 🔍 Get-Command: Trouvez la commande qu'il vous faut

`Get-Command` vous permet de découvrir les commandes disponibles dans votre environnement PowerShell.

### Utilisation basique

```powershell
# Affiche toutes les commandes disponibles
Get-Command
```

⚠️ Cette commande renvoie des centaines de résultats! Utilisons des filtres pour affiner la recherche.

### Filtrer par nom

```powershell
# Trouve toutes les commandes contenant "process" dans leur nom
Get-Command -Name "*process*"

# Trouve toutes les commandes commençant par "Start-"
Get-Command -Name "Start-*"
```

### Filtrer par type de commande

```powershell
# Affiche uniquement les cmdlets (commandes natives PowerShell)
Get-Command -CommandType Cmdlet

# Affiche uniquement les fonctions
Get-Command -CommandType Function

# Autres types: Alias, Application, Script...
```

### Filtrer par module

```powershell
# Affiche les commandes du module Microsoft.PowerShell.Management
Get-Command -Module Microsoft.PowerShell.Management
```

### Filtrer par verbe ou nom

PowerShell utilise la convention Verbe-Nom pour ses cmdlets:

```powershell
# Toutes les commandes avec le verbe "Get"
Get-Command -Verb Get

# Toutes les commandes avec le nom "Process"
Get-Command -Noun Process
```

### Astuces pour les débutants avec Get-Command

- Pour voir les modules disponibles: `Get-Module -ListAvailable`
- Pour trouver des commandes par fonctionnalité, utilisez un mot descriptif:
  ```powershell
  Get-Command -Name "*file*"  # Commandes liées aux fichiers
  Get-Command -Name "*user*"  # Commandes liées aux utilisateurs
  Get-Command -Name "*network*"  # Commandes liées au réseau
  ```

## 🔮 Get-Member: Explorez les objets PowerShell

L'une des particularités de PowerShell est qu'il manipule des objets (pas seulement du texte). `Get-Member` vous permet de découvrir ce que vous pouvez faire avec ces objets.

### Utilisation basique

```powershell
# Découvrir ce qu'on peut faire avec un objet processus
Get-Process | Get-Member
```

Cette commande affiche:
- Le **TypeName** (type d'objet)
- Les **Properties** (informations que l'objet contient)
- Les **Methods** (actions que l'objet peut effectuer)

### Comprendre la sortie de Get-Member

Voici un extrait de ce que vous pourriez voir:

```
   TypeName: System.Diagnostics.Process

Name                       MemberType     Definition
----                       ----------     ----------
Kill                       Method         void Kill()
...
CPU                        Property       System.TimeSpan CPU {get;}
Id                         Property       int Id {get;}
...
```

- **Methods** (comme `Kill()`) sont des actions que vous pouvez réaliser sur l'objet
- **Properties** (comme `Id`) sont des informations que vous pouvez consulter

### Filtrer les résultats

```powershell
# Afficher uniquement les propriétés
Get-Process | Get-Member -MemberType Property

# Afficher uniquement les méthodes
Get-Process | Get-Member -MemberType Method
```

### Utilisation pratique avec le pipeline

Une fois que vous connaissez les propriétés, vous pouvez les utiliser:

```powershell
# Trier les processus par consommation mémoire
Get-Process | Sort-Object -Property WorkingSet -Descending

# Sélectionner seulement certaines propriétés
Get-Process | Select-Object Name, Id, CPU
```

### Exemple concret

Supposons que nous voulons travailler avec des services:

1. Trouvons les commandes liées aux services:
   ```powershell
   Get-Command -Noun Service
   ```

2. Obtenons de l'aide sur Get-Service:
   ```powershell
   Get-Help Get-Service -Examples
   ```

3. Récupérons des services et explorons leurs propriétés:
   ```powershell
   Get-Service | Get-Member
   ```

4. Utilisons ces informations pour filtrer les services:
   ```powershell
   Get-Service | Where-Object Status -eq "Running" | Sort-Object DisplayName
   ```

## 🧩 Combiner ces commandes pour apprendre PowerShell

Ces trois commandes fonctionnent mieux ensemble. Voici une approche pour explorer une nouvelle fonctionnalité:

1. Utilisez `Get-Command` pour trouver des commandes pertinentes
2. Utilisez `Get-Help` pour comprendre comment utiliser ces commandes
3. Utilisez `Get-Member` pour explorer les objets retournés par ces commandes

### Exemple de workflow d'apprentissage

Supposons que vous voulez apprendre à travailler avec des fichiers:

```powershell
# 1. Trouvez les commandes liées aux fichiers
Get-Command -Name "*item*" -CommandType Cmdlet

# 2. Consultez l'aide et les exemples pour une commande intéressante
Get-Help Get-ChildItem -Examples

# 3. Exécutez la commande et explorez le résultat
Get-ChildItem | Get-Member

# 4. Utilisez des propriétés spécifiques
Get-ChildItem | Where-Object Length -gt 1MB | Sort-Object Length -Descending
```

## 📝 Exercices pratiques

### Exercice 1: Explorer Get-Help
1. Mettez à jour l'aide avec `Update-Help`
2. Découvrez ce que fait la commande `Get-Random` avec `Get-Help Get-Random -Examples`
3. Explorez le concept de pipeline avec `Get-Help about_Pipeline`

### Exercice 2: Trouver des commandes
1. Trouvez toutes les commandes qui peuvent créer quelque chose (indice: verbe "New")
2. Trouvez toutes les commandes liées aux événements système
3. Trouvez toutes les commandes du module "Microsoft.PowerShell.Security"

### Exercice 3: Explorer des objets
1. Récupérez des informations sur votre ordinateur avec `Get-ComputerInfo`
2. Utilisez `Get-Member` pour explorer les propriétés disponibles
3. Affichez uniquement les informations sur le système d'exploitation

## 🎓 Conclusion

L'aide intégrée de PowerShell est l'une de ses fonctionnalités les plus puissantes. En maîtrisant `Get-Help`, `Get-Command` et `Get-Member`, vous:

- Deviendrez autonome dans votre apprentissage
- Éviterez les recherches constantes sur Internet
- Découvrirez des possibilités que vous n'auriez pas imaginées

N'hésitez pas à explorer et à expérimenter - c'est la meilleure façon d'apprendre!

## 🔑 Points clés à retenir

1. `Get-Help`: Votre manuel intégré (utilisez `-Examples` pour des cas concrets)
2. `Get-Command`: Votre moteur de recherche de commandes PowerShell
3. `Get-Member`: Votre explorateur d'objets et de leurs capacités
4. Les trois commandes ci-dessus sont vos meilleurs amis pour l'auto-apprentissage
5. PowerShell manipule des objets, pas seulement du texte
6. La convention de nommage Verbe-Nom facilite la découverte de commandes

Dans le prochain module, nous explorerons comment personnaliser votre environnement PowerShell pour le rendre plus efficace et agréable à utiliser!
