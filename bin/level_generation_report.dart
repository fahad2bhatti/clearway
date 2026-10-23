// ignore_for_file: avoid_print

import 'package:clearway/game/data/level_catalog.dart';

void main() {
  const levels = [1, 10, 20, 40, 60, 80];
  print('level,grid,generation_ms');
  for (final number in levels) {
    final timer = Stopwatch()..start();
    final level = LevelCatalog.getLevel(number);
    timer.stop();
    print(
      '$number,${level.width}x${level.height},${timer.elapsedMicroseconds / 1000}',
    );
  }
}
