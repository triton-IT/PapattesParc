import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/games/familles_du_parc/data/animal_sort_progress_store.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/animal_sort_session.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/campaign.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/models.dart';
import 'package:papatte_parc/games/refuge/domain/levels.dart';
import 'package:papatte_parc/games/familles_du_parc/domain/sort_food.dart';
import 'package:papatte_parc/shared/park_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('un groupe visible rejoint seulement une zone compatible', () {
    final level = AnimalSortLevelDefinition(
      stage: levels.first,
      foods: const [SortFood.beef, SortFood.acaciaLeaves],
      initialZones: const [
        [SortFood.beef, SortFood.acaciaLeaves, SortFood.acaciaLeaves],
        [SortFood.beef],
        [],
      ],
      referenceSolution: const [AnimalSortMove(0, 2)],
    );
    final session = AnimalSortSession(level);

    expect(session.move(0, 1), AnimalSortMoveResult.blocked);
    expect(session.moves, 0);
    expect(session.move(0, 2), AnimalSortMoveResult.moved);
    expect(session.zones[0], const [SortFood.beef]);
    expect(session.zones[2], const [
      SortFood.acaciaLeaves,
      SortFood.acaciaLeaves,
    ]);
    expect(session.undo(), isTrue);
    expect(session.zones, level.initialZones);
    expect(session.moves, 0);
  });

  test('le bas détermine les portions déplacées et la compatibilité', () {
    final level = AnimalSortLevelDefinition(
      stage: levels.first,
      foods: const [SortFood.beef, SortFood.acaciaLeaves],
      initialZones: const [
        [SortFood.beef, SortFood.acaciaLeaves, SortFood.acaciaLeaves],
        [SortFood.acaciaLeaves, SortFood.beef],
        [SortFood.beef, SortFood.acaciaLeaves, SortFood.acaciaLeaves],
        [],
      ],
      referenceSolution: const [AnimalSortMove(0, 2)],
    );
    final session = AnimalSortSession(level);
    expect(session.canMove(0, 1), isFalse);
    expect(session.move(0, 2), AnimalSortMoveResult.moved);
    expect(session.zones[0], [SortFood.beef, SortFood.acaciaLeaves]);
    expect(session.zones[2], [
      SortFood.beef,
      SortFood.acaciaLeaves,
      SortFood.acaciaLeaves,
      SortFood.acaciaLeaves,
    ]);
    expect(session.undo(), isTrue);
    expect(session.zones, level.initialZones);
  });

  test('les 45 mélanges possèdent une solution de référence valide', () {
    final campaign = buildAnimalSortCampaign(levels);

    expect(campaign, hasLength(45));
    for (final level in campaign) {
      final session = AnimalSortSession(level);
      expect(
        level.initialZones.last,
        isEmpty,
        reason: 'niveau ${level.number}',
      );
      expect(
        level.initialZones.expand((zone) => zone).length,
        level.foods.length * animalSortZoneCapacity,
      );
      for (final move in level.referenceSolution) {
        expect(
          session.move(move.from, move.to),
          isNot(AnimalSortMoveResult.blocked),
          reason: 'niveau ${level.number}, $move',
        );
      }
      expect(
        session.status,
        AnimalSortStatus.won,
        reason: 'niveau ${level.number}',
      );
      expect(session.moves, level.parMoves);
      expect(session.footprints(), 3);
    }
  });

  test('les repas correspondent aux scènes et restent distincts', () {
    final campaign = buildAnimalSortCampaign(levels);
    expect(campaign[1].foods, [SortFood.beef, SortFood.poultry, SortFood.boar]);
    expect(campaign[14].foods, isNot(contains(SortFood.crayfish)));
    expect(campaign[14].foods, isNot(contains(SortFood.salmonBerries)));
    expect(campaign[24].foods.take(3), [
      SortFood.bambooLeaves,
      SortFood.bambooShoot,
      SortFood.apple,
    ]);
    expect(
      campaign[33].foods,
      containsAll([SortFood.smallFish, SortFood.crayfish]),
    );
    expect(
      campaign[44].foods,
      containsAll([SortFood.meadowGrass, SortFood.hay]),
    );
    for (final level in campaign) {
      expect(
        level.foods.toSet().length,
        level.foods.length,
        reason: 'niveau ${level.number}',
      );
    }
  });

  test('chaque biome propose huit repas distincts en partie libre', () {
    for (final biome in LevelBiome.values) {
      final stage = levels.firstWhere((stage) => stage.biome == biome);
      final level = buildAnimalSortLevel(stage, speciesCount: 8, seed: 7);
      expect(level.foods.toSet().length, 8, reason: biome.name);
      final session = AnimalSortSession(level);
      for (final move in level.referenceSolution) {
        expect(
          session.move(move.from, move.to),
          isNot(AnimalSortMoveResult.blocked),
          reason: biome.name,
        );
      }
      expect(session.status, AnimalSortStatus.won, reason: biome.name);
    }
  });

  test('un indice suit la solution connue et reste limité à trois', () {
    final session = AnimalSortSession(buildAnimalSortCampaign(levels).first);

    expect(session.hint(), session.level.referenceSolution.first);
    expect(session.hint(), session.level.referenceSolution.first);
    expect(session.hint(), session.level.referenceSolution.first);
    expect(session.hint(), isNull);
  });

  test('la progression conserve le meilleur nombre de déplacements', () async {
    SharedPreferences.setMockInitialValues({'numberlink:unlockedLevel': 9});
    final store = await AnimalSortProgressStore.load();

    expect(await store.completeLevel(1, 20, 2), isTrue);
    expect(await store.completeLevel(1, 24, 1), isFalse);
    expect(await store.completeLevel(1, 18, 3), isTrue);
    expect(store.unlockedLevel, 2);
    expect(store.bestMoves(1), 18);
    expect(store.footprints(1), 3);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt('numberlink:unlockedLevel'), 9);
  });
}
