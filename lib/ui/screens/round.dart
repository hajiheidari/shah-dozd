import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../app/privacy.dart';
import '../../app/sfx.dart';
import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/strings.dart';
import '../theme.dart';
import '../widgets.dart';
import '../../l10n/penalties.dart';
import '../../shop/catalog.dart';
import 'champion.dart';
import 'scoreboard.dart';
import 'shop.dart';

enum _Phase { shuffle, handover, reveal, announce, guess, result }

/// One round of the current tournament, from the shuffle to the scores.
///
/// Privacy rules (see docs/ARCHITECTURE.md › Hidden roles):
/// * a role is drawn only while the holder presses the card;
/// * there is no way back to a previous player;
/// * when the app goes to the background during the deal, everything is
///   covered and the current player must confirm their name again;
/// * the deal lives only in memory until the round is resolved.
class RoundScreen extends StatefulWidget {
  const RoundScreen({super.key});

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> with WidgetsBindingObserver {
  late Tournament t;
  late Scenario scenario;
  late Map<String, Role> deal;
  _Phase phase = _Phase.shuffle;
  int seat = 0;
  bool holding = false;
  bool seen = false;
  bool covered = false;
  final List<String> picks = [];
  RoundOutcome? outcome;
  Timer? _shuffleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _newRound();
    }
  }

  void _newRound() {
    t = AppScope.read(context).tournament!;
    scenario = t.scenario;
    deal = dealRoles([for (final p in t.players) p.id], scenario);
    seat = 0;
    holding = false;
    seen = false;
    picks.clear();
    outcome = null;
    phase = _Phase.shuffle;
    Sounds.play(Sfx.shuffle);
    _shuffleTimer?.cancel();
    _shuffleTimer = Timer(motion(context, 1300), () {
      if (mounted && phase == _Phase.shuffle) setState(() => phase = _Phase.handover);
    });
  }

  @override
  void dispose() {
    SecureScreen.set(false);
    _shuffleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hide secrets before the OS takes the app-switcher snapshot.
    if (state != AppLifecycleState.resumed && (phase == _Phase.reveal || phase == _Phase.handover)) {
      setState(() {
        holding = false;
        covered = true;
      });
    }
  }

  Player get current => t.players[seat];

  void _confirmIdentity() {
    setState(() {
      phase = _Phase.reveal;
      seen = false;
      holding = false;
    });
  }

  void _doneSeeing() {
    if (!seen) return;
    setState(() {
      holding = false;
      if (seat < t.players.length - 1) {
        seat++;
        phase = _Phase.handover;
      } else {
        phase = _Phase.announce;
        Sounds.play(Sfx.reveal);
      }
    });
  }

  void _togglePick(String id) {
    setState(() {
      if (picks.contains(id)) {
        picks.remove(id);
      } else if (picks.length < scenario.picks) {
        picks.add(id);
      } else if (scenario.picks == 1) {
        picks
          ..clear()
          ..add(id);
      }
    });
    Sounds.play(Sfx.tap);
  }

  void _resolve() {
    if (picks.length != scenario.picks) return;
    final app = AppScope.read(context);
    final o = t.play(deal, List.of(picks));
    app.saveTournament();
    setState(() {
      outcome = o;
      phase = _Phase.result;
    });
    Sounds.play(Sfx.flip);
    Future.delayed(motion(context, 650), () {
      if (!mounted) return;
      if (o.perfectCatch) {
        Sounds.play(Sfx.perfect);
      } else if (o.jokerFooledGuesser) {
        Sounds.play(Sfx.joker);
      } else {
        Sounds.play(o.guesserWins ? Sfx.win : Sfx.lose);
      }
    });
  }

  void _next() {
    if (t.isFinished) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const ChampionScreen()));
      return;
    }
    setState(_newRound);
  }

  Future<void> _leave() async {
    final s = S.of(context);
    if (phase == _Phase.result) {
      Navigator.of(context).pop();
      return;
    }
    final ok = await confirm(context, s.t('exit.q'), body: s.t('exit.sub'));
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    SecureScreen.set(phase.index <= _Phase.reveal.index);
    final Widget body;
    if (covered) {
      body = _Cover(onTap: () => setState(() {
            covered = false;
            if (phase == _Phase.reveal) phase = _Phase.handover;
          }));
    } else {
      body = switch (phase) {
        _Phase.shuffle => _ShuffleView(count: t.players.length),
        _Phase.handover => _HandoverView(player: current, seat: seat, total: t.players.length, onConfirm: _confirmIdentity),
        _Phase.reveal => _RevealView(
            player: current,
            seat: seat,
            total: t.players.length,
            role: deal[current.id]!,
            scenario: scenario,
            holding: holding,
            seen: seen,
            last: seat == t.players.length - 1,
            onHold: (h) => setState(() {
              holding = h;
              if (h) {
                seen = true;
                Sounds.buzz();
              }
            }),
            onDone: _doneSeeing,
          ),
        _Phase.announce => _AnnounceView(t: t, scenario: scenario, deal: deal, onReady: () => setState(() => phase = _Phase.guess)),
        _Phase.guess => _GuessView(t: t, scenario: scenario, deal: deal, picks: picks, onToggle: _togglePick, onReveal: _resolve),
        _Phase.result => _ResultView(t: t, scenario: scenario, deal: deal, outcome: outcome!, onNext: _next),
      };
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        body: Body(
          child: Column(children: [
            Row(children: [
              IconBox(icon: Icons.close_rounded, label: s.t('close'), onPressed: _leave),
              Expanded(
                child: Text(
                  phase.index <= _Phase.reveal.index
                      ? '${s.t('deal.title')} · ${s.t('deal.progress', {'i': seat + 1, 'n': t.players.length})}'
                      : s.t('result.round', {'mode': s.mode(t.mode), 'r': outcome == null ? t.roundNumber : t.rounds.length}),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: C.muted),
                ),
              ),
              if (phase == _Phase.result || phase == _Phase.guess || phase == _Phase.announce)
                IconBox(
                  icon: Icons.leaderboard_outlined,
                  label: s.t('board.title'),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScoreboardScreen(readOnly: true))),
                )
              else
                const SizedBox(width: 48),
            ]),
            if (phase.index <= _Phase.reveal.index) ...[
              const SizedBox(height: 12),
              _Progress(done: phase == _Phase.shuffle ? 0 : seat + (phase == _Phase.reveal && seen ? 1 : 0), total: t.players.length),
            ],
            const SizedBox(height: 8),
            Expanded(child: AnimatedSwitcher(duration: motion(context, 220), child: KeyedSubtree(key: ValueKey('$phase/$seat/$covered'), child: body))),
          ]),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});
  final int done, total;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: motion(context, 200),
              height: 5,
              decoration: BoxDecoration(
                color: i < done ? C.gold : (i == done ? C.goldLight.withValues(alpha: .55) : const Color(0xFF2A2E5E)),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ]);
}

class _Cover extends StatelessWidget {
  const _Cover({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CardArt(width: 150),
          const SizedBox(height: 20),
          Text(s.t('deal.hidden'), style: F.title(s.lang, 28)),
          const SizedBox(height: 6),
          Text(s.t('deal.hidden.sub'), style: const TextStyle(color: C.muted)),
        ]),
      ),
    );
  }
}

class _ShuffleView extends StatefulWidget {
  const _ShuffleView({required this.count});
  final int count;

  @override
  State<_ShuffleView> createState() => _ShuffleViewState();
}

class _ShuffleViewState extends State<_ShuffleView> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..forward();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(
        height: 260,
        child: AnimatedBuilder(
          animation: c,
          builder: (context, _) {
            final v = Curves.easeInOutCubic.transform(c.value);
            final spread = sin(v * pi); // fan out, then gather
            return Stack(alignment: Alignment.center, children: [
              for (var i = 0; i < widget.count; i++)
                Transform.translate(
                  offset: Offset((i - (widget.count - 1) / 2) * 34 * spread + sin(v * pi * 3 + i) * 10 * spread, -spread * 10 * cos(i.toDouble())),
                  child: Transform.rotate(angle: (i - (widget.count - 1) / 2) * .16 * spread + (i.isEven ? 1 : -1) * .06 * spread, child: const CardArt(width: 130)),
                ),
            ]);
          },
        ),
      ),
      const SizedBox(height: 24),
      Text(s.t('deal.shuffling'), style: const TextStyle(fontSize: 16, color: C.muted)),
    ]);
  }
}

class _HandoverView extends StatelessWidget {
  const _HandoverView({required this.player, required this.seat, required this.total, required this.onConfirm});
  final Player player;
  final int seat, total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Column(children: [
      const Spacer(),
      Avatar(player: player, size: 84),
      const SizedBox(height: 18),
      Text(s.t('deal.give', {'name': player.name}), textAlign: TextAlign.center, style: F.title(s.lang, 32)),
      const SizedBox(height: 8),
      Text(s.t('deal.give.sub'), style: const TextStyle(fontSize: 15, color: C.muted)),
      const Spacer(),
      GoldButton(label: s.t('deal.iam', {'name': player.name}), icon: Icons.front_hand_outlined, onPressed: onConfirm),
    ]);
  }
}

class _RevealView extends StatelessWidget {
  const _RevealView({
    required this.player,
    required this.seat,
    required this.total,
    required this.role,
    required this.scenario,
    required this.holding,
    required this.seen,
    required this.last,
    required this.onHold,
    required this.onDone,
  });
  final Player player;
  final int seat, total;
  final Role role;
  final Scenario scenario;
  final bool holding, seen, last;
  final ValueChanged<bool> onHold;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LayoutBuilder(builder: (context, box) {
      final cardW = min(box.maxWidth * .68, (box.maxHeight - 270) / CardArt.ratio).clamp(140.0, 300.0);
      return Column(children: [
        Text(s.t('deal.turn'), style: const TextStyle(fontSize: 14, color: C.muted)),
        Text(player.name, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: F.title(s.lang, 36)),
        const SizedBox(height: 4),
        Text(s.t('deal.hold'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.5, height: 1.65, color: C.muted)),
        const Spacer(),
        Semantics(
          label: s.t('deal.cardA11y'),
          button: true,
          child: Listener(
            key: const Key('roleCard'),
            onPointerDown: (_) => onHold(true),
            onPointerUp: (_) => onHold(false),
            onPointerCancel: (_) => onHold(false),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: SizedBox(
                width: cardW,
                height: cardW * CardArt.ratio,
                child: FlipSwitcher(
                  duration: motion(context, 170),
                  child: holding
                      ? Stack(key: const ValueKey('face'), alignment: Alignment.bottomCenter, children: [
                          CardArt(role: role, width: cardW, glow: role == Role.joker ? C.joker : C.gold),
                          Padding(
                            padding: EdgeInsets.only(bottom: cardW * .06),
                            child: Text(s.role(role, scenario.mode),
                                style: F.title(s.lang, cardW * .13, color: C.goldLight).copyWith(shadows: const [Shadow(color: Colors.black, blurRadius: 10)])),
                          ),
                        ])
                      : Stack(key: const ValueKey('back'), alignment: Alignment.bottomCenter, children: [
                          CardArt(width: cardW),
                          Padding(
                            padding: EdgeInsets.only(bottom: cardW * .14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(color: C.night, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.line)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.touch_app_outlined, size: 16, color: C.goldText),
                                const SizedBox(width: 6),
                                Text(s.t('deal.holdLabel'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.goldText)),
                              ]),
                            ),
                          ),
                        ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: Text(
            holding ? s.roleHint(role, scenario) : s.t('deal.private'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.6, color: holding ? const Color(0xFFE6DDCB) : const Color(0xFF8F8878)),
          ),
        ),
        const Spacer(),
        GoldButton(
          label: seen ? s.t(last ? 'deal.doneLast' : 'deal.done') : s.t('deal.seeFirst'),
          onPressed: seen && !holding ? onDone : null,
        ),
      ]);
    });
  }
}

class _PublicChip extends StatelessWidget {
  const _PublicChip({required this.role, required this.player, required this.mode, this.highlight = false});
  final Role role;
  final Player player;
  final ModeId mode;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? C.gold.withValues(alpha: .7) : C.lineSoft),
      ),
      child: Row(children: [
        CardArt(role: role, width: 40),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.role(role, mode), style: const TextStyle(fontSize: 12, color: C.faint)),
            Text(player.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ),
      ]),
    );
  }
}

class _AnnounceView extends StatelessWidget {
  const _AnnounceView({required this.t, required this.scenario, required this.deal, required this.onReady});
  final Tournament t;
  final Scenario scenario;
  final Map<String, Role> deal;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final king = t.player(holderOf(deal, Role.king));
    final guesser = t.player(holderOf(deal, scenario.guesser));
    return LayoutBuilder(builder: (context, box) {
      final w = min(box.maxWidth * .42, (box.maxHeight - 260) / CardArt.ratio).clamp(110.0, 220.0);
      Widget col(Role r, Player p, int delay) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: motion(context, 500 + delay),
            curve: Curves.easeOutBack,
            builder: (context, v, child) => Opacity(opacity: v.clamp(0, 1), child: Transform.translate(offset: Offset(0, (1 - v) * 30), child: child)),
            child: Column(children: [
              CardArt(role: r, width: w, glow: C.gold),
              const SizedBox(height: 8),
              FittedBox(fit: BoxFit.scaleDown, child: Text(s.role(r, scenario.mode), maxLines: 1, style: F.title(s.lang, 24))),
              Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ]),
          );
      return Column(children: [
        Text(s.t('announce.title'), textAlign: TextAlign.center, style: F.title(s.lang, 30)),
        const Spacer(),
        Row(children: [Expanded(child: col(Role.king, king, 0)), const SizedBox(width: 12), Expanded(child: col(scenario.guesser, guesser, 200))]),
        const Spacer(),
        GoldButton(label: s.t('announce.ready'), sub: s.t('announce.go', {'name': guesser.name}), onPressed: onReady),
      ]);
    });
  }
}

class _GuessView extends StatelessWidget {
  const _GuessView({required this.t, required this.scenario, required this.deal, required this.picks, required this.onToggle, required this.onReveal});
  final Tournament t;
  final Scenario scenario;
  final Map<String, Role> deal;
  final List<String> picks;
  final ValueChanged<String> onToggle;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final guesser = t.player(holderOf(deal, scenario.guesser));
    final king = t.player(holderOf(deal, Role.king));
    final cands = [for (final p in t.players) if (candidatesOf(deal, scenario).contains(p.id)) p];
    final title = scenario.picks == 2
        ? s.t('guess.title2', {'name': guesser.name})
        : s.t('guess.title', {'name': guesser.name, 'thief': s.role(Role.thief, scenario.mode)});
    return LayoutBuilder(builder: (context, box) {
      final cols = cands.length <= 2 ? 2 : (box.maxWidth > 520 ? cands.length : 2);
      final rows = (cands.length / cols).ceil();
      return Column(children: [
        Expanded(
          child: ListView(children: [
            RuleBanner(scenario: scenario),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _PublicChip(role: Role.king, player: king, mode: scenario.mode)),
              const SizedBox(width: 10),
              Expanded(child: _PublicChip(role: scenario.guesser, player: guesser, mode: scenario.mode, highlight: true)),
            ]),
            const SizedBox(height: 14),
            Text(title, textAlign: TextAlign.center, style: F.title(s.lang, 26)),
            Text(s.t('guess.count', {'k': picks.length, 'n': scenario.picks}), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: C.muted)),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, inner) {
              final w = min((inner.maxWidth - (cols - 1) * 16) / cols - 8, 150.0) * (rows > 1 ? .76 : 1);
              return Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final p in cands)
                    _Pickable(key: Key('pick-${p.id}'), player: p, width: w, selected: picks.contains(p.id), onTap: () => onToggle(p.id)),
                ],
              );
            }),
            const SizedBox(height: 12),
          ]),
        ),
        GoldButton(label: s.t('guess.reveal'), icon: Icons.visibility_outlined, onPressed: picks.length == scenario.picks ? onReveal : null),
      ]);
    });
  }
}

class _Pickable extends StatelessWidget {
  const _Pickable({super.key, required this.player, required this.width, required this.selected, required this.onTap});
  final Player player;
  final double width;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: player.name,
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedContainer(
                duration: motion(context, 180),
                transform: Matrix4.translationValues(0, selected ? -6 : 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(width * .08),
                  boxShadow: selected ? [const BoxShadow(color: C.goldLight, spreadRadius: 3), BoxShadow(color: C.gold.withValues(alpha: .35), blurRadius: 24)] : null,
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  CardArt(width: width),
                  if (selected)
                    PositionedDirectional(
                      top: -8,
                      start: -8,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(color: C.gold, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 18, color: C.onGold),
                      ),
                    ),
                  Positioned.fill(
                    child: Center(child: Avatar(player: player, size: width * .3)),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: width + 16,
                child: Text(player.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: selected ? C.goldLight : const Color(0xFFE6DDCB))),
              ),
            ]),
          ),
        ),
      );
}

class _ResultView extends StatefulWidget {
  const _ResultView({required this.t, required this.scenario, required this.deal, required this.outcome, required this.onNext});
  final Tournament t;
  final Scenario scenario;
  final Map<String, Role> deal;
  final RoundOutcome outcome;
  final VoidCallback onNext;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  bool flipped = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(motion(context, 380), () {
        if (mounted) setState(() => flipped = true);
      });
    });
  }

  String? _loser() {
    final o = widget.outcome;
    if (!o.guesserWins) return holderOf(widget.deal, widget.scenario.guesser);
    return o.picks.firstWhere((id) => widget.deal[id]!.isThief);
  }

  Future<void> _challenge() async {
    final s = S.of(context);
    final wallet = AppScope.read(context).wallet;
    final loser = widget.t.player(_loser()!);
    final owned = {
      PenaltyPack.base,
      for (final i in shopItems) if (i.pack != null && wallet.owns(i.id)) i.pack!,
    };
    final list = [for (final p in penalties) if (owned.contains(p.pack)) p]..shuffle();
    final morePacks = owned.length < PenaltyPack.values.length;
    var i = 0;
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final p = list[i % list.length];
          return AlertDialog(
            title: Text(s.t('result.challenge.for', {'name': loser.name}), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CardArt(role: p.byExecutioner ? widget.scenario.guard : _loserRole(), width: 84),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: p.byExecutioner ? C.ruby : C.surfaceHi, borderRadius: BorderRadius.circular(99)),
                  child: Text(s.t(p.byExecutioner ? 'penalty.byExec' : 'penalty.byLoser'),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(height: 12),
                Text(p.text[s.lang.index], textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, height: 1.7, color: C.ivory)),
                const SizedBox(height: 10),
                Text(s.t('penalty.safe'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, height: 1.6, color: C.faint)),
                if (morePacks)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
                    },
                    icon: const Icon(Icons.storefront_outlined, size: 18),
                    label: Text(s.t('penalty.more')),
                    style: TextButton.styleFrom(foregroundColor: C.gold),
                  ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => set(() => i++), child: Text(s.t('result.challenge.another'), style: const TextStyle(color: C.muted))),
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.t('result.challenge.done'), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800))),
            ],
          );
        },
      ),
    );
  }

  Role _loserRole() => widget.deal[_loser()!]!;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final t = widget.t;
    final sc = widget.scenario;
    final o = widget.outcome;
    final g = s.role(sc.guesser, sc.mode);
    final thief = s.role(Role.thief, sc.mode);
    final headline = o.guesserWins ? s.t('result.win', {'g': g}) : s.t('result.lose', {'g': g});
    final sub = o.perfectCatch
        ? s.t('result.perfect')
        : o.guesserWins
            ? (sc.thiefCount == 2 ? s.t('result.win.one') : s.t('result.win.sub', {'thief': thief}))
            : (sc.thiefCount == 2 ? s.t('result.lose.two') : s.t('result.lose.sub', {'thief': thief}));
    final totals = t.totals;
    final jokerId = sc.hasJoker ? holderOf(widget.deal, Role.joker) : null;
    final showChallenge = app.settings.challenges && sc.guard == Role.executioner;

    return Stack(children: [
      Column(children: [
        Expanded(
          child: ListView(children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .6, end: 1),
              duration: motion(context, 600),
              curve: Curves.elasticOut,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Column(children: [
                Text(headline, textAlign: TextAlign.center, style: F.title(s.lang, 34, color: o.guesserWins ? C.goldLight : const Color(0xFFF0B7A8))),
                const SizedBox(height: 2),
                Text(sub, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14.5, color: Color(0xFFE6DDCB))),
              ]),
            ),
            const SizedBox(height: 14),
            _PicksRow(t: t, scenario: sc, deal: widget.deal, outcome: o, flipped: flipped),
            if (o.jokerFooledGuesser && jokerId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF2A1236), borderRadius: BorderRadius.circular(14), border: Border.all(color: C.joker.withValues(alpha: .6))),
                child: Row(children: [
                  const Icon(Icons.auto_awesome, color: C.goldLight, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(s.t('result.joker', {'g': g, 'p': s.pts(t.scoring.jokerBonus)}),
                        style: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFFF3DCEA))),
                  ),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            _ScoreTable(t: t, scenario: sc, deal: widget.deal, points: o.points, totals: totals),
            const SizedBox(height: 12),
          ]),
        ),
        if (showChallenge) ...[
          GoldButton(label: s.t('result.challenge', {'guard': s.role(Role.executioner, sc.mode)}), secondary: true, icon: Icons.gavel_rounded, onPressed: _challenge),
          const SizedBox(height: 10),
        ],
        GoldButton(label: t.isFinished ? s.t('result.champion') : s.t('result.next'), icon: t.isFinished ? Icons.emoji_events_outlined : Icons.replay_rounded, onPressed: widget.onNext),
      ]),
      if (flipped && (o.perfectCatch || o.jokerFooledGuesser || o.guesserWins))
        Positioned.fill(
          child: Confetti(
            count: o.perfectCatch ? 110 : 60,
            colors: o.jokerFooledGuesser ? const [C.joker, Color(0xFF7A2CA0), C.goldLight, Color(0xFF5ED1C4)] : const [C.gold, C.goldLight, C.ivory, Color(0xFF5ED1C4)],
          ),
        ),
    ]);
  }
}

class _PicksRow extends StatelessWidget {
  const _PicksRow({required this.t, required this.scenario, required this.deal, required this.outcome, required this.flipped});
  final Tournament t;
  final Scenario scenario;
  final Map<String, Role> deal;
  final RoundOutcome outcome;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return LayoutBuilder(builder: (context, box) {
      final w = min(box.maxWidth / 2 - 24, 150.0);
      return Wrap(alignment: WrapAlignment.center, spacing: 18, runSpacing: 12, children: [
        for (final id in outcome.picks)
          Builder(builder: (context) {
            final r = deal[id]!;
            final joker = r == Role.joker;
            final color = r.isThief ? C.goldLight : (joker ? C.joker : const Color(0xFF8F8DA8));
            final tag = r.isThief ? s.t('result.caught') : (joker ? s.t('result.fooled') : s.t('result.innocent'));
            Widget card = FlipSwitcher(
              duration: motion(context, 420),
              child: flipped ? CardArt(key: ValueKey('f$id'), role: r, width: w, glow: color) : CardArt(key: ValueKey('b$id'), width: w),
            );
            if (joker && flipped) {
              card = TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: motion(context, 1100),
                builder: (context, v, child) => Transform.rotate(
                  angle: sin(v * pi * 6) * (1 - v) * .18,
                  child: Transform.scale(scale: 1 + sin(v * pi) * .12, child: child),
                ),
                child: card,
              );
            }
            return Column(mainAxisSize: MainAxisSize.min, children: [
              Stack(clipBehavior: Clip.none, children: [
                card,
                if (flipped)
                  PositionedDirectional(
                    top: -10,
                    start: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: r.isThief ? C.gold : (joker ? C.joker : C.surfaceHi), borderRadius: BorderRadius.circular(99)),
                      child: Text(tag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: r.isThief ? C.onGold : Colors.white)),
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Text('${t.player(id).name} · ${flipped ? s.role(r, scenario.mode) : (s.rtl ? '؟' : '?')}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ]);
          }),
      ]);
    });
  }
}

class _ScoreTable extends StatelessWidget {
  const _ScoreTable({required this.t, required this.scenario, required this.deal, required this.points, required this.totals});
  final Tournament t;
  final Scenario scenario;
  final Map<String, Role> deal;
  final Map<String, int> points;
  final Map<String, int> totals;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final order = t.standings;
    return Container(
      decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(Space.radius), border: Border.all(color: C.lineSoft)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(child: Text(s.t('result.table'), style: const TextStyle(fontSize: 12, color: C.faint))),
            SizedBox(width: 64, child: Text(s.t('result.thisRound'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: C.faint))),
            SizedBox(width: 64, child: Text(s.t('result.total'), textAlign: TextAlign.end, style: const TextStyle(fontSize: 12, color: C.faint))),
          ]),
        ),
        for (var i = 0; i < order.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x1AD4AE55)))),
            child: Row(children: [
              SizedBox(width: 22, child: Text(s.n(i + 1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: C.gold))),
              Avatar(player: order[i], size: 24),
              const SizedBox(width: 8),
              Flexible(child: Text(order[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700))),
              const SizedBox(width: 6),
              Text(s.role(deal[order[i].id]!, scenario.mode), style: const TextStyle(fontSize: 12, color: C.faint)),
              const Spacer(),
              SizedBox(
                width: 64,
                child: Text(s.pts(points[order[i].id] ?? 0),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: (points[order[i].id] ?? 0) > 0 ? C.success : const Color(0xFF8F8878))),
              ),
              SizedBox(width: 64, child: Text(s.n(totals[order[i].id] ?? 0), textAlign: TextAlign.end, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
            ]),
          ),
      ]),
    );
  }
}
