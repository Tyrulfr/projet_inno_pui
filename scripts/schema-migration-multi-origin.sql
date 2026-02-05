-- Migration : passer d'un modèle Moodle seul à multi-origine (Moodle, FunMooc, site direct).
-- À exécuter sur une base qui a DÉJÀ les tables apprenants et progress (ancien schéma avec moodle_user_id).
-- PostgreSQL.

-- 1) Ajouter les colonnes origin et external_user_id
ALTER TABLE apprenants ADD COLUMN IF NOT EXISTS origin VARCHAR(50);
ALTER TABLE apprenants ADD COLUMN IF NOT EXISTS external_user_id VARCHAR(255);

-- 2) Remplir à partir de moodle_user_id pour les enregistrements existants
UPDATE apprenants
SET origin = 'moodle', external_user_id = COALESCE(TRIM(moodle_user_id::TEXT), 'legacy-' || id)
WHERE origin IS NULL OR external_user_id IS NULL OR external_user_id = '';

-- 3) Valeurs par défaut pour les prochains insert
ALTER TABLE apprenants ALTER COLUMN origin SET DEFAULT 'moodle';
-- Ne pas forcer NOT NULL ici pour ne pas casser les lignes existantes sans external_user_id.

-- 4) Index unique pour (origin, external_user_id)
CREATE UNIQUE INDEX IF NOT EXISTS idx_apprenants_origin_external
ON apprenants(origin, external_user_id);

-- 5) Optionnel : commentaires
COMMENT ON COLUMN apprenants.origin IS 'moodle | funmooc | direct';
COMMENT ON COLUMN apprenants.external_user_id IS 'Id utilisateur côté plateforme (Moodle, edX, ou UUID direct)';

-- Note : on garde moodle_user_id pour rétrocompatibilité et affichage. Vous pourrez le déprécier plus tard
-- si vous ne l'utilisez plus (toute la logique passant par origin + external_user_id).
