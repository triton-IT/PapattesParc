import '../../../shared/park_catalog.dart';

enum SolitaireMode {
  drawOne(1, 'Pioche 1 carte'),
  drawThree(3, 'Pioche 3 cartes');

  const SolitaireMode(this.drawCount, this.label);

  final int drawCount;
  final String label;
}

class SolitaireLevelDefinition {
  const SolitaireLevelDefinition({
    required this.stage,
    required this.mode,
    required this.seed,
    required this.targetRedeals,
  });

  final ParkStage stage;
  final SolitaireMode mode;
  final int seed;
  final int targetRedeals;

  int get number => stage.number;
}

int solitaireFootprints(SolitaireLevelDefinition level, int redeals) {
  if (redeals <= level.targetRedeals) return 3;
  if (redeals == level.targetRedeals + 1) return 2;
  return 1;
}

enum CardSuit { hearts, diamonds, clubs, spades }

extension CardSuitInfo on CardSuit {
  bool get isRed => this == CardSuit.hearts || this == CardSuit.diamonds;

  String get symbol => switch (this) {
    CardSuit.hearts => '♥',
    CardSuit.diamonds => '♦',
    CardSuit.clubs => '♣',
    CardSuit.spades => '♠',
  };

  String get label => switch (this) {
    CardSuit.hearts => 'cœur',
    CardSuit.diamonds => 'carreau',
    CardSuit.clubs => 'trèfle',
    CardSuit.spades => 'pique',
  };
}

enum CardRank {
  ace(1, 'A'),
  two(2, '2'),
  three(3, '3'),
  four(4, '4'),
  five(5, '5'),
  six(6, '6'),
  seven(7, '7'),
  eight(8, '8'),
  nine(9, '9'),
  ten(10, '10'),
  jack(11, 'V'),
  queen(12, 'D'),
  king(13, 'R');

  const CardRank(this.value, this.label);

  final int value;
  final String label;
}

class SolitaireCard {
  const SolitaireCard({
    required this.id,
    required this.suit,
    required this.rank,
    this.faceUp = false,
  });

  final int id;
  final CardSuit suit;
  final CardRank rank;
  final bool faceUp;

  SolitaireCard withFaceUp(bool value) =>
      SolitaireCard(id: id, suit: suit, rank: rank, faceUp: value);

  String get label => '${rank.label} de ${suit.label}';
}

enum CardArea { stock, waste, tableau, foundation }

class CardLocation {
  const CardLocation(this.area, [this.pile = 0, this.card = -1]);

  const CardLocation.stock() : this(CardArea.stock);
  const CardLocation.waste() : this(CardArea.waste);
  const CardLocation.tableau(int pile, int card)
    : this(CardArea.tableau, pile, card);
  CardLocation.foundation(CardSuit suit)
    : this(CardArea.foundation, suit.index);

  final CardArea area;
  final int pile;
  final int card;

  @override
  bool operator ==(Object other) =>
      other is CardLocation &&
      area == other.area &&
      pile == other.pile &&
      card == other.card;

  @override
  int get hashCode => Object.hash(area, pile, card);
}

class SolitaireMove {
  const SolitaireMove(this.source, this.target);

  final CardLocation source;
  final CardLocation target;
}

enum SolitaireStatus { playing, won }

enum SolitaireHintKind { move, draw }

class SolitaireHint {
  const SolitaireHint.move(this.move, this.message)
    : kind = SolitaireHintKind.move;
  const SolitaireHint.draw(this.message)
    : kind = SolitaireHintKind.draw,
      move = null;

  final SolitaireHintKind kind;
  final SolitaireMove? move;
  final String message;
}
