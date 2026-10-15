import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Marks the screen as secret while roles are dealt. On Android this sets
/// FLAG_SECURE (no screenshots, blank app-switcher thumbnail). iOS and the
/// web rely on the in-app cover shown when the app becomes inactive.
class SecureScreen {
  SecureScreen._();
  static const _channel = MethodChannel('shahdozd/privacy');
  static bool _on = false;

  static Future<void> set(bool on) async {
    if (on == _on || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _on = on;
    try {
      await _channel.invokeMethod<void>('secure', on);
    } catch (_) {
      // Older embedders or tests: the in-app cover still protects the deal.
    }
  }
}
