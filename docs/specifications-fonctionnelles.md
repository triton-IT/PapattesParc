# Papatte Parc — Spécifications fonctionnelles détaillées

## 1. Objet

Ce document décrit le comportement attendu de la première version jouable de **Papatte Parc**. Il couvre la configuration, la génération, la partie, les états d’interface, les résultats et la persistance locale.

Les termes « animal », « indice » et « balise » sont normatifs dans l’interface. Les noms techniques historiques liés au démineur peuvent rester internes afin de limiter la portée de l’adaptation, mais ne doivent jamais être exposés au joueur.

## 2. Glossaire

| Terme | Définition |
|---|---|
| Refuge | Grille complète d’une partie |
| Secteur | Case de la grille |
| Secteur sûr | Secteur qui ne contient pas d’animal |
| Animal | Élément caché que le joueur doit localiser |
| Indice | Nombre exact d’animaux dans les secteurs voisins |
| Balise | Marque posée par le joueur sur un animal supposé |
| Observation | Révélation d’un secteur |
| Mission standard | Partie sur une nouvelle grille, éligible au record |
| Entraînement | Reprise de la grille précédente, non éligible au record |

## 3. Périmètre

La version comprend :

- un écran d’accueil ;
- trois missions prédéfinies ;
- une configuration personnalisée ;
- une grille générée à partir du premier secteur observé ;
- des grilles certifiées résolubles sans hasard ;
- l’observation, la propagation automatique et les balises ;
- un chronomètre et un meilleur temps local ;
- les fins de mission réussie et interrompue ;
- la reprise de la même grille en entraînement ;
- la souris, le tactile et le déplacement d’une grande grille.

Sont hors périmètre :

- comptes, synchronisation en ligne et classement ;
- collection persistante d’animaux ;
- achats, monnaie et récompenses quotidiennes ;
- indices automatiques et résolution assistée ;
- sauvegarde d’une mission en cours ;
- annulation d’un coup ;
- plusieurs espèces sur une même grille.

## 4. Configuration

### SF-001 — Valeurs initiales

Au premier affichage, la mission **Clairière des lapins** est sélectionnée avec une grille de 9 × 9 et 10 animaux. Le bouton de démarrage est actif.

### SF-002 — Missions prédéfinies

| Identifiant | Nom | Largeur | Hauteur | Animaux |
|---|---|---:|---:|---:|
| `beginner` | Clairière des lapins | 9 | 9 | 10 |
| `intermediate` | Canopée des toucans | 16 | 16 | 40 |
| `expert` | Banquise des manchots | 30 | 16 | 99 |

Sélectionner une mission recopie ses trois valeurs dans la configuration et sélectionne son biome.

### SF-003 — Configuration personnalisée

Les champs n’acceptent que des nombres entiers :

- largeur : de 5 à 30 ;
- hauteur : de 5 à 30 ;
- animaux : de 1 à `(largeur × hauteur) - 9`.

Toute modification manuelle sélectionne la **Réserve libre**. La validation s’effectue à la saisie, avant le démarrage :

- si une valeur n’est pas un entier : « Saisis trois nombres entiers. » ;
- si une dimension est hors limites : « La largeur et la hauteur doivent être comprises entre 5 et 30. » ;
- si le nombre d’animaux est hors limites : « Le nombre d’animaux doit être compris entre 1 et N. ».

Tant que la configuration est invalide, le bouton « COMMENCER LA MISSION » est désactivé. Aucune correction automatique des valeurs n’est effectuée.

## 5. États de l’application

| État | Écrans actifs | Entrées de grille |
|---|---|---|
| `Accueil` | Accueil | Interdites |
| `En attente` | Mission, grille couverte | Première observation seulement |
| `Préparation` | Mission + voile de chargement | Interdites |
| `En cours` | Mission | Autorisées |
| `Terminée` | Mission + résultat | Interdites |
| `Confirmation de sortie` | Mission + confirmation | Interdites |

Transitions :

- Accueil → En attente : configuration valide puis démarrage ;
- En attente → Préparation : première observation ;
- Préparation → En cours : génération réussie ;
- Préparation → Accueil : génération impossible ;
- En cours → Terminée : réussite ou animal effrayé ;
- En cours → Confirmation de sortie : demande de retour ;
- Confirmation → En cours : continuer ;
- Confirmation → Accueil : quitter ;
- Terminée → En attente : nouvelle grille ;
- Terminée → En cours : même grille en entraînement ;
- Terminée → Accueil : accueil.

## 6. Génération du refuge

### SF-010 — Déclenchement

La grille logique n’est générée qu’après la première observation. La position choisie devient le point de départ de la génération.

### SF-011 — Zone initiale protégée

Le secteur choisi et tous ses voisins existants sont sûrs. La première observation révèle cette zone sûre selon la règle de propagation.

### SF-012 — Exactitude

Le refuge contient exactement le nombre d’animaux demandé. Pour chaque secteur sûr, l’indice correspond exactement au nombre d’animaux parmi ses huit voisins au maximum.

### SF-013 — Résolution sans hasard

Chaque refuge livré au joueur possède un certificat de résolution fondé uniquement sur :

- si toutes les balises voisines d’un indice égalent cet indice, les autres voisins sont sûrs ;
- si le nombre de voisins encore cachés plus les balises voisines égale l’indice, les voisins cachés contiennent des animaux ;
- si tous les animaux restants sont localisés, les autres secteurs sont sûrs ;
- si tous les secteurs non résolus doivent contenir les animaux restants, ils peuvent tous être balisés.

Une grille dont le certificat échoue n’est jamais présentée.

### SF-014 — Échec de génération

Le générateur peut effectuer au maximum 100 tentatives avec des graines distinctes. Si aucune grille certifiée n’est produite :

1. la mission n’est pas créée ;
2. le joueur revient à l’accueil ;
3. le message « Ce refuge ne peut pas être préparé. Choisis moins d’animaux. » est affiché ;
4. aucune partie ni aucun temps n’est enregistré.

## 7. Interaction avec la grille

### SF-020 — Observer

Le clic gauche ou le toucher bref observe un secteur. L’action est ignorée si le secteur est déjà révélé, possède une balise ou si la mission n’est pas interactive.

Observer un secteur sûr le révèle. Observer un secteur contenant un animal termine immédiatement la mission avec l’état « animal effrayé ».

### SF-021 — Propagation

Lorsqu’un secteur révélé possède un indice égal à zéro, tous ses voisins sûrs non révélés et non balisés sont révélés. La propagation continue à partir de chaque nouveau secteur d’indice zéro jusqu’à sa frontière d’indices non nuls.

Une balise incorrecte bloque la propagation sur son secteur jusqu’à son retrait.

### SF-022 — Poser une balise

Le clic droit ou l’appui long de 450 ms bascule la balise d’un secteur caché :

- sans balise → balisé ;
- balisé → sans balise.

L’action est ignorée sur un secteur révélé ou lorsque la mission n’est pas en cours.

### SF-023 — Première action

Une balise ne peut pas être posée avant la première observation. La tentative affiche pendant deux secondes : « Observe d’abord un secteur pour préparer le refuge. »

### SF-024 — Limite des balises

Le joueur ne peut pas poser plus de balises que le nombre total d’animaux. Une tentative au-delà de cette limite ne modifie pas la grille et affiche pendant deux secondes : « Toutes les balises sont déjà placées. »

### SF-025 — Déplacement de la grille

Lorsque la grille dépasse la zone disponible, elle peut être déplacée horizontalement et verticalement. Un glissement supérieur à 12 px :

- annule l’observation en attente ;
- annule l’appui long ;
- déplace la grille ;
- ne change aucune case.

### SF-026 — Commandes clavier

Le focus se déplace entre les secteurs avec les flèches :

- `Entrée` ou `Espace` observe le secteur ciblé ;
- `B` pose ou retire une balise ;
- `Échap` ouvre la confirmation de sortie pendant une mission.

## 8. Informations de partie

### SF-030 — Compteur

Le bandeau affiche `À localiser : N`, où `N = nombre total d’animaux - nombre de balises posées`. Il peut atteindre zéro même si certaines balises sont incorrectes, mais jamais devenir négatif.

### SF-031 — Chronomètre standard

Le chronomètre :

- affiche `00:00` avant la fin de la génération ;
- démarre lorsque la grille générée devient interactive ;
- utilise le temps réel non affecté par la cadence ou la pause interne du moteur ;
- s’arrête à la fin de la mission ;
- affiche les minutes et secondes écoulées, arrondies à l’entier inférieur.

### SF-032 — Chronomètre d’entraînement

Une reprise en entraînement affiche immédiatement la première zone déjà définie. Son chronomètre reste à `00:00` jusqu’à la première observation ou pose de balise, puis suit les règles normales.

## 9. Conditions de fin

### SF-040 — Réussite

La mission est réussie si et seulement si :

1. tous les secteurs sûrs sont révélés ;
2. le nombre de balises égale le nombre d’animaux ;
3. chaque balise se trouve sur un animal.

La seule révélation de tous les secteurs sûrs ne suffit pas.

### SF-041 — Animal effrayé

Lorsqu’un animal est observé :

- le chronomètre s’arrête ;
- les entrées de grille sont bloquées ;
- tous les animaux sont révélés ;
- la position déclenchée est distinguée par des traces de départ ;
- chaque balise incorrecte est barrée ;
- la modale de résultat apparaît.

### SF-042 — Verrouillage

Après la fin, observer ou baliser ne modifie ni le plateau, ni le compteur, ni le temps.

## 10. Résultat et rejeu

### SF-050 — Résultat réussi

La modale affiche :

- « REFUGE SÉCURISÉ ! » ;
- les dimensions et le nombre d’animaux ;
- le temps final ;
- « Nouveau meilleur temps ! » lorsque le record est amélioré ;
- « Entraînement : ce temps ne compte pas pour le record. » le cas échéant.

### SF-051 — Résultat interrompu

La modale affiche :

- « UN ANIMAL S’EST ÉLOIGNÉ » ;
- « Ce secteur abritait un animal. Observe les indices avant de t’en approcher. » ;
- les dimensions, le nombre d’animaux et le temps final.

### SF-052 — Même grille

« Revoir cette mission » recrée une session vierge avec la même grille, la même position initiale et les mêmes animaux. Cette session est en entraînement et ne peut pas modifier un record.

### SF-053 — Nouvelle grille

« Explorer un nouveau refuge » conserve la configuration et le biome, revient à une grille entièrement couverte et attend un nouveau premier secteur. Une nouvelle graine est utilisée.

## 11. Persistance

### SF-060 — Meilleur temps

Un meilleur temps est conservé localement pour chaque triplet `(largeur, hauteur, animaux)`.

- Seule une mission standard réussie est éligible.
- Le premier résultat réussi devient le record.
- Un résultat ultérieur remplace le record uniquement s’il est strictement plus rapide.
- Un échec et un entraînement ne modifient jamais le record.

Le choix du biome ne fait pas partie de la clé : deux missions de même configuration partagent le même record.

### SF-061 — Données non conservées

La grille en cours, les balises, le temps courant et la dernière graine ne sont pas restaurés après fermeture de l’application.

## 12. Navigation et prévention des erreurs

### SF-070 — Retour pendant une mission

Demander l’accueil pendant une mission active ouvre une confirmation :

- « Continuer » ferme la confirmation sans modifier la mission ;
- « Quitter » abandonne la mission et retourne à l’accueil.

La grille est inactive tant que la confirmation est visible.

### SF-071 — Retour hors mission active

Depuis une mission terminée, le retour à l’accueil ne demande pas de confirmation.

### SF-072 — Actions concurrentes

Pendant la préparation, une transition ou l’affichage d’une modale, toutes les actions susceptibles de modifier la grille sont désactivées à leur source.

## 13. Adaptation et performance

### SF-080 — Taille des secteurs

La grille utilise les plus grands secteurs carrés permettant de tenir dans l’espace disponible, dans la limite de 48 à 128 px. Si la grille ne tient pas avec des secteurs de 48 px, sa taille de contenu augmente et le défilement prend le relais.

### SF-081 — Redimensionnement

Après un changement de taille ou d’orientation :

- la taille des secteurs est recalculée ;
- la grille reste dans les limites de défilement ;
- l’état logique ne change pas.

### SF-082 — Budget de génération

Sur la machine de référence, 20 grilles expertes 30 × 16 avec 99 animaux doivent être générées et certifiées en moins de cinq secondes au total.

### SF-083 — Réactivité

Hors génération, une action doit mettre à jour l’état logique dans la même image. Les animations peuvent se poursuivre sans bloquer l’action suivante sur une autre case.

## 14. Accessibilité fonctionnelle

### SF-090 — Information redondante

Les états « balisé », « incorrect », « animal » et « animal effrayé » possèdent chacun une forme distincte. Les indices restent des chiffres ; aucune information nécessaire ne dépend uniquement de la couleur, du son ou d’une animation.

### SF-091 — Réduction des animations

Une option permet de supprimer les mouvements décoratifs, la propagation en vague et les transitions longues. L’état final apparaît alors immédiatement.

### SF-092 — Absence de son

Couper tous les sons ne supprime aucun retour nécessaire à la compréhension ou à la navigation.

## 15. Scénarios de validation fonctionnelle

### VF-01 — Mission prédéfinie

1. Sélectionner « Clairière des lapins ».
2. Démarrer et observer le centre.
3. Vérifier une grille 9 × 9, exactement 10 animaux et une zone initiale sûre.
4. Rejouer le certificat par observations et balises.
5. Vérifier l’état « REFUGE SÉCURISÉ ! ».

### VF-02 — Configuration rejetée à la frontière

1. Saisir 4 × 9 avec 10 animaux.
2. Vérifier le message de dimensions et le bouton désactivé.
3. Saisir 30 × 30 avec 891 animaux.
4. Vérifier que le démarrage est autorisé.
5. Saisir 892 animaux et vérifier qu’il est interdit.

### VF-03 — Erreur sans violence

1. Commencer une mission.
2. Observer un secteur contenant un animal.
3. Vérifier l’arrêt du temps, le verrouillage de la grille, les traces de départ et le texte prévu.
4. Vérifier l’absence d’explosion, de blessure et de vocabulaire minier.

### VF-04 — Balises obligatoires

1. Révéler tous les secteurs sûrs sans poser de balise.
2. Vérifier que la mission reste en cours.
3. Baliser chaque animal.
4. Vérifier la réussite.

### VF-05 — Entraînement

1. Terminer une mission et noter son record.
2. Choisir « Revoir cette mission ».
3. Vérifier que la disposition est identique et que le temps attend la première action.
4. Réussir plus vite.
5. Vérifier que le record initial reste inchangé.

### VF-06 — Gestes tactiles

1. Effectuer un appui long sur un secteur caché et vérifier la pose d’une balise sans observation.
2. Faire glisser la grille de plus de 12 px en maintenant le toucher plus de 450 ms.
3. Vérifier qu’aucun secteur n’a été observé ou balisé.

### VF-07 — Cohérence sémantique

Parcourir l’accueil, la mission, les messages, la préparation et les deux résultats. Vérifier qu’aucun texte visible ne contient « mine », « démineur », « bombe », « explosion », « drapeau », « gagné » ou « perdu ».

