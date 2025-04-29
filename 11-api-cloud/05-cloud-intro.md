# 12-5. Introduction à PowerShell + Azure / AWS / Google Cloud

🔝 Retour à la [Table des matières](/SOMMAIRE.md)

## 🌩️ PowerShell et le Cloud : Les bases

PowerShell est devenu un outil essentiel pour gérer les principales plateformes cloud. Que vous travailliez avec Microsoft Azure, Amazon Web Services (AWS) ou Google Cloud Platform (GCP), PowerShell vous offre une interface cohérente pour administrer vos ressources cloud.

## Microsoft Azure

### Installation du module Azure PowerShell

Azure est la plateforme cloud qui s'intègre le plus naturellement avec PowerShell, Microsoft étant derrière les deux technologies.

```powershell
# Installation du module Az (remplace AzureRM)
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
```

### Connexion à votre compte Azure

```powershell
# Se connecter à Azure (ouvre une fenêtre de navigateur)
Connect-AzAccount

# Vérifier votre abonnement actif
Get-AzSubscription

# Changer d'abonnement si nécessaire
Set-AzContext -SubscriptionId "votre-id-abonnement"
```

### Exemples de commandes Azure courantes

```powershell
# Lister toutes les machines virtuelles
Get-AzVM

# Créer un groupe de ressources
New-AzResourceGroup -Name "MonGroupe" -Location "westeurope"

# Démarrer une VM
Start-AzVM -ResourceGroupName "MonGroupe" -Name "MaVM"

# Récupérer des informations sur un stockage
Get-AzStorageAccount -ResourceGroupName "MonGroupe"
```

## Amazon Web Services (AWS)

### Installation du module AWS Tools for PowerShell

```powershell
# Installation du module AWS
Install-Module -Name AWSPowerShell -Scope CurrentUser -Force

# Variante : module plus léger qui charge les cmdlets à la demande
Install-Module -Name AWS.Tools.Installer -Scope CurrentUser -Force
Install-AWSToolsModule AWS.Tools.EC2, AWS.Tools.S3 -CleanUp
```

### Connexion à votre compte AWS

```powershell
# Configuration avec vos clés d'accès
Set-AWSCredential -AccessKey VOTRE_CLE_ACCES -SecretKey VOTRE_CLE_SECRETE -StoreAs MonProfil

# Utiliser un profil spécifique et définir la région par défaut
Initialize-AWSDefaultConfiguration -ProfileName MonProfil -Region eu-west-1
```

### Exemples de commandes AWS courantes

```powershell
# Lister toutes les instances EC2
Get-EC2Instance

# Récupérer les buckets S3
Get-S3Bucket

# Démarrer une instance EC2
Start-EC2Instance -InstanceId "i-1234567890abcdef0"

# Créer un bucket S3
New-S3Bucket -BucketName "mon-bucket-unique"
```

## Google Cloud Platform (GCP)

### Installation du module Google Cloud pour PowerShell

```powershell
# Installation du module Google Cloud (moins mature que les autres)
Install-Module -Name GoogleCloud -Scope CurrentUser -Force
```

### Connexion à votre compte GCP

Pour Google Cloud, l'authentification se fait généralement via gcloud CLI, mais PowerShell peut l'utiliser :

```powershell
# Utiliser le fichier d'authentification généré par gcloud
$env:GOOGLE_APPLICATION_CREDENTIALS = "C:\chemin\vers\votre-fichier-credentials.json"

# Connexion via PowerShell (après avoir installé gcloud CLI)
gcloud auth login
```

### Exemples de commandes GCP avec PowerShell

```powershell
# Utiliser Invoke-RestMethod pour interagir avec l'API Google Cloud
$token = (gcloud auth print-access-token)
$headers = @{ "Authorization" = "Bearer $token" }

# Exemple : Lister les instances de VM dans un projet
$projet = "votre-projet-id"
$zone = "europe-west1-b"
$uri = "https://compute.googleapis.com/compute/v1/projects/$projet/zones/$zone/instances"

$vms = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
$vms.items | Select-Object name, status, machineType
```

## 🔄 Comparaison des approches

| Plateforme | Maturité PowerShell | Nombre de cmdlets | Installation |
|------------|---------------------|------------------|--------------|
| Azure      | Excellente          | 5000+            | Très simple  |
| AWS        | Très bonne          | 4000+            | Simple       |
| GCP        | Limitée             | < 100            | Avancée      |

## 💡 Conseils pour débutants

1. **Commencez par explorer** : Utilisez `Get-Command -Module Az*` pour découvrir les cmdlets disponibles dans Azure.

2. **Utilisez l'aide intégrée** : `Get-Help Get-AzVM -Examples` pour voir des exemples concrets.

3. **Authentifiez-vous une seule fois** : Utilisez `Save-AzContext` pour Azure ou des profils nommés pour AWS.

4. **Créez des scripts réutilisables** : Stockez vos identifiants et paramètres communs dans des variables.

5. **Testez dans un environnement sandbox** : La plupart des fournisseurs cloud offrent des environnements de test gratuits.

## 🚀 Mini-projet : Multi-cloud VM Inventory

Voici un petit script pour récupérer l'inventaire de vos machines virtuelles sur les différentes plateformes :

```powershell
# Fonction pour récupérer les VMs de différents clouds
function Get-CloudVMInventory {
    param (
        [ValidateSet("Azure", "AWS", "All")]
        [string]$Platform = "All"
    )

    $inventory = @()

    # Azure VMs
    if ($Platform -eq "Azure" -or $Platform -eq "All") {
        try {
            $azVMs = Get-AzVM
            foreach ($vm in $azVMs) {
                $inventory += [PSCustomObject]@{
                    Name = $vm.Name
                    Platform = "Azure"
                    ResourceGroup = $vm.ResourceGroupName
                    Status = (Get-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status).Statuses[1].DisplayStatus
                    Size = $vm.HardwareProfile.VmSize
                }
            }
        } catch {
            Write-Warning "Erreur lors de la récupération des VMs Azure: $_"
        }
    }

    # AWS EC2 Instances
    if ($Platform -eq "AWS" -or $Platform -eq "All") {
        try {
            $awsVMs = Get-EC2Instance
            foreach ($reservation in $awsVMs.Reservations) {
                foreach ($instance in $reservation.Instances) {
                    $name = ($instance.Tags | Where-Object { $_.Key -eq "Name" }).Value
                    $inventory += [PSCustomObject]@{
                        Name = if ($name) { $name } else { $instance.InstanceId }
                        Platform = "AWS"
                        ResourceGroup = "N/A"
                        Status = $instance.State.Name
                        Size = $instance.InstanceType
                    }
                }
            }
        } catch {
            Write-Warning "Erreur lors de la récupération des instances EC2: $_"
        }
    }

    return $inventory
}

# Utilisation
$allVMs = Get-CloudVMInventory
$allVMs | Format-Table -AutoSize
```

## 📚 Pour aller plus loin

- Documentation Azure PowerShell : [docs.microsoft.com/powershell/azure](https://docs.microsoft.com/powershell/azure/)
- Documentation AWS Tools : [docs.aws.amazon.com/powershell](https://docs.aws.amazon.com/powershell/)
- Documentation Google Cloud : [cloud.google.com/sdk/gcloud/reference](https://cloud.google.com/sdk/gcloud/reference)

---

## ✅ Points à retenir

- PowerShell offre une interface unifiée pour gérer différentes plateformes cloud
- Azure dispose de l'intégration PowerShell la plus complète
- AWS propose des modules PowerShell bien développés
- Google Cloud nécessite souvent de combiner PowerShell avec gcloud CLI
- L'utilisation de PowerShell avec le cloud facilite l'automatisation des tâches récurrentes

⏭️ [Module 13 – Tests, CI/CD et DevOps](/12-ci-cd-tests/README.md)
