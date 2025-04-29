# Solutions des Exercices - Module 9 - Administration Windows

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Exercice 1 - Services
**Objectif**: Lister tous les services qui démarrent automatiquement et qui sont actuellement arrêtés.

### Solution:

```powershell
# Méthode 1: Utiliser Get-Service et Get-CimInstance combinés
Get-Service |
    Where-Object Status -eq "Stopped" |
    ForEach-Object {
        $svcName = $_.Name
        $svcInfo = Get-CimInstance -ClassName Win32_Service -Filter "Name='$svcName'"
        if ($svcInfo.StartMode -eq "Auto") {
            [PSCustomObject]@{
                Nom = $svcName
                NomAffiche = $_.DisplayName
                Statut = $_.Status
                ModeDepart = $svcInfo.StartMode
            }
        }
    } | Format-Table -AutoSize

# Méthode 2: Utiliser uniquement Get-CimInstance (plus efficace)
Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto' AND State='Stopped'" |
    Select-Object Name, DisplayName, State, StartMode |
    Sort-Object -Property DisplayName
```

**Explication**:
- La première méthode utilise `Get-Service` pour obtenir tous les services arrêtés, puis vérifie leur mode de démarrage avec `Get-CimInstance`.
- La deuxième méthode est plus efficace car elle filtre directement au niveau WMI, ce qui réduit considérablement le temps d'exécution.
- Le paramètre `-Filter` dans `Get-CimInstance` utilise la syntaxe WQL (WMI Query Language), similaire à SQL.

## Exercice 2 - Processus
**Objectif**: Identifier les 5 processus consommant le plus de mémoire sur votre système.

### Solution:

```powershell
# Solution simple
Get-Process |
    Sort-Object -Property WorkingSet -Descending |
    Select-Object -First 5 -Property ProcessName, Id, @{
        Name="MemoireMB";
        Expression={[math]::Round($_.WorkingSet / 1MB, 2)}
    }

# Solution plus détaillée avec formatage
Get-Process |
    Sort-Object -Property WorkingSet -Descending |
    Select-Object -First 5 |
    Format-Table -Property ProcessName, Id, @{
        Name="Mémoire (MB)";
        Expression={"{0:N2}" -f ($_.WorkingSet / 1MB)}
    }, @{
        Name="CPU (s)";
        Expression={"{0:N2}" -f $_.CPU}
    }, @{
        Name="Threads";
        Expression={$_.Threads.Count}
    }, @{
        Name="Handles";
        Expression={$_.Handles}
    } -AutoSize
```

**Explication**:
- La propriété `WorkingSet` représente la quantité de mémoire physique utilisée par le processus en octets.
- L'expression calculée `$_.WorkingSet / 1MB` convertit la valeur en mégaoctets pour une meilleure lisibilité.
- La deuxième solution ajoute des informations supplémentaires comme le nombre de threads et de handles.

## Exercice 3 - Registre
**Objectif**: Créer une clé de registre pour votre application fictive et y ajouter quelques valeurs de configuration.

### Solution:

```powershell
# Définir le chemin de la clé de registre
$appRegistryPath = "HKCU:\Software\MaFormationPowerShell"

# Vérifier si la clé existe déjà et la supprimer pour éviter les erreurs
if (Test-Path -Path $appRegistryPath) {
    Remove-Item -Path $appRegistryPath -Recurse -Force
    Write-Host "Ancienne clé supprimée." -ForegroundColor Yellow
}

# Créer la clé principale de l'application
New-Item -Path $appRegistryPath -Force | Out-Null
Write-Host "Clé de registre créée: $appRegistryPath" -ForegroundColor Green

# Ajouter différents types de valeurs
# 1. Valeurs simples (String)
Set-ItemProperty -Path $appRegistryPath -Name "Version" -Value "1.0.0" -Type String
Set-ItemProperty -Path $appRegistryPath -Name "NomApplication" -Value "Mon Application PowerShell" -Type String

# 2. Valeur numérique (DWord)
Set-ItemProperty -Path $appRegistryPath -Name "ModeDebug" -Value 0 -Type DWord
Set-ItemProperty -Path $appRegistryPath -Name "NiveauLog" -Value 2 -Type DWord

# 3. Valeur avec variable d'environnement (ExpandString)
Set-ItemProperty -Path $appRegistryPath -Name "CheminDonnees" -Value "%APPDATA%\MaFormationPowerShell" -Type ExpandString

# 4. Tableau de chaînes (MultiString)
Set-ItemProperty -Path $appRegistryPath -Name "ModulesActifs" -Value @("Core", "Admin", "Reporting") -Type MultiString

# Créer une sous-clé pour les préférences utilisateur
$prefsPath = "$appRegistryPath\Preferences"
New-Item -Path $prefsPath -Force | Out-Null
Write-Host "Sous-clé créée: $prefsPath" -ForegroundColor Green

# Ajouter des valeurs dans la sous-clé
Set-ItemProperty -Path $prefsPath -Name "Theme" -Value "Sombre" -Type String
Set-ItemProperty -Path $prefsPath -Name "Police" -Value "Consolas" -Type String
Set-ItemProperty -Path $prefsPath -Name "TaillePolice" -Value 12 -Type DWord
Set-ItemProperty -Path $prefsPath -Name "CouleursTerminal" -Value @("#000000", "#FFFFFF", "#0078D4") -Type MultiString

# Afficher le contenu des clés créées
Write-Host "`nValeurs dans la clé principale:" -ForegroundColor Cyan
Get-ItemProperty -Path $appRegistryPath | Format-List -Property * -Force

Write-Host "`nValeurs dans la sous-clé Preferences:" -ForegroundColor Cyan
Get-ItemProperty -Path $prefsPath | Format-List -Property * -Force
```

**Explication**:
- La solution nettoie d'abord les clés existantes pour éviter les conflits.
- Elle crée ensuite une structure hiérarchique avec une clé principale et une sous-clé.
- Différents types de données du registre sont utilisés:
  - `String` pour les textes simples
  - `DWord` pour les valeurs numériques
  - `ExpandString` pour les chemins avec variables d'environnement
  - `MultiString` pour les tableaux de chaînes

## Exercice 4 - Événements
**Objectif**: Trouver les 10 dernières erreurs critiques dans le journal système.

### Solution:

```powershell
# Méthode 1: Utiliser Get-EventLog (version classique)
Write-Host "Méthode 1: Get-EventLog" -ForegroundColor Cyan
Get-EventLog -LogName System -EntryType Error -Newest 10 |
    Select-Object TimeGenerated, Source, EventID, Message |
    Format-Table -AutoSize -Wrap

# Méthode 2: Utiliser Get-WinEvent avec un filtre hashtable (recommandée)
Write-Host "`nMéthode 2: Get-WinEvent (erreurs)" -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level = 2  # 2 = Error
} -MaxEvents 10 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message

# Méthode 3: Chercher spécifiquement les événements critiques (niveau 1)
Write-Host "`nMéthode 3: Get-WinEvent (critiques)" -ForegroundColor Cyan
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level = 1  # 1 = Critical
} -MaxEvents 10 -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, ProviderName, Id, LevelDisplayName, Message

# Méthode 4: Combiner erreurs et critiques avec exportation vers CSV
Write-Host "`nMéthode 4: Erreurs et critiques combinées" -ForegroundColor Cyan
$events = Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Level = 1,2  # 1 = Critical, 2 = Error
} -MaxEvents 10 -ErrorAction SilentlyContinue |
    Select-Object @{Name="Date"; Expression={$_.TimeCreated}},
                  @{Name="Source"; Expression={$_.ProviderName}},
                  @{Name="EventID"; Expression={$_.Id}},
                  @{Name="Niveau"; Expression={$_.LevelDisplayName}},
                  @{Name="Message"; Expression={$_.Message}}

# Afficher les résultats
$events | Format-Table -AutoSize -Wrap

# Option: Exporter vers CSV (décommenter pour utiliser)
# $events | Export-Csv -Path "$env:USERPROFILE\Desktop\ErrorEvents.csv" -NoTypeInformation -Encoding UTF8
# Write-Host "Événements exportés vers le bureau." -ForegroundColor Green
```

**Explication**:
- La première méthode utilise `Get-EventLog`, qui est plus simple mais désormais considérée comme obsolète.
- La deuxième méthode utilise `Get-WinEvent` avec un filtre hashtable pour les erreurs (niveau 2).
- La troisième méthode cherche spécifiquement les événements critiques (niveau 1).
- La quatrième méthode combine les deux niveaux et prépare les données pour une exportation CSV.
- Les niveaux des événements Windows sont:
  - 1 = Critique
  - 2 = Erreur
  - 3 = Avertissement
  - 4 = Information
  - 5 = Détaillé

## Conseils et astuces supplémentaires

### Pour les services
- Pour des raisons de sécurité, limitez les redémarrages automatiques de services aux environnements de test.
- Utilisez `Suspend-Service` uniquement pour les services qui prennent en charge la pause (vérifiez avec `CanPauseAndContinue`).

### Pour les processus
- Soyez prudent avec `Stop-Process` car cela peut entraîner une perte de données non sauvegardées.
- Pour les processus avec des privilèges élevés, vous devrez exécuter PowerShell en tant qu'administrateur.

### Pour le registre
- **Toujours** faire une sauvegarde du registre avant de faire des modifications importantes:
  ```powershell
  reg export "HKCU\Software" "C:\Backup\mon_registre.reg" /y
  ```
- Pour les applications réelles, préférez stocker les configurations dans `%APPDATA%` plutôt que dans le registre.

### Pour les événements
- Créez des scripts de surveillance qui vous alertent des événements critiques.
- Pour une analyse plus poussée, envisagez d'utiliser des outils comme PowerBI avec vos exports CSV.
