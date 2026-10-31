import '../../data/local_save.dart';

enum ShopOfferKind { coinPurchase, freeReward, removeAds }

final class ShopOffer {
  const ShopOffer({
    required this.id,
    required this.kind,
    this.coinCost,
    this.coinReward = 0,
    this.hintReward = 0,
    this.dailyLimit,
  });

  final String id;
  final ShopOfferKind kind;
  final int? coinCost;
  final int coinReward;
  final int hintReward;
  final int? dailyLimit;
}

List<ShopOffer> shopOffers() => [
      ShopOffer(
        id: 'hint-pack',
        kind: ShopOfferKind.coinPurchase,
        coinCost: LocalSave.hintPackCost,
        hintReward: LocalSave.hintPackSize,
      ),
      const ShopOffer(
        id: 'undo-pack',
        kind: ShopOfferKind.coinPurchase,
        coinCost: 30,
      ),
      ShopOffer(
        id: 'ad-coins',
        kind: ShopOfferKind.freeReward,
        coinReward: LocalSave.adCoinsReward,
        dailyLimit: LocalSave.maxAdCoinsPerDay,
      ),
      ShopOffer(
        id: 'ad-hints',
        kind: ShopOfferKind.freeReward,
        hintReward: LocalSave.adHintsReward,
        dailyLimit: LocalSave.maxAdHintsPerDay,
      ),
      const ShopOffer(
        id: 'remove-ads',
        kind: ShopOfferKind.removeAds,
      ),
    ];
