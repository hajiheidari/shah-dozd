# Scoring

Implemented in `lib/engine/scoring.dart` (`ScoringConfig`) and applied by
`resolveRound` in `lib/engine/round.dart`. A tournament copies its scoring at
the start, so changing the setting never rewrites past rounds. Winning a round
(`guesserWins`) and earning bonus points are separate: bonuses never decide
who won.

## Presets

| Value | Traditional (default) | Simple party |
|---|---|---|
| King (always) | 1000 | 0 |
| Minister / Mantri role | 800 | 0 |
| Guard role (Executioner / Sipahi) | 500 | 0 |
| Duel value (what the guesser wins) | the guesser's role value (800, or 500 when the Sipahi guesses) | 1 |
| Escaped thief, one-thief modes | the duel value (the thief "takes" the guesser's points) | 1 |
| Escaped thief, Two Thieves | 50 % of the duel value each (400) | 100 % (1 each) |
| Caught thief | 0 | 0 |
| Joker (always) | 200 | 0 |
| Joker picked by the guesser | +600 | +1 |
| Perfect Catch (both thieves) | +400 to the guesser | +1 |

## Per player, every round

* **King:** `king`.
* **Guesser:** `duel` if at least one thief was picked, plus `perfectBonus`
  for a Perfect Catch; otherwise 0.
* **Thief / Second thief:** 0 if picked, otherwise the escape share.
* **Joker:** `jokerBase`, plus `jokerBonus` if picked.
* **Everyone else** (the guard, or the Mantri when the Sipahi guesses): their
  role value.

Points are never negative. Ties at the top of a tournament are shown as a
shared championship.

## Examples (traditional)

| Mode | Picks | King | Minister | Thief | Thief 2 | Guard | Joker |
|---|---|---|---|---|---|---|---|
| Persian | thief | 1000 | 800 | 0 | – | 500 | – |
| Persian | executioner | 1000 | 0 | 800 | – | 500 | – |
| Joker | joker | 1000 | 0 | 800 | – | 500 | 800 |
| Two Thieves | thief + guard | 1000 | 800 | 0 | 400 | 500 | 200 |
| Two Thieves | thief + thief 2 | 1000 | 1200 | 0 | 0 | 500 | 200 |
| Two Thieves | thief 2 + joker | 1000 | 800 | 400 | 0 | 500 | 800 |
| Two Thieves | guard + joker | 1000 | 0 | 400 | 400 | 500 | 800 |

Indian, Sipahi guesses: Chor picked → Raja 1000, Mantri 800, Sipahi 500,
Chor 0; Mantri picked → Raja 1000, Mantri 800, Sipahi 0, Chor 500.

## Tests

`test/engine/engine_test.dart` checks these formulas for every permutation of
roles and every legal set of picks, for all four modes, both Indian variants,
both guard characters and both presets, plus the explicit examples above.
