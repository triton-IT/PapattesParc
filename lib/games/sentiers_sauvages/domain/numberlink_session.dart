import 'models.dart';

class NumberlinkSession {
  NumberlinkSession(this.level)
    : _paths = {for (final pair in level.pairs) pair.id: []};

  final NumberlinkLevelDefinition level;
  final Map<int, List<NumberlinkPosition>> _paths;
  final Set<int> _hintedPairIds = {};
  int? _activePairId;

  NumberlinkStatus status = NumberlinkStatus.playing;
  Duration elapsed = Duration.zero;
  int hintsUsed = 0;
  bool hasStarted = false;

  Map<int, List<NumberlinkPosition>> get paths =>
      Map<int, List<NumberlinkPosition>>.unmodifiable({
        for (final entry in _paths.entries)
          entry.key: List<NumberlinkPosition>.unmodifiable(entry.value),
      });

  Set<int> get hintedPairIds => Set.unmodifiable(_hintedPairIds);
  bool get hasMoved => hasStarted;
  int get hintsRemaining => 3 - hintsUsed;
  int get footprints => hintsUsed == 0
      ? 3
      : hintsUsed == 1
      ? 2
      : 1;
  int get completedPairs =>
      level.pairs.where((pair) => isPairConnected(pair.id)).length;
  int get remainingCells => level.size * level.size - _occupiedCells.length;

  List<NumberlinkPosition> pathFor(int pairId) =>
      List.unmodifiable(_paths[pairId]!);

  bool isPairConnected(int pairId) {
    final pair = level.pairs[pairId];
    final path = _paths[pairId]!;
    return path.length > 1 &&
        pair.isEndpoint(path.first) &&
        path.last == pair.otherEndpoint(path.first);
  }

  int? pairAt(NumberlinkPosition position) {
    final endpoint = level.pairAtEndpoint(position);
    if (endpoint != null) return endpoint.id;
    for (final entry in _paths.entries) {
      if (entry.value.contains(position)) return entry.key;
    }
    return null;
  }

  NumberlinkTraceResult begin(NumberlinkPosition position) {
    if (status != NumberlinkStatus.playing || !_isInside(position)) {
      return NumberlinkTraceResult.blocked;
    }
    final endpoint = level.pairAtEndpoint(position);
    if (endpoint != null) {
      final path = _paths[endpoint.id]!;
      if (path.length > 1) hasStarted = true;
      path
        ..clear()
        ..add(position);
      _activePairId = endpoint.id;
      return NumberlinkTraceResult.started;
    }
    for (final entry in _paths.entries) {
      final index = entry.value.indexOf(position);
      if (index < 0) continue;
      if (index < entry.value.length - 1) {
        entry.value.removeRange(index + 1, entry.value.length);
        hasStarted = true;
      }
      _activePairId = entry.key;
      return NumberlinkTraceResult.started;
    }
    return NumberlinkTraceResult.blocked;
  }

  NumberlinkTraceResult trace(NumberlinkPosition position) {
    final pairId = _activePairId;
    if (status != NumberlinkStatus.playing ||
        pairId == null ||
        !_isInside(position)) {
      return NumberlinkTraceResult.blocked;
    }
    final path = _paths[pairId]!;
    if (!path.last.isAdjacentTo(position)) {
      return NumberlinkTraceResult.blocked;
    }
    final ownIndex = path.indexOf(position);
    if (ownIndex >= 0) {
      if (ownIndex == path.length - 1) return NumberlinkTraceResult.blocked;
      path.removeRange(ownIndex + 1, path.length);
      hasStarted = true;
      return NumberlinkTraceResult.retracted;
    }

    final endpoint = level.pairAtEndpoint(position);
    final pair = level.pairs[pairId];
    if (endpoint != null) {
      if (endpoint.id != pairId || position != pair.otherEndpoint(path.first)) {
        return NumberlinkTraceResult.blocked;
      }
      path.add(position);
      hasStarted = true;
      _activePairId = null;
      if (completedPairs == level.pairCount && remainingCells == 0) {
        status = NumberlinkStatus.won;
        return NumberlinkTraceResult.won;
      }
      return NumberlinkTraceResult.connected;
    }
    if (pairAt(position) != null) return NumberlinkTraceResult.blocked;

    path.add(position);
    hasStarted = true;
    return NumberlinkTraceResult.extended;
  }

  void endTrace() => _activePairId = null;

  int? hint() {
    if (status != NumberlinkStatus.playing || hintsRemaining == 0) return null;
    for (final pair in level.pairs) {
      if (isPairConnected(pair.id) || _hintedPairIds.contains(pair.id)) {
        continue;
      }
      _hintedPairIds.add(pair.id);
      hintsUsed++;
      hasStarted = true;
      return pair.id;
    }
    return null;
  }

  void tick(Duration delta) {
    if (status == NumberlinkStatus.playing && hasStarted) elapsed += delta;
  }

  Set<NumberlinkPosition> get _occupiedCells => {
    for (final pair in level.pairs) ...[
      pair.animalPosition,
      pair.enclosurePosition,
    ],
    for (final path in _paths.values) ...path,
  };

  bool _isInside(NumberlinkPosition position) =>
      position.x >= 0 &&
      position.x < level.size &&
      position.y >= 0 &&
      position.y < level.size;
}
