# Solutions des exercices - Module 11-3: Firewall Windows Defender
# Ces scripts doivent être exécutés avec des privilèges d'administrateur

# ===================================
# Solution Exercice 1: Lister toutes les règles actives
# ===================================

function Get-ActiveFirewallRules {
    <#
    .SYNOPSIS
        Liste toutes les règles de pare-feu actives, triées par direction.

    .DESCRIPTION
        Ce script récupère et affiche toutes les règles de pare-feu Windows actuellement actives.
        Les règles sont regroupées par direction (entrante/sortante) pour une meilleure lisibilité.

    .EXAMPLE
        Get-ActiveFirewallRules

    .NOTES
        Requiert des privilèges d'administrateur pour fonctionner correctement.
    #>

    # Vérifier si le script est exécuté en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Warning "Ce script nécessite des privilèges d'administrateur pour afficher toutes les règles."
        Write-Warning "Veuillez relancer PowerShell en tant qu'administrateur."
        return
    }

    Write-Host "Récupération des règles de pare-feu actives..." -ForegroundColor Cyan

    # Récupérer et afficher les règles actives groupées par direction
    $rules = Get-NetFirewallRule |
        Where-Object Enabled -eq 'True' |
        Sort-Object Direction |
        Select-Object Name, DisplayName, Direction, Action, Profile

    # Séparer les règles entrantes et sortantes pour un meilleur affichage
    $inboundRules = $rules | Where-Object Direction -eq 'Inbound'
    $outboundRules = $rules | Where-Object Direction -eq 'Outbound'

    # Afficher le nombre de règles trouvées
    Write-Host "Règles actives trouvées: $($rules.Count) total" -ForegroundColor Green
    Write-Host "- $($inboundRules.Count) règles entrantes" -ForegroundColor Yellow
    Write-Host "- $($outboundRules.Count) règles sortantes" -ForegroundColor Yellow

    # Afficher les règles entrantes
    Write-Host "`n=== RÈGLES ENTRANTES ===" -ForegroundColor Cyan
    $inboundRules | Format-Table DisplayName, Action, Profile -AutoSize

    # Afficher les règles sortantes
    Write-Host "`n=== RÈGLES SORTANTES ===" -ForegroundColor Cyan
    $outboundRules | Format-Table DisplayName, Action, Profile -AutoSize

    # Option pour exporter les résultats
    $export = Read-Host "Voulez-vous exporter ces résultats dans un fichier CSV? (O/N)"
    if ($export -eq "O" -or $export -eq "o") {
        $dateStamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportPath = "$env:USERPROFILE\Desktop\FirewallRules_$dateStamp.csv"
        $rules | Export-Csv -Path $exportPath -NoTypeInformation -Encoding UTF8
        Write-Host "Règles exportées vers: $exportPath" -ForegroundColor Green
    }
}

# Pour exécuter la fonction:
# Get-ActiveFirewallRules


# ===================================
# Solution Exercice 2: Créer une règle pour une application
# ===================================

function New-ApplicationFirewallRule {
    <#
    .SYNOPSIS
        Crée une règle de pare-feu pour autoriser une application.

    .DESCRIPTION
        Ce script crée une règle de pare-feu Windows pour autoriser le trafic entrant
        pour une application spécifique sur les profils de réseau sélectionnés.

    .PARAMETER ApplicationPath
        Chemin complet vers l'exécutable de l'application.

    .PARAMETER RuleName
        Nom affiché pour la règle de pare-feu. Si non spécifié, utilise le nom de l'application.

    .PARAMETER NetworkProfiles
        Profils réseau auxquels la règle s'applique. Par défaut: Domain,Private
        Options: Domain, Private, Public ou une combinaison.

    .EXAMPLE
        New-ApplicationFirewallRule -ApplicationPath "C:\Program Files\MyApp\MyApp.exe"

    .EXAMPLE
        New-ApplicationFirewallRule -ApplicationPath "C:\Program Files\MyApp\MyApp.exe" -RuleName "Mon Application" -NetworkProfiles "Private,Domain"

    .NOTES
        Requiert des privilèges d'administrateur pour fonctionner correctement.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ApplicationPath,

        [Parameter(Mandatory = $false)]
        [string]$RuleName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Domain", "Private", "Public", "Domain,Private", "Domain,Public", "Private,Public", "Domain,Private,Public")]
        [string]$NetworkProfiles = "Domain,Private"
    )

    # Vérifier si le script est exécuté en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Error "Ce script nécessite des privilèges d'administrateur pour créer des règles de pare-feu."
        Write-Warning "Veuillez relancer PowerShell en tant qu'administrateur."
        return
    }

    # Si le nom de la règle n'est pas spécifié, utiliser le nom du fichier
    if (-not $RuleName) {
        $RuleName = "Autoriser $((Get-Item $ApplicationPath).BaseName)"
    }

    # Vérifier si une règle avec ce nom existe déjà
    $existingRule = Get-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

    if ($existingRule) {
        Write-Warning "Une règle avec le nom '$RuleName' existe déjà."
        $overwrite = Read-Host "Voulez-vous remplacer cette règle? (O/N)"

        if ($overwrite -eq "O" -or $overwrite -eq "o") {
            Remove-NetFirewallRule -DisplayName $RuleName
            Write-Host "Règle existante supprimée." -ForegroundColor Yellow
        } else {
            $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
            $RuleName = "$RuleName ($timestamp)"
            Write-Host "Utilisation du nouveau nom: $RuleName" -ForegroundColor Yellow
        }
    }

    # Créer la règle de pare-feu
    try {
        Write-Host "Création de la règle de pare-feu pour: $ApplicationPath" -ForegroundColor Cyan

        New-NetFirewallRule -DisplayName $RuleName `
                           -Direction Inbound `
                           -Program $ApplicationPath `
                           -Action Allow `
                           -Profile $NetworkProfiles `
                           -Description "Règle créée automatiquement le $(Get-Date -Format 'dd/MM/yyyy à HH:mm')" | Out-Null

        Write-Host "Règle de pare-feu '$RuleName' créée avec succès!" -ForegroundColor Green
        Write-Host "  - Application: $ApplicationPath" -ForegroundColor White
        Write-Host "  - Direction: Entrante" -ForegroundColor White
        Write-Host "  - Action: Autoriser" -ForegroundColor White
        Write-Host "  - Profils: $NetworkProfiles" -ForegroundColor White

        # Proposer de créer une règle sortante également
        $createOutbound = Read-Host "Voulez-vous également créer une règle sortante pour cette application? (O/N)"

        if ($createOutbound -eq "O" -or $createOutbound -eq "o") {
            $outboundRuleName = "$RuleName (Sortant)"

            New-NetFirewallRule -DisplayName $outboundRuleName `
                               -Direction Outbound `
                               -Program $ApplicationPath `
                               -Action Allow `
                               -Profile $NetworkProfiles `
                               -Description "Règle sortante créée automatiquement le $(Get-Date -Format 'dd/MM/yyyy à HH:mm')" | Out-Null

            Write-Host "Règle sortante '$outboundRuleName' créée avec succès!" -ForegroundColor Green
        }

    } catch {
        Write-Error "Erreur lors de la création de la règle de pare-feu: $_"
    }
}

# Pour exécuter la fonction:
# New-ApplicationFirewallRule -ApplicationPath "C:\Windows\System32\notepad.exe" -RuleName "Autoriser Notepad" -NetworkProfiles "Private,Domain"


# ===================================
# Script bonus: Gestionnaire de règles de pare-feu
# ===================================

function Show-FirewallManager {
    <#
    .SYNOPSIS
        Interface interactive pour gérer les règles de pare-feu Windows.

    .DESCRIPTION
        Ce script offre une interface menu-driven pour gérer les règles de pare-feu Windows.
        Il permet de lister, créer, modifier, activer/désactiver et supprimer des règles.

    .EXAMPLE
        Show-FirewallManager

    .NOTES
        Requiert des privilèges d'administrateur pour fonctionner correctement.
    #>

    # Vérifier si le script est exécuté en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Error "Ce script nécessite des privilèges d'administrateur."
        Write-Warning "Veuillez relancer PowerShell en tant qu'administrateur."
        return
    }

    function Show-Menu {
        Clear-Host
        Write-Host "=======================================" -ForegroundColor Cyan
        Write-Host "   GESTIONNAIRE DE PARE-FEU WINDOWS    " -ForegroundColor Cyan
        Write-Host "=======================================" -ForegroundColor Cyan
        Write-Host "1: Afficher toutes les règles actives" -ForegroundColor Yellow
        Write-Host "2: Rechercher une règle par nom" -ForegroundColor Yellow
        Write-Host "3: Créer une nouvelle règle d'application" -ForegroundColor Yellow
        Write-Host "4: Créer une nouvelle règle de port" -ForegroundColor Yellow
        Write-Host "5: Activer/Désactiver une règle existante" -ForegroundColor Yellow
        Write-Host "6: Supprimer une règle" -ForegroundColor Yellow
        Write-Host "7: Afficher l'état des profils de pare-feu" -ForegroundColor Yellow
        Write-Host "8: Sauvegarder la configuration actuelle" -ForegroundColor Yellow
        Write-Host "0: Quitter" -ForegroundColor Red
        Write-Host "=======================================" -ForegroundColor Cyan
    }

    function Search-FirewallRule {
        param([string]$searchPattern)

        $rules = Get-NetFirewallRule -DisplayName "*$searchPattern*" |
                 Select-Object Name, DisplayName, Enabled, Direction, Action,
                          @{Name='Protocol'; Expression={(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_).Protocol}},
                          @{Name='LocalPort'; Expression={(Get-NetFirewallPortFilter -AssociatedNetFirewallRule $_).LocalPort}},
                          @{Name='Program'; Expression={(Get-NetFirewallApplicationFilter -AssociatedNetFirewallRule $_).Program}},
                          Profile

        if ($rules) {
            $rules | Format-Table -AutoSize
            return $rules
        } else {
            Write-Warning "Aucune règle trouvée avec le motif: '$searchPattern'"
            return $null
        }
    }

    do {
        Show-Menu
        $choice = Read-Host "Entrez votre choix"

        switch ($choice) {
            "1" {
                # Afficher toutes les règles actives
                Write-Host "`nRécupération des règles actives..." -ForegroundColor Cyan
                Get-NetFirewallRule | Where-Object Enabled -eq 'True' |
                    Format-Table DisplayName, Direction, Action, Profile -AutoSize
                Read-Host "Appuyez sur Entrée pour continuer"
            }

            "2" {
                # Rechercher une règle par nom
                $searchPattern = Read-Host "Entrez un terme de recherche"
                Search-FirewallRule -searchPattern $searchPattern
                Read-Host "Appuyez sur Entrée pour continuer"
            }

            "3" {
                # Créer une règle d'application
                $appPath = Read-Host "Entrez le chemin complet de l'application"

                if (Test-Path $appPath -PathType Leaf) {
                    $ruleName = Read-Host "Entrez un nom pour la règle (laisser vide pour nom automatique)"
                    $profiles = Read-Host "Entrez les profils (Domain,Private,Public) [Par défaut: Domain,Private]"

                    if ([string]::IsNullOrEmpty($profiles)) {
                        $profiles = "Domain,Private"
                    }

                    if ([string]::IsNullOrEmpty($ruleName)) {
                        New-ApplicationFirewallRule -ApplicationPath $appPath -NetworkProfiles $profiles
                    } else {
                        New-ApplicationFirewallRule -ApplicationPath $appPath -RuleName $ruleName -NetworkProfiles $profiles
                    }
                } else {
                    Write-Warning "Le fichier spécifié n'existe pas: $appPath"
                }
                Read-Host "Appuyez sur Entrée pour continuer"
            }

            "4" {
                # Créer une règle de port
                $portNumber = Read-Host "Entrez le numéro de port"
                $protocol = Read-Host "Entrez le protocole (TCP/UDP) [Par défaut: TCP]"
                $direction = Read-Host "Entrez la direction (Inbound/Outbound) [Par défaut: Inbound]"
                $action = Read-Host "Entrez l'action (Allow/Block) [Par défaut: Allow]"
                $ruleName = Read-Host "Entrez un nom pour la règle"

                if ([string]::IsNullOrEmpty($protocol)) { $protocol = "TCP" }
                if ([string]::IsNullOrEmpty($direction)) { $direction = "Inbound" }
                if ([string]::IsNullOrEmpty($action)) { $action = "Allow" }
                if ([string]::IsNullOrEmpty($ruleName)) { $ruleName = "$action $protocol port $portNumber ($direction)" }

                try {
                    New-NetFirewallRule -DisplayName $ruleName `
                                      -Direction $direction `
                                      -LocalPort $portNumber `
                                      -Protocol $protocol `
                                      -Action $action `
                                      -Profile "Domain,Private" | Out-Null

                    Write-Host "Règle de port créée avec succès!" -ForegroundColor Green
                } catch {
                    Write-Error "Erreur lors de la création de la règle: $_"
                }
                Read-Host "Appuyez sur Entrée pour continuer"
            }

            "5" {
                # Activer/Désactiver une règle
                $searchPattern = Read-Host "Entrez le nom de la règle à modifier"
                $rules = Search-FirewallRule -searchPattern $searchPattern

                if ($rules -and $rules.Count -gt 0) {
                    $ruleNumber = Read-Host "Entrez le numéro de la règle à modifier (1-$($rules.Count))"

                    if ([int]::TryParse($ruleNumber, [ref]$null) -and [int]$ruleNumber -ge 1 -and [int]$ruleNumber -le $rules.Count) {
                        $selectedRule = $rules[$ruleNumber - 1]
                        $currentState = $selectedRule.Enabled

                        if ($currentState -eq "True") {
                            Disable-NetFirewallRule -DisplayName $selectedRule.DisplayName
                            Write-Host "Règle désactivée: $($selectedRule.DisplayName)" -ForegroundColor Yellow
                        } else {
                            Enable-NetFirewallRule -DisplayName $selectedRule.DisplayName
                            Write-Host "Règle activée: $($selectedRule.DisplayName)" -ForegroundColor Green
                        }
                    } else {
                        Write-Warning "Numéro de règle invalide."
                    }
                }
                Read-Host "Appuyez sur Entrée pour continuer"
            }

            "6" {
                # Supprimer une règle
                $searchPattern = Read-Host "Entrez le nom de la règle à supprimer"
                $rules = Search-FirewallRule -searchPattern $searchPattern

                if ($rules -and $rules.Count -gt 0) {
                    $ruleNumber = Read-Host "Entrez le numéro de la règle à supprimer (1-$($rules.Count))"

                    if ([int]::TryParse($ruleNumber, [ref]$null) -and [int]$ruleNumber -ge 1 -and [int]$ruleNumber -le $rules.Count) {
                        $selectedRule = $rules[$ruleNumber - 1]
                        $confirm = Read-Host "Êtes-vous sûr de vouloir supprimer '$($selectedRule.DisplayName)'? (O/N)"

                        if ($confirm -eq "O" -or $confirm -eq "o") {
                            Remove-NetFirewallRule -DisplayName $selectedRule.DisplayName
                            Write-Host "Règle supprimée: $($selectedRule.DisplayName)" -ForegroundColor Red
                        }
                    } else {
                        Write-Warning "Numéro de règle invalide."
                    }
                }
                Read-Host "Appuyez sur Entrée pour continuer"
            }

            "7" {
                # Afficher l'état des profils
                Write-Host "`nÉtat des profils de pare-feu:" -ForegroundColor Cyan
                Get-NetFirewallProfile | Format-Table Name, Enabled, DefaultInboundAction, DefaultOutboundAction -AutoSize
                Read-Host "Appuyez sur Entrée pour continuer"
            }

            "8" {
                # Sauvegarder la configuration
                $date = Get-Date -Format "yyyyMMdd_HHmmss"
                $backupPath = "$env:USERPROFILE\Desktop\FirewallBackup_$date.wfw"

                try {
                    netsh advfirewall export $backupPath | Out-Null
                    Write-Host "Configuration de pare-feu sauvegardée avec succès dans:" -ForegroundColor Green
                    Write-Host $backupPath -ForegroundColor Yellow
                    Write-Host "Pour restaurer cette configuration ultérieurement, utilisez la commande:" -ForegroundColor Cyan
                    Write-Host "netsh advfirewall import '$backupPath'" -ForegroundColor White
                } catch {
                    Write-Error "Erreur lors de la sauvegarde: $_"
                }
                Read-Host "Appuyez sur Entrée pour continuer"
            }
        }
    } while ($choice -ne "0")
}

# Pour exécuter le gestionnaire de règles:
# Show-FirewallManager
