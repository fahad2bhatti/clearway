import 'dart:math';

import '../../core/daily_clock.dart';
import '../engine/game_level.dart';
import '../engine/grid_point.dart';
import '../engine/level_solver.dart';
import '../engine/move_validator.dart';
import '../engine/vehicle.dart';

/// Deterministic yard catalog with a gradual size and difficulty ramp.
/// Generated boards are checked by the same pure-Dart solver used in play.
abstract final class LevelCatalog {
  static const totalLevels = 80;
  static final Map<int, GameLevel> _levelCache = {};

  /// Optional hook used by the Flutter app to report slow generation in debug.
  static void Function(int levelNumber, Duration elapsed)? onSlowGeneration;
  static const chapters = [
    'Lahore',
    'Karachi',
    'Multan',
    'Quetta',
    'Peshawar',
    'Faisalabad',
  ];

  static String chapterFor(int number) =>
      chapters[((number - 1) ~/ 10) % chapters.length];

  static GameLevel getLevel(int number) {
    if (number < 1 || number > totalLevels) {
      throw RangeError.range(number, 1, totalLevels, 'number');
    }
    final cached = _levelCache[number];
    if (cached != null) return cached;

    final timer = Stopwatch()..start();
    final level = _buildLevel(number);
    timer.stop();
    _levelCache[number] = level;
    if (timer.elapsed > const Duration(milliseconds: 50)) {
      onSlowGeneration?.call(number, timer.elapsed);
    }
    return level;
  }

  static GameLevel _buildLevel(int number) {
    if (number == 1) return _handOne();
    if (number == 2) return _handTwo();
    if (number == 3) return _handThree();
    for (var attempt = 0; attempt < 6; attempt++) {
      final seed = attempt == 0
          ? 91000 + number * 97
          : 44000 + number * 13 + (attempt - 1) * 997;
      final level = _generate(number, seed);
      if (LevelSolver.isSolvable(level)) return level;
    }
    // A simple verified board is a deterministic safety net for rare seeds.
    final fallbackSize = _sizeFor(number);
    return GameLevel(
      number: number,
      title: 'Yard $number',
      width: fallbackSize,
      height: fallbackSize,
      vehicles: [
        _makeVehicle(
          'vehicle-1',
          TravelDirection.right,
          fallbackSize ~/ 2,
          fallbackSize - 1,
          2,
          VehicleType.truck,
        ),
      ],
      chapter: chapterFor(number),
    );
  }

  static GameLevel daily(String dayKey, {int? serverSeed}) {
    final seed = serverSeed ?? DailyClock.seedFor(dayKey);
    for (var attempt = 0; attempt < 8; attempt++) {
      final candidateSeed = attempt == 0
          ? seed
          : (seed ^ (0x9e3779b9 * attempt)) & 0xffffffff;
      final candidate = _generate(
        900000 + candidateSeed,
        candidateSeed,
        daily: true,
      );
      if (LevelSolver.isSolvable(candidate)) return candidate;
    }

    // A final verified, seed-independent board keeps daily play available even
    // if all deterministic generator attempts fail for an unusual seed.
    final fallback = GameLevel(
      number: 900000 + seed,
      title: 'Daily rush',
      width: 6,
      height: 6,
      vehicles: [
        _makeVehicle(
          'vehicle-1',
          TravelDirection.right,
          2,
          5,
          2,
          VehicleType.truck,
        ),
      ],
      chapter: 'Rush Hour',
    );
    if (!LevelSolver.isSolvable(fallback)) {
      throw StateError('Daily fallback puzzle must be solvable.');
    }
    return fallback;
  }

  static GameLevel _generate(int id, int seed, {bool daily = false}) {
    final rand = _Random(seed);
    final n = daily ? 6 : _sizeFor(id);
    final boss = !daily && id % 10 == 0;
    final cones = <GridPoint>[];
    final gates = <OneWayGate>[];
    final obstacleCount = daily
        ? 1
        : id >= 30
        ? 2
        : id >= 10
        ? 1
        : 0;
    final gateCount = !daily && id >= 25 ? 1 : 0;
    final crossingBusLength = daily || id < 40
        ? 0
        : min(n - 2, 7 + (id - 40) ~/ 10);
    final reverseCrossing = !daily && (id ~/ 10).isOdd;
    final crossingColumn = reverseCrossing ? crossingBusLength - 1 : n - 2;
    final crossingRow = reverseCrossing ? n - 2 : 1;
    final crossingBusCells = <GridPoint>{
      if (crossingBusLength > 0) ...[
        for (var i = 0; i < crossingBusLength; i++)
          GridPoint(crossingRow, reverseCrossing ? i : n - 1 - i),
        for (var i = 0; i < crossingBusLength; i++)
          GridPoint(reverseCrossing ? n - 3 - i : 2 + i, crossingColumn),
      ],
    };
    final empty = [
      for (var r = 0; r < n; r++)
        for (var c = 0; c < n; c++)
          if (!crossingBusCells.contains(GridPoint(r, c))) GridPoint(r, c),
    ];
    _shuffle(empty, rand);
    var cursor = 0;
    for (var i = 0; i < obstacleCount && cursor < empty.length; i++) {
      cones.add(empty[cursor++]);
    }
    for (var i = 0; i < gateCount && cursor < empty.length; i++) {
      gates.add(
        OneWayGate(empty[cursor++], TravelDirection.values[rand.nextInt(4)]),
      );
    }
    final vehicles = <Vehicle>[];
    if (crossingBusLength > 0) {
      // The buses are independent. One blocks the other's exit; later chapters
      // reverse their orientation to vary the route-planning.
      final verticalDirection = reverseCrossing
          ? TravelDirection.down
          : TravelDirection.up;
      final verticalHead = reverseCrossing
          ? GridPoint(n - 3, crossingColumn)
          : GridPoint(2, crossingColumn);
      vehicles.add(
        Vehicle(
          id: 'vehicle-1',
          type: VehicleType.bus,
          direction: verticalDirection,
          head: verticalHead,
          cells: [
            for (var i = 0; i < crossingBusLength; i++)
              GridPoint(
                verticalHead.row - verticalDirection.rowStep * i,
                verticalHead.column,
              ),
          ],
        ),
      );
      final horizontalDirection = reverseCrossing
          ? TravelDirection.left
          : TravelDirection.right;
      final horizontalHead = reverseCrossing
          ? GridPoint(crossingRow, 0)
          : GridPoint(crossingRow, n - 1);
      vehicles.add(
        Vehicle(
          id: 'vehicle-2',
          type: VehicleType.bus,
          direction: horizontalDirection,
          head: horizontalHead,
          cells: [
            for (var i = 0; i < crossingBusLength; i++)
              GridPoint(
                horizontalHead.row,
                horizontalHead.column - horizontalDirection.columnStep * i,
              ),
          ],
        ),
      );
    }

    // Tutorial band: few short vehicles. Each later chapter adds traffic and
    // introduces larger grids, so challenge grows without a sudden spike.
    final target = daily
        ? 6
        : id <= 10
        ? min(4, 2 + id ~/ 3)
        : min(n + (boss ? 2 : 0), 10 + (id - 11) ~/ 4);
    final allowConvoy = !daily && id >= 50;
    var convoyCreated = false;
    var guard = 0;
    while (vehicles.length < target && guard++ < 80) {
      final useConvoy =
          allowConvoy &&
          !convoyCreated &&
          (rand.nextDouble() < .35 || vehicles.length >= target - 4) &&
          target - vehicles.length >= 2;
      final maxLength = daily ? min(5, n - 1) : _maxVehicleLength(id, n);
      final length = useConvoy
          ? 2 + rand.nextInt(2)
          : max(2, maxLength - rand.nextInt(min(3, maxLength - 1)));
      final kind = length >= 5
          ? VehicleType.bus
          : length == 2 && id >= 8 && rand.nextDouble() < .45
          ? VehicleType.rickshaw
          : VehicleType.truck;
      // The browser model consumed a random color for each piece. Appearance
      // is derived from the truck-art theme in Flutter, but preserve the seed
      // stream so generated board geometry stays aligned with that source.
      rand.nextInt(5);
      var direction = TravelDirection.values[rand.nextInt(4)];
      if (length >= 5 &&
          vehicles.any(
            (vehicle) =>
                vehicle.type == VehicleType.bus &&
                vehicle.direction == direction,
          )) {
        direction = _perpendicular(direction, rand);
      }
      if (useConvoy) {
        final groupId = 'convoy-${vehicles.length}';
        final a = _tryPlace(
          vehicles,
          cones,
          gates,
          n,
          direction,
          length,
          VehicleType.truck,
          groupId,
          rand,
        );
        if (a == null) continue;
        vehicles.add(a);
        final b = _tryPlace(
          vehicles,
          cones,
          gates,
          n,
          _perpendicular(direction, rand),
          2,
          VehicleType.rickshaw,
          groupId,
          rand,
        );
        if (b == null) {
          vehicles.removeLast();
          continue;
        }
        vehicles.add(b);
        convoyCreated = true;
      } else {
        final v = _tryPlace(
          vehicles,
          cones,
          gates,
          n,
          direction,
          min(length, n - 1),
          kind,
          null,
          rand,
        );
        if (v != null) vehicles.add(v);
      }
    }
    if (vehicles.isEmpty) {
      vehicles.add(
        _makeVehicle(
          'vehicle-1',
          TravelDirection.right,
          1,
          0,
          2,
          VehicleType.truck,
        ),
      );
    }
    return GameLevel(
      number: id,
      title: daily
          ? 'Daily rush'
          : boss
          ? '${chapterFor(id)} yard'
          : 'Yard $id',
      width: n,
      height: n,
      vehicles: vehicles,
      cones: cones,
      gates: gates,
      chapter: daily ? 'Rush Hour' : chapterFor(id),
      boss: boss,
    );
  }

  static Vehicle? _tryPlace(
    List<Vehicle> vehicles,
    List<GridPoint> cones,
    List<OneWayGate> gates,
    int size,
    TravelDirection dir,
    int length,
    VehicleType kind,
    String? convoy,
    _Random rand,
  ) {
    final heads = [
      for (var r = 0; r < size; r++)
        for (var c = 0; c < size; c++) GridPoint(r, c),
    ];
    _shuffle(heads, rand);
    for (final head in heads) {
      final cells = [
        for (var i = 0; i < length; i++)
          GridPoint(
            head.row - dir.rowStep * i,
            head.column - dir.columnStep * i,
          ),
      ];
      if (cells.any(
        (cell) =>
            cell.row < 0 ||
            cell.column < 0 ||
            cell.row >= size ||
            cell.column >= size,
      )) {
        continue;
      }
      final occupied = vehicles.expand((vehicle) => vehicle.cells).toSet();
      if (cells.any(
        (cell) =>
            occupied.contains(cell) ||
            cones.contains(cell) ||
            gates.any((gate) => gate.position == cell),
      )) {
        continue;
      }
      final vehicle = Vehicle(
        id: 'vehicle-${vehicles.length + 1}',
        type: kind,
        direction: dir,
        cells: cells,
        head: head,
        convoyId: convoy,
      );
      // Build only after making sure new pieces are safe to remove; older pieces
      // may become blocked, which is why the full solver validates the board.
      final probeVehicles = [
        for (final existing in vehicles)
          Vehicle(
            id: existing.id,
            type: existing.type,
            direction: existing.direction,
            cells: existing.cells,
            head: existing.head,
            convoyId: existing.convoyId == convoy ? null : existing.convoyId,
          ),
        Vehicle(
          id: vehicle.id,
          type: vehicle.type,
          direction: vehicle.direction,
          cells: vehicle.cells,
          head: vehicle.head,
        ),
      ];
      final probe = GameLevel(
        number: 1,
        title: '',
        width: size,
        height: size,
        vehicles: probeVehicles,
        cones: cones,
        gates: gates,
      );
      if (MoveValidator.check(probe, probeVehicles, vehicle).canEscape) {
        return vehicle;
      }
    }
    return null;
  }

  /// The first ten boards stay compact and forgiving. Later chapters increase
  /// by two rows and columns so the endgame gives long vehicles room to weave.
  static int _sizeFor(int level) => level <= 2
      ? 4
      : level <= 5
      ? 5
      : level <= 10
      ? 6
      : 7 + 2 * ((level - 11) ~/ 10);

  /// Short paths in the tutorial band, then longer trucks every chapter.
  static int _maxVehicleLength(int level, int gridSize) => level <= 10
      ? min(3, gridSize - 1)
      : min(gridSize - 1, 4 + (level - 11) ~/ 8);

  static void _shuffle<T>(List<T> values, Random random) {
    for (var i = values.length - 1; i > 0; i--) {
      final swapIndex = random.nextInt(i + 1);
      final value = values[i];
      values[i] = values[swapIndex];
      values[swapIndex] = value;
    }
  }

  static TravelDirection _perpendicular(
    TravelDirection direction,
    Random rand,
  ) {
    final options = switch (direction) {
      TravelDirection.up ||
      TravelDirection.down => [TravelDirection.left, TravelDirection.right],
      TravelDirection.left ||
      TravelDirection.right => [TravelDirection.up, TravelDirection.down],
    };
    return options[rand.nextInt(options.length)];
  }

  static Vehicle _makeVehicle(
    String id,
    TravelDirection direction,
    int row,
    int column,
    int length,
    VehicleType type,
  ) {
    final head = GridPoint(row, column);
    return Vehicle(
      id: id,
      type: type,
      direction: direction,
      head: head,
      cells: [
        for (var i = 0; i < length; i++)
          GridPoint(
            row - direction.rowStep * i,
            column - direction.columnStep * i,
          ),
      ],
    );
  }

  static GameLevel _handOne() => _custom(1, 4, 'First departure', [
    _makeVehicle('1', TravelDirection.right, 1, 1, 2, VehicleType.truck),
  ]);
  static GameLevel _handTwo() => _custom(2, 4, 'Wait your turn', [
    _makeVehicle('1', TravelDirection.right, 1, 1, 2, VehicleType.truck),
    _makeVehicle('2', TravelDirection.down, 1, 2, 2, VehicleType.truck),
  ]);
  static GameLevel _handThree() => _custom(3, 5, 'Plan the order', [
    _makeVehicle('3', TravelDirection.right, 2, 2, 3, VehicleType.truck),
    _makeVehicle('2', TravelDirection.up, 1, 3, 2, VehicleType.truck),
    _makeVehicle('1', TravelDirection.right, 0, 3, 2, VehicleType.rickshaw),
  ]);
  static GameLevel _custom(
    int n,
    int size,
    String title,
    List<Vehicle> vehicles,
  ) => GameLevel(
    number: n,
    title: title,
    width: size,
    height: size,
    vehicles: vehicles,
    chapter: chapterFor(n),
  );
}

class _Random implements Random {
  _Random(int seed) : _state = seed & 0xffffffff;
  int _state;
  int _next() {
    _state = (_state + 0x6d2b79f5) & 0xffffffff;
    var t = _state;
    t = ((t ^ (t >> 15)) * (t | 1)) & 0xffffffff;
    t ^= (t + (((t ^ (t >> 7)) * (t | 61)) & 0xffffffff)) & 0xffffffff;
    return (t ^ (t >> 14)) & 0xffffffff;
  }

  @override
  bool nextBool() => nextInt(2) == 0;
  @override
  double nextDouble() => _next() / 4294967296;
  @override
  int nextInt(int max) => (nextDouble() * max).floor();
}
