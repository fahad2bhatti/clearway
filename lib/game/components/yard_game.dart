import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../../app/theme_pack.dart';
import '../engine/game_level.dart';
import '../engine/grid_point.dart';
import '../engine/vehicle.dart';

typedef VehicleTap = void Function(Vehicle vehicle);

/// Flame owns the board drawing, hit testing and short vehicle feedback.
final class YardGame extends FlameGame with TapCallbacks {
  YardGame({
    required this.level,
    required this.onVehicleTap,
    this.themePack = ThemePack.truckArt,
  });

  final GameLevel level;
  final VehicleTap onVehicleTap;
  final ThemePack themePack;

  List<Vehicle> vehicles = [];
  String? suggestedVehicleId;
  Set<String> assistedVehicleIds = const {};
  String? blockerVehicleId;
  String? _bumpedVehicleId;
  double _feedbackRemaining = 0;
  final Map<String, _ExitingVehicle> _exiting = {};

  ui.Rect _boardRect = ui.Rect.zero;
  double _cellSize = 0;

  @override
  Color backgroundColor() => themePack.asphalt;

  void showExit(Vehicle vehicle) {
    _exiting[vehicle.id] = _ExitingVehicle(vehicle);
  }

  void showBlocked(String movingId, String blockerId) {
    _bumpedVehicleId = movingId;
    blockerVehicleId = blockerId;
    _feedbackRemaining = 0.3;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_feedbackRemaining > 0) {
      _feedbackRemaining = math.max(0, _feedbackRemaining - dt).toDouble();
      if (_feedbackRemaining == 0) {
        _bumpedVehicleId = null;
        blockerVehicleId = null;
      }
    }
    final finished = <String>[];
    for (final entry in _exiting.entries) {
      entry.value.progress += dt / 0.23;
      if (entry.value.progress >= 1) finished.add(entry.key);
    }
    for (final id in finished) {
      _exiting.remove(id);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;

    _cellSize = math
        .min(size.x * 0.9 / level.width, size.y * 0.88 / level.height)
        .toDouble();
    final width = _cellSize * level.width;
    final height = _cellSize * level.height;
    _boardRect = ui.Rect.fromLTWH(
      (size.x - width) / 2,
      (size.y - height) / 2,
      width,
      height,
    );

    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        _boardRect.inflate(8),
        const ui.Radius.circular(26),
      ),
      ui.Paint()..color = themePack.yardSurface,
    );
    _drawGrid(canvas);
    for (var index = 0; index < vehicles.length; index++) {
      final vehicle = vehicles[index];
      _drawVehicle(canvas, vehicle, index);
    }
    for (final exiting in _exiting.values) {
      _drawVehicle(canvas, exiting.vehicle, 0, exitProgress: exiting.progress);
    }
  }

  void _drawGrid(ui.Canvas canvas) {
    final paint = ui.Paint()
      ..color = themePack.gridLine
      ..strokeWidth = 1.2
      ..style = ui.PaintingStyle.stroke;
    for (var column = 0; column <= level.width; column++) {
      final x = _boardRect.left + column * _cellSize;
      canvas.drawLine(
        ui.Offset(x, _boardRect.top),
        ui.Offset(x, _boardRect.bottom),
        paint,
      );
    }
    for (var row = 0; row <= level.height; row++) {
      final y = _boardRect.top + row * _cellSize;
      canvas.drawLine(
        ui.Offset(_boardRect.left, y),
        ui.Offset(_boardRect.right, y),
        paint,
      );
    }
    final border = ui.Paint()
      ..color = themePack.accent.withValues(alpha: 0.75)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(_boardRect, const ui.Radius.circular(10)),
      border,
    );
  }

  void _drawVehicle(
    ui.Canvas canvas,
    Vehicle vehicle,
    int index, {
    double exitProgress = 0,
  }) {
    final minRow = vehicle.cells
        .map((cell) => cell.row)
        .reduce((a, b) => a < b ? a : b);
    final maxRow = vehicle.cells
        .map((cell) => cell.row)
        .reduce((a, b) => a > b ? a : b);
    final minColumn = vehicle.cells
        .map((cell) => cell.column)
        .reduce((a, b) => a < b ? a : b);
    final maxColumn = vehicle.cells
        .map((cell) => cell.column)
        .reduce((a, b) => a > b ? a : b);
    var rect = ui.Rect.fromLTRB(
      _boardRect.left + minColumn * _cellSize + 4,
      _boardRect.top + minRow * _cellSize + 4,
      _boardRect.left + (maxColumn + 1) * _cellSize - 4,
      _boardRect.top + (maxRow + 1) * _cellSize - 4,
    );
    final unshiftedTopLeft = rect.topLeft;

    final flash = blockerVehicleId == vehicle.id && _feedbackRemaining > 0;
    final bumped = _bumpedVehicleId == vehicle.id && _feedbackRemaining > 0;
    if (bumped) {
      final shake =
          math.sin((0.3 - _feedbackRemaining) * 100) * _cellSize * 0.055;
      rect = rect.shift(ui.Offset(shake, 0));
    }
    if (exitProgress > 0) {
      final distance =
          exitProgress *
          (_cellSize * 1.6 + math.max(size.x, size.y).toDouble() * 0.35);
      rect = rect.shift(
        ui.Offset(
          vehicle.direction.columnStep * distance,
          vehicle.direction.rowStep * distance,
        ),
      );
    }

    final color = flash
        ? themePack.coral
        : themePack.vehicleColors[index % themePack.vehicleColors.length];
    final radius = ui.Radius.circular(_cellSize * 0.2);
    final shadow = ui.Paint()
      ..color = const Color(0xff071013).withValues(alpha: 0.45)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, _cellSize * 0.08);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(rect.shift(ui.Offset(0, 3)), radius),
      shadow,
    );

    final body = ui.Paint()..color = color;
    canvas.drawRRect(ui.RRect.fromRectAndRadius(rect, radius), body);
    final inner = rect.deflate(_cellSize * 0.07);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(inner, ui.Radius.circular(_cellSize * 0.15)),
      ui.Paint()
        ..color = themePack.ivory.withValues(alpha: 0.22)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );

    _drawDecorativeStripe(canvas, vehicle, rect, color);
    _drawCabAndWheels(
      canvas,
      vehicle,
      rect,
      color,
      rect.topLeft - unshiftedTopLeft,
    );
    if (suggestedVehicleId == vehicle.id ||
        assistedVehicleIds.contains(vehicle.id)) {
      _drawHint(canvas, rect);
    }
  }

  void _drawDecorativeStripe(
    ui.Canvas canvas,
    Vehicle vehicle,
    ui.Rect rect,
    Color color,
  ) {
    final horizontal =
        vehicle.direction == TravelDirection.left ||
        vehicle.direction == TravelDirection.right;
    final accent = ui.Paint()
      ..color = themePack.ivory.withValues(alpha: 0.88)
      ..strokeWidth = math.max(1.5, _cellSize * 0.045)
      ..strokeCap = ui.StrokeCap.round;
    if (horizontal) {
      final y = rect.center.dy;
      canvas.drawLine(
        ui.Offset(rect.left + 7, y),
        ui.Offset(rect.right - 7, y),
        accent,
      );
      for (var dot = 0; dot < vehicle.cells.length; dot++) {
        final x = rect.left + rect.width * (dot + 0.5) / vehicle.cells.length;
        canvas.drawCircle(
          ui.Offset(x, y - _cellSize * 0.14),
          _cellSize * 0.045,
          ui.Paint()..color = themePack.floralMagenta,
        );
      }
    } else {
      final x = rect.center.dx;
      canvas.drawLine(
        ui.Offset(x, rect.top + 7),
        ui.Offset(x, rect.bottom - 7),
        accent,
      );
      for (var dot = 0; dot < vehicle.cells.length; dot++) {
        final y = rect.top + rect.height * (dot + 0.5) / vehicle.cells.length;
        canvas.drawCircle(
          ui.Offset(x + _cellSize * 0.14, y),
          _cellSize * 0.045,
          ui.Paint()..color = themePack.turquoise,
        );
      }
    }
    // Small floral rosettes are drawn from simple original vector shapes.
    if (!themePack.showFloralMotifs) return;
    final center = rect.center;
    final flowerRadius = _cellSize * 0.09;
    for (var petal = 0; petal < 4; petal++) {
      final angle = petal * math.pi / 2;
      canvas.drawCircle(
        center + ui.Offset(math.cos(angle), math.sin(angle)) * flowerRadius,
        flowerRadius * 0.34,
        ui.Paint()
          ..color = petal.isEven
              ? themePack.floralMagenta
              : themePack.turquoise,
      );
    }
    canvas.drawCircle(
      center,
      flowerRadius * 0.3,
      ui.Paint()..color = themePack.ivory,
    );
  }

  void _drawCabAndWheels(
    ui.Canvas canvas,
    Vehicle vehicle,
    ui.Rect rect,
    Color color,
    ui.Offset animationOffset,
  ) {
    final headRect = _cellRect(vehicle.head)
        .shift(animationOffset)
        .deflate(_cellSize * 0.13);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        headRect,
        ui.Radius.circular(_cellSize * 0.14),
      ),
      ui.Paint()..color = color.withValues(alpha: 0.74),
    );
    final window = headRect.deflate(_cellSize * 0.18);
    final glassRect = switch (vehicle.direction) {
      TravelDirection.right => ui.Rect.fromLTWH(
        window.right - window.width * 0.45,
        window.top,
        window.width * 0.45,
        window.height,
      ),
      TravelDirection.left => ui.Rect.fromLTWH(
        window.left,
        window.top,
        window.width * 0.45,
        window.height,
      ),
      TravelDirection.up => ui.Rect.fromLTWH(
        window.left,
        window.top,
        window.width,
        window.height * 0.45,
      ),
      TravelDirection.down => ui.Rect.fromLTWH(
        window.left,
        window.bottom - window.height * 0.45,
        window.width,
        window.height * 0.45,
      ),
    };
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        glassRect,
        ui.Radius.circular(_cellSize * 0.07),
      ),
      ui.Paint()..color = const Color(0xff183840),
    );

    final wheel = ui.Paint()..color = const Color(0xff182329);
    final wheelRadius = _cellSize * 0.075;
    if (vehicle.direction == TravelDirection.left ||
        vehicle.direction == TravelDirection.right) {
      canvas.drawCircle(
        ui.Offset(rect.left + _cellSize * 0.25, rect.bottom - 2),
        wheelRadius,
        wheel,
      );
      canvas.drawCircle(
        ui.Offset(rect.right - _cellSize * 0.25, rect.bottom - 2),
        wheelRadius,
        wheel,
      );
    } else {
      canvas.drawCircle(
        ui.Offset(rect.right - 2, rect.top + _cellSize * 0.25),
        wheelRadius,
        wheel,
      );
      canvas.drawCircle(
        ui.Offset(rect.right - 2, rect.bottom - _cellSize * 0.25),
        wheelRadius,
        wheel,
      );
    }
    final lights = ui.Paint()..color = themePack.ivory;
    switch (vehicle.direction) {
      case TravelDirection.right:
        canvas.drawCircle(
          ui.Offset(rect.right - 3, rect.top + _cellSize * 0.2),
          _cellSize * 0.04,
          lights,
        );
        canvas.drawCircle(
          ui.Offset(rect.right - 3, rect.bottom - _cellSize * 0.2),
          _cellSize * 0.04,
          lights,
        );
      case TravelDirection.left:
        canvas.drawCircle(
          ui.Offset(rect.left + 3, rect.top + _cellSize * 0.2),
          _cellSize * 0.04,
          lights,
        );
        canvas.drawCircle(
          ui.Offset(rect.left + 3, rect.bottom - _cellSize * 0.2),
          _cellSize * 0.04,
          lights,
        );
      case TravelDirection.up:
        canvas.drawCircle(
          ui.Offset(rect.left + _cellSize * 0.2, rect.top + 3),
          _cellSize * 0.04,
          lights,
        );
        canvas.drawCircle(
          ui.Offset(rect.right - _cellSize * 0.2, rect.top + 3),
          _cellSize * 0.04,
          lights,
        );
      case TravelDirection.down:
        canvas.drawCircle(
          ui.Offset(rect.left + _cellSize * 0.2, rect.bottom - 3),
          _cellSize * 0.04,
          lights,
        );
        canvas.drawCircle(
          ui.Offset(rect.right - _cellSize * 0.2, rect.bottom - 3),
          _cellSize * 0.04,
          lights,
        );
    }
  }

  void _drawHint(ui.Canvas canvas, ui.Rect rect) {
    final pulse = 0.42 + 0.18 * math.sin(nowSeconds * 7);
    canvas.drawRRect(
      ui.RRect.fromRectAndRadius(
        rect.inflate(4),
        ui.Radius.circular(_cellSize * 0.22),
      ),
      ui.Paint()
        ..color = themePack.ivory.withValues(alpha: pulse)
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
  }

  ui.Rect _cellRect(GridPoint cell) => ui.Rect.fromLTWH(
    _boardRect.left + cell.column * _cellSize,
    _boardRect.top + cell.row * _cellSize,
    _cellSize,
    _cellSize,
  );

  @override
  void onTapDown(TapDownEvent event) {
    final point = ui.Offset(event.canvasPosition.x, event.canvasPosition.y);
    if (!_boardRect.contains(point)) return;
    Vehicle? nearest;
    var nearestDistance = _cellSize * 0.68;
    for (final vehicle in vehicles) {
      for (final cell in vehicle.cells) {
        final center = _cellRect(cell).center;
        final distance = (center - point).distance;
        if (distance < nearestDistance) {
          nearest = vehicle;
          nearestDistance = distance;
        }
      }
    }
    if (nearest != null) onVehicleTap(nearest);
  }

  double get nowSeconds => DateTime.now().millisecondsSinceEpoch / 1000;
}

final class _ExitingVehicle {
  _ExitingVehicle(this.vehicle);

  final Vehicle vehicle;
  double progress = 0;
}
