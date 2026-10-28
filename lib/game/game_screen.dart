import 'package:flame/game.dart' hide Matrix4;

import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/clearway_banner.dart';

import 'package:flutter/services.dart';

import '../app/theme_pack.dart';
import '../core/clearway_strings.dart';
import '../core/daily_clock.dart';
import '../data/local_save.dart';
import 'chapter_intro.dart';
import 'components/yard_game.dart';
import 'data/level_catalog.dart';
import 'engine/game_level.dart';
import 'engine/move_validator.dart';
import 'engine/vehicle.dart';
import '../services/ad_service.dart';
import '../services/sound_service.dart';
import 'revive.dart';
import 'tutorial.dart';

enum GamePhase { ready, animating, paused, won, lost }

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.startingLevel,
    required this.onHome,
    required this.onLevelChanged,
    required this.onLevelWon,
    required this.save,
    this.daily = false,
    this.dailyDayKey,
    this.dailyServerSeed,
  });

  final int startingLevel;
  final ValueChanged<int> onHome;
  final ValueChanged<int> onLevelChanged;
  final VoidCallback onLevelWon;
  final LocalSave save;
  final bool daily;
  final String? dailyDayKey;
  final int? dailyServerSeed;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _levelLayoutVersion = 7;
  final _themePack = ThemePack.truckArt;
  ClearwayStrings get strings => ClearwayStrings(widget.save.language);
  late int _levelIndex;
  late GameLevel _level;
  late YardGame _yardGame;
  // Same widget instance across rebuilds, so Flutter skips the whole board
  // subtree when only HUD state (lives, hints, zoom lock) changes.
  late Widget _board;

  // safeVehicles() walks every bus; cache it until the board actually changes.
  List<Vehicle>? _safeKey;
  var _safeCountCache = 0;
  late List<Vehicle> _remaining;
  List<Vehicle>? _undoSnapshot;
  var _undoUsed = false;
  var _lives = 3;
  var _mistakes = 0;
  var _phase = GamePhase.ready;
  var _assistEnabled = false;
  var _dailyTouched = false;
  var _revived = false;
  var _zoomLocked = false;
  final _zoom = TransformationController();

  @override
  void initState() {
    super.initState();
    _levelIndex = (widget.startingLevel - 1)
        .clamp(0, LevelCatalog.totalLevels - 1)
        .toInt();
    _loadLevel(restore: true);
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) _flushSave();
    _saveTimer?.cancel();
    _zoom.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.daily &&
        (oldWidget.dailyDayKey != widget.dailyDayKey ||
            oldWidget.dailyServerSeed != widget.dailyServerSeed) &&
        !_dailyTouched &&
        _phase == GamePhase.ready) {
      setState(() => _loadLevel(restore: false));
    }
  }

  void _loadLevel({bool restore = false}) {
    _dailyTouched = false;
    _level = widget.daily
        ? LevelCatalog.daily(_dailyDayKey, serverSeed: widget.dailyServerSeed)
        : LevelCatalog.getLevel(_levelIndex + 1);
    _remaining = _level.vehicles.map((vehicle) => vehicle.copy()).toList();
    _undoSnapshot = null;
    _undoUsed = false;
    _lives = 3;
    _mistakes = 0;
    _phase = GamePhase.ready;
    _assistEnabled = false;
    _revived = false;
    _zoomLocked = false;
    _zoom.value = Matrix4.identity();
    if (restore) _restoreActiveBoard();
    _yardGame =
        YardGame(
            level: _level,
            onVehicleTap: _onVehicleTap,
            themePack: _themePack,
            colorblindMode: widget.save.colorblind,
          )
          ..vehicles = _remaining
          ..suggestedVehicleId = _tutorialVehicleId;
    _board = GameWidget<YardGame>(game: _yardGame);
    _scheduleChapterIntro();
    _persistActiveBoard();
    // Build the next level on a background isolate while the player is busy.
    if (!widget.daily) unawaited(LevelCatalog.prefetch(_level.number + 1));
    if (_remaining.isEmpty || _lives <= 0) {
      if (_remaining.isEmpty) _phase = GamePhase.won;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_remaining.isEmpty) {
          _showWinDialog();
        } else {
          _showLoseDialog();
        }
      });
    }
  }

  void _restoreActiveBoard() {
    final saved = widget.save.activeBoard;
    if (saved == null ||
        saved['layoutVersion'] != _levelLayoutVersion ||
        saved['level'] != _level.number ||
        saved['daily'] != widget.daily) {
      return;
    }
    if (widget.daily && saved['dayKey'] != _dailyDayKey) return;
    final vehiclesById = {
      for (final vehicle in _level.vehicles) vehicle.id: vehicle,
    };
    final remainingIds = (saved['remaining'] as List<dynamic>? ?? [])
        .cast<String>();
    if (remainingIds.any((id) => !vehiclesById.containsKey(id))) return;
    _remaining = [for (final id in remainingIds) vehiclesById[id]!];
    final undoIds = (saved['undoSnapshot'] as List<dynamic>? ?? [])
        .cast<String>();
    if (undoIds.isNotEmpty && undoIds.every(vehiclesById.containsKey)) {
      _undoSnapshot = [for (final id in undoIds) vehiclesById[id]!];
    }
    _undoUsed = saved['undoUsed'] == true;
    _lives = ((saved['lives'] as num?)?.toInt() ?? 3).clamp(0, 3);
    _mistakes = ((saved['mistakes'] as num?)?.toInt() ?? 0).clamp(0, 1000);
    _dailyTouched =
        widget.daily &&
        (_remaining.length != _level.vehicles.length || _mistakes > 0);
    _assistEnabled = saved['assistEnabled'] == true;
    _revived = saved['revived'] == true;
    if (_lives == 0) _phase = GamePhase.lost;
  }

  String get _dailyDayKey => widget.dailyDayKey ?? DailyClock.dayKey();

  bool get _zoomable => _level.width >= 9 || _level.height >= 12;

  /// Marks the chapter card as shown (the save that follows in
  /// [_persistActiveBoard] records it) and opens it after the first frame.
  void _scheduleChapterIntro() {
    if (widget.daily || _remaining.isEmpty || _lives <= 0) return;
    final chapter = ChapterIntro.due(_level.number, widget.save.chaptersSeen);
    if (chapter == null) return;
    widget.save.chaptersSeen.add(chapter);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showChapterIntro(chapter);
    });
  }

  Future<void> _showChapterIntro(int chapter) async {
    final first = LevelCatalog.firstLevelOfChapter(chapter);
    final last = LevelCatalog.lastLevelOfChapter(chapter);
    final lines = [
      strings.chapterLevels(first, last),
      strings.chapterBoard(_level.width, _level.height),
      strings.chapterBoss(last),
    ];
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ChapterIntroDialog(
        label: strings.chapterLabel(chapter),
        name: strings.chapterName(_level.chapter),
        lines: lines,
        buttonLabel: strings.letsGo,
        onStart: () => Navigator.pop(context),
      ),
    );
  }

  String? get _tutorialVehicleId {
    if (widget.daily ||
        !Tutorial.helps(_level.number, done: widget.save.tutorialDone)) {
      return null;
    }
    return MoveValidator.safeVehicles(_level, _remaining).firstOrNull?.id;
  }

  Timer? _saveTimer;

  /// Writing the save to disk on every tap is slow late in a big level, so
  /// taps are grouped into one write.
  void _flushSave() {
    _saveTimer?.cancel();
    _saveTimer = null;
    unawaited(widget.save.save(notify: false));
  }

  void _persistActiveBoard() {
    widget.save.activeBoard = {
      'layoutVersion': _levelLayoutVersion,
      'level': _level.number,
      'daily': widget.daily,
      if (widget.daily) 'dayKey': _dailyDayKey,
      if (widget.daily && widget.dailyServerSeed != null)
        'dailySeed': widget.dailyServerSeed,
      'remaining': _remaining.map((vehicle) => vehicle.id).toList(),
      'undoSnapshot':
          _undoSnapshot?.map((vehicle) => vehicle.id).toList() ?? [],
      'undoUsed': _undoUsed,
      'lives': _lives,
      'mistakes': _mistakes,
      'assistEnabled': _assistEnabled,
      'revived': _revived,
    };
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _flushSave);
  }

  void _clearActiveBoard() {
    widget.save.activeBoard = null;
  }

  void _onVehicleTap(Vehicle vehicle) {
    if (_phase != GamePhase.ready ||
        !_remaining.any((item) => item.id == vehicle.id)) {
      return;
    }
    if (widget.daily) _dailyTouched = true;
    final result = MoveValidator.check(_level, _remaining, vehicle);
    if (result.canEscape) {
      SoundService.clear(enabled: widget.save.sound);
      if (widget.save.haptics) HapticFeedback.selectionClick();
      setState(() {
        _phase = GamePhase.animating;
        _undoSnapshot = List.of(_remaining);
        for (final id in result.groupIds) {
          final member = _remaining.where((item) => item.id == id).firstOrNull;
          if (member != null) _yardGame.showExit(member);
        }
        _remaining.removeWhere((item) => result.groupIds.contains(item.id));
        _yardGame
          ..vehicles = List.of(_remaining)
          ..suggestedVehicleId = null
          ..assistedVehicleIds = const {};
      });
      _persistActiveBoard();
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        if (_remaining.isEmpty) {
          setState(() => _phase = GamePhase.won);
          _showWinDialog();
        } else {
          setState(() => _phase = GamePhase.ready);
        }
      });
      return;
    }

    if (widget.save.haptics) HapticFeedback.lightImpact();
    SoundService.bump(enabled: widget.save.sound);
    setState(() {
      _mistakes++;
      _lives--;
      _phase = GamePhase.animating;
      _yardGame.showBlocked(
        vehicle.id,
        result.blockerId ?? '',
        cell: result.blockerCell,
      );
    });
    _persistActiveBoard();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(switch (result.blockKind) {
            BlockKind.cone => strings.coneBlocked,
            BlockKind.oneWayGate => strings.gateBlocked,
            BlockKind.convoyPartner => strings.convoyBlocked,
            _ => strings.blockedByVehicle,
          }),
          duration: Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
          width: 280,
        ),
      );
    Future<void>.delayed(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      if (_lives == 0) {
        setState(() => _phase = GamePhase.lost);
        _showLoseDialog();
      } else {
        setState(() => _phase = GamePhase.ready);
      }
    });
  }

  void _useHint() {
    if (_phase != GamePhase.ready) return;
    if (widget.save.hints <= 0) {
      unawaited(
        _offerRewardedAd(
          message: strings.adForHint,
          rewardMessage: strings.hintAdded,
          grant: () => widget.save.hints += 1,
        ),
      );
      return;
    }
    if (widget.daily) _dailyTouched = true;
    final safe = MoveValidator.safeVehicles(_level, _remaining);
    if (safe.isEmpty) return;
    widget.save.hints--;
    widget.save.save();
    setState(() {
      _yardGame.suggestedVehicleId = safe.first.id;
      _yardGame.assistedVehicleIds = const {};
    });
    _persistActiveBoard();
  }

  Future<void> _offerRewardedAd({
    required String message,
    required String rewardMessage,
    required void Function() grant,
  }) async {
    AdService.preload();
    final watch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff25343a),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xfffff3d8), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              strings.notNow,
              style: const TextStyle(color: Color(0xffc6d2ca)),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff4ecac1),
              foregroundColor: const Color(0xff182329),
            ),
            icon: const Icon(Icons.play_circle_fill),
            label: Text(strings.watchAd),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;
    final rewarded = await AdService.showRewarded();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (rewarded) {
      grant();
      await widget.save.save();
      messenger.showSnackBar(SnackBar(content: Text(rewardMessage)));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(strings.adNotReady)));
    }
  }

  void _toggleAssist(bool value) {
    if (widget.daily) _dailyTouched = true;
    final safeIds = MoveValidator.safeVehicles(
      _level,
      _remaining,
    ).map((v) => v.id).toSet();
    setState(() {
      _assistEnabled = value;
      _yardGame.assistedVehicleIds = value ? safeIds : const {};
      if (value) _yardGame.suggestedVehicleId = null;
    });
    _persistActiveBoard();
  }

  void _undo() {
    if (_phase != GamePhase.ready || _undoUsed || _undoSnapshot == null) return;
    if (widget.save.undos <= 0) {
      unawaited(
        _offerRewardedAd(
          message: strings.adForUndo,
          rewardMessage: strings.undoAdded,
          grant: () => widget.save.undos += 1,
        ),
      );
      return;
    }
    widget.save.undos--;
    setState(() {
      _remaining = List.of(_undoSnapshot!);
      _undoSnapshot = null;
      _undoUsed = true;
      _yardGame
        ..vehicles = _remaining
        ..suggestedVehicleId = null
        ..assistedVehicleIds = const {};
    });
    _persistActiveBoard();
  }

  Future<void> _showWinDialog() async {
    SoundService.win(enabled: widget.save.sound);
    final stars = _mistakes == 0
        ? 3
        : _mistakes == 1
        ? 2
        : 1;
    final isLast = widget.daily || _levelIndex == LevelCatalog.totalLevels - 1;
    final coinsBefore = widget.save.coins;
    if (!widget.daily) AdService.registerLevelCleared();
    if (widget.daily) {
      final key = _dailyDayKey;
      if (widget.save.completedDailies.add(key)) {
        final yesterday = DateTime.parse('${key}T00:00:00Z')
            .subtract(const Duration(days: 1));
        final yesterdayKey = DailyClock.dayKey(clock: () => yesterday);
        widget.save.streak = widget.save.lastDaily == yesterdayKey
            ? widget.save.streak + 1
            : 1;
        widget.save.lastDaily = key;
        widget.save.coins += 20;
      }
    } else {
      final previousStars = widget.save.stars[_level.number] ?? 0;
      widget.save.stars[_level.number] = previousStars > stars
          ? previousStars
          : stars;
      widget.save.coins += previousStars == 0 ? 15 : 5;
      final unlocked = (_level.number + 1).clamp(1, LevelCatalog.totalLevels);
      if (unlocked > widget.save.level) widget.save.level = unlocked;
      if (_level.number >= Tutorial.levels) widget.save.tutorialDone = true;
    }
    _clearActiveBoard();
    await widget.save.save();
    widget.onLevelWon();
    if (!mounted) return;
    final earned = widget.save.coins - coinsBefore;
    AdService.preload();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        won: true,
        title: strings.wayClear,
        message: strings.allVehiclesOut,
        stars: stars,
        adLabel: earned > 0 ? strings.watchAdDouble(earned) : null,
        adDoneLabel: strings.rewardDoubled,
        adFailedMessage: strings.adNotReady,
        onAd: () async {
          final rewarded = await AdService.showRewarded();
          if (rewarded) {
            widget.save.coins += earned;
            await widget.save.save();
            if (mounted) setState(() {});
          }
          return rewarded;
        },
        primaryLabel: isLast ? strings.backToHome : strings.nextLevel,
        onPrimary: () async {
          Navigator.pop(context);
          if (isLast) {
            _clearActiveBoard();
            widget.save.save();
            widget.onHome(_level.number);
          } else {
            await AdService.maybeShowInterstitial();
            if (!mounted) return;
            setState(() {
              _levelIndex++;
              _loadLevel();
            });
            widget.onLevelChanged(_level.number);
          }
        },
        secondaryLabel: strings.replay,
        onSecondary: () {
          Navigator.pop(context);
          _clearActiveBoard();
          widget.save.save();
          setState(_loadLevel);
        },
        tertiaryLabel: isLast ? null : strings.backToHome,
        onTertiary: isLast
            ? null
            : () {
                Navigator.pop(context);
                _clearActiveBoard();
                widget.save.save();
                widget.onHome(_level.number);
              },
      ),
    );
  }

  void _revive() {
    if (_phase != GamePhase.lost ||
        !Revive.isAvailable(alreadyRevived: _revived) ||
        !Revive.canAfford(widget.save.coins)) {
      return;
    }
    widget.save.coins -= Revive.cost;
    unawaited(widget.save.save());
    setState(() {
      _revived = true;
      _lives = Revive.livesRestored;
      _phase = GamePhase.ready;
    });
    _persistActiveBoard();
  }

  void _reviveFromAd() {
    if (_phase != GamePhase.lost ||
        !Revive.isAvailable(alreadyRevived: _revived)) {
      return;
    }
    setState(() {
      _revived = true;
      _lives = Revive.adLivesRestored;
      _phase = GamePhase.ready;
    });
    _persistActiveBoard();
  }

  Future<void> _showLoseDialog() async {
    SoundService.lose(enabled: widget.save.sound);
    final canRevive = Revive.isAvailable(alreadyRevived: _revived);
    final canAfford = Revive.canAfford(widget.save.coins);
    AdService.preload();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        won: false,
        title: strings.trafficJam,
        message: strings.retryMessage,
        note: canRevive && !canAfford
            ? strings.reviveShort(Revive.shortBy(widget.save.coins))
            : null,
        adLabel: canRevive
            ? strings.watchAdRevive(Revive.adLivesRestored)
            : null,
        adFailedMessage: strings.adNotReady,
        onAd: () async {
          final rewarded = await AdService.showRewarded();
          if (rewarded && context.mounted) {
            Navigator.pop(context);
            _reviveFromAd();
          }
          return rewarded;
        },
        reviveLabel: canRevive ? strings.reviveLabel(Revive.cost) : null,
        reviveEnabled: canAfford,
        onRevive: () {
          Navigator.pop(context);
          _revive();
        },
        primaryLabel: strings.tryAgain,
        onPrimary: () {
          Navigator.pop(context);
          _clearActiveBoard();
          widget.save.save();
          setState(_loadLevel);
        },
        secondaryLabel: strings.home,
        onSecondary: () {
          Navigator.pop(context);
          _clearActiveBoard();
          widget.save.save();
          widget.onHome(_level.number);
        },
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    setState(() => _phase = GamePhase.paused);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff25343a),
        title: Text(
          strings.takeABreak,
          style: const TextStyle(color: Color(0xfffff3d8)),
        ),
        content: Text(
          strings.pauseMessage,
          style: const TextStyle(color: Color(0xffc6d2ca)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _persistActiveBoard();
              setState(() => _phase = GamePhase.ready);
            },
            child: Text(strings.keepPlaying),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(_loadLevel);
            },
            child: Text(strings.restartLevel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearActiveBoard();
              widget.save.save();
              widget.onHome(_level.number);
            },
            child: Text(strings.home),
          ),
        ],
      ),
    );
  }

  int get _safeCount {
    final key = _safeKey;
    if (key != null && key.length == _remaining.length) {
      var same = true;
      for (var i = 0; i < key.length; i++) {
        if (!identical(key[i], _remaining[i])) {
          same = false;
          break;
        }
      }
      if (same) return _safeCountCache;
    }
    _safeKey = List.of(_remaining);
    return _safeCountCache = MoveValidator.safeVehicles(
      _level,
      _remaining,
    ).length;
  }

  @override
  Widget build(BuildContext context) {
    final safeCount = _safeCount;
    final tutorialTip = _tutorialTip;
    return Scaffold(
      backgroundColor: _themePack.asphalt,
      bottomNavigationBar: const ClearwayBanner(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 8),
          child: Column(
            children: [
              Padding(
                padding: _sidePad,
                child: _TopBar(
                  level: _level,
                  lives: _lives,
                  onPause: _showPauseDialog,
                  daily: widget.daily,
                  coins: widget.save.coins,
                  strings: strings,
                ),
              ),
              if (tutorialTip != null)
                Padding(
                  padding: _sidePad.copyWith(top: 6),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xff38554f),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      tutorialTip,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xfffff3d8),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              // The board owns all the space between the bars.
              Expanded(
                child: InteractiveViewer(
                  transformationController: _zoom,
                  panEnabled: _zoomable && !_zoomLocked,
                  scaleEnabled: _zoomable && !_zoomLocked,
                  minScale: 1,
                  maxScale: (_level.height / 5).clamp(2.2, 8.0).toDouble(),
                  boundaryMargin: const EdgeInsets.all(48),
                  child: _board,
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: _sidePad,
                child: _ActionBar(
                  onHint: _useHint,
                  hintCount: widget.save.hints,
                  onUndo: _undo,
                  undoCount: widget.save.undos,
                  undoEnabled: !_undoUsed && _undoSnapshot != null,
                  assistEnabled: _assistEnabled,
                  safeCount: safeCount,
                  onAssistChanged: _toggleAssist,
                  zoomAvailable: _zoomable,
                  zoomLocked: _zoomLocked,
                  onZoomLockChanged: (value) =>
                      setState(() => _zoomLocked = value),
                  strings: strings,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _remaining.isEmpty
                    ? _themePack.emptyYardMessage
                    : strings.vehiclesRemaining(_remaining.length),
                style: const TextStyle(
                  color: Color(0xff91a49e),
                  fontSize: 12,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _sidePad = EdgeInsets.symmetric(horizontal: 14);

  String? get _tutorialTip {
    if (widget.daily) return null;
    if (Tutorial.covers(_level.number) && widget.save.tutorialDone) return null;
    return switch (_level.number) {
      1 => strings.firstDepartureTip,
      2 => strings.blockedVehicleTip,
      3 => strings.orderTip,
      10 => strings.bossShapeTip,
      25 => strings.breatherTip,
      40 => strings.bigBoardTip,
      _ => null,
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.level,
    required this.lives,
    required this.onPause,
    required this.daily,
    required this.coins,
    required this.strings,
  });

  final GameLevel level;
  final int lives;
  final VoidCallback onPause;
  final bool daily;
  final int coins;
  final ClearwayStrings strings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton.filledTonal(
        onPressed: onPause,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xff25343a),
          foregroundColor: const Color(0xfffff3d8),
        ),
        icon: const Icon(Icons.pause_rounded),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              daily
                  ? '${strings.rushHour}  •  ${strings.dailyLabel}'
                  : '${strings.levelNumber(level.number)}${level.boss ? '  •  ${strings.bossLevel}' : ''}',
              style: const TextStyle(
                color: Color(0xffffb347),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
            if (!RegExp(r'^(Boss yard|Yard) \d+$').hasMatch(level.title))
              Text(
                strings.levelTitle(level.title),
                style: const TextStyle(
                  color: Color(0xfffff3d8),
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
          ],
        ),
      ),
      Row(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Icon(
              index < lives
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: index < lives
                  ? const Color(0xffed6ca7)
                  : const Color(0xff59666a),
              size: 20,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        '🪙$coins',
        style: const TextStyle(
          color: Color(0xfffff3d8),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    ],
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onHint,
    required this.hintCount,
    required this.onUndo,
    required this.undoCount,
    required this.undoEnabled,
    required this.assistEnabled,
    required this.safeCount,
    required this.onAssistChanged,
    required this.zoomAvailable,
    required this.zoomLocked,
    required this.onZoomLockChanged,
    required this.strings,
  });

  final VoidCallback onHint;
  final int hintCount;
  final VoidCallback onUndo;
  final int undoCount;
  final bool undoEnabled;
  final bool assistEnabled;
  final int safeCount;
  final ValueChanged<bool> onAssistChanged;
  final bool zoomAvailable;
  final bool zoomLocked;
  final ValueChanged<bool> onZoomLockChanged;
  final ClearwayStrings strings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ActionButton(
          icon: Icons.lightbulb_rounded,
          label: strings.hintCount(hintCount),
          onTap: onHint,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionButton(
          icon: Icons.undo_rounded,
          label: strings.undoCount(undoCount),
          enabled: undoEnabled,
          onTap: onUndo,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionButton(
          icon: assistEnabled ? Icons.grid_on_rounded : Icons.grid_4x4_rounded,
          label: assistEnabled ? strings.assistOn : strings.gridAssist,
          onTap: () => onAssistChanged(!assistEnabled),
          selected: assistEnabled,
        ),
      ),
      if (zoomAvailable) ...[
        const SizedBox(width: 9),
        Expanded(
          child: _ActionButton(
            icon: zoomLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
            label: zoomLocked ? strings.zoomLocked : strings.lockZoom,
            onTap: () => onZoomLockChanged(!zoomLocked),
            selected: zoomLocked,
          ),
        ),
      ],
    ],
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xff38554f) : const Color(0xff25343a),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled
                  ? const Color(0xffffb347)
                  : const Color(0xff69777a),
              size: 20,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? const Color(0xfffff3d8)
                      : const Color(0xff758386),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.won,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.tertiaryLabel,
    this.onTertiary,
    this.stars = 0,
    this.note,
    this.reviveLabel,
    this.reviveEnabled = false,
    this.onRevive,
    this.adLabel,
    this.adDoneLabel,
    this.adFailedMessage = '',
    this.onAd,
  });

  final bool won;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final String? tertiaryLabel;
  final VoidCallback? onTertiary;
  final int stars;
  final String? note;
  final String? reviveLabel;
  final bool reviveEnabled;
  final VoidCallback? onRevive;
  final String? adLabel;
  final String? adDoneLabel;
  final String adFailedMessage;
  final Future<bool> Function()? onAd;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xff25343a),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 21),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: won ? const Color(0xff38554f) : const Color(0xff46363c),
              shape: BoxShape.circle,
            ),
            child: Icon(
              won ? Icons.arrow_outward_rounded : Icons.traffic_rounded,
              color: won ? const Color(0xffffb347) : const Color(0xffed6ca7),
              size: 34,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xfffff3d8),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (won) ...[
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Icon(
                  Icons.star_rounded,
                  size: 33,
                  color: index < stars
                      ? const Color(0xffffb347)
                      : const Color(0xff536165),
                ),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xffc6d2ca), height: 1.45),
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xff91a49e), fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          if (adLabel != null && onAd != null) ...[
            _AdRewardButton(
              label: adLabel!,
              doneLabel: adDoneLabel,
              failedMessage: adFailedMessage,
              onWatch: onAd!,
            ),
            const SizedBox(height: 10),
          ],
          if (reviveLabel != null && onRevive != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: reviveEnabled ? onRevive : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xffffb347),
                  disabledForegroundColor: const Color(0xff758386),
                  side: BorderSide(
                    color: reviveEnabled
                        ? const Color(0xffffb347)
                        : const Color(0xff536165),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  reviveLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPrimary,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffffb347),
                foregroundColor: const Color(0xff182329),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                primaryLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: onSecondary,
                child: Text(
                  secondaryLabel,
                  style: const TextStyle(color: Color(0xffc6d2ca)),
                ),
              ),
              if (tertiaryLabel != null && onTertiary != null)
                TextButton(
                  onPressed: onTertiary,
                  child: Text(
                    tertiaryLabel!,
                    style: const TextStyle(color: Color(0xffc6d2ca)),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// "Ad dekho, reward pao" button. Ad dekhne ke baad ek hi bar kaam karta hai.
class _AdRewardButton extends StatefulWidget {
  const _AdRewardButton({
    required this.label,
    required this.failedMessage,
    required this.onWatch,
    this.doneLabel,
  });

  final String label;
  final String? doneLabel;
  final String failedMessage;
  final Future<bool> Function() onWatch;

  @override
  State<_AdRewardButton> createState() => _AdRewardButtonState();
}

class _AdRewardButtonState extends State<_AdRewardButton> {
  var _busy = false;
  var _done = false;

  Future<void> _watch() async {
    setState(() => _busy = true);
    final rewarded = await widget.onWatch();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _done = rewarded;
    });
    if (!rewarded) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(widget.failedMessage)));
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: _busy || _done ? null : _watch,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xff4ecac1),
        foregroundColor: const Color(0xff182329),
        disabledBackgroundColor: const Color(0xff38554f),
        disabledForegroundColor: const Color(0xffc6d2ca),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_done ? Icons.check_circle_rounded : Icons.play_circle_fill),
      label: Text(
        _done ? (widget.doneLabel ?? widget.label) : widget.label,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _ChapterIntroDialog extends StatelessWidget {
  const _ChapterIntroDialog({
    required this.label,
    required this.name,
    required this.lines,
    required this.buttonLabel,
    required this.onStart,
  });

  final String label;
  final String name;
  final List<String> lines;
  final String buttonLabel;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: const Color(0xff25343a),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 27, 24, 21),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xff38554f),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.map_rounded,
              color: Color(0xffffb347),
              size: 34,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xffffb347),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xfffff3d8),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                line,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xffc6d2ca), height: 1.45),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xffffb347),
                foregroundColor: const Color(0xff182329),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
