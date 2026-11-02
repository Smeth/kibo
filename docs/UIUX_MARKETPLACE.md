# Lot UI/UX marketplace — 2026-11-01

L’utilisateur a demandé de donner priorité à l’UI/UX. Trois volets réalisés en conservant les parcours et contrats existants ; aucune donnée de recette réelle créée et aucun changement Supabase/Auth/RLS. Les prototypes de suppression restent non déployés.

## Accueil, recherche et cartes

L’accueil propose une action de recherche directe vers l’onglet Recherche existant, accessible sans compte. La bannière conserve les couleurs et la signature KIBO, avec des marges resserrées et sans flèche décorative donnant l’impression que la localisation est un bouton.

Sur les cartes, la catégorie passe sous la photo et peut prendre plusieurs lignes ; elle ne masque plus l’image. Favori sur fond circulaire en haut à droite, nombre de photos en bas à gauche, prix mis en évidence et localisation secondaire. Les titres/prix restent libres de grandir, la grille conserve son adaptation au texte et les clés de navigation sont préservées.

## Détail, galerie et publication

Une galerie remplace les photos empilées : balayage, boutons précédent/suivant, compteur annoncé et retour à la première image si la liste change. La hauteur reste bornée ; l’animation respecte la préférence système de réduction des animations. Les photos continuent à utiliser les mêmes références et le service de lecture privé existant.

Prix et localisation sont hiérarchisés ; les contacts et échanges sont placés **avant la description**, même longue. Les conseils de prudence restent à proximité des contacts, le signalement après la description. Les contrôles de connexion/propriété et les routes restent ceux de l’application. Les erreurs/annonces indisponibles utilisent un panneau cohérent défilable, avec reprise sans exception technique affichée.

Le formulaire sépare Vos photos / Votre annonce / Localisation. Les outils de sauvegarde et d’effacement du brouillon sont regroupés après les champs. Le texte précise la sauvegarde locale des photos et distingue une annonce déjà créée d’un brouillon à publier. Actions clavier Suivant / Terminé adaptées, fermeture du clavier au défilement, exemples de saisie et espace entre les actions. Aucun wizard, validation supplémentaire, publication de test ou changement de persistance.

## Accessibilité et identité

Repères de titre accessibles pour les résultats, descriptions, sections de formulaire et panneaux d’état. Les cinq destinations restent visibles, avec leur comportement existant à texte agrandi. Les boutons secondaires OutlinedButton reprennent le thème : hauteur minimale 52, rayon 12, Manrope et couleurs existantes. Aucun plafonnement de la taille de texte.

L’icône Flutter de départ est remplacée par un monogramme K blanc/Emerald : vecteur Android adaptatif API 26+ et cinq tailles PNG de repli. Source reproductible dans `tool/generate_launcher_icons_test.dart`, à lancer explicitement avec Flutter ; ce générateur utilise le moteur de rendu mais n’est pas une vérification fonctionnelle et ne fait pas partie du compte des tests de test/. Aucune bibliothèque, police ni image distante ajoutée. ApplicationId et signature debug existants conservés.

## Vérifications et observations

Commandes exécutées, Flutter/Dart via le snapshot du SDK installé : `dart format lib test` ; `Validate-MvpLot.ps1 -Lot uiux-final-standard` (analyse stricte, suite complète, diff) ; `flutter test --no-pub --reporter expanded --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true --dart-define=KIBO_CAPTURE_UI_PREVIEWS=true` ; générateur explicite `flutter test --no-pub tool/generate_launcher_icons_test.dart` ; `Launch-KiboAndroid.ps1` ; `git diff --check`. DEBUG a été vidé pour les lancements SDK afin d’éviter l’affichage des paramètres Gradle. Aucun nouveau package installé.

Sept tests nouveaux : recherche publique directe ; carte longue à 320 px/texte double ; galerie par boutons et balayage ; changement de photos sans index invalide ; contacts avant longue description avec contrôle de connexion préservé ; erreur récupérable à texte triple ; sections et clavier du formulaire. 24 tests UI/responsive ciblés réussis, incluant les régressions de navigation et de grille jusqu’à texte triple.

La régression de navigation photos vérifie l’accès à la seconde image dans la galerie, au lieu d’exiger deux images visibles simultanément. Les reprises et changements de photo ont révélé des futures échouant avant le prochain frame : un gestionnaire immédiat évite une erreur non interceptée, tandis que FutureBuilder conserve le futur échoué et affiche toujours son état d’erreur. Aucun refus transformé en réussite.

Validation finale : **334 tests standard + 334 photos activées réussis**, analyse stricte sans anomalie, format lib/test (110 fichiers) et diff conformes. Logs `.dart_tool/mvp-uiux-final-standard-{analyze,tests}.log` et `.dart_tool/uiux-photos-tests.log`, suites de 60 s et 65 s. La commande photos ajoute `KIBO_CAPTURE_UI_PREVIEWS=true` uniquement au banc de test : les aperçus sous `.dart_tool/uiux-previews/` utilisent Manrope, Material Icons et des données fictives ; accueil/carte à texte double/détail/publication ont été inspectés, y compris les boutons harmonisés. Ils ne constituent pas une recette physique complète.

Installation/lancement réels : Launch-KiboAndroid code 0 sur TECNO H6929CK6NU012345, build 37,0 s, installation 7,8 s, synchronisation 496 ms, processus 18184 et KIBO au premier plan confirmés. Empreinte SHA-256 APK `EC3FFDBE413D81751EE4354DE1DA40DC12CB3F692538E32D761C7663DE05E549`. Aucun effacement/désinstallation. L’accueil a été inspecté sur une capture réelle sous `.dart_tool/uiux-phone-f6ad082fa10b4387ad3ffa5d45cbfa40.png`, focus KIBO vérifié avant/après ; cartes, photos, prix, recherche et navigation visibles. Aucun autre écran d’application capturé et aucune action favorite/contact/publication effectuée. L’essai d’ouverture sémantique d’une fiche a été abandonné sans clic car le dump accessible n’était pas exploitable ; cela ne prouve pas un défaut TalkBack. Le détail, la galerie et la publication ont été contrôlés sur les aperçus/tests fictifs, sans revendiquer une recette physique complète.

## Fichiers de ce lot

- Flutter : `lib/main.dart`, `lib/features/listings/{listing_card.dart,listing_feed.dart,listing_detail_page.dart,listing_photo_widgets.dart,publish_listing_page.dart}`, `lib/core/theme/kibo_theme.dart`, `lib/core/widgets/kibo_state_panel.dart`.
- Android : `android/app/src/main/res/drawable/kibo_launcher_foreground.xml`, `values/kibo_launcher_colors.xml`, `mipmap-anydpi-v26/ic_launcher.xml`, les cinq `mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`.
- Outil de rendu explicite : `tool/generate_launcher_icons_test.dart`.
- Tests : `test/listings/uiux_marketplace_test.dart`, `test/listings/listing_photo_widgets_test.dart`.
- Documentation : ce rapport, UI_THEME, PROGRESS et NEXT_TASK.

Les modifications préexistantes du dépôt ont été conservées. Aucun commit/push ni publication. Limites : revue physique TalkBack, paramètres système de texte/réseau et recette à deux comptes encore à effectuer ; pas de certification générale d’accessibilité revendiquée. La galerie n’ajoute pas d’éditeur ni de zoom plein écran.

Suite UI/UX proposée : Profil/connexion/récupération ; Messages/Notifications ; Favoris/Mes annonces. La disponibilité des comptes de recette ne sera pas redemandée tant que l’utilisateur n’annonce pas de changement.
