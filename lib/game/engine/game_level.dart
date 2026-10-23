import 'grid_point.dart';
import 'vehicle.dart';

/// A gate cell that vehicles may enter only while travelling in [direction].
final class OneWayGate {
  const OneWayGate(this.position, this.direction);

  final GridPoint position;
  final TravelDirection direction;
}

final class GameLevel {
  GameLevel({
    required this.number,
    required this.title,
    required this.width,
    required this.height,
    required List<Vehicle> vehicles,
    List<GridPoint> cones = const [],
    List<OneWayGate> gates = const [],
  }) : vehicles = List.unmodifiable(vehicles),
       cones = List.unmodifiable(cones),
       gates = List.unmodifiable(gates) {
    if (width < 2 || height < 2) {
      throw ArgumentError('A yard must be at least 2 by 2 cells.');
    }
    final ids = <String>{};
    final occupied = <GridPoint>{};
    final convoyCounts = <String, int>{};
    for (final vehicle in this.vehicles) {
      if (!ids.add(vehicle.id)) {
        throw ArgumentError('Vehicle ids must be unique.');
      }
      final convoyId = vehicle.convoyId;
      if (convoyId != null) {
        convoyCounts.update(convoyId, (count) => count + 1, ifAbsent: () => 1);
      }
      for (final cell in vehicle.cells) {
        if (!_inside(cell)) {
          throw ArgumentError(
            'Vehicle ${vehicle.id} lies outside the board at $cell.',
          );
        }
        if (!occupied.add(cell)) {
          throw ArgumentError('Two vehicles occupy $cell.');
        }
      }
    }
    for (final entry in convoyCounts.entries) {
      if (entry.value != 2) {
        throw ArgumentError(
          'Convoy ${entry.key} must have exactly 2 vehicles.',
        );
      }
    }
    final obstacleCells = <GridPoint>{};
    for (final cone in this.cones) {
      _checkObstacle(cone, 'Cone', occupied, obstacleCells);
    }
    for (final gate in this.gates) {
      _checkObstacle(gate.position, 'Gate', occupied, obstacleCells);
    }
  }

  final int number;
  final String title;
  final int width;
  final int height;
  final List<Vehicle> vehicles;
  final List<GridPoint> cones;
  final List<OneWayGate> gates;

  bool contains(GridPoint cell) => _inside(cell);

  bool hasCone(GridPoint cell) => cones.contains(cell);

  OneWayGate? gateAt(GridPoint cell) {
    for (final gate in gates) {
      if (gate.position == cell) return gate;
    }
    return null;
  }

  bool _inside(GridPoint cell) =>
      cell.row >= 0 &&
      cell.row < height &&
      cell.column >= 0 &&
      cell.column < width;

  void _checkObstacle(
    GridPoint cell,
    String label,
    Set<GridPoint> occupied,
    Set<GridPoint> used,
  ) {
    if (!_inside(cell)) {
      throw ArgumentError('$label lies outside the board at $cell.');
    }
    if (occupied.contains(cell)) {
      throw ArgumentError('$label sits on a vehicle at $cell.');
    }
    if (!used.add(cell)) {
      throw ArgumentError('Two obstacles share $cell.');
    }
  }
}
