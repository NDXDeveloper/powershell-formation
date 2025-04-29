# 📚 Module 16-5 : Glossaire PowerShell & Liens Utiles

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 📘 Glossaire des termes PowerShell

### A
- **Alias** : Raccourci pour une commande PowerShell (ex: `ls` est un alias de `Get-ChildItem`).
- **Array** (Tableau) : Collection ordonnée d'éléments accessibles par leur index (ex: `$array = 1,2,3`).
- **Advanced Function** : Fonction qui utilise des fonctionnalités avancées comme CmdletBinding et paramètres.

### B
- **Boolean** : Type de donnée qui peut être vrai (`$true`) ou faux (`$false`).

### C
- **CIM** (Common Information Model) : Système standardisé pour accéder aux informations système, remplaçant progressivement WMI.
- **Cmdlet** : Commande native PowerShell suivant le format Verbe-Nom (ex: `Get-Process`).
- **Comment** : Ligne de code précédée par `#` qui n'est pas exécutée.
- **Comparison Operator** : Opérateur permettant de comparer des valeurs (`-eq`, `-lt`, `-gt`, etc.).

### D
- **DSC** (Desired State Configuration) : Plateforme pour maintenir et gérer les configurations.

### E
- **Enumeration** : Type qui définit un ensemble de constantes nommées.
- **ErrorActionPreference** : Variable qui détermine comment PowerShell gère les erreurs.
- **Expression** : Code qui produit une valeur lorsqu'il est évalué.

### F
- **Function** : Bloc de code réutilisable avec un nom spécifique.
- **Foreach** : Boucle qui traite chaque élément d'une collection.
- **Format-Table/Format-List** : Cmdlets pour afficher des données sous forme de tableau ou de liste.

### H
- **Hashtable** : Structure de données constituée de paires clé-valeur (ex: `@{Name="Valeur"; Age=30}`).
- **Help System** : Système de documentation intégré accessible via `Get-Help`.

### I
- **IF Statement** : Structure conditionnelle pour exécuter du code selon une condition.

### J
- **Job** : Tâche PowerShell qui s'exécute en arrière-plan.

### L
- **Loop** : Structure permettant d'exécuter du code plusieurs fois (ex: `for`, `while`).

### M
- **Module** : Ensemble de fonctionnalités PowerShell regroupées et distribuables.
- **Method** : Action qu'un objet peut effectuer (ex: `$string.ToUpper()`).

### O
- **Object** : Instance d'une classe contenant des propriétés et des méthodes.
- **Output** : Résultat d'une commande PowerShell.

### P
- **Parameter** : Valeur passée à une fonction ou cmdlet.
- **Pipeline** : Mécanisme pour passer les objets d'une commande à une autre en utilisant `|`.
- **Profile** : Script qui s'exécute au démarrage de PowerShell (`$PROFILE`).
- **Property** : Caractéristique d'un objet (ex: `$process.Name`).
- **PSProvider** : Interface d'accès aux données (ex: FileSystem, Registry).

### R
- **Remoting** : Capacité d'exécuter des commandes sur des ordinateurs distants.
- **Return** : Mot-clé utilisé pour terminer une fonction et retourner une valeur.

### S
- **Script** : Fichier `.ps1` contenant des commandes PowerShell.
- **Script Block** : Code délimité par des accolades `{}`.
- **Session** : Instance d'exécution PowerShell, locale ou distante.
- **Switch** : Alternative plus flexible à multiples `if...elseif`.

### T
- **Try/Catch** : Structure pour gérer les exceptions (erreurs).

### V
- **Variable** : Emplacement mémoire nommé pour stocker une valeur (ex: `$maVariable = 10`).
- **Verb** : Premier mot d'un cmdlet, indiquant l'action (ex: Get, Set, New).

### W
- **Where-Object** : Cmdlet pour filtrer des objets selon une condition.
- **WMI** (Windows Management Instrumentation) : API pour accéder aux informations système.

## 🔗 Liens Utiles

### Documentation officielle
- [Documentation PowerShell](https://docs.microsoft.com/powershell/) - Documentation Microsoft complète
- [PowerShell Gallery](https://www.powershellgallery.com/) - Dépôt de modules et scripts PowerShell
- [PowerShell GitHub](https://github.com/PowerShell/PowerShell) - Projet PowerShell open source

### Communauté et apprentissage
- [PowerShell.org](https://powershell.org/) - Articles, forums et ressources communautaires
- [Reddit r/PowerShell](https://www.reddit.com/r/PowerShell/) - Communauté PowerShell sur Reddit
- [Stack Overflow - PowerShell](https://stackoverflow.com/questions/tagged/powershell) - Questions/réponses

### Outils en ligne
- [PowerShell Explainer](https://powershellexplained.com/) - Explications détaillées de concepts PowerShell
- [SS64 PowerShell](https://ss64.com/ps/) - Référence rapide des commandes
- [PSKoans](https://github.com/vexx32/PSKoans) - Apprentissage par la pratique

### Blogs et tutoriels
- [Hey, Scripting Guy!](https://devblogs.microsoft.com/scripting/) - Blog Microsoft dédié au scripting
- [PowerShell Magazine](https://www.powershellmagazine.com/) - Articles et tutoriels
- [Learn PowerShell in a Month of Lunches](https://www.manning.com/books/learn-powershell-in-a-month-of-lunches) - Livre populaire pour débutants

### Outils de développement
- [Visual Studio Code avec extension PowerShell](https://marketplace.visualstudio.com/items?itemName=ms-vscode.PowerShell) - Environnement de développement recommandé
- [PowerShell ISE](https://docs.microsoft.com/powershell/scripting/windows-powershell/ise/introducing-the-windows-powershell-ise) - Environnement de script intégré à Windows
- [Pester](https://github.com/pester/Pester) - Framework de test pour PowerShell

### Personnalisation
- [Oh My Posh](https://ohmyposh.dev/) - Personnalisation avancée du prompt
- [PSReadLine](https://github.com/PowerShell/PSReadLine) - Module pour améliorer l'expérience en ligne de commande
- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) - Icônes pour le terminal PowerShell

### Sécurité
- [PowerShell Security Best Practices](https://devblogs.microsoft.com/powershell/powershell-security-best-practices/) - Bonnes pratiques de sécurité
- [PowerShell Constrained Language Mode](https://devblogs.microsoft.com/powershell/powershell-constrained-language-mode/) - Mode de langage restreint

### Automatisation
- [Task Scheduler](https://docs.microsoft.com/windows/win32/taskschd/task-scheduler-start-page) - Documentation sur la planification de tâches
- [Jenkins avec PowerShell](https://jenkins.io/solutions/windows/) - Intégration PowerShell dans Jenkins

## 🎓 Petits conseils pour progresser

1. **Pratiquez régulièrement** - La maîtrise de PowerShell vient avec la pratique quotidienne
2. **Consultez l'aide** - Utilisez `Get-Help` et `Get-Command` pour découvrir de nouvelles commandes
3. **Explorez les objets** - Utilisez `Get-Member` pour comprendre les objets que vous manipulez
4. **Rejoignez la communauté** - Posez des questions sur les forums et partagez vos connaissances
5. **Créez un projet personnel** - Automatisez une tâche répétitive pour mettre en pratique vos connaissances
6. **Lisez le code des autres** - Examinez comment les autres écrivent du code PowerShell
7. **Gardez un carnet de notes** - Conservez les commandes utiles pour pouvoir les réutiliser

---

*N'oubliez pas : PowerShell est un langage orienté objet où tout est un objet. Comprendre ce concept fondamental vous aidera grandement dans votre apprentissage !*

🔝 Retour à la [Table des matières](/SOMMAIRE.md)
