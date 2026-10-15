import 'dart:math';

import 'role.dart';
import 'scenario.dart';
import 'scoring.dart';

/// Deals [scenario]'s roles to [playerIds] (same length) with an unbiased
/// Fisher–Yates shuffle. Defaults to [Random.secure] so the deal cannot be
/// predicted; tests pass a seeded generator.
Map<String, Role> dealRoles(List<String> playerIds, Scenario scenario, {Random? random}) {
  if (playerIds.length != scenario.playerCount) {
    throw ArgumentError('${scenario.mode.name} needs ${scenario.playerCount} players, got ${playerIds.length}');
  }
  if (playerIds.toSet().length != playerIds.length) {
    throw ArgumentError('player ids must be unique');
  }
  final rng = random ?? Random.secure();
  final roles = List<Role>.of(scenario.roles);
  for (var i = roles.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final t = roles[i];
    roles[i] = roles[j];
    roles[j] = t;
  }
  return {for (var i = 0; i < playerIds.length; i++) playerIds[i]: roles[i]};
}

/// Who holds [role] in [deal] (each role is dealt at most once).
String holderOf(Map<String, Role> deal, Role role) => deal.entries.firstWhere((e) => e.value == role).key;

/// Players the guesser may pick: everyone except the King and the guesser.
List<String> candidatesOf(Map<String, Role> deal, Scenario scenario) =>
    [for (final e in deal.entries) if (!scenario.publicRoles.contains(e.value)) e.key];

/// The outcome of one round.
class RoundOutcome {
  const RoundOutcome({
    required this.picks,
    required this.thievesCaught,
    required this.guesserWins,
    required this.perfectCatch,
    required this.jokerFooledGuesser,
    required this.points,
  });

  final List<String> picks;

  /// How many of the picked players are thieves (0, 1 or 2).
  final int thievesCaught;

  /// The guesser wins when at least one picked player is a thief. In the
  /// two-thief mode one thief is enough: this is a product rule.
  final bool guesserWins;

  /// Both thieves picked in the two-thief mode.
  final bool perfectCatch;

  /// The Joker was among the picks (a special Joker victory). It never
  /// changes [guesserWins].
  final bool jokerFooledGuesser;

  /// Points every player earns this round (every player has an entry).
  final Map<String, int> points;
}

/// Resolves the guess [picks] for [deal] under [scenario] and [scoring].
///
/// Throws [ArgumentError] for an invalid guess: wrong number of picks,
/// duplicates, or picking the King or the guesser.
RoundOutcome resolveRound({
  required Scenario scenario,
  required Map<String, Role> deal,
  required List<String> picks,
  required ScoringConfig scoring,
}) {
  final candidates = candidatesOf(deal, scenario);
  if (picks.length != scenario.picks) {
    throw ArgumentError('expected ${scenario.picks} picks, got ${picks.length}');
  }
  if (picks.toSet().length != picks.length) throw ArgumentError('duplicate pick');
  for (final p in picks) {
    if (!candidates.contains(p)) throw ArgumentError('$p cannot be picked');
  }

  final caught = picks.where((p) => deal[p]!.isThief).length;
  final guesserWins = caught >= 1;
  final perfect = scenario.thiefCount == 2 && caught == 2;
  final jokerPicked = picks.any((p) => deal[p] == Role.joker);

  final duel = scoring.duelValue(scenario.guesser);
  final escapeShare = scenario.thiefCount == 2 ? (duel * scoring.twoThiefEscapePercent / 100).round() : duel;

  final points = <String, int>{};
  for (final MapEntry(key: id, value: role) in deal.entries) {
    int pts;
    if (role == scenario.guesser) {
      pts = guesserWins ? duel + (perfect ? scoring.perfectBonus : 0) : 0;
    } else if (role.isThief) {
      pts = picks.contains(id) ? 0 : escapeShare;
    } else if (role == Role.joker) {
      pts = scoring.jokerBase + (jokerPicked ? scoring.jokerBonus : 0);
    } else {
      pts = scoring.roleValue(role);
    }
    points[id] = pts;
  }

  return RoundOutcome(
    picks: List.unmodifiable(picks),
    thievesCaught: caught,
    guesserWins: guesserWins,
    perfectCatch: perfect,
    jokerFooledGuesser: jokerPicked,
    points: Map.unmodifiable(points),
  );
}
