import 'package:flutter/material.dart';

import '../../../shared/app_theme.dart';
import '../../../shared/animal_background.dart';
import '../../../shared/animal_colors.dart';
import '../../../shared/game_help.dart';
import '../domain/match3_session.dart';
import '../domain/models.dart';

class Match3Screen extends StatelessWidget {
  const Match3Screen({
    required this.session,
    this.displayed,
    this.clearing = const {},
    this.cascade = 0,
    this.inputEnabled = true,
    this.showResult,
    required this.selected,
    required this.onSelect,
    required this.onSwap,
    required this.onLevels,
    required this.onRetry,
    required this.onNext,
    this.isFreeGame = false,
    this.onConfigure,
    this.onBack,
    super.key,
  });

  final Match3Session session;
  final Match3BoardSnapshot? displayed;
  final Set<Match3Position> clearing;
  final int cascade;
  final bool inputEnabled;
  final bool? showResult;
  final Match3Position? selected;
  final ValueChanged<Match3Position> onSelect;
  final void Function(Match3Position, Match3Position) onSwap;
  final VoidCallback onLevels;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final bool isFreeGame;
  final VoidCallback? onConfigure;
  final VoidCallback? onBack;

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
                final board = Match3Board(
                  session: session,
                  displayed: displayed,
                  clearing: clearing,
                  inputEnabled: inputEnabled,
                  selected: selected,
                  onSelect: onSelect,
                  onSwap: onSwap,
                );
                final panel = _MissionPanel(
                  session: session,
                  displayed: displayed,
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: board),
                      SizedBox(width: 330, child: panel),
                    ],
                  );
                }
                return Column(
                  children: [
                    _CompactHeader(
                      session: session,
                      onLevels: onBack ?? onLevels,
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
                key: const Key('match3-back-to-levels'),
                tooltip: 'Retour aux niveaux',
                onPressed: onBack ?? onLevels,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
            const Positioned(
              right: 12,
              top: 12,
              child: GameHelpButton(kind: GameHelpKind.match3),
            ),
            if (!inputEnabled)
              Positioned(
                top: 64,
                left: 0,
                right: 0,
                child: Center(
                  child: Chip(
                    key: const Key('match3-resolving'),
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      cascade > 1 ? 'CASCADE ×$cascade' : 'ALIGNEMENT',
                    ),
                  ),
                ),
              ),
            if (showResult ?? session.status != Match3Status.playing)
              Positioned.fill(
                child: _ResultOverlay(
                  session: session,
                  onLevels: onLevels,
                  onRetry: onRetry,
                  onNext: onNext,
                  isFreeGame: isFreeGame,
                  onConfigure: onConfigure,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class Match3Board extends StatefulWidget {
  const Match3Board({
    required this.session,
    required this.displayed,
    required this.clearing,
    required this.inputEnabled,
    required this.selected,
    required this.onSelect,
    required this.onSwap,
    super.key,
  });

  final Match3Session session;
  final Match3BoardSnapshot? displayed;
  final Set<Match3Position> clearing;
  final bool inputEnabled;
  final Match3Position? selected;
  final ValueChanged<Match3Position> onSelect;
  final void Function(Match3Position, Match3Position) onSwap;

  @override
  State<Match3Board> createState() => _Match3BoardState();
}

class _Match3BoardState extends State<Match3Board> {
  Match3Position? _dragPosition;
  Offset _dragDelta = Offset.zero;
  Map<Match3Position, Offset> _dropOffsets = const {};

  @override
  void didUpdateWidget(Match3Board oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.displayed;
    final current = widget.displayed;
    _dropOffsets = previous == null || current == null || previous == current
        ? const {}
        : _drops(previous, current, oldWidget.clearing);
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.deep,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40245b4a),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Match3Session.size,
                crossAxisSpacing: 3,
                mainAxisSpacing: 3,
              ),
              itemCount: Match3Session.size * Match3Session.size,
              itemBuilder: (context, index) {
                final position = Match3Position(
                  index % Match3Session.size,
                  index ~/ Match3Session.size,
                );
                final snapshot =
                    widget.displayed?.cell(position) ??
                    widget.session.cell(position);
                return TweenAnimationBuilder<Offset>(
                  key: ValueKey((widget.displayed, position)),
                  tween: Tween(
                    begin: _dropOffsets[position] ?? Offset.zero,
                    end: Offset.zero,
                  ),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  builder: (context, offset, child) =>
                      FractionalTranslation(translation: offset, child: child),
                  child: GestureDetector(
                    onTap: widget.inputEnabled && snapshot.isActive
                        ? () => widget.onSelect(position)
                        : null,
                    onPanStart: widget.inputEnabled && snapshot.isActive
                        ? (_) {
                            _dragPosition = position;
                            _dragDelta = Offset.zero;
                          }
                        : null,
                    onPanUpdate: widget.inputEnabled && snapshot.isActive
                        ? (details) => _dragDelta += details.delta
                        : null,
                    onPanEnd: widget.inputEnabled && snapshot.isActive
                        ? (_) => _finishDrag()
                        : null,
                    child: AnimatedOpacity(
                      opacity: widget.clearing.contains(position) ? 0 : 1,
                      duration: const Duration(milliseconds: 220),
                      child: AnimatedScale(
                        scale: widget.clearing.contains(position) ? .3 : 1,
                        duration: const Duration(milliseconds: 220),
                        child: _Match3Cell(
                          position: position,
                          snapshot: snapshot,
                          haloColor: snapshot.tile?.isBasket == false
                              ? animalHaloColor(snapshot.tile!.animal)
                              : const Color(0xfffffdf5),
                          selected: widget.selected == position,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Map<Match3Position, Offset> _drops(
    Match3BoardSnapshot previous,
    Match3BoardSnapshot current,
    Set<Match3Position> cleared,
  ) {
    final drops = <Match3Position, Offset>{};
    for (var x = 0; x < Match3Session.size; x++) {
      final origins = <int>[
        for (var y = Match3Session.size - 1; y >= 0; y--)
          if (previous.cell(Match3Position(x, y)).tile != null &&
              !cleared.contains(Match3Position(x, y)))
            y,
      ];
      final destinations = <int>[
        for (var y = Match3Session.size - 1; y >= 0; y--)
          if (current.cell(Match3Position(x, y)).tile != null) y,
      ];
      for (var i = 0; i < destinations.length; i++) {
        final destination = destinations[i];
        final origin = i < origins.length
            ? origins[i]
            : -1 - i + origins.length;
        if (origin != destination) {
          drops[Match3Position(x, destination)] = Offset(
            0,
            (origin - destination).toDouble(),
          );
        }
      }
    }
    return drops;
  }

  void _finishDrag() {
    final start = _dragPosition;
    if (start == null || _dragDelta.distance < 12) return;
    final horizontal = _dragDelta.dx.abs() > _dragDelta.dy.abs();
    final target = Match3Position(
      start.x + (horizontal ? _dragDelta.dx.sign.toInt() : 0),
      start.y + (horizontal ? 0 : _dragDelta.dy.sign.toInt()),
    );
    if (target.x < 0 ||
        target.x >= Match3Session.size ||
        target.y < 0 ||
        target.y >= Match3Session.size) {
      return;
    }
    widget.onSwap(start, target);
  }
}

class _Match3Cell extends StatelessWidget {
  const _Match3Cell({
    required this.position,
    required this.snapshot,
    required this.haloColor,
    required this.selected,
  });

  final Match3Position position;
  final Match3CellSnapshot snapshot;
  final Color haloColor;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (!snapshot.isActive) {
      return const ColoredBox(color: Colors.transparent);
    }
    final tile = snapshot.tile;
    return Semantics(
      button: true,
      selected: selected,
      label: tile?.isBasket == true
          ? 'Panier de friandises'
          : tile?.animal.label,
      child: AnimatedContainer(
        key: Key('match3-cell-${position.x}-${position.y}'),
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: snapshot.blocker == null
              ? haloColor
              : _cellColor(snapshot.blocker),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? AppColors.sun
                : Colors.white.withValues(alpha: .6),
            width: selected ? 4 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (tile != null)
              Padding(
                padding: const EdgeInsets.all(4),
                child: tile.isBasket
                    ? const Icon(
                        Icons.shopping_basket_rounded,
                        color: Color(0xffb56736),
                      )
                    : Image.asset(
                        tile.animal.asset,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => CircleAvatar(
                          backgroundColor: haloColor,
                          child: Text(
                            tile.animal.label.characters.first,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
              ),
            if (snapshot.blocker != null)
              _BlockerOverlay(
                kind: snapshot.blocker!,
                layers: snapshot.blockerLayers,
              ),
            if (tile != null && tile.special != SpecialKind.none)
              Align(
                alignment: Alignment.bottomRight,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.sun,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      _specialIcon(tile.special),
                      size: 17,
                      color: AppColors.deep,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _cellColor(BlockerKind? blocker) => switch (blocker) {
    BlockerKind.leaves => const Color(0xffa8c878),
    BlockerKind.mud => const Color(0xffb88a66),
    BlockerKind.vines => const Color(0xff77a45b),
    BlockerKind.ice => const Color(0xffbde8ef),
    null => const Color(0xfffffdf5),
  };

  IconData _specialIcon(SpecialKind special) => switch (special) {
    SpecialKind.horizontalBinoculars => Icons.swap_horiz_rounded,
    SpecialKind.verticalBinoculars => Icons.swap_vert_rounded,
    SpecialKind.basketBlast => Icons.redeem_rounded,
    SpecialKind.goldenPaw => Icons.pets_rounded,
    SpecialKind.none => Icons.circle,
  };
}

class _BlockerOverlay extends StatelessWidget {
  const _BlockerOverlay({required this.kind, required this.layers});

  final BlockerKind kind;
  final int layers;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: _color, width: layers == 2 ? 4 : 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: Icon(_icon, color: _color, size: 17),
      ),
    ),
  );

  Color get _color => switch (kind) {
    BlockerKind.leaves => const Color(0xff39784f),
    BlockerKind.mud => const Color(0xff70432e),
    BlockerKind.vines => const Color(0xff245b4a),
    BlockerKind.ice => const Color(0xff31889b),
  };

  IconData get _icon => switch (kind) {
    BlockerKind.leaves => Icons.eco_rounded,
    BlockerKind.mud => Icons.water_drop_rounded,
    BlockerKind.vines => Icons.grass_rounded,
    BlockerKind.ice => Icons.ac_unit_rounded,
  };
}

class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.session, required this.onLevels});

  final Match3Session session;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(64, 10, 12, 0),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '${session.level.number} · ${session.level.stage.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const Icon(Icons.touch_app_rounded, size: 19),
        const SizedBox(width: 4),
        Text(
          '${session.movesLeft}',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );
}

class _MissionPanel extends StatelessWidget {
  const _MissionPanel({required this.session, required this.displayed});

  final Match3Session session;
  final Match3BoardSnapshot? displayed;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surface,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'NIVEAU ${session.level.number}',
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            session.level.stage.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Metric(
                icon: Icons.touch_app_rounded,
                label: '${session.movesLeft} coups',
              ),
              _Metric(
                icon: Icons.stars_rounded,
                label: '${displayed?.score ?? session.score} points',
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < session.level.goals.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _GoalLine(
                goal: session.level.goals[i],
                blockerKinds: session.level.blockers
                    .map((blocker) => blocker.kind)
                    .toSet(),
                progress: displayed?.goalProgress[i] ?? session.goalProgress(i),
                color: session.level.goals[i].animal == null
                    ? AppColors.primary
                    : animalHaloColor(session.level.goals[i].animal!),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xfffff4dc),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    ),
  );
}

class _GoalLine extends StatelessWidget {
  const _GoalLine({
    required this.goal,
    required this.blockerKinds,
    required this.progress,
    required this.color,
  });

  final Match3Goal goal;
  final Set<BlockerKind> blockerKinds;
  final int progress;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (goal.kind == Match3GoalKind.collectAnimal)
        Container(
          key: Key('match3-goal-animal-${goal.animal!.name}'),
          width: 28,
          height: 28,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Image.asset(goal.animal!.asset),
        )
      else
        Icon(_icon, color: AppColors.primary, size: 20),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          _label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      Text(
        '$progress / ${goal.target}',
        style: TextStyle(
          color: progress >= goal.target ? AppColors.success : AppColors.deep,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );

  IconData get _icon => switch (goal.kind) {
    Match3GoalKind.collectAnimal => Icons.pets_rounded,
    Match3GoalKind.clearBlockers => Icons.auto_awesome_rounded,
    Match3GoalKind.deliverBaskets => Icons.shopping_basket_rounded,
  };

  String get _label => switch (goal.kind) {
    Match3GoalKind.collectAnimal => goal.animal!.label,
    Match3GoalKind.clearBlockers =>
      blockerKinds.map((kind) => kind.goalLabel).join(' · '),
    Match3GoalKind.deliverBaskets => 'Livrer les paniers',
  };
}

extension on BlockerKind {
  String get goalLabel => switch (this) {
    BlockerKind.leaves => 'Balayer les feuilles',
    BlockerKind.mud => 'Nettoyer la boue',
    BlockerKind.vines => 'Couper les lianes',
    BlockerKind.ice => 'Briser la glace',
  };
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({
    required this.session,
    required this.onLevels,
    required this.onRetry,
    required this.onNext,
    required this.isFreeGame,
    required this.onConfigure,
  });

  final Match3Session session;
  final VoidCallback onLevels;
  final VoidCallback onRetry;
  final VoidCallback? onNext;
  final bool isFreeGame;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) {
    final won = session.status == Match3Status.won;
    return ColoredBox(
      key: const Key('match3-result-overlay'),
      color: const Color(0x990f2f26),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(20),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    won ? Icons.pets_rounded : Icons.refresh_rounded,
                    size: 54,
                    color: won ? AppColors.sun : AppColors.danger,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    won ? 'MISSION ACCOMPLIE !' : 'PLUS DE COUPS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    won
                        ? isFreeGame
                              ? '${session.score} points'
                              : '${session.score} points · ${session.footprintsForScore()} empreinte(s)'
                        : 'Les paniers peuvent être préparés autrement. Réessaie sans limite.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  if (won && onNext != null)
                    FilledButton.icon(
                      key: const Key('match3-next-level'),
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('NIVEAU SUIVANT'),
                    ),
                  FilledButton.tonalIcon(
                    key: const Key('match3-retry'),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('REJOUER'),
                  ),
                  if (onConfigure != null)
                    TextButton.icon(
                      key: const Key('match3-configure'),
                      onPressed: onConfigure,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('MODIFIER LES RÉGLAGES'),
                    ),
                  TextButton.icon(
                    onPressed: onLevels,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('CHOISIR UN NIVEAU'),
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
