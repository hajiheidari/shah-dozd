import 'package:flutter/material.dart';

import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'rules.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final st = app.settings;
    void set(Settings n) => app.updateSettings(n);

    Widget section(String title, List<Widget> children) => Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: C.goldText)),
            const SizedBox(height: 8),
            Material(
              color: C.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Space.radius), side: const BorderSide(color: C.lineSoft)),
              child: Column(children: children),
            ),
          ]),
        );

    Widget toggle(String label, bool v, ValueChanged<bool> on) => SwitchListTile(
          value: v,
          onChanged: on,
          title: Text(label, style: const TextStyle(fontSize: 15)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        );

    Widget choice<T>(List<(T, String)> options, T value, ValueChanged<T> on) => Padding(
          padding: const EdgeInsets.all(10),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (v, label) in options)
              ChoiceChip(
                label: Text(label),
                selected: v == value,
                showCheckmark: false,
                selectedColor: C.gold,
                backgroundColor: C.night,
                side: const BorderSide(color: C.lineSoft),
                labelStyle: TextStyle(fontWeight: FontWeight.w700, color: v == value ? C.onGold : C.ivory),
                onSelected: (_) => on(v),
              ),
          ]),
        );

    return Scaffold(
      body: Body(
        child: Column(children: [
          TopBar(title: s.t('settings.title')),
          const SizedBox(height: 14),
          Expanded(
            child: ListView(children: [
              section(s.t('settings.language'), [
                choice([for (final l in Lang.values) (l, l.label)], app.lang, (l) => set(st.copyWith(lang: l))),
              ]),
              section(s.t('settings.sound'), [
                toggle(s.t('settings.sound'), st.sound, (v) => set(st.copyWith(sound: v))),
                toggle(s.t('settings.haptics'), st.haptics, (v) => set(st.copyWith(haptics: v))),
                toggle(s.t('settings.motion'), st.reduceMotion, (v) => set(st.copyWith(reduceMotion: v))),
              ]),
              section(s.t('settings.rules'), [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Text(s.t('settings.indian'), style: const TextStyle(fontSize: 14, color: C.muted)),
                ),
                choice([
                  (IndianGuesser.minister, s.t('role.mantri')),
                  (IndianGuesser.sipahi, s.t('role.sipahi')),
                ], st.indianGuesser, (v) => set(st.copyWith(indianGuesser: v))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: Text(s.t('settings.guard'), style: const TextStyle(fontSize: 14, color: C.muted)),
                ),
                choice([
                  (Role.executioner, s.t('role.executioner')),
                  (Role.sipahi, s.t('role.sipahi')),
                ], st.guard, (v) => set(st.copyWith(guard: v))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: Text(s.t('settings.scoring'), style: const TextStyle(fontSize: 14, color: C.muted)),
                ),
                choice([
                  (ScoringPreset.traditional, s.t('settings.scoring.traditional')),
                  (ScoringPreset.party, s.t('settings.scoring.party')),
                ], st.scoring, (v) => set(st.copyWith(scoring: v))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Text(s.t('settings.scoring.note'), style: const TextStyle(fontSize: 12, color: C.faint)),
                ),
                toggle(s.t('settings.challenges'), st.challenges, (v) => set(st.copyWith(challenges: v))),
                ListTile(
                  title: Text(s.t('rules.title')),
                  trailing: const Icon(Icons.chevron_right, color: C.goldText), // mirrored in RTL
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RulesScreen())),
                ),
              ]),
              section(s.t('settings.premium'), [
                Padding(padding: const EdgeInsets.all(14), child: Text(s.t('settings.premium.sub'), style: const TextStyle(fontSize: 14, height: 1.7, color: C.muted))),
              ]),
              section(s.t('settings.about'), [
                Padding(padding: const EdgeInsets.all(14), child: Text(s.t('settings.about.sub'), style: const TextStyle(fontSize: 14, height: 1.7, color: C.muted))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
