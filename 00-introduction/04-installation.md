# Module 1-4: Installation (Windows, Linux, macOS)

## Installation de PowerShell sur différentes plateformes

Une des grandes forces de PowerShell moderne est sa disponibilité sur plusieurs systèmes d'exploitation. Ce guide vous expliquera comment installer PowerShell sur Windows, Linux et macOS de façon simple et accessible.

## 📋 Prérequis généraux

- Une connexion internet stable
- Droits d'administrateur sur votre machine
- Espace disque disponible (environ 200 Mo)

## 🪟 Installation sur Windows

Windows dispose déjà de Windows PowerShell 5.1 préinstallé, mais nous allons installer PowerShell 7+ pour bénéficier des dernières fonctionnalités.

### Méthode 1: Installation via le Microsoft Store (recommandée pour débutants)

1. Ouvrez le **Microsoft Store** depuis le menu Démarrer
2. Recherchez "PowerShell"
3. Sélectionnez "PowerShell" (celui avec le logo bleu) développé par Microsoft
4. Cliquez sur **Installer**
5. Une fois l'installation terminée, vous pouvez lancer PowerShell depuis le menu Démarrer

![Capture d'écran du Microsoft Store montrant PowerShell](https://i0.wp.com/learn.microsoft.com/en-us/powershell/media/installing-powershell/pwsh-in-ms-store.png?w=420)

### Méthode 2: Installation via le programme d'installation MSI

1. Visitez la [page de téléchargement PowerShell sur GitHub](https://github.com/PowerShell/PowerShell/releases)
2. Choisissez la dernière version stable (par exemple "PowerShell-7.4.0-win-x64.msi")
3. Téléchargez et exécutez le fichier MSI
4. Suivez les instructions à l'écran pour compléter l'installation

### Comment vérifier l'installation sur Windows

1. Ouvrez PowerShell depuis le menu Démarrer
2. Tapez la commande suivante et appuyez sur Entrée:

```powershell
$PSVersionTable
```

Vous devriez voir un résultat similaire à ceci:

```
Name                           Value
----                           -----
PSVersion                      7.4.0
PSEdition                      Core
GitCommitId                    7.4.0
OS                             Microsoft Windows 10.0.19045
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
...
```

Si vous voyez un numéro de version commençant par 7, l'installation a réussi!

### Coexistence avec Windows PowerShell 5.1

- PowerShell 7+ et Windows PowerShell 5.1 peuvent coexister sans problème
- Pour lancer spécifiquement PowerShell 7+, utilisez le raccourci "PowerShell 7" dans le menu Démarrer
- Pour lancer Windows PowerShell 5.1, utilisez l'ancien raccourci "Windows PowerShell"

## 🐧 Installation sur Linux

PowerShell peut être installé sur la plupart des distributions Linux. Voici les instructions pour les plus populaires:

### Ubuntu/Debian

1. Ouvrez un terminal
2. Mettez à jour les packages:

```bash
sudo apt update
```

3. Installez les prérequis:

```bash
sudo apt install -y wget apt-transport-https software-properties-common
```

4. Téléchargez et enregistrez la clef Microsoft:

```bash
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
```

5. Mettez à jour les sources et installez PowerShell:

```bash
sudo apt update
sudo apt install -y powershell
```

### Fedora/CentOS/RHEL

1. Ouvrez un terminal
2. Enregistrez le dépôt Microsoft:

```bash
# Pour Fedora
sudo rpm -Uvh https://packages.microsoft.com/config/fedora/$(rpm -E %fedora)/packages-microsoft-prod.rpm

# Pour CentOS/RHEL
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/$(rpm -E %rhel)/packages-microsoft-prod.rpm
```

3. Installez PowerShell:

```bash
# Pour Fedora
sudo dnf install powershell

# Pour CentOS/RHEL
sudo yum install powershell
```

### Comment vérifier l'installation sur Linux

1. Dans votre terminal, lancez PowerShell:

```bash
pwsh
```

2. Vérifiez la version:

```powershell
$PSVersionTable
```

## 🍎 Installation sur macOS

PowerShell fonctionne très bien sur macOS, et l'installation est simple.

### Installation via Homebrew (recommandée)

1. Si vous n'avez pas Homebrew, installez-le d'abord:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Installez PowerShell avec Homebrew:

```bash
brew install --cask powershell
```

### Installation manuelle

1. Visitez la [page de téléchargement PowerShell sur GitHub](https://github.com/PowerShell/PowerShell/releases)
2. Téléchargez le fichier PKG pour macOS (par exemple "powershell-7.4.0-osx-x64.pkg")
3. Double-cliquez sur le fichier PKG et suivez les instructions d'installation

### Comment vérifier l'installation sur macOS

1. Ouvrez l'application Terminal
2. Lancez PowerShell:

```bash
pwsh
```

3. Vérifiez la version:

```powershell
$PSVersionTable
```

## 🔍 Résolution des problèmes courants

### La commande pwsh n'est pas reconnue

**Solution**: Assurez-vous que le dossier d'installation est dans votre PATH système.

- Sur Windows: Vérifiez dans les "Variables d'environnement" du Panneau de configuration
- Sur Linux/macOS: Exécutez `echo $PATH` pour vérifier

### Erreurs de dépendances sur Linux

**Solution**: Assurez-vous d'avoir toutes les dépendances nécessaires:

```bash
# Sur Ubuntu/Debian
sudo apt install -y libc6 libgcc1 libgssapi-krb5-2 libstdc++6 libunwind8 libuuid1 zlib1g libicu66

# Les numéros de version peuvent varier selon votre distribution
```

### Problèmes d'exécution sur macOS

**Solution**: Vous pourriez devoir autoriser l'exécution:

```bash
sudo chmod +x /usr/local/microsoft/powershell/7/pwsh
```

## 📝 Configuration recommandée pour les débutants

### Éditeurs de code recommandés

1. **VS Code** (recommandé):
   - Téléchargez et installez [Visual Studio Code](https://code.visualstudio.com/)
   - Installez l'extension "PowerShell" depuis le marketplace de VS Code

2. **PowerShell ISE** (Windows uniquement, pour Windows PowerShell 5.1):
   - Déjà installé sur Windows
   - Tapez "ISE" dans le menu Démarrer pour le trouver

## 🎓 Test de votre installation

Pour confirmer que tout fonctionne correctement, exécutez ce simple script dans PowerShell:

```powershell
# Création d'une variable
$message = "Félicitations! PowerShell est correctement installé!"

# Affichage avec une couleur
Write-Host $message -ForegroundColor Green

# Information système
Write-Host "Votre version de PowerShell est:" -NoNewline
Write-Host " $($PSVersionTable.PSVersion)" -ForegroundColor Cyan

# Date et heure
Write-Host "Date et heure actuelles: $(Get-Date)"
```

## 📚 Ressources supplémentaires

- [Documentation officielle d'installation PowerShell](https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell)
- [GitHub PowerShell](https://github.com/PowerShell/PowerShell)
- [Forum PowerShell](https://forums.powershell.org/)

---

Dans le prochain module, nous découvrirons l'interface de PowerShell et comment utiliser VS Code avec PowerShell.
