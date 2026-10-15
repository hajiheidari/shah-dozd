import 'package:flutter/material.dart';

import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';
import 'players.dart';
import 'round.dart';
import 'rules.dart';
import 'scoreboard.dart';
import 'settings.dart';
import 'shop.dart';
import 'setup.dart';

class _ModeLook {
  const _ModeLook(this.mode, this.front, this.left, this.right, this.tint);
  final ModeId mode;
  final Role front, left, right;
  final Color tint;
}

const _looks = [
  _ModeLook(ModeId.persian, Role.king, Role.thief, Role.minister, Color(0xFF2C1752)),
  _ModeLook(ModeId.indian, Role.king, Role.minister, Role.sipahi, Color(0xFF4A2A12)),
  _ModeLook(ModeId.joker, Role.joker, Role.minister, Role.thief, Color(0xFF3E1240)),
  _ModeLook(ModeId.twoThieves, Role.thief, Role.joker, Role.thief2, Color(0xFF1A2448)),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final t = app.tournament;
    return Scaffold(
      body: LayoutBuilder(builder: (context, box) {
        final wide = box.maxWidth >= 820;
        return Body(
          maxWidth: wide ? 1080 : 560,
          child: CustomScrollView(slivers: [
            if (wide && box.maxHeight > 760) SliverToBoxAdapter(child: SizedBox(height: ((box.maxHeight - 700) / 3).clamp(0, 160))),
            SliverToBoxAdapter(
              child: Row(children: [
                IconBox(icon: Icons.groups_2_outlined, label: s.t('home.players'), onPressed: () => _push(context, const SavedPlayersScreen())),
                Expanded(child: Center(child: CoinPill(coins: app.wallet.coins, label: s.t('home.shop'), onTap: () => _push(context, const ShopScreen())))),
                IconBox(icon: Icons.settings_outlined, label: s.t('home.settings'), onPressed: () => _push(context, const SettingsScreen())),
              ]),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 18),
                child: Column(children: [
                  const CrownMark(),
                  const SizedBox(height: 4),
                  Text(s.t('app.title'), textAlign: TextAlign.center, style: F.title(s.lang, wide ? 46 : 38)),
                  const SizedBox(height: 2),
                  Text(s.t('home.pick'), style: const TextStyle(fontSize: 14, color: C.muted)),
                ]),
              ),
            ),
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: wide ? 4 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                mainAxisExtent: wide ? 300 : (box.maxWidth < 360 ? 236 : 252),
              ),
              delegate: SliverChildListDelegate([for (final l in _looks) _ModeCard(look: l)]),
            ),
            if (t != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: GoldButton(
                    label: s.t('home.continue'),
                    sub: s.t('home.continue.sub', {'mode': s.mode(t.mode), 'r': t.isFinished ? t.rounds.length : t.roundNumber, 'n': t.players.length}),
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _push(context, t.isFinished ? const ScoreboardScreen() : const RoundScreen()),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  children: [
                    _Link(s.t('home.rules'), () => _push(context, const RulesScreen())),
                    if (t != null) _Link(s.t('board.title'), () => _push(context, const ScoreboardScreen())),
                    _Link('فارسی · English · हिन्दी', () => pickLanguage(context)),
                  ],
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

void _push(BuildContext context, Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: C.muted, minimumSize: const Size(48, 44)),
        child: Text(label, style: const TextStyle(fontSize: 14, decoration: TextDecoration.underline, decorationColor: C.lineSoft)),
      );
}

Future<void> pickLanguage(BuildContext context) async {
  final app = AppScope.read(context);
  final picked = await showModalBottomSheet<Lang>(
    context: context,
    backgroundColor: C.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final l in Lang.values)
            ListTile(
              minTileHeight: 56,
              title: Text(l.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: l == app.lang ? C.gold : C.ivory)),
              onTap: () => Navigator.pop(ctx, l),
            ),
        ]),
      ),
    ),
  );
  if (picked != null) app.updateSettings(app.settings.copyWith(lang: picked));
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.look});
  final _ModeLook look;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final n = Scenario.playersFor(look.mode);
    return Semantics(
      button: true,
      label: '${s.mode(look.mode)}, ${s.t('players.count', {'n': n})}',
      child: Material(
        color: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Space.radiusL), side: const BorderSide(color: C.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _push(context, SetupScreen(mode: look.mode)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: Container(
                color: look.tint,
                child: LayoutBuilder(builder: (context, box) {
                  final h = box.maxHeight;
                  final side = (h * .6) / CardArt.ratio;
                  final front = (h * .78) / CardArt.ratio;
                  return Stack(alignment: Alignment.bottomCenter, children: [
                    PositionedDirectional(
                      bottom: h * .06,
                      end: box.maxWidth * .03,
                      child: Transform.rotate(angle: .17, child: CardArt(role: look.right, width: side)),
                    ),
                    PositionedDirectional(
                      bottom: h * .06,
                      start: box.maxWidth * .03,
                      child: Transform.rotate(angle: -.17, child: CardArt(role: look.left, width: side)),
                    ),
                    Positioned(bottom: h * .07, child: CardArt(role: look.front, width: front)),
                    PositionedDirectional(
                      top: 10,
                      start: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(99)),
                        child: Text(s.t('players.count', {'n': n}), style: const TextStyle(color: C.onGold, fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]);
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 12, 11),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.mode(look.mode), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                // Always two lines high, so every card's art has the same size.
                SizedBox(
                  height: MediaQuery.textScalerOf(context).scale(12) * 1.5 * 2 + 2,
                  child: Text(s.modeLine(look.mode), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFB9B0A0))),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
