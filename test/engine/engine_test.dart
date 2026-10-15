import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shah_dozd/engine/engine.dart';

List<String> ids(int n) => [for (var i = 0; i < n; i++) 'p$i'];

/// Every deal of [s] (all permutations of its roles over the seats).
Iterable<Map<String, Role>> allDeals(Scenario s) sync* {
  final seats = ids(s.playerCount);
  Iterable<List<Role>> perms(List<Role> xs) sync* {
    if (xs.isEmpty) {
      yield [];
      return;
    }
    for (var i = 0; i < xs.length; i++) {
      final rest = [...xs]..removeAt(i);
      for (final p in perms(rest)) {
        yield [xs[i], ...p];
      }
    }
  }

  for (final p in perms(s.roles)) {
    yield {for (var i = 0; i < seats.length; i++) seats[i]: p[i]};
  }
}

Iterable<List<String>> allPicks(List<String> candidates, int n) sync* {
  if (n == 1) {
    for (final c in candidates) {
      yield [c];
    }
  } else {
    for (var i = 0; i < candidates.length; i++) {
      for (var j = i + 1; j < candidates.length; j++) {
        yield [candidates[i], candidates[j]];
      }
    }
  }
}

final traditional = ScoringConfig.preset(ScoringPreset.traditional);
final party = ScoringConfig.preset(ScoringPreset.party);

void main() {
  group('scenarios', () {
    test('exact player counts and unique roles', () {
      expect(Scenario.of(ModeId.persian).roles, [Role.king, Role.minister, Role.thief, Role.executioner]);
      expect(Scenario.of(ModeId.indian).roles, [Role.king, Role.minister, Role.thief, Role.sipahi]);
      expect(Scenario.of(ModeId.joker).playerCount, 5);
      expect(Scenario.of(ModeId.twoThieves).playerCount, 6);
      for (final m in ModeId.values) {
        final s = Scenario.of(m);
        expect(s.roles.toSet().length, s.roles.length, reason: m.name);
        expect(s.roles, contains(Role.king));
        expect(s.roles, contains(s.guesser));
      }
    });

    test('mode-specific guessers, picks and guards', () {
      expect(Scenario.of(ModeId.indian, indianGuesser: IndianGuesser.sipahi).guesser, Role.sipahi);
      expect(Scenario.of(ModeId.indian).guesser, Role.minister);
      expect(Scenario.of(ModeId.twoThieves).picks, 2);
      expect(Scenario.of(ModeId.twoThieves).thiefCount, 2);
      expect(Scenario.of(ModeId.joker, guard: Role.sipahi).roles, contains(Role.sipahi));
      expect(Scenario.of(ModeId.persian).hiddenRoles, [Role.thief, Role.executioner]);
      expect(Scenario.of(ModeId.twoThieves).hiddenRoles.length, 4);
    });
  });

  group('deal', () {
    test('gives every role exactly once', () {
      for (final m in ModeId.values) {
        final s = Scenario.of(m);
        final d = dealRoles(ids(s.playerCount), s);
        expect(d.length, s.playerCount);
        expect(d.values.toList()..sort((a, b) => a.index - b.index), [...s.roles]..sort((a, b) => a.index - b.index));
      }
    });

    test('rejects wrong player counts and duplicate ids', () {
      final s = Scenario.of(ModeId.persian);
      expect(() => dealRoles(ids(5), s), throwsArgumentError);
      expect(() => dealRoles(['a', 'a', 'b', 'c'], s), throwsArgumentError);
    });

    test('is roughly uniform (every seat gets every role)', () {
      final s = Scenario.of(ModeId.twoThieves);
      final rng = Random(42);
      final counts = <String, int>{};
      const n = 60000;
      for (var i = 0; i < n; i++) {
        dealRoles(ids(6), s, random: rng).forEach((seat, role) {
          counts['$seat/${role.name}'] = (counts['$seat/${role.name}'] ?? 0) + 1;
        });
      }
      expect(counts.length, 36);
      for (final c in counts.values) {
        expect(c, inInclusiveRange(n / 6 * 0.93, n / 6 * 1.07));
      }
    });

    test('uses a secure generator by default (deals differ)', () {
      final s = Scenario.of(ModeId.twoThieves);
      final seen = {for (var i = 0; i < 30; i++) dealRoles(ids(6), s).values.map((r) => r.name).join()};
      expect(seen.length, greaterThan(10));
    });
  });

  group('round validation', () {
    final s = Scenario.of(ModeId.twoThieves);
    final deal = {'k': Role.king, 'm': Role.minister, 't': Role.thief, 't2': Role.thief2, 'g': Role.executioner, 'j': Role.joker};

    test('candidates exclude King and Minister', () {
      expect(candidatesOf(deal, s), unorderedEquals(['t', 't2', 'g', 'j']));
    });

    test('invalid picks throw', () {
      expect(() => resolveRound(scenario: s, deal: deal, picks: ['t'], scoring: traditional), throwsArgumentError);
      expect(() => resolveRound(scenario: s, deal: deal, picks: ['t', 't'], scoring: traditional), throwsArgumentError);
      expect(() => resolveRound(scenario: s, deal: deal, picks: ['t', 'k'], scoring: traditional), throwsArgumentError);
      expect(() => resolveRound(scenario: s, deal: deal, picks: ['m', 't'], scoring: traditional), throwsArgumentError);
      expect(() => resolveRound(scenario: s, deal: deal, picks: ['t', 'g', 'j'], scoring: traditional), throwsArgumentError);
    });
  });

  group('every deal × every guess', () {
    for (final mode in ModeId.values) {
      for (final variant in [IndianGuesser.minister, IndianGuesser.sipahi]) {
        if (mode != ModeId.indian && variant == IndianGuesser.sipahi) continue;
        for (final guard in [Role.executioner, Role.sipahi]) {
          if ((mode == ModeId.persian || mode == ModeId.indian) && guard == Role.sipahi) continue;
          for (final cfg in [traditional, party]) {
            test('${mode.name} / ${variant.name} / ${guard.name} / ${cfg.preset.name}', () {
              final s = Scenario.of(mode, indianGuesser: variant, guard: guard);
              var rounds = 0;
              for (final deal in allDeals(s)) {
                final cands = candidatesOf(deal, s);
                expect(cands.length, s.playerCount - 2);
                for (final picks in allPicks(cands, s.picks)) {
                  final o = resolveRound(scenario: s, deal: deal, picks: picks, scoring: cfg);
                  rounds++;
                  final caught = picks.where((p) => deal[p]!.isThief).length;
                  final guesser = holderOf(deal, s.guesser);

                  // Winning: one thief is enough, never both required.
                  expect(o.thievesCaught, caught);
                  expect(o.guesserWins, caught >= 1);
                  expect(o.perfectCatch, s.thiefCount == 2 && caught == 2);
                  expect(o.jokerFooledGuesser, picks.any((p) => deal[p] == Role.joker));

                  // Every player has points; nobody goes negative.
                  expect(o.points.keys.toSet(), deal.keys.toSet());
                  expect(o.points.values.every((v) => v >= 0), isTrue);

                  // Points follow the documented tables.
                  final duel = cfg.duelValue(s.guesser);
                  expect(o.points[holderOf(deal, Role.king)], cfg.king);
                  expect(o.points[guesser],
                      o.guesserWins ? duel + (o.perfectCatch ? cfg.perfectBonus : 0) : 0);
                  for (final id in deal.keys.where((id) => deal[id]!.isThief)) {
                    final share = s.thiefCount == 2 ? (duel * cfg.twoThiefEscapePercent / 100).round() : duel;
                    expect(o.points[id], picks.contains(id) ? 0 : share);
                  }
                  if (s.hasJoker) {
                    expect(o.points[holderOf(deal, Role.joker)],
                        cfg.jokerBase + (o.jokerFooledGuesser ? cfg.jokerBonus : 0));
                  }
                  for (final id in deal.keys) {
                    final r = deal[id]!;
                    if (r != Role.king && r != s.guesser && !r.isThief && r != Role.joker) {
                      expect(o.points[id], cfg.roleValue(r));
                    }
                  }
                }
              }
              expect(rounds, greaterThan(0));
            });
          }
        }
      }
    }
  });

  group('explicit outcomes', () {
    test('Persian: right guess → thief loses; wrong → minister loses, thief takes 800', () {
      final s = Scenario.of(ModeId.persian);
      final deal = {'a': Role.king, 'b': Role.minister, 'c': Role.thief, 'd': Role.executioner};
      final right = resolveRound(scenario: s, deal: deal, picks: ['c'], scoring: traditional);
      expect(right.guesserWins, isTrue);
      expect(right.points, {'a': 1000, 'b': 800, 'c': 0, 'd': 500});
      final wrong = resolveRound(scenario: s, deal: deal, picks: ['d'], scoring: traditional);
      expect(wrong.guesserWins, isFalse);
      expect(wrong.points, {'a': 1000, 'b': 0, 'c': 800, 'd': 500});
    });

    test('Indian, Sipahi guesses: Sipahi wins 500, Mantri keeps 800', () {
      final s = Scenario.of(ModeId.indian, indianGuesser: IndianGuesser.sipahi);
      final deal = {'a': Role.king, 'b': Role.minister, 'c': Role.thief, 'd': Role.sipahi};
      expect(candidatesOf(deal, s), unorderedEquals(['b', 'c']));
      expect(resolveRound(scenario: s, deal: deal, picks: ['c'], scoring: traditional).points,
          {'a': 1000, 'b': 800, 'c': 0, 'd': 500});
      expect(resolveRound(scenario: s, deal: deal, picks: ['b'], scoring: traditional).points,
          {'a': 1000, 'b': 800, 'c': 500, 'd': 0});
    });

    test('Joker mode: picking the Joker is a Joker victory and a Minister loss', () {
      final s = Scenario.of(ModeId.joker);
      final deal = {'a': Role.king, 'b': Role.minister, 'c': Role.thief, 'd': Role.executioner, 'e': Role.joker};
      final o = resolveRound(scenario: s, deal: deal, picks: ['e'], scoring: traditional);
      expect(o.guesserWins, isFalse);
      expect(o.jokerFooledGuesser, isTrue);
      expect(o.points, {'a': 1000, 'b': 0, 'c': 800, 'd': 500, 'e': 800});
      final guard = resolveRound(scenario: s, deal: deal, picks: ['d'], scoring: traditional);
      expect(guard.guesserWins, isFalse);
      expect(guard.jokerFooledGuesser, isFalse);
      expect(guard.points['e'], 200);
      final thief = resolveRound(scenario: s, deal: deal, picks: ['c'], scoring: traditional);
      expect(thief.guesserWins, isTrue);
      expect(thief.points['b'], 800);
    });

    group('Two Thieves', () {
      final s = Scenario.of(ModeId.twoThieves);
      final deal = {'k': Role.king, 'm': Role.minister, 't': Role.thief, 't2': Role.thief2, 'g': Role.executioner, 'j': Role.joker};
      RoundOutcome play(List<String> picks, [ScoringConfig? c]) =>
          resolveRound(scenario: s, deal: deal, picks: picks, scoring: c ?? traditional);

      test('one thief is enough for a Minister win', () {
        for (final picks in [['t', 'g'], ['t2', 'g'], ['g', 't'], ['j', 't2']]) {
          expect(play(picks).guesserWins, isTrue, reason: '$picks');
          expect(play(picks).perfectCatch, isFalse);
        }
      });

      test('both thieves → Perfect Catch bonus', () {
        final o = play(['t2', 't']);
        expect(o.guesserWins, isTrue);
        expect(o.perfectCatch, isTrue);
        expect(o.points['m'], 800 + 400);
        expect(o.points['t'], 0);
        expect(o.points['t2'], 0);
      });

      test('no thief → Minister loses, both thieves escape', () {
        final o = play(['g', 'j']);
        expect(o.guesserWins, isFalse);
        expect(o.points['m'], 0);
        expect(o.points['t'], 400);
        expect(o.points['t2'], 400);
      });

      test('Joker bonus never overrides a Minister win', () {
        final o = play(['j', 't']);
        expect(o.guesserWins, isTrue);
        expect(o.jokerFooledGuesser, isTrue);
        expect(o.points['m'], 800);
        expect(o.points['j'], 200 + 600);
        expect(o.points['t2'], 400);
        final p = play(['t2', 'j'], party);
        expect(p.guesserWins, isTrue);
        expect(p.points, {'k': 0, 'm': 1, 't': 1, 't2': 0, 'g': 0, 'j': 1});
      });
    });
  });

  group('tournament', () {
    Tournament make({int target = 0}) => Tournament(
          mode: ModeId.persian,
          players: [for (final id in ids(4)) Player(id: id, name: 'P $id')],
          scoring: traditional,
          targetRounds: target,
        );

    test('totals, standings, leaders, finish', () {
      final t = make(target: 2);
      expect(t.leaders, isEmpty);
      t.play({'p0': Role.king, 'p1': Role.minister, 'p2': Role.thief, 'p3': Role.executioner}, ['p2']);
      t.play({'p0': Role.thief, 'p1': Role.king, 'p2': Role.executioner, 'p3': Role.minister}, ['p2']);
      expect(t.totals, {'p0': 1000 + 800, 'p1': 800 + 1000, 'p2': 0 + 500, 'p3': 500 + 0});
      expect(t.leaders.map((p) => p.id), ['p0', 'p1']);
      expect(t.standings.map((p) => p.id), ['p0', 'p1', 'p2', 'p3']);
      expect(t.isFinished, isTrue);
      expect(t.restarted().rounds, isEmpty);
    });

    test('JSON round trip keeps everything', () {
      final t = Tournament(
        mode: ModeId.twoThieves,
        players: [for (final id in ids(6)) Player(id: id, name: 'نام $id', avatar: 3)],
        scoring: party,
        guard: Role.sipahi,
        targetRounds: 10,
      );
      final s = t.scenario;
      final deal = dealRoles(ids(6), s, random: Random(1));
      t.play(deal, candidatesOf(deal, s).take(2).toList());
      final back = Tournament.fromJson(t.toJson());
      expect(back.toJson(), t.toJson());
      expect(back.totals, t.totals);
      expect(back.scenario.guard, Role.sipahi);
    });

    test('rules are frozen per tournament', () {
      final t = make();
      expect(t.scoring, traditional);
      expect(ScoringConfig.fromJson(party.toJson()), party);
    });

    test('rejects a table of the wrong size', () {
      expect(
          () => Tournament(mode: ModeId.joker, players: [for (final id in ids(4)) Player(id: id, name: id)], scoring: party),
          throwsArgumentError);
    });
  });
}
