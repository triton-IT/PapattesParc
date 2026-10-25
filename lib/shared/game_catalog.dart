import 'package:flutter/material.dart';
import 'app_theme.dart';

enum GameId {
  refuge,
  pattesFriandises,
  mahjongAnimaux,
  solitaireAnimaux,
  sudokuAnimaux,
  repasAnimaux,
  numberlink,
  animalSort,
}

class GameCatalogEntry {
  const GameCatalogEntry(
    this.id,
    this.key,
    this.title,
    this.description,
    this.artAsset,
    this.icon,
    this.color,
  );
  final GameId id;
  final String key, title, description, artAsset;
  final IconData icon;
  final Color color;
}

const gameCatalog = <GameCatalogEntry>[
  GameCatalogEntry(
    GameId.refuge,
    'game-refuge',
    'Balises du refuge',
    'Observe les indices et localise les animaux sans les effrayer.',
    'assets/level_art/level-01-suricates-porcs-epics.png',
    Icons.grid_on_rounded,
    AppColors.primary,
  ),
  GameCatalogEntry(
    GameId.pattesFriandises,
    'game-pattes-friandises',
    'Align’Animaux',
    'Aligne les animaux, prépare les paniers et nettoie les habitats.',
    'assets/level_art/level-45-alpagas.png',
    Icons.pets_rounded,
    Color(0xffc9694b),
  ),
  GameCatalogEntry(
    GameId.mahjongAnimaux,
    'game-mahjong-animaux',
    'Mahjong des animaux',
    'Libère les tuiles et rassemble les animaux par paires.',
    'assets/mahjong/mahjong-cover.png',
    Icons.view_module_rounded,
    AppColors.success,
  ),
  GameCatalogEntry(
    GameId.solitaireAnimaux,
    'game-solitaire-animaux',
    'Solitaire des animaux',
    'Range les cartes et révèle les animaux du parc.',
    'assets/solitaire/solitaire-cover.png',
    Icons.style_rounded,
    AppColors.primary,
  ),
  GameCatalogEntry(
    GameId.sudokuAnimaux,
    'game-sudoku-animaux',
    'Le Défi des Papattes',
    'Replace chaque animal dans sa ligne, sa colonne et son enclos.',
    'assets/level_art/level-14-tapirs-coendous-capybaras-nandous-fourmiliers.png',
    Icons.grid_view_rounded,
    Color(0xff8c5e9e),
  ),
  GameCatalogEntry(
    GameId.repasAnimaux,
    'game-repas-animaux',
    'Le repas des animaux',
    'Aide le soigneur à livrer les caisses de nourriture dans chaque enclos.',
    'assets/sokoban/cover.png',
    Icons.restaurant_rounded,
    Color(0xffb56736),
  ),
  GameCatalogEntry(
    GameId.numberlink,
    'game-numberlink',
    'Sentiers sauvages',
    'Relie chaque animal à son enclos sans croiser les sentiers.',
    'assets/level_art/level-09-gibbons-loutres-asie.png',
    Icons.route_rounded,
    AppColors.success,
  ),
  GameCatalogEntry(
    GameId.animalSort,
    'game-animal-sort',
    'Réserves du parc',
    'Classe la nourriture selon les animaux du biome.',
    'assets/level_art/level-03-girafes-gazelles-addax.png',
    Icons.inventory_2_rounded,
    Color(0xff4f7f68),
  ),
];
