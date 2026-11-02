# Personnalisation visuelle, connexion directe et thème sombre — 2026-11-01

La demande utilisateur remplace temporairement la priorité aux diagnostics : poursuivre l’interface, rapprocher le détail de la référence, corriger l’état vide des messages, intégrer la connexion au profil public et prendre en charge le sombre. Les résultats de performance du lot précédent restent consignés, sans nouvelle mesure ni conclusion de résolution dans ce lot.

## Réalisation

- `AuthPage` est réutilisé dans le profil déconnecté en mode intégré : mêmes validateurs, contrôleur, états d’attente, confirmation email, récupération et inscription. La connexion intégrée ne dépile pas la route d’accueil. Le groupe autofill est annulé à la destruction pour préserver le comportement de non-enregistrement automatique des mots de passe. Aucun fournisseur Google/Apple n’a été ajouté : l’utilisateur a précisé qu’il parlait du formulaire proposé dans Profil.
- Profil connecté : carte d’identité lisible et menu des actions existantes ; apparence regroupée avec les réglages. Le profil public entier défile lorsque les caractères sont grands, y compris l’en-tête et le choix de thème.
- Messages : titres courts et bloc vide illustré par une icône Material, contraint en largeur et défilable. Pas de texte tronqué pour masquer le problème.
- Détail : galerie bord à bord, favori superposé, compteur/commandes sur la photo, titre/prix/localisation/description sur surface arrondie et contacts persistants. Boutons en ligne si la largeur et l’échelle du texte le permettent, en colonne sinon. Les contrôles d’accès et routes de chat/vendeur sont conservés ; aucun numéro exposé directement.
- Palette sombre verte/neutre et `ColorScheme` distinct ; cartes, champs, prix, séparateurs, navigation, menus, dialogues et snackbars suivent le thème. Zones système adaptées. Sélecteur « Appareil / Clair / Sombre » dans Profil et dans le panneau d’apparence de l’accueil.
- `AppearanceController` injectable et stockage sécurisé existant : préférence locale indépendante d’Auth, écritures sérialisées, lecture tardive ignorée après un choix manuel, erreur de sauvegarde récupérable. Système par défaut, aucune modification des réglages globaux du téléphone.
- Badge de notifications espacé pour ne pas recouvrir le libellé lorsque le compteur est grand.
- [`maquette/`](../maquette/README.md) contient la galerie, les PNG clairs/sombres, le catalogue et le manifeste. Exports depuis les widgets actuels, données et illustration fictives ; retours et navigation présents suivant le contexte de chaque écran.

## Préservation et vérification

Dépôt KIBO, `origin` et branche main contrôlés avant modification. Inventaire des empreintes préexistantes dans `.dart_tool/visual2-preexisting-hashes.json`, sans affichage des configurations. Aucun fichier réinitialisé ni supprimé. Pas de changement de backend, RLS, modèle, repository de production, route métier ou dépendance. Pas de nouvelle donnée réelle, ni commit/push.

Les nouveaux tests ciblent : persistance et ordre des choix de thème ; lecture tardive ; contrastes sombres ; intégration de KiboApp et conservation des saisies ; connexion directement dans Profil sans dépiler l’accueil ; messages vides à 320 px/texte ×3 ; largeur de galerie, contact persistant et garde invité. Les tests existants sont conservés ; les assertions de texte et de position sont adaptées aux boutons courts et au pied de page fixe. Les tests ont détecté puis permis de corriger le débordement du profil public à texte ×3.

## Résultats réellement obtenus

- Formatage de `lib`, `test` et des deux nouveaux outils : **118 fichiers, aucun changement nécessaire** au contrôle final.
- `flutter analyze --no-pub --fatal-infos` : **aucune anomalie**, `.dart_tool/visual2-analyze.log`.
- `flutter test --no-pub --reporter expanded` : **346 tests réussis**, `.dart_tool/visual2-tests.log`.
- Même suite avec `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` : **346 tests réussis**, `.dart_tool/visual2-photos-tests.log`.
- Générateur `tool/export_maquettes_test.dart` : **1 scénario d’export réussi** ; **66 PNG pour 33 écrans/panneaux**, tous présents et validés à 786 × 1704 px par lecture des en-têtes PNG et du manifeste. Galerie, catalogue et manifeste régénérés ; une référence initiale distincte est conservée. Journal `.dart_tool/maquette-export.log`.
- Inspection des rendus, notamment détail, profils, accueil sombre, messages vides et aperçu de publication. Retour et navigation apparaissent selon le contexte de route/onglet. Le téléphone dessiné dans les fixtures illustre une photo sans utiliser de donnée réelle.
- `git diff --check` : **code 0**. Inventaire relu : aucun fichier préexistant manquant ; modifications existantes préservées, aucun commit/push.

## Téléphone

Lanceur existant exécuté dans un processus PowerShell dédié : **code 0**, build debug **22,6 s**, installation **7,0 s**, synchronisation **258 ms**, **processus 6104 et KIBO au premier plan confirmés**. Application normale avec la configuration locale et les photos activées, sans désinstallation ni effacement.

Une capture limitée au premier plan KIBO, vérifié avant/après, a permis d’observer l’écran vendeur en sombre sur TECNO. Aucun bouton de contact, connexion ou changement d’apparence n’a été actionné par l’agent pendant ce contrôle. L’écran et le réglage déjà présents sur le téléphone ont été laissés tels quels. Capture ignorée sous `.dart_tool/visual2-device-6528c81c326646d28ab3bb0149524c0b.png`, jamais incluse dans `maquette/`.

## Limites et suite visuelle

Les PNG sont des références de la version implémentée, pas une certification visuelle de tous les états ou une copie exacte de la maquette initiale. Les parcours longs restent défilables ; les dialogues et états transitoires ne sont pas tous exportés individuellement. Les tests et exports utilisent des fixtures : aucune nouvelle recette réelle d’authentification, messagerie ou droits à deux comptes n’a été réalisée. La persistance et les changements rapides de thème sont vérifiés avec un store simulé ; l’affichage sombre est observé sur téléphone, sans test automatisé de redémarrage du stockage natif.

La prochaine passe peut affiner la publication guidée, les présentations compactes recherche/favoris et les actions des conversations, en gardant les références à jour. Les diagnostics restent différés selon la demande utilisateur.

## Fichiers du lot

- `lib/core/theme/{appearance_controller.dart,kibo_theme.dart}` ; `lib/core/widgets/kibo_bottom_navigation.dart` ; `lib/main.dart`.
- `lib/features/auth/{auth_page.dart,profile_page.dart}`, `lib/features/chat/chat_page.dart`, `lib/features/safety/safety_entry.dart`.
- `lib/features/listings/{listing_card.dart,listing_detail_page.dart,listing_photo_widgets.dart}`.
- `test/theme/appearance_test.dart`, adaptations dans `test/auth/auth_widgets_test.dart`, `test/chat/chat_widgets_test.dart`, `test/seller/seller_widgets_test.dart`, `test/listings/uiux_marketplace_test.dart`.
- `tool/{export_maquettes_test.dart,maquette_fixtures.dart}`, références dans `maquette/`, `docs/{CHARTE_GRAPHIQUE.md,UI_THEME.md,PROGRESS.md,NEXT_TASK.md,VISUAL_PERSONALIZATION.md}`.
