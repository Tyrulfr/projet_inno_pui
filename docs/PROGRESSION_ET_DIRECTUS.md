# Progression apprenant et Directus (Scaleway)

Ce document explique comment la progression (grains / modules terminés) est rattachée à un apprenant dans Directus, **sans modifier la structure de la base**, et comment brancher le site pour enregistrer et lire cette donnée.

---

## 1. Faut-il modifier la structure Directus ?

**Non.** La structure actuelle suffit pour garder la progression propre à chaque apprenant.

### Tables utilisées

| Table         | Rôle |
|---------------|------|
| **apprenants** | Un enregistrement = un apprenant (Moodle, FunMooc ou **direct**). Identifié par `origin` + `external_user_id`. Pour un apprenant direct, le lien envoyé contient `?token=external_user_id` (ex. un UUID). |
| **progress**   | Un enregistrement = un grain complété par un apprenant. Champs : `apprenant_id` (FK), `grain_id`, `module_id`, `sequence_id`, `completed_at`. Contrainte `UNIQUE(apprenant_id, grain_id)` pour éviter les doublons. |

La donnée est donc **déjà par apprenant** : chaque ligne de `progress` est liée à un `apprenant_id`. Aucun changement de schéma n’est nécessaire.

---

## 2. Pourquoi une API entre le site et Directus ?

Le site (GitHub Pages) est **statique** : il n’y a pas de serveur côté projet. On ne peut pas mettre le token d’administration Directus dans le navigateur (il serait visible et permettrait d’écrire n’importe quoi dans la base).

Il faut donc une **couche intermédiaire** (API proxy) qui :

1. Reçoit le **token apprenant** (celui du lien `?token=...`, c’est l’`external_user_id`).
2. Utilise le **token admin Directus** (secret, côté serveur uniquement) pour :
   - retrouver l’apprenant : `origin = 'direct'` et `external_user_id = token` ;
   - lire ou écrire les lignes de `progress` pour cet `apprenant_id`.

L’apprenant ne connaît que son propre token (dans l’URL puis stocké en localStorage) ; il ne voit jamais le token Directus.

---

## 3. Contrat d’API proposé

Cette API peut être déployée sur Scaleway (Functions, ou un petit backend), Vercel, Netlify, etc.

### Base URL

Une seule base configurable côté site, ex. : `https://votre-api.example.com` ou (en dev) `http://localhost:9999`.

### Endpoints

| Méthode | Chemin        | Rôle |
|---------|---------------|------|
| **GET** | `/api/progress?token=UUID` | Retourne la liste des `grain_id` complétés pour cet apprenant. Réponse : `{ "completed": ["grain1", "grain2", ...] }`. |
| **POST**| `/api/progress`           | Corps : `{ "token": "UUID", "grain_id": "grain1", "module_id": "module1", "sequence_id": "seq1" }` (optionnel). Crée ou ignore si déjà présent. Réponse : `{ "ok": true }` ou erreur. |

Côté API, pour **GET** : récupérer l’apprenant par `origin=direct` + `external_user_id=token`, puis lire les `progress` avec ce `apprenant_id` et retourner les `grain_id`. Pour **POST** : même résolution apprenant, puis insertion dans `progress` (avec `module_id` / `sequence_id` si fournis).

---

## 4. Côté site (frontend)

Déjà prévu / à brancher :

1. **Lecture du token** : à l’arrivée sur le portail (ou toute page apprenant) avec `?token=...`, stocker le token en localStorage (ex. clé `projet_inno_apprenant_token`) pour les visites suivantes.
2. **Chargement de la progression** : au chargement des pages avec le widget de progression, si un token est présent et qu’une URL d’API est configurée, appeler `GET /api/progress?token=...` et utiliser la liste `completed` retournée (au lieu ou en fusion avec le localStorage).
3. **Enregistrement** : au clic sur « Terminer ce grain », en plus du localStorage, appeler `POST /api/progress` avec le token et le `grain_id` (et `module_id` / `sequence_id` si disponibles).

Le script `progress-indicators.js` est déjà adapté : il lit le **token** depuis l’URL (`?token=...`) au premier chargement et le stocke en localStorage, puis à chaque chargement appelle **GET /api/progress** si `window.PROGRESS_API_BASE` est défini, et envoie **POST /api/progress** à chaque « Terminer ce grain ». Pour activer la synchro Directus, définir **avant** le chargement du script (par ex. dans le layout ou sur la page portail) :  
`window.PROGRESS_API_BASE = 'https://votre-api.example.com';`  
Sans cette variable, seule la progression en localStorage est utilisée (mode invité / hors ligne).

---

## 5. Résumé

| Question | Réponse |
|----------|---------|
| Modifications dans la structure Directus ? | **Aucune.** Les tables `apprenants` et `progress` suffisent ; la progression est déjà propre à chaque apprenant via `apprenant_id`. |
| Où est stockée la progression par apprenant ? | Dans la table **progress**, liée à **apprenants** par `apprenant_id`. L’apprenant direct est identifié par le token ( = `external_user_id`). |
| Comment connecter le site à Directus ? | En déployant une **API proxy** (serverless ou backend) qui reçoit le token apprenant et lit/écrit dans Directus avec le token admin. Le site appelle cette API (GET/POST progression) au lieu d’appeler Directus directement. |

Un exemple d’implémentation est dans **`api/progress.js`** (format Vercel serverless). Vous pouvez le déployer sur Vercel (dossier `api/` exposé en `/api/*`), ou réutiliser la logique pour une Scaleway Function / Netlify. Variables d’environnement côté API : `DIRECTUS_URL`, `DIRECTUS_TOKEN`, et optionnellement `CORS_ORIGIN` (origine du site).
