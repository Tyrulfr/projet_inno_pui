/**
 * API proxy progression → Directus (Scaleway).
 * Utilisable sur Vercel (déployer à la racine avec vercel.json) ou autre serverless.
 * Variables d'environnement : DIRECTUS_URL, DIRECTUS_TOKEN.
 * CORS : autorise l'origine du site (optionnel, ou * en dev).
 */

const DIRECTUS_URL = (process.env.DIRECTUS_URL || '').replace(/\/$/, '');
const DIRECTUS_TOKEN = process.env.DIRECTUS_TOKEN || '';
const CORS_ORIGIN = process.env.CORS_ORIGIN || '*';

function json(res, status, data) {
  return res.status(status).setHeader('Content-Type', 'application/json').end(JSON.stringify(data));
}

function cors(res, req) {
  const origin = req.headers.origin || CORS_ORIGIN;
  res.setHeader('Access-Control-Allow-Origin', CORS_ORIGIN === '*' ? '*' : origin);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();
}

async function directus(method, path, body = null) {
  const url = `${DIRECTUS_URL}${path}`;
  const opts = { method, headers: { Authorization: `Bearer ${DIRECTUS_TOKEN}`, 'Content-Type': 'application/json' } };
  if (body) opts.body = JSON.stringify(body);
  const r = await fetch(url, opts);
  const text = await r.text();
  if (!r.ok) throw new Error(text || r.statusText);
  return text ? JSON.parse(text) : null;
}

/** Retrouve l'apprenant direct par external_user_id (token). */
async function getApprenantId(token) {
  const res = await directus('GET', `/items/apprenants?filter[origin][_eq]=direct&filter[external_user_id][_eq]=${encodeURIComponent(token)}&fields=id`);
  const data = res.data;
  if (!Array.isArray(data) || data.length === 0) return null;
  return data[0].id;
}

module.exports = async function handler(req, res) {
  cors(res, req);

  if (!DIRECTUS_URL || !DIRECTUS_TOKEN) {
    return json(res, 500, { error: 'API non configurée (DIRECTUS_URL / DIRECTUS_TOKEN)' });
  }

  if (req.method === 'GET') {
    const token = req.query.token;
    if (!token) return json(res, 400, { error: 'Paramètre token requis' });
    try {
      const apprenantId = await getApprenantId(token);
      if (!apprenantId) return json(res, 404, { completed: [] });
      const progress = await directus('GET', '/items/progress?filter[apprenant_id][_eq]=' + apprenantId + '&fields=grain_id');
      const completed = (progress.data || []).map(function (p) { return p.grain_id; });
      return json(res, 200, { completed: completed });
    } catch (e) {
      return json(res, 500, { error: e.message || 'Erreur Directus' });
    }
  }

  if (req.method === 'POST') {
    var body;
    try {
      body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    } catch (_) {
      return json(res, 400, { error: 'Body JSON invalide' });
    }
    var token = body && body.token;
    var grainId = body && body.grain_id;
    var moduleId = body && body.module_id;
    var sequenceId = body && body.sequence_id;
    if (!token || !grainId) return json(res, 400, { error: 'token et grain_id requis' });
    try {
      const apprenantId = await getApprenantId(token);
      if (!apprenantId) return json(res, 404, { error: 'Apprenant non trouvé' });
      await directus('POST', '/items/progress', {
        apprenant_id: apprenantId,
        grain_id: grainId,
        module_id: moduleId || 'module1',
        sequence_id: sequenceId || null
      });
      return json(res, 200, { ok: true });
    } catch (e) {
      if (e.message && e.message.indexOf('Unique constraint') !== -1) return json(res, 200, { ok: true });
      return json(res, 500, { error: e.message || 'Erreur Directus' });
    }
  }

  return json(res, 405, { error: 'Méthode non autorisée' });
};
