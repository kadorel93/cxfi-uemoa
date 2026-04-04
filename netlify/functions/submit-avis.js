/**
 * Goxen — Netlify Function : submit-avis
 * Proxy serverless entre le formulaire public et Supabase.
 * - Hash HMAC-SHA256 de l'IP (jamais stockée en clair)
 * - Rate limiting côté serveur : 1 avis / institution / 90 jours par IP
 * - Clé service-role Supabase uniquement en variable d'env (jamais dans le client)
 */

const crypto = require('crypto');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const IP_SALT      = process.env.IP_SALT || 'goxen-fallback-salt';

const CORS = {
  'Access-Control-Allow-Origin':  'https://goxen.co',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Content-Type': 'application/json',
};

// ── helpers ────────────────────────────────────────────────────────

function hashIP(ip) {
  return crypto.createHmac('sha256', IP_SALT).update(ip).digest('hex');
}

async function sbReq(path, opts = {}) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...opts,
    headers: {
      'Content-Type': 'application/json',
      apikey:         SUPABASE_KEY,
      Authorization: `Bearer ${SUPABASE_KEY}`,
      ...opts.headers,
    },
  });
  const text = await res.text();
  let data;
  try { data = JSON.parse(text); } catch { data = text; }
  return { data, status: res.status };
}

function reply(statusCode, body) {
  return { statusCode, headers: CORS, body: JSON.stringify(body) };
}

// ── handler ────────────────────────────────────────────────────────

exports.handler = async (event) => {

  // Preflight CORS
  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers: CORS, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return reply(405, { error: 'Méthode non autorisée' });
  }

  // Parse body
  let body;
  try { body = JSON.parse(event.body || '{}'); }
  catch { return reply(400, { error: 'JSON invalide' }); }

  const { institution, pays } = body;
  if (!institution || !pays) {
    return reply(400, { error: 'Champs obligatoires manquants (institution, pays)' });
  }

  // Config manquante (env vars non définies)
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    console.error('submit-avis: SUPABASE_URL ou SUPABASE_SERVICE_ROLE_KEY manquant');
    return reply(500, { error: 'Configuration serveur incomplète.' });
  }

  // Hash IP — jamais stockée en clair
  const rawIP = (event.headers['x-forwarded-for'] || '').split(',')[0].trim()
    || event.headers['client-ip']
    || 'unknown';
  const ipHash = hashIP(rawIP);

  // Rate limit : même IP + même institution dans les 90 derniers jours ?
  const cutoff = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();
  const checkPath = `avis?select=id`
    + `&ip_hash=eq.${encodeURIComponent(ipHash)}`
    + `&institution=eq.${encodeURIComponent(institution)}`
    + `&created_at=gte.${cutoff}`
    + `&limit=1`;

  const { data: existing, status: checkStatus } = await sbReq(checkPath);

  if (checkStatus === 200 && Array.isArray(existing) && existing.length > 0) {
    return reply(429, {
      error: `Vous avez déjà soumis un avis pour ${institution} il y a moins de 90 jours.`,
    });
  }

  // Insertion avec ip_hash (jamais exposé au client)
  const record = { ...body, ip_hash: ipHash };
  const { status: insertStatus, data: insertData } = await sbReq('avis', {
    method: 'POST',
    headers: { Prefer: 'return=minimal' },
    body: JSON.stringify(record),
  });

  if (insertStatus >= 400) {
    console.error('submit-avis insert error:', insertData);
    return reply(500, { error: "Erreur lors de l'enregistrement. Réessayez." });
  }

  return reply(200, { success: true });
};
