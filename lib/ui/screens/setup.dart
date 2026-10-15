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
  int rounds = 5;
  int _lastFinite = 5;
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
      if (rounds > 0) _lastFinite = rounds;
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
              _RoundsPicker(
                rounds: rounds,
                onChanged: (r) => setState(() {
                  rounds = r;
                  if (r > 0) _lastFinite = r;
                }),
                lastFinite: _lastFinite,
              ),
              const SizedBox(height: 16),
            ]),
          ),
          GoldButton(label: s.t('setup.start'), icon: Icons.style_rounded, onPressed: _start),
        ]),
      ),
    );
  }
}

/// Number of rounds: −/+ (1–99), tap the number to type it, or unlimited.
class _RoundsPicker extends StatelessWidget {
  const _RoundsPicker({required this.rounds, required this.lastFinite, required this.onChanged});
  final int rounds;
  final int lastFinite;
  final ValueChanged<int> onChanged;

  static const max = 99;

  Future<void> _type(BuildContext context) async {
    final s = S.of(context);
    final c = TextEditingController(text: '${rounds == 0 ? lastFinite : rounds}');
    final r = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.t('setup.rounds'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          onSubmitted: (v) => Navigator.pop(ctx, _parse(v)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.t('cancel'), style: const TextStyle(color: C.muted))),
          TextButton(onPressed: () => Navigator.pop(ctx, _parse(c.text)), child: Text(s.t('save'), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800))),
        ],
      ),
    );
    c.dispose();
    if (r != null) onChanged(r);
  }

  /// Accepts Persian, Arabic-Indic and Devanagari digits too.
  static int? _parse(String v) {
    const sets = ['۰۱۲۳۴۵۶۷۸۹', '٠١٢٣٤٥٦٧٨٩', '०१२३४५६७८९'];
    var t = v.trim();
    for (final d in sets) {
      for (var i = 0; i < 10; i++) {
        t = t.replaceAll(d[i], '$i');
      }
    }
    final n = int.tryParse(t);
    return n?.clamp(1, max);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final unlimited = rounds == 0;
    final value = unlimited ? lastFinite : rounds;
    Widget step(IconData icon, String label, int delta) => IconButton.filledTonal(
          tooltip: label,
          onPressed: unlimited || (value + delta) < 1 || (value + delta) > max ? null : () => onChanged(value + delta),
          style: IconButton.styleFrom(backgroundColor: C.surface, foregroundColor: C.goldText, minimumSize: const Size(48, 48), side: const BorderSide(color: C.lineSoft)),
          icon: Icon(icon),
        );
    return Row(children: [
      step(Icons.remove_rounded, '−', -1),
      const SizedBox(width: 8),
      Expanded(
        child: Semantics(
          button: true,
          label: s.t('setup.rounds'),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: unlimited ? null : () => _type(context),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: unlimited ? C.lineSoft : C.line)),
              child: Text(
                unlimited ? '∞' : s.n(value),
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: unlimited ? C.faint : C.goldLight),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      step(Icons.add_rounded, '+', 1),
      const SizedBox(width: 12),
      FilterChip(
        label: Text(s.t('setup.unlimited')),
        selected: unlimited,
        showCheckmark: false,
        selectedColor: C.gold,
        backgroundColor: C.surface,
        side: const BorderSide(color: C.lineSoft),
        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: unlimited ? C.onGold : C.ivory),
        onSelected: (on) => onChanged(on ? 0 : lastFinite),
      ),
    ]);
  }
}
