/**
 * Création d'un apprenant direct avec identifiant + mot de passe (admin uniquement).
 * POST /api/create-apprenant
 * Headers: Authorization: Bearer ADMIN_SECRET
 * Body: { email, identifiant, password }
 * Variables: DIRECTUS_URL, DIRECTUS_TOKEN, ADMIN_SECRET
 */
var bcrypt = require('bcryptjs');

var DIRECTUS_URL = (process.env.DIRECTUS_URL || '').replace(/\/$/, '');
var DIRECTUS_TOKEN = process.env.DIRECTUS_TOKEN || '';
var ADMIN_SECRET = process.env.ADMIN_SECRET || '';
var CORS_ORIGIN = process.env.CORS_ORIGIN || '*';

function json(res, status, data) {
  res.status(status).setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(data));
}

function cors(res, req) {
  res.setHeader('Access-Control-Allow-Origin', CORS_ORIGIN === '*' ? '*' : (req.headers.origin || CORS_ORIGIN));
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  if (req.method === 'OPTIONS') return res.status(204).end();
}

function randomId(len) {
  var chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  var out = '';
  for (var i = 0; i < len; i++) out += chars.charAt(Math.floor(Math.random() * chars.length));
  return out;
}

module.exports = async function handler(req, res) {
  cors(res, req);
  if (req.method === 'OPTIONS') return;

  if (!ADMIN_SECRET) return json(res, 500, { error: 'ADMIN_SECRET non configuré' });
  var auth = req.headers.authorization || '';
  if (auth !== 'Bearer ' + ADMIN_SECRET) return json(res, 401, { error: 'Non autorisé' });

  if (!DIRECTUS_URL || !DIRECTUS_TOKEN) return json(res, 500, { error: 'Directus non configuré' });

  var body = typeof req.body === 'string' ? (function () { try { return JSON.parse(req.body); } catch (e) { return null; } })() : req.body;
  if (!body) return json(res, 400, { error: 'Body JSON invalide' });
  var email = body.email;
  var identifiant = body.identifiant;
  var password = body.password;
  if (!identifiant || !password) return json(res, 400, { error: 'identifiant et password requis' });

  var passwordHash = bcrypt.hashSync(password, 10);
  var externalUserId = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
    var r = Math.random() * 16 | 0, v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });

  var directusBody = {
    origin: 'direct',
    external_user_id: externalUserId,
    email: email || null,
    identifiant: identifiant,
    password_hash: passwordHash
  };

  try {
    var r = await fetch(DIRECTUS_URL + '/items/apprenants', {
      method: 'POST',
      headers: { 'Authorization': 'Bearer ' + DIRECTUS_TOKEN, 'Content-Type': 'application/json' },
      body: JSON.stringify(directusBody)
    });
    var text = await r.text();
    if (!r.ok) throw new Error(text || r.status);
    var data = text ? JSON.parse(text) : {};
    var id = (data.data && data.data.id) || data.id;
    return json(res, 200, { ok: true, identifiant: identifiant, external_user_id: externalUserId, id: id });
  } catch (e) {
    return json(res, 500, { error: e.message || 'Erreur Directus' });
  }
};
