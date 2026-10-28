import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import '../../app/theme_pack.dart';
import '../engine/game_level.dart';
import '../engine/grid_point.dart';
import '../engine/vehicle.dart';
import 'tap_gate.dart';

typedef VehicleTap = void Function(Vehicle vehicle);

/// Flame owns the board drawing, hit testing and short vehicle feedback.
final class YardGame extends FlameGame with TapCallbacks {
  static const _minColumns = 7;

  YardGame({
    required this.level,
    required this.onVehicleTap,
    this.themePack = ThemePack.truckArt,
    this.colorblindMode = false,
  });

  final GameLevel level;
  final VehicleTap onVehicleTap;
  final ThemePack themePack;
  final bool colorblindMode;

  List<Vehicle> _vehicles = [];
  List<Vehicle> get vehicles => _vehicles;
  set vehicles(List<Vehicle> value) {
    _vehicles = value;
    _invalidateScene();
  }

  String? _suggestedVehicleId;
  String? get suggestedVehicleId => _suggestedVehicleId;
  set suggestedVehicleId(String? value) {
    _suggestedVehicleId = value;
    _invalidateScene();
  }

  Set<String> _assistedVehicleIds = const {};
  Set<String> get assistedVehicleIds => _assistedVehicleIds;
  set assistedVehicleIds(Set<String> value) {
    _assistedVehicleIds = value;
    _invalidateScene();
  }

  // The still board is recorded once and replayed as one picture, so idle
  // frames cost almost nothing even with hundreds of vehicles.
  ui.Picture? _scene;
  bool _sceneDirty = true;

  void _invalidateScene() => _sceneDirty = true;

  @override
  void onRemove() {
    _scene?.dispose();
    _scene = null;
    super.onRemove();
  }

  String? blockerVehicleId;
  GridPoint? blockerCell;
  String? _bumpedVehicleId;
  double _feedbackRemaining = 0;
  final Map<String, _ExitingVehicle> _exiting = {};
  final TapGate _tapGate = TapGate();

  ui.Rect _boardRect = ui.Rect.zero;
  double _cellSize = 0;
  ui.Path? _silhouette;
  String _silhouetteKey = '';

  // Per-bus geometry only changes when the board is resized, so it is built
  // once and reused every frame instead of being rebuilt 60 times a second.
  final Map<Vehicle, _VehicleShape> _shapes = Map.identity();
  double _shapesCellSize = -1;
  ui.Rect _shapesBoard = ui.Rect.zero;

  // Reused paints: no per-frame allocation inside render().
  late final ui.Paint _surface = ui.Paint()..color = themePack.yardSurface;
  final ui.Paint _fill = ui.Paint();
  final ui.Paint _stroke = ui.Paint()
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeJoin = ui.StrokeJoin.round;
  final ui.Paint _dashPaint = ui.Paint()..style = ui.PaintingStyle.stroke;
  static final TextPainter _pointer = TextPainter(
    text: const TextSpan(text: '\u{1F446}', style: TextStyle(fontSize: 22)),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  Color backgroundColor() => themePack.asphalt;

  void showExit(Vehicle vehicle) {
    _exiting[vehicle.id] = _ExitingVehicle(vehicle);
  }

  /// Drops running exit animations, e.g. when an undo brings the arrows back.
  void clearExits() => _exiting.clear();

  void showBlocked(String movingId, String blockerId, {GridPoint? cell}) {
    _bumpedVehicleId = movingId;
    blockerVehicleId = blockerId;
    blockerCell = cell;
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
        blockerCell = null;
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

    // The board takes almost the whole play area, but a cell never grows past
    // 1/7 of the screen width, so small early boards keep slim arrows.
    final cellSize = math
        .min(
          math.min(size.x * 0.96 / level.width, size.y * 0.97 / level.height),
          size.x / _minColumns,
        )
        .toDouble();
    final width = cellSize * level.width;
    final height = cellSize * level.height;
    final boardRect = ui.Rect.fromLTWH(
      (size.x - width) / 2,
      (size.y - height) / 2,
      width,
      height,
    );
    if (cellSize != _cellSize || boardRect != _boardRect) {
      _cellSize = cellSize;
      _boardRect = boardRect;
      _sceneDirty = true;
    }
    if (_cellSize != _shapesCellSize || _boardRect != _shapesBoard) {
      _shapes.clear();
      _shapesCellSize = _cellSize;
      _shapesBoard = _boardRect;
    }

    // Anything that moves is drawn live; a still board is cached, including
    // its hint and assist highlights, which are static.
    final live = _feedbackRemaining > 0 || _exiting.isNotEmpty;
    if (live) {
      _scene?.dispose();
      _scene = null;
      _sceneDirty = true;
      _paintScene(canvas);
      return;
    }
    if (_sceneDirty || _scene == null) {
      _scene?.dispose();
      final recorder = ui.PictureRecorder();
      _paintScene(ui.Canvas(recorder));
      _scene = recorder.endRecording();
      _sceneDirty = false;
    }
    canvas.drawPicture(_scene!);
  }

  void _paintScene(ui.Canvas canvas) {
    _drawBoard(canvas);
    _drawObstacles(canvas);
    if (_feedbackRemaining > 0 && blockerCell != null) {
      final rect = _cellRect(blockerCell!).deflate(_cellSize * .07);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(_cellSize * .15)),
        _fill..color = themePack.coral.withValues(alpha: .48),
      );
    }
    for (var index = 0; index < vehicles.length; index++) {
      _drawVehicle(canvas, vehicles[index], index);
    }
    for (final exiting in _exiting.values) {
      _drawVehicle(canvas, exiting.vehicle, 0, exitProgress: exiting.progress);
    }
  }

  void _drawObstacles(ui.Canvas canvas) {
    for (final cone in level.cones) {
      final rect = _cellRect(cone).deflate(_cellSize * .19);
      final path = ui.Path()
        ..moveTo(rect.center.dx, rect.top)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.left, rect.bottom)
        ..close();
      canvas.drawPath(path, ui.Paint()..color = themePack.accent);
      canvas.drawLine(
        ui.Offset(rect.left + 2, rect.bottom - 3),
        ui.Offset(rect.right - 2, rect.bottom - 3),
        ui.Paint()
          ..color = themePack.ivory
          ..strokeWidth = 2.3,
      );
      canvas.drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(rect.center.dx, rect.bottom + 2),
          width: rect.width + 5,
          height: 4,
        ),
        ui.Paint()..color = const Color(0xff121a1d),
      );
    }
    for (final gate in level.gates) {
      final rect = _cellRect(gate.position).deflate(_cellSize * .13);
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(_cellSize * .12)),
        ui.Paint()..color = themePack.coral.withValues(alpha: .84),
      );
      final center = rect.center;
      final direction = gate.direction.step;
      final tip =
          center +
          ui.Offset(
            direction.column * _cellSize * .22,
            direction.row * _cellSize * .22,
          );
      final tail =
          center -
          ui.Offset(
            direction.column * _cellSize * .17,
            direction.row * _cellSize * .17,
          );
      final wing = ui.Offset(
        -direction.row * _cellSize * .13,
        direction.column * _cellSize * .13,
      );
      final arrow = ui.Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tail.dx + wing.dx, tail.dy + wing.dy)
        ..lineTo(tail.dx - wing.dx, tail.dy - wing.dy)
        ..close();
      canvas.drawPath(arrow, ui.Paint()..color = themePack.ivory);
    }
  }

  /// The yard floor. A silhouette yard paints only its own cells. There is no
  /// visible grid, so the buses read as lines drawn on the floor.
  void _drawBoard(ui.Canvas canvas) {
    final shape = level.shape;
    final surface = _surface;
    if (shape == null) {
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          _boardRect.inflate(5),
          const ui.Radius.circular(26),
        ),
        surface,
      );
      return;
    }
    // A full rectangle gets no backing box: arrows sit on the screen itself.
    if (shape.length == level.width * level.height) return;
    final key = '$_cellSize:${_boardRect.left}:${_boardRect.top}';
    if (_silhouette == null || _silhouetteKey != key) {
      final path = ui.Path();
      for (final cell in shape) {
        path.addRect(_cellRect(cell).inflate(_cellSize * 0.04));
      }
      _silhouette = path;
      _silhouetteKey = key;
    }
    canvas.drawPath(_silhouette!, surface);
  }

  void _drawVehicle(
    ui.Canvas canvas,
    Vehicle vehicle,
    int index, {
    double exitProgress = 0,
  }) {
    final flash = blockerVehicleId == vehicle.id && _feedbackRemaining > 0;
    final bumped = _bumpedVehicleId == vehicle.id && _feedbackRemaining > 0;
    // Colour follows the bus id, so it stays the same while others leave.
    final colorIndex = int.tryParse(vehicle.id.split('-').last) ?? index;
    final color = flash
        ? themePack.coral
        : themePack.vehicleColors[colorIndex % themePack.vehicleColors.length];

    final _VehicleShape? shape;
    if (exitProgress > 0) {
      // Exit animation changes every frame, so it is never cached.
      shape = _buildShape(_exitPoints(vehicle, exitProgress));
    } else {
      var cached = _shapes[vehicle];
      if (cached == null) {
        cached = _buildShape([
          for (final cell in vehicle.cells.reversed) _cellRect(cell).center,
        ]);
        if (cached != null) _shapes[vehicle] = cached;
      }
      shape = cached;
    }
    if (shape == null) return;
    final lineWidth = math.max(1.6, _cellSize * 0.26).toDouble();

    canvas.save();
    if (bumped) {
      final shake =
          math.sin((0.3 - _feedbackRemaining) * 100) * _cellSize * 0.055;
      canvas.translate(shake, 0);
    }
    canvas.drawPath(
      shape.shadow,
      _stroke
        ..color = _shadowColor
        ..strokeWidth = lineWidth,
    );
    final hinted =
        suggestedVehicleId == vehicle.id ||
        assistedVehicleIds.contains(vehicle.id);
    if (hinted && exitProgress == 0) _drawHint(canvas, shape.path);
    canvas.drawPath(
      shape.path,
      _stroke
        ..color = color
        ..strokeWidth = lineWidth,
    );
    canvas.drawPath(shape.arrow, _fill..color = color);
    if (colorblindMode) {
      _drawPattern(canvas, shape.path, shape, colorIndex % 5, exitProgress > 0);
    }
    canvas.restore();

    if (level.number <= 3 && suggestedVehicleId == vehicle.id) {
      final headCenter = _cellRect(vehicle.head).center;
      canvas.drawRRect(
        ui.RRect.fromRectAndRadius(
          ui.Rect.fromCenter(
            center: headCenter.translate(0, -_cellSize * .1),
            width: _cellSize * .58,
            height: _cellSize * .58,
          ),
          ui.Radius.circular(_cellSize * .18),
        ),
        _fill..color = themePack.yardSurface.withValues(alpha: .92),
      );
      _pointer.paint(
        canvas,
        ui.Offset(
          headCenter.dx - _pointer.width / 2,
          headCenter.dy - _pointer.height / 2 - _cellSize * .1,
        ),
      );
    }
  }

  static const _shadowColor = Color(0x73071013);

  /// Path, shadow and arrow head for a bus drawn through [points]
  /// (tail first, head last).
  _VehicleShape? _buildShape(List<ui.Offset> points) {
    if (points.length < 2) return null;
    final path = _roundedPath(points);
    final last = points[points.length - 1];
    final before = points[points.length - 2];
    final heading = (last - before) / (last - before).distance;
    return _VehicleShape(
      path: path,
      shadow: path.shift(ui.Offset(0, _cellSize * 0.05)),
      arrow: _arrowPath(last, heading),
    );
  }

  /// Smooth line through the cell centres (tail first, head last) with
  /// rounded corners, so a bent bus looks like one curved snake.
  ui.Path _roundedPath(List<ui.Offset> points) {
    final path = ui.Path()..moveTo(points.first.dx, points.first.dy);
    final radius = _cellSize * 0.32;
    for (var i = 1; i < points.length - 1; i++) {
      final a = points[i - 1];
      final b = points[i];
      final c = points[i + 1];
      final ab = b - a;
      final bc = c - b;
      final cross = ab.dx * bc.dy - ab.dy * bc.dx;
      if (cross.abs() < 1e-6) continue; // straight on, no corner here
      final entry = b - ab / ab.distance * math.min(radius, ab.distance / 2);
      final exit = b + bc / bc.distance * math.min(radius, bc.distance / 2);
      path.lineTo(entry.dx, entry.dy);
      path.quadraticBezierTo(b.dx, b.dy, exit.dx, exit.dy);
    }
    path.lineTo(points.last.dx, points.last.dy);
    return path;
  }

  ui.Path _arrowPath(ui.Offset at, ui.Offset heading) {
    final tip = at + heading * (_cellSize * 0.5);
    final base = at - heading * (_cellSize * 0.04);
    final side = ui.Offset(-heading.dy, heading.dx) * (_cellSize * 0.34);
    return ui.Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(base.dx + side.dx, base.dy + side.dy)
      ..lineTo(base.dx - side.dx, base.dy - side.dy)
      ..close();
  }

  /// Snake-style exit: the head drives straight out of the yard and the body
  /// follows the path it already lies on, until the whole bus has left.
  List<ui.Offset> _exitPoints(Vehicle vehicle, double progress) {
    final bodyCells = vehicle.cells.length - 1;
    final toEdge = switch (vehicle.direction) {
      TravelDirection.up => vehicle.head.row,
      TravelDirection.down => level.height - 1 - vehicle.head.row,
      TravelDirection.left => vehicle.head.column,
      TravelDirection.right => level.width - 1 - vehicle.head.column,
    };
    final step =
        ui.Offset(
          vehicle.direction.columnStep.toDouble(),
          vehicle.direction.rowStep.toDouble(),
        ) *
        _cellSize;
    // Tail ... head, then straight on past the edge of the yard.
    final line = <ui.Offset>[
      for (final cell in vehicle.cells.reversed) _cellRect(cell).center,
    ];
    final extra = bodyCells + toEdge + 2;
    for (var k = 1; k <= extra; k++) {
      line.add(line[bodyCells] + step * k.toDouble());
    }
    final travel = (bodyCells + toEdge + 1).toDouble();
    final eased = (0.35 * progress + 0.65 * progress * progress).clamp(
      0.0,
      1.0,
    );
    final from = eased * travel;
    final to = from + bodyCells;
    final result = <ui.Offset>[_pointAt(line, from)];
    for (var i = from.floor() + 1; i <= to.floor(); i++) {
      result.add(line[i]);
    }
    final end = _pointAt(line, to);
    if ((end - result.last).distance > _cellSize * 0.01) result.add(end);
    return result;
  }

  /// Point at [position] segments along [line] (all segments are one cell).
  ui.Offset _pointAt(List<ui.Offset> line, double position) {
    final i = math.min(math.max(position.floor(), 0), line.length - 2);
    return ui.Offset.lerp(line[i], line[i + 1], position - i)!;
  }

  /// Colour-blind mode: every bus colour gets its own dash pattern.
  void _drawPattern(
    ui.Canvas canvas,
    ui.Path path,
    _VehicleShape shape,
    int kind,
    bool animated,
  ) {
    final dashes = animated
        ? _dashPath(path, kind)
        : (shape.pattern ??= _dashPath(path, kind));
    canvas.drawPath(
      dashes,
      _dashPaint
        ..color = themePack.asphalt.withValues(alpha: 0.85)
        ..strokeWidth = _cellSize * 0.09,
    );
  }

  ui.Path _dashPath(ui.Path path, int kind) {
    const patterns = [
      [1.0, 0.0],
      [0.3, 0.3],
      [0.12, 0.28],
      [0.5, 0.5],
      [0.12, 0.12],
    ];
    final on = patterns[kind][0] * _cellSize;
    final off = patterns[kind][1] * _cellSize;
    if (off == 0) return path;
    final dashes = ui.Path();
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        dashes.addPath(
          metric.extractPath(distance, math.min(distance + on, metric.length)),
          ui.Offset.zero,
        );
        distance += on + off;
      }
    }
    return dashes;
  }

  void _drawHint(ui.Canvas canvas, ui.Path path) {
    canvas.drawPath(
      path,
      _stroke
        ..color = themePack.ivory.withValues(alpha: .5)
        ..strokeWidth = _cellSize * 0.5,
    );
  }

  ui.Rect _cellRect(GridPoint cell) => ui.Rect.fromLTWH(
    _boardRect.left + cell.column * _cellSize,
    _boardRect.top + cell.row * _cellSize,
    _cellSize,
    _cellSize,
  );

  // A touch only counts once the finger lifts, and only when it was a quick,
  // still, single-finger tap. Panning, pinching and long presses on the board
  // must not move a bus (and cost a life).
  @override
  void onTapDown(TapDownEvent event) => _tapGate.down(
    event.pointerId,
    event.devicePosition.x,
    event.devicePosition.y,
  );

  @override
  void onTapCancel(TapCancelEvent event) => _tapGate.cancel(event.pointerId);

  @override
  void onTapUp(TapUpEvent event) {
    final isTap = _tapGate.up(
      event.pointerId,
      event.devicePosition.x,
      event.devicePosition.y,
    );
    if (!isTap) return;
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
}

final class _ExitingVehicle {
  _ExitingVehicle(this.vehicle);

  final Vehicle vehicle;
  double progress = 0;
}

/// Cached drawing geometry of one bus at the current board size.
final class _VehicleShape {
  _VehicleShape({
    required this.path,
    required this.shadow,
    required this.arrow,
  });

  final ui.Path path;
  final ui.Path shadow;
  final ui.Path arrow;

  /// Colour-blind dash overlay, built the first time it is needed.
  ui.Path? pattern;
}
