import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'formatters.dart';

import 'app_theme.dart';
import 'game_help.dart';

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
    this.overlays = const [],
    this.backgroundOverlay,
    this.scrim = const Color(0x2618382f),
    this.backgroundColor = AppColors.deep,
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
  final GameStageBuilder builder;
  final List<Widget> overlays;
  final Widget? backgroundOverlay;
  final Color scrim;
  final Color backgroundColor;

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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                        child: Material(
                          color: AppColors.deep.withValues(alpha: .88),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: _GameStageHud(
                              eyebrow: eyebrow,
                              title: title,
                              backKey: backKey,
                              onBack: onBack,
                              backTooltip: backTooltip,
                              helpKind: helpKind,
                              metrics: metrics,
                              actions: actions,
                              wide: landscape,
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
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

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
    icon: Icon(icon),
  );
}

class GameStageSplit extends StatelessWidget {
  const GameStageSplit({
    required this.wide,
    required this.board,
    required this.panel,
    super.key,
  });

  final bool wide;
  final Widget board;
  final Widget panel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final short = constraints.maxHeight < 400;
      final panelWidth = math.min(
        short ? 260.0 : 340.0,
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
    required this.wide,
  });

  final String eyebrow;
  final String title;
  final Key backKey;
  final VoidCallback onBack;
  final String backTooltip;
  final GameHelpKind helpKind;
  final List<GameStageMetric> metrics;
  final List<Widget> actions;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          _Metric(metric: metrics[i]),
        ],
        if (metrics.isNotEmpty && actions.isNotEmpty) const SizedBox(width: 6),
        ...actions,
      ],
    );
    final firstRow = Row(
      children: [
        _BackButton(key: backKey, tooltip: backTooltip, onPressed: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.sun,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
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
        const SizedBox(width: 8),
        GameHelpButton(kind: helpKind, color: Colors.white, compact: true),
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

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

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
      icon: const Icon(Icons.arrow_back_rounded),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.metric});

  final GameStageMetric metric;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: metric.key,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .2)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(metric.icon, size: 17, color: Colors.white),
          const SizedBox(width: 5),
          if (metric.elapsed case final elapsed?)
            ValueListenableBuilder<Duration>(
              valueListenable: elapsed,
              builder: (context, value, _) => Text(
                formatDuration(value),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          else
            Text(
              metric.label,
              style: const TextStyle(
                color: Colors.white,
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
