# Module 1 - Introduction à PowerShell
## 1-2. PowerShell vs Bash / CMD / VBScript

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Bienvenue dans cette section où nous allons comparer PowerShell avec d'autres interfaces en ligne de commande et langages de script ! Cette comparaison vous aidera à comprendre ce qui rend PowerShell spécial et pourquoi il vaut la peine d'être appris, même si vous connaissez déjà d'autres outils.

### 📊 Tableau comparatif rapide

| Caractéristique | PowerShell | CMD | Bash | VBScript |
|-----------------|------------|-----|------|----------|
| Type | Shell et langage de script orienté objet | Shell avec commandes simples | Shell et langage de script orienté texte | Langage de script |
| Sortie | Objets | Texte | Texte | Variables |
| Multiplateformes | ✅ (depuis PS Core) | ❌ (Windows uniquement) | ✅ | ❌ (Windows uniquement) |
| Intégration Windows | ✅✅✅ (Natif) | ✅✅ | ❌ (limité) | ✅✅ |
| Syntaxe | Verbe-Nom | Commandes simples | Commandes et options | Programmation procédurale |
| Maintenance | Actif | Minimal | Actif | Obsolète |

### 🔄 PowerShell vs CMD (Invite de commandes Windows)

**CMD** est l'interpréteur de commandes historique de Windows, mais il présente plusieurs limitations :

- **Traitement du texte uniquement** : CMD traite tout comme du texte, ce qui rend difficile la manipulation de données structurées.
- **Commandes limitées** : Ensemble de commandes restreint et syntaxe peu cohérente.
- **Scripts peu puissants** : Les fichiers batch (.bat/.cmd) ont une syntaxe complexe pour les opérations avancées.

**PowerShell**, en revanche :
- **Manipule des objets** : Au lieu de manipuler du texte, PowerShell traite des objets avec propriétés et méthodes.
- **Syntaxe cohérente** : Les commandes (cmdlets) suivent un format Verbe-Nom standardisé.
- **Plus puissant** : Accès complet à .NET, WMI, COM, et plus encore.

#### Exemple concret :

```cmd
# CMD - Lister les fichiers et trier par taille (complexe)
dir /o:s
```

```powershell
# PowerShell - Lister et trier par taille (intuitif et puissant)
Get-ChildItem | Sort-Object -Property Length -Descending
```

### 🐧 PowerShell vs Bash

**Bash** est le shell standard sur Linux et macOS, connu pour :
- **Manipulation de texte** : Excellent pour le traitement en ligne de texte avec grep, sed, awk, etc.
- **Écosystème Unix** : Riche collection d'outils en ligne de commande.
- **Portabilité** : Disponible sur presque tous les systèmes Unix-like.

**PowerShell** se distingue par :
- **Traitement d'objets** : Pas besoin de parser du texte, vous manipulez directement des propriétés.
- **Cohérence** : Syntaxe et conventions de nommage standardisées.
- **Intégration Windows** : Accès natif aux API Windows et .NET.

#### Exemple concret :

```bash
# Bash - Trouver les 5 plus gros fichiers
find . -type f -exec ls -s {} \; | sort -n -r | head -5
```

```powershell
# PowerShell - Trouver les 5 plus gros fichiers
Get-ChildItem -Recurse -File | Sort-Object -Property Length -Descending | Select-Object -First 5
```

### 📜 PowerShell vs VBScript

**VBScript** était couramment utilisé pour l'automatisation Windows avant PowerShell :
- **Syntaxe Visual Basic** : Familière pour les utilisateurs de VBA.
- **Accès COM/ActiveX** : Bonne intégration avec les technologies Windows.
- **Maintenance limitée** : Microsoft ne le développe plus activement.

**PowerShell** offre :
- **Pleine intégration système** : Accès direct aux API système.
- **Pipeline d'objets** : Facilite le chaînage des commandes.
- **Activement maintenu** : Nouvelles fonctionnalités et améliorations régulières.

#### Exemple concret :

```vbscript
' VBScript - Obtenir l'espace disque
Set fso = CreateObject("Scripting.FileSystemObject")
Set drive = fso.GetDrive(fso.GetDriveName("C:"))
WScript.Echo "Espace libre sur C: " & FormatNumber(drive.FreeSpace / 1073741824, 2) & " GB"
```

```powershell
# PowerShell - Obtenir l'espace disque
$drive = Get-PSDrive C
"Espace libre sur C: {0:N2} GB" -f ($drive.Free / 1GB)
```

### 🌟 Pourquoi choisir PowerShell ?

1. **Orientation objet** : Manipulez des données structurées facilement
2. **Cohérence** : Syntaxe standardisée facile à apprendre
3. **Multiplateformes** : Depuis PowerShell Core (v6+), fonctionne sur Windows, Linux et macOS
4. **Extensibilité** : Nombreux modules supplémentaires disponibles
5. **Intégration** : Accès natif aux technologies Microsoft (.NET, Active Directory, Azure...)

### 💡 À retenir pour les débutants

- PowerShell traite des **objets**, pas seulement du texte
- La syntaxe **Verbe-Nom** (comme Get-Process) est très intuitive
- Le **pipeline** (`|`) transmet des objets complets, pas juste du texte
- PowerShell est une compétence **très valorisée** pour l'administration système moderne

---

Dans le prochain module, nous découvrirons l'histoire de PowerShell et ses différentes versions.

Des questions ? N'hésitez pas à les poser avant d'avancer !

⏭️ [Historique et versions (Windows PowerShell, PowerShell 7+)](/00-introduction/03-historique-et-versions.md)
