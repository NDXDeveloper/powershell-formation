# Module 6 : Fonctions, modules et structuration
## 6-4. Portée des variables et scopes

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

La portée des variables (ou "scope" en anglais) est un concept fondamental en PowerShell qui détermine où une variable est accessible et pendant combien de temps elle existe. Comprendre les scopes vous aidera à éviter des erreurs courantes et à structurer vos scripts de manière plus efficace.

### Qu'est-ce qu'un scope ?

Un scope est comme un conteneur invisible qui définit la "zone de visibilité" d'une variable, fonction ou alias. Chaque élément créé dans PowerShell existe dans un scope spécifique.

> 💡 **Analogie** : Imaginez les scopes comme des pièces dans une maison. Les objets dans le salon (scope parent) sont visibles depuis la cuisine (scope enfant), mais les objets dans la cuisine ne sont pas visibles depuis le salon.

### Les différents types de scopes

PowerShell dispose de plusieurs niveaux de scope, du plus large au plus restreint :

#### 1. Scope Global

- Concerne toute la session PowerShell
- Les variables globales sont accessibles partout
- Déclaration : `$global:MaVariable = "Valeur"`

```powershell
# Créer une variable globale
$global:MessageGlobal = "Je suis accessible partout !"

# Cette variable sera visible dans les fonctions, scripts et modules
function Test-ScopeGlobal {
    Write-Output "Dans la fonction : $global:MessageGlobal"
}

Test-ScopeGlobal
# Résultat : "Dans la fonction : Je suis accessible partout !"
```

#### 2. Scope Script

- Limité au script actuel
- Disponible du début à la fin du script
- Déclaration : `$script:MaVariable = "Valeur"`

```powershell
# Dans un script MonScript.ps1
$script:CompteurScript = 0

function Incrementer-Compteur {
    $script:CompteurScript++
    Write-Output "Compteur script : $script:CompteurScript"
}

Incrementer-Compteur  # Résultat : "Compteur script : 1"
Incrementer-Compteur  # Résultat : "Compteur script : 2"
```

#### 3. Scope Local (ou Scope de fonction)

- Limité à la fonction actuelle
- Par défaut, les variables créées dans une fonction sont locales
- Déclaration explicite : `$local:MaVariable = "Valeur"` (ou simplement `$MaVariable = "Valeur"`)

```powershell
function Test-ScopeLocal {
    $messageLocal = "Je suis uniquement visible dans cette fonction"
    Write-Output "Dans la fonction : $messageLocal"
}

Test-ScopeLocal
# Résultat : "Dans la fonction : Je suis uniquement visible dans cette fonction"

# Tentative d'accès en dehors de la fonction
Write-Output $messageLocal
# Résultat : Rien (ou erreur si -ErrorAction Stop)
```

#### 4. Scope Private (pour les modules)

- Limité au module actuel
- Non accessible même par les fonctions enfants
- Déclaration : `$private:MaVariable = "Valeur"`

```powershell
# Dans un module
$private:ConfigInterne = @{
    TimeoutSeconds = 30
    MaxRetries = 3
}

function Get-ModuleConfig {
    # Peut accéder à $private:ConfigInterne
}

# Les scripts qui importent ce module ne pourront pas accéder à $private:ConfigInterne
```

### La hiérarchie des scopes

Les scopes dans PowerShell suivent une hiérarchie parent-enfant :

```
Global (Parent)
   │
   ├─ Script (Enfant de Global)
   │     │
   │     └─ Fonction (Enfant de Script)
   │
   └─ Module (Enfant de Global)
         │
         └─ Fonction dans module (Enfant de Module)
```

#### Règles importantes

1. Un scope enfant peut **voir** les variables du scope parent
2. Un scope parent ne peut **pas voir** les variables du scope enfant
3. Un scope enfant peut **modifier** une variable du scope parent avec le préfixe approprié

### Comment les scopes affectent les variables

#### Exemple concret

```powershell
# Scope global
$fruit = "Pomme"  # Variable dans le scope global

function Modifier-FruitLocal {
    $fruit = "Banane"  # Nouvelle variable locale, ne modifie pas la variable globale
    Write-Output "Dans la fonction locale : $fruit"
}

function Modifier-FruitGlobal {
    $global:fruit = "Orange"  # Modifie la variable globale
    Write-Output "Dans la fonction globale : $global:fruit"
}

Write-Output "Avant : $fruit"
Modifier-FruitLocal
Write-Output "Après local : $fruit"
Modifier-FruitGlobal
Write-Output "Après global : $fruit"

# Résultat :
# Avant : Pomme
# Dans la fonction locale : Banane
# Après local : Pomme (non modifiée)
# Dans la fonction globale : Orange
# Après global : Orange (modifiée)
```

### Variables automatiques et leur scope

Certaines variables automatiques comme `$_` (l'objet courant dans le pipeline) ou `$PSItem` ont une portée spéciale :

```powershell
# $_ est limité au bloc de code actuel
1..3 | ForEach-Object {
    $_ * 2  # $_ fait référence à l'élément actuel du pipeline

    # Dans une sous-expression ou un bloc imbriqué, $_ change
    1..2 | ForEach-Object {
        # Ici, $_ fait référence au pipeline interne
    }
}
```

### Scopes dans les Scripts

Lorsque vous exécutez un script, PowerShell crée un nouveau scope :

```powershell
# Dans la console
$message = "Message de la console"

# Contenu de MonScript.ps1
Write-Output "Dans le script : $message"  # Visible (scope parent)
$message = "Message modifié par le script"
Write-Output "Message modifié dans le script : $message"

# Après exécution de MonScript.ps1
Write-Output "Dans la console : $message"  # Toujours "Message de la console"
```

Pour modifier une variable du scope parent depuis un script, utilisez l'opérateur de portée :

```powershell
# Dans MonScript.ps1
$global:message = "Cette modification sera visible dans la console"
```

### Scopes dans les Modules

Les modules fonctionnent différemment des scripts :

```powershell
# Dans MonModule.psm1
$moduleVar = "Variable du module"

function Get-ModuleVar {
    Write-Output $moduleVar  # Visible car dans le même scope du module
}

function Set-ModuleVar {
    param($Valeur)
    $script:moduleVar = $Valeur  # Utiliser $script: pour mettre à jour la variable du module
}

Export-ModuleMember -Function Get-ModuleVar, Set-ModuleVar
```

### Utilisations pratiques des scopes

#### 1. Compteurs persistants

```powershell
function Add-LogEntry {
    param($Message)

    # Initialiser le compteur s'il n'existe pas
    if (-not (Test-Path variable:script:logCounter)) {
        $script:logCounter = 1
    }

    "[Entrée $script:logCounter] $Message"
    $script:logCounter++
}

Add-LogEntry "Premier message"    # [Entrée 1] Premier message
Add-LogEntry "Deuxième message"   # [Entrée 2] Deuxième message
```

#### 2. Configuration d'un module

```powershell
# Dans un module de journalisation
$script:config = @{
    LogPath = "C:\Logs\app.log"
    MaxSize = 10MB
    Niveau = "INFO"
}

function Set-LogConfig {
    param(
        $Path,
        $MaxSize,
        $Niveau
    )

    if ($Path) { $script:config.LogPath = $Path }
    if ($MaxSize) { $script:config.MaxSize = $MaxSize }
    if ($Niveau) { $script:config.Niveau = $Niveau }
}

function Get-LogConfig {
    # Retourne une copie pour éviter la modification directe
    [PSCustomObject]$script:config.Clone()
}

function Write-Log {
    param($Message, $Niveau = "INFO")

    if ($Niveau -eq $script:config.Niveau) {
        Add-Content -Path $script:config.LogPath -Value $Message
    }
}
```

### Bonnes pratiques pour gérer les scopes

1. **Utilisez le scope le plus restreint possible**
   - Évitez d'utiliser `$global:` sauf si nécessaire

2. **Soyez explicite avec les scopes dans les modules**
   - Utilisez `$script:` pour les variables partagées dans un module

3. **Préfixez les variables globales importantes**
   - Ex : `$global:AppConfig` plutôt que `$global:Config`

4. **Documentez les variables de script**
   - Ajoutez des commentaires pour les variables de script importantes

5. **Évitez les modifications implicites**
   - Ne modifiez pas les variables d'un scope parent sans préfixe explicite

### Vérifier le scope d'une variable

```powershell
# Obtenir des informations sur une variable
Get-Variable nom_variable

# Vérifier si une variable existe dans un scope
Test-Path variable:nom_variable
```

### 🔄 Exercices pratiques

1. **Exercice de base** : Créez un script qui définit une variable locale, une variable de script et une variable globale, puis affichez leur portée.

2. **Exercice intermédiaire** : Créez une fonction qui utilise une variable de compteur persistante dans le scope script pour compter le nombre d'appels.

3. **Exercice avancé** : Créez un petit module avec une configuration interne accessible uniquement par les fonctions du module.

### 🌟 Résumé

- Les scopes définissent où les variables sont visibles et accessibles
- Hiérarchie des scopes : Global > Script > Fonction
- Un scope enfant peut voir les variables du scope parent, mais pas l'inverse
- Utilisez des préfixes (`$global:`, `$script:`, `$local:`, `$private:`) pour cibler un scope spécifique
- Les variables sans préfixe sont créées dans le scope actuel
- Dans les modules, utilisez `$script:` pour partager des variables entre fonctions

Dans la prochaine section, nous explorerons les meilleures pratiques de structuration et de nommage pour vos scripts et modules PowerShell.

⏭️ [Meilleures pratiques de structuration et nommage](/05-fonctions-modules/05-bonnes-pratiques.md)
