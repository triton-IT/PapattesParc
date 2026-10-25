# Papatte Parc — mise en œuvre et qualification

Chantier des 24–25 octobre 2026, basé sur `e97fce84ce0cbe77d7ac7b05365c0072331a1c8a`
avec les modifications locales présentes au début du chantier conservées.
L’audit initial reste dans `docs/audits/2026-10-22`.

Ce document distingue les changements de code, les contrôles automatisés et
la qualification sur appareil. Les builds ne valent pas qualification complète.

## Changements par lot

| Lot | Avant | Comportement livré |
|---|---|---|
| 0 | SDK non figé, sondes responsive temporaires, performance mesurée avec d’autres suites | Flutter 3.44.9, tests responsive permanents, tests de performance isolés par tag ; copie locale de référence et empreintes dans `tmp/implementation/baseline*` |
| 1 | Dispositions portrait/paysage à seuil global, HUD superposé et panneaux fixes | Mesure de l’espace restant après le HUD, trois modes de disposition, panneaux flexibles/défilables, commandes accessibles ; résultats défilables, piles du Solitaire avec défilement et déplacement automatique près des bords |
| 2 | Deux cartes, missions parfois lancées immédiatement, marqueurs réduits avec la carte | Carte commune, marqueurs de 48 px, groupes ouvrant une liste, sélection puis fiche puis Jouer ; Continuer direct, zoom/recentrage/vue du parc/liste, mémoire de caméra par jeu |
| 3 | Progression déduite du dernier niveau débloqué, fin à 98 % | Niveaux terminés explicites et migration additive ; 45 victoires = 100 %, records et récompenses conservés ; catalogue et métadonnées du parc indépendants du Refuge |
| 4 | Originaux PNG distribués et chargés pour les cartes du menu | Variantes WebP adaptées au DPR et à l’usage, originaux conservés hors du paquet, alias pour trois paires de doublons, placeholders et reprise sur erreur |
| 5 | Rafraîchissements fréquents de tout l’écran et calculs lourds sur le fil UI | Horloge monotone avec affichage à la seconde, suspension/reprise automatiques, audio commun protégé contre les refus d’autoplay ; génération en isolate natif ou worker Web avec rejet des requêtes périmées et Sudoku à la demande |
| 6 | Styles/commandes divergents, amorçage Web minimal, orientation imposée | Composants communs, focus clavier et sémantique, texte agrandi, amorçage français léger avec erreur/réessai, portrait et paysage ; retrait de l’enregistrement du cache applicatif hors ligne |
| 7 | Publication Web sans qualification multi-build et signature debug de release Android | CI avec analyse/tests/assets, références Windows, builds Web/Windows/Android et publication conditionnée ; signature de production externe optionnelle, vérifications ordinaires Android non signées |

Les moteurs et les huit jeux restent distincts. Le stockage commun intervient
sur les politiques de meilleur temps, score, déplacements, poussées, récompenses
et déblocage ; les anciennes clés restent les mêmes, y compris celles des modes
libres. Un record nul existant est conservé.

Le lancement du candidat Windows a repris les sauvegardes présentes : comparaison
avant/après sur 222 anciennes clés, **aucune valeur existante modifiée** ; seules
sept listes de niveaux terminés ont été ajoutées. Aucune victoire artificielle
n’a été enregistrée pendant ce contrôle. Voir `evidence/windows-migration-evidence.json`.

La navigation agrandie utilise deux doigts. À la souris, le bouton **Déplacer
le plateau** permet de parcourir le plateau sans lancer les gestes du jeu.
Le désactiver rend les interactions de jeu habituelles. Ce mode ne suspend pas
la partie. Il n’existe aucun bouton ni écran de pause/reprise manuelle.

## Vérifications reproductibles

```powershell
flutter analyze
flutter test --exclude-tags=performance --concurrency=1
# Attendre la fin de toute compilation avant la mesure suivante :
flutter test test/games/mahjong_animaux/mahjong_functional_test.dart --tags=performance --concurrency=1
py -3.13 tool/generate_artwork.py --check
./tool/build_web.ps1 -BaseHref /PapattesParc/
py -3.13 tool/check_runtime_assets.py build/web/assets
flutter build windows --release
flutter build appbundle --release
```

Le contrôle des assets compare les empreintes des sources et des variantes,
leurs dimensions déclarées dans le manifeste Dart et leur inventaire. Les
illustrations originales et ressources 3D sont interdites dans le paquet.

Les références visuelles couvrent les configurations, campagnes, parties et
résultats en 800 × 360, 360 × 800, 800 × 1280, 1366 × 768 et 1920 × 1080.
Les tests responsive parcourent dix formats, à texte 100/150/200 %, avec rotation
pendant la partie. Ils vérifient notamment les grilles les plus grandes, les dix
paniers et le défilement du Solitaire. Les tests de contrats couvrent migration,
fin de campagne, conservation des records, horloge, actions différées, livraison
des générations après retour et gestes concurrents du jeu et de la caméra.

## Images et revue visuelle

155 sources logiques correspondent à 45 944 808 octets de variantes distribuées.
Les trois paires Sokoban identiques partagent leurs fichiers physiques. Les
106 sources prévues en sans perte ont été comparées après composition sur fond
noir et blanc : rendu pixel à pixel identique, transparence comprise.

Menu bureau observé localement en 1280 × 720 : huit vignettes et la carte demandent
**2 073 770 octets**, contre 16 785 007 octets d’images dans le scénario initial
de l’audit, soit **87,65 % de réduction**. Ce relevé porte sur les fichiers demandés,
sans compression HTTP, et ne mesure pas le délai de chargement. La liste des
requêtes retenues et les limites figurent dans `evidence/menu-image-measurement.json`.

Quatre décors ont été examinés côte à côte à taille native : suricates/porcs-épics,
takins/markhors, couverture Mahjong et couverture Repas. Les PSNR observés sont
de 37,67 à 41,26 dB ; ce nombre décrit une différence numérique, pas à lui seul
une validation perceptuelle. Aucun artefact gênant n’a été constaté dans les
échantillons examinés. L’examen sur écrans physiques haute densité reste requis.

Les écarts initiaux Numberlink et Repas n’ont pas été masqués par une mise à jour
globale : le plateau Numberlink et ses commandes ont changé de disposition ;
Repas utilise les sprites locaux déjà présents au début du chantier, désormais
référencés par le résolveur. Les captures candidates sont produites séparément,
examinées par type d’écran, puis intégrées aux références correspondantes.
Les sondes visuelles attendent désormais les illustrations visibles avant de
capturer, afin de ne pas prendre un placeholder transitoire pour référence.
Le contrôle natif a aussi permis de corriger le débordement du zoom Repas sur le
HUD ; le viewport coupe désormais le débordement et conserve les marges des sprites.

## Résultats du candidat

- Analyse statique : aucune anomalie.
- Suite complète sans mesure chronométrique : **145 tests réussis**, 9 min 10 s
  sur cette machine ; cette durée n’est pas une mesure de vitesse du jeu.
- Test de performance Mahjong exécuté seul, dans son fichier dédié : **1 test
  réussi**. La limite de 15 s pour la génération/vérification des 45 plateaux
  est respectée ; cela ne mesure ni les frames ni un appareil Android.
- **152 références visuelles** examinées puis vérifiées par la suite complète ;
  les empreintes avant/après et motifs sont dans `evidence/golden-review.json`.
- Compilation Web release sous `/PapattesParc/`, Windows release et Android AAB
  release réussies. Le bundle Android ne contient aucune signature RSA/DSA/EC :
  c’est un artefact de vérification non signé.
- Web final exercé dans le navigateur : menu, sélection/fiche/Jouer, worker Sudoku,
  rotation en 800 × 360, retour aux campagnes, zoom et déplacement Repas sans
  changement des compteurs, puis coup de jeu après désactivation du déplacement.
  Aucune erreur console observée dans ce scénario.
- Sauvegardes Windows réelles relues et comparées, menu et campagne Repas ouverts
  dans le natif. La suspension/reprise du candidat Windows final n’a pas été
  exercée manuellement ; les tests automatisés de cycle de vie sont réussis.

Lors du second lancement Windows, la capture était noire alors que l’arbre UIA
annonçait le menu ; la fenêtre n’était ensuite plus disponible. Aucun événement
Application Error 1000 concernant le jeu n’a été trouvé dans la période examinée.
La cause n’est pas établie : ce contrôle ne qualifie pas le rendu du dernier
exécutable et devra être reproduit dans une session Windows disponible.

Les captures `evidence/web-menu.png`, `evidence/web-sudoku-800x360.png` et
`evidence/web-repas-zoom.png` proviennent du navigateur sur le candidat compilé.
Les journaux complets sont dans `evidence/analyze.txt`, `evidence/tests.txt`,
`evidence/performance.txt` et `evidence/build-*.txt`.

Les trois artefacts locaux sont dans `tmp/implementation/candidate-2026-10-25` :
`web.zip`, `windows.zip` et `android-unsigned.aab`. Le manifeste `candidate.json`
associe leurs SHA-256 aux empreintes des sources exécutables. Sa copie est dans
`evidence/candidate.json`. Ces archives constituent un candidat local, sans
engagement de qualification matérielle ni de publication.

## Qualification restant à effectuer

| Contrôle | État et condition de clôture |
|---|---|
| Android physique modeste et intermédiaire | Non qualifié : aucun appareil physique connecté ; tester gestes, arrière-plan, audio, mémoire et frames |
| Safari iPhone/iPad | Non qualifié : Safari/Apple indisponible dans cet environnement ; vérifier rotation, viewport, multitouch, audio et stockage |
| Windows, réglages 125/150 %, écrans tactiles/120 Hz | Build et tests Windows disponibles ; essais matériels et p95 des frames restant à mesurer |
| GitHub Pages réel | Sous-répertoire exercé localement ; déploiement réel et mise à jour d’une ancienne version restant à tester après exécution de la CI |
| Réseau 10 Mbit/s, latence 100 ms | Objectifs froid < 5 s et chaud < 3 s non qualifiés ; mesurer séparément local et Pages, compression HTTP et moteur Flutter compris |
| p95 des frames à 60 Hz | Objectif 16,7 ms non qualifié sur appareils de référence ; ne pas le déduire des durées des tests |
| Mémoire après vingt changements | Reste à profiler en build release sur Windows et Android ; observer images, joueurs audio et workers/isolate |
| Signature Android de production | Configuration prête ; aucun secret de production ni artefact signé validé pendant ce chantier |
| CI hébergée | Workflow écrit ; exécution des runners Linux/Windows/Android à vérifier sur le dépôt distant |

Le chantier ne peut être déclaré intégralement qualifié tant que ces lignes ne
disposent pas de résultats datés, associés à un candidat et à un appareil précis.
Les tests automatisés locaux et les builds sont consignés dans les preuves du
candidat ; aucune publication distante n’a été déclenchée depuis ce chantier.

## Retour arrière

La copie initiale locale inclut le code, les tests, les références, la configuration
Web/CI et les empreintes des fichiers audités. Les originaux graphiques et anciennes
clés de sauvegarde sont conservés. La CI archive les candidats avec le SHA Git ;
conserver l’artefact précédent avant toute publication et redéployer cet artefact
en cas de régression. Une migration de progression n’efface aucune ancienne clé.
La copie `tmp/implementation/baseline.zip` est une référence de sources et tests,
pas un ancien binaire qualifié. Aucun binaire précédent de production n’a été
identifié et archivé localement ; le retour à une livraison antérieure devra
utiliser son artefact CI conservé.
