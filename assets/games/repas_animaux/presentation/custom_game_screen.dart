import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../domain/generator.dart';

class RepasCustomGameScreen extends StatefulWidget {
  const RepasCustomGameScreen({
    required this.generating,
    required this.onBack,
    required this.onStart,
    super.key,
  });

  final bool generating;
  final VoidCallback onBack;
  final ValueChanged<RepasFreeGameConfig> onStart;

  @override
  State<RepasCustomGameScreen> createState() => _RepasCustomGameScreenState();
}

class _RepasCustomGameScreenState extends State<RepasCustomGameScreen> {
  RepasBoardSize _size = RepasBoardSize.medium;
  RepasDifficulty _difficulty = RepasDifficulty.medium;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .12,
              child: Image.asset('assets/park_map.png', fit: BoxFit.cover),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('repas-custom-back'),
                      tooltip: 'Retour aux niveaux',
                      onPressed: widget.generating ? null : widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(
                      backgroundColor: AppColors.sun,
                      foregroundColor: AppColors.deep,
                      child: Icon(Icons.tune_rounded),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'PARTIE LIBRE',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Préparer une tournée',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Chaque grille contient des obstacles internes et est construite depuis une solution valide.',
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'TAILLE DU NIVEAU',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<RepasBoardSize>(
                                key: const Key('repas-custom-size'),
                                showSelectedIcon: false,
                                segments: [
                                  for (final size in RepasBoardSize.values)
                                    ButtonSegment(
                                      value: size,
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(_sizeName(size)),
                                            Text('${size.side} × ${size.side}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                                selected: {_size},
                                onSelectionChanged: widget.generating
                                    ? null
                                    : (selection) => setState(
                                        () => _size = selection.single,
                                      ),
                              ),
                              const SizedBox(height: 22),
                              Text(
                                'DIFFICULTÉ',
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<RepasDifficulty>(
                                key: const Key('repas-custom-difficulty'),
                                showSelectedIcon: false,
                                segments: [
                                  for (final difficulty
                                      in RepasDifficulty.values)
                                    ButtonSegment(
                                      value: difficulty,
                                      label: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(difficulty.label),
                                      ),
                                    ),
                                ],
                                selected: {_difficulty},
                                onSelectionChanged: widget.generating
                                    ? null
                                    : (selection) => setState(
                                        () => _difficulty = selection.single,
                                      ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton.icon(
                                key: const Key('repas-custom-start'),
                                onPressed: widget.generating
                                    ? null
                                    : () => widget.onStart(
                                        RepasFreeGameConfig(
                                          size: _size,
                                          difficulty: _difficulty,
                                        ),
                                      ),
                                icon: widget.generating
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Icon(Icons.auto_awesome_rounded),
                                label: Text(
                                  widget.generating
                                      ? 'PRÉPARATION…'
                                      : 'GÉNÉRER LE NIVEAU',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

String _sizeName(RepasBoardSize size) => switch (size) {
  RepasBoardSize.small => 'Petite',
  RepasBoardSize.medium => 'Moyenne',
  RepasBoardSize.large => 'Grande',
};
