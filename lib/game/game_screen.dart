import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme_pack.dart';
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
  });

  final int startingLevel;
  final ValueChanged<int> onHome;
  final ValueChanged<int> onLevelChanged;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _themePack = ThemePack.truckArt;
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

  @override
  void initState() {
    super.initState();
    _levelIndex = (widget.startingLevel - 1)
        .clamp(0, LevelCatalog.levels.length - 1)
        .toInt();
    _loadLevel();
  }

  void _loadLevel() {
    _level = LevelCatalog.levels[_levelIndex];
    _remaining = _level.vehicles.map((vehicle) => vehicle.copy()).toList();
    _undoSnapshot = null;
    _undoUsed = false;
    _lives = 3;
    _mistakes = 0;
    _phase = GamePhase.ready;
    _assistEnabled = false;
    _yardGame =
        YardGame(
            level: _level,
            onVehicleTap: _onVehicleTap,
            themePack: _themePack,
          )
          ..vehicles = _remaining
          ..suggestedVehicleId = null;
  }

  void _onVehicleTap(Vehicle vehicle) {
    if (_phase != GamePhase.ready ||
        !_remaining.any((item) => item.id == vehicle.id)) {
      return;
    }
    final result = MoveValidator.check(_level, _remaining, vehicle);
    if (result.canEscape) {
      HapticFeedback.selectionClick();
      setState(() {
        _phase = GamePhase.animating;
        _undoSnapshot = List.of(_remaining);
        _remaining.removeWhere((item) => item.id == vehicle.id);
        _yardGame
          ..showExit(vehicle)
          ..vehicles = List.of(_remaining)
          ..suggestedVehicleId = null
          ..assistedVehicleIds = const {};
      });
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

    HapticFeedback.lightImpact();
    setState(() {
      _mistakes++;
      _lives--;
      _phase = GamePhase.animating;
      _yardGame.showBlocked(vehicle.id, result.blockerId ?? '');
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Blocked by another vehicle'),
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
    final safe = MoveValidator.safeVehicles(_level, _remaining);
    if (safe.isEmpty) return;
    setState(() {
      _yardGame.suggestedVehicleId = safe.first.id;
      _yardGame.assistedVehicleIds = const {};
    });
  }

  void _toggleAssist(bool value) {
    final safeIds = MoveValidator.safeVehicles(
      _level,
      _remaining,
    ).map((v) => v.id).toSet();
    setState(() {
      _assistEnabled = value;
      _yardGame.assistedVehicleIds = value ? safeIds : const {};
      if (value) _yardGame.suggestedVehicleId = null;
    });
  }

  void _undo() {
    if (_phase != GamePhase.ready || _undoUsed || _undoSnapshot == null) return;
    setState(() {
      _remaining = List.of(_undoSnapshot!);
      _undoSnapshot = null;
      _undoUsed = true;
      _yardGame
        ..vehicles = _remaining
        ..suggestedVehicleId = null
        ..assistedVehicleIds = const {};
    });
  }

  Future<void> _showWinDialog() async {
    final stars = _mistakes == 0
        ? 3
        : _mistakes == 1
        ? 2
        : 1;
    final isLast = _levelIndex == LevelCatalog.levels.length - 1;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ResultDialog(
        won: true,
        title: 'Way clear!',
        message: 'You guided every vehicle out of the yard.',
        stars: stars,
        primaryLabel: isLast ? 'Back to yard' : 'Next level',
        onPrimary: () {
          Navigator.pop(context);
          if (isLast) {
            widget.onHome(_level.number);
          } else {
            setState(() {
              _levelIndex++;
              _loadLevel();
            });
            widget.onLevelChanged(_level.number);
          }
        },
        secondaryLabel: 'Replay',
        onSecondary: () {
          Navigator.pop(context);
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
        title: 'Traffic jam!',
        message: 'Take a breath and try a different order.',
        primaryLabel: 'Try again',
        onPrimary: () {
          Navigator.pop(context);
          setState(_loadLevel);
        },
        secondaryLabel: 'Home',
        onSecondary: () {
          Navigator.pop(context);
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
        title: const Text(
          'Take a break',
          style: TextStyle(color: Color(0xfffff3d8)),
        ),
        content: const Text(
          'Your place in the yard is right here.',
          style: TextStyle(color: Color(0xffc6d2ca)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _phase = GamePhase.ready);
            },
            child: const Text('Keep playing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(_loadLevel);
            },
            child: const Text('Restart level'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onHome(_level.number);
            },
            child: const Text('Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeCount = MoveValidator.safeVehicles(_level, _remaining).length;
    return Scaffold(
      backgroundColor: _themePack.asphalt,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            children: [
              _TopBar(level: _level, lives: _lives, onPause: _showPauseDialog),
              const SizedBox(height: 18),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: GameWidget<YardGame>(game: _yardGame),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _ActionBar(
                onHint: _useHint,
                onUndo: _undo,
                undoEnabled: !_undoUsed && _undoSnapshot != null,
                assistEnabled: _assistEnabled,
                safeCount: safeCount,
                onAssistChanged: _toggleAssist,
              ),
              const SizedBox(height: 8),
              Text(
                _remaining.isEmpty
                    ? _themePack.emptyYardMessage
                    : '${_remaining.length} ${_themePack.vehicleNoun}${_remaining.length == 1 ? '' : 's'} still in the yard',
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
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.level,
    required this.lives,
    required this.onPause,
  });

  final GameLevel level;
  final int lives;
  final VoidCallback onPause;

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
              'LEVEL ${level.number.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Color(0xffffb347),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                fontSize: 11,
              ),
            ),
            Text(
              level.title,
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
    ],
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.onHint,
    required this.onUndo,
    required this.undoEnabled,
    required this.assistEnabled,
    required this.safeCount,
    required this.onAssistChanged,
  });

  final VoidCallback onHint;
  final VoidCallback onUndo;
  final bool undoEnabled;
  final bool assistEnabled;
  final int safeCount;
  final ValueChanged<bool> onAssistChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _ActionButton(
          icon: Icons.lightbulb_rounded,
          label: 'Hint',
          onTap: onHint,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionButton(
          icon: Icons.undo_rounded,
          label: 'Undo',
          enabled: undoEnabled,
          onTap: onUndo,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionButton(
          icon: assistEnabled ? Icons.grid_on_rounded : Icons.grid_4x4_rounded,
          label: assistEnabled ? 'Assist on' : 'Grid assist',
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
