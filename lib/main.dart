import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_identity.dart';
import 'features/home/home_screen.dart';
import 'game/game_screen.dart';
import 'data/local_save.dart';
import 'firebase_options.dart';
import 'services/cloud_progress_sync.dart';

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
}

class ClearwayApp extends StatefulWidget {
  const ClearwayApp({super.key});

  @override
  State<ClearwayApp> createState() => _ClearwayAppState();
}

class _ClearwayAppState extends State<ClearwayApp> {
  final _save = LocalSave();
  final _cloud = CloudProgressSync();
  var _playing = false;
  var _level = 1;
  var _daily = false;

  @override
  void initState() {
    super.initState();
    _save.addListener(_onSaveChanged);
    _cloud.addListener(_refresh);
    unawaited(_initializeServices());
  }

  Future<void> _initializeServices() async {
    await _save.load();
    final activeBoard = _save.activeBoard;
    if (activeBoard != null) {
      final isDaily = activeBoard['daily'] == true;
      if (isDaily && activeBoard['dayKey'] != _todayKey()) {
        _save.activeBoard = null;
        await _save.save();
      } else {
        _level = (activeBoard['level'] as num?)?.toInt() ?? _save.level;
        _daily = isDaily;
        _playing = true;
      }
    }
    if (mounted) setState(() {});
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await _cloud.initialize();
      await _cloud.sync(_save);
    } catch (_) {
      // Keep the whole game playable when Firebase is unavailable or offline.
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _onSaveChanged() {
    _refresh();
    if (_cloud.isReady) unawaited(_cloud.sync(_save));
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
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
    theme: ThemeData(
      useMaterial3: true,
      brightness: _save.darkTheme ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: _save.darkTheme
          ? const Color(0xff182329)
          : const Color(0xfffff8e9),
      colorScheme: _save.darkTheme
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
      textTheme: (_save.darkTheme ? ThemeData.dark() : ThemeData.light())
          .textTheme
          .apply(
            bodyColor: _save.darkTheme
                ? const Color(0xfffff3d8)
                : const Color(0xff273238),
            displayColor: _save.darkTheme
                ? const Color(0xfffff3d8)
                : const Color(0xff273238),
          ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: Color(0xff33434a),
        contentTextStyle: TextStyle(color: Color(0xfffff3d8)),
      ),
    ),
    home: _playing
        ? GameScreen(
            startingLevel: _level,
            daily: _daily,
            save: _save,
            onHome: (level) => setState(() {
              _level = level;
              _playing = false;
              _daily = false;
            }),
            onLevelChanged: (level) => setState(() => _level = level),
          )
        : HomeScreen(
            currentLevel: _save.level,
            save: _save,
            cloudStatus: _cloud.status,
            onSyncNow: () => unawaited(_cloud.retry(_save)),
            onPlay: (level) => setState(() {
              _level = level;
              _playing = true;
              _daily = false;
            }),
            onDaily: () => setState(() {
              _level = _save.level;
              _daily = true;
              _playing = true;
            }),
          ),
  );
}
