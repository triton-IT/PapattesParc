import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../data/solitaire_progress_store.dart';
import '../domain/models.dart';
import 'card_view.dart';

class SolitaireSetupScreen extends StatelessWidget {
  const SolitaireSetupScreen({
    required this.progress,
    required this.mode,
    required this.animal,
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onModeChanged,
    required this.onAnimalChanged,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onStart,
    required this.onExit,
    super.key,
  });

  final SolitaireProgressStore progress;
  final SolitaireMode mode;
  final AnimalKind animal;
  final bool musicEnabled;
  final bool effectsEnabled;
  final ValueChanged<SolitaireMode> onModeChanged;
  final ValueChanged<AnimalKind> onAnimalChanged;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback onStart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: SafeArea(
      child: Column(
        children: [
          _Header(
            musicEnabled: musicEnabled,
            effectsEnabled: effectsEnabled,
            onToggleMusic: onToggleMusic,
            onToggleEffects: onToggleEffects,
            onExit: onExit,
          ),
          Expanded(
            child: CustomScrollView(
              key: const Key('solitaire-setup'),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 940),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                        child: _Configuration(
                          progress: progress,
                          mode: mode,
                          animal: animal,
                          onModeChanged: onModeChanged,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 940),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Text(
                          'Choisis l’animal du verso',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent.clamp(0, 940);
                      final margin = (constraints.crossAxisExtent - width) / 2;
                      return SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: margin),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final value = AnimalKind.values[index];
                            return _AnimalChoice(
                              animal: value,
                              selected: value == animal,
                              onTap: () => onAnimalChanged(value),
                            );
                          }, childCount: AnimalKind.values.length),
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 135,
                                mainAxisExtent: 116,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: FilledButton.icon(
                key: const Key('solitaire-start'),
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('COMMENCER'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.musicEnabled,
    required this.effectsEnabled,
    required this.onToggleMusic,
    required this.onToggleEffects,
    required this.onExit,
  });

  final bool musicEnabled;
  final bool effectsEnabled;
  final VoidCallback onToggleMusic;
  final VoidCallback onToggleEffects;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
    child: Row(
      children: [
        IconButton(
          key: const Key('solitaire-exit'),
          tooltip: 'Choisir un jeu',
          onPressed: onExit,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Solitaire des animaux',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        IconButton(
          tooltip: musicEnabled ? 'Couper la musique' : 'Activer la musique',
          onPressed: onToggleMusic,
          icon: Icon(
            musicEnabled ? Icons.music_note_rounded : Icons.music_off_rounded,
          ),
        ),
        IconButton(
          tooltip: effectsEnabled
              ? 'Couper les effets sonores'
              : 'Activer les effets sonores',
          onPressed: onToggleEffects,
          icon: Icon(
            effectsEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          ),
        ),
        const GameHelpButton(kind: GameHelpKind.solitaire),
      ],
    ),
  );
}

class _Configuration extends StatelessWidget {
  const _Configuration({
    required this.progress,
    required this.mode,
    required this.animal,
    required this.onModeChanged,
  });

  final SolitaireProgressStore progress;
  final SolitaireMode mode;
  final AnimalKind animal;
  final ValueChanged<SolitaireMode> onModeChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final preview = SizedBox(
            width: 86,
            height: 121,
            child: CardBack(animal: animal),
          );
          final choices = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'MODE DE PIOCHE',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<SolitaireMode>(
                key: const Key('solitaire-mode'),
                segments: [
                  for (final value in SolitaireMode.values)
                    ButtonSegment(value: value, label: Text(value.label)),
                ],
                selected: {mode},
                onSelectionChanged: (values) => onModeChanged(values.single),
              ),
              const SizedBox(height: 12),
              for (final value in SolitaireMode.values)
                Text(
                  '${value == SolitaireMode.drawOne ? '1 carte' : '3 cartes'} · '
                  '${progress.wins(value)} victoire(s) · '
                  '${progress.bestTime(value) == null ? 'aucun record' : 'record ${formatDuration(progress.bestTime(value)!)}'}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          );
          if (constraints.maxWidth < 560) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                preview,
                const SizedBox(width: 14),
                Expanded(child: choices),
              ],
            );
          }
          return Row(
            children: [
              preview,
              const SizedBox(width: 22),
              Expanded(child: choices),
            ],
          );
        },
      ),
    ),
  );
}

class _AnimalChoice extends StatelessWidget {
  const _AnimalChoice({
    required this.animal,
    required this.selected,
    required this.onTap,
  });

  final AnimalKind animal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${animal.label}, verso de carte',
    child: Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.primary : Colors.transparent,
          width: 4,
        ),
      ),
      child: InkWell(
        key: Key('solitaire-animal-${animal.name}'),
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 24),
                child: Image.asset(animal.asset, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              left: 4,
              right: 4,
              bottom: 5,
              child: Text(
                animal.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (selected)
              const Positioned(
                right: 5,
                top: 5,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.check_rounded, size: 16),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
