import 'dart:math';

import 'models.dart';

const _unknown = -1;
const _safe = 0;
const _animal = 1;

class BoardGenerationRequest {
  const BoardGenerationRequest(this.config, this.firstMove, this.firstSeed);

  final BoardConfig config;
  final CellPosition firstMove;
  final int firstSeed;
}

GeneratedBoard? generateBoard(BoardGenerationRequest request) =>
    generateCertifiedBoard(
      request.config,
      request.firstMove,
      request.firstSeed,
    );

GeneratedBoard? generateCertifiedBoard(
  BoardConfig config,
  CellPosition firstMove,
  int firstSeed,
) {
  for (var attempt = 0; attempt < 100; attempt++) {
    final board = ConstructiveBoardGenerator.tryGenerate(
      config,
      firstMove,
      firstSeed + attempt * 104729,
    );
    if (board != null) return board;
  }
  return null;
}

class ConstructiveBoardGenerator {
  static GeneratedBoard? tryGenerate(
    BoardConfig config,
    CellPosition firstMove,
    int seed,
  ) {
    final draft = _Draft(config, firstMove, seed);
    if (!draft.tryComplete()) return null;
    final board = draft.build();
    return CertificateVerifier.verify(board) ? board : null;
  }
}

class _Draft {
  _Draft(this.config, this.firstMove, this.seed)
    : cells = List.filled(config.cellCount, _unknown),
      visible = List.filled(config.cellCount, false),
      neighbours = _buildNeighbours(config),
      random = _DeterministicRandom(seed),
      remainingAnimals = config.animalCount,
      unknownCount = config.cellCount {
    _createInitialArea();
  }

  final BoardConfig config;
  final CellPosition firstMove;
  final int seed;
  final List<int> cells;
  final List<bool> visible;
  final List<List<int>> neighbours;
  final List<DeductionStep> steps = [];
  final List<_Branch> branches = [];
  final _DeterministicRandom random;
  int remainingAnimals;
  int unknownCount;

  bool tryComplete() {
    while (unknownCount > 0) {
      if (remainingAnimals == 0) {
        _assignRemaining(_safe, DeductionKind.revealRemainingCells);
        break;
      }
      if (remainingAnimals == unknownCount) {
        _assignRemaining(_animal, DeductionKind.flagRemainingAnimals);
        break;
      }
      if (!_tryApplyLocalDeduction() && !_tryBacktrack()) return false;
    }
    return remainingAnimals == 0;
  }

  GeneratedBoard build() {
    final animals = [for (final cell in cells) cell == _animal];
    final adjacent = List.filled(config.cellCount, 0);
    for (var index = 0; index < cells.length; index++) {
      adjacent[index] = neighbours[index].where((i) => animals[i]).length;
    }
    return GeneratedBoard(config, seed, firstMove, animals, adjacent, steps);
  }

  void _createInitialArea() {
    final targets = <CellPosition>[];
    for (
      var y = max(0, firstMove.y - 1);
      y <= min(config.height - 1, firstMove.y + 1);
      y++
    ) {
      for (
        var x = max(0, firstMove.x - 1);
        x <= min(config.width - 1, firstMove.x + 1);
        x++
      ) {
        final index = y * config.width + x;
        cells[index] = _safe;
        visible[index] = true;
        unknownCount--;
        targets.add(CellPosition(x, y));
      }
    }
    steps.add(DeductionStep(DeductionKind.initialReveal, firstMove, targets));
  }

  bool _tryApplyLocalDeduction() {
    _Candidate? safeCandidate;
    _Candidate? animalCandidate;
    var safeTargetCount = -1;
    var animalTargetCount = 1 << 31;
    var safeTies = 0;
    var animalTies = 0;

    for (var source = 0; source < cells.length; source++) {
      if (!visible[source]) continue;
      final targets = _unknownNeighbours(source);
      final count = targets.length;
      if (count == 0) continue;
      if (remainingAnimals <= unknownCount - count) {
        final choice = _chooseCandidate(
          safeCandidate,
          safeTargetCount,
          safeTies,
          source,
          targets,
          preferLarger: true,
        );
        safeCandidate = choice.candidate;
        safeTargetCount = choice.count;
        safeTies = choice.ties;
      }
      if (count <= remainingAnimals) {
        final choice = _chooseCandidate(
          animalCandidate,
          animalTargetCount,
          animalTies,
          source,
          targets,
          preferLarger: false,
        );
        animalCandidate = choice.candidate;
        animalTargetCount = choice.count;
        animalTies = choice.ties;
      }
    }

    final hasSafe = safeCandidate != null;
    final hasAnimal = animalCandidate != null;
    if (!hasSafe && !hasAnimal) return false;
    final placeAnimals =
        hasAnimal && (!hasSafe || random.next(unknownCount) < remainingAnimals);
    if (hasSafe && hasAnimal && branches.length < 64) {
      branches.add(
        _Branch(
          List.of(cells),
          List.of(visible),
          remainingAnimals,
          unknownCount,
          steps.length,
          placeAnimals ? safeCandidate : animalCandidate,
          placeAnimals ? _safe : _animal,
        ),
      );
    }
    _apply(
      placeAnimals ? animalCandidate : safeCandidate!,
      placeAnimals ? _animal : _safe,
    );
    return true;
  }

  ({_Candidate candidate, int count, int ties}) _chooseCandidate(
    _Candidate? selected,
    int selectedCount,
    int ties,
    int source,
    List<int> targets, {
    required bool preferLarger,
  }) {
    final count = targets.length;
    final better = preferLarger ? count > selectedCount : count < selectedCount;
    if (better) {
      return (candidate: _Candidate(source, targets), count: count, ties: 1);
    }
    if (count != selectedCount) {
      return (candidate: selected!, count: selectedCount, ties: ties);
    }
    ties++;
    if (random.next(ties) == 0) selected = _Candidate(source, targets);
    return (candidate: selected!, count: selectedCount, ties: ties);
  }

  bool _tryBacktrack() {
    if (branches.isEmpty) return false;
    final branch = branches.removeLast();
    cells.setAll(0, branch.cells);
    visible.setAll(0, branch.visible);
    remainingAnimals = branch.remainingAnimals;
    unknownCount = branch.unknownCount;
    steps.removeRange(branch.stepCount, steps.length);
    _apply(branch.alternative, branch.alternativeValue);
    return true;
  }

  void _apply(_Candidate candidate, int value) {
    final targets = <CellPosition>[];
    for (final index in candidate.targets) {
      cells[index] = value;
      visible[index] = value == _safe;
      unknownCount--;
      if (value == _animal) remainingAnimals--;
      targets.add(_position(index));
    }
    steps.add(
      DeductionStep(
        value == _animal
            ? DeductionKind.flagAnimals
            : DeductionKind.revealSafeCells,
        _position(candidate.source),
        targets,
      ),
    );
  }

  void _assignRemaining(int value, DeductionKind kind) {
    final targets = <CellPosition>[];
    for (var index = 0; index < cells.length; index++) {
      if (cells[index] != _unknown) continue;
      cells[index] = value;
      visible[index] = value == _safe;
      unknownCount--;
      if (value == _animal) remainingAnimals--;
      targets.add(_position(index));
    }
    steps.add(DeductionStep(kind, const CellPosition(0, 0), targets));
  }

  List<int> _unknownNeighbours(int source) =>
      neighbours[source].where((index) => cells[index] == _unknown).toList();

  CellPosition _position(int index) =>
      CellPosition(index % config.width, index ~/ config.width);
}

class _Candidate {
  const _Candidate(this.source, this.targets);

  final int source;
  final List<int> targets;
}

class _Branch {
  const _Branch(
    this.cells,
    this.visible,
    this.remainingAnimals,
    this.unknownCount,
    this.stepCount,
    this.alternative,
    this.alternativeValue,
  );

  final List<int> cells;
  final List<bool> visible;
  final int remainingAnimals;
  final int unknownCount;
  final int stepCount;
  final _Candidate alternative;
  final int alternativeValue;
}

class _DeterministicRandom {
  _DeterministicRandom(int seed) : _state = seed & 0xffffffff;

  int _state;

  int next(int maximum) {
    _state = (_state * 1664525 + 1013904223) & 0xffffffff;
    return _state % maximum;
  }
}

List<List<int>> _buildNeighbours(BoardConfig config) {
  return List.generate(config.cellCount, (index) {
    final x = index % config.width;
    final y = index ~/ config.width;
    final result = <int>[];
    for (
      var adjacentY = max(0, y - 1);
      adjacentY <= min(config.height - 1, y + 1);
      adjacentY++
    ) {
      for (
        var adjacentX = max(0, x - 1);
        adjacentX <= min(config.width - 1, x + 1);
        adjacentX++
      ) {
        if (adjacentX != x || adjacentY != y) {
          result.add(adjacentY * config.width + adjacentX);
        }
      }
    }
    return result;
  });
}

class CertificateVerifier {
  static bool verify(GeneratedBoard board) {
    final visible = List.filled(board.config.cellCount, false);
    final flagged = List.filled(board.config.cellCount, false);
    var flagCount = 0;
    for (final step in board.certificate) {
      final result = _verifyStep(board, step, visible, flagged, flagCount);
      if (!result.valid) return false;
      flagCount = result.flagCount;
    }
    for (var index = 0; index < board.config.cellCount; index++) {
      final position = _position(board.config, index);
      if (board.isAnimal(position) ? !flagged[index] : !visible[index]) {
        return false;
      }
    }
    return flagCount == board.config.animalCount;
  }

  static ({bool valid, int flagCount}) _verifyStep(
    GeneratedBoard board,
    DeductionStep step,
    List<bool> visible,
    List<bool> flagged,
    int flagCount,
  ) {
    if (step.kind == DeductionKind.initialReveal) {
      return (
        valid: _revealTargets(board, step.targets, visible, flagged),
        flagCount: flagCount,
      );
    }
    if (step.kind == DeductionKind.revealRemainingCells) {
      if (flagCount != board.config.animalCount) {
        return (valid: false, flagCount: flagCount);
      }
      if (step.targets.length != _unknownCount(visible, flagged)) {
        return (valid: false, flagCount: flagCount);
      }
      return (
        valid: _revealTargets(board, step.targets, visible, flagged),
        flagCount: flagCount,
      );
    }
    if (step.kind == DeductionKind.flagRemainingAnimals) {
      if (_unknownCount(visible, flagged) !=
              board.config.animalCount - flagCount ||
          step.targets.length != _unknownCount(visible, flagged)) {
        return (valid: false, flagCount: flagCount);
      }
      return _flagTargets(board, step.targets, visible, flagged, flagCount);
    }

    final sourceIndex = _index(board.config, step.source);
    if (!visible[sourceIndex] ||
        !_targetsMatchUnknownNeighbours(board.config, step, visible, flagged)) {
      return (valid: false, flagCount: flagCount);
    }
    final adjacentFlags = _adjacentFlagCount(
      board.config,
      step.source,
      flagged,
    );
    if (step.kind == DeductionKind.revealSafeCells) {
      if (adjacentFlags != board.adjacentAnimals(step.source)) {
        return (valid: false, flagCount: flagCount);
      }
      return (
        valid: _revealTargets(board, step.targets, visible, flagged),
        flagCount: flagCount,
      );
    }
    if (adjacentFlags + step.targets.length !=
        board.adjacentAnimals(step.source)) {
      return (valid: false, flagCount: flagCount);
    }
    return _flagTargets(board, step.targets, visible, flagged, flagCount);
  }

  static bool _revealTargets(
    GeneratedBoard board,
    List<CellPosition> targets,
    List<bool> visible,
    List<bool> flagged,
  ) {
    for (final target in targets) {
      final index = _index(board.config, target);
      if (visible[index] || flagged[index] || board.isAnimal(target)) {
        return false;
      }
      visible[index] = true;
    }
    return true;
  }

  static ({bool valid, int flagCount}) _flagTargets(
    GeneratedBoard board,
    List<CellPosition> targets,
    List<bool> visible,
    List<bool> flagged,
    int flagCount,
  ) {
    for (final target in targets) {
      final index = _index(board.config, target);
      if (visible[index] || flagged[index] || !board.isAnimal(target)) {
        return (valid: false, flagCount: flagCount);
      }
      flagged[index] = true;
      flagCount++;
    }
    return (valid: true, flagCount: flagCount);
  }

  static bool _targetsMatchUnknownNeighbours(
    BoardConfig config,
    DeductionStep step,
    List<bool> visible,
    List<bool> flagged,
  ) {
    final targets = step.targets.toSet();
    var matched = 0;
    var unknown = 0;
    for (final position in _neighbourPositions(config, step.source)) {
      final index = _index(config, position);
      if (visible[index] || flagged[index]) continue;
      unknown++;
      if (targets.contains(position)) matched++;
    }
    return matched == targets.length && matched == unknown;
  }

  static int _adjacentFlagCount(
    BoardConfig config,
    CellPosition position,
    List<bool> flagged,
  ) => _neighbourPositions(
    config,
    position,
  ).where((neighbour) => flagged[_index(config, neighbour)]).length;

  static int _unknownCount(List<bool> visible, List<bool> flagged) {
    var count = 0;
    for (var index = 0; index < visible.length; index++) {
      if (!visible[index] && !flagged[index]) count++;
    }
    return count;
  }
}

Iterable<CellPosition> _neighbourPositions(
  BoardConfig config,
  CellPosition position,
) sync* {
  for (
    var y = max(0, position.y - 1);
    y <= min(config.height - 1, position.y + 1);
    y++
  ) {
    for (
      var x = max(0, position.x - 1);
      x <= min(config.width - 1, position.x + 1);
      x++
    ) {
      if (x != position.x || y != position.y) yield CellPosition(x, y);
    }
  }
}

int _index(BoardConfig config, CellPosition position) =>
    position.y * config.width + position.x;

CellPosition _position(BoardConfig config, int index) =>
    CellPosition(index % config.width, index ~/ config.width);
