# 📝 Module 15-5: Documentation de scripts et fonctions en PowerShell

## Introduction

Une bonne documentation est essentielle pour tout script PowerShell professionnel. Elle permet non seulement aux autres utilisateurs de comprendre votre code, mais elle vous aidera également à vous rappeler ce que fait votre script lorsque vous y reviendrez plus tard.

PowerShell intègre un système de documentation appelé "Comment-Based Help" qui est facilement accessible via la commande `Get-Help`. Dans cette section, nous allons apprendre comment documenter correctement vos scripts et fonctions.

## Les blocs de commentaires d'aide (Comment-Based Help)

En PowerShell, la documentation s'écrit à l'aide de commentaires spéciaux placés soit au début du script, soit juste avant la déclaration d'une fonction.

### Structure de base

Un bloc de commentaires d'aide est délimité de l'une des façons suivantes :

```powershell
<#
.KEYWORD
Texte d'aide
#>
```

Ou en utilisant des commentaires simples :

```powershell
# .KEYWORD
# Texte d'aide
```

## Les mots-clés principaux

Voici les mots-clés les plus importants que vous devriez utiliser :

### `.SYNOPSIS`

Un bref résumé de la fonction ou du script (une ligne).

```powershell
<#
.SYNOPSIS
Sauvegarde les fichiers importants d'un utilisateur.
#>
```

### `.DESCRIPTION`

Une description détaillée de ce que fait la fonction ou le script.

```powershell
<#
.DESCRIPTION
Ce script effectue une sauvegarde complète des dossiers Documents, Images et Bureau
de l'utilisateur vers un emplacement spécifié. Il crée automatiquement un dossier
avec la date du jour et compresse les fichiers pour économiser de l'espace.
#>
```

### `.PARAMETER`

Description de chaque paramètre de votre fonction.

```powershell
<#
.PARAMETER Destination
Chemin où la sauvegarde sera créée. Si non spécifié, utilise le dossier "Backups" sur le bureau.

.PARAMETER Compression
Niveau de compression (Normal, Maximum, ou Aucune). La valeur par défaut est "Normal".
#>
```

### `.EXAMPLE`

Des exemples d'utilisation de votre script ou fonction. Vous pouvez inclure plusieurs exemples.

```powershell
<#
.EXAMPLE
Backup-UserFiles -Destination "D:\Mes Sauvegardes"
Sauvegarde les fichiers vers le dossier "D:\Mes Sauvegardes".

.EXAMPLE
Backup-UserFiles -Compression Maximum
Sauvegarde les fichiers avec une compression maximale dans le dossier par défaut.
#>
```

### `.INPUTS`

Décrit les objets que vous pouvez envoyer à la fonction via le pipeline.

```powershell
<#
.INPUTS
Aucun. Cette fonction n'accepte pas d'entrées via le pipeline.
#>
```

### `.OUTPUTS`

Décrit les objets que la fonction renvoie.

```powershell
<#
.OUTPUTS
System.IO.FileInfo. Retourne un objet fichier représentant l'archive créée.
#>
```

### `.NOTES`

Informations supplémentaires sur le script (auteur, version, date, etc.).

```powershell
<#
.NOTES
Auteur: Jean Dupont
Version: 1.2
Date de création: 15/01/2024
Changements: Ajout de la compression
#>
```

### `.LINK`

Liens vers d'autres sujets connexes ou documentation externe.

```powershell
<#
.LINK
https://docs.microsoft.com/powershell/
https://github.com/MonProjet/Documentation
#>
```

## Exemple complet

Voici un exemple de documentation complète pour une fonction :

```powershell
function Backup-UserFiles {
    <#
    .SYNOPSIS
    Sauvegarde les fichiers importants d'un utilisateur.

    .DESCRIPTION
    Ce script effectue une sauvegarde complète des dossiers Documents, Images et Bureau
    de l'utilisateur vers un emplacement spécifié. Il crée automatiquement un dossier
    avec la date du jour et compresse les fichiers pour économiser de l'espace.

    .PARAMETER Destination
    Chemin où la sauvegarde sera créée. Si non spécifié, utilise le dossier "Backups" sur le bureau.

    .PARAMETER Compression
    Niveau de compression (Normal, Maximum, ou Aucune). La valeur par défaut est "Normal".

    .EXAMPLE
    Backup-UserFiles -Destination "D:\Mes Sauvegardes"
    Sauvegarde les fichiers vers le dossier "D:\Mes Sauvegardes".

    .EXAMPLE
    Backup-UserFiles -Compression Maximum
    Sauvegarde les fichiers avec une compression maximale dans le dossier par défaut.

    .INPUTS
    Aucun. Cette fonction n'accepte pas d'entrées via le pipeline.

    .OUTPUTS
    System.IO.FileInfo. Retourne un objet fichier représentant l'archive créée.

    .NOTES
    Auteur: Jean Dupont
    Version: 1.2
    Date de création: 15/01/2024
    Changements: Ajout de la compression

    .LINK
    https://docs.microsoft.com/powershell/
    #>
    [CmdletBinding()]
    param (
        [string]$Destination = "$env:USERPROFILE\Desktop\Backups",
        [ValidateSet('Normal', 'Maximum', 'Aucune')]
        [string]$Compression = 'Normal'
    )

    # Code de la fonction...
}
```

## Comment consulter l'aide

Une fois votre script ou fonction documenté, les utilisateurs peuvent consulter l'aide avec `Get-Help` :

```powershell
# Afficher l'aide complète
Get-Help Backup-UserFiles -Full

# Afficher uniquement les exemples
Get-Help Backup-UserFiles -Examples

# Afficher des informations détaillées sur les paramètres
Get-Help Backup-UserFiles -Parameter *

# Afficher uniquement le synopsis et la syntaxe
Get-Help Backup-UserFiles
```

## Bonnes pratiques

1. **Soyez clair et concis** : Le synopsis doit être court, mais la description peut être détaillée.
2. **Incluez toujours des exemples** : C'est souvent la première chose que les utilisateurs regardent.
3. **Documentez tous les paramètres** : Même ceux qui semblent évidents.
4. **Maintenez la documentation à jour** : Si vous modifiez votre code, mettez à jour la documentation.
5. **Utilisez un style cohérent** : Adoptez un format standard pour tous vos scripts.

## Astuce pour les débutants

Vous pouvez générer un modèle de documentation vide pour votre fonction en utilisant le snippet "Comment Help" dans VSCode ou en tapant simplement `##` au-dessus de votre fonction et en appuyant sur Tab.

## Exercice pratique

Prenez un script ou une fonction que vous avez écrit précédemment et ajoutez-y une documentation complète en utilisant tous les mots-clés que nous avons vus. Ensuite, testez votre documentation avec `Get-Help`.

---

## Conclusion

Une bonne documentation est la marque d'un script PowerShell professionnel. Elle facilite la maintenance, l'utilisation par d'autres personnes et vous fait gagner du temps à long terme. Prenez l'habitude de documenter vos scripts dès le début, et vous remarquerez rapidement les avantages de cette pratique.
