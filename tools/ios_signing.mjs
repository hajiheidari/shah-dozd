#!/usr/bin/env node
// App Store signing for CI (used by .github/workflows/ios.yml). Adapted from
// hajiheidari/mafia tools/ios_signing.mjs.
// The bundle id comes from IOS_BUNDLE_ID and is registered on first use.
//
// The Espadna team keeps one Apple Distribution certificate for good
// (revoking the certificate that signed a build makes Apple reject that build,
// ITMS-90035). The Mafia app's CI keeps it in Cloudflare Workers KV
// (namespace "mafia-ci", key "ios-distribution-certificate"), encrypted with
// a key derived from ASC_PRIVATE_KEY. This app *reads* that shared
// certificate and never overwrites or revokes it. Only if it cannot be read
// (missing, or saved with another App Store Connect key) does this app make
// its own certificate, kept under its own KV key. This copy never revokes
// any certificate.
//
//   node tools/ios_signing.mjs load <out-dir>
//       writes key.pem + cert.cer of the kept certificate and prints its id;
//       exits with 3 when there is none (or Apple no longer accepts it).
//   node tools/ios_signing.mjs newcert <csr-file> <key-file> <out-dir>
//       creates the certificate from the CSR, keeps it with its key, writes
//       cert.cer and prints its id.
//   node tools/ios_signing.mjs profile <cert-id> <out-dir>
//       (re)uses the app's App Store profile for that certificate; writes
//       profile.mobileprovision and prints {"profileId","profileName","profileUuid"}.
//
// Env: ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY (.p8 file, with or without
// its BEGIN/END lines); for load/newcert also CLOUDFLARE_API_TOKEN,
// CLOUDFLARE_ACCOUNT_ID and CF_KV_ID (the "mafia-ci" namespace, from
// tools/cf_kv.mjs). Never prints secrets.
import crypto from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';

const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.espadna.shahdozd';
const APP_NAME = process.env.IOS_APP_NAME || 'Shah Dozd Vazir';

// Team keys sign with iss = Issuer ID; Individual keys use sub = "user" and no
// iss. The kind that works is remembered after the first successful call.
let keyKind = process.env.ASC_KEY_KIND || 'team';

function token(kind = keyKind) {
  let k = process.env.ASC_PRIVATE_KEY.trim();
  if (!k.includes('BEGIN')) {
    k = `-----BEGIN PRIVATE KEY-----\n${k.replace(/\s+/g, '')}\n-----END PRIVATE KEY-----\n`;
  }
  const b64u = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  // Trimmed: a pasted secret often ends with a space or newline.
  const head = b64u({ alg: 'ES256', kid: process.env.ASC_KEY_ID.trim(), typ: 'JWT' });
  const claims = { iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' };
  if (kind === 'individual') claims.sub = 'user';
  else claims.iss = process.env.ASC_ISSUER_ID.trim();
  const body = b64u(claims);
  const sig = crypto
    .sign('sha256', Buffer.from(`${head}.${body}`), { key: crypto.createPrivateKey(k), dsaEncoding: 'ieee-p1363' })
    .toString('base64url');
  return `${head}.${body}.${sig}`;
}

async function api(method, path, body) {
  const send = (kind) =>
    fetch(`https://api.appstoreconnect.apple.com${path}`, {
      method,
      headers: { Authorization: `Bearer ${token(kind)}`, 'Content-Type': 'application/json' },
      body: body ? JSON.stringify(body) : undefined,
    });
  let r = await send(keyKind);
  if (r.status === 401 && keyKind === 'team') {
    // Maybe an Individual key: same key, the other token form.
    const retry = await send('individual');
    if (retry.status !== 401) {
      keyKind = 'individual';
      console.error('using the key as an Individual key');
      r = retry;
    }
  }
  const text = await r.text();
  if (!r.ok) {
    const detail = (() => {
      try {
        return JSON.parse(text).errors.map((e) => `${e.title}: ${e.detail}`).join('; ');
      } catch {
        return text.slice(0, 300);
      }
    })();
    const hint = r.status === 401
      ? ' (Apple rejected the key: the Issuer ID, Key ID and .p8 file must belong to the same Team key with Admin access; an "Individual" key does not work here)'
      : '';
    throw new Error(`${method} ${path} → ${r.status} ${detail}${hint}`);
  }
  return text ? JSON.parse(text) : null;
}

async function appBundle() {
  const ids = await api('GET', `/v1/bundleIds?filter[identifier]=${BUNDLE_ID}&limit=20`);
  let bundle = ids.data.find((b) => b.attributes.identifier === BUNDLE_ID);
  if (!bundle) {
    // First build: register the App ID, so the app can then be created in
    // App Store Connect with this bundle id.
    const created = await api('POST', '/v1/bundleIds', {
      data: { type: 'bundleIds', attributes: { identifier: BUNDLE_ID, name: APP_NAME, platform: 'IOS' } },
    });
    bundle = created.data;
    console.error(`registered bundle id ${BUNDLE_ID}`);
  }
  return bundle;
}

// ---- The kept certificate, encrypted in Cloudflare KV ----

const SHARED_KV_KEY = 'ios-distribution-certificate'; // Mafia's, read only
const OWN_KV_KEY = 'shahdozd-ios-distribution-certificate';

function kvUrl(key) {
  const { CLOUDFLARE_ACCOUNT_ID: account, CF_KV_ID: ns } = process.env;
  if (!process.env.CLOUDFLARE_API_TOKEN || !account || !ns) {
    throw new Error('CLOUDFLARE_API_TOKEN, CLOUDFLARE_ACCOUNT_ID and CF_KV_ID are needed to keep the signing certificate');
  }
  return `https://api.cloudflare.com/client/v4/accounts/${account}/storage/kv/namespaces/${ns}/values/${key}`;
}

function vaultKey() {
  const body = process.env.ASC_PRIVATE_KEY.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  return crypto.createHash('sha256').update(`mafia-ios-signing-v1\n${body}`).digest();
}

async function keep(certId, keyPem, certDer) {
  const iv = crypto.randomBytes(12);
  const c = crypto.createCipheriv('aes-256-gcm', vaultKey(), iv);
  const plain = JSON.stringify({ keyPem, cert: certDer.toString('base64') });
  const data = Buffer.concat([c.update(plain, 'utf8'), c.final(), c.getAuthTag()]);
  const r = await fetch(kvUrl(OWN_KV_KEY), {
    method: 'PUT',
    headers: { Authorization: `Bearer ${process.env.CLOUDFLARE_API_TOKEN}`, 'Content-Type': 'text/plain' },
    body: JSON.stringify({ certId, iv: iv.toString('base64'), data: data.toString('base64') }),
  });
  if (!r.ok) throw new Error(`could not keep the certificate in Cloudflare KV → ${r.status}`);
}

async function kept() {
  return (await keptAt(OWN_KV_KEY)) || (await keptAt(SHARED_KV_KEY));
}

async function keptAt(key) {
  const r = await fetch(kvUrl(key), { headers: { Authorization: `Bearer ${process.env.CLOUDFLARE_API_TOKEN}` } });
  if (r.status === 404) return null;
  if (!r.ok) throw new Error(`could not read the kept certificate from Cloudflare KV → ${r.status}`);
  const box = JSON.parse(await r.text());
  const raw = Buffer.from(box.data, 'base64');
  const d = crypto.createDecipheriv('aes-256-gcm', vaultKey(), Buffer.from(box.iv, 'base64'));
  d.setAuthTag(raw.subarray(raw.length - 16));
  let plain;
  try {
    plain = JSON.parse(Buffer.concat([d.update(raw.subarray(0, raw.length - 16)), d.final()]).toString('utf8'));
  } catch {
    console.error(`the certificate kept as ${key} was saved with another App Store Connect key`);
    return null;
  }
  return { certId: box.certId, keyPem: plain.keyPem, certDer: Buffer.from(plain.cert, 'base64') };
}

async function load(outDir) {
  const k = await kept();
  if (!k) return 3;
  try {
    const c = await api('GET', `/v1/certificates/${k.certId}`);
    const left = new Date(c.data.attributes.expirationDate).getTime() - Date.now();
    if (left < 14 * 24 * 3600 * 1000) {
      console.error('the kept certificate expires within two weeks; making a new one');
      return 3;
    }
  } catch (e) {
    if (!/404/.test(e.message)) throw e;
    console.error('the kept certificate was revoked; making a new one');
    return 3;
  }
  writeFileSync(join(outDir, 'key.pem'), k.keyPem, { mode: 0o600 });
  writeFileSync(join(outDir, 'cert.cer'), k.certDer);
  console.log(k.certId);
  return 0;
}

async function newCert(csrFile, keyFile, outDir) {
  await appBundle();
  const csr = readFileSync(csrFile, 'utf8').replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  let cert;
  try {
    cert = await api('POST', '/v1/certificates', {
      data: { type: 'certificates', attributes: { certificateType: 'DISTRIBUTION', csrContent: csr } },
    });
  } catch (e) {
    if (/already have a current Distribution certificate/i.test(e.message)) {
      throw new Error('Apple allows no more Distribution certificates for this team. Run the Mafia app\'s iOS workflow once (it keeps the shared certificate), or revoke an unused one in developer.apple.com, then run again.');
    }
    throw e;
  }
  const der = Buffer.from(cert.data.attributes.certificateContent, 'base64');
  await keep(cert.data.id, readFileSync(keyFile, 'utf8'), der);
  writeFileSync(join(outDir, 'cert.cer'), der);
  console.error(`made and kept a new Apple Distribution certificate (${cert.data.id})`);
  console.log(cert.data.id);
}

/** The app's App Store profile for the kept certificate, reused while valid. */
async function profile(certId, outDir) {
  const bundle = await appBundle();
  const profileName = 'Shah Dozd App Store (CI)';
  const found = await api('GET', `/v1/profiles?filter[name]=${encodeURIComponent(profileName)}&include=certificates&limit=20`);
  const use0 = found.data.find((p) =>
    p.attributes.profileState === 'ACTIVE' &&
    new Date(p.attributes.expirationDate).getTime() - Date.now() > 14 * 24 * 3600 * 1000 &&
    (p.relationships?.certificates?.data || []).some((c) => c.id === certId));
  for (const p of found.data) {
    if (p !== use0) await api('DELETE', `/v1/profiles/${p.id}`).catch((e) => console.error(e.message));
  }
  let use = use0;
  if (!use) {
    use = (await api('POST', '/v1/profiles', {
      data: {
        type: 'profiles',
        attributes: { name: profileName, profileType: 'IOS_APP_STORE' },
        relationships: {
          bundleId: { data: { type: 'bundleIds', id: bundle.id } },
          certificates: { data: [{ type: 'certificates', id: certId }] },
        },
      },
    })).data;
    console.error('made the App Store profile');
  }
  writeFileSync(join(outDir, 'profile.mobileprovision'), Buffer.from(use.attributes.profileContent, 'base64'));
  console.log(JSON.stringify({ profileId: use.id, profileName, profileUuid: use.attributes.uuid }));
}

/** Format check of the three secrets, without printing them (diagnoses a 401). */
function check() {
  const problems = [];
  const issuer = (process.env.ASC_ISSUER_ID || '').trim();
  const keyId = (process.env.ASC_KEY_ID || '').trim();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(issuer)) {
    problems.push(`ASC_ISSUER_ID is not an Issuer ID (expected 36 characters like 69a6de7e-…; got ${issuer.length} characters)`);
  }
  if (!/^[A-Z0-9]{10}$/.test(keyId)) {
    problems.push(`ASC_KEY_ID is not a Key ID (expected 10 capital letters/digits; got ${keyId.length} characters)`);
  }
  if (issuer && keyId && issuer === keyId) problems.push('ASC_ISSUER_ID and ASC_KEY_ID are the same value');
  try {
    let k = (process.env.ASC_PRIVATE_KEY || '').trim();
    if (!k.includes('BEGIN')) k = `-----BEGIN PRIVATE KEY-----\n${k.replace(/\s+/g, '')}\n-----END PRIVATE KEY-----\n`;
    const key = crypto.createPrivateKey(k);
    if (key.asymmetricKeyType !== 'ec') problems.push('ASC_PRIVATE_KEY is not an App Store Connect key (.p8 EC key)');
  } catch {
    problems.push('ASC_PRIVATE_KEY cannot be read: paste the whole AuthKey_….p8 file');
  }
  for (const p of problems) console.error(`::error::${p}`);
  if (problems.length) process.exit(1);
  console.log('secrets look well-formed');
}

export { api };

// Run as a command unless imported.
const asCommand = import.meta.url === pathToFileURL(process.argv[1] || '').href;
const [cmd, a, b] = asCommand ? process.argv.slice(2) : [];
if (asCommand) try {
  if (cmd === 'check') check();
  else if (cmd === 'load') process.exitCode = await load(a);
  else if (cmd === 'newcert') await newCert(a, b, process.argv[5]);
  else if (cmd === 'profile') await profile(a, b);
  else throw new Error('usage: ios_signing.mjs check | load <dir> | newcert <csr> <key> <dir> | profile <certId> <dir>');
} catch (e) {
  console.error(`::error::${e.message}`);
  process.exit(1);
}
