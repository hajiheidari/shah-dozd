/// Store-independent Premium entitlements.
///
/// The free game never depends on this: all four modes and unlimited rounds
/// are always available. Premium may later unlock cosmetic extras only
/// (card themes, extra art, sound packs, challenge collections).
///
/// Each distribution channel gets its own [BillingAdapter]. None is active
/// yet: an adapter is wired in only after its SDK, policy and merchant
/// account are verified (see docs/MONETIZATION.md). Until then every build
/// uses [NoBilling], so a missing store never blocks offline play.
library;

/// Things Premium can unlock. Never a competitive advantage.
enum PremiumFeature { cardThemes, extraArt, soundPacks, challengePacks, customChallenges, appearance }

/// The distribution channel of a build (set with --dart-define=CHANNEL=...).
enum Channel { googlePlay, cafeBazaar, appStore, directApk, web }

Channel get currentChannel => switch (const String.fromEnvironment('CHANNEL', defaultValue: 'web')) {
      'play' => Channel.googlePlay,
      'bazaar' => Channel.cafeBazaar,
      'appstore' => Channel.appStore,
      'apk' => Channel.directApk,
      _ => Channel.web,
    };

/// One store's purchase flow. Implementations must verify purchases with
/// the store (or a signed receipt) before reporting them owned, and must
/// support restoring purchases.
abstract interface class BillingAdapter {
  /// Whether the store can sell on this device right now.
  Future<bool> get available;

  /// Product ids the user owns, after verification.
  Future<Set<String>> owned();

  /// Starts the purchase of [productId]; true when it completed and verified.
  Future<bool> buy(String productId);

  /// Re-reads past purchases from the store (new phone, reinstall).
  Future<Set<String>> restore();
}

/// The default: no store, nothing to buy, nothing locked.
class NoBilling implements BillingAdapter {
  const NoBilling();
  @override
  Future<bool> get available async => false;
  @override
  Future<Set<String>> owned() async => const {};
  @override
  Future<bool> buy(String productId) async => false;
  @override
  Future<Set<String>> restore() async => const {};
}

/// The single product of the planned one-time unlock.
const premiumProductId = 'premium_unlock';

class Entitlements {
  Entitlements([this.adapter = const NoBilling()]);
  final BillingAdapter adapter;
  Set<String> _owned = const {};

  bool get isPremium => _owned.contains(premiumProductId);

  /// Gameplay is never gated; only cosmetic [PremiumFeature]s are.
  bool has(PremiumFeature f) => isPremium;

  Future<void> refresh() async {
    try {
      _owned = await adapter.owned();
    } catch (_) {
      // A store outage keeps what we had; the free game is unaffected.
    }
  }
}
