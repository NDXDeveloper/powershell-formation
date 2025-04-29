# =============================================================================
# EXERCICES DU MODULE 4 - OBJETS ET TRAITEMENT DE DONNÉES
# Formation PowerShell – Du Débutant à l'Expert
# =============================================================================

# -----------------------------------------------------------------------------
# 4-1. Le modèle objet PowerShell - EXERCICES
# -----------------------------------------------------------------------------
<#
Exercice 4-1 :
1. Exécutez `Get-Service | Get-Member` et identifiez 3 propriétés intéressantes
2. Utilisez `$service = Get-Service | Select-Object -First 1` puis affichez ces propriétés
3. Essayez d'utiliser une méthode sur cet objet service
#>

Write-Host "`n=== SOLUTIONS EXERCICE 4-1 ===" -ForegroundColor Green

# 1. Exécuter Get-Service | Get-Member pour identifier les propriétés
# (Pas de sortie à afficher ici, l'utilisateur doit l'exécuter)

# 2. Créer une variable avec le premier service et afficher des propriétés intéressantes
$service = Get-Service | Select-Object -First 1
Write-Host "Nom du service: $($service.Name)"
Write-Host "État du service: $($service.Status)"
Write-Host "Type de démarrage: $($service.StartType)"

# 3. Utiliser une méthode sur l'objet service
Write-Host "Liste des services dépendants:"
$service.DependentServices | ForEach-Object { "- $($_.Name)" }

# -----------------------------------------------------------------------------
# 4-2. Manipulation des objets - EXERCICES
# -----------------------------------------------------------------------------
<#
Exercice 4-2 :
1. Affichez uniquement les services Windows qui sont actuellement en cours d'exécution
2. Trouvez les 3 fichiers les plus volumineux dans votre dossier utilisateur
3. Listez tous les processus qui contiennent la lettre "s" dans leur nom et utilisent plus de 50MB de mémoire
#>

Write-Host "`n=== SOLUTIONS EXERCICE 4-2 ===" -ForegroundColor Green

# 1. Services Windows en cours d'exécution
Write-Host "`n1. Services Windows en cours d'exécution:" -ForegroundColor Cyan
$servicesEnCours = Get-Service | Where-Object { $_.Status -eq "Running" }
$servicesEnCours | Select-Object -First 5 | Format-Table Name, DisplayName, Status
Write-Host "(Affichage limité aux 5 premiers services pour la lisibilité)"

# 2. Les 3 fichiers les plus volumineux dans le dossier utilisateur
Write-Host "`n2. Les 3 fichiers les plus volumineux dans le dossier utilisateur:" -ForegroundColor Cyan
$grosfichers = Get-ChildItem -Path $HOME -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object Length -Descending |
    Select-Object -First 3
$grosfichers | Format-Table Name, @{Name="Taille (MB)"; Expression={[Math]::Round($_.Length / 1MB, 2)}} -AutoSize

# 3. Processus avec "s" dans le nom et utilisant plus de 50MB
Write-Host "`n3. Processus avec 's' dans le nom et utilisant plus de 50MB:" -ForegroundColor Cyan
$processusFiltres = Get-Process |
    Where-Object { $_.Name -like "*s*" -and $_.WorkingSet -gt 50MB }
$processusFiltres |
    Select-Object Name, Id, @{Name="RAM (MB)"; Expression={[Math]::Round($_.WorkingSet / 1MB, 2)}} |
    Format-Table -AutoSize

# -----------------------------------------------------------------------------
# 4-3. Création d'objets personnalisés - EXERCICES
# -----------------------------------------------------------------------------
<#
Exercice 4-3 :
Créez un objet personnalisé qui représente un employé avec:
- Prénom, Nom
- Poste
- AnneesExperience
- Competences (un tableau de compétences)
- Une méthode `Description` qui retourne un résumé de l'employé
#>

Write-Host "`n=== SOLUTIONS EXERCICE 4-3 ===" -ForegroundColor Green

# Création d'un objet employé
$employe = [PSCustomObject]@{
    Prenom = "Marie"
    Nom = "Martin"
    Poste = "Développeuse PowerShell"
    AnneesExperience = 5
    Competences = @("PowerShell", "Azure", "Active Directory")
}

# Ajouter une méthode Description
$employe | Add-Member -MemberType ScriptMethod -Name "Description" -Value {
    "$($this.Prenom) $($this.Nom) est $($this.Poste) avec $($this.AnneesExperience) ans d'expérience. " +
    "Compétences: $($this.Competences -join ', ')"
}

# Afficher l'objet et utiliser la méthode
Write-Host "`nObjet employé créé:" -ForegroundColor Cyan
$employe | Format-List

Write-Host "`nAppel de la méthode Description:" -ForegroundColor Cyan
$employe.Description()

# -----------------------------------------------------------------------------
# 4-4. Groupement, agrégation - EXERCICES
# -----------------------------------------------------------------------------
<#
Exercice 4-4 :
Créez un script qui:
1. Liste tous les processus en cours d'exécution
2. Les groupe par leur propriété `Company`
3. Calcule pour chaque groupe:
   - Le nombre de processus
   - L'utilisation totale de mémoire
   - L'utilisation moyenne de CPU
4. Affiche les 5 compagnies qui utilisent le plus de mémoire
#>

Write-Host "`n=== SOLUTIONS EXERCICE 4-4 ===" -ForegroundColor Green

# Analyse des processus par compagnie
$rapportProcessus = Get-Process |
    Where-Object Company |
    Group-Object Company |
    ForEach-Object {
        $memoire = $_.Group | Measure-Object WorkingSet -Sum
        $cpu = $_.Group | Measure-Object CPU -Average
        [PSCustomObject]@{
            Compagnie = $_.Name
            "Nombre de processus" = $_.Count
            "Mémoire totale (MB)" = [math]::Round($memoire.Sum / 1MB, 2)
            "CPU moyen" = [math]::Round($cpu.Average, 2)
        }
    } | Sort-Object "Mémoire totale (MB)" -Descending |
    Select-Object -First 5

Write-Host "`nTop 5 des compagnies par utilisation mémoire:" -ForegroundColor Cyan
$rapportProcessus | Format-Table -AutoSize

# -----------------------------------------------------------------------------
# 4-5. Export de données - EXERCICES
# -----------------------------------------------------------------------------
<#
Exercice 4-5 :
Créez un script qui:
1. Récupère tous les utilisateurs locaux de l'ordinateur
2. Sélectionne leurs nom, description, état (activé/désactivé) et dernière connexion
3. Exporte ces données dans les trois formats: CSV, JSON et XML
4. Bonus: Crée un rapport HTML coloré où les comptes désactivés sont en rouge
#>

Write-Host "`n=== SOLUTIONS EXERCICE 4-5 ===" -ForegroundColor Green

# Créer un répertoire temporaire pour les exports (au lieu d'utiliser le Bureau)
$outputPath = Join-Path -Path $env:TEMP -ChildPath "PowerShellExercice"
if (-not (Test-Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
}

# Récupérer les utilisateurs locaux
$utilisateurs = Get-LocalUser |
    Select-Object Name, Description, Enabled,
        @{Name="LastLogon"; Expression={if ($_.LastLogon) {$_.LastLogon.ToString()} else {"Jamais"}}}

Write-Host "`nListe des utilisateurs locaux récupérés:" -ForegroundColor Cyan
$utilisateurs | Format-Table -AutoSize

# 1. Export CSV
$csvPath = Join-Path -Path $outputPath -ChildPath "utilisateurs.csv"
$utilisateurs | Export-Csv -Path $csvPath -NoTypeInformation -Delimiter ";"
Write-Host "✅ Export CSV: $csvPath" -ForegroundColor Cyan

# 2. Export JSON
$jsonPath = Join-Path -Path $outputPath -ChildPath "utilisateurs.json"
$utilisateurs | ConvertTo-Json | Out-File -FilePath $jsonPath
Write-Host "✅ Export JSON: $jsonPath" -ForegroundColor Cyan

# 3. Export XML
$xmlPath = Join-Path -Path $outputPath -ChildPath "utilisateurs.xml"
$utilisateurs | Export-Clixml -Path $xmlPath
Write-Host "✅ Export XML: $xmlPath" -ForegroundColor Cyan

# 4. Rapport HTML
$htmlPath = Join-Path -Path $outputPath -ChildPath "rapport_utilisateurs.html"

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
    } | Out-File -FilePath $htmlPath

Write-Host "✅ Rapport HTML: $htmlPath" -ForegroundColor Cyan
Write-Host "`nPour ouvrir le rapport HTML dans votre navigateur, exécutez:" -ForegroundColor Yellow
Write-Host "Invoke-Item '$htmlPath'"

# -----------------------------------------------------------------------------
# FIN DES EXERCICES
# -----------------------------------------------------------------------------
Write-Host "`n=== FIN DES EXERCICES DU MODULE 4 ===" -ForegroundColor Green
Write-Host "Tous les fichiers exportés sont disponibles dans: $outputPath" -ForegroundColor Yellow
