#!/usr/bin/env node
// Renders the vector sources in art/ to the bitmaps the app ships:
//   art/cards/**/*.svg → assets/cards/**/*.webp (600×840, transparent corners)
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
// art/cards/<theme or backs>/<name>.svg → assets/cards/<same path>.webp
const svgs = (dir) => readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
  e.isDirectory() ? svgs(join(dir, e.name)).map((f) => join(e.name, f)) : e.name.endsWith('.svg') ? [e.name] : []);
for (const f of svgs(join(root, 'art/cards'))) {
  const name = f.replace(/\.svg$/, '');
  const png = join(tmp, name.replace(/\//g, '_') + '.png');
  await shot(join(root, 'art/cards', f), png, 600, 840);
  mkdirSync(join(root, 'assets/cards', name, '..'), { recursive: true });
  execFileSync('convert', [png, '-quality', '90', '-define', 'webp:alpha-quality=100', join(root, 'assets/cards', name + '.webp')]);
}
mkdirSync(join(root, 'assets/icon'), { recursive: true });
await shot(join(root, 'art/icon.svg'), join(root, 'assets/icon/icon.png'), 1024, 1024);
// Social preview for the landing pages (1200×630) → site/og.png
{
  const page = await browser.newPage({ viewport: { width: 1200, height: 630 } });
  const font = (f) => 'data:font/ttf;base64,' + readFileSync(join(root, 'assets/fonts', f)).toString('base64');
  const card = (n) => 'data:image/svg+xml;base64,' + readFileSync(join(root, 'art/cards', n + '.svg')).toString('base64');
  await page.setContent(`<html><head><style>
    @font-face{font-family:V;src:url(${font('Vazirmatn-Black.ttf')});font-weight:900}
    @font-face{font-family:C;src:url(${font('CormorantGaramond-Bold.ttf')});font-weight:700}
    body{margin:0;width:1200px;height:630px;background:radial-gradient(circle at 70% 45%,#2A2466,#0C0F2A 70%);display:flex;align-items:center;overflow:hidden}
    .t{width:560px;padding-left:70px;color:#E9CD86}
    h1{font:900 82px/1.2 V;margin:0;direction:rtl;text-align:left}
    p{font:700 40px C;color:#F6EEDC;margin:10px 0 0}
    .fan{position:relative;flex:1;height:630px}
    .fan img{position:absolute;width:250px;top:120px;filter:drop-shadow(0 20px 30px rgba(0,0,0,.55))}
  </style></head><body><div class="t"><h1>شاه، دزد، وزیر</h1><p>Shah · Thief · Minister</p></div>
  <div class="fan"><img src="${card('minister')}" style="left:40px;transform:rotate(-12deg)"><img src="${card('joker')}" style="left:330px;transform:rotate(12deg)"><img src="${card('king')}" style="left:180px;top:90px;width:280px"></div></body></html>`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(300);
  await page.screenshot({ path: join(root, 'site/og.png') });
  await page.close();
}
await browser.close();
const icon = join(root, 'assets/icon/icon.png');
const sizes = { 'web/icons/Icon-192.png': 192, 'web/icons/Icon-512.png': 512, 'web/icons/Icon-maskable-192.png': 192,
  'web/icons/Icon-maskable-512.png': 512, 'web/favicon.png': 64 };
for (const [out, s] of Object.entries(sizes)) execFileSync('convert', [icon, '-resize', `${s}x${s}`, join(root, out)]);
// Game Center achievement images (1024×1024, opaque) → ios/gamecenter/<key>.png
const ACH = { first_round: 'king', rounds_50: 'minister', rounds_200: 'sipahi', champion: 'decks/engraving/king',
  all_modes: 'back', perfect_catch: 'thief2', joker_trick: 'joker', collector: 'backs/sun', deck_owner: 'decks/qajar/king' };
for (const [key, card] of Object.entries(ACH)) {
  execFileSync('convert', ['-size', '1024x1024', 'radial-gradient:#2A2466-#0C0F2A',
    '(', join(root, 'assets/cards', card + '.webp'), '-resize', 'x840', ')', '-gravity', 'center', '-composite',
    '-alpha', 'off', '-depth', '8', join(root, 'ios/gamecenter', key + '.png')]);
}
rmSync(tmp, { recursive: true, force: true });
console.log('rendered');
