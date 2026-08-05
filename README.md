# Papatte Parc

Application Flutter multijeux autour du parcours animalier :

- **Balises du refuge**, jeu de déduction en 45 missions ;
- **Align’Animaux**, match-3 original en 45 niveaux et partie libre ;
- **Mahjong des animaux**, jeu de paires en 45 niveaux ;
- **Solitaire des animaux**, 45 donnes fixes notées selon les recyclages de la pioche, plus un mode libre en pioche 1 ou 3 cartes.
- **Le Défi des Papattes**, sudoku animalier en 45 niveaux et partie libre ;
- **Sentiers sauvages**, jeu Numberlink animalier en 45 niveaux et partie libre.

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
