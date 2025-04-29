# Solutions des exercices pratiques - Gestion des objets AD

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## Rappel des exercices
1. Créez un utilisateur nommé "Pierre Martin" dans l'OU "Stagiaires"
2. Ajoutez cet utilisateur au groupe "Lecteurs PDF"
3. Modifiez son titre en "Stagiaire Marketing"
4. Déplacez l'utilisateur vers l'OU "Marketing"
5. Créez un script qui désactive tous les comptes utilisateurs qui n'ont pas été utilisés depuis plus de 90 jours

## Solutions détaillées

### Exercice 1 : Création d'un utilisateur dans l'OU "Stagiaires"

```powershell
# Solution de l'exercice 1
# Création de l'utilisateur Pierre Martin dans l'OU Stagiaires

# Définition du mot de passe sécurisé
$securePassword = ConvertTo-SecureString "P@ssw0rd_Init123!" -AsPlainText -Force

# Création de l'utilisateur
New-ADUser -Name "Pierre Martin" `
           -GivenName "Pierre" `
           -Surname "Martin" `
           -SamAccountName "pmartin" `
           -UserPrincipalName "pmartin@mondomaine.local" `
           -Path "OU=Stagiaires,DC=mondomaine,DC=local" `
           -AccountPassword $securePassword `
           -Enabled $true `
           -ChangePasswordAtLogon $true `
           -Description "Stagiaire - Arrivé le $(Get-Date -Format 'dd/MM/yyyy')"

# Vérification que l'utilisateur a bien été créé
Get-ADUser -Identity "pmartin" | Format-List Name, DistinguishedName
```

### Exercice 2 : Ajouter l'utilisateur au groupe "Lecteurs PDF"

```powershell
# Solution de l'exercice 2
# Ajout de Pierre Martin au groupe Lecteurs PDF

# Ajout de l'utilisateur au groupe
Add-ADGroupMember -Identity "Lecteurs PDF" -Members "pmartin"

# Vérification de l'appartenance au groupe
Get-ADGroupMember -Identity "Lecteurs PDF" | Where-Object {$_.SamAccountName -eq "pmartin"}

# Alternative : vérifier tous les groupes de l'utilisateur
Get-ADPrincipalGroupMembership -Identity "pmartin" | Select-Object Name
```

### Exercice 3 : Modification du titre en "Stagiaire Marketing"

```powershell
# Solution de l'exercice 3
# Modification du titre de Pierre Martin

# Modification du titre
Set-ADUser -Identity "pmartin" `
           -Title "Stagiaire Marketing" `
           -Department "Marketing"

# Vérification des modifications
Get-ADUser -Identity "pmartin" -Properties Title, Department |
    Select-Object Name, Title, Department
```

### Exercice 4 : Déplacement de l'utilisateur vers l'OU "Marketing"

```powershell
# Solution de l'exercice 4
# Déplacement de Pierre Martin vers l'OU Marketing

# Récupérer le Distinguished Name actuel de l'utilisateur
$userDN = (Get-ADUser -Identity "pmartin").DistinguishedName

# Déplacer l'utilisateur vers la nouvelle OU
Move-ADObject -Identity $userDN `
              -TargetPath "OU=Marketing,DC=mondomaine,DC=local"

# Vérification que l'utilisateur a bien été déplacé
Get-ADUser -Identity "pmartin" | Select-Object Name, DistinguishedName
```

### Exercice 5 : Script pour désactiver les comptes inactifs depuis plus de 90 jours

```powershell
# Solution de l'exercice 5
# Script qui désactive les comptes inactifs depuis plus de 90 jours

# Définir la date limite (aujourd'hui moins 90 jours)
$dateLimite = (Get-Date).AddDays(-90)

# Rechercher les utilisateurs inactifs
$utilisateursInactifs = Get-ADUser -Filter {Enabled -eq $true} -Properties LastLogonDate |
    Where-Object {
        # Vérifier si LastLogonDate existe et est antérieure à la date limite
        $_.LastLogonDate -ne $null -and $_.LastLogonDate -lt $dateLimite
    }

# Créer un dossier pour les logs si nécessaire
$logFolder = "C:\Scripts\Logs"
if (!(Test-Path $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force
}

# Chemin du fichier de log
$logFile = "$logFolder\Desactivation_Comptes_$(Get-Date -Format 'yyyyMMdd').log"

# Initialisation du fichier de log
"# Rapport de désactivation des comptes inactifs (plus de 90 jours)" | Out-File -FilePath $logFile
"# Date d'exécution : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" | Out-File -FilePath $logFile -Append
"# Date limite d'inactivité : $($dateLimite.ToString('dd/MM/yyyy'))" | Out-File -FilePath $logFile -Append
"" | Out-File -FilePath $logFile -Append

# Compteur pour le rapport
$compteurDesactives = 0

# Traitement des utilisateurs inactifs
foreach ($user in $utilisateursInactifs) {
    try {
        # Capture des informations avant désactivation pour le rapport
        $infosUtilisateur = [PSCustomObject]@{
            Nom = $user.Name
            SamAccountName = $user.SamAccountName
            DerniereConnexion = $user.LastLogonDate
            JoursInactivite = [math]::Round((New-TimeSpan -Start $user.LastLogonDate -End (Get-Date)).TotalDays)
        }

        # Désactivation du compte
        Set-ADUser -Identity $user.SamAccountName -Enabled $false

        # Option : déplacer vers une OU spécifique pour les comptes désactivés
        # $userDN = $user.DistinguishedName
        # Move-ADObject -Identity $userDN -TargetPath "OU=ComptesDesactives,DC=mondomaine,DC=local"

        # Ajout au rapport
        "DÉSACTIVÉ : $($infosUtilisateur.Nom) ($($infosUtilisateur.SamAccountName)) - Dernière connexion : $($infosUtilisateur.DerniereConnexion) - Inactif depuis $($infosUtilisateur.JoursInactivite) jours" |
            Out-File -FilePath $logFile -Append

        $compteurDesactives++
    }
    catch {
        # Gestion des erreurs
        "ERREUR lors de la désactivation de $($user.Name) : $($_.Exception.Message)" |
            Out-File -FilePath $logFile -Append
    }
}

# Résumé dans le rapport
"" | Out-File -FilePath $logFile -Append
"## Résumé" | Out-File -FilePath $logFile -Append
"Nombre total d'utilisateurs analysés : $($utilisateursInactifs.Count)" | Out-File -FilePath $logFile -Append
"Nombre d'utilisateurs désactivés : $compteurDesactives" | Out-File -FilePath $logFile -Append

# Affichage du résumé dans la console
Write-Host "Traitement terminé. $compteurDesactives utilisateurs ont été désactivés." -ForegroundColor Green
Write-Host "Le rapport a été enregistré dans le fichier : $logFile" -ForegroundColor Cyan

# Option : envoi du rapport par e-mail à l'administrateur
<#
Send-MailMessage -From "powershell@mondomaine.local" `
                -To "admin@mondomaine.local" `
                -Subject "Rapport de désactivation des comptes inactifs - $(Get-Date -Format 'dd/MM/yyyy')" `
                -Body "Veuillez trouver ci-joint le rapport de désactivation des comptes inactifs." `
                -Attachments $logFile `
                -SmtpServer "smtp.mondomaine.local"
#>
```

## Explications supplémentaires

### Pour l'exercice 1 :
- Nous créons un utilisateur avec les attributs de base nécessaires
- La date d'arrivée est automatiquement intégrée dans la description
- L'option `ChangePasswordAtLogon` force le stagiaire à changer son mot de passe à sa première connexion

### Pour l'exercice 2 :
- La commande `Add-ADGroupMember` est simple mais efficace
- Nous vérifions ensuite de deux façons différentes que l'utilisateur est bien membre du groupe

### Pour l'exercice 3 :
- Nous modifions à la fois le titre et le département pour plus de cohérence
- Nous utilisons `-Properties` lors de la récupération car ces attributs ne font pas partie des attributs par défaut

### Pour l'exercice 4 :
- Nous récupérons d'abord le DN (Distinguished Name) actuel de l'utilisateur
- Ensuite, nous le déplaçons vers la nouvelle OU
- La vérification confirme que le chemin a été modifié

### Pour l'exercice 5 :
- Ce script est plus élaboré car il s'agit d'une tâche d'administration courante mais critique
- Nous créons un rapport détaillé des actions effectuées
- La gestion des erreurs est incluse pour éviter l'arrêt du script en cas de problème
- Des options commentées montrent comment étendre le script (déplacement vers une OU dédiée, envoi par e-mail)
- L'utilisation de `LastLogonDate` est privilégiée car cette propriété est répliquée entre les contrôleurs de domaine

## Bonnes pratiques illustrées

1. **Vérification** : Après chaque action, nous vérifions le résultat
2. **Documentation** : Le script de l'exercice 5 crée automatiquement un journal détaillé
3. **Erreurs** : Gestion des exceptions pour éviter l'arrêt inattendu du script
4. **Flexibilité** : Paramètres configurables (90 jours d'inactivité)
5. **Rapport** : Un résumé clair des actions effectuées
