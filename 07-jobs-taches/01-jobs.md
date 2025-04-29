# Module 8 - Jobs, tâches planifiées et parallélisme
## 8-1. Jobs (`Start-Job`, `Receive-Job`, `Remove-Job`)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### Introduction aux Jobs PowerShell

Les **Jobs** dans PowerShell sont un moyen d'exécuter des commandes ou des scripts en arrière-plan, sans bloquer votre console. C'est particulièrement utile lorsque vous devez:
- Exécuter des tâches qui prennent beaucoup de temps
- Effectuer plusieurs opérations simultanément
- Continuer à travailler dans votre console pendant qu'une tâche s'exécute

### Pourquoi utiliser des Jobs?

Imaginez que vous devez copier un très grand fichier, ce qui pourrait prendre plusieurs minutes. Sans les jobs, votre console PowerShell serait bloquée pendant toute la durée de l'opération. Avec les jobs, vous pouvez lancer la copie en arrière-plan et continuer à utiliser votre console pour d'autres tâches.

### Les Cmdlets principales pour gérer les Jobs

#### 1. `Start-Job` - Démarrer un job en arrière-plan

Cette commande lance l'exécution d'un script ou d'une commande en arrière-plan.

```powershell
# Syntaxe de base
Start-Job -ScriptBlock { commandes à exécuter }

# Exemple : un job qui attend 30 secondes puis retourne un message
Start-Job -ScriptBlock {
    Start-Sleep -Seconds 30
    Write-Output "Job terminé après 30 secondes d'attente!"
}
```

Lorsque vous exécutez `Start-Job`, PowerShell vous retourne immédiatement des informations sur le job créé, notamment son **ID** qui est important pour le retrouver plus tard.

#### 2. `Get-Job` - Vérifier l'état des jobs

Cette commande vous permet de voir tous les jobs et leur état actuel.

```powershell
# Lister tous les jobs
Get-Job

# Vérifier un job spécifique par son ID
Get-Job -Id 1
```

Les états possibles d'un job incluent:
- **Running** - Le job est en cours d'exécution
- **Completed** - Le job s'est terminé normalement
- **Failed** - Le job a rencontré une erreur
- **Stopped** - Le job a été arrêté manuellement

#### 3. `Receive-Job` - Récupérer les résultats d'un job

Cette commande permet de voir la sortie produite par un job.

```powershell
# Récupérer les résultats d'un job spécifique
Receive-Job -Id 1

# Récupérer les résultats et les conserver pour pouvoir les consulter à nouveau
Receive-Job -Id 1 -Keep
```

**Attention:** Par défaut, `Receive-Job` efface les résultats après les avoir affichés. Utilisez le paramètre `-Keep` si vous souhaitez pouvoir récupérer les résultats plusieurs fois.

#### 4. `Remove-Job` - Supprimer un job terminé

Cette commande supprime un job de la liste des jobs.

```powershell
# Supprimer un job spécifique
Remove-Job -Id 1

# Supprimer tous les jobs terminés
Get-Job -State Completed | Remove-Job
```

**Bonne pratique:** Pensez à nettoyer régulièrement vos jobs terminés pour libérer des ressources.

#### 5. `Stop-Job` - Arrêter un job en cours

Si vous avez besoin d'arrêter un job avant qu'il ne se termine:

```powershell
# Arrêter un job spécifique
Stop-Job -Id 1
```

### Exemple pratique: Vérifier plusieurs serveurs en parallèle

Voici un exemple concret qui montre comment les jobs peuvent être utiles pour vérifier simultanément l'état de plusieurs serveurs:

```powershell
# Liste de serveurs à vérifier
$serveurs = "serveur1", "serveur2", "serveur3", "serveur4"

# Lancer un job pour chaque serveur
foreach ($serveur in $serveurs) {
    Start-Job -Name "Ping_$serveur" -ScriptBlock {
        param($nom)
        $resultat = Test-Connection -ComputerName $nom -Count 1 -Quiet
        if ($resultat) {
            "$nom est en ligne"
        } else {
            "$nom est hors ligne"
        }
    } -ArgumentList $serveur
}

# Attendre quelques secondes pour que les jobs s'exécutent
Start-Sleep -Seconds 5

# Récupérer tous les résultats
Get-Job | Receive-Job -Keep

# Nettoyer les jobs terminés
Get-Job | Remove-Job
```

### Points importants à retenir

1. **Passage de paramètres**: Utilisez `-ArgumentList` pour passer des variables ou des valeurs à votre script.
2. **Nommage des jobs**: Donnez des noms explicites à vos jobs avec `-Name` pour les identifier facilement.
3. **Gestion de la mémoire**: Les jobs consomment des ressources, n'oubliez pas de les supprimer avec `Remove-Job` lorsqu'ils sont terminés.
4. **Conservation des résultats**: Utilisez `-Keep` avec `Receive-Job` si vous souhaitez pouvoir récupérer les résultats plusieurs fois.

### Limitations des jobs PowerShell

- Ils consomment plus de ressources que l'exécution normale de commandes
- Il peut y avoir une limite au nombre de jobs pouvant s'exécuter simultanément
- La communication entre les jobs et la session principale est limitée

### Exercice pratique

Essayez de créer un job qui liste tous les fichiers d'un répertoire contenant beaucoup de fichiers, puis récupérez le résultat:

```powershell
# Créer un job qui liste les fichiers du répertoire Windows
Start-Job -Name "ListeFichiers" -ScriptBlock {
    Get-ChildItem -Path "C:\Windows" -File | Select-Object Name, Length
}

# Attendre quelques secondes
Start-Sleep -Seconds 5

# Récupérer les résultats
Receive-Job -Name "ListeFichiers" -Keep

# Supprimer le job
Remove-Job -Name "ListeFichiers"
```

### Conclusion

Les jobs PowerShell vous offrent un moyen puissant d'exécuter des tâches en arrière-plan, permettant d'améliorer considérablement votre productivité en automatisant des processus qui prendraient normalement beaucoup de temps. Maîtriser les jobs est une compétence essentielle pour tout administrateur système ou développeur PowerShell.

Dans le prochain module, nous verrons comment utiliser les Runspaces et la parallélisation avec ForEach-Object -Parallel, des fonctionnalités encore plus puissantes disponibles dans PowerShell 7+.

⏭️ [Runspaces & ForEach-Object -Parallel (PowerShell 7+)](/07-jobs-taches/02-runspaces-parallel.md)
