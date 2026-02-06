/**
 * Envoi du mail de bienvenue à un apprenant.
 * POST /api/send-welcome-email
 * Headers: Authorization: Bearer ADMIN_SECRET
 * Body: { to, subject, text } (ou html)
 * Variables: ADMIN_SECRET, RESEND_API_KEY, RESEND_FROM (ex: "OSER POUR INNOVER <onboarding@resend.dev>")
 */
var ADMIN_SECRET = (process.env.ADMIN_SECRET || '').trim();
var RESEND_API_KEY = (process.env.RESEND_API_KEY || '').trim();
var RESEND_FROM = (process.env.RESEND_FROM || 'OSER POUR INNOVER <onboarding@resend.dev>').trim();
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

module.exports = async function handler(req, res) {
  cors(res, req);
  if (req.method === 'OPTIONS') return;

  if (!ADMIN_SECRET) return json(res, 500, { error: 'ADMIN_SECRET non configuré' });
  var auth = req.headers.authorization || '';
  if (auth !== 'Bearer ' + ADMIN_SECRET) return json(res, 401, { error: 'Non autorisé' });

  if (req.method !== 'POST') return json(res, 405, { error: 'Méthode non autorisée' });
  if (!RESEND_API_KEY) return json(res, 500, { error: 'RESEND_API_KEY non configuré' });

  var body = typeof req.body === 'string' ? (function () { try { return JSON.parse(req.body); } catch (e) { return null; } })() : req.body;
  if (!body || !body.to) return json(res, 400, { error: 'Champ "to" (email du destinataire) requis' });

  var to = body.to;
  var subject = body.subject || 'Accès au parcours OSER POUR INNOVER';
  var text = body.text || body.body || '';
  var html = body.html;

  var payload = {
    from: RESEND_FROM,
    to: [to],
    subject: subject
  };
  if (html) payload.html = html;
  else payload.text = text;

  try {
    var r = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': 'Bearer ' + RESEND_API_KEY,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(payload)
    });
    var data = await r.json().catch(function () { return {}; });
    if (!r.ok) return json(res, r.status, { error: data.message || data.error || 'Erreur Resend' });
    return json(res, 200, { ok: true, id: data.id });
  } catch (e) {
    return json(res, 500, { error: e.message || 'Erreur envoi email' });
  }
};
