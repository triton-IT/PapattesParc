import 'dart:math';

import '../../../shared/animal_catalog.dart';
import 'models.dart';

class AnimalSortSession {
  AnimalSortSession(this.level)
    : zones = [
        for (final zone in level.initialZones) [...zone],
      ];

  final AnimalSortLevelDefinition level;
  final List<List<AnimalKind>> zones;
  final List<_AnimalSortSnapshot> _history = [];
  AnimalSortStatus status = AnimalSortStatus.playing;
  int moves = 0;
  int hintsRemaining = 3;
  int _referenceIndex = 0;
  bool _onReferencePath = true;

  bool get canUndo => _history.isNotEmpty;
  bool get hasMoved => moves > 0;
  int get completedMeals => zones.where(_isComplete).length;

  bool canMove(int from, int to) {
    if (status == AnimalSortStatus.won || from == to || zones[from].isEmpty) {
      return false;
    }
    final destination = zones[to];
    return destination.length < animalSortZoneCapacity &&
        (destination.isEmpty || destination.last == zones[from].last);
  }

  AnimalSortMoveResult move(int from, int to) {
    if (!canMove(from, to)) return AnimalSortMoveResult.blocked;
    _history.add(_snapshot());
    final source = zones[from];
    final animal = source.last;
    final count = min(
      _topRun(source),
      animalSortZoneCapacity - zones[to].length,
    );
    source.removeRange(source.length - count, source.length);
    zones[to].addAll(List.filled(count, animal));
    moves++;
    if (_onReferencePath) {
      final expected = level.referenceSolution[_referenceIndex];
      if (expected == AnimalSortMove(from, to)) {
        _referenceIndex++;
      } else {
        _onReferencePath = false;
      }
    }
    if (zones.every((zone) => zone.isEmpty || _isComplete(zone))) {
      status = AnimalSortStatus.won;
      return AnimalSortMoveResult.won;
    }
    return AnimalSortMoveResult.moved;
  }

  bool undo() {
    if (_history.isEmpty) return false;
    final snapshot = _history.removeLast();
    for (var index = 0; index < zones.length; index++) {
      zones[index]
        ..clear()
        ..addAll(snapshot.zones[index]);
    }
    status = snapshot.status;
    moves = snapshot.moves;
    _referenceIndex = snapshot.referenceIndex;
    _onReferencePath = snapshot.onReferencePath;
    return true;
  }

  AnimalSortMove? hint() {
    if (hintsRemaining == 0 || !_onReferencePath) return null;
    if (_referenceIndex == level.referenceSolution.length) return null;
    hintsRemaining--;
    return level.referenceSolution[_referenceIndex];
  }

  int footprints() {
    if (moves <= level.parMoves) return 3;
    if (moves <= (level.parMoves * 1.25).ceil()) return 2;
    return 1;
  }

  _AnimalSortSnapshot _snapshot() => _AnimalSortSnapshot(
    [
      for (final zone in zones) [...zone],
    ],
    status,
    moves,
    _referenceIndex,
    _onReferencePath,
  );

  bool _isComplete(List<AnimalKind> zone) =>
      zone.length == animalSortZoneCapacity && zone.every((a) => a == zone[0]);

  int _topRun(List<AnimalKind> zone) {
    var count = 1;
    while (count < zone.length && zone[zone.length - 1 - count] == zone.last) {
      count++;
    }
    return count;
  }
}

class _AnimalSortSnapshot {
  const _AnimalSortSnapshot(
    this.zones,
    this.status,
    this.moves,
    this.referenceIndex,
    this.onReferencePath,
  );

  final List<List<AnimalKind>> zones;
  final AnimalSortStatus status;
  final int moves;
  final int referenceIndex;
  final bool onReferencePath;
}
