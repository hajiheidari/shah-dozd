import '../engine/engine.dart';
import '../shop/catalog.dart';
import '../shop/wallet.dart';

/// Lifetime play statistics on this device, the source of the Game Center
/// leaderboard and achievements (ios/gamecenter/gamecenter.json).
class Stats {
  Stats({this.rounds = 0, this.tournaments = 0, Set<String>? modes, this.perfectCatches = 0, this.jokerTricks = 0})
      : modes = modes ?? {};

  static const leaderboard = 'shahdozd.rounds';

  int rounds;
  int tournaments;
  final Set<String> modes;
  int perfectCatches;
  int jokerTricks;

  void recordRound(ModeId mode, RoundOutcome o) {
    rounds++;
    modes.add(mode.name);
    if (o.perfectCatch) perfectCatches++;
    if (o.jokerFooledGuesser) jokerTricks++;
  }

  void recordTournament() => tournaments++;

  /// Achievement ids earned so far (key → Game Center id).
  Set<String> achievements(Wallet wallet) => {
        if (rounds >= 1) 'shahdozd.first_round',
        if (rounds >= 50) 'shahdozd.rounds_50',
        if (rounds >= 200) 'shahdozd.rounds_200',
        if (tournaments >= 1) 'shahdozd.champion',
        if (modes.length >= ModeId.values.length) 'shahdozd.all_modes',
        if (perfectCatches >= 1) 'shahdozd.perfect_catch',
        if (jokerTricks >= 1) 'shahdozd.joker_trick',
        if (shopItems.any((i) => !i.free && wallet.owns(i.id))) 'shahdozd.collector',
        if (shopItems.any((i) => i.kind == ItemKind.deck && !i.free && wallet.owns(i.id))) 'shahdozd.deck_owner',
      };

  static const allAchievements = [
    'shahdozd.first_round',
    'shahdozd.rounds_50',
    'shahdozd.rounds_200',
    'shahdozd.champion',
    'shahdozd.all_modes',
    'shahdozd.perfect_catch',
    'shahdozd.joker_trick',
    'shahdozd.collector',
    'shahdozd.deck_owner',
  ];

  Map<String, Object?> toJson() => {
        'rounds': rounds,
        'tournaments': tournaments,
        'modes': modes.toList()..sort(),
        'perfectCatches': perfectCatches,
        'jokerTricks': jokerTricks,
      };

  factory Stats.fromJson(Map<String, Object?> j) => Stats(
        rounds: (j['rounds'] as num?)?.toInt() ?? 0,
        tournaments: (j['tournaments'] as num?)?.toInt() ?? 0,
        modes: {...(j['modes'] as List? ?? const []).cast<String>()},
        perfectCatches: (j['perfectCatches'] as num?)?.toInt() ?? 0,
        jokerTricks: (j['jokerTricks'] as num?)?.toInt() ?? 0,
      );

  /// Keeps the larger of each counter (used when restoring a backup).
  void mergeMax(Stats o) {
    if (o.rounds > rounds) rounds = o.rounds;
    if (o.tournaments > tournaments) tournaments = o.tournaments;
    modes.addAll(o.modes);
    if (o.perfectCatches > perfectCatches) perfectCatches = o.perfectCatches;
    if (o.jokerTricks > jokerTricks) jokerTricks = o.jokerTricks;
  }
}
