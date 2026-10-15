import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// iOS-only native features (ios/Runner/AppDelegate.swift, channel
/// "shahdozd/native"): Game Center and iCloud key-value storage. Every call
/// is a no-op elsewhere and never throws: none of this may block the game.
class Native {
  Native._();
  static const _ch = MethodChannel('shahdozd/native');

  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool gameCenterSignedIn = false;

  static Future<T?> _call<T>(String method, [Object? args]) async {
    if (!isIOS) return null;
    try {
      return await _ch.invokeMethod<T>(method, args).timeout(const Duration(seconds: 20));
    } catch (_) {
      return null;
    }
  }

  /// Signs in to Game Center (Apple shows its own sheet the first time).
  static Future<void> gameCenterSignIn() async {
    final r = await _call<Map>('gcAuthenticate');
    gameCenterSignedIn = r?['authenticated'] == true;
  }

  /// Submits the leaderboard score and every earned achievement (Game
  /// Center ignores repeats).
  static Future<void> gameCenterReport({required String leaderboard, required int score, required Iterable<String> achievements}) async {
    if (!gameCenterSignedIn) return;
    await _call<void>('gcReport', {'leaderboard': leaderboard, 'score': score, 'achievements': achievements.toList()});
  }

  static Future<void> gameCenterDashboard() => _call<void>('gcShowDashboard');

  /// iCloud key-value storage (synced across the player's Apple devices).
  static Future<String?> iCloudGet(String key) => _call<String>('kvGet', {'key': key});

  static Future<bool> iCloudSet(String key, String value) async => await _call<bool>('kvSet', {'key': key, 'value': value}) ?? false;
}
