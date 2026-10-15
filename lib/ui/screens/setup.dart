import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'round.dart';

String newId() {
  final r = Random.secure();
  return List.generate(10, (_) => 'abcdefghijklmnopqrstuvwxyz0123456789'[r.nextInt(36)]).join();
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.mode});
  final ModeId mode;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late final int count = Scenario.playersFor(widget.mode);
  late final List<TextEditingController> names = List.generate(count, (_) => TextEditingController());
  late final List<int> avatars = List.generate(count, (i) => i);
  int rounds = 10;
  String? error;
  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    // Same table as last time? Pre-fill it.
    final app = AppScope.read(context);
    final last = app.tournament;
    if (last != null && last.players.length == count) {
      for (var i = 0; i < count; i++) {
        names[i].text = last.players[i].name;
        avatars[i] = last.players[i].avatar;
      }
      rounds = last.targetRounds;
    }
  }

  @override
  void dispose() {
    for (final c in names) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillFromSaved(Player p) {
    if (names.any((c) => c.text.trim() == p.name)) return;
    final i = names.indexWhere((c) => c.text.trim().isEmpty);
    if (i < 0) return;
    setState(() {
      names[i].text = p.name;
      avatars[i] = p.avatar;
    });
  }

  Future<void> _start() async {
    final s = S.of(context);
    final app = AppScope.read(context);
    final chosen = [
      for (var i = 0; i < count; i++) names[i].text.trim().isEmpty ? s.t('setup.default', {'n': i + 1}) : names[i].text.trim(),
    ];
    if (chosen.toSet().length != chosen.length) {
      setState(() => error = s.t('setup.duplicate'));
      return;
    }
    final saved = {for (final p in app.savedPlayers) p.name: p};
    final players = [
      for (var i = 0; i < count; i++) Player(id: saved[chosen[i]]?.id ?? newId(), name: chosen[i], avatar: avatars[i]),
    ];
    app.rememberPlayers([for (var i = 0; i < count; i++) if (names[i].text.trim().isNotEmpty) players[i]]);
    final st = app.settings;
    app.setTournament(Tournament(
      mode: widget.mode,
      players: players,
      scoring: ScoringConfig.preset(st.scoring),
      indianGuesser: st.indianGuesser,
      guard: st.guard,
      targetRounds: rounds,
    ));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoundScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final st = app.settings;
    final scenario = Scenario.of(widget.mode, indianGuesser: st.indianGuesser, guard: st.guard);
    final suggestions = app.savedPlayers.where((p) => !names.any((c) => c.text.trim() == p.name)).take(12).toList();
    return Scaffold(
      body: Body(
        child: Column(children: [
          TopBar(title: s.mode(widget.mode)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: [
              RuleBanner(scenario: scenario),
              const SizedBox(height: 18),
              Text(s.t('setup.title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.goldText)),
              const SizedBox(height: 8),
              for (var i = 0; i < count; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Semantics(
                      button: true,
                      label: s.t('setup.avatar'),
                      child: InkResponse(
                        radius: 28,
                        onTap: () => setState(() => avatars[i] = (avatars[i] + 1) % C.avatars.length),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Avatar(player: Player(id: '$i', name: names[i].text.isEmpty ? '${i + 1}' : names[i].text, avatar: avatars[i]), size: 40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: names[i],
                        maxLength: 18,
                        textInputAction: i == count - 1 ? TextInputAction.done : TextInputAction.next,
                        onChanged: (_) => setState(() => error = null),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: s.t('setup.default', {'n': i + 1}),
                          labelText: s.t('setup.name', {'n': i + 1}),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                        ),
                      ),
                    ),
                  ]),
                ),
              if (error != null)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(error!, style: const TextStyle(color: Color(0xFFFF9A9A)))),
              if (suggestions.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(s.t('setup.saved'), style: const TextStyle(fontSize: 13, color: C.faint)),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final p in suggestions)
                    ActionChip(
                      avatar: Avatar(player: p, size: 24),
                      label: Text(p.name),
                      backgroundColor: C.surface,
                      side: const BorderSide(color: C.lineSoft),
                      onPressed: () => _fillFromSaved(p),
                    ),
                ]),
              ],
              const SizedBox(height: 18),
              Text(s.t('setup.rounds'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.goldText)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final r in const [5, 10, 15, 0])
                  ChoiceChip(
                    label: Text(r == 0 ? s.t('setup.unlimited') : s.n(r)),
                    selected: rounds == r,
                    showCheckmark: false,
                    selectedColor: C.gold,
                    backgroundColor: C.surface,
                    side: const BorderSide(color: C.lineSoft),
                    labelStyle: TextStyle(fontWeight: FontWeight.w700, color: rounds == r ? C.onGold : C.ivory),
                    onSelected: (_) => setState(() => rounds = r),
                  ),
              ]),
              const SizedBox(height: 16),
            ]),
          ),
          GoldButton(label: s.t('setup.start'), icon: Icons.style_rounded, onPressed: _start),
        ]),
      ),
    );
  }
}
