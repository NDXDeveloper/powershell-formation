# Module 2-3: Historique de commandes et raccourcis clavier

## Travailler efficacement dans PowerShell

Imaginez que vous venez d'exécuter une longue commande complexe et que vous avez besoin de la relancer avec une légère modification. Ou que vous vous souvenez d'avoir exécuté une commande parfaite la semaine dernière, mais vous ne vous rappelez plus exactement comment vous l'aviez formulée.

C'est là que l'**historique des commandes** et les **raccourcis clavier** de PowerShell entrent en jeu! Ces fonctionnalités vous feront gagner énormément de temps et rendront votre expérience PowerShell beaucoup plus agréable.

## L'historique des commandes

PowerShell garde automatiquement une trace des commandes que vous avez exécutées précédemment. Vous pouvez accéder à cet historique de plusieurs façons.

### Afficher l'historique avec Get-History

La commande `Get-History` (ou son alias `history`) affiche la liste des commandes récentes:

```powershell
Get-History
```

Résultat typique:
```
  Id CommandLine
  -- -----------
   1 Get-Process
   2 Get-Service
   3 Get-ChildItem C:\Windows
```

### Rappeler une commande par son ID

Vous pouvez réexécuter une commande spécifique en utilisant son ID:

```powershell
Invoke-History 3    # Exécute la commande avec l'ID 3
```

L'alias plus court `r` fonctionne aussi:

```powershell
r 3                 # Équivalent à Invoke-History 3
```

### Limites de l'historique

Par défaut, PowerShell conserve les 4096 dernières commandes. Vous pouvez vérifier cette limite avec:

```powershell
(Get-PSReadLineOption).MaximumHistoryCount
```

Pour modifier cette limite, ajoutez cette ligne à votre profil PowerShell:

```powershell
Set-PSReadLineOption -MaximumHistoryCount 10000
```

### Recherche dans l'historique

La fonctionnalité la plus utile est la recherche dans l'historique en utilisant les touches fléchées:

- **Flèche Haut** (↑) : affiche la commande précédente
- **Flèche Bas** (↓) : affiche la commande suivante

Mais cela devient rapidement inefficace si vous avez beaucoup de commandes. Voici une astuce plus avancée:

## Raccourcis clavier avec PSReadLine

PSReadLine est un module qui améliore grandement l'expérience de la ligne de commande PowerShell. Il est préinstallé avec PowerShell 5.1 et supérieur.

### Configurer la recherche intelligente dans l'historique

Ajoutez ces lignes à votre profil PowerShell pour activer la recherche contextuelle:

```powershell
# Recherche dans l'historique basée sur ce que vous avez déjà tapé
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
```

Avec cette configuration:
1. Tapez le début d'une commande (par exemple `Get-`)
2. Appuyez sur **Flèche Haut** (↑)
3. PowerShell recherchera la commande précédente commençant par `Get-`

C'est beaucoup plus efficace que de parcourir tout l'historique!

### Raccourcis clavier essentiels

Voici les raccourcis clavier les plus utiles dans PowerShell:

| Raccourci | Action |
|-----------|--------|
| **Tab** | Complète automatiquement les commandes, chemins et paramètres |
| **Ctrl + espace** | Affiche les suggestions de complétion (PowerShell 7+) |
| **Flèche Haut/Bas** | Navigation dans l'historique |
| **F7** | Affiche une fenêtre avec l'historique des commandes |
| **F8** | Recherche dans l'historique en commençant par le texte saisi |
| **Ctrl + r** | Recherche en arrière dans l'historique (mode recherche) |
| **Ctrl + s** | Recherche en avant dans l'historique (mode recherche) |
| **Ctrl + c** | Annule la commande en cours d'exécution |
| **Ctrl + l** | Efface l'écran (équivalent à `Clear-Host`) |
| **Ctrl + a** | Va au début de la ligne |
| **Ctrl + e** | Va à la fin de la ligne |
| **Ctrl + →** | Déplace le curseur d'un mot vers la droite |
| **Ctrl + ←** | Déplace le curseur d'un mot vers la gauche |
| **Ctrl + Backspace** | Supprime le mot à gauche du curseur |
| **Ctrl + Delete** | Supprime le mot à droite du curseur |
| **Alt + b** | Mode marquage (sélection) |
| **Ctrl + z** | Annule la dernière modification (Undo) |

### Mode Recherche (Ctrl+r)

Le mode recherche est particulièrement puissant:

1. Appuyez sur **Ctrl+r**
2. Commencez à taper une partie de la commande recherchée
3. PowerShell affichera la commande correspondante la plus récente
4. Continuez à appuyer sur **Ctrl+r** pour voir les correspondances précédentes
5. Appuyez sur **Entrée** pour exécuter la commande trouvée ou **Échap** pour quitter la recherche

### Configuration avancée de PSReadLine

Voici quelques configurations utiles à ajouter à votre profil PowerShell:

```powershell
# Prédiction basée sur l'historique (PowerShell 7.1+)
Set-PSReadLineOption -PredictionSource History

# Autocomplétion améliorée avec Tab (similaire à bash)
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

# Effacer l'écran avec Ctrl+l
Set-PSReadLineKeyHandler -Key "Ctrl+l" -Function ClearScreen

# Ctrl+d pour quitter la session, comme dans bash
Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function ViExit

# Historique sans doublons
Set-PSReadLineOption -HistoryNoDuplicates

# Coloration syntaxique
Set-PSReadLineOption -Colors @{
    Command            = 'Cyan'
    Parameter          = 'Green'
    String             = 'Yellow'
    Operator           = 'Magenta'
    Variable           = 'White'
    Number             = 'DarkGreen'
    Member             = 'DarkGreen'
    Type               = 'DarkRed'
    Comment            = 'DarkGray'
}
```

## Gestion avancée de l'historique

### Persistance de l'historique

Par défaut, l'historique n'est conservé que pendant la session PowerShell en cours. Pour le conserver entre les sessions, ajoutez ceci à votre profil:

```powershell
# Définir le fichier d'historique
$historyFilePath = Join-Path ([Environment]::GetFolderPath('UserProfile')) .ps_history
Set-PSReadLineOption -HistorySavePath $historyFilePath
```

### Nettoyer l'historique

Si vous souhaitez supprimer l'historique (par exemple pour des raisons de sécurité):

```powershell
# Effacer l'historique complet
Clear-History

# Avec PSReadLine, effacer aussi l'historique en mémoire
[Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
```

### Exporter et importer l'historique

Vous pouvez sauvegarder votre historique pour référence future:

```powershell
# Exporter l'historique vers un fichier
Get-History | Export-Clixml -Path "$HOME\Documents\PowerShell_History_$(Get-Date -Format 'yyyyMMdd').xml"

# Importer un historique précédemment exporté
Import-Clixml -Path "$HOME\Documents\PowerShell_History_20231001.xml" | Add-History
```

## Astuces de productivité pour les débutants

### 1. Utilisez la touche Tab abondamment

La touche **Tab** est votre meilleure amie dans PowerShell:

- Appuyez sur **Tab** après avoir tapé le début d'une commande, d'un chemin ou d'un nom de fichier
- Appuyez plusieurs fois sur **Tab** pour faire défiler toutes les options possibles
- Avec certaines configurations, **Shift+Tab** permet de revenir en arrière dans les suggestions

### 2. Créez des snippets pour vos commandes fréquentes

Dans votre profil PowerShell, créez des fonctions courtes pour les commandes que vous utilisez souvent:

```powershell
function ll { Get-ChildItem | Format-Table -Property Mode, LastWriteTime, Length, Name }
function up { Set-Location .. }
function grep { param($pattern, $file) Get-Content $file | Where-Object { $_ -match $pattern } }
```

### 3. Utilisez F7 pour visualiser l'historique

La touche **F7** affiche une fenêtre avec votre historique de commandes. Utilisez les flèches pour naviguer et **Entrée** pour exécuter la commande sélectionnée.

## Exercices pratiques

### Exercice 1: Configuration de base
1. Ouvrez votre profil PowerShell (`code $PROFILE`)
2. Ajoutez la configuration pour la recherche intelligente dans l'historique
3. Rechargez votre profil (`. $PROFILE`)
4. Testez la recherche en tapant le début d'une commande et en utilisant la flèche haut

### Exercice 2: Exploration des raccourcis
1. Essayez chacun des raccourcis clavier mentionnés dans ce guide
2. Identifiez les 5 raccourcis que vous trouvez les plus utiles
3. Créez un aide-mémoire pour ces raccourcis (par exemple, écrivez-les sur un post-it)

### Exercice 3: Personnalisation avancée
1. Configurez la prédiction basée sur l'historique (PowerShell 7.1+)
2. Personnalisez la coloration syntaxique selon vos préférences
3. Ajoutez la persistance de l'historique à votre profil

## Points clés à retenir

1. **L'historique des commandes** vous permet de réutiliser des commandes précédentes sans les retaper
2. **PSReadLine** améliore considérablement l'expérience de ligne de commande
3. La **recherche intelligente** dans l'historique avec les flèches est indispensable
4. **Les raccourcis clavier** augmentent significativement votre productivité
5. En **personnalisant votre profil**, vous adaptez PowerShell à votre style de travail

## Dépannage

### "PSReadLine n'est pas reconnu"
Installez ou mettez à jour le module:
```powershell
Install-Module -Name PSReadLine -Force
```

### "Les flèches haut/bas ne fonctionnent pas comme prévu"
Vérifiez votre configuration avec:
```powershell
Get-PSReadLineKeyHandler | Where-Object Function -match "History"
```

### "L'historique ne persiste pas entre les sessions"
Assurez-vous que votre configuration de `HistorySavePath` est correcte et que le chemin existe.

---

Dans la prochaine section, nous explorerons les modules PowerShell utiles qui peuvent encore plus améliorer votre productivité!
