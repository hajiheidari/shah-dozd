/// What coins can buy. Cosmetic only (and extra penalty packs): nothing in
/// the shop changes who wins a round. All prices in game coins, which are
/// earned, never bought. See docs/MONETIZATION.md for the economy.
library;

import '../l10n/penalties.dart';

enum ItemKind {
  /// Card back.
  back,

  /// Frame style of the faces: colours, background and ornament around the
  /// characters (khatam, miniature, tile…).
  theme,

  /// A whole new deck: every character redrawn in another style. Overrides
  /// the frame theme while equipped.
  deck,

  /// Extra penalties for the Executioner.
  pack,
}

class ShopItem {
  const ShopItem(this.code, this.id, this.kind, this.price, this.name, {this.pack});

  /// Stable small number used by the recovery code. Never reuse or change.
  final int code;
  final String id;
  final ItemKind kind;
  final int price;
  final List<String> name; // fa, en, hi
  final PenaltyPack? pack;

  bool get free => price == 0;
}

const shopItems = <ShopItem>[
  // Card backs (art/cards/backs/*.svg)
  ShopItem(0, 'back.classic', ItemKind.back, 0, ['کلاسیک شاهانه', 'Royal Classic', 'शाही क्लासिक']),
  ShopItem(1, 'back.emerald', ItemKind.back, 600, ['زمرد', 'Emerald', 'पन्ना']),
  ShopItem(2, 'back.ruby', ItemKind.back, 600, ['یاقوت', 'Ruby', 'माणिक']),
  ShopItem(3, 'back.paisley', ItemKind.back, 900, ['بته‌جقه', 'Paisley', 'पैस्ले']),
  ShopItem(4, 'back.starry', ItemKind.back, 900, ['شب پرستاره', 'Starry Night', 'तारों भरी रात']),
  ShopItem(5, 'back.sun', ItemKind.back, 1200, ['خورشید طلایی', 'Golden Sun', 'सुनहरा सूरज']),
  // Frame styles (art/cards/<theme>/*.svg)
  ShopItem(6, 'theme.gold', ItemKind.theme, 0, ['طلایی شاهانه', 'Royal gold', 'शाही सुनहरा']),
  ShopItem(7, 'theme.silver', ItemKind.theme, 1200, ['نقره‌کوب', 'Silverwork', 'चाँदी का काम']),
  ShopItem(10, 'theme.tile', ItemKind.theme, 1500, ['کاشی فیروزه‌ای', 'Turquoise tile', 'फ़िरोज़ी टाइल']),
  ShopItem(11, 'theme.khatam', ItemKind.theme, 1800, ['خاتم‌کاری', 'Khatam inlay', 'ख़ातम जड़ाई']),
  ShopItem(12, 'theme.miniature', ItemKind.theme, 2000, ['مینیاتور و تذهیب', 'Miniature', 'मिनिएचर']),
  // Whole decks (art/cards/decks/<deck>/*.svg)
  ShopItem(13, 'deck.classic', ItemKind.deck, 0, ['دست اصلی', 'Original deck', 'मूल गड्डी']),
  ShopItem(14, 'deck.qajar', ItemKind.deck, 4000, ['عکس قاجاری', 'Qajar photographs', 'क़ाजार तस्वीरें']),
  ShopItem(15, 'deck.shadow', ItemKind.deck, 5000, ['خیمه‌شب‌بازی', 'Shadow puppets', 'छाया कठपुतली']),
  ShopItem(16, 'deck.engraving', ItemKind.deck, 6000, ['طلاکوب', 'Gold engraving', 'सुनहरी नक़्क़ाशी']),
  // Penalty packs
  ShopItem(17, 'pack.party', ItemKind.pack, 1000, ['جریمه‌های مهمانی', 'Party penalties', 'पार्टी की सज़ाएँ'], pack: PenaltyPack.party),
  ShopItem(18, 'pack.fiery', ItemKind.pack, 1500, ['جریمه‌های آتشین جلاد', 'The Executioner’s fiery penalties', 'जल्लाद की तीखी सज़ाएँ'],
      pack: PenaltyPack.fiery),
];

ShopItem itemById(String id) => shopItems.firstWhere((i) => i.id == id);

ShopItem? itemByCode(int code) {
  for (final i in shopItems) {
    if (i.code == code) return i;
  }
  return null;
}

String _last(String id) => id.split('.').last;

/// The asset of a card back.
String backAsset(String backId) => _last(backId) == 'classic' ? 'assets/cards/back.webp' : 'assets/cards/backs/${_last(backId)}.webp';

/// The asset of a face: a non-classic deck wins over the frame theme.
String faceAsset(String themeId, String role, {String deckId = 'deck.classic'}) {
  if (_last(deckId) != 'classic') return 'assets/cards/decks/${_last(deckId)}/$role.webp';
  final name = _last(themeId);
  return name == 'gold' ? 'assets/cards/$role.webp' : 'assets/cards/$name/$role.webp';
}
