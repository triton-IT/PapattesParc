import 'dart:collection';

import 'models.dart';

class GameSession {
  GameSession(this.config)
    : _revealed = List.filled(config.cellCount, false),
      _flagged = List.filled(config.cellCount, false);

  final BoardConfig config;
  final List<bool> _revealed;
  final List<bool> _flagged;
  GeneratedBoard? board;
  GameStatus status = GameStatus.waitingFirstMove;
  CellPosition? triggeredAnimal;
  Duration elapsed = Duration.zero;
  bool isPractice = false;
  int hintsUsed = 0;
  int _revealedSafeCells = 0;
  int _flagCount = 0;
  bool _timerStarted = false;
  final List<(List<bool>, List<bool>, int, int)> _history = [];

  bool get canUndo => _history.isNotEmpty && status == GameStatus.running;

  void _saveUndo() => _history.add((
    List.of(_revealed),
    List.of(_flagged),
    _revealedSafeCells,
    _flagCount,
  ));

  bool undo() {
    if (!canUndo) return false;
    final (revealed, flagged, safeCells, flags) = _history.removeLast();
    _revealed.setAll(0, revealed);
    _flagged.setAll(0, flagged);
    _revealedSafeCells = safeCells;
    _flagCount = flags;
    return true;
  }

  int get remainingAnimals => config.animalCount - _flagCount;

  /// Returns a position and the action: observe, flag, or remove a wrong flag.
  (CellPosition, String)? hint() {
    if (status != GameStatus.running || board == null) return null;
    for (var i = 0; i < config.cellCount; i++) {
      final p = _position(i);
      if (_flagged[i] && !board!.isAnimal(p)) return (p, 'retire cette balise');
    }
    for (var i = 0; i < config.cellCount; i++) {
      if (!_revealed[i]) continue;
      final p = _position(i);
      final neighbours = _neighbours(p).toList();
      final flags = neighbours.where((n) => _flagged[_index(n)]).length;
      final hidden = neighbours
          .where((n) => !_revealed[_index(n)] && !_flagged[_index(n)])
          .toList();
      if (hidden.isEmpty) continue;
      final remaining = board!.adjacentAnimals(p) - flags;
      if (remaining == 0) return (hidden.first, 'observe cette case');
      if (remaining == hidden.length) {
        return (hidden.first, 'pose une balise ici');
      }
    }
    final hidden = [
      for (var i = 0; i < config.cellCount; i++)
        if (!_revealed[i] && !_flagged[i]) _position(i),
    ];
    if (hidden.isNotEmpty && remainingAnimals == 0) {
      return (hidden.first, 'observe cette case');
    }
    if (hidden.isNotEmpty && remainingAnimals == hidden.length) {
      return (hidden.first, 'pose une balise ici');
    }
    return null;
  }

  void prepare(GeneratedBoard generatedBoard, {required bool practice}) {
    board = generatedBoard;
    isPractice = practice;
    status = GameStatus.running;
    _timerStarted = !practice;
    _revealSafeArea(generatedBoard.firstMove);
    _checkVictory();
  }

  void tick(Duration delta) {
    if (status == GameStatus.running && _timerStarted) elapsed += delta;
  }

  void reveal(CellPosition position) {
    if (status != GameStatus.running) return;
    _startPracticeTimer();
    final index = _index(position);
    if (_revealed[index] || _flagged[index]) return;
    _saveUndo();
    if (board!.isAnimal(position)) {
      _revealed[index] = true;
      triggeredAnimal = position;
      status = GameStatus.lost;
      return;
    }
    _revealSafeArea(position);
    _checkVictory();
  }

  FlagResult toggleFlag(CellPosition position) {
    if (status != GameStatus.running) return FlagResult.ignored;
    _startPracticeTimer();
    final index = _index(position);
    if (_revealed[index]) return FlagResult.ignored;
    if (!_flagged[index] && _flagCount == config.animalCount) {
      return FlagResult.limitReached;
    }
    _saveUndo();
    if (_flagged[index]) {
      _flagged[index] = false;
      _flagCount--;
      return FlagResult.changed;
    }
    if (_flagCount == config.animalCount) return FlagResult.limitReached;
    _flagged[index] = true;
    _flagCount++;
    _checkVictory();
    return FlagResult.changed;
  }

  CellSnapshot cell(CellPosition position) {
    final index = _index(position);
    final animal = board?.isAnimal(position) ?? false;
    return CellSnapshot(
      isAnimal: animal,
      isRevealed: _revealed[index],
      isFlagged: _flagged[index],
      isTriggeredAnimal:
          status == GameStatus.lost && animal && position == triggeredAnimal,
      isWrongFlag: status == GameStatus.lost && _flagged[index] && !animal,
      adjacentAnimals: board?.adjacentAnimals(position) ?? 0,
    );
  }

  void _revealSafeArea(CellPosition start) {
    final queue = Queue<CellPosition>()..add(start);
    while (queue.isNotEmpty) {
      final position = queue.removeFirst();
      final index = _index(position);
      if (_revealed[index] || _flagged[index] || board!.isAnimal(position)) {
        continue;
      }
      _revealed[index] = true;
      _revealedSafeCells++;
      if (board!.adjacentAnimals(position) != 0) continue;
      queue.addAll(_neighbours(position));
    }
  }

  void _checkVictory() {
    if (_revealedSafeCells != config.cellCount - config.animalCount ||
        _flagCount != config.animalCount) {
      return;
    }
    for (var index = 0; index < config.cellCount; index++) {
      if (board!.isAnimal(_position(index)) != _flagged[index]) return;
    }
    status = GameStatus.won;
  }

  Iterable<CellPosition> _neighbours(CellPosition position) sync* {
    for (
      var y = (position.y - 1).clamp(0, config.height - 1);
      y <= (position.y + 1).clamp(0, config.height - 1);
      y++
    ) {
      for (
        var x = (position.x - 1).clamp(0, config.width - 1);
        x <= (position.x + 1).clamp(0, config.width - 1);
        x++
      ) {
        if (x != position.x || y != position.y) yield CellPosition(x, y);
      }
    }
  }

  void _startPracticeTimer() {
    if (isPractice) _timerStarted = true;
  }

  int _index(CellPosition position) => position.y * config.width + position.x;
  CellPosition _position(int index) =>
      CellPosition(index % config.width, index ~/ config.width);
}
