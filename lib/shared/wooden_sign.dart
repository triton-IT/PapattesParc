import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A horizontal three-part sign: the decorated ends keep their proportions
/// while only the plain middle of the plank stretches.
class WoodenSign extends StatelessWidget {
  const WoodenSign({required this.child, this.green = true, super.key});

  final Widget child;
  final bool green;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.passthrough,
    children: [
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = green ? 128.0 : 138.0;
            final end = green ? 80.0 : 85.0;
            final imageHeight = math.max(
              1,
              math
                  .min(
                    constraints.maxHeight,
                    constraints.maxWidth * height / (2 * end + 1),
                  )
                  .floor(),
            );
            final imageWidth = (384 * imageHeight / height).round();
            final capWidth = (end * imageHeight / height).floorToDouble();
            return DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: ResizeImage(
                    AssetImage(
                      green
                          ? 'assets/optimized/sudoku/hint-sign.webp'
                          : 'assets/optimized/sudoku/hud-plank.webp',
                    ),
                    width: imageWidth,
                    height: imageHeight,
                  ),
                  centerSlice: Rect.fromLTRB(
                    capWidth,
                    0,
                    imageWidth - capWidth,
                    imageHeight.toDouble(),
                  ),
                  fit: BoxFit.fill,
                ),
              ),
            );
          },
        ),
      ),
      child,
    ],
  );
}

/// Stretch only plain sections of the frame. Leaves, knots and the leather
/// patches stay together and retain the same scale on both axes.
const parchmentDecoration = _ParchmentDecoration();

class _ParchmentDecoration extends Decoration {
  const _ParchmentDecoration();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _ParchmentPainter(onChanged);
}

class _ParchmentPainter extends BoxPainter {
  _ParchmentPainter(super.onChanged);

  static const _provider = ResizeImage(
    AssetImage('assets/optimized/sudoku/parchment-panel.webp'),
    width: 384,
    height: 384,
  );
  ImageStream? _stream;
  ImageInfo? _image;
  ImageStreamListener? _listener;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final stream = _provider.resolve(configuration);
    if (_stream?.key != stream.key) {
      if (_listener != null) _stream?.removeListener(_listener!);
      _stream = stream;
      _listener = ImageStreamListener((image, synchronousCall) {
        _image?.dispose();
        _image = image;
        if (!synchronousCall) onChanged?.call();
      });
      stream.addListener(_listener!);
    }
    final image = _image?.image;
    final size = configuration.size;
    if (image == null || size == null || size.isEmpty) return;

    // The two narrow strips on each axis contain plain wood and parchment.
    const xs = [0.0, 130.0, 145.0, 239.0, 254.0, 384.0];
    const ys = [0.0, 108.0, 120.0, 264.0, 276.0, 384.0];
    final scale = math.min(.5, math.min(size.width / 356, size.height / 362));
    final dx = _positions(xs, size.width, scale);
    final dy = _positions(ys, size.height, scale);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 5; x++) {
        if (x > 0 && x < 4 && y > 0 && y < 4) continue;
        canvas.drawImageRect(
          image,
          Rect.fromLTRB(xs[x], ys[y], xs[x + 1], ys[y + 1]),
          Rect.fromLTRB(
            offset.dx + dx[x],
            offset.dy + dy[y],
            offset.dx + dx[x + 1],
            offset.dy + dy[y + 1],
          ),
          paint,
        );
      }
    }
    // Paint the inner paper as one piece, covering joins between frame strips.
    canvas.drawImageRect(
      image,
      const Rect.fromLTRB(60, 60, 324, 324),
      Rect.fromLTRB(
        offset.dx + _map(60, xs, dx),
        offset.dy + _map(60, ys, dy),
        offset.dx + _map(324, xs, dx),
        offset.dy + _map(324, ys, dy),
      ),
      paint,
    );
  }

  double _map(double value, List<double> source, List<double> destination) {
    for (var i = 0; i < source.length - 1; i++) {
      if (value <= source[i + 1]) {
        final t = (value - source[i]) / (source[i + 1] - source[i]);
        return destination[i] + t * (destination[i + 1] - destination[i]);
      }
    }
    return destination.last;
  }

  List<double> _positions(List<double> source, double extent, double scale) {
    final fixed =
        (source[1] -
            source[0] +
            source[3] -
            source[2] +
            source[5] -
            source[4]) *
        scale;
    final stretch = math.max(0.0, extent - fixed) / 2;
    return [
      0,
      source[1] * scale,
      source[1] * scale + stretch,
      (source[1] + source[3] - source[2]) * scale + stretch,
      (source[1] + source[3] - source[2]) * scale + 2 * stretch,
      extent,
    ];
  }

  @override
  void dispose() {
    if (_listener != null) _stream?.removeListener(_listener!);
    _image?.dispose();
    super.dispose();
  }
}
