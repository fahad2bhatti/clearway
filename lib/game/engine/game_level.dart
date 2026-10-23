import 'vehicle.dart';

final class GameLevel {
  GameLevel({
    required this.number,
    required this.title,
    required this.width,
    required this.height,
    required List<Vehicle> vehicles,
  }) : vehicles = List.unmodifiable(vehicles) {
    if (width < 2 || height < 2) {
      throw ArgumentError('A yard must be at least 2 by 2 cells.');
    }
    final ids = <String>{};
    final occupied = <Object>{};
    for (final vehicle in this.vehicles) {
      if (!ids.add(vehicle.id)) {
        throw ArgumentError('Vehicle ids must be unique.');
      }
      for (final cell in vehicle.cells) {
        if (cell.row < 0 ||
            cell.row >= height ||
            cell.column < 0 ||
            cell.column >= width) {
          throw ArgumentError(
            'Vehicle ${vehicle.id} lies outside the board at $cell.',
          );
        }
        final key = '${cell.row}:${cell.column}';
        if (!occupied.add(key)) {
          throw ArgumentError('Two vehicles occupy $cell.');
        }
      }
    }
  }

  final int number;
  final String title;
  final int width;
  final int height;
  final List<Vehicle> vehicles;
}
