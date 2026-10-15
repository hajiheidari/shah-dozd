# Builds and releases

Nothing here publishes on its own: store uploads, signing keys, developer
accounts and Cloudflare secrets are the owner's. Commands assume Flutter
3.47 stable (`flutter --version`) and are run from the repo root.

## Web (shahdozd.espadna.com) and landing pages (espadna.com/shahdozd-app)

```bash
node tools/web_build.mjs
#   build/site/      the game (Flutter web, no CDN, sw.js offline, files.json)
#   build/landing/   landing pages en/fa/hi + privacy
#   build/shahdozd-web.zip  the game for any static host
```

Deployment is automatic: `.github/workflows/web.yml` tests and builds on every
push and deploys from `main` to two Cloudflare Workers
(`deploy/wrangler.site.toml` → custom domain `shahdozd.espadna.com`,
`deploy/wrangler.landing.toml` → route `espadna.com/shahdozd-app*`).
Needs repository secrets `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`
(the same values as in hajiheidari/espadna-site; the token needs *Workers
Scripts: Edit*, *Workers Routes: Edit* and the `espadna.com` zone). Never run
`wrangler deploy` by hand.

PWA: installable from the browser menu (manifest + icons); offline after the
first full load, on HTTPS only.

### espadna.com home page and espadna.ir

In hajiheidari/espadna-site (see its CLAUDE.md), one commit on `main`:

1. `products.json`: add the `shahdozd` card (icon `/shahdozd-app/icon.png`,
   pages `/shahdozd-app/`, `/shahdozd-app/fa/`, web
   `https://shahdozd.espadna.com/?lang=..`), then `python3 tools/site_home.py`.
2. `public/sitemap.xml`: the four landing URLs.
3. `tools/mirror_pack.py` `FILE_SITES`: `'shahdozd': 'https://shahdozd.espadna.com'`
   and `'shahdozd-app': 'https://espadna.com/shahdozd-app'`. The game opens in
   Persian on `.ir` by itself, so it is **not** in `PERSIAN_GAMES`.
4. `README.md` / `mirror-ir/README.md` tables.
5. On the Iranian host (DirectAdmin): create the subdomain `shahdozd.espadna.ir`
   and its Let's Encrypt certificate. `sync.php` finds the new sites itself.

Steps 1–4 are done on the branch `claude/cool-johnson-mrzl83` of
hajiheidari/espadna-site. Merge it into `main` only after this repo's web
workflow has deployed the game and the landing pages, so the new card never
points to a page that does not exist yet.

## Android

Three flavors, one `applicationId` (`com.espadna.shahdozd`):

| Channel | Command | Output |
|---|---|---|
| Google Play | `flutter build appbundle --release --flavor play --dart-define=CHANNEL=play` | `build/app/outputs/bundle/playRelease/app-play-release.aab` |
| Cafe Bazaar | `flutter build apk --release --flavor bazaar --dart-define=CHANNEL=bazaar` | `build/app/outputs/flutter-apk/app-bazaar-release.apk` |
| Direct APK (universal) | `flutter build apk --release --flavor direct --dart-define=CHANNEL=apk` | `app-direct-release.apk` |
| Direct APKs per ABI | add `--split-per-abi` | `app-armeabi-v7a-direct-release.apk`, `app-arm64-v8a-…`, `app-x86_64-…` |

**Signing.** Create an upload key once (keep it and its passwords safe, outside
the repo):

```bash
keytool -genkey -v -keystore ~/shahdozd-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

and `android/key.properties` (git-ignored):

```
storeFile=/home/you/shahdozd-upload.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

Without it, release builds are signed with the debug key (testing only).
CI (`.github/workflows/android.yml`) builds all of the above on `main` and
signs them when the secrets `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` exist.

**Google Play.** Play App Signing (recommended), upload the AAB, content
rating questionnaire (no violence beyond a cartoon sword, no gambling, no
ads), data safety form: *no data collected or shared*. Target API: Flutter's
default `targetSdk` follows Play's current requirement; check it before each
release.

**Cafe Bazaar.** Upload the bazaar APK in the Pishkhan (developer panel), with
the Persian listing from STORE_LISTING.md. The same signing key must be used
for every update. No Bazaar SDK is linked yet (Premium is not active).

**Direct download.** Host the universal APK (and the per-ABI ones for small
downloads), e.g. `espadna.com/shahdozd-app/download/` like Pantomime. Users
must allow installs from unknown sources. Keep the same key forever, or
updates will fail to install over the old version.

## iPhone and iPad

On a Mac with Xcode (current stable) and an Apple Developer account:

```bash
flutter build ipa --release --dart-define=CHANNEL=appstore
open build/ios/archive/Runner.xcarchive   # or upload build/ios/ipa/*.ipa with Transporter
```

Bundle id `com.espadna.shahdozd` (set the team in Xcode › Runner › Signing).
Universal app: iPhone and iPad, all orientations on iPad. App Privacy:
*Data Not Collected*. `ITSAppUsesNonExemptEncryption` is false. Check the
current App Store minimum SDK requirement before submitting.

## Release checklist

- [ ] `flutter analyze` clean, `flutter test` green (CI)
- [ ] version bumped in `pubspec.yaml` (`x.y.z+build`)
- [ ] play one full tournament in each mode on a phone; Persian, English, Hindi
- [ ] reveal privacy: hold/release, app switcher during the deal, screenshots blocked on Android
- [ ] airplane mode: app starts and plays; web: reload offline after one visit
- [ ] tablet (iPad/Android) portrait and landscape; a small phone (320 px wide)
- [ ] web deployed by CI; landing pages and `files.json` reachable; espadna.ir copy updated
- [ ] store listings and screenshots updated (STORE_LISTING.md)
- [ ] privacy policy reachable at `espadna.com/shahdozd-app/privacy/`
- [ ] signed with the production upload key; key and passwords backed up
