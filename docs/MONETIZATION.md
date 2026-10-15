# Coins, shop and rewarded ads

All four modes stay free with unlimited rounds. Coins buy only looks and
extra penalty packs; nothing changes who wins.

## Coins (`lib/shop/wallet.dart`)

| Source | Coins | Limit |
|---|---|---|
| Welcome gift (first launch) | 100 | once |
| Share the game with friends (share sheet completed; on the web the link is copied) | 50 | 3 per day |
| Watch a rewarded ad to the end (player taps "Watch an ad" in the shop) | 25 | 10 per day |

Coins cannot be bought. Without accounts or a server, coins and items live on
the device only (a reinstall starts over), and a share cannot be verified as
an install: the daily cap is the only guard.

## Shop (`lib/shop/catalog.dart`)

| Item | Price |
|---|---|
| Card backs: Royal Classic (free), Emerald, Ruby (150), Paisley, Starry Night (250), Golden Sun (300) | |
| Card frames: Gold (free), Silver (200), Rose-gold (250), Jade (300) | |
| Penalty packs: Party penalties (200), the Executioner's fiery penalties (300) | |

Art is generated: `tools/gen_art.py` (THEMES for frames, `back(...)` for backs)
→ `node tools/render_art.mjs` → `assets/cards/{backs,silver,rose,jade}/`.

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
