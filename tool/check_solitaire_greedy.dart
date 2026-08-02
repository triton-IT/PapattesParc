import 'package:papatte_parc/games/refuge/domain/levels.dart' as park;
import 'package:papatte_parc/games/solitaire_animaux/domain/campaign.dart';
import 'package:papatte_parc/games/solitaire_animaux/domain/models.dart';
import 'package:papatte_parc/games/solitaire_animaux/domain/solitaire_session.dart';

void main() {
  for (final level in buildSolitaireCampaign(park.levels)) {
    final result = solveSolitaireDeal(level.mode, level.seed);
    if (result == null || result.redealCount > level.targetRedeals) {
      throw StateError('Niveau ${level.number} sans solution de référence.');
    }
  }
}

SolitaireSolveResult? solveSolitaireDeal(SolitaireMode mode, int seed) {
  final queue = _Heap()
    ..add(_Node(SolitaireSession(mode: mode, seed: seed), 0));
  final visited = <String, int>{};
  var expanded = 0;
  while (queue.isNotEmpty && expanded++ < 25000) {
    final node = queue.removeFirst();
    final session = node.session;
    if (session.canAutoFinish) {
      final finished = _copy(session)..autoFinish();
      return SolitaireSolveResult(finished.redealCount, node.depth, expanded);
    }
    if (node.depth >= 260 || session.redealCount > 10) continue;
    final signature = _signature(session);
    final previous = visited[signature];
    if (previous != null && previous <= session.redealCount) continue;
    visited[signature] = session.redealCount;
    for (final action in _actions(session)) {
      final next = _copy(session);
      final changed = action.move == null
          ? next.draw()
          : next.move(action.move!);
      if (changed) queue.add(_Node(next, node.depth + 1));
    }
  }
  return null;
}

List<_Action> _actions(SolitaireSession session) {
  final actions = <_Action>[];
  void addSource(CardLocation source, SolitaireCard card, bool revealsCard) {
    final foundation = SolitaireMove(
      source,
      CardLocation.foundation(card.suit),
    );
    if (session.canMove(foundation)) {
      actions.add(_Action(foundation, revealsCard ? 120 : 70));
    }
    for (var target = 0; target < session.tableau.length; target++) {
      final move = SolitaireMove(source, CardLocation.tableau(target, -1));
      if (!session.canMove(move)) continue;
      if (source.area == CardArea.tableau && source.pile == target) continue;
      final targetEmpty = session.tableau[target].isEmpty;
      final sourceFullyVisible =
          source.area == CardArea.tableau &&
          session.tableau[source.pile].first.faceUp;
      if (targetEmpty && sourceFullyVisible) continue;
      actions.add(_Action(move, revealsCard ? 150 : 30));
    }
  }

  if (session.waste.isNotEmpty) {
    addSource(const CardLocation.waste(), session.waste.last, false);
  }
  for (var pile = 0; pile < session.tableau.length; pile++) {
    final cards = session.tableau[pile];
    for (var index = 0; index < cards.length; index++) {
      if (!cards[index].faceUp) continue;
      addSource(
        CardLocation.tableau(pile, index),
        cards[index],
        index > 0 && !cards[index - 1].faceUp,
      );
    }
  }
  if (session.stock.isNotEmpty || session.waste.isNotEmpty) {
    actions.add(const _Action(null, 0));
  }
  actions.sort((a, b) => b.bonus.compareTo(a.bonus));
  return actions;
}

SolitaireSession _copy(SolitaireSession source) {
  final copy = SolitaireSession(mode: source.mode, seed: 0)
    ..stock.clear()
    ..waste.clear()
    ..stock.addAll(source.stock)
    ..waste.addAll(source.waste)
    ..elapsed = source.elapsed
    ..redealCount = source.redealCount
    ..status = source.status;
  for (var index = 0; index < source.tableau.length; index++) {
    copy.tableau[index]
      ..clear()
      ..addAll(source.tableau[index]);
  }
  for (var index = 0; index < source.foundations.length; index++) {
    copy.foundations[index]
      ..clear()
      ..addAll(source.foundations[index]);
  }
  return copy;
}

String _signature(SolitaireSession session) => [
  session.stock.map((card) => card.id).join(','),
  session.waste.map((card) => card.id).join(','),
  for (final pile in session.tableau)
    pile.map((card) => '${card.id}:${card.faceUp}').join(','),
  for (final pile in session.foundations) pile.map((card) => card.id).join(','),
].join('|');

class _Action {
  const _Action(this.move, this.bonus);
  final SolitaireMove? move;
  final int bonus;
}

class _Node {
  const _Node(this.session, this.depth);
  final SolitaireSession session;
  final int depth;

  int get priority =>
      session.foundationCount * 10000 +
      session.tableau
              .expand((pile) => pile)
              .where((card) => card.faceUp)
              .length *
          1000 +
      session.tableau.where((pile) => pile.isEmpty).length * 100 -
      session.redealCount * 50 -
      depth;
}

class SolitaireSolveResult {
  const SolitaireSolveResult(this.redealCount, this.depth, this.expanded);
  final int redealCount;
  final int depth;
  final int expanded;
}

class _Heap {
  final List<_Node> _nodes = [];
  bool get isNotEmpty => _nodes.isNotEmpty;

  void add(_Node node) {
    _nodes.add(node);
    var index = _nodes.length - 1;
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (_nodes[parent].priority >= node.priority) break;
      _nodes[index] = _nodes[parent];
      index = parent;
    }
    _nodes[index] = node;
  }

  _Node removeFirst() {
    final first = _nodes.first;
    final last = _nodes.removeLast();
    if (_nodes.isEmpty) return first;
    var index = 0;
    while (true) {
      final left = index * 2 + 1;
      if (left >= _nodes.length) break;
      final right = left + 1;
      final child =
          right < _nodes.length &&
              _nodes[right].priority > _nodes[left].priority
          ? right
          : left;
      if (_nodes[child].priority <= last.priority) break;
      _nodes[index] = _nodes[child];
      index = child;
    }
    _nodes[index] = last;
    return first;
  }
}
