import 'package:flutter/material.dart';

import 'app_theme.dart';

enum GameHelpKind { refuge, match3, mahjong, solitaire, sudoku, repasAnimaux }

class GameHelpButton extends StatelessWidget {
  const GameHelpButton({
    required this.kind,
    this.color,
    this.compact = false,
    super.key,
  });

  final GameHelpKind kind;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) => IconButton(
    key: Key('help-${kind.name}'),
    tooltip: 'Comment jouer',
    color: color,
    padding: compact ? EdgeInsets.zero : null,
    constraints: compact
        ? const BoxConstraints.tightFor(width: 40, height: 40)
        : null,
    onPressed: () => _showHelp(context),
    icon: const Icon(Icons.help_outline_rounded),
  );

  Future<void> _showHelp(BuildContext context) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_title),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            key: Key('help-content-${kind.name}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GameCoach(kind: kind, messages: _items),
              if (kind == GameHelpKind.match3) const _Match3Legend(),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('J’AI COMPRIS'),
        ),
      ],
    ),
  );

  String get _title => switch (kind) {
    GameHelpKind.refuge => 'Balises du refuge',
    GameHelpKind.match3 => 'Align’Animaux',
    GameHelpKind.mahjong => 'Mahjong des animaux',
    GameHelpKind.solitaire => 'Solitaire des animaux',
    GameHelpKind.sudoku => 'Le Défi des Papattes',
    GameHelpKind.repasAnimaux => 'Le repas des animaux',
  };

  List<String> get _items => switch (kind) {
    GameHelpKind.refuge => const [
      'Observe les nombres : ils indiquent combien d’animaux se trouvent dans les cases voisines.',
      'Touche une case pour l’observer. Maintiens-la pour poser ou retirer une balise.',
      'Localise tous les animaux sans révéler leur case. Pince pour zoomer et déplace le plateau si nécessaire.',
    ],
    GameHelpKind.match3 => const [
      'Échange deux animaux voisins pour en aligner au moins trois et remplir les objectifs avant la fin des coups.',
      'Les obstacles se nettoient avec les alignements. Les paniers doivent atteindre le bas du plateau. Les alignements de quatre ou cinq créent des bonus.',
      'Les nouveaux alignements forment des cascades : chaque étape compte dans les objectifs et rapporte davantage de points.',
    ],
    GameHelpKind.mahjong => const [
      'Sélectionne deux animaux identiques pour retirer leur paire.',
      'Une tuile est libre si aucune tuile ne la recouvre et si au moins un de ses côtés est dégagé.',
      'Utilise un indice ou un mélange si tu bloques. Pince pour zoomer et déplace le plateau pour explorer les grandes dispositions.',
    ],
    GameHelpKind.solitaire => const [
      'Construis les quatre fondations de l’as au roi, une enseigne par pile.',
      'Sur le tableau, pose les cartes en ordre décroissant en alternant les couleurs. Seul un roi peut ouvrir une colonne vide.',
      'Une victoire débloque le niveau suivant. Moins tu recycles la défausse pour reformer la pioche, plus tu gagnes d’empreintes.',
      'Le temps est enregistré comme record mais ne change pas les empreintes. Annulation et indice restent disponibles.',
    ],
    GameHelpKind.sudoku => const [
      'Les emplacements de la parade ont été mélangés. Replace les animaux avant l’ouverture du parc.',
      'Chaque animal doit apparaître une seule fois dans chaque ligne, chaque colonne et chaque enclos.',
      'Sélectionne une case puis un animal. Le mode Notes conserve tes candidats et trois indices peuvent remplir une case si tu bloques.',
    ],
    GameHelpKind.repasAnimaux => const [
      'Guide le soigneur avec les flèches, les touches WASD, un glissement ou le pavé directionnel.',
      'Pousse chaque caisse de nourriture sur un point de nourrissage. Une caisse ne peut être ni tirée ni pousser une autre caisse.',
      'Annule autant de déplacements que nécessaire ou recommence le niveau si une caisse est bloquée.',
    ],
  };
}

class _GameCoach extends StatefulWidget {
  const _GameCoach({required this.kind, required this.messages});

  final GameHelpKind kind;
  final List<String> messages;

  @override
  State<_GameCoach> createState() => _GameCoachState();
}

class _GameCoachState extends State<_GameCoach> {
  var _messageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.of(context).disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 350);
    return Padding(
      key: Key('help-coach-${widget.kind.name}'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final portraitSize = constraints.maxWidth < 320 ? 56.0 : 76.0;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    key: ValueKey(_messageIndex),
                    tween: Tween(begin: 0, end: 1),
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset(-12 * (1 - value), 0),
                      child: Transform.rotate(
                        angle: -.08 * (1 - value),
                        child: Opacity(opacity: value, child: child),
                      ),
                    ),
                    child: Semantics(
                      image: true,
                      label: 'Suricate guide',
                      child: Image.asset(
                        'assets/match3/animals/suricate.png',
                        key: const Key('help-coach-suricate'),
                        width: portraitSize,
                        height: portraitSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: duration,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          alignment: Alignment.centerLeft,
                          scale: Tween(begin: .92, end: 1.0).animate(animation),
                          child: child,
                        ),
                      ),
                      child: _SpeechBubble(
                        key: ValueKey(_messageIndex),
                        message: widget.messages[_messageIndex],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                key: const Key('help-coach-previous'),
                tooltip: 'Consigne précédente',
                onPressed: _messageIndex == 0
                    ? null
                    : () => setState(() => _messageIndex--),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Text('${_messageIndex + 1} sur ${widget.messages.length}'),
              IconButton(
                key: const Key('help-coach-next'),
                tooltip: 'Consigne suivante',
                onPressed: _messageIndex == widget.messages.length - 1
                    ? null
                    : () => setState(() => _messageIndex++),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _SpeechBubblePainter(),
    child: Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 14, 14),
        child: Text(message),
      ),
    ),
  );
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(10, 0, size.width - 10, size.height),
          const Radius.circular(18),
        ),
      )
      ..moveTo(11, 24)
      ..lineTo(0, 36)
      ..lineTo(11, 44)
      ..close();
    canvas.drawShadow(path, AppColors.deep.withValues(alpha: .2), 4, false);
    canvas.drawPath(path, Paint()..color = const Color(0xfffff4dc));
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.sun
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpeechBubblePainter oldDelegate) => false;
}

class _Match3Legend extends StatelessWidget {
  const _Match3Legend();

  static const _bonuses = [
    (
      icon: Icons.swap_horiz_rounded,
      title: 'Flèches horizontales',
      effect: '4 animaux horizontaux : nettoie toute la ligne.',
    ),
    (
      icon: Icons.swap_vert_rounded,
      title: 'Flèches verticales',
      effect: '4 animaux verticaux : nettoie toute la colonne.',
    ),
    (
      icon: Icons.redeem_rounded,
      title: 'Cadeau',
      effect: 'Alignement en T, L ou croix : nettoie une zone 3 × 3.',
    ),
    (
      icon: Icons.pets_rounded,
      title: 'Patte dorée',
      effect: '5 animaux ou plus : retire tous ceux de la même espèce.',
    ),
  ];

  static const _obstacles = [
    (
      icon: Icons.eco_rounded,
      iconColor: Color(0xff39784f),
      backgroundColor: Color(0xffa8c878),
      title: 'Feuilles',
      effect:
          'Bloquent l’animal et les alignements. Forme un alignement sur une case voisine pour les retirer.',
    ),
    (
      icon: Icons.water_drop_rounded,
      iconColor: Color(0xff70432e),
      backgroundColor: Color(0xffb88a66),
      title: 'Boue',
      effect: 'Fais passer un alignement par cette case pour retirer la boue.',
    ),
    (
      icon: Icons.grass_rounded,
      iconColor: Color(0xff245b4a),
      backgroundColor: Color(0xff77a45b),
      title: 'Lianes',
      effect:
          'Immobilisent l’animal ; forme un alignement sur sa case ou une voisine directe.',
    ),
    (
      icon: Icons.ac_unit_rounded,
      iconColor: Color(0xff31889b),
      backgroundColor: Color(0xffbde8ef),
      title: 'Glace',
      effect:
          'Chaque alignement passant par la case retire une couche ; bord épais = 2 couches.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('match3-legend'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Divider(),
      _sectionTitle(context, 'BONUS · PASTILLE JAUNE EN BAS À DROITE'),
      const SizedBox(height: 8),
      for (final bonus in _bonuses)
        _LegendRow(
          icon: bonus.icon,
          iconColor: AppColors.deep,
          backgroundColor: AppColors.sun,
          title: bonus.title,
          effect: bonus.effect,
          round: true,
        ),
      const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: Text(
          'Un bonus s’active dans un alignement ou lorsqu’un autre bonus le touche. Deux bonus voisins combinent leurs effets ; deux pattes nettoient tout le plateau.',
        ),
      ),
      _sectionTitle(context, 'OBSTACLES · SYMBOLE EN HAUT À GAUCHE'),
      const SizedBox(height: 8),
      for (final obstacle in _obstacles)
        _LegendRow(
          icon: obstacle.icon,
          iconColor: obstacle.iconColor,
          backgroundColor: obstacle.backgroundColor,
          title: obstacle.title,
          effect: obstacle.effect,
        ),
      _sectionTitle(context, 'À LIVRER'),
      const SizedBox(height: 8),
      const _LegendRow(
        icon: Icons.shopping_basket_rounded,
        iconColor: Color(0xffb56736),
        backgroundColor: Color(0xfffff4dc),
        title: 'Panier de friandises',
        effect:
            'Ne s’échange pas et résiste aux bonus. Libère les cases dessous pour le faire descendre jusqu’en bas.',
      ),
    ],
  );

  Widget _sectionTitle(BuildContext context, String title) => Semantics(
    header: true,
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: AppColors.muted,
        fontWeight: FontWeight.w900,
        letterSpacing: .5,
      ),
    ),
  );
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.effect,
    this.round = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String title;
  final String effect;
  final bool round;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: round ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: round ? null : BorderRadius.circular(6),
            ),
            child: ExcludeSemantics(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title — ',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  TextSpan(text: effect),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
