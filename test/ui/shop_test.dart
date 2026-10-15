import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shah_dozd/app/app.dart';
import 'package:shah_dozd/app/state.dart';
import 'package:shah_dozd/l10n/strings.dart';
import 'package:shah_dozd/shop/wallet.dart';

Future<void> settle(WidgetTester t, [int ms = 400]) async {
  for (var i = 0; i < ms ~/ 50; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('buy and equip a card back from the home coin pill', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final state = AppState.memory(
      settings: const Settings(lang: Lang.en, sound: false, haptics: false, reduceMotion: true),
      wallet: Wallet(coins: 400),
    );
    await tester.pumpWidget(ShahDozdApp(state: state));
    await settle(tester);
    await tester.tap(find.text('400'));
    await settle(tester);
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('Watch an ad'), findsNothing, reason: 'no ad network in tests/web');
    await tester.tap(find.text('Emerald'));
    await settle(tester);
    await tester.tap(find.text('Yes'));
    await settle(tester);
    expect(state.wallet.coins, 250);
    expect(state.wallet.back, 'back.emerald');
    expect(find.text('In use'), findsWidgets);
  });

  testWidgets('back arrow points right in Persian (mirrored)', (tester) async {
    final state = AppState.memory(settings: const Settings(lang: Lang.fa, sound: false, haptics: false, reduceMotion: true));
    await tester.pumpWidget(ShahDozdApp(state: state));
    await settle(tester);
    await tester.tap(find.byTooltip(S(Lang.fa).t('home.settings')));
    await settle(tester);
    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_back_rounded));
    expect(icon.icon!.matchTextDirection, isTrue);
    expect(Directionality.of(tester.element(find.byIcon(Icons.arrow_back_rounded))), TextDirection.rtl);
  });
}
