# Solutions des exercices et challenges - Utilisation des filtres LDAP

## Solutions des exercices pratiques

### Exercice 1
**Tous les utilisateurs dont le nom commence par "D" et qui sont dans le département "Ventes"**

```powershell
# Solution avec filtre LDAP
Get-ADUser -LDAPFilter "(&(sn=D*)(department=Ventes))" -Properties department

# Alternative avec le paramètre -Filter (plus lisible pour les débutants)
Get-ADUser -Filter "Surname -like 'D*' -and Department -eq 'Ventes'" -Properties Department
```

### Exercice 2
**Tous les ordinateurs Windows 10 (rechercher dans la description ou le système d'exploitation)**

```powershell
# Solution avec filtre LDAP - recherche dans l'attribut operatingSystem
Get-ADComputer -LDAPFilter "(operatingSystem=*Windows 10*)" -Properties operatingSystem

# Solution alternative cherchant dans la description OU le système d'exploitation
Get-ADComputer -LDAPFilter "(|(operatingSystem=*Windows 10*)(description=*Windows 10*))" -Properties operatingSystem, description

# Alternative avec le paramètre -Filter
Get-ADComputer -Filter "OperatingSystem -like '*Windows 10*'" -Properties operatingSystem
```

### Exercice 3
**Tous les utilisateurs qui n'ont pas changé leur mot de passe depuis plus de 90 jours**

```powershell
# D'abord, calculons la date d'il y a 90 jours au format LDAP
$dateActuelle = Get-Date
$date90JoursAvant = $dateActuelle.AddDays(-90)
$dateLDAP = $date90JoursAvant.ToString("yyyyMMddHHmmss") + ".0Z"

# Solution avec filtre LDAP
Get-ADUser -LDAPFilter "(&(objectClass=user)(pwdLastSet<=$dateLDAP))" -Properties pwdLastSet

# Alternative plus précise et lisible avec PowerShell
$utilisateurs = Get-ADUser -Filter * -Properties PasswordLastSet
$utilisateurs | Where-Object {
    $_.PasswordLastSet -ne $null -and
    $_.PasswordLastSet -lt $date90JoursAvant
} | Select-Object Name, SamAccountName, PasswordLastSet
```

## Solution du challenge
**Créer un script PowerShell qui génère un rapport des utilisateurs créés dans les 30 derniers jours, regroupés par département**

```powershell
# Script complet pour le challenge

# Calculer la date d'il y a 30 jours au format LDAP
$dateActuelle = Get-Date
$date30JoursAvant = $dateActuelle.AddDays(-30)
$dateLDAP = $date30JoursAvant.ToString("yyyyMMddHHmmss") + ".0Z"

# Récupérer tous les utilisateurs créés dans les 30 derniers jours
$filtreLDAP = "(&(objectClass=user)(whenCreated>=$dateLDAP))"
$utilisateursRecents = Get-ADUser -LDAPFilter $filtreLDAP -Properties whenCreated, department, title, mail

# Vérifier si des utilisateurs ont été trouvés
if ($utilisateursRecents.Count -eq 0) {
    Write-Host "Aucun utilisateur n'a été créé au cours des 30 derniers jours." -ForegroundColor Yellow
    exit
}

# Création du rapport
$rapport = $utilisateursRecents |
    Select-Object Name, SamAccountName, @{Name="DateCreation"; Expression={$_.whenCreated}},
                  @{Name="Departement"; Expression={if($_.department){$_.department}else{"Non spécifié"}}},
                  @{Name="Fonction"; Expression={if($_.title){$_.title}else{"Non spécifiée"}}},
                  @{Name="Email"; Expression={if($_.mail){$_.mail}else{"Non spécifié"}}}

# Grouper par département et générer des statistiques
$groupesParDepartement = $rapport | Group-Object -Property Departement

# Afficher un résumé
Write-Host "`n===== RÉSUMÉ DES CRÉATIONS D'UTILISATEURS SUR LES 30 DERNIERS JOURS =====" -ForegroundColor Cyan
Write-Host "Nombre total d'utilisateurs créés: $($utilisateursRecents.Count)" -ForegroundColor Green

Write-Host "`n----- Répartition par département -----" -ForegroundColor Cyan
foreach ($groupe in $groupesParDepartement) {
    Write-Host "$($groupe.Name): $($groupe.Count) utilisateur(s)" -ForegroundColor Green
}

# Afficher le détail par département
Write-Host "`n===== DÉTAIL DES UTILISATEURS PAR DÉPARTEMENT =====" -ForegroundColor Cyan

foreach ($groupe in $groupesParDepartement) {
    Write-Host "`n----- Département: $($groupe.Name) -----" -ForegroundColor Yellow
    $groupe.Group | Format-Table Name, SamAccountName, DateCreation, Fonction, Email -AutoSize
}

# Exporter en CSV si nécessaire
$dateExport = $dateActuelle.ToString("yyyyMMdd-HHmmss")
$cheminExport = ".\NouveauxUtilisateurs_$dateExport.csv"
$rapport | Export-Csv -Path $cheminExport -NoTypeInformation -Encoding UTF8

Write-Host "`nRapport exporté dans le fichier: $cheminExport" -ForegroundColor Green

# Statistiques avancées (bonus)
$plusAncien = $rapport | Sort-Object DateCreation | Select-Object -First 1
$plusRecent = $rapport | Sort-Object DateCreation -Descending | Select-Object -First 1

Write-Host "`n===== STATISTIQUES SUPPLÉMENTAIRES =====" -ForegroundColor Cyan
Write-Host "Premier utilisateur créé: $($plusAncien.Name) le $($plusAncien.DateCreation)" -ForegroundColor Green
Write-Host "Dernier utilisateur créé: $($plusRecent.Name) le $($plusRecent.DateCreation)" -ForegroundColor Green

# Afficher une visualisation textuelle simple (graphique ASCII)
Write-Host "`n===== VISUALISATION =====" -ForegroundColor Cyan
foreach ($groupe in ($groupesParDepartement | Sort-Object Count -Descending)) {
    $barreProgression = "#" * [Math]::Min($groupe.Count * 2, 50)
    Write-Host ("{0,-20}: {1} ({2})" -f $groupe.Name, $barreProgression, $groupe.Count) -ForegroundColor Green
}
```

### Explication de la solution du challenge

1. **Calcul de la date** : Nous commençons par calculer la date d'il y a 30 jours et la convertir au format LDAP.

2. **Recherche des utilisateurs** : Nous utilisons un filtre LDAP pour trouver tous les utilisateurs créés au cours des 30 derniers jours.

3. **Création du rapport** : Nous sélectionnons les propriétés intéressantes et gérons les valeurs nulles.

4. **Groupement par département** : Nous utilisons `Group-Object` pour organiser les utilisateurs par département.

5. **Affichage du résumé** : Nous présentons une vue synthétique du nombre d'utilisateurs par département.

6. **Affichage des détails** : Pour chaque département, nous listons les utilisateurs avec leurs informations.

7. **Export CSV** : Le rapport est sauvegardé dans un fichier CSV pour une utilisation ultérieure.

8. **Statistiques supplémentaires** : En bonus, nous affichons le premier et le dernier utilisateur créé.

9. **Visualisation ASCII** : Pour finir, nous ajoutons une simple visualisation sous forme de graphique à barres textuelles.

### Variante avancée du challenge (pour utilisateurs intermédiaires)

Cette variante ajoute la possibilité de choisir la période et d'envoyer le rapport par e-mail:

```powershell
# Challenge avancé - Avec paramètres et envoi par email
param(
    [int]$NombreJours = 30,
    [string]$CheminExport = ".\NouveauxUtilisateurs.csv",
    [switch]$EnvoyerEmail,
    [string]$DestinataireEmail = "admin@entreprise.com"
)

# Calculer la date au format LDAP
$dateActuelle = Get-Date
$dateAvant = $dateActuelle.AddDays(-$NombreJours)
$dateLDAP = $dateAvant.ToString("yyyyMMddHHmmss") + ".0Z"

Write-Host "Génération du rapport des utilisateurs créés depuis le $($dateAvant.ToString("dd/MM/yyyy"))" -ForegroundColor Cyan

# Récupérer les utilisateurs avec le filtre LDAP
$filtreLDAP = "(&(objectClass=user)(whenCreated>=$dateLDAP))"
$utilisateursRecents = Get-ADUser -LDAPFilter $filtreLDAP -Properties whenCreated, department, title, mail

# Code du rapport (identique à la solution précédente)
# ...

# Envoi par email si demandé
if ($EnvoyerEmail) {
    $corps = "Veuillez trouver ci-joint le rapport des utilisateurs créés au cours des $NombreJours derniers jours."
    $sujet = "Rapport des nouveaux utilisateurs AD - $($dateActuelle.ToString("dd/MM/yyyy"))"

    Send-MailMessage -To $DestinataireEmail -From "rapports@entreprise.com" `
                    -Subject $sujet -Body $corps -Attachments $CheminExport `
                    -SmtpServer "smtp.entreprise.com"

    Write-Host "Rapport envoyé par email à $DestinataireEmail" -ForegroundColor Green
}
```

## Astuces complémentaires pour les exercices

### 1. Optimiser la performance des filtres LDAP

Si vous travaillez avec un grand Active Directory, limitez les propriétés demandées:

```powershell
# Au lieu de
Get-ADUser -LDAPfilter "(department=IT)" -Properties *

# Préférez
Get-ADUser -LDAPfilter "(department=IT)" -Properties department, title, mail
```

### 2. Escapement des caractères spéciaux

Dans les filtres LDAP, certains caractères spéciaux doivent être échappés:

| Caractère | Échappement |
|-----------|-------------|
| * | \2a |
| ( | \28 |
| ) | \29 |
| \ | \5c |
| NUL | \00 |

Par exemple, pour rechercher un utilisateur avec un astérisque dans son nom:
```powershell
Get-ADUser -LDAPFilter "(cn=Jean\2aDupont)"
```

### 3. Combiner avec Where-Object pour des filtres plus complexes

```powershell
Get-ADUser -LDAPFilter "(department=IT)" -Properties whenCreated |
    Where-Object { $_.whenCreated -gt (Get-Date).AddDays(-30) }
```

Cette approche hybride utilise d'abord un filtre LDAP côté serveur puis affine avec PowerShell côté client.
