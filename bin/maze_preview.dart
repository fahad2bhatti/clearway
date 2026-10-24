// Prints stats for generated maze levels and writes an SVG picture of each
// one, so levels can be judged without running the app.
//
//   dart run bin/maze_preview.dart 1 3 12 40 80 daily
//
// Pictures are written to build/maze_preview/.
import 'dart:io';

import 'package:clearway/game/engine/game_level.dart';
import 'package:clearway/game/engine/grid_point.dart';
import 'package:clearway/game/engine/level_solver.dart';
import 'package:clearway/game/engine/vehicle.dart';
import 'package:clearway/game/generator/maze_level_generator.dart';

void main(List<String> args) {
  final targets = args.isEmpty ? ['1', '12', '40', '80', 'daily'] : args;
  Directory('build/maze_preview').createSync(recursive: true);
  stdout.writeln('level      size  buses  fill%  rounds  free0  ms');
  for (final target in targets) {
    final clock = Stopwatch()..start();
    final isDaily = target == 'daily';
    final level = isDaily
        ? MazeLevelGenerator.generateDaily(_todayKey())
        : MazeLevelGenerator.generate(int.parse(target));
    clock.stop();
    final report = LevelSolver.analyze(level)!;
    final usedCells = level.vehicles.fold<int>(
      0,
      (sum, v) => sum + v.cells.length,
    );
    final boardCells = level.shape?.length ?? level.width * level.height;
    stdout.writeln(
      '${(isDaily ? 'daily' : target).padRight(10)} '
      '${level.width.toString().padLeft(2)}x${level.height.toString().padRight(2)} '
      '${level.vehicles.length.toString().padLeft(6)} '
      '${(100 * usedCells / boardCells).toStringAsFixed(0).padLeft(5)} '
      '${report.rounds.toString().padLeft(7)} '
      '${report.initiallyFree.toString().padLeft(6)} '
      '${clock.elapsedMilliseconds.toString().padLeft(4)}',
    );
    File('build/maze_preview/level_${isDaily ? 'daily' : target}.svg')
        .writeAsStringSync(_svg(level));
  }
  stdout.writeln('SVG files: build/maze_preview/');
}

int _todayKey() {
  final now = DateTime.now().toUtc();
  return now.year * 10000 + now.month * 100 + now.day;
}

String _svg(GameLevel level) {
  const cell = 20.0;
  final size = level.width * cell;
  final out = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" '
      'viewBox="0 0 $size ${level.height * cell}" '
      'width="${size.round()}" height="${(level.height * cell).round()}">',
    )
    ..writeln('<rect width="100%" height="100%" fill="#ffffff"/>');
  for (final vehicle in level.vehicles) {
    final points = vehicle.cells
        .map((c) => '${(c.column + .5) * cell},${(c.row + .5) * cell}')
        .join(' ');
    out.writeln(
      '<polyline points="$points" fill="none" stroke="#1d2233" '
      'stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"/>',
    );
    out.writeln(_arrowHead(vehicle, cell));
  }
  out.writeln('</svg>');
  return out.toString();
}

String _arrowHead(Vehicle vehicle, double cell) {
  final GridPoint head = vehicle.head;
  final d = vehicle.direction;
  final cx = (head.column + .5) * cell;
  final cy = (head.row + .5) * cell;
  final tipX = cx + d.columnStep * cell * .5;
  final tipY = cy + d.rowStep * cell * .5;
  final baseX = cx - d.columnStep * cell * .05;
  final baseY = cy - d.rowStep * cell * .05;
  // Perpendicular offsets for the two base corners.
  final px = d.rowStep.abs() * cell * .3;
  final py = d.columnStep.abs() * cell * .3;
  return '<polygon points="$tipX,$tipY ${baseX + px},${baseY + py} '
      '${baseX - px},${baseY - py}" fill="#1d2233"/>';
}
