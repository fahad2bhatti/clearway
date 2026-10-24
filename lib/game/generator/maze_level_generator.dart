import 'dart:math' as math;

import '../engine/game_level.dart';
import '../engine/grid_point.dart';
import '../engine/level_solver.dart';
import '../engine/vehicle.dart';
import 'board_shapes.dart';
import 'seeded_random.dart';

/// Everything the generator needs to know about one level.
final class MazeSpec {
  const MazeSpec({
    required this.buses,
    required this.shape,
    required this.maxLength,
    this.minLength = 2,
    this.bendPercent = 35,
    this.tanglePercent = 60,
    this.boss = false,
  });

  /// Number of buses on the board.
  final int buses;
  final BoardShapeKind shape;

  /// Bus length in cells (head included).
  final int minLength;
  final int maxLength;

  /// Chance (0-100) that a bus body turns at each cell instead of going on
  /// straight. Higher means curvier buses.
  final int bendPercent;

  /// How strongly a new bus prefers to sit in front of other buses. Higher
  /// means more buses block each other and the order matters more.
  final int tanglePercent;
  final bool boss;
}

/// Builds dense "arrow maze" boards: long, curvy buses packed tightly, where
/// the only obstacles are other buses.
///
/// Solvability is guaranteed by construction. Buses are placed in REVERSE
/// removal order: when a bus is placed, the straight line in front of its
/// head (up to the board edge) must be free of every bus placed so far. That
/// bus can therefore be removed before all of them. The solver double-checks.
abstract final class MazeLevelGenerator {
  static const maxLevelBuses = 80;
  static const dailyBuses = 100;
  static const _density = 0.85;
  static const _attempts = 24;

  static MazeSpec specFor(int number) {
    if (number < 1) throw RangeError.value(number, 'number');
    final boss = number % 10 == 0;
    final relief = number > 10 && number % 5 == 0 && !boss;
    var buses = number <= 3
        ? 1 + number
        : math.min(maxLevelBuses, 4 + ((number - 3) * 0.95).floor());
    if (relief) buses = math.max(3, (buses * 0.7).floor());
    const bossShapes = [
      BoardShapeKind.heart,
      BoardShapeKind.diamond,
      BoardShapeKind.cross,
      BoardShapeKind.ellipse,
    ];
    final shape = boss
        ? bossShapes[(number ~/ 10 - 1) % bossShapes.length]
        : (number >= 12 && number % 4 == 2
              ? BoardShapeKind.ellipse
              : BoardShapeKind.rectangle);
    return MazeSpec(
      buses: buses,
      shape: shape,
      minLength: number <= 3 ? 3 : 2,
      maxLength: number <= 3 ? 4 : math.min(26, 5 + number ~/ 3),
      bendPercent: number <= 3 ? 0 : math.min(55, 10 + number),
      tanglePercent: relief ? 20 : math.min(85, 30 + number),
      boss: boss,
    );
  }

  /// Level [number] of the main progression. Always the same puzzle.
  static GameLevel generate(int number, {String chapter = 'Lahore'}) {
    final spec = specFor(number);
    return _generate(
      number: number,
      title: spec.boss ? 'Boss yard $number' : 'Yard $number',
      spec: spec,
      seedBase: number * 7919 + 13,
      chapter: chapter,
    );
  }

  /// The Rush Hour daily board for a date key such as 20261024: 100 buses.
  static GameLevel generateDaily(int dateKey, {String chapter = 'Rush Hour'}) {
    const shapes = BoardShapeKind.values;
    final spec = MazeSpec(
      buses: dailyBuses,
      shape: shapes[dateKey % shapes.length],
      maxLength: 22,
      bendPercent: 45,
      tanglePercent: 70,
    );
    return _generate(
      number: 900000 + dateKey,
      title: 'Rush Hour',
      spec: spec,
      seedBase: dateKey * 17 + 3,
      chapter: chapter,
    );
  }

  static GameLevel _generate({
    required int number,
    required String title,
    required MazeSpec spec,
    required int seedBase,
    required String chapter,
  }) {
    final baseSide = _sideFor(spec);
    GameLevel? best;
    var bestRounds = -1;
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final rng = SeededRandom(seedBase * 31 + attempt);
      final layout = _Builder(spec, baseSide + attempt ~/ 2, rng).build();
      if (layout.buses.length < math.min(2, spec.buses)) continue;
      final level = _toLevel(number, title, spec, layout, chapter);
      final report = LevelSolver.analyze(level);
      if (report == null) continue; // cannot happen, kept as a safety net
      final complete = layout.buses.length >= spec.buses;
      final deepEnough = report.rounds >= _minRounds(number, spec);
      // A complete board beats an incomplete one; then deeper beats shallower.
      final score = (complete ? 1000 : 0) + report.rounds;
      if (best == null || score > bestRounds) {
        best = level;
        bestRounds = score;
      }
      if (complete && deepEnough) break;
    }
    if (best == null) {
      throw StateError('Could not generate level $number.');
    }
    return best;
  }

  /// How many removal waves a level should need at least. Level 2 teaches a
  /// blocked bus, level 3 teaches order planning, and later levels grow.
  static int _minRounds(int number, MazeSpec spec) {
    if (number <= 1) return 1;
    if (number <= 3) return 2;
    if (number >= 900000) return 8; // daily
    return math.min(spec.buses ~/ 2 + 1, math.min(14, 2 + (number - 4) ~/ 3));
  }

  /// Smallest square box whose shape has room for all buses.
  static int _sideFor(MazeSpec spec) {
    final averageLength =
        spec.minLength + (spec.maxLength - spec.minLength) * 0.25;
    final needed = spec.buses * averageLength / _density;
    for (var side = 4; side < 90; side++) {
      if (BoardShapes.cells(spec.shape, side, side).length >= needed) {
        return side;
      }
    }
    return 90;
  }

  static GameLevel _toLevel(
    int number,
    String title,
    MazeSpec spec,
    _Layout layout,
    String chapter,
  ) {
    return GameLevel(
      number: number,
      title: title,
      width: layout.side,
      height: layout.side,
      chapter: chapter,
      boss: spec.boss,
      shape: layout.mask,
      vehicles: [
        for (var i = 0; i < layout.buses.length; i++)
          Vehicle(
            id: 'bus-${i + 1}',
            type: VehicleType.bus,
            direction: layout.buses[i].direction,
            cells: layout.buses[i].cells,
            head: layout.buses[i].cells.first,
          ),
      ],
    );
  }
}

final class _Bus {
  const _Bus(this.direction, this.cells);

  final TravelDirection direction;

  /// Head first, then the body following the path backwards.
  final List<GridPoint> cells;
}

final class _Layout {
  const _Layout(this.side, this.mask, this.buses);

  final int side;
  final Set<GridPoint> mask;
  final List<_Bus> buses;
}

final class _Builder {
  _Builder(this.spec, this.side, this.rng)
    : mask = BoardShapes.cells(spec.shape, side, side) {
    maskList = mask.toList(growable: false);
  }

  final MazeSpec spec;
  final int side;
  final SeededRandom rng;
  final Set<GridPoint> mask;
  late final List<GridPoint> maskList;

  final occupied = <GridPoint>{};

  /// For every cell: the buses whose exit line passes through it.
  final rayAt = <GridPoint, List<int>>{};
  final buses = <_Bus>[];

  /// For every bus: how many later buses sit in front of it. Zero means the
  /// bus could leave right now.
  final blockedBy = <int>[];

  _Layout build() {
    while (buses.length < spec.buses) {
      final freeCells = [
        for (final cell in maskList)
          if (!occupied.contains(cell)) cell,
      ];
      if (freeCells.length < spec.minLength) break;
      final remaining = spec.buses - buses.length;
      // Never let early buses eat the room later buses still need.
      final cap = math.max(
        spec.minLength,
        math.min(spec.maxLength, (freeCells.length * 0.85 / remaining).floor()),
      );
      final bus = _bestCandidate(freeCells, cap);
      if (bus == null) break;
      _commit(bus);
    }
    return _Layout(side, mask, List.unmodifiable(buses));
  }

  void _commit(_Bus bus) {
    final index = buses.length;
    for (final blocked in _blockedBuses(bus)) {
      blockedBy[blocked]++;
    }
    buses.add(bus);
    blockedBy.add(0);
    occupied.addAll(bus.cells);
    for (final cell in _ray(bus.cells.first, bus.direction)) {
      rayAt.putIfAbsent(cell, () => []).add(index);
    }
  }

  _Bus? _bestCandidate(List<GridPoint> freeCells, int cap) {
    _Bus? best;
    var bestScore = -1;
    for (var attempt = 0; attempt < 14; attempt++) {
      final head = freeCells[rng.nextInt(freeCells.length)];
      final candidate = _candidateAt(head, cap);
      if (candidate == null) continue;
      final score = _score(candidate);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    if (best != null) return best;
    // Random sampling found nothing: look through every free cell once.
    final order = [...freeCells];
    rng.shuffle(order);
    for (final head in order) {
      final candidate = _candidateAt(head, cap);
      if (candidate != null) return candidate;
    }
    return null;
  }

  /// Buses (by index) whose exit line [bus] would sit on.
  Set<int> _blockedBuses(_Bus bus) {
    final blocked = <int>{};
    for (final cell in bus.cells) {
      final owners = rayAt[cell];
      if (owners != null) blocked.addAll(owners);
    }
    return blocked;
  }

  /// Blocking a bus that is currently free scores most: it keeps the number
  /// of buses that can leave at the start low and the chains of "this must go
  /// first" long. How much that matters follows the level's tangle percent.
  int _score(_Bus bus) {
    final blocked = _blockedBuses(bus);
    var newlyBlocked = 0;
    for (final index in blocked) {
      if (blockedBy[index] == 0) newlyBlocked++;
    }
    // A bus whose head sits on the board edge has an empty exit line and can
    // never be blocked, so it adds no depth. Long exit lines can still be
    // crossed by buses placed later.
    final exitLength = _ray(bus.cells.first, bus.direction).length;
    return newlyBlocked * (spec.tanglePercent ~/ 4 + 2) +
        blocked.length * 2 +
        math.min(exitLength, side ~/ 2) * (spec.tanglePercent ~/ 20 + 1) +
        bus.cells.length;
  }

  _Bus? _candidateAt(GridPoint head, int cap) {
    final directions = [...TravelDirection.values];
    rng.shuffle(directions);
    for (final direction in directions) {
      final ray = _ray(head, direction);
      if (ray.any(occupied.contains)) continue;
      final target = spec.minLength + rng.nextInt(cap - spec.minLength + 1);
      final path = _walk(head, direction, ray.toSet(), target);
      if (path.length >= spec.minLength) return _Bus(direction, path);
    }
    return null;
  }

  /// Cells in front of [head] up to the edge of the board box.
  List<GridPoint> _ray(GridPoint head, TravelDirection direction) {
    final cells = <GridPoint>[];
    var cursor = head + direction.step;
    while (cursor.row >= 0 &&
        cursor.row < side &&
        cursor.column >= 0 &&
        cursor.column < side) {
      cells.add(cursor);
      cursor += direction.step;
    }
    return cells;
  }

  /// Grows the body backwards from the head as a self-avoiding walk. The
  /// cell right behind the head keeps the head pointing along its last step.
  List<GridPoint> _walk(
    GridPoint head,
    TravelDirection direction,
    Set<GridPoint> raySet,
    int targetLength,
  ) {
    var step = GridPoint(-direction.rowStep, -direction.columnStep);
    final first = head + step;
    final used = <GridPoint>{head};
    if (!_open(first, used, raySet)) return const [];
    final path = <GridPoint>[head, first];
    used.add(first);
    while (path.length < targetLength) {
      final last = path.last;
      final canStraight = _open(last + step, used, raySet);
      final turns = <GridPoint>[];
      for (final turn in TravelDirection.values) {
        final candidate = turn.step;
        final isStraight = candidate == step;
        final isReverse =
            candidate.row == -step.row && candidate.column == -step.column;
        if (isStraight || isReverse) continue;
        if (_open(last + candidate, used, raySet)) turns.add(candidate);
      }
      GridPoint? choice;
      if (canStraight && (turns.isEmpty || !rng.chance(spec.bendPercent))) {
        choice = step;
      } else if (turns.isNotEmpty) {
        choice = rng.chance(70)
            ? _tightest(last, turns, used, raySet)
            : turns[rng.nextInt(turns.length)];
      }
      if (choice == null) break;
      step = choice;
      final next = last + step;
      path.add(next);
      used.add(next);
    }
    return path;
  }

  /// Of the possible turns, the one leading to the cell with the fewest free
  /// neighbours. Hugging walls and other buses like this fills small pockets
  /// instead of leaving holes, which gives the packed maze look.
  GridPoint _tightest(
    GridPoint last,
    List<GridPoint> turns,
    Set<GridPoint> used,
    Set<GridPoint> raySet,
  ) {
    var best = turns.first;
    var bestFree = 5;
    for (final turn in turns) {
      final next = last + turn;
      var free = 0;
      for (final direction in TravelDirection.values) {
        if (_open(next + direction.step, used, raySet)) free++;
      }
      if (free < bestFree) {
        best = turn;
        bestFree = free;
      }
    }
    return best;
  }

  /// A body cell must be on the board, free, unused and never on the bus's
  /// own exit line (a bus cannot drive through itself).
  bool _open(GridPoint cell, Set<GridPoint> used, Set<GridPoint> raySet) =>
      mask.contains(cell) &&
      !occupied.contains(cell) &&
      !used.contains(cell) &&
      !raySet.contains(cell);
}
