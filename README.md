# Papatte Parc

Application Flutter multijeux autour du parcours animalier :

- **Balises du refuge**, jeu de déduction en 45 missions ;
- **Align’Animaux**, match-3 original en 45 niveaux et partie libre ;
- **Mahjong des animaux**, jeu de paires en 45 niveaux ;
- **Solitaire des animaux**, 45 donnes fixes notées selon les recyclages de la pioche, plus un mode libre en pioche 1 ou 3 cartes.
- **Le Défi des Papattes**, sudoku animalier en 45 niveaux et partie libre ;
- **Repas des animaux**, Sokoban animalier en 45 niveaux et partie libre ;
- **Sentiers sauvages**, jeu Numberlink animalier en 45 niveaux et partie libre.
- **Réserves du parc**, jeu de tri des repas en 45 niveaux et partie libre.

Les jeux conservent des progressions locales séparées. Les réglages audio
restent communs.

## Lancer

SDK de référence : Flutter **3.44.9**, indiqué dans `.flutter-version` et la CI.

```powershell
flutter run -d windows
```

Le Web utilise un worker Dart compilé pour les générateurs. Le préparer avant
`flutter run -d chrome`, ou produire le paquet complet :

```powershell
dart compile js -O2 tool/generation_worker.dart -o web/generation_worker.js
./tool/build_web.ps1 -BaseHref /PapattesParc/
```

Servir `build/web` sous le chemin correspondant au `BaseHref` (ne pas ouvrir
`index.html` directement). Connexion requise, cache HTTP ordinaire ; aucun
téléchargement hors ligne du parc. Le worker doit rester à côté d’`index.html`.

Un appui sur une mission ouvre sa fiche ; **Jouer** lance la sélection et
**Continuer** rejoint directement la mission courante. Carte, sélection et zoom
restent en mémoire par jeu. La liste permet d’accéder aux missions regroupées.
Les plateaux agrandis se déplacent avec deux doigts ; un doigt conserve le
geste du jeu. À la souris, activer **Déplacer le plateau**, puis le désactiver
pour rejouer. Les boutons de zoom et de recentrage sont accessibles au clavier.

Temps actif, audio, actions différées et interactions se suspendent lorsque
l’application perd son activité et reprennent automatiquement au retour.
Il n’existe aucune pause manuelle.

## Vérifier

```powershell
flutter analyze
flutter test --exclude-tags=performance --concurrency=1
# Exécuter seul, sans compilation ou autres suites concurrentes :
flutter test test/games/mahjong_animaux/mahjong_functional_test.dart --tags=performance --concurrency=1
flutter build windows --release
flutter build appbundle --release
```

Les tests fonctionnels s’exécutent sur toutes les plateformes. Les références
visuelles pixel à pixel sont vérifiées et régénérées uniquement sous Windows.

Les tests responsive parcourent les huit jeux, les grandes grilles, la rotation
et les textes à 200 %. Une référence visuelle ne doit être remplacée qu’après
examen de la capture correspondante.

## Illustrations

Les PNG originaux sont conservés dans le dépôt. Seules les variantes déclarées
dans `assets/optimized` sont distribuées. Génération reproductible avec Python
3.13 et Pillow 11.3.0 :

```powershell
py -3.13 -m pip install Pillow==11.3.0
py -3.13 tool/generate_artwork.py
py -3.13 tool/generate_artwork.py --check
py -3.13 tool/check_runtime_assets.py build/web/assets
```

`ArtworkResolver` choisit la résolution selon la taille et le DPR. Les décors
sont en WebP qualité 90 ; carte, sprites et interfaces utilisent le sans perte.
Les doublons graphiques sont associés au même fichier généré. Ne pas modifier
le manifeste Dart à la main.

## Android et livraison

La signature release utilise les variables `ANDROID_KEYSTORE_PATH`,
`ANDROID_KEY_ALIAS`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, ou
`android/key.properties` (`storeFile`, `keyAlias`, `storePassword`, `keyPassword`).
Ces secrets ne doivent jamais être versionnés. Sans configuration, le bundle
de vérification reste **non signé** ; aucune clé debug ne signe une release.
Une configuration partielle fait échouer le build.
Le déclenchement manuel de la CI propose `signed_android_release` : il requiert
aussi le secret `ANDROID_KEYSTORE_BASE64` et les trois secrets alias/mots de
passe ci-dessus. Le keystore est recréé uniquement dans le dossier temporaire
du runner. Cette option reste désactivée pour les vérifications ordinaires.

La CI analyse et teste sous Linux, contrôle les références sous Windows,
compile Web/Windows/Android et conserve les candidats par SHA. Pages n’est
publié qu’après réussite des trois jobs. Conserver le candidat précédent pour
un retour arrière ; les anciennes clés de sauvegarde restent lisibles.

La compilation et les tests automatisés ne remplacent pas la qualification
sur Android physique, Safari iPhone/iPad et Windows. Les mesures réseau et
frames doivent préciser l’appareil et le scénario ; voir `docs/audits`.
