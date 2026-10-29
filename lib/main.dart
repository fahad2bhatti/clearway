import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_identity.dart';
import 'core/daily_clock.dart';
import 'features/home/home_screen.dart';
import 'features/shop/shop_screen.dart';
import 'features/settings/settings_screen.dart';
import 'game/data/level_catalog.dart';
import 'game/game_screen.dart';
import 'data/local_save.dart';
import 'firebase_options.dart';
import 'services/ad_service.dart';
import 'services/cloud_progress_sync.dart';
import 'services/progress_sync_debouncer.dart';
import 'services/sound_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (Firebase.apps.isNotEmpty) {
      unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details));
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (Firebase.apps.isEmpty) return false;
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
    );
    return true;
  };
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  runApp(const ClearwayApp());
  // Ads (consent form + SDK init) start after the first frame is on screen.
  unawaited(SoundService.preload());
  unawaited(AdService.initialize());
}

class ClearwayApp extends StatefulWidget {
  const ClearwayApp({super.key});

  @override
  State<ClearwayApp> createState() => _ClearwayAppState();
}

class _ClearwayAppState extends State<ClearwayApp> with WidgetsBindingObserver {
  final _save = LocalSave();
  final _cloud = CloudProgressSync();
  late final _progressSync = ProgressSyncDebouncer(
    operation: (force) => force ? _cloud.retry(_save) : _cloud.sync(_save),
  );
  var _playing = false;
  var _screen = _AppScreen.home;
  var _level = 1;
  var _daily = false;
  String? _dailyDayKey;
  int? _dailyServerSeed;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      LevelCatalog.onSlowGeneration = (number, elapsed) {
        debugPrint('Level $number generated in ${elapsed.inMilliseconds} ms.');
      };
    }
    WidgetsBinding.instance.addObserver(this);
    _save.addListener(_onSaveChanged);
    _cloud.addListener(_refresh);
    unawaited(_initializeServices());
  }

  Future<void> _initializeServices() async {
    await _save.load();
    _save.ensureDailyMissions();
    await _save.save(notify: false);
    unawaited(LevelCatalog.prefetch(_save.level));
    unawaited(LevelCatalog.prefetchDaily(DailyClock.dayKey()));
    final activeBoard = _save.activeBoard;
    if (activeBoard != null) {
      final isDaily = activeBoard['daily'] == true;
      if (isDaily && activeBoard['dayKey'] != DailyClock.dayKey()) {
        _save.activeBoard = null;
        await _save.save();
      } else {
        _level = (activeBoard['level'] as num?)?.toInt() ?? _save.level;
        _daily = isDaily;
        _dailyDayKey = isDaily ? activeBoard['dayKey'] as String? : null;
        _dailyServerSeed = isDaily
            ? (activeBoard['dailySeed'] as num?)?.toInt()
            : null;
        _playing = true;
      }
    }
    if (mounted) setState(() {});
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _cloud.initialize();
      final synced = await _cloud.sync(_save, force: true);
      if (synced != null) _progressSync.markSynced(synced);
      final dailyKey = _dailyDayKey;
      if (_daily && dailyKey != null) {
        unawaited(_refreshDailySeed(dailyKey));
      }
    } catch (_) {
      // Keep the whole game playable when Firebase is unavailable or offline.
    }
  }

  Future<void> _startDaily() async {
    final dayKey = DailyClock.dayKey();
    final cachedSeed = await _cloud.readDailySeed(dayKey, cacheOnly: true);
    if (!mounted) return;
    setState(() {
      _level = _save.level;
      _daily = true;
      _dailyDayKey = dayKey;
      _dailyServerSeed = cachedSeed;
      _playing = true;
    });
    unawaited(_refreshDailySeed(dayKey));
  }

  Future<void> _refreshDailySeed(String dayKey) async {
    final seed = await _cloud.readDailySeed(dayKey);
    if (!mounted ||
        seed == null ||
        !_playing ||
        !_daily ||
        _dailyDayKey != dayKey ||
        _dailyServerSeed == seed) {
      return;
    }
    await LevelCatalog.prefetchDaily(dayKey, serverSeed: seed);
    if (!mounted || !_playing || !_daily || _dailyDayKey != dayKey) return;
    setState(() => _dailyServerSeed = seed);
  }

  void _onSaveChanged() {
    _refresh();
    _progressSync.request(ProgressSyncSignature.fromSave(_save));
  }

  Future<void> _retryCloudSync() async {
    _progressSync.request(ProgressSyncSignature.fromSave(_save));
    await _progressSync.flush(force: true);
  }

  void _onLevelWon() => unawaited(_progressSync.flush());

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_progressSync.flush());
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressSync.dispose();
    _save.removeListener(_onSaveChanged);
    _cloud.removeListener(_refresh);
    _save.dispose();
    _cloud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: AppIdentity.name,
    debugShowCheckedModeBanner: false,
    builder: (context, child) => Directionality(
      textDirection: _save.language == 'ur'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: child ?? const SizedBox.shrink(),
    ),
    theme: _save.darkTheme ? _darkTheme : _lightTheme,
    home: _playing
        ? GameScreen(
            startingLevel: _level,
            daily: _daily,
            dailyDayKey: _dailyDayKey,
            dailyServerSeed: _dailyServerSeed,
            save: _save,
            onLevelWon: _onLevelWon,
            onHome: (level) => setState(() {
              _level = level;
              _playing = false;
              _daily = false;
              _dailyDayKey = null;
              _dailyServerSeed = null;
            }),
            onLevelChanged: (level) => setState(() => _level = level),
          )
        : _screen == _AppScreen.shop
        ? ShopScreen(save: _save, onBack: () => setState(() => _screen = _AppScreen.home))
        : _screen == _AppScreen.settings
        ? SettingsScreen(
            save: _save,
            cloud: _cloud,
            onBack: () => setState(() => _screen = _AppScreen.home),
          )
        : HomeScreen(
            currentLevel: _save.level,
            save: _save,
            cloudStatus: _cloud.status,
            onSyncNow: () => unawaited(_retryCloudSync()),
            onPlay: (level) => setState(() {
              _level = level;
              _playing = true;
              _daily = false;
              _dailyDayKey = null;
              _dailyServerSeed = null;
            }),
            onDaily: () => unawaited(_startDaily()),
            onShop: () => setState(() => _screen = _AppScreen.shop),
            onSettings: () => setState(() => _screen = _AppScreen.settings),
          ),
  );
}

enum _AppScreen { home, shop, settings }

// Built once (top-level finals are lazy) instead of on every app rebuild.
final _darkTheme = _buildTheme(dark: true);
final _lightTheme = _buildTheme(dark: false);

ThemeData _buildTheme({required bool dark}) {
  final text = dark ? const Color(0xfffff3d8) : const Color(0xff273238);
  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: dark
        ? const Color(0xff182329)
        : const Color(0xfffff8e9),
    colorScheme: dark
        ? const ColorScheme.dark(
            primary: Color(0xffffb347),
            secondary: Color(0xff4ecac1),
            surface: Color(0xff25343a),
            onPrimary: Color(0xff182329),
            onSurface: Color(0xfffff3d8),
          )
        : const ColorScheme.light(
            primary: Color(0xffc47718),
            secondary: Color(0xff148d83),
          ),
    textTheme: (dark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
      bodyColor: text,
      displayColor: text,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xff33434a),
      contentTextStyle: TextStyle(color: Color(0xfffff3d8)),
    ),
  );
}
