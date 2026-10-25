import 'artwork.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'campaign_selection_controller.dart';

class ParkJourneyProgress extends StatelessWidget {
  const ParkJourneyProgress({
    required this.currentLevel,
    required this.itemCount,
    super.key,
  });
  final int currentLevel;
  final int itemCount;
  @override
  Widget build(BuildContext context) => Chip(
    avatar: const Icon(Icons.verified_rounded, size: 20),
    label: Text('$currentLevel / $itemCount'),
  );
}

class ParkJourneyLegend extends StatelessWidget {
  const ParkJourneyLegend({super.key});
  @override
  Widget build(BuildContext context) => const Text(
    'Sélectionne un niveau',
    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
  );
}

class ParkJourneyMap extends StatefulWidget {
  const ParkJourneyMap({
    required this.itemCount,
    required this.unlockedLevel,
    required this.keyPrefix,
    required this.labelBuilder,
    required this.onSelect,
    this.controller,
    super.key,
  });
  final int itemCount;
  final int unlockedLevel;
  final String keyPrefix;
  final String Function(int) labelBuilder;
  final ValueChanged<int> onSelect;
  final CampaignSelectionController? controller;
  @override
  State<ParkJourneyMap> createState() => _ParkJourneyMapState();
}

class _ParkJourneyMapState extends State<ParkJourneyMap> {
  static const _world = Size(1491, 1055);
  late CampaignSelectionController _selection;
  bool _positionPending = false;
  @override
  void initState() {
    super.initState();
    _selection =
        widget.controller ??
        CampaignSelectionController.forGame(
          widget.keyPrefix,
          widget.unlockedLevel,
        );
  }

  double _fit(Size viewport) =>
      math.min(viewport.width / _world.width, viewport.height / _world.height);

  void _focus(Size viewport, {bool overview = false}) {
    if (!mounted || viewport.isEmpty) return;
    final fit = _fit(viewport);
    final point = parkLevelPositions[_selection.selectedIndex];
    final scale = fit * (overview ? 1 : 3);
    _selection.camera.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        viewport.width / 2 - (overview ? .5 : point.dx) * _world.width * scale,
        viewport.height / 2 -
            (overview ? .5 : point.dy) * _world.height * scale,
        0,
      );
    _selection.viewport = viewport;
    _selection.focusRequested = false;
  }

  void _zoom(double factor, Size viewport) {
    final old = _selection.camera.value;
    final scale = old.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(_fit(viewport), _fit(viewport) * 6);
    final center = viewport.center(Offset.zero);
    final world = _selection.camera.toScene(center);
    _selection.camera.value = Matrix4.diagonal3Values(next, next, 1)
      ..setTranslationRaw(
        center.dx - world.dx * next,
        center.dy - world.dy * next,
        0,
      );
  }

  Future<void> _list([List<int>? indices]) async {
    final entries = indices ?? List.generate(widget.itemCount, (i) => i);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            children: [
              Text(
                indices == null ? 'Niveaux du parc' : 'Niveaux de cette zone',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, position) {
                    final index = entries[position];
                    final unlocked = index < widget.unlockedLevel;
                    return ListTile(
                      key: Key('${widget.keyPrefix}-list-level-${index + 1}'),
                      enabled: unlocked,
                      selected: index == _selection.selectedIndex,
                      leading: Icon(
                        unlocked ? Icons.pets_rounded : Icons.lock_rounded,
                      ),
                      title: Text(
                        '${index + 1} · ${widget.labelBuilder(index)}',
                      ),
                      onTap: unlocked
                          ? () {
                              Navigator.pop(context);
                              _selection.select(index);
                              widget.onSelect(index);
                              if (_selection.viewport case final viewport?) {
                                _focus(viewport);
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xfffff4dc),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final oldSize = _selection.viewport;
        if ((oldSize != viewport || _selection.focusRequested) &&
            !_positionPending) {
          _positionPending = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _positionPending = false;
            if (!mounted) return;
            if (oldSize == null || _selection.focusRequested) {
              _focus(viewport);
            } else {
              final scene = _selection.camera.toScene(
                oldSize.center(Offset.zero),
              );
              final scale =
                  _selection.camera.value.getMaxScaleOnAxis() *
                  _fit(viewport) /
                  _fit(oldSize);
              _selection.camera.value = Matrix4.diagonal3Values(scale, scale, 1)
                ..setTranslationRaw(
                  viewport.width / 2 - scene.dx * scale,
                  viewport.height / 2 - scene.dy * scale,
                  0,
                );
              _selection.viewport = viewport;
            }
          });
        }
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            InteractiveViewer(
              transformationController: _selection.camera,
              constrained: false,
              minScale: _fit(viewport),
              maxScale: _fit(viewport) * 6,
              boundaryMargin: const EdgeInsets.all(1600),
              child: SizedBox.fromSize(
                size: _world,
                child: ArtworkImage('assets/park_map.png', fit: BoxFit.fill),
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_selection.camera, _selection]),
              builder: (context, _) {
                final points = [
                  for (var i = 0; i < widget.itemCount; i++)
                    MatrixUtils.transformPoint(
                      _selection.camera.value,
                      Offset(
                        parkLevelPositions[i].dx * _world.width,
                        parkLevelPositions[i].dy * _world.height,
                      ),
                    ),
                ];
                final groups = <List<int>>[];
                final remaining = {for (var i = 0; i < points.length; i++) i};
                while (remaining.isNotEmpty) {
                  final group = [remaining.first];
                  remaining.remove(group.first);
                  for (var cursor = 0; cursor < group.length; cursor++) {
                    final nearby = remaining
                        .where(
                          (i) =>
                              (points[i] - points[group[cursor]]).distance < 54,
                        )
                        .toList();
                    group.addAll(nearby);
                    remaining.removeAll(nearby);
                  }
                  groups.add(group);
                }
                return Stack(
                  children: [
                    for (final group in groups) _marker(group, points),
                  ],
                );
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                elevation: 2,
                child: Wrap(
                  direction: Axis.vertical,
                  children: [
                    IconButton(
                      tooltip: 'Zoom +',
                      onPressed: () => _zoom(1.4, viewport),
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Zoom −',
                      onPressed: () => _zoom(1 / 1.4, viewport),
                      icon: const Icon(Icons.remove),
                    ),
                    IconButton(
                      tooltip: 'Recentrer',
                      onPressed: () => _focus(viewport),
                      icon: const Icon(Icons.my_location),
                    ),
                    IconButton(
                      tooltip: 'Vue du parc',
                      onPressed: () => _focus(viewport, overview: true),
                      icon: const Icon(Icons.map_outlined),
                    ),
                    IconButton(
                      key: Key('${widget.keyPrefix}-level-list'),
                      tooltip: 'Liste des niveaux',
                      onPressed: _list,
                      icon: const Icon(Icons.format_list_numbered),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _marker(List<int> group, List<Offset> points) {
    final containsSelection = group.contains(_selection.selectedIndex);
    final anchor = containsSelection
        ? points[_selection.selectedIndex]
        : points[group.first];
    final index = group.first;
    final unlocked = index < widget.unlockedLevel;
    final label = group.length > 1
        ? '${group.length} niveaux'
        : '${index + 1} · ${widget.labelBuilder(index)}';
    return Positioned(
      left: anchor.dx - 24,
      top: anchor.dy - 24,
      child: Tooltip(
        message: label,
        child: Semantics(
          label: label,
          selected: containsSelection,
          enabled: group.length > 1 || unlocked,
          button: true,
          child: Material(
            color: containsSelection
                ? AppColors.sun
                : unlocked
                ? AppColors.success
                : AppColors.deep,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              key: Key(
                group.length == 1
                    ? '${widget.keyPrefix}-level-${index + 1}'
                    : '${widget.keyPrefix}-group-${group.first}',
              ),
              customBorder: const CircleBorder(),
              onTap: group.length > 1
                  ? () => _list(group..sort())
                  : unlocked
                  ? () {
                      _selection.select(index);
                      widget.onSelect(index);
                    }
                  : null,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: group.length > 1
                      ? Text(
                          '${group.length}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            color: containsSelection
                                ? AppColors.deep
                                : Colors.white,
                          ),
                        )
                      : unlocked
                      ? Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            color: containsSelection
                                ? AppColors.deep
                                : Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const parkLevelPositions = [
  Offset(.625, .590),
  Offset(.647, .616),
  Offset(.612, .718),
  Offset(.777, .682),
  Offset(.827, .680),
  Offset(.753, .610),
  Offset(.727, .639),
  Offset(.708, .646),
  Offset(.711, .544),
  Offset(.659, .522),
  Offset(.641, .567),
  Offset(.582, .476),
  Offset(.534, .446),
  Offset(.548, .393),
  Offset(.542, .325),
  Offset(.593, .336),
  Offset(.614, .219),
  Offset(.500, .299),
  Offset(.422, .333),
  Offset(.393, .291),
  Offset(.423, .296),
  Offset(.393, .238),
  Offset(.467, .189),
  Offset(.425, .155),
  Offset(.346, .208),
  Offset(.358, .125),
  Offset(.314, .227),
  Offset(.187, .144),
  Offset(.123, .068),
  Offset(.182, .187),
  Offset(.227, .287),
  Offset(.321, .280),
  Offset(.326, .318),
  Offset(.369, .336),
  Offset(.398, .333),
  Offset(.347, .408),
  Offset(.358, .457),
  Offset(.467, .420),
  Offset(.550, .525),
  Offset(.393, .514),
  Offset(.288, .435),
  Offset(.363, .571),
  Offset(.513, .586),
  Offset(.550, .571),
  Offset(.775, .854),
];
