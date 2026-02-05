# Scripts – structure de la base Directus

Ces scripts permettent de créer les collections **apprenants** et **progress** dans Directus, soit via l’API (Option A), soit via du SQL (Option B).

---

## Option A : via l’API Directus (recommandé si vous avez un token admin)

1. **Créer un token API dans Directus**  
   Directus → **Settings** (engrenage) → **Access Tokens** → **Create** → copier le token.

2. **Configurer le projet**  
   À la racine du projet :
   - Copier `.env.example` en `.env`
   - Dans `.env`, renseigner :
     - `DIRECTUS_URL` : URL de votre instance (ex. `https://xxx.directus.app`) sans slash final
     - `DIRECTUS_TOKEN` : le token créé à l’étape 1

3. **Lancer le script**  
   Dans un terminal à la racine du projet :
   ```bash
   run-setup-directus.bat (double-clic) ou : powershell -ExecutionPolicy Bypass -File scripts/setup-directus.ps1
   (Node : node scripts/setup-directus.js)
   ```
   Le script crée les collections et les champs. En cas d’erreur (format d’API différent selon la version Directus), utiliser l’Option B ou créer les collections à la main (voir `docs/DIRECTUS_PREPARER_LA_BASE.md`).

---

## Option B : via SQL (si vous avez accès à PostgreSQL)

1. **Récupérer l’URL de connexion**  
   C’est la même base que celle utilisée par Directus (ex. sur Scaleway : console → base managée → connexion).

2. **Exécuter le script SQL**  
   Avec `psql` (ou l’outil de votre hébergeur) :
   ```bash
   psql "postgresql://user:password@host:5432/database" -f scripts/schema.sql
   ```
   Sous Windows (PowerShell), si l’URL contient des caractères spéciaux, utilisez des guillemets et échappez si besoin, ou mettez l’URL dans `.env` (variable `DATABASE_URL`) et lancez :
   ```bash
   psql "%DATABASE_URL%" -f scripts/schema.sql
   ```

3. **Dans Directus**  
   Les tables créées en base peuvent apparaître automatiquement dans **Settings > Data Model**. Sinon, selon votre version, utilisez l’option du type « Importer depuis la base » ou « Sync » si disponible.

---

## Fichiers présents

| Fichier | Rôle |
|--------|------|
| `setup-directus.ps1` | Crée collections/champs via API Directus (PowerShell, sans Node). |
| `setup-directus.js` | Crée les collections et champs via l’API Directus (Option A). |
| `schema.sql` | Crée les tables `apprenants` et `progress` en PostgreSQL (Option B). |
| `README.md` | Ce fichier (instructions d’utilisation). |

---

## Après la structure

Une fois les collections en place, vous pourrez brancher le front (ou un backend) pour :
- créer un profil **apprenants** à partir de l’id Moodle ;
- enregistrer les grains complétés dans **progress** ;
- mettre à jour les barres de progression côté mini-site et, plus tard, remonter les données vers Moodle.

Voir `docs/SUIVI_APPRENANTS_ET_MOODLE.md` et `docs/CHOIX_SIMPLE_DIRECTUS_OU_BACKEND.md` pour la suite.
