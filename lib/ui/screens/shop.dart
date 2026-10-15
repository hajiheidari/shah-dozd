import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/sfx.dart';
import '../../app/state.dart';
import '../../engine/engine.dart';
import '../../l10n/penalties.dart';
import '../../l10n/strings.dart';
import '../../shop/ads.dart';
import '../../shop/catalog.dart';
import '../../shop/wallet.dart';
import '../theme.dart';
import '../widgets.dart';

/// Coins shop: card backs, card frames and penalty packs. Coins come from
/// sharing the game and from rewarded ads the player chooses to watch.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool busy = false;

  @override
  void initState() {
    super.initState();
    rewardedAds.preload();
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text, textAlign: TextAlign.center), duration: const Duration(seconds: 2)));
  }

  Future<void> _watchAd() async {
    final s = S.of(context);
    final app = AppScope.read(context);
    if (!app.wallet.canWatchAd()) return _toast(s.t('shop.limit'));
    setState(() => busy = true);
    final ok = await rewardedAds.show();
    if (!mounted) return;
    setState(() => busy = false);
    if (!ok) return _toast(s.t('shop.adFail'));
    final got = app.wallet.rewardAd();
    app.saveWallet();
    Sounds.play(Sfx.win);
    _toast(s.t('shop.got', {'n': got}));
  }

  Future<void> _share() async {
    final s = S.of(context);
    final app = AppScope.read(context);
    final url = 'https://espadna.com/shahdozd-app/${s.lang == Lang.fa ? 'fa/' : s.lang == Lang.hi ? 'hi/' : ''}';
    final text = s.t('share.text', {'url': url});
    var shared = false;
    try {
      final r = await SharePlus.instance.share(ShareParams(text: text, subject: s.t('app.title')));
      shared = r.status == ShareResultStatus.success;
      if (r.status == ShareResultStatus.unavailable) {
        await Clipboard.setData(ClipboardData(text: text));
        shared = true;
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      shared = true;
    }
    if (!mounted || !shared) return;
    final got = app.wallet.rewardShare();
    app.saveWallet();
    if (got > 0) {
      Sounds.play(Sfx.win);
      _toast(s.t('shop.got', {'n': got}));
    } else {
      _toast(s.t('shop.limit'));
    }
  }

  Future<void> _tap(ShopItem item) async {
    final s = S.of(context);
    final app = AppScope.read(context);
    final w = app.wallet;
    if (w.owns(item.id)) {
      if (item.kind != ItemKind.pack && w.equip(item.id)) {
        app.saveWallet();
        Sounds.play(Sfx.flip);
      }
      return;
    }
    if (w.coins < item.price) return _toast(s.t('shop.notEnough'));
    final name = item.name[s.lang.index];
    if (!await confirm(context, s.t('shop.confirm', {'item': name, 'p': item.price}))) return;
    if (w.buy(item.id)) {
      if (item.kind != ItemKind.pack) w.equip(item.id);
      app.saveWallet();
      Sounds.play(Sfx.reveal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppScope.of(context);
    final w = app.wallet;
    Widget title(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: C.goldText)),
        );
    return Scaffold(
      body: Body(
        maxWidth: 720,
        child: Column(children: [
          TopBar(title: s.t('shop.title')),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: [
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF16352B), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x669FE0B8))),
                child: Row(children: [
                  const Icon(Icons.volunteer_activism_outlined, color: C.success, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.t('shop.noMoney'), style: const TextStyle(fontSize: 13.5, height: 1.6, color: Color(0xFFDDF5E6)))),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(Space.radiusL), border: Border.all(color: C.line)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const CoinIcon(size: 30),
                    const SizedBox(width: 10),
                    Text(s.n(w.coins), style: F.title(s.lang, 32, color: C.goldLight)),
                  ]),
                  const SizedBox(height: 12),
                  Text(s.t('shop.earn'), style: const TextStyle(fontSize: 13, color: C.muted)),
                  const SizedBox(height: 8),
                  if (rewardedAds.supported) ...[
                    GoldButton(
                      label: s.t('shop.watch'),
                      sub: w.canWatchAd() ? s.t('shop.reward', {'n': Wallet.adReward, 'k': Wallet.adsPerDay - w.adsToday}) : s.t('shop.limit'),
                      icon: Icons.ondemand_video_rounded,
                      onPressed: busy || !w.canWatchAd() ? null : _watchAd,
                    ),
                    const SizedBox(height: 8),
                  ],
                  GoldButton(
                    label: s.t('shop.share'),
                    sub: w.canShare() ? s.t('shop.reward', {'n': Wallet.shareReward, 'k': Wallet.sharesPerDay - w.sharesToday}) : s.t('shop.limit'),
                    icon: Icons.ios_share_rounded,
                    secondary: true,
                    onPressed: _share,
                  ),
                ]),
              ),
              title(s.t('shop.backs')),
              _Grid(children: [
                for (final i in shopItems.where((i) => i.kind == ItemKind.back))
                  _ItemTile(item: i, wallet: w, preview: CardArt(back: i.id, width: 92), onTap: () => _tap(i)),
              ]),
              title(s.t('shop.themes')),
              if (w.deck != 'deck.classic')
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(s.t('shop.deckNote'), style: const TextStyle(fontSize: 12.5, color: C.faint)),
                ),
              _Grid(children: [
                for (final i in shopItems.where((i) => i.kind == ItemKind.theme))
                  _ItemTile(item: i, wallet: w, preview: CardArt(role: Role.king, theme: i.id, width: 92), onTap: () => _tap(i)),
              ]),
              title(s.t('shop.decks')),
              _Grid(children: [
                for (final i in shopItems.where((i) => i.kind == ItemKind.deck))
                  _ItemTile(item: i, wallet: w, preview: CardArt(role: Role.joker, deck: i.id, width: 92), onTap: () => _tap(i)),
              ]),
              title(s.t('shop.packs')),
              for (final i in shopItems.where((i) => i.kind == ItemKind.pack))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PackTile(item: i, wallet: w, onTap: () => _tap(i)),
                ),
              const SizedBox(height: 8),
              Text(s.t('shop.note'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: C.faint)),
              const SizedBox(height: 16),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 10, runSpacing: 12, alignment: WrapAlignment.start, children: children);
}

String _priceLabel(S s, ShopItem item, Wallet w) {
  if (w.isEquipped(item.id)) return s.t('shop.equipped');
  if (w.owns(item.id)) return item.kind == ItemKind.pack ? s.t('shop.owned') : s.t('shop.equip');
  return item.free ? s.t('shop.free') : s.n(item.price);
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.wallet, required this.preview, required this.onTap});
  final ShopItem item;
  final Wallet wallet;
  final Widget preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final equipped = wallet.isEquipped(item.id);
    final owned = wallet.owns(item.id);
    return Semantics(
      button: true,
      selected: equipped,
      label: item.name[s.lang.index],
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 112,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          decoration: BoxDecoration(
            color: C.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: equipped ? C.goldLight : C.lineSoft, width: equipped ? 2 : 1),
          ),
          child: Column(children: [
            preview,
            const SizedBox(height: 8),
            Text(item.name[s.lang.index], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _Price(label: _priceLabel(s, item, wallet), coin: !owned && !item.free, highlight: equipped),
          ]),
        ),
      ),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.item, required this.wallet, required this.onTap});
  final ShopItem item;
  final Wallet wallet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final count = penalties.where((p) => p.pack == item.pack).length;
    final sample = penalties.firstWhere((p) => p.pack == item.pack).text[s.lang.index];
    final owned = wallet.owns(item.id);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: owned ? C.line : C.lineSoft)),
        child: Row(children: [
          const CardArt(role: Role.executioner, width: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.name[s.lang.index], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              Text(s.t('shop.packCount', {'n': count}), style: const TextStyle(fontSize: 12, color: C.gold)),
              const SizedBox(height: 4),
              Text(sample, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.5, color: C.muted)),
            ]),
          ),
          const SizedBox(width: 8),
          _Price(label: _priceLabel(s, item, wallet), coin: !owned, highlight: owned),
        ]),
      ),
    );
  }
}

class _Price extends StatelessWidget {
  const _Price({required this.label, required this.coin, required this.highlight});
  final String label;
  final bool coin;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: highlight ? C.gold : C.night, borderRadius: BorderRadius.circular(99), border: Border.all(color: C.line)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (coin) ...[const CoinIcon(size: 14), const SizedBox(width: 4)],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: highlight ? C.onGold : C.goldLight)),
            ),
          ),
        ]),
      );
}
