import 'package:flutter/material.dart';

import '../domain/custom_game.dart';
import '../domain/models.dart';
import 'app_theme.dart';

class CustomGameScreen extends StatefulWidget {
  const CustomGameScreen({
    required this.onBack,
    required this.onStart,
    required this.onButtonClick,
    super.key,
  });

  final VoidCallback onBack;
  final ValueChanged<LevelDefinition> onStart;
  final VoidCallback onButtonClick;

  @override
  State<CustomGameScreen> createState() => _CustomGameScreenState();
}

class _CustomGameScreenState extends State<CustomGameScreen> {
  int _animalTypeIndex = 0;
  int _width = 8;
  int _height = 8;
  int _animalCount = 10;

  LevelDefinition get _animalType => customAnimalTypes[_animalTypeIndex];
  int get _maxAnimals => CustomBoardRules.maxAnimals(_width, _height);

  void _changeSize({int? width, int? height}) {
    widget.onButtonClick();
    setState(() {
      _width = width ?? _width;
      _height = height ?? _height;
      _animalCount = _animalCount.clamp(
        CustomBoardRules.minAnimals,
        _maxAnimals,
      );
    });
  }

  void _changeAnimalCount(int value) {
    widget.onButtonClick();
    setState(() => _animalCount = value);
  }

  void _start() {
    widget.onButtonClick();
    widget.onStart(
      createCustomLevel(
        _animalType,
        BoardConfig(_width, _height, _animalCount),
      ),
    );
  }

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
              child: LevelBackdrop(level: _animalType),
            ),
          ),
          Positioned.fill(child: _CustomBackdropVeil(wide: wide)),
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
                          _Header(
                            onBack: () {
                              widget.onButtonClick();
                              widget.onBack();
                            },
                          ),
                          SizedBox(
                            height: wide ? 72 : constraints.maxHeight * .28,
                          ),
                          Align(
                            alignment: wide
                                ? Alignment.centerRight
                                : Alignment.center,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 760),
                              child: _Settings(
                                compact: constraints.maxWidth < 600,
                                animalTypeIndex: _animalTypeIndex,
                                width: _width,
                                height: _height,
                                animalCount: _animalCount,
                                maxAnimals: _maxAnimals,
                                onAnimalTypeChanged: (index) {
                                  widget.onButtonClick();
                                  setState(() => _animalTypeIndex = index);
                                },
                                onWidthChanged: (width) =>
                                    _changeSize(width: width),
                                onHeightChanged: (height) =>
                                    _changeSize(height: height),
                                onAnimalCountChanged: _changeAnimalCount,
                                onStart: _start,
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

class _CustomBackdropVeil extends StatelessWidget {
  const _CustomBackdropVeil({required this.wide});

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

class _Settings extends StatelessWidget {
  const _Settings({
    required this.compact,
    required this.animalTypeIndex,
    required this.width,
    required this.height,
    required this.animalCount,
    required this.maxAnimals,
    required this.onAnimalTypeChanged,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onAnimalCountChanged,
    required this.onStart,
  });

  final bool compact;
  final int animalTypeIndex;
  final int width;
  final int height;
  final int animalCount;
  final int maxAnimals;
  final ValueChanged<int> onAnimalTypeChanged;
  final ValueChanged<int> onWidthChanged;
  final ValueChanged<int> onHeightChanged;
  final ValueChanged<int> onAnimalCountChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: compact ? 18 : 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Crée ton refuge',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontSize: compact ? 28 : 38,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choisis le terrain et les animaux à retrouver.',
          style: TextStyle(color: Color(0xffe3eee8), fontSize: 16),
        ),
        const SizedBox(height: 24),
        _AnimalTypePicker(
          selectedIndex: animalTypeIndex,
          onChanged: onAnimalTypeChanged,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.spaceBetween,
          children: [
            _Counter(
              key: const Key('custom-width'),
              label: 'Largeur',
              value: width,
              suffix: 'cases',
              onDecrease: width > CustomBoardRules.minWidth
                  ? () => onWidthChanged(width - 1)
                  : null,
              onIncrease: width < CustomBoardRules.maxWidth
                  ? () => onWidthChanged(width + 1)
                  : null,
            ),
            _Counter(
              key: const Key('custom-height'),
              label: 'Hauteur',
              value: height,
              suffix: 'cases',
              onDecrease: height > CustomBoardRules.minHeight
                  ? () => onHeightChanged(height - 1)
                  : null,
              onIncrease: height < CustomBoardRules.maxHeight
                  ? () => onHeightChanged(height + 1)
                  : null,
            ),
            _Counter(
              key: const Key('custom-animal-count'),
              label: 'Animaux',
              value: animalCount,
              suffix: 'à retrouver',
              onDecrease: animalCount > CustomBoardRules.minAnimals
                  ? () => onAnimalCountChanged(animalCount - 1)
                  : null,
              onIncrease: animalCount < maxAnimals
                  ? () => onAnimalCountChanged(animalCount + 1)
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Pour une grille $width × $height : '
          '${CustomBoardRules.minAnimals} à '
          '$maxAnimals animaux.',
          key: const Key('custom-animal-limits'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xffe3eee8),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          key: const Key('start-custom-game'),
          onPressed: onStart,
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          icon: const Icon(Icons.grid_view_rounded),
          label: const Text('CRÉER LA GRILLE'),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      FilledButton.tonalIcon(
        key: const Key('back-from-custom'),
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
  );
}

class _AnimalTypePicker extends StatelessWidget {
  const _AnimalTypePicker({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Type d’animal',
        style: TextStyle(color: Color(0xffe3eee8), fontSize: 12),
      ),
      Row(
        children: [
          const Icon(Icons.pets_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(focusColor: AppColors.primary),
              child: DropdownButton<int>(
                key: const Key('custom-animal-type'),
                value: selectedIndex,
                isExpanded: true,
                dropdownColor: AppColors.deep,
                iconEnabledColor: Colors.white,
                underline: const Divider(color: Color(0xffe3eee8)),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (var index = 0; index < customAnimalTypes.length; index++)
                    DropdownMenuItem(
                      value: index,
                      child: Text(
                        customAnimalTypes[index].species,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (index) => onChanged(index!),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.suffix,
    required this.onDecrease,
    required this.onIncrease,
    super.key,
  });

  final String label;
  final int value;
  final String suffix;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xffb9d8c9),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Diminuer $label',
                color: Colors.white,
                disabledColor: Colors.white38,
                onPressed: onDecrease,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$value',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      suffix,
                      style: const TextStyle(
                        color: Color(0xffe3eee8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Augmenter $label',
                color: Colors.white,
                disabledColor: Colors.white38,
                onPressed: onIncrease,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
