import 'dart:math';

import 'package:flutter/material.dart';

import '../../../shared/animal_catalog.dart';
import '../../../shared/animal_colors.dart';
import '../../../shared/animal_background.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/formatters.dart';
import '../../../shared/game_help.dart';
import '../domain/mahjong_session.dart';
import '../domain/models.dart';

class MahjongScreen extends StatelessWidget {
  const MahjongScreen({
    required this.session,
    required this.title,
    required this.backgroundAsset,
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

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfffff4dc),
    body: AnimalBackground(
      asset: backgroundAsset,
      child: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 900 &&
                    constraints.maxWidth > constraints.maxHeight;
                final board = MahjongBoard(
                  session: session,
                  hintedIds: hintedIds,
                  onSelect: onSelect,
                  onBlocked: onBlocked,
                );
                final panel = _GamePanel(
                  session: session,
                  title: title,
                  isFreeGame: isFreeGame,
                  onHint: onHint,
                  onShuffle: onShuffle,
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: board),
                      SizedBox(width: 340, child: panel),
                    ],
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(64, 10, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
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
                key: const Key('mahjong-back'),
                tooltip: 'Retour',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const Positioned(
              right: 12,
              top: 12,
              child: GameHelpButton(kind: GameHelpKind.mahjong),
            ),
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
        ),
      ),
    ),
  );
}

class MahjongBoard extends StatefulWidget {
  const MahjongBoard({
    required this.session,
    required this.hintedIds,
    required this.onSelect,
    required this.onBlocked,
    super.key,
  });

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
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final fitScale = min(
          1.0,
          min(viewport.width / width, viewport.height / height),
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
        return InteractiveViewer(
          key: const Key('mahjong-board'),
          transformationController: _controller,
          constrained: false,
          minScale: fitScale,
          maxScale: max(1, min(2.4, fitScale * 5)),
          boundaryMargin: const EdgeInsets.all(80),
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
              child: Image.asset(
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

class _GamePanel extends StatelessWidget {
  const _GamePanel({
    required this.session,
    required this.title,
    required this.isFreeGame,
    required this.onHint,
    required this.onShuffle,
  });

  final MahjongSession session;
  final String title;
  final bool isFreeGame;
  final VoidCallback onHint;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isFreeGame ? 'PARTIE LIBRE' : 'MISSION',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric(Icons.timer_rounded, formatDuration(session.elapsed)),
              _Metric(Icons.layers_rounded, '${session.remainingPairs} paires'),
              _Metric(Icons.shuffle_rounded, '${session.shufflesRemaining}/3'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('mahjong-hint'),
                  onPressed: session.availablePair == null ? null : onHint,
                  icon: const Icon(Icons.lightbulb_rounded),
                  label: const Text('INDICE'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('mahjong-shuffle'),
                  onPressed: session.shufflesRemaining == 0 ? null : onShuffle,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('MÉLANGER'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xfffff4dc),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
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
                  FilledButton.tonalIcon(
                    key: const Key('mahjong-replay-same'),
                    onPressed: onReplaySame,
                    icon: const Icon(Icons.replay_rounded),
                    label: Text(
                      isFreeGame ? 'REJOUER CETTE PARTIE' : 'REJOUER',
                    ),
                  ),
                  if (isFreeGame)
                    FilledButton.tonalIcon(
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
