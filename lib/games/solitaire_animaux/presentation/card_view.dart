import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/app_theme.dart';
import '../domain/models.dart';

class SolitaireCardView extends StatelessWidget {
  const SolitaireCardView({
    required this.card,
    required this.backAnimal,
    required this.width,
    this.selected = false,
    this.highlighted = false,
    this.highlightColor,
    super.key,
  });

  final SolitaireCard card;
  final AnimalKind backAnimal;
  final double width;
  final bool selected;
  final bool highlighted;
  final Color? highlightColor;

  double get height => width * 1.4;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 140),
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(width * .1),
      border: Border.all(
        color: selected
            ? AppColors.sun
            : highlightColor != null
            ? highlightColor!
            : highlighted
            ? AppColors.success
            : AppColors.deep.withValues(alpha: .7),
        width: selected || highlighted || highlightColor != null ? 3 : 1.4,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.deep.withValues(alpha: .24),
          offset: Offset(width * .035, width * .055),
          blurRadius: width * .035,
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: card.faceUp
        ? _CardFace(card: card, width: width)
        : CardBack(animal: backAnimal),
  );
}

class CardBack extends StatelessWidget {
  const CardBack({required this.animal, super.key});

  final AnimalKind animal;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.deep,
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffffe8b0), width: 2),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: 4,
              top: 4,
              child: Icon(Icons.eco_rounded, color: Color(0x88ffe8b0)),
            ),
            const Positioned(
              right: 4,
              bottom: 4,
              child: RotatedBox(
                quarterTurns: 2,
                child: Icon(Icons.eco_rounded, color: Color(0x88ffe8b0)),
              ),
            ),
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(
                Icons.pets_rounded,
                size: 15,
                color: Color(0x77ffe8b0),
              ),
            ),
            Center(
              child: FractionallySizedBox(
                widthFactor: .65,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xfffff4dc),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xffffd166),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Image.asset(animal.asset, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EmptyCardSlot extends StatelessWidget {
  const EmptyCardSlot({
    required this.width,
    this.suit,
    this.label,
    this.highlightColor,
    super.key,
  });

  final double width;
  final CardSuit? suit;
  final String? label;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: width * 1.4,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .2),
      borderRadius: BorderRadius.circular(width * .1),
      border: Border.all(
        color: highlightColor ?? AppColors.deep.withValues(alpha: .35),
        width: highlightColor == null ? 1.5 : 3,
      ),
    ),
    alignment: Alignment.center,
    child: suit == null
        ? Text(
            label ?? '',
            style: TextStyle(
              color: AppColors.deep.withValues(alpha: .35),
              fontSize: width * .35,
              fontWeight: FontWeight.w900,
            ),
          )
        : SuitMark(
            suit: suit!,
            size: width * .34,
            color: AppColors.deep.withValues(alpha: .35),
          ),
  );
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card, required this.width});

  final SolitaireCard card;
  final double width;

  @override
  Widget build(BuildContext context) {
    final color = card.suit.isRed ? const Color(0xffb9503f) : AppColors.deep;
    final figure = _figureAnimal(card);
    return Stack(
      children: [
        Positioned(
          left: width * .08,
          top: width * .05,
          child: _Corner(card: card, color: color, width: width),
        ),
        if (width >= 54)
          Positioned(
            right: width * .08,
            bottom: width * .05,
            child: RotatedBox(
              quarterTurns: 2,
              child: _Corner(card: card, color: color, width: width),
            ),
          ),
        Center(
          child: figure == null
              ? _Pips(card: card, color: color, width: width)
              : Padding(
                  padding: EdgeInsets.fromLTRB(
                    width * .2,
                    width * .22,
                    width * .12,
                    width * .18,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xfffff0c9),
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.4),
                    ),
                    child: Image.asset(figure.asset, fit: BoxFit.contain),
                  ),
                ),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.card, required this.color, required this.width});

  final SolitaireCard card;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        card.rank.label,
        style: TextStyle(
          color: color,
          height: .9,
          fontSize: width * .22,
          fontWeight: FontWeight.w900,
        ),
      ),
      SuitMark(suit: card.suit, size: width * .16, color: color),
    ],
  );
}

class _Pips extends StatelessWidget {
  const _Pips({required this.card, required this.color, required this.width});

  final SolitaireCard card;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    final positions = _pipPositions(card.rank.value.clamp(1, 10));
    final pipSize = width * .17;
    return SizedBox(
      width: width * .62,
      height: width * .78,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            for (final position in positions)
              Positioned(
                left: position.dx * constraints.maxWidth - pipSize / 2,
                top: position.dy * constraints.maxHeight - pipSize / 2,
                child: SuitMark(suit: card.suit, size: pipSize, color: color),
              ),
          ],
        ),
      ),
    );
  }
}

List<Offset> _pipPositions(int count) {
  const left = .16;
  const center = .5;
  const right = .84;
  const top = .14;
  const upper = .31;
  const middle = .5;
  const lower = .69;
  const bottom = .86;
  const outerRows = [top, .38, .62, bottom];
  return switch (count) {
    1 => const [Offset(center, middle)],
    2 => const [Offset(center, top), Offset(center, bottom)],
    3 => const [
      Offset(center, top),
      Offset(center, middle),
      Offset(center, bottom),
    ],
    4 => const [
      Offset(left, top),
      Offset(right, top),
      Offset(left, bottom),
      Offset(right, bottom),
    ],
    5 => const [
      Offset(left, top),
      Offset(right, top),
      Offset(center, middle),
      Offset(left, bottom),
      Offset(right, bottom),
    ],
    6 => const [
      Offset(left, top),
      Offset(right, top),
      Offset(left, middle),
      Offset(right, middle),
      Offset(left, bottom),
      Offset(right, bottom),
    ],
    7 => const [
      Offset(left, top),
      Offset(right, top),
      Offset(center, upper),
      Offset(left, middle),
      Offset(right, middle),
      Offset(left, bottom),
      Offset(right, bottom),
    ],
    8 => const [
      Offset(left, top),
      Offset(right, top),
      Offset(center, upper),
      Offset(left, middle),
      Offset(right, middle),
      Offset(center, lower),
      Offset(left, bottom),
      Offset(right, bottom),
    ],
    9 => [
      for (final y in outerRows) Offset(left, y),
      const Offset(center, middle),
      for (final y in outerRows) Offset(right, y),
    ],
    10 => [
      for (final y in outerRows) Offset(left, y),
      const Offset(center, upper),
      const Offset(center, lower),
      for (final y in outerRows) Offset(right, y),
    ],
    _ => const [],
  };
}

class SuitMark extends StatelessWidget {
  const SuitMark({
    required this.suit,
    required this.size,
    required this.color,
    super.key,
  });

  final CardSuit suit;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _SuitPainter(suit, color)),
  );
}

class _SuitPainter extends CustomPainter {
  const _SuitPainter(this.suit, this.color);

  final CardSuit suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    switch (suit) {
      case CardSuit.hearts:
        canvas.drawPath(_heart(w, h), paint);
        break;
      case CardSuit.diamonds:
        canvas.drawPath(
          Path()
            ..moveTo(w * .5, 0)
            ..lineTo(w, h * .5)
            ..lineTo(w * .5, h)
            ..lineTo(0, h * .5)
            ..close(),
          paint,
        );
        break;
      case CardSuit.clubs:
        final radius = w * .22;
        canvas.drawCircle(Offset(w * .5, h * .25), radius, paint);
        canvas.drawCircle(Offset(w * .25, h * .5), radius, paint);
        canvas.drawCircle(Offset(w * .75, h * .5), radius, paint);
        canvas.drawPath(_stem(w, h), paint);
        break;
      case CardSuit.spades:
        canvas.drawPath(_spade(w, h), paint);
        canvas.drawPath(_stem(w, h), paint);
        break;
    }
  }

  Path _heart(double width, double height) => Path()
    ..moveTo(width * .5, height)
    ..cubicTo(width * .42, height * .78, 0, height * .58, 0, height * .28)
    ..cubicTo(0, 0, width * .36, -.06 * height, width * .5, height * .2)
    ..cubicTo(width * .64, -.06 * height, width, 0, width, height * .28)
    ..cubicTo(
      width,
      height * .58,
      width * .58,
      height * .78,
      width * .5,
      height,
    )
    ..close();

  Path _stem(double width, double height) => Path()
    ..moveTo(width * .44, height * .48)
    ..lineTo(width * .56, height * .48)
    ..lineTo(width * .62, height * .88)
    ..lineTo(width * .78, height)
    ..lineTo(width * .22, height)
    ..lineTo(width * .38, height * .88)
    ..close();

  Path _spade(double width, double height) => Path()
    ..moveTo(width * .5, 0)
    ..cubicTo(
      width * .42,
      height * .16,
      width * .06,
      height * .36,
      width * .06,
      height * .6,
    )
    ..cubicTo(
      width * .06,
      height * .82,
      width * .34,
      height * .86,
      width * .5,
      height * .63,
    )
    ..cubicTo(
      width * .66,
      height * .86,
      width * .94,
      height * .82,
      width * .94,
      height * .6,
    )
    ..cubicTo(
      width * .94,
      height * .36,
      width * .58,
      height * .16,
      width * .5,
      0,
    )
    ..close();

  @override
  bool shouldRepaint(_SuitPainter oldDelegate) =>
      oldDelegate.suit != suit || oldDelegate.color != color;
}

AnimalKind? _figureAnimal(SolitaireCard card) {
  final animals = switch (card.suit) {
    CardSuit.hearts => const [
      AnimalKind.capybara,
      AnimalKind.loutre,
      AnimalKind.hippopotame,
    ],
    CardSuit.diamonds => const [
      AnimalKind.suricate,
      AnimalKind.girafe,
      AnimalKind.lion,
    ],
    CardSuit.clubs => const [
      AnimalKind.pandaRoux,
      AnimalKind.loup,
      AnimalKind.ours,
    ],
    CardSuit.spades => const [
      AnimalKind.alpaga,
      AnimalKind.panthereNeiges,
      AnimalKind.markhor,
    ],
  };
  return switch (card.rank) {
    CardRank.jack => animals[0],
    CardRank.queen => animals[1],
    CardRank.king => animals[2],
    _ => null,
  };
}
