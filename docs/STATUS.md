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
* iOS / iPadOS: needs a Mac with Xcode and an Apple Developer team. The
  project is configured (bundle id, name, locales, icons, launch colour) but
  has not been compiled.
* Store uploads (Google Play, Cafe Bazaar, App Store), Play Console forms.
* Cloudflare deploy: needs `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`
  in this repository's secrets; then merge to `main`.
* espadna-site: branch `claude/cool-johnson-mrzl83` (home card, sitemap,
  mirror entries) waits to be merged after the first deploy; create
  `shahdozd.espadna.ir` + SSL on the Iranian host.
* Real-device checks: FLAG_SECURE on Android, the iOS app-switcher snapshot,
  haptics, audio latency, foldables, VoiceOver/TalkBack.
* Web PWA offline: the service worker is written and registered on HTTPS
  only; offline reload must be checked on the deployed HTTPS site.

## Known limitations

* No background music/ambience (only sound effects). Optional for later.
* Premium is not purchasable: `lib/premium/` defines the store-independent
  interface and `NoBilling`; adapters for Google Play Billing, Cafe Bazaar
  (Poolakey) and Apple IAP are to be added only after their current SDKs,
  policies and merchant accounts are verified. Purchases will not move
  between stores (no accounts).
* Cosmetic Premium content (card themes, extra art, sound packs, extra
  challenge packs, custom challenges) is not made yet.
* The iOS home-screen name is "Shah Dozd Vazir" in every language
  (Android has localized names). Localized `InfoPlist.strings` need Xcode.
* Screen readers: buttons and cards have labels, but the press-and-hold
  reveal has no screen-reader alternative yet.
* The web build is ~33 MB on the server (several renderer variants); a
  Chrome visitor loads about 10 MB uncompressed the first time (less over
  the wire with Cloudflare compression), then plays from the cache.
* Card art is original vector art made in code (approved concept). A
  painted, more detailed edition could be produced later as a Premium theme.
