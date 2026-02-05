# Suivi des apprenants et remontée vers Moodle

Ce document décrit les options pour **faire évoluer les barres de progression** (suivi réel de l’avancement) et pour **remonter les données vers Moodle**.

---

## 1. État actuel

- Les barres de progression (sommaire module, séquences) sont **statiques** (`width: 0%` ou `20%` en dur).
- Aucune persistance : un clic sur « Terminer ce grain » ne sauvegarde rien.
- Aucun identifiant apprenant ni lien avec un LMS (Moodle).

---

## 2. Modèle de données à suivre

À définir une fois pour toutes (pour votre affichage **et** pour Moodle) :

| Donnée | Exemple | Utilité |
|--------|---------|--------|
| **Grain complété** | `grain1`, `grain8`, … | Barre par séquence / module |
| **Quiz** | Réponse correcte/incorrecte, score | Optionnel : note Moodle |
| **Temps** | Date/heure de complétion, durée par grain | Optionnel : analytics |
| **Identifiant apprenant** | Id Moodle ou email | Obligatoire si remontée Moodle |

**Structure type (JSON)** :
```json
{
  "userId": "moodle_12345",
  "module1": { "completed": ["grain1", "grain2", "grain8"], "progress": 3 },
  "sequence1": { "completed": ["grain1", "grain2"], "total": 5 },
  "lastUpdated": "2025-02-02T14:30:00Z"
}
```

Vous pouvez en déduire les **pourcentages** (ex. séquence 1 : 2/5 = 40 %) pour mettre à jour les barres.

---

## 3. Où stocker l’avancement ?

### Option A : Uniquement dans le navigateur (localStorage)

- **Principe** : à chaque « Terminer ce grain », on enregistre en `localStorage` (clé du type `progress_module1`, liste des grains complétés).
- **Avantages** : pas de backend, pas de base de données, rapide à mettre en place.
- **Inconvénients** :  
  - un seul appareil / navigateur ;  
  - pas de vue côté formateur ;  
  - **pas de remontée automatique vers Moodle**.

**Utile pour** : prototype, démo, ou parcours hébergé **dans** Moodle (voir SCORM/LTI ci‑dessous).

---

### Option B : Backend + base de données

- **Principe** : un serveur (Node.js, PHP, Python, etc.) + une base (MySQL, PostgreSQL, SQLite) qui stocke par `userId` les grains complétés (et éventuellement quiz, temps).
- **Flux** :  
  1. L’apprenant ouvre une page (avec `userId` fourni par Moodle ou par un login maison).  
  2. Au chargement : l’appel API renvoie l’avancement → vous mettez à jour les barres.  
  3. À chaque « Terminer ce grain » : envoi d’un appel API (ex. `POST /progress` avec `userId`, `grainId`, `moduleId`).
- **Avantages** :  
  - un même avancement sur plusieurs appareils ;  
  - tableau de bord formateur possible ;  
  - **vous pouvez ensuite pousser ces données vers Moodle** (services web, LTI, etc.).
- **Inconvénients** : hébergement, sécurité, conception API.

**Utile pour** : parcours en production avec suivi centralisé et remontée Moodle.

---

### Option C : Tout dans Moodle (SCORM ou LTI)

L’avancement est géré **par** Moodle ; votre site ne garde pas de base de données propre (ou seulement un cache).

- **SCORM**  
  - Vous empaquetez vos pages HTML/JS en paquet SCORM 1.2 ou 2004.  
  - Le contenu est déposé dans une activité « Paquet SCORM » Moodle.  
  - Chaque grain appelle l’API SCORM (ex. `cmi.completion_status`, `cmi.core.lesson_status`) pour marquer « completed ».  
  - Moodle enregistre l’état et affiche la progression dans le cours.  
  - **Remontée** : native (Moodle lit le paquet SCORM).

- **LTI (Learning Tools Interoperability)**  
  - Votre parcours est une « ressource externe » lancée depuis Moodle (LTI 1.1 ou 1.3).  
  - Moodle envoie `user_id`, `context_id`, etc. à votre URL.  
  - Vous stockez l’avancement côté vous (backend + BDD) en utilisant cet `user_id`.  
  - **Remontée** : vous renvoyez la note / complétion à Moodle via **LTI Outcomes** (1.1) ou **LTI Advantage – Grade Services** (1.3).

**Utile pour** : priorité « tout dans Moodle » (SCORM) ou « Moodle + outil externe avec note » (LTI).

---

### Option D : xAPI (Experience API) + LRS

- **Principe** : chaque action (grain complété, quiz répondu) envoie une « statement » xAPI vers un LRS (Learning Record Store). Moodle peut avoir un plugin LRS ou être connecté à un LRS externe ; les rapports Moodle (ou d’autres outils) lisent le LRS.
- **Avantages** : très flexible, multi‑outils, multi‑LMS.
- **Inconvénients** : mise en place LRS, modélisation des verbes/activités, configuration Moodle.

**Utile pour** : écosystème plus large (plusieurs LMS, plateformes, analytics).

---

## 4. Faire évoluer les barres (côté front)

Indépendamment du stockage (localStorage ou API) :

1. **Définir la structure du parcours**  
   Ex. : module 1 = 18 grains, séquence 1 = 5 grains, séquence 2 = 8, séquence 3 = 5.

2. **Au chargement de la page**  
   - Récupérer l’avancement (lecture `localStorage` ou `GET /api/progress?userId=...`).  
   - Calculer les pourcentages (ex. `completedSequence1.length / 5 * 100`).  
   - Mettre à jour le `style.width` des `.progress-bar` (déjà en place en CSS).

3. **À la fin d’un grain**  
   - Quand l’apprenant clique « Terminer ce grain » :  
     - ajouter le grain à la liste « complété » (localStorage ou `POST /progress`);  
     - recalculer les % et mettre à jour les barres si on reste sur la même page, ou au prochain chargement.

Vous n’avez pas besoin d’une base de données pour **voir** les barres évoluer : il suffit d’une source de vérité (localStorage ou API) et d’un petit script commun qui calcule les % et met à jour le DOM.

---

## 5. Remontée des informations vers Moodle – synthèse

| Méthode | Difficulté | Ce qui remonte | Contrainte côté Moodle |
|---------|------------|----------------|------------------------|
| **SCORM** | Moyenne | Complétion, score (si vous utilisez les champs SCORM) | Activité « Paquet SCORM » ; contenu hébergé dans Moodle |
| **LTI (Outcomes / Grade)** | Moyenne à élevée | Note, complétion (selon implémentation) | Activité « LTI » ; clé/secret ou JWT (LTI 1.3) |
| **Services web Moodle** | Élevée | Notes, achèvement d’activité, champs personnalisés | Token, droits « webservice », peut‑être plugin ou activité « externe » |
| **xAPI + LRS** | Élevée | Toutes les actions modélisées en xAPI | Plugin LRS ou LRS externe connecté à Moodle |
| **Export manuel (CSV)** | Faible | Tout ce que vous stockez | Import manuel ou script côté Moodle |

La « difficulté » inclut : développement, déploiement, et maintenance.

---

## 6. Parcours recommandé (par étape)

### Étape 1 – Barres qui évoluent (sans Moodle)

1. Introduire un **script commun** (ex. `assets/js/progress.js`) qui :  
   - connaît la structure du module 1 (liste des grains par séquence) ;  
   - lit/écrit un objet « avancement » en **localStorage** (ex. clé `oser_innover_progress`).  
2. Sur chaque page **grain** : au clic « Terminer ce grain », appeler ce script pour marquer le grain complété, puis (optionnel) rediriger vers le sommaire.  
3. Sur **sommaire_module1** et **sommaire_sequence1/2/3** : au chargement, appeler le script pour récupérer l’avancement, calculer les % et mettre à jour les `.progress-bar`.

Résultat : les barres évoluent selon ce que l’apprenant a fait, **sur ce navigateur**, sans backend.

### Étape 2 – Identifiant apprenant (pour plus tard Moodle)

- Si vous prévoyez **LTI** : l’identifiant viendra de Moodle (paramètre LTI).  
- Si vous prévoyez **SCORM** : pas besoin d’id explicite dans votre code ; SCORM utilise le contexte Moodle.  
- Si vous prévoyez **backend + BDD** : prévoir dès maintenant un `userId` (ou `session_id`) passé en paramètre d’URL ou en POST au premier accès, et stocké en session/localStorage pour les appels suivants.

Adapter le script d’avancement pour utiliser ce `userId` dès que vous passez à une API (remplacement du localStorage par des appels API).

### Étape 3 – Backend (si besoin multi‑appareils / formateur)

- Mettre en place une petite API (ex. Node + Express + SQLite ou PostgreSQL) :  
  - `GET /progress?userId=...`  
  - `POST /progress` avec `userId`, `grainId`, `moduleId`, optionnellement `score` ou `completedAt`.  
- Remplacer dans le front les lectures/écritures localStorage par des appels à cette API.  
- Les barres continuent de se mettre à jour comme en étape 1, avec des données maintenant centralisées.

### Étape 4 – Remontée vers Moodle

- Choisir **une** des options : SCORM, LTI, ou services web (ou xAPI si écosystème plus large).  
- **SCORM** : adapter le parcours en paquet SCORM et utiliser l’API SCORM dans chaque grain pour signaler la complétion (et la note si besoin).  
- **LTI** : exposer le parcours en outil LTI ; à chaque complétion (ou en fin de parcours), appeler LTI Outcomes (1.1) ou Grade Services (1.3) pour envoyer la note / complétion à Moodle.  
- **Services web** : depuis votre backend, appeler les API Moodle (ex. `core_grades_update_grades`, achèvement d’activité) avec un token dédié.

---

## 7. Fichiers à faire évoluer dans votre projet

- **Script d’avancement** (nouveau) : `assets/js/progress.js` (ou équivalent) : structure du parcours, lecture/écriture localStorage (ou API), calcul des %, mise à jour des barres.
- **Pages grains** : appeler ce script au clic « Terminer ce grain » (et éventuellement passer un identifiant grain/module/sequence).
- **Sommaires** : au chargement, appeler le script pour récupérer l’avancement et mettre à jour les barres (et optionnellement afficher « X / Y leçons »).
- **Backend** (plus tard) : routes progress + BDD.
- **Moodle** : selon le choix (SCORM, LTI, webservices), configuration côté Moodle + éventuellement petit endpoint ou paquet SCORM côté vous.

---

## 8. Résumé des choix

- **Barres qui évoluent tout de suite, sans Moodle** → **localStorage + script commun** (étape 1).  
- **Même avancement sur plusieurs appareils + vue formateur** → **backend + BDD** (étape 3).  
- **Remontée vers Moodle** :  
  - **Le plus simple côté Moodle** : **SCORM** (tout dans Moodle, pas de backend obligatoire).  
  - **Parcours hébergé chez vous + note dans Moodle** : **LTI** avec Grade/Outcomes.  
  - **Contrôle total et intégration fine** : **services web Moodle** depuis votre backend.

Si vous indiquez votre priorité (rapidité / tout dans Moodle / multi‑appareils / note dans Moodle), on peut détailler la prochaine étape concrète (ex. structure exacte de `progress.js` et modification d’un sommaire + un grain en exemple).

---

## 9. Mini-site inclus dans Moodle, avec profil dérivé de l’inscription

### Est-ce faisable à partir de vos pages HTML ?

**Oui.** Vos pages HTML restent la base de l’interface. On ajoute :

1. Un **petit backend** (API + base de données) qui gère les profils et l’avancement.
2. Un **script JavaScript commun** dans vos pages qui appelle cette API au lieu du localStorage.
3. Une **intégration Moodle** (LTI ou iframe avec paramètres) pour que Moodle envoie l’identifiant de l’apprenant au mini-site.

Aucune refonte des HTML : mêmes sommaires, mêmes grains, mêmes barres ; seul le *stockage* change (API au lieu de localStorage) et l’**identifiant utilisateur** vient de Moodle.

---

### Principe : inscription Moodle ⇒ profil dans le mini-site

- L’apprenant s’inscrit / est inscrit **dans Moodle** (cours, activité).
- Il accède au **mini-site** depuis Moodle (lien ou activité « outil externe » LTI).
- Au premier accès, le **backend du mini-site** reçoit l’identifiant Moodle (user_id, ou token) et :
  - crée automatiquement un **profil** (une entrée en base) pour cet utilisateur,
  - ou récupère le profil existant.
- Toute la progression (grains complétés, barres) est enregistrée **côté serveur**, liée à ce profil, donc **pas local** (même avancement sur tout appareil où il se connecte via Moodle).

Donc : **inscription dans Moodle implique bien un profil (ou un enregistrement) dans le mini-site**, créé à la volée au premier lancement.

---

### Deux façons d’inclure le mini-site dans Moodle

| Méthode | Comment Moodle envoie l’identité | Côté mini-site |
|--------|-----------------------------------|----------------|
| **LTI (recommandé)** | Moodle lance le mini-site comme « outil externe » et envoie en POST : `user_id`, `context_id`, `lis_person_*`, etc. | Backend reçoit le lancement LTI, vérifie la signature, crée/récupère le profil avec `user_id` Moodle, renvoie la page du parcours (avec un token de session ou un cookie). |
| **Iframe + paramètres** | Moodle affiche le mini-site en iframe avec une URL du type : `https://votre-mini-site.fr/?token=xxx` ou `?moodle_user_id=123`. Le token est généré par Moodle (plugin ou script) et vérifiable par votre backend. | Backend vérifie le token (ou lit `moodle_user_id` si sécurisé), crée/récupère le profil, sert les pages ; le JS lit l’identifiant (injecté en page ou renvoyé par une API « moi »). |

Dans les deux cas, **l’identifiant qui compte est celui de Moodle** ; le profil dans le mini-site est indexé par cet id (ou par un id interne lié à cet id Moodle).

---

### Ce qu’il vous faut concrètement

1. **Backend (API + BDD)**  
   - **Création / récupération du profil** : à chaque entrée (LTI launch ou URL avec token), créer ou charger l’enregistrement « apprenant » lié à l’id Moodle.  
   - **GET /progress** : renvoyer l’avancement (grains complétés par module/séquence) pour l’apprenant connecté.  
   - **POST /progress** : enregistrer un grain complété (appelé depuis le JS au clic « Terminer ce grain »).  
   - Tables minimales : par ex. `users` (id, moodle_user_id, …) et `progress` (user_id, grain_id, module_id, completed_at).

2. **Vos pages HTML**  
   - Inclure un script commun (ex. `progress-api.js`) qui :  
     - connaît l’identifiant de l’apprenant (fourni par le backend après LTI ou après vérification du token),  
     - au chargement des sommaires : appelle GET /progress et met à jour les barres,  
     - au clic « Terminer ce grain » : appelle POST /progress puis met à jour l’affichage ou redirige.  
   - Les pages en elles-mêmes restent vos HTML actuels ; seuls les appels de suivi passent par l’API.

3. **Côté Moodle**  
   - **Si LTI** : créer une activité « outil externe » pointant vers l’URL de lancement de votre backend ; configurer clé/secret (LTI 1.1) ou JWT (LTI 1.3). Les inscrits au cours voient l’activité ; au clic, Moodle envoie l’identité à votre backend.  
   - **Si iframe** : une activité « page » ou « URL » qui affiche l’iframe avec l’URL contenant le token (ou moodle_user_id) générée par un plugin ou un script Moodle.

---

### Résumé

- **Faisable** à partir de vos pages HTML actuelles, sans tout réécrire.  
- **Pas local** : l’avancement est stocké en base côté serveur, associé au profil dérivé de l’id Moodle.  
- **Inscription dans Moodle** = au premier accès au mini-site, **création automatique d’un profil** (ou enregistrement) dans le mini-site, puis suivi de la progression via l’API.  
- **Mini-site inclus dans Moodle** = Moodle ouvre le parcours (LTI ou iframe) et transmet l’identifiant ; le reste (barres, grains, affichage) reste dans votre mini-site, avec un backend minimal pour profils et progression.
