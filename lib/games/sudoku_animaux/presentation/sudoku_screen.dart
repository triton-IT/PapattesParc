import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/animal_background.dart';
import '../../../shared/animal_catalog.dart';
import '../../../shared/animal_colors.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../domain/sudoku_session.dart';

class SudokuScreen extends StatelessWidget {
  const SudokuScreen({
    required this.session,
    required this.selectedIndex,
    required this.noteMode,
    required this.wrongIndex,
    required this.finished,
    required this.newRecord,
    this.isFreeGame = false,
    required this.onSelectCell,
    required this.onSelectAnimal,
    required this.onToggleNotes,
    required this.onClear,
    required this.onHint,
    required this.onBack,
    required this.onReplay,
    required this.onLevels,
    required this.onNext,
    this.onNewGame,
    this.onConfigure,
    super.key,
  });

  final SudokuSession session;
  final int? selectedIndex;
  final bool noteMode;
  final int? wrongIndex;
  final bool finished;
  final bool newRecord;
  final bool isFreeGame;
  final ValueChanged<int> onSelectCell;
  final ValueChanged<int> onSelectAnimal;
  final VoidCallback onToggleNotes;
  final VoidCallback onClear;
  final VoidCallback onHint;
  final VoidCallback onBack;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback? onNext;
  final VoidCallback? onNewGame;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: AnimalBackground(
      asset: session.level.stage.artAsset!,
      child: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 900 &&
                    constraints.maxWidth > constraints.maxHeight;
                final board = SudokuBoard(
                  session: session,
                  selectedIndex: selectedIndex,
                  wrongIndex: wrongIndex,
                  onSelect: onSelectCell,
                );
                final panel = _GamePanel(
                  session: session,
                  noteMode: noteMode,
                  selectedIndex: selectedIndex,
                  wide: wide,
                  isFreeGame: isFreeGame,
                  onSelectAnimal: onSelectAnimal,
                  onToggleNotes: onToggleNotes,
                  onClear: onClear,
                  onHint: onHint,
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: board),
                      SizedBox(width: 360, child: panel),
                    ],
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(64, 10, 64, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${isFreeGame ? 'Partie libre' : 'Niveau ${session.level.number}'} · '
                              '${session.level.size} × ${session.level.size}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            formatDuration(session.elapsed),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: board),
                    panel,
                  ],
                );
              },
            ),
            Positioned(
              left: 12,
              top: 12,
              child: IconButton.filledTonal(
                key: const Key('sudoku-back'),
                tooltip: 'Retour',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const Positioned(
              right: 12,
              top: 12,
              child: GameHelpButton(kind: GameHelpKind.sudoku),
            ),
            if (finished)
              Positioned.fill(
                child: _ResultOverlay(
                  session: session,
                  newRecord: newRecord,
                  isFreeGame: isFreeGame,
                  onReplay: onReplay,
                  onLevels: onLevels,
                  onNext: onNext,
                  onNewGame: onNewGame,
                  onConfigure: onConfigure,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class SudokuBoard extends StatelessWidget {
  const SudokuBoard({
    required this.session,
    required this.selectedIndex,
    required this.wrongIndex,
    required this.onSelect,
    super.key,
  });

  final SudokuSession session;
  final int? selectedIndex;
  final int? wrongIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = min(constraints.maxWidth, constraints.maxHeight) - 24;
      return Center(
        child: SizedBox.square(
          dimension: max(0, side),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: const [
                BoxShadow(color: Color(0x66245b4a), blurRadius: 16),
              ],
            ),
            child: GridView.builder(
              key: const Key('sudoku-board'),
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: session.level.size,
              ),
              itemCount: session.entries.length,
              itemBuilder: (context, index) => _SudokuCell(
                session: session,
                index: index,
                selected: selectedIndex == index,
                wrong: wrongIndex == index,
                onTap: session.isGiven(index) ? null : () => onSelect(index),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SudokuCell extends StatelessWidget {
  const _SudokuCell({
    required this.session,
    required this.index,
    required this.selected,
    required this.wrong,
    required this.onTap,
  });

  final SudokuSession session;
  final int index;
  final bool selected;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final level = session.level;
    final row = index ~/ level.size;
    final column = index % level.size;
    final value = session.entries[index];
    final given = session.isGiven(index);
    final animal = value == null ? null : level.animals[value];
    return Semantics(
      button: !given,
      enabled: !given,
      selected: selected,
      label: animal == null
          ? 'Ligne ${row + 1}, colonne ${column + 1}, vide'
          : 'Ligne ${row + 1}, colonne ${column + 1}, ${animal.label}',
      child: AnimatedContainer(
        key: Key('sudoku-cell-$index'),
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: wrong
              ? AppColors.danger.withValues(alpha: .34)
              : selected
              ? AppColors.sun.withValues(alpha: .5)
              : given
              ? const Color(0xffffe9b5)
              : Colors.white.withValues(alpha: .94),
          border: Border(
            left: BorderSide(
              color: AppColors.deep,
              width: column % level.boxWidth == 0 ? 3 : 1,
            ),
            top: BorderSide(
              color: AppColors.deep,
              width: row % level.boxHeight == 0 ? 3 : 1,
            ),
            right: column == level.size - 1
                ? const BorderSide(color: AppColors.deep, width: 3)
                : BorderSide.none,
            bottom: row == level.size - 1
                ? const BorderSide(color: AppColors.deep, width: 3)
                : BorderSide.none,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: value == null
                ? _Notes(animals: level.animals, values: session.notes[index])
                : Padding(
                    padding: EdgeInsets.all(level.size == 9 ? 2 : 5),
                    child: Image.asset(animal!.asset, fit: BoxFit.contain),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes({required this.animals, required this.values});

  final List<AnimalKind> animals;
  final Set<int> values;

  @override
  Widget build(BuildContext context) => GridView.count(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(1),
    crossAxisCount: animals.length <= 4 ? 2 : 3,
    children: [
      for (var index = 0; index < animals.length; index++)
        values.contains(index)
            ? Image.asset(animals[index].asset, fit: BoxFit.contain)
            : const SizedBox.shrink(),
    ],
  );
}

class _GamePanel extends StatelessWidget {
  const _GamePanel({
    required this.session,
    required this.noteMode,
    required this.selectedIndex,
    required this.wide,
    required this.isFreeGame,
    required this.onSelectAnimal,
    required this.onToggleNotes,
    required this.onClear,
    required this.onHint,
  });

  final SudokuSession session;
  final bool noteMode;
  final int? selectedIndex;
  final bool wide;
  final bool isFreeGame;
  final ValueChanged<int> onSelectAnimal;
  final VoidCallback onToggleNotes;
  final VoidCallback onClear;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (wide) ...[
            const Text(
              'SUDOKU DES ANIMAUX',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${isFreeGame ? 'Partie libre' : 'Niveau ${session.level.number}'} · '
              '${session.level.size} × ${session.level.size}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 5,
            runSpacing: 5,
            children: [
              for (var index = 0; index < session.level.animals.length; index++)
                _AnimalButton(
                  animal: session.level.animals[index],
                  index: index,
                  enabled: selectedIndex != null,
                  onTap: () => onSelectAnimal(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('sudoku-notes'),
                  onPressed: selectedIndex == null ? null : onToggleNotes,
                  style: FilledButton.styleFrom(
                    backgroundColor: noteMode
                        ? AppColors.sun.withValues(alpha: .65)
                        : null,
                    minimumSize: const Size(40, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('NOTES'),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('sudoku-clear'),
                  onPressed: selectedIndex == null ? null : onClear,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(40, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  icon: const Icon(Icons.backspace_rounded),
                  label: const Text('GOMME'),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('sudoku-hint'),
                  onPressed: session.hintsRemaining == 0 ? null : onHint,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(40, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: Text('INDICE ${session.hintsRemaining}/3'),
                ),
              ),
            ],
          ),
          if (wide) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formatDuration(session.elapsed),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${session.footprints} empreinte(s)',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ],
        ],
      ),
    ),
  );
}

class _AnimalButton extends StatelessWidget {
  const _AnimalButton({
    required this.animal,
    required this.index,
    required this.enabled,
    required this.onTap,
  });

  final AnimalKind animal;
  final int index;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: animal.label,
    child: Semantics(
      button: true,
      enabled: enabled,
      label: animal.label,
      child: InkWell(
        key: Key('sudoku-animal-$index'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: animalHaloColor(animal).withValues(alpha: enabled ? 1 : .35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.deep, width: 1.5),
          ),
          child: Image.asset(animal.asset, fit: BoxFit.contain),
        ),
      ),
    ),
  );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.newRecord,
    required this.isFreeGame,
    required this.onReplay,
    required this.onLevels,
    required this.onNext,
    required this.onNewGame,
    required this.onConfigure,
  });

  final SudokuSession session;
  final bool newRecord;
  final bool isFreeGame;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback? onNext;
  final VoidCallback? onNewGame;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) => ColoredBox(
    key: const Key('sudoku-result-overlay'),
    color: const Color(0xaa173a31),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          margin: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.pets_rounded, size: 54, color: AppColors.sun),
                Text(
                  'PARADE PRÊTE !',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${formatDuration(session.elapsed)} · '
                  '${isFreeGame ? '${session.hintsUsed} indice(s)' : '${session.footprints} empreinte(s)'}'
                  '${newRecord ? '\nNouveau record !' : ''}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                if (onNext != null)
                  FilledButton.icon(
                    key: const Key('sudoku-next'),
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('NIVEAU SUIVANT'),
                  ),
                FilledButton.tonalIcon(
                  key: const Key('sudoku-replay'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('REJOUER'),
                ),
                if (onNewGame != null)
                  FilledButton.tonalIcon(
                    key: const Key('sudoku-new-free-game'),
                    onPressed: onNewGame,
                    icon: const Icon(Icons.casino_rounded),
                    label: const Text('NOUVELLE GRILLE'),
                  ),
                if (onConfigure != null)
                  TextButton.icon(
                    key: const Key('sudoku-configure'),
                    onPressed: onConfigure,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('MODIFIER LES RÉGLAGES'),
                  ),
                TextButton.icon(
                  key: const Key('sudoku-levels'),
                  onPressed: onLevels,
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('RETOUR AUX NIVEAUX'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
