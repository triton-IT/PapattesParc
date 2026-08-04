import 'models.dart';

class RepasSession {
  RepasSession(this.level) {
    reset();
  }

  final RepasLevelDefinition level;
  final List<_RepasSnapshot> _history = [];
  late RepasPosition keeper;
  late Set<RepasPosition> crates;
  late RepasDirection facing;
  late RepasStatus status;
  late int moves;
  late int pushes;

  bool get canUndo => _history.isNotEmpty;
  bool get hasMoved => moves > 0;
  int get cratesRemaining => crates.difference(level.targets).length;

  RepasMoveResult move(RepasDirection direction) {
    if (status == RepasStatus.won) return RepasMoveResult.blocked;
    final destination = keeper + direction.offset;
    if (!level.floor.contains(destination)) return RepasMoveResult.blocked;
    final crate = crates.contains(destination);
    final beyond = destination + direction.offset;
    if (crate && (!level.floor.contains(beyond) || crates.contains(beyond))) {
      return RepasMoveResult.blocked;
    }

    _history.add(_snapshot());
    facing = direction;
    keeper = destination;
    moves++;
    if (crate) {
      crates = {...crates}
        ..remove(destination)
        ..add(beyond);
      pushes++;
    }
    if (level.targets.every(crates.contains)) {
      status = RepasStatus.won;
      return RepasMoveResult.won;
    }
    return crate ? RepasMoveResult.pushed : RepasMoveResult.moved;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    _restore(_history.removeLast());
    return true;
  }

  void reset() {
    keeper = level.initialKeeper;
    crates = {...level.initialCrates};
    facing = RepasDirection.south;
    status = RepasStatus.playing;
    moves = 0;
    pushes = 0;
    _history.clear();
  }

  int footprints() {
    if (pushes <= level.parPushes) return 3;
    if (pushes <= (level.parPushes * 1.25).ceil()) return 2;
    return 1;
  }

  _RepasSnapshot _snapshot() =>
      _RepasSnapshot(keeper, {...crates}, facing, status, moves, pushes);

  void _restore(_RepasSnapshot snapshot) {
    keeper = snapshot.keeper;
    crates = snapshot.crates;
    facing = snapshot.facing;
    status = snapshot.status;
    moves = snapshot.moves;
    pushes = snapshot.pushes;
  }
}

class _RepasSnapshot {
  const _RepasSnapshot(
    this.keeper,
    this.crates,
    this.facing,
    this.status,
    this.moves,
    this.pushes,
  );

  final RepasPosition keeper;
  final Set<RepasPosition> crates;
  final RepasDirection facing;
  final RepasStatus status;
  final int moves;
  final int pushes;
}
