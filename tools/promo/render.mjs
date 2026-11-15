#!/usr/bin/env node
// Renders the Persian promo poster and video for Cafe Bazaar (and socials).
//
//   (python3 -m http.server 8790) &   # from the repo root
//   node tools/promo/render.mjs [poster|video] [http://localhost:8790]
//
// poster → store/promo/fa-iphone-android.jpg (1080×1920)
// video  → store/promo/fa-promo.mp4 (1080×1920, 30 fps, H.264 + AAC; needs ffmpeg)
import { execFileSync } from 'node:child_process';
import { mkdirSync, rmSync } from 'node:fs';

const pw = await import(process.env.PLAYWRIGHT || '/opt/node22/lib/node_modules/playwright/index.mjs');
const chromium = pw.chromium || pw.default.chromium;
const what = process.argv[2] || 'all';
const BASE = process.argv[3] || 'http://localhost:8790';
const ROOT = new URL('../..', import.meta.url).pathname;
const OUT = `${ROOT}store/promo`;
mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });

if (what === 'all' || what === 'poster') {
  await page.goto(`${BASE}/tools/promo/poster.html`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(500);
  await page.screenshot({ path: `${OUT}/fa-iphone-android.jpg`, type: 'jpeg', quality: 92 });
  console.log('poster: store/promo/fa-iphone-android.jpg');
}

if (what === 'all' || what === 'video') {
  const FPS = 30;
  await page.goto(`${BASE}/tools/promo/video.html`);
  await page.evaluate(() => document.fonts.ready);
  await page.waitForTimeout(800);
  const { duration, sounds } = await page.evaluate(() => ({ duration: window.DURATION, sounds: window.SOUNDS }));
  const frames = `${ROOT}build/promo-frames`;
  rmSync(frames, { recursive: true, force: true });
  mkdirSync(frames, { recursive: true });
  const n = Math.round(duration * FPS);
  for (let i = 0; i < n; i++) {
    await page.evaluate((t) => window.render(t), i / FPS);
    await page.screenshot({ path: `${frames}/${String(i).padStart(4, '0')}.jpg`, type: 'jpeg', quality: 95 });
  }
  // Sound effects from the game, each at its moment.
  const inputs = [];
  const filters = [];
  sounds.forEach(([file, at], k) => {
    inputs.push('-i', `${ROOT}assets/sounds/${file}`);
    filters.push(`[${k + 1}:a]adelay=${Math.round(at * 1000)}|${Math.round(at * 1000)}[s${k}]`);
  });
  const mix = `${filters.join(';')};${sounds.map((_, k) => `[s${k}]`).join('')}amix=inputs=${sounds.length}:normalize=0,apad[a]`;
  execFileSync('ffmpeg', ['-y', '-loglevel', 'error', '-framerate', String(FPS), '-i', `${frames}/%04d.jpg`, ...inputs,
    '-filter_complex', mix, '-map', '0:v', '-map', '[a]', '-t', String(duration),
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-crf', '20', '-preset', 'slow', '-movflags', '+faststart',
    '-c:a', 'aac', '-b:a', '128k', `${OUT}/fa-promo.mp4`], { stdio: 'inherit' });
  rmSync(frames, { recursive: true, force: true });
  console.log(`video: store/promo/fa-promo.mp4 (${duration}s, ${n} frames)`);
}
await browser.close();
