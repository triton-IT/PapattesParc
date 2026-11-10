import '../../../shared/wooden_sign.dart';
import '../../../shared/board_camera.dart';
import '../../../shared/artwork.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/animal_scene.dart';
import '../../../shared/animal_colors.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../../../shared/game_stage_layout.dart';
import '../domain/sudoku_session.dart';

class SudokuScreen extends StatelessWidget {
  const SudokuScreen({
    this.elapsed,
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
    this.onUndo,
    this.onRestart,
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
  final VoidCallback? onUndo, onRestart;
  final VoidCallback onBack;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback? onNext;
  final VoidCallback? onNewGame;
  final VoidCallback? onConfigure;

  final ValueListenable<Duration>? elapsed;

  @override
  Widget build(BuildContext context) => TooltipTheme(
    data: TooltipThemeData(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xffffe9be), Color(0xffe6c58f)],
        ),
        border: Border.all(color: const Color(0xff895b32), width: 2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x663b2412),
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Color(0xff563619),
        fontFamily: 'Nunito',
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.all(8),
      verticalOffset: 12,
      preferBelow: true,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final sceneScale = min(
          constraints.maxWidth / 1672,
          constraints.maxHeight / 941,
        );
        if ((isFreeGame || session.level.number != 19) &&
            sceneScale >= .8 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
          return _integratedScene(context);
        }
        return _responsiveScene(context);
      },
    ),
  );

  Widget _responsiveScene(BuildContext context) => GameStageLayout(
    background: session.level.number == 1 && !isFreeGame
        ? const Image(
            image: AssetImage('assets/optimized/sudoku/savanna.webp'),
            fit: BoxFit.cover,
          )
        : ArtworkImage(session.level.stage.artAsset!, fit: BoxFit.cover),
    wooden: true,
    scrim: Colors.transparent,
    eyebrow: 'SUDOKU DES ANIMAUX',
    title:
        '${isFreeGame ? 'Partie libre' : 'Niveau ${session.level.number}'} · '
        '${session.level.size} × ${session.level.size}',
    backKey: const Key('sudoku-back'),
    onBack: onBack,
    helpKind: GameHelpKind.sudoku,
    fixedActions: [
      GameStageAction(
        key: const Key('sudoku-undo'),
        icon: Icons.undo_rounded,
        tooltip: 'Annuler',
        onPressed: session.canUndo ? onUndo : null,
      ),
      GameStageAction(
        key: const Key('sudoku-restart'),
        icon: Icons.refresh_rounded,
        tooltip: 'Recommencer',
        onPressed: onRestart,
      ),
    ],
    metrics: [
      GameStageMetric(
        icon: Icons.timer_rounded,
        elapsed: elapsed,
        label: formatDuration(session.elapsed),
      ),
      GameStageMetric(
        icon: Icons.pets_rounded,
        label: '${session.footprints} empreinte(s)',
      ),
    ],
    builder: (context, layout) => GameStageSplit(
      wide: layout.isLandscape,
      maxPanelWidth: 560,
      board: BoardCamera(
        wooden: true,
        child: SudokuBoard(
          session: session,
          selectedIndex: selectedIndex,
          wrongIndex: wrongIndex,
          onSelect: onSelectCell,
        ),
      ),
      panel: _GamePanel(
        session: session,
        noteMode: noteMode,
        selectedIndex: selectedIndex,
        onSelectAnimal: onSelectAnimal,
        onToggleNotes: onToggleNotes,
        onClear: onClear,
        onHint: onHint,
      ),
    ),
    overlays: [
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
  );

  Widget _integratedScene(BuildContext context) {
    final sceneAsset = animalSceneAsset(
      session.level.number,
      isFreeGame: isFreeGame,
    );
    final themedLevel =
        !isFreeGame && session.level.number >= 2 && session.level.number <= 30;
    final title =
        '${isFreeGame ? 'Partie libre' : 'Niveau ${session.level.number}'} · ${session.level.size} × ${session.level.size}';
    return Scaffold(
      backgroundColor: const Color(0xff986a3e),
      body: Stack(
        children: [
          Positioned.fill(
            child: themedLevel
                ? ArtworkImage(session.level.stage.artAsset!, fit: BoxFit.cover)
                : const Image(
                    image: AssetImage('assets/optimized/sudoku/savanna.webp'),
                    fit: BoxFit.cover,
                  ),
          ),
          SafeArea(
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 1672,
                  height: 941,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image(
                          key: const Key('sudoku-scene-background'),
                          image: AssetImage(sceneAsset),
                          fit: BoxFit.fill,
                        ),
                      ),
                      Positioned.fill(
                        child: BoardCamera(
                          wooden: true,
                          layoutBuilder: (context, viewport, controls) => Stack(
                            children: [
                              Positioned(
                                left: 193,
                                top: 225,
                                width: 555,
                                height: 531,
                                child: viewport,
                              ),
                              Positioned(
                                left: 1038,
                                top: 295,
                                width: 92,
                                height: 404,
                                child: controls,
                              ),
                            ],
                          ),
                          child: _SceneGrid(
                            session: session,
                            selectedIndex: selectedIndex,
                            wrongIndex: wrongIndex,
                            onSelect: onSelectCell,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 60,
                        top: 42,
                        width: 110,
                        height: 110,
                        child: IconButton(
                          key: const Key('sudoku-back'),
                          tooltip: 'Retour',
                          onPressed: onBack,
                          color: const Color(0xffffedcb),
                          iconSize: 65,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                      ),
                      Positioned(
                        left: 205,
                        top: 50,
                        width: 460,
                        height: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'SUDOKU DES ANIMAUX',
                              maxLines: 1,
                              style: TextStyle(
                                color: Color(0xffffcc69),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Color(0xff4d2813),
                                    blurRadius: 4,
                                    offset: Offset(1, 2),
                                  ),
                                ],
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                title,
                                style: const TextStyle(
                                  color: Color(0xffffefd5),
                                  fontSize: 40,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      color: Color(0xff4d2813),
                                      blurRadius: 4,
                                      offset: Offset(1, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: 708,
                        top: 76,
                        width: 190,
                        height: 60,
                        child: _SceneMetric(
                          icon: Icons.timer_rounded,
                          label: formatDuration(session.elapsed),
                          elapsed: elapsed,
                        ),
                      ),
                      Positioned(
                        left: 973,
                        top: 76,
                        width: 320,
                        height: 60,
                        child: _SceneMetric(
                          icon: Icons.pets_rounded,
                          label: '${session.footprints} empreinte(s)',
                        ),
                      ),
                      Positioned(
                        left: 1351,
                        top: 70,
                        width: 75,
                        height: 75,
                        child: GameHelpButton(
                          kind: GameHelpKind.sudoku,
                          color: const Color(0xffffecd0),
                          iconSize: 52,
                        ),
                      ),
                      Positioned(
                        left: 1190,
                        top: 329,
                        width: 430,
                        height: 350,
                        child: _ScenePanel(
                          session: session,
                          selectedIndex: selectedIndex,
                          noteMode: noteMode,
                          onSelectAnimal: onSelectAnimal,
                          onToggleNotes: onToggleNotes,
                          onClear: onClear,
                          onHint: onHint,
                          onUndo: onUndo,
                          onRestart: onRestart,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (finished)
            Positioned.fill(
              child: SafeArea(
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
            ),
        ],
      ),
    );
  }
}

class _SceneMetric extends StatelessWidget {
  const _SceneMetric({required this.icon, required this.label, this.elapsed});
  final IconData icon;
  final String label;
  final ValueListenable<Duration>? elapsed;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: const Color(0xffffecd0), size: 39),
      const SizedBox(width: 10),
      Flexible(
        child: elapsed == null
            ? _text(label)
            : ValueListenableBuilder<Duration>(
                valueListenable: elapsed!,
                builder: (context, value, _) => _text(formatDuration(value)),
              ),
      ),
    ],
  );
  Widget _text(String value) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      value,
      maxLines: 1,
      style: const TextStyle(
        color: Color(0xffffecd0),
        fontWeight: FontWeight.w900,
        fontSize: 29,
        shadows: [
          Shadow(color: Color(0xff523017), blurRadius: 4, offset: Offset(1, 2)),
        ],
      ),
    ),
  );
}

class _SceneGrid extends StatelessWidget {
  const _SceneGrid({
    required this.session,
    required this.selectedIndex,
    required this.wrongIndex,
    required this.onSelect,
  });
  final SudokuSession session;
  final int? selectedIndex, wrongIndex;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(9, 0, 9, 18),
    child: Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.identity()..setEntry(3, 1, -.00006),
      child: LayoutBuilder(
        builder: (context, constraints) => CustomPaint(
          foregroundPainter: session.level.size > 4
              ? _BoxSeparators(
                  session.level.size,
                  session.level.boxWidth,
                  session.level.boxHeight,
                )
              : null,
          child: GridView.builder(
            key: const Key('sudoku-board'),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: session.level.size,
              childAspectRatio: constraints.maxWidth / constraints.maxHeight,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
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
    ),
  );
}

class _ScenePanel extends StatelessWidget {
  const _ScenePanel({
    required this.session,
    required this.selectedIndex,
    required this.noteMode,
    required this.onSelectAnimal,
    required this.onToggleNotes,
    required this.onClear,
    required this.onHint,
    this.onUndo,
    this.onRestart,
  });
  final SudokuSession session;
  final int? selectedIndex;
  final bool noteMode;
  final ValueChanged<int> onSelectAnimal;
  final VoidCallback onToggleNotes, onClear, onHint;
  final VoidCallback? onUndo, onRestart;
  @override
  Widget build(BuildContext context) {
    final columns = session.level.animals.length <= 4 ? 4 : 5;
    final tileSize = min(
      (430 - (columns - 1) * 6) / columns,
      session.level.size > 4 ? 64.0 : 82.0,
    );
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Center(
                  child: _SudokuActionButton(
                    buttonKey: const Key('sudoku-undo'),
                    tooltip: 'Annuler',
                    onPressed: session.canUndo ? onUndo : null,
                    icon: Icons.undo_rounded,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _SudokuActionButton(
                    buttonKey: const Key('sudoku-restart'),
                    tooltip: 'Recommencer',
                    onPressed: onRestart,
                    icon: Icons.refresh_rounded,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < session.level.animals.length; i++)
                _AnimalButton(
                  animal: session.level.animals[i],
                  index: i,
                  size: tileSize,
                  enabled: selectedIndex != null,
                  onTap: () => onSelectAnimal(i),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _NotePaper(
            compact: session.level.size > 4,
            enabled:
                selectedIndex != null &&
                session.entries[selectedIndex!] == null,
            active: noteMode,
            onClearEnabled: selectedIndex != null,
            onToggle: onToggleNotes,
            onClear: onClear,
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: session.level.size > 4 ? 59 : 75,
            child: WoodenSign(
              child: TextButton.icon(
                key: const Key('sudoku-hint'),
                onPressed: session.hintsRemaining == 0 ? null : onHint,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffffedc2),
                  disabledForegroundColor: const Color(0xffe1c9a0),
                ),
                icon: const Icon(Icons.lightbulb_rounded, size: 35),
                label: Text(
                  'INDICE ${session.hintsRemaining}/3',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0xff30501f),
                        blurRadius: 3,
                        offset: Offset(1, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
      final landscape =
          MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
      final spacious = landscape && MediaQuery.sizeOf(context).height >= 500;
      final side =
          (min(constraints.maxWidth, constraints.maxHeight) - 24) *
          (spacious ? .84 : 1.0);
      return Align(
        alignment: spacious ? const Alignment(-.7, 0) : Alignment.center,
        child: SizedBox.square(
          dimension: max(0, side),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Padding(
                padding: EdgeInsets.all(max(5, side * .155)),
                child: Container(
                  padding: EdgeInsets.all(max(2, side * .008)),
                  decoration: BoxDecoration(
                    color: const Color(0xffc99b65),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CustomPaint(
                    foregroundPainter: session.level.size > 4
                        ? _BoxSeparators(
                            session.level.size,
                            session.level.boxWidth,
                            session.level.boxHeight,
                          )
                        : null,
                    child: GridView.builder(
                      key: const Key('sudoku-board'),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: session.level.size,
                        mainAxisSpacing: max(1, side * .004),
                        crossAxisSpacing: max(1, side * .004),
                      ),
                      itemCount: session.entries.length,
                      itemBuilder: (context, index) => _SudokuCell(
                        session: session,
                        index: index,
                        selected: selectedIndex == index,
                        wrong: wrongIndex == index,
                        onTap: session.isGiven(index)
                            ? null
                            : () => onSelect(index),
                      ),
                    ),
                  ),
                ),
              ),
              const IgnorePointer(
                child: Image(
                  image: AssetImage('assets/optimized/sudoku/wood-frame.webp'),
                  fit: BoxFit.fill,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _BoxSeparators extends CustomPainter {
  const _BoxSeparators(this.size, this.boxWidth, this.boxHeight);
  final int size, boxWidth, boxHeight;
  @override
  void paint(Canvas canvas, Size area) {
    final paint = Paint()
      ..color = const Color(0xff93653c)
      ..strokeWidth = 2.5;
    for (var column = boxWidth; column < size; column += boxWidth) {
      final x = area.width * column / size;
      canvas.drawLine(Offset(x, 0), Offset(x, area.height), paint);
    }
    for (var row = boxHeight; row < size; row += boxHeight) {
      final y = area.height * row / size;
      canvas.drawLine(Offset(0, y), Offset(area.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxSeparators oldDelegate) =>
      size != oldDelegate.size ||
      boxWidth != oldDelegate.boxWidth ||
      boxHeight != oldDelegate.boxHeight;
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
              ? const Color(0xffe7a38b)
              : selected
              ? const Color(0xffffdc85)
              : const Color(0xffecd3a3),
          borderRadius: BorderRadius.circular(level.size == 9 ? 3 : 8),
          image: DecorationImage(
            image: const AssetImage(
              'assets/optimized/sudoku/sandstone-tile.webp',
            ),
            fit: BoxFit.fill,
            colorFilter: wrong
                ? const ColorFilter.mode(Color(0x88d94d35), BlendMode.srcATop)
                : selected
                ? const ColorFilter.mode(Color(0x66ffc83d), BlendMode.srcATop)
                : null,
          ),
          border: Border.all(color: const Color(0xffb38c5e), width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x553d2815),
              blurRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: value == null
                ? _Notes(animals: level.animals, values: session.notes[index])
                : LayoutBuilder(
                    builder: (context, constraints) => Padding(
                      padding: EdgeInsets.all(
                        min(constraints.maxWidth, constraints.maxHeight) * .08,
                      ),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x663d2815),
                              blurRadius: 3,
                              offset: Offset(1, 3),
                            ),
                          ],
                        ),
                        child: ArtworkImage(animal!.asset, fit: BoxFit.contain),
                      ),
                    ),
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
            ? ArtworkImage(animals[index].asset, fit: BoxFit.contain)
            : const SizedBox.shrink(),
    ],
  );
}

class _GamePanel extends StatelessWidget {
  const _GamePanel({
    required this.session,
    required this.noteMode,
    required this.selectedIndex,
    required this.onSelectAnimal,
    required this.onToggleNotes,
    required this.onClear,
    required this.onHint,
  });

  final SudokuSession session;
  final bool noteMode;
  final int? selectedIndex;
  final ValueChanged<int> onSelectAnimal;
  final VoidCallback onToggleNotes;
  final VoidCallback onClear;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(38, 38, 38, 38),
    decoration: parchmentDecoration,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = session.level.animals.length <= 4 ? 4 : 3;
            final size = ((constraints.maxWidth - (columns - 1) * 5) / columns)
                .clamp(36.0, 86.0);
            return Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 5,
              children: [
                for (
                  var index = 0;
                  index < session.level.animals.length;
                  index++
                )
                  _AnimalButton(
                    animal: session.level.animals[index],
                    index: index,
                    size: size,
                    enabled: selectedIndex != null,
                    onTap: () => onSelectAnimal(index),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 8),
        _NotePaper(
          enabled:
              selectedIndex != null && session.entries[selectedIndex!] == null,
          active: noteMode,
          onClearEnabled: selectedIndex != null,
          onToggle: onToggleNotes,
          onClear: onClear,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('sudoku-hint'),
          onPressed: session.hintsRemaining == 0 ? null : onHint,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff397b32),
            foregroundColor: const Color(0xfffff0c9),
            minimumSize: const Size(40, 46),
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
          icon: const Icon(Icons.lightbulb_rounded),
          label: Text(
            'INDICE ${session.hintsRemaining}/3',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: (MediaQuery.sizeOf(context).width / 70).clamp(
                14.0,
                24.0,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _NotePaper extends StatelessWidget {
  const _NotePaper({
    this.compact = false,
    required this.enabled,
    required this.active,
    required this.onClearEnabled,
    required this.onToggle,
    required this.onClear,
  });
  final bool enabled, active, compact, onClearEnabled;
  final VoidCallback onToggle, onClear;

  @override
  Widget build(BuildContext context) {
    final scale = compact
        ? 1.0
        : (MediaQuery.sizeOf(context).width / 900).clamp(1.0, 1.7);
    return Row(
      children: [
        Expanded(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: ExactAssetImage(
                  'assets/optimized/sudoku/notes-plank.webp',
                  scale: 4,
                ),
                fit: BoxFit.fill,
              ),
            ),
            child: Semantics(
              toggled: active,
              child: TextButton(
                key: const Key('sudoku-notes'),
                onPressed: enabled ? onToggle : null,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffffedc2),
                  disabledForegroundColor: const Color(0xffe1c9a0),
                  minimumSize: Size(40, 72 * scale),
                  padding: EdgeInsets.symmetric(
                    horizontal: 30 * scale,
                    vertical: 10 * scale,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    active
                        ? 'MES PETITS MÉMOS : OUI'
                        : 'MES PETITS MÉMOS : NON',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: active ? const Color(0xffc9ee9c) : null,
                      fontWeight: FontWeight.w900,
                      fontSize: 15 * scale,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SudokuActionButton(
          buttonKey: const Key('sudoku-clear'),
          tooltip: 'Gomme',
          onPressed: onClearEnabled ? onClear : null,
          icon: Icons.backspace_outlined,
        ),
      ],
    );
  }
}

class _SudokuActionButton extends StatelessWidget {
  const _SudokuActionButton({
    required this.buttonKey,
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final Key buttonKey;
  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 54,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/optimized/sudoku/camera-stone.webp'),
          fit: BoxFit.fill,
        ),
      ),
      child: IconButton(
        key: buttonKey,
        tooltip: tooltip,
        onPressed: onPressed,
        color: const Color(0xff245b4a),
        disabledColor: const Color(0xff245b4a).withValues(alpha: .4),
        icon: Icon(icon, size: 28),
      ),
    ),
  );
}

class _AnimalButton extends StatelessWidget {
  const _AnimalButton({
    required this.animal,
    required this.index,
    required this.size,
    required this.enabled,
    required this.onTap,
  });

  final AnimalKind animal;
  final int index;
  final double size;
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
          width: size,
          height: size,
          padding: EdgeInsets.all(size * .09),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  animalHaloColor(animal),
                  const Color(0xffffdeb0),
                  .25,
                )!,
                Color.lerp(
                  animalHaloColor(animal),
                  const Color(0xff513b27),
                  .28,
                )!,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xff65452e), width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x77542f1b),
                blurRadius: 4,
                offset: Offset(1, 3),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x66542f1b),
                  blurRadius: 3,
                  offset: Offset(1, 3),
                ),
              ],
            ),
            child: ArtworkImage(animal.asset, fit: BoxFit.contain),
          ),
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
    child: GameResultViewport(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GameResultPanel(
          biome: session.level.stage.biome,
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
                TextButton.icon(
                  key: const Key('sudoku-replay'),
                  onPressed: onReplay,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('REJOUER'),
                ),
                if (onNewGame != null)
                  TextButton.icon(
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
