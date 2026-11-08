import 'package:flutter/material.dart';

import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import '../../services/ad_service.dart';
import '../../services/economy_repository.dart';
import '../../game/skins/arrow_skin.dart';
import '../../widgets/game_ui.dart';
import '../onboarding/onboarding_theme.dart';
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
    final language = widget.save.language;
    final offers = shopOffers();
    final coinOffers = offers
        .where((o) => o.kind == ShopOfferKind.coinPurchase)
        .toList();
    final adOffers = offers
        .where((o) => o.kind == ShopOfferKind.freeReward)
        .toList();
    return RedesignTheme(
      child: Scaffold(
        backgroundColor: OnboardingTheme.bgTop,
        body: SafeArea(
          child: Column(
            children: [
              ScreenHeader(
                title: strings.shopTitle,
                onBack: widget.onBack,
                trailing: _balance(),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    for (final offer in adOffers) _adBanner(offer),
                    const SizedBox(height: 8),
                    SectionLabel(title: strings.shopCoins, language: language),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < coinOffers.length; i++) ...[
                            if (i > 0) const SizedBox(width: 10),
                            Expanded(child: _coinCard(coinOffers[i])),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionLabel(title: strings.shopSkins, language: language),
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
                            Expanded(child: _skinTile(ArrowSkinCatalog.all[i])),
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

  Widget _balance() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: OnboardingTheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: OnboardingTheme.line),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _coinDot(),
        const SizedBox(width: 8),
        Text('${widget.save.coins}', style: OnboardingTheme.display(18)),
      ],
    ),
  );

  Widget _coinDot() => Container(
    width: 8,
    height: 8,
    decoration: const BoxDecoration(
      color: OnboardingTheme.coin,
      shape: BoxShape.circle,
    ),
  );

  /// A small rounded button used for every shop action.
  Widget _pill({
    required Widget child,
    required VoidCallback? onTap,
    Color color = OnboardingTheme.accent,
  }) => Opacity(
    opacity: onTap == null ? 0.5 : 1,
    child: Material(
      color: color,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: child,
        ),
      ),
    ),
  );

  TextStyle _pillText([Color color = OnboardingTheme.onAccent]) =>
      OnboardingTheme.display(17, color: color);

  Widget _price(int cost) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _coinDot(),
      const SizedBox(width: 7),
      Text('$cost', style: _pillText()),
    ],
  );

  Widget _adBanner(ShopOffer offer) {
    final remaining = _remaining(offer);
    final canWatch = !_busy && !AdService.adsRemoved && remaining > 0;
    final soft = OnboardingTheme.onAccent.withValues(alpha: 0.8);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: OnboardingTheme.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OnboardingTheme.onAccent.withValues(alpha: 0.2),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: OnboardingTheme.onAccent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.shopOfferTitle(offer.id),
                  style: OnboardingTheme.display(
                    22,
                    color: OnboardingTheme.onAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.freeRewardLeft(remaining),
                  style: TextStyle(
                    color: soft,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (remaining == 0)
                  Text(
                    strings.dailyOfferReset,
                    style: TextStyle(color: soft, fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _pill(
            color: OnboardingTheme.onAccent,
            onTap: canWatch ? () => _claimAdReward(offer) : null,
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: OnboardingTheme.accent,
                    ),
                  )
                : Text(
                    strings.watchAd,
                    style: _pillText(OnboardingTheme.accent),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _coinCard(ShopOffer offer) {
    final cost = offer.coinCost ?? 0;
    final insufficient = widget.save.coins < cost;
    final isHint = offer.id == 'hint-pack';
    final color = isHint ? OnboardingTheme.teal : OnboardingTheme.hot;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnboardingTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OnboardingTheme.line),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
            ),
            child: Icon(
              isHint ? Icons.lightbulb_rounded : Icons.undo_rounded,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            strings.shopOfferTitle(offer.id),
            textAlign: TextAlign.center,
            style: OnboardingTheme.display(20),
          ),
          const SizedBox(height: 4),
          Text(
            strings.shopOfferDescription(offer.id),
            textAlign: TextAlign.center,
            style: const TextStyle(color: OnboardingTheme.muted, fontSize: 12),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          _pill(
            onTap: _busy || insufficient ? null : () => _buy(offer),
            child: _price(cost),
          ),
          if (insufficient) ...[
            const SizedBox(height: 6),
            Text(
              strings.insufficientCoins,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnboardingTheme.hot,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _skinTile(ArrowSkin skin) {
    final owned = widget.save.ownedArrowSkins.contains(skin.id);
    final selected = widget.save.selectedArrowSkin == skin.id;
    final available =
        skin.unlockLevel == null || widget.save.level >= skin.unlockLevel!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: OnboardingTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? OnboardingTheme.accent : OnboardingTheme.line,
          width: selected ? 2 : 1,
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
            style: const TextStyle(
              color: OnboardingTheme.cream,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 8),
          _skinAction(skin, owned, selected, available),
        ],
      ),
    );
  }

  Widget _chip(
    String label, {
    Color color = OnboardingTheme.muted,
    IconData? icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _skinAction(ArrowSkin skin, bool owned, bool selected, bool available) {
    if (selected) {
      return _chip(
        strings.selected,
        color: OnboardingTheme.teal,
        icon: Icons.check_rounded,
      );
    }
    if (owned) {
      return _pill(
        color: OnboardingTheme.teal,
        onTap: _busy
            ? null
            : () async {
                if (await economy.equipSkin(skin.id) && mounted) {
                  setState(() {});
                }
              },
        child: Text(strings.select, style: _pillText(OnboardingTheme.bgTop)),
      );
    }
    if (!available) {
      return _chip(strings.unlockAt80, icon: Icons.lock_rounded);
    }
    if (skin.price == 0) {
      return _chip(strings.skinUnlocked, color: OnboardingTheme.teal);
    }
    return _pill(
      onTap: _busy || widget.save.coins < skin.price
          ? null
          : () => _buySkin(skin),
      child: _price(skin.price),
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
