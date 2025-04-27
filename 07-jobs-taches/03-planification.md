# Module 8 - Jobs, tâches planifiées et parallélisme
## 8-3. Planification via le Planificateur de tâches Windows

### Introduction à la planification de tâches

Jusqu'à présent, nous avons vu comment exécuter des tâches PowerShell en arrière-plan avec les Jobs et comment paralléliser des opérations. Mais que faire si vous souhaitez qu'un script s'exécute **automatiquement** à un moment précis, ou selon un intervalle régulier, même lorsque vous n'êtes pas devant votre ordinateur?

C'est là qu'intervient le **Planificateur de tâches Windows** (Windows Task Scheduler), un outil intégré à Windows qui permet de programmer l'exécution automatique de scripts et programmes.

### Pourquoi planifier des tâches PowerShell?

Voici quelques scénarios courants où la planification de scripts PowerShell est utile:

- Exécuter un script de sauvegarde tous les soirs à minuit
- Générer un rapport hebdomadaire chaque lundi matin
- Vérifier l'espace disque disponible toutes les heures
- Nettoyer des fichiers temporaires tous les weekends
- Synchroniser des données entre systèmes selon un calendrier précis

### Méthodes pour planifier des scripts PowerShell

Il existe deux approches principales pour planifier l'exécution de scripts PowerShell:

1. **Interface graphique** : Utiliser l'application "Planificateur de tâches" de Windows
2. **PowerShell** : Utiliser la cmdlet `Register-ScheduledTask` (plus avancé)

Nous verrons les deux méthodes, en commençant par la plus simple.

### Méthode 1: Utiliser l'interface graphique du Planificateur de tâches

#### Étape 1: Ouvrir le Planificateur de tâches

Il existe plusieurs façons d'ouvrir le Planificateur de tâches:

- Appuyer sur `Win + R`, taper `taskschd.msc` et valider
- Rechercher "Planificateur de tâches" dans le menu Démarrer
- Accéder à "Panneau de configuration > Outils d'administration > Planificateur de tâches"

![Planificateur de tâches Windows](https://exemple.com/image-planificateur.png)

#### Étape 2: Créer une nouvelle tâche planifiée

1. Dans le panneau de droite, cliquez sur **"Créer une tâche..."** (ou "Create Basic Task..." pour un assistant simplifié)
2. Dans l'onglet **Général**:
   - Donnez un **nom** descriptif à votre tâche (ex: "Sauvegarde_Quotidienne")
   - Ajoutez une **description** détaillant ce que fait votre tâche
   - Sélectionnez l'option d'exécution **"Que l'utilisateur soit connecté ou non"**
   - Cochez **"Exécuter avec les privilèges les plus élevés"** si votre script nécessite des droits administrateur

#### Étape 3: Configurer le déclencheur (quand la tâche doit s'exécuter)

1. Allez dans l'onglet **Déclencheurs** et cliquez sur **"Nouveau..."**
2. Choisissez quand la tâche doit s'exécuter:
   - **Une fois**: à une date et heure précises
   - **Quotidien**: tous les jours à une heure fixe
   - **Hebdomadaire**: certains jours de la semaine
   - **Mensuel**: à des jours spécifiques du mois
   - **Au démarrage de l'ordinateur**
   - **À la connexion de l'utilisateur**
   - **À la création ou modification d'un événement spécifique**
   - **En cas d'inactivité**

3. Configurez les détails du déclencheur (heure, répétition, etc.)
4. Cliquez sur **OK**

#### Étape 4: Configurer l'action (exécuter un script PowerShell)

1. Allez dans l'onglet **Actions** et cliquez sur **"Nouveau..."**
2. Pour l'action, sélectionnez **"Démarrer un programme"**
3. Dans **"Programme/script"**, entrez `powershell.exe`
4. Dans **"Ajouter des arguments"**, entrez les paramètres pour lancer votre script:

```
-ExecutionPolicy Bypass -NoProfile -File "C:\Scripts\MonScript.ps1"
```

Explication des paramètres:
- `-ExecutionPolicy Bypass`: Ignore temporairement la politique d'exécution
- `-NoProfile`: Démarre PowerShell sans charger le profil utilisateur
- `-File`: Spécifie le script à exécuter

5. Dans **"Commencer dans"**, vous pouvez spécifier le répertoire où se trouve votre script (optionnel)
6. Cliquez sur **OK**

#### Étape 5: Configurer les conditions et paramètres (optionnel)

1. Dans l'onglet **Conditions**, vous pouvez définir des conditions supplémentaires:
   - N'exécuter que sur alimentation secteur
   - Démarrer seulement si l'ordinateur est inactif
   - Arrêter si l'ordinateur passe sur batterie

2. Dans l'onglet **Paramètres**, vous pouvez configurer:
   - Autoriser l'exécution à la demande
   - Redémarrer la tâche en cas d'échec
   - Arrêter la tâche si elle s'exécute trop longtemps

3. Cliquez sur **OK** pour finaliser la création de la tâche

### Méthode 2: Utiliser PowerShell pour créer des tâches planifiées

Pour les utilisateurs plus avancés ou si vous avez besoin d'automatiser la création de tâches planifiées, PowerShell offre des cmdlets dédiées.

#### Exemple simple: Créer une tâche quotidienne

```powershell
# Créer une action qui lance un script PowerShell
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-ExecutionPolicy Bypass -NoProfile -File "C:\Scripts\MonScript.ps1"'

# Créer un déclencheur quotidien à 22h00
$trigger = New-ScheduledTaskTrigger -Daily -At '22:00'

# Créer la tâche planifiée
Register-ScheduledTask -TaskName "Sauvegarde_Quotidienne" `
    -Action $action `
    -Trigger $trigger `
    -Description "Exécute le script de sauvegarde quotidienne" `
    -RunLevel Highest
```

#### Exemple avancé: Tâche hebdomadaire avec plusieurs paramètres

```powershell
# Créer une action qui lance un script PowerShell avec des paramètres
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-ExecutionPolicy Bypass -NoProfile -File "C:\Scripts\RapportHebdo.ps1" -Format PDF -Destinataires "equipe@exemple.com"'

# Créer un déclencheur hebdomadaire (chaque lundi à 8h00)
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At '08:00'

# Définir les paramètres (redémarrer en cas d'échec, durée maximale, etc.)
$settings = New-ScheduledTaskSettingsSet `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5) `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1)

# Créer la tâche planifiée avec tous les éléments
Register-ScheduledTask -TaskName "Rapport_Hebdomadaire" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Génère et envoie le rapport hebdomadaire" `
    -User "SYSTEM"
```

### Bonnes pratiques pour les tâches planifiées

1. **Utilisez des chemins absolus** dans vos scripts pour éviter les problèmes de répertoire de travail

2. **Ajoutez une journalisation** dans vos scripts pour faciliter le débogage:
   ```powershell
   # Au début de votre script
   Start-Transcript -Path "C:\Logs\MonScript_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

   # À la fin de votre script
   Stop-Transcript
   ```

3. **Gérez les erreurs** dans vos scripts pour éviter les échecs silencieux:
   ```powershell
   try {
       # Votre code ici
   }
   catch {
       # Journaliser l'erreur
       $_ | Out-File "C:\Logs\Erreurs.log" -Append

       # Éventuellement, envoyer une alerte par email
       Send-MailMessage -To "admin@exemple.com" -Subject "Erreur tâche planifiée" -Body $_.Exception.Message
   }
   ```

4. **Testez vos scripts** manuellement avant de les planifier

5. **Vérifiez les droits d'accès** aux fichiers et ressources nécessaires

6. **Utilisez un compte de service** dédié pour les tâches critiques plutôt que votre compte utilisateur

### Gestion des tâches planifiées existantes

#### Consulter les tâches existantes

```powershell
# Lister toutes les tâches planifiées
Get-ScheduledTask

# Filtrer les tâches par nom
Get-ScheduledTask -TaskName "*Sauvegarde*"

# Afficher les détails d'une tâche spécifique
Get-ScheduledTaskInfo -TaskName "Sauvegarde_Quotidienne"
```

#### Modifier une tâche existante

```powershell
# Récupérer la tâche existante
$tache = Get-ScheduledTask -TaskName "Sauvegarde_Quotidienne"

# Créer un nouveau déclencheur
$nouveauDeclencheur = New-ScheduledTaskTrigger -Daily -At '23:00'

# Mettre à jour la tâche avec le nouveau déclencheur
Set-ScheduledTask -TaskName "Sauvegarde_Quotidienne" -Trigger $nouveauDeclencheur
```

#### Exécuter ou désactiver une tâche manuellement

```powershell
# Exécuter une tâche immédiatement
Start-ScheduledTask -TaskName "Sauvegarde_Quotidienne"

# Désactiver temporairement une tâche
Disable-ScheduledTask -TaskName "Sauvegarde_Quotidienne"

# Réactiver une tâche
Enable-ScheduledTask -TaskName "Sauvegarde_Quotidienne"
```

#### Supprimer une tâche

```powershell
# Supprimer une tâche planifiée
Unregister-ScheduledTask -TaskName "Sauvegarde_Quotidienne" -Confirm:$false
```

### Exemple pratique: Rapport d'espace disque quotidien

Voici un exemple complet montrant comment créer un script PowerShell qui génère un rapport d'espace disque, puis comment planifier son exécution quotidienne.

#### 1. Créer le script PowerShell (DiskSpaceReport.ps1)

```powershell
# Script de rapport d'espace disque
# Enregistrer sous C:\Scripts\DiskSpaceReport.ps1

# Démarrer la journalisation
$logPath = "C:\Logs\DiskReports"
if (-not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType Directory -Force }
Start-Transcript -Path "$logPath\DiskReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Définir le seuil d'alerte (en pourcentage)
$seuilAlerte = 15

# Obtenir les informations sur les disques
$disques = Get-Volume | Where-Object { $_.DriveLetter -ne $null -and $_.Size -gt 0 }

# Créer le rapport HTML
$rapportHTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'espace disque</title>
    <style>
        body { font-family: Arial, sans-serif; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .critique { background-color: #ffcccc; }
    </style>
</head>
<body>
    <h1>Rapport d'espace disque du $(Get-Date -Format 'dd/MM/yyyy')</h1>
    <table>
        <tr>
            <th>Lecteur</th>
            <th>Étiquette</th>
            <th>Taille totale</th>
            <th>Espace libre</th>
            <th>% libre</th>
            <th>Statut</th>
        </tr>
"@

# Ajouter chaque disque au rapport
foreach ($disque in $disques) {
    $pourcentLibre = [math]::Round(($disque.SizeRemaining / $disque.Size) * 100, 2)
    $classeCSS = if ($pourcentLibre -lt $seuilAlerte) { "critique" } else { "" }
    $statut = if ($pourcentLibre -lt $seuilAlerte) { "ATTENTION: Espace faible" } else { "OK" }

    $rapportHTML += @"
        <tr class="$classeCSS">
            <td>$($disque.DriveLetter):</td>
            <td>$($disque.FileSystemLabel)</td>
            <td>$([math]::Round($disque.Size / 1GB, 2)) GB</td>
            <td>$([math]::Round($disque.SizeRemaining / 1GB, 2)) GB</td>
            <td>$pourcentLibre%</td>
            <td>$statut</td>
        </tr>
"@
}

# Finaliser le rapport HTML
$rapportHTML += @"
    </table>
    <p>Rapport généré le $(Get-Date -Format 'dd/MM/yyyy à HH:mm:ss')</p>
</body>
</html>
"@

# Enregistrer le rapport
$cheminRapport = "C:\Rapports\EspaceDisk"
if (-not (Test-Path $cheminRapport)) { New-Item -Path $cheminRapport -ItemType Directory -Force }
$fichierRapport = "$cheminRapport\Rapport_Espace_Disque_$(Get-Date -Format 'yyyyMMdd').html"
$rapportHTML | Out-File -FilePath $fichierRapport -Encoding UTF8

Write-Host "Rapport enregistré dans: $fichierRapport"

# Vérifier si un envoi par email est nécessaire (si un disque est sous le seuil)
$envoiEmailNecessaire = $disques | Where-Object { ($_.SizeRemaining / $_.Size) * 100 -lt $seuilAlerte }

if ($envoiEmailNecessaire) {
    Write-Host "Des disques ont un espace faible. Un email d'alerte serait envoyé ici."
    # Ici, vous pourriez ajouter du code pour envoyer un email avec Send-MailMessage
    # (nécessite une configuration SMTP)
}

# Arrêter la journalisation
Stop-Transcript
```

#### 2. Planifier l'exécution quotidienne du script

```powershell
# Créer l'action
$action = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument '-ExecutionPolicy Bypass -NoProfile -File "C:\Scripts\DiskSpaceReport.ps1"' `
    -WorkingDirectory 'C:\Scripts'

# Créer le déclencheur (tous les jours à 7h00)
$trigger = New-ScheduledTaskTrigger -Daily -At '07:00'

# Configurer les paramètres
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -DontStopOnIdleEnd `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)

# Enregistrer la tâche
Register-ScheduledTask -TaskName "Rapport_Espace_Disque_Quotidien" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description "Génère un rapport quotidien sur l'espace disque disponible" `
    -RunLevel Highest
```

### Conclusion

Le Planificateur de tâches Windows est un outil puissant qui, combiné avec PowerShell, vous permet d'automatiser pratiquement n'importe quelle tâche administrative ou de maintenance selon un calendrier précis. Que ce soit via l'interface graphique ou les cmdlets PowerShell, la planification de tâches est accessible à tous les niveaux d'utilisateurs et peut économiser énormément de temps et d'efforts.

Dans le prochain module, nous verrons comment créer des services PowerShell de fond qui s'exécutent en permanence, plutôt que selon un calendrier.

### Exercices pratiques

1. **Exercice simple**: Créez une tâche planifiée qui exécute un script affichant "Bonjour Monde" chaque jour à une heure spécifique.

2. **Exercice intermédiaire**: Créez un script qui nettoie les fichiers temporaires de votre système, puis planifiez son exécution hebdomadaire.

3. **Exercice avancé**: Créez un script qui vérifie si certains services Windows sont arrêtés et les redémarre si nécessaire. Planifiez l'exécution de ce script toutes les heures.
