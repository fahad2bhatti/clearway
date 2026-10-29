import '../data/local_save.dart';
import '../game/milestones/milestone_config.dart';
import '../game/skins/arrow_skin.dart';

final class PurchaseResult {
  const PurchaseResult({
    required this.success,
    this.reason,
  });

  final bool success;
  final String? reason;
}

final class MilestoneGrant {
  const MilestoneGrant({
    required this.coins,
    required this.hints,
    required this.level,
    required this.skinUnlocked,
  });

  final int coins;
  final int hints;
  final int level;
  final bool skinUnlocked;

  bool get isEmpty => coins == 0 && hints == 0 && !skinUnlocked;
}

final class EconomyRepository {
  EconomyRepository(this.save);

  final LocalSave save;

  Future<PurchaseResult> buySkin(ArrowSkin skin) async {
    if (save.ownedArrowSkins.contains(skin.id)) {
      return const PurchaseResult(success: false, reason: 'owned');
    }
    if (!ArrowSkinCatalog.contains(skin.id) ||
        (skin.unlockLevel != null && save.level < skin.unlockLevel!)) {
      return const PurchaseResult(success: false, reason: 'unavailable');
    }
    if (save.coins < skin.price) {
      return const PurchaseResult(success: false, reason: 'insufficient');
    }
    save.coins -= skin.price;
    save.ownedArrowSkins.add(skin.id);
    await save.save();
    return const PurchaseResult(success: true);
  }

  Future<bool> equipSkin(String skinId) async {
    if (!ArrowSkinCatalog.contains(skinId) ||
        !save.ownedArrowSkins.contains(skinId)) {
      return false;
    }
    save.selectedArrowSkin = skinId;
    await save.save();
    return true;
  }

  Future<MilestoneGrant> grantMilestonesThrough(int level) async {
    var coins = 0;
    var hints = 0;
    var skinUnlocked = false;
    for (final reward in MilestoneConfig.rewards) {
      if (reward.level > level || !save.claimedMilestones.add(reward.id)) {
        continue;
      }
      save.coins += reward.coins;
      save.hints += reward.hints;
      coins += reward.coins;
      hints += reward.hints;
    }
    if (level >= ArrowSkinCatalog.spectrum.unlockLevel! &&
        save.ownedArrowSkins.add(ArrowSkinCatalog.spectrum.id)) {
      skinUnlocked = true;
    }
    if (coins > 0 || hints > 0 || skinUnlocked) await save.save();
    return MilestoneGrant(
      coins: coins,
      hints: hints,
      level: level,
      skinUnlocked: skinUnlocked,
    );
  }
}
