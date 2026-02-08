/**
 * Script de structure de la base Directus pour le mini-site OSER POUR INNOVER.
 * SUPPRIME les anciennes collections apprenants et progress puis recrée le modèle MULTI-ORIGINE.
 * Aligné sur scripts/setup-directus.ps1 (origin, external_user_id, identifiant, password_hash).
 *
 * Prérequis : .env avec DIRECTUS_URL et DIRECTUS_TOKEN (ou DIRECTUS_EMAIL + DIRECTUS_PASSWORD).
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
let DIRECTUS_TOKEN = (env.DIRECTUS_TOKEN || '').trim().replace(/^["']|["']$/g, '');
const DIRECTUS_EMAIL = (env.DIRECTUS_EMAIL || '').trim().replace(/^["']|["']$/g, '');
const DIRECTUS_PASSWORD = (env.DIRECTUS_PASSWORD || '').trim().replace(/^["']|["']$/g, '');

if (!DIRECTUS_URL) {
  console.error('Dans .env, renseignez DIRECTUS_URL.');
  process.exit(1);
}
if (!DIRECTUS_TOKEN && (!DIRECTUS_EMAIL || !DIRECTUS_PASSWORD)) {
  console.error('Dans .env : soit DIRECTUS_TOKEN, soit DIRECTUS_EMAIL + DIRECTUS_PASSWORD.');
  process.exit(1);
}

const headers = { 'Content-Type': 'application/json' };
if (DIRECTUS_TOKEN) headers['Authorization'] = `Bearer ${DIRECTUS_TOKEN}`;

async function api(method, path, body = null) {
  const url = `${DIRECTUS_URL}${path}`;
  const options = { method, headers: { ...headers } };
  if (body) options.body = JSON.stringify(body);
  const res = await fetch(url, options);
  const text = await res.text();
  let data = null;
  try {
    data = text ? JSON.parse(text) : null;
  } catch (_) {}
  if (!res.ok) {
    const errMsg = data?.errors?.[0]?.message || data?.error?.message || text || res.statusText;
    throw new Error(errMsg);
  }
  return data;
}

async function main() {
  console.log('Connexion à Directus :', DIRECTUS_URL);

  let authOk = false;
  try {
    await api('GET', '/users/me');
    console.log('Authentifié : OK (Bearer)');
    authOk = true;
  } catch (_) {}

  if (!authOk && DIRECTUS_TOKEN) {
    try {
      const r = await fetch(`${DIRECTUS_URL}/users/me?access_token=${encodeURIComponent(DIRECTUS_TOKEN)}`, { method: 'GET', headers: { 'Content-Type': 'application/json' } });
      if (r.ok) {
        console.log('Authentifié : OK (access_token en paramètre)');
        authOk = true;
      }
    } catch (_) {}
  }

  if (!authOk && DIRECTUS_EMAIL && DIRECTUS_PASSWORD) {
    try {
      console.log('Tentative connexion par login (email/mot de passe)...');
      const loginResp = await fetch(`${DIRECTUS_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: DIRECTUS_EMAIL, password: DIRECTUS_PASSWORD }),
      });
      const loginData = await loginResp.json();
      if (loginData?.data?.access_token) {
        DIRECTUS_TOKEN = loginData.data.access_token;
        headers['Authorization'] = `Bearer ${DIRECTUS_TOKEN}`;
        console.log('Authentifié : OK (login)');
        authOk = true;
      }
    } catch (e) {
      console.error('Erreur login:', e.message);
    }
  }

  if (!authOk) {
    console.error('Impossible de se connecter. Vérifiez DIRECTUS_TOKEN ou DIRECTUS_EMAIL + DIRECTUS_PASSWORD dans .env');
    process.exit(1);
  }

  console.log('\nSuppression des anciennes collections (si elles existent)...');
  try {
    await api('DELETE', '/collections/progress');
    console.log('  -> Collection progress supprimée.');
  } catch (e) {
    if (/404|not found/i.test(String(e.message))) console.log('  -> Pas de collection progress à supprimer.');
    else console.log('  -> progress :', e.message);
  }
  try {
    await api('DELETE', '/collections/apprenants');
    console.log('  -> Collection apprenants supprimée.');
  } catch (e) {
    if (/404|not found/i.test(String(e.message))) console.log('  -> Pas de collection apprenants à supprimer.');
    else console.log('  -> apprenants :', e.message);
  }

  console.log('\nCréation de la collection apprenants (modèle multi-origine)...');
  await api('POST', '/collections', {
    collection: 'apprenants',
    meta: { icon: 'person', note: 'Profils apprenants : Moodle, FunMooc (edX) ou site direct (origin + external_user_id)' },
    schema: {},
    fields: [
      { field: 'id', type: 'integer', meta: { hidden: true, readonly: true, interface: 'input', special: ['integer', 'primary'] }, schema: { is_primary_key: true, has_auto_increment: true } },
      { field: 'origin', type: 'string', meta: { interface: 'select-dropdown', required: true, options: { choices: [{ text: 'Moodle', value: 'moodle' }, { text: 'FunMooc (edX)', value: 'funmooc' }, { text: 'Site direct', value: 'direct' }] }, note: 'moodle | funmooc | direct' }, schema: { is_nullable: false, default_value: 'moodle' } },
      { field: 'external_user_id', type: 'string', meta: { interface: 'input', required: true, note: 'Id utilisateur côté plateforme (Moodle, edX, ou UUID direct)' }, schema: { is_nullable: false } },
      { field: 'email', type: 'string', meta: { interface: 'input' }, schema: { is_nullable: true } },
      { field: 'identifiant', type: 'string', meta: { interface: 'input', note: 'Login pour connexion site (apprenants direct)' }, schema: { is_nullable: true } },
      { field: 'password_hash', type: 'string', meta: { interface: 'input-hidden', note: 'Hash du mot de passe (ne pas modifier)' }, schema: { is_nullable: true } },
      { field: 'date_creation', type: 'timestamp', meta: { interface: 'datetime', readonly: true }, schema: { is_nullable: true, default_value: 'CURRENT_TIMESTAMP' } },
    ],
  });
  console.log('  -> Collection apprenants créée (origin, external_user_id, email, identifiant, password_hash, date_creation).');

  console.log('Création de la collection progress...');
  await api('POST', '/collections', {
    collection: 'progress',
    meta: { icon: 'check_circle', note: 'Grains complétés par apprenant' },
    schema: {},
    fields: [
      { field: 'id', type: 'integer', meta: { hidden: true, readonly: true, interface: 'input', special: ['integer', 'primary'] }, schema: { is_primary_key: true, has_auto_increment: true } },
      { field: 'apprenant_id', type: 'integer', meta: { interface: 'select-dropdown-m2o', special: ['m2o'], required: true, options: { template: '{{origin}} - {{external_user_id}}' } }, schema: { is_nullable: false, foreign_key_table: 'apprenants', foreign_key_column: 'id' } },
      { field: 'grain_id', type: 'string', meta: { interface: 'input', required: true }, schema: { is_nullable: false } },
      { field: 'module_id', type: 'string', meta: { interface: 'input', required: true }, schema: { is_nullable: false } },
      { field: 'sequence_id', type: 'string', meta: { interface: 'input' }, schema: { is_nullable: true } },
      { field: 'completed_at', type: 'timestamp', meta: { interface: 'datetime' }, schema: { is_nullable: true, default_value: 'CURRENT_TIMESTAMP' } },
    ],
  });
  console.log('  -> Collection progress créée.');

  console.log('\nTerminé. Modèle multi-origine en place. Vérifiez dans Directus : Settings > Data Model.');
}

main().catch((err) => {
  console.error('Erreur :', err.message);
  process.exit(1);
});
