import '../data/local_save.dart';
import '../game/milestones/milestone_config.dart';
import '../game/skins/arrow_skin.dart';
import '../game/achievements/achievement_models.dart';

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

abstract interface class RewardRepository {
  Future<bool> claimAchievement(String achievementId);
  Future<bool> claimDailyMission(String missionId);
}

final class EconomyRepository implements RewardRepository {
  EconomyRepository(this.save);

  final LocalSave save;

  @override
  Future<bool> claimAchievement(String achievementId) async {
    final definition = AchievementCatalog.byId(achievementId);
    if (definition == null ||
        save.claimedAchievements.contains(achievementId) ||
        (save.achievementProgress[achievementId] ?? 0) < definition.target) {
      return false;
    }
    save.claimedAchievements.add(achievementId);
    save.coins += 25;
    await save.save();
    return true;
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
    state.claimed.add(missionId);
    save.coins += mission.coins;
    await save.save();
    return true;
  }

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
