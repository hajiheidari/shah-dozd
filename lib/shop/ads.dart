/// Rewarded ads: the only ads in the game. Shown only when the player taps
/// "Watch an ad for coins" in the shop; never during play, never forced.
///
/// Network per build (`--dart-define=CHANNEL=…`, see lib/premium/entitlements.dart):
///   play, appstore → Google AdMob
///   bazaar, apk    → Adivery (AdMob does not serve ads in Iran)
///   web            → none (the button is hidden)
library;

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'ads_stub.dart' if (dart.library.io) 'ads_io.dart' as impl;

abstract interface class RewardedAds {
  /// Whether this build has an ad network configured at all.
  bool get supported;

  /// Starts loading an ad in the background (call when the shop opens).
  Future<void> preload();

  /// Shows an ad; true only when the player watched it to the reward.
  Future<bool> show();
}

class NoAds implements RewardedAds {
  const NoAds();
  @override
  bool get supported => false;
  @override
  Future<void> preload() async {}
  @override
  Future<bool> show() async => false;
}

/// Ad unit ids, passed at build time. Until real ones are set, store
/// (release) builds have no ads at all (the shop hides the button); debug
/// builds use Google's public *test* units. Adivery is off until set.
abstract final class AdIds {
  static const _admobAndroid = String.fromEnvironment('ADMOB_REWARDED_ANDROID');
  static const _admobIos = String.fromEnvironment('ADMOB_REWARDED_IOS');
  static String get admobAndroid => _admobAndroid.isNotEmpty || kReleaseMode ? _admobAndroid : 'ca-app-pub-3940256099942544/5224354917';
  static String get admobIos => _admobIos.isNotEmpty || kReleaseMode ? _admobIos : 'ca-app-pub-3940256099942544/1712485313';
  static const adiveryApp = String.fromEnvironment('ADIVERY_APP_ID');
  static const adiveryRewarded = String.fromEnvironment('ADIVERY_REWARDED');
}

RewardedAds? _instance;

/// The rewarded-ad network of this build.
RewardedAds get rewardedAds => _instance ??= impl.createRewardedAds();

/// Tests replace the network.
set rewardedAdsForTest(RewardedAds ads) => _instance = ads;
