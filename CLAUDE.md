# Working on Shah, Dozd, Vazir

- Rules live only in `lib/engine/` (pure Dart). Change a rule there, update
  docs/RULES.md or docs/SCORING.md, and keep `test/engine/` exhaustive.
- Two-thief mode: one caught thief is a Minister win; the Joker bonus never
  changes the winner. Tests must keep proving both.
- Every visible text is a key in `lib/l10n/strings.dart` with fa, en and hi.
  Persian is the original; never leave a column empty.
- Never show a role outside the press-and-hold card before the result, never
  add role-specific sound/vibration to the deal, keep the background cover.
- No accounts and no network calls during play. Ads: only rewarded, only when
  the player taps "Watch an ad" in the shop (docs/MONETIZATION.md); never
  banners or interstitials. The shop sells looks and penalty packs, never an
  advantage. The web build must keep `--no-web-resources-cdn`.
- Art and sounds are generated (`tools/gen_art.py`, `tools/render_art.mjs`,
  `tools/gen_sounds.py`); edit the sources, then re-render.
- Before committing: `flutter analyze` and `flutter test`.
- Deploys happen only from `main` via GitHub Actions; never run
  `wrangler deploy` by hand. espadna.com's card and the espadna.ir mirror
  entries live in hajiheidari/espadna-site (see docs/RELEASE.md).
