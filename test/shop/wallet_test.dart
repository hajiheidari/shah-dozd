import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shah_dozd/l10n/penalties.dart';
import 'package:shah_dozd/shop/catalog.dart';
import 'package:shah_dozd/shop/wallet.dart';

void main() {
  final day1 = DateTime(2026, 10, 15, 9);
  final day1late = DateTime(2026, 10, 15, 23);
  final day2 = DateTime(2026, 10, 16, 8);

  test('new wallet: welcome gift, free items owned and equipped', () {
    final w = Wallet();
    expect(w.coins, Wallet.welcomeGift);
    for (final i in shopItems.where((i) => i.free)) {
      expect(w.owns(i.id), isTrue, reason: i.id);
    }
    expect(w.back, 'back.classic');
    expect(w.theme, 'theme.gold');
  });

  test('share and ad rewards are capped per day and reset the next day', () {
    final w = Wallet(coins: 0);
    for (var i = 0; i < Wallet.sharesPerDay; i++) {
      expect(w.rewardShare(day1), Wallet.shareReward);
    }
    expect(w.rewardShare(day1late), 0);
    for (var i = 0; i < Wallet.adsPerDay; i++) {
      expect(w.rewardAd(day1), Wallet.adReward);
    }
    expect(w.rewardAd(day1late), 0);
    expect(w.coins, Wallet.sharesPerDay * Wallet.shareReward + Wallet.adsPerDay * Wallet.adReward);
    expect(w.rewardShare(day2), Wallet.shareReward);
    expect(w.rewardAd(day2), Wallet.adReward);
  });

  test('buying needs enough coins, happens once, and equips only backs and themes', () {
    final w = Wallet(coins: 610);
    expect(w.buy('back.paisley'), isFalse, reason: 'costs 900');
    expect(w.buy('back.emerald'), isTrue);
    expect(w.coins, 10);
    expect(w.buy('back.emerald'), isFalse, reason: 'already owned');
    expect(w.equip('back.emerald'), isTrue);
    expect(w.back, 'back.emerald');
    expect(w.equip('theme.jade'), isFalse, reason: 'not owned');
    w.coins = 10000;
    expect(w.buy('pack.fiery'), isTrue);
    expect(w.equip('pack.fiery'), isFalse);
    expect(w.buy('deck.qajar'), isTrue);
    expect(w.equip('deck.qajar'), isTrue);
    expect(w.isEquipped('deck.qajar'), isTrue);
  });

  test('JSON round trip; unknown or unowned ids are ignored', () {
    final w = Wallet(coins: 5000)..buy('theme.silver');
    w.equip('theme.silver');
    final back = Wallet.fromJson(w.toJson());
    expect(back.toJson(), w.toJson());
    final odd = Wallet.fromJson({'coins': -5, 'owned': ['nope', 'back.ruby'], 'back': 'back.sun', 'theme': 'theme.silver'});
    expect(odd.coins, 0);
    expect(odd.owns('back.ruby'), isTrue);
    expect(odd.owns('nope'), isFalse);
    expect(odd.back, 'back.classic', reason: 'sun is not owned');
    expect(odd.theme, 'theme.gold');
  });

  test('every penalty and shop item has Persian, English and Hindi text', () {
    for (final p in penalties) {
      expect(p.text, hasLength(3));
      expect(p.text.every((t) => t.trim().isNotEmpty), isTrue);
    }
    for (final i in shopItems) {
      expect(i.name.every((t) => t.trim().isNotEmpty), isTrue, reason: i.id);
    }
    for (final pack in PenaltyPack.values) {
      expect(penalties.where((p) => p.pack == pack), isNotEmpty, reason: pack.name);
    }
    expect(penalties.where((p) => p.pack == PenaltyPack.base && p.byExecutioner), isNotEmpty);
    expect(penalties.where((p) => p.pack == PenaltyPack.base && !p.byExecutioner), isNotEmpty);
  });

  test('assets exist for every back and theme', () {
    expect(backAsset('back.classic'), 'assets/cards/back.webp');
    expect(backAsset('back.ruby'), 'assets/cards/backs/ruby.webp');
    expect(faceAsset('theme.gold', 'king'), 'assets/cards/king.webp');
    expect(faceAsset('theme.khatam', 'king'), 'assets/cards/khatam/king.webp');
    expect(faceAsset('theme.khatam', 'king', deckId: 'deck.qajar'), 'assets/cards/decks/qajar/king.webp');
    const roles = ['king', 'minister', 'thief', 'thief2', 'executioner', 'sipahi', 'joker'];
    for (final i in shopItems) {
      if (i.kind == ItemKind.back) expect(File(backAsset(i.id)).existsSync(), isTrue, reason: i.id);
      for (final r in roles) {
        if (i.kind == ItemKind.theme) expect(File(faceAsset(i.id, r)).existsSync(), isTrue, reason: '${i.id} $r');
        if (i.kind == ItemKind.deck) expect(File(faceAsset('theme.gold', r, deckId: i.id)).existsSync(), isTrue, reason: '${i.id} $r');
      }
    }
  });
}

