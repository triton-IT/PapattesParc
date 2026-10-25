import 'package:flutter/material.dart';
import 'artwork_manifest.dart';

abstract final class ArtworkResolver {
  static String resolve(String logicalPath, {double? physicalWidth}) {
    final variants = artworkVariants[logicalPath];
    if (variants == null || variants.isEmpty) return logicalPath;
    if (physicalWidth != null && physicalWidth.isFinite) {
      for (final variant in variants) {
        if (variant.width >= physicalWidth) return variant.path;
      }
    }
    return variants.last.path;
  }

  static AssetImage provider(String path, {double? physicalWidth}) =>
      AssetImage(resolve(path, physicalWidth: physicalWidth));
}

/// One image policy for menu thumbnails, backgrounds, and transparent sprites.
class ArtworkImage extends StatefulWidget {
  const ArtworkImage(
    this.asset, {
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.medium,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    super.key,
  });
  final String asset;
  final double? width, height;
  final BoxFit? fit;
  final AlignmentGeometry alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  final String? semanticLabel;
  final bool excludeFromSemantics;
  @override
  State<ArtworkImage> createState() => _ArtworkImageState();
}

class _ArtworkImageState extends State<ArtworkImage> {
  int _attempt = 0;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final logicalWidth = widget.width?.isFinite == true
          ? widget.width!
          : constraints.hasBoundedWidth
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width;
      final logicalHeight = widget.height?.isFinite == true
          ? widget.height!
          : constraints.hasBoundedHeight
          ? constraints.maxHeight
          : 0.0;
      final variants = artworkVariants[widget.asset];
      var neededWidth = logicalWidth;
      if (widget.fit == BoxFit.cover && variants != null) {
        final ratio = variants.last.width / variants.last.height;
        if (logicalHeight * ratio > neededWidth) {
          neededWidth = logicalHeight * ratio;
        }
      }
      final path = ArtworkResolver.resolve(
        widget.asset,
        physicalWidth: neededWidth * MediaQuery.devicePixelRatioOf(context),
      );
      return Image.asset(
        path,
        key: ValueKey((path, _attempt)),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        color: widget.color,
        colorBlendMode: widget.colorBlendMode,
        filterQuality: widget.filterQuality,
        semanticLabel: widget.semanticLabel,
        excludeFromSemantics: widget.excludeFromSemantics,
        frameBuilder: (context, child, frame, synchronous) =>
            synchronous || frame != null
            ? child
            : ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainer,
                child: SizedBox(width: widget.width, height: widget.height),
              ),
        errorBuilder:
            widget.errorBuilder ??
            (context, error, trace) => Center(
              child: IconButton(
                tooltip: 'Réessayer le chargement de l’image',
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await AssetImage(path).evict();
                  if (mounted) setState(() => _attempt++);
                },
              ),
            ),
      );
    },
  );
}

/// Test support: preload the bounded set of variants, never used at app startup.
Future<void> precacheArtwork(
  ImageProvider provider,
  BuildContext context,
) async {
  String? path;
  if (provider is AssetImage) path = provider.assetName;
  final entries = artworkVariants.values.where(
    (variants) => variants.any((variant) => variant.path == path),
  );
  if (entries.isEmpty) {
    await precacheImage(provider, context);
    return;
  }
  await Future.wait([
    for (final variant in entries.first)
      precacheImage(AssetImage(variant.path), context),
  ]);
}
