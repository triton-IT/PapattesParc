import 'animal_catalog.dart';

extension AnimalKindFood on AnimalKind {
  String get foodAsset => 'assets/food_sort/$name.png';

  String get foodLabel => switch (this) {
    AnimalKind.suricate => 'Vers de farine et scorpion',
    AnimalKind.lion => 'Viande de grand herbivore',
    AnimalKind.girafe => 'Feuilles d’acacia',
    AnimalKind.zebre => 'Herbes fraîches de savane',
    AnimalKind.guepard => 'Viande maigre et volaille',
    AnimalKind.addax => 'Melon du désert',
    AnimalKind.atele => 'Fruits tropicaux',
    AnimalKind.gibbon => 'Figues mûres',
    AnimalKind.paresseux => 'Feuilles de cécropia',
    AnimalKind.tamarin => 'Fleurs riches en nectar',
    AnimalKind.lemurien => 'Gousses de tamarin',
    AnimalKind.saimiri => 'Noix et insectes',
    AnimalKind.loutre => 'Écrevisse',
    AnimalKind.hippopotame => 'Herbes aquatiques',
    AnimalKind.capybara => 'Courge et potiron',
    AnimalKind.vison => 'Truite',
    AnimalKind.tortue => 'Pissenlit et feuilles',
    AnimalKind.tapir => 'Fruits et légumes-racines',
    AnimalKind.tigre => 'Viande de sanglier',
    AnimalKind.pandaRoux => 'Bambou',
    AnimalKind.loup => 'Côtes de cervidé',
    AnimalKind.ours => 'Saumon et baies',
    AnimalKind.glouton => 'Os à moelle',
    AnimalKind.cerfSika => 'Glands et feuillage',
    AnimalKind.kulan => 'Stipe des steppes',
    AnimalKind.renne => 'Lichen',
    AnimalKind.oryx => 'Racines et plantes du désert',
    AnimalKind.gazelle => 'Gousses d’acacia',
    AnimalKind.cerfCochon => 'Roseaux et tubercules',
    AnimalKind.goral => 'Feuilles, champignons et lichen',
    AnimalKind.tahr => 'Herbes alpines et baies',
    AnimalKind.markhor => 'Rameaux feuillus',
    AnimalKind.panthereNeiges => 'Viande de mouton bleu',
    AnimalKind.alpaga => 'Foin',
    AnimalKind.urial => 'Herbes de montagne et graines',
    AnimalKind.panthereAmour => 'Viande de chevreuil',
  };
}
