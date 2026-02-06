-- Structure multi-origine : Moodle, FunMooc (edX), site direct.
-- Pour une NOUVELLE installation Directus (Scaleway). Si vous avez déjà apprenants avec moodle_user_id, utilisez schema-migration-multi-origin.sql à la place.

-- Table des apprenants (origine = moodle | funmooc | direct)
CREATE TABLE IF NOT EXISTS apprenants (
  id SERIAL PRIMARY KEY,
  origin VARCHAR(50) NOT NULL DEFAULT 'moodle',
  external_user_id VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  identifiant VARCHAR(255),
  password_hash VARCHAR(255),
  date_creation TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(origin, external_user_id),
  UNIQUE(identifiant)
);

-- Table de la progression (inchangée)
CREATE TABLE IF NOT EXISTS progress (
  id SERIAL PRIMARY KEY,
  apprenant_id INTEGER NOT NULL REFERENCES apprenants(id) ON DELETE CASCADE,
  grain_id VARCHAR(100) NOT NULL,
  module_id VARCHAR(100) NOT NULL,
  sequence_id VARCHAR(100),
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(apprenant_id, grain_id)
);

CREATE INDEX IF NOT EXISTS idx_progress_apprenant_id ON progress(apprenant_id);
CREATE INDEX IF NOT EXISTS idx_progress_grain_id ON progress(grain_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_apprenants_origin_external ON apprenants(origin, external_user_id);

COMMENT ON TABLE apprenants IS 'Profils apprenants : Moodle, FunMooc (edX) ou site direct (origin + external_user_id)';
COMMENT ON COLUMN apprenants.origin IS 'moodle | funmooc | direct';
COMMENT ON COLUMN apprenants.external_user_id IS 'Id utilisateur côté plateforme (Moodle, edX, ou UUID pour direct)';
COMMENT ON TABLE progress IS 'Grains complétés par apprenant (suivi progression)';
