import 'package:flame/game.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme_pack.dart';
import '../core/clearway_strings.dart';
import '../core/daily_clock.dart';
import '../data/local_save.dart';
import 'components/yard_game.dart';
import 'data/level_catalog.dart';
import 'engine/game_level.dart';
import 'engine/move_validator.dart';
import 'engine/vehicle.dart';

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
  static const _levelLayoutVersion = 4;
  final _themePack = ThemePack.truckArt;
  ClearwayStrings get strings => ClearwayStrings(widget.save.language);
  late int _levelIndex;
  late GameLevel _level;
  late YardGame _yardGame;
  late List<Vehicle> _remaining;
  List<Vehicle>? _undoSnapshot;
  var _undoUsed = false;
  var _lives = 3;
  var _mistakes = 0;
  var _phase = GamePhase.ready;
  var _assistEnabled = false;
  var _dailyTouched = false;

  @override
  void initState() {
    super.initState();
    _levelIndex = (widget.startingLevel - 1)
        .clamp(0, LevelCatalog.totalLevels - 1)
        .toInt();
    _loadLevel(restore: true);
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
    _persistActiveBoard();
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
    if (_lives == 0) _phase = GamePhase.lost;
  }

  String get _dailyDayKey => widget.dailyDayKey ?? DailyClock.dayKey();

  String? get _tutorialVehicleId {
    if (widget.daily || _level.number > 3) return null;
    return MoveValidator.safeVehicles(_level, _remaining).firstOrNull?.id;
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
    };
    unawaited(widget.save.save(notify: false));
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
      if (widget.save.sound) SystemSound.play(SystemSoundType.click);
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
    if (widget.save.sound) SystemSound.play(SystemSoundType.alert);
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.outOfHintsShort)));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.outOfUndosShort)));
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
    final stars = _mistakes == 0
        ? 3
        : _mistakes == 1
        ? 2
        : 1;
    final isLast = widget.daily || _levelIndex == LevelCatalog.totalLevels - 1;
    if (!isLast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        scheduleMicrotask(() {
          if (mounted) LevelCatalog.getLevel(_level.number + 1);
        });
      });
    }
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
    }
    _clearActiveBoard();
    await widget.save.save();
    widget.onLevelWon();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        won: true,
        title: strings.wayClear,
        message: strings.allVehiclesOut,
        stars: stars,
        primaryLabel: isLast ? strings.backToYard : strings.nextLevel,
        onPrimary: () {
          Navigator.pop(context);
          if (isLast) {
            _clearActiveBoard();
            widget.save.save();
            widget.onHome(_level.number);
          } else {
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
      ),
    );
  }

  Future<void> _showLoseDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        won: false,
        title: strings.trafficJam,
        message: strings.retryMessage,
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

  @override
  Widget build(BuildContext context) {
    final safeCount = MoveValidator.safeVehicles(_level, _remaining).length;
    final tutorialTip = _tutorialTip;
    return Scaffold(
      backgroundColor: _themePack.asphalt,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            children: [
              _TopBar(
                level: _level,
                lives: _lives,
                onPause: _showPauseDialog,
                daily: widget.daily,
                coins: widget.save.coins,
                strings: strings,
              ),
              if (tutorialTip != null) ...[
                const SizedBox(height: 9),
                Container(
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
              ],
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: InteractiveViewer(
                        panEnabled: _level.width >= 9,
                        scaleEnabled: _level.width >= 9,
                        minScale: 1,
                        maxScale: 2.2,
                        boundaryMargin: const EdgeInsets.all(48),
                        child: GameWidget<YardGame>(game: _yardGame),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _ActionBar(
                onHint: _useHint,
                hintCount: widget.save.hints,
                onUndo: _undo,
                undoCount: widget.save.undos,
                undoEnabled: !_undoUsed && _undoSnapshot != null,
                assistEnabled: _assistEnabled,
                safeCount: safeCount,
                onAssistChanged: _toggleAssist,
                strings: strings,
              ),
              const SizedBox(height: 8),
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

  String? get _tutorialTip {
    if (widget.daily) return null;
    return switch (_level.number) {
      1 => strings.firstDepartureTip,
      2 => strings.blockedVehicleTip,
      3 => strings.orderTip,
      10 => strings.coneTip,
      25 => strings.gateTip,
      40 => strings.convoyTip,
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
                  : '${strings.levelNumber(level.number)}${level.boss ? '  •  ${strings.bossYard}' : ''}',
              style: const TextStyle(
                color: Color(0xffffb347),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
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
    this.stars = 0,
  });

  final bool won;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;
  final int stars;

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
              won ? Icons.local_shipping_rounded : Icons.traffic_rounded,
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
          const SizedBox(height: 24),
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
          TextButton(
            onPressed: onSecondary,
            child: Text(
              secondaryLabel,
              style: const TextStyle(color: Color(0xffc6d2ca)),
            ),
          ),
        ],
      ),
    ),
  );
}
