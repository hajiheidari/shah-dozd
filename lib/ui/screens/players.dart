import 'package:flutter/material.dart';

import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'setup.dart';

/// Frequently used players, kept on this device only.
class SavedPlayersScreen extends StatefulWidget {
  const SavedPlayersScreen({super.key});

  @override
  State<SavedPlayersScreen> createState() => _SavedPlayersScreenState();
}

class _SavedPlayersScreenState extends State<SavedPlayersScreen> {
  final _new = TextEditingController();

  @override
  void dispose() {
    _new.dispose();
    super.dispose();
  }

  void _add(AppState app) {
    final name = _new.text.trim();
    if (name.isEmpty || app.savedPlayers.any((p) => p.name == name)) return;
    app.upsertSavedPlayer(Player(id: newId(), name: name, avatar: app.savedPlayers.length % C.avatars.length));
    _new.clear();
  }

  Future<void> _edit(AppState app, Player p) async {
    final s = S.of(context);
    final c = TextEditingController(text: p.name);
    var avatar = p.avatar;
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < C.avatars.length; i++)
                InkResponse(
                  onTap: () => set(() => avatar = i),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: avatar == i ? C.goldLight : Colors.transparent, width: 2)),
                    child: Avatar(player: p.copyWith(avatar: i, name: c.text), size: 34),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            TextField(controller: c, maxLength: 18, autofocus: true, decoration: const InputDecoration(counterText: '')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, '\u0000delete'), child: Text(s.t('delete'), style: const TextStyle(color: Color(0xFFFF9A9A)))),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.t('cancel'), style: const TextStyle(color: C.muted))),
            TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(s.t('save'), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800))),
          ],
        ),
      ),
    );
    c.dispose();
    if (r == null) return;
    if (r == '\u0000delete') {
      app.removeSavedPlayer(p.id);
    } else if (r.isNotEmpty) {
      app.upsertSavedPlayer(p.copyWith(name: r, avatar: avatar));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    return Scaffold(
      body: Body(
        child: Column(children: [
          TopBar(title: s.t('saved.title')),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _new,
                maxLength: 18,
                onSubmitted: (_) => _add(app),
                decoration: InputDecoration(counterText: '', hintText: s.t('saved.new')),
              ),
            ),
            const SizedBox(width: 10),
            IconBox(icon: Icons.person_add_alt_1_outlined, label: s.t('add'), onPressed: () => _add(app)),
          ]),
          const SizedBox(height: 14),
          Expanded(
            child: app.savedPlayers.isEmpty
                ? Center(child: Text(s.t('saved.empty'), textAlign: TextAlign.center, style: const TextStyle(color: C.faint, height: 1.7)))
                : ListView.separated(
                    itemCount: app.savedPlayers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = app.savedPlayers[i];
                      return Material(
                        color: C.surface,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          minTileHeight: 56,
                          leading: Avatar(player: p),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          trailing: const Icon(Icons.edit_outlined, color: C.goldText, size: 20),
                          onTap: () => _edit(app, p),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
