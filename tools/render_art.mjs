#!/usr/bin/env node
// Renders the vector sources in art/ to the bitmaps the app ships:
//   art/cards/*.svg → assets/cards/*.webp (600×840, transparent corners)
//   art/icon.svg    → assets/icon/icon.png (1024), web/icons/*, web/favicon.png
// Needs Playwright's Chromium (dev only):  node tools/render_art.mjs
import { chromium } from 'playwright';
import { execFileSync } from 'node:child_process';
import { mkdirSync, readdirSync, readFileSync, rmSync } from 'node:fs';
import { join } from 'node:path';

const root = new URL('..', import.meta.url).pathname;
const browser = await chromium.launch();
async function shot(svgPath, out, w, h) {
  const page = await browser.newPage({ viewport: { width: w, height: h } });
  const svg = readFileSync(svgPath, 'utf8');
  await page.setContent(`<html><body style="margin:0;background:transparent">${svg.replace(/<svg /, `<svg style="display:block;width:${w}px;height:${h}px" `)}</body></html>`);
  await page.screenshot({ path: out, omitBackground: true });
  await page.close();
}
mkdirSync(join(root, 'assets/cards'), { recursive: true });
const tmp = join(root, 'build/art');
mkdirSync(tmp, { recursive: true });
for (const f of readdirSync(join(root, 'art/cards')).filter((f) => f.endsWith('.svg'))) {
  const name = f.replace('.svg', '');
  const png = join(tmp, name + '.png');
  await shot(join(root, 'art/cards', f), png, 600, 840);
  execFileSync('convert', [png, '-quality', '90', '-define', 'webp:alpha-quality=100', join(root, 'assets/cards', name + '.webp')]);
}
mkdirSync(join(root, 'assets/icon'), { recursive: true });
await shot(join(root, 'art/icon.svg'), join(root, 'assets/icon/icon.png'), 1024, 1024);
await browser.close();
const icon = join(root, 'assets/icon/icon.png');
const sizes = { 'web/icons/Icon-192.png': 192, 'web/icons/Icon-512.png': 512, 'web/icons/Icon-maskable-192.png': 192,
  'web/icons/Icon-maskable-512.png': 512, 'web/favicon.png': 64 };
for (const [out, s] of Object.entries(sizes)) execFileSync('convert', [icon, '-resize', `${s}x${s}`, join(root, out)]);
rmSync(tmp, { recursive: true, force: true });
console.log('rendered');
