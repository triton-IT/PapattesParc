import 'models.dart';

const levels = <LevelDefinition>[
  LevelDefinition(
    1,
    'Terrier des sentinelles',
    'Suricates · Porcs-épics à crête',
    BoardConfig(6, 6, 5),
    LevelBiome.savanna,
    'assets/level_art/level-01-suricates-porcs-epics.png',
    'assets/animal_markers/level-01-suricates-porcs-epics.png',
  ),
  LevelDefinition(
    2,
    'Plaine des lions',
    'Lions d’Afrique',
    BoardConfig(7, 7, 7),
    LevelBiome.savanna,
    'assets/level_art/level-02-lions-afrique.png',
    'assets/animal_markers/level-02-lion.png',
  ),
  LevelDefinition(
    3,
    'Savane des géants',
    'Girafes · Gazelles de Mhorr · Addax',
    BoardConfig(8, 8, 9),
    LevelBiome.savanna,
    'assets/level_art/level-03-girafes-gazelles-addax.png',
    'assets/animal_markers/level-03-girafe-gazelle-addax.png',
  ),
  LevelDefinition(
    4,
    'Serre de Madagascar',
    'Tortues étoilées de Madagascar',
    BoardConfig(8, 8, 10),
    LevelBiome.tropical,
    'assets/level_art/level-04-tortue-etoilee-madagascar.png',
  ),
  LevelDefinition(
    5,
    'Grande savane',
    'Oryx beïsa · Cobes de Lechwe · Zèbres de Hartmann · Addax',
    BoardConfig(9, 9, 12),
    LevelBiome.savanna,
    'assets/level_art/level-05-oryx-cobes-zebres-addax.png',
  ),
  LevelDefinition(
    6,
    'Canopée des atèles',
    'Atèles variés',
    BoardConfig(9, 9, 13),
    LevelBiome.tropical,
    'assets/level_art/level-06-ateles-varies.png',
  ),
  LevelDefinition(
    7,
    'Forêt des gibbons',
    'Gibbons à favoris blancs',
    BoardConfig(10, 9, 14),
    LevelBiome.tropical,
    'assets/level_art/level-07-gibbons-favoris-blancs.png',
  ),
  LevelDefinition(
    8,
    'Île des siamangs',
    'Siamangs',
    BoardConfig(10, 10, 16),
    LevelBiome.tropical,
    'assets/level_art/level-08-siamangs.png',
  ),
  LevelDefinition(
    9,
    'Rivière d’Asie',
    'Gibbons à mains blanches · Loutres naines d’Asie',
    BoardConfig(11, 10, 18),
    LevelBiome.riverside,
    'assets/level_art/level-09-gibbons-loutres-asie.png',
  ),
  LevelDefinition(
    10,
    'Carré des paresseux',
    'Tamarins pinchés · Tatous à trois bandes · Paresseux à deux doigts',
    BoardConfig(11, 11, 20),
    LevelBiome.tropical,
    'assets/level_art/level-10-tamarins-tatous-paresseux.png',
  ),
  LevelDefinition(
    11,
    'Second territoire des lions',
    'Lions d’Afrique',
    BoardConfig(12, 10, 20),
    LevelBiome.savanna,
    'assets/level_art/level-11-lions-afrique.png',
  ),
  LevelDefinition(
    12,
    'Marais pygmée',
    'Hippopotames pygmées · Tortues sillonnées',
    BoardConfig(12, 11, 22),
    LevelBiome.riverside,
    'assets/level_art/level-12-hippopotames-pygmees-tortues-sillonnees.png',
  ),
  LevelDefinition(
    13,
    'Forêt des tamarins',
    'Tamarins lions à tête dorée · Tamarins de Goeldi',
    BoardConfig(12, 12, 24),
    LevelBiome.tropical,
    'assets/level_art/level-13-tamarins-tete-doree-goeldi.png',
  ),
  LevelDefinition(
    14,
    'Plaine sud-américaine',
    'Tapirs terrestres · Coendous · Capybaras · Nandous de Darwin · Fourmiliers géants',
    BoardConfig(13, 12, 26),
    LevelBiome.tropical,
    'assets/level_art/level-14-tapirs-coendous-capybaras-nandous-fourmiliers.png',
  ),
  LevelDefinition(
    15,
    'Territoire des tigres',
    'Tigres',
    BoardConfig(13, 13, 28),
    LevelBiome.woodland,
    'assets/level_art/level-15-tigres.png',
  ),
  LevelDefinition(
    16,
    'Sous-bois d’Asie',
    'Cerfs huppés · Binturongs',
    BoardConfig(14, 12, 30),
    LevelBiome.woodland,
    'assets/level_art/level-16-cerfs-huppes-binturongs.png',
  ),
  LevelDefinition(
    17,
    'Clairière des cerfs sikas',
    'Cerfs sikas',
    BoardConfig(14, 13, 32),
    LevelBiome.woodland,
    'assets/level_art/level-17-cerfs-sikas.png',
  ),
  LevelDefinition(
    18,
    'Second territoire des tigres',
    'Tigres',
    BoardConfig(14, 14, 34),
    LevelBiome.woodland,
    'assets/level_art/level-18-tigres-riviere.png',
  ),
  LevelDefinition(
    19,
    'Vallée des dholes',
    'Dholes',
    BoardConfig(15, 13, 36),
    LevelBiome.woodland,
    'assets/level_art/level-19-dholes.png',
  ),
  LevelDefinition(
    20,
    'Rochers des gloutons',
    'Gloutons',
    BoardConfig(15, 14, 38),
    LevelBiome.woodland,
    'assets/level_art/level-20-gloutons.png',
  ),
  LevelDefinition(
    21,
    'Crête du goral',
    'Gorals de Chine',
    BoardConfig(15, 15, 40),
    LevelBiome.mountain,
    'assets/level_art/level-21-gorals-chine.png',
  ),
  LevelDefinition(
    22,
    'Steppe des kulans',
    'Kulans',
    BoardConfig(16, 14, 42),
    LevelBiome.steppe,
    'assets/level_art/level-22-kulans-steppe.png',
  ),
  LevelDefinition(
    23,
    'Grande steppe des kulans',
    'Kulans',
    BoardConfig(16, 15, 44),
    LevelBiome.steppe,
    'assets/level_art/level-23-kulans-grande-steppe.png',
  ),
  LevelDefinition(
    24,
    'Plateau himalayen',
    'Cerfs de Thorold · Tahrs de l’Himalaya',
    BoardConfig(16, 16, 46),
    LevelBiome.mountain,
    'assets/level_art/level-24-cerfs-thorold-tahrs-himalaya.png',
  ),
  LevelDefinition(
    25,
    'Forêt des pandas roux',
    'Pandas roux',
    BoardConfig(17, 15, 48),
    LevelBiome.woodland,
    'assets/level_art/level-25-pandas-roux.png',
  ),
  LevelDefinition(
    26,
    'Forêt des loups',
    'Loups du Canada',
    BoardConfig(17, 16, 50),
    LevelBiome.woodland,
    'assets/level_art/level-26-loups-canada.png',
  ),
  LevelDefinition(
    27,
    'Forêt des ours',
    'Ours bruns',
    BoardConfig(18, 15, 52),
    LevelBiome.woodland,
    'assets/level_art/level-27-ours-bruns.png',
  ),
  LevelDefinition(
    28,
    'Bois des panthères',
    'Panthères de l’Amour',
    BoardConfig(18, 16, 54),
    LevelBiome.woodland,
    'assets/level_art/level-28-pantheres-amour-automne.png',
  ),
  LevelDefinition(
    29,
    'Toundra des rennes',
    'Rennes',
    BoardConfig(18, 17, 56),
    LevelBiome.tundra,
    'assets/level_art/level-29-rennes-toundra.png',
  ),
  LevelDefinition(
    30,
    'Second bois des panthères',
    'Panthères de l’Amour',
    BoardConfig(19, 16, 58),
    LevelBiome.woodland,
    'assets/level_art/level-30-pantheres-amour-hiver.png',
  ),
  LevelDefinition(
    31,
    'Crêtes du Caucase',
    'Urials · Turs du Caucase',
    BoardConfig(19, 17, 60),
    LevelBiome.mountain,
    'assets/level_art/level-31-urials-turs-caucase.png',
  ),
  LevelDefinition(
    32,
    'Vallon des ours',
    'Ours bruns',
    BoardConfig(20, 16, 62),
    LevelBiome.woodland,
    'assets/level_art/level-32-ours-bruns-vallon.png',
  ),
  LevelDefinition(
    33,
    'Falaises d’Asie',
    'Takins · Markhors',
    BoardConfig(20, 17, 64),
    LevelBiome.mountain,
    'assets/level_art/level-33-takins-markhors.png',
  ),
  LevelDefinition(
    34,
    'Ruisseau des visons',
    'Visons d’Europe',
    BoardConfig(20, 18, 66),
    LevelBiome.riverside,
    'assets/level_art/level-34-visons-europe.png',
  ),
  LevelDefinition(
    35,
    'Bois des gloutons',
    'Gloutons',
    BoardConfig(21, 17, 68),
    LevelBiome.woodland,
    'assets/level_art/level-35-gloutons-bois.png',
  ),
  LevelDefinition(
    36,
    'Prairie des cerfs cochons',
    'Cerfs cochons',
    BoardConfig(21, 18, 70),
    LevelBiome.woodland,
    'assets/level_art/level-36-cerfs-cochons.png',
  ),
  LevelDefinition(
    37,
    'Bois des pandas roux',
    'Pandas roux',
    BoardConfig(22, 17, 72),
    LevelBiome.woodland,
    'assets/level_art/level-37-pandas-roux-hiver.png',
  ),
  LevelDefinition(
    38,
    'Île des lémuriens',
    'Makis cattas · Varis roux · Lémurs couronnés',
    BoardConfig(22, 18, 74),
    LevelBiome.tropical,
    'assets/level_art/level-38-lemuriens.png',
  ),
  LevelDefinition(
    39,
    'Canopée de Prévost',
    'Écureuils de Prévost',
    BoardConfig(22, 19, 76),
    LevelBiome.tropical,
    'assets/level_art/level-39-ecureuils-prevost.png',
  ),
  LevelDefinition(
    40,
    'Montagne des macaques',
    'Macaques de Barbarie',
    BoardConfig(23, 18, 78),
    LevelBiome.woodland,
    'assets/level_art/level-40-macaques-barbarie.png',
  ),
  LevelDefinition(
    41,
    'Falaises des neiges',
    'Panthères des neiges',
    BoardConfig(23, 19, 80),
    LevelBiome.mountain,
    'assets/level_art/level-41-pantheres-neiges.png',
  ),
  LevelDefinition(
    42,
    'Plaine des guépards',
    'Guépards',
    BoardConfig(24, 18, 82),
    LevelBiome.savanna,
    'assets/level_art/level-42-guepards-plaine.png',
  ),
  LevelDefinition(
    43,
    'Course des guépards',
    'Guépards',
    BoardConfig(24, 19, 84),
    LevelBiome.savanna,
    'assets/level_art/level-43-guepards-course.png',
  ),
  LevelDefinition(
    44,
    'Forêt du Pérou et du Chili',
    'Saïmiris du Pérou · Pudus du Chili',
    BoardConfig(25, 19, 86),
    LevelBiome.tropical,
    'assets/level_art/level-44-saimiris-pudus.png',
  ),
  LevelDefinition(
    45,
    'Prairie des alpagas',
    'Alpagas',
    BoardConfig(25, 20, 88),
    LevelBiome.mountain,
    'assets/level_art/level-45-alpagas.png',
  ),
];

extension LevelTemperament on LevelDefinition {
  AnimalTemperament get temperament => switch (number) {
    6 ||
    7 ||
    8 ||
    9 ||
    10 ||
    13 ||
    25 ||
    34 ||
    37 ||
    38 ||
    39 ||
    40 ||
    44 => AnimalTemperament.curious,
    2 ||
    11 ||
    15 ||
    18 ||
    28 ||
    30 ||
    41 ||
    42 ||
    43 => AnimalTemperament.majestic,
    3 ||
    4 ||
    12 ||
    14 ||
    16 ||
    17 ||
    29 ||
    36 ||
    45 => AnimalTemperament.peaceful,
    5 || 21 || 22 || 23 || 24 || 31 || 33 => AnimalTemperament.adventurous,
    1 || 19 || 20 || 26 || 27 || 32 || 35 => AnimalTemperament.brave,
    _ => throw StateError('Niveau sans tempérament : $number'),
  };
}
