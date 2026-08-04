import '../../../shared/park_catalog.dart';

enum RepasDirection { north, east, south, west }

extension RepasDirectionOffset on RepasDirection {
  RepasPosition get offset => switch (this) {
    RepasDirection.north => const RepasPosition(0, -1),
    RepasDirection.east => const RepasPosition(1, 0),
    RepasDirection.south => const RepasPosition(0, 1),
    RepasDirection.west => const RepasPosition(-1, 0),
  };
}

class RepasPosition {
  const RepasPosition(this.x, this.y);

  final int x;
  final int y;

  RepasPosition operator +(RepasPosition other) =>
      RepasPosition(x + other.x, y + other.y);

  RepasPosition operator -(RepasPosition other) =>
      RepasPosition(x - other.x, y - other.y);

  @override
  bool operator ==(Object other) =>
      other is RepasPosition && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

enum RepasStatus { playing, won }

enum RepasMoveResult { blocked, moved, pushed, won }

class RepasLevelDefinition {
  RepasLevelDefinition({
    required this.stage,
    required this.rows,
    required this.parPushes,
    this.referenceSolution = const [],
  }) : width = rows.fold(
         0,
         (width, row) => row.length > width ? row.length : width,
       ),
       height = rows.length {
    for (var y = 0; y < rows.length; y++) {
      for (var x = 0; x < rows[y].length; x++) {
        final position = RepasPosition(x, y);
        switch (rows[y][x]) {
          case '#':
            walls.add(position);
          case '.':
            floor.add(position);
          case 't':
            floor.add(position);
            targets.add(position);
          case 'c':
            floor.add(position);
            initialCrates.add(position);
          case 'C':
            floor.add(position);
            targets.add(position);
            initialCrates.add(position);
          case 's':
            floor.add(position);
            initialKeeper = position;
          case 'S':
            floor.add(position);
            targets.add(position);
            initialKeeper = position;
        }
      }
    }
  }

  final ParkStage stage;
  final List<String> rows;
  final int parPushes;
  final List<RepasDirection> referenceSolution;
  final int width;
  final int height;
  final Set<RepasPosition> walls = {};
  final Set<RepasPosition> floor = {};
  final Set<RepasPosition> targets = {};
  final Set<RepasPosition> initialCrates = {};
  late RepasPosition initialKeeper;

  int get number => stage.number;
}
