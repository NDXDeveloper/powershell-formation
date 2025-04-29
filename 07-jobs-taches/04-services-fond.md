# Module 8 - Jobs, tâches planifiées et parallélisme
## 8-4. Création de services de fond en PowerShell

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### Introduction aux services de fond

Vous avez déjà appris à exécuter des tâches en arrière-plan avec les Jobs PowerShell et à planifier l'exécution automatique de scripts avec le Planificateur de tâches Windows. Mais que faire lorsque vous avez besoin d'un programme qui s'exécute en permanence, surveille continuellement un système, et démarre automatiquement avec Windows ?

C'est là qu'interviennent les **services Windows**. Un service est un programme spécial qui :
- S'exécute en arrière-plan (sans interface utilisateur)
- Démarre automatiquement avec le système (ou selon une configuration)
- Continue à s'exécuter même lorsqu'aucun utilisateur n'est connecté
- Peut être démarré, arrêté et redémarré facilement

Dans cette partie, nous allons apprendre à créer de véritables services Windows à l'aide de PowerShell.

### Pourquoi créer un service avec PowerShell ?

Voici quelques cas d'utilisation courants :
- Surveillance continue d'un système ou d'une application
- Exécution régulière d'une tâche (toutes les minutes par exemple)
- Traitement automatisé de fichiers entrants
- Synchronisation de données en temps réel
- Agent de collecte de données pour la télémétrie

### Méthodes pour créer un service PowerShell

Il existe plusieurs approches pour transformer un script PowerShell en service :

1. **Méthode simple** : Utiliser NSSM (Non-Sucking Service Manager)
2. **Méthode intermédiaire** : Créer un service Windows avec PowerShell et SC (Service Control)
3. **Méthode avancée** : Créer un véritable service Windows en .NET avec PowerShell

Nous allons explorer ces différentes méthodes, en commençant par la plus simple.

### Méthode 1 : Utiliser NSSM (méthode recommandée pour les débutants)

[NSSM](https://nssm.cc/) (Non-Sucking Service Manager) est un outil gratuit qui permet de transformer facilement n'importe quel programme en service Windows, y compris PowerShell.

#### Étape 1 : Télécharger et installer NSSM

1. Téléchargez NSSM depuis [le site officiel](https://nssm.cc/download)
2. Extrayez le fichier zip dans un dossier (par exemple, `C:\Tools\NSSM`)
3. Ajoutez ce dossier au PATH de Windows ou gardez le chemin complet pour les commandes

#### Étape 2 : Créer votre script PowerShell de service

Voici un exemple simple de script qui pourrait fonctionner comme un service. Enregistrez-le sous `C:\Scripts\MonService.ps1` :

```powershell
# Démarrer la journalisation
$logPath = "C:\Logs\MonService"
if (-not (Test-Path $logPath)) { New-Item -Path $logPath -ItemType Directory -Force }
Start-Transcript -Path "$logPath\MonService_$(Get-Date -Format 'yyyyMMdd').log" -Append

Write-Output "Service démarré à $(Get-Date)"

# Fonction pour notre traitement principal
function Faire-Traitement {
    param($iteration)

    Write-Output "Traitement #$iteration en cours à $(Get-Date -Format 'HH:mm:ss')"

    # Exemple : vérifier l'espace disque disponible
    $disqueC = Get-PSDrive C
    $espaceLibreGB = [math]::Round($disqueC.Free / 1GB, 2)

    Write-Output "Espace libre sur C: $espaceLibreGB GB"

    # Exemple : vérifier les services critiques
    $services = @("wuauserv", "BITS", "Spooler")
    foreach ($service in $services) {
        $status = (Get-Service -Name $service -ErrorAction SilentlyContinue).Status
        Write-Output "Service $service est $status"
    }

    # Simuler un traitement quelconque
    Start-Sleep -Seconds 2
}

# Boucle principale qui s'exécutera indéfiniment
$iteration = 1
try {
    while ($true) {
        Faire-Traitement -iteration $iteration
        $iteration++

        # Attendre 60 secondes avant la prochaine vérification
        Write-Output "En attente pendant 60 secondes..."
        Start-Sleep -Seconds 60
    }
}
catch {
    # Journaliser toute erreur
    Write-Output "ERREUR : $($_.Exception.Message)"
    Write-Output $_.ScriptStackTrace
}
finally {
    # S'assurer que la journalisation est bien arrêtée
    Write-Output "Service arrêté à $(Get-Date)"
    Stop-Transcript
}
```

Ce script simple :
- Crée un journal de son activité
- S'exécute dans une boucle infinie
- Effectue un traitement toutes les 60 secondes (vérification de l'espace disque et des services)
- Gère les erreurs pour éviter que le service ne s'arrête brutalement

#### Étape 3 : Créer un wrapper batch pour le script PowerShell

Pour plus de robustesse, créez un fichier batch qui lancera PowerShell. Enregistrez-le sous `C:\Scripts\LanceMonService.bat` :

```batch
@echo off
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\MonService.ps1"
```

#### Étape 4 : Installer le service avec NSSM

Ouvrez une invite de commande en tant qu'administrateur et exécutez :

```
nssm.exe install "MonServicePowerShell" "C:\Scripts\LanceMonService.bat"
```

Cela ouvre une interface graphique où vous pouvez configurer votre service :

Dans l'onglet **Application** :
- **Path** : `C:\Scripts\LanceMonService.bat` (le batch file)
- **Startup directory** : `C:\Scripts` (le dossier contenant vos scripts)
- **Service name** : MonServicePowerShell (ou autre nom de votre choix)
- **Description** : Mon premier service PowerShell

Dans l'onglet **Details** :
- **Display name** : Mon Service PowerShell
- **Description** : Service de surveillance créé avec PowerShell
- **Startup type** : Automatic (démarrage avec Windows)

Dans l'onglet **I/O** :
- **Output (stdout)** : `C:\Logs\MonService\service_output.log`
- **Error (stderr)** : `C:\Logs\MonService\service_error.log`

Cliquez sur **Install service** pour finaliser l'installation.

#### Étape 5 : Démarrer et tester le service

Vous pouvez maintenant gérer votre service comme n'importe quel autre service Windows :

```powershell
# Démarrer le service
Start-Service -Name "MonServicePowerShell"

# Vérifier son statut
Get-Service -Name "MonServicePowerShell"

# Arrêter le service (lorsque vous voulez le désactiver)
Stop-Service -Name "MonServicePowerShell"
```

Vous pouvez également utiliser le Gestionnaire des services Windows (`services.msc`) pour voir et gérer votre service.

#### Étape 6 : Vérifier les journaux

Pour vérifier si votre service fonctionne correctement, examinez les fichiers de journalisation :

```powershell
# Afficher les dernières lignes du journal de transcription
Get-Content -Path "C:\Logs\MonService\MonService_$(Get-Date -Format 'yyyyMMdd').log" -Tail 20

# Afficher les erreurs éventuelles
Get-Content -Path "C:\Logs\MonService\service_error.log"
```

### Méthode 2 : Utiliser SC (Service Control)

Pour ceux qui préfèrent éviter l'installation d'outils tiers, vous pouvez utiliser la commande `sc.exe` native de Windows.

#### Étape 1 : Créer un exécutable PowerShell

Tout d'abord, enregistrez le script suivant en tant que `ServiceWrapper.ps1` :

```powershell
$scriptPath = "C:\Scripts\MonService.ps1"

# Créer le code C# pour le wrapper de service
$serviceCode = @"
using System;
using System.ServiceProcess;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.ComponentModel;

public enum ServiceType : int {
    SERVICE_WIN32_OWN_PROCESS = 0x00000010,
    SERVICE_WIN32_SHARE_PROCESS = 0x00000020,
}

public enum ServiceState : int {
    SERVICE_STOPPED = 0x00000001,
    SERVICE_START_PENDING = 0x00000002,
    SERVICE_STOP_PENDING = 0x00000003,
    SERVICE_RUNNING = 0x00000004,
    SERVICE_CONTINUE_PENDING = 0x00000005,
    SERVICE_PAUSE_PENDING = 0x00000006,
    SERVICE_PAUSED = 0x00000007,
}

[StructLayout(LayoutKind.Sequential)]
public struct ServiceStatus {
    public ServiceType dwServiceType;
    public ServiceState dwCurrentState;
    public int dwControlsAccepted;
    public int dwWin32ExitCode;
    public int dwServiceSpecificExitCode;
    public int dwCheckPoint;
    public int dwWaitHint;
}

public class PowerShellService : ServiceBase {
    private Process process;
    private ServiceStatus serviceStatus;

    public PowerShellService() {
        this.ServiceName = "MonServicePowerShell";
        this.EventLog.Log = "Application";
        this.AutoLog = true;
    }

    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool SetServiceStatus(IntPtr handle, ref ServiceStatus serviceStatus);

    protected override void OnStart(string[] args) {
        process = new Process();
        process.StartInfo.FileName = "powershell.exe";
        process.StartInfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File \\"$scriptPath\\"";
        process.StartInfo.UseShellExecute = false;
        process.StartInfo.RedirectStandardOutput = true;
        process.StartInfo.RedirectStandardError = true;
        process.StartInfo.CreateNoWindow = true;
        process.Start();

        // Mise à jour du statut du service
        serviceStatus.dwCurrentState = ServiceState.SERVICE_RUNNING;
        SetServiceStatus(this.ServiceHandle, ref serviceStatus);
    }

    protected override void OnStop() {
        if (process != null && !process.HasExited) {
            process.Kill();
            process.WaitForExit();
        }

        // Mise à jour du statut du service
        serviceStatus.dwCurrentState = ServiceState.SERVICE_STOPPED;
        SetServiceStatus(this.ServiceHandle, ref serviceStatus);
    }

    public static void Main() {
        ServiceBase.Run(new PowerShellService());
    }
}
"@

# Créer un répertoire pour compiler le service
$buildDir = "C:\Scripts\ServiceBuild"
if (-not (Test-Path $buildDir)) { New-Item -Path $buildDir -ItemType Directory -Force }

# Enregistrer le code C# dans un fichier
$serviceCode | Out-File -FilePath "$buildDir\PowerShellService.cs" -Encoding Default

# Compiler le service
Add-Type -OutputAssembly "$buildDir\PowerShellService.exe" -OutputType ConsoleApplication `
    -ReferencedAssemblies "System.ServiceProcess.dll" `
    -TypeDefinition $serviceCode -Language CSharp

Write-Host "Service compilé: $buildDir\PowerShellService.exe"
```

Exécutez ce script pour créer l'exécutable du service.

#### Étape 2 : Installer le service avec SC

Ouvrez une invite de commande en tant qu'administrateur et exécutez :

```
sc.exe create "MonServicePowerShell" binPath= "C:\Scripts\ServiceBuild\PowerShellService.exe" start= auto DisplayName= "Mon Service PowerShell"
sc.exe description "MonServicePowerShell" "Service de surveillance créé avec PowerShell"
```

> **Note** : L'espace après le signe égal est obligatoire pour SC.

#### Étape 3 : Démarrer et tester le service

```powershell
# Démarrer le service
Start-Service -Name "MonServicePowerShell"

# Vérifier son statut
Get-Service -Name "MonServicePowerShell"
```

### Méthode 3 : Créer un vrai service .NET avec PowerShell Core (méthode avancée)

Pour les utilisateurs avancés qui souhaitent une solution plus propre et moderne, vous pouvez créer un service Windows directement en PowerShell 7+.

#### Étape 1 : Installer le module de service

```powershell
Install-Module -Name Microsoft.PowerShell.PSResourceGet -Force
Install-PSResource -Name Microsoft.PowerShell.PSWindowsService -Repository PSGallery
```

#### Étape 2 : Créer le script de service

Créez un fichier nommé `AdvancedService.ps1` :

```powershell
using namespace System.ServiceProcess
using namespace System.Timers

# Importer les assemblages nécessaires
Add-Type -AssemblyName System.ServiceProcess

# Classe principale du service
class PowerShellMonitorService : ServiceBase {
    [Timer] $timer
    [string] $logPath = "C:\Logs\AdvancedService"

    PowerShellMonitorService() {
        $this.ServiceName = "PowerShellMonitorService"
        $this.CanStop = $true
        $this.CanPauseAndContinue = $false
        $this.AutoLog = $true
    }

    # Méthode appelée au démarrage du service
    [void] OnStart([string[]] $args) {
        # Configurer la journalisation
        if (-not (Test-Path $this.logPath)) {
            New-Item -Path $this.logPath -ItemType Directory -Force | Out-Null
        }

        $this.LogWrite("Service démarré à $(Get-Date)")

        # Créer et configurer le timer
        $this.timer = New-Object Timer
        $this.timer.Interval = 60000  # 60 secondes
        $this.timer.AutoReset = $true

        # Définir l'action à exécuter à chaque intervalle
        $this.timer.Elapsed.Add({
            try {
                $service = $Event.MessageData
                $service.ExecuteTask()
            }
            catch {
                $service.LogWrite("ERREUR: $($_.Exception.Message)")
            }
        })

        # Passer une référence à cette instance pour l'utiliser dans l'événement
        $this.timer.Start()
        $this.timer.Enabled = $true

        $this.LogWrite("Timer initialisé, service en cours d'exécution")
    }

    # Méthode appelée à l'arrêt du service
    [void] OnStop() {
        $this.LogWrite("Service en cours d'arrêt...")
        if ($this.timer) {
            $this.timer.Stop()
            $this.timer.Dispose()
        }
        $this.LogWrite("Service arrêté à $(Get-Date)")
    }

    # Méthode pour journaliser les événements
    [void] LogWrite([string] $message) {
        $logFile = Join-Path $this.logPath "Service_$(Get-Date -Format 'yyyyMMdd').log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $message" | Out-File -FilePath $logFile -Append
    }

    # Méthode qui sera exécutée à chaque intervalle du timer
    [void] ExecuteTask() {
        $this.LogWrite("Exécution de tâche planifiée à $(Get-Date -Format 'HH:mm:ss')")

        # Exemple : vérifier l'espace disque
        $disqueC = Get-PSDrive C
        $espaceLibreGB = [math]::Round($disqueC.Free / 1GB, 2)
        $this.LogWrite("Espace libre sur C: $espaceLibreGB GB")

        # Exemple : vérifier l'utilisation du CPU
        $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
        $cpuPercent = [math]::Round($cpuUsage.CounterSamples.CookedValue, 2)
        $this.LogWrite("Utilisation CPU: $cpuPercent%")

        # Exemple : vérifier des services critiques
        $serviceNoms = @("wuauserv", "BITS", "Spooler")
        foreach ($nom in $serviceNoms) {
            $serviceStatus = (Get-Service -Name $nom -ErrorAction SilentlyContinue).Status
            $this.LogWrite("Service $nom est $serviceStatus")
        }
    }
}

# Point d'entrée pour le service
function Main {
    # Créer et démarrer le service
    [ServiceBase[]] $services = [PowerShellMonitorService]::new()
    [ServiceBase]::Run($services)
}

# Exécution du service
Main
```

#### Étape 3 : Compiler le service

```powershell
$servicePath = "C:\Scripts\AdvancedService"
if (-not (Test-Path $servicePath)) { New-Item -Path $servicePath -ItemType Directory -Force }

# Utiliser le module PSWindowsService pour générer et compiler le service
Import-Module Microsoft.PowerShell.PSWindowsService
New-PSWindowsService -Path "C:\Scripts\AdvancedService.ps1" `
    -ServiceName "PowerShellMonitorService" `
    -DisplayName "Service de Surveillance PowerShell Avancé" `
    -Description "Service de monitoring système avancé créé en PowerShell" `
    -OutputPath "$servicePath\bin"
```

#### Étape 4 : Installer et démarrer le service

```powershell
# Installer le service
& "$servicePath\bin\InstallService.ps1"

# Démarrer le service
Start-Service -Name "PowerShellMonitorService"

# Vérifier l'état
Get-Service -Name "PowerShellMonitorService"
```

### Bonnes pratiques pour les services PowerShell

1. **Journalisation robuste**
   - Utilisez toujours `Start-Transcript` ou une méthode de journalisation personnalisée
   - Incluez l'horodatage dans le nom des fichiers journaux
   - Mettez en place une rotation des journaux pour éviter qu'ils ne deviennent trop volumineux

2. **Gestion des erreurs**
   - Enveloppez toujours votre code dans des blocs try/catch
   - Journalisez toutes les erreurs de manière détaillée
   - Évitez que des exceptions non gérées n'arrêtent votre service

3. **Gestion des ressources**
   - Libérez explicitement les ressources (connexions, handles, etc.)
   - Évitez les fuites de mémoire dans les boucles infinies
   - Utilisez le bloc `finally` pour le nettoyage

4. **Performances**
   - Surveillez l'utilisation des ressources par votre service
   - Évitez les opérations intensives en CPU qui pourraient impacter le système
   - Utilisez des intervalles raisonnables pour vos vérifications périodiques

5. **Sécurité**
   - Utilisez un compte de service dédié si possible
   - Suivez le principe du moindre privilège
   - Protégez les fichiers de journalisation et les scripts contre les accès non autorisés

### Gestion des services existants

#### Afficher les services
```powershell
# Lister tous les services
Get-Service

# Filtrer par nom
Get-Service -Name "*PowerShell*"

# Afficher les services en cours d'exécution
Get-Service | Where-Object { $_.Status -eq 'Running' }
```

#### Démarrer, arrêter et redémarrer un service
```powershell
# Démarrer un service
Start-Service -Name "MonServicePowerShell"

# Arrêter un service
Stop-Service -Name "MonServicePowerShell"

# Redémarrer un service
Restart-Service -Name "MonServicePowerShell"
```

#### Supprimer un service
```powershell
# Avec SC
sc.exe delete "MonServicePowerShell"

# Avec NSSM (si vous l'avez utilisé)
nssm.exe remove "MonServicePowerShell" confirm
```

### Exemple pratique : Service de surveillance de dossier

Voici un exemple concret d'un service qui surveille un dossier et traite automatiquement les nouveaux fichiers.

#### Script de surveillance de dossier (FolderMonitor.ps1)

```powershell
# Configurer les paramètres
$dossierAuSurveiller = "C:\Dossier_Entrant"
$dossierTraite = "C:\Dossier_Traite"
$dossierErreur = "C:\Dossier_Erreur"
$logPath = "C:\Logs\FolderMonitor"

# Créer les dossiers s'ils n'existent pas
foreach ($dossier in @($dossierAuSurveiller, $dossierTraite, $dossierErreur, $logPath)) {
    if (-not (Test-Path $dossier)) {
        New-Item -Path $dossier -ItemType Directory -Force
    }
}

# Démarrer la journalisation
Start-Transcript -Path "$logPath\FolderMonitor_$(Get-Date -Format 'yyyyMMdd').log" -Append

Write-Output "Service de surveillance de dossier démarré à $(Get-Date)"

# Fonction pour traiter un fichier
function Traiter-Fichier {
    param($cheminFichier)

    $nomFichier = Split-Path $cheminFichier -Leaf
    Write-Output "Traitement du fichier: $nomFichier"

    try {
        # Exemple: lire le contenu du fichier
        $contenu = Get-Content -Path $cheminFichier -Raw

        # Exemple: faire quelque chose avec le contenu (ici, nous ajoutons une ligne)
        $contenuModifie = $contenu + "`n# Traité le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

        # Enregistrer dans le dossier des fichiers traités
        $cheminDestination = Join-Path $dossierTraite $nomFichier
        $contenuModifie | Out-File -FilePath $cheminDestination -Force

        # Supprimer le fichier original
        Remove-Item -Path $cheminFichier -Force

        Write-Output "Fichier traité avec succès et déplacé vers: $cheminDestination"
        return $true
    }
    catch {
        Write-Output "ERREUR lors du traitement du fichier $nomFichier : $($_.Exception.Message)"

        # Déplacer le fichier problématique vers le dossier d'erreur
        $cheminErreur = Join-Path $dossierErreur $nomFichier
        Move-Item -Path $cheminFichier -Destination $cheminErreur -Force

        Write-Output "Fichier déplacé vers le dossier d'erreur: $cheminErreur"
        return $false
    }
}

# Boucle principale
$iteration = 1
try {
    while ($true) {
        Write-Output "Itération #$iteration - Vérification du dossier à $(Get-Date -Format 'HH:mm:ss')"

        # Rechercher tous les fichiers dans le dossier surveillé
        $fichiers = Get-ChildItem -Path $dossierAuSurveiller -File

        if ($fichiers.Count -gt 0) {
            Write-Output "Trouvé $($fichiers.Count) fichier(s) à traiter"

            # Traiter chaque fichier
            foreach ($fichier in $fichiers) {
                Traiter-Fichier -cheminFichier $fichier.FullName
            }
        }
        else {
            Write-Output "Aucun fichier à traiter pour le moment"
        }

        $iteration++

        # Attendre avant la prochaine vérification
        Write-Output "En attente de 30 secondes avant la prochaine vérification..."
        Start-Sleep -Seconds 30
    }
}
catch {
    # Journaliser toute erreur dans la boucle principale
    Write-Output "ERREUR CRITIQUE: $($_.Exception.Message)"
    Write-Output $_.ScriptStackTrace
}
finally {
    # S'assurer que la journalisation est bien arrêtée
    Write-Output "Service arrêté à $(Get-Date)"
    Stop-Transcript
}
```

Installez ce script en tant que service en suivant l'une des méthodes décrites précédemment.

### Conclusion

Les services PowerShell de fond vous permettent d'automatiser des tâches qui doivent s'exécuter en continu, sans intervention de l'utilisateur, et qui démarrent automatiquement avec le système. Bien que la création d'un véritable service Windows nécessite un peu plus d'effort qu'un simple script, les avantages en termes de fiabilité et de facilité de gestion sont considérables.

Pour les débutants, NSSM est la solution la plus simple et la plus flexible. À mesure que votre expérience augmente, vous pourriez préférer les méthodes plus avancées pour un meilleur contrôle.

Dans la prochaine section, nous verrons comment surveiller l'exécution de scripts PowerShell de longue durée, ce qui est particulièrement utile pour les scripts qui fonctionnent comme des services.

### Exercices pratiques

1. **Exercice simple** : Créez un service qui écrit la date et l'heure actuelles dans un fichier journal toutes les 5 minutes.

2. **Exercice intermédiaire** : Créez un service qui surveille l'utilisation du CPU et de la mémoire et envoie une alerte (par exemple, en créant un fichier dans un dossier spécifique) si l'utilisation dépasse un certain seuil.

3. **Exercice avancé** : Créez un service qui surveille un dossier partagé réseau, traite les fichiers entrants (par exemple, en compressant des images ou en convertissant des formats), et les déplace vers un dossier de destination.
