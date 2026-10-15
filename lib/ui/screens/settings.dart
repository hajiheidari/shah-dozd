import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/native.dart';

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
              section(s.t('backup.title'), [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: Text(
                    s.t(Native.isIOS ? 'backup.icloud' : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ? 'backup.android' : 'backup.web'),
                    style: const TextStyle(fontSize: 13, height: 1.7, color: C.muted),
                  ),
                ),
                if (Native.isIOS)
                  ListTile(
                    key: const Key('icloudRestore'),
                    leading: const Icon(Icons.cloud_download_outlined, color: C.goldText),
                    title: Text(s.t('backup.icloud.restore')),
                    onTap: () async {
                      final ok = await app.restoreFromICloud();
                      if (context.mounted) _toast(context, s.t(ok ? 'backup.ok' : 'backup.none'));
                    },
                  ),
                ListTile(
                  key: const Key('showCode'),
                  leading: const Icon(Icons.key_rounded, color: C.goldText),
                  title: Text(s.t('backup.code')),
                  onTap: () => _showCode(context, app),
                ),
                ListTile(
                  key: const Key('enterCode'),
                  leading: const Icon(Icons.restore_rounded, color: C.goldText),
                  title: Text(s.t('backup.enter')),
                  onTap: () => _enterCode(context, app),
                ),
              ]),
              if (Native.isIOS)
                section(s.t('gc.title'), [
                  ListTile(
                    leading: const Icon(Icons.emoji_events_outlined, color: C.goldText),
                    title: Text(s.t(Native.gameCenterSignedIn ? 'gc.open' : 'gc.signin')),
                    onTap: () async {
                      if (!Native.gameCenterSignedIn) await Native.gameCenterSignIn();
                      if (Native.gameCenterSignedIn) await Native.gameCenterDashboard();
                    },
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

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), duration: const Duration(seconds: 2)));

Future<void> _showCode(BuildContext context, AppState app) {
  final s = S.of(context);
  final code = app.recoveryCode();
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: C.surface,
      title: Text(s.t('backup.code')),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(color: C.night, borderRadius: BorderRadius.circular(12), border: Border.all(color: C.lineSoft)),
          child: SelectableText(
            code,
            key: const Key('recoveryCode'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: C.goldText),
          ),
        ),
        const SizedBox(height: 12),
        Text(s.t('backup.code.note'), style: const TextStyle(fontSize: 13, height: 1.7, color: C.muted)),
      ]),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (ctx.mounted) _toast(ctx, s.t('backup.copied'));
          },
          child: Text(s.t('backup.copy')),
        ),
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(MaterialLocalizations.of(ctx).okButtonLabel)),
      ],
    ),
  );
}

Future<void> _enterCode(BuildContext context, AppState app) async {
  final s = S.of(context);
  final controller = TextEditingController();
  String? error;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: C.surface,
        title: Text(s.t('backup.enter')),
        content: TextField(
          key: const Key('codeField'),
          controller: controller,
          autofocus: true,
          textDirection: TextDirection.ltr,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontFamily: 'monospace', letterSpacing: 1.2),
          decoration: InputDecoration(hintText: 'XXXX-XXXX-XXXX', errorText: error, hintTextDirection: TextDirection.ltr),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(s.t('backup.cancel'))),
          FilledButton(
            key: const Key('restoreCode'),
            onPressed: () {
              if (app.restoreCode(controller.text)) {
                Navigator.of(ctx).pop(true);
              } else {
                setState(() => error = s.t('backup.bad'));
              }
            },
            child: Text(s.t('backup.restore')),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  if (ok == true && context.mounted) _toast(context, s.t('backup.ok'));
}
