# Papatte Parc — Design détaillé

## 1. Direction générale

L’interface doit évoquer un carnet de naturaliste vivant : formes arrondies, aplats colorés, textures légères de papier et végétation stylisée. Le rendu est en 2D, vu du dessus, avec une profondeur discrète obtenue par les ombres et les superpositions.

La grille reste l’objet principal. Le décor crée l’univers autour d’elle, mais aucun détail illustratif ne doit être confondu avec un indice, une balise ou une case interactive.

## 2. Principes visuels

- Silhouettes simples et reconnaissables à petite taille.
- Formes généreuses, coins arrondis et ombres courtes.
- Contrastes forts sur les informations de jeu, plus doux sur le décor.
- Aucun état transmis uniquement par la couleur.
- Animations courtes pendant la réflexion, plus expressives à la fin d’une mission.
- Un seul biome par partie ; plusieurs espèces sont possibles lorsqu’elles partagent une zone du parc.

## 3. Palette commune

| Usage | Couleur | Rôle |
|---|---|---|
| Ciel clair | `#EAF8F3` | Fond principal lumineux |
| Feuille profonde | `#245B4A` | Texte principal et contours |
| Feuille vive | `#48A868` | Action principale et succès |
| Soleil | `#FFD166` | Balises et accents |
| Terre douce | `#8D6E63` | Éléments secondaires |
| Corail | `#EE6C62` | Alerte non violente |
| Blanc chaud | `#FFFDF5` | Cartes et cases révélées |
| Ombre | `#183D32` à 18 % | Séparation des plans |

Chaque biome ajoute deux ou trois couleurs décoratives, sans changer la signification des couleurs fonctionnelles. Les indices utilisent une gamme fixe et contrastée ; leur chiffre reste toujours visible.

## 4. Typographie et iconographie

- Titres : police ronde et chaleureuse, graisse 700.
- Interface et nombres : sans-serif très lisible, graisse 600 ou 700.
- Texte courant : graisse 400 ou 500.
- Nombres de la grille : chiffres tabulaires, centrés, jamais remplacés par une icône.
- Icônes : trait arrondi homogène, forme pleine uniquement pour les états importants.

Icônes principales :

- jumelles : observer ;
- balise jaune avec petite feuille : protéger ;
- patte : animal ou indice de présence dans les explications ;
- chronomètre : temps ;
- carte pliée : nouvelle mission ;
- flèche circulaire : entraînement sur la même mission.

## 5. Composition des écrans

### Accueil

Ordre de lecture :

1. Logo **Papatte Parc** et signature « Observe. Déduis. Protège. » ;
2. courte phrase : « Localise les animaux sans les effrayer. Chaque mission se résout sans hasard. » ;
3. trois cartes de mission ;
4. configuration personnalisée ;
5. bouton principal « COMMENCER LA MISSION ».

Chaque carte prédéfinie montre une illustration du biome, le nom de la mission, la taille de la grille et le nombre d’animaux. La carte sélectionnée reçoit un contour vert épais et une coche ; la couleur seule ne suffit pas.

La configuration personnalisée contient « Largeur », « Hauteur » et « Animaux ». Une saisie invalide désactive le bouton principal et affiche immédiatement le motif sous les champs.

### Mission

Le bandeau supérieur contient :

- retour vers l’accueil ;
- nom court de la mission ;
- compteur « À localiser : N » avec l’icône de balise ;
- chronomètre ;
- rappel contextuel des commandes.

La grille est centrée lorsque sa taille le permet. Elle devient défilable horizontalement et verticalement lorsqu’une case passerait sous la taille minimale de 48 px.

Sur téléphone, le rappel des commandes est condensé en « Toucher : observer · Appui long : baliser ». Le glissement déplace la grille sans agir sur une case.

### Construction du refuge

Après le premier toucher, un voile translucide affiche « Préparation du refuge… ». Une animation de feuilles suit une boucle douce. Le plateau et les commandes sont bloqués jusqu’à la fin de la génération.

### Fin de mission

Une carte modale conserve le plateau visible derrière elle.

En cas de réussite :

- titre « REFUGE SÉCURISÉ ! » ;
- phrase « Tous les animaux ont été localisés. L’équipe peut intervenir. » ;
- espèce, dimensions, nombre d’animaux et temps ;
- mention « Nouveau meilleur temps ! » si nécessaire ;
- actions « Explorer un nouveau refuge », « Revoir cette mission » et « Accueil ».

En cas d’erreur :

- titre « UN ANIMAL S’EST ÉLOIGNÉ » ;
- phrase « Ce secteur abritait un animal. Observe les indices avant de t’en approcher. » ;
- plateau montrant les positions réelles et les balises incorrectes ;
- mêmes actions, avec « Revoir cette mission » mis en avant.

## 6. Design de la grille

Une case conserve la même géométrie dans tous les biomes. Seules sa texture légère et ses petits éléments de bord changent.

| État | Apparence | Animation | Son |
|---|---|---|---|
| Inexploré | Tuile végétale, volume léger | Balancement presque imperceptible | Aucun |
| Survol/focus | Contour blanc et légère élévation | 100 ms | Clic très discret |
| Révélé vide | Sol clair, sans symbole central | Ouverture en 120 ms | Froissement doux |
| Révélé avec indice | Sol clair et grand chiffre | Chiffre après l’ouverture | Note courte |
| Balise posée | Balise jaune + contour plein | Petit déploiement en 150 ms | Tintement de bois |
| Balise incorrecte | Balise barrée + contour corail | Aucun tremblement agressif | Deux notes descendantes |
| Animal révélé à la fin | Silhouette de l’espèce | Apparition douce | Cri animal très léger |
| Animal effrayé | Traces quittant la case | Départ vers le bord en 400 ms | Bruissement |

L’animal n’apparaît pas au moment de poser une balise : la position reste une déduction jusqu’à la validation finale.

## 7. Indices

Les indices affichent toujours un chiffre de 1 à 8. Leur couleur améliore le repérage mais ne remplace pas le chiffre :

| Indice | Couleur |
|---:|---|
| 1 | `#2878B8` |
| 2 | `#2E8B57` |
| 3 | `#D95D4F` |
| 4 | `#6656A3` |
| 5 | `#A75536` |
| 6 | `#168A8A` |
| 7 | `#38404A` |
| 8 | `#7A4D7D` |

Une case vide n’affiche ni zéro ni symbole. Les couleurs doivent être vérifiées sur le fond clair des cases révélées.

## 8. Déclinaisons des biomes

### Clairière des lapins

- Palette : verts tendres, fleurs jaunes, ciel crème.
- Cases inexplorées : touffes d’herbe.
- Animal : lapin brun ou blanc, oreilles lisibles.
- Ambiance : oiseaux matinaux et brise légère.

### Canopée des toucans

- Palette : émeraude, turquoise, orange et rose.
- Cases inexplorées : grandes feuilles superposées.
- Animal : toucan au bec coloré.
- Ambiance : gouttes, insectes doux et feuillage.

### Banquise des manchots

- Palette : bleu glacier, bleu nuit, blanc et corail.
- Cases inexplorées : plaques de neige arrondies.
- Animal : jeune manchot en silhouette noir et blanc.
- Ambiance : vent feutré et petits craquements de glace.

### Réserve libre

- Palette : sauge, ocre et bleu clair.
- Cases inexplorées : mosaïque végétale neutre.
- Animal : hérisson, silhouette compacte.
- Ambiance : prairie calme.

## 9. Mouvement et retour d’action

- Survol/focus : 80 à 120 ms.
- Révélation d’une case : 120 ms.
- Propagation des cases vides : vague de 20 ms entre couronnes, plafonnée à 350 ms.
- Pose ou retrait d’une balise : 150 ms.
- Ouverture d’une modale : 180 ms.
- Célébration : 1,5 à 2,5 s, interruptible par les boutons.

L’état logique est appliqué avant l’animation. Les entrées visant une case déjà en animation sont ignorées jusqu’à son état final, sans retarder le reste de l’interface.

Les animations décoratives sont désactivées avec l’option « Réduire les animations ». Les informations restent alors instantanées.

## 10. Son

La musique est douce, instrumentale et peu dense. Elle ne doit pas accélérer avec le temps.

- Une boucle par biome, sans rupture audible.
- Sons d’interface courts et non métalliques.
- Signaux différents pour observer, baliser et retirer une balise.
- Échec sans explosion ni cri de détresse.
- Victoire chaleureuse, limitée à quelques secondes.

Le jeu doit rester entièrement compréhensible sans son.

## 11. Texte et ton

Le joueur est tutoyé. Les phrases décrivent l’action ou la conséquence, jamais une faute morale.

| Situation | Texte |
|---|---|
| Instruction | « Touche un secteur pour commencer l’observation. » |
| Balise avant le premier coup | « Observe d’abord un secteur pour préparer le refuge. » |
| Plus de balise disponible | « Toutes les balises sont déjà placées. » |
| Génération impossible | « Ce refuge ne peut pas être préparé. Choisis moins d’animaux. » |
| Abandon | « Quitter la mission en cours ? » |
| Réussite | « Tous les animaux sont en sécurité. » |
| Échec | « Un animal s’est éloigné. Tu peux revoir cette mission. » |
| Entraînement | « Entraînement : ce temps ne compte pas pour le record. » |

## 12. Accessibilité et adaptation

- Taille tactile minimale : 48 × 48 px.
- Navigation clavier complète avec focus visible de 3 px minimum.
- Validation par `Entrée` ou `Espace`, balise par touche dédiée ou menu contextuel.
- Contraste minimal visé : 4,5:1 pour les textes essentiels.
- Forme propre pour chaque état important ; aucune dépendance exclusive à la couleur ou au son.
- Option de réduction des animations.
- Textes compatibles avec un agrandissement à 200 % hors nombres de grille.
- Défilement de la grille sans déclencher de case.
- Appui long fixé à 450 ms et annulé dès qu’un glissement dépasse 12 px.

## 13. Garde-fous de lisibilité

- Pas d’empreintes décoratives dans les cases : elles seraient confondues avec les indices.
- Pas de personnage animé au-dessus de la grille pendant la partie.
- Pas de particules persistantes sur les nombres.
- Pas de variation de forme ou de position des chiffres entre les biomes.
- Pas de texte narratif pendant une séquence de déduction.
- Les animaux révélés à la fin ne masquent jamais les balises incorrectes.

