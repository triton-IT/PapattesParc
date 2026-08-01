import 'package:flutter/material.dart';

enum GameHelpKind { refuge, match3, mahjong, solitaire }

class GameHelpButton extends StatelessWidget {
  const GameHelpButton({required this.kind, this.color, super.key});

  final GameHelpKind kind;
  final Color? color;

  @override
  Widget build(BuildContext context) => IconButton(
    key: Key('help-${kind.name}'),
    tooltip: 'Comment jouer',
    color: color,
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
              for (final item in _items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(item),
                ),
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
      'Touche deux emplacements ou fais glisser une carte. Un double toucher l’envoie vers sa fondation. Annulation et indice restent disponibles.',
    ],
  };
}
