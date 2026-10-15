#!/usr/bin/env node
// Sets up Game Center for the app in App Store Connect, through the API key
// the iOS build already uses (run by .github/workflows/gamecenter.yml).
// Adapted from hajiheidari/mafia tools/gamecenter_setup.mjs.
//
//   - Game Center turned on for the app
//   - one all-time leaderboard: rounds played (lib/app/stats.dart)
//   - the achievements of ios/gamecenter/gamecenter.json, with English and
//     Hindi texts and the images ios/gamecenter/<key>.png
//
// Safe to run again: whatever already exists is left as it is. App Store
// Connect has no Persian locale; Persian players see the English names.
//
// Env: ASC_ISSUER_ID, ASC_KEY_ID, ASC_PRIVATE_KEY, IOS_BUNDLE_ID (default com.espadna.shahdozd).
import { readFileSync, statSync } from 'node:fs';
import { api } from './ios_signing.mjs';

const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.espadna.shahdozd';
const ROOT = new URL('..', import.meta.url).pathname;
const GC = JSON.parse(readFileSync(`${ROOT}ios/gamecenter/gamecenter.json`, 'utf8'));
const LOCALES = ['en-US', 'hi'];

const log = (...a) => console.log(...a);
let problems = 0;
const warn = (msg) => {
  problems++;
  console.log(`::warning::${msg}`);
};

async function all(path) {
  const out = [];
  let next = path;
  while (next) {
    const page = await api('GET', next.replace('https://api.appstoreconnect.apple.com', ''));
    out.push(...page.data);
    next = page.links?.next;
  }
  return out;
}

const rel = (type, id) => ({ data: { type, id } });

async function gameCenterDetail(appId) {
  try {
    const r = await api('GET', `/v1/apps/${appId}/gameCenterDetail`);
    if (r?.data) return r.data.id;
  } catch (e) {
    if (!/404/.test(e.message)) throw e;
  }
  const r = await api('POST', '/v1/gameCenterDetails', {
    data: { type: 'gameCenterDetails', relationships: { app: rel('apps', appId) } },
  });
  log('Game Center turned on for the app');
  return r.data.id;
}

async function leaderboards(detailId) {
  const existing = await all(`/v1/gameCenterDetails/${detailId}/gameCenterLeaderboards?limit=200`);
  const text = GC.leaderboard;
  let board = existing.find((b) => b.attributes.vendorIdentifier === text.id);
  if (!board) {
    try {
      board = (await api('POST', '/v1/gameCenterLeaderboards', {
        data: {
          type: 'gameCenterLeaderboards',
          attributes: {
            referenceName: text.ref,
            vendorIdentifier: text.id,
            defaultFormatter: 'INTEGER',
            submissionType: 'BEST_SCORE',
            scoreSortType: 'DESC',
            scoreRangeStart: '0',
            scoreRangeEnd: '10000000',
          },
          relationships: { gameCenterDetail: rel('gameCenterDetails', detailId) },
        },
      })).data;
      log(`leaderboard created: ${text.id}`);
    } catch (e) {
      warn(`could not create leaderboard ${text.id}: ${e.message}`);
      return;
    }
  } else {
    log(`leaderboard exists: ${text.id}`);
  }
  const locs = await all(`/v1/gameCenterLeaderboards/${board.id}/localizations?limit=50`);
  for (const locale of LOCALES) {
    if (locs.some((l) => l.attributes.locale === locale)) continue;
    try {
      await api('POST', '/v1/gameCenterLeaderboardLocalizations', {
        data: {
          type: 'gameCenterLeaderboardLocalizations',
          attributes: { locale, name: text[locale] },
          relationships: { gameCenterLeaderboard: rel('gameCenterLeaderboards', board.id) },
        },
      });
      log(`  ${locale}: ${text[locale]}`);
    } catch (e) {
      warn(`leaderboard ${locale}: ${e.message}`);
    }
  }
}

async function uploadImage(localizationId, file) {
  const bytes = readFileSync(file);
  const res = await api('POST', '/v1/gameCenterAchievementImages', {
    data: {
      type: 'gameCenterAchievementImages',
      attributes: { fileName: file.split('/').pop(), fileSize: statSync(file).size },
      relationships: { gameCenterAchievementLocalization: rel('gameCenterAchievementLocalizations', localizationId) },
    },
  });
  for (const op of res.data.attributes.uploadOperations || []) {
    const headers = Object.fromEntries((op.requestHeaders || []).map((h) => [h.name, h.value]));
    const r = await fetch(op.url, { method: op.method, headers, body: bytes.subarray(op.offset, op.offset + op.length) });
    if (!r.ok) throw new Error(`image upload → ${r.status}`);
  }
  await api('PATCH', `/v1/gameCenterAchievementImages/${res.data.id}`, {
    data: { type: 'gameCenterAchievementImages', id: res.data.id, attributes: { uploaded: true } },
  });
}

async function achievements(detailId) {
  const existing = await all(`/v1/gameCenterDetails/${detailId}/gameCenterAchievements?limit=200`);
  for (const medal of GC.achievements) {
    let ach = existing.find((a) => a.attributes.vendorIdentifier === medal.id);
    if (!ach) {
      try {
        ach = (await api('POST', '/v1/gameCenterAchievements', {
          data: {
            type: 'gameCenterAchievements',
            attributes: {
              referenceName: medal['en-US'][0],
              vendorIdentifier: medal.id,
              points: medal.points,
              showBeforeEarned: true,
              repeatable: false,
            },
            relationships: { gameCenterDetail: rel('gameCenterDetails', detailId) },
          },
        })).data;
        log(`achievement created: ${medal.id} (${medal.points} points)`);
      } catch (e) {
        warn(`achievement ${medal.id}: ${e.message}`);
        continue;
      }
    } else {
      log(`achievement exists: ${medal.id}`);
    }
    const locs = await all(`/v1/gameCenterAchievements/${ach.id}/localizations?limit=50`);
    for (const locale of LOCALES) {
      let loc = locs.find((l) => l.attributes.locale === locale);
      try {
        if (!loc) {
          const [name, desc] = medal[locale];
          loc = (await api('POST', '/v1/gameCenterAchievementLocalizations', {
            data: {
              type: 'gameCenterAchievementLocalizations',
              attributes: {
                locale,
                name,
                beforeEarnedDescription: desc,
                afterEarnedDescription: desc,
              },
              relationships: { gameCenterAchievement: rel('gameCenterAchievements', ach.id) },
            },
          })).data;
          log(`  ${locale}: ${name}`);
        }
        const image = await api('GET', `/v1/gameCenterAchievementLocalizations/${loc.id}/gameCenterAchievementImage`).catch(() => null);
        if (!image?.data) {
          await uploadImage(loc.id, `${ROOT}ios/gamecenter/${medal.key}.png`);
          log(`  ${locale}: image uploaded`);
        }
      } catch (e) {
        warn(`achievement ${medal.id} ${locale}: ${e.message}`);
      }
    }
  }
}

try {
  const apps = await api('GET', `/v1/apps?filter[bundleId]=${BUNDLE_ID}&limit=5`);
  const app = apps.data.find((a) => a.attributes.bundleId === BUNDLE_ID);
  if (!app) throw new Error(`no app with bundle id ${BUNDLE_ID} in App Store Connect`);
  log(`app: ${app.attributes.name} (${app.id})`);
  const detailId = await gameCenterDetail(app.id);
  await leaderboards(detailId);
  await achievements(detailId);
  log(problems ? `done with ${problems} problem(s); see the warnings above` : 'Game Center is set up');
  if (problems) process.exit(1);
} catch (e) {
  console.error(`::error::${e.message}`);
  process.exit(1);
}
