# Reply to App Review: Guidelines 4.3 and 4.2.6 (version 1.2.0)

Paste the English text below into App Store Connect → the app → App Review
(Resolution Center) → Reply. Do **not** resubmit; Apple asks for a reply
when the app is not spam. In answer 5, keep only the apps that are published
on this developer account.

---

Hello, and thank you for the review. I believe Shah Dozd Vazir is not a duplicate, not an opportunistic variant and not built from a template, so I am replying instead of resubmitting. My answers:

**1. What the app does and the problem it solves**

Shah-Dozd-Vazir ("King, Thief, Minister") is a traditional party game played in Iran, and in India as Raja Mantri Chor Sipahi. On paper it needs folded slips, someone who deals without peeking, and someone who keeps score; slips get seen, deals get disputed and the scores get lost. The app replaces all of that with one shared phone at the table. It deals the roles fairly with a secure random generator. Each player privately looks at their own role by pressing and holding the card, and the role disappears when they let go. The screen is covered if the app goes to the background mid-deal, so nobody can peek. The app then guides the Minister's guess, applies the scoring rules (traditional 1000/800/500 or simple party scoring), keeps a scoreboard across rounds, runs tournaments with a champion, and can resume an interrupted game. The people play with each other face to face; the app is the dealer, the referee and the scorekeeper.

**2. Intended users**

Families and groups of friends who meet in person: Persian-speaking families (including the diaspora), for whom this is a childhood game; Indian families who know it as Raja Mantri Chor Sipahi; and English-speaking groups looking for a short, simple hidden-role game for 4 to 6 people of mixed ages, from children to grandparents. It is meant for gatherings, holidays and trips, often without internet.

**3. The need it addresses**

- **Both traditions and four rule sets.** Persian Classic with the Executioner, Indian Classic with both local rules for who finds the Chor, a Joker Edition for 5 players (the Joker bluffs and earns a bonus if the Minister falls for it), and Two Thieves for 6 players (the Minister picks two people, and one thief is enough to win). The mode's rule is always on screen, which settles arguments at the table.
- **Pass-and-play on one device, made private.** The press-and-hold reveal and the background cover exist because peeking is the real problem when a phone is passed around.
- **Persian language.** The app is written in Persian first (right to left, Persian digits), with full English and Hindi.
- **Offline and respectful.** No account, no internet needed, no ads, no tracking and no purchases. A cosmetic shop (card backs, card styles, redrawn decks, extra penalty packs) uses only free in-game coins.
- **Original art.** Every character (King, Minister, Thief, Executioner, Sipahi, Joker) and every card style (Persian tile, khatam inlay, miniature) was drawn for this app.

**4. Beta testing and feedback applied**

I am a one-person studio, so I did the testing myself: I installed every TestFlight build (builds 2 to 5, October 2026) on my own devices and played full rounds in every mode and language. Problems I found and fixed before this build:

- The decorative Persian title font was hard to read, so I switched to a clear typeface.
- The four mode cards had different sizes in English and Hindi, so I made them uniform.
- The back arrow pointed the wrong way in Persian (right to left), so I mirrored it.
- The number of rounds could only be changed with + and −, so I added typing; in Persian the + and − now sit on the correct sides.
- The loser's penalties felt too mild, so I added "The Executioner's penalty", a set of playful challenges that can be turned off.
- The home screen scrolled on small phones; it now fits on one screen.
- The coin rewards were out of balance with the shop prices, so I rebalanced them. A first-launch message now explains the coins and the shop.
- On iPad the layout looked small, so the whole interface now scales up on tablets.

**5. Standalone or part of a suite**

It is a standalone game. My studio, Espadna, makes a few other apps. I built them separately, one at a time, each with its own code, rules and art. Once my developer account was ready, I submitted the ones that were finished within a short time, which is why several reached review together. I will space out future submissions. The other apps:

- Mafia God: a narrator tool for the Mafia game (6 or more players, night actions and voting)
- Dorehami Pantomime: charades
- Tiaro: a single-player daily logic puzzle
- Adadi: a single-player math crossword
- Ludo Dosti: the Ludo board game

Shah Dozd Vazir is the only one about this game: it has fixed roles for 4 to 6 players, a Minister's guess and point scoring. None of the others deal roles, guess a thief or keep this kind of score.

**6. Could it be an in-app purchase or an addition to another app?**

No. The closest app, Mafia God, is a moderator tool for a long, elimination-based game with a human narrator, night actions and voting. Shah-Dozd-Vazir is a different traditional game, with no narrator, everyone playing, short scored rounds and a winner decided by points. Putting it inside Mafia God would confuse both audiences. Players look for each game by its own name, in Persian and Hindi as well as English.

**7. Code, frameworks or assets shared with my other apps**

The app is its own Flutter codebase: its game engine, user interface, art, sounds and texts were all written for it. The only shared piece is a small native helper of about 100 lines that I reuse across my apps. It connects to Game Center (leaderboard and achievements) and to iCloud key-value storage (to back up coins and settings). My build and upload scripts are shared too, but they are not part of the app. The fonts are standard open-source fonts (Vazirmatn, Noto Sans Devanagari, Cormorant Garamond).

**8. Codebase, SDK or content shared with a third party**

No, beyond standard frameworks: Flutter, Apple's GameKit, and open-source packages for storage, audio and sharing. The Google Mobile Ads SDK is also linked, for an optional rewarded ad I may add later; it is not initialised and shows nothing in this version. No template, white-label product or app-generation service was used. The game is a public-domain folk game; the rules text, penalties, art and sounds are my own.

**9. Created for a client or third party?**

No. Espadna is my own studio, and this account belongs to it. The concept is a traditional game, and the content and branding are mine. Nothing was supplied by a client, partner or template provider.

Thank you for taking another look. I am happy to provide a short video of the app in use if that helps.

---
