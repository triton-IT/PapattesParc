import 'dart:math';

import '../../../shared/animal_catalog.dart';
import 'mahjong_solver.dart';
import 'models.dart';

class MahjongDeal {
  const MahjongDeal(this.animals, this.solution, this.complexity);

  final List<AnimalKind> animals;
  final List<MahjongPair> solution;
  final int complexity;
}

class MahjongGenerator {
  MahjongGenerator({
    required this.layout,
    required this.animals,
    required this.random,
  });

  final MahjongLayoutDefinition layout;
  final List<AnimalKind> animals;
  final Random random;

  MahjongDeal generate() {
    var symbols = _solvableSymbols();
    final present = List.filled(layout.tileCount, true);
    final initialSolver = MahjongSolver(layout.positions, symbols);
    var solution = initialSolver.evaluate(
      present,
      initialSolver.geometricRemovalOrder(present),
    );
    var bestSymbols = symbols;
    var bestSolution = solution;
    final attempts = 3 + (layout.challenge * 6).round();

    for (var attempt = 0; attempt < attempts; attempt++) {
      final candidate = List<int>.of(symbols);
      _swapDifferentSymbols(candidate);
      final candidateSolution = MahjongSolver(
        layout.positions,
        candidate,
      ).solve(List.filled(layout.tileCount, true), maxStates: 1000);
      if (candidateSolution == null) continue;
      symbols = candidate;
      solution = candidateSolution;
      if (solution.complexity > bestSolution.complexity) {
        bestSymbols = symbols;
        bestSolution = solution;
      }
    }

    return MahjongDeal(
      [for (final symbol in bestSymbols) animals[symbol]],
      bestSolution.moves,
      bestSolution.complexity,
    );
  }

  List<int> _solvableSymbols() {
    final emptySymbols = List.filled(layout.tileCount, 0);
    final order = MahjongSolver(
      layout.positions,
      emptySymbols,
    ).geometricRemovalOrder(List.filled(layout.tileCount, true));
    final pairs = [
      for (var symbol = 0; symbol < animals.length; symbol++) symbol,
      for (var symbol = 0; symbol < animals.length; symbol++) symbol,
    ]..shuffle(random);
    final symbols = List.filled(layout.tileCount, 0);
    for (var index = 0; index < order.length; index++) {
      symbols[order[index].first] = pairs[index];
      symbols[order[index].second] = pairs[index];
    }
    return symbols;
  }

  void _swapDifferentSymbols(List<int> symbols) {
    final first = random.nextInt(symbols.length);
    var second = random.nextInt(symbols.length);
    while (symbols[first] == symbols[second]) {
      second = random.nextInt(symbols.length);
    }
    final value = symbols[first];
    symbols[first] = symbols[second];
    symbols[second] = value;
  }
}

class RecordedRandom implements Random {
  RecordedRandom(int seed) : _random = Random(seed);
  final Random _random;
  final List<int> calls = [];
  @override
  int nextInt(int max) {
    calls.add(max);
    return _random.nextInt(max);
  }

  @override
  double nextDouble() {
    calls.add(-1);
    return _random.nextDouble();
  }

  @override
  bool nextBool() {
    calls.add(-2);
    return _random.nextBool();
  }
}

class PreparedMahjongDeal {
  const PreparedMahjongDeal(this.deal, this.randomCalls);
  final MahjongDeal deal;
  final List<int> randomCalls;
}
