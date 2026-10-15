import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/engine.dart';
import '../l10n/strings.dart';
import '../shop/wallet.dart';

/// User preferences. Rules-related ones are copied into each new tournament.
class Settings {
  const Settings({
    this.lang,
    this.sound = true,
    this.haptics = true,
    this.reduceMotion = false,
    this.indianGuesser = IndianGuesser.minister,
    this.guard = Role.executioner,
    this.scoring = ScoringPreset.traditional,
    this.challenges = true,
  });

  /// null = not chosen yet (follow the device / site).
  final Lang? lang;
  final bool sound;
  final bool haptics;
  final bool reduceMotion;
  final IndianGuesser indianGuesser;
  final Role guard;
  final ScoringPreset scoring;
  final bool challenges;

  Settings copyWith({
    Lang? lang,
    bool? sound,
    bool? haptics,
    bool? reduceMotion,
    IndianGuesser? indianGuesser,
    Role? guard,
    ScoringPreset? scoring,
    bool? challenges,
  }) =>
      Settings(
        lang: lang ?? this.lang,
        sound: sound ?? this.sound,
        haptics: haptics ?? this.haptics,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        indianGuesser: indianGuesser ?? this.indianGuesser,
        guard: guard ?? this.guard,
        scoring: scoring ?? this.scoring,
        challenges: challenges ?? this.challenges,
      );

  Map<String, Object?> toJson() => {
        'lang': lang?.name,
        'sound': sound,
        'haptics': haptics,
        'reduceMotion': reduceMotion,
        'indianGuesser': indianGuesser.name,
        'guard': guard.name,
        'scoring': scoring.name,
        'challenges': challenges,
      };

  factory Settings.fromJson(Map<String, Object?> j) => Settings(
        lang: Lang.tryParse(j['lang'] as String?),
        sound: j['sound'] as bool? ?? true,
        haptics: j['haptics'] as bool? ?? true,
        reduceMotion: j['reduceMotion'] as bool? ?? false,
        indianGuesser: IndianGuesser.values.asNameMap()[j['indianGuesser']] ?? IndianGuesser.minister,
        guard: Role.values.asNameMap()[j['guard']] ?? Role.executioner,
        scoring: ScoringPreset.values.asNameMap()[j['scoring']] ?? ScoringPreset.traditional,
        challenges: j['challenges'] as bool? ?? true,
      );
}

/// Everything the app keeps between launches, in local storage only.
class AppState extends ChangeNotifier {
  AppState._(this._prefs, this.settings, this.savedPlayers, this.tournament, this._fallbackLang, [Wallet? wallet])
      : wallet = wallet ?? Wallet();

  static const _kSettings = 'settings.v1';
  static const _kPlayers = 'players.v1';
  static const _kTournament = 'tournament.v1';
  static const _kWallet = 'wallet.v1';

  final SharedPreferences? _prefs;
  Settings settings;
  List<Player> savedPlayers;
  Tournament? tournament;
  final Wallet wallet;
  final Lang _fallbackLang;

  /// Loads saved state. Corrupt entries are dropped rather than crashing.
  static Future<AppState> load({Lang? forcedLang}) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null; // storage blocked (private browsing): play without saving
    }
    T? read<T>(String key, T Function(Map<String, Object?>) parse) {
      try {
        final raw = prefs?.getString(key);
        return raw == null ? null : parse((jsonDecode(raw) as Map).cast());
      } catch (_) {
        return null;
      }
    }

    var settings = read(_kSettings, Settings.fromJson) ?? const Settings();
    if (forcedLang != null) settings = settings.copyWith(lang: forcedLang);
    List<Player> players = const [];
    try {
      final raw = prefs?.getString(_kPlayers);
      if (raw != null) {
        players = [for (final p in jsonDecode(raw) as List) Player.fromJson((p as Map).cast())];
      }
    } catch (_) {}
    final t = read(_kTournament, Tournament.fromJson);
    final wallet = read(_kWallet, Wallet.fromJson);
    return AppState._(prefs, settings, players, t, _deviceLang(), wallet);
  }

  /// For tests: in-memory state.
  @visibleForTesting
  factory AppState.memory({Settings settings = const Settings(), Lang fallback = Lang.en, Wallet? wallet}) =>
      AppState._(null, settings, [], null, fallback, wallet);

  static Lang _deviceLang() {
    // On the Iranian mirror (espadna.ir) the game opens in Persian.
    if (kIsWeb && Uri.base.host.endsWith('.ir')) return Lang.fa;
    for (final l in WidgetsBinding.instance.platformDispatcher.locales) {
      final lang = Lang.tryParse(l.languageCode);
      if (lang != null) return lang;
    }
    return Lang.en;
  }

  Lang get lang => settings.lang ?? _fallbackLang;

  void updateSettings(Settings s) {
    settings = s;
    _write(_kSettings, jsonEncode(s.toJson()));
    notifyListeners();
  }

  /// Remembers the names used at a table (most recent first, max 40).
  void rememberPlayers(List<Player> players) {
    final merged = <Player>[...players];
    for (final p in savedPlayers) {
      if (!players.any((q) => q.name == p.name)) merged.add(p);
    }
    savedPlayers = merged.take(40).toList();
    _savePlayers();
  }

  void upsertSavedPlayer(Player p) {
    final i = savedPlayers.indexWhere((q) => q.id == p.id);
    savedPlayers = [...savedPlayers];
    if (i < 0) {
      savedPlayers.insert(0, p);
    } else {
      savedPlayers[i] = p;
    }
    _savePlayers();
  }

  void removeSavedPlayer(String id) {
    savedPlayers = savedPlayers.where((p) => p.id != id).toList();
    _savePlayers();
  }

  void _savePlayers() {
    _write(_kPlayers, jsonEncode([for (final p in savedPlayers) p.toJson()]));
    notifyListeners();
  }

  void setTournament(Tournament? t) {
    tournament = t;
    saveTournament();
  }

  /// Call after every change to [tournament] (a finished round).
  void saveTournament() {
    final t = tournament;
    if (t == null) {
      _prefs?.remove(_kTournament);
    } else {
      _write(_kTournament, jsonEncode(t.toJson()));
    }
    notifyListeners();
  }

  /// Call after every change to [wallet].
  void saveWallet() {
    _write(_kWallet, jsonEncode(wallet.toJson()));
    notifyListeners();
  }

  void _write(String key, String value) {
    _prefs?.setString(key, value).catchError((_) => false);
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
