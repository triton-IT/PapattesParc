import 'package:flutter/material.dart';

import 'animal_catalog.dart';

const animalHaloColors = [
  Color(0xffffb74d),
  Color(0xff4fc3f7),
  Color(0xffce93d8),
  Color(0xff81c784),
  Color(0xffff8a80),
  Color(0xffffd54f),
  Color(0xff4dd0e1),
  Color(0xff9575cd),
];

Color animalHaloColor(AnimalKind animal) =>
    animalHaloColors[animal.index % animalHaloColors.length];
