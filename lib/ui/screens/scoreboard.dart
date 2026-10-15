import 'package:flutter/material.dart';

import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'round.dart';

/// Leaderboard and round history of the current tournament.
class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key, this.readOnly = false});

  /// Opened from inside a round: no restart/end buttons.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final t = app.tournament;
    if (t == null) {
      return Scaffold(body: Body(child: Column(children: [TopBar(title: s.t('board.title')), Expanded(child: Center(child: Text(s.t('board.empty'))))])));
    }
    final totals = t.totals;
    final sc = t.scenario;
    return Scaffold(
      body: Body(
        child: Column(children: [
          TopBar(title: s.t('board.title')),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: [
              Text('${s.mode(t.mode)} · ${s.t('players.count', {'n': t.players.length})}', textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
              const SizedBox(height: 12),
              for (final (i, p) in t.standings.indexed)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: i == 0 && t.rounds.isNotEmpty ? const Color(0xFF231C4A) : C.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: i == 0 && t.rounds.isNotEmpty ? C.gold : C.lineSoft),
                  ),
                  child: Row(children: [
                    SizedBox(width: 28, child: Text(s.n(i + 1), style: const TextStyle(fontWeight: FontWeight.w900, color: C.gold, fontSize: 16))),
                    Avatar(player: p, size: 32),
                    const SizedBox(width: 10),
                    Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                    Text(s.n(totals[p.id]!), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: C.goldLight)),
                  ]),
                ),
              const SizedBox(height: 14),
              Text(s.t('result.history'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.goldText)),
              const SizedBox(height: 8),
              if (t.rounds.isEmpty) Text(s.t('board.empty'), style: const TextStyle(color: C.faint)),
              for (final (i, r) in t.rounds.indexed.toList().reversed)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Text(s.t('board.round', {'r': i + 1}), style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            r.guesserWins ? s.t('result.win', {'g': s.role(sc.guesser, sc.mode)}) : s.t('result.lose', {'g': s.role(sc.guesser, sc.mode)}),
                            if (r.perfectCatch) s.t('result.perfect').split('!').first,
                            if (r.jokerFooledGuesser) s.role(Role.joker, sc.mode),
                          ].join(' · '),
                          style: TextStyle(fontSize: 13, color: r.guesserWins ? C.success : const Color(0xFFF0B7A8)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 10, runSpacing: 4, children: [
                      for (final p in t.players)
                        Text('${p.name} (${s.role(r.deal[p.id]!, sc.mode)}) ${s.pts(r.points[p.id] ?? 0)}', style: const TextStyle(fontSize: 12.5, color: C.muted)),
                    ]),
                  ]),
                ),
            ]),
          ),
          if (!readOnly) ...[
            if (!t.isFinished)
              GoldButton(
                label: s.t('home.continue'),
                onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoundScreen())),
              ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: GoldButton(
                  label: s.t('board.restart'),
                  secondary: true,
                  onPressed: () async {
                    if (await confirm(context, s.t('board.restart.q'))) app.setTournament(t.restarted());
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GoldButton(
                  label: s.t('board.end'),
                  secondary: true,
                  onPressed: () async {
                    if (await confirm(context, s.t('board.end') + (s.rtl ? '؟' : '?'))) {
                      app.setTournament(null);
                      if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
