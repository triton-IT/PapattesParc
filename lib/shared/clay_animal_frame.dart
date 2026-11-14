import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A small modelled coloured surround for an animal portrait.
class ClayAnimalFrame extends StatelessWidget {
  const ClayAnimalFrame({
    required this.color,
    required this.child,
    this.circular = false,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final Color color;
  final Widget child;
  final bool circular;
  final EdgeInsetsGeometry padding;

  static final Future<ui.Image> _frames = _loadFrames();

  static Future<ui.Image> _loadFrames() async {
    final bytes = await rootBundle.load(
      'assets/optimized/clay_type/animal-frames.png',
    );
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ui.Image>(
    future: _frames,
    builder: (context, snapshot) => CustomPaint(
      painter: _FramePainter(color, circular, snapshot.data),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.color, this.circular, this.image);
  final Color color;
  final bool circular;
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final short = size.shortestSide;
    if (short <= 0) return;
    if (image case final frame?) {
      final source = circular
          ? const Rect.fromLTRB(929, 58, 1716, 834)
          : const Rect.fromLTRB(48, 67, 836, 833);
      // Preserve the modelled light while keeping each animal's colour cue.
      final red = (color.r + .20).clamp(.30, 1.20);
      final green = (color.g + .20).clamp(.30, 1.20);
      final blue = (color.b + .30).clamp(.30, 1.30);
      canvas.drawImageRect(
        frame,
        source,
        Offset.zero & size,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..colorFilter = ColorFilter.matrix([
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
          ]),
      );
      return;
    }
    final rect = (Offset.zero & size).deflate(short * .035);
    final radius = circular
        ? Radius.circular(short / 2)
        : Radius.circular(short * .18);
    final outline = RRect.fromRectAndRadius(rect, radius);
    final path = Path()..addRRect(outline);
    canvas.drawShadow(path, const Color(0xff553922), short * .04, true);
    canvas.drawRRect(
      outline,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, const Color(0xffffe0ae), .34)!,
            color,
            Color.lerp(color, const Color(0xff4f402b), .28)!,
          ],
          stops: const [0, .50, 1],
        ).createShader(rect),
    );
    canvas.drawRRect(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.6, short * .035)
        ..color = Color.lerp(color, const Color(0xff4a3427), .43)!,
    );
    canvas.drawRRect(
      outline.deflate(short * .07),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(.5, short * .018)
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0x99fff0d2), const Color(0x00403422)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      color != oldDelegate.color ||
      circular != oldDelegate.circular ||
      image != oldDelegate.image;
}
