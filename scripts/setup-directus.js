/**
 * Script de structure de la base Directus pour le mini-site OSER POUR INNOVER.
 * Crée les collections "apprenants" et "progress" via l'API Directus.
 *
 * Prérequis :
 * - Node.js 18+ (pour fetch natif)
 * - Fichier .env à la racine du projet avec DIRECTUS_URL et DIRECTUS_TOKEN
 *
 * Usage : node scripts/setup-directus.js
 */

const fs = require('fs');
const path = require('path');

function loadEnv() {
  const envPath = path.join(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) {
    console.error('Fichier .env introuvable. Copiez .env.example en .env et renseignez DIRECTUS_URL et DIRECTUS_TOKEN.');
    process.exit(1);
  }
  const content = fs.readFileSync(envPath, 'utf8');
  const env = {};
  content.split('\n').forEach((line) => {
    const m = line.match(/^\s*([^#=]+)=(.*)$/);
    if (m) env[m[1].trim()] = m[2].trim().replace(/^["']|["']$/g, '');
  });
  return env;
}

const env = loadEnv();
const DIRECTUS_URL = (env.DIRECTUS_URL || '').replace(/\/$/, '');
const DIRECTUS_TOKEN = env.DIRECTUS_TOKEN;

if (!DIRECTUS_URL || !DIRECTUS_TOKEN) {
  console.error('Dans .env, renseignez DIRECTUS_URL et DIRECTUS_TOKEN.');
  process.exit(1);
}

const headers = {
  'Content-Type': 'application/json',
  Authorization: `Bearer ${DIRECTUS_TOKEN}`,
};

async function api(method, path, body = null) {
  const url = `${DIRECTUS_URL}${path}`;
  const options = { method, headers };
  if (body) options.body = JSON.stringify(body);
  const res = await fetch(url, options);
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch (_) {}
  if (!res.ok) {
    console.error(`Erreur ${res.status} ${path}:`, data || text);
    throw new Error(data?.errors?.[0]?.message || data?.error?.message || text || res.statusText);
  }
  return data;
}

async function createApprenantsCollection() {
  console.log('Création de la collection apprenants...');
  const existing = await api('GET', '/collections/apprenants').catch(() => null);
  if (existing?.data) {
    console.log('  → La collection apprenants existe déjà.');
    return;
  }

  await api('POST', '/collections', {
    collection: 'apprenants',
    meta: { icon: 'person', note: 'Profils apprenants (lien Moodle)' },
    schema: {},
    fields: [
      { field: 'id', type: 'integer', meta: { hidden: true, readonly: true, interface: 'input', special: ['integer', 'primary'] }, schema: { is_primary_key: true, has_auto_increment: true } },
      { field: 'moodle_user_id', type: 'string', meta: { interface: 'input', required: true, note: 'Identifiant Moodle' }, schema: { is_nullable: false } },
      { field: 'email', type: 'string', meta: { interface: 'input' }, schema: { is_nullable: true } },
      { field: 'date_creation', type: 'timestamp', meta: { interface: 'datetime', readonly: true }, schema: { is_nullable: true, default_value: 'CURRENT_TIMESTAMP' } },
    ],
  });
  console.log('  → Collection apprenants créée.');
}

async function createProgressCollection() {
  console.log('Création de la collection progress...');
  const existing = await api('GET', '/collections/progress').catch(() => null);
  if (existing?.data) {
    console.log('  → La collection progress existe déjà.');
    return;
  }

  await api('POST', '/collections', {
    collection: 'progress',
    meta: { icon: 'check_circle', note: 'Grains complétés par apprenant' },
    schema: {},
    fields: [
      { field: 'id', type: 'integer', meta: { hidden: true, readonly: true, interface: 'input', special: ['integer', 'primary'] }, schema: { is_primary_key: true, has_auto_increment: true } },
      { field: 'apprenant_id', type: 'integer', meta: { interface: 'select-dropdown-m2o', special: ['m2o'], required: true, options: { template: '{{moodle_user_id}}' } }, schema: { is_nullable: false, foreign_key_table: 'apprenants', foreign_key_column: 'id' } },
      { field: 'grain_id', type: 'string', meta: { interface: 'input', required: true }, schema: { is_nullable: false } },
      { field: 'module_id', type: 'string', meta: { interface: 'input', required: true }, schema: { is_nullable: false } },
      { field: 'sequence_id', type: 'string', meta: { interface: 'input' }, schema: { is_nullable: true } },
      { field: 'completed_at', type: 'timestamp', meta: { interface: 'datetime' }, schema: { is_nullable: true, default_value: 'CURRENT_TIMESTAMP' } },
    ],
  });
  console.log('  → Collection progress créée.');
}

async function main() {
  console.log('Connexion à Directus :', DIRECTUS_URL);
  try {
    const me = await api('GET', '/users/me');
    console.log('Authentifié :', me?.data?.email || me?.data?.first_name || 'OK');
  } catch (e) {
    console.error('Impossible de se connecter à Directus. Vérifiez URL et token.', e.message);
    process.exit(1);
  }

  await createApprenantsCollection();
  await createProgressCollection();

  console.log('\nTerminé. Vérifiez dans Directus : Settings > Data Model.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
