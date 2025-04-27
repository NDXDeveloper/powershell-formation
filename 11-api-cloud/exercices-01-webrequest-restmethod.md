# Solutions des exercices pratiques - Module 12-1

## Exercice : Récupérer les derniers articles d'un site web

Voici plusieurs solutions complètes pour récupérer et afficher les derniers articles d'un site web, en utilisant différentes approches.

### Solution 1 : Utilisation d'un flux RSS avec Invoke-RestMethod

```powershell
# Script pour récupérer les derniers articles du blog PowerShell Microsoft via RSS
# Fichier: Get-BlogPosts-RSS.ps1

<#
.SYNOPSIS
    Récupère les derniers articles du blog PowerShell Microsoft.

.DESCRIPTION
    Ce script utilise Invoke-RestMethod pour récupérer le flux RSS du blog PowerShell Microsoft,
    puis extrait et affiche les titres, dates et liens des articles récents.

.NOTES
    Auteur: Votre Nom
    Date: 27/04/2025
    Version: 1.0
#>

# URL du flux RSS du blog PowerShell Microsoft
$rssUrl = "https://devblogs.microsoft.com/powershell/feed/"

try {
    # Récupération du flux RSS
    Write-Host "Récupération des derniers articles du blog PowerShell..." -ForegroundColor Cyan
    $rssFeed = Invoke-RestMethod -Uri $rssUrl -ErrorAction Stop

    # Traitement et affichage des articles
    Write-Host "`nDerniers articles du blog PowerShell Microsoft:`n" -ForegroundColor Green

    # Création d'un tableau personnalisé avec les articles
    $articles = $rssFeed.channel.item | Select-Object -First 10 | ForEach-Object {
        [PSCustomObject]@{
            Titre = $_.title
            Date = [DateTime]$_.pubDate | Get-Date -Format "dd/MM/yyyy"
            Lien = $_.link
        }
    }

    # Affichage du tableau
    $articles | Format-Table -AutoSize

    # Enregistrement des résultats dans un fichier CSV (optionnel)
    $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "PowerShellBlogArticles.csv"
    $articles | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Les résultats ont été enregistrés dans: $csvPath" -ForegroundColor Green

} catch {
    Write-Host "Erreur lors de la récupération des articles: $_" -ForegroundColor Red
}
```

### Solution 2 : Analyse HTML avec Invoke-WebRequest

```powershell
# Script pour récupérer les derniers articles d'un site d'actualités via HTML scraping
# Fichier: Get-NewsArticles-HTML.ps1

<#
.SYNOPSIS
    Récupère les derniers articles d'actualités depuis The Register.

.DESCRIPTION
    Ce script utilise Invoke-WebRequest pour récupérer et analyser la page web de The Register,
    puis extrait les titres et dates des derniers articles d'actualités.

.NOTES
    Auteur: Votre Nom
    Date: 27/04/2025
    Version: 1.0
#>

# URL du site d'actualités
$newsUrl = "https://www.theregister.com/"

try {
    # Récupération de la page web
    Write-Host "Récupération des articles d'actualités..." -ForegroundColor Cyan
    $response = Invoke-WebRequest -Uri $newsUrl -UserAgent "Mozilla/5.0" -ErrorAction Stop

    # Analyse du contenu HTML pour extraire les articles
    $articles = @()

    # The Register utilise des éléments article avec des classes spécifiques
    $articleNodes = $response.ParsedHtml.getElementsByTagName("article")

    foreach ($article in $articleNodes) {
        # Chercher le titre et la date dans chaque élément d'article
        $titleElement = $article.getElementsByTagName("h4") | Where-Object { $_.className -like "*article_title*" }
        $dateElement = $article.getElementsByTagName("div") | Where-Object { $_.className -like "*article_meta*" }

        if ($titleElement -and $dateElement) {
            # Extraire le texte et le lien
            $title = $titleElement[0].innerText.Trim()
            $link = $titleElement[0].getElementsByTagName("a")[0].href
            $dateText = $dateElement[0].innerText.Trim()

            # Ajouter à notre collection
            $articles += [PSCustomObject]@{
                Titre = $title
                Date = $dateText
                Lien = $link
            }
        }
    }

    # Affichage des résultats
    Write-Host "`nDerniers articles de The Register:`n" -ForegroundColor Green
    $articles | Select-Object -First 10 | Format-Table -AutoSize

    # Enregistrement des résultats dans un fichier CSV (optionnel)
    $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "TheRegisterArticles.csv"
    $articles | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Les résultats ont été enregistrés dans: $csvPath" -ForegroundColor Green

} catch {
    Write-Host "Erreur lors de la récupération des articles: $_" -ForegroundColor Red
}
```

### Solution 3 : Utilisation d'une API JSON avec Invoke-RestMethod

```powershell
# Script pour récupérer les derniers articles de Reddit via l'API JSON
# Fichier: Get-RedditPosts.ps1

<#
.SYNOPSIS
    Récupère les posts récents d'un subreddit spécifique.

.DESCRIPTION
    Ce script utilise l'API JSON publique de Reddit pour récupérer les posts récents
    d'un subreddit au choix, puis les affiche sous forme de tableau.

.PARAMETER Subreddit
    Le nom du subreddit à interroger (sans le r/).

.PARAMETER Limit
    Le nombre maximum de posts à récupérer.

.EXAMPLE
    .\Get-RedditPosts.ps1 -Subreddit PowerShell -Limit 5

.NOTES
    Auteur: Votre Nom
    Date: 27/04/2025
    Version: 1.0
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Subreddit = "PowerShell",

    [Parameter(Mandatory = $false)]
    [int]$Limit = 10
)

# Construction de l'URL de l'API JSON de Reddit
$apiUrl = "https://www.reddit.com/r/$Subreddit/new.json?limit=$Limit"

try {
    # Définition d'un User-Agent personnalisé (bonne pratique pour les API Reddit)
    $userAgent = "PowerShell:SujetExercice:v1.0 (by /u/VotreNomUtilisateur)"
    $headers = @{
        "User-Agent" = $userAgent
    }

    # Récupération des données JSON
    Write-Host "Récupération des posts récents du subreddit r/$Subreddit..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop

    # Traitement des données
    $posts = $response.data.children | ForEach-Object {
        $post = $_.data

        # Conversion du timestamp Unix en date
        $date = (Get-Date "1970-01-01").AddSeconds($post.created_utc)

        [PSCustomObject]@{
            Titre = $post.title
            Auteur = "u/" + $post.author
            Date = $date.ToString("dd/MM/yyyy HH:mm")
            Votes = $post.score
            Commentaires = $post.num_comments
            URL = "https://www.reddit.com" + $post.permalink
        }
    }

    # Affichage des résultats
    Write-Host "`nDerniers posts de r/$Subreddit:`n" -ForegroundColor Green
    $posts | Format-Table Titre, Auteur, Date, Votes, Commentaires -AutoSize

    # Enregistrement des résultats dans un fichier CSV (optionnel)
    $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "Reddit_${Subreddit}_Posts.csv"
    $posts | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Les résultats ont été enregistrés dans: $csvPath" -ForegroundColor Green

} catch {
    Write-Host "Erreur lors de la récupération des posts: $_" -ForegroundColor Red
}
```

### Solution 4 : Solution avancée avec menu interactif

```powershell
# Script avancé avec menu interactif pour récupérer des articles de plusieurs sources
# Fichier: Get-NewsInteractive.ps1

<#
.SYNOPSIS
    Script interactif pour récupérer des articles de différentes sources.

.DESCRIPTION
    Ce script offre un menu interactif permettant à l'utilisateur de choisir
    parmi différentes sources d'articles (RSS, API, ou HTML), puis récupère
    et affiche les derniers articles de la source sélectionnée.

.NOTES
    Auteur: Votre Nom
    Date: 27/04/2025
    Version: 1.0
#>

function Show-Menu {
    param (
        [string]$Title = "Menu des sources d'actualités"
    )
    Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Cyan
    Write-Host "1: Blog PowerShell Microsoft (RSS)" -ForegroundColor Yellow
    Write-Host "2: Actualités technologiques (HTML)" -ForegroundColor Yellow
    Write-Host "3: Reddit PowerShell (API JSON)" -ForegroundColor Yellow
    Write-Host "Q: Quitter" -ForegroundColor Red
    Write-Host "=============================================" -ForegroundColor Cyan
}

function Get-PowerShellBlogPosts {
    $rssUrl = "https://devblogs.microsoft.com/powershell/feed/"

    try {
        Write-Host "Récupération des articles du blog PowerShell..." -ForegroundColor Cyan
        $rssFeed = Invoke-RestMethod -Uri $rssUrl -ErrorAction Stop

        $articles = $rssFeed.channel.item | Select-Object -First 10 | ForEach-Object {
            [PSCustomObject]@{
                Titre = $_.title
                Date = [DateTime]$_.pubDate | Get-Date -Format "dd/MM/yyyy"
                Auteur = $_.creator
                Lien = $_.link
            }
        }

        return $articles
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $null
    }
}

function Get-TechNews {
    $newsUrl = "https://www.techrepublic.com/"

    try {
        Write-Host "Récupération des actualités technologiques..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $newsUrl -UserAgent "Mozilla/5.0" -ErrorAction Stop

        $articles = @()

        # Note: Cette partie dépend de la structure HTML spécifique du site
        # et pourrait nécessiter des ajustements si le site change
        $articleNodes = $response.ParsedHtml.getElementsByTagName("article")

        foreach ($article in $articleNodes) {
            $titleElement = $article.getElementsByTagName("h4")
            $dateElement = $article.getElementsByTagName("time")

            if ($titleElement -and $titleElement.Length -gt 0) {
                $title = $titleElement[0].innerText.Trim()
                $date = if ($dateElement -and $dateElement.Length -gt 0) { $dateElement[0].innerText.Trim() } else { "Date inconnue" }

                $linkElement = $titleElement[0].getElementsByTagName("a")
                $link = if ($linkElement -and $linkElement.Length -gt 0) { $linkElement[0].href } else { "#" }

                $articles += [PSCustomObject]@{
                    Titre = $title
                    Date = $date
                    Lien = $link
                }
            }
        }

        return $articles | Select-Object -First 10
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $null
    }
}

function Get-RedditPosts {
    $apiUrl = "https://www.reddit.com/r/PowerShell/new.json?limit=10"
    $userAgent = "PowerShell:MenuExercice:v1.0"

    try {
        Write-Host "Récupération des posts Reddit sur PowerShell..." -ForegroundColor Cyan
        $headers = @{ "User-Agent" = $userAgent }
        $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop

        $posts = $response.data.children | ForEach-Object {
            $post = $_.data
            $date = (Get-Date "1970-01-01").AddSeconds($post.created_utc)

            [PSCustomObject]@{
                Titre = $post.title
                Date = $date.ToString("dd/MM/yyyy HH:mm")
                Auteur = "u/" + $post.author
                Votes = $post.score
                Lien = "https://www.reddit.com" + $post.permalink
            }
        }

        return $posts
    } catch {
        Write-Host "Erreur: $_" -ForegroundColor Red
        return $null
    }
}

function Export-ArticlesToCsv {
    param (
        [Parameter(Mandatory = $true)]
        [Array]$Articles,

        [Parameter(Mandatory = $true)]
        [string]$SourceName
    )

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "${SourceName}_${timestamp}.csv"

    $Articles | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Les résultats ont été enregistrés dans: $csvPath" -ForegroundColor Green
}

# Boucle principale du menu
do {
    Show-Menu
    $input = Read-Host "Veuillez faire un choix"

    switch ($input) {
        '1' {
            Clear-Host
            $articles = Get-PowerShellBlogPosts
            if ($articles) {
                Write-Host "`nDerniers articles du blog PowerShell Microsoft:" -ForegroundColor Green
                $articles | Format-Table -AutoSize

                $export = Read-Host "Voulez-vous exporter ces résultats en CSV? (O/N)"
                if ($export -eq 'O' -or $export -eq 'o') {
                    Export-ArticlesToCsv -Articles $articles -SourceName "PowerShellBlog"
                }
            }

            Write-Host "`nAppuyez sur une touche pour continuer..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '2' {
            Clear-Host
            $articles = Get-TechNews
            if ($articles) {
                Write-Host "`nDernières actualités technologiques:" -ForegroundColor Green
                $articles | Format-Table -AutoSize

                $export = Read-Host "Voulez-vous exporter ces résultats en CSV? (O/N)"
                if ($export -eq 'O' -or $export -eq 'o') {
                    Export-ArticlesToCsv -Articles $articles -SourceName "TechNews"
                }
            }

            Write-Host "`nAppuyez sur une touche pour continuer..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        '3' {
            Clear-Host
            $articles = Get-RedditPosts
            if ($articles) {
                Write-Host "`nDerniers posts du subreddit PowerShell:" -ForegroundColor Green
                $articles | Format-Table -AutoSize

                $export = Read-Host "Voulez-vous exporter ces résultats en CSV? (O/N)"
                if ($export -eq 'O' -or $export -eq 'o') {
                    Export-ArticlesToCsv -Articles $articles -SourceName "RedditPowerShell"
                }
            }

            Write-Host "`nAppuyez sur une touche pour continuer..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        'q' {
            return
        }
    }
} until ($input -eq 'q')
```

### Solution bonus : Analyse d'une API GitHub

```powershell
# Script pour récupérer les derniers commits d'un repository GitHub
# Fichier: Get-GitHubCommits.ps1

<#
.SYNOPSIS
    Récupère les derniers commits d'un repository GitHub.

.DESCRIPTION
    Ce script utilise l'API GitHub pour récupérer les derniers commits
    d'un repository donné, puis les affiche sous forme de tableau.

.PARAMETER Owner
    Le propriétaire du repository GitHub.

.PARAMETER Repo
    Le nom du repository GitHub.

.PARAMETER Count
    Le nombre de commits à récupérer.

.EXAMPLE
    .\Get-GitHubCommits.ps1 -Owner "microsoft" -Repo "PowerShell" -Count 5

.NOTES
    Auteur: Votre Nom
    Date: 27/04/2025
    Version: 1.0
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$Owner,

    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [Parameter(Mandatory = $false)]
    [int]$Count = 10
)

# Construction de l'URL de l'API GitHub
$apiUrl = "https://api.github.com/repos/$Owner/$Repo/commits?per_page=$Count"

try {
    # Définition des en-têtes pour l'API GitHub
    $headers = @{
        "Accept" = "application/vnd.github.v3+json"
        "User-Agent" = "PowerShell-GitHub-Commits-Script"
    }

    # Récupération des commits
    Write-Host "Récupération des derniers commits du repository $Owner/$Repo..." -ForegroundColor Cyan
    $commits = Invoke-RestMethod -Uri $apiUrl -Headers $headers -ErrorAction Stop

    # Traitement et affichage des commits
    $formattedCommits = $commits | ForEach-Object {
        $commitDate = [DateTime]$_.commit.author.date

        [PSCustomObject]@{
            "Hash" = $_.sha.Substring(0, 7)  # Version courte du hash
            "Auteur" = $_.commit.author.name
            "Date" = $commitDate.ToString("dd/MM/yyyy HH:mm")
            "Message" = $_.commit.message.Split("`n")[0].Trim()  # Première ligne du message
            "URL" = $_.html_url
        }
    }

    # Affichage des résultats
    Write-Host "`nDerniers commits du repository $Owner/$Repo:`n" -ForegroundColor Green
    $formattedCommits | Format-Table -AutoSize

    # Enregistrement des résultats dans un fichier CSV (optionnel)
    $csvPath = Join-Path -Path $PSScriptRoot -ChildPath "GitHub_${Owner}_${Repo}_Commits.csv"
    $formattedCommits | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
    Write-Host "Les résultats ont été enregistrés dans: $csvPath" -ForegroundColor Green

} catch {
    Write-Host "Erreur lors de la récupération des commits: $_" -ForegroundColor Red
}
```

## Notes sur les solutions

Chaque script illustre une approche différente pour récupérer et afficher des informations à partir de sources en ligne :

1. **Solution RSS** : Idéale pour les sites qui fournissent des flux RSS, cette approche est simple et structurée.
2. **Solution HTML** : Utile quand un site n'a pas d'API ou de flux RSS, mais nécessite une compréhension de la structure HTML du site.
3. **Solution API JSON** : Montre comment utiliser une API publique pour récupérer des données structurées.
4. **Solution interactive** : Combine plusieurs approches avec une interface utilisateur pour choisir la source.
5. **Solution GitHub** : Exemple pratique avec l'API GitHub, souvent utilisée dans des scénarios DevOps.

### Précautions importantes

1. **Respect des conditions d'utilisation** : Avant d'utiliser ces scripts, assurez-vous de respecter les conditions d'utilisation des sites et APIs ciblés.
2. **Rate Limiting** : De nombreuses APIs publiques ont des limites de requêtes. Ajoutez des délais si nécessaire.
3. **Maintenance** : Les structures HTML et les APIs peuvent changer. Vérifiez régulièrement le fonctionnement de vos scripts.
4. **User-Agent** : Utilisez toujours un User-Agent approprié pour identifier votre script.
5. **Gestion des erreurs** : Tous ces scripts incluent une gestion d'erreurs basique, mais vous pourriez vouloir l'améliorer selon vos besoins.

### Pour aller plus loin

- Ajoutez une pagination pour récupérer plus d'articles
- Implémentez un système de cache pour éviter de solliciter trop souvent les APIs
- Créez une interface graphique WPF ou Windows Forms pour afficher les résultats
- Combinez plusieurs sources pour créer un agrégateur d'actualités personnalisé
