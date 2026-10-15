import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shah_dozd/app/state.dart';
import 'package:shah_dozd/app/stats.dart';
import 'package:shah_dozd/engine/engine.dart';
import 'package:shah_dozd/shop/catalog.dart';
import 'package:shah_dozd/shop/recovery.dart';
import 'package:shah_dozd/shop/wallet.dart';

void main() {
  const data = RecoveryData(
    coins: 123456,
    owned: {'back.classic', 'back.sun', 'theme.gold', 'theme.khatam', 'deck.classic', 'deck.qajar', 'pack.fiery'},
    back: 'back.sun',
    theme: 'theme.khatam',
    deck: 'deck.qajar',
    rounds: 4321,
  );

  test('recovery code round trip', () {
    final code = RecoveryCode.encode(data);
    expect(code, matches(RegExp(r'^[0-9A-Z]{1,4}(-[0-9A-Z]{1,4})*$')));
    final d = RecoveryCode.decode(code)!;
    expect(d.coins, data.coins);
    expect(d.owned, data.owned);
    expect((d.back, d.theme, d.deck, d.rounds), (data.back, data.theme, data.deck, data.rounds));
    // Lower case, spaces and look-alike letters are accepted.
    expect(RecoveryCode.decode(code.toLowerCase().replaceAll('-', ' '))!.coins, data.coins);
  });

  test('every shop item fits in the code', () {
    for (final i in shopItems) {
      expect(i.code, lessThan(32), reason: i.id);
    }
    expect({for (final i in shopItems) i.code}.length, shopItems.length, reason: 'codes are unique');
  });

  test('a changed or mistyped code is refused', () {
    final code = RecoveryCode.encode(data);
    for (var i = 0; i < code.length; i++) {
      if (code[i] == '-') continue;
      final swapped = code[i] == '7' ? '8' : '7';
      final bad = code.replaceRange(i, i + 1, swapped);
      expect(RecoveryCode.decode(bad), isNull, reason: 'position $i');
    }
    expect(RecoveryCode.decode(''), isNull);
    expect(RecoveryCode.decode('hello world'), isNull);
  });

  test('restoring a code merges: more coins win, items are added', () {
    final app = AppState.memory(wallet: Wallet(coins: 50, welcomed: true));
    expect(app.restoreCode('nope'), isFalse);
    expect(app.restoreCode(RecoveryCode.encode(data)), isTrue);
    expect(app.wallet.coins, 123456);
    expect(app.wallet.owns('deck.qajar'), isTrue);
    expect(app.wallet.deck, 'deck.qajar');
    expect(app.stats.rounds, 4321);
    // A poorer code never takes coins away.
    final poor = RecoveryCode.encode(const RecoveryData(coins: 1, owned: {}, back: 'back.classic', theme: 'theme.gold', deck: 'deck.classic', rounds: 0));
    expect(app.restoreCode(poor), isTrue);
    expect(app.wallet.coins, 123456);
    expect(app.wallet.owns('deck.qajar'), isTrue);
  });

  test('snapshot restore keeps the larger counters', () {
    final a = AppState.memory(wallet: Wallet(coins: 900, welcomed: true));
    a.wallet.buy('back.emerald');
    final snap = jsonDecode(jsonEncode(a.snapshot())) as Map<String, Object?>;
    final b = AppState.memory(wallet: Wallet(coins: 10));
    b.restoreSnapshot(snap);
    expect(b.wallet.coins, 300);
    expect(b.wallet.owns('back.emerald'), isTrue);
    expect(b.wallet.welcomed, isTrue);
  });

  test('achievements match ios/gamecenter/gamecenter.json', () {
    final json = jsonDecode(File('ios/gamecenter/gamecenter.json').readAsStringSync()) as Map;
    final ids = {for (final a in json['achievements'] as List) 'shahdozd.${(a as Map)['key']}'};
    expect(ids, Stats.allAchievements.toSet());
    expect(jsonEncode(json).contains(Stats.leaderboard), isTrue);

    final st = Stats();
    final w = Wallet(welcomed: true);
    expect(st.achievements(w), isEmpty);
    final all = Stats(rounds: 200, tournaments: 1, modes: {for (final m in ModeId.values) m.name}, perfectCatches: 1, jokerTricks: 1);
    final rich = Wallet(coins: 100000)..buy('deck.qajar');
    expect(all.achievements(rich), Stats.allAchievements.toSet());
    expect(Stats.fromJson(jsonDecode(jsonEncode(all.toJson())) as Map<String, Object?>).achievements(rich), Stats.allAchievements.toSet());
  });
}
