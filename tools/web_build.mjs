#!/usr/bin/env node
// Builds the two static sites of Shah, Dozd, Vazir:
//
//   build/site/      → https://shahdozd.espadna.com        (the game, Flutter web)
//   build/landing/   → https://espadna.com/shahdozd-app/   (landing pages, en/fa/hi)
//   build/shahdozd-web.zip  build/site for a manual mirror (any folder of any host)
//
// Each site gets _headers (Cloudflare cache rules) and files.json: every file
// with its sha256 plus the _redirects text, which the Iranian mirror
// (hajiheidari/espadna-site, mirror-ir/sync.php) copies to espadna.ir.
//
//   node tools/web_build.mjs            (runs `flutter build web` first)
//   node tools/web_build.mjs --no-flutter   (reuse build/web)
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { cpSync, existsSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { join, relative } from 'node:path';

const root = new URL('..', import.meta.url).pathname;
const build = join(root, 'build');

const walk = (dir) =>
  readdirSync(dir).flatMap((f) => {
    const p = join(dir, f);
    return statSync(p).isDirectory() ? walk(p) : [p];
  });
const rel = (base, f) => relative(base, f).split('\\').join('/');
const sha = (data) => createHash('sha256').update(data).digest('hex');

/** files.json for the mirror; `dir` is the folder that maps to the site's root URL. */
function manifest(dir, redirects) {
  const files = walk(dir)
    .map((f) => rel(dir, f))
    .filter((f) => !['files.json', '_headers', '_redirects'].includes(f))
    .sort()
    .map((f) => {
      const data = readFileSync(join(dir, f));
      return { path: f, size: data.length, sha256: sha(data) };
    });
  const version = sha(files.map((f) => f.sha256).join('') + redirects).slice(0, 12);
  writeFileSync(join(dir, 'files.json'), JSON.stringify({ version, files, redirects }));
  return { version, count: files.length, bytes: files.reduce((a, f) => a + f.size, 0) };
}

// --- the game ---------------------------------------------------------------
if (!process.argv.includes('--no-flutter')) {
  // No CDN: CanvasKit and the fallback font are served from our own site, so
  // the game also loads on the Iranian national internet (espadna.ir).
  execFileSync('flutter', ['build', 'web', '--release', '--no-web-resources-cdn', '--no-wasm-dry-run'], { cwd: root, stdio: 'inherit' });
}

const site = join(build, 'site');
rmSync(site, { recursive: true, force: true });
cpSync(join(build, 'web'), site, { recursive: true });

// Debug symbols and Flutter's own (no-op) service worker are not shipped.
for (const f of walk(site)) {
  const r = rel(site, f);
  if (r.endsWith('.symbols') || r === 'flutter_service_worker.js' || r === 'assets/NOTICES') rmSync(f);
}

// Files every visitor needs, cached by sw.js at install. Renderer variants
// for other browsers are cached on first use instead.
const all = walk(site).map((f) => rel(site, f)).filter((f) => f !== 'sw.js').sort();
const core = [
  './',
  ...all.filter(
    (f) =>
      !f.startsWith('canvaskit/') ||
      f === 'canvaskit/canvaskit.js' ||
      f === 'canvaskit/canvaskit.wasm' ||
      f.startsWith('canvaskit/chromium/'),
  ),
].filter((f) => f !== 'index.html');
const appVersion = sha(all.map((f) => f + sha(readFileSync(join(site, f)))).join('')).slice(0, 12);
const swPath = join(site, 'sw.js');
writeFileSync(swPath, readFileSync(swPath, 'utf8').replace('__VERSION__', appVersion).replace('__FILES__', JSON.stringify(core)));

writeFileSync(join(site, '_headers'), `/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
/
  Cache-Control: no-cache
/index.html
  Cache-Control: no-cache
/sw.js
  Cache-Control: no-cache
/flutter_bootstrap.js
  Cache-Control: no-cache
/main.dart.js
  Cache-Control: no-cache
/manifest.json
  Cache-Control: no-cache
/version.json
  Cache-Control: no-cache
/canvaskit/*
  Cache-Control: public, max-age=604800
/assets/*
  Cache-Control: public, max-age=86400
`);
const siteRedirects = '';
writeFileSync(join(site, '_redirects'), siteRedirects);
const s = manifest(site, siteRedirects);

// --- landing pages ------------------------------------------------------------
const landing = join(build, 'landing');
rmSync(landing, { recursive: true, force: true });
execFileSync('python3', [join(root, 'tools/landing.py'), join(landing, 'shahdozd-app')], { stdio: 'inherit' });
writeFileSync(join(landing, '_headers'), `/shahdozd-app/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
`);
// Paths in files.json and its redirects are relative to /shahdozd-app/.
const landingRedirects = '/en /shahdozd-app/ 301\n/en/ /shahdozd-app/ 301\n/privacy /shahdozd-app/privacy/ 301\n';
writeFileSync(
  join(landing, '_redirects'),
  '/shahdozd-app/en /shahdozd-app/ 301\n/shahdozd-app/en/ /shahdozd-app/ 301\n/shahdozd-app/privacy /shahdozd-app/privacy/ 301\n',
);
const l = manifest(join(landing, 'shahdozd-app'), landingRedirects);

// --- zip of the game for a manual mirror --------------------------------------
const zip = join(build, 'shahdozd-web.zip');
rmSync(zip, { force: true });
if (existsSync('/usr/bin/zip')) {
  execFileSync('zip', ['-qr', zip, '.', '-x', '_headers', '_redirects'], { cwd: site });
}

const mb = (b) => (b / 1048576).toFixed(1) + ' MB';
console.log(`build/site: ${s.count} files, ${mb(s.bytes)}, version ${s.version} (sw ${appVersion}, ${core.length} precached)`);
console.log(`build/landing/shahdozd-app: ${l.count} files, version ${l.version}`);
