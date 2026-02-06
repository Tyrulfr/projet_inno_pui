/**
 * Liste et suppression des apprenants (admin uniquement).
 * GET /api/apprenants → liste des apprenants (même champs que le modèle Directus, sans password_hash).
 * DELETE /api/apprenants?id=123 → supprime l'apprenant (et sa progression en CASCADE).
 * Headers: Authorization: Bearer ADMIN_SECRET
 */
var DIRECTUS_URL = (process.env.DIRECTUS_URL || '').replace(/\/$/, '');
var DIRECTUS_TOKEN = process.env.DIRECTUS_TOKEN || '';
var ADMIN_SECRET = (process.env.ADMIN_SECRET || '').trim();
var CORS_ORIGIN = process.env.CORS_ORIGIN || '*';

function json(res, status, data) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(data));
}

function cors(res, req) {
  res.setHeader('Access-Control-Allow-Origin', CORS_ORIGIN === '*' ? '*' : (req.headers.origin || CORS_ORIGIN));
  res.setHeader('Access-Control-Allow-Methods', 'GET, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(204).end();
}

module.exports = async function handler(req, res) {
  cors(res, req);
  if (req.method === 'OPTIONS') return;

  if (!ADMIN_SECRET) return json(res, 500, { error: 'ADMIN_SECRET non configuré' });
  var auth = req.headers.authorization || '';
  if (auth !== 'Bearer ' + ADMIN_SECRET) return json(res, 401, { error: 'Non autorisé' });

  if (!DIRECTUS_URL || !DIRECTUS_TOKEN) return json(res, 500, { error: 'Directus non configuré' });

  if (req.method === 'GET') {
    try {
      var r = await fetch(DIRECTUS_URL + '/items/apprenants?fields=id,origin,external_user_id,email,identifiant,date_creation&sort=-date_creation', {
        method: 'GET',
        headers: { 'Authorization': 'Bearer ' + DIRECTUS_TOKEN, 'Content-Type': 'application/json' }
      });
      var text = await r.text();
      if (!r.ok) throw new Error(text || r.status);
      var data = text ? JSON.parse(text) : {};
      return json(res, 200, { data: data.data || [] });
    } catch (e) {
      return json(res, 500, { error: e.message || 'Erreur Directus' });
    }
  }

  if (req.method === 'DELETE') {
    var id = req.query.id || (req.query && req.query.id);
    if (!id) return json(res, 400, { error: 'Paramètre id requis' });
    try {
      var del = await fetch(DIRECTUS_URL + '/items/apprenants/' + encodeURIComponent(id), {
        method: 'DELETE',
        headers: { 'Authorization': 'Bearer ' + DIRECTUS_TOKEN }
      });
      if (!del.ok) {
        var errText = await del.text();
        throw new Error(errText || del.status);
      }
      return json(res, 200, { ok: true });
    } catch (e) {
      return json(res, 500, { error: e.message || 'Erreur suppression' });
    }
  }

  return json(res, 405, { error: 'Méthode non autorisée' });
};
