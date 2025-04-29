# Module 5 - Gestion des fichiers et du système
## 5-1. Fichiers, dossiers, chemins (`Get-Item`, `Get-ChildItem`, etc.)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

La gestion des fichiers et dossiers est une tâche fondamentale pour tout administrateur système ou développeur. PowerShell offre des outils puissants pour naviguer, explorer et manipuler le système de fichiers de manière efficace et intuitive.

### 🗂️ Comprendre les chemins PowerShell

PowerShell utilise le concept de **lecteurs PowerShell** (PSDrives) qui vont au-delà des simples lecteurs de disque. Ils peuvent représenter:

- Des lecteurs physiques (`C:`, `D:`)
- Le Registre Windows (`HKLM:`, `HKCU:`)
- Des variables (`Variable:`)
- Des fonctions (`Function:`)
- Et bien plus encore

#### Types de chemins

PowerShell prend en charge deux types de chemins:

1. **Chemins absolus**: Commencent à la racine d'un lecteur
   ```powershell
   C:\Windows\System32\calc.exe
   ```

2. **Chemins relatifs**: Relatifs à l'emplacement actuel
   ```powershell
   .\Documents\notes.txt   # .\ représente le dossier actuel
   ..\images\photo.jpg     # ..\ représente le dossier parent
   ```

### 📁 Navigation dans le système de fichiers

#### Vérifier l'emplacement actuel

```powershell
Get-Location   # Équivalent de 'pwd' sous Linux
# ou son alias
pwd
```

#### Changer de répertoire

```powershell
Set-Location C:\Windows
# ou son alias
cd C:\Windows
```

#### Revenir au répertoire précédent

```powershell
cd -
```

### 🔍 Explorer les fichiers et dossiers

#### Lister le contenu d'un dossier

La cmdlet `Get-ChildItem` est l'équivalent de `dir` ou `ls`:

```powershell
Get-ChildItem
# ou ses alias
dir
ls
```

#### Afficher uniquement les fichiers

```powershell
Get-ChildItem -File
```

#### Afficher uniquement les dossiers

```powershell
Get-ChildItem -Directory
```

#### Filtrer par nom

```powershell
# Tous les fichiers .txt
Get-ChildItem -Filter *.txt

# Tous les fichiers commençant par "rapport"
Get-ChildItem -Filter rapport*
```

#### Recherche récursive

```powershell
# Rechercher tous les fichiers .log dans le dossier et ses sous-dossiers
Get-ChildItem -Filter *.log -Recurse
```

#### Limiter la profondeur de recherche

```powershell
# Rechercher dans le dossier actuel et jusqu'à 2 niveaux de sous-dossiers
Get-ChildItem -Recurse -Depth 2
```

### 📊 Obtenir des informations sur un élément spécifique

#### Informations sur un fichier ou dossier

```powershell
Get-Item C:\Windows\notepad.exe
```

#### Vérifier si un fichier existe

```powershell
Test-Path C:\Windows\notepad.exe    # Retourne $true si le fichier existe
```

#### Obtenir les attributs d'un fichier

```powershell
(Get-Item C:\Windows\notepad.exe).Attributes
```

### 🌳 Comprendre les objets du système de fichiers

Dans PowerShell, les fichiers et dossiers sont représentés par des objets:

- `System.IO.FileInfo` pour les fichiers
- `System.IO.DirectoryInfo` pour les dossiers

Ces objets ont de nombreuses propriétés utiles:

```powershell
$fichier = Get-Item C:\Windows\notepad.exe
$fichier.Length           # Taille en octets
$fichier.CreationTime     # Date de création
$fichier.LastWriteTime    # Date de dernière modification
$fichier.FullName         # Chemin complet
$fichier.DirectoryName    # Dossier contenant le fichier
$fichier.Extension        # Extension (.exe)
$fichier.BaseName         # Nom sans extension (notepad)
```

### 🛠️ Manipulation des chemins

PowerShell offre plusieurs cmdlets pour manipuler les chemins:

#### Joindre des chemins

```powershell
Join-Path -Path "C:\Users" -ChildPath "Documents\notes.txt"
# Résultat: C:\Users\Documents\notes.txt
```

#### Obtenir différentes parties d'un chemin

```powershell
$chemin = "C:\Users\Jean\Documents\rapport.docx"

Split-Path -Path $chemin -Leaf          # rapport.docx
Split-Path -Path $chemin -Parent        # C:\Users\Jean\Documents
Split-Path -Path $chemin -Qualifier     # C:
```

#### Convertir un chemin relatif en absolu

```powershell
Resolve-Path ".\Documents"
```

### 🌟 Exemples pratiques

#### Exemple 1: Trouver les fichiers les plus volumineux

```powershell
Get-ChildItem -Path C:\Windows -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object -Property Length -Descending |
    Select-Object -First 10 Name, @{Name="Size (MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}}
```

#### Exemple 2: Trouver les fichiers récemment modifiés

```powershell
Get-ChildItem -Path $HOME -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-7) } |
    Sort-Object LastWriteTime -Descending |
    Format-Table Name, LastWriteTime
```

#### Exemple 3: Rechercher un texte dans plusieurs fichiers

```powershell
Get-ChildItem -Path C:\Scripts -Filter *.ps1 |
    Select-String -Pattern "fonction" |
    Format-Table Path, LineNumber, Line -AutoSize
```

### 💪 Exercice pratique

1. Affichez tous les fichiers `.txt` présents dans votre dossier Documents
2. Trouvez les 5 fichiers les plus volumineux de votre dossier utilisateur
3. Créez une liste des dossiers de votre système qui contiennent plus de 10 fichiers

### 🎓 Solution de l'exercice

```powershell
# 1. Fichiers .txt dans Documents
Get-ChildItem -Path $HOME\Documents -Filter *.txt

# 2. Les 5 fichiers les plus volumineux
Get-ChildItem -Path $HOME -File -Recurse -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 5 FullName, @{Name="Size (MB)"; Expression={[math]::Round($_.Length / 1MB, 2)}}

# 3. Dossiers contenant plus de 10 fichiers
Get-ChildItem -Path C:\ -Directory -Recurse -Depth 2 -ErrorAction SilentlyContinue |
    ForEach-Object {
        $fichiers = Get-ChildItem -Path $_.FullName -File -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Dossier = $_.FullName
            NombreFichiers = $fichiers.Count
        }
    } |
    Where-Object { $_.NombreFichiers -gt 10 } |
    Sort-Object NombreFichiers -Descending
```

### 🔑 Points clés à retenir

- `Get-ChildItem` (alias: `dir`, `ls`) liste le contenu des dossiers
- `Get-Item` récupère un élément spécifique (fichier ou dossier)
- `-Recurse` permet une recherche dans les sous-dossiers
- `-Filter` est plus efficace que `-Include` pour filtrer par nom
- `Test-Path` vérifie l'existence d'un fichier ou dossier
- `Join-Path` et `Split-Path` manipulent les chemins de manière sécurisée
- `-ErrorAction SilentlyContinue` permet d'ignorer les erreurs d'accès refusé

### 🔮 Pour aller plus loin

Dans la prochaine section, nous verrons comment lire et écrire le contenu des fichiers dans différents formats (TXT, CSV, JSON, XML), ce qui vous permettra d'automatiser davantage vos tâches quotidiennes.

---

💡 **Astuce de pro**: Utilisez `-ErrorAction SilentlyContinue` avec les commandes récursives comme `Get-ChildItem -Recurse` pour éviter que votre écran soit rempli de messages d'erreur "Accès refusé" lorsque vous n'avez pas les droits sur certains dossiers.

⏭️ [Lecture/écriture de fichiers (TXT, CSV, JSON, XML)](/04-systeme-fichiers/02-lecture-ecriture.md)
