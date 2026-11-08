import 'package:flutter/material.dart';

import '../domain/custom_game.dart';
import '../domain/models.dart';
import '../../../shared/app_theme.dart';
import '../../../shared/free_game_theme.dart';

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
  Widget build(BuildContext context) => FreeGameScaffold(
    backgroundAsset: _animalType.artAsset!,
    backgroundKey: const Key('level-art'),
    title: 'Crée ton refuge',
    subtitle: 'Choisis le terrain et les animaux à retrouver.',
    backKey: const Key('refuge-custom-back'),
    onBack: () {
      widget.onButtonClick();
      widget.onBack();
    },
    child: _Settings(
      compact: MediaQuery.sizeOf(context).width < 600,
      animalTypeIndex: _animalTypeIndex,
      width: _width,
      height: _height,
      animalCount: _animalCount,
      maxAnimals: _maxAnimals,
      onAnimalTypeChanged: (index) {
        widget.onButtonClick();
        setState(() => _animalTypeIndex = index);
      },
      onWidthChanged: (width) => _changeSize(width: width),
      onHeightChanged: (height) => _changeSize(height: height),
      onAnimalCountChanged: _changeAnimalCount,
      onStart: _start,
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
                  fontFamily: 'Nunito',
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
