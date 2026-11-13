import 'package:flame/game.dart' hide Matrix4;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';

import '../widgets/clearway_banner.dart';

import 'package:flutter/services.dart';

import '../app/theme_pack.dart';
import '../features/onboarding/onboarding_theme.dart';
import '../core/clearway_strings.dart';
import '../core/daily_clock.dart';
import '../data/local_save.dart';
import 'blocked_tap_guard.dart';
import 'chapter_intro.dart';
import 'components/yard_game.dart';
import 'data/level_catalog.dart';
import 'engine/game_level.dart';
import 'engine/move_validator.dart';
import 'engine/vehicle.dart';
import '../services/ad_service.dart';
import '../services/economy_repository.dart';
import '../services/sound_service.dart';
import 'revive.dart';
import 'tutorial.dart';
import 'level_clear_dialog.dart';
import 'rating_prompt.dart';
import 'skins/arrow_skin.dart';
import 'achievements/achievement_models.dart';

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
  });

  final int startingLevel;
  final ValueChanged<int> onHome;
  final ValueChanged<int> onLevelChanged;
  final VoidCallback onLevelWon;
  final LocalSave save;
  final bool daily;
  final String? dailyDayKey;

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

  late List<Vehicle> _remaining;
  List<Vehicle>? _undoSnapshot;
  var _undoUsed = false;
  var _lives = 3;
  var _mistakes = 0;
  var _phase = GamePhase.ready;
  final _blockedTaps = BlockedTapGuard();
  var _dailyTouched = false;
  var _hintUsed = false;
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
        oldWidget.dailyDayKey != widget.dailyDayKey &&
        !_dailyTouched &&
        _phase == GamePhase.ready) {
      setState(() => _loadLevel(restore: false));
    }
  }

  void _loadLevel({bool restore = false}) {
    _dailyTouched = false;
    _hintUsed = false;
    _level = widget.daily
        ? LevelCatalog.daily(_dailyDayKey)
        : LevelCatalog.getLevel(_levelIndex + 1);
    _remaining = _level.vehicles.map((vehicle) => vehicle.copy()).toList();
    _undoSnapshot = null;
    _undoUsed = false;
    _blockedTaps.reset();
    _lives = 3;
    _mistakes = 0;
    _phase = GamePhase.ready;
    _revived = false;
    _zoomLocked = false;
    _zoom.value = Matrix4.identity();
    if (restore) _restoreActiveBoard();
    _yardGame =
        YardGame(
            level: _level,
            onVehicleTap: _onVehicleTap,
            themePack: _themePack,
            skin: ArrowSkinCatalog.byId(widget.save.selectedArrowSkin),
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
    _hintUsed = saved['hintUsed'] == true;
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
      'remaining': _remaining.map((vehicle) => vehicle.id).toList(),
      'undoSnapshot':
          _undoSnapshot?.map((vehicle) => vehicle.id).toList() ?? [],
      'undoUsed': _undoUsed,
      'lives': _lives,
      'mistakes': _mistakes,
      'hintUsed': _hintUsed,
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
      _blockedTaps.reset();
      setState(() {
        _undoSnapshot = List.of(_remaining);
        for (final id in result.groupIds) {
          final member = _remaining.where((item) => item.id == id).firstOrNull;
          if (member != null) _yardGame.showExit(member);
        }
        _remaining.removeWhere((item) => result.groupIds.contains(item.id));
        // Taps stay open while exit animations play; only the last arrow
        // locks the board until the win dialog opens.
        if (_remaining.isEmpty) _phase = GamePhase.animating;
        _yardGame
          ..vehicles = List.of(_remaining)
          ..suggestedVehicleId = null;
      });
      _persistActiveBoard();
      if (_remaining.isEmpty) {
        Future<void>.delayed(const Duration(milliseconds: 250), () {
          if (!mounted || _phase == GamePhase.won) return;
          setState(() => _phase = GamePhase.won);
          _showWinDialog();
        });
      }
      return;
    }

    if (widget.save.haptics) HapticFeedback.lightImpact();
    SoundService.bump(enabled: widget.save.sound);
    final repeat = _blockedTaps.isRepeat(vehicle.id, _remaining.length);
    _blockedTaps.record(vehicle.id, _remaining.length);
    setState(() {
      if (!repeat) {
        _mistakes++;
        _lives--;
      }
      _phase = GamePhase.animating;
      _yardGame.showBlocked(
        vehicle.id,
        result.blockerId ?? '',
        cell: result.blockerCell,
      );
    });
    if (!repeat) _persistActiveBoard();
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
          grant: () async {
            final result = await EconomyRepository(widget.save).claimAdHints();
            return result.success;
          },
        ),
      );
      return;
    }
    if (widget.daily) _dailyTouched = true;
    final safe = MoveValidator.safeVehicles(_level, _remaining);
    if (safe.isEmpty) return;
    unawaited(() async {
      final result = await EconomyRepository(widget.save).spend('hint');
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.cloudError)));
        return;
      }
      _hintUsed = true;
      setState(() => _yardGame.suggestedVehicleId = safe.first.id);
      _persistActiveBoard();
    }());
  }

  Future<void> _offerRewardedAd({
    required String message,
    required String rewardMessage,
    required Future<bool> Function() grant,
  }) async {
    AdService.preload();
    final watch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _themePack.panel,
        content: Text(
          message,
          style: TextStyle(color: _themePack.ivory, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              strings.notNow,
              style: TextStyle(color: _themePack.textMuted),
            ),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: OnboardingTheme.accent,
              foregroundColor: OnboardingTheme.onAccent,
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.play_circle_fill),
            label: Text(strings.watchAd),
          ),
        ],
      ),
    );
    if (watch != true || !mounted) return;
    await _playRewardedAd(rewardMessage: rewardMessage, grant: grant);
  }

  Future<void> _playRewardedAd({
    required String rewardMessage,
    required Future<bool> Function() grant,
  }) async {
    final rewarded = await AdService.showRewarded();
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (rewarded) {
      if (await grant()) {
        await widget.save.save();
        messenger.showSnackBar(SnackBar(content: Text(rewardMessage)));
      } else {
        messenger.showSnackBar(SnackBar(content: Text(strings.adLimitReached)));
      }
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(strings.adNotReady),
          action: SnackBarAction(
            label: strings.tryAgain,
            onPressed: () {
              if (mounted) {
                unawaited(
                  _playRewardedAd(rewardMessage: rewardMessage, grant: grant),
                );
              }
            },
          ),
        ),
      );
  }

  void _undo() {
    if (_phase != GamePhase.ready || _undoUsed || _undoSnapshot == null) return;
    if (widget.save.undos <= 0) {
      unawaited(
        _offerRewardedAd(
          message: strings.adForUndo,
          rewardMessage: strings.undoAdded,
          grant: () async {
            widget.save.undos += 1;
            return true;
          },
        ),
      );
      return;
    }
    unawaited(() async {
      final result = await EconomyRepository(widget.save).spend('undo');
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.cloudError)));
        return;
      }
      _blockedTaps.reset();
      setState(() {
        _remaining = List.of(_undoSnapshot!);
        _undoSnapshot = null;
        _undoUsed = true;
        _yardGame
          ..clearExits()
          ..vehicles = _remaining
          ..suggestedVehicleId = null;
      });
      _persistActiveBoard();
    }());
  }

  Future<void> _showWinDialog() async {
    final completedLevel = _level.number;
    SoundService.win(enabled: widget.save.sound);
    final stars = _mistakes == 0
        ? 3
        : _mistakes == 1
        ? 2
        : 1;
    final isLast = widget.daily || _levelIndex == LevelCatalog.totalLevels - 1;
    final coinsBefore = widget.save.coins;
    final economy = EconomyRepository(widget.save);
    var milestoneNote = '';
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
      final milestone = await economy.grantMilestonesThrough(widget.save.level);
      if (!milestone.isEmpty) {
        final parts = <String>[
          if (milestone.coins > 0) '🪙${milestone.coins}',
          if (milestone.hints > 0) '${milestone.hints} hints',
          if (milestone.skinUnlocked) strings.skinUnlocked,
        ];
        milestoneNote = '${strings.rewardSummary}: ${parts.join(', ')}';
      }
    }
    widget.save.recordGameplayEvent(
      GameplayEvent(
        type: widget.daily
            ? GameplayEventType.dailyCleared
            : GameplayEventType.levelCleared,
        level: _level.number,
        usedHint: _hintUsed,
        isBoss: _level.boss,
        streak: widget.save.streak,
      ),
    );
    _clearActiveBoard();
    await widget.save.save();
    widget.onLevelWon();
    if (!mounted) return;
    final earned = widget.save.coins - coinsBefore;
    AdService.preload();
    Future<void>? dialogFollowUp;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      builder: (context) => LevelClearDialog(
        title: strings.levelCleared,
        stars: stars,
        coinsEarned: earned,
        coinsLabel: strings.coinsGained,
        starsLabel: strings.starsEarned(stars),
        note: milestoneNote.isEmpty ? null : milestoneNote,
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
        nextLabel: isLast ? strings.backToHome : strings.nextLevel,
        onNext: () async {
          Navigator.pop(context);
          if (isLast) {
            _clearActiveBoard();
            widget.save.save();
            widget.onHome(_level.number);
          } else {
            dialogFollowUp = () async {
              await AdService.maybeShowInterstitial();
              if (!mounted) return;
              setState(() {
                _levelIndex++;
                _loadLevel();
              });
              widget.onLevelChanged(_level.number);
            }();
            await dialogFollowUp;
          }
        },
        replayLabel: strings.replay,
        onReplay: () {
          Navigator.pop(context);
          _clearActiveBoard();
          widget.save.save();
          dialogFollowUp = Future<void>.sync(() {
            if (!mounted) return;
            setState(_loadLevel);
          });
        },
        homeLabel: isLast ? null : strings.home,
        onHome: isLast
            ? null
            : () {
                Navigator.pop(context);
                _clearActiveBoard();
                widget.save.save();
                widget.onHome(_level.number);
              },
      ),
    );
    final followUp = dialogFollowUp;
    if (followUp != null) await followUp;
    await _maybeRequestRatingPrompt(completedLevel);
  }

  Future<void> _maybeRequestRatingPrompt(int completedLevel) async {
    if (!mounted ||
        _phase != GamePhase.ready ||
        !shouldShowRatingPrompt(
          level: completedLevel,
          won: true,
          daily: widget.daily,
          shownMilestones: widget.save.ratingPromptMilestonesShown,
        )) {
      return;
    }
    widget.save.ratingPromptMilestonesShown.add(completedLevel);
    await widget.save.save();
    if (!mounted) return;
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        if (!mounted) return;
        await review.requestReview();
      }
    } catch (_) {
      // Native review availability is best effort.
    }
  }

  void _revive() {
    if (_phase != GamePhase.lost ||
        !Revive.isAvailable(alreadyRevived: _revived) ||
        !Revive.canAfford(widget.save.coins)) {
      return;
    }
    unawaited(() async {
      final result = await EconomyRepository(widget.save).spend('revive');
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(strings.cloudError)));
        return;
      }
      setState(() {
        _revived = true;
        _lives = Revive.livesRestored;
        _phase = GamePhase.ready;
      });
      _persistActiveBoard();
    }());
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
        title: Text(strings.takeABreak, style: OnboardingTheme.display(30)),
        content: Text(
          strings.pauseMessage,
          style: const TextStyle(color: OnboardingTheme.muted, height: 1.4),
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
            onPressed: () async {
              Navigator.pop(context);
              await AdService.maybeShowPauseInterstitial();
              if (!mounted) return;
              setState(_loadLevel);
            },
            child: Text(strings.restartLevel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await AdService.maybeShowPauseInterstitial();
              if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final tutorialTip = _tutorialTip;
    return Scaffold(
      backgroundColor: OnboardingTheme.bgTop,
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
                      color: OnboardingTheme.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: OnboardingTheme.accent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      tutorialTip,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: OnboardingTheme.cream,
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
                  color: OnboardingTheme.muted,
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
      Tooltip(
        message: strings.takeABreak,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPause,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: OnboardingTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: OnboardingTheme.line),
            ),
            child: const Icon(
              Icons.pause_rounded,
              color: OnboardingTheme.cream,
              size: 22,
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              daily
                  ? '${strings.rushHour}  •  ${strings.dailyLabel}'
                  : '${strings.levelNumber(level.number)}${level.boss ? '  •  ${strings.bossLevel}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnboardingTheme.label.copyWith(
                color: OnboardingTheme.accent,
              ),
            ),
            if (!RegExp(r'^(Boss yard|Yard) \d+$').hasMatch(level.title))
              Text(
                strings.levelTitle(level.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: OnboardingTheme.cream,
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
              color: index < lives ? OnboardingTheme.hot : OnboardingTheme.line,
              size: 20,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: OnboardingTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: OnboardingTheme.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: OnboardingTheme.coin,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('$coins', style: OnboardingTheme.display(16)),
          ],
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
    color: selected
        ? OnboardingTheme.accent.withValues(alpha: 0.16)
        : OnboardingTheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? OnboardingTheme.accent : OnboardingTheme.line,
      ),
    ),
    child: InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 5),
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled
                  ? (selected ? OnboardingTheme.accent : OnboardingTheme.cream)
                  : const Color(0xff4a4a52),
              size: 20,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: enabled
                      ? OnboardingTheme.cream
                      : const Color(0xff5e5e66),
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

/// Shared flat shell for the lose and chapter-intro dialogs.
class _DialogCard extends StatelessWidget {
  const _DialogCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: OnboardingTheme.surface,
    surfaceTintColor: Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: OnboardingTheme.line),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: child,
    ),
  );
}

class _DialogBadge extends StatelessWidget {
  const _DialogBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 32),
  );
}

const _pillShape = StadiumBorder();

class _ResultDialog extends StatelessWidget {
  const _ResultDialog({
    required this.won,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.note,
    this.reviveLabel,
    this.reviveEnabled = false,
    this.onRevive,
    this.adLabel,
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
  final String? note;
  final String? reviveLabel;
  final bool reviveEnabled;
  final VoidCallback? onRevive;
  final String? adLabel;
  final String adFailedMessage;
  final Future<bool> Function()? onAd;

  @override
  Widget build(BuildContext context) => _DialogCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DialogBadge(
          icon: won ? Icons.arrow_outward_rounded : Icons.traffic_rounded,
          color: won ? OnboardingTheme.teal : OnboardingTheme.hot,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: OnboardingTheme.display(38),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: OnboardingTheme.muted,
            height: 1.45,
            fontSize: 15,
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 8),
          Text(
            note!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: OnboardingTheme.muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 24),
        if (adLabel != null && onAd != null) ...[
          _AdRewardButton(
            label: adLabel!,
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
                foregroundColor: OnboardingTheme.coin,
                disabledForegroundColor: const Color(0xff5e5e66),
                shape: _pillShape,
                side: BorderSide(
                  color: reviveEnabled
                      ? OnboardingTheme.coin
                      : OnboardingTheme.line,
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
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
              backgroundColor: OnboardingTheme.accent,
              foregroundColor: OnboardingTheme.onAccent,
              shape: _pillShape,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              primaryLabel,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
        TextButton(
          onPressed: onSecondary,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: Text(
            secondaryLabel,
            style: const TextStyle(
              color: OnboardingTheme.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

/// "Ad dekho, reward pao" button. Ad dekhne ke baad ek hi bar kaam karta hai.
class _AdRewardButton extends StatefulWidget {
  const _AdRewardButton({
    required this.label,
    required this.failedMessage,
    required this.onWatch,
  });

  final String label;
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
        backgroundColor: OnboardingTheme.teal,
        foregroundColor: OnboardingTheme.bgTop,
        disabledBackgroundColor: OnboardingTheme.teal.withValues(alpha: 0.16),
        disabledForegroundColor: OnboardingTheme.teal,
        shape: _pillShape,
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_done ? Icons.check_circle_rounded : Icons.play_circle_fill),
      label: Text(
        widget.label,
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
  Widget build(BuildContext context) => _DialogCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _DialogBadge(
          icon: Icons.map_rounded,
          color: OnboardingTheme.accent,
        ),
        const SizedBox(height: 16),
        Text(
          label.toUpperCase(),
          style: OnboardingTheme.label.copyWith(
            color: OnboardingTheme.accent,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          style: OnboardingTheme.display(42),
        ),
        const SizedBox(height: 12),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: OnboardingTheme.muted,
                height: 1.4,
                fontSize: 15,
              ),
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: OnboardingTheme.accent,
              foregroundColor: OnboardingTheme.onAccent,
              shape: _pillShape,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              buttonLabel.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
