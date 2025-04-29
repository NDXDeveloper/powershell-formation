# Module 7 - Gestion des erreurs en PowerShell

## 7-4. Journaux d'exécution (`Start-Transcript`)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

Imaginez que vous exécutiez un script PowerShell important et que vous vouliez garder une trace de tout ce qui s'est passé pendant son exécution : les commandes, les résultats, les erreurs... C'est exactement ce que permettent les journaux d'exécution avec la commande `Start-Transcript` !

### Qu'est-ce qu'un journal d'exécution (transcript) ?

Un transcript en PowerShell est un enregistrement texte complet de votre session PowerShell. Il capture :
- Toutes les commandes que vous tapez
- Tous les résultats affichés dans la console
- Les erreurs qui se produisent
- L'heure de début et de fin de la session

C'est comme si quelqu'un prenait des notes détaillées de tout ce qui se passe dans votre session PowerShell !

### Pourquoi utiliser `Start-Transcript` ?

Les journaux d'exécution sont précieux pour plusieurs raisons :

- 📝 **Documentation** : Gardez une trace de ce que vous avez fait et des résultats obtenus
- 🐞 **Débogage** : Analysez ce qui s'est passé lorsqu'une erreur s'est produite
- 📊 **Audit** : Conservez des preuves des actions effectuées (important dans certains environnements d'entreprise)
- 🔄 **Reproductibilité** : Utilisez le journal pour reproduire les étapes exactes d'un processus
- 📚 **Formation** : Créez des tutoriels en capturant toutes les étapes d'une procédure

### Utilisation de base de `Start-Transcript`

La commande est très simple à utiliser :

```powershell
# Démarrer l'enregistrement du journal
Start-Transcript

# Exécuter vos commandes PowerShell
Get-Service | Where-Object Status -eq "Running"
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5

# Arrêter l'enregistrement
Stop-Transcript
```

Par défaut, PowerShell enregistre le transcript dans votre dossier Documents avec un nom comme "PowerShell_transcript.20250426104212.txt" (incluant la date et l'heure).

### Personnaliser l'enregistrement du journal

Vous pouvez personnaliser l'emplacement et le nom du fichier de journal :

```powershell
# Spécifier un chemin et un nom de fichier
Start-Transcript -Path "C:\Logs\MonScript_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Vos commandes ici...

Stop-Transcript
```

L'expression `$(Get-Date -Format 'yyyyMMdd_HHmmss')` ajoute un horodatage au nom du fichier, ce qui évite d'écraser les anciens journaux.

### Options utiles de `Start-Transcript`

`Start-Transcript` offre plusieurs paramètres pratiques :

| Paramètre | Description | Exemple |
|-----------|-------------|---------|
| `-Path` | Spécifie l'emplacement du fichier de journal | `Start-Transcript -Path "C:\Logs\MonJournal.txt"` |
| `-Append` | Ajoute au fichier existant au lieu de l'écraser | `Start-Transcript -Path "C:\Logs\MonJournal.txt" -Append` |
| `-IncludeInvocationHeader` | Ajoute des informations détaillées sur chaque commande | `Start-Transcript -IncludeInvocationHeader` |
| `-NoClobber` | Empêche l'écrasement d'un fichier existant | `Start-Transcript -Path "C:\Logs\MonJournal.txt" -NoClobber` |
| `-Force` | Force l'écrasement même si le fichier est en lecture seule | `Start-Transcript -Path "C:\Logs\MonJournal.txt" -Force` |

### Exemple pratique : Journal d'exécution pour un script de maintenance

Voici comment intégrer `Start-Transcript` dans un script de maintenance système simple :

```powershell
# Script de maintenance système basique
# Enregistrez-le comme Maintenance.ps1

# Démarrer l'enregistrement du journal
$logPath = "C:\Logs\Maintenance_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logPath -Append

try {
    # Afficher un en-tête
    Write-Host "=== DÉBUT DE LA MAINTENANCE SYSTÈME $(Get-Date) ===" -ForegroundColor Green

    # 1. Vérifier l'espace disque
    Write-Host "`n--- Vérification de l'espace disque ---" -ForegroundColor Cyan
    Get-Volume | Where-Object { $_.DriveLetter } | Format-Table -AutoSize

    # 2. Lister les services arrêtés qui devraient être en cours d'exécution
    Write-Host "`n--- Services arrêtés (démarrage automatique) ---" -ForegroundColor Cyan
    Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -ne 'Running' }

    # 3. Vérifier les 5 processus qui utilisent le plus de mémoire
    Write-Host "`n--- Top 5 des processus par utilisation de mémoire ---" -ForegroundColor Cyan
    Get-Process | Sort-Object -Property WorkingSet64 -Descending | Select-Object -First 5 |
        Format-Table Name, ID, @{Name='Memory (MB)'; Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} -AutoSize

    # 4. Vérifier les mises à jour Windows (simulation)
    Write-Host "`n--- Vérification des mises à jour Windows ---" -ForegroundColor Cyan
    Write-Host "Simulation: 3 mises à jour disponibles"

    Write-Host "`n=== FIN DE LA MAINTENANCE SYSTÈME $(Get-Date) ===" -ForegroundColor Green
} catch {
    # En cas d'erreur, l'enregistrer dans le journal
    Write-Host "!!! ERREUR LORS DE LA MAINTENANCE : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Toujours arrêter l'enregistrement, même en cas d'erreur
    Stop-Transcript
}
```

Quand vous exécutez ce script, il crée un fichier journal détaillé de toutes les vérifications effectuées, avec les résultats et les éventuelles erreurs.

### Bonnes pratiques pour les journaux d'exécution

1. **Utilisez des noms de fichiers avec horodatage** pour éviter d'écraser les anciens journaux

2. **Créez un dossier dédié pour vos journaux** (par exemple, `C:\Logs\`)

3. **Utilisez `try/catch/finally` avec `Start-Transcript`** :
   ```powershell
   try {
       Start-Transcript -Path $logPath
       # Vos commandes ici...
   } catch {
       # Gestion des erreurs
   } finally {
       Stop-Transcript # S'exécute même en cas d'erreur
   }
   ```

4. **Ajoutez des en-têtes clairs dans vos scripts** pour faciliter la lecture du journal :
   ```powershell
   Write-Host "=== DÉBUT DU TRAITEMENT ===" -ForegroundColor Green
   # ...
   Write-Host "=== FIN DU TRAITEMENT ===" -ForegroundColor Green
   ```

5. **Pensez à la rotation des journaux** pour les scripts qui s'exécutent régulièrement :
   ```powershell
   # Supprimer les journaux de plus de 30 jours
   Get-ChildItem -Path "C:\Logs" -Filter "*.txt" |
     Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
     Remove-Item -Force
   ```

### Exemple de contenu d'un journal d'exécution

Voici à quoi ressemble un fichier journal typique :

```
Démarrage du journal : 26/04/2025 10:42:12
Version de Windows PowerShell : 5.1.19041.3031
Nom d'hôte : DESKTOP-ABC123

PS C:\> Get-Service | Where-Object Status -eq "Running" | Select-Object -First 3

Status   Name               DisplayName
------   ----               -----------
Running  AdobeARMservice    Adobe Acrobat Update Service
Running  Appinfo            Application Information
Running  AppXSvc            AppX Deployment Service

PS C:\> Get-Date

Saturday, April 26, 2025 10:42:34

PS C:\> Stop-Transcript
Fin du journal : 26/04/2025 10:42:39
```

### Automatisation des journaux d'exécution

Vous pouvez configurer PowerShell pour démarrer automatiquement un journal à chaque session en ajoutant `Start-Transcript` à votre profil PowerShell :

1. Vérifiez si vous avez déjà un profil :
   ```powershell
   Test-Path $PROFILE
   ```

2. Si le résultat est `False`, créez-en un :
   ```powershell
   New-Item -Path $PROFILE -ItemType File -Force
   ```

3. Ouvrez le profil pour l'éditer :
   ```powershell
   notepad $PROFILE
   ```

4. Ajoutez cette ligne au profil :
   ```powershell
   Start-Transcript -Path "$HOME\Documents\PowerShell_Logs\PowerShell_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" -Append
   ```

5. Enregistrez et fermez le fichier

Maintenant, chaque fois que vous ouvrez PowerShell, un nouveau journal démarrera automatiquement !

### Journal d'exécution dans les scripts planifiés

Pour les scripts qui s'exécutent automatiquement (via le Planificateur de tâches Windows, par exemple), les journaux d'exécution sont particulièrement importants car vous ne voyez pas ce qui se passe pendant l'exécution.

```powershell
# Exemple de script planifié avec journalisation
$logFolder = "C:\Logs\ScriptPlanifie"

# Créer le dossier de logs s'il n'existe pas
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}

# Démarrer le journal avec la date dans le nom de fichier
$logFile = Join-Path -Path $logFolder -ChildPath "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logFile

try {
    # Votre script planifié ici
    Write-Host "Script planifié exécuté le $(Get-Date)"
    # ...
} catch {
    Write-Host "Erreur dans le script planifié : $($_.Exception.Message)" -ForegroundColor Red
    # Éventuellement, envoyez un email d'alerte ici
} finally {
    # Toujours arrêter le journal
    Stop-Transcript
}
```

### Limitations de `Start-Transcript`

Il est important de connaître quelques limitations :

1. `Start-Transcript` capture uniquement ce qui est affiché dans la console PowerShell, pas les sorties redirigées ou les opérations en arrière-plan

2. Il ne capture pas l'affichage graphique ou les fenêtres séparées ouvertes par un script

3. Les sorties binaires ou certains caractères spéciaux peuvent ne pas être correctement enregistrés

### En résumé : Quand utiliser `Start-Transcript` ?

✅ **Utilisez `Start-Transcript` quand :**
- Vous exécutez des scripts critiques ou complexes
- Vous avez besoin de prouver ce qui a été fait (audit)
- Vous dépannez un problème intermittent
- Vous automatisez des tâches via le Planificateur de tâches
- Vous voulez documenter un processus pour quelqu'un d'autre

### Exercice pratique

Créez un script simple qui :
1. Démarre un journal d'exécution dans un dossier de votre choix
2. Collecte des informations système de base (nom d'ordinateur, espace disque, mémoire disponible)
3. Arrête le journal
4. Ouvre le fichier journal généré pour vérification

```powershell
# Exercice : Journal d'informations système
# Enregistrez ce script comme SystemInfo.ps1

# Créer un dossier pour les journaux
$logFolder = "$HOME\Documents\SystemLogs"
if (-not (Test-Path -Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory | Out-Null
}

# Démarrer le journal
$logFile = Join-Path -Path $logFolder -ChildPath "SystemInfo_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Start-Transcript -Path $logFile

# Afficher un en-tête
Write-Host "=== INFORMATIONS SYSTÈME ===" -ForegroundColor Green
Write-Host "Date et heure : $(Get-Date)" -ForegroundColor Yellow

# Collecte d'informations
Write-Host "`n--- Informations sur l'ordinateur ---" -ForegroundColor Cyan
Get-ComputerInfo | Select-Object CsName, CsDomain, OsName, OsVersion | Format-List

Write-Host "`n--- Espace disque ---" -ForegroundColor Cyan
Get-Volume | Where-Object DriveLetter | Format-Table DriveLetter, FileSystemLabel,
    @{Name='Size (GB)'; Expression={[math]::Round($_.Size / 1GB, 2)}},
    @{Name='Free (GB)'; Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
    @{Name='Free (%)'; Expression={[math]::Round(($_.SizeRemaining / $_.Size) * 100, 0)}}

Write-Host "`n--- Mémoire RAM ---" -ForegroundColor Cyan
$os = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRAM = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRAM = $totalRAM - $freeRAM
$percentFree = [math]::Round(($freeRAM / $totalRAM) * 100, 0)

Write-Host "RAM totale : $totalRAM GB"
Write-Host "RAM utilisée : $usedRAM GB"
Write-Host "RAM libre : $freeRAM GB ($percentFree%)"

# Arrêter le journal
Stop-Transcript

# Ouvrir le fichier journal (fonctionne sur Windows)
Invoke-Item $logFile
```

### Conclusion

Les journaux d'exécution avec `Start-Transcript` sont un outil simple mais puissant pour documenter, déboguer et auditer vos scripts PowerShell. Prenez l'habitude de les utiliser pour vos scripts importants, et vous vous remercierez plus tard lorsque vous aurez besoin de comprendre ce qui s'est passé pendant leur exécution !

---

**Astuce finale** : Utilisez la commande `Get-Help Start-Transcript -Full` pour découvrir toutes les options disponibles et obtenir plus d'exemples d'utilisation.
