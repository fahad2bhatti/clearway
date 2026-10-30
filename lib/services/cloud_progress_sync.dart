import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../data/local_save.dart';
import '../data/progress_codec.dart';
import '../game/achievements/achievement_models.dart';
import 'progress_sync_debouncer.dart';

enum CloudSyncStatus { notConfigured, offline, syncing, synced, failed }

/// Anonymous account and conflict-safe progress sync. Local play never waits
/// for Firebase to be reachable.
final class CloudProgressSync extends ChangeNotifier {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  CloudSyncStatus status = CloudSyncStatus.notConfigured;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  Future<void> _handleConnectivityChanged(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      await _submitPendingFeedback();
    }
  }
  bool _busy = false;
  bool _ready = false;
  bool _emulatorConfigured = false;
  bool _syncAgain = false;
  bool _syncAgainForce = false;
  bool _legacyRulesOnly = false;
  ProgressSyncSignature? _lastSyncedSignature;
  final Map<String, int> _dailySeedCache = {};

  bool get isReady => _ready;

  bool get hasLinkedProvider =>
      (_auth?.currentUser?.providerData ?? const []).isNotEmpty;

  String? get accountEmail => _auth?.currentUser?.email;

  String? get accountUid => _auth?.currentUser?.uid;

  ProgressSyncSignature? get lastSyncedSignature => _lastSyncedSignature;

  /// Cache-only mode is used before starting a daily so play never waits on
  /// the network. A later online fetch can replace the local fallback seed.
  Future<int?> readDailySeed(String dayKey, {bool cacheOnly = false}) async {
    if (!_ready || _firestore == null) return null;
    final cached = _dailySeedCache[dayKey];
    if (cacheOnly && cached != null) return cached;
    try {
      final source = cacheOnly ? Source.cache : Source.serverAndCache;
      final snapshot = await _firestore!
          .collection('dailyChallenges')
          .doc(dayKey)
          .get(GetOptions(source: source))
          .timeout(const Duration(milliseconds: 1500));
      final seed = (snapshot.data()?['seed'] as num?)?.toInt();
      if (seed == null || seed < 0 || seed > 0xffffffff) return null;
      _dailySeedCache[dayKey] = seed;
      return seed;
    } catch (_) {
      return null;
    }
  }

  Future<ProgressSyncSignature?> retry(LocalSave local) async {
    await initialize();
    return sync(local, force: true);
  }

  static const _useEmulators = bool.fromEnvironment(
    'CLEARWAY_FIREBASE_EMULATORS',
    defaultValue: false,
  );
  static const _emulatorHost = String.fromEnvironment(
    'CLEARWAY_FIREBASE_EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        throw StateError('Firebase has not been initialized.');
      }

      _auth ??= FirebaseAuth.instance;
      _firestore ??= FirebaseFirestore.instance;
      if (_useEmulators && !_emulatorConfigured) {
        _auth!.useAuthEmulator(_emulatorHost, 9099);
        _firestore!.useFirestoreEmulator(_emulatorHost, 8080);
        _emulatorConfigured = true;
      }
      if (_auth!.currentUser == null) {
        await _auth!.signInAnonymously();
      }
      _ready = _auth!.currentUser != null;
      status = _ready ? CloudSyncStatus.offline : CloudSyncStatus.failed;
    } catch (_) {
      _ready = false;
      status = CloudSyncStatus.offline;
    }
    notifyListeners();
  }

  Future<bool> deleteAccount() async {
    if (!_ready) return false;
    await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
    await _auth?.signOut();
    _ready = false;
    status = CloudSyncStatus.offline;
    notifyListeners();
    return true;
  }

  Future<void> signOut() async {
    if (!hasLinkedProvider) {
      throw StateError('Anonymous accounts cannot be signed out safely.');
    }
    await _auth?.signOut();
    _ready = false;
    status = CloudSyncStatus.offline;
    notifyListeners();
  }

  static const String _pendingFeedbackKey = 'pendingFeedback';

  Future<void> _savePendingFeedback(String text, String appVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFeedback = prefs.getStringList(_pendingFeedbackKey) ?? [];
    final device = defaultTargetPlatform.name;
    
    final newFeedback = {
      'uid': _auth?.currentUser?.uid,
      'type': 'feedback',
      'text': text.trim(),
      'appVersion': appVersion,
      'device': device,
    };
    
    if (!pendingFeedback.any((item) => item['text'] == text)) {
      pendingFeedback.add(jsonEncode(newFeedback));
      await prefs.setStringList(_pendingFeedbackKey, pendingFeedback);
    }
  }

  Future<void> _submitPendingFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFeedback = prefs.getStringList(_pendingFeedbackKey) ?? [];
    
    if (pendingFeedback.isNotEmpty) {
      for (final feedbackJson in pendingFeedback) {
        try {
          final feedback = jsonDecode(feedbackJson) as Map<String, dynamic>;
          await _firestore!.collection('reports').add(feedback);
        } catch (e) {
          // Log error and continue with next feedback
          debugPrint('Error submitting feedback: $e');
        }
      }
      await prefs.remove(_pendingFeedbackKey);
    }
  }

  static const String _pendingFeedbackKey = 'pendingFeedback';

  Future<void> _savePendingFeedback(String text, String appVersion) async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFeedback = prefs.getStringList(_pendingFeedbackKey) ?? [];
    final device = defaultTargetPlatform.name;
    
    final newFeedback = {
      'uid': _auth?.currentUser?.uid,
      'type': 'feedback',
      'text': text.trim(),
      'appVersion': appVersion,
      'device': device,
    };
    
    if (!pendingFeedback.any((item) => jsonDecode(item)['text'] == text)) {
      pendingFeedback.add(jsonEncode(newFeedback));
      await prefs.setStringList(_pendingFeedbackKey, pendingFeedback);
    }
  }

  Future<void> _submitPendingFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingFeedback = prefs.getStringList(_pendingFeedbackKey) ?? [];
    
    if (pendingFeedback.isNotEmpty) {
      for (final feedbackJson in pendingFeedback) {
        try {
          final feedback = jsonDecode(feedbackJson) as Map<String, dynamic>;
          await _firestore!.collection('reports').add(feedback);
        } catch (e) {
          debugPrint('Error submitting feedback: $e');
        }
      }
      await prefs.remove(_pendingFeedbackKey);
    }
  }

  Future<void> sendFeedback({
    required String text,
    required String appVersion,
  }) async {
    final uid = _auth?.currentUser?.uid;
    if (!_ready || _firestore == null) {
      await _savePendingFeedback(text, appVersion);
      return;
    }
    if (uid == null) {
      throw StateError('Feedback is unavailable.');
    }
    if (!_ready || _firestore == null) {
      await _savePendingFeedback(text, appVersion);
      return;
    }
    if (uid == null) {
      throw StateError('Feedback unavailable.');
    }
    await _firestore!.collection('reports').add({
      'uid': uid,
      'type': 'feedback',
      'text': text.trim(),
      'appVersion': appVersion,
      'device': defaultTargetPlatform.name,
    });
  }

  Future<ProgressSyncSignature?> sync(
    LocalSave local, {
    bool force = false,
  }) async {
    if (!_ready) return null;
    if (_busy) {
      _syncAgain = true;
      _syncAgainForce = _syncAgainForce || force;
      return null;
    }
    final requestedSignature = ProgressSyncSignature.fromSave(local);
    if (!force && requestedSignature == _lastSyncedSignature) {
      status = CloudSyncStatus.synced;
      return requestedSignature;
    }
    final uid = _auth?.currentUser?.uid;
    if (uid == null) {
      _ready = false;
      status = CloudSyncStatus.offline;
      notifyListeners();
      return null;
    }
    _busy = true;
    status = CloudSyncStatus.syncing;
    notifyListeners();
    try {
      final ref = _firestore!
          .collection('users')
          .doc(uid)
          .collection('progress')
          .doc('state');
      final snapshot = await ref.get();
      final remote = snapshot.data();
      final remoteLevel = (remote?['highestLevel'] as num?)?.toInt() ?? 1;
      final oldStars = (remote?['stars'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(int.parse(key), (value as num).toInt()),
      );
      final remoteStarsCode = remote?['starsCode'] as String?;
      final remoteStars = remoteStarsCode == null
          ? oldStars
          : ProgressCodec.decode(remoteStarsCode);
      final remoteArrowSkins = (remote?['arrowSkins'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toSet();
      final remoteSelectedArrowSkin =
          remote?['selectedArrowSkin'] as String? ?? 'classic';
      final remoteClaimedMilestones =
          (remote?['claimedMilestones'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toSet();
      final remoteAchievementProgress =
          (remote?['achievementProgress'] as Map<String, dynamic>? ?? {}).map(
            (key, value) => MapEntry(key, (value as num).toInt()),
          );
      final remoteClaimedAchievements =
          (remote?['claimedAchievements'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toSet();
      final remoteDailyMissions = _decodeDailyMissions(remote?['dailyMissions']);
      final remoteSignature = ProgressSyncSignature.fromProgress(
        remoteLevel,
        remoteStars,
        arrowSkins: remoteArrowSkins,
        selectedArrowSkin: remoteSelectedArrowSkin,
        claimedMilestones: remoteClaimedMilestones,
        achievementProgress: remoteAchievementProgress,
        claimedAchievements: remoteClaimedAchievements,
        dailyMissions: remoteDailyMissions,
      );
      if (remote != null) {
        await local.mergeCloudProgress(
          remoteLevel,
          remoteStars,
          cloudArrowSkins: remoteArrowSkins,
          cloudSelectedArrowSkin: remoteSelectedArrowSkin,
          cloudClaimedMilestones: remoteClaimedMilestones,
          cloudAchievementProgress: remoteAchievementProgress,
          cloudClaimedAchievements: remoteClaimedAchievements,
          cloudDailyMissions: remoteDailyMissions,
        );
      }
      final mergedSignature = ProgressSyncSignature.fromSave(local);
      final localStarsCode = ProgressCodec.encode(
        local.stars,
        throughLevel: local.level,
      );
      final remoteIsAhead =
          remote != null &&
          (local.level < remoteLevel ||
              (remoteStarsCode != null &&
                  localStarsCode.length < remoteStarsCode.length));
      final needsFormatMigration = remote != null && remoteStarsCode == null;
      if (!snapshot.exists ||
          needsFormatMigration ||
          (!remoteIsAhead && mergedSignature != remoteSignature)) {
        if (_legacyRulesOnly) {
          await _writeLegacyProgress(
            ref,
            local: local,
            starsCode: localStarsCode,
          );
        } else {
          try {
            await ref.set({
              'highestLevel': local.level,
              'starsCode': localStarsCode,
              'arrowSkins': local.ownedArrowSkins.toList()..sort(),
              'selectedArrowSkin': local.selectedArrowSkin,
              'claimedMilestones': local.claimedMilestones.toList()..sort(),
              'achievementProgress': local.achievementProgress,
              'claimedAchievements': local.claimedAchievements.toList()..sort(),
              if (local.dailyMissions != null)
                'dailyMissions': _encodeDailyMissions(local.dailyMissions!),
              'schemaVersion': 3,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } on FirebaseException catch (error) {
            if (error.code != 'permission-denied') rethrow;
            // Supports app rollout before the updated Firestore rules deploy.
            // Phase 9 state remains local until schema 3 rules are live.
            _legacyRulesOnly = true;
            await _writeLegacyProgress(
              ref,
              local: local,
              starsCode: localStarsCode,
            );
          }
        }
      }
      _lastSyncedSignature = mergedSignature;
      status = CloudSyncStatus.synced;
      return mergedSignature;
    } on FirebaseException catch (error) {
      status =
          error.code == 'unavailable' || error.code == 'network-request-failed'
          ? CloudSyncStatus.offline
          : CloudSyncStatus.failed;
    } catch (_) {
      status = CloudSyncStatus.failed;
    } finally {
      _busy = false;
      notifyListeners();
      if (_syncAgain) {
        final forceAgain = _syncAgainForce;
        _syncAgain = false;
        _syncAgainForce = false;
        await sync(local, force: forceAgain);
      }
    }
    return null;
  }

  Future<void> _writeLegacyProgress(
    DocumentReference<Map<String, dynamic>> ref, {
    required LocalSave local,
    required String starsCode,
  }) => ref.set({
    'highestLevel': local.level,
    'starsCode': starsCode,
    'arrowSkins': local.ownedArrowSkins.toList()..sort(),
    'selectedArrowSkin': local.selectedArrowSkin,
    'claimedMilestones': local.claimedMilestones.toList()..sort(),
    'schemaVersion': 2,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  DailyMissionState? _decodeDailyMissions(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final dayKey = raw['dayKey'];
    final missions = raw['missions'];
    if (dayKey is! String || missions is! List) return null;
    final definitions = <DailyMissionDefinition>[];
    for (final item in missions) {
      if (item is! Map<String, dynamic>) continue;
      final objective = switch (item['objective']) {
        'clearLevels' => DailyMissionObjective.clearLevels,
        'clearWithoutHints' => DailyMissionObjective.clearWithoutHints,
        'clearBoss' => DailyMissionObjective.clearBoss,
        _ => null,
      };
      if (objective == null ||
          item['id'] is! String ||
          item['target'] is! num ||
          item['coins'] is! num) {
        continue;
      }
      definitions.add(
        DailyMissionDefinition(
          id: item['id'] as String,
          objective: objective,
          target: (item['target'] as num).toInt(),
          coins: (item['coins'] as num).toInt(),
        ),
      );
    }
    if (definitions.length != 3) return null;
    final progress = <String, int>{};
    final rawProgress = raw['progress'];
    if (rawProgress is Map<String, dynamic>) {
      for (final definition in definitions) {
        final value = (rawProgress[definition.id] as num?)?.toInt();
        if (value != null) {
          progress[definition.id] = value.clamp(0, definition.target);
        }
      }
    }
    final claimed = (raw['claimed'] as List<dynamic>? ?? [])
        .whereType<String>()
        .where((id) => definitions.any((definition) => definition.id == id))
        .toSet();
    return DailyMissionState(
      dayKey: dayKey,
      missions: definitions,
      progress: progress,
      claimed: claimed,
    );
  }

  Map<String, dynamic> _encodeDailyMissions(DailyMissionState state) => {
    'dayKey': state.dayKey,
    'missions': [
      for (final mission in state.missions)
        {
          'id': mission.id,
          'objective': mission.objective.name,
          'target': mission.target,
          'coins': mission.coins,
        },
    ],
    'progress': state.progress,
    'claimed': state.claimed.toList()..sort(),
  };
}
