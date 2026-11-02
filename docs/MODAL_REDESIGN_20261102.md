# Sélection, aperçus et fenêtres — 2 novembre 2026

Demande du propriétaire : remplacer les petits panneaux et fenêtres disparates par un rendu plus soigné, inspiré du soin des interfaces Apple, tout en conservant Manrope, Emerald et les composants Material de KIBO.

## Changements

1. **Mes annonces.** Le grand bloc de boutons sous la liste devient une barre flottante arrondie : compteur, menu d'actions et fermeture. Elle apparaît avec une transition de taille douce. Le menu ouvre une feuille dédiée, avec lignes tactiles complètes pour la vente ou le retrait. Le raccourci d'annulation redondant dans la liste est retiré. La sélection, l'archivage et les confirmations restent explicites ; aucune action n'est exécutée lors de l'ouverture du menu.
2. **Aperçu d'annonce.** Une feuille avec poignée, titre et fermeture présente une carte : photo éventuelle, titre, prix, ville et description espacés. Le statut de brouillon reste explicite. Le bouton permet de revenir au formulaire ; ouvrir l'aperçu ne publie rien.
3. **Autres fenêtres.** Apparence, villes et actions de message partagent la même surface flottante avec marges latérales, rayon de 32 px, largeur maximale de 640 px et respect du clavier et des zones système. Les confirmations et saisies utilisent un dialogue contenu à 440 px, des boutons pleine largeur et une lecture verticale. Les actions destructives sont distinguées par la couleur. Le contenu défile pendant que les commandes restent visibles dans une hauteur normale ; en espace très réduit, l'ensemble reste défilable.

`lib/core/widgets/kibo_modal.dart` centralise ces surfaces. Les appels sont harmonisés dans `main.dart`, le sélecteur de ville et les fonctions annonces, chat, favoris, modération et demandes de compte. Les callbacks, conditions de session et autorisations serveur sont conservés. Les feuilles se ferment par leur commande, le geste de retour ou le comportement de route Material existant.

## Vérification visuelle

L'exporteur des vrais widgets `tool/export_maquettes_test.dart` couvre ces références avec données fictives :

| Référence | Fenêtre |
|---|---|
| 31 | Aperçu avant publication |
| 32 | Apparence |
| 34 | Villes |
| 35 | Retrait individuel du catalogue |
| 36 | Modification de message |
| 37 | Suppression de message |
| 39 | Actions du message |
| 61 | Barre de sélection |
| 62 | Actions de sélection |
| 63 | Confirmation groupée |
| 64 | Confirmation de transfert des favoris |
| 65 | Confirmation de blocage |
| 66 | Confirmation d'effacement du brouillon |

Les ombres sont activées dans l'exporteur pour éviter les anneaux gris du mode de diagnostic Flutter et examiner le rendu réel des élévations.

Catalogues locaux ignorés par Git : `.dart_tool/modal-audit/final/index.html` (clair/sombre) et `.dart_tool/modal-audit/small/index.html` (320 px, texte à 200 %). Les anciennes maquettes suivies restent intactes.

## Contrôles

```text
dart format --output=none --set-exit-if-changed lib test tool/export_maquettes_test.dart
flutter analyze --fatal-infos
flutter test --no-pub --reporter expanded
flutter test --no-pub --reporter expanded --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true
flutter test --no-pub tool/export_maquettes_test.dart --dart-define=KIBO_UI_EXPORT_DIR=.dart_tool/modal-audit/final --dart-define=KIBO_UI_ONLY=31,32,34,35,36,37,39,61,62,63,64,65,66
flutter test --no-pub tool/export_maquettes_test.dart --dart-define=KIBO_UI_EXPORT_DIR=.dart_tool/modal-audit/small --dart-define=KIBO_UI_ONLY=31,32,34,35,36,37,39,61,62,63,64,65,66 --dart-define=KIBO_UI_WIDTH=320 --dart-define=KIBO_UI_TEXT_SCALE=200 --dart-define=KIBO_UI_LIGHT_ONLY=true
git diff --check
```

Les tests de sélection incluent le nouveau passage par le menu, la compacité du panneau, l'annulation, l'exécution confirmée et la perte de session pendant l'ouverture. `test/kibo_modal_test.dart` couvre l'action explicite, la fermeture et le dialogue avec clavier, en grande police et dans les deux thèmes.

Suites globales : **460 tests standard et 460 avec photos réussis**. Les dernières retouches de présentation ont ensuite été contrôlées par **38 tests ciblés**, puis **9 tests de sélection** avec assertions adaptées au nouveau menu ; le dernier espacement de carte a été vérifié par un nouveau rendu de l'aperçu à 200 %. Analyse stricte sans anomalie, formatage de 160 fichiers sans changement, diff relu et vérifié. **26 PNG standard + 13 en petit écran** contrôlés ; aucun débordement Flutter. Les captures de l'aperçu et du compteur ont servi à ajuster les marges et la place du titre sans réduire l'échelle de texte système.

Code applicatif conservé dans `a0b3d13`. Version 1.0.0+2 installée et relancée sur TECNO CK6n Android 14 en mode profile : compilation 53,7 s, installation 6,6 s, processus **20367**, premier plan confirmé et données conservées. La barre finale et le menu ont été inspectés en thème sombre sur l'appareil ; sélection locale ensuite annulée, retour à l'accueil. Aucune confirmation métier effectuée et aucune annonce modifiée. Les autres fenêtres sont contrôlées sur les fixtures, pas par une opération réelle sur des comptes ou annonces.

## Limites

Pas de modification Supabase ni de nouvelle fonctionnalité métier. Aucun transfert de favoris, archivage, suppression ou publication sur des données réelles n'est nécessaire à la recette visuelle. Le bundle signé antérieur reste à reconstruire avant diffusion ; le déploiement demandé concerne l'APK profile du téléphone de recette.
