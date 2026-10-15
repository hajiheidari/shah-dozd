import 'package:flutter/material.dart';

import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final st = AppScope.of(context).settings;
    return Scaffold(
      body: Body(
        child: Column(children: [
          TopBar(title: s.t('rules.title')),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(children: [
              Text(s.t('rules.intro'), style: const TextStyle(fontSize: 15, height: 1.8, color: Color(0xFFE6DDCB))),
              const SizedBox(height: 18),
              for (final m in ModeId.values) _ModeRules(scenario: Scenario.of(m, indianGuesser: st.indianGuesser, guard: st.guard)),
              Text(s.t('rules.scoring'), style: F.title(s.lang, 22)),
              const SizedBox(height: 6),
              Text(s.t('rules.scoring.traditional'), style: const TextStyle(fontSize: 14, height: 1.8, color: C.muted)),
              const SizedBox(height: 8),
              Text(s.t('rules.scoring.party'), style: const TextStyle(fontSize: 14, height: 1.8, color: C.muted)),
              const SizedBox(height: 24),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _ModeRules extends StatelessWidget {
  const _ModeRules({required this.scenario});
  final Scenario scenario;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(Space.radius), border: Border.all(color: C.lineSoft)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(s.mode(scenario.mode), style: F.title(s.lang, 22))),
          Text(s.t('players.count', {'n': scenario.playerCount}), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: scenario.roles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => Column(children: [
              CardArt(role: scenario.roles[i], width: 42),
              const SizedBox(height: 2),
              Text(s.role(scenario.roles[i], scenario.mode), style: const TextStyle(fontSize: 11, color: C.muted)),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        for (final line in s.fullRules(scenario))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 10), child: Icon(Icons.circle, size: 5, color: C.gold)),
              const SizedBox(width: 8),
              Expanded(child: Text(line, style: const TextStyle(fontSize: 14, height: 1.75, color: Color(0xFFE6DDCB)))),
            ]),
          ),
      ]),
    );
  }
}
