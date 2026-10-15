import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/engine.dart';
import '../l10n/strings.dart';
import '../shop/recovery.dart';
import '../shop/wallet.dart';
import 'native.dart';
import 'stats.dart';

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
  AppState._(this._prefs, this.settings, this.savedPlayers, this.tournament, this._fallbackLang, [Wallet? wallet, Stats? stats])
      : wallet = wallet ?? Wallet(),
        stats = stats ?? Stats();

  static const _kSettings = 'settings.v1';
  static const _kPlayers = 'players.v1';
  static const _kTournament = 'tournament.v1';
  static const _kWallet = 'wallet.v1';
  static const _kStats = 'stats.v1';
  static const _kICloud = 'backup.v1';

  final SharedPreferences? _prefs;
  Settings settings;
  List<Player> savedPlayers;
  Tournament? tournament;
  final Wallet wallet;
  final Stats stats;
  final Lang _fallbackLang;

  /// True when nothing was stored yet (first launch or a reinstall).
  bool freshInstall = false;

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
    final stats = read(_kStats, Stats.fromJson);
    return AppState._(prefs, settings, players, t, _deviceLang(), wallet, stats)..freshInstall = prefs?.getString(_kWallet) == null;
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
    _reportGameCenter();
  }

  /// After every resolved round.
  void recordRound(ModeId mode, RoundOutcome outcome, {required bool tournamentFinished}) {
    stats.recordRound(mode, outcome);
    if (tournamentFinished) stats.recordTournament();
    _write(_kStats, jsonEncode(stats.toJson()));
    _reportGameCenter();
  }

  void _reportGameCenter() {
    Native.gameCenterReport(leaderboard: Stats.leaderboard, score: stats.rounds, achievements: stats.achievements(wallet));
  }

  // ---- Backup: iCloud (iOS), Android Auto Backup (by the system), code ----

  /// Everything worth keeping, as one JSON object.
  Map<String, Object?> snapshot() => {
        'v': 1,
        'at': DateTime.now().toUtc().toIso8601String(),
        'settings': settings.toJson(),
        'players': [for (final p in savedPlayers) p.toJson()],
        'tournament': tournament?.toJson(),
        'wallet': wallet.toJson(),
        'stats': stats.toJson(),
      };

  /// Restores a [snapshot]: coins and counters keep the larger value, bought
  /// items are merged, the rest is taken from the backup.
  void restoreSnapshot(Map<String, Object?> j) {
    try {
      final w = Wallet.fromJson((j['wallet'] as Map).cast());
      _mergeWallet(coins: w.coins, owned: w.owned, back: w.back, theme: w.theme, deck: w.deck);
      wallet.welcomed = true;
      stats.mergeMax(Stats.fromJson((j['stats'] as Map? ?? const {}).cast()));
      if (j['settings'] is Map) settings = Settings.fromJson((j['settings'] as Map).cast());
      if (j['players'] is List && savedPlayers.isEmpty) {
        savedPlayers = [for (final p in j['players'] as List) Player.fromJson((p as Map).cast())];
      }
      if (j['tournament'] is Map && tournament == null) tournament = Tournament.fromJson((j['tournament'] as Map).cast());
    } catch (_) {
      return;
    }
    _saveAll();
  }

  /// Restores from a recovery code; false when the code is wrong.
  bool restoreCode(String code) {
    final d = RecoveryCode.decode(code);
    if (d == null) return false;
    _mergeWallet(coins: d.coins, owned: d.owned, back: d.back, theme: d.theme, deck: d.deck);
    wallet.welcomed = true;
    if (d.rounds > stats.rounds) stats.rounds = d.rounds;
    _saveAll();
    return true;
  }

  String recoveryCode() => RecoveryCode.encode(RecoveryData(
        coins: wallet.coins,
        owned: wallet.owned,
        back: wallet.back,
        theme: wallet.theme,
        deck: wallet.deck,
        rounds: stats.rounds,
      ));

  void _mergeWallet({required int coins, required Set<String> owned, required String back, required String theme, required String deck}) {
    if (coins > wallet.coins) wallet.coins = coins;
    wallet.owned.addAll(owned);
    wallet.equip(back);
    wallet.equip(theme);
    wallet.equip(deck);
  }

  void _saveAll() {
    _write(_kSettings, jsonEncode(settings.toJson()));
    _write(_kPlayers, jsonEncode([for (final p in savedPlayers) p.toJson()]));
    final t = tournament;
    if (t != null) _write(_kTournament, jsonEncode(t.toJson()));
    _write(_kStats, jsonEncode(stats.toJson()));
    _write(_kWallet, jsonEncode(wallet.toJson()));
    notifyListeners();
  }

  /// iOS: on a fresh install, bring back the iCloud backup if there is one.
  Future<bool> restoreFromICloud({bool onlyIfFresh = false}) async {
    if (!Native.isIOS || (onlyIfFresh && !freshInstall)) return false;
    final raw = await Native.iCloudGet(_kICloud);
    if (raw == null) return false;
    try {
      restoreSnapshot((jsonDecode(raw) as Map).cast());
      return true;
    } catch (_) {
      return false;
    }
  }

  Timer? _backupTimer;

  /// iOS: keeps the iCloud copy current (a few seconds after each change).
  void _scheduleICloudBackup() {
    if (!Native.isIOS) return;
    _backupTimer?.cancel();
    _backupTimer = Timer(const Duration(seconds: 3), () => Native.iCloudSet(_kICloud, jsonEncode(snapshot())));
  }

  void _write(String key, String value) {
    _prefs?.setString(key, value).catchError((_) => false);
    _scheduleICloudBackup();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Without subscribing to changes (for callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
