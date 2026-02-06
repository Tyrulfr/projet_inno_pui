# Connexion apprenant par identifiant et mot de passe

À chaque inscription avec `creer-apprenant-direct.bat`, le script génère **automatiquement** un **lien**, un **identifiant** et un **mot de passe**, les enregistre dans Directus (identifiant + hash du mot de passe) et affiche un bloc **« À copier dans le mail de bienvenue »**. Vous n’avez rien à configurer de plus pour cela : uniquement le .env avec DIRECTUS_URL et DIRECTUS_TOKEN.

---

## 1. Côté administrateur (vous)

### Prérequis pour l’inscription (lien + identifiant + mot de passe)

- **Directus** : collections `apprenants` et `progress` avec les champs **identifiant** et **password_hash** dans `apprenants`.  
  - Nouvelle base : exécutez `run-setup-directus.bat` (le schéma inclut ces champs).  
  - Base existante : exécutez une fois `scripts\add-apprenant-login-fields.ps1` pour ajouter les champs sans perdre les données.
- **Fichier .env** : `DIRECTUS_URL`, `DIRECTUS_TOKEN`, `SITE_BASE_URL` (optionnel).
- **Mot de passe hashé** : pour que le mot de passe soit stocké en base et que la connexion (identifiant/mdp) fonctionne plus tard, exécutez **une fois** à la racine du projet : `npm install`. Le script utilisera alors `scripts/hash-password.js` (bcrypt) pour enregistrer le mot de passe dans Directus. Sans cela, le script affiche quand même l’identifiant et le lien, mais pas de mot de passe (et l’apprenant devra utiliser uniquement le lien).

### Créer un apprenant et envoyer le mail de bienvenue

1. À la racine du projet : `creer-apprenant-direct.bat "apprenant@exemple.com"` (ou saisir l’email quand il est demandé).
2. Le script crée l’apprenant dans Directus et affiche le bloc **« À COPIER DANS LE MAIL DE BIENVENUE »** avec :
   - le **lien d’accès** (à ouvrir dans le navigateur),
   - l’**identifiant** (ex. `appr_xxxxxxxx`),
   - le **mot de passe** (si `npm install` a été fait),
   - l’URL de la **page Connexion** du site.
3. Copiez ce bloc dans votre mail de bienvenue et envoyez-le à l’apprenant. Conservez une copie : le mot de passe ne peut pas être récupéré.

**Optionnel (mode API)** : si vous avez déployé l’API et renseigné dans .env `API_BASE_URL` et `ADMIN_SECRET`, le script appellera l’API pour créer l’apprenant au lieu d’écrire directement dans Directus. Le résultat affiché (lien, identifiant, mot de passe) est le même.

---

## 2. Côté apprenant

- L’apprenant n’a **que** l’interface du site (Espace apprenant·e·s) : pas d’accès à Directus.
- Il ouvre la **page de connexion** (lien « Se connecter » sur le portail ou URL fournie par vous).
- Il saisit l’**identifiant** et le **mot de passe** reçus, puis valide.
- Après connexion, un **token** est stocké dans le navigateur ; la **progression** (grains terminés) est enregistrée et lue via l’API, donc liée à son profil dans Directus.

---

## 3. Récapitulatif technique

| Élément | Rôle |
|--------|------|
| **identifiant** | Login unique (ex. `appr_xxxxxxxx`) stocké dans `apprenants`. |
| **password_hash** | Hash bcrypt du mot de passe, stocké dans `apprenants`. |
| **token** (après login) | `external_user_id` de l’apprenant ; utilisé par l’API pour GET/POST progression. |
| **API** | `create-apprenant` (admin), `auth/login` (apprenant), `progress` (GET/POST). |

Voir aussi `docs/PROGRESSION_ET_DIRECTUS.md` pour la synchro progression et `docs/CREER_APPRENANT_ET_ENVOYER_ACCES.md` pour le lien magique (mode sans identifiant/mdp).
