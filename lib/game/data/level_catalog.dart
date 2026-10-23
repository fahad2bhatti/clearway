import '../engine/game_level.dart';
import '../engine/grid_point.dart';
import '../engine/vehicle.dart';

/// Ten hand-built, solver-verified teaching boards for the first prototype.
abstract final class LevelCatalog {
  static final levels = List<GameLevel>.unmodifiable([
    _level(1, 'First way out', [
      _vehicle('rang', VehicleType.truck, TravelDirection.right, 3, 1, 2),
      _vehicle('gul', VehicleType.rickshaw, TravelDirection.down, 5, 4, 2),
    ]),
    _level(2, 'A little patience', [
      _vehicle('sunehri', VehicleType.truck, TravelDirection.up, 2, 2, 2),
      _vehicle('neeli', VehicleType.rickshaw, TravelDirection.right, 1, 3, 2),
    ]),
    _level(3, 'Clear in order', [
      _vehicle('pista', VehicleType.truck, TravelDirection.up, 3, 3, 2),
      _vehicle('gulabi', VehicleType.truck, TravelDirection.right, 2, 4, 2),
      _vehicle('tota', VehicleType.rickshaw, TravelDirection.left, 5, 1, 2),
    ]),
    _level(4, 'Side street', [
      _vehicle('badal', VehicleType.truck, TravelDirection.up, 2, 1, 2),
      _vehicle('suraj', VehicleType.rickshaw, TravelDirection.right, 1, 2, 2),
      _vehicle('gulab', VehicleType.truck, TravelDirection.left, 4, 4, 2),
    ]),
    _level(5, 'Open the yard', [
      _vehicle('rangrez', VehicleType.truck, TravelDirection.up, 1, 3, 2),
      _vehicle('chai', VehicleType.rickshaw, TravelDirection.right, 0, 4, 2),
      _vehicle('hawa', VehicleType.truck, TravelDirection.down, 5, 0, 2),
      _vehicle('sitara', VehicleType.rickshaw, TravelDirection.left, 3, 4, 2),
    ]),
    _level(6, 'Room to turn', [
      _vehicle('teal', VehicleType.truck, TravelDirection.left, 2, 1, 3),
      _vehicle('amber', VehicleType.rickshaw, TravelDirection.down, 5, 4, 2),
      _vehicle('rose', VehicleType.truck, TravelDirection.right, 4, 3, 2),
    ]),
    _level(7, 'Three lanes', [
      _vehicle('dhoop', VehicleType.truck, TravelDirection.down, 5, 1, 3),
      _vehicle('badami', VehicleType.rickshaw, TravelDirection.left, 0, 1, 2),
      _vehicle('phool', VehicleType.truck, TravelDirection.up, 2, 3, 2),
      _vehicle('kiran', VehicleType.rickshaw, TravelDirection.right, 3, 5, 2),
    ]),
    _level(8, 'Long way home', [
      _vehicle('indigo', VehicleType.truck, TravelDirection.left, 1, 2, 3),
      _vehicle('marigold', VehicleType.rickshaw, TravelDirection.down, 5, 0, 2),
      _vehicle('mint', VehicleType.truck, TravelDirection.up, 2, 5, 3),
      _vehicle('coral', VehicleType.rickshaw, TravelDirection.left, 4, 3, 2),
    ]),
    _level(9, 'Market morning', [
      _vehicle('truck-1', VehicleType.truck, TravelDirection.right, 1, 2, 3),
      _vehicle('truck-2', VehicleType.truck, TravelDirection.down, 5, 4, 3),
      _vehicle('tuk-1', VehicleType.rickshaw, TravelDirection.left, 3, 1, 2),
      _vehicle('tuk-2', VehicleType.rickshaw, TravelDirection.down, 5, 5, 2),
    ]),
    _level(10, 'Open road', [
      _vehicle('truck-3', VehicleType.truck, TravelDirection.up, 2, 2, 3),
      _vehicle('truck-4', VehicleType.truck, TravelDirection.left, 5, 2, 3),
      _vehicle('tuk-3', VehicleType.rickshaw, TravelDirection.right, 0, 3, 2),
      _vehicle('tuk-4', VehicleType.rickshaw, TravelDirection.down, 5, 5, 2),
    ]),
  ]);

  static GameLevel _level(int number, String title, List<Vehicle> vehicles) =>
      GameLevel(
        number: number,
        title: title,
        width: 6,
        height: 6,
        vehicles: vehicles,
      );

  /// The supplied row and column point at the vehicle's cab/front.
  static Vehicle _vehicle(
    String id,
    VehicleType type,
    TravelDirection direction,
    int headRow,
    int headColumn,
    int length,
  ) {
    final head = GridPoint(headRow, headColumn);
    final cells = List.generate(
      length,
      (index) => GridPoint(
        headRow - direction.rowStep * index,
        headColumn - direction.columnStep * index,
      ),
    );
    return Vehicle(
      id: id,
      type: type,
      direction: direction,
      cells: cells,
      head: head,
    );
  }
}
