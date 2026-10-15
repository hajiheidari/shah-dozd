import 'role.dart';

/// The four game modes on the home screen.
enum ModeId {
  /// Shah, Vazir, Dozd, Jallad — 4 players.
  persian,

  /// Raja, Mantri, Chor, Sipahi — 4 players.
  indian,

  /// King, Minister, Thief, Guard, Joker — 5 players.
  joker,

  /// King, Minister, two Thieves, Guard, Joker — 6 players.
  twoThieves,
}

/// Who identifies the thief in the Indian mode (a local-rule setting).
enum IndianGuesser { minister, sipahi }

/// A fully resolved scenario: which roles are dealt, who is revealed in
/// public before the guess, who guesses and how many players they pick.
///
/// Scenarios are data, built by [Scenario.of]; the UI and the scoring engine
/// read them and never hard-code a mode's rules.
class Scenario {
  const Scenario._({
    required this.mode,
    required this.roles,
    required this.guesser,
    required this.picks,
  });

  final ModeId mode;

  /// One role per player, in a fixed order (the deal shuffles them).
  final List<Role> roles;

  /// The role that makes the guess.
  final Role guesser;

  /// How many players the guesser selects at once (2 only in [ModeId.twoThieves]).
  final int picks;

  int get playerCount => roles.length;

  /// Roles shown to everybody before the guess: the King and the guesser.
  List<Role> get publicRoles => [Role.king, guesser];

  /// Roles the guesser chooses among.
  List<Role> get hiddenRoles => roles.where((r) => !publicRoles.contains(r)).toList();

  int get thiefCount => roles.where((r) => r.isThief).length;

  bool get hasJoker => roles.contains(Role.joker);

  /// The guard character that is dealt (executioner or sipahi), if any.
  Role? get guard {
    for (final r in roles) {
      if (r.isGuard) return r;
    }
    return null;
  }

  /// Builds the scenario of [mode].
  ///
  /// [indianGuesser] picks the Indian local rule; [guard] is the character
  /// used as the guard in the Joker and Two Thieves modes (executioner or
  /// sipahi). The Persian mode always uses the executioner, the Indian mode
  /// always uses the sipahi.
  factory Scenario.of(
    ModeId mode, {
    IndianGuesser indianGuesser = IndianGuesser.minister,
    Role guard = Role.executioner,
  }) {
    assert(guard.isGuard);
    switch (mode) {
      case ModeId.persian:
        return const Scenario._(
          mode: ModeId.persian,
          roles: [Role.king, Role.minister, Role.thief, Role.executioner],
          guesser: Role.minister,
          picks: 1,
        );
      case ModeId.indian:
        return Scenario._(
          mode: ModeId.indian,
          roles: const [Role.king, Role.minister, Role.thief, Role.sipahi],
          guesser: indianGuesser == IndianGuesser.sipahi ? Role.sipahi : Role.minister,
          picks: 1,
        );
      case ModeId.joker:
        return Scenario._(
          mode: ModeId.joker,
          roles: [Role.king, Role.minister, Role.thief, guard, Role.joker],
          guesser: Role.minister,
          picks: 1,
        );
      case ModeId.twoThieves:
        return Scenario._(
          mode: ModeId.twoThieves,
          roles: [Role.king, Role.minister, Role.thief, Role.thief2, guard, Role.joker],
          guesser: Role.minister,
          picks: 2,
        );
    }
  }

  static int playersFor(ModeId mode) => Scenario.of(mode).playerCount;
}
