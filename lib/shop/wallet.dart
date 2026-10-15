import 'catalog.dart';

/// Coins earned, bought items, equipped looks. Pure Dart; stored by AppState.
///
/// Coins are earned (never bought): by sharing the game with friends and by
/// choosing to watch a rewarded ad. Both are capped per day. Without an
/// account and a server, coins live on this device only.
class Wallet {
  Wallet({
    this.coins = welcomeGift,
    Set<String>? owned,
    this.back = 'back.classic',
    this.theme = 'theme.gold',
    this.day = '',
    this.sharesToday = 0,
    this.adsToday = 0,
  }) : owned = owned ?? {for (final i in shopItems) if (i.free) i.id};

  static const welcomeGift = 100;
  static const shareReward = 50;
  static const sharesPerDay = 3;
  static const adReward = 25;
  static const adsPerDay = 10;

  int coins;
  final Set<String> owned;
  String back;
  String theme;

  /// yyyy-mm-dd of the day the counters below belong to.
  String day;
  int sharesToday;
  int adsToday;

  static String today([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  void _roll(DateTime? now) {
    final t = today(now);
    if (t != day) {
      day = t;
      sharesToday = 0;
      adsToday = 0;
    }
  }

  bool canShare([DateTime? now]) {
    _roll(now);
    return sharesToday < sharesPerDay;
  }

  bool canWatchAd([DateTime? now]) {
    _roll(now);
    return adsToday < adsPerDay;
  }

  /// After a completed share. Returns the coins added (0 when capped).
  int rewardShare([DateTime? now]) {
    if (!canShare(now)) return 0;
    sharesToday++;
    coins += shareReward;
    return shareReward;
  }

  /// After a rewarded ad was watched to the end.
  int rewardAd([DateTime? now]) {
    if (!canWatchAd(now)) return 0;
    adsToday++;
    coins += adReward;
    return adReward;
  }

  bool owns(String id) => owned.contains(id);

  /// Buys [id]; false when already owned or not enough coins.
  bool buy(String id) {
    final item = itemById(id);
    if (owns(id) || coins < item.price) return false;
    coins -= item.price;
    owned.add(id);
    return true;
  }

  /// Equips an owned back or theme; false otherwise.
  bool equip(String id) {
    if (!owns(id)) return false;
    switch (itemById(id).kind) {
      case ItemKind.back:
        back = id;
      case ItemKind.theme:
        theme = id;
      case ItemKind.pack:
        return false;
    }
    return true;
  }

  bool isEquipped(String id) => id == back || id == theme;

  Map<String, Object?> toJson() => {
        'v': 1,
        'coins': coins,
        'owned': owned.toList()..sort(),
        'back': back,
        'theme': theme,
        'day': day,
        'sharesToday': sharesToday,
        'adsToday': adsToday,
      };

  factory Wallet.fromJson(Map<String, Object?> j) {
    final known = {for (final i in shopItems) i.id};
    final w = Wallet(
      coins: ((j['coins'] as num?)?.toInt() ?? welcomeGift).clamp(0, 1 << 30),
      owned: {
        for (final i in shopItems) if (i.free) i.id,
        for (final id in (j['owned'] as List? ?? const []).cast<String>()) if (known.contains(id)) id,
      },
      day: j['day'] as String? ?? '',
      sharesToday: (j['sharesToday'] as num?)?.toInt() ?? 0,
      adsToday: (j['adsToday'] as num?)?.toInt() ?? 0,
    );
    final back = j['back'] as String?;
    final theme = j['theme'] as String?;
    if (back != null && w.owns(back)) w.back = back;
    if (theme != null && w.owns(theme)) w.theme = theme;
    return w;
  }
}
