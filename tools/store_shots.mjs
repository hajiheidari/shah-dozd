#!/usr/bin/env node
// Store screenshots from the web build, driven through Flutter's
// accessibility tree (so it works in every language and screen size).
//
//   flutter build web --release --no-web-resources-cdn
//   (cd build/web && python3 -m http.server 8766) &
//   node tools/store_shots.mjs [http://localhost:8766]
//
// Writes store/screenshots/<device>/<lang>/0N-<name>.jpg:
//   iphone  1320×2868 (App Store 6.9")      en, hi
//   ipad    2064×2752 (App Store 13")       en, hi
//   android 1080×1920 (Google Play, Bazaar) fa, en, hi
import { mkdirSync, rmSync } from 'node:fs';
// Playwright: the global install, or PLAYWRIGHT=/path/to/playwright/index.mjs.
const pw = await import(process.env.PLAYWRIGHT || '/opt/node22/lib/node_modules/playwright/index.mjs');
const chromium = pw.chromium || pw.default.chromium;

const BASE = process.argv[2] || 'http://localhost:8766';
const ROOT = new URL('..', import.meta.url).pathname;
const DEVICES = {
  iphone: { viewport: { width: 440, height: 956 }, scale: 3, langs: ['en', 'hi'] },
  ipad: { viewport: { width: 1032, height: 1376 }, scale: 2, langs: ['en', 'hi'] },
  android: { viewport: { width: 405, height: 720 }, scale: 8 / 3, langs: ['fa', 'en', 'hi'] },
};
const NAMES = {
  en: ['Sara', 'Ali', 'Maya', 'Leo', 'Nina', 'Omid'],
  fa: ['سارا', 'علی', 'مریم', 'رضا', 'نیلوفر', 'امید'],
  hi: ['प्रिया', 'राहुल', 'अंजलि', 'विक्रम', 'नेहा', 'अर्जुन'],
};
// Home: buttons 0-2 are Players, Shop, Settings; then the four modes.
const MODE = { en: 3, fa: 3, hi: 4 }; // Hindi players get the Indian Classic

const browser = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });

async function run(device, lang) {
  const d = DEVICES[device];
  const dir = `${ROOT}store/screenshots/${device}/${lang}`;
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(dir, { recursive: true });
  const context = await browser.newContext({ viewport: d.viewport, deviceScaleFactor: d.scale, locale: 'en-US' });
  const page = await context.newPage();
  page.on('pageerror', (e) => console.error(device, lang, e.message.split('\n')[0]));
  await page.addInitScript((l) => {
    const put = (k, v) => localStorage.setItem(`flutter.${k}`, JSON.stringify(JSON.stringify(v)));
    put('wallet.v1', { coins: 2450, welcomed: true });
    put('settings.v1', { lang: l, sound: false });
  }, lang);
  await page.goto(`${BASE}/?lang=${lang}`);
  await page.waitForTimeout(5000);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await page.waitForTimeout(800);
  const buttons = () => page.getByRole('button');
  const slow = device === 'ipad' ? 2 : 1; // the big canvas renders slower
  const wait = (ms = 900) => page.waitForTimeout(ms * slow);
  let n = 0;
  const shot = async (name) => {
    await page.screenshot({ path: `${dir}/0${++n}-${name}.jpg`, type: 'jpeg', quality: 90 });
  };
  const hold = async (ms) => {
    const box = await page.getByRole('button').nth(1).boundingBox();
    await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
    await page.mouse.down();
    await wait(ms);
  };

  await shot('home');

  // Setup: four names, then start.
  await buttons().nth(MODE[lang]).click();
  await wait(1200);
  const names = NAMES[lang];
  for (let i = 0; i < 4; i++) {
    const badge = await buttons().nth(2 + i).boundingBox(); // after Back, Full rules
    const x = lang === 'fa' ? badge.x - 120 : badge.x + badge.width + 120; // the field is beside the badge
    await page.mouse.click(x, badge.y + badge.height / 2);
    await wait(600);
    await page.keyboard.type(names[i], { delay: 30 });
    await wait(300);
  }
  await page.keyboard.press('Escape');
  await page.mouse.click(5, d.viewport.height * 0.7);
  await wait(400);
  await shot('setup');
  await buttons().last().click();
  await wait(1500);

  // Deal: each player says "I am …", holds the card, passes the phone on.
  for (let i = 0; i < 4; i++) {
    await buttons().last().click(); // I am …
    await wait(1000);
    await hold(1300);
    if (i === 0) await shot('role');
    await page.mouse.up();
    await wait(500);
    await buttons().last().click(); // pass the phone on
    await wait(1100);
  }
  await buttons().last().click(); // announce: ready to guess
  await wait(1200);
  // Guess: pick the first player button that is a name.
  const all = await buttons().allTextContents();
  const idx = all.findIndex((t) => names.some((nm) => t.includes(nm)));
  await buttons().nth(idx).click();
  await wait(700);
  await shot('guess');
  await buttons().last().click(); // reveal
  await wait(3200);
  await shot('result');

  // Shop, from home.
  await page.goto(`${BASE}/?lang=${lang}`);
  await wait(4500);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await wait(800);
  await buttons().nth(1).click();
  await wait(1500);
  await shot('shop');
  await page.mouse.move(d.viewport.width / 2, d.viewport.height / 2);
  const scroll = async (times) => {
    for (let i = 0; i < times; i++) {
      await page.mouse.wheel(0, d.viewport.height * 0.5);
      await wait(600);
    }
    await wait(1000);
  };
  await scroll(12);
  await shot('decks');
  await context.close();
  console.log(`${device}/${lang}: ${n} screenshots`);
}

// ONLY=iphone:en limits the run to one device/language.
for (const [device, d] of Object.entries(DEVICES)) {
  for (const lang of d.langs) {
    if (!process.env.ONLY || process.env.ONLY === `${device}:${lang}`) await run(device, lang);
  }
}
await browser.close();
