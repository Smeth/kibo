# Refonte Material 3 — 2026-11-01

## Périmètre

Référence inspectée : `Maquette UI KIBO en vert Material 3.png`, fournie localement par l’utilisateur et confirmée dans la conversation. Le fichier original reste intact hors dépôt. Installation locale et profilage TECNO expressément autorisés ; aucun déploiement distant, commit ou push.

Le dépôt KIBO, `origin` et la branche `main` ont été contrôlés. Les changements préexistants, y compris les fichiers non suivis, sont conservés. Inventaire avec empreintes avant modification des sources existantes : `.dart_tool/m3-preexisting-hashes.json` (ignoré). Aucun repository, modèle, contrat serveur, configuration Supabase, route ou contrôle d’accès n’est modifié. La lecture des catégories d’accueil réutilise `ListingRepository.categories()`.

## Système visuel et écrans

- Thème M3 clair : palette `KiboColors`, Manrope locale, surfaces neutres explicites, boutons/champs, recherche, chips, navigation, menus, dialogues, feuilles, snackbars et progression. Tokens de dimensions partagés. Les libellés d’erreur utilisent le texte foncé lisible, avec le rouge sémantique conservé pour les repères d’erreur.
- Accueil : en-tête Emerald foncé, recherche directe, catégories du repository public, cartes photo/prix/localisation, accès Messages et Notifications conservés.
- Recherche : `SearchBar`, limite de 120 caractères conservée, chip Filtres ouvrant le groupe de champs, sélection active, tri, retrait individuel, remise à zéro et gestion des erreurs. Une catégorie initiale reste affichable pendant le chargement asynchrone du menu.
- Détail : galerie existante, surface de lecture arrondie, hiérarchie titre/prix/localisation, séparation et contacts existants avant description longue. Signalement et contrôles Auth inchangés.
- Publication/modification : sections repérées par icônes, indicateur des cinq champs requis, brouillons, aperçu, réorganisation des photos et validations conservés. Aucune étape bloquante ajoutée, aucune publication anticipée. Les photos restent facultatives et limitées à trois.
- Favoris/profil : état vide utile, menu de compte sous forme de cartes, transferts explicites et actions de session conservés. L’état sélectionné du cœur est exposé aux lecteurs d’écran.
- Chat/notifications/Mes annonces : surfaces et contrôles du thème, bulles différenciées dans le chat, listes construites à la demande. Les autres écrans existants (authentification, comptes, contacts, commentaires, modération) héritent du thème commun sans changement de leurs contrats.
- Navigation : mêmes cinq destinations et callbacks, action Publier en vert, adaptation aux grands caractères conservée.

## Performance : protocole reproductible

`tool/material_benchmark.dart` est une entrée distincte, sans client Supabase, stockage local, identifiant réel ni écriture métier. Deux interfaces de test du dépôt sont réutilisées ; aucune dépendance ajoutée. Un serveur HTTP uniquement sur loopback fournit des images JPEG fictives de 1600 × 1200. Une fixture de 200 annonces constitue une charge volontairement supérieure à la page serveur de 20, qui reste inchangée dans l’application normale.

Mode **profile**, TECNO CK6n Android 14, Impeller/Vulkan, écran annoncé 60 Hz. Trois répétitions par version ; chacune comprend trois défilements aller-retour à 2400 px, ouvertures/retours du détail et changements Accueil/Recherche. Un échauffement initial de trois secondes précède la mesure, puis le cache d’images est vidé avant chaque répétition. `FrameTiming` mesure les temps de construction et de rasterisation ; les marqueurs JSON sont filtrés depuis le seul processus du banc. Le cache d’images est une mesure du cache Flutter, **pas** de la mémoire totale du processus.

Commande : `flutter run --profile -t tool/material_benchmark.dart -d <TECNO> --no-resident --no-pub --dart-define=KIBO_BENCH_VERSION=before` ; même commande avec `after` après refonte. Journaux locaux ignorés `.dart_tool/m3-benchmark-{before,after}-build.log` et `-results.log`.

| Avant | Frames | Construction p95 ms | Rendu p95 ms | Frames dépassant 16,67 ms sur un des deux temps | Cache images |
|---|---:|---:|---:|---:|---:|
| Répétition 1 | 968 | 10,260 | 5,896 | 12 | 76 982 400 octets |
| Répétition 2 | 896 | 18,678 | 15,706 | 91 | 76 982 400 octets |
| Répétition 3 | 728 | 24,802 | 20,268 | 269 | 76 982 400 octets |

Optimisations structurelles : `SliverList.builder` dans le catalogue, suppression de `IntrinsicHeight` pour chaque rangée, `ListView.builder` dans Favoris/Mes annonces/conversations/messages et slivers à la demande pour les notifications. Les cartes d’une rangée peuvent avoir des hauteurs différentes selon leur texte ; les photos restent alignées, sans troncature du contenu. Le décodage utilise la largeur réellement contrainte × DPR, plafonnée à 1600, et conserve les caches Flutter/URLs signées existants.

| Après, première passe | Frames | Construction p95 ms | Rendu p95 ms | Frames dépassant 16,67 ms sur un des deux temps | Cache images |
|---|---:|---:|---:|---:|---:|
| Répétition 1 | 970 | 10,865 | 6,018 | 17 | 17 173 392 octets |
| Répétition 2 | 851 | 19,139 | 16,136 | 98 | 17 173 392 octets |
| Répétition 3 | 658 | 28,604 | 20,225 | 312 | 17 173 392 octets |

Le cache mesuré baisse de **77,7 %**. En revanche, le temps de construction p95 de la troisième répétition augmente de **15,3 %** ; les frames dépassant le budget représentent 372/2592 avant et 427/2479 après sur l’ensemble des séquences. **La préservation de la fluidité n’est donc pas démontrée ; une régression est observée dans ces conditions.** Elle ne doit pas être masquée par le gain de cache ou par les tests fonctionnels réussis. La chauffe, l’ordonnancement du téléphone et les diagnostics Vulkan peuvent influencer les résultats ; leur causalité n’a pas été établie. Un second lancement après repos est contrôlé séparément, sans remplacer les résultats ci-dessus.

Second lancement après une période d’inactivité, journal `.dart_tool/m3-benchmark-after-repeat-results.log` : p95 construction **12,315 / 17,439 / 26,603 ms**, p95 rendu **6,033 / 14,407 / 19,228 ms**, dépassements **15/970, 77/876, 253/658** ; cache toujours 17 173 392 octets. Les résultats varient dans les deux sens selon la répétition. Ce contrôle ne permet pas d’attribuer la différence à la chauffe, ni de lever la réserve de fluidité. Ces deux séries précèdent la simplification finale du groupe de filtres ; une mesure `after-final` porte sur le code figé.

| Version finale `after-final` | Frames | Construction p95 ms | Rendu p95 ms | Dépassements du budget | Cache images |
|---|---:|---:|---:|---:|---:|
| Répétition 1 | 973 | 10,246 | 5,377 | 11 | 17 173 392 octets |
| Répétition 2 | 857 | 22,808 | 19,070 | 136 | 17 173 392 octets |
| Répétition 3 | 649 | 30,369 | 20,477 | 263 | 17 173 392 octets |

Journal `.dart_tool/m3-benchmark-final-results.log` ; compilation/lancement profile code 0 dans `m3-benchmark-final-build.log`. La première répétition est comparable au départ avant refonte, mais les suivantes se dégradent : la troisième construction p95 augmente de **22,4 %** face à la troisième mesure avant. Le total des dépassements est **410/2479 (16,5 %) contre 372/2592 (14,4 %)**. Cette mesure finale ne lève pas la réserve : le gain de cache est établi sur la fixture, **pas une garantie de fluidité conservée**. La priorité avant diffusion est un diagnostic CPU/GPU/Vulkan, avec essais de durée, ordre des versions et conditions thermiques contrôlés. Aucune modification du moteur ou des réglages système n’a été faite pour masquer ces résultats.

## Vérifications fonctionnelles et visuelles

Sur le code figé :

- `dart format --output=none --set-exit-if-changed lib test tool/material_benchmark.dart tool/material_previews_test.dart` : **116 fichiers, aucun changement nécessaire**.
- `flutter analyze --no-pub --fatal-infos` : **aucune anomalie**, journal `.dart_tool/m3-final-analyze.log`.
- `flutter test --no-pub --reporter expanded` : **339 tests réussis**, journal `.dart_tool/m3-final-tests.log`.
- Même suite avec `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` : **339 tests réussis**, journal `.dart_tool/m3-final-photos-tests.log`.
- Générateur explicite `flutter test --no-pub tool/material_previews_test.dart --dart-define=KIBO_CAPTURE_UI_PREVIEWS=true` : **1 scénario d’aperçus réussi**, distinct des 339 tests fonctionnels.
- Sept aperçus fictifs Manrope/Material Icons inspectés : accueil, carte à texte doublé, détail, publication, profil, favoris, recherche. PNG ignorés sous `.dart_tool/uiux-previews/`. La capture Recherche a été régénérée après suppression de la commande de filtre en double.
- Les tests responsive existants sont conservés : petits écrans 320/360 px, texte jusqu’à ×3 selon les scénarios, tablette 800 px, navigation complète, défilement, clavier et erreurs. Les cinq nouveaux tests couvrent les contrastes de la charte, le montage borné de 200 annonces, l’ouverture du filtre par catégorie, la recherche et ses filtres, la résolution photo selon le composant.

Les tests ont permis de corriger le menu de catégorie initialement sélectionné avant chargement et de replacer la modification du profil près de l’identité. Les tests adaptés continuent de vérifier les comportements, avec défilement explicite et le composant `SearchBar` à la place du `TextField`. Aucun test de permission n’a été supprimé ou assoupli.

`git diff --check` : **code 0** ; diff relu, fichiers nouveaux compris, aucune disparition dans l’inventaire préexistant. Les avertissements Git de conversion LF/CRLF concernent la configuration du poste, sans erreur de whitespace.

Application normale réellement restaurée avec la configuration locale existante et les photos activées : `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/Launch-KiboAndroid.ps1 -DeviceId H6929CK6NU012345` (option limitée à ce processus, aucun réglage Windows persistant modifié). **Code 0**, entrée `lib/main.dart` en mode debug, build 29,4 s, installation 6,4 s, synchronisation 1 188 ms, **processus 2742 et premier plan confirmés**. Ces durées d’outillage ne sont pas des mesures de performance d’exécution. Aucun effacement, désinstallation ou donnée de recette distante.

Accueil réel inspecté après contrôle du premier plan avant/après capture : en-tête, catégories du serveur, photos, prix et cinq destinations visibles. Capture locale ignorée `.dart_tool/m3-device-final-ed80c6be016149fe9c20c4a6e9938cc6.png`. Aucun favori, contact ou autre action métier cliqué pendant ce contrôle. Ce constat visuel ne vaut pas recette réelle des parcours authentifiés ou validation prolongée de la fluidité.

## Écarts assumés et limites

- La charte du dépôt prime : wordmark sans sac ajouté, vert exact, Manrope, XAF et Brazzaville. Pas de villes camerounaises, date inventée, « 8 photos », partage ou scanner fictif. Le modèle actuel n’expose pas de date publique utilisable ; elle n’est pas ajoutée à l’interface.
- Aucun onboarding, thème sombre ou assistant de publication en étapes n’est créé : ce serait un changement de parcours. L’avancement informe sans modifier les règles de validation.
- La maquette est une référence, pas un golden pixel par pixel. Les textes complets et les zones tactiles accessibles prennent davantage de place. Les photos réelles restent celles des annonces ; aucun visuel commercial de la maquette n’est injecté.
- Le benchmark ne mesure ni réseau mobile, ni service de signatures distant, ni temps serveur, ni mémoire totale, ni délai humain d’ouverture. Les métriques sont agrégées sur la séquence ; elles ne constituent pas des latences séparées par écran. Le taux de rafraîchissement peut varier et l’échauffement du téléphone n’est pas contrôlé. Les fortes variations entre répétitions interdisent une garantie générale sur tous les appareils.
- Un diagnostic Impeller d’allocation Vulkan a été observé au démarrage des deux versions ; les répétitions ont ensuite produit leurs marqueurs. Il reste à surveiller sur une utilisation prolongée, sans le confondre avec un succès graphique universel. Une lecture thermique après les mesures indique un statut global 0, mais des sondes CPU/GPU à 58,1 °C : cela documente le contexte sans prouver un throttling ni expliquer la régression.
- La recette réelle avec deux comptes dédiés reste différée selon la demande utilisateur. Aucune annonce, conversation, notification ou donnée Auth de recette réelle créée.
- Les commentaires et la file de modération héritent du thème ; leur comportement sous forte charge n’a pas fait l’objet d’une mesure séparée. Une validation des parcours sensibles et d’un usage prolongé reste nécessaire avant diffusion du MVP.

## Fichiers de ce lot

`lib/core/theme/{kibo_theme.dart,kibo_tokens.dart}` ; `lib/core/widgets/{kibo_bottom_navigation.dart,kibo_section.dart,kibo_state_panel.dart}` ; `lib/main.dart` ; `lib/features/listings/{category_shortcuts.dart,catalogue_search_form.dart,listing_feed.dart,listing_photo_widgets.dart,listing_detail_page.dart,publish_listing_page.dart,edit_listing_page.dart,my_listings_page.dart}` ; `lib/features/favorites/{favorite_button.dart,favorites_page.dart}` ; `lib/features/auth/profile_page.dart` ; `lib/features/chat/chat_page.dart` ; `lib/features/safety/safety_page.dart`.

Tests : `test/theme/material3_test.dart` (contraste, paresse du catalogue, catégorie vers recherche, limite/soumission/filtres, résolution photo), adaptations de composants et défilement dans `test/listings/{direct_publication_flow_test.dart,mvp_discovery_test.dart}`, `test/favorites/favorites_widgets_test.dart` et `test/auth/auth_widgets_test.dart`.

Outillage : `tool/material_benchmark.dart`, `tool/material_previews_test.dart` (aperçus fictifs explicites, hors suite fonctionnelle). Suivi : ce document, `docs/UI_THEME.md`, `docs/PROGRESS.md`, `docs/NEXT_TASK.md`.
