import '../engine/grid_point.dart';

/// Silhouettes a yard can have. Cells outside the shape are simply not part
/// of the board: nothing is drawn there and no bus can occupy them.
enum BoardShapeKind { rectangle, ellipse, diamond, heart, cross }

abstract final class BoardShapes {
  /// All board cells of [kind] inside a [width] x [height] box, row by row.
  static Set<GridPoint> cells(BoardShapeKind kind, int width, int height) {
    final result = <GridPoint>{};
    for (var row = 0; row < height; row++) {
      for (var column = 0; column < width; column++) {
        // Cell centre mapped to the range -1..1 in both axes.
        final x = (column + 0.5 - width / 2) / (width / 2);
        final y = (height / 2 - (row + 0.5)) / (height / 2);
        if (_inside(kind, x, y)) result.add(GridPoint(row, column));
      }
    }
    return result;
  }

  static bool _inside(BoardShapeKind kind, double x, double y) {
    switch (kind) {
      case BoardShapeKind.rectangle:
        return true;
      case BoardShapeKind.ellipse:
        return x * x + y * y <= 1.0;
      case BoardShapeKind.diamond:
        return x.abs() + y.abs() <= 1.0;
      case BoardShapeKind.cross:
        return x.abs() <= 0.36 || y.abs() <= 0.36;
      case BoardShapeKind.heart:
        final hx = x * 1.2;
        final hy = y * 1.15 + 0.1;
        final a = hx * hx + hy * hy - 1;
        return a * a * a - hx * hx * hy * hy * hy <= 0;
    }
  }
}
