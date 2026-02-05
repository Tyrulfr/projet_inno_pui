-- Structure de la base pour le suivi apprenants (mini-site OSER POUR INNOVER).
-- À exécuter sur la base PostgreSQL utilisée par Directus (Scaleway ou autre).
-- Après exécution, dans Directus : Settings > Data Model > éventuellement "Importer" ou rafraîchir pour voir les tables.

-- Table des apprenants (un enregistrement = un profil, identifié par l'id Moodle)
CREATE TABLE IF NOT EXISTS apprenants (
  id SERIAL PRIMARY KEY,
  moodle_user_id VARCHAR(255) NOT NULL UNIQUE,
  email VARCHAR(255),
  date_creation TIMESTAMPTZ DEFAULT NOW()
);

-- Table de la progression (un enregistrement = un grain complété par un apprenant)
CREATE TABLE IF NOT EXISTS progress (
  id SERIAL PRIMARY KEY,
  apprenant_id INTEGER NOT NULL REFERENCES apprenants(id) ON DELETE CASCADE,
  grain_id VARCHAR(100) NOT NULL,
  module_id VARCHAR(100) NOT NULL,
  sequence_id VARCHAR(100),
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(apprenant_id, grain_id)
);

-- Index pour les recherches courantes
CREATE INDEX IF NOT EXISTS idx_progress_apprenant_id ON progress(apprenant_id);
CREATE INDEX IF NOT EXISTS idx_progress_grain_id ON progress(grain_id);
CREATE INDEX IF NOT EXISTS idx_apprenants_moodle_user_id ON apprenants(moodle_user_id);

COMMENT ON TABLE apprenants IS 'Profils apprenants (lien avec Moodle via moodle_user_id)';
COMMENT ON TABLE progress IS 'Grains complétés par apprenant (suivi progression)';
