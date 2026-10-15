import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shah_dozd/app/app.dart';
import 'package:shah_dozd/app/state.dart';
import 'package:shah_dozd/engine/engine.dart';
import 'package:shah_dozd/l10n/strings.dart';

const allRoleNames = ['King', 'Minister', 'Thief', 'Executioner', 'Sipahi', 'Joker', 'Second Thief', 'First Thief'];

Future<void> settle(WidgetTester t, [int ms = 400]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void expectNoRoleVisible() {
  for (final r in allRoleNames) {
    expect(find.text(r), findsNothing, reason: '"$r" must not be on screen');
  }
}

Future<AppState> startGame(WidgetTester tester, ModeId mode, String modeTitle) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final state = AppState.memory(settings: const Settings(lang: Lang.en, sound: false, haptics: false, reduceMotion: true));
  await tester.pumpWidget(ShahDozdApp(state: state));
  await settle(tester);
  await tester.tap(find.text(modeTitle));
  await settle(tester);
  await tester.tap(find.text('Start game'));
  await settle(tester, 600);
  return state;
}

/// Deals to every player, checking privacy on the way.
Future<void> dealAll(WidgetTester tester, AppState state) async {
  final t = state.tournament!;
  for (var i = 0; i < t.players.length; i++) {
    final name = t.players[i].name;
    expect(find.text('Hand the phone to $name'), findsOneWidget);
    expectNoRoleVisible();
    await tester.tap(find.text('I am $name'));
    await settle(tester);

    // Hidden until pressed; "done" is disabled before the role was seen.
    expectNoRoleVisible();
    await tester.tap(find.text('Hold the card first'));
    await settle(tester);
    expect(find.text('Hold the card first'), findsOneWidget);

    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('roleCard'))));
    await settle(tester);
    expect(allRoleNames.where((r) => find.text(r).evaluate().isNotEmpty), hasLength(1));
    await g.up();
    await settle(tester);
    expectNoRoleVisible();

    await tester.tap(find.textContaining('Got it'));
    await settle(tester);
  }
}

void main() {
  testWidgets('Persian Classic: private deal, guess, scores saved', (tester) async {
    final state = await startGame(tester, ModeId.persian, 'Persian Classic');
    expect(state.tournament!.players, hasLength(4));
    await dealAll(tester, state);

    expect(find.text('Reveal yourselves!'), findsOneWidget);
    await tester.tap(find.text('Ready'));
    await settle(tester);
    expect(find.textContaining('where is the Thief?'), findsOneWidget);
    // The rule summary is pinned at the top.
    expect(find.textContaining('picks one player as the Thief'), findsOneWidget);

    final picks = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('pick-'));
    expect(picks, findsNWidgets(2));
    await tester.tap(picks.first);
    await settle(tester);
    await tester.tap(find.text('Reveal!'));
    await settle(tester, 1200);

    expect(find.textContaining(RegExp(r'The Minister (wins|loses)!')), findsOneWidget);
    expect(state.tournament!.rounds, hasLength(1));
    final totals = state.tournament!.totals.values.toList();
    expect(totals.reduce((a, b) => a + b), 1000 + 800 + 500); // traditional points always sum to 2300
    expect(Tournament.fromJson(state.tournament!.toJson()).rounds, hasLength(1));
  });

  testWidgets('backgrounding during the deal covers the screen and asks for the name again', (tester) async {
    final state = await startGame(tester, ModeId.joker, 'Joker Edition');
    final first = state.tournament!.players.first.name;
    await tester.tap(find.text('I am $first'));
    await settle(tester);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('roleCard'))));
    await settle(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await settle(tester);
    expect(find.text('Game hidden'), findsOneWidget);
    expectNoRoleVisible();
    await g.up();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.tap(find.text('Game hidden'));
    await settle(tester);
    expect(find.text('Hand the phone to $first'), findsOneWidget);
  });

  testWidgets('Two Thieves needs exactly two picks', (tester) async {
    final state = await startGame(tester, ModeId.twoThieves, 'Two Thieves');
    await dealAll(tester, state);
    await tester.tap(find.text('Ready'));
    await settle(tester);
    expect(find.textContaining('If even one of them is a thief'), findsOneWidget);
    final picks = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('pick-'));
    expect(picks, findsNWidgets(4));
    await tester.tap(picks.at(0));
    await settle(tester);
    await tester.tap(find.text('Reveal!'));
    await settle(tester);
    expect(state.tournament!.rounds, isEmpty, reason: 'one pick is not enough');
    expect(find.text('1 of 2 picked'), findsOneWidget);
    await tester.ensureVisible(picks.at(2));
    await settle(tester);
    await tester.tap(picks.at(2));
    await settle(tester);
    expect(find.text('2 of 2 picked'), findsOneWidget);
    await tester.tap(find.text('Reveal!'));
    await settle(tester, 1200);
    expect(state.tournament!.rounds, hasLength(1));
    final r = state.tournament!.rounds.single;
    expect(r.picks, hasLength(2));
    expect(r.guesserWins, r.picks.any((id) => r.deal[id]!.isThief));
  });
}
