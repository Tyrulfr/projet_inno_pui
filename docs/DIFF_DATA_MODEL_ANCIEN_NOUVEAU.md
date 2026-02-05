# Différence ancien / nouveau data model Directus

Tableau pour vérifier les **collections** et **champs** dans Directus (Settings > Data Model).

---

## Collection **apprenants**

| Champ | Ancien modèle (Moodle seul) | Nouveau modèle (multi-origine) |
|-------|-----------------------------|--------------------------------|
| **id** | ✅ Integer, PK, auto-increment | ✅ Inchangé |
| **moodle_user_id** | ✅ String, **obligatoire**, **UNIQUE** | ❌ **Supprimé** (remplacé par origin + external_user_id) |
| **origin** | ❌ N'existe pas | ✅ String (VARCHAR 50), **obligatoire**, défaut `moodle`. Valeurs : `moodle` \| `funmooc` \| `direct` |
| **external_user_id** | ❌ N'existe pas | ✅ String (VARCHAR 255), **obligatoire**. Id utilisateur côté plateforme (Moodle, edX, ou UUID direct) |
| **email** | ✅ String, optionnel | ✅ Inchangé |
| **date_creation** | ✅ Timestamp, optionnel | ✅ Inchangé |
| **Contrainte d'unicité** | `moodle_user_id` UNIQUE | `(origin, external_user_id)` UNIQUE |

**Résumé apprenants**  
- Ancien : un apprenant = un `moodle_user_id` unique.  
- Nouveau : un apprenant = un couple **(origin, external_user_id)** unique (Moodle, FunMooc ou direct).

---

## Collection **progress**

| Champ | Ancien modèle | Nouveau modèle |
|-------|----------------|----------------|
| **id** | ✅ Integer, PK, auto-increment | ✅ Inchangé |
| **apprenant_id** | ✅ Integer, FK → apprenants(id), obligatoire | ✅ Inchangé |
| **grain_id** | ✅ String, obligatoire | ✅ Inchangé |
| **module_id** | ✅ String, obligatoire | ✅ Inchangé |
| **sequence_id** | ✅ String, optionnel | ✅ Inchangé |
| **completed_at** | ✅ Timestamp, optionnel | ✅ Inchangé |
| **Contrainte** | UNIQUE(apprenant_id, grain_id) | UNIQUE(apprenant_id, grain_id) |

**Résumé progress**  
- **Aucun changement** entre ancien et nouveau modèle. La table progress reste identique.

---

## Vérification rapide dans Directus

### Si vous avez l’ancien modèle
- **apprenants** : champs `id`, `moodle_user_id`, `email`, `date_creation`. Pas de `origin` ni `external_user_id`.
- **progress** : champs listés ci-dessus.

### Si vous passez au nouveau (migration ou nouvelle base)
- **apprenants** : champs `id`, **origin**, **external_user_id**, `email`, `date_creation`. Plus de `moodle_user_id` (sauf si vous avez fait la migration et gardé l’ancien champ pour affichage).
- **progress** : inchangé.

### Après migration (schema-migration-multi-origin.sql)
- **apprenants** : anciens champs **conservés** (`moodle_user_id`) + **ajout** de `origin` et `external_user_id`. Les lignes existantes ont `origin = 'moodle'` et `external_user_id` = ancienne valeur de `moodle_user_id`.

---

## Récap visuel

```
ANCIEN (Moodle seul)
────────────────────
apprenants:  id | moodle_user_id (UNIQUE) | email | date_creation
progress:    id | apprenant_id | grain_id | module_id | sequence_id | completed_at

NOUVEAU (multi-origine)
───────────────────────
apprenants:  id | origin | external_user_id | email | date_creation   [UNIQUE(origin, external_user_id)]
progress:    id | apprenant_id | grain_id | module_id | sequence_id | completed_at   [inchangé]
```
