# Coins, shop and rewarded ads

All four modes stay free with unlimited rounds. Coins buy only looks and
extra penalty packs; nothing changes who wins.

## Coins (`lib/shop/wallet.dart`)

| Source | Coins | Limit | Most per day |
|---|---|---|---|
| Welcome gift (first launch, shown in a popup that leads to the shop) | 150 | once | |
| Share the game with friends (share sheet completed; on the web the link is copied) | 15 | 2 per day | 30 |
| Watch a rewarded ad to the end (player taps "Watch an ad" in the shop) | 10 | 8 per day | 80 |

So a very active player earns at most 110 coins a day. Sharing pays little on
purpose: without a server a share cannot be verified as an install. Coins
cannot be bought; the shop header says no real money is needed.

## Shop (`lib/shop/catalog.dart`)

| Kind | Items (price in coins) | Days at the daily maximum |
|---|---|---|
| Card backs | Royal Classic (free), Emerald, Ruby (600), Paisley, Starry Night (900), Golden Sun (1200) | 6 to 11 |
| Card styles: frame, colours and background of every card | Gold (free), Silver (1200), Persian Tile (1500), Khatam-kari inlay (1800), Persian Miniature (2000) | 11 to 18 |
| Whole decks: every character redrawn | Royal (free), Qajar Portrait (4000), Shadow Play (5000), Gold Engraving (6000) | 36 to 55 |
| Penalty packs | Party penalties (1000), the Executioner's fiery penalties (1500) | 9 to 14 |

A deck replaces the faces and takes precedence over the card style; the style
shows again when the Royal deck is chosen. Each item has a stable `code`
(0..31) used by the recovery code: never reuse or renumber a code.

Art is generated: `tools/gen_art.py` (STYLES for styles and decks, `back(...)`
for backs) → `node tools/render_art.mjs` → `assets/cards/{backs,silver,tile,
khatam,miniature}/` and `assets/cards/decks/{qajar,shadow,engraving}/`.

## Backup and recovery

* iOS: the whole saved state is mirrored to iCloud key-value storage
  (`backup.v1`, a few seconds after each change) and restored automatically on
  a fresh install; Settings has "Restore from iCloud".
* Android: Auto Backup to the player's Google Drive
  (`res/xml/data_extraction_rules.xml`, `full_backup_content.xml`; shared
  preferences only).
* Everywhere (also web and the Iranian network): an offline recovery code in
  Settings (`lib/shop/recovery.dart`): coins, bought and equipped items and
  rounds played, with a short HMAC so typos fail. Restoring merges: more
  coins win, items are added, nothing is taken away.

## Game Center (iOS)

Leaderboard `shahdozd.rounds` (rounds played) and 9 achievements, defined in
`ios/gamecenter/gamecenter.json` (checked against `lib/app/stats.dart` by
`test/shop/recovery_test.dart`) and created in App Store Connect by
`.github/workflows/gamecenter.yml`. Sign-in is silent at launch and never
blocks play.

## Rewarded ads (`lib/shop/ads.dart`)

Only rewarded ads, only when the player asks. No banners, no interstitials,
nothing during play. Non-personalized requests (no tracking prompt needed).

| Build (`CHANNEL`) | Network | Configuration |
|---|---|---|
| `play` (Google Play), `appstore` (iOS) | Google AdMob (`google_mobile_ads`) | app id in `AndroidManifest.xml` / `Info.plist`; rewarded unit via `--dart-define=ADMOB_REWARDED_ANDROID=…` / `ADMOB_REWARDED_IOS=…` |
| `bazaar`, `apk` (Iran) | Adivery (native SDK 4.8.3 via `android/app/src/{bazaar,direct}/…/AdsBridge.kt`) | `--dart-define=ADIVERY_APP_ID=… --dart-define=ADIVERY_REWARDED=…` |
| web | none | the button is hidden |

**Until real ids are set:** AdMob uses Google's public *test* ids (test ads
only, no revenue); Adivery is off (button hidden). To go live:

1. AdMob: create the app(s) "Shah Dozd Vazir" for Android and iOS and one
   rewarded ad unit each. Replace the test app ids in
   `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`,
   and pass the unit ids as repository secrets/variables to the build
   (`ADMOB_REWARDED_ANDROID`, `ADMOB_REWARDED_IOS`).
2. Adivery: add the app (package `com.espadna.shahdozd`) in the Adivery panel
   with one rewarded placement; set `ADIVERY_APP_ID` and `ADIVERY_REWARDED`.
3. Store forms: Google Play "Contains ads: yes" and Data safety (advertising
   ID, collected by AdMob); App Store privacy "Identifiers / Device ID: used for
   third-party advertising, not linked to the user"; update the listings.

## Store purchases

None. `lib/premium/entitlements.dart` keeps the store-independent interface
for a future optional purchase.
