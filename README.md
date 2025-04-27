# 🧠 Formation PowerShell – Du Débutant à l'Expert

![PowerShell Logo](https://raw.githubusercontent.com/PowerShell/PowerShell/master/assets/ps_black_64.svg)

## 📋 Présentation

Bienvenue dans cette formation complète sur PowerShell, conçue pour vous accompagner pas à pas depuis les concepts fondamentaux jusqu'aux techniques avancées utilisées par les experts. Que vous soyez administrateur système, développeur, ou simplement curieux d'apprendre un langage puissant d'automatisation, cette formation vous fournira les compétences nécessaires pour maîtriser PowerShell.

## 🎯 Objectifs de la formation

- Comprendre les concepts fondamentaux de PowerShell
- Maîtriser la syntaxe et les structures de base
- Développer des scripts robustes et performants
- Automatiser les tâches d'administration système
- Manipuler efficacement les données et objets
- Intégrer PowerShell avec des services cloud et des API
- Adopter les bonnes pratiques professionnelles

## 📚 Structure du cours

La formation est divisée en 16 modules progressifs, chacun se concentrant sur des aspects spécifiques de PowerShell :

### 🟦 Module 1 – Introduction à PowerShell
Découverte de l'environnement PowerShell, son histoire et ses différences avec d'autres shells.

### 🟦 Module 2 – Environnement de travail et personnalisation
Configuration de votre environnement pour une productivité optimale.

### 🟦 Module 3 – Syntaxe et fondamentaux
Apprentissage des bases du langage : cmdlets, variables, opérateurs et structures de contrôle.

### 🟦 Module 4 – Objets et traitement de données
Exploration du modèle objet de PowerShell et manipulation avancée des données.

### 🟦 Module 5 – Gestion des fichiers et du système
Opérations sur les fichiers, dossiers et manipulation du système.

### 🟦 Module 6 – Fonctions, modules et structuration
Création de composants réutilisables et organisation du code.

### 🟦 Module 7 – Gestion des erreurs et debug
Techniques pour gérer les exceptions et déboguer efficacement vos scripts.

### 🟦 Module 8 – Jobs, tâches planifiées et parallélisme
Exécution de tâches en arrière-plan et optimisation des performances.

### 🟦 Module 9 – Administration Windows
Gestion des composants Windows via PowerShell.

### 🟦 Module 10 – Active Directory & LDAP
Automatisation des tâches d'administration Active Directory.

### 🟦 Module 11 – Réseau & Sécurité
Configuration et diagnostic réseau, gestion de la sécurité.

### 🟦 Module 12 – API, Web & Cloud
Interaction avec des services web et cloud modernes.

### 🟦 Module 13 – Tests, CI/CD et DevOps
Intégration de PowerShell dans les workflows DevOps.

### 🟦 Module 14 – Performance et optimisation
Techniques pour améliorer les performances de vos scripts.

### 🟦 Module 15 – Architecture & design de scripts pro
Conception avancée pour des projets PowerShell à grande échelle.

### 🟨 Module 16 – Annexes et bonus
Ressources supplémentaires, exercices pratiques et projets.

## 🛠️ Prérequis

- Système d'exploitation Windows, Linux ou macOS
- PowerShell 5.1 ou PowerShell 7+ installé
- Éditeur de code (Visual Studio Code recommandé avec l'extension PowerShell)
- Connaissances de base en informatique

## ⚡ Installation rapide

### Windows
```powershell
# PowerShell est préinstallé, mais pour obtenir la dernière version :
winget install Microsoft.PowerShell
```

### Linux (Ubuntu/Debian)
```bash
# Installer PowerShell 7
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
wget -q "https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb"
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
```

### macOS
```bash
# Avec Homebrew
brew install --cask powershell
```

## 🚀 Comment utiliser cette formation

1. Clonez ce dépôt sur votre machine locale
   ```
   git clone https://github.com/NDXDeveloper/powershell-formation.git
   ```
2. Parcourez les modules dans l'ordre suggéré
3. Chaque module contient:
   - Des explications théoriques
   - Des exemples de code
   - Des exercices pratiques
   - Des quiz pour tester vos connaissances

## 📋 Table des matières détaillée

<details>
<summary>Cliquez pour afficher la table des matières complète</summary>

### 🟦 **Module 1 – Introduction à PowerShell**

1-1. Qu'est-ce que PowerShell ?
1-2. PowerShell vs Bash / CMD / VBScript
1-3. Historique et versions (Windows PowerShell, PowerShell 7+)
1-4. Installation (Windows, Linux, macOS)
1-5. Découverte de la console PowerShell et VS Code
1-6. Utilisation de l'aide intégrée (`Get-Help`, `Get-Command`, `Get-Member`)

### 🟦 **Module 2 – Environnement de travail et personnalisation**

2-1. Fichier de profil (`$PROFILE`)
2-2. Customisation du prompt (oh-my-posh, PSReadLine)
2-3. Historique de commandes et raccourcis clavier
2-4. Modules utiles (PSReadLine, posh-git, Terminal-Icons, etc.)
2-5. Découverte de la PowerShell Gallery

### 🟦 **Module 3 – Syntaxe et fondamentaux**

3-1. Cmdlets, alias et pipeline
3-2. Variables, typage, tableaux, hashtables
3-3. Opérateurs (logiques, arithmétiques, comparaison)
3-4. Structures de contrôle (`if`, `switch`, `for`, `foreach`, `while`)
3-5. Expressions régulières et filtrage
3-6. Scripting : premiers scripts `.ps1`

### 🟦 **Module 4 – Objets et traitement de données**

4-1. Le modèle objet PowerShell
4-2. Manipulation des objets (`Select-Object`, `Where-Object`, `Sort-Object`)
4-3. Création d'objets personnalisés (`[PSCustomObject]`)
4-4. Groupement, agrégation (`Group-Object`, `Measure-Object`)
4-5. Export de données (CSV, JSON, XML)

### 🟦 **Module 5 – Gestion des fichiers et du système**

5-1. Fichiers, dossiers, chemins (`Get-Item`, `Get-ChildItem`, etc.)
5-2. Lecture/écriture de fichiers (TXT, CSV, JSON, XML)
5-3. Gestion des permissions NTFS
5-4. Compression, archivage et extraction
5-5. Dates et temps (`Get-Date`, manipulation des TimeSpan)

### 🟦 **Module 6 – Fonctions, modules et structuration**

6-1. Création de fonctions et paramètres
6-2. Validation des paramètres (`[ValidateNotNullOrEmpty]`, etc.)
6-3. Scripts, modules (`.ps1`, `.psm1`), manifestes
6-4. Portée des variables et scopes
6-5. Meilleures pratiques de structuration et nommage

### 🟦 **Module 7 – Gestion des erreurs et debug**

7-1. `try/catch/finally`, `throw`, `Write-Error`
7-2. `$?`, `$LASTEXITCODE`, `$ErrorActionPreference`
7-3. Débogage avec VS Code (`Set-PSBreakpoint`, etc.)
7-4. Journaux d'exécution (`Start-Transcript`)
7-5. Gestion des exceptions réseau, fichiers, API

### 🟦 **Module 8 – Jobs, tâches planifiées et parallélisme**

8-1. Jobs (`Start-Job`, `Receive-Job`, `Remove-Job`)
8-2. Runspaces & ForEach-Object -Parallel (PowerShell 7+)
8-3. Planification via le Planificateur de tâches Windows
8-4. Création de services de fond en PowerShell
8-5. Monitoring de scripts longue durée

### 🟦 **Module 9 – Administration Windows**

9-1. Services, processus, registre, événements
9-2. WMI vs CIM (`Get-CimInstance`, `Invoke-CimMethod`)
9-3. Gestion des disques, partitions, volumes
9-4. Interrogation du matériel (RAM, CPU, etc.)
9-5. Gestion des utilisateurs et groupes locaux

### 🟦 **Module 10 – Active Directory & LDAP**

10-1. Module RSAT et importation (`Import-Module ActiveDirectory`)
10-2. Requêtes sur les utilisateurs, groupes, ordinateurs
10-3. Création, modification, suppression d'objets AD
10-4. Utilisation de filtres LDAP
10-5. Audit de l'environnement AD (dernière connexion, comptes inactifs)

### 🟦 **Module 11 – Réseau & Sécurité**

11-1. Cmdlets réseau : `Test-Connection`, `Test-NetConnection`, `Resolve-DnsName`
11-2. Découverte réseau (scan, ports, ping, IP)
11-3. Firewall, pare-feu, et règles Windows Defender
11-4. Gestion des certificats
11-5. Sécurité des scripts : droits, exécution, sessions à privilèges

### 🟦 **Module 12 – API, Web & Cloud**

12-1. `Invoke-WebRequest` vs `Invoke-RestMethod`
12-2. Authentification (Basic, Bearer, Token)
12-3. Consommer une API REST, envoyer du JSON
12-4. Appels vers GitHub, Azure, Teams, etc.
12-5. Introduction à PowerShell + Azure / AWS / Google Cloud

### 🟦 **Module 13 – Tests, CI/CD et DevOps**

13-1. Introduction à Pester (tests unitaires)
13-2. PowerShell + Git
13-3. Scripts dans les pipelines (Azure DevOps, GitHub Actions)
13-4. Linting et validation automatique
13-5. Publication de modules (PSGallery)

### 🟦 **Module 14 – Performance et optimisation**

14-1. Profilage (`Measure-Command`, Stopwatch)
14-2. Pipeline vs Boucles
14-3. Techniques d'optimisation (filtrage natif, évitement de WMI)
14-4. Éviter les ralentissements courants
14-5. Chargement conditionnel de modules

### 🟦 **Module 15 – Architecture & design de scripts pro**

15-1. Organisation de projets PowerShell
15-2. Séparation logique (orchestration vs logique métier)
15-3. Gestion de la configuration externe (JSON, ENV, INI)
15-4. Structuration modulaire avancée
15-5. Documentation de scripts et fonctions (`.SYNOPSIS`, `.EXAMPLE`, etc.)

### 🟨 **Module 16 – Annexes et bonus**

16-1. Mini-projets (inventaire réseau, backup automatique, API weather, etc.)
16-2. Modèles de scripts prêts à l'emploi
16-3. Quiz et exercices corrigés par niveau
16-4. Outils complémentaires (ISE, VS Code, Terminal Windows)
16-5. Glossaire PowerShell & liens utiles
</details>

## 📊 Progression suggérée

Cette formation est conçue pour être suivie de manière progressive, mais vous pouvez adapter votre parcours selon vos besoins :

- **Débutant** : Modules 1 à 6
- **Intermédiaire** : Modules 7 à 11
- **Avancé** : Modules 12 à 15
- **Bonus et projets pratiques** : Module 16

## 📝 License

Ce projet est sous licence [GNU General Public License v3.0](LICENSE).

## 👨‍💻 Auteur

**Nicolas DEOUX**
📧 Email: [NDXDev@gmail.com](mailto:NDXDev@gmail.com)
🔗 LinkedIn: [https://www.linkedin.com/in/nicolas-deoux-ab295980/](https://www.linkedin.com/in/nicolas-deoux-ab295980/)
🌐 GitHub: [https://github.com/NDXDeveloper/powershell-formation](https://github.com/NDXDeveloper/powershell-formation)
