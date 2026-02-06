/**
 * Connexion apprenant : identifiant + mot de passe → token (external_user_id).
 * POST /api/auth/login
 * Body: { identifiant, password }
 * Retourne: { token } pour utiliser avec GET/POST /api/progress
 */
var bcrypt = require('bcryptjs');

var DIRECTUS_URL = (process.env.DIRECTUS_URL || '').replace(/\/$/, '');
var DIRECTUS_TOKEN = process.env.DIRECTUS_TOKEN || '';
var CORS_ORIGIN = process.env.CORS_ORIGIN || '*';

function json(res, status, data) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(data));
}

function cors(res, req) {
  res.setHeader('Access-Control-Allow-Origin', CORS_ORIGIN === '*' ? '*' : (req.headers.origin || CORS_ORIGIN));
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.status(204).end();
}

module.exports = async function handler(req, res) {
  cors(res, req);
  if (req.method === 'OPTIONS') return;

  if (req.method !== 'POST') return json(res, 405, { error: 'Méthode non autorisée' });
  if (!DIRECTUS_URL || !DIRECTUS_TOKEN) return json(res, 500, { error: 'API non configurée' });

  var body = typeof req.body === 'string' ? (function () { try { return JSON.parse(req.body); } catch (e) { return null; } })() : req.body;
  if (!body) return json(res, 400, { error: 'Body JSON invalide' });
  var identifiant = (body.identifiant || '').trim();
  var password = body.password;
  if (!identifiant || !password) return json(res, 400, { error: 'identifiant et password requis' });

  try {
    var url = DIRECTUS_URL + '/items/apprenants?filter[identifiant][_eq]=' + encodeURIComponent(identifiant) + '&fields=id,external_user_id,password_hash';
    var r = await fetch(url, {
      method: 'GET',
      headers: { 'Authorization': 'Bearer ' + DIRECTUS_TOKEN, 'Content-Type': 'application/json' }
    });
    var text = await r.text();
    if (!r.ok) throw new Error(text || r.status);
    var data = text ? JSON.parse(text) : {};
    var list = data.data || [];
    if (list.length === 0) return json(res, 401, { error: 'Identifiant ou mot de passe incorrect' });
    var row = list[0];
    var hash = row.password_hash;
    if (!hash) return json(res, 401, { error: 'Compte sans mot de passe. Utilisez le lien de connexion envoyé par l\'administrateur.' });
    if (!bcrypt.compareSync(password, hash)) return json(res, 401, { error: 'Identifiant ou mot de passe incorrect' });
    return json(res, 200, { token: row.external_user_id });
  } catch (e) {
    return json(res, 500, { error: e.message || 'Erreur serveur' });
  }
};
