# Revue UI/UX des écrans — 2 novembre 2026

## Périmètre

Revue des vrais widgets Flutter, avec Manrope et des données fictives : 60 écrans, positions de défilement et états de parcours. Ce nombre inclut les variantes d'une même page, pas 60 pages distinctes. Rendu standard de 393 × 852 en clair et sombre ; contrôle complémentaire à 320 × 852 avec texte à 200 %. Les tests ciblés utilisent aussi 320 × 640, un clavier de 260 px et une marge système basse de 24 px.

L'exporteur `tool/export_maquettes_test.dart` couvre désormais les écrans récents et utilise un faux client pour la sécurité et les signalements. Aucun envoi, enrôlement TOTP, modification Supabase ou suppression réelle n'est nécessaire à cette revue. L'OTP est montré uniquement comme écran préparé et reste désactivé dans l'application pilote.

## Parcours examinés

| Parcours | Références dans le catalogue | Points contrôlés / corrections |
|---|---|---|
| Accueil, recherche, filtres, erreur réseau | 01–03, 33 | Alignement des commandes, retour visuel, compteur sans chevauchement avec les autres raccourcis |
| Détail d'annonce et galerie consultable | 04 | Marges de détail à 16 px, titre adaptable, navigation photo et actions de contact |
| Favoris et proposition de transfert | 05, 60 | Carte verticale sur écran étroit avec texte agrandi ; espacement entre texte de consentement, boutons et première annonce. Dernier cas relevé pendant la revue du téléphone, ajouté aux fixtures sans effectuer de transfert réel |
| Profil connecté et visiteur | 06–07, 51 | Aide alignée avec le formulaire visiteur ; déconnexion en dernière position, visuellement secondaire après les réglages et l'aide |
| Inscription, connexion, mots de passe | 08, 24–25, 30, 53, 58–59 | Marges communes, titres longs, champs et actions accessibles avec clavier |
| Publication, photos, aperçu et brouillon | 09–10, 31, 55 | Espacement des sections, ordre des photos, commandes du brouillon et publication en bas de formulaire |
| Mes annonces, modification, archivage | 11–12, 35, 38, 56 | Titre adaptable, formulaire complet, absence de photo et dialogue d'archivage |
| Conversations et messages | 13–15, 36–37, 39, 54 | État vide, texte, menus et confirmations, clavier ouvert ; place réservée aux compteurs |
| Notifications, signalement d'annonce, modération | 16–18 | Titres adaptables et lecture des commandes, états et formulaires |
| Commentaires et réponses | 19–20 | Formulaires, actions, cartes et absence de réponses |
| Vendeur et coordonnées de contact | 21–22 | Titres longs sans concurrence avec les actions, coordonnées et consentements |
| Édition du profil | 23 | Alignement du nom, ville, sauvegarde et annulation |
| Compte, blocages et demande de suppression | 26–27, 29, 57 | Marges communes, défilement et titres lisibles |
| Préférences de notifications | 28 | Interrupteurs alignés sur le texte et le bouton de sauvegarde |
| Apparence | 32 | Choix clair, sombre et système ; retour à la ligne en texte agrandi |
| Sélection de ville | 34 | Recherche, liste et commandes de fermeture |
| Aide et confidentialité | 40, 52 | Hiérarchie des sections, espacement, défilement ; retour explicite si navigateur ou application email indisponible |
| Sécurité TOTP | 41 | Hiérarchie de la protection du compte, espacement des commandes et saisie du code |
| Alertes Android | 42 | État indisponible identifié par un panneau explicite ; aucune activation Firebase |
| Signalement de profil et message | 43–44 | Espacement commun et défilement au clavier, sans modifier les protections de session |
| Échanges conservés et conversation archivée | 45–46 | Filtres en puces pouvant passer à la ligne ; marge système basse respectée |
| Gestion des photos publiées | 47 | Photo entière en aperçu, commandes centrées, marges et protection de la zone système |
| Administration et demandes opérateur | 48–49 | Titre séparé des commandes en grande police, panneaux et file de demandes |
| Connexion téléphone préparée | 50 | Lisibilité et disposition uniquement ; fournisseur SMS toujours exclu |

## Corrections communes

- `KiboAppBar` mesure le titre avec la police et l'agrandissement réels. Les titres longs passent sur plusieurs lignes ; en grande police, ils disposent d'une ligne de contenu distincte sous le retour et les actions, afin de préserver leur largeur.
- Les formulaires partagent une marge de 16 px et respectent la zone système basse. Le défilement permet de retrouver les actions quand le clavier est ouvert.
- Les pages aide, sécurité, push et signalement utilisent les mêmes composants d'espacement. Aucun changement de règles métier ou de permissions serveur.
- Les aperçus de gestion de galerie utilisent `BoxFit.contain` ; le recadrage des vignettes du catalogue est conservé.

## Reproduction et preuves

Exécuter avec le SDK Flutter local, sans afficher la configuration privée :

```text
dart format lib test tool/export_maquettes_test.dart
flutter analyze --fatal-infos
flutter test --no-pub --reporter expanded
flutter test --no-pub --reporter expanded --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true
flutter test --no-pub tool/export_maquettes_test.dart --dart-define=KIBO_UI_EXPORT_DIR=.dart_tool/ui-audit/final
flutter test --no-pub tool/export_maquettes_test.dart --dart-define=KIBO_UI_EXPORT_DIR=.dart_tool/ui-audit/small-final --dart-define=KIBO_UI_WIDTH=320 --dart-define=KIBO_UI_TEXT_SCALE=200 --dart-define=KIBO_UI_LIGHT_ONLY=true
git diff --check
```

Le catalogue HTML, les PNG et le manifeste sont générés dans le répertoire demandé, ignoré par Git. Les anciennes maquettes suivies restent intactes. `KIBO_UI_ONLY` permet de rejouer un ou plusieurs préfixes de références séparés par une virgule. Les simulations de clavier sont des rendus Flutter, pas des captures d'un clavier Android réel.

Validation finale : **454 tests standard et 454 tests avec photos réussis**, analyse stricte conforme, formatage de 158 fichiers sans changement et diff vérifié. Les trois tests d'accessibilité supplémentaires sont inclus dans ces suites. **120 rendus standard + 60 rendus à 320 px/texte 200 %** consolidés, sans erreur Flutter ; les cas Google et transfert des favoris ont été rejoués séparément puis intégrés aux catalogues. Les anciens fichiers de maquette suivis ne sont pas remplacés.

Version applicative `520be4f`, 1.0.0+2, installée et relancée sur TECNO CK6n Android 14 en mode profile : compilation 47,5 s, installation 6,7 s, processus **18878**, premier plan confirmé. Données conservées. Accueil, favoris et profil/fin de profil examinés sur l'appareil ; la dernière capture des favoris confirme l'espacement du transfert sans effectuer cette action. Application laissée sur l'accueil. La revue des 60 vues est celle des widgets sur fixtures ; elle ne constitue pas une visite physique de chacun des 60 états.

Fichiers : composants communs `lib/core/widgets/kibo_app_bar.dart` et `kibo_form_layout.dart`, pages et menus sous `lib/features/`, aperçu photo `listing_photo_widgets.dart`, nouveau test `test/kibo_screen_accessibility_test.dart`, exporteur `tool/export_maquettes_test.dart`, et documents de suivi. Catalogues locaux : `.dart_tool/ui-audit/final/index.html` et `.dart_tool/ui-audit/small-final/index.html`. Les captures du téléphone restent locales et ignorées par Git.

## Limites

La revue visuelle de fixtures ne prouve pas le fonctionnement réseau, le parcours Google dans un navigateur externe, les notifications Firebase ni une recette à deux comptes sur deux téléphones. L'enregistrement personnel du TOTP reste à réaliser par le propriétaire. Les contrôles serveur déjà déployés ne sont pas modifiés dans ce lot.

Le bundle pilote signé précédemment généré précède ce lot UI/UX. Il devra être reconstruit avant une nouvelle diffusion ; l'APK profile du téléphone contient bien les corrections présentes.
