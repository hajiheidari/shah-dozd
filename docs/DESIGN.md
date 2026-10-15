# Design system

Approved concept: the canvas "شاه دزد وزیر — طرح گرافیکی" (character sheet,
home, reveal, guess and result screens). Change: titles use **Vazirmatn
Black** instead of a calligraphic face, for legibility.

## Colour tokens (`lib/ui/theme.dart`, `C`)

| Token | Hex | Use |
|---|---|---|
| night | `#0C0F2A` | background |
| surface / surfaceHi | `#151942` / `#1E2356` | panels, cards, inputs |
| indigo, purple | `#2A2466`, `#4A2180` | card back, King |
| gold | `#D4AE55` | primary buttons, borders, chips |
| goldLight / goldText | `#F6E3A6` / `#E9CD86` | titles, highlights |
| ivory | `#F6EEDC` | body text |
| muted / faint | `#CFC6B4` / `#A9A090` | secondary text (≥ 4.5:1 on night) |
| ruby | `#B3243A` | jewel accents |
| joker | `#C2387F` | Joker moments |
| success | `#9FE0B8` | positive points |
| line / lineSoft | gold at 40 % / 20 % | 1 px borders |

Each role has its own card colour: King purple, Minister teal, Thief ruby,
Second Thief indigo, Executioner crimson, Sipahi saffron, Joker magenta.

## Typography

| Use | Persian | English | Hindi |
|---|---|---|---|
| Titles, role names | Vazirmatn Black 900 | Cormorant Garamond Bold | Noto Sans Devanagari Bold |
| UI, rules, buttons | Vazirmatn 400/700 | Vazirmatn (Latin) | Noto Sans Devanagari |

All fonts are bundled (SIL OFL), nothing is fetched at run time.
Sizes: title 30–46, section 15/800, body 13.5–16, captions 12; line height
1.6–1.8 for Persian and Hindi.

## Spacing and shape

4/8/12/16/24/32 scale; 16 px side gutters on phones; radius 14 (inputs,
chips), 16 (buttons, panels), 20 (mode cards); touch targets ≥ 48 px
(buttons 54 px high).

## Components

`GoldButton` (primary gold / secondary outlined, debounced), `IconBox`,
`CardArt` (card image with shadow/glow), `FlipSwitcher` (3D flip),
`RuleBanner`, `Avatar` (colour badge + initial or seat number),
`CrownMark`, `Confetti`, `TopBar`, dialogs via `confirm()`.

## Illustration guidelines

* Card 300×420 viewBox: dark frame, double gold border, Persian pointed arch
  window with the role colour, sunburst rays, bust portrait, soft fade at the
  bottom for the name.
* Flat vector shapes, 2–3 tones per surface, almond eyes with a white
  highlight, gold `#D4AE55` gradient for metal. No outlines thicker than 4.
* Adult, warm humour; nothing gory (the Executioner's sword is stylised).
* Sources: `art/cards/*.svg` from `tools/gen_art.py` (all original);
  rendered to 600×840 WebP by `tools/render_art.mjs`.

## Motion

* Shuffle 1.25 s (skipped with reduced motion), flips 170–420 ms,
  screen cross-fade 220 ms, result headline elastic pop 600 ms, Joker wobble
  1.1 s, confetti 2.6 s (more for Perfect Catch and the champion).
* Nothing blocks input except the shuffle; with "Reduce motion" (setting or
  the system preference) every duration is zero and confetti is not drawn.

## Sound

Original synthesized effects (`tools/gen_sounds.py`): tap, flip, shuffle,
reveal, win, lose, joker, perfect, champion. Sound and vibration have
separate switches. Background music is not included (see STATUS.md).
