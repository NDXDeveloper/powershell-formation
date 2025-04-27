# Module 7 - Gestion des erreurs en PowerShell

## 7-3. Débogage avec VS Code (`Set-PSBreakpoint`, etc.)

Le débogage est une compétence essentielle pour tout développeur de scripts. Lorsque votre code ne fonctionne pas comme prévu, les outils de débogage vous aident à comprendre ce qui se passe réellement et à trouver les erreurs. Dans cette section, nous allons explorer le débogage de scripts PowerShell, à la fois avec les commandes natives et avec Visual Studio Code.

### Pourquoi utiliser le débogage ?

Les erreurs dans les scripts peuvent être difficiles à repérer uniquement avec les messages d'erreur. Le débogage vous permet de :

- ✅ Examiner la valeur des variables à un moment précis
- ✅ Exécuter votre script pas à pas
- ✅ Comprendre le flux d'exécution
- ✅ Déterminer pourquoi un script ne se comporte pas comme prévu

### Les points d'arrêt (breakpoints)

Un point d'arrêt est un marqueur placé dans votre code qui indique à PowerShell de suspendre l'exécution lorsqu'il atteint cet endroit. C'est comme un panneau "STOP" temporaire dans votre script.

#### Points d'arrêt natifs avec PowerShell

PowerShell propose plusieurs cmdlets pour définir des points d'arrêt :

- `Set-PSBreakpoint` : Définit un point d'arrêt
- `Get-PSBreakpoint` : Liste les points d'arrêt actuels
- `Remove-PSBreakpoint` : Supprime un point d'arrêt
- `Disable-PSBreakpoint` : Désactive temporairement un point d'arrêt
- `Enable-PSBreakpoint` : Réactive un point d'arrêt désactivé

#### Types de points d'arrêt en PowerShell

1. **Points d'arrêt de ligne** - S'arrêtent à une ligne spécifique
2. **Points d'arrêt de commande** - S'arrêtent lorsqu'une commande particulière est exécutée
3. **Points d'arrêt de variable** - S'arrêtent lorsqu'une variable est lue ou modifiée

Voyons quelques exemples :

```powershell
# Créons un script simple à déboguer (enregistrez-le comme MonScript.ps1)
function Calculer-Somme {
    param($a, $b)
    $resultat = $a + $b
    return $resultat
}

$nombre1 = 10
$nombre2 = 20
$somme = Calculer-Somme -a $nombre1 -b $nombre2
Write-Host "La somme de $nombre1 et $nombre2 est $somme"
```

Maintenant, définissons des points d'arrêt :

```powershell
# Point d'arrêt sur une ligne spécifique (ligne 4 dans MonScript.ps1)
Set-PSBreakpoint -Script C:\Chemin\vers\MonScript.ps1 -Line 4

# Point d'arrêt sur une commande (Write-Host)
Set-PSBreakpoint -Script C:\Chemin\vers\MonScript.ps1 -Command "Write-Host"

# Point d'arrêt sur une variable (quand $somme est modifiée)
Set-PSBreakpoint -Script C:\Chemin\vers\MonScript.ps1 -Variable "somme" -Mode Write
```

Après avoir défini vos points d'arrêt, exécutez votre script. L'exécution s'arrêtera à chaque point d'arrêt et vous donnera une invite de débogage spéciale :

```
Hit Line breakpoint on 'C:\Chemin\vers\MonScript.ps1:4'
At C:\Chemin\vers\MonScript.ps1:4
DBG>
```

#### Commandes de l'invite de débogage (DBG>)

À l'invite de débogage, vous pouvez utiliser plusieurs commandes :

| Commande | Description |
|----------|-------------|
| `c` ou `continue` | Continue l'exécution jusqu'au prochain point d'arrêt |
| `s` ou `step` | Exécute la ligne actuelle et s'arrête à la suivante |
| `v` ou `stepOver` | Exécute la ligne actuelle (sans entrer dans les fonctions) |
| `o` ou `stepOut` | Continue l'exécution jusqu'à la sortie de la fonction actuelle |
| `q` ou `quit` | Arrête le débogueur et termine le script |
| `k` ou `get-psCallStack` | Affiche la pile d'appels actuelle |
| `l` ou `list` | Affiche les lignes autour de la position actuelle |
| `<variable>` | Affiche la valeur d'une variable |
| `$_` | Affiche l'objet courant |

### Débogage avec Visual Studio Code

Visual Studio Code offre une expérience de débogage beaucoup plus conviviale et visuelle. Si vous débutez en PowerShell, c'est l'approche recommandée.

#### Configuration de VS Code pour le débogage PowerShell

1. **Installez VS Code** : Téléchargez et installez depuis [code.visualstudio.com](https://code.visualstudio.com/)

2. **Installez l'extension PowerShell** : Cliquez sur l'icône Extensions (ou appuyez sur Ctrl+Shift+X), recherchez "PowerShell" et installez l'extension officielle de Microsoft

   ![Installation de l'extension PowerShell](https://i.imgur.com/abCD1234.png)

3. **Ouvrez votre script** : Ouvrez VS Code et chargez votre fichier PowerShell

#### Définir des points d'arrêt dans VS Code

C'est vraiment simple :

1. Cliquez dans la marge à gauche de la ligne où vous voulez arrêter l'exécution
   - Un point rouge apparaît, indiquant un point d'arrêt
   - Cliquez à nouveau sur le point rouge pour le supprimer

2. Vous pouvez aussi utiliser F9 pour ajouter/supprimer un point d'arrêt sur la ligne actuelle

#### Démarrer une session de débogage

1. Appuyez sur F5 ou cliquez sur l'icône de débogage dans la barre latérale, puis sur le bouton de lecture vert

2. VS Code lancera PowerShell et exécutera votre script jusqu'au premier point d'arrêt

#### Interface de débogage VS Code

Lorsque l'exécution s'arrête à un point d'arrêt, VS Code vous offre une interface complète :

![Interface de débogage VS Code](https://i.imgur.com/efGH5678.png)

Les éléments clés sont :

1. **Barre d'outils de débogage** - Contient des boutons pour :
   - Continuer (F5)
   - Pas à pas (F10)
   - Pas à pas détaillé (F11)
   - Pas à pas sortant (Shift+F11)
   - Redémarrer
   - Arrêter

2. **Panneau Variables** - Affiche toutes les variables dans la portée actuelle

3. **Panneau Watch** - Vous permet de surveiller des expressions spécifiques

4. **Pile d'appels** - Montre la hiérarchie des appels de fonction

5. **Point d'arrêt** - Liste tous vos points d'arrêt

6. **Console de débogage** - Vous permet d'exécuter des commandes PowerShell pendant la session de débogage

### Techniques de débogage avancées

#### Points d'arrêt conditionnels dans VS Code

VS Code permet de créer des points d'arrêt qui ne s'activent que lorsqu'une condition est remplie :

1. Créez un point d'arrêt normal en cliquant dans la marge
2. Faites un clic droit sur le point d'arrêt et sélectionnez "Edit Breakpoint"
3. Entrez une expression PowerShell qui doit être vraie pour que le point d'arrêt s'active

Par exemple, pour ne s'arrêter que si une variable dépasse une certaine valeur :
```
$i -gt 100
```

#### Débogage à distance

PowerShell permet également de déboguer des scripts s'exécutant sur des ordinateurs distants :

```powershell
# Sur l'ordinateur distant, activez le débogage à distance
Enable-PSRemoting -Force

# Sur votre ordinateur local
Enter-PSSession -ComputerName NomServeur
# Puis utilisez les commandes de débogage normales
```

### Exercice pratique : Déboguer un script qui calcule la factorielle

Voici un script avec une erreur. Utilisez les techniques de débogage pour trouver et corriger le problème :

```powershell
# Enregistrez ce script comme Factorielle.ps1
function Calculer-Factorielle {
    param(
        [int]$nombre
    )

    $resultat = 0  # <-- Il y a une erreur ici !

    if ($nombre -le 1) {
        return 1
    }

    for ($i = 1; $i -le $nombre; $i++) {
        $resultat = $resultat * $i
    }

    return $resultat
}

# Tester avec quelques valeurs
$test1 = Calculer-Factorielle -nombre 5
Write-Host "Factorielle de 5 = $test1"  # Devrait être 120

$test2 = Calculer-Factorielle -nombre 0
Write-Host "Factorielle de 0 = $test2"  # Devrait être 1
```

#### Solution pas à pas

1. Ouvrez le script dans VS Code
2. Placez un point d'arrêt à la ligne où `$resultat` est initialisé
3. Lancez le débogage avec F5
4. Utilisez F10 pour avancer pas à pas et observer les valeurs des variables
5. Vous constaterez que `$resultat` commence à 0, donc le produit sera toujours 0
6. Modifiez la ligne pour initialiser `$resultat` à 1 au lieu de 0
7. Relancez le débogage pour vérifier la correction

### Bonnes pratiques de débogage

1. **Commencez par les erreurs simples** :
   - Vérifiez d'abord les fautes de frappe
   - Assurez-vous que toutes les variables sont correctement initialisées
   - Vérifiez les conditions de boucle

2. **Utilisez des points d'arrêt stratégiques** :
   - Placez-les juste avant où vous pensez que le problème se produit
   - Utilisez des points d'arrêt au début et à la fin des fonctions

3. **Exploitez la console de débogage** :
   - Vous pouvez exécuter des commandes PowerShell pendant une pause
   - Très utile pour tester des hypothèses sans modifier le script

4. **Journal de débogage** :
   - Ajoutez des instructions `Write-Host` ou `Write-Debug` pour tracer l'exécution
   - Utilisez `Write-Verbose` avec le paramètre `-Verbose` pour le débogage temporaire

5. **Simplifiez pour isoler** :
   - Si un script complexe échoue, simplifiez-le jusqu'à ce qu'il fonctionne
   - Puis ajoutez progressivement la complexité pour identifier où le problème apparaît

### Résumé des commandes clés

| Outil | Commande/Action | Description |
|-------|----------------|-------------|
| PowerShell | `Set-PSBreakpoint -Script fichier.ps1 -Line 10` | Définit un point d'arrêt à la ligne 10 |
| PowerShell | `Set-PSBreakpoint -Script fichier.ps1 -Variable var -Mode Write` | S'arrête quand la variable est modifiée |
| PowerShell | `Get-PSBreakpoint` | Liste tous les points d'arrêt actifs |
| PowerShell | `Remove-PSBreakpoint -Id 3` | Supprime le point d'arrêt avec l'ID 3 |
| VS Code | Clic dans la marge | Ajoute/supprime un point d'arrêt |
| VS Code | F5 | Démarre/continue le débogage |
| VS Code | F10 | Pas à pas (step over) |
| VS Code | F11 | Pas à pas détaillé (step into) |
| VS Code | Shift+F11 | Pas à pas sortant (step out) |
| VS Code | Ctrl+Shift+F5 | Redémarrer le débogage |
| VS Code | Shift+F5 | Arrêter le débogage |

### Conclusion

Le débogage est une compétence qui s'améliore avec la pratique. N'ayez pas peur des erreurs - elles sont des opportunités d'apprentissage ! Avec les outils de débogage de PowerShell et VS Code, vous pouvez rapidement identifier et résoudre les problèmes dans vos scripts.

Pour les débutants, commencez par utiliser VS Code et ses outils visuels. Au fur et à mesure que vous devenez plus à l'aise, vous pourrez explorer les commandes PowerShell natives pour des scénarios plus avancés.

---

**Astuce bonus** : Pour un débogage efficace, prenez l'habitude d'écrire des scripts modulaires avec de petites fonctions qui ont une responsabilité unique. Un code bien structuré est beaucoup plus facile à déboguer !
