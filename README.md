# شاه، دزد، وزیر · Shah, Thief & Minister

The Persian party game *Shah, Dozd, Vazir* and its Indian cousin *Raja Mantri
Chor Sipahi*, for **one shared phone**: secret roles, four modes for 4–6
players, original illustrated cards, Persian/English/Hindi, fully offline, no
ads, no accounts. An [Espadna](https://espadna.com) game.

| Where | What |
|---|---|
| `https://shahdozd.espadna.com` | web version (installable PWA, offline after the first visit) |
| `https://espadna.com/shahdozd-app/` (`fa/`, `hi/`, `privacy/`) | landing pages |
| `https://shahdozd.espadna.ir`, `https://espadna.ir/shahdozd-app/` | Iranian copies (national internet), made by hajiheidari/espadna-site `mirror-ir/` |
| Android (Google Play AAB, Cafe Bazaar APK, direct APKs), iPhone/iPad | same Flutter code, see [docs/RELEASE.md](docs/RELEASE.md) |

## The four modes

| Mode | Players | Roles | Guess |
|---|---|---|---|
| Persian Classic | 4 | King, Minister, Thief, Executioner | Minister picks 1 of 2 |
| Indian Classic | 4 | Raja, Mantri, Chor, Sipahi | Mantri (or Sipahi, a setting) picks 1 of 2 |
| Joker Edition | 5 | King, Minister, Thief, Guard, Joker | Minister picks 1 of 3 |
| Two Thieves | 6 | King, Minister, Thief ×2, Guard, Joker | Minister picks 2 of 4 — **one thief is enough to win** |

Full rules: [docs/RULES.md](docs/RULES.md) · points: [docs/SCORING.md](docs/SCORING.md).
All modes are free with unlimited rounds.

## Develop

Needs Flutter (stable, 3.47+). Node 22 + Python 3 only for the web build.

```bash
flutter pub get
flutter test                 # engine (every deal × every guess) + widget tests
flutter run -d chrome        # or an Android/iOS device
node tools/web_build.mjs     # build/site (game), build/landing (pages), build/shahdozd-web.zip
```

Art and sounds are generated from sources in this repo (all original):

```bash
python3 tools/gen_art.py art/cards   # vector character cards (SVG)
node tools/render_art.mjs            # → assets/cards/*.webp, app icons, site/og.png (needs Playwright)
python3 tools/gen_sounds.py          # → assets/sounds/*.wav
```

## Layout

```
lib/engine/      rules: roles, scenarios, secure deal, round resolution, scoring, tournaments (pure Dart)
lib/l10n/        all texts (fa, en, hi), numerals, role names per mode
lib/app/         app state + local storage, sounds, Android secure-window channel
lib/premium/     store-independent entitlement interface (no store active)
lib/ui/          theme (design tokens), shared widgets, screens/
test/            engine/ (exhaustive rules tests), ui/ (flow + privacy tests)
art/             SVG sources of the cards and icon
assets/          rendered cards, sounds, fonts (OFL)
web/             index.html, manifest, sw.js (offline)
tools/           art/sound generators, web build, landing pages
deploy/          Cloudflare Worker configs (deployed only by CI)
docs/            architecture, rules, scoring, design, release, store texts, privacy, status
```

Docs: [ARCHITECTURE](docs/ARCHITECTURE.md) · [RULES](docs/RULES.md) ·
[SCORING](docs/SCORING.md) · [DESIGN](docs/DESIGN.md) · [RELEASE](docs/RELEASE.md) ·
[STORE_LISTING](docs/STORE_LISTING.md) · [PRIVACY](docs/PRIVACY.md) ·
[STATUS (limitations, open tasks)](docs/STATUS.md)

## خلاصه به فارسی

بازی دورهمی شاه دزد وزیر با یک گوشی: هر کس کارت را نگه می‌دارد تا نقش مخفی‌اش را
ببیند، شاه و وزیر معرفی می‌شوند و وزیر دزد را پیدا می‌کند. چهار حالت (کلاسیک ایرانی،
کلاسیک هندی، نسخه‌ی دلقک ۵ نفره، دو دزد ۶ نفره)، سه زبان، بدون اینترنت و بدون تبلیغ.
نسخه‌ی وب روی `shahdozd.espadna.com` و صفحه‌ی معرفی روی `espadna.com/shahdozd-app/`
منتشر می‌شود و نسخه‌ی `.ir` خودکار از روی آن‌ها کپی می‌شود. راهنمای انتشار برای
گوگل‌پلی، کافه‌بازار، APK مستقیم، App Store و وب در [docs/RELEASE.md](docs/RELEASE.md) است.
