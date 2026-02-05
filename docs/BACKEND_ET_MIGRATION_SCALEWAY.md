# Backend, base de données et migration (Scaleway + Directus)

Ce document décrit comment construire **ensemble** le backend du mini-site (profils apprenants, progression), en prévoyant dès le départ une **migration simple** de la BDD d’un serveur Scaleway vers un autre. La base est **manipulée via Directus** (interface d’administration des données).

---

## 1. BDD sur Scaleway, manipulée via Directus

- **Scaleway** : héberge la base de données (Instance + PostgreSQL/MySQL, ou Managed Database). C’est là que les données sont stockées.
- **Directus** : [directus.io](https://directus.io) — c’est l’**environnement** (interface web) avec lequel vous **manipulez** cette BDD. Directus se connecte à votre base (PostgreSQL ou MySQL) et vous permet de :
  - créer / modifier des tables (ou « collections »),
  - voir et éditer les données,
  - gérer les utilisateurs Directus et les permissions,
  - exposer une **API REST (et GraphQL)** automatique sur vos données.

Donc : **BDD stockée sur Scaleway, manipulée à travers Directus**. Lors d’une migration, vous migrerez la même base ; Directus sur le nouveau serveur pointera vers la nouvelle URL de BDD (via sa config / variables d’environnement).

---

## 2. Mini-site et Directus : deux façons de faire

Comme la BDD est déjà gérée via Directus, vous avez deux options pour le mini-site.

| Option | Rôle de Directus | Rôle du mini-site |
|--------|-------------------|--------------------|
| **A – API Directus** | Directus **est** l’API : vous créez dans Directus les collections (ex. `apprenants`, `progress`), vous configurez les permissions (token public ou par rôle), et le **front du mini-site** appelle l’API REST Directus (`GET /items/progress`, `POST /items/progress`, etc.) pour lire/écrire l’avancement. | Pas de backend Express à maintenir : uniquement du JS dans vos pages qui appelle l’URL de votre instance Directus. |
| **B – Backend dédié + même BDD** | Directus reste l’**interface d’admin** (vous consultez/éditez les données dans Directus). L’API du mini-site est un petit backend (Node/Express) qui se connecte **à la même base** que Directus. | Le backend expose des routes métier (`GET/POST /api/progress`) et parle directement à la BDD ; Directus et le backend partagent les mêmes tables. |

- **Option A** : moins de code à déployer, tout passe par Directus ; il faut bien configurer les rôles et permissions Directus (et éventuellement un token pour le front).
- **Option B** : logique métier (création de profil à partir de Moodle, règles de calcul) dans votre code ; Directus sert uniquement à visualiser/éditer les données. Migration : même BDD, vous migrez la base ; Directus et le backend pointent tous deux vers la nouvelle `DATABASE_URL` sur le nouveau serveur.

La suite du document reste valable dans les deux cas ; l’option B reprend la structure `backend/` décrite plus bas. Si vous choisissez l’option A, on adaptera en remplaçant les appels « API backend » par des appels à l’**API Directus** (même schéma de tables, mais créées comme collections dans Directus).

---

## 3. Principes pour une migration BDD simple

- **Tout ce qui dépend du serveur** est dans des **variables d’environnement** (fichier `.env` en local, config dans l’interface Scaleway en prod) :  
  `DATABASE_URL`, `PORT`, `API_URL`, etc.
- **Aucune URL ou identifiant de BDD en dur** dans le code.
- **Base standard** : PostgreSQL (recommandé) ou MySQL — dump SQL standard, restaurable n’importe où.
- **Sauvegardes** : exports réguliers (dump) ; Scaleway Managed Database propose des backups automatiques que vous pouvez utiliser pour restaurer sur une nouvelle instance.

Ainsi, **migrer** = nouveau serveur + nouvelle base (ou nouvelle instance Managed DB) + recopier `.env` (avec les nouvelles valeurs) + restaurer un dump SQL. Pas de changement de code.

---

## 4. Stack proposé (backend, option B)

| Composant | Choix | Raison |
|-----------|--------|--------|
| **Runtime** | Node.js (LTS) | Simple pour une API REST, déploiement léger, bien supporté sur Scaleway (Instances, Serverless, etc.). |
| **API** | Express | Léger, standard, facile à faire évoluer. |
| **Base de données** | PostgreSQL | Robuste, standard, Managed DB sur Scaleway ; dump/restore trivial. En dev on peut utiliser SQLite pour ne pas dépendre d’un serveur. |
| **Config** | Variables d’environnement (`.env`) | Un seul endroit à modifier lors d’un changement de serveur ou de BDD. |

**Alternative** : PHP + MySQL si vous préférez rester dans l’écosystème Moodle (Moodle est en PHP) ; les mêmes principes (config en env, dump SQL) s’appliquent pour la migration.

---

## 5. Où placer le backend dans le projet

Deux options courantes :

- **Option A – Backend à la racine du repo**  
  Le dépôt contient à la fois le front (vos pages HTML/JS/CSS) et le backend (ex. dossier `server/` ou `api/`).  
  Sur Scaleway vous déployez soit une Instance qui sert le front + l’API, soit un déploiement séparé (front en statique, API en sous-dossier ou sous-domaine).

- **Option B – Backend dans un sous-dossier dédié**  
  Ex. `projet_inno_pui/backend/` avec son propre `package.json`, ses routes, sa connexion BDD. Le front reste à la racine (ou dans `pages/`, `assets/`). En prod : un seul serveur peut servir le dossier racine en statique et monter l’API sur `/api`, ou deux services (front + API).

**Recommandation** : **Option B** — dossier `backend/` à la racine du projet. Clair pour la suite et pour la migration (vous déplacez tout le repo, ou seulement `backend/` + dump BDD).

Structure cible proposée :

```
projet_inno_pui/
├── backend/
│   ├── .env.example
│   ├── .env                    # ignoré par git, contient DATABASE_URL, PORT, etc.
│   ├── package.json
│   ├── server.js               # ou index.js
│   ├── config.js               # lit process.env
│   ├── routes/
│   │   └── progress.js
│   ├── db/
│   │   ├── connection.js
│   │   └── schema.sql          # création des tables (pour migration / nouveau serveur)
│   └── scripts/
│       └── migrate-export.sh   # exemple : dump pour migration
├── docs/
├── assets/
│   └── js/
│       └── progress-api.js     # script front qui appelle l’API
├── pages/
└── ...
```

---

## 6. Schéma de base de données (migration-friendly)

Deux tables suffisent pour commencer ; tout est en SQL standard, facile à dump/restore.

**Table `users` (profil = un enregistrement par apprenant Moodle)**  
- `id` (UUID ou SERIAL) — clé interne.  
- `moodle_user_id` (VARCHAR/INT) — identifiant Moodle (ou issu du token LTI).  
- `email` (VARCHAR, optionnel) — si fourni par Moodle/LTI.  
- `created_at`, `updated_at` (timestamps).

**Table `progress`**  
- `id` (SERIAL).  
- `user_id` (FK vers `users.id`).  
- `grain_id` (ex. `grain1`, `grain8`).  
- `module_id` (ex. `module1`).  
- `sequence_id` (ex. `sequence1`, optionnel).  
- `completed_at` (timestamp).  

Contrainte unique `(user_id, grain_id)` pour éviter les doublons.

Fichier **`backend/db/schema.sql`** à créer : instructions `CREATE TABLE` + index. Ce fichier sert à **créer la base sur un nouveau serveur** lors d’une migration ; vous n’y mettez pas de données sensibles, uniquement la structure.

---

## 7. Variables d’environnement (pour migration)

Fichier **`.env`** (jamais commité ; version **`.env.example`** à committer) :

```env
# Base de données (chaîne de connexion complète ; à changer lors d’une migration)
DATABASE_URL=postgresql://user:password@host:5432/dbname

# Ou pour dev local avec SQLite (optionnel)
# DATABASE_URL=sqlite:./dev.sqlite

# Serveur
PORT=3000
NODE_ENV=development

# URL publique de l’API (pour le front) ; à adapter selon le serveur
API_URL=http://localhost:3000
```

En **production sur Scaleway** : vous renseignez les mêmes variables dans l’interface (Console Scaleway → votre Instance ou App → Variables d’environnement) ou dans un fichier `.env` sur le serveur. Lors d’une **migration** : nouveau `DATABASE_URL` (et `API_URL` si besoin), même code, même `schema.sql`.

---

## 8. Migration BDD : d’un serveur Scaleway vers un autre

1. **Sur l’ancien serveur (ou depuis la Console Scaleway – Managed Database)**  
   - Exporter la base :  
     `pg_dump $DATABASE_URL > backup_YYYYMMDD.sql`  
   - Ou utiliser les **sauvegardes automatiques** Scaleway si vous utilisez Managed Database.

2. **Sur le nouveau serveur (ou nouvelle instance Managed Database)**  
   - Créer une base vide.  
   - Appliquer le schéma :  
     `psql $NEW_DATABASE_URL -f backend/db/schema.sql`  
   - Restaurer les données :  
     `psql $NEW_DATABASE_URL < backup_YYYYMMDD.sql`

3. **Mettre à jour la config**  
   - Sur le nouveau serveur : `.env` (ou variables d’environnement) avec le nouveau `DATABASE_URL` et `API_URL` si besoin.

4. **Redémarrer l’API**  
   - L’application lit toujours `process.env.DATABASE_URL` ; aucun changement de code.

**Avec Directus** : sur le nouveau serveur, après avoir restauré la BDD, vous **reconfigurez Directus** pour qu’il pointe vers la nouvelle base (variable d’environnement `DB_URL` ou équivalent dans la config Directus). Même dump, même schéma ; seul l’endpoint de connexion change. Aucune dépendance à l’ancien serveur dans le code : **migration = nouveau serveur + nouveau `.env` (backend si option B) + config Directus (nouvelle DB) + dump/restore**.

---

## 9. Étapes pour « faire ensemble » (ordre proposé)

On peut avancer dans cet ordre, en gardant la migration en tête à chaque étape.

1. **Créer le dossier `backend/`**  
   - `package.json`, `server.js`, `config.js`, lecture de `DATABASE_URL` et `PORT` depuis `process.env`.

2. **Ajouter `backend/db/schema.sql`**  
   - Tables `users` et `progress` comme ci-dessus ; pas de données en dur.

3. **Mettre en place les routes API**  
   - `POST /api/auth/profile` (ou équivalent) : création/récupération du profil à partir de `moodle_user_id` (ou token).  
   - `GET /api/progress` : renvoyer l’avancement de l’utilisateur (grains complétés).  
   - `POST /api/progress` : enregistrer un grain complété (body : `grain_id`, `module_id`, etc. ; user identifié par session ou token).

4. **Fichier `.env.example`**  
   - Documenter `DATABASE_URL`, `PORT`, `API_URL` ; ajouter `.env` au `.gitignore` si ce n’est pas déjà fait.

5. **Script front `assets/js/progress-api.js`**  
   - Appeler `GET /api/progress` au chargement des sommaires et mettre à jour les barres.  
   - Au clic « Terminer ce grain », appeler `POST /api/progress` puis mettre à jour l’affichage.

6. **Intégration Moodle (LTI ou iframe)**  
   - D’abord en local : simuler un `moodle_user_id` (ex. en paramètre d’URL ou en header) pour créer le profil et tester les barres.  
   - Ensuite brancher LTI ou iframe avec token pour que l’identifiant vienne de Moodle.

7. **Documenter la procédure de migration**  
   - Un court fichier `docs/MIGRATION_BDD.md` : commandes `pg_dump` / `psql`, où changer `DATABASE_URL`, et rappel d’utiliser la Console Scaleway (ou l’interface que vous utilisez) pour les backups.

---

## 10. Résumé

- **BDD** = stockée sur Scaleway, **manipulée via Directus** (interface d'admin + API optionnelle).  
- **Migration BDD** = config en variables d’environnement + schéma SQL versionné + dump/restore ; après migration, reconfigurer Directus pour pointer vers la nouvelle base.  
- **Deux options** : utiliser l'**API Directus** comme backend du mini-site (option A), ou un **backend dédié** qui partage la même BDD que Directus (option B).
- **On construit ensemble** : selon l'option choisie, soit collections Directus + script front qui appelle Directus, soit `backend/` + API progress + profils, puis script front et intégration Moodle.

Prochaine étape concrète : décider option A (tout Directus) ou B (backend dédié + même BDD) ; ensuite créer les collections/tables (users, progress), puis le script front et l'intégration Moodle.
