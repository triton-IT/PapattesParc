import 'package:flutter/material.dart';

import '../domain/models.dart';

abstract final class AppColors {
  static const background = Color(0xffeaf8f3);
  static const surface = Color(0xfffffdf5);
  static const deep = Color(0xff245b4a);
  static const primary = Color(0xff2f6d5b);
  static const success = Color(0xff48a868);
  static const sun = Color(0xffffd166);
  static const danger = Color(0xffee6c62);
  static const muted = Color(0xff8d6e63);
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.success,
    onSecondary: Colors.white,
    error: AppColors.danger,
    onError: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.deep,
  );
  final baseText = ThemeData.light().textTheme.apply(
    fontFamily: 'Nunito',
    bodyColor: AppColors.deep,
    displayColor: AppColors.deep,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Nunito',
    textTheme: baseText.copyWith(
      displaySmall: baseText.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 5,
      shadowColor: AppColors.deep.withValues(alpha: .18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.deep,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    focusColor: Colors.white,
    hoverColor: Colors.white.withValues(alpha: .16),
  );
}

class _BiomeVisuals {
  const _BiomeVisuals({
    required this.sky,
    required this.horizon,
    required this.ground,
    required this.accent,
    required this.covered,
    required this.board,
  });

  final Color sky;
  final Color horizon;
  final Color ground;
  final Color accent;
  final Color covered;
  final Color board;
}

const _biomes = <LevelBiome, _BiomeVisuals>{
  LevelBiome.savanna: _BiomeVisuals(
    sky: Color(0xffffe7b0),
    horizon: Color(0xffdcae62),
    ground: Color(0xffaa7645),
    accent: Color(0xff647541),
    covered: Color(0xff8ca45b),
    board: Color(0xffd8c58f),
  ),
  LevelBiome.tropical: _BiomeVisuals(
    sky: Color(0xffb9ddd0),
    horizon: Color(0xff549477),
    ground: Color(0xff2f654f),
    accent: Color(0xffec9d58),
    covered: Color(0xff4f8d66),
    board: Color(0xffaacbb5),
  ),
  LevelBiome.riverside: _BiomeVisuals(
    sky: Color(0xffc8e8e4),
    horizon: Color(0xff68a7a2),
    ground: Color(0xff517d62),
    accent: Color(0xfff2c66d),
    covered: Color(0xff6d9b75),
    board: Color(0xffacd3c7),
  ),
  LevelBiome.woodland: _BiomeVisuals(
    sky: Color(0xffd9e1bc),
    horizon: Color(0xff73855d),
    ground: Color(0xff405b43),
    accent: Color(0xffbc8058),
    covered: Color(0xff718b58),
    board: Color(0xffb7c69d),
  ),
  LevelBiome.steppe: _BiomeVisuals(
    sky: Color(0xffd9e4c9),
    horizon: Color(0xffa6aa65),
    ground: Color(0xff797847),
    accent: Color(0xffd49a58),
    covered: Color(0xff92995c),
    board: Color(0xffcbd0a4),
  ),
  LevelBiome.mountain: _BiomeVisuals(
    sky: Color(0xffd8e6e7),
    horizon: Color(0xff869b91),
    ground: Color(0xff59695e),
    accent: Color(0xffd6b878),
    covered: Color(0xff718778),
    board: Color(0xffbdcbc4),
  ),
  LevelBiome.tundra: _BiomeVisuals(
    sky: Color(0xffd8edf2),
    horizon: Color(0xff91b3bb),
    ground: Color(0xff667e78),
    accent: Color(0xffef9c78),
    covered: Color(0xff829e98),
    board: Color(0xffc7dcda),
  ),
};

Color biomeCoveredColor(LevelBiome biome) => _biomes[biome]!.covered;
Color biomeBoardColor(LevelBiome biome) => _biomes[biome]!.board;

class LevelBackdrop extends StatelessWidget {
  const LevelBackdrop({required this.level, super.key});

  final LevelDefinition level;

  @override
  Widget build(BuildContext context) {
    if (level.artAsset != null) {
      return Image.asset(
        level.artAsset!,
        key: const Key('level-art'),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    return CustomPaint(
      key: const Key('biome-backdrop'),
      painter: _BiomePainter(level.biome),
      child: const SizedBox.expand(),
    );
  }
}

class _BiomePainter extends CustomPainter {
  const _BiomePainter(this.biome);

  final LevelBiome biome;

  @override
  void paint(Canvas canvas, Size size) {
    final visuals = _biomes[biome]!;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [visuals.sky, visuals.horizon],
        ).createShader(Offset.zero & size),
    );
    final horizon = Path()
      ..moveTo(0, size.height * .58)
      ..quadraticBezierTo(
        size.width * .24,
        size.height * .42,
        size.width * .48,
        size.height * .59,
      )
      ..quadraticBezierTo(
        size.width * .72,
        size.height * .43,
        size.width,
        size.height * .55,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(horizon, Paint()..color = visuals.ground);
    _paintLandmark(canvas, size, visuals);
    _paintFoliage(canvas, size, visuals.accent);
  }

  void _paintLandmark(Canvas canvas, Size size, _BiomeVisuals visuals) {
    final paint = Paint()..color = visuals.horizon.withValues(alpha: .68);
    if (biome == LevelBiome.mountain || biome == LevelBiome.tundra) {
      final mountains = Path()
        ..moveTo(size.width * .12, size.height * .58)
        ..lineTo(size.width * .36, size.height * .18)
        ..lineTo(size.width * .52, size.height * .58)
        ..lineTo(size.width * .7, size.height * .27)
        ..lineTo(size.width * .94, size.height * .58)
        ..close();
      canvas.drawPath(mountains, paint);
      return;
    }
    if (biome == LevelBiome.riverside) {
      final river = Path()
        ..moveTo(size.width * .36, size.height)
        ..quadraticBezierTo(
          size.width * .6,
          size.height * .66,
          size.width * .48,
          size.height * .52,
        )
        ..quadraticBezierTo(
          size.width * .66,
          size.height * .7,
          size.width * .72,
          size.height,
        )
        ..close();
      canvas.drawPath(
        river,
        Paint()..color = visuals.sky.withValues(alpha: .7),
      );
      return;
    }
    canvas.drawCircle(
      Offset(size.width * .82, size.height * .2),
      size.shortestSide * .075,
      Paint()..color = visuals.accent.withValues(alpha: .65),
    );
  }

  void _paintFoliage(Canvas canvas, Size size, Color color) {
    final paint = Paint()..color = color.withValues(alpha: .72);
    for (final point in [
      Offset(size.width * .06, size.height * .72),
      Offset(size.width * .12, size.height * .8),
      Offset(size.width * .89, size.height * .68),
      Offset(size.width * .95, size.height * .78),
    ]) {
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(point.dx > size.width / 2 ? -.5 : .5);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.shortestSide * .08,
          height: size.shortestSide * .2,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BiomePainter oldDelegate) => oldDelegate.biome != biome;
}
