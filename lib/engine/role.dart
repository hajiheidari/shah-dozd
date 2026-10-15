/// The characters of the game. Names are display-independent; see
/// `lib/l10n/` for what each one is called in Persian, English and Hindi.
enum Role {
  /// Shah (Persian) / Raja (Indian). Always revealed first.
  king,

  /// Vazir / Mantri. The usual guesser.
  minister,

  /// Dozd / Chor.
  thief,

  /// The second thief of the six-player mode.
  thief2,

  /// Jallad. The guard of the Persian game.
  executioner,

  /// The guard of the Indian game; also the guesser in one Indian variant.
  sipahi,

  /// Wins a special bonus when the guesser picks them by mistake.
  joker;

  bool get isThief => this == thief || this == thief2;

  bool get isGuard => this == executioner || this == sipahi;

  /// File name (without extension) of the card art in `assets/cards/`.
  String get art => name;
}
