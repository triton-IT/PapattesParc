# Papatte Parc

Application Flutter multijeux autour du parcours animalier :

- **Balises du refuge**, jeu de déduction en 45 missions ;
- **Align’Animaux**, match-3 original en 45 niveaux ;
- **Mahjong des animaux**, jeu de paires en 45 niveaux ;
- **Solitaire des animaux**, Klondike en pioche 1 ou 3 cartes.

Les jeux conservent des progressions locales séparées. Les réglages audio
restent communs.

## Lancer

```powershell
flutter run -d windows
```

## Vérifier

```powershell
flutter test
flutter analyze
flutter build windows
```

Les tests fonctionnels s’exécutent sur toutes les plateformes. Les références
visuelles pixel à pixel sont vérifiées et régénérées uniquement sous Windows.
