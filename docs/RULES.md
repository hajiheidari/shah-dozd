# Game rules specification

The rules live in `lib/engine/` as data (`Scenario.of`) and one resolver
(`resolveRound`); the UI never hard-codes a mode's rule. Every statement
below is checked by `test/engine/engine_test.dart`, which plays **every deal
× every legal guess** of every mode, variant and scoring preset.

## Common flow (all modes)

1. **Deal.** Roles are shuffled with an unbiased Fisher–Yates shuffle driven by
   `Random.secure()` and dealt one per player, in seat order.
2. **Private reveal.** The phone goes round. For each player: a neutral
   hand-over screen with their name → "I am <name>" → the card is shown only
   while it is pressed and held → "Got it" (enabled only after the role was
   seen, and not while it is held). There is no way back to a previous player.
3. **Public reveal.** The King and the guesser are shown to everybody.
4. **Guess.** The guesser selects, at once, exactly `picks` players among the
   others (the *candidates*: everyone but the King and the guesser).
5. **Result.** All picked cards flip, the outcome and the points are shown,
   the tournament is saved.

There is no voting, no night phase, no elimination and no extra ability.

## Scenarios

| Mode | `roles` | `guesser` | `picks` | candidates |
|---|---|---|---|---|
| `persian` | king, minister, thief, executioner | minister | 1 | thief, executioner |
| `indian` | king (Raja), minister (Mantri), thief (Chor), sipahi | minister **or** sipahi (setting) | 1 | the two others |
| `joker` | king, minister, thief, *guard*, joker | minister | 1 | thief, guard, joker |
| `twoThieves` | king, minister, thief, thief2, *guard*, joker | minister | 2 | thief, thief2, guard, joker |

*guard* = executioner (default) or sipahi, a setting ("Guard in the 5- and
6-player modes"). The 5- and 6-player modes are original adaptations, not
traditional rules.

## Outcome

Let `caught` = number of picked players who are thieves.

* **Guesser wins** ⇔ `caught ≥ 1`. In Two Thieves, identifying **one** of the
  two thieves is enough; both are never required.
* **Perfect Catch** ⇔ the mode has two thieves and `caught = 2` (a bonus only).
* **Joker victory** ⇔ the Joker is among the picks. It is a bonus for the
  Joker and **never changes who won**: in Two Thieves, picking the Joker and a
  thief is a Minister win *and* a Joker bonus.

Per mode, in words:

* **Persian / Indian.** Right guess → the thief loses the round. Wrong guess →
  the guesser loses and the thief takes the guesser's points.
* **Joker (5).** Real thief picked → Minister wins. Joker picked → Minister
  loses, Joker gets the special victory. Guard picked → Minister loses.
* **Two Thieves (6).** At least one thief among the two picks → Minister wins;
  both → Perfect Catch; neither → Minister loses; Joker picked → Joker bonus
  on top, whatever the result.

## Indian local rules

Two documented variants, chosen in Settings (default: Mantri):

* *Mantri finds the Chor* — the Mantri guesses between Chor and Sipahi.
* *Sipahi finds the Chor* — the Raja and the Sipahi reveal themselves and the
  Sipahi guesses between Mantri and Chor.

## Executioner's challenge (optional)

When the guard is the Executioner and the setting is on, the result screen
offers "Executioner's challenge": a random, harmless, family-friendly task for
the round's loser (the guesser if they lost, otherwise the caught thief). It
has no effect on points. Texts: `_challenges` in `lib/l10n/strings.dart`.

## Rules on screen

The guess screen always shows the current mode's one-paragraph rule at the
top (`RuleBanner`), with an expandable "Full rules" list; the setup screen
shows the same banner. Nothing on either reveals a hidden role.
