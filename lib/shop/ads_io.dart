import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../premium/entitlements.dart';
import 'ads.dart';

RewardedAds createRewardedAds() {
  switch (currentChannel) {
    case Channel.googlePlay:
    case Channel.appStore:
      final unit = Platform.isIOS ? AdIds.admobIos : AdIds.admobAndroid;
      return unit.isEmpty ? const NoAds() : _AdMob(unit);
    case Channel.cafeBazaar:
    case Channel.directApk:
      if (AdIds.adiveryApp.isEmpty || AdIds.adiveryRewarded.isEmpty || !Platform.isAndroid) return const NoAds();
      return _Adivery(AdIds.adiveryApp, AdIds.adiveryRewarded);
    case Channel.web:
      return const NoAds();
  }
}

class _AdMob implements RewardedAds {
  _AdMob(this.unit);
  final String unit;
  bool _started = false;
  RewardedAd? _ad;
  Completer<void>? _loading;

  @override
  bool get supported => true;

  @override
  Future<void> preload() async {
    try {
      if (!_started) {
        _started = true;
        await MobileAds.instance.initialize();
      }
      if (_ad != null) return;
      if (_loading != null) return await _loading!.future;
      final c = _loading = Completer<void>();
      await RewardedAd.load(
        adUnitId: unit,
        // Non-personalized: no tracking, no consent prompt needed.
        request: const AdRequest(nonPersonalizedAds: true),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            _loading = null;
            c.complete();
          },
          onAdFailedToLoad: (_) {
            _loading = null;
            c.complete();
          },
        ),
      );
      return await c.future;
    } catch (_) {
      _loading = null;
    }
  }

  @override
  Future<bool> show() async {
    if (_ad == null) await preload().timeout(const Duration(seconds: 15), onTimeout: () {});
    final ad = _ad;
    if (ad == null) return false;
    _ad = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!done.isCompleted) done.complete(earned);
        preload();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        if (!done.isCompleted) done.complete(false);
        preload();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }
}

/// Adivery through the native SDK (android/app/src/{bazaar,direct}/…/AdsBridge.kt).
class _Adivery implements RewardedAds {
  _Adivery(this.appId, this.placement);
  final String appId;
  final String placement;
  static const _ch = MethodChannel('shahdozd/adivery');

  @override
  bool get supported => true;

  @override
  Future<void> preload() async {
    try {
      await _ch.invokeMethod<bool>('init', {'appId': appId, 'placement': placement});
    } catch (_) {}
  }

  @override
  Future<bool> show() async {
    try {
      await preload();
      for (var i = 0; i < 15; i++) {
        if (await _ch.invokeMethod<bool>('isLoaded', {'placement': placement}) == true) {
          return await _ch.invokeMethod<bool>('show', {'placement': placement}) ?? false;
        }
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    } catch (_) {}
    return false;
  }
}
