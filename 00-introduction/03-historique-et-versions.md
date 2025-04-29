# Module 1-3: Historique et versions (Windows PowerShell, PowerShell 7+)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## L'évolution de PowerShell au fil du temps

PowerShell a connu une évolution remarquable depuis sa création, passant d'un simple outil Windows à un environnement multi-plateforme puissant. Comprendre cette évolution vous aidera à mieux appréhender les différentes versions que vous pourriez rencontrer.

### Les débuts : Project Monad (2002-2006)

- **Origine** : PowerShell était initialement connu sous le nom de code "Project Monad" (MSH)
- **Architecte principal** : Jeffrey Snover, qui a publié le "Monad Manifesto" en 2002
- **Objectif** : Créer un environnement d'automatisation plus puissant que les outils existants (CMD, VBScript)

### Windows PowerShell 1.0 (2006)

- **Première version officielle** publiée en novembre 2006
- Intégrée à Windows Server 2008 et disponible en téléchargement pour Windows XP/Vista
- Introduit le concept fondamental de manipulation d'objets (et non de texte)
- ~130 cmdlets disponibles dans cette version initiale

### Windows PowerShell 2.0 (2009)

- **Fonctionnalités importantes** :
  - Introduction de l'IDE PowerShell (Integrated Scripting Environment)
  - Ajout des jobs en arrière-plan
  - Création de modules PowerShell
  - Sessions à distance (remoting)
  - Débogueur de scripts
- Inclus par défaut dans Windows 7 et Windows Server 2008 R2

### Windows PowerShell 3.0 (2012)

- Intégré à Windows 8 et Windows Server 2012
- **Améliorations notables** :
  - Performances grandement améliorées
  - Workflow PowerShell
  - Nouvelles commandes pour la gestion des tâches planifiées
  - Support amélioré pour WMI et CIM

### Windows PowerShell 4.0 (2013)

- Livré avec Windows 8.1 et Windows Server 2012 R2
- Introduction de "Desired State Configuration" (DSC)
- Améliorations du débogueur et des fonctionnalités de workflow

### Windows PowerShell 5.0 et 5.1 (2015-2016)

- **Version 5.0** : Incluse dans Windows 10
- **Version 5.1** : Dernière version de la branche Windows PowerShell (intégrée à Windows 10 et Windows Server 2016)
- **Nouveautés importantes** :
  - PowerShell Gallery (dépôt de modules)
  - PowerShellGet (gestionnaire de modules)
  - Prise en charge de classes (programmation orientée objet)
  - Support des modules binaires compilés
  - Améliorations de l'éditeur ISE

## Le grand tournant : PowerShell Core et PowerShell 7+

### PowerShell Core 6.0 (2018)

- **Changement majeur** : Première version multi-plateforme basée sur .NET Core
- **Open Source** : Code disponible sur GitHub
- Compatible avec Windows, macOS et plusieurs distributions Linux
- Suppression de certaines fonctionnalités Windows-spécifiques

### PowerShell 7+ (2020-présent)

- **PowerShell 7.0** (mars 2020) : Basé sur .NET Core 3.1
- **PowerShell 7.1, 7.2, 7.3...** : Mises à jour régulières
- **Principales caractéristiques** :
  - Rétablissement de la compatibilité avec les modules Windows
  - Exécution parallèle (ForEach-Object -Parallel)
  - Opérateur ternaire (condition ? si_vrai : si_faux)
  - Opérateur pipeline && et ||
  - Nouvelles fonctionnalités de traitement des erreurs
  - Amélioration continue des performances

## Quelle version utiliser?

### Pour les débutants (en 2025)

- **Sur Windows** : PowerShell 7+ est recommandé pour l'apprentissage
  - Windows PowerShell 5.1 reste installé par défaut
  - Les deux versions peuvent coexister sans problème
- **Sur macOS/Linux** : PowerShell 7+ est la seule option

### Comment vérifier ma version?

Ouvrez PowerShell et tapez la commande suivante :

```powershell
$PSVersionTable
```

Vous verrez un tableau affichant des informations sur votre version, comme ceci :

```
Name                           Value
----                           -----
PSVersion                      7.3.4
PSEdition                      Core
GitCommitId                    7.3.4
OS                             Microsoft Windows 10.0.19045
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0...}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

Si la valeur de "PSVersion" commence par "5", vous utilisez Windows PowerShell.
Si elle commence par "6" ou plus, vous utilisez PowerShell Core/7+.

## Résumé des principales différences

| Caractéristique | Windows PowerShell (5.1) | PowerShell 7+ |
|----------------|------------------------|--------------|
| Plateformes | Windows uniquement | Windows, macOS, Linux |
| Framework | .NET Framework | .NET (Core) |
| Open Source | Non | Oui |
| Mise à jour | Plus de nouvelles versions | Mises à jour régulières |
| Intégration Windows | Complète | Très bonne mais pas complète |
| Performance | Bonne | Meilleure |
| Nouvelles fonctionnalités | Non | Oui |

## Points importants à retenir

1. **Deux branches principales** coexistent aujourd'hui :
   - Windows PowerShell 5.1 (dernière version de la branche Windows-only)
   - PowerShell 7+ (multi-plateforme, open source, en développement actif)

2. **La majorité des commandes** fonctionnent de manière identique dans les deux versions

3. Dans ce cours, nous utiliserons **principalement PowerShell 7+**, mais nous soulignerons les différences importantes avec Windows PowerShell 5.1 quand nécessaire

4. **Conseil** : Si vous débutez aujourd'hui avec PowerShell, privilégiez l'apprentissage de PowerShell 7+, tout en gardant à l'esprit que vous pourriez rencontrer Windows PowerShell 5.1 dans des environnements d'entreprise

⏭️ [Installation (Windows, Linux, macOS)](/00-introduction/04-installation.md)
