# Connexion apprenant par identifiant et mot de passe

Lorsque l’API est déployée, vous pouvez créer des apprenants avec **identifiant + mot de passe** : l’apprenant se connecte sur le site (page « Se connecter ») et accède à son espace et à sa progression, liée à son profil dans Directus.

---

## 1. Côté administrateur (vous)

### Prérequis

- **Directus** : collections `apprenants` et `progress` avec les champs **identifiant** et **password_hash** dans `apprenants`.  
  - Nouvelle base : exécutez `run-setup-directus.bat` (le schéma inclut ces champs).  
  - Base existante : exécutez une fois `scripts\add-apprenant-login-fields.ps1` pour ajouter les champs sans perdre les données.
- **API déployée** (dossier `api/` sur Vercel, Scaleway Functions, etc.) avec les variables : `DIRECTUS_URL`, `DIRECTUS_TOKEN`, `ADMIN_SECRET`, `CORS_ORIGIN` (optionnel).
- **Site** : `window.PROGRESS_API_BASE` défini (URL de l’API) sur les pages apprenant (portal, login), pour la connexion et la synchro progression.

### Fichier .env (pour le script de création)

En plus de `DIRECTUS_URL`, `DIRECTUS_TOKEN`, `SITE_BASE_URL`, ajoutez :

- **API_BASE_URL** : URL de votre API (ex. `https://votre-api.vercel.app`).
- **ADMIN_SECRET** : même valeur que la variable `ADMIN_SECRET` configurée côté API (secret pour protéger la création d’apprenants).

### Créer un apprenant (identifiant + mot de passe)

1. À la racine du projet : `creer-apprenant-direct.bat "apprenant@exemple.com"`.
2. Le script appelle l’API `create-apprenant`, qui crée l’apprenant dans Directus avec un **identifiant** et un **mot de passe** générés.
3. Le script affiche :
   - **Identifiant** : ex. `appr_xxxxxxxx`
   - **Mot de passe** : ex. 12 caractères aléatoires
   - **Page de connexion** : `https://votre-site/pages/apprenant/login.html`
4. Transmettez **identifiant** et **mot de passe** à l’apprenant (email, etc.). Indiquez-lui d’ouvrir la page de connexion du site et de s’y connecter. **Conservez ces identifiants** ; le mot de passe ne peut pas être récupéré.

Si `API_BASE_URL` ou `ADMIN_SECRET` n’est pas dans le .env, le script crée l’apprenant directement dans Directus et affiche un **lien magique** (?token=...) comme avant (sans identifiant/mot de passe).

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
