import 'role.dart';

/// Named scoring presets. See docs/SCORING.md for the full tables.
enum ScoringPreset {
  /// The traditional Raja-Mantri-Chor-Sipahi points (1000/800/500/0),
  /// used for every mode.
  traditional,

  /// Simple party scoring: one point for winning the round's duel, one for
  /// each special achievement. Nobody scores just for their role.
  party,
}

/// Point values used by [resolveRound]. Immutable; build one with
/// [ScoringConfig.preset] or [copyWith].
class ScoringConfig {
  const ScoringConfig({
    required this.preset,
    required this.king,
    required this.minister,
    required this.guard,
    required this.jokerBase,
    required this.jokerBonus,
    required this.perfectBonus,
    required this.duelOverride,
    required this.twoThiefEscapePercent,
  });

  factory ScoringConfig.preset(ScoringPreset p) => switch (p) {
        ScoringPreset.traditional => const ScoringConfig(
            preset: ScoringPreset.traditional,
            king: 1000,
            minister: 800,
            guard: 500,
            jokerBase: 200,
            jokerBonus: 600,
            perfectBonus: 400,
            duelOverride: null,
            twoThiefEscapePercent: 50,
          ),
        ScoringPreset.party => const ScoringConfig(
            preset: ScoringPreset.party,
            king: 0,
            minister: 0,
            guard: 0,
            jokerBase: 0,
            jokerBonus: 1,
            perfectBonus: 1,
            duelOverride: 1,
            twoThiefEscapePercent: 100,
          ),
      };

  final ScoringPreset preset;

  /// Points the King always receives.
  final int king;

  /// Points of the Minister/Mantri role (won when guessing right, or always
  /// when the Sipahi is the guesser).
  final int minister;

  /// Points of the Executioner/Sipahi role (won when guessing right in the
  /// Sipahi variant, otherwise always).
  final int guard;

  /// Points the Joker always receives.
  final int jokerBase;

  /// Extra points for the Joker when the guesser picks them.
  final int jokerBonus;

  /// Extra points for the guesser when both thieves are caught (6 players).
  final int perfectBonus;

  /// When set, the value of the duel (guesser vs thief) regardless of the
  /// guesser's role points. Used by the party preset.
  final int? duelOverride;

  /// Share of the duel value each escaped thief receives in the two-thief
  /// mode (the traditional preset splits it, the party preset does not).
  final int twoThiefEscapePercent;

  /// Fixed points of a role that is neither guesser nor thief nor joker.
  int roleValue(Role r) => switch (r) {
        Role.king => king,
        Role.minister => minister,
        Role.executioner || Role.sipahi => guard,
        _ => 0,
      };

  /// What the guesser wins (and an escaped single thief takes instead).
  int duelValue(Role guesser) => duelOverride ?? roleValue(guesser);

  Map<String, Object?> toJson() => {
        'preset': preset.name,
        'king': king,
        'minister': minister,
        'guard': guard,
        'jokerBase': jokerBase,
        'jokerBonus': jokerBonus,
        'perfectBonus': perfectBonus,
        'duelOverride': duelOverride,
        'twoThiefEscapePercent': twoThiefEscapePercent,
      };

  factory ScoringConfig.fromJson(Map<String, Object?> j) {
    final base = ScoringConfig.preset(
        ScoringPreset.values.asNameMap()[j['preset']] ?? ScoringPreset.traditional);
    int v(String k, int d) => (j[k] as num?)?.toInt() ?? d;
    return ScoringConfig(
      preset: base.preset,
      king: v('king', base.king),
      minister: v('minister', base.minister),
      guard: v('guard', base.guard),
      jokerBase: v('jokerBase', base.jokerBase),
      jokerBonus: v('jokerBonus', base.jokerBonus),
      perfectBonus: v('perfectBonus', base.perfectBonus),
      duelOverride: j.containsKey('duelOverride') ? (j['duelOverride'] as num?)?.toInt() : base.duelOverride,
      twoThiefEscapePercent: v('twoThiefEscapePercent', base.twoThiefEscapePercent),
    );
  }

  @override
  bool operator ==(Object other) => other is ScoringConfig && _eq(toJson(), other.toJson());

  @override
  int get hashCode => Object.hashAll(toJson().values);

  static bool _eq(Map a, Map b) => a.length == b.length && a.keys.every((k) => a[k] == b[k]);
}
