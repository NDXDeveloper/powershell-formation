#############################################################
# Module: GestionFichiers
# Description: Module d'exemple pour la gestion de fichiers
# Auteur: Formation PowerShell
# Date: 26/04/2025
#############################################################

# Variables internes au module (privées)
$script:extensionsFichiers = @{
    "Document" = @(".docx", ".doc", ".pdf", ".txt", ".rtf")
    "Image" = @(".jpg", ".jpeg", ".png", ".gif", ".bmp")
    "Vidéo" = @(".mp4", ".avi", ".mkv", ".mov", ".wmv")
    "Audio" = @(".mp3", ".wav", ".flac", ".ogg", ".aac")
    "Archive" = @(".zip", ".rar", ".7z", ".tar", ".gz")
}

#############################################################
# Fonction publique: Get-TailleDossier
# Description: Calcule la taille d'un dossier et ses sous-dossiers
#############################################################
function Get-TailleDossier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   ValueFromPipeline = $true,
                   ValueFromPipelineByPropertyName = $true,
                   HelpMessage = "Chemin du dossier à analyser")]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$Chemin,

        [Parameter(HelpMessage = "Unité de mesure pour la taille")]
        [ValidateSet("B", "KB", "MB", "GB", "TB")]
        [string]$Unite = "MB"
    )

    begin {
        Write-Verbose "Démarrage de l'analyse de taille de dossier"

        # Définir les diviseurs selon l'unité choisie
        $diviseurs = @{
            "B" = 1
            "KB" = 1KB
            "MB" = 1MB
            "GB" = 1GB
            "TB" = 1TB
        }

        $diviseur = $diviseurs[$Unite]
    }

    process {
        try {
            Write-Verbose "Analyse du dossier: $Chemin"

            # Récupérer tous les fichiers dans le dossier et sous-dossiers
            $fichiers = Get-ChildItem -Path $Chemin -Recurse -File -ErrorAction Stop

            # Calculer la taille totale
            $tailleTotale = ($fichiers | Measure-Object -Property Length -Sum).Sum

            # Convertir dans l'unité demandée
            $tailleFormatee = $tailleTotale / $diviseur

            # Créer un objet personnalisé pour le résultat
            $resultat = [PSCustomObject]@{
                Dossier = $Chemin
                Taille = [math]::Round($tailleFormatee, 2)
                Unite = $Unite
                NombreFichiers = $fichiers.Count
            }

            return $resultat
        }
        catch {
            Write-Error "Erreur lors de l'analyse du dossier '$Chemin': $_"
        }
    }

    end {
        Write-Verbose "Analyse terminée"
    }
}

#############################################################
# Fonction publique: Find-FichierParType
# Description: Recherche des fichiers par type (Document, Image, etc.)
#############################################################
function Find-FichierParType {
    [CmdletBinding(DefaultParameterSetName = "ParType")]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   HelpMessage = "Dossier dans lequel effectuer la recherche")]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$Dossier,

        [Parameter(ParameterSetName = "ParType",
                   Mandatory = $true,
                   HelpMessage = "Type de fichier à rechercher")]
        [ValidateSet("Document", "Image", "Vidéo", "Audio", "Archive")]
        [string]$Type,

        [Parameter(ParameterSetName = "ParExtension",
                   Mandatory = $true,
                   HelpMessage = "Extension spécifique à rechercher (avec le point)")]
        [ValidatePattern('^\.\w+$')]
        [string]$Extension,

        [Parameter(HelpMessage = "Indique si la recherche doit être récursive")]
        [switch]$Recursif
    )

    begin {
        Write-Verbose "Démarrage de la recherche de fichiers"

        # Paramètre pour la récursivité
        $paramRecursif = @{}
        if ($Recursif) {
            $paramRecursif = @{ Recurse = $true }
            Write-Verbose "Mode récursif activé"
        }
    }

    process {
        try {
            # Déterminer l'extension ou le type à chercher
            if ($PSCmdlet.ParameterSetName -eq "ParType") {
                Write-Verbose "Recherche par type: $Type"
                $extensions = $script:extensionsFichiers[$Type]
                $filtre = $extensions | ForEach-Object { "*$_" }
            }
            else {
                Write-Verbose "Recherche par extension: $Extension"
                $filtre = "*$Extension"
            }

            # Effectuer la recherche
            $resultats = Get-ChildItem -Path $Dossier -File @paramRecursif |
                         Where-Object {
                             $fichier = $_
                             if ($PSCmdlet.ParameterSetName -eq "ParType") {
                                 $extensions | ForEach-Object { $fichier.Name -like "*$_" }
                             }
                             else {
                                 $fichier.Name -like $filtre
                             }
                         }

            # Ajouter une propriété TypeFichier
            $resultats | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "TypeFichier" -Value (Get-TypeFichier -Extension $_.Extension) -PassThru
            }
        }
        catch {
            Write-Error "Erreur lors de la recherche de fichiers dans '$Dossier': $_"
        }
    }

    end {
        Write-Verbose "Recherche terminée"
    }
}

#############################################################
# Fonction publique: Rename-FichierBatch
# Description: Renomme un lot de fichiers selon un modèle
#############################################################
function Rename-FichierBatch {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true,
                   Position = 0,
                   HelpMessage = "Dossier contenant les fichiers à renommer")]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$Dossier,

        [Parameter(Mandatory = $true,
                   Position = 1,
                   HelpMessage = "Modèle de renommage (utiliser {0} pour le numéro)")]
        [ValidateNotNullOrEmpty()]
        [string]$Modele,

        [Parameter(HelpMessage = "Extension de fichier à cibler (avec le point)")]
        [ValidatePattern('^\.\w+$')]
        [string]$Extension = ".*",

        [Parameter(HelpMessage = "Numéro de départ pour la séquence")]
        [int]$NumeroDepart = 1,

        [Parameter(HelpMessage = "Nombre de chiffres pour le padding")]
        [ValidateRange(1, 10)]
        [int]$Padding = 3,

        [Parameter(HelpMessage = "Trier les fichiers avant renommage")]
        [ValidateSet("Nom", "Date", "Taille")]
        [string]$TriPar = "Nom",

        [Parameter(HelpMessage = "Trier en ordre décroissant")]
        [switch]$Decroissant
    )

    begin {
        Write-Verbose "Préparation du renommage batch dans le dossier: $Dossier"

        # Déterminer le paramètre de tri
        $paramTri = @{
            Property = switch ($TriPar) {
                "Nom" { "Name" }
                "Date" { "LastWriteTime" }
                "Taille" { "Length" }
            }
        }

        if ($Decroissant) {
            $paramTri.Add("Descending", $true)
        }
    }

    process {
        try {
            # Récupérer les fichiers correspondant au critère d'extension
            $fichiers = Get-ChildItem -Path $Dossier -File |
                        Where-Object { $_.Extension -like $Extension } |
                        Sort-Object @paramTri

            $nombreFichiers = $fichiers.Count
            Write-Verbose "Nombre de fichiers à renommer: $nombreFichiers"

            # Renommer chaque fichier
            $compteur = $NumeroDepart
            foreach ($fichier in $fichiers) {
                $numeroFormate = "{0:D$Padding}" -f $compteur
                $nouveauNom = $Modele -replace '\{0\}', $numeroFormate

                # Conserver l'extension d'origine
                $nouveauNomComplet = "{0}{1}" -f $nouveauNom, $fichier.Extension
                $cheminComplet = Join-Path -Path $Dossier -ChildPath $nouveauNomComplet

                if ($PSCmdlet.ShouldProcess($fichier.FullName, "Renommer en $nouveauNomComplet")) {
                    Rename-Item -Path $fichier.FullName -NewName $nouveauNomComplet
                    Write-Verbose "Renommé: $($fichier.Name) -> $nouveauNomComplet"

                    # Créer un objet pour montrer le résultat
                    [PSCustomObject]@{
                        AncienNom = $fichier.Name
                        NouveauNom = $nouveauNomComplet
                        Chemin = $Dossier
                    }
                }

                $compteur++
            }
        }
        catch {
            Write-Error "Erreur lors du renommage des fichiers: $_"
        }
    }

    end {
        Write-Verbose "Opération de renommage terminée"
    }
}

#############################################################
# Fonction privée: Get-TypeFichier
# Description: Détermine le type de fichier selon son extension
# Note: Fonction interne, non exportée
#############################################################
function Get-TypeFichier {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Extension
    )

    foreach ($type in $script:extensionsFichiers.Keys) {
        if ($script:extensionsFichiers[$type] -contains $Extension.ToLower()) {
            return $type
        }
    }

    return "Autre"
}

#############################################################
# Exporter uniquement les fonctions publiques
#############################################################
Export-ModuleMember -Function Get-TailleDossier, Find-FichierParType, Rename-FichierBatch
