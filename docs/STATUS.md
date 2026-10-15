# Status, known limitations and open tasks

Updated 2026-10-15.

## Milestones

| # | Milestone | State |
|---|---|---|
| 1 | Specification and architecture | done (docs/RULES, SCORING, ARCHITECTURE, DESIGN) |
| 2 | Core gameplay: deal, four modes, hidden roles, win conditions | done, tested |
| 3 | UI, original art, animations, sounds | done; music not included (below) |
| 4 | Localization (fa, en, hi) and persistence | done |
| 5 | Monetization architecture | interface only, no store active (by design) |
| 6 | Cross-platform builds | web built and checked; Android: see below; iOS: configured, not built |
| 7 | Testing and polish | automated tests green; device tests pending |

## Verified here

* `flutter analyze`: no issues.
* `flutter test`: engine tests (every deal × every legal guess for all four
  modes, both Indian variants, both guard characters, both scoring presets;
  uniform deal distribution; JSON round trip) and widget tests (home in fa,
  en, hi; full Persian round with saved scores; role visible only while held;
  cover after backgrounding; Two Thieves needs two picks) all pass.
* `node tools/web_build.mjs`: release web build without CDN, played
  through a full six-player round in headless Chromium (Persian), home
  screens checked in English, Hindi, at 320 px and on a 1180 px tablet.

## Needs a device, an account or a secret (not done here)

* Android release builds: the Android SDK was installed here, but Gradle's
  downloads from Maven Central were rate-limited (HTTP 429) twice, so no APK
  was produced in this environment. CI (`.github/workflows/android.yml`)
  builds the AAB and APKs on GitHub; signing needs your upload key
  (docs/RELEASE.md).
* Store uploads (Google Play, Cafe Bazaar, App Store), Play Console forms.
* Live since 2026-10-15: shahdozd.espadna.com and espadna.com/shahdozd-app
  (deployed by CI from `main`); the card is on the espadna.com home pages and
  both sites are on the espadna.ir mirror branch (the .ir host itself could
  not be reached from the build environment to check it).
* iOS TestFlight: build 2 uploaded 2026-10-15 by `.github/workflows/ios.yml`.
* Real-device checks: FLAG_SECURE on Android, the iOS app-switcher snapshot,
  haptics, audio latency, foldables, VoiceOver/TalkBack.
* Web PWA offline: the service worker is written and registered on HTTPS
  only; offline reload must be checked on the deployed HTTPS site.

## Known limitations

* No background music/ambience (only sound effects). Optional for later.
* Coins shop (2026-10-15): card backs, card frames, penalty packs; coins from
  sharing and rewarded ads (docs/MONETIZATION.md). AdMob runs on Google's
  test ids and Adivery is off until the real ids are set. Coins live on the
  device only; a share cannot be verified as an install (daily caps only).
* No money purchases: `lib/premium/` keeps the store-independent interface.
* The iOS home-screen name is "Shah Dozd Vazir" in every language
  (Android has localized names). Localized `InfoPlist.strings` need Xcode.
* Screen readers: buttons and cards have labels, but the press-and-hold
  reveal has no screen-reader alternative yet.
* The web build is ~33 MB on the server (several renderer variants); a
  Chrome visitor loads about 10 MB uncompressed the first time (less over
  the wire with Cloudflare compression), then plays from the cache.
* Card art is original vector art made in code (approved concept). A
  painted, more detailed edition could be produced later as a Premium theme.
