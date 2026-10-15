/// What coins can buy. Cosmetic only (and extra penalty packs): nothing in
/// the shop changes who wins a round. All prices in game coins.
library;

import '../l10n/penalties.dart';

enum ItemKind { back, theme, pack }

class ShopItem {
  const ShopItem(this.id, this.kind, this.price, this.name, {this.pack});
  final String id;
  final ItemKind kind;
  final int price;
  final List<String> name; // fa, en, hi
  final PenaltyPack? pack;

  bool get free => price == 0;
}

const shopItems = <ShopItem>[
  // Card backs (art/backs/*.svg → assets/cards/backs/*.webp)
  ShopItem('back.classic', ItemKind.back, 0, ['کلاسیک شاهانه', 'Royal Classic', 'शाही क्लासिक']),
  ShopItem('back.emerald', ItemKind.back, 150, ['زمرد', 'Emerald', 'पन्ना']),
  ShopItem('back.ruby', ItemKind.back, 150, ['یاقوت', 'Ruby', 'माणिक']),
  ShopItem('back.paisley', ItemKind.back, 250, ['بته‌جقه', 'Paisley', 'पैस्ले']),
  ShopItem('back.starry', ItemKind.back, 250, ['شب پرستاره', 'Starry Night', 'तारों भरी रात']),
  ShopItem('back.sun', ItemKind.back, 300, ['خورشید طلایی', 'Golden Sun', 'सुनहरा सूरज']),
  // Card face themes (frame metal and border colour)
  ShopItem('theme.gold', ItemKind.theme, 0, ['قاب طلایی', 'Gold frame', 'सुनहरा फ़्रेम']),
  ShopItem('theme.silver', ItemKind.theme, 200, ['قاب نقره‌ای', 'Silver frame', 'चाँदी का फ़्रेम']),
  ShopItem('theme.rose', ItemKind.theme, 250, ['قاب رزگلد', 'Rose-gold frame', 'रोज़-गोल्ड फ़्रेम']),
  ShopItem('theme.jade', ItemKind.theme, 300, ['قاب یشم', 'Jade frame', 'जेड फ़्रेम']),
  // Penalty packs
  ShopItem('pack.fiery', ItemKind.pack, 300, ['جریمه‌های آتشین جلاد', 'The Executioner’s fiery penalties', 'जल्लाद की तीखी सज़ाएँ'],
      pack: PenaltyPack.fiery),
  ShopItem('pack.party', ItemKind.pack, 200, ['جریمه‌های مهمانی', 'Party penalties', 'पार्टी की सज़ाएँ'], pack: PenaltyPack.party),
];

ShopItem itemById(String id) => shopItems.firstWhere((i) => i.id == id);

/// The asset of a card back or face, for the equipped items.
String backAsset(String backId) {
  final name = backId.split('.').last;
  return name == 'classic' ? 'assets/cards/back.webp' : 'assets/cards/backs/$name.webp';
}

String faceAsset(String themeId, String role) {
  final name = themeId.split('.').last;
  return name == 'gold' ? 'assets/cards/$role.webp' : 'assets/cards/$name/$role.webp';
}
