import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ClayHudIconKind {
  back,
  timer,
  help,
  undo,
  hint,
  restart,
  paw,
  zoomIn,
  zoomOut,
  pan,
  recenter,
  tap,
  score,
  pairs,
  redeal,
  crate,
  walking,
  route,
  meal,
}

/// Bitmap icons share the same modelled material as the game HUD lettering.
class ClayHudIcon extends StatelessWidget {
  const ClayHudIcon(this.kind, {required this.size, this.color, super.key});

  final ClayHudIconKind kind;
  final double size;
  final Color? color;

  static final Future<ui.Image> _atlas = _load('icons.png');
  static final Future<ui.Image> _actions = _load('actions.png');
  static final Future<ui.Image> _greenCamera = _load('camera-green.png');
  static final Future<ui.Image> _metrics = _load('metrics.png');

  bool get _usesGreenCamera =>
      kind.index >= ClayHudIconKind.zoomIn.index &&
      kind.index <= ClayHudIconKind.recenter.index &&
      color != null &&
      color!.g > color!.r * 1.2 &&
      color!.g > color!.b;

  static Future<ui.Image> _load(String name) async {
    final bytes = await rootBundle.load('assets/optimized/clay_type/$name');
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: FutureBuilder<ui.Image>(
      future: _usesGreenCamera
          ? _greenCamera
          : kind.index >= ClayHudIconKind.tap.index
          ? _metrics
          : kind.index <= ClayHudIconKind.help.index
          ? _atlas
          : _actions,
      builder: (context, snapshot) {
        final atlas = snapshot.data;
        if (atlas == null) {
          return Icon(
            switch (kind) {
              ClayHudIconKind.back => Icons.arrow_back_ios_new_rounded,
              ClayHudIconKind.timer => Icons.timer_rounded,
              ClayHudIconKind.help => Icons.help_outline_rounded,
              ClayHudIconKind.undo => Icons.undo_rounded,
              ClayHudIconKind.hint => Icons.lightbulb_rounded,
              ClayHudIconKind.restart => Icons.refresh_rounded,
              ClayHudIconKind.paw => Icons.pets_rounded,
              ClayHudIconKind.zoomIn => Icons.zoom_in,
              ClayHudIconKind.zoomOut => Icons.zoom_out,
              ClayHudIconKind.pan => Icons.pan_tool_outlined,
              ClayHudIconKind.recenter => Icons.center_focus_strong,
              ClayHudIconKind.tap => Icons.touch_app_rounded,
              ClayHudIconKind.score => Icons.stars_rounded,
              ClayHudIconKind.pairs => Icons.layers_rounded,
              ClayHudIconKind.redeal => Icons.replay_circle_filled_rounded,
              ClayHudIconKind.crate => Icons.inventory_2_rounded,
              ClayHudIconKind.walking => Icons.directions_walk_rounded,
              ClayHudIconKind.route => Icons.route_rounded,
              ClayHudIconKind.meal => Icons.restaurant_rounded,
            },
            color: color ?? const Color(0xffffecd0),
            size: size,
          );
        }
        return CustomPaint(
          painter: _ClayIconPainter(atlas, kind, color, _usesGreenCamera),
        );
      },
    ),
  );
}

/// Uses a modelled icon where available and preserves Material's fallback.
/// Illustrated controls used by campaign menus and level lists.
enum ClayMenuIconKind { lock, settings, list, chevron }

class ClayMenuIcon extends StatelessWidget {
  const ClayMenuIcon(
    this.kind, {
    this.size = 24,
    this.onDark = false,
    super.key,
  });
  final ClayMenuIconKind kind;
  final double size;
  final bool onDark;
  static final Future<ui.Image> _atlas = ClayHudIcon._load('menu-icons.png');

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: FutureBuilder<ui.Image>(
      future: _atlas,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Icon(
            switch (kind) {
              ClayMenuIconKind.lock => Icons.lock_rounded,
              ClayMenuIconKind.settings => Icons.settings_rounded,
              ClayMenuIconKind.list => Icons.format_list_bulleted_rounded,
              ClayMenuIconKind.chevron => Icons.expand_more_rounded,
            },
            size: size,
            color: onDark ? const Color(0xffffedcb) : const Color(0xff315a3c),
          );
        }
        return CustomPaint(
          painter: _ClayMenuIconPainter(snapshot.data!, kind, onDark),
        );
      },
    ),
  );
}

class _ClayMenuIconPainter extends CustomPainter {
  const _ClayMenuIconPainter(this.image, this.kind, this.onDark);
  final ui.Image image;
  final ClayMenuIconKind kind;
  final bool onDark;
  @override
  void paint(Canvas canvas, Size size) {
    final source = switch (kind) {
      ClayMenuIconKind.lock => const Rect.fromLTRB(75, 135, 465, 595),
      ClayMenuIconKind.settings => const Rect.fromLTRB(600, 140, 1035, 590),
      ClayMenuIconKind.list => const Rect.fromLTRB(1140, 205, 1580, 530),
      ClayMenuIconKind.chevron => const Rect.fromLTRB(1685, 240, 2110, 515),
    };
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (onDark) {
      paint.colorFilter = const ColorFilter.matrix([
        0,
        .50,
        0,
        0,
        145,
        0,
        .48,
        0,
        0,
        137,
        0,
        .40,
        0,
        0,
        111,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    canvas.drawImageRect(
      image,
      source,
      Alignment.center.inscribe(
        applyBoxFit(BoxFit.contain, source.size, size).destination,
        Offset.zero & size,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ClayMenuIconPainter old) =>
      image != old.image || kind != old.kind || onDark != old.onDark;
}

class ClaySymbol extends StatelessWidget {
  const ClaySymbol(this.icon, {this.size, this.color, super.key});
  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final kind = switch (icon) {
      Icons.undo_rounded => ClayHudIconKind.undo,
      Icons.lightbulb_rounded ||
      Icons.lightbulb_outline_rounded => ClayHudIconKind.hint,
      Icons.refresh_rounded || Icons.refresh => ClayHudIconKind.restart,
      Icons.pets_rounded || Icons.pets => ClayHudIconKind.paw,
      Icons.zoom_in => ClayHudIconKind.zoomIn,
      Icons.zoom_out => ClayHudIconKind.zoomOut,
      Icons.pan_tool_outlined => ClayHudIconKind.pan,
      Icons.center_focus_strong => ClayHudIconKind.recenter,
      Icons.touch_app_rounded => ClayHudIconKind.tap,
      Icons.stars_rounded => ClayHudIconKind.score,
      Icons.layers_rounded => ClayHudIconKind.pairs,
      Icons.replay_circle_filled_rounded => ClayHudIconKind.redeal,
      Icons.inventory_2_rounded => ClayHudIconKind.crate,
      Icons.directions_walk_rounded => ClayHudIconKind.walking,
      Icons.route_rounded => ClayHudIconKind.route,
      Icons.restaurant_rounded => ClayHudIconKind.meal,
      _ => null,
    };
    if (kind == null) return Icon(icon, size: size, color: color);
    final theme = IconTheme.of(context);
    final effectiveColor = color ?? theme.color;
    return Opacity(
      opacity: (theme.opacity ?? 1) * (effectiveColor?.a ?? 1),
      child: ClayHudIcon(
        kind,
        size: size ?? theme.size ?? 24,
        color: effectiveColor,
      ),
    );
  }
}

class _ClayIconPainter extends CustomPainter {
  const _ClayIconPainter(this.atlas, this.kind, this.color, this.greenCamera);
  final ui.Image atlas;
  final ClayHudIconKind kind;
  final Color? color;
  final bool greenCamera;

  @override
  void paint(Canvas canvas, Size size) {
    final source = greenCamera
        ? switch (kind) {
            ClayHudIconKind.zoomIn => const Rect.fromLTRB(46, 150, 500, 612),
            ClayHudIconKind.zoomOut => const Rect.fromLTRB(590, 150, 1042, 612),
            ClayHudIconKind.pan => const Rect.fromLTRB(1118, 144, 1569, 615),
            ClayHudIconKind.recenter => const Rect.fromLTRB(
              1674,
              169,
              2126,
              599,
            ),
            _ => throw StateError('Unsupported green camera icon'),
          }
        : switch (kind) {
            ClayHudIconKind.back => const Rect.fromLTRB(212, 144, 492, 608),
            ClayHudIconKind.timer => const Rect.fromLTRB(883, 129, 1285, 609),
            ClayHudIconKind.help => const Rect.fromLTRB(1567, 134, 2036, 612),
            ClayHudIconKind.undo => const Rect.fromLTRB(80, 94, 383, 391),
            ClayHudIconKind.hint => const Rect.fromLTRB(543, 71, 784, 406),
            ClayHudIconKind.restart => const Rect.fromLTRB(948, 94, 1240, 395),
            ClayHudIconKind.paw => const Rect.fromLTRB(1377, 95, 1694, 384),
            ClayHudIconKind.zoomIn => const Rect.fromLTRB(60, 494, 378, 822),
            ClayHudIconKind.zoomOut => const Rect.fromLTRB(504, 495, 822, 822),
            ClayHudIconKind.pan => const Rect.fromLTRB(925, 490, 1253, 827),
            ClayHudIconKind.recenter => const Rect.fromLTRB(
              1375,
              505,
              1697,
              811,
            ),
            ClayHudIconKind.tap => const Rect.fromLTRB(96, 68, 352, 409),
            ClayHudIconKind.score => const Rect.fromLTRB(506, 73, 819, 396),
            ClayHudIconKind.pairs => const Rect.fromLTRB(977, 78, 1236, 403),
            ClayHudIconKind.redeal => const Rect.fromLTRB(1390, 73, 1705, 399),
            ClayHudIconKind.crate => const Rect.fromLTRB(65, 516, 379, 820),
            ClayHudIconKind.walking => const Rect.fromLTRB(522, 483, 794, 836),
            ClayHudIconKind.route => const Rect.fromLTRB(942, 508, 1259, 812),
            ClayHudIconKind.meal => const Rect.fromLTRB(1387, 485, 1705, 832),
          };
    final destination = applyBoxFit(
      BoxFit.contain,
      source.size,
      size,
    ).destination;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    // Green ink on parchment, while cream symbols keep their original colours.
    final tone = color;
    if (greenCamera) {
      // Lift the shadows and compress highlights without removing the
      // modelling already painted into the green camera sprites.
      paint.colorFilter = const ColorFilter.matrix([
        .60,
        0,
        0,
        0,
        25,
        0,
        .60,
        0,
        0,
        38,
        0,
        0,
        .60,
        0,
        30,
        0,
        0,
        0,
        1,
        0,
      ]);
    } else if (tone != null && tone.g > tone.r * 1.2 && tone.g > tone.b) {
      // Stretch the source's light-to-dark range when tinting; a simple
      // multiplication compresses it and makes the modelling look flat.
      paint.colorFilter = const ColorFilter.matrix([
        .12,
        .33,
        .10,
        0,
        -65,
        .26,
        .70,
        .24,
        0,
        -150,
        .20,
        .56,
        .19,
        0,
        -118,
        0,
        0,
        0,
        1,
        0,
      ]);
    } else if (tone != null && tone.r < .94) {
      // Follow muted/disabled foreground colours without flattening the clay.
      final red = (tone.r / .94).clamp(0.0, 1.0);
      final green = (tone.g / .88).clamp(0.0, 1.0);
      final blue = (tone.b / .76).clamp(0.0, 1.0);
      paint.colorFilter = ColorFilter.matrix([
        red,
        0,
        0,
        0,
        0,
        0,
        green,
        0,
        0,
        0,
        0,
        0,
        blue,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]);
    }
    canvas.drawImageRect(
      atlas,
      source,
      Alignment.center.inscribe(destination, Offset.zero & size),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ClayIconPainter oldDelegate) =>
      atlas != oldDelegate.atlas ||
      kind != oldDelegate.kind ||
      color != oldDelegate.color ||
      greenCamera != oldDelegate.greenCamera;
}
