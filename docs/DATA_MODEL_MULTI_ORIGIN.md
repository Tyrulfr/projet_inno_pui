# Modèle de données multi-origine (Moodle, FunMooc, site direct)

Vous aurez trois types d’apprenants :
- **Moodle** : identifiés par l’id utilisateur Moodle
- **FunMooc (edX)** : identifiés par l’id utilisateur FunMooc/edX
- **Site direct** : invités ou inscrits directement sur le site (pas de LMS)

Le modèle Directus doit permettre de distinguer ces origines et d’identifier de façon unique chaque apprenant par **(origine + id externe)**.

---

## 1. Modèle recommandé

### Table `apprenants`

| Champ              | Type        | Description |
|--------------------|-------------|-------------|
| `id`               | SERIAL PK   | Clé interne Directus |
| `origin`           | VARCHAR(50)  | **moodle** \| **funmooc** \| **direct** |
| `external_user_id` | VARCHAR(255) | Id utilisateur côté plateforme (Moodle, edX, ou UUID pour direct) |
| `email`            | VARCHAR(255) | Optionnel |
| `date_creation`    | TIMESTAMPTZ | Optionnel |

- **Contrainte d’unicité** : `UNIQUE(origin, external_user_id)`  
  → Un même `external_user_id` peut exister pour Moodle et pour FunMooc (ce sont des personnes différentes).

Exemples :
- Moodle : `origin = 'moodle'`, `external_user_id = '12345'` (id Moodle)
- FunMooc : `origin = 'funmooc'`, `external_user_id = 'abc-def-edx-uuid'` (id edX/FunMooc)
- Site direct : `origin = 'direct'`, `external_user_id = 'uuid-genere-cote-front'` (UUID stocké en cookie/localStorage)

### Table `progress`

Inchangée : `apprenant_id` (FK vers `apprenants`), `grain_id`, `module_id`, `sequence_id`, `completed_at`.  
La progression est toujours liée à un enregistrement `apprenants`, quel que soit l’origine.

---

## 2. Faut-il modifier la base Directus actuelle ?

**Oui**, si vous voulez gérer les trois origines dans la même base Scaleway.

- **Base déjà en production avec uniquement Moodle** : utiliser le script de **migration** `schema-migration-multi-origin.sql` (ajout des champs, conservation de `moodle_user_id` en option pour rétrocompatibilité).
- **Nouvelle base** : utiliser le nouveau `schema.sql` qui crée directement le modèle avec `origin` + `external_user_id`.

---

## 3. Côté mini-site (logique à prévoir)

- **Entrée depuis Moodle** (LTI ou iframe avec paramètres) :  
  `origin = 'moodle'`, `external_user_id = <id fourni par Moodle>`.  
  **Standard cible pour l’intégration Moodle : LTI 1.3** (et LTI Advantage pour les notes/complétion), pas encore implémenté.
- **Entrée depuis FunMooc (edX)** :  
  `origin = 'funmooc'`, `external_user_id = <id fourni par la plateforme edX/FunMooc>`.
- **Entrée directe** (pas de LMS) :  
  `origin = 'direct'`, `external_user_id = <UUID généré et stocké en cookie/localStorage>` (mode invité avec suivi possible en base si vous le souhaitez).

L’API (ou les appels Directus) devront accepter en entrée `origin` + `external_user_id` pour créer ou récupérer le bon `apprenants`, puis lire/écrire `progress` via `apprenant_id`.

---

## 4. Résumé

| Question | Réponse |
|----------|---------|
| Faut-il modifier le data model Directus ? | **Oui** pour gérer Moodle + FunMooc + direct dans la même base. |
| Que changer ? | Ajouter `origin` et `external_user_id`, et une contrainte `UNIQUE(origin, external_user_id)`. Soit migration si la base existe déjà, soit nouveau schéma pour une base neuve. |
| Table `progress` ? | Pas de changement de structure : elle reste liée à `apprenants` par `apprenant_id`. |

Les scripts SQL sont dans `scripts/` :
- **Nouvelle base** (Moodle + FunMooc + direct) : `schema-multi-origin.sql`
- **Base existante** (déjà avec `moodle_user_id`) : `schema-migration-multi-origin.sql`
- **Ancien modèle** (Moodle seul) : `schema.sql` (conservé pour référence).
