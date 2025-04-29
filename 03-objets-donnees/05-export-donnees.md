# Module 4 - Objets et traitement de données
## 4-5. Export de données (CSV, JSON, XML)

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

### 📘 Introduction

Une fois que vous avez collecté, manipulé et analysé vos données dans PowerShell, l'étape suivante consiste souvent à les exporter dans un format que d'autres applications peuvent comprendre. PowerShell facilite grandement cette tâche grâce à ses cmdlets d'exportation intégrées.

Dans cette section, nous découvrirons comment transformer vos objets PowerShell en fichiers CSV, JSON et XML - trois formats universels qui peuvent être utilisés presque partout.

### 🔄 Pourquoi exporter vos données?

- **Partage** : Envoyer vos résultats à des collègues qui n'utilisent pas PowerShell
- **Intégration** : Connecter vos scripts PowerShell à d'autres systèmes ou applications
- **Sauvegarde** : Conserver vos données pour une utilisation ultérieure
- **Reporting** : Créer des rapports lisibles par Excel ou d'autres outils d'analyse

### 📊 Export au format CSV

#### Qu'est-ce que le CSV?

CSV (Comma-Separated Values) est un format simple où chaque ligne représente un enregistrement et les valeurs sont séparées par des virgules. C'est parfait pour les données tabulaires et il est reconnu par Excel et de nombreux autres outils.

#### Export de base avec `Export-Csv`

```powershell
# Récupérer tous les services et les exporter en CSV
Get-Service | Export-Csv -Path C:\temp\services.csv
```

Par défaut, cette commande inclut une ligne d'en-tête technique. Pour l'éviter:

```powershell
Get-Service | Export-Csv -Path C:\temp\services.csv -NoTypeInformation
```

#### Spécifier les colonnes à exporter

Vous pouvez contrôler les propriétés exportées:

```powershell
Get-Process |
    Select-Object Name, Id, CPU, WorkingSet |
    Export-Csv -Path C:\temp\processus.csv -NoTypeInformation
```

#### Personnaliser le délimiteur

Par défaut, PowerShell utilise la virgule, mais vous pouvez choisir un autre caractère:

```powershell
# Utiliser le point-virgule (pratique pour Excel en français)
Get-Service | Export-Csv -Path C:\temp\services.csv -Delimiter ";" -NoTypeInformation
```

#### Exemple pratique: Rapport d'inventaire

```powershell
# Créer un rapport d'inventaire des disques
Get-Volume |
    Where-Object DriveLetter |
    Select-Object DriveLetter, FileSystemLabel,
        @{Name="Taille(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}},
        @{Name="EspaceLibre(GB)"; Expression={[math]::Round($_.SizeRemaining / 1GB, 2)}},
        @{Name="PourcentageLibre"; Expression={[math]::Round(($_.SizeRemaining / $_.Size) * 100, 1)}} |
    Export-Csv -Path C:\temp\inventaire_disques.csv -NoTypeInformation -Delimiter ";"
```

### 📝 Export au format JSON

#### Qu'est-ce que le JSON?

JSON (JavaScript Object Notation) est un format de données léger et lisible qui est largement utilisé pour les API web et le stockage structuré de données. Il est parfait pour les données hiérarchiques.

#### Export de base avec `ConvertTo-Json`

```powershell
# Récupérer les 5 processus utilisant le plus de mémoire et les exporter en JSON
Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5 |
    ConvertTo-Json | Out-File -FilePath C:\temp\top_processus.json
```

#### Contrôler la profondeur

Pour les objets complexes, la profondeur par défaut peut être insuffisante:

```powershell
# Augmenter la profondeur pour inclure plus de détails
Get-ComputerInfo | ConvertTo-Json -Depth 4 | Out-File -FilePath C:\temp\info_systeme.json
```

#### Exemple pratique: Configuration exportable

```powershell
# Créer et exporter une configuration
$config = [PSCustomObject]@{
    NomServeur = $env:COMPUTERNAME
    Date = Get-Date
    Environnement = "Production"
    BaseDeDonnees = @{
        Serveur = "SQL01"
        Instance = "MSSQLSERVER"
        Port = 1433
    }
    Applications = @(
        @{Nom = "App1"; Version = "1.0"; Chemin = "C:\Apps\App1"},
        @{Nom = "App2"; Version = "2.1"; Chemin = "C:\Apps\App2"}
    )
}

# Exporter en JSON
$config | ConvertTo-Json -Depth 4 | Out-File -FilePath C:\temp\configuration.json
```

### 📋 Export au format XML

#### Qu'est-ce que le XML?

XML (eXtensible Markup Language) est un format de données plus ancien mais très puissant et flexible. Il est utilisé dans de nombreuses applications d'entreprise et documents structurés.

#### Export de base avec `Export-Clixml`

```powershell
# Exporter les services en XML
Get-Service | Export-Clixml -Path C:\temp\services.xml
```

#### Utiliser `ConvertTo-Xml` pour plus de contrôle

```powershell
# Convertir les processus en XML avec des options personnalisées
Get-Process | Select-Object Name, Id, CPU |
    ConvertTo-Xml -NoTypeInformation |
    Out-File -FilePath C:\temp\processus.xml
```

#### Exemple pratique: Sauvegarde de configuration

```powershell
# Sauvegarder la configuration du pare-feu
Get-NetFirewallRule | Where-Object Enabled -eq $true | Export-Clixml -Path C:\temp\regles_firewall.xml
```

### 🔄 Import de données

Chaque format d'export a sa cmdlet d'import correspondante:

```powershell
# Import CSV
$services = Import-Csv -Path C:\temp\services.csv

# Import JSON
$jsonContent = Get-Content -Path C:\temp\configuration.json -Raw
$config = $jsonContent | ConvertFrom-Json

# Import XML
$servicesXml = Import-Clixml -Path C:\temp\services.xml
```

### 📊 Tableau comparatif des formats

| Format | Avantages | Inconvénients | Idéal pour |
|--------|-----------|---------------|------------|
| CSV    | Simple, compatible avec Excel | Données plates uniquement, pas de hiérarchie | Données tabulaires, reporting |
| JSON   | Supporte les hiérarchies, standard web | Moins facile à lire pour les humains | APIs, configurations, données complexes |
| XML    | Très structuré, supporte les schémas | Verbeux, plus lourd | Applications d'entreprise, échanges formels |

### 🎭 Cas d'usage avancés

#### Export hybride HTML + CSS

```powershell
# Créer un rapport HTML élégant
$htmlHead = @"
<style>
body { font-family: Arial; }
table { border-collapse: collapse; width: 100%; }
th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; }
th { background-color: #0078D7; color: white; }
tr:nth-child(even) { background-color: #f2f2f2; }
.critical { background-color: #ffcccc; }
</style>
"@

Get-Service |
    Where-Object Status -eq "Running" |
    ConvertTo-Html -Head $htmlHead -Title "Services en cours" |
    Out-File -FilePath C:\temp\rapport_services.html

# Ouvrir le rapport dans le navigateur
Invoke-Item C:\temp\rapport_services.html
```

#### Export vers Excel avec module additionnel

```powershell
# Nécessite le module ImportExcel (Install-Module ImportExcel)
if (Get-Module -ListAvailable -Name ImportExcel) {
    Get-Process |
        Sort-Object CPU -Descending |
        Select-Object -First 10 Name, ID, CPU, WorkingSet |
        Export-Excel -Path C:\temp\top_processus.xlsx -WorksheetName "Processus" -AutoSize
} else {
    Write-Warning "Module ImportExcel non installé. Utilisez 'Install-Module ImportExcel' pour l'installer."
}
```

### 💪 Exercice pratique

Créez un script qui:
1. Récupère tous les utilisateurs locaux de l'ordinateur
2. Sélectionne leurs nom, description, état (activé/désactivé) et dernière connexion
3. Exporte ces données dans les trois formats: CSV, JSON et XML
4. Bonus: Crée un rapport HTML coloré où les comptes désactivés sont en rouge

### 🎓 Solution de l'exercice

```powershell
# Récupérer les utilisateurs locaux
$utilisateurs = Get-LocalUser |
    Select-Object Name, Description, Enabled,
        @{Name="LastLogon"; Expression={if ($_.LastLogon) {$_.LastLogon} else {"Jamais"}}}

# 1. Export CSV
$utilisateurs | Export-Csv -Path "$env:USERPROFILE\Desktop\utilisateurs.csv" -NoTypeInformation -Delimiter ";"

# 2. Export JSON
$utilisateurs | ConvertTo-Json | Out-File -FilePath "$env:USERPROFILE\Desktop\utilisateurs.json"

# 3. Export XML
$utilisateurs | Export-Clixml -Path "$env:USERPROFILE\Desktop\utilisateurs.xml"

# 4. Bonus: Rapport HTML
$htmlHead = @"
<style>
body { font-family: Segoe UI; margin: 20px; }
h1 { color: #0078D7; }
table { border-collapse: collapse; width: 100%; margin-top: 20px; }
th { background-color: #0078D7; color: white; padding: 10px; text-align: left; }
td { padding: 8px; border-bottom: 1px solid #ddd; }
tr:nth-child(even) { background-color: #f2f2f2; }
.disabled { background-color: #ffcccc; }
</style>
<h1>Rapport des utilisateurs locaux</h1>
<p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm")</p>
"@

$utilisateurs |
    ConvertTo-Html -Head $htmlHead -Title "Utilisateurs locaux" -PreContent "<h1>Utilisateurs de $env:COMPUTERNAME</h1>" |
    ForEach-Object {
        if ($_ -match "<tr><td>.*</td><td>.*</td><td>False</td>") {
            $_ -replace "<tr>", "<tr class='disabled'>"
        } else {
            $_
        }
    } | Out-File -FilePath "$env:USERPROFILE\Desktop\rapport_utilisateurs.html"

Write-Host "Exports terminés! Fichiers créés sur le Bureau." -ForegroundColor Green
```

### 🔑 Points clés à retenir

- **CSV** (`Export-Csv`) est parfait pour les données tabulaires et le partage avec Excel
- **JSON** (`ConvertTo-Json`) est idéal pour les données hiérarchiques et les APIs
- **XML** (`Export-Clixml`) est utile pour les données complexes et l'interopérabilité
- Utilisez `Select-Object` avant l'export pour contrôler exactement ce qui est exporté
- Pour les données numériques, formatez-les avant l'export pour plus de lisibilité
- HTML (`ConvertTo-Html`) est excellent pour les rapports visuels et interactifs

### 🔮 Pour aller plus loin

- Explorez d'autres modules comme **ImportExcel** pour des exports Excel avancés
- Découvrez les formats d'échange plus spécialisés comme YAML ou TOML
- Dans le Module 5, nous approfondirons la lecture et l'écriture de ces formats de fichiers

---

💡 **Astuce de pro**: Pour les fichiers destinés à être ouverts avec Excel en français, utilisez toujours le point-virgule (`;`) comme délimiteur CSV et enregistrez avec l'extension `.csv`. Cela évitera les problèmes courants d'affichage dans Excel.

⏭️ [Module 5 – Gestion des fichiers et du système](/04-systeme-fichiers/README.md)
