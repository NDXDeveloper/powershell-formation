# Module 1-5: Découverte de la console PowerShell et VS Code

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Prise en main de l'environnement PowerShell

Maintenant que vous avez installé PowerShell, il est temps de découvrir comment l'utiliser efficacement. Dans ce module, nous explorerons deux façons principales d'interagir avec PowerShell : via la console (terminal) et avec Visual Studio Code (VS Code).

## 🖥️ La console PowerShell

### Lancement de la console PowerShell

**Sur Windows :**
- Cliquez sur le menu Démarrer
- Tapez "PowerShell"
- Sélectionnez "PowerShell 7" (ou "Windows PowerShell" si vous utilisez la version 5.1)

**Sur macOS/Linux :**
- Ouvrez l'application Terminal
- Tapez `pwsh` et appuyez sur Entrée

### Découverte de l'interface

Une fois la console PowerShell ouverte, vous verrez quelque chose comme ceci :

```
PowerShell 7.4.0
Copyright (c) Microsoft Corporation.

https://aka.ms/powershell
Type 'help' to get help.

PS C:\Users\VotreNom>
```

Expliquons les éléments principaux :

1. **L'invite de commande (prompt)** : C'est la partie qui indique où vous vous trouvez dans le système de fichiers.
   - Par défaut : `PS C:\Users\VotreNom>`
   - "PS" indique que vous êtes dans PowerShell
   - Le texte après est votre position actuelle dans l'arborescence des fichiers

2. **Le curseur clignotant** : Il indique où votre texte sera saisi

### Premiers pas dans la console

Essayons quelques commandes simples :

1. **Afficher la date et l'heure** :
```powershell
Get-Date
```

2. **Voir la version de PowerShell** :
```powershell
$PSVersionTable
```

3. **Afficher le contenu du répertoire actuel** :
```powershell
Get-ChildItem
# Ou utilisez l'alias plus court
dir
```

4. **Créer un nouveau dossier** :
```powershell
New-Item -ItemType Directory -Name "MonDossierPowerShell"
```

5. **Effacer l'écran** :
```powershell
Clear-Host
# Ou utilisez l'alias plus court
cls
```

### Navigation et utilisation de base

- **Flèches ↑/↓** : Parcourir l'historique des commandes
- **Tab** : Complétion automatique des commandes, noms de fichiers, etc.
- **Ctrl+C** : Interrompre une commande en cours d'exécution
- **F7** : Afficher une liste des commandes précédentes dans une fenêtre
- **Ctrl+L** : Effacer l'écran (alternative à `cls`)

### Copier/Coller dans la console

- **Copier** : Sélectionnez le texte avec la souris puis appuyez sur **Ctrl+C**
- **Coller** :
  - Windows : Clic droit ou **Ctrl+V**
  - Linux/macOS : Clic droit ou **Cmd+V** (macOS) / **Ctrl+Shift+V** (Linux)

### Personnalisation rapide de la console

Vous pouvez changer les couleurs et la taille de la fenêtre :

1. **Changer la couleur du texte** :
```powershell
Write-Host "Texte en couleur!" -ForegroundColor Green
```

2. **Modifier le titre de la fenêtre** :
```powershell
$host.UI.RawUI.WindowTitle = "Ma console PowerShell"
```

## 🧩 Visual Studio Code (VS Code)

VS Code est un éditeur de code gratuit et puissant qui offre une excellente expérience pour travailler avec PowerShell.

### Installation de VS Code et de l'extension PowerShell

1. Téléchargez et installez VS Code depuis [code.visualstudio.com](https://code.visualstudio.com/)
2. Lancez VS Code
3. Ouvrez la vue Extensions (Ctrl+Shift+X ou cliquez sur l'icône des extensions dans la barre latérale)
4. Recherchez "PowerShell" et installez l'extension créée par Microsoft

![Installation de l'extension PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/media/using-vscode/vscode.png)

### Création d'un premier script PowerShell

1. Dans VS Code, cliquez sur **Fichier** > **Nouveau fichier**
2. Sauvegardez-le avec l'extension `.ps1` (par exemple `MonPremierScript.ps1`)
3. Écrivons un script simple :

```powershell
# Mon premier script PowerShell
Write-Host "Bonjour depuis PowerShell!" -ForegroundColor Blue
$date = Get-Date
Write-Host "Aujourd'hui nous sommes le $date" -ForegroundColor Green

# Obtenir des informations système
$osInfo = Get-CimInstance Win32_OperatingSystem
Write-Host "Vous utilisez $($osInfo.Caption)" -ForegroundColor Yellow

# Pause pour voir les résultats
Write-Host "Appuyez sur une touche pour fermer..." -ForegroundColor Cyan
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
```

### Exécution d'un script dans VS Code

Il existe plusieurs façons d'exécuter votre script :

1. **Exécuter le script entier** :
   - Appuyez sur **F5** ou cliquez sur le bouton "Play" en haut à droite de l'éditeur

2. **Exécuter une sélection** :
   - Sélectionnez une portion du code
   - Appuyez sur **F8** pour exécuter uniquement cette sélection

3. **Dans un terminal intégré** :
   - Ouvrez le terminal intégré avec **Ctrl+`** (accent grave)
   - Naviguez jusqu'au dossier où se trouve votre script
   - Tapez `.\MonPremierScript.ps1` pour l'exécuter

### Fonctionnalités utiles de VS Code pour PowerShell

1. **IntelliSense** : Suggestions automatiques pendant que vous tapez
   ![PowerShell IntelliSense](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/media/using-vscode/intellisense.png)

2. **Navigation dans le code** : Cliquez sur une fonction ou variable tout en maintenant **Ctrl** enfoncé pour voir sa définition

3. **Débogage** : Placez des points d'arrêt en cliquant dans la marge à gauche d'une ligne, puis exécutez avec **F5**

4. **Coloration syntaxique** : VS Code colore automatiquement les différentes parties de votre code pour une meilleure lisibilité

5. **Explorateur de variables** : Pendant le débogage, vous pouvez voir et explorer toutes les variables

### Conseils pour débutants dans VS Code

1. **Terminal intégré** : Utilisez le terminal intégré (Ctrl+`) pour tester des commandes rapidement

2. **Panneaux multiples** : Vous pouvez diviser l'éditeur pour voir plusieurs fichiers côte à côte

3. **Explorateur de fichiers** : Le panneau gauche vous permet de naviguer facilement entre vos fichiers

4. **Problèmes et erreurs** : VS Code souligne les problèmes potentiels dans votre code

5. **Paramètres de personnalisation** : Accédez aux paramètres (Ctrl+,) pour personnaliser votre expérience

## 📋 Comparaison console vs VS Code

| Fonction | Console PowerShell | VS Code |
|----------|-------------------|---------|
| Exécution rapide de commandes | ✓✓✓ (Excellent) | ✓✓ (Bon) |
| Édition de scripts complexes | ✗ (Limité) | ✓✓✓ (Excellent) |
| Débogage | ✓ (Basique) | ✓✓✓ (Avancé) |
| Facilité d'utilisation pour débutants | ✓✓ (Simple) | ✓ (Plus complexe) |
| IntelliSense | ✓ (Basique) | ✓✓✓ (Complet) |

## 🛠️ Exercices pratiques

### Exercice 1 : Familiarisation avec la console

1. Ouvrez la console PowerShell
2. Utilisez `Get-Process` pour voir tous les processus en cours
3. Utilisez `Sort-Object` pour les trier par utilisation mémoire : `Get-Process | Sort-Object -Property WorkingSet -Descending`
4. Utilisez `Select-Object` pour n'afficher que les 5 premiers : `Get-Process | Sort-Object -Property WorkingSet -Descending | Select-Object -First 5`

### Exercice 2 : Premier script dans VS Code

1. Créez un nouveau fichier dans VS Code et enregistrez-le sous le nom `InfoSysteme.ps1`
2. Écrivez un script qui collecte et affiche :
   - Le nom de l'ordinateur
   - La version de Windows/OS
   - L'espace disque disponible
   - La quantité de mémoire RAM
3. Exécutez le script et observez les résultats

### Exercice 3 : Personnalisation de l'environnement

1. Dans VS Code, modifiez la taille de police (Ctrl+, puis cherchez "font size")
2. Essayez différents thèmes de couleurs (Ctrl+K Ctrl+T)
3. Dans la console PowerShell, essayez de changer la couleur d'arrière-plan et de texte

## 📚 Conclusion

Vous avez maintenant découvert les deux principaux environnements pour travailler avec PowerShell :

- La **console PowerShell** est idéale pour des commandes rapides et des tests
- **VS Code** est parfait pour créer, tester et déboguer des scripts plus complexes

Au fur et à mesure que vous progresserez, vous apprendrez à combiner ces deux outils pour tirer le meilleur parti de PowerShell. N'hésitez pas à explorer et expérimenter avec ces environnements !

Dans le prochain module, nous découvrirons comment utiliser l'aide intégrée de PowerShell pour apprendre et maîtriser ses commandes.
