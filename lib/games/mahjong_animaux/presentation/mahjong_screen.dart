import '../../../shared/clay_hud_icon.dart';
import '../../../shared/clay_text.dart';
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
import '../domain/mahjong_session.dart';
import '../domain/models.dart';

class MahjongScreen extends StatelessWidget {
  const MahjongScreen({
    this.elapsed,
    required this.session,
    required this.title,
    required this.backgroundAsset,
    this.levelNumber = 1,
    required this.isFreeGame,
    required this.hintedIds,
    required this.finished,
    required this.newRecord,
    required this.onSelect,
    required this.onBlocked,
    required this.onHint,
    required this.onShuffle,
    required this.onBack,
    required this.onReplaySame,
    required this.onReplayNew,
    required this.onLevels,
    required this.onConfigure,
    required this.onNext,
    super.key,
  });

  final MahjongSession session;
  final String title;
  final String backgroundAsset;
  final int levelNumber;
  final bool isFreeGame;
  final Set<int> hintedIds;
  final bool finished;
  final bool newRecord;
  final ValueChanged<int> onSelect;
  final VoidCallback onBlocked;
  final VoidCallback onHint;
  final VoidCallback onShuffle;
  final VoidCallback onBack;
  final VoidCallback onReplaySame;
  final VoidCallback onReplayNew;
  final VoidCallback onLevels;
  final VoidCallback? onConfigure;
  final VoidCallback? onNext;

  final ValueListenable<Duration>? elapsed;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = min(
        constraints.maxWidth / 1672,
        constraints.maxHeight / 941,
      );
      if ((isFreeGame || levelNumber != 19) &&
          scale >= .8 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
        return _integratedScene();
      }
      return _responsiveScene();
    },
  );

  Widget _responsiveScene() => GameStageLayout(
    background: ArtworkImage(backgroundAsset, fit: BoxFit.cover),
    wooden: true,
    scrim: Colors.transparent,
    eyebrow: isFreeGame ? 'PARTIE LIBRE' : 'MISSION',
    title: title,
    backKey: const Key('mahjong-back'),
    onBack: onBack,
    helpKind: GameHelpKind.mahjong,
    metrics: [
      GameStageMetric(
        icon: Icons.timer_rounded,
        elapsed: elapsed,
        label: formatDuration(session.elapsed),
      ),
      GameStageMetric(
        icon: Icons.layers_rounded,
        label: '${session.remainingPairs} paires',
      ),
      GameStageMetric(
        icon: Icons.shuffle_rounded,
        label: '${session.shufflesRemaining}/3',
      ),
    ],
    builder: (context, layout) => GameStageSplit(
      wide: layout.isLandscape,
      board: MahjongBoard(
        session: session,
        hintedIds: hintedIds,
        onSelect: onSelect,
        onBlocked: onBlocked,
      ),
      panel: _GamePanel(session: session, onHint: onHint, onShuffle: onShuffle),
    ),
    overlays: [
      if (finished)
        Positioned.fill(
          child: _ResultOverlay(
            session: session,
            isFreeGame: isFreeGame,
            newRecord: newRecord,
            onReplaySame: onReplaySame,
            onReplayNew: onReplayNew,
            onLevels: onLevels,
            onConfigure: onConfigure,
            onNext: onNext,
          ),
        ),
    ],
  );

  Widget _integratedScene() => Scaffold(
    backgroundColor: const Color(0xff986a3e),
    body: Stack(
      children: [
        Positioned.fill(
          child: ArtworkImage(backgroundAsset, fit: BoxFit.cover),
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
                        key: const Key('mahjong-scene-background'),
                        image: AssetImage(
                          animalSceneAsset(levelNumber, isFreeGame: isFreeGame),
                        ),
                        fit: BoxFit.fill,
                      ),
                    ),
                    Positioned.fill(
                      child: MahjongBoard(
                        session: session,
                        hintedIds: hintedIds,
                        onSelect: onSelect,
                        onBlocked: onBlocked,
                        integrated: true,
                      ),
                    ),
                    Positioned(
                      left: 60,
                      top: 42,
                      width: 110,
                      height: 110,
                      child: IconButton(
                        key: const Key('mahjong-back'),
                        tooltip: 'Retour',
                        onPressed: onBack,
                        color: const Color(0xffffedcb),
                        iconSize: 65,
                        icon: const ClayHudIcon(ClayHudIconKind.back, size: 65),
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
                          const ClayText(
                            'MAHJONG DES ANIMAUX',
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
                            child: ClayText(
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
                        icon: Icons.layers_rounded,
                        label: '${session.remainingPairs} paires',
                      ),
                    ),
                    Positioned(
                      left: 1351,
                      top: 70,
                      width: 75,
                      height: 75,
                      child: GameHelpButton(
                        clay: true,
                        kind: GameHelpKind.mahjong,
                        color: const Color(0xffffecd0),
                        iconSize: 52,
                      ),
                    ),
                    Positioned(
                      left: 1190,
                      top: 329,
                      width: 430,
                      height: 350,
                      child: _SceneCommands(
                        session: session,
                        onHint: onHint,
                        onShuffle: onShuffle,
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
                isFreeGame: isFreeGame,
                newRecord: newRecord,
                onReplaySame: onReplaySame,
                onReplayNew: onReplayNew,
                onLevels: onLevels,
                onConfigure: onConfigure,
                onNext: onNext,
              ),
            ),
          ),
      ],
    ),
  );
}

class MahjongBoard extends StatefulWidget {
  const MahjongBoard({
    required this.session,
    required this.hintedIds,
    required this.onSelect,
    required this.onBlocked,
    this.integrated = false,
    super.key,
  });

  final bool integrated;
  final MahjongSession session;
  final Set<int> hintedIds;
  final ValueChanged<int> onSelect;
  final VoidCallback onBlocked;

  @override
  State<MahjongBoard> createState() => _MahjongBoardState();
}

class _MahjongBoardState extends State<MahjongBoard> {
  final TransformationController _controller = TransformationController();
  MahjongSession? _session;
  Size? _viewport;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshots =
        widget.session.tiles.where((snapshot) => snapshot.isPresent).toList()
          ..sort((first, second) {
            final layer = first.tile.position.layer.compareTo(
              second.tile.position.layer,
            );
            return layer != 0 ? layer : first.tile.id.compareTo(second.tile.id);
          });
    final maxX =
        widget.session.layout.positions.fold(
          0,
          (value, position) => position.x > value ? position.x : value,
        ) +
        2;
    final maxY =
        widget.session.layout.positions.fold(
          0,
          (value, position) => position.y > value ? position.y : value,
        ) +
        2;
    final width = maxX * 28.0 + 24;
    final height = maxY * 34.0 + 24;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(
          widget.integrated
              ? 555
              : (constraints.maxWidth - 48).clamp(1, double.infinity),
          widget.integrated ? 531 : constraints.maxHeight,
        );
        final fitScale = min(
          1.0,
          min(viewport.width / width, viewport.height / height),
        );
        final boundaryMargin = EdgeInsets.symmetric(
          horizontal: (viewport.width / fitScale - width) / 2,
          vertical: (viewport.height / fitScale - height) / 2,
        );
        if (_session != widget.session || _viewport != viewport) {
          _session = widget.session;
          _viewport = viewport;
          _controller.value = Matrix4.diagonal3Values(fitScale, fitScale, 1)
            ..setTranslationRaw(
              (viewport.width - width * fitScale) / 2,
              (viewport.height - height * fitScale) / 2,
              0,
            );
        }
        return BoardCamera(
          viewerKey: const Key('mahjong-board'),
          wooden: true,
          layoutBuilder: widget.integrated
              ? (context, viewport, controls) => Stack(
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
                )
              : null,
          transformationController: _controller,
          constrained: false,
          minScale: fitScale,
          maxScale: max(1, min(2.4, fitScale * 5)),
          boundaryMargin: boundaryMargin,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                for (final snapshot in snapshots)
                  Positioned(
                    left:
                        12 +
                        snapshot.tile.position.x * 28.0 +
                        snapshot.tile.position.layer * 4,
                    top:
                        12 +
                        snapshot.tile.position.y * 34.0 -
                        snapshot.tile.position.layer * 4 +
                        0,
                    child: _MahjongTileView(
                      snapshot: snapshot,
                      selected: widget.session.selectedId == snapshot.tile.id,
                      hinted: widget.hintedIds.contains(snapshot.tile.id),
                      onTap: snapshot.isFree
                          ? () => widget.onSelect(snapshot.tile.id)
                          : widget.onBlocked,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MahjongTileView extends StatelessWidget {
  const _MahjongTileView({
    required this.snapshot,
    required this.selected,
    required this.hinted,
    required this.onTap,
  });

  final MahjongTileSnapshot snapshot;
  final bool selected;
  final bool hinted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: snapshot.isFree,
    selected: selected,
    label:
        '${snapshot.tile.animal.label}${snapshot.isFree ? ', libre' : ', bloquée'}',
    child: AnimatedContainer(
      key: Key('mahjong-tile-${snapshot.tile.id}'),
      duration: const Duration(milliseconds: 140),
      width: 56,
      height: 68,
      decoration: BoxDecoration(
        color: animalHaloColor(snapshot.tile.animal),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: selected
              ? AppColors.sun
              : hinted
              ? AppColors.success
              : AppColors.deep,
          width: selected || hinted ? 4 : 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55245b4a),
            offset: Offset(4, 5),
            blurRadius: 3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(7),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Opacity(
              opacity: snapshot.isFree ? 1 : .62,
              child: ArtworkImage(
                snapshot.tile.animal.asset,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => CircleAvatar(
                  backgroundColor: animalHaloColor(snapshot.tile.animal),
                  child: Text(snapshot.tile.animal.label.characters.first),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
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
      if (icon == Icons.timer_rounded)
        const ClayHudIcon(ClayHudIconKind.timer, size: 39)
      else
        ClaySymbol(icon, color: const Color(0xffffecd0), size: 39),
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
    child: ClayText(
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

class _SceneCommands extends StatelessWidget {
  const _SceneCommands({
    required this.session,
    required this.onHint,
    required this.onShuffle,
  });
  final MahjongSession session;
  final VoidCallback onHint, onShuffle;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _button(
        key: const Key('mahjong-hint'),
        icon: Icons.lightbulb_rounded,
        label: 'INDICE',
        onPressed: session.availablePair == null ? null : onHint,
      ),
      const SizedBox(height: 20),
      _button(
        key: const Key('mahjong-shuffle'),
        icon: Icons.shuffle_rounded,
        label: 'MÉLANGER ${session.shufflesRemaining}/3',
        onPressed: session.shufflesRemaining == 0 ? null : onShuffle,
      ),
    ],
  );
  Widget _button({
    required Key key,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) => SizedBox(
    width: double.infinity,
    height: 75,
    child: WoodenSign(
      child: TextButton.icon(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xffffedc2),
          disabledForegroundColor: const Color(0xffe1c9a0),
        ),
        icon: ClaySymbol(icon, size: 35),
        label: ClayText(
          label,
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
  );
}

class _GamePanel extends StatelessWidget {
  const _GamePanel({
    required this.session,
    required this.onHint,
    required this.onShuffle,
  });

  final MahjongSession session;
  final VoidCallback onHint;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) => GameStagePanel(
    child: GameStageCommands(
      children: [
        FilledButton.tonalIcon(
          key: const Key('mahjong-hint'),
          onPressed: session.availablePair == null ? null : onHint,
          icon: const ClaySymbol(Icons.lightbulb_rounded),
          label: const Text('INDICE'),
        ),
        FilledButton.tonalIcon(
          key: const Key('mahjong-shuffle'),
          onPressed: session.shufflesRemaining == 0 ? null : onShuffle,
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('MÉLANGER'),
        ),
      ],
    ),
  );
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.isFreeGame,
    required this.newRecord,
    required this.onReplaySame,
    required this.onReplayNew,
    required this.onLevels,
    required this.onConfigure,
    required this.onNext,
  });

  final MahjongSession session;
  final bool isFreeGame;
  final bool newRecord;
  final VoidCallback onReplaySame;
  final VoidCallback onReplayNew;
  final VoidCallback onLevels;
  final VoidCallback? onConfigure;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final won = session.status == MahjongStatus.won;
    return ColoredBox(
      key: const Key('mahjong-result-overlay'),
      color: const Color(0xaa173a31),
      child: GameResultViewport(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: GameResultPanel(
            biome: session.biome,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    won ? Icons.pets_rounded : Icons.block_rounded,
                    size: 54,
                    color: won ? AppColors.sun : AppColors.danger,
                  ),
                  Text(
                    won ? 'PLATEAU TERMINÉ !' : 'PLUS DE PAIRES',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won
                        ? '${formatDuration(session.elapsed)} · ${session.shufflesUsed} mélange(s)${isFreeGame ? '' : ' · ${session.footprints} empreinte(s)'}${newRecord ? '\nNouveau record !' : ''}'
                        : 'Les trois mélanges ont été utilisés. Essaie un autre ordre.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (won && !isFreeGame && onNext != null)
                    FilledButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('NIVEAU SUIVANT'),
                    ),
                  TextButton.icon(
                    key: const Key('mahjong-replay-same'),
                    onPressed: onReplaySame,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(
                      isFreeGame ? 'REJOUER CETTE PARTIE' : 'REJOUER',
                    ),
                  ),
                  if (isFreeGame)
                    TextButton.icon(
                      key: const Key('mahjong-new-free-game'),
                      onPressed: onReplayNew,
                      icon: const Icon(Icons.casino_rounded),
                      label: const Text('NOUVELLE PARTIE'),
                    ),
                  if (onConfigure != null)
                    TextButton.icon(
                      onPressed: onConfigure,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('MODIFIER LES RÉGLAGES'),
                    ),
                  TextButton.icon(
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
}
