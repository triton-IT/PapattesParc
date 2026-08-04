import 'dart:math';

import 'models.dart';

class SolitaireSession {
  SolitaireSession({required this.mode, required int seed}) {
    final deck = <SolitaireCard>[
      for (final suit in CardSuit.values)
        for (final rank in CardRank.values)
          SolitaireCard(
            id: suit.index * 13 + rank.index,
            suit: suit,
            rank: rank,
          ),
    ]..shuffle(Random(seed));
    for (var pile = 0; pile < 7; pile++) {
      for (var row = 0; row <= pile; row++) {
        final card = deck.removeLast();
        tableau[pile].add(card.withFaceUp(row == pile));
      }
    }
    stock.addAll(deck);
  }

  SolitaireSession._copy(this.mode);

  final SolitaireMode mode;
  final List<SolitaireCard> stock = [];
  final List<SolitaireCard> waste = [];
  final List<List<SolitaireCard>> tableau = List.generate(7, (_) => []);
  final List<List<SolitaireCard>> foundations = List.generate(4, (_) => []);
  final List<_SessionSnapshot> _history = [];
  SolitaireStatus status = SolitaireStatus.playing;
  Duration elapsed = Duration.zero;
  int redealCount = 0;

  bool get hasMoved => _history.isNotEmpty;
  bool get canUndo => _history.isNotEmpty;
  int get foundationCount =>
      foundations.fold(0, (sum, pile) => sum + pile.length);

  Iterable<SolitaireCard> get cards sync* {
    yield* stock;
    yield* waste;
    for (final pile in tableau) {
      yield* pile;
    }
    for (final pile in foundations) {
      yield* pile;
    }
  }

  void tick(Duration duration) {
    if (status == SolitaireStatus.playing) elapsed += duration;
  }

  bool draw() {
    if (stock.isEmpty && waste.isEmpty) return false;
    _remember();
    if (stock.isEmpty) {
      redealCount++;
      while (waste.isNotEmpty) {
        stock.add(waste.removeLast().withFaceUp(false));
      }
      return true;
    }
    final count = min(mode.drawCount, stock.length);
    for (var i = 0; i < count; i++) {
      waste.add(stock.removeLast().withFaceUp(true));
    }
    return true;
  }

  bool canMove(SolitaireMove move) {
    final moving = _movingCards(move.source);
    if (moving.isEmpty) return false;
    return switch (move.target.area) {
      CardArea.tableau => _canPlaceOnTableau(moving.first, move.target.pile),
      CardArea.foundation =>
        moving.length == 1 &&
            _canPlaceOnFoundation(moving.single, move.target.pile),
      CardArea.stock || CardArea.waste => false,
    };
  }

  bool move(SolitaireMove move) {
    if (!canMove(move)) return false;
    _remember();
    final moving = _remove(move.source);
    if (move.target.area == CardArea.tableau) {
      tableau[move.target.pile].addAll(moving);
    } else {
      foundations[move.target.pile].add(moving.single);
    }
    _revealTableauTop(move.source);
    _updateStatus();
    return true;
  }

  bool moveToFoundation(CardLocation source) {
    final moving = _movingCards(source);
    if (moving.length != 1) return false;
    return move(
      SolitaireMove(source, CardLocation.foundation(moving.single.suit)),
    );
  }

  bool undo() {
    if (_history.isEmpty) return false;
    _restore(_history.removeLast());
    return true;
  }

  SolitaireHint? hint() {
    for (var from = 0; from < tableau.length; from++) {
      final firstFaceUp = tableau[from].indexWhere((card) => card.faceUp);
      if (firstFaceUp <= 0) continue;
      for (var target = 0; target < tableau.length; target++) {
        final move = SolitaireMove(
          CardLocation.tableau(from, firstFaceUp),
          CardLocation.tableau(target, -1),
        );
        if (canMove(move)) {
          final card = tableau[from][firstFaceUp];
          return SolitaireHint.move(
            move,
            'Déplace ${_cardPhrase(card)} ${_tableauTargetPhrase(target)} pour révéler une carte.',
          );
        }
      }
    }
    for (final source in _topSources()) {
      final moving = _movingCards(source);
      if (moving.length != 1) continue;
      final move = SolitaireMove(
        source,
        CardLocation.foundation(moving.single.suit),
      );
      if (canMove(move)) {
        final card = moving.single;
        final foundation = foundations[card.suit.index];
        return SolitaireHint.move(
          move,
          foundation.isEmpty
              ? 'Déplace ${_cardPhrase(card)} vers la fondation de ${card.suit.label}.'
              : 'Déplace ${_cardPhrase(card)} sur ${_cardPhrase(foundation.last)} dans la fondation.',
        );
      }
    }
    for (var from = 0; from < tableau.length; from++) {
      final firstFaceUp = tableau[from].indexWhere((card) => card.faceUp);
      if (firstFaceUp < 0) continue;
      for (var target = 0; target < tableau.length; target++) {
        if (from == target) continue;
        final move = SolitaireMove(
          CardLocation.tableau(from, firstFaceUp),
          CardLocation.tableau(target, -1),
        );
        if (canMove(move)) {
          final card = tableau[from][firstFaceUp];
          return SolitaireHint.move(
            move,
            'Déplace ${_cardPhrase(card)} ${_tableauTargetPhrase(target)}.',
          );
        }
      }
    }
    if (_stockContainsUsefulCard()) {
      return const SolitaireHint.draw('Pioche pour trouver une carte jouable.');
    }
    return null;
  }

  String _cardPhrase(SolitaireCard card) => card.rank == CardRank.ace
      ? 'l’as de ${card.suit.label}'
      : 'le ${card.rank.label} de ${card.suit.label}';

  String _tableauTargetPhrase(int pile) => tableau[pile].isEmpty
      ? 'vers la colonne vide'
      : 'sur ${_cardPhrase(tableau[pile].last)}';

  bool get canAutoFinish {
    if (tableau.any((pile) => pile.any((card) => !card.faceUp))) return false;
    final copy = _clone();
    return copy._finishWithoutHistory();
  }

  bool autoFinish() {
    if (!prepareAutoFinish()) return false;
    _finishWithoutHistory();
    _updateStatus();
    return true;
  }

  bool prepareAutoFinish() {
    if (!canAutoFinish) return false;
    _remember();
    return true;
  }

  bool autoFinishStep() {
    for (final source in _topSources().toList()) {
      final cards = _movingCards(source);
      if (cards.length != 1) continue;
      final target = cards.single.suit.index;
      if (!_canPlaceOnFoundation(cards.single, target)) continue;
      foundations[target].add(_remove(source).single);
      _revealTableauTop(source);
      _updateStatus();
      return true;
    }
    if (stock.isEmpty && waste.isEmpty) return false;
    if (stock.isEmpty) {
      redealCount++;
      while (waste.isNotEmpty) {
        stock.add(waste.removeLast().withFaceUp(false));
      }
      return true;
    }
    final count = min(mode.drawCount, stock.length);
    for (var i = 0; i < count; i++) {
      waste.add(stock.removeLast().withFaceUp(true));
    }
    return true;
  }

  List<SolitaireCard> _movingCards(CardLocation source) =>
      switch (source.area) {
        CardArea.waste => waste.isEmpty ? const [] : [waste.last],
        CardArea.foundation =>
          foundations[source.pile].isEmpty
              ? const []
              : [foundations[source.pile].last],
        CardArea.tableau =>
          source.card < 0 ||
                  source.card >= tableau[source.pile].length ||
                  !tableau[source.pile][source.card].faceUp
              ? const []
              : tableau[source.pile].sublist(source.card),
        CardArea.stock => const [],
      };

  bool _canPlaceOnTableau(SolitaireCard card, int pile) {
    final target = tableau[pile];
    if (target.isEmpty) return card.rank == CardRank.king;
    final top = target.last;
    return top.faceUp &&
        top.suit.isRed != card.suit.isRed &&
        top.rank.value == card.rank.value + 1;
  }

  bool _canPlaceOnFoundation(SolitaireCard card, int pile) {
    if (card.suit.index != pile) return false;
    final target = foundations[pile];
    return target.isEmpty
        ? card.rank == CardRank.ace
        : target.last.rank.value + 1 == card.rank.value;
  }

  List<SolitaireCard> _remove(CardLocation source) => switch (source.area) {
    CardArea.waste => [waste.removeLast()],
    CardArea.foundation => [foundations[source.pile].removeLast()],
    CardArea.tableau => tableau[source.pile].removeRangeFrom(source.card),
    CardArea.stock => const [],
  };

  void _revealTableauTop(CardLocation source) {
    if (source.area != CardArea.tableau || tableau[source.pile].isEmpty) return;
    final top = tableau[source.pile].last;
    if (!top.faceUp) tableau[source.pile].last = top.withFaceUp(true);
  }

  Iterable<CardLocation> _topSources() sync* {
    if (waste.isNotEmpty) yield const CardLocation.waste();
    for (var pile = 0; pile < tableau.length; pile++) {
      if (tableau[pile].isNotEmpty && tableau[pile].last.faceUp) {
        yield CardLocation.tableau(pile, tableau[pile].length - 1);
      }
    }
  }

  bool _stockContainsUsefulCard() {
    if (stock.isEmpty && waste.isEmpty) return false;
    final simulatedStock = [...stock];
    final simulatedWaste = [...waste];
    final visited = <String>{};
    while (true) {
      final signature =
          '${simulatedStock.map((c) => c.id).join(',')}|${simulatedWaste.map((c) => c.id).join(',')}';
      if (!visited.add(signature)) return false;
      if (simulatedWaste.isNotEmpty &&
          _canMoveCardAnywhere(simulatedWaste.last)) {
        return true;
      }
      _drawLists(simulatedStock, simulatedWaste);
    }
  }

  bool _canMoveCardAnywhere(SolitaireCard card) {
    if (_canPlaceOnFoundation(card, card.suit.index)) return true;
    return List.generate(
      7,
      (index) => index,
    ).any((pile) => _canPlaceOnTableau(card, pile));
  }

  void _drawLists(List<SolitaireCard> source, List<SolitaireCard> target) {
    if (source.isEmpty) {
      while (target.isNotEmpty) {
        source.add(target.removeLast());
      }
      return;
    }
    for (var i = 0; i < min(mode.drawCount, source.length); i++) {
      target.add(source.removeLast());
    }
  }

  bool _finishWithoutHistory() {
    final visited = <String>{};
    while (foundationCount < 52) {
      var moved = false;
      for (final source in _topSources().toList()) {
        final cards = _movingCards(source);
        if (cards.length != 1) continue;
        final target = cards.single.suit.index;
        if (!_canPlaceOnFoundation(cards.single, target)) continue;
        foundations[target].add(_remove(source).single);
        _revealTableauTop(source);
        moved = true;
      }
      if (moved) {
        visited.clear();
        continue;
      }
      if (stock.isEmpty && waste.isEmpty) return false;
      final signature =
          '$foundationCount:${stock.map((c) => c.id).join(',')}|${waste.map((c) => c.id).join(',')}';
      if (!visited.add(signature)) return false;
      if (stock.isEmpty) {
        redealCount++;
        while (waste.isNotEmpty) {
          stock.add(waste.removeLast().withFaceUp(false));
        }
      } else {
        final count = min(mode.drawCount, stock.length);
        for (var i = 0; i < count; i++) {
          waste.add(stock.removeLast().withFaceUp(true));
        }
      }
    }
    return true;
  }

  SolitaireSession _clone() {
    final copy = SolitaireSession._copy(mode)
      ..stock.addAll(stock)
      ..waste.addAll(waste)
      ..elapsed = elapsed
      ..redealCount = redealCount
      ..status = status;
    for (var i = 0; i < 7; i++) {
      copy.tableau[i].addAll(tableau[i]);
    }
    for (var i = 0; i < 4; i++) {
      copy.foundations[i].addAll(foundations[i]);
    }
    return copy;
  }

  void _updateStatus() {
    if (foundationCount == 52) status = SolitaireStatus.won;
  }

  void _remember() => _history.add(
    _SessionSnapshot(
      stock: [...stock],
      waste: [...waste],
      tableau: [
        for (final pile in tableau) [...pile],
      ],
      foundations: [
        for (final pile in foundations) [...pile],
      ],
      status: status,
    ),
  );

  void _restore(_SessionSnapshot snapshot) {
    stock
      ..clear()
      ..addAll(snapshot.stock);
    waste
      ..clear()
      ..addAll(snapshot.waste);
    for (var i = 0; i < 7; i++) {
      tableau[i]
        ..clear()
        ..addAll(snapshot.tableau[i]);
    }
    for (var i = 0; i < 4; i++) {
      foundations[i]
        ..clear()
        ..addAll(snapshot.foundations[i]);
    }
    status = snapshot.status;
  }
}

class _SessionSnapshot {
  const _SessionSnapshot({
    required this.stock,
    required this.waste,
    required this.tableau,
    required this.foundations,
    required this.status,
  });

  final List<SolitaireCard> stock;
  final List<SolitaireCard> waste;
  final List<List<SolitaireCard>> tableau;
  final List<List<SolitaireCard>> foundations;
  final SolitaireStatus status;
}

extension on List<SolitaireCard> {
  List<SolitaireCard> removeRangeFrom(int start) {
    final result = sublist(start);
    removeRange(start, length);
    return result;
  }
}
