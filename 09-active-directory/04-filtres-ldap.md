# Module 10 - Active Directory & LDAP
## 10-4. Utilisation de filtres LDAP

### 🎯 Objectif
Apprendre à utiliser les filtres LDAP (Lightweight Directory Access Protocol) pour effectuer des recherches précises et optimisées dans Active Directory.

### 📘 Introduction aux filtres LDAP

Les filtres LDAP constituent un langage de requête puissant pour interroger Active Directory. Ils vous permettent de cibler très précisément les objets qui vous intéressent, souvent avec de meilleures performances que les filtres PowerShell classiques.

### 🔎 Syntaxe de base des filtres LDAP

Un filtre LDAP suit cette structure:
```
(attribut=valeur)
```

Exemples simples:
- `(cn=Jean Dupont)` - trouve un utilisateur dont le nom commun est "Jean Dupont"
- `(objectClass=user)` - trouve tous les objets de type utilisateur

### 🧩 Opérateurs LDAP courants

| Opérateur | Description | Exemple |
|-----------|-------------|---------|
| = | Égalité | `(givenName=Marie)` |
| ~= | Approximation | `(givenName~=Mari)` |
| >= | Supérieur ou égal | `(whenCreated>=20230101000000.0Z)` |
| <= | Inférieur ou égal | `(whenCreated<=20231231235959.0Z)` |
| & | ET logique | `(&(objectClass=user)(enabled=TRUE))` |
| \| | OU logique | `(|(department=IT)(department=Finance))` |
| ! | NON logique | `(!(enabled=FALSE))` |
| * | Caractère générique | `(cn=Jean*)` |

### 💻 Utilisation des filtres LDAP dans PowerShell

Dans PowerShell, vous pouvez utiliser les filtres LDAP avec les paramètres `-LDAPFilter` ou `-Filter` (pour certaines commandes):

```powershell
# Rechercher tous les utilisateurs dont le prénom commence par "Jean"
Get-ADUser -LDAPFilter "(givenName=Jean*)"

# Rechercher tous les utilisateurs du département IT
Get-ADUser -LDAPFilter "(department=IT)"
```

### 🔄 Combinaison de filtres avec les opérateurs logiques

Les filtres complexes utilisent des parenthèses et des opérateurs logiques:

```powershell
# Utilisateurs du département IT dont le compte n'est pas désactivé
Get-ADUser -LDAPFilter "(&(department=IT)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))"

# Utilisateurs du département IT ou Finance
Get-ADUser -LDAPFilter "(|(department=IT)(department=Finance))"
```

### 🛠️ Exemples pratiques

#### Exemple 1: Trouver des comptes créés dans une période spécifique
```powershell
$dateDebut = "20230101000000.0Z"  # 1er janvier 2023
$dateFin = "20230131235959.0Z"    # 31 janvier 2023

Get-ADUser -LDAPFilter "(&(objectClass=user)(whenCreated>=$dateDebut)(whenCreated<=$dateFin))"
```

#### Exemple 2: Rechercher des utilisateurs sans adresse email
```powershell
Get-ADUser -LDAPFilter "(&(objectClass=user)(!(mail=*)))" -Properties mail
```

#### Exemple 3: Comptes utilisateurs expirés
```powershell
Get-ADUser -LDAPFilter "(&(objectClass=user)(accountExpires<=133180800000000000))" -Properties accountExpires
```

### 📊 LDAP vs PowerShell Filtering

| Aspect | Filtres LDAP | Filtres PowerShell |
|--------|--------------|-------------------|
| Exécution | Côté serveur AD | Côté client PowerShell |
| Performance | Meilleure pour grandes quantités | Moins efficace sur gros volumes |
| Syntaxe | Plus complexe | Plus intuitive |
| Flexibilité | Moins flexible | Plus flexible |

### 🔍 Attributs LDAP courants pour le filtrage

| Attribut | Description | Exemple |
|----------|-------------|---------|
| sAMAccountName | Nom de connexion | `(sAMAccountName=jdupont)` |
| givenName | Prénom | `(givenName=Jean)` |
| sn | Nom de famille | `(sn=Dupont)` |
| mail | Adresse email | `(mail=jean.dupont@entreprise.com)` |
| department | Département | `(department=IT)` |
| title | Fonction | `(title=Développeur)` |
| whenCreated | Date de création | `(whenCreated>=20230101000000.0Z)` |
| memberOf | Groupe d'appartenance | `(memberOf=CN=Admins,DC=entreprise,DC=com)` |

### 📝 Exercice pratique

Essayez de créer un filtre LDAP pour trouver:
1. Tous les utilisateurs dont le nom commence par "D" et qui sont dans le département "Ventes"
2. Tous les ordinateurs Windows 10 (rechercher dans la description ou le système d'exploitation)
3. Tous les utilisateurs qui n'ont pas changé leur mot de passe depuis plus de 90 jours

### ⚠️ Points d'attention

1. **Sensibilité à la casse**: Les filtres LDAP peuvent être sensibles à la casse selon la configuration de votre domaine.
2. **Performance**: Bien que les filtres LDAP soient efficaces, des filtres trop complexes peuvent ralentir les requêtes.
3. **Formats de date**: Les dates dans LDAP suivent un format spécifique (généralement AAAAMMJJHHMMSS.0Z).
4. **Échappement des caractères**: Certains caractères spéciaux doivent être échappés dans les filtres LDAP.

### 🌟 Astuces avancées

- Utilisez le paramètre `-Properties` avec `Get-ADUser` pour récupérer des attributs supplémentaires non inclus par défaut:
  ```powershell
  Get-ADUser -LDAPFilter "(department=IT)" -Properties title, mail, department
  ```

- Combinez avec `Select-Object` pour n'afficher que les propriétés qui vous intéressent:
  ```powershell
  Get-ADUser -LDAPFilter "(department=IT)" -Properties title, mail |
  Select-Object Name, SamAccountName, title, mail
  ```

### 🔗 Ressources supplémentaires

- [Documentation Microsoft sur les filtres LDAP](https://learn.microsoft.com/fr-fr/windows/win32/adsi/search-filter-syntax)
- [Liste complète des attributs LDAP Active Directory](https://learn.microsoft.com/fr-fr/windows/win32/adschema/attributes-all)

### 🏆 Challenge

Créez un script PowerShell qui génère un rapport des utilisateurs créés dans les 30 derniers jours, regroupés par département, en utilisant des filtres LDAP.

---

Dans le prochain module (10-5), nous aborderons l'audit de l'environnement AD, incluant la détection des comptes inactifs et l'analyse des dernières connexions.
