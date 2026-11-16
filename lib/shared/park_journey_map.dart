import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'wooden_sign.dart';
import 'clay_hud_icon.dart';
import 'clay_text.dart';
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
    this.clayStyle = false,
    this.controller,
    super.key,
  });
  final bool clayStyle;
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
  bool _constraining = false;
  @override
  void initState() {
    super.initState();
    _selection =
        widget.controller ??
        CampaignSelectionController.forGame(
          widget.keyPrefix,
          widget.unlockedLevel,
        );
    _selection.camera.addListener(_enforceCamera);
  }

  @override
  void dispose() {
    _selection.camera.removeListener(_enforceCamera);
    super.dispose();
  }

  void _enforceCamera() {
    final viewport = _selection.viewport;
    if (_constraining || viewport == null || viewport.isEmpty) return;
    _constraining = true;
    _constrainCamera(viewport);
    _constraining = false;
  }

  double _fit(Size viewport) =>
      math.min(viewport.width / _world.width, viewport.height / _world.height);

  Size _sceneSize(Size viewport) {
    final fit = _fit(viewport);
    return Size(
      math.max(_world.width, viewport.width / fit),
      math.max(_world.height, viewport.height / fit),
    );
  }

  Offset _mapOffset(Size viewport) {
    final scene = _sceneSize(viewport);
    return Offset(
      (scene.width - _world.width) / 2,
      (scene.height - _world.height) / 2,
    );
  }

  void _setCamera(Size viewport, double scale, Offset translation) {
    final fit = _fit(viewport);
    final scene = _sceneSize(viewport);
    if (scale <= fit * 1.001) {
      scale = fit;
      translation = Offset(
        (viewport.width - scene.width * scale) / 2,
        (viewport.height - scene.height * scale) / 2,
      );
    } else {
      translation = Offset(
        translation.dx.clamp(
          math.min(0.0, viewport.width - scene.width * scale),
          0.0,
        ),
        translation.dy.clamp(
          math.min(0.0, viewport.height - scene.height * scale),
          0.0,
        ),
      );
    }
    final current = _selection.camera.value;
    if ((current.getMaxScaleOnAxis() - scale).abs() < 1e-8 &&
        (current.getTranslation().x - translation.dx).abs() < 1e-8 &&
        (current.getTranslation().y - translation.dy).abs() < 1e-8) {
      return;
    }
    _selection.camera.value = Matrix4.diagonal3Values(scale, scale, scale)
      ..setTranslationRaw(translation.dx, translation.dy, 0);
  }

  void _focus(Size viewport, {bool overview = false}) {
    if (!mounted || viewport.isEmpty) return;
    final fit = _fit(viewport);
    final currentScale = _selection.camera.value.getMaxScaleOnAxis();
    final scale = overview || currentScale <= fit * 1.001 ? fit : currentScale;
    final point = parkLevelPositions[_selection.selectedIndex];
    final mapOffset = _mapOffset(viewport);
    final target = scale == fit
        ? Offset(
            _sceneSize(viewport).width / 2,
            _sceneSize(viewport).height / 2,
          )
        : mapOffset + Offset(point.dx * _world.width, point.dy * _world.height);
    _selection.viewport = viewport;
    _setCamera(viewport, scale, viewport.center(Offset.zero) - target * scale);
    _selection.focusRequested = false;
  }

  void _zoom(double factor, Size viewport) {
    final scale = _selection.camera.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(_fit(viewport), _fit(viewport) * 6);
    final center = viewport.center(Offset.zero);
    final world = _selection.camera.toScene(center);
    _setCamera(viewport, next, center - world * next);
  }

  void _constrainCamera(Size viewport) {
    final matrix = _selection.camera.value;
    _setCamera(
      viewport,
      matrix.getMaxScaleOnAxis(),
      Offset(matrix.getTranslation().x, matrix.getTranslation().y),
    );
  }

  Future<void> _list([List<int>? indices]) async {
    final entries = indices ?? List.generate(widget.itemCount, (i) => i);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.clayStyle ? Colors.transparent : null,
      showDragHandle: !widget.clayStyle,
      builder: (context) => SafeArea(
        child: Container(
          decoration: widget.clayStyle ? parchmentDecoration : null,
          padding: widget.clayStyle
              ? const EdgeInsets.fromLTRB(32, 30, 32, 20)
              : EdgeInsets.zero,
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .78,
            child: Column(
              children: [
                if (widget.clayStyle)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ClayText(
                      indices == null
                          ? 'Niveaux du parc'
                          : 'Niveaux de cette zone',
                      style: const TextStyle(
                        fontSize: 26,
                        color: Color(0xff315a3c),
                      ),
                    ),
                  )
                else
                  Text(
                    indices == null
                        ? 'Niveaux du parc'
                        : 'Niveaux de cette zone',
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
                        leading: widget.clayStyle
                            ? unlocked
                                  ? const ClaySymbol(
                                      Icons.pets_rounded,
                                      size: 25,
                                      color: Color(0xff315a3c),
                                    )
                                  : const ClayMenuIcon(
                                      ClayMenuIconKind.lock,
                                      size: 25,
                                    )
                            : Icon(
                                unlocked
                                    ? Icons.pets_rounded
                                    : Icons.lock_rounded,
                              ),
                        title: widget.clayStyle
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: ClayText(
                                  '${index + 1} · ${widget.labelBuilder(index)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: unlocked
                                        ? const Color(0xff315a3c)
                                        : const Color(0xff826e50),
                                  ),
                                ),
                              )
                            : Text(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: widget.clayStyle ? Colors.transparent : const Color(0xffa9653a),
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
              _focus(viewport, overview: true);
            } else {
              final oldMapCenter =
                  _selection.camera.toScene(oldSize.center(Offset.zero)) -
                  _mapOffset(oldSize);
              final scale =
                  _selection.camera.value.getMaxScaleOnAxis() *
                  _fit(viewport) /
                  _fit(oldSize);
              final target = oldMapCenter + _mapOffset(viewport);
              _selection.viewport = viewport;
              _setCamera(
                viewport,
                scale,
                viewport.center(Offset.zero) - target * scale,
              );
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
              onInteractionUpdate: (_) => _constrainCamera(viewport),
              onInteractionEnd: (_) => _constrainCamera(viewport),
              child: SizedBox.fromSize(
                size: _sceneSize(viewport),
                child: Stack(
                  children: [
                    if (!widget.clayStyle)
                      Positioned(
                        left: _mapOffset(viewport).dx,
                        top: _mapOffset(viewport).dy,
                        width: _world.width,
                        height: _world.height,
                        child: Image.asset(
                          'assets/optimized/park-scene-clay.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                  ],
                ),
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
                        _mapOffset(viewport).dx +
                            parkLevelPositions[i].dx * _world.width,
                        _mapOffset(viewport).dy +
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
              child: Container(
                decoration: widget.clayStyle ? parchmentDecoration : null,
                padding: widget.clayStyle
                    ? const EdgeInsets.all(6)
                    : EdgeInsets.zero,
                child: Material(
                  color: widget.clayStyle
                      ? Colors.transparent
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  elevation: widget.clayStyle ? 0 : 2,
                  child: Wrap(
                    direction: Axis.vertical,
                    children: [
                      IconButton(
                        tooltip: 'Zoom +',
                        onPressed: () => _zoom(1.4, viewport),
                        icon: widget.clayStyle
                            ? const ClayHudIcon(
                                ClayHudIconKind.zoomIn,
                                size: 26,
                                color: Color(0xff315a3c),
                              )
                            : const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Zoom −',
                        onPressed: () => _zoom(1 / 1.4, viewport),
                        icon: widget.clayStyle
                            ? const ClayHudIcon(
                                ClayHudIconKind.zoomOut,
                                size: 26,
                                color: Color(0xff315a3c),
                              )
                            : const Icon(Icons.remove),
                      ),
                      IconButton(
                        tooltip: 'Recentrer',
                        onPressed: () => _focus(viewport),
                        icon: widget.clayStyle
                            ? const ClayHudIcon(
                                ClayHudIconKind.recenter,
                                size: 26,
                                color: Color(0xff315a3c),
                              )
                            : const Icon(Icons.my_location),
                      ),
                      IconButton(
                        tooltip: 'Vue du parc',
                        onPressed: () => _focus(viewport, overview: true),
                        icon: widget.clayStyle
                            ? const ClaySymbol(
                                Icons.route_rounded,
                                size: 26,
                                color: Color(0xff315a3c),
                              )
                            : const Icon(Icons.map_outlined),
                      ),
                      IconButton(
                        key: Key('${widget.keyPrefix}-level-list'),
                        tooltip: 'Liste des niveaux',
                        onPressed: _list,
                        icon: widget.clayStyle
                            ? const ClayMenuIcon(
                                ClayMenuIconKind.list,
                                size: 26,
                              )
                            : const Icon(Icons.format_list_numbered),
                      ),
                    ],
                  ),
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
            shape: CircleBorder(
              side: widget.clayStyle
                  ? const BorderSide(color: Color(0xffd9b076), width: 3)
                  : BorderSide.none,
            ),
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
                  child: group.length > 1 || unlocked
                      ? widget.clayStyle
                            ? ClayText(
                                group.length > 1
                                    ? '${group.length}'
                                    : '${index + 1}',
                                style: TextStyle(
                                  fontSize: 19,
                                  color: containsSelection
                                      ? const Color(0xff315a3c)
                                      : const Color(0xffffedcb),
                                ),
                              )
                            : Text(
                                group.length > 1
                                    ? '${group.length}'
                                    : '${index + 1}',
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w900,
                                  color: containsSelection
                                      ? AppColors.deep
                                      : Colors.white,
                                ),
                              )
                      : widget.clayStyle
                      ? const ClayMenuIcon(
                          ClayMenuIconKind.lock,
                          size: 23,
                          onDark: true,
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

/// One illustration contains the park and its surroundings. Its outermost
/// pixels extend the scene behind fixed panels and across unusual aspect ratios.
class ParkSceneBackdrop extends StatelessWidget {
  const ParkSceneBackdrop({required this.imageRect, super.key});
  final Rect imageRect;
  static final Future<ui.Image> _image = _load();

  static Future<ui.Image> _load() async {
    final data = await rootBundle.load(
      'assets/optimized/park-scene-expanded.png',
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
    future: _image,
    builder: (context, snapshot) => snapshot.hasData
        ? CustomPaint(painter: _ParkScenePainter(snapshot.data!, imageRect))
        : const ColoredBox(color: Color(0xffc77b2a)),
  );
}

class _ParkScenePainter extends CustomPainter {
  const _ParkScenePainter(this.image, this.destination);
  final ui.Image image;
  final Rect destination;

  @override
  void paint(Canvas canvas, Size size) {
    final width = image.width.toDouble(), height = image.height.toDouble();
    final paint = Paint()..filterQuality = FilterQuality.medium;
    // Extend the earth from the same illustration when a screen is wider or
    // taller than the scene. The map itself is never stretched or duplicated.
    final soil = Rect.fromLTRB(
      width * .72,
      height * .32,
      width * .80,
      height * .45,
    );
    final tileWidth = destination.width * .08;
    final tileHeight = destination.height * .13;
    if (tileWidth <= 0 || tileHeight <= 0) return;
    final startX =
        destination.left - ((destination.left / tileWidth).ceil() * tileWidth);
    final startY =
        destination.top - ((destination.top / tileHeight).ceil() * tileHeight);
    final columns = ((size.width - startX) / tileWidth).ceil();
    final rows = ((size.height - startY) / tileHeight).ceil();
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final rect = Rect.fromLTWH(
          startX + column * tileWidth,
          startY + row * tileHeight,
          tileWidth,
          tileHeight,
        );
        canvas.save();
        canvas.translate(rect.center.dx, rect.center.dy);
        canvas.scale(column.isOdd ? -1 : 1, row.isOdd ? -1 : 1);
        canvas.drawImageRect(
          image,
          soil,
          Rect.fromCenter(
            center: Offset.zero,
            width: tileWidth + 1,
            height: tileHeight + 1,
          ),
          paint,
        );
        canvas.restore();
      }
    }
    canvas.saveLayer(destination, Paint());
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, width, height),
      destination,
      paint,
    );
    final fade = math.min(
      32.0,
      math.min(destination.width, destination.height) * .04,
    );
    void feather(Rect area, Alignment begin, Alignment end) {
      canvas.drawRect(
        area,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: begin,
            end: end,
            colors: const [Colors.transparent, Colors.white],
          ).createShader(area),
      );
    }

    feather(
      Rect.fromLTWH(
        destination.left,
        destination.top,
        fade,
        destination.height,
      ),
      Alignment.centerLeft,
      Alignment.centerRight,
    );
    feather(
      Rect.fromLTWH(
        destination.right - fade,
        destination.top,
        fade,
        destination.height,
      ),
      Alignment.centerRight,
      Alignment.centerLeft,
    );
    feather(
      Rect.fromLTWH(
        destination.left,
        destination.bottom - fade,
        destination.width,
        fade,
      ),
      Alignment.bottomCenter,
      Alignment.topCenter,
    );
    canvas.restore();
    // Extend the top foliage, not the soil, into any space above the scene.
    // The map begins below this strip, so its coordinates remain unchanged.
    if (destination.top > 0) {
      const topFraction = .05;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, width, height * topFraction),
        Rect.fromLTRB(
          destination.left,
          0,
          destination.right,
          destination.top + destination.height * topFraction,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParkScenePainter old) =>
      old.image != image || old.destination != destination;
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
