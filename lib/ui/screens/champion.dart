import 'package:flutter/material.dart';

import '../../app/sfx.dart';
import '../../app/state.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'round.dart';

class ChampionScreen extends StatefulWidget {
  const ChampionScreen({super.key});

  @override
  State<ChampionScreen> createState() => _ChampionScreenState();
}

class _ChampionScreenState extends State<ChampionScreen> {
  @override
  void initState() {
    super.initState();
    Sounds.play(Sfx.champion);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final t = app.tournament!;
    final leaders = t.leaders;
    final totals = t.totals;
    return Scaffold(
      body: Stack(children: [
        Body(
          child: Column(children: [
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: motion(context, 900),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(scale: .5 + v * .5, child: child),
              child: const CrownMark(width: 120),
            ),
            const SizedBox(height: 10),
            Text(leaders.length > 1 ? s.t('champ.tie') : s.t('champ.title'), style: const TextStyle(fontSize: 16, color: C.muted)),
            const SizedBox(height: 10),
            Wrap(alignment: WrapAlignment.center, spacing: 18, runSpacing: 12, children: [
              for (final p in leaders)
                Column(children: [
                  Avatar(player: p, size: 76),
                  const SizedBox(height: 8),
                  Text(p.name, style: F.title(s.lang, 34)),
                ]),
            ]),
            const SizedBox(height: 4),
            if (leaders.isNotEmpty) Text(s.t('champ.points', {'p': totals[leaders.first.id]!}), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: C.goldLight)),
            const SizedBox(height: 20),
            for (final (i, p) in t.standings.indexed.skip(leaders.length))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${s.n(i + 1)}. ${p.name}', style: const TextStyle(color: C.muted, fontSize: 15)),
                  const SizedBox(width: 10),
                  Text(s.n(totals[p.id]!), style: const TextStyle(color: C.ivory, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            const Spacer(),
            GoldButton(
              label: s.t('champ.again'),
              icon: Icons.replay_rounded,
              onPressed: () {
                app.setTournament(t.restarted());
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RoundScreen()));
              },
            ),
            const SizedBox(height: 10),
            GoldButton(label: s.t('champ.home'), secondary: true, onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          ]),
        ),
        const Positioned.fill(child: Confetti(count: 140)),
      ]),
    );
  }
}
