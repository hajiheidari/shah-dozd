import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short original sound effects (tools/gen_sounds.py). Never role-specific
/// while roles are being dealt, so nobody can hear what another player got.
enum Sfx { tap, flip, shuffle, reveal, win, lose, joker, perfect, champion }

class Sounds {
  Sounds._();
  static bool enabled = true;
  static bool haptics = true;

  static final Map<Sfx, AudioPlayer> _players = {};

  static Future<void> play(Sfx s) async {
    if (!enabled) return;
    try {
      final p = _players.putIfAbsent(s, () => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      await p.stop();
      await p.play(AssetSource('sounds/${s.name}.wav'), volume: s == Sfx.tap ? .45 : .8);
    } catch (_) {
      // Audio is decoration: a missing codec or a blocked autoplay never stops the game.
    }
  }

  static void buzz() {
    if (haptics) HapticFeedback.lightImpact();
  }
}
