import 'dart:math';

import 'package:flutter/material.dart';

import '../app/sfx.dart';
import '../app/state.dart';
import '../engine/engine.dart';
import '../l10n/strings.dart';
import '../shop/catalog.dart';
import 'theme.dart';

/// True when animations should be skipped (setting or system preference).
bool reduceMotion(BuildContext context) =>
    AppScope.of(context).settings.reduceMotion || MediaQuery.maybeDisableAnimationsOf(context) == true;

Duration motion(BuildContext context, int ms) => reduceMotion(context) ? Duration.zero : Duration(milliseconds: ms);

/// Page body: safe area, comfortable width on tablets/desktop, side gutters.
class Body extends StatelessWidget {
  const Body({super.key, required this.child, this.maxWidth = 560, this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16)});
  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Ignores a second tap that comes within [gap] (prevents accidental
/// double taps from skipping a player during the deal).
class _Debounce {
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  bool pass([Duration gap = const Duration(milliseconds: 450)]) {
    final now = DateTime.now();
    if (now.difference(_last) < gap) return false;
    _last = now;
    return true;
  }
}

class GoldButton extends StatefulWidget {
  const GoldButton({super.key, required this.label, this.onPressed, this.secondary = false, this.icon, this.sub, this.sound = true});
  final String label;
  final String? sub;
  final VoidCallback? onPressed;
  final bool secondary;
  final IconData? icon;
  final bool sound;

  @override
  State<GoldButton> createState() => _GoldButtonState();
}

class _GoldButtonState extends State<GoldButton> {
  final _debounce = _Debounce();

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bg = widget.secondary ? Colors.transparent : (enabled ? C.gold : C.disabled);
    final fg = widget.secondary ? C.goldText : (enabled ? C.onGold : const Color(0xFF8A86A0));
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Space.radius),
          side: widget.secondary ? const BorderSide(color: C.line) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled
              ? () {
                  if (!_debounce.pass()) return;
                  if (widget.sound) Sounds.play(Sfx.tap);
                  widget.onPressed!();
                }
              : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[Icon(widget.icon, color: fg, size: 22), const SizedBox(width: 8)],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w800, height: 1.3)),
                        if (widget.sub != null)
                          Text(widget.sub!, textAlign: TextAlign.center, style: TextStyle(color: fg.withValues(alpha: .85), fontSize: 12.5, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square 48×48 icon button with the gold outline.
class IconBox extends StatelessWidget {
  const IconBox({super.key, required this.icon, required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Material(
          color: C.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: C.line)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Sounds.play(Sfx.tap);
              onPressed();
            },
            child: SizedBox(width: 48, height: 48, child: Icon(icon, color: C.goldText, size: 22, semanticLabel: label)),
          ),
        ),
      );
}

/// A card's art. [role] null = the card back.
class CardArt extends StatelessWidget {
  const CardArt({super.key, this.role, required this.width, this.glow, this.back, this.theme});
  final Role? role;
  final double width;
  final Color? glow;

  /// Shop previews pass a back or theme id; otherwise the equipped one is used.
  final String? back;
  final String? theme;

  static const ratio = 420 / 300;

  @override
  Widget build(BuildContext context) {
    final wallet = context.dependOnInheritedWidgetOfExactType<AppScope>()?.notifier?.wallet;
    final asset = role == null
        ? backAsset(back ?? wallet?.back ?? 'back.classic')
        : faceAsset(theme ?? wallet?.theme ?? 'theme.gold', role!.art);
    return Container(
        width: width,
        height: width * ratio,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(width * .075),
          boxShadow: [
            BoxShadow(color: (glow ?? Colors.black).withValues(alpha: glow == null ? .5 : .45), blurRadius: width * .12, offset: Offset(0, width * .05)),
          ],
        ),
        child: Image.asset(
          asset,
          width: width,
          height: width * ratio,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
      );
  }
}

/// Turns between two faces around the vertical axis.
class FlipSwitcher extends StatelessWidget {
  const FlipSwitcher({super.key, required this.child, this.duration = const Duration(milliseconds: 220)});
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(alignment: Alignment.center, children: [...previous, ?current]),
        transitionBuilder: (child, anim) => AnimatedBuilder(
          animation: anim,
          child: child,
          builder: (context, child) {
            final isIncoming = child!.key == this.child.key;
            // Incoming turns in from 90°, outgoing turns away to 90°.
            final angle = (1 - anim.value) * pi / 2;
            return Opacity(
              opacity: anim.value < .02 ? 0 : 1,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, .0012)
                  ..rotateY(isIncoming ? angle : -angle),
                child: child,
              ),
            );
          },
        ),
        child: child,
      );
}

/// A player's round badge with their initial.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.player, this.size = 36});
  final Player player;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = C.avatars[player.avatar % C.avatars.length];
    final name = player.name.trim();
    final words = name.split(RegExp(r'\s+'));
    // Default names ("Player 3", "بازیکن ۳") show their number.
    final initial = name.isEmpty
        ? '?'
        : (words.length > 1 && RegExp(r'^[0-9۰-۹०-९]+$').hasMatch(words.last) ? words.last : name.characters.first);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: C.goldLight.withValues(alpha: .7), width: 1.5),
      ),
      child: Text(initial, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * .44, height: 1.1)),
    );
  }
}

/// Rule summary of the current mode, always visible; expands to the full rules.
class RuleBanner extends StatefulWidget {
  const RuleBanner({super.key, required this.scenario});
  final Scenario scenario;

  @override
  State<RuleBanner> createState() => _RuleBannerState();
}

class _RuleBannerState extends State<RuleBanner> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Container(
      decoration: BoxDecoration(
        color: C.surface,
        borderRadius: BorderRadius.circular(Space.radius),
        border: Border.all(color: C.line),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Icon(Icons.info_outline_rounded, size: 18, color: C.goldText),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${s.t('rule.title')} · ${s.mode(widget.scenario.mode)}',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: C.goldText)),
            ),
          ]),
          const SizedBox(height: 6),
          Text(s.ruleSummary(widget.scenario), style: const TextStyle(fontSize: 13.5, height: 1.7, color: Color(0xFFE6DDCB))),
          AnimatedSize(
            duration: motion(context, 200),
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final line in s.fullRules(widget.scenario))
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Padding(padding: EdgeInsets.only(top: 9), child: Icon(Icons.circle, size: 5, color: C.gold)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(line, style: const TextStyle(fontSize: 13, height: 1.7, color: C.muted))),
                            ]),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => setState(() => open = !open),
              style: TextButton.styleFrom(foregroundColor: C.gold, padding: EdgeInsets.zero, minimumSize: const Size(48, 40)),
              child: Text(open ? s.t('rule.less') : s.t('rule.more'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gold crown mark used in headers.
class CrownMark extends StatelessWidget {
  const CrownMark({super.key, this.width = 64});
  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(width, width * 30 / 64), painter: _CrownPainter());
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 64, sy = size.height / 30;
    final p = Path()
      ..moveTo(8 * sx, 28 * sy)
      ..lineTo(5 * sx, 6 * sy)
      ..lineTo(18 * sx, 17 * sy)
      ..lineTo(32 * sx, 0)
      ..lineTo(46 * sx, 17 * sy)
      ..lineTo(59 * sx, 6 * sy)
      ..lineTo(56 * sx, 28 * sy)
      ..close();
    canvas.drawPath(p, Paint()..color = C.gold);
    canvas.drawCircle(Offset(32 * sx, 16 * sy), 3.5 * sx, Paint()..color = C.ruby);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Falling confetti for celebrations; draws nothing when motion is reduced.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.colors = const [C.gold, C.goldLight, C.ivory, Color(0xFF5ED1C4), C.joker], this.count = 70});
  final List<Color> colors;
  final int count;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final List<_Bit> bits;

  @override
  void initState() {
    super.initState();
    final r = Random();
    bits = List.generate(widget.count, (i) => _Bit(r.nextDouble(), r.nextDouble() * .35, .55 + r.nextDouble() * .6, r.nextDouble() * 6, widget.colors[i % widget.colors.length], r.nextDouble() * .4 - .2));
    c.forward();
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _ConfettiPainter(c, bits), size: Size.infinite)));
  }
}

class _Bit {
  _Bit(this.x, this.delay, this.speed, this.spin, this.color, this.drift);
  final double x, delay, speed, spin, drift;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.anim, this.bits) : super(repaint: anim);
  final Animation<double> anim;
  final List<_Bit> bits;

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    for (final b in bits) {
      final p = ((t - b.delay) / (1 - b.delay)).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final y = -20 + p * b.speed * (size.height + 40) * 1.2;
      final x = (b.x + b.drift * p) * size.width + sin(p * 12 + b.spin) * 14;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p * b.spin * 4);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -2.5, 10, 5), const Radius.circular(1.5)),
          Paint()..color = b.color.withValues(alpha: 1 - p * .6));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

Future<bool> confirm(BuildContext context, String title, {String? body, String? yes, String? no}) async {
  final s = S.of(context);
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      content: body == null ? null : Text(body, style: const TextStyle(color: C.muted, height: 1.6)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(no ?? s.t('no'), style: const TextStyle(color: C.muted))),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(yes ?? s.t('yes'), style: const TextStyle(color: C.gold, fontWeight: FontWeight.w800))),
      ],
    ),
  );
  return r ?? false;
}

/// A small header row: back button, centered title, optional trailing.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.onBack, this.trailing});
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(children: [
      IconBox(
        icon: Icons.arrow_back_rounded, // mirrored by Flutter in RTL
        label: s.t('back'),
        onPressed: onBack ?? () => Navigator.maybePop(context),
      ),
      Expanded(
        child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: C.ivory)),
      ),
      SizedBox(width: 48, child: trailing),
    ]);
  }
}

/// The game's gold coin (a crown stamped on a coin).
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _CoinPainter());
}

class _CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.goldLight, C.gold, Color(0xFF8A6424)]).createShader(Offset.zero & size));
    canvas.drawCircle(c, r * .78, Paint()..color = const Color(0xFF8A6424)..style = PaintingStyle.stroke..strokeWidth = r * .1);
    final s = r / 10;
    final crown = Path()
      ..moveTo(c.dx - 5 * s, c.dy + 3.5 * s)
      ..lineTo(c.dx - 5.5 * s, c.dy - 3 * s)
      ..lineTo(c.dx - 2.2 * s, c.dy - .5 * s)
      ..lineTo(c.dx, c.dy - 4.5 * s)
      ..lineTo(c.dx + 2.2 * s, c.dy - .5 * s)
      ..lineTo(c.dx + 5.5 * s, c.dy - 3 * s)
      ..lineTo(c.dx + 5 * s, c.dy + 3.5 * s)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFF7E5A1E));
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Coin balance; opens the shop when tapped.
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.coins, required this.onTap, required this.label});
  final int coins;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Semantics(
      button: true,
      label: '$label, ${s.t('shop.coins', {'n': coins})}',
      child: Material(
        color: C.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99), side: const BorderSide(color: C.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const CoinIcon(size: 22),
              const SizedBox(width: 8),
              Text(s.n(coins), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: C.goldLight)),
              const SizedBox(width: 8),
              const Icon(Icons.storefront_outlined, size: 18, color: C.goldText),
            ]),
          ),
        ),
      ),
    );
  }
}
