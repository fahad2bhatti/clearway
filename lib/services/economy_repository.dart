import '../data/local_save.dart';
import '../game/achievements/achievement_models.dart';
import '../game/milestones/milestone_config.dart';
import '../game/skins/arrow_skin.dart';

final class PurchaseResult {
  const PurchaseResult({required this.success, this.reason});

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

abstract interface class RewardRepository {
  Future<bool> claimAchievement(String achievementId);
  Future<bool> claimDailyMission(String missionId);
}

final class EconomyRepository implements RewardRepository {
  EconomyRepository(this.save);

  final LocalSave save;

  Future<PurchaseResult> _purchase(String itemId) async {
    final item = switch (itemId) {
      'hint-pack' => (cost: 50, hints: 2, undos: 0, skin: null),
      'undo-pack' => (cost: 30, hints: 0, undos: 3, skin: null),
      'sunset-skin' => (cost: 150, hints: 0, undos: 0, skin: 'sunset'),
      _ => null,
    };
    if (item == null || save.coins < item.cost) {
      return const PurchaseResult(success: false, reason: 'insufficient');
    }
    if (item.skin != null && save.ownedArrowSkins.contains(item.skin)) {
      return const PurchaseResult(success: false, reason: 'owned');
    }
    save.coins -= item.cost;
    save.hints += item.hints;
    save.undos += item.undos;
    if (item.skin != null) save.ownedArrowSkins.add(item.skin!);
    await save.save();
    return const PurchaseResult(success: true);
  }

  Future<PurchaseResult> claimAdCoins() async {
    if (save.adCoinsLeft == 0) {
      return const PurchaseResult(
        success: false,
        reason: 'failed-precondition',
      );
    }
    save.recordAdCoins();
    save.coins += LocalSave.adCoinsReward;
    await save.save();
    return const PurchaseResult(success: true);
  }

  Future<PurchaseResult> claimAdHints() async {
    if (save.adHintsLeft == 0) {
      return const PurchaseResult(
        success: false,
        reason: 'failed-precondition',
      );
    }
    // Server-side validation remains TODO for the later server-economy phase.
    save.recordAdHints();
    save.hints += LocalSave.adHintsReward;
    await save.save();
    return const PurchaseResult(success: true);
  }

  Future<PurchaseResult> buyOffer(String offerId) {
    if (offerId != 'hint-pack' && offerId != 'undo-pack') {
      return Future.value(
        const PurchaseResult(success: false, reason: 'unavailable'),
      );
    }
    return _purchase(offerId);
  }

  Future<PurchaseResult> spend(String action) async {
    if (action != 'hint' && action != 'undo' && action != 'revive') {
      return const PurchaseResult(success: false, reason: 'unavailable');
    }
    if (action == 'hint' && save.hints > 0) {
      save.hints--;
    } else if (action == 'undo' && save.undos > 0) {
      save.undos--;
    } else if (action == 'revive' && save.coins >= 30) {
      save.coins -= 30;
    } else {
      return const PurchaseResult(success: false, reason: 'insufficient');
    }
    await save.save();
    return const PurchaseResult(success: true);
  }

  @override
  Future<bool> claimAchievement(String achievementId) async {
    final definition = AchievementCatalog.byId(achievementId);
    if (definition == null ||
        save.claimedAchievements.contains(achievementId) ||
        (save.achievementProgress[achievementId] ?? 0) < definition.target) {
      return false;
    }
    return _claim(() => save.claimedAchievements.add(achievementId));
  }

  @override
  Future<bool> claimDailyMission(String missionId) async {
    save.ensureDailyMissions();
    final state = save.dailyMissions!;
    final mission = state.missions
        .where((candidate) => candidate.id == missionId)
        .firstOrNull;
    if (mission == null ||
        state.claimed.contains(missionId) ||
        (state.progress[missionId] ?? 0) < mission.target) {
      return false;
    }
    return _claim(() => state.claimed.add(missionId));
  }

  Future<PurchaseResult> buySkin(ArrowSkin skin) async {
    if (save.ownedArrowSkins.contains(skin.id)) {
      return const PurchaseResult(success: false, reason: 'owned');
    }
    if (!ArrowSkinCatalog.contains(skin.id) ||
        (skin.unlockLevel != null && save.level < skin.unlockLevel!)) {
      return const PurchaseResult(success: false, reason: 'unavailable');
    }
    if (skin.id != 'sunset') {
      return const PurchaseResult(success: false, reason: 'unavailable');
    }
    return _purchase('sunset-skin');
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
    for (final reward in MilestoneConfig.rewards) {
      if (reward.level > level || !save.claimedMilestones.add(reward.id)) {
        continue;
      }
      save.coins += reward.coins;
      save.hints += reward.hints;
      coins += reward.coins;
      hints += reward.hints;
    }
    var skinUnlocked = false;
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

  Future<bool> _claim(void Function() onSuccess) async {
    onSuccess();
    await save.save();
    return true;
  }
}
