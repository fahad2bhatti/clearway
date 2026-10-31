import 'package:flutter/material.dart';

import '../../core/clearway_strings.dart';
import '../../data/local_save.dart';
import '../../services/ad_service.dart';
import '../../services/economy_repository.dart';
import '../../game/skins/arrow_skin.dart';
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
    final offers = shopOffers();
    final coinOffers = offers.where((o) => o.kind == ShopOfferKind.coinPurchase);
    final adOffers = offers.where((o) => o.kind == ShopOfferKind.freeReward);
    final removeAds = offers.where((o) => o.kind == ShopOfferKind.removeAds);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(strings.shopTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('🪙 ${widget.save.coins}', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          _section(strings.shopCoins, coinOffers),
          _skinSection(),
          _section(strings.shopAds, adOffers),
          _section(strings.shopRemoveAds, removeAds),
        ],
      ),
    );
  }

  Widget _section(String title, Iterable<ShopOffer> offers) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          for (final offer in offers) _offerTile(offer),
        ],
      );

  Widget _skinSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              strings.shopSkins,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          for (final skin in ArrowSkinCatalog.all) _skinTile(skin),
        ],
      );

  Widget _skinTile(ArrowSkin skin) {
    final owned = widget.save.ownedArrowSkins.contains(skin.id);
    final selected = widget.save.selectedArrowSkin == skin.id;
    final available =
        skin.unlockLevel == null || widget.save.level >= skin.unlockLevel!;
    return Card(
      child: ListTile(
        leading: _SkinPreview(skin: skin),
        title: Text(skin.name(strings)),
        subtitle: Text(
          '${skin.description(strings)}'
          '${skin.unlockLevel != null && !available ? '\n${strings.unlockAt80}' : ''}',
        ),
        trailing: _skinAction(skin, owned, selected, available),
      ),
    );
  }

  Widget _skinAction(
    ArrowSkin skin,
    bool owned,
    bool selected,
    bool available,
  ) {
    if (selected) return Chip(label: Text(strings.selected));
    if (owned) {
      return TextButton(
        onPressed: _busy
            ? null
            : () async {
                if (await economy.equipSkin(skin.id) && mounted) {
                  setState(() {});
                }
              },
        child: Text(strings.select),
      );
    }
    if (!available) return Chip(label: Text(strings.unlockAt80));
    if (skin.price == 0) {
      return Chip(label: Text(strings.skinUnlocked));
    }
    return FilledButton(
      onPressed: _busy || widget.save.coins < skin.price
          ? null
          : () => _buySkin(skin),
      child: Text('${skin.price} 🪙'),
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

  Widget _offerTile(ShopOffer offer) {
    final remaining = switch (offer.id) {
      'ad-coins' => widget.save.adCoinsLeft,
      'ad-hints' => widget.save.adHintsLeft,
      _ => null,
    };
    final insufficient = offer.coinCost != null && widget.save.coins < offer.coinCost!;
    return Card(
      child: ListTile(
        leading: Icon(_iconFor(offer.kind)),
        title: Text(strings.shopOfferTitle(offer.id)),
        subtitle: Text(
          '${strings.shopOfferDescription(offer.id)}'
          '${remaining == null ? '' : '\n${strings.freeRewardLeft(remaining)}'}'
          '${remaining == null ? '' : '\n${strings.dailyOfferReset}'}'
          '${insufficient ? '\n${strings.insufficientCoins}' : ''}',
        ),
        isThreeLine: remaining != null,
        trailing: _action(offer),
      ),
    );
  }

  Widget _action(ShopOffer offer) {
    if (offer.kind == ShopOfferKind.removeAds) {
      return Chip(label: Text(strings.comingSoon));
    }
    if (_busy) return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator());
    if (offer.kind == ShopOfferKind.freeReward) {
      return FilledButton(
        onPressed: AdService.adsRemoved || _remaining(offer) == 0
            ? null
            : () => _claimAdReward(offer),
        child: Text(strings.watchAd),
      );
    }
    return FilledButton(
      onPressed: widget.save.coins < (offer.coinCost ?? 0) ? null : () => _buy(offer),
      child: Text('${offer.coinCost} 🪙'),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  IconData _iconFor(ShopOfferKind kind) => switch (kind) {
        ShopOfferKind.coinPurchase => Icons.lightbulb_rounded,
        ShopOfferKind.freeReward => Icons.ondemand_video_rounded,
        ShopOfferKind.removeAds => Icons.block_rounded,
      };
}

class _SkinPreview extends StatelessWidget {
  const _SkinPreview({required this.skin});

  final ArrowSkin skin;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 42,
        child: Row(
          children: [
            for (final color in skin.primaryColors)
              Expanded(
                child: Container(
                  height: 28,
                  color: color,
                ),
              ),
          ],
        ),
      );
}
