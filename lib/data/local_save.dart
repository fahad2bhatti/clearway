import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/daily_clock.dart';
import '../game/skins/arrow_skin.dart';
import '../game/milestones/milestone_config.dart';
import '../game/achievements/achievement_models.dart';

/// Offline-first progress matching the original browser game's local save.
final class LocalSave extends ChangeNotifier {
  static const _storageKey = 'clearway-save-v1';

  int level = 1;
  int coins = 30;
  int hints = 3;
  int undos = 3;
  int streak = 0;
  String lastDaily = '';

  // Ad rewards
  static const dailyGiftCoins = 50;
  static const adCoinsReward = 30;
  static const maxAdCoinsPerDay = 5;

  String giftDay = '';
  String adCoinsDay = '';
  int adCoinsCount = 0;

  // Username and Terms
  String? _username;
  bool _termsAccepted = false;

  String? get username => _username;
  set username(String? value) {
    _username = value;
    _notifyListeners();
  }

  Future<void> setUsername(String username) async {
    _username = username;
    await save();
  }

  bool get termsAccepted => _termsAccepted;
  set termsAccepted(bool value) {
    _termsAccepted = value;
    _notifyListeners();
  }

  Future<void> acceptTerms() async {
    _termsAccepted = true;
    await save();
  }

  // Other properties
  List<String> ownedArrowSkins = [];
  String selectedArrowSkin = 'classic';
  List<String> claimedMilestones = [];
  List<String> claimedAchievements = [];
  Map<String, int> achievementProgress = {};
  Map<String, dynamic>? dailyMissions;
  List<String> completedDailies = [];
  Map<String, dynamic>? activeBoard;
  bool notifications = true;
  bool notificationPermissionAsked = false;
  String language = 'en';
  bool darkTheme = true;
  bool colorblind = false;
  bool sound = true;
  bool music = false;
  bool haptics = true;
  String acceptedTermsVersion = '';
  int stars = 0;
  List<int> chaptersSeen = [];
  bool tutorialDone = false;
  String starsCode = '';

  int get adCoinsLeft => adCoinsDay == DailyClock.dayKey() ? (maxAdCoinsPerDay - adCoinsCount).clamp(0, maxAdCoinsPerDay) : maxAdCoinsPerDay;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonDecode(prefs.getString(_storageKey) ?? '{}') as Map;

    level = _count(data['level'], 1);
    coins = _count(data['coins'], 30);
    hints = _count(data['hints'], 3);
    undos = _count(data['undos'], 3);
    streak = _count(data['streak'], 0);
    lastDaily = data['lastDaily'] as String? ?? '';
    giftDay = data['giftDay'] as String? ?? '';
    adCoinsDay = data['adCoinsDay'] as String? ?? '';
    adCoinsCount = _count(data['adCoinsCount'], 0);
    _username = data['username'] as String?;
    _termsAccepted = data['termsAccepted'] as bool? ?? false;
    stars = _count(data['stars'], 0);
    chaptersSeen = (data['chaptersSeen'] as List<dynamic>? ?? []).whereType<int>().toList();
    tutorialDone = data['tutorialDone'] as bool? ?? false;
    starsCode = data['starsCode'] as String? ?? '';

    ownedArrowSkins
      ..clear()
      ..addAll(
        (data['arrowSkins'] as List<dynamic>? ?? [ArrowSkinCatalog.classic.id])
            .whereType<String>()
            .where((id) => ArrowSkinCatalog.contains(id)),
      );
    if (ownedArrowSkins.isEmpty) ownedArrowSkins.add('classic');
    if (level >= ArrowSkinCatalog.spectrumUnlockLevel) {
      ownedArrowSkins.add(ArrowSkinCatalog.spectrum.id);
    }
    selectedArrowSkin = ownedArrowSkins.contains(data['selectedArrowSkin'])
        ? data['selectedArrowSkin'] as String
        : ArrowSkinCatalog.classic.id;

    claimedMilestones
      ..clear()
      ..addAll(
        (data['claimedMilestones'] as List<dynamic>? ?? [])
            .whereType<String>()
            .where(
              (id) => MilestoneConfig.rewards.any((reward) => reward.id == id),
            ),
      );

    claimedAchievements
      ..clear()
      ..addAll(
        (data['claimedAchievements'] as List<dynamic>? ?? [])
            .whereType<String>()
            .where(
              (id) => AchievementCatalog.byId(id) != null,
            ),
      );

    achievementProgress.clear();
    achievementProgress.addAll(
        (data['achievementProgress'] as Map<dynamic, dynamic>? ?? {})
            .map((key, value) => MapEntry(key.toString(), _count(value, 0))),
    );

    dailyMissions = data['dailyMissions'] != null ? _decodeDailyMissions(data['dailyMissions'] as Map) : null;
    completedDailies.clear();
    completedDailies.addAll((data['completedDailies'] as List<dynamic>? ?? []).whereType<String>());
    activeBoard = data['activeBoard'] != null ? _decodeBoard(data['activeBoard'] as Map) : null;
    notifications = data['notifications'] as bool? ?? true;
    notificationPermissionAsked = data['notificationPermissionAsked'] as bool? ?? false;
    language = data['lang'] as String? ?? 'en';
    darkTheme = (data['theme'] as String? ?? 'dark') == 'dark';
    colorblind = data['colorblind'] as bool? ?? false;
    sound = data['sound'] as bool? ?? true;
    music = data['music'] as bool? ?? false;
    haptics = data['haptics'] as bool? ?? true;
    acceptedTermsVersion = data['termsVersion'] as String? ?? '';

    _notifyListeners();
  }

  Future<void> save({bool notify = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'level': level,
      'coins': coins,
      'hints': hints,
      'undos': undos,
      'streak': streak,
      'lastDaily': lastDaily,
      'giftDay': giftDay,
      'adCoinsDay': adCoinsDay,
      'adCoinsCount': adCoinsCount,
      'username': _username,
      'termsAccepted': _termsAccepted,
      'stars': stars,
      'chaptersSeen': chaptersSeen,
      'tutorialDone': tutorialDone,
      'starsCode': starsCode,
      'arrowSkins': ownedArrowSkins,
      'selectedArrowSkin': selectedArrowSkin,
      'claimedMilestones': claimedMilestones,
      'claimedAchievements': claimedAchievements,
      'achievementProgress': achievementProgress,
      'dailyMissions': dailyMissions,
      'completedDailies': completedDailies,
      'activeBoard': activeBoard,
      'notifications': notifications,
      'notificationPermissionAsked': notificationPermissionAsked,
      'lang': language,
      'theme': darkTheme ? 'dark' : 'light',
      'colorblind': colorblind,
      'sound': sound,
      'music': music,
      'haptics': haptics,
      'termsVersion': acceptedTermsVersion,
    };
    await prefs.setString(_storageKey, jsonEncode(data));
    if (notify) _notifyListeners();
  }

  void recordAdCoins() {
    final today = DailyClock.dayKey();
    if (adCoinsDay != today) {
      adCoinsDay = today;
      adCoinsCount = 0;
    }
    adCoinsCount++;
  }

  void recordGameplayEvent(String event) {}

  void mergeCloudProgress(Map<String, dynamic> cloudData) {}

  void ensureDailyMissions() {}

  void reset() {}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }

  void _notifyListeners() {
    super.notifyListeners();
  }

  int _count(dynamic value, int defaultValue) => (value as num?)?.toInt() ?? defaultValue;

  Map<String, dynamic>? _decodeDailyMissions(Map<dynamic, dynamic> data) => null;

  Map<String, dynamic>? _decodeBoard(Map<dynamic, dynamic> data) => null;
}