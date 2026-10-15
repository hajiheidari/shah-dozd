# Architecture

One Flutter/Dart code base for Android, iOS/iPadOS and the web. No backend:
everything runs and is stored on the device, so the game works in airplane
mode. Dependencies are kept to three maintained packages:
`shared_preferences` (local storage), `audioplayers` (sound effects) and
`flutter_localizations` (Material texts and RTL).

```
            ┌────────────── lib/ui (screens, widgets, theme) ──────────────┐
            │  Home → Setup → Round(shuffle → hand-over → reveal → announce │
            │         → guess → result) → Champion / Scoreboard / Settings │
            └───────▲─────────────────────▲─────────────────────▲──────────┘
                    │ texts               │ state               │ rules
            lib/l10n/strings.dart   lib/app/state.dart     lib/engine/*
            (fa, en, hi; digits;    (Settings, saved       (pure Dart, no Flutter:
             role names per mode)    players, Tournament;   Scenario, dealRoles,
                                     shared_preferences)    resolveRound, Scoring,
                                                            Tournament + JSON)
            lib/app/sfx.dart  lib/app/privacy.dart  lib/premium/entitlements.dart
```

## Layers

* **Engine** (`lib/engine/`): roles, scenario definitions (data), the secure
  deal, round validation and resolution, scoring presets, tournaments with
  JSON (versioned `v: 1`). No Flutter import, fully unit-tested.
* **Localization** (`lib/l10n/strings.dart`): one table, three columns
  (fa/en/hi). Role names depend on the mode (Shah vs Raja, बादशाह vs राजा).
  Persian uses Persian digits and a left-to-right mark before signed numbers.
* **State and persistence** (`lib/app/state.dart`): `AppState`
  (`ChangeNotifier`) exposed with an `InheritedNotifier`. Settings, saved
  players and the current tournament are JSON strings in
  `shared_preferences` (localStorage on the web). Corrupt or blocked storage
  falls back to defaults instead of crashing. A tournament is saved after
  every resolved round, so it survives restarts.
* **UI** (`lib/ui/`): design tokens in `theme.dart`, shared widgets in
  `widgets.dart`, one file per screen. Layouts are constrained to readable
  widths (560 px for flows, 1080 px for the home grid on tablets/desktop),
  `SafeArea` everywhere, `LayoutBuilder` for card sizes.
* **Audio** (`lib/app/sfx.dart`): short original sounds; failures are ignored.
* **Premium** (`lib/premium/`): a store-independent `BillingAdapter`
  interface and `NoBilling`. Gameplay is never gated.

## Hidden roles (privacy)

* The deal exists only in memory until the round is resolved; resuming an
  interrupted round re-deals it.
* A role is painted only while the card is pressed (`Listener`
  down/up/cancel). The hint text is shown only while holding.
* "Got it" is disabled until the role was seen and while it is held; buttons
  ignore a second tap within 450 ms (no accidental skip).
* No back navigation to a previous player (`PopScope`, exit asks first).
* When the app becomes inactive during the deal, a cover replaces the screen
  before the OS snapshot and the player must confirm their name again.
* Android: `FLAG_SECURE` during the deal (`MainActivity` + `privacy.dart`):
  no screenshots, blank app-switcher thumbnail.
* No role-specific sound or vibration during the deal (the same tap and
  light buzz for everyone); no notifications are used at all.
* The role list is never shown before the result; the scoreboard shows
  roles only of finished rounds.

## Web

`tools/web_build.mjs` runs `flutter build web --no-web-resources-cdn` (the
renderer and fallback font come from our own site, so the game loads on the
Iranian national internet), removes debug symbols, writes `sw.js` (offline:
core files precached, the rest cached on first use), Cloudflare `_headers`,
and `files.json` (sha256 of every file) for the espadna.ir mirror. On a
`.ir` host the game opens in Persian; `?lang=fa|en|hi` overrides.

## Adding a mode

Add a `ModeId`, its case in `Scenario.of`, texts in `strings.dart`
(`mode.*`, rules), a look in `home.dart`; the engine tests pick it up
automatically.
