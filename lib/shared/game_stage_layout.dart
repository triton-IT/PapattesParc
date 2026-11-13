import 'wooden_sign.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'formatters.dart';
import 'clay_text.dart';
import 'clay_hud_icon.dart';

import 'app_theme.dart';
import 'game_help.dart';
import 'park_catalog.dart';

class _StageHudBackground extends StatelessWidget {
  const _StageHudBackground({required this.wooden, required this.child});

  final bool wooden;
  final Widget child;

  @override
  Widget build(BuildContext context) => wooden
      ? WoodenSign(green: false, child: child)
      : DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.deep.withValues(alpha: .88),
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        );
}

enum GameLayoutMode { portrait, shortLandscape, wideLandscape }

class GameLayoutContext {
  const GameLayoutContext(this.availableSize, this.mode);
  factory GameLayoutContext.forSize(Size size) => GameLayoutContext(
    size,
    size.width > size.height
        ? (size.height < 500
              ? GameLayoutMode.shortLandscape
              : GameLayoutMode.wideLandscape)
        : GameLayoutMode.portrait,
  );
  final Size availableSize;
  final GameLayoutMode mode;
  bool get isLandscape => mode != GameLayoutMode.portrait;
  bool get isShort => mode == GameLayoutMode.shortLandscape;
}

typedef GameStageBuilder =
    Widget Function(BuildContext context, GameLayoutContext layout);

class GameStageCommands extends StatelessWidget {
  const GameStageCommands({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 300 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 8) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class GameStageLayout extends StatelessWidget {
  const GameStageLayout({
    required this.background,
    required this.eyebrow,
    required this.title,
    required this.backKey,
    required this.onBack,
    required this.helpKind,
    required this.builder,
    this.backTooltip = 'Retour',
    this.metrics = const [],
    this.actions = const [],
    this.fixedActions = const [],
    this.overlays = const [],
    this.backgroundOverlay,
    this.scrim = const Color(0x2618382f),
    this.backgroundColor = AppColors.deep,
    this.wooden = false,
    this.clayText = true,
    super.key,
  });

  final Widget background;
  final String eyebrow;
  final String title;
  final Key backKey;
  final VoidCallback onBack;
  final String backTooltip;
  final GameHelpKind helpKind;
  final List<GameStageMetric> metrics;
  final List<Widget> actions;
  final List<Widget> fixedActions;
  final GameStageBuilder builder;
  final List<Widget> overlays;
  final Widget? backgroundOverlay;
  final Color scrim;
  final Color backgroundColor;
  final bool wooden;
  final bool clayText;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    body: Stack(
      children: [
        Positioned.fill(child: background),
        if (scrim.a > 0) Positioned.fill(child: ColoredBox(color: scrim)),
        if (backgroundOverlay case final overlay?)
          Positioned.fill(child: overlay),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final landscape = constraints.maxWidth > constraints.maxHeight;
              return Stack(
                children: [
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width:
                              wooden &&
                                  landscape &&
                                  constraints.maxHeight >= 500
                              ? constraints.maxWidth * .87
                              : constraints.maxWidth,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                            child: _StageHudBackground(
                              wooden: wooden,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: wooden ? 14 : 4,
                                  vertical: wooden ? 8 : 4,
                                ),
                                child: _GameStageHud(
                                  eyebrow: eyebrow,
                                  title: title,
                                  backKey: backKey,
                                  onBack: onBack,
                                  backTooltip: backTooltip,
                                  helpKind: helpKind,
                                  metrics: metrics,
                                  actions: actions,
                                  fixedActions: fixedActions,
                                  wide: landscape,
                                  wooden: wooden,
                                  clayText: clayText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, area) => builder(
                            context,
                            GameLayoutContext.forSize(area.biggest),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...overlays,
                ],
              );
            },
          ),
        ),
      ],
    ),
  );
}

class GameStageMetric {
  const GameStageMetric({
    required this.icon,
    required this.label,
    this.elapsed,
    this.key,
  });

  final IconData icon;
  final ValueListenable<Duration>? elapsed;
  final String label;
  final Key? key;
}

class GameStageAction extends StatelessWidget {
  const GameStageAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.badgeLabel,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    color: Colors.white,
    disabledColor: Colors.white.withValues(alpha: .35),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints.tightFor(
      width: AppGeometry.touchTarget,
      height: AppGeometry.touchTarget,
    ),
    icon: badgeLabel == null
        ? ClaySymbol(icon)
        : Badge(label: Text(badgeLabel!), child: ClaySymbol(icon)),
  );
}

class GameStageSplit extends StatelessWidget {
  const GameStageSplit({
    required this.wide,
    required this.board,
    required this.panel,
    this.maxPanelWidth = 340,
    super.key,
  });

  final double maxPanelWidth;
  final bool wide;
  final Widget board;
  final Widget panel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final short = constraints.maxHeight < 400;
      final panelWidth = math.min(
        short ? 260.0 : maxPanelWidth,
        math.max(200.0, constraints.maxWidth * .32),
      );
      final controls = SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        child: panel,
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        child: wide
            ? Row(
                children: [
                  Expanded(child: Center(child: board)),
                  const SizedBox(width: 8),
                  SizedBox(width: panelWidth, child: controls),
                ],
              )
            : Column(
                children: [
                  Expanded(child: Center(child: board)),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * .44,
                    ),
                    child: controls,
                  ),
                ],
              ),
      );
    },
  );
}

class GameStagePanel extends StatelessWidget {
  const GameStagePanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(AppGeometry.panelRadius),
      border: Border.all(color: Colors.white.withValues(alpha: .24)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(AppGeometry.panelPadding),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          shadows: [Shadow(color: Color(0x66000000), blurRadius: 5)],
        ),
        child: child,
      ),
    ),
  );
}

class _GameStageHud extends StatelessWidget {
  const _GameStageHud({
    required this.eyebrow,
    required this.title,
    required this.backKey,
    required this.onBack,
    required this.backTooltip,
    required this.helpKind,
    required this.metrics,
    required this.actions,
    required this.fixedActions,
    required this.wide,
    required this.wooden,
    required this.clayText,
  });

  final bool wooden;
  final bool clayText;
  final String eyebrow;
  final String title;
  final Key backKey;
  final VoidCallback onBack;
  final String backTooltip;
  final GameHelpKind helpKind;
  final List<GameStageMetric> metrics;
  final List<Widget> actions;
  final List<Widget> fixedActions;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final scale = wooden && wide
        ? (MediaQuery.sizeOf(context).width / 800).clamp(1.0, 2.0)
        : 1.0;
    final spaciousWooden =
        wooden && wide && MediaQuery.sizeOf(context).width >= 1000;
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _Metric(
            metric: metrics[i],
            wooden: wooden,
            scale: scale,
            clayText: clayText,
          ),
        ],
        if (metrics.isNotEmpty && actions.isNotEmpty) const SizedBox(width: 6),
        ...actions,
      ],
    );
    final firstRow = Row(
      children: [
        _BackButton(
          key: backKey,
          tooltip: backTooltip,
          onPressed: onBack,
          scale: scale,
        ),
        const SizedBox(width: 12),
        if (spaciousWooden)
          SizedBox(
            width: MediaQuery.sizeOf(context).width * .30,
            child: _HudTitle(
              eyebrow: eyebrow,
              title: title,
              scale: scale,
              clayText: clayText,
            ),
          )
        else
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HudText(
                  eyebrow,
                  clay: clayText,
                  style: TextStyle(
                    color: AppColors.sun,
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                _HudText(
                  title,
                  clay: clayText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Color(0x66000000), blurRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (wide) ...[
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: trailing,
            ),
          ),
        ],
        if (spaciousWooden) const Spacer(),
        ...fixedActions,
        const SizedBox(width: 8),
        GameHelpButton(
          kind: helpKind,
          color: Colors.white,
          compact: true,
          iconSize: 24 * scale,
          clay: wooden,
        ),
      ],
    );
    if (wide || metrics.isEmpty && actions.isEmpty) return firstRow;
    return Column(
      children: [
        firstRow,
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: trailing,
          ),
        ),
      ],
    );
  }
}

class _HudTitle extends StatelessWidget {
  const _HudTitle({
    required this.eyebrow,
    required this.title,
    required this.scale,
    required this.clayText,
  });
  final String eyebrow, title;
  final double scale;
  final bool clayText;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _HudText(
        eyebrow,
        clay: clayText,
        style: TextStyle(
          color: AppColors.sun,
          fontSize: 11 * scale,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      _HudText(
        title,
        clay: clayText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18 * scale,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(color: Color(0x66000000), blurRadius: 6)],
        ),
      ),
    ],
  );
}

class _HudText extends StatelessWidget {
  const _HudText(this.text, {required this.style, required this.clay});
  final String text;
  final TextStyle style;
  final bool clay;

  @override
  Widget build(BuildContext context) => clay
      ? FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ClayText(text, style: style),
        )
      : Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
}

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.tooltip,
    required this.onPressed,
    this.scale = 1,
    super.key,
  });

  final double scale;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: .24)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: Colors.white,
      iconSize: 24 * scale,
      icon: ClayHudIcon(ClayHudIconKind.back, size: 24 * scale),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.metric,
    this.wooden = false,
    this.scale = 1,
    this.clayText = false,
  });

  final double scale;

  final bool wooden;
  final bool clayText;

  final GameStageMetric metric;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: metric.key,
    decoration: BoxDecoration(
      color: wooden ? null : Colors.white.withValues(alpha: .14),
      gradient: wooden
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xffbd8955), Color(0xff82512d), Color(0xffa97143)],
            )
          : null,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: wooden
            ? const Color(0xffd6ab70)
            : Colors.white.withValues(alpha: .2),
        width: wooden ? 2 : 1,
      ),
      boxShadow: wooden
          ? const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 4,
                offset: Offset(0, 3),
              ),
            ]
          : null,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 11 * scale,
        vertical: 7 * scale,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (metric.icon == Icons.timer_rounded)
            ClayHudIcon(ClayHudIconKind.timer, size: 17 * scale)
          else
            ClaySymbol(metric.icon, size: 17 * scale, color: Colors.white),
          const SizedBox(width: 5),
          if (metric.elapsed case final elapsed?)
            ValueListenableBuilder<Duration>(
              valueListenable: elapsed,
              builder: (context, value, _) => _HudText(
                formatDuration(value),
                clay: clayText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            _HudText(
              metric.label,
              clay: clayText,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    ),
  );
}

/// Shared scrollable surface for result cards on short windows and large text.
class GameResultViewport extends StatelessWidget {
  const GameResultViewport({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(child: child),
      ),
    ),
  );
}

/// A handcrafted result sign, coloured to suit the current habitat.
class GameResultPanel extends StatelessWidget {
  const GameResultPanel({required this.biome, required this.child, super.key});

  final LevelBiome biome;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accent = switch (biome) {
      LevelBiome.savanna => const Color(0xff80602c),
      LevelBiome.tropical => const Color(0xff476b27),
      LevelBiome.riverside => const Color(0xff326c60),
      LevelBiome.woodland => const Color(0xff52643a),
      LevelBiome.steppe => const Color(0xff796737),
      LevelBiome.mountain => const Color(0xff5d6b63),
      LevelBiome.tundra => const Color(0xff4c6c72),
    };
    const ink = Color(0xff3f3a20);
    final theme = Theme.of(context);
    final compactHeight = MediaQuery.sizeOf(context).height <= 500;
    Widget signBackground(
      String asset,
      Set<WidgetState> states,
      Widget? child,
    ) => Opacity(
      opacity: states.contains(WidgetState.disabled) ? .55 : 1,
      child: WoodenSign(
        green: asset.endsWith('hint-sign.webp'),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    const labelStyle = TextStyle(
      fontFamily: 'Nunito',
      fontWeight: FontWeight.w900,
    );
    final buttonStyle =
        FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xffffedc2),
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: Size(0, compactHeight ? 48 : 58),
          padding: EdgeInsets.symmetric(
            horizontal: 40,
            vertical: compactHeight ? 6 : 12,
          ),
          shape: const RoundedRectangleBorder(),
          textStyle: labelStyle,
        ).copyWith(
          backgroundBuilder: (context, states, child) => signBackground(
            'assets/optimized/sudoku/hint-sign.webp',
            states,
            child,
          ),
        );
    final secondaryStyle =
        TextButton.styleFrom(
          foregroundColor: const Color(0xffffedc2),
          minimumSize: Size(0, compactHeight ? 48 : 58),
          padding: EdgeInsets.symmetric(
            horizontal: 40,
            vertical: compactHeight ? 6 : 12,
          ),
          shape: const RoundedRectangleBorder(),
          textStyle: labelStyle,
        ).copyWith(
          backgroundBuilder: (context, states, child) => signBackground(
            'assets/optimized/sudoku/hud-plank.webp',
            states,
            child,
          ),
        );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: DecoratedBox(
        decoration: parchmentDecoration,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            36,
            compactHeight ? 10 : 30,
            36,
            compactHeight ? 10 : 30,
          ),
          child: Theme(
            data: theme.copyWith(
              textTheme: theme.textTheme.apply(
                bodyColor: ink,
                displayColor: ink,
              ),
              iconTheme: theme.iconTheme.copyWith(color: accent),
              filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
              textButtonTheme: TextButtonThemeData(style: secondaryStyle),
            ),
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: ink),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Confirmation sign used when leaving an unfinished game.
class GameConfirmDialog extends StatelessWidget {
  const GameConfirmDialog({
    required this.biome,
    required this.title,
    required this.actions,
    this.content,
    super.key,
  });

  final LevelBiome biome;
  final Widget title;
  final Widget? content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    insetPadding: const EdgeInsets.all(12),
    child: SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: GameResultPanel(
          biome: biome,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DefaultTextStyle(
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: const Color(0xff3f3a20),
                    fontWeight: FontWeight.w900,
                  ),
                  child: title,
                ),
                if (content != null) ...[
                  const SizedBox(height: 12),
                  DefaultTextStyle(
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: const Color(0xff3f3a20),
                    ),
                    child: content!,
                  ),
                ],
                const SizedBox(height: 16),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
