import 'package:flutter/material.dart';

import '../../app/theme_pack.dart';
import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import '../../services/ad_service.dart';
import '../../services/economy_repository.dart';
import '../../game/skins/arrow_skin.dart';
import '../../widgets/game_ui.dart';
import 'shop_catalog.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.save, required this.onBack});

  final LocalSave save;
  final VoidCallback onBack;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _busy = false;

  ClearwayStrings get strings => ClearwayStrings(widget.save.language);
  EconomyRepository get economy => EconomyRepository(widget.save);

  @override
  Widget build(BuildContext context) {
    const pack = ThemePack.truckArt;
    final ur = widget.save.language == 'ur';
    final offers = shopOffers();
    final coinOffers = offers
        .where((o) => o.kind == ShopOfferKind.coinPurchase)
        .toList();
    final adOffers = offers
        .where((o) => o.kind == ShopOfferKind.freeReward)
        .toList();
    return Scaffold(
      body: GameBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 20, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: widget.onBack,
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      style: IconButton.styleFrom(
                        backgroundColor: pack.ivory.withValues(alpha: 0.1),
                        minimumSize: const Size(44, 44),
                      ),
                      icon: Icon(Icons.arrow_back_rounded, color: pack.ivory),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.shopTitle,
                        style: TextStyle(
                          fontFamily: GameFonts.display,
                          fontSize: 30,
                          color: pack.ivory,
                        ),
                      ),
                    ),
                    _balance(pack),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    for (final offer in adOffers) _adBanner(pack, offer),
                    const SizedBox(height: 8),
                    _heading(pack, strings.shopCoins, ur),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < coinOffers.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(child: _coinCard(pack, coinOffers[i])),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _heading(pack, strings.shopSkins, ur),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (
                            var i = 0;
                            i < ArrowSkinCatalog.all.length;
                            i++
                          ) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _skinTile(pack, ArrowSkinCatalog.all[i]),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balance(ThemePack pack) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: pack.ivory.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.monetization_on_rounded, color: pack.accent, size: 22),
        const SizedBox(width: 8),
        Text(
          '${widget.save.coins}',
          style: TextStyle(
            fontFamily: GameFonts.display,
            fontSize: 20,
            color: pack.accent,
          ),
        ),
      ],
    ),
  );

  Widget _heading(ThemePack pack, String title, bool ur) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 6, right: 6),
    child: Text(
      ur ? title : title.toUpperCase(),
      style: TextStyle(
        color: pack.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: letterSpacingFor(widget.save.language, 2),
      ),
    ),
  );

  /// A small rounded button used for every shop action.
  Widget _pill(
    ThemePack pack, {
    required Widget child,
    required VoidCallback? onTap,
    Color? color,
  }) => Opacity(
    opacity: onTap == null ? 0.5 : 1,
    child: Material(
      color: color ?? pack.accent,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: child,
        ),
      ),
    ),
  );

  TextStyle _pillText(ThemePack pack) => TextStyle(
    fontFamily: GameFonts.display,
    fontSize: 16,
    color: pack.asphalt,
  );

  Widget _price(ThemePack pack, int cost) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.monetization_on_rounded, size: 18, color: pack.asphalt),
      const SizedBox(width: 5),
      Text('$cost', style: _pillText(pack)),
    ],
  );

  Widget _adBanner(ThemePack pack, ShopOffer offer) {
    final remaining = _remaining(offer);
    final color = offer.id == 'ad-hints' ? pack.floralMagenta : pack.turquoise;
    final edge = Color.lerp(color, Colors.black, 0.35)!;
    final canWatch = !_busy && !AdService.adsRemoved && remaining > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, edge],
        ),
        boxShadow: [BoxShadow(offset: const Offset(0, 5), color: edge)],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pack.ivory.withValues(alpha: 0.25),
            ),
            child: Icon(Icons.play_arrow_rounded, color: pack.asphalt),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.shopOfferTitle(offer.id),
                  style: TextStyle(
                    fontFamily: GameFonts.display,
                    fontSize: 22,
                    color: pack.asphalt,
                  ),
                ),
                Text(
                  strings.freeRewardLeft(remaining),
                  style: TextStyle(
                    color: pack.asphalt.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (remaining == 0)
                  Text(
                    strings.dailyOfferReset,
                    style: TextStyle(
                      color: pack.asphalt.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pill(
            pack,
            onTap: canWatch ? () => _claimAdReward(offer) : null,
            child: _busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: pack.asphalt,
                    ),
                  )
                : Text(strings.watchAd, style: _pillText(pack)),
          ),
        ],
      ),
    );
  }

  Widget _coinCard(ThemePack pack, ShopOffer offer) {
    final cost = offer.coinCost ?? 0;
    final insufficient = widget.save.coins < cost;
    final isHint = offer.id == 'hint-pack';
    final color = isHint ? pack.turquoise : pack.floralMagenta;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: pack.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: pack.panelActive, width: 2),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.2),
            ),
            child: Icon(
              isHint ? Icons.lightbulb_rounded : Icons.undo_rounded,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.shopOfferTitle(offer.id),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: GameFonts.display,
              fontSize: 20,
              color: pack.ivory,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.shopOfferDescription(offer.id),
            textAlign: TextAlign.center,
            style: TextStyle(color: pack.textMuted, fontSize: 12),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          _pill(
            pack,
            onTap: _busy || insufficient ? null : () => _buy(offer),
            child: _price(pack, cost),
          ),
          if (insufficient) ...[
            const SizedBox(height: 6),
            Text(
              strings.insufficientCoins,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pack.coral,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _skinTile(ThemePack pack, ArrowSkin skin) {
    final owned = widget.save.ownedArrowSkins.contains(skin.id);
    final selected = widget.save.selectedArrowSkin == skin.id;
    final available =
        skin.unlockLevel == null || widget.save.level >= skin.unlockLevel!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: pack.panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? pack.accent : pack.panelActive,
          width: selected ? 3 : 2,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 64,
            height: 40,
            child: CustomPaint(painter: _SkinArrowPainter(skin.primaryColors)),
          ),
          const SizedBox(height: 8),
          Text(
            skin.name(strings),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: pack.ivory,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 8),
          _skinAction(pack, skin, owned, selected, available),
        ],
      ),
    );
  }

  Widget _chip(ThemePack pack, String label, {Color? color, IconData? icon}) {
    final tint = color ?? pack.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: tint),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tint,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skinAction(
    ThemePack pack,
    ArrowSkin skin,
    bool owned,
    bool selected,
    bool available,
  ) {
    if (selected) {
      return _chip(
        pack,
        strings.selected,
        color: pack.turquoise,
        icon: Icons.check_rounded,
      );
    }
    if (owned) {
      return _pill(
        pack,
        color: pack.turquoise,
        onTap: _busy
            ? null
            : () async {
                if (await economy.equipSkin(skin.id) && mounted) {
                  setState(() {});
                }
              },
        child: Text(strings.select, style: _pillText(pack)),
      );
    }
    if (!available) {
      return _chip(pack, strings.unlockAt80, icon: Icons.lock_rounded);
    }
    if (skin.price == 0) {
      return _chip(pack, strings.skinUnlocked, color: pack.turquoise);
    }
    return _pill(
      pack,
      onTap: _busy || widget.save.coins < skin.price
          ? null
          : () => _buySkin(skin),
      child: _price(pack, skin.price),
    );
  }

  Future<void> _buySkin(ArrowSkin skin) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await economy.buySkin(skin);
      if (!mounted) return;
      if (result.success) {
        _message(strings.skinPurchased);
      } else if (result.reason == 'insufficient') {
        _message(strings.insufficientCoins);
      }
      setState(() {});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _buy(ShopOffer offer) async {
    if (_busy || widget.save.coins < (offer.coinCost ?? 0)) return;
    setState(() => _busy = true);
    try {
      final result = await economy.buyOffer(offer.id);
      if (mounted && !result.success) {
        _message(
          result.reason == 'failed-precondition'
              ? strings.insufficientCoins
              : strings.cloudError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int _remaining(ShopOffer offer) => switch (offer.id) {
    'ad-coins' => widget.save.adCoinsLeft,
    'ad-hints' => widget.save.adHintsLeft,
    _ => 0,
  };

  Future<void> _claimAdReward(ShopOffer offer) async {
    if (_busy || _remaining(offer) == 0 || AdService.adsRemoved) return;
    setState(() => _busy = true);
    try {
      AdService.preload();
      if (!await AdService.showRewarded()) {
        _messageWithRetry(strings.adNotReady, () => _claimAdReward(offer));
        return;
      }

      final result = offer.id == 'ad-hints'
          ? await economy.claimAdHints()
          : await economy.claimAdCoins();
      if (!mounted) return;
      if (!result.success && result.reason != 'failed-precondition') {
        _message(strings.cloudError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _messageWithRetry(String message, VoidCallback retry) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(label: strings.tryAgain, onPressed: retry),
        ),
      );
  }
}

class _SkinArrowPainter extends CustomPainter {
  const _SkinArrowPainter(this.colors);

  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 64, size.height / 40);
    final path = Path()
      ..moveTo(4, 12)
      ..lineTo(36, 12)
      ..lineTo(36, 3)
      ..lineTo(60, 20)
      ..lineTo(36, 37)
      ..lineTo(36, 28)
      ..lineTo(4, 28)
      ..close();
    final paint = Paint();
    if (colors.length < 2) {
      paint.color = colors.first;
    } else {
      paint.shader = LinearGradient(colors: colors)
          .createShader(const Rect.fromLTWH(0, 0, 64, 40));
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SkinArrowPainter oldDelegate) =>
      oldDelegate.colors != colors;
}
