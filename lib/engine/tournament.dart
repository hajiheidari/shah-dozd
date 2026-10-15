import 'role.dart';
import 'round.dart';
import 'scenario.dart';
import 'scoring.dart';

/// A player at the table. [avatar] indexes the avatar palette of the UI.
class Player {
  const Player({required this.id, required this.name, this.avatar = 0});

  final String id;
  final String name;
  final int avatar;

  Player copyWith({String? name, int? avatar}) => Player(id: id, name: name ?? this.name, avatar: avatar ?? this.avatar);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'avatar': avatar};

  factory Player.fromJson(Map<String, Object?> j) =>
      Player(id: j['id'] as String, name: j['name'] as String, avatar: (j['avatar'] as num?)?.toInt() ?? 0);
}

/// One finished round, as stored in the tournament history.
class RoundRecord {
  const RoundRecord({
    required this.deal,
    required this.picks,
    required this.points,
    required this.guesserWins,
    required this.perfectCatch,
    required this.jokerFooledGuesser,
  });

  factory RoundRecord.from(Map<String, Role> deal, RoundOutcome o) => RoundRecord(
        deal: Map.unmodifiable(deal),
        picks: o.picks,
        points: o.points,
        guesserWins: o.guesserWins,
        perfectCatch: o.perfectCatch,
        jokerFooledGuesser: o.jokerFooledGuesser,
      );

  final Map<String, Role> deal;
  final List<String> picks;
  final Map<String, int> points;
  final bool guesserWins;
  final bool perfectCatch;
  final bool jokerFooledGuesser;

  Map<String, Object?> toJson() => {
        'deal': deal.map((k, v) => MapEntry(k, v.name)),
        'picks': picks,
        'points': points,
        'guesserWins': guesserWins,
        'perfectCatch': perfectCatch,
        'jokerFooledGuesser': jokerFooledGuesser,
      };

  factory RoundRecord.fromJson(Map<String, Object?> j) => RoundRecord(
        deal: (j['deal'] as Map).map((k, v) => MapEntry(k as String, Role.values.byName(v as String))),
        picks: (j['picks'] as List).cast<String>(),
        points: (j['points'] as Map).map((k, v) => MapEntry(k as String, (v as num).toInt())),
        guesserWins: j['guesserWins'] as bool,
        perfectCatch: j['perfectCatch'] as bool? ?? false,
        jokerFooledGuesser: j['jokerFooledGuesser'] as bool? ?? false,
      );
}

/// A local tournament: fixed table, rules frozen at the start, round history.
///
/// Rules (scenario options and scoring) are copied in when the tournament
/// starts, so changing the settings mid-way never rewrites past scores.
class Tournament {
  Tournament({
    required this.mode,
    required this.players,
    required this.scoring,
    this.indianGuesser = IndianGuesser.minister,
    this.guard = Role.executioner,
    this.targetRounds = 0,
    List<RoundRecord>? rounds,
  }) : rounds = rounds ?? [] {
    if (players.length != scenario.playerCount) {
      throw ArgumentError('${mode.name} needs ${scenario.playerCount} players');
    }
  }

  final ModeId mode;
  final List<Player> players;
  final ScoringConfig scoring;
  final IndianGuesser indianGuesser;
  final Role guard;

  /// 0 = unlimited.
  final int targetRounds;
  final List<RoundRecord> rounds;

  Scenario get scenario => Scenario.of(mode, indianGuesser: indianGuesser, guard: guard);

  int get roundNumber => rounds.length + 1;

  bool get isFinished => targetRounds > 0 && rounds.length >= targetRounds;

  Player player(String id) => players.firstWhere((p) => p.id == id);

  Map<String, int> get totals {
    final t = {for (final p in players) p.id: 0};
    for (final r in rounds) {
      r.points.forEach((id, pts) => t[id] = (t[id] ?? 0) + pts);
    }
    return t;
  }

  /// Players sorted by total, highest first (stable: seat order breaks ties).
  List<Player> get standings {
    final t = totals;
    final order = [...players];
    order.sort((a, b) {
      final c = t[b.id]!.compareTo(t[a.id]!);
      return c != 0 ? c : players.indexOf(a).compareTo(players.indexOf(b));
    });
    return order;
  }

  /// Everybody sharing the highest total (empty before the first round).
  List<Player> get leaders {
    if (rounds.isEmpty) return const [];
    final t = totals;
    final best = t.values.reduce((a, b) => a > b ? a : b);
    return players.where((p) => t[p.id] == best).toList();
  }

  RoundOutcome play(Map<String, Role> deal, List<String> picks) {
    final o = resolveRound(scenario: scenario, deal: deal, picks: picks, scoring: scoring);
    rounds.add(RoundRecord.from(deal, o));
    return o;
  }

  /// Same table and rules, scores cleared.
  Tournament restarted() => Tournament(
        mode: mode,
        players: players,
        scoring: scoring,
        indianGuesser: indianGuesser,
        guard: guard,
        targetRounds: targetRounds,
      );

  Map<String, Object?> toJson() => {
        'v': 1,
        'mode': mode.name,
        'players': [for (final p in players) p.toJson()],
        'scoring': scoring.toJson(),
        'indianGuesser': indianGuesser.name,
        'guard': guard.name,
        'targetRounds': targetRounds,
        'rounds': [for (final r in rounds) r.toJson()],
      };

  factory Tournament.fromJson(Map<String, Object?> j) => Tournament(
        mode: ModeId.values.byName(j['mode'] as String),
        players: [for (final p in j['players'] as List) Player.fromJson((p as Map).cast())],
        scoring: ScoringConfig.fromJson((j['scoring'] as Map).cast()),
        indianGuesser: IndianGuesser.values.byName(j['indianGuesser'] as String? ?? 'minister'),
        guard: Role.values.byName(j['guard'] as String? ?? 'executioner'),
        targetRounds: (j['targetRounds'] as num?)?.toInt() ?? 0,
        rounds: [for (final r in j['rounds'] as List? ?? const []) RoundRecord.fromJson((r as Map).cast())],
      );
}
