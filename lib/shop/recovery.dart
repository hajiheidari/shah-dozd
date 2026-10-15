import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'catalog.dart';

/// An offline recovery code for coins, bought items and play count.
///
/// Works without internet or a server (also on the Iranian national
/// network): everything is inside the code, e.g. `K7QM-2ZD8-W1PA-6C3T-9`.
/// A short HMAC makes typos and casual edits fail; it is not meant to stop a
/// determined cheater, since coins have no money value.
class RecoveryData {
  const RecoveryData({required this.coins, required this.owned, required this.back, required this.theme, required this.deck, required this.rounds});

  final int coins;
  final Set<String> owned;
  final String back;
  final String theme;
  final String deck;
  final int rounds;
}

abstract final class RecoveryCode {
  static const _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; // Crockford base32
  static const _version = 1;
  static final _key = utf8.encode('shah-dozd-vazir/recovery/v1');

  static String encode(RecoveryData d) {
    final b = BytesBuilder();
    b.addByte(_version);
    _varint(b, d.coins);
    var mask = 0;
    for (final id in d.owned) {
      final code = itemByIdOrNull(id)?.code;
      if (code != null && code < 32) mask |= 1 << code;
    }
    b.add([mask & 0xFF, (mask >> 8) & 0xFF, (mask >> 16) & 0xFF, (mask >> 24) & 0xFF]);
    b.add([_code(d.back), _code(d.theme), _code(d.deck)]);
    _varint(b, d.rounds);
    final payload = b.toBytes();
    final mac = Hmac(sha256, _key).convert(payload).bytes.sublist(0, 4);
    final raw = _base32([...payload, ...mac]);
    final groups = <String>[];
    for (var i = 0; i < raw.length; i += 4) {
      groups.add(raw.substring(i, i + 4 > raw.length ? raw.length : i + 4));
    }
    return groups.join('-');
  }

  /// Null when the code is mistyped or not ours.
  static RecoveryData? decode(String input) {
    final clean = input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '').replaceAll('O', '0').replaceAll(RegExp('[IL]'), '1');
    final bytes = _unbase32(clean);
    if (bytes == null || bytes.length < 13) return null;
    final payload = bytes.sublist(0, bytes.length - 4);
    final mac = Hmac(sha256, _key).convert(payload).bytes.sublist(0, 4);
    for (var i = 0; i < 4; i++) {
      if (mac[i] != bytes[bytes.length - 4 + i]) return null;
    }
    if (payload[0] != _version) return null;
    var p = 1;
    int varint() {
      var v = 0, shift = 0;
      while (p < payload.length) {
        final x = payload[p++];
        v |= (x & 0x7F) << shift;
        if (x < 0x80) return v;
        shift += 7;
      }
      throw const FormatException('truncated');
    }

    try {
      final coins = varint();
      final mask = payload[p] | payload[p + 1] << 8 | payload[p + 2] << 16 | payload[p + 3] << 24;
      p += 4;
      final back = itemByCode(payload[p++])?.id ?? 'back.classic';
      final theme = itemByCode(payload[p++])?.id ?? 'theme.gold';
      final deck = itemByCode(payload[p++])?.id ?? 'deck.classic';
      final rounds = varint();
      final owned = <String>{
        for (final i in shopItems) if (i.code < 32 && mask & (1 << i.code) != 0) i.id,
      };
      return RecoveryData(coins: coins, owned: owned, back: back, theme: theme, deck: deck, rounds: rounds);
    } catch (_) {
      return null;
    }
  }

  static int _code(String id) => itemByIdOrNull(id)?.code ?? 0;

  static void _varint(BytesBuilder b, int v) {
    var x = v < 0 ? 0 : v;
    while (x >= 0x80) {
      b.addByte((x & 0x7F) | 0x80);
      x >>= 7;
    }
    b.addByte(x);
  }

  static String _base32(List<int> data) {
    final out = StringBuffer();
    var buffer = 0, bits = 0;
    for (final byte in data) {
      buffer = (buffer << 8) | byte;
      bits += 8;
      while (bits >= 5) {
        out.write(_alphabet[(buffer >> (bits - 5)) & 31]);
        bits -= 5;
      }
    }
    if (bits > 0) out.write(_alphabet[(buffer << (5 - bits)) & 31]);
    return out.toString();
  }

  static List<int>? _unbase32(String s) {
    final out = <int>[];
    var buffer = 0, bits = 0;
    for (final ch in s.split('')) {
      final v = _alphabet.indexOf(ch);
      if (v < 0) return null;
      buffer = (buffer << 5) | v;
      bits += 5;
      if (bits >= 8) {
        out.add((buffer >> (bits - 8)) & 0xFF);
        bits -= 8;
      }
    }
    return out;
  }
}

ShopItem? itemByIdOrNull(String id) {
  for (final i in shopItems) {
    if (i.id == id) return i;
  }
  return null;
}
