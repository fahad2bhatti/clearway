final class GridPoint {
  const GridPoint(this.row, this.column);

  final int row;
  final int column;

  GridPoint operator +(GridPoint other) =>
      GridPoint(row + other.row, column + other.column);

  GridPoint operator -(GridPoint other) =>
      GridPoint(row - other.row, column - other.column);

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.row == row && other.column == column;

  @override
  int get hashCode => Object.hash(row, column);

  @override
  String toString() => '($row, $column)';
}
