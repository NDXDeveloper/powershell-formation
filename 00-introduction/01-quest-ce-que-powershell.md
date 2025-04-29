# Module 1 - Introduction à PowerShell

## 1.1 Qu'est-ce que PowerShell ?

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### Introduction

PowerShell est un **environnement d'automatisation et de scripting** développé par Microsoft. Il combine les capacités d'un langage de script avec les fonctionnalités d'une interface en ligne de commande (CLI).

Contrairement aux interfaces en ligne de commande traditionnelles qui travaillent avec du texte, **PowerShell manipule des objets** - un concept que nous détaillerons plus tard, mais qui constitue l'une de ses forces principales.

### Les points essentiels à comprendre

1. **Une plateforme complète** : PowerShell n'est pas seulement un interpréteur de commandes, c'est aussi :
   - Un langage de programmation
   - Un environnement d'automatisation
   - Un gestionnaire de configuration

2. **Multi-plateformes** : Initialement conçu pour Windows uniquement, PowerShell est désormais disponible sur :
   - Windows
   - macOS
   - Linux

3. **Un outil orienté objet** : Au lieu de traiter du simple texte, PowerShell manipule des objets qui contiennent des propriétés et des méthodes, ce qui le rend beaucoup plus puissant.

### À quoi sert PowerShell ?

PowerShell peut être utilisé pour de nombreuses tâches :

- **Administration système** : gestion des services, processus, registre Windows
- **Automatisation** : création de scripts pour automatiser des tâches répétitives
- **Gestion de configuration** : installation et configuration de logiciels
- **Accès aux données** : interrogation de bases de données, API web, fichiers
- **Gestion du cloud** : administration d'environnements Azure, AWS ou Google Cloud

### Les "cmdlets" - Le cœur de PowerShell

Les commandes PowerShell s'appellent des **cmdlets** (prononcé "command-lets"). Elles suivent une convention de nommage simple : **Verbe-Nom**

Quelques exemples :
- `Get-Process` : récupère la liste des processus en cours d'exécution
- `Stop-Service` : arrête un service
- `New-Item` : crée un nouvel élément (fichier, dossier, clé de registre...)

```powershell
# Exemple simple : afficher la liste des processus
Get-Process

# Exemple : créer un nouveau dossier
New-Item -Path "C:\MonDossier" -ItemType Directory
```

### PowerShell vs Command Prompt (cmd.exe)

Voici quelques différences clés entre PowerShell et l'ancien Command Prompt de Windows :

| Caractéristique | Command Prompt | PowerShell |
|----------------|----------------|------------|
| Type de données | Texte uniquement | Objets |
| Commandes | Limitées | Plusieurs milliers de cmdlets |
| Scripts | Basiques (.bat, .cmd) | Avancés (.ps1) |
| Fonctionnalités | Simples | Programmation complète |
| Extensibilité | Limitée | Très extensible (modules) |

### En résumé

PowerShell est un outil puissant qui va bien au-delà d'un simple terminal de commandes. Il vous permet d'administrer votre système, d'automatiser des tâches complexes et même de développer des applications complètes.

Dans les prochaines sections, nous apprendrons comment l'installer, le configurer et utiliser ses commandes de base.

---

💡 **Conseil pour débutants** : Ne vous inquiétez pas si tous ces concepts semblent complexes pour l'instant. PowerShell a été conçu pour être intuitif et nous allons progresser pas à pas dans ce cours.
