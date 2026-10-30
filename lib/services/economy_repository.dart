import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

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
  FirebaseFunctions get _functions => FirebaseFunctions.instance;
  bool get _firebaseUnavailable =>
      Firebase.apps.isEmpty || FirebaseAuth.instance.currentUser == null;
  static int _requestSequence = 0;

  String _requestId(String operation, String subject) {
    final sequence = _requestSequence++;
    return '$operation-$subject-${DateTime.now().microsecondsSinceEpoch}-$sequence';
  }

  void _applyState(Object? raw) {
    if (raw is! Map) return;
    final state = raw['state'];
    if (state is! Map) return;
    final coins = state['coins'];
    final hints = state['hints'];
    final undos = state['undos'];
    final skins = state['ownedSkins'];
    if (coins is! num ||
        hints is! num ||
        undos is! num ||
        skins is! List ||
        coins < 0 ||
        hints < 0 ||
        undos < 0 ||
        !coins.isFinite ||
        !hints.isFinite ||
        !undos.isFinite) {
      return;
    }
    save
      ..coins = coins.toInt()
      ..hints = hints.toInt()
      ..undos = undos.toInt();
    save.ownedArrowSkins
      ..clear()
      ..addAll(skins.whereType<String>().where(ArrowSkinCatalog.contains));
    save.ownedArrowSkins.add('classic');
    if (!save.ownedArrowSkins.contains(save.selectedArrowSkin)) {
      save.selectedArrowSkin = 'classic';
    }
  }

  Future<PurchaseResult> _purchase(String itemId) async {
    if (_firebaseUnavailable) return _localPurchase(itemId);
    try {
      final result = await _functions.httpsCallable('purchaseEconomyItem').call({
        'itemId': itemId,
        'requestId': _requestId('purchase', itemId),
      });
      _applyState(result.data);
      await save.save();
      return const PurchaseResult(success: true);
    } on FirebaseFunctionsException catch (error) {
      return PurchaseResult(success: false, reason: error.code);
    } catch (_) {
      return const PurchaseResult(success: false, reason: 'offline');
    }
  }

  Future<PurchaseResult> _localPurchase(String itemId) async {
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
    if (_firebaseUnavailable) {
      save.recordAdCoins();
      save.coins += LocalSave.adCoinsReward;
      await save.save();
      return const PurchaseResult(success: true);
    }
    try {
      final result = await _functions.httpsCallable('claimAdCoins').call({
        'requestId': _requestId('ad-coins', 'daily'),
      });
      _applyState(result.data);
      save.recordAdCoins();
      await save.save();
      return const PurchaseResult(success: true);
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'failed-precondition') {
        while (save.adCoinsLeft > 0) {
          save.recordAdCoins();
        }
        await save.save();
      }
      return PurchaseResult(success: false, reason: error.code);
    } catch (_) {
      return const PurchaseResult(success: false, reason: 'offline');
    }
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
    if (_firebaseUnavailable) {
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
    try {
      final result =
          await _functions.httpsCallable('spendEconomyResource').call({
        'action': action,
        'requestId': _requestId('spend', action),
      });
      _applyState(result.data);
      await save.save();
      return const PurchaseResult(success: true);
    } on FirebaseFunctionsException catch (error) {
      return PurchaseResult(success: false, reason: error.code);
    } catch (_) {
      return const PurchaseResult(success: false, reason: 'offline');
    }
  }

  @override
  Future<bool> claimAchievement(String achievementId) async {
    final definition = AchievementCatalog.byId(achievementId);
    if (definition == null ||
        save.claimedAchievements.contains(achievementId) ||
        (save.achievementProgress[achievementId] ?? 0) < definition.target) {
      return false;
    }
    return _claim(
      claimId: 'achievement-$achievementId',
      onSuccess: () => save.claimedAchievements.add(achievementId),
    );
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
    return _claim(
      claimId: 'mission-${state.dayKey}-$missionId',
      onSuccess: () => state.claimed.add(missionId),
    );
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
    if (_firebaseUnavailable) return _grantMilestonesLocally(level);
    var coins = 0;
    var hints = 0;
    var skinUnlocked = false;
    for (final reward in MilestoneConfig.rewards) {
      if (reward.level > level ||
          save.claimedMilestones.contains(reward.id)) {
        continue;
      }
      final claimed = await _claim(
        claimId: 'milestone-${reward.id}',
        onSuccess: () => save.claimedMilestones.add(reward.id),
      );
      if (claimed) {
        coins += reward.coins;
        hints += reward.hints;
      }
    }
    return MilestoneGrant(
      coins: coins,
      hints: hints,
      level: level,
      skinUnlocked: skinUnlocked,
    );
  }

  Future<MilestoneGrant> _grantMilestonesLocally(int level) async {
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

  Future<bool> _claim({
    required String claimId,
    required void Function() onSuccess,
  }) async {
    if (_firebaseUnavailable) {
      onSuccess();
      await save.save();
      return true;
    }
    try {
      final result =
          await _functions.httpsCallable('claimEconomyReward').call({
        'claimId': claimId,
        'requestId': _requestId('claim', claimId),
      });
      _applyState(result.data);
      onSuccess();
      await save.save();
      return true;
    } on FirebaseFunctionsException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
