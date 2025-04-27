## 🧠 Formation PowerShell – Du Débutant à l'Expert

### 🟦 [Module 1 – Introduction à PowerShell](00-introduction/README.md)

1-1. [Qu'est-ce que PowerShell ?](00-introduction/01-quest-ce-que-powershell.md)
1-2. [PowerShell vs Bash / CMD / VBScript](00-introduction/02-comparaison-cmd-bash.md)
1-3. [Historique et versions (Windows PowerShell, PowerShell 7+)](00-introduction/03-historique-et-versions.md)
1-4. [Installation (Windows, Linux, macOS)](00-introduction/04-installation.md)
1-5. [Découverte de la console PowerShell et VS Code](00-introduction/05-interface-console-vscode.md)
1-6. [Utilisation de l'aide intégrée (`Get-Help`, `Get-Command`, `Get-Member`)](00-introduction/06-utilisation-aide-integrée.md)

### 🟦 [Module 2 – Environnement de travail et personnalisation](01-environnement/README.md)

- 2-1. [Fichier de profil (`$PROFILE`)](01-environnement/01-profil.md)
- 2-2. [Customisation du prompt (oh-my-posh, PSReadLine)](01-environnement/02-customisation-prompt.md)
- 2-3. [Historique de commandes et raccourcis clavier](01-environnement/03-historique-et-raccourcis.md)
- 2-4. [Modules utiles (PSReadLine, posh-git, Terminal-Icons, etc.)](01-environnement/04-modules-utiles.md)
- 2-5. [Découverte de la PowerShell Gallery](01-environnement/05-powershell-gallery.md)

### 🟦 [Module 3 – Syntaxe et fondamentaux](02-syntaxe-fondamentaux/README.md)

3-1. [Cmdlets, alias et pipeline](02-syntaxe-fondamentaux/01-cmdlets-alias-pipeline.md)
3-2. [Variables, typage, tableaux, hashtables](02-syntaxe-fondamentaux/02-variables-et-collections.md)
3-3. [Opérateurs (logiques, arithmétiques, comparaison)](02-syntaxe-fondamentaux/03-operateurs.md)
3-4. [Structures de contrôle (`if`, `switch`, `for`, `foreach`, `while`)](02-syntaxe-fondamentaux/04-structures-controle.md)
3-5. [Expressions régulières et filtrage](02-syntaxe-fondamentaux/05-regex-filtrage.md)
3-6. [Scripting : premiers scripts `.ps1`](02-syntaxe-fondamentaux/06-premiers-scripts.md)

### 🟦 [Module 4 – Objets et traitement de données](03-objets-donnees/README.md)

4-1. [Le modèle objet PowerShell](03-objets-donnees/01-modele-objet.md)
4-2. [Manipulation des objets (`Select-Object`, `Where-Object`, `Sort-Object`)](03-objets-donnees/02-manipulation-objets.md)
4-3. [Création d'objets personnalisés (`[PSCustomObject]`)](03-objets-donnees/03-objets-custom.md)
4-4. [Groupement, agrégation (`Group-Object`, `Measure-Object`)](03-objets-donnees/04-groupement-aggregation.md)
4-5. [Export de données (CSV, JSON, XML)](03-objets-donnees/05-export-donnees.md)

### 🟦 [Module 5 – Gestion des fichiers et du système](04-systeme-fichiers/README.md)

5-1. [Fichiers, dossiers, chemins (`Get-Item`, `Get-ChildItem`, etc.)](04-systeme-fichiers/01-fichiers-dossiers.md)
5-2. [Lecture/écriture de fichiers (TXT, CSV, JSON, XML)](04-systeme-fichiers/02-lecture-ecriture.md)
5-3. [Gestion des permissions NTFS](04-systeme-fichiers/03-droits-ntfs.md)
5-4. [Compression, archivage et extraction](04-systeme-fichiers/04-compression-archivage.md)
5-5. [Dates et temps (`Get-Date`, manipulation des TimeSpan)](04-systeme-fichiers/05-gestion-dates.md)

### 🟦 [Module 6 – Fonctions, modules et structuration](05-fonctions-modules/README.md)

6-1. [Création de fonctions et paramètres](05-fonctions-modules/01-fonctions-et-parametres.md)
6-2. [Validation des paramètres (`[ValidateNotNullOrEmpty]`, etc.)](05-fonctions-modules/02-validation.md)
6-3. [Scripts, modules (`.ps1`, `.psm1`), manifestes](05-fonctions-modules/03-modules-et-manifestes.md)
6-4. [Portée des variables et scopes](05-fonctions-modules/04-portee.md)
6-5. [Meilleures pratiques de structuration et nommage](05-fonctions-modules/05-bonnes-pratiques.md)

### 🟦 [Module 7 – Gestion des erreurs et debug](06-erreurs-debug/README.md)

7-1. [`try/catch/finally`, `throw`, `Write-Error`](06-erreurs-debug/01-gestion-erreurs.md)
7-2. [`$?`, `$LASTEXITCODE`, `$ErrorActionPreference`](06-erreurs-debug/02-variables-erreurs.md)
7-3. [Débogage avec VS Code (`Set-PSBreakpoint`, etc.)](06-erreurs-debug/03-debug-vscode.md)
7-4. [Journaux d'exécution (`Start-Transcript`)](06-erreurs-debug/04-logs-transcripts.md)
7-5. [Gestion des exceptions réseau, fichiers, API](06-erreurs-debug/05-erreurs-api-reseau.md)

### 🟦 [Module 8 – Jobs, tâches planifiées et parallélisme](07-jobs-taches/README.md)

8-1. [Jobs (`Start-Job`, `Receive-Job`, `Remove-Job`)](07-jobs-taches/01-jobs.md)
8-2. [Runspaces & ForEach-Object -Parallel (PowerShell 7+)](07-jobs-taches/02-runspaces-parallel.md)
8-3. [Planification via le Planificateur de tâches Windows](07-jobs-taches/03-planification.md)
8-4. [Création de services de fond en PowerShell](07-jobs-taches/04-services-fond.md)
8-5. [Monitoring de scripts longue durée](07-jobs-taches/05-monitoring.md)

### 🟦 [Module 9 – Administration Windows](08-administration-windows/README.md)

9-1. [Services, processus, registre, événements](08-administration-windows/01-processus-services.md)
9-2. [WMI vs CIM (`Get-CimInstance`, `Invoke-CimMethod`)](08-administration-windows/02-wmi-vs-cim.md)
9-3. [Gestion des disques, partitions, volumes](08-administration-windows/03-disques-volumes.md)
9-4. [Interrogation du matériel (RAM, CPU, etc.)](08-administration-windows/04-hardware-info.md)
9-5. [Gestion des utilisateurs et groupes locaux](08-administration-windows/05-utilisateurs-locaux.md)

### 🟦 [Module 10 – Active Directory & LDAP](09-active-directory/README.md)

10-1. [Module RSAT et importation (`Import-Module ActiveDirectory`)](09-active-directory/01-rsat.md)
10-2. [Requêtes sur les utilisateurs, groupes, ordinateurs](09-active-directory/02-requetes-objets.md)
10-3. [Création, modification, suppression d'objets AD](09-active-directory/03-gestion-utilisateurs-groupes.md)
10-4. [Utilisation de filtres LDAP](09-active-directory/04-filtres-ldap.md)
10-5. [Audit de l'environnement AD (dernière connexion, comptes inactifs)](09-active-directory/05-audit-ad.md)

### 🟦 [Module 11 – Réseau & Sécurité](10-reseau-securite/README.md)

11-1. [Cmdlets réseau : `Test-Connection`, `Test-NetConnection`, `Resolve-DnsName`](10-reseau-securite/01-cmdlets-reseau.md)
11-2. [Découverte réseau (scan, ports, ping, IP)](10-reseau-securite/02-decouverte-reseau.md)
11-3. [Firewall, pare-feu, et règles Windows Defender](10-reseau-securite/03-firewall-defender.md)
11-4. [Gestion des certificats](10-reseau-securite/04-certificats.md)
11-5. [Sécurité des scripts : droits, exécution, sessions à privilèges](10-reseau-securite/05-securite-scripts.md)

### 🟦 [Module 12 – API, Web & Cloud](11-api-cloud/README.md)

12-1. [`Invoke-WebRequest` vs `Invoke-RestMethod`](11-api-cloud/01-webrequest-restmethod.md)
12-2. [Authentification (Basic, Bearer, Token)](11-api-cloud/02-authentification.md)
12-3. [Consommer une API REST, envoyer du JSON](11-api-cloud/03-consommer-api.md)
12-4. [Appels vers GitHub, Azure, Teams, etc.](11-api-cloud/04-api-externes.md)
12-5. [Introduction à PowerShell + Azure / AWS / Google Cloud](11-api-cloud/05-cloud-intro.md)

### 🟦 [Module 13 – Tests, CI/CD et DevOps](12-ci-cd-tests/README.md)

13-1. [Introduction à Pester (tests unitaires)](12-ci-cd-tests/01-pester-tests.md)
13-2. [PowerShell + Git](12-ci-cd-tests/02-git-integration.md)
13-3. [Scripts dans les pipelines (Azure DevOps, GitHub Actions)](12-ci-cd-tests/03-azure-devops.md)
13-4. [Linting et validation automatique](12-ci-cd-tests/04-linting.md)
13-5. [Publication de modules (PSGallery)](12-ci-cd-tests/05-publishing-modules.md)

### 🟦 [Module 14 – Performance et optimisation](13-optimisation/README.md)

14-1. [Profilage (`Measure-Command`, Stopwatch)](13-optimisation/01-profilage.md)
14-2. [Pipeline vs Boucles](13-optimisation/02-pipeline-vs-boucles.md)
14-3. [Techniques d'optimisation (filtrage natif, évitement de WMI)](13-optimisation/03-techniques.md)
14-4. [Éviter les ralentissements courants](13-optimisation/04-ralentissements.md)
14-5. [Chargement conditionnel de modules](13-optimisation/05-chargement-conditionnel.md)

### 🟦 [Module 15 – Architecture & design de scripts pro](14-architecture/README.md)

15-1. [Organisation de projets PowerShell](14-architecture/01-structure-projet.md)
15-2. [Séparation logique (orchestration vs logique métier)](14-architecture/02-orchestration.md)
15-3. [Gestion de la configuration externe (JSON, ENV, INI)](14-architecture/03-configuration-externe.md)
15-4. [Structuration modulaire avancée](14-architecture/04-structure-modulaire.md)
15-5. [Documentation de scripts et fonctions (`.SYNOPSIS`, `.EXAMPLE`, etc.)](14-architecture/05-documentation-scripts.md)

### 🟨 [Module 16 – Annexes et bonus](annexes/README.md)

- 📁 16-1. [Mini-projets (inventaire réseau, backup automatique, API weather, etc.)](annexes/16-1-mini-projets.md)
- 📄 16-2. [Modèles de scripts prêts à l'emploi](annexes/16-2-modeles-scripts.md)
- 🎓 16-3. [Quiz et exercices corrigés par niveau](annexes/16-3-quiz-exercices.md)
- 🧰 16-4. [Outils complémentaires (ISE, VS Code, Terminal Windows)](annexes/16-4-outils-complementaires.md)
- 📚 16-5. [Glossaire PowerShell & liens utiles](annexes/16-5-glossaire-powershell.md)
