# Préparer la base Directus pour le mini-site (nettoyage / structure)

Ce guide vous explique quoi faire **dans Directus** pour partir sur une base propre et prête pour les profils apprenants et la progression. On ne supprime rien d’important sans avoir une sauvegarde.

---

## 1. Avant de toucher à quoi que ce soit : sauvegarder

- Si votre base contient déjà des données utiles, **faites un export** ou une **sauvegarde** (backup) de la base côté Scaleway / hébergeur avant de supprimer des tables ou des données.
- Dans Directus : **Settings** (icône engrenage) → onglet **Data Model** : vous voyez la liste des **collections** (tables). Vous pouvez noter lesquelles existent déjà.
- La vraie sauvegarde se fait en général **en dehors** de Directus : export SQL de la base (pg_dump, ou outil de votre hébergeur Scaleway). Si vous ne savez pas comment, demandez à l’hébergeur ou à un collègue avant de supprimer quoi que ce soit.

---

## 2. Ce qu’on veut avoir à la fin (structure cible)

Deux **collections** (tables) suffisent pour commencer :

| Collection | Rôle | Champs utiles |
|------------|------|----------------|
| **apprenants** | Un enregistrement = un apprenant (profil), identifié par l’id Moodle. | `moodle_user_id` (String ou Integer), `email` (String, optionnel), `date_creation` (DateTime, optionnel). Directus ajoute souvent `id` (Primary Key) et dates automatiquement. |
| **progress** | Un enregistrement = un grain complété par un apprenant. | `apprenant` (relation vers **apprenants**), `grain_id` (String, ex. grain1, grain8), `module_id` (String, ex. module1), `sequence_id` (String, optionnel), `completed_at` (DateTime). |

Vous n’êtes pas obligé de tout créer d’un coup ; l’important est de ne garder que ce qui sert au mini-site et à Moodle, et d’avoir au moins ces deux collections.

---

## 3. Nettoyer : quoi faire selon votre cas

### Cas A : La base est neuve ou vous voulez repartir de zéro (sauvegarde faite)

1. Dans Directus : **Settings** → **Data Model**.
2. Si des collections existent déjà et que vous voulez tout repartir :
   - Supprimez les collections qui ne servent pas au projet (clic sur la collection → **Delete** ou équivalent). Attention : supprimer une collection supprime les **données** dedans.
3. Créez les deux collections **apprenants** et **progress** comme ci‑dessous.

### Cas B : Vous voulez garder d’autres données et seulement ajouter le suivi apprenants

1. Ne supprimez **pas** les collections qui servent à autre chose.
2. Créez seulement les deux nouvelles collections **apprenants** et **progress** (voir section 4).
3. Pas besoin de « nettoyer » le reste si ça ne gêne pas.

### Cas C : Il y a des collections de test ou des doublons

1. Identifiez les collections qui sont clairement des essais (noms du type « test », « copy », etc.).
2. Après **sauvegarde** : supprimez ces collections de test dans **Data Model**.
3. Créez ou complétez **apprenants** et **progress** comme en section 4.

---

## 4. Créer les collections dans Directus (étape par étape)

### 4.1 Collection **apprenants**

1. **Settings** (engrenage) → **Data Model** → **Create Collection**.
2. **Collection Name** : `apprenants` (sans espace, minuscules ou comme vous voulez, mais on utilisera ce nom dans le backend).
3. **Primary Key** : laisser **ID** (Integer ou UUID selon votre version).
4. **Create** pour créer la collection.
5. Ensuite, **ajouter les champs** :
   - **moodle_user_id** : type **String** (ou Integer si Moodle envoie un nombre). Important : c’est l’identifiant Moodle.
   - **email** : type **String**, optionnel.
   - Vous pouvez ajouter **date_creation** (type **DateTime**) si Directus ne le fait pas tout seul.
6. Optionnel : dans les paramètres du champ **moodle_user_id**, activez **Unique** pour éviter deux profils avec le même id Moodle.

### 4.2 Collection **progress**

1. **Data Model** → **Create Collection**.
2. **Collection Name** : `progress`.
3. **Primary Key** : **ID**.
4. **Create**.
5. Ajouter les champs :
   - **apprenant** : type **Many to One** (ou **Relation**) vers la collection **apprenants**. Directus créera un champ `apprenant_id` (Foreign Key). C’est le lien « ce grain complété appartient à quel apprenant ».
   - **grain_id** : type **String** (ex. `grain1`, `grain8`).
   - **module_id** : type **String** (ex. `module1`).
   - **sequence_id** : type **String**, optionnel (ex. `sequence1`).
   - **completed_at** : type **DateTime** (date/heure de complétion). Vous pouvez mettre une valeur par défaut « now » si vous voulez.

6. Optionnel : pour éviter de enregistrer deux fois le même grain pour le même apprenant, vous pouvez ajouter une **contrainte unique** sur la combinaison (apprenant + grain_id). Dans certaines versions de Directus c’est dans les paramètres de la collection ou via un index unique. Sinon, le backend pourra vérifier avant d’insérer.

---

## 5. Vérifier

- Dans le menu principal de Directus, vous devez voir **Apprenants** et **Progress** (ou les noms que vous avez donnés).
- En cliquant dessus : les tableaux sont vides, c’est normal. Les données seront ajoutées par le **backend** (ou par l’API Directus) quand les apprenants ouvriront le mini-site depuis Moodle.

---

## 6. Récap « nettoyage »

- **Sauvegarder** la base avant de supprimer des collections.
- **Nettoyer** = supprimer les collections inutiles ou de test (après sauvegarde), puis avoir **au minimum** les deux collections **apprenants** et **progress** avec les champs ci‑dessus.
- Si vous ne voulez rien supprimer, contentez-vous d’**ajouter** **apprenants** et **progress** ; le reste de la base reste inchangé.

Une fois que c’est en place, on pourra brancher le backend (ou l’API Directus) sur ces deux collections pour créer les profils et enregistrer la progression.

---

## 7. Alternative : scripts du projet

Le projet contient des scripts pour créer la structure sans tout faire à la main :

- **Option API** : fichier `.env` avec `DIRECTUS_URL` et `DIRECTUS_TOKEN`, puis `node scripts/setup-directus.js`.
- **Option SQL** : exécuter `scripts/schema.sql` sur la base PostgreSQL utilisée par Directus.

Voir **`scripts/README.md`** pour les instructions détaillées.
