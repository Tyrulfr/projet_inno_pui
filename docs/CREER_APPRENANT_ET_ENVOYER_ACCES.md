# Créer un apprenant et lui envoyer les identifiants d'accès

**Qui fait quoi** : c’est l’**administrateur** qui utilise le script (creer-apprenant-direct.bat) et Directus pour créer le profil et obtenir le lien. L’**apprenant** ne se connecte pas à Directus et n’utilise pas le .bat : il reçoit le lien et se connecte uniquement au **site inno_pui** (projet_inno_pui), sur l’Espace apprenant·e·s (ex. [GitHub Pages](https://tyrulfr.github.io/projet_inno_pui/)).

Pour un apprenant **direct** (hors Moodle, hors FunMooc), on crée un **profil apprenant** dans Directus et on lui envoie un **lien d’accès unique** (token) vers **le site** (Espace apprenants). Plus tard, ce token permettra au site de sauvegarder sa progression dans Directus.

---

## 1. Créer l’apprenant dans Directus

### Option A : À la main (interface Directus)

1. Ouvrez votre instance Directus (ex. `https://votre-directus.scaleway...`).
2. Allez dans **Content** (ou **Apprenants**) → collection **apprenants**.
3. Cliquez sur **Create new item** (ou **+**).
4. Renseignez :
   - **origin** : `direct`
   - **external_user_id** : une valeur **unique** (ex. un UUID). Vous pouvez en générer un sur [uuidgenerator.net](https://www.uuidgenerator.net/) ou avec le script ci‑dessous.
   - **email** : l’email de l’apprenant (optionnel mais utile pour lui envoyer le lien).
5. Enregistrez. Notez l’**external_user_id** (ou l’**id** si le site utilisera l’id interne).

Le **lien à envoyer** à l’apprenant est alors l’**Espace apprenants** du site, avec le token en paramètre, par exemple :  
`https://tyrulfr.github.io/projet_inno_pui/pages/apprenant/portal.html?token=EXTERNAL_USER_ID`  
(en remplaçant `EXTERNAL_USER_ID` par la valeur créée).

---

### Option B : Avec le script PowerShell (recommandé)

Un script crée l’apprenant dans Directus et affiche le lien à envoyer.

1. Vérifiez que le fichier **.env** à la racine du projet contient **DIRECTUS_URL** et **DIRECTUS_TOKEN** (ou DIRECTUS_EMAIL + DIRECTUS_PASSWORD).
2. À la racine du projet, exécutez :
   ```bat
   creer-apprenant-direct.bat "apprenant@exemple.com"
   ```
   ou en double-cliquant sur **creer-apprenant-direct.bat** puis en saisissant l’email quand il est demandé.  
   En PowerShell :
   ```powershell
   .\scripts\creer-apprenant-direct.ps1 -Email "apprenant@exemple.com"
   ```
   Pour que le lien affiché soit complet, ajoutez dans **.env** l’URL du site (pas Directus) :  
   `SITE_BASE_URL=https://tyrulfr.github.io/projet_inno_pui`  
   ou passez :  
   `-BaseUrl "https://tyrulfr.github.io/projet_inno_pui"`.
3. Le script affiche :
   - l’**id** et l’**external_user_id** de l’apprenant créé ;
   - le **lien d’accès** à copier et envoyer à l’apprenant (par email ou autre).

L’apprenant n’a **pas de mot de passe** : il ouvre simplement ce lien (une seule URL = son “identifiant” d’accès). Le site utilise déjà le `token` pour les coches de progression (localStorage). Pour que la progression remonte dans Directus, déployez l’API `api/progress.js` et définissez `PROGRESS_API_BASE` sur le site (voir `docs/PROGRESSION_ET_DIRECTUS.md`).

---

## 2. Envoyer les “identifiants” à l’apprenant

- **Ce qu’on envoie** : le **lien unique** (avec `?token=...`).
- **Message type** (à adapter) :
  - Objet : Accès au parcours OSER POUR INNOVER  
  - Texte : « Bonjour, voici votre lien d’accès personnel au parcours. Conservez-le pour retrouver votre progression : [COLLER LE LIEN]. Ce lien est personnel ; ne le partagez pas. »

Il n’y a pas de “identifiant / mot de passe” séparés : le lien **est** l’accès. Par défaut la progression reste en **localStorage** (coches et avancement sur l’appareil). Pour qu’elle soit aussi enregistrée dans la base Directus (table `progress`), déployez l’API `api/progress.js` et configurez `PROGRESS_API_BASE` sur le site (voir `docs/PROGRESSION_ET_DIRECTUS.md`).

---

## 3. Résumé

| Étape | Action |
|-------|--------|
| 1 | Créer un enregistrement **apprenants** dans Directus : `origin` = `direct`, `external_user_id` = valeur unique, `email` = email de l’apprenant. |
| 2 | Construire le lien vers l’Espace apprenants du site : `https://tyrulfr.github.io/projet_inno_pui/pages/apprenant/portal.html?token=EXTERNAL_USER_ID`. |
| 3 | Envoyer ce lien à l’apprenant (email, messagerie, etc.). |

Pour générer l’apprenant et le lien automatiquement : utiliser **creer-apprenant-direct.bat** (ou le script PowerShell associé) avec l’email de l’apprenant.
