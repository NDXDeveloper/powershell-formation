# Module 14-3: Techniques d'optimisation en PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Filtrage natif et évitement de WMI

---

## 🎯 Objectifs du module
- Comprendre ce qu'est le filtrage natif et pourquoi l'utiliser
- Apprendre à éviter l'utilisation excessive de WMI/CIM
- Maîtriser les techniques d'optimisation pour des scripts plus rapides

---

## 📘 Introduction

La performance est un aspect crucial dans le développement de scripts PowerShell, surtout lorsque vous travaillez avec de grandes quantités de données ou dans des environnements avec des ressources limitées. Dans ce module, nous allons explorer deux techniques d'optimisation essentielles : le filtrage natif et l'évitement de l'utilisation excessive de WMI (Windows Management Instrumentation).

---

## 🔍 1. Le filtrage natif : un gain de performance considérable

### Qu'est-ce que le filtrage natif ?

Le filtrage natif consiste à filtrer les données **à la source** plutôt que de récupérer toutes les données puis de les filtrer dans PowerShell. Cette approche réduit considérablement la quantité de données transférées et traitées.

### 🚫 Approche inefficace (à éviter)

```powershell
# ÉVITEZ CETTE APPROCHE
# Récupère TOUS les processus puis filtre dans PowerShell
$processus = Get-Process
$processusExcel = $processus | Where-Object { $_.Name -eq "excel" }
```

### ✅ Approche optimisée (à privilégier)

```powershell
# RECOMMANDÉ
# Filtre directement à la source
$processusExcel = Get-Process -Name "excel"
```

### Exemples de filtrage natif avec différentes commandes

#### Exemple 1: Filtrage de fichiers

```powershell
# Inefficace: récupère tous les fichiers puis filtre
Get-ChildItem C:\Documents | Where-Object { $_.Extension -eq ".txt" }

# Optimisé: utilise le filtrage natif
Get-ChildItem C:\Documents -Filter "*.txt"
```

#### Exemple 2: Filtrage de services

```powershell
# Inefficace
Get-Service | Where-Object { $_.Status -eq "Running" }

# Optimisé
Get-Service | Where { $_.Status -eq "Running" }  # Syntaxe abrégée
# Ou encore mieux avec certaines commandes qui ont des paramètres spécifiques:
Get-Service -Status Running
```

#### Exemple 3: Filtrage des événements du journal

```powershell
# Inefficace (peut prendre plusieurs minutes sur un gros journal)
Get-EventLog -LogName System | Where-Object { $_.EntryType -eq "Error" -and $_.TimeGenerated -gt (Get-Date).AddDays(-1) }

# Optimisé (beaucoup plus rapide)
Get-EventLog -LogName System -EntryType Error -After (Get-Date).AddDays(-1)
```

### 💡 Astuce pour les débutants

Pour savoir si une cmdlet supporte le filtrage natif, consultez son aide avec :

```powershell
Get-Help Get-Process -Full
```

Recherchez les paramètres comme `-Filter`, `-Name`, `-Include`, `-Exclude` ou d'autres paramètres spécifiques qui permettent de filtrer directement.

---

## 🔄 2. Évitement de WMI/CIM : quand c'est possible

WMI (Windows Management Instrumentation) et son successeur CIM (Common Information Model) sont des technologies puissantes pour gérer les systèmes Windows, mais elles peuvent être lentes pour certaines opérations.

### Pourquoi éviter WMI/CIM quand possible ?
- Les requêtes WMI/CIM sont souvent plus lentes que les cmdlets natives de PowerShell
- Elles consomment plus de ressources système
- Les opérations à distance avec WMI peuvent être particulièrement coûteuses

### Alternatives aux commandes WMI/CIM courantes

#### Exemple 1: Obtenir des informations sur le système

```powershell
# Utilisation de WMI (plus lent)
Get-WmiObject -Class Win32_OperatingSystem

# Alternative plus rapide (PowerShell 3.0+)
Get-CimInstance -ClassName Win32_OperatingSystem

# Alternative encore plus rapide pour certaines informations
$env:OS
$env:COMPUTERNAME
[System.Environment]::OSVersion
```

#### Exemple 2: Lister les processus

```powershell
# Via WMI (lent)
Get-WmiObject -Class Win32_Process

# Alternative native beaucoup plus rapide
Get-Process
```

#### Exemple 3: Informations sur les disques

```powershell
# Via WMI (lent)
Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"

# Alternative native plus rapide
Get-PSDrive -PSProvider FileSystem
# ou
Get-Volume
```

### Quand faut-il utiliser WMI/CIM malgré tout ?

WMI/CIM reste nécessaire pour certaines informations spécifiques non accessibles autrement :

- Informations matérielles détaillées (BIOS, carte mère, etc.)
- Certaines métriques de performances avancées
- Certaines configurations système spécifiques

Dans ces cas, optimisez vos requêtes WMI/CIM :

```powershell
# Utilisez toujours des filtres dans la requête WMI elle-même
Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'"

# Limitez les propriétés retournées
Get-CimInstance -ClassName Win32_Process -Property Name,ID,WorkingSetSize
```

---

## 🧪 3. Comparaison de performance

Pour illustrer l'impact des techniques d'optimisation, voici une comparaison simple :

```powershell
# Test 1: Filtrage inefficace
Measure-Command {
    Get-ChildItem C:\ -Recurse -Depth 2 | Where-Object { $_.Extension -eq ".txt" }
}

# Test 2: Filtrage natif
Measure-Command {
    Get-ChildItem C:\ -Recurse -Depth 2 -Filter "*.txt"
}
```

Exécutez ces tests sur votre système pour voir la différence de performance. La différence peut être spectaculaire sur des volumes de données importants !

---

## 📝 Exercices pratiques

### Exercice 1: Conversion d'un script non optimisé

Convertissez ce script non optimisé en utilisant les techniques d'optimisation apprises :

```powershell
# Version non optimisée
$tousLesServices = Get-Service
$servicesArretes = $tousLesServices | Where-Object { $_.Status -eq "Stopped" }
$servicesCritiques = $servicesArretes | Where-Object { $_.DisplayName -like "*Windows*" }
```

### Exercice 2: Comparaison de performance

Écrivez un script qui compare la performance entre :
1. Obtenir la taille de tous les fichiers .log dans C:\Windows\Logs avec et sans filtrage natif
2. Obtenir la liste des applications installées via WMI vs via le registre

---

## ⚠️ Pièges à éviter

1. **Ne supposez pas que toutes les cmdlets ont les mêmes paramètres de filtrage** - vérifiez la documentation
2. **N'utilisez pas toujours Where-Object par réflexe** - cherchez d'abord s'il existe un paramètre natif
3. **N'abusez pas du pipeline** - parfois une approche plus directe est plus efficace
4. **Ne récupérez pas plus de propriétés que nécessaire** - utilisez Select-Object ou les paramètres -Property

---

## 🎓 Résumé des bonnes pratiques

1. **Filtrez à la source** avec les paramètres natifs des cmdlets
2. **Utilisez Get-CimInstance** plutôt que Get-WmiObject (si vous devez utiliser WMI)
3. **Préférez les cmdlets PowerShell natives** aux requêtes WMI/CIM quand c'est possible
4. **Limitez les propriétés retournées** pour réduire la quantité de données traitées
5. **Testez la performance** de vos scripts avec Measure-Command

---

## 🔍 Pour aller plus loin

- Explorez les autres cmdlets qui offrent un filtrage natif
- Apprenez à utiliser les requêtes CIM optimisées avec des sessions CIM persistantes
- Découvrez l'impact du parallélisme sur les opérations de filtrage
- Explorez les techniques de mise en cache pour les données obtenues via WMI/CIM

---

## 📚 Ressources additionnelles

- [Documentation PowerShell sur Microsoft Learn](https://learn.microsoft.com/powershell/)
- [PowerShell Performance Considerations](https://devblogs.microsoft.com/scripting/powershell-performance-considerations/)
- [CIM Sessions for Performance Optimization](https://devblogs.microsoft.com/scripting/optimizing-cim-cmdlets-for-better-performance/)

⏭️ [Éviter les ralentissements courants](/13-optimisation/04-ralentissements.md)
