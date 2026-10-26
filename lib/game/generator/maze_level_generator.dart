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
    this.fillGaps = true,
    this.growBuses = true,
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

  /// Fill leftover empty cells after the main build, so the board has no
  /// visible holes (tiny tutorial levels keep their open space).
  final bool fillGaps;

  /// When filling, also add extra short buses into gaps. Off for the daily
  /// board, which must keep exactly [MazeLevelGenerator.dailyBuses] buses.
  final bool growBuses;
}

/// Builds dense "arrow maze" boards: long, curvy buses packed tightly, where
/// the only obstacles are other buses.
///
/// Solvability is guaranteed by construction. Buses are placed in REVERSE
/// removal order: when a bus is placed, the straight line in front of its
/// head (up to the board edge) must be free of every bus placed so far. That
/// bus can therefore be removed before all of them. The solver double-checks.
abstract final class MazeLevelGenerator {
  static const maxLevelBuses = 100;
  static const dailyBuses = 100;
  static const _density = 0.87;
  static const _attempts = 24;

  /// After this many attempts a complete, tidy board is accepted even if it
  /// is shallower than wanted. Keeps generation fast on phones.
  static const _goodEnoughAttempt = 3;

  /// Extra arrows per 10-level tier (0.6 = +60% each tier). Tune this to
  /// make the game softer or harder.
  static const _tierStep = 0.6;

  /// Monster levels carry this many times the normal arrow count.
  static const _monsterFactor = 1.5;

  /// Monster level: every 5th level from level 5 on (5, 10, 15, ...).
  static bool isMonster(int number) => number >= 5 && number % 5 == 0;

  static MazeSpec specFor(int number) {
    if (number < 1) throw RangeError.value(number, 'number');
    final monster = isMonster(number);
    // Every 10 levels the board gets a big step up in arrows (tier 0, 1, 2...).
    final tier = (number - 1) ~/ 10;
    final tierFactor = 1 + _tierStep * tier;
    var buses = number <= 3 ? 1 + number : (6 + (number - 3) * 1.3).floor();
    if (number > 3) buses = (buses * tierFactor).floor();
    if (monster) buses = (buses * _monsterFactor).floor();
    buses = math.min(maxLevelBuses, buses);
    const bossShapes = [
      BoardShapeKind.heart,
      BoardShapeKind.diamond,
      BoardShapeKind.cross,
      BoardShapeKind.ellipse,
    ];
    final BoardShapeKind shape;
    if (monster && number % 10 == 0) {
      shape = bossShapes[(number ~/ 10 - 1) % bossShapes.length];
    } else if (monster) {
      shape = BoardShapeKind.ellipse;
    } else {
      shape = number >= 12 && number % 4 == 2
          ? BoardShapeKind.ellipse
          : BoardShapeKind.rectangle;
    }
    return MazeSpec(
      buses: buses,
      shape: shape,
      minLength: number <= 3 ? 3 : 2,
      maxLength: number <= 3
          ? 4
          : math.min(30, 5 + number ~/ 3 + (monster ? 6 : 0)),
      bendPercent: number <= 3
          ? 0
          : math.min(60, 15 + number + (monster ? 10 : 0)),
      tanglePercent: monster ? 95 : math.min(90, 40 + number),
      boss: monster,
      fillGaps: number > 3,
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
      growBuses: false,
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
    _Layout? best;
    var bestScore = -1000000000;
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final rng = SeededRandom(seedBase * 31 + attempt);
      final layout = _Builder(spec, baseSide + attempt ~/ 2, rng).build();
      if (layout.buses.length < math.min(2, spec.buses)) continue;
      final complete = layout.buses.length >= spec.buses;
      final deepEnough = layout.rounds >= _minRounds(number, spec);
      final tidy = !spec.fillGaps || layout.empty <= 3;
      // A complete board beats an incomplete one, fewer empty cells beat more,
      // then deeper beats shallower.
      final score = (complete ? 100000 : 0) - layout.empty * 50 + layout.rounds;
      if (best == null || score > bestScore) {
        best = layout;
        bestScore = score;
      }
      if (complete && tidy && (deepEnough || attempt >= _goodEnoughAttempt)) {
        break;
      }
    }
    if (best == null) {
      throw StateError('Could not generate level $number.');
    }
    final level = _toLevel(number, title, spec, best, chapter);
    // The builder keeps the board solvable by construction; the solver only
    // double-checks the one board we hand out.
    if (LevelSolver.analyze(level) != null) return level;
    if (spec.fillGaps) {
      // Safety net: rebuild without gap filling (the proven original path).
      return _generate(
        number: number,
        title: title,
        spec: MazeSpec(
          buses: spec.buses,
          shape: spec.shape,
          minLength: spec.minLength,
          maxLength: spec.maxLength,
          bendPercent: spec.bendPercent,
          tanglePercent: spec.tanglePercent,
          boss: spec.boss,
          fillGaps: false,
          growBuses: spec.growBuses,
        ),
        seedBase: seedBase,
        chapter: chapter,
      );
    }
    throw StateError('Level $number is not solvable.');
  }

  /// How many removal waves a level should need at least. Level 2 teaches a
  /// blocked bus, level 3 teaches order planning, and later levels grow.
  static int _minRounds(int number, MazeSpec spec) {
    if (number <= 1) return 1;
    if (number <= 3) return 2;
    if (number >= 900000) return 8; // daily
    if (isMonster(number)) return math.min(spec.buses ~/ 4, 24);
    return math.min(spec.buses ~/ 2 + 1, math.min(20, 3 + (number - 4) ~/ 2));
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
  const _Layout(this.side, this.mask, this.buses, this.empty, this.rounds);

  final int side;
  final Set<GridPoint> mask;
  final List<_Bus> buses;

  /// Board cells no bus covers after filling.
  final int empty;

  /// Removal waves the board needs (same number the solver reports).
  final int rounds;
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

  /// Which bus covers each occupied cell.
  final owner = <GridPoint, int>{};

  /// For every bus: the buses sitting on its exit line, which must leave
  /// first. The board is solvable exactly when this graph has no cycle.
  final deps = <Set<int>>[];

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
    if (spec.fillGaps) _fillGaps();
    final empty = _countAndPruneEmpty();
    return _Layout(side, mask, List.unmodifiable(buses), empty, _rounds());
  }

  /// Longest chain of "must leave first" links: the number of waves.
  int _rounds() {
    final depth = List<int>.filled(buses.length, 0);
    int visit(int index) {
      if (depth[index] != 0) return depth[index];
      var longest = 1;
      for (final other in deps[index]) {
        longest = math.max(longest, visit(other) + 1);
      }
      return depth[index] = longest;
    }

    var rounds = 0;
    for (var i = 0; i < buses.length; i++) {
      rounds = math.max(rounds, visit(i));
    }
    return rounds;
  }

  void _commit(_Bus bus) {
    final index = buses.length;
    final exitLine = _ray(bus.cells.first, bus.direction);
    final mustLeaveFirst = <int>{};
    for (final cell in exitLine) {
      final other = owner[cell];
      if (other != null) mustLeaveFirst.add(other);
    }
    for (final blocked in _blockedBuses(bus)) {
      blockedBy[blocked]++;
      deps[blocked].add(index);
    }
    buses.add(bus);
    blockedBy.add(0);
    deps.add(mustLeaveFirst);
    occupied.addAll(bus.cells);
    for (final cell in bus.cells) {
      owner[cell] = index;
    }
    for (final cell in exitLine) {
      rayAt.putIfAbsent(cell, () => []).add(index);
    }
  }

  // ---- Gap filling -------------------------------------------------------

  static const _maxGrownLength = 40;

  /// True if following "must leave first" links from [from] reaches any bus
  /// in [targets]. Adding a bus (or a cell) that would close such a loop makes
  /// the board unsolvable, so those additions are skipped.
  bool _reaches(Iterable<int> from, Set<int> targets) {
    if (targets.isEmpty) return false;
    final seen = <int>{};
    final stack = [...from];
    while (stack.isNotEmpty) {
      final node = stack.removeLast();
      if (!seen.add(node)) continue;
      if (targets.contains(node)) return true;
      stack.addAll(deps[node]);
    }
    return false;
  }

  List<GridPoint> _freeCells() => [
    for (final cell in maskList)
      if (!occupied.contains(cell)) cell,
  ];

  /// Fills holes without ever creating a deadlock: first with extra short
  /// buses (if allowed), then by growing the tail of existing buses.
  void _fillGaps() {
    for (var pass = 0; pass < 6; pass++) {
      var changed = false;
      if (spec.growBuses && _insertSmallBuses()) changed = true;
      if (_extendTails()) changed = true;
      if (spec.growBuses && _stealTails()) changed = true;
      if (!changed) break;
    }
  }

  bool _insertSmallBuses() {
    var added = false;
    final free = _freeCells();
    rng.shuffle(free);
    for (final head in free) {
      if (occupied.contains(head)) continue;
      final directions = [...TravelDirection.values];
      rng.shuffle(directions);
      for (final direction in directions) {
        final exitLine = _ray(head, direction);
        final target = spec.minLength + rng.nextInt(3);
        final path = _walk(head, direction, exitLine.toSet(), target);
        if (path.length < spec.minLength) continue;
        final needs = <int>{};
        for (final cell in exitLine) {
          final other = owner[cell];
          if (other != null) needs.add(other);
        }
        final blocks = <int>{};
        for (final cell in path) {
          final owners = rayAt[cell];
          if (owners != null) blocks.addAll(owners);
        }
        if (_reaches(needs, blocks)) continue;
        _commit(_Bus(direction, path));
        added = true;
        break;
      }
    }
    return added;
  }

  bool _extendTails() {
    var extended = false;
    final order = [for (var i = 0; i < buses.length; i++) i];
    rng.shuffle(order);
    for (final index in order) {
      while (buses[index].cells.length < _maxGrownLength) {
        final bus = buses[index];
        final options = <GridPoint>[];
        for (final direction in TravelDirection.values) {
          final cell = bus.cells.last + direction.step;
          if (!mask.contains(cell) || occupied.contains(cell)) continue;
          final owners = rayAt[cell];
          if (owners != null) {
            // A bus never drives through itself.
            if (owners.contains(index)) continue;
            if (_reaches(deps[index], owners.toSet())) continue;
          }
          options.add(cell);
        }
        if (options.isEmpty) break;
        // Eat dead ends first so no single cell is left stranded.
        var cell = options.first;
        var fewestFree = 5;
        for (final option in options) {
          var free = 0;
          for (final direction in TravelDirection.values) {
            final next = option + direction.step;
            if (mask.contains(next) && !occupied.contains(next)) free++;
          }
          if (free < fewestFree) {
            fewestFree = free;
            cell = option;
          }
        }
        buses[index] = _Bus(bus.direction, [...bus.cells, cell]);
        occupied.add(cell);
        owner[cell] = index;
        for (final other in rayAt[cell] ?? const <int>[]) {
          deps[other].add(index);
        }
        extended = true;
      }
    }
    return extended;
  }

  /// A free cell next to the tail of a longer bus: cut that tail cell off and
  /// turn it plus the free cell into a new two-cell bus. Works where growing
  /// the tail would have created a deadlock.
  bool _stealTails() {
    var changed = false;
    final free = _freeCells();
    rng.shuffle(free);
    for (final cell in free) {
      if (occupied.contains(cell)) continue;
      for (final direction in TravelDirection.values) {
        final behind = GridPoint(
          cell.row - direction.rowStep,
          cell.column - direction.columnStep,
        );
        final donor = owner[behind];
        if (donor == null) continue;
        final donorBus = buses[donor];
        if (donorBus.cells.length < 3 || donorBus.cells.last != behind) {
          continue;
        }
        final exitLine = _ray(cell, direction);
        final needs = <int>{};
        for (final onLine in exitLine) {
          final other = owner[onLine];
          if (other != null) needs.add(other);
        }
        final blocks = <int>{
          ...(rayAt[cell] ?? const <int>[]),
          ...(rayAt[behind] ?? const <int>[]),
        };
        if (_reaches(needs, blocks)) continue;

        final index = buses.length;
        buses[donor] = _Bus(
          donorBus.direction,
          donorBus.cells.sublist(0, donorBus.cells.length - 1),
        );
        buses.add(_Bus(direction, [cell, behind]));
        blockedBy.add(0);
        deps.add(needs);
        occupied.add(cell);
        owner[cell] = index;
        owner[behind] = index;
        for (final other in blocks) {
          deps[other].add(index);
        }
        for (final onLine in exitLine) {
          rayAt.putIfAbsent(onLine, () => []).add(index);
        }
        changed = true;
        break;
      }
    }
    return changed;
  }

  /// Removes any unfillable cells from the rendered board shape, so gap
  /// filling never leaves visible empty holes between vehicles.
  int _countAndPruneEmpty() {
    var empty = 0;
    for (final cell in maskList) {
      if (occupied.contains(cell)) continue;
      empty++;
      if (spec.fillGaps) {
        mask.remove(cell);
      }
    }
    return empty;
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
