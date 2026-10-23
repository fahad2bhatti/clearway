import 'grid_point.dart';

enum TravelDirection {
  up(-1, 0),
  right(0, 1),
  down(1, 0),
  left(0, -1);

  const TravelDirection(this.rowStep, this.columnStep);

  final int rowStep;
  final int columnStep;

  GridPoint get step => GridPoint(rowStep, columnStep);
}

enum VehicleType { truck, rickshaw, bus }

/// A vehicle is a connected set of occupied cells with a front and direction.
/// The engine knows only this generic model; the theme decides how it looks.
///
/// Two vehicles that share a [convoyId] are a convoy pair: tapping one moves
/// both, and both paths must be clear at that moment.
final class Vehicle {
  Vehicle({
    required this.id,
    required this.type,
    required this.direction,
    required List<GridPoint> cells,
    required this.head,
    this.convoyId,
  }) : cells = List.unmodifiable(cells) {
    if (this.cells.length < 2 || this.cells.first != head) {
      throw ArgumentError(
        'A vehicle needs at least two cells, starting at its head.',
      );
    }
    if (this.cells.toSet().length != this.cells.length) {
      throw ArgumentError('A vehicle path cannot visit the same cell twice.');
    }
    for (var index = 1; index < this.cells.length; index++) {
      final previous = this.cells[index - 1];
      final current = this.cells[index];
      final distance =
          (current.row - previous.row).abs() +
          (current.column - previous.column).abs();
      if (distance != 1) {
        throw ArgumentError(
          'Vehicle path cells must be connected edge-to-edge.',
        );
      }
    }
  }

  final String id;
  final VehicleType type;
  final TravelDirection direction;
  final List<GridPoint> cells;
  final GridPoint head;

  /// Null for a normal vehicle; shared by exactly two vehicles in a convoy.
  final String? convoyId;

  Vehicle copy() => Vehicle(
    id: id,
    type: type,
    direction: direction,
    cells: cells,
    head: head,
    convoyId: convoyId,
  );
}
