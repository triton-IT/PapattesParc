import 'package:flutter/material.dart';

import 'app_theme.dart';

class FreeGameScaffold extends StatelessWidget {
  const FreeGameScaffold({
    required this.backgroundAsset,
    required this.title,
    required this.subtitle,
    required this.backKey,
    required this.onBack,
    required this.child,
    this.backgroundKey,
    this.maxContentWidth = 760,
    super.key,
  });

  final String backgroundAsset;
  final String title;
  final String subtitle;
  final Key backKey;
  final VoidCallback onBack;
  final Widget child;
  final Key? backgroundKey;
  final double maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Transform.scale(
              scale: wide ? 1.28 : 1.2,
              alignment: wide ? Alignment.centerRight : Alignment.bottomCenter,
              child: Image.asset(
                backgroundAsset,
                key: backgroundKey,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(child: _BackdropVeil(wide: wide)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(backKey: backKey, onBack: onBack),
                          SizedBox(
                            height: wide ? 72 : constraints.maxHeight * .28,
                          ),
                          Align(
                            alignment: wide
                                ? Alignment.centerRight
                                : Alignment.center,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxContentWidth,
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: constraints.maxWidth < 600
                                      ? 18
                                      : 28,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontSize: constraints.maxWidth < 600
                                                ? 28
                                                : 38,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        color: Color(0xffe3eee8),
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    DefaultTextStyle.merge(
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      child: IconTheme(
                                        data: const IconThemeData(
                                          color: Colors.white,
                                        ),
                                        child: child,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FreeGameDropdown<T> extends StatelessWidget {
  const FreeGameDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon = Icons.tune_rounded,
    super.key,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: Color(0xffe3eee8), fontSize: 12),
      ),
      Row(
        children: [
          Icon(icon),
          const SizedBox(width: 10),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(focusColor: AppColors.primary),
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.deep,
                iconEnabledColor: Colors.white,
                underline: const Divider(color: Color(0xffe3eee8)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                items: items,
                onChanged: (value) => onChanged(value as T),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class FreeGameSummary extends StatelessWidget {
  const FreeGameSummary(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: const TextStyle(
      color: Color(0xffe3eee8),
      fontWeight: FontWeight.w800,
    ),
  );
}

class _BackdropVeil extends StatelessWidget {
  const _BackdropVeil({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: wide ? Alignment.centerLeft : Alignment.topCenter,
        end: wide ? Alignment.centerRight : Alignment.bottomCenter,
        colors: wide
            ? [
                Colors.transparent,
                AppColors.deep.withValues(alpha: .16),
                AppColors.deep.withValues(alpha: .88),
              ]
            : [
                Colors.transparent,
                AppColors.deep.withValues(alpha: .32),
                AppColors.deep.withValues(alpha: .92),
              ],
        stops: wide ? const [0, .48, 1] : const [0, .28, 1],
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.backKey, required this.onBack});

  final Key backKey;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Row(
      children: [
        if (constraints.maxWidth < 430)
          IconButton.filledTonal(
            key: backKey,
            tooltip: 'Parcours',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          )
        else
          FilledButton.tonalIcon(
            key: backKey,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Parcours'),
          ),
        const Spacer(),
        const DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.sun,
            borderRadius: BorderRadius.all(Radius.circular(99)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: AppColors.deep, size: 20),
                SizedBox(width: 7),
                Text(
                  'PARTIE LIBRE',
                  style: TextStyle(
                    color: AppColors.deep,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
