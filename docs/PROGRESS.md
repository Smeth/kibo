# Consolidation Git et CI — 2026-11-02

Commit puis push sur origin/main explicitement autorisés par le propriétaire. Inventaire initial préservé ; commit distant 2a3b4fb intégré par avance rapide, sans conflit, avec ses deux migrations historiques. Sources, tests, assets, maquettes, scripts et propositions serveur préparés ensemble ; aucune migration appliquée à distance. Contrôle des 523 chemins indexés : aucune configuration locale suivie ni motif de clé privée/token réel détecté. Les JWT du test de configuration sont des fixtures.

CI étendue aux chemins assets, tool, scripts, supabase et configuration publique/exemple ; matrice Flutter photos false/true et 19 tests Node isolés du worker de suppression. README et état MVP consolidés, description du projet corrigée. Un test Dart reformaté et deux fins de documents normalisées. Analyse stricte réussie sans anomalie ; **447 tests Flutter standard + 447 avec photos + 19 tests Node réussis**. Format final : 146 fichiers, aucun changement. Commandes : `dart format lib test`, puis vérification `--output=none --set-exit-if-changed` ; `flutter analyze --no-pub --fatal-infos` ; `flutter test --no-pub --reporter expanded` avec/sans `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` ; `node --test test/audit/account_deletion_worker_test.mjs` ; `git diff --cached --check`. Les contrôles utilisent les SDK locaux, sans déploiement. Aucun Android détecté par ADB : installation/relance non exécutées. Aucun réglage ni donnée Supabase distant modifié. Les propositions restent non activées par ce versionnement.

# Audit global en lecture seule — 2026-11-02

Demande utilisateur : bilan complet avant choix des évolutions. [Rapport détaillé](AUDIT_ETAT_ACTUEL_2026_11_02.md) : état du MVP, limites, défauts reproduits, sécurité/confidentialité, performance, exploitation et priorités. Analyse relancée sans anomalie, **443 tests standard réussis**, format lecture seule 147 fichiers inchangés et diff conforme. Variante photos 443 du dernier lot rappelée comme preuve antérieure, pas rejouée pendant cet audit. Aucun changement applicatif, build, installation, commit/push ou écriture distante.

Contrôles distants : 3 comptes dont 1 admin ; 18 tables public à RLS active ; 1 200 annonces dont 1 188 fixtures ; 4 753 commentaires, 4 755 notifications ; 1 199 photos/objets sans orphelin observé ; Google/email actifs, Phone inactif ; prix nullable mais 0 NULL constaté ; 0 facteur MFA Supabase admin vérifié. Ancien bucket public vide, nouveau privé. Conseillers sécurité/performance et journaux agrégés consultés sans contenu privé. Accès admin aux conversations autorisé par les politiques, pas de chiffrement de bout en bout implémenté.

**Défaut confirmé restant : recherche française par préfixes.** « iph » = 44, « tél/télé/télép » = 0, « téléphone » = 132. Cas tél confirmé via l’API visiteur ; dictionnaire français transforme le préfixe différemment du mot indexé. Aucune correction faite pendant l’analyse. Requêtes reproductibles dans `supabase/audits/application_state_readonly.sql` (préparé, contrôles exécutés séparément).

Écarts majeurs : 53 fichiers de fonctionnalités locaux non suivis par Git, suppression effective de compte encore prototype, signature release locale absente, données fictives dans le catalogue partagé, absence de push/badge officiel, gestion partielle des photos après publication, recette multi-appareils et charge non prouvées. Priorités et lots proposés dans le rapport ; aucune de ces recommandations ne vaut autorisation de déploiement ou d’effacement.

# Vendeur, sélection des cartes et style Administration — 2026-11-02

Dernier ajustement clavier installé sur TECNO en mode profile : build 83,6 s, installation 5,1 s, processus **20344** et premier plan confirmés, sans effacement. Suites finales : **443 tests standard + 443 photos activées réussis** ; 23 tests ciblés après le correctif de hauteur disponible, analyse stricte sans anomalie.

Message direct toujours visible au-dessus de WhatsApp, désactivé/expliqué sur sa propre annonce ; garde de connexion existante conservée pour un visiteur. Appui sur les cartes de Mes annonces pour sélectionner/désélectionner, bordure/fond sélectionnés et barre d’actions persistante en bas. Suppression groupée = retrait par archivage avec confirmation/bilan, pas d’effacement définitif. Entrée Administration rendue avec le même KiboMenuAction que les autres lignes. [Fichiers, tests et limites](SELLER_SELECTION_ADMIN_UI.md).

Analyse stricte et diff conformes. Captures de vrais widgets à texte ×1/×2 inspectées, puis contrôle supplémentaire avec clavier validé. Installation finale confirmée ci-dessus. Travail préexistant préservé ; aucune donnée métier distante modifiée pour la recette, aucun commit/push.

# Profil vendeur, recherche progressive et prix facultatif — 2026-11-02

Application normale installée/relancée sur TECNO en mode profile : build 49,9 s, installation 8,0 s, processus **16509** et premier plan confirmés, sans effacement. Connexion/message et publication sans prix vérifiés avec fixtures/SQL local ; aucun message ni annonce métier créé à distance pendant ce lot.

Boutons vendeur séparés via espacement commun, pictogramme WhatsApp officiel intégré et Message direct ajouté. Visiteur dirigé vers AuthPage, ouverture du chat après connexion seulement, annulation sans conversation ; même parcours depuis le détail. Recherche titre/description désormais progressive à partir de trois caractères (350 ms) avec préfixes de mots et curseur conservé. Contrôle réel « iph » : 0 avant, 44 avec préfixe ; API visiteur HTTP 206, page de 20 sur 44 confirmée.

Prix vide → NULL → « Prix à négocier », zéro distinct, publication/modification/aperçus adaptés. SQL local réel et RLS/isolation validés. Après accord explicite, migration **20261102021424 / kibo_optional_listing_price** appliquée ; 1 200 annonces et empreintes de leurs prix/politiques/triggers identiques avant/après, RLS active, seule nullabilité changée. **435 tests standard + 435 photos activées réussis**, analyse stricte et diff conformes ; sept tests de revue/export réussis, capture des vrais widgets contrôlée. [Fichiers, commandes, preuves et limites](SELLER_SEARCH_OPTIONAL_PRICE.md). Aucun commit/push.

# Revue UI 2, administration et import massif — 2026-11-02

Application normale réellement installée et relancée sur TECNO en **mode profile**, processus 13433 et premier plan confirmés, sans effacement. Capture physique inspectée : accueil et nouvelles images visibles. Pas de connexion réelle sous kanasmeth, de décision admin physique ni de mesure FPS revendiquée.

Espacement commun appliqué aux formulaires, rafraîchissement Favoris/Mes annonces/Notifications, scope photo transmis aux routes de gestion, sélection et archivage/vente groupés avec bilan partiel. Accueil Administration et file opérateur dédiés intégrés. **426 tests standard réussis**, analyse stricte sans anomalie ; capture de vrais widgets avec fixtures contrôlée. [Détails](UI_REVIEW_2_ADMIN_STRESS.md).

Instruction explicite exécutée : rôle admin attribué uniquement à `kanasmeth@gmail.com`, compte confirmé, métadonnées serveur vérifiées ; nouveau JWT après reconnexion nécessaire. Aucun changement de schéma/RLS ni attribution aux comptes vendeurs. **Second lot réellement terminé et audité : 1 080 annonces publiées/1 080 JPEG/4 320 commentaires**, vendeur `frposx@gmail.com`. Erreur réseau après 612, reprise après contrôle exact des 612 IDs/photos ; dix transactions de commentaires achevées. Premier lot 108/108/432 conservé ; total 1 188 annonces et 4 752 commentaires, auteurs/destinataires attendus, six tables RLS actives. Suites **426 standard + 426 photos réussies**, puis 42 tests ciblés après les derniers détails ; analyse et diff conformes. Aucun commit/push.

# Avancement KIBO

## Lot de données de recette et état administrateur — 2026-11-02

**Résultat final distant réellement vérifié : 108 annonces publiées, 108 photos JPEG, 216 commentaires racines + 216 réponses (432), 12 annonces par catégorie.** Vendeur : second compte de test désigné, questions : premier compte, réponses : vendeur. 432 notifications de commentaire générées normalement vers ces comptes. Aucune attribution admin et RLS active sur annonces/commentaires/photos/signalements/journal. Annonces/photos importées par les APIs existantes dans la session du vendeur ; commentaires insérés ensuite par transaction opérateur bornée au lot, sans UPDATE/DELETE ni désactivation des triggers. Contrôle réel d’une photo en visiteur : HTTP 200, 7 057 octets et JPEG inspecté. L’application normale est réinstallée/relancée au premier plan (processus 23507) ; les paragraphes ci-dessous conservent les étapes et incidents du lot.

Utilisateur : au moins 100 annonces avec images/commentaires, puis explication de la modération. Choix explicite de la base Supabase connectée et désignation de deux comptes de test existants. Lot local prêt : **108 annonces (12 par catégorie), 108 fichiers image et 432 commentaires/réponses**, marquage TEST, prix XAF et villes CG. 95 contenus visuels distincts ; photographies de fixtures DummyJSON, illustrations pour services/formation/logements. [Périmètre, import et limites](TEST_CATALOGUE.md).

Trois tâches préparées : génération des fixtures et contrôle de toutes leurs images ; lanceur Android d’import par session vendeur, identifiants stables, APIs existantes et reprise sans recréation d’annonces ; état précis de l’[administrateur/modérateur](ADMIN_MODERATOR_STATUS.md), avec capture de la vue mobile existante. Les comptes désignés ont été confirmés existants, avec profil, sans rôle admin ; aucun rôle attribué. Avant import : **0 annonce du lot** constatée sur le serveur. Aucun compte, réglage Auth ou rôle créé/modifié.

**409 tests standard + 409 photos activées réussis**, sept nouveaux de structure/photos/intégrité/isolement/reprise. Analyse stricte sans anomalie. Les remarques de style initiales et un import superflu ont été corrigés avant validation. Syntaxe du lanceur conforme, diff conforme. Le lanceur consigne seulement phase/compteur dans son fichier de statut local, sans compte, clé ou jeton. Installation/lancement et import distant en cours ; ne pas confondre ces étapes avec la préparation locale. Aucun commit/push.

Fichiers : `assets/test_catalogue/` ; `scripts/prepare_test_catalogue.py`, `Import-TestCatalogueAndroid.ps1` ; `lib/features/development/test_catalogue_importer.dart` ; `tool/import_test_catalogue.dart` ; `test/listings/test_catalogue_importer_test.dart` ; `pubspec.yaml` ; `docs/{TEST_CATALOGUE,ADMIN_MODERATOR_STATUS,PROGRESS,NEXT_TASK}.md`. Cibles de comptes/projet uniquement dans `config/seed.local.json` ignoré. Inventaire préexistant `.dart_tool/demo-preexisting-untracked.txt`. Source et empreinte des images dans le manifeste du lot.

Deux lancements réels du lanceur sur TECNO ont vérifié successivement les deux seuls comptes autorisés ; tous deux se sont arrêtés avec `wrong_account`, compteur **0**, avant écriture. Premier build 32,1 s / installation 8,7 s ; second build 24,0 s / installation 9,4 s. Statut local fraîchement écrit confirmé, activité reprise et processus 19942 au second contrôle. Aucun jeton/session native lu par l’agent : seul le lanceur utilise le SDK et seul son fichier phase/compteur est consulté. L’application normale est en cours de restauration pour connexion locale du vendeur ; une question attend la confirmation utilisateur. Les 108 annonces/432 commentaires ne sont donc **pas encore importés**. SQL de commentaires préparé localement, non exécuté ; aucun rôle accordé.

L’utilisateur a confirmé la connexion du second compte après restauration normale (build 14,7 s / installation 5,7 s, processus 20451 et premier plan confirmés). Un troisième contrôle immédiat s’est encore arrêté à zéro ; lecture du SDK local : récupération de session effectuée après l’initialisation. Le lanceur attend désormais les événements AuthController et propose la connexion native dans sa propre session si nécessaire. Dernière analyse stricte conforme ; installation du lanceur corrigé en cours. Le statut peut contenir le nom du type d’erreur, sans message brut ni valeur d’authentification. Cible courante : second compte vendeur, premier compte questions, sans attribution de privilège.

Connexion confirmée par l’utilisateur directement dans le lanceur corrigé. L’import a commencé sa préparation puis s’est arrêté avant toute ligne avec ArgumentError : les UUID v5 déterministes du générateur n’étaient pas acceptés par le contrat UUID v4 de `createOnce`. Générateur corrigé en identifiants déterministes de forme v4 pour les annonces ; commentaires inchangés. La validation locale vérifie désormais explicitement `isOperationId`, avec assertion dans le test du jeu complet. Zéro ancienne/nouvelle annonce de ce lot constatée avant reprise. Analyse stricte et nouvelle suite standard conformes ; vérification photos/réinstallation en cours. Aucun élargissement du contrat de publication ni changement serveur pour contourner ce refus.

Après correction : **409 tests standard + 409 photos activées réussis**, analyse stricte conforme. Lanceur réinstallé (build 20,1 s, installation 6,3 s) ; cette fois, la session vendeur est restaurée et l’import redémarre automatiquement en phase preparing. Les commentaires restent préparés, non exécutés tant que 108 photos ne sont pas confirmées. Contrôle modération en lecture seule : cinq RPC publiques invoker présentes, RLS active sur cinq tables concernées. Aucun rôle attribué ni politique modifiée.

Import désormais réellement en cours sous le second compte autorisé : contrôle intermédiaire distant **59 annonces / 59 réservations / 58 objets photo non vides** (une photo en vol), puis progression locale continue. Ces lignes sont des créations autorisées du lot TEST ; les étapes d’avant ce redémarrage restent sans insertion. Ne pas annoncer le lot complet avant le contrôle final 108/108 et l’insertion transactionnelle des commentaires.

Clôture du lot : statut du lanceur `done / 108`, puis contrôle serveur 108 annonces publiées du vendeur attendu et 108 photos JPEG réelles. Transaction des commentaires exécutée avec succès : **432 / 216 racines / 216 réponses**. Audit final : auteurs attendus uniquement, neuf catégories à douze annonces, 432 notifications, comptes non admin et RLS active. Application normale réellement réinstallée/relancée : build **11,5 s**, installation **6,4 s**, synchronisation **122 ms**, processus **23507** et premier plan confirmés. Aucun effacement, migration, changement Auth/Storage/RLS ou rôle ; aucun commit/push. Dernier format 136 fichiers inchangés, diff conforme et aucun fichier préexistant non suivi disparu. Les contrôles de données réelles ci-dessus ne constituent pas une recette humaine complète de tous les parcours ou de modération.

## Détails des écrans et cache photos — 2026-11-02

Lot demandé : espacements récupération/changement de mot de passe et revue des formulaires (cas similaires corrigés dans demandes de compte, modération/commentaires) ; tirer pour actualiser le catalogue même vide, filtres conservés ; filtre ville uniquement par catalogue CG avec contrôle du pays du fichier ; thème local des SearchBar sans contrainte de champ formulaire et caret centré ; cache de fichiers photo partagé, borné, temporaire et isolé par session. [Mécanismes, limites et fichiers](UI_REFINEMENTS_CACHE.md).

**402 tests standard + 402 photos activées réussis**, treize nouveaux. Analyse stricte sans anomalie, contrôle final du format : 133 fichiers inchangés, diff conforme. Les premières erreurs de test venaient de l’accès au RenderEditable et d’une propriété readOnly recherchée sur TextFormField plutôt que son TextField interne ; elles ont été corrigées avant les passes complètes. Deux imports superflus retirés. Installation sur TECNO réussie, affichage bloqué par le verrouillage système (détails ci-dessous). Inventaire préexistant `.dart_tool/polish-preexisting-untracked.txt`, aucun fichier préexistant disparu ; aucun commit/push, migration, réglage ou donnée métier distante modifié. Logs `.dart_tool/polish-{format,format-check,analyze,tests,photos-tests}.log`.

Fichiers du lot : `lib/features/auth/password_pages.dart` ; `lib/features/profile/{account_settings_page,engagement_pages}.dart` ; `lib/features/safety/safety_page.dart` ; `lib/features/comments/comments_page.dart` ; `lib/core/widgets/{congo_city_field,kibo_search_field_theme}.dart` ; `lib/features/listings/{catalogue_search_form,listing_feed,listing_photos,listing_photo_widgets,listing_photo_cache}.dart` ; `test/listings/{ui_polish,listing_photo_cache,listing_photo_memory}_test.dart` ; `test/locations/congo_city_test.dart` ; `docs/{UI_REFINEMENTS_CACHE,PROGRESS,NEXT_TASK}.md`.

Build debug **22,4 s**, installation TECNO **10,8 s**, synchronisation **103 ms**, code 0 et processus **5803** confirmés, sans effacement ni désinstallation. Premier plan non confirmé : une relance explicite a livré l’intent à l’activité déjà démarrée ; l’état système indique que le verrouillage est affiché (`showing=true`, `mIsShowing=true`). Aucune tentative de déverrouillage. L’application est dans la pile, mais sa recette visuelle et le profilage FPS restent à effectuer après déverrouillage par le propriétaire. Ne pas confondre lancement du processus et affichage visible. Aucun contenu d’annonce réel utilisé pour un scénario de recette automatisé.

## Logo Google et préparation OTP téléphone — 2026-11-02

Trois tâches implémentées : (1) logo G officiel Google embarqué, couleurs/proportions conservées, bouton blanc lisible en clair/sombre ; (2) parcours OTP SMS +242, numéro/code, renvoi après 60 secondes, correction et erreurs françaises, session uniquement après confirmation SDK, profil personnel compatible avec un email vide ; (3) garde désactivée par défaut `KIBO_PHONE_AUTH_ENABLED`, refus des appels repository quand désactivée, option `-EnablePhoneAuth` du lanceur et [procédure d’activation](PHONE_AUTH.md). Un prestataire SMS directement compatible Supabase est nécessaire ; un prestataire arbitraire peut exiger un hook serveur supplémentaire. Aucun fournisseur, code de test fixe, SMS réel ni compte de recette activé/créé.

Audit serveur en lecture seule : métadonnées des colonnes de `profiles` et définition du trigger INSERT sur `auth.users`. `handle_new_user` utilise ID et nom facultatif, pas l’email ; nom nullable, ville Brazzaville et type individual par défaut constatés. Aucun contenu métier lu ni contrat/réglage distant modifié. Cela ne constitue pas une recette réelle de création par téléphone.

**389 tests standard + 389 photos activées réussis**, dix nouveaux OTP et tests Google enrichis pour le logo : URL/contrat SDK simulés, absence de requête quand désactivé, numéros/codes invalides, doublons/délai, erreurs expurgées, correction, disposition, session sans email, fermeture des routes et petit écran/clavier/texte ×2. Analyse stricte sans anomalie. Deux remarques de style sur des `if` multilignes corrigées avant validation. Installation Android réussie (détails ci-dessous). Contrôle final du format : 128 fichiers inchangés, `git diff --check` conforme, syntaxe du lanceur PowerShell valide ; aucun fichier préexistant non suivi disparu. Inventaire `.dart_tool/otp-preexisting-untracked.txt`, logs `.dart_tool/otp-{format,format-check,analyze,tests,photos-tests}.log`. Aucun commit/push.

Fichiers : `assets/branding/google-g.png` et provenance ; `pubspec.yaml` ; `lib/features/auth/auth_repository.dart`, `auth_page.dart`, `profile_page.dart`, `phone_auth_{validation,controller,page}.dart` ; `test/auth/{google_auth,phone_auth}_test.dart` ; `scripts/Launch-KiboAndroid.ps1` ; `docs/{PHONE_AUTH,GOOGLE_AUTH,AUTHENTICATION,PROGRESS,NEXT_TASK}.md`.

Version réellement installée et relancée sur TECNO, OTP désactivé : build 23,9 s, installation 8,2 s, synchronisation 153 ms ; processus **4771** et premier plan confirmés. Aucun effacement ni désinstallation. Cette validation de lancement et les tests simulés ne certifient pas la livraison SMS ou une connexion réelle OTP ; fournisseur et recette humaine restent nécessaires. Logo source inspecté visuellement, widgets clair/sombre et dimensions vérifiés dans les tests. Aucune nouvelle recette réelle Google exécutée.

## Connexion Google — 2026-11-02

Lot de trois tâches : (1) bouton « Continuer avec Google » dans les formulaires connexion/inscription et leur version intégrée au profil ; (2) repository OAuth navigateur externe, choix du compte et callback PKCE existant, contrôleur sans faux succès lors de l’ouverture du navigateur, annulation réessayable et mots de passe effacés ; (3) tests SDK/contrôleur/widgets et procédure de configuration/recette dans [GOOGLE_AUTH.md](GOOGLE_AUTH.md).

Lecture distante strictement limitée aux paramètres Auth publics : `external.google=true` réellement constaté avec la configuration locale existante. Aucun réglage distant, compte, profil ou donnée métier créé/modifié. Aucun nouveau package, migration, secret OAuth client, commit ou push. Travail préexistant inventorié dans `.dart_tool/google-preexisting-{untracked,diff}.txt` et conservé. Les sections antérieures signalant l’absence de bouton Google décrivent l’historique.

**379 tests standard + 379 photos activées réussis**, dont six nouveaux : URL OAuth réelle générée par le SDK avec Google/callback/challenge S256/navigateur externe ; doublons, absence de session à l’ouverture, reprise ; erreurs expurgées ; connexion et inscription sans remplir les champs email/mot de passe, fermeture sur événement de session simulé ; profil intégré à 320 px, texte ×2, thème sombre et désactivation pendant l’ouverture. Analyse stricte sans anomalie, contrôle final du format : 124 fichiers inchangés, `git diff --check` conforme et aucun fichier préexistant non suivi disparu. Installation Android réussie (détails ci-dessous) ; recette Google humaine non exécutée. Les paramètres Google Cloud et les Redirect URLs n’ont pas été inspectés. Logs `.dart_tool/google-{format,format-check,analyze,tests,photos-tests}.log`.

Fichiers du lot : `lib/features/auth/auth_repository.dart`, `auth_controller.dart`, `auth_page.dart`, `test/auth/google_auth_test.dart`, `docs/GOOGLE_AUTH.md`, `AUTHENTICATION.md`, PROGRESS et NEXT_TASK.

Installation finale réellement réussie sur TECNO CK6n : build debug 51,2 s, installation 8,4 s, synchronisation 95 ms ; processus **31974** et premier plan confirmés. Aucun effacement ni désinstallation. Le script a été lancé dans un processus PowerShell dédié avec `-ExecutionPolicy Bypass` après refus de la politique d’exécution du shell, sans modifier la politique Windows persistante. Les premiers essais Flutter en sandbox ont également nécessité un accès approuvé au cache SDK/télémétrie ; les contrôles ci-dessus proviennent des exécutions réussies. Recette humaine Google à chaud/froid et compte email existant encore à effectuer ; ne pas déclarer le consentement Google et les redirections validés par cette seule installation.

## Cartes uniformes et appui long des messages — 2026-11-01

Correction demandée par l’utilisateur : les cartes de l’accueil ont désormais les mêmes hauteurs et largeurs pour un même affichage, y compris entre rangées, avec titres longs/courts, prix longs, villes, dates ou photos absentes. Espaces réservés selon les métriques du thème et l’échelle de texte ; titres/prix limités visuellement à deux lignes, ville/date à une ligne, contenu complet disponible dans le détail. Le mode liste recherche/favoris est conservé. Les alertes photo s’affichent sur la zone image sans agrandir la carte.

Appui long sur la bulle ou le texte de ses messages autorisés : panneau Material Modifier/Supprimer/Copier, menu ⋯ conservé. Le texte des messages concernés utilise le geste de la bulle ; Copier préserve l’accès au presse-papiers. Les messages reçus conservent leur sélection native. Les callbacks existants assurent confirmation, session, auteur, blocage et refus sur messages supprimés. Aucun contrat, permission ou donnée Supabase modifié dans ce lot.

**373 tests standard + 373 photos activées réussis**, quatre nouveaux : égalité des dimensions sur plusieurs rangées, contenu varié, texte ×2/sombre et appui long réel sur le texte vers suppression/modification. Analyse stricte sans anomalie ; tests historiques adaptés à la limite visuelle de deux lignes demandée. Une parenthèse du nouveau test et une assertion historique sur le titre illimité ont été corrigées avant les passes complètes. Logs `.dart_tool/cards5-{analyze,tests,photos-tests,format,maquettes}.log`.

Fichiers du lot : `lib/features/listings/listing_card.dart`, `listing_feed.dart`, `lib/features/chat/message_bubble.dart`, `test/listings/uniform_cards_test.dart`, `test/chat/message_actions_test.dart`, `test/kibo_layout_regression_test.dart`, `tool/export_maquettes_test.dart`, `maquette/`, PROGRESS et NEXT_TASK. Aucun commit/push ; travail préexistant conservé.

Contrôles finaux : format 124 fichiers inchangés, analyse stricte sans anomalie et `git diff --check` conforme. Export de **78 PNG de 39 écrans/panneaux** réussi ; manifeste/uniqueness/dimensions 786 × 1704 vérifiés. Accueil clair et panneau d’appui long sombre inspectés. Version normale installée et relancée sur TECNO : code 0, build 18,3 s, installation 7,4 s, synchronisation 401 ms, processus **24411** et premier plan confirmés. Aucun effacement, changement du thème ou mutation métier de recette. Les gestes sont testés sur widgets simulés ; aucune suppression de message réel effectuée pour la validation.

## Gestion des annonces et messages Material — 2026-11-01

Mes annonces : couverture photo, prix au format partagé, ville, statut illustré et actions ; suppression du catalogue explicitement réalisée par archivage, sans effacement définitif ni doublon d’action. Modification : galerie existante et ajout/prévisualisation/reprise de trois photos au maximum sur annonce sans image, par les mécanismes déjà déployés. Les photos déjà enregistrées restent conservées. Chat : bulles Material clair/sombre, menus de ses messages, formulaire validé et confirmation de suppression ; brouillon de correction conservé après erreur. [Rapport, fichiers et limites](MANAGEMENT_MATERIAL3.md).

**369 tests standard + 369 photos activées réussis**, quatorze nouveaux ; analyse stricte sans anomalie, contrôle de format 123 fichiers inchangés et diff conforme. Tests PostgreSQL locaux de la suite `MessageActions` réussis : auteur/tiers/visiteur, validation du texte, conflits de version, blocage, suppression logique, refus de restauration, journal et privilèges. Le premier test de petit écran a révélé un défilement insuffisant du lanceur de test après agrandissement des cartes ; il a été corrigé avant les deux passes finales. Le formulaire d’édition de message est aussi vidé/masqué et désactivé après changement de session. Journaux `.dart_tool/management4-{analyze,tests,photos-tests,format-check,sql}.log`.

Audit Supabase **en lecture seule** réellement effectué avant application : RLS active, droits UPDATE/DELETE client absents, INSERT par colonnes et garde/déclencheurs attendus. Après accord explicite, `supabase/proposals/chat_message_actions.sql` a été appliqué via la migration `chat_message_actions_20261101` (succès). Contrôles distants après application : dates/RPC présentes, wrappers invoker, RLS messages/journal active, droits directs UPDATE/DELETE et lecture client du journal refusés, RPC membre autorisée et RPC visiteur refusée. Conseiller sécurité : INFO attendu pour le journal privé sans politique ; avertissement Auth sur les mots de passe compromis désactivés, non modifié, documenté avec liens dans le bilan. Aucun contenu métier lu dans ces audits ni modifié par une recette ; aucune écriture de message réel, changement Auth, commit/push ou diagnostic de performance. Connexion Google possible et procédure documentée ; aucun bouton ni fournisseur activé dans ce lot.

Export final des **76 PNG de 38 écrans/panneaux** clair/sombre réussi ; manifeste, unicité et dimensions 786 × 1704 contrôlés. Mes annonces et modification avec galerie, conversation, formulaire de correction clair et confirmation de suppression sombre inspectés. Version normale installée et relancée sur TECNO : **code 0**, build 32,8 s / installation 21,3 s / synchronisation 666 ms, processus **22520** et premier plan confirmés. Aucun effacement, changement du thème ou mutation métier de recette. Aucun fichier préexistant disparu selon l’inventaire de début de lot. Les contrôles de lancement et métadonnées ne remplacent pas une recette à deux comptes ; gestion avancée des photos et reprise après fermeture d’un upload partiel restent des limites documentées.

## Accueil, villes sélectionnables et ancienneté — 2026-11-01

Accueil compact rapproché de la référence initiale : recherche large, ville, catégories à icônes et cartes avec métadonnées. Recherche/favoris en listes et menus de profil resserrés. Catalogue hors ligne de 4 538 noms distincts de villes/localités CG, issu de 5 778 enregistrements GeoNames attribués ; sélection partagée entre accueil, filtres et formulaires, saisie libre conservée. Ancienneté basée sur `published_at` déjà sélectionné, sans date inventée ni migration. [Rapport, fichiers et limites](REFERENCE_CITIES_DATES.md).

**355 tests standard + 355 photos activées réussis**, neuf nouveaux ; analyse stricte sans anomalie, format 121 fichiers inchangés, `git diff --check` conforme. Une infobulle de chat doublonnée révélée par la première passe a été corrigée avant ces deux passes complètes. Journaux `.dart_tool/reference3-{format,analyze,tests,photos-tests}.log`. Export des 68 maquettes réussi ; manifeste, unicité et dimensions 786 × 1704 vérifiés. Accueil clair, favoris clairs et sélecteur sombre inspectés. Aucun fichier préexistant supprimé selon l’inventaire de début de lot. Aucun SQL, réglage distant, donnée réelle de recette, commit/push ou profilage effectué.

Application normale installée et relancée sur TECNO : code 0, build 22,8 s, installation 7,1 s, synchronisation 364 ms ; processus **12513** et premier plan confirmés. Aucun effacement ni changement du thème par l’agent ; aucune interaction de recette réelle. Ce contrôle de lancement ne constitue pas une recette physique complète des nouveaux parcours.

## Connexion intégrée, détails visuels, sombre et maquettes — 2026-11-01

Priorité utilisateur : laisser les diagnostics de côté et revenir au visuel/fonctionnel. Profil public avec formulaire email/mot de passe directement intégré ; profil connecté regroupé en carte ; messages vides courts et défilables ; galerie de détail bord à bord, compteur superposé et contacts persistants/adaptatifs. Mode Appareil/Clair/Sombre mémorisé localement, palette et composants cohérents ; aucune configuration Auth distante, route métier, donnée réelle ou dépendance modifiée. [Rapport et fichiers](VISUAL_PERSONALIZATION.md).

**66 références de 33 écrans/panneaux générées**, 786 × 1704 px, uniquement à partir des widgets et de fixtures, avec navigation/retour suivant leur contexte. Galerie HTML, catalogue et manifeste dans [`maquette/`](../maquette/README.md). Les 66 fichiers et leurs dimensions ont été contrôlés ; comparaison visuelle du détail, des profils et des messages vides, en clair/sombre. Référence initiale conservée sans modifier l’original.

Validation finale : **346 tests standard + 346 photos activées réussis**, sept nouveaux ; analyse stricte sans anomalie, format 118 fichiers inchangés, diff conforme. Export de 66 PNG réussi et dimensions/manifeste contrôlés. Journaux `.dart_tool/visual2-{analyze,tests,photos-tests}.log` et `.dart_tool/maquette-export.log`. Les tests ont révélé le débordement du profil public à 320 px/texte ×3 : l’en-tête et le formulaire défilent désormais ensemble. Aucun profilage supplémentaire ; les réserves antérieures ne sont ni effacées ni déclarées résolues.

Version normale réellement installée et relancée sur TECNO : **code 0**, build 22,6 s / installation 7,0 s / synchronisation 258 ms, **processus 6104 et premier plan confirmés**. Sombre observé sur l’écran vendeur après garde du focus avant/après capture ; aucune action de contact/connexion ou changement d’apparence par l’agent pendant ce contrôle. Écran et réglage existants laissés tels quels. Aucun effacement, donnée réelle de recette, commit ou push. Tests simulés et observation physique restent distingués dans le rapport.

## Refonte Material 3 — 2026-11-01

Nouvelle priorité utilisateur : appliquer réellement la maquette verte aux écrans existants, en préservant les contrats et le travail local. Thème commun, recherche/catégories/navigation, détail/formulaires, favoris/profil et listes de chat/notifications/annonces refondus. Aucun backend, modèle, route ou contrôle de session modifié. [Périmètre, fichiers et mesures](MATERIAL3_REDESIGN.md).

Validation du code figé : **339 tests standard + 339 photos activées réussis**, cinq nouveaux tests ; scénario d’aperçus additionnels réussi, sept aperçus fictifs inspectés. Analyse stricte sans anomalie, format 116 fichiers inchangés, diff conforme et aucune disparition de fichier préexistant. Journaux `.dart_tool/m3-final-{analyze,tests,photos-tests}.log`. Authentification, publication, favoris et navigation restent couverts ; correction du filtre de catégorie avant chargement et modification du profil rapprochée de l’identité.

Mesures profile sur TECNO, données fictives et images loopback : cache réduit de **77,7 %** (76 982 400 → 17 173 392 octets), mais **fluidité non validée**. Sur la troisième répétition finale, construction p95 **30,369 ms contre 24,802 ms avant**, dépassements cumulés **16,5 % contre 14,4 %**. Deux séries intermédiaires et un nouveau lancement après repos montrent une forte variabilité ; diagnostic d’allocation Vulkan observé dans les deux versions, causalité non établie. Le rapport conserve tous les résultats et limites ; ne pas annoncer une absence de régression ni une performance prête pour diffusion.

Application normale configurée, photos activées, réellement réinstallée et relancée après le banc : **code 0**, entrée lib/main.dart debug, build 29,4 s / installation 6,4 s / synchronisation 1 188 ms, processus **2742** et premier plan confirmés. Accueil réel inspecté après garde du focus, photos et cinq destinations visibles ; aucun clic métier de recette. Aucune désinstallation ni donnée effacée. Aucun changement Supabase, donnée de recette réelle, commit, push ou déploiement distant. Le diagnostic de fluidité prolongée et la recette réelle à deux comptes restent ouverts.

## Lot UI/UX prioritaire — 2026-11-01

Recentrage explicitement demandé sur l’UI/UX. Trois volets locaux implémentés : recherche directe depuis l’accueil et cartes lisibles ; galerie de détail navigable et contacts avant les descriptions longues, formulaire de publication réorganisé ; états récupérables/repères accessibles et icône Android KIBO. Pas de changement Supabase, Auth/RLS ou permissions, pas de donnée de recette réelle. Les travaux de suppression restent différés et non activés.

24 tests UI/responsive ciblés réussis, dont sept nouveaux ; aperçus fictifs Manrope/Material Icons générés et inspectés sous `.dart_tool/uiux-previews` (accueil, carte à texte doublé, détail, publication). Générateur explicite d’icônes vectorielles/raster hors de test/, cinq densités legacy plus icône adaptative Android ; monogramme K Emerald/blanc inspecté. Les tests ont révélé deux erreurs de future immédiate avant attachement de FutureBuilder lors du retry et d’un changement de photo : gestion corrigée, les états d’erreur restent affichés sans détails techniques. La régression photos vérifie désormais l’accès à la seconde photo par la galerie, pas deux images visibles simultanément.

Validation finale : **334 tests standard + 334 photos activées réussis**, analyse stricte sans anomalie, format 110 fichiers inchangés et diff conforme ; boutons secondaires harmonisés au thème. Logs `.dart_tool/mvp-uiux-final-standard-{analyze,tests}.log` et `.dart_tool/uiux-photos-tests.log`. TECNO installé/relancé code 0 : build 37,0 s, installation 7,8 s, synchronisation 496 ms, processus 18184 et premier plan confirmés. SHA-256 APK `EC3FFDBE413D81751EE4354DE1DA40DC12CB3F692538E32D761C7663DE05E549`. Accueil réel inspecté sur capture limitée à KIBO (focus vérifié avant/après), photos/cartes/navigation lisibles ; aucune action favorite/contact/publication effectuée. L’ouverture automatisée d’une fiche a été abandonnée sans clic faute d’arbre accessible exploitable : détail/publication restent validés par aperçus et tests, pas par recette physique complète. TalkBack et recette à deux comptes non exécutés. [Bilan et fichiers](UIUX_MARKETPLACE.md). Aucun commit/push, changements préexistants conservés.

## Historique conservé et moteur de suppression — local, 2026-11-01

Trois volets préparés : modèle SQL privé avec RLS pour les contributions conservées, compatibilité Flutter pour compte supprimé/historique en lecture seule, noyau de worker avec adaptateurs fictifs. [Contrats, inventaire et limites](RETAINED_HISTORY_PROTOTYPE.md). Aucune requête distante ni migration appliquée dans ce lot. L’utilisateur a confirmé ne pas avoir les deux comptes/appareils de recette et demande de poursuivre les travaux locaux ; aucune écriture de recette réelle autorisée ou réalisée.

Proposition `retained_history.sql` testée sur un PostgreSQL 13 isolé : conservation après nettoyage des seuls personnages de fixture, texte d’ancien auteur remplacé, accès tiers/visiteur/écriture client refusés, expiration de threads/messages/commentaires. Code 0 sur 55500, cluster arrêté, fixture conservée. Le SQL ne copie aucune donnée existante et n’est pas déployé ; RPC nouvelles non branchées aux repositories de production. Aucun worker destructif opérationnel : noyau hors Edge Functions, sans réseau/SDK/secret/handler, désactivé par défaut et refusant le projet de production. **19 tests Node réussis**, y compris erreurs sensibles neutralisées ; verrous, autorisations, journal SQL et effets externes restent des obligations des futurs adaptateurs réels, pas une preuve de leur fonctionnement en staging.

Flutter : identité nullable seulement avec indicateur supprimé cohérent ; nom/titre/aperçu supprimés, ancien texte masqué, lecture seule irréversible sur l’écran, brouillon/cache effacés lors de la transition. Contrat actif préservé. **327 tests standard + 327 photos activées réussis**, six nouveaux tests, 55 ciblés chat/commentaires ; analyse stricte sans anomalie, format 109 fichiers sans changement, diff conforme. Logs `.dart_tool/mvp-retained-history-standard-{analyze,tests}.log`, `.dart_tool/history-photos-tests.log`, `.dart_tool/deletion-worker-tests.log`, `.dart_tool/history-sql-final.log`. Installation/relance TECNO code 0 : 22,6 s build, 6,9 s installation, processus 13467 et premier plan confirmés ; aucun effacement/désinstallation. SHA-256 APK `205F3346E2CFE91163EC61B37CB957AA7EF1035BCFF1E17D3C166BCBF0DBE252`. Aucun scénario destructif réel ou recette humaine effectué. Aucun commit/push ; modifications préexistantes conservées.

## Préparation recette, suppression et pilote Android — 2026-11-01

Trois chantiers locaux : [vingt scénarios de recette à deux comptes](RECETTE_MVP_DEUX_COMPTES.md), tous encore NON EXÉCUTÉ/BLOQUÉ ; [procédure de suppression réelle](ACCOUNT_DELETION_RUNBOOK.md), selon le choix utilisateur d’anonymiser les échanges conservés et supprimer profil/annonces/coordonnées, à valider avant activation ; [pilote Android](ANDROID_PILOT.md), garde de signature release et lanceur dédié sans effacement. Audit distant limité aux métadonnées FK/colonnes/CHECK, aucune ligne de membre lue, aucun DML/DDL distant. Cascades de conversations/réponses et RESTRICT identifiés : un delete Auth direct ne respecte pas le choix de conservation. Aucun worker d’effacement ni nouvelle migration activé.

Corrections d’interface : lecture échouée après demande ne devient plus une fausse absence, annulation concurrente explicitement non confirmée, ancienne erreur effacée après relecture réussie ; compteur Messages distinguant zéro/indisponible pour le lecteur d’écran ; libellés opérateur longs et test 320 px/texte double. Android affiche KIBO ; applicationId conservé. Le repli release sur clé debug est supprimé, aucun keystore généré ni clé lue hors des fichiers de configuration prévus. Gradle debug `--dry-run --offline` réussi ; release sans signature refusée comme attendu, aucun binaire produit par ces vérifications.

Validation finale : **321 tests standard + 321 photos activées réussis**, cinq tests ajoutés ; analyse stricte sans anomalie, format 108 fichiers inchangés et diff check conforme. Logs `.dart_tool/mvp-pilot-standard-{analyze,tests}.log` et `.dart_tool/pilot-photos-tests.log` ; suites 56 s et 41 s. Nouveau lanceur exécuté avec succès : build debug 21,5 s, installation 8,5 s, synchronisation 137 ms, TECNO H6929CK6NU012345, processus 31758 et premier plan confirmés au retour de la commande. Aucun effacement/désinstallation. SHA-256 APK `10723ECAE483B723612D8FCCE1E8BC72647B1139C43BD54ABF42D9EFE96B51BF`. Contrôle visuel ensuite non effectué : focus KIBO non confirmé lors de la tentative de capture, aucune capture d’autre application. Recette humaine à deux comptes toujours non exécutée. [Bilan et inventaire complet](PILOT_PREPARATION_RECAP.md). Aucun commit/push ; toutes les modifications préexistantes ont été conservées.

## Notifications, comptes et reprise des photos — 2026-11-01

Lot de trois chantiers implémenté : compteur global Messages et préférences des futures notifications ; interlocuteurs bloqués/déblocage et suivi personnel/file opérateur des demandes de compte ; photos compressées persistantes des brouillons, ordre et reprise sans recréer une annonce confirmée. Navigation, contrôle de session, résumés/permissions/RPC de chat existants réutilisés. Erreur initiale de lecture du compte : aucune nouvelle demande autorisée tant que l’état n’est pas relu. [Inventaire, contrat et limites](ENGAGEMENT_ACCOUNT_WORKFLOWS.md).

SQL isolé Engagement code 0, y compris socle Safety/MVP, 21 conversations, isolation, préférences et notifications système, faux rôle refusé, concurrence/annulation-recréation et journal atomique, refus de réapplication ; cluster 55497 arrêté. Après accord spécifique, contrat exact appliqué **20261101092315 kibo_engagement_workflows**, success=true ; deux nouvelles tables RLS, droits clients et six RPC invoker vérifiés en lecture seule. Aucun DML de recette distant, compte Auth ou rôle modifié. La suppression effective n’est pas réalisée par ce parcours. Avertissement sécurité préexistant : protection des mots de passe compromis désactivée, réglages inchangés ; aucune nouvelle alerte RLS. Conseiller performance : anciens FK non indexés/politiques à optimiser, plus index nouveaux encore inutilisés, sans retrait automatique.

Validation finale : **316 tests standard + 316 photos activées réussis** (23 nouveaux), analyse stricte sans anomalie, format 108 fichiers sans changement, diff check conforme. Logs `.dart_tool/mvp-engagement-standard-{analyze,tests}.log` et `.dart_tool/engagement-photos-tests.log` ; suites respectivement 66 s et 84 s. Téléphone absent lors de deux contrôles ADB : **aucun nouveau build, installation ou lancement physique effectué pour ce lot**. Reconnecter le TECNO avec débogage autorisé pour relancer sans effacement ; ne pas annoncer une recette physique depuis les tests locaux. Aucun commit/push. Les modifications préexistantes, y compris les fichiers non suivis, ont été conservées.

## Delta MAINTAIN explicitement autorisé et appliqué — 2026-11-01

Accord utilisateur exact sur les neuf tables et futures tables publiques créées par postgres. Fichier `client_maintain_pending_review.sql` relu et appliqué sans modification via MCP, migration **20261101090123 kibo_client_maintain_public**, success=true sur PG17.11. Après application : 0 table ciblée conservant MAINTAIN client et 0 entrée de defaults postgres/public pour anon/authenticated. Empreintes ACL hors MAINTAIN et RLS identiques avant/après. Aucun DML, aucune donnée modifiée, aucun changement Storage/Auth ni de defaults supabase_admin. Conseiller sécurité : seul WARN Auth préexistant. [Preuves et limites](CLIENT_MAINTAIN_DEPLOYED.md). Les mentions « en attente d'accord » des sections historiques ci-dessous sont dépassées pour ce delta précis seulement. Code Flutter inchangé, aucun nouveau test Flutter/build/commit/push.

## Exécution autonome lots 2–8

Autorisation utilisateur de poursuivre sans intervention, avec choix techniques courants et modifications limitées à KIBO. Plan/preuves dans [AUTONOMOUS_MVP_LOTS_2_8.md](AUTONOMOUS_MVP_LOTS_2_8.md). Lot 2 : 93 tests ciblés réussis et analyse stricte conforme ; SQL isolé Safety croisant chat/notifications/cycle annonce code 0, cluster arrêté. Recettes réelles à deux comptes non disponibles sans identifiants de test : aucun identifiant extrait du téléphone ni succès réel inventé. Nouveau lanceur reproductible `scripts/Validate-MvpLot.ps1`, sans installation d'outil ni nettoyage extérieur.

Lots 3–5 implémentés et installés sur TECNO : navigation explicite/réactive, filtres et scroll conservés, cartes/états utiles, brouillon texte propre au compte, photo principale et aperçu. 59 tests UI ciblés, 7 recherche puis 110 annonces/photos/responsive réussis. Stockage simulé injecté dans les tests de redémarrage ; aucun effacement pour résoudre un échec. Lots 6–8 implémentés : chat enrichi/non lus, blocage et comptes, anti-doublons/reprise, pause des ressources et durcissement ciblé. 33 tests ciblés finaux réussis ; validations/installations finales en cours. Deux migrations autorisées par la consigne autonome appliquées et contrôlées : 20261101052757 et 20261101053807. Partie MAINTAIN globale refusée par la revue automatique, non appliquée ; contrat réduit accepté sans ce retrait global. Voir le rapport détaillé et les limites restantes.

**Validation finale terminée : 293 tests standard + 293 photos activées réussis**, 21 tests ajoutés par rapport au socle 272 ; analyse stricte sans anomalie, format 100 fichiers sans changement, diff check code 0. Ajouts de régression finaux : récupération liée à l'identité de l'événement et blocage de publication si le brouillon n'a pas pu être lu. Lot 6 : 25 tests chat et lancement ; lot 7 : 60 tests auth/profil/vendeur et lancement. Troisième migration ciblée 20261101054728 (index blocage) appliquée après SQL isolé complet code 0, cluster 55490 arrêté. Dernier build/install/run TECNO code 0 : 18,5 s/6,7 s/202 ms, processus 7381 et MainActivity observés, aucune donnée effacée. Contrôle visuel non effectué faute de fenêtre KIBO au premier plan confirmée ; aucune capture d'autre application. [Récapitulatif final et inventaire](MVP_AUTONOMOUS_RECAP.md). Les mentions « en cours » du paragraphe précédent sont historiques.

## MVP — notifications, signalements et modération, 2026-11-01

Trois parcours implémentés : centre personnel/cloche non lues et navigation ; signalements annonces/commentaires ; file administrateur, contenu signalé et décisions motivées avec journal atomique. Audit distant de métadonnées avant modifications, aucune donnée métier lue pour la recette. Contrat préparé/testé PG13 isolé ; accord explicite utilisateur puis application MCP **20261101051653 kibo_safety_workflows**, success=true. Aucune donnée existante modifiée lors de l'application. Nouveaux triggers pour les futurs messages/commentaires ; politiques existantes et guards réutilisés, droits directs reports UPDATE retirés au profit de la RPC contrôlée. RLS journal=true, log vide, aucun INSERT journal client ni UPDATE reports client, aucun EXECUTE visiteur ni definer public parmi les quatre RPC. Même avertissement sécurité Auth préexistant, aucun réglage changé.

25 nouveaux tests ciblés réussis (12 repository/13 widgets). Suites finales : **272 standard + 272 photos activées réussis**, analyse stricte sans anomalie (57,5 s), format 89 fichiers sans changement, diff check code 0. SQL enrichi code 0 sur 55485 : annonce et commentaire masqués uniquement par admin, journal protégé, rollback de décision lors d'une panne simulée du journal. Cluster arrêté, fixture conservée ; détails, fichiers et limites dans [NOTIFICATIONS_MODERATION.md](NOTIFICATIONS_MODERATION.md). Aucun signalement, masquage ou message réel de test. Aucun commit/push.

Lot compilé/installé/lancé sur TECNO H6929CK6NU012345 : `flutter run --no-resident --no-pub` via snapshot, configuration locale existante, photos activées, code 0 ; compilation 19,9 s, installation 8,0 s, synchronisation 363 ms. Processus PID 30419 et activité MainActivity observés après lancement. Aucune suppression de données ni attribution de rôle. Génération/réception de notifications entre deux comptes et recette administrateur réelles restent à effectuer ; push OS et administration web séparée hors de ce lot.

## MVP — lancement téléphone et lot chat, 2026-11-01

L'utilisateur demande d'intégrer puis d'exécuter le lancement sur son téléphone après chaque lot validé. Autorisation consignée dans AGENTS/WORKFLOW ; elle remplace l'interdiction antérieure de générer un exécutable pour cette recette, sans autoriser de commit/push ni de DML de test distant. Version contacts compilée/installée/lancée sur TECNO CK6n H6929CK6NU012345 : Flutter indique APK construit, installation 8,4 s, synchronisation 358 ms ; processus com.kibo.kibo observé (PID 23075). Configuration locale existante réutilisée sans affichage volontaire des valeurs ni effacement des données. Lancement réussi, recette complète des contacts toujours non effectuée.

Trois tâches chat terminées : conversations paginées, conversation avec messages texte persistants et actualisation Realtime/erreurs/vide/isolation. Navigation en-tête/Profil/détail catalogue et favoris. Contrat distant audité avant code : tables et guards existants réutilisés, aucune nouvelle permission de lecture. Publication initialement vide ; proposition ciblée testée sur fixture PG13, utilisateur autorise « Oui, activer Realtime pour le chat », migration **20261101050420 kibo_chat_realtime** appliquée success=true. Post-contrôle : les deux tables sont publiées, RLS toujours active. Conseiller sécurité : seul WARN Auth préexistant, aucun réglage changé. Aucun message réel envoyé par l'agent.

Validation finale : **247 tests standard + 247 photos activées réussis**, dont 20 nouveaux chat (10 repository/10 widgets), analyse stricte sans anomalie (13,7 s), format 84 fichiers sans changement, diff check code 0. SQL Chat code 0, réapplication idempotente testée, cluster 55483 arrêté. Tests couvrant aussi A/B/A pendant lecture SDK empêchant un INSERT tardif, navigation et pagination. Incidents non bloquants corrigés : fixtures Flutter (prix String/liste), sélecteur de sous-classe FilledButton et thème KIBO requis par la barre ; remarques de style et accès télémétrie du sandbox résolus. Aucun test supprimé. [Inventaire, contrats, commandes et limites](CHAT.md).

Lot chat également compilé/installé/lancé sur le TECNO avec `flutter run -d H6929CK6NU012345 --no-resident --no-pub` et les deux JSON de configuration existants, photos activées : code 0, compilation 16,6 s, installation 7,3 s, synchronisation 275 ms, processus actif PID 29686. Aucune désinstallation ni suppression de données. Réception réelle entre deux comptes/appareils, accusés de lecture, pièces jointes et recette hors réseau non validés. Notifications, signalements et modération restent à compléter. Aucun commit/push.

## MVP — profil vendeur et contacts volontaires, 2026-11-01

Validation finale terminée : **227 tests standard + 227 photos activées réussis**, dont 19 tests vendeur nouveaux (8 repository/11 widgets). Analyse stricte sans anomalie (29,1 s), format 80 fichiers sans changement, diff check code 0. SQL Contacts code 0 sur fixture isolée, cluster arrêté. Audit des droits réels : id/full_name/city lisibles par anon/authenticated, bio non autorisée ; projection finale réduite aux trois colonnes permises, sans élargir les droits. Suites relancées après cette correction. Aucun appel/message réel, numéro de recette, build, installation, commit ou push. Inventaire du lot dans SELLER_CONTACTS ; chat, notifications et modération restent à terminer.

Trois tâches enchaînées : profil public nom/ville lié depuis l'annonce ; préférences privées de coordonnées depuis Profil ; lancement WhatsApp/appel après session et relecture serveur du consentement. Nouveau contrat SQL préparé/testé localement sur PG13 isolé, puis explicitement autorisé et déployé par MCP : **20261101044111 kibo_seller_contacts**, success=true. RLS active, table vide au contrôle, visiteurs sans SELECT ni EXECUTE, clients sans UPDATE propriétaire/date, façade publique invoker et helper privé à entrée bornée. Aucun numéro Auth ni donnée existante repris/modifié. Conseiller sécurité : même WARN Auth préexistant.

Tests SQL fictifs passés, cluster 55482 arrêté. Les 17 tests vendeur initiaux ont été complétés par deux cas supplémentaires ; résultats finaux ci-dessus. url_launcher 6.3.2 transitif promu direct, pub get offline, pas de changement de version. Incidents non bloquants corrigés sans nouvelle demande : style, chevauchement d'une correction automatique et d'une édition dans le nouveau formulaire, invalidation A/B/A devenue synchrone via listener. Le test ancien excluant seller_id est adapté au profil public en conservant et renforçant les assertions d'absence de numéros/colonnes privées. [Contrat, déploiement et limites](SELLER_CONTACTS.md).

## MVP — déploiement propriétaire/privilèges et commentaires, 2026-11-01

L'utilisateur autorise la suite proposée (« vas y ») et demande de poursuivre les fonctionnalités malgré les incidents non bloquants. AGENTS/WORKFLOW alignés : corriger tests/style/outillage sans avis systématique ; préserver les arrêts pour les risques et autorisations réelles.

Déploiement MCP après relecture PG17.11/baseline : quatre apply_migration success=true, versions 20261101042109/42116/42123/42132. sold présent, deux guards hash 90f8a195363171aca55afe8223f1c35e, ACL conservées ; 54 grants TRUNCATE/REFERENCES/TRIGGER supprimés des tables actuelles, defaults postgres corrigés. L'acteur postgres n'est pas membre de supabase_admin : son delta defaults non appliqué, accès manquant consigné sans bloquer le développement. Aucun DML métier, Auth, Storage ou objet utilisateur touché. [Détails réels](OWNER_MANAGEMENT_DEPLOYED_20261101.md).

Fonctionnalités enchaînées : lecture des commentaires publics paginés depuis le détail, publication authentifiée, réponses à un niveau. Contrat distant listing_comments audité, lecture SQL anon LIMIT 0 réussie ; aucune migration supplémentaire ni écriture réelle de commentaire. Repository injectable, formulaire/navigation catalogue/favoris, validation Unicode, erreurs/reprise et isolation de session. **Version finale : 208 tests standard + 208 photos activées réussis**, dont 17 nouveaux (8 SDK/9 widgets), analyse stricte sans anomalie, format 75 fichiers conforme et diff check code 0. Dernières suites après date française vérifiée : 49 s standard, 32 s photos ; analyse 37,6 s. [Contrat/limites et fichiers](COMMENTS.md).

Incidents non bloquants corrigés dans le lot : mock HTTP sans request, tri ID implicitement descendant, défilement du test de catalogue et style. Pas de nouvelle demande d'avis, aucun test retiré. Conseiller sécurité Supabase : un WARN protection des mots de passe compromis désactivée, aucun réglage Auth modifié. Aucun build, installation, compte/donnée métier de recette créé, commit Git ou push. Le MVP n'est pas déclaré terminé : contacts, chat, notifications et signalements/modération restent à compléter.

## Lot SQL — trois tâches terminées localement, 2026-11-01

Validation finale du lanceur : **code 0** sur nouveau cluster 127.0.0.1:55479, arrêté et conservé sous `.dart_tool/owner-sql-717b082825d246909a4e4168563f1e16`. Delta enum/guards, assertions étendues avec les deux guards réels, privilèges de neuf tables et defaults des deux créateurs validés. Refus attendu de réapplication (psql 3, baseline), préservation ACL/RLS/voies admin, conflits de version, métadonnées photos/favoris et retours arrière des guards/grants réussis. Sources CRLF restaurées exactement et baseline vérifiée après rollback. Aucun TRUNCATE exécuté.

Audit distant de métadonnées seulement, serveur PG17.11 ; SQL testé sur PG13 local, sans Auth/Storage réels et sans écriture distante. Code Flutter inchangé : aucune nouvelle suite Flutter/analyse/build, résultats 191+191 du lot précédent conservés comme historiques. Diff check code 0. Les trois tâches sont prêtes pour revue, pas déployées ni certifiées production. Inventaire des 18 fichiers et limites dans [OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md](OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md). Aucun commit/push.

## Lot SQL — delta et assertions réussis, contrôles finaux de repli, 2026-11-01

Après accord utilisateur « Oui, corriger et terminer le lot », lanceur remplacé par ProcessStartInfo .NET sans fenêtre, attente de pg_ctl seul, collecte bornée et arrêt du cluster dans finally. L'exécution locale complète sur 55478 réussit : enum/guards, assertions propriétaire A/B/visiteur/admin, conflit updated_at entre transactions, vecteur/date, références photos et favoris, restauration exacte des deux guards, révocations ciblées et defaults des deux créateurs, contrôle des nouvelles tables. Cluster arrêté ; dossier .dart_tool/owner-sql-1d3a8999c53546cea87f343c0297f37c conservé.

Deux défauts de test/préparation ont été corrigés sans désactiver les gardes : le snapshot ACL de fixture dans public héritait des droits excessifs (déplacé en private) ; les retours CRLF exportés étaient normalisés dans le rollback (restauration par JSON pour préserver l'empreinte exacte). Le contrôle de baseline a détecté ces écarts comme prévu. Validation finale enrichie en cours : refus de réapplication et rollback des privilèges, sans TRUNCATE réel. Aucune modification Flutter ou distante, aucun exécutable/commit/push.

## Lot SQL propriétaire et privilèges — préparation, 2026-11-01

Trois tâches demandées : delta vente/archivage, test local de deux guards réels, proposition de durcissement clients. Audit de métadonnées distant READ ONLY : corps inchangés exportés sans données métier ; 54 grants excessifs directs sur neuf tables, default ACL public de postgres/supabase_admin et absence d'appartenance des rôles clients relevées. Deux étapes enum/guards et retours arrière préparés ; correction des trois privilèges séparée par tables et créateurs. Rien appliqué à distance, aucun Flutter modifié.

Lanceur PostgreSQL Windows en échec avant assertions : attente des descendants puis ExitCode null ; avis utilisateur demandé avant correction finale conformément au workflow. Trois clusters neufs distincts, dossiers conservés ; dernier arrêté proprement, deux premiers sans réponse/PID vivant au contrôle. Aucun succès SQL annoncé. Détails : [OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md](OWNER_MANAGEMENT_DEPLOYMENT_REVIEW.md).

## Favoris visiteurs — tâche 3, transfert explicite terminé localement, 2026-11-01

Offre dans Favoris après connexion, report « Plus tard », confirmation avec propriétaire/révision capturés. Fusion par ajout sans DELETE serveur, déduplication, confirmation par relecture des IDs du compte ; retrait local des seuls IDs confirmés. Échec partiel/disque/changement A/B/A : sélection restante conservée et aucun ajout au nouveau compte. Aucune copie des favoris du compte vers le stockage visiteur. Validation ciblée : **34 tests réussis** (28 favoris + 6 navigation), dont 18 nouveaux tests.

Suite initiale : 186 tests réussis, quatre timeouts navigation ; analyse : trois infos de style. Arrêt/avis conformément à WORKFLOW, autorisation utilisateur « Oui, corriger et terminer le lot ». Le stockage natif non injecté dans les tests généraux bloquait le chargement : store mémoire ajouté, délais inchangés et assertions conservées ; style corrigé. Contrôle supplémentaire : ajout/retrait local indépendant du réseau et offset corrigé après retrait. **Suites finales : 191 standard + 191 photos activées réussis**, codes 0 ; analyse stricte sans anomalie (27,0 s), format 71 fichiers sans changement, diff check code 0. Les trois tâches sont terminées localement. Détails et limites dans [GUEST_FAVORITES.md](GUEST_FAVORITES.md). Aucun accès Supabase distant pendant ce lot, aucune donnée réelle ni exécutable, aucun commit/push.

## Favoris visiteurs — tâches 1 et 2 du lot, 2026-11-01

Décision utilisateur : ajout/retrait sans connexion et persistance sur l'appareil avant le lot serveur. Nouveau contrôleur/store guest séparé des favoris des comptes, IDs seuls dans le stockage sécurisé existant avec clé isolée par projet. Pas de nouvelle dépendance. Lecture des fiches via le repository public existant : annonces retirées masquées sans suppression des IDs. Pages de vingt IDs, progression même si toute une page est indisponible. Cœurs, détail et onglet Favoris adaptés. Erreur lecture/corruption : aucune écriture écrasant la sélection ; erreur écriture : aucun faux succès ; logout n'efface pas la clé guest. Tests favoris initiaux : **21 réussis**, dont 11 nouveaux sur contrôleur/stockage/transfert. Validation finale et tests UI de transfert à suivre.

## Lot de trois tâches — recherche propriétaire (3/3), 2026-11-01

Recherche française serveur sur le vecteur titre/description existant, combinée au statut et à seller_id. Validation 120 caractères, bouton/clavier, réinitialisation des deux critères, pagination conservant les critères, réponses tardives ignorées. Quatre tests widgets et quatre tests repository ajoutés pour combinaison/pagination, réinitialisation, requête structurée, blanc/longueur, erreurs et réponses hors ordre. La suite complète standard passe : **173 tests**, soit 21 de plus que les 152 de la reprise précédente. Analyse stricte code 0 sans anomalie, format 68 fichiers conforme.

Incident réel : nouveau test de pagination échoué sur un bouton/champ hors arbre après défilement. Arrêt conformément à WORKFLOW puis autorisation utilisateur « Oui, corriger et terminer le lot ». Navigation du test corrigée ; l'assertion a ensuite révélé que FormState.reset pouvait restaurer l'ancien texte. Ordre reset puis clear corrigé, scénario isolé réussi puis suite complète réussie. Aucun test retiré ni assertion affaiblie. La revue a aussi ajouté une garde/validation indépendante lorsque le formulaire est démonté après défilement ; scénario étendu puis suites relancées. **Version finale : 173 standard + 173 photos activées réussis**, codes 0 ; analyse stricte sans anomalie (2,9 s), format 68 fichiers sans changement, diff check code 0.

Audit distant réel ajouté à [OWNER_LISTING_SERVER_AUDIT.md](OWNER_LISTING_SERVER_AUDIT.md), script readonly complété et exécuté avec succès. Métadonnées seules et ROLLBACK : aucune donnée métier lue/modifiée, aucun déploiement ni changement de droits. Le candidat de guard préexistant et les fixtures SQL ne sont ni modifiés ni exécutés ; aucune validation SQL locale du futur delta revendiquée.

## Lot de trois tâches — filtres de statut (2/3), 2026-11-01

Sélecteur Tous/Publiée/Vendue/Archivée/Brouillon/En attente/Refusée ajouté dans Mes annonces. Critère typé transmis au serveur avec seller_id, tri stable et pagination ; changement de filtre repart à zéro, état vide distinct. **36 tests ciblés réussis** (repository + widgets). Le choix Vendue nécessite toujours le futur contrat sold ; aucune exception serveur masquée, aucun changement distant.

## Lot de trois tâches — confirmation serveur (1/3), 2026-11-01

UPDATE relit maintenant la projection propriétaire : ID/identité, statut attendu, date valide et champs demandés vérifiés avant succès. Prix comparé en centimes BigInt sans arrondi flottant ; retour inattendu distinct d'un conflit, sans retry. **17 tests repository réussis**, dont six nouveaux. Travail local antérieur conservé. Aucun UPDATE réel ni build/commit/push.

Audit SQL connecté effectué en transaction READ ONLY puis ROLLBACK : enum réel draft,pending,published,rejected,archived (sold absent) ; deux guards UPDATE refusent les transitions vendeur. Le statut est donc un blocage serveur confirmé. Grants TRUNCATE présents pour anon/authenticated : risque séparé à traiter explicitement, aucun droit modifié.

## Reprise de la gestion des annonces — 2026-11-01

L'utilisateur choisit la gestion de ses annonces. Inspection de main/origin Smeth/kibo et inventaire local effectués ; nombreux changements suivis/non suivis conservés. Écrans Mes annonces/édition, repository propriétaire, intégration Profil et fixtures SQL déjà présents à la reprise, sans mention correspondante dans l'ancien suivi. Ils sont conservés et revus ; pas de réécriture de ce travail.

Compléments : PopScope bloque le retour pendant sauvegarde, garde contre les confirmations multiples, tests de navigation Profil → Mes annonces et de sauvegarde bloquant retour/double envoi. Résultats : **23 tests ciblés réussis, 152 tests Flutter standard réussis**, analyse stricte sans anomalie, format de 67 fichiers conforme et diff check code 0. Tentatives initiales sandbox bloquées puis interrompues ; contrôles relancés avec accès au SDK, premier format perturbé par le fichier de télémétrie puis réussi.

Le serveur réel n'est pas validé pour cette fonctionnalité : sold absent du contrat historique et guards UPDATE distants protecteurs du statut. Audit/candidat SQL et fixtures préexistants non exécutés. Aucun changement Supabase distant, donnée réelle, exécutable, installation, commit ou push. Détails et limites : [OWNER_LISTING_MANAGEMENT.md](OWNER_LISTING_MANAGEMENT.md).

## Retour de recette utilisateur — 2026-11-01

Après les corrections Supabase, l'utilisateur confirme sur le TECNO : « tout fonctionne maintenant sans problème ». Le blocage photos/catalogue est clos sur la base de ce retour utilisateur, sans prétendre à une nouvelle observation directe par l'assistant. Ce retour global ne constitue pas un relevé détaillé de chacun des scénarios de sécurité A/B, d'expiration de session ou de pagination.

Reprise suivante : inspection de Git, du workflow, de la feuille de route et des modules existants. La gestion des annonces du vendeur, les commentaires/réponses et les contacts vendeur ne sont pas implémentés dans les modules inspectés. Priorité produit demandée à l'utilisateur avant de choisir le prochain lot. Aucun changement applicatif ou distant, commit ou push pendant cette reprise documentaire.

## Supabase réellement corrigé après autorisation explicite — 2026-11-01

L'utilisateur autorise désormais l'intervention distante complète dans le périmètre KIBO. Une session Dashboard déjà authentifiée est trouvée dans Chrome via contrôle natif ; les anciennes limites « aucun accès SQL » ne sont plus actuelles. Audit réel, corrections et contrôles détaillés dans [SUPABASE_REPAIR_20261101.md](SUPABASE_REPAIR_20261101.md). Aucun secret extrait et aucun commit/push.

- Fonction private.is_admin() inspectée : boolean STABLE SECURITY DEFINER, search_path vide, rôle admin issu de auth.jwt().app_metadata.role ; anon EXECUTE=false, authenticated=true. Delta avec garde exacte appliqué : **GRANT EXECUTE à anon seulement**. Lecture publique passée de 401/42501 à **200**.
- Storage historique retrouvé : listing-images public, 5 Mio, table listing_images, deux policies upload/delete scoped à cet ancien bucket. Préservé intégralement. Variante **20261101022728_listing_photos_existing_storage.sql** créée et testée pour ajouter table et bucket privés KIBO + quatre gardes restrictives ; application avec la migration recherche **20261031220520** dans un lot transactionnel borné par timeouts/garde d'empreinte, historique source enregistré, cache PostgREST rechargé. Original photos intact et non exécuté, publication directe déjà déployée non rejouée.
- Fonction **kibo-upload-listing-photo déployée** via Dashboard avec index.ts testé et paquet Deno autonome ; verrou partagé conservé, copie locale à la fonction et deno.json adapté. Vérification JWT conservée, aucun secret ou compte Auth modifié.
- Vérifications distantes : catalogue avec relation photos **200**, table photos **200**, vecteur **200**, OPTIONS Edge **200** ; POST sans credentials et faux JWT **401** à la passerelle, clé publique seule **401/authentication** au handler. Bucket privé JPEG/4194304, RLS=true, 4 gardes restrictives, INSERT owner_id/UPDATE path interdits au client, deux index valides. **6 annonces avant/après**, images historiques0, réservations0 au contrôle ; empreinte des anciennes policies inchangée **3d072f7988e307137d9abd57c16e5a8a**. Aucun upload ou annonce de test, aucune suppression/recréation.
- Vérification locale de cette intervention : nouvelle fixture PostgreSQL isolée53225, variante avec ancien bucket/policy, tests de règle globale permissive, photos/recherche/propriété/favoris **tous réussis**, cluster arrêté. Deno check et **4 tests réussis** (~414ms). Flutter non modifié ici ; ses dernières suites **129+129** et build43,1s restent celles du lot précédent. Pas de nouvelle installation Android, pour préserver la reprise en mémoire.
- Prochaine recette utilisateur : si formulaire/aperçus encore présents, **Réessayer les photos une seule fois**, jamais nouvelle annonce ; sinon actualiser Accueil pour vérifier la lecture réparée. Aucun upload authentifié réel ou parcours physique A/B revendiqué par l'assistant. Les nouvelles migrations sont enregistrées ; la baseline des versions historiques et de l'ancienne proposition photos reste à réconcilier séparément avant tout db push global.

## Correctifs de compatibilité et causes distantes confirmées — 2026-11-01

Reprise après les captures P01/PO2 et demande de correction complète. Lectures REST autorisées avec clé publique locale, **limit=0**, aucune ligne privée : base listings **401/42501, permission denied for function is_admin** ; relation photos **400/PGRST200** ; table photo API **404/PGRST205** ; vecteur absent **400/42703**. OPTIONS fonction upload **404/NOT_FOUND**. Il s'agit de réponses distantes réelles, contrairement aux simulations précédentes ; pas d'audit des ACL/corps de fonction par clé publique. La réponse publique ne certifie pas les droits authenticated ou l'absence physique de table derrière un cache/exposition manquants.

- Correctifs locaux : projection photos optionnelle avec relecture bornée sans photos uniquement sur erreur de schéma ciblée, pour catalogue/détail/favoris ; indication explicite photos indisponibles. Aucune erreur RLS ou autre relation masquée. Recherche de compatibilité serveur titre OU description en français lorsque seule la colonne vectorielle manque, texte cité JSON, filtres/tri/page conservés ; différences sémantiques/performance documentées. Nouveau préflight lecture sans lignes + OPTIONS avant création avec photos ; panne préalable → zéro annonce créée, saisies/images conservées. Reprise existante toujours même ID, jamais une recréation.
- Préparation serveur : `supabase/audits/catalogue_compatibility_readonly.sql` pour corps/ACL is_admin, politiques/grants/contrat ; candidat séparé `supabase/proposals/restore_listing_read_execute.sql`, GRANT EXECUTE seulement si private.is_admin() boolean sans argument et corps sûr confirmés. Migrations originales intactes. Configuration locale Edge `supabase/config.toml` (JWT exigé/entrypoint) et deno.json (lock existant). Aucune modification distante appliquée.
- Tests finaux : analyse stricte sans anomalie, code 0, 6,0 s ; **129 Flutter photos activées**, code 0 (~16 s), et **129 standard**, code 0 (~22 s) ; **17 ciblés** après correction des premiers échecs locaux. Formatage conforme. Deno check nouvelle configuration et **4 tests Edge réussis** (~319 ms). SQL fixture : retrait EXECUTE reproduit le refus, GRANT ciblé rétablit la lecture ; assertions propriété/champs protégés/favoris réussies ; transactions annulées, cluster isolé arrêté. Incident du lanceur local et limites dans [CATALOGUE_PHOTOS_FIX.md](CATALOGUE_PHOTOS_FIX.md).
- Deux validations REST de syntaxe du mode de recherche, sans lignes, atteignent 42501 au lieu d'une erreur de parsing ; elles ne valident pas des résultats réels. Le droit is_admin reste à réparer côté serveur, pas à contourner dans Flutter. Plugin Supabase installé/activé confirmé par gestion des connexions mais aucun outil SQL exposé ici ; variables administratives courantes absentes, hôte navigateur indisponible. Aucun secret demandé/extrait.
- APK local corrigé : `flutter build apk --debug --no-pub --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` : **code 0**, assembleDebug **43,1 s**. `C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk`, **110696428 octets**, SHA-256 **FC17FAEE2E8C22E77896AF006A5907FDA10ADEAB4C422DEE288E5E11938CB93C**. Ancien APK archivé `.dart_tool/kibo-verifications/app-debug-before-catalogue-fix-c83238d633864a6cbc6c5888b571a829.apk` (hash 775B66D2…). **Aucune installation**, pour préserver le formulaire/photo en mémoire. Aucun scénario physique ni upload retenté.
- Le lot n'est pas revendiqué fonctionnel de bout en bout : audit ACL réel, application autorisée du delta et backend photos/recherche/Edge, puis recette autorisée restent nécessaires. Pas de SQL/donnée distante modifiés, annonce supprimée/recréée, commit/push ou déploiement. Travail local antérieur conservé ; dossier de diagnostic/action dans CATALOGUE_PHOTOS_FIX.md et PHOTO_UPLOAD_DIAGNOSTIC.md.

## Instrumentation locale de reprise photo — 2026-11-01

Demande exécutée dans le dépôt : `PhotoUploadDiagnostics` et transport HTTP expurgé, stages validation/session/réservation/lookup/Edge/confirmation, statut HTTP réellement reçu, code SQLSTATE/PostgREST ou Edge de liste fermée, attempt aléatoire local et sb-request-id UUID si présent. Pas de corps/URL/identité/chemin/hash/message brut/secret. Logs activés par défaut en debug seulement ; exceptions originales et requêtes inchangées, aucune nouvelle politique de retry. Le formulaire, son ID existant et ses photos ne sont pas modifiés. `http` 1.6.0 passe de dépendance dev à principale, `flutter pub get --offline` sans changement de version.

- Nouveau `scripts/Collect-PhotoUploadLogs.ps1` : PID existant seulement, collecte continue sans effacer logcat, reconstruction par liste de champs/valeurs autorisés vers fichier ignoré unique, aucun log brut conservé. Test sur fixture : une ligne valide conservée, lignes invalides/champs privés exclus. Aucune collecte sur le téléphone ou tentative réelle déclenchée pendant cette instrumentation.
- Tests ciblés : **13 réussis**, incluant 5 nouveaux tests de confidentialité, statut inconnu non inventé, transport intact, absence de logs hors contexte et sink cassé. Cas d'échec/reprise SDK enrichis par stage/statut/code/corrélation, sans recréation. Formatage réussi ; analyse stricte finale code 0 sans anomalie, 2,6 s ; suite complète `flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true --reporter expanded` : **118 réussis**, code 0, environ 14 s. Deux infos de style corrigées après le premier analyze ; aucun test désactivé.
- **Pas de mise en service sur TECNO** : ancien APK sans instrumentation, file de reprise uniquement en mémoire ; installation/restart risqueraient sa perte. Un hot reload ne garantit pas la réinitialisation du transport SDK ; aide attach consultée, aucune connexion/recharge tentée. Aucun APK compilé/installé pour ce lot. Activation sûre sur l'état existant encore à valider, donc nouvelle tentative instrumentée non effectuée. Cause réelle toujours indéterminée.
- Procédure conditionnelle précise, commande collecteur, geste unique Réessayer les photos et lecture des erreurs : [PHOTO_UPLOAD_DIAGNOSTIC.md](PHOTO_UPLOAD_DIAGNOSTIC.md), section Journalisation locale. Ne pas lancer la procédure sur l'ancien binaire en croyant collecter ces nouveaux événements. Alternative actuelle : logs distants existants via accès autorisé en lecture seule. Pas de modification distante, annonce supprimée/recréée, clic de reprise, commit/push/déploiement.

## Diagnostic publication réussie / photos incomplètes — 2026-11-01

Observation physique **rapportée par l'utilisateur** : « Annonce publiée, photos incomplètes, réessayer les photos ». Analyse dans [PHOTO_UPLOAD_DIAGNOSTIC.md](PHOTO_UPLOAD_DIAGNOSTIC.md). Cause du message démontrée : création published confirmée, puis réservation/invocation/upload distincts ; catch après ID conservé. **Cause exacte de l'échec photo distante indéterminée**, aucun statut HTTP observé. Cela ne prouve pas que Storage a reçu l'upload.

- ADB lecture seule : TECNO device, KIBO PID 13411 ; `logcat -d --pid=13411 -v brief -t 1500` retourne 32 lignes, aucun marqueur d'exception/42501/PGRST205/NOT_FOUND ni statut structuré exploitable. Aucun journal brut affiché/conservé. Catch Flutter et erreurs Edge masquées expliquent cette limite de diagnostic ; absence de log n'est pas absence d'échec.
- Contrat local code/SQL cohérent : table kibo_listing_photos, bucket privé kibo-listing-photos, chemin owner/listing/position-SHA256.jpg ; upload serveur seulement après validation. Pas d'outil Supabase actif pour comparer les objets/logs réels. Aucun changement distant proposé comme correctif prouvé ; documentation détaillant vérification REST → Edge → Storage, grants/RLS, réservation/objet et configuration serveur en lecture seule.
- Tests ajoutés : 7 cas SDK simulés (réservation 42501/PGRST205 sans invocation, Edge 401/404/502/503, seconde photo échouée puis reprise des chemins immuables). Widget renforcé : deux échecs successifs, images/ordre conservés, suppression verrouillée et une seule création. Edge : refus Storage 403/404/500 → 502/storage puis reprise, pas d'upsert. Le statut amont Storage est effectivement perdu par le protocole local actuel ; aucun de ces statuts n'est revendiqué comme observé sur appareil.
- Résultats : `dart format` des deux tests Dart réussi ; `flutter analyze --no-pub --fatal-infos` code 0, aucune anomalie, 4,9 s ; `flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true --reporter expanded` **113 tests réussis**, code 0, environ 26 s. Deno 2.5.6 fmt et test avec lock : **4 réussis**, environ 296 ms, services simulés. Première assertion UI supplémentaire corrigée (Tooltip n'est pas IconButton) avant la suite finale ; pas de changement produit pour contourner un test.
- `_createdId` et photos conservés seulement dans le formulaire vivant : garder l'écran ouvert, ne pas réinstaller/redémarrer/republier. Aucun clic de reprise, annonce supprimée/recréée, upload réel ou nouvelle installation effectué par l'assistant. Migrations, runtime Flutter/Edge et travail préexistant conservés. Seuls tests et documentation changés ; aucun commit/push/déploiement ou accès en écriture Supabase.

## Timeout photos corrigé et APK installé — 2026-11-01

L'utilisateur a demandé le diagnostic/correctif avant installation. Timeout reproduit en isolation avec flag true à l'ouverture de Publier : test de parcours avec services Auth/annonces/favoris fictifs mais sélecteur photo natif laissé par défaut ; récupération Android non simulée. Correction **du test seulement**, dans `test/listings/direct_publication_flow_test.dart` : services photo fictifs activés injectés lors des deux créations de KiboApp, récupération vérifiée sous A/B ; opérations photo inattendues refusées. Aucune assertion métier supprimée ni augmentation de délai/skip. Aucun changement des sources livrées ou migrations.

- Test ciblé corrigé : 1 réussi. Analyse stricte `flutter analyze --no-pub --fatal-infos` : aucune anomalie, code 0, 77,8 s. Suite complète `flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true --reporter expanded` : **106 réussis**, code 0, environ 25 s. Suite complète standard : **106 réussis**, code 0, environ 30 s. Formatage du test réussi ; diff contrôlé. Un premier placement de la nouvelle assertion de récupération avant ouverture a été rectifié avant ces résultats finaux.
- APK déjà compilé inchangé, SHA-256 `775B66D245F21A8F479BD93EB3CC9929D9775687C66F23086042B8819DF330B2` vérifié ; pas de rebuild pour un correctif de test. ADB get-state : device. Installation autorisée reprise après validation : `adb -s H6929CK6NU012345 install -r C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk` : **Success**, code 0. Package 1.0.0 (1), update 2026-11-01 02:35:00.
- App **non lancée**, aucun scénario manuel ou connecté exécuté, aucune donnée/objet Supabase distant modifié. La checklist [PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md](PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md) conserve les échecs historiques et donne cet état actuel ; dépendances D/P/S/E/R/F toujours à valider avant recette intégrée. Aucun commit/push ; autres changements locaux préservés.

## Préparation recette Android photos/recherche — 2026-11-01

Checklist créée : [PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md](PHYSICAL_TEST_PLAN_PHOTOS_SEARCH.md), étapes précises, préconditions D/P/S/E/R/F, preuves expurgées et cas d'erreur. Aucun scénario physique fonctionnel exécuté ni modification Supabase distante. La détection/compilation ne valident pas le backend.

- ADB : H6929CK6NU012345 en état device ; TECNO CK6n sous Android 14. Configuration locale ignorée et nature publique vérifiées sans impression de valeur. Changements préexistants inventoriés avant intervention, ancien APK archivé dans le répertoire ignoré.
- `flutter build apk --debug --no-pub --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` : **code 0**, assembleDebug 286,3 s. APK exact : `C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk`, 110696428 octets, SHA-256 `775B66D245F21A8F479BD93EB3CC9929D9775687C66F23086042B8819DF330B2`. aapt : com.kibo.kibo 1.0.0 (1), debug, min 24/cible 36, arm64 présent.
- Format sans réécriture : 58 fichiers conformes. Tests ciblés avec **photos activées** : **38 réussis, 1 échec**, code 1, timeout du premier pumpAndSettle dans `test/listings/direct_publication_flow_test.dart:36`. Code/tests inchangés ; aucune cause distante ou Android déduite. Analyse et suite standard du précédent audit non relancées.
- Installation autorisée dans la demande mais **suspendue après l'échec**, conformément à l'arrêt demandé par WORKFLOW ; avis utilisateur sollicité pour correction préalable ou installation malgré l'échec, sans lancement. Aucun adb install, lancement, effacement ni recette connectée exécuté. Le nouvel APK active la projection photos : ne pas lancer sur un backend non validé comme preuve d'intégration.
- `git diff --check` passé ; sources/migrations préexistantes conservées, index inchangé. Seuls la checklist et ces deux documents de suivi sont modifiés pour cette préparation. Pas de commit, push, migration/déploiement ni donnée distante créée.

## Audit pré-déploiement photos/recherche — 2026-10-31

**Préparation terminée ; déploiement distant non validé et non exécuté.** Plan : [DEPLOYMENT_PLAN_PHOTOS_SEARCH.md](DEPLOYMENT_PLAN_PHOTOS_SEARCH.md). Adaptations conditionnelles, séparées et non appliquées : [PROPOSED_PHOTOS_SEARCH_CORRECTIONS.md](PROPOSED_PHOTOS_SEARCH_CORRECTIONS.md). Migrations, code Flutter/Edge et tests préexistants inchangés ; inventaire SHA-256 préalable conservé dans le répertoire ignoré de vérification. Aucun commit, push, installation ou appel Supabase distant.

- Audit des trois deltas, des modèles/services Flutter, du validateur Edge, des politiques et assertions locales. Le contrat local est un bucket privé `kibo-listing-photos`, trois réservations immuables par annonce, objets accessibles par URL signée courte et upload uniquement via validation serveur. Le contrat Storage effectivement déployé n'est pas accessible ici ; aucune compatibilité distante certifiée.
- PostgreSQL 13.22 isolé, boucle locale 53215 : migrations originales appliquées dans l'ordre ; assertions publication, propriété/champs protégés/favoris et photos/recherche réussies. Réexécutions photos/recherche refusées comme attendu, sans altération de la fixture ; une politique Storage préexistante fait échouer le preflight sans être supprimée. Le delta recherche réécrit physiquement listings et nécessite un verrou ; refus attendu avec lecteur concurrent et lock_timeout=500ms, puis application réussie après libération. Un rôle fictif limité aux anciennes colonnes ne peut pas lire le nouveau vecteur. Cluster arrêté, fichiers conservés, service existant intact.
- `flutter analyze --no-pub --fatal-infos` : code 0, aucune anomalie, 3,3 s. `flutter test --no-pub --reporter expanded` : **106 tests réussis**, code 0, environ 14 s. Deno 2.5.6 check/tests avec verrou : **3 tests Edge réussis**, services simulés. Nouveau `test/audit/edge_photo_boundary_test.ts` : **1 test réussi**, JPEG synthétique bruité 1600×1600 de 3 743 980 octets, réponse 200 et une seule écriture simulée, environ 1044 ms ; aucune garantie de performance hébergée déduite de ce temps mural.
- Points de validation humaine : politiques/ACL et fonctions dépendantes réelles ; variante photos si des politiques Storage existent ; éventuel SELECT ciblé sur le vecteur ; volume/espace/fenêtre SQL ; historique des migrations ; configuration, verrou et démarrage Edge avec JWT ; recette autorisée A/B et appareil avant diffusion Flutter. Les propositions SQL ne constituent pas des migrations validées ou appliquées. Pas de test distant, de Storage HTTP réel, de bundle/runtime Supabase complet ou de recette physique effectué.
- Les commandes détaillées, incidents du lanceur local, contrôles finaux de diff/empreintes, limites de reprise et stratégie de retour sans suppression sont consignés dans le plan. Les anciens résultats ci-dessous restent historiques ; ils ne prouvent pas un déploiement.

## Lot parcours, photos et recherche — implémentation locale

Les trois étapes ont été traitées dans l'ordre sur main, en préservant les changements non committés déjà inventoriés. Aucun fichier préexistant supprimé ; aucun reset, nettoyage, commit, push, déploiement ou changement Supabase distant. Le socle Auth/profil, la configuration réelle et la migration de publication directe sont conservés. Le hash du delta de publication est inchangé.

1. Parcours vendeur/acheteur : test intégré étendu de A vers B, favori actualisé, recréation de KiboApp/contrôleurs sur repositories fictifs persistants, isolation A/B et retrait. Les fakes de favoris sont maintenant séparés par utilisateur ; le test de réponse tardive est adapté à ce stockage. Tests des refus, statuts/dates, erreurs réseau et chargements conservés.
2. Photos : sélection appareil injectable, JPEG/PNG/WebP, 3 maximum, compression/redimensionnement dans un isolate, suppression des métadonnées, aperçu/suppression/ordre/principale. Source 20 Mio/24 MP, résultat JPEG 1600 px/4 Mio. Reprise d'envoi avec le même ID d'annonce, réservation immuable et chemins stables, pas d'upsert. Scope photos transmis au détail et aux Favoris ; affichage, erreurs et reprise par URL signée privée de 60 s. Marqueur de compte sécurisé pour empêcher la récupération Android d'images d'un autre compte.
3. Recherche : onglet dédié avec titre/description, catégorie, ville exacte, min/max XAF, trois tris et effacement. Requêtes Supabase combinées, vectorisation française, pages de 20, ID secondaire explicite, invalidation des réponses obsolètes et états distincts. Pas de filtrage production de tout le catalogue en mémoire.

Contrat photo existant introuvable localement : l'utilisateur a autorisé une proposition locale. Audit Storage distant non réalisé, outils non exposés ; aucune politique distante inventée. Bucket privé kibo-listing-photos et table kibo_listing_photos proposés dans 20261031220517_listing_photos.sql. La migration refuse les collisions et toute politique Storage existante pour empêcher un contournement permissif OR ; une revue distante est indispensable avant application. Fonction Edge locale kibo-upload-listing-photo : Auth utilisateur validée, propriété/réservation vérifiées, limites réelles de corps/image, décodage JPEG et réencodage sans EXIF/GPS avant upload serveur. Aucun secret dans Flutter. Photos désactivées par défaut via KIBO_LISTING_PHOTOS_ENABLED ; activation uniquement après autorisations de migration/déploiement. La recherche textuelle nécessite 20261031220520_catalogue_search.sql (tsvector généré, index GIN et prix).

### Commandes et résultats effectivement obtenus

| Commande / périmètre | Résultat final |
|---|---|
| git status --short --branch, remote -v, inventaire SHA-256 local avant/après | Changements préexistants conservés ; seulement fichiers attendus modifiés/ajoutés, index non préparé. |
| flutter pub get | Réussi avec image_picker 1.2.1, image 4.5.4 et crypto 3.0.8 ; lockfile et registrants générés actualisés. Pas de mise à niveau Flutter. |
| dart format lib test, puis format --output=none --set-exit-if-changed lib test | Réussi, 58 fichiers ; contrôle final 0 changement, code 0. |
| flutter analyze --no-pub --fatal-infos | Aucune anomalie, code 0, dernier passage 3,2 s. |
| flutter test --no-pub --reporter expanded | **106 tests réussis**, code 0, dernier passage environ 12 s. Les 95 précédents sont conservés/adaptés ; 11 tests nouveaux. |
| flutter test --no-pub --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true test/listings/listing_repository_test.dart test/favorites/favorites_repository_test.dart test/listings/listing_photo_widgets_test.dart --reporter expanded | **9 tests réussis**, code 0 ; projection photo activée uniquement dans les simulations. |
| npx.cmd --yes supabase@2.54.11 migration new listing_photos ; ... migration new catalogue_search | Deux fichiers locaux générés puis complétés ; aucune liaison ou application de migration distante. |
| npx.cmd --yes deno@2.5.6 check .../index.ts .../index_test.ts ; deno fmt ; deno cache --lock=supabase/functions/deno.lock ; deno test --no-prompt --lock=... .../index_test.ts | Typage réussi et **3 tests Edge réussis**, Auth/REST/Storage entièrement simulés, aucune requête réelle. Dépendance JPEG verrouillée. |
| PostgreSQL 13.22 : initdb cluster jetable, pg_ctl start, psql -X -v ON_ERROR_STOP=1 | Fixture initiale, delta publication, stub Storage, deltas photos/recherche puis assertions publication/propriété/photos/recherche : **tous réussis**, codes 0. Transactions d'assertions annulées. |
| pg_ctl -D <cluster photos> -w stop -m fast, puis status | Arrêt réussi ; aucun serveur actif pour ce cluster. Service PostgreSQL existant laissé intact. |
| git diff --check ; git diff --cached --check | Réussis ; seuls avertissements LF/CRLF préexistants. |

Tests SQL utilisés : test/sql/direct_publication_assertions.sql, direct_publication_ownership_assertions.sql et listing_photos_assertions.sql. Les tests photos vérifient limite de trois positions/PK unique, refus d'upload direct, réservation propriétaire seulement, immutabilité, lecture publiée et masquage pending, et recherche serveur combinée. Stub des catalogues Storage uniquement, pas une instance du serveur Storage Supabase.

Incidents corrigés pendant la tâche : dernière version image_picker incompatible Dart 3.10.4, version compatible choisie ; CLI npm courante sans binaire Windows, CLI officielle 2.54.11 utilisée ; npx.ps1 refusé par PowerShell, npx.cmd utilisé sans changer la politique système ; erreurs initiales de fixture multi-compte, décodage d'image tronquée, requêtes HTTP simulées, ordre SDK implicite et test de défilement corrigées. Accolades ajoutées par dart fix ciblé et correction du type BufferSource dans le test Edge. Premier port local 55469 indisponible, nouveau port libre 54933 choisi avant exécution SQL. Contrôle de format restreint échoué sur cache de télémétrie après formatage conforme ; relance avec accès SDK autorisé : code 0. Aucun de ces incidents n'a nécessité un changement distant ou une suppression de travail.

### Limites et suite

Documentation complète et inventaire exact des fichiers : LISTING_PHOTOS_SEARCH.md. Photos prêtes côté code et contrat local, **pas activées sur Supabase réel** ; recherche texte dépend de son delta non appliqué. Reprise photos limitée au formulaire vivant ; pas de file persistante d'uploads après fermeture. Cache natif du sélecteur géré par le plugin/OS, non vérifié physiquement. Nettoyage distant non automatique : audit readonly des réservations/objets orphelins proposé, toute purge nécessitant un protocole distinct.

Aucun APK construit/installé, aucune recette physique Android/iOS, aucun test de JWT/URL signée/expiration/quotas/upload HTTP ou concurrence Storage réelle. Les tests Edge et SQL ne certifient pas ces comportements distants. La publication réelle reste soumise au delta RLS de publication directe et aux autorisations précédemment documentées. Prochaine étape : audit readonly du Storage réel et comparaison du contrat proposé ; adaptation sans affaiblissement, puis autorisations séparées avant migrations/Edge/recette de comptes A/B.

## Publication directe — cause distante confirmée et SQL final proposé

Les faits audités distants fournis par l'utilisateur remplacent le blocage historique d'accès ci-dessous : listings_insert_own autorise draft/pending seulement, published_at doit être NULL, authenticated possède INSERT et les triggers existants relevés sont BEFORE UPDATE. Le tuple published/date du client échoue donc au prédicat RLS INSERT ; cause identifiée sur la base de cet audit confirmé, sans réauditer ni inventer un export SQL complet.

Migration relue et **compatible avec les faits confirmés** : conserver sans modification supabase/migrations/20261031050000_direct_listing_publication.sql, SHA-256 3976C7FF2D33E3CB1998AC7146E6CCB4DE60259C7CA2220F0CA403E6E8E80969. Effet minimal : trigger BEFORE INSERT d'horodatage serveur et adaptation de la politique INSERT existante, propriétaire courant/vues 0/rejet NULL conservés ; aucune nouvelle politique OR, aucun élargissement de grant, aucun changement des triggers UPDATE/lecture/favoris ou des annonces existantes. Preflight transactionnel conservé, refus d'écart/collision à respecter.

Assertions de publication/propriété/champs protégés/favoris/ancien prédicat relues et couverture confirmée. Pas de nouvelle exécution : aucune donnée de test créée, même localement. Les réussites PostgreSQL précédentes restent historiques. Détails et limites de provenance dans RLS_PUBLICATION_AUDIT.md, section État courant ; trois documents de suivi uniquement modifiés, sources/tests/SQL préservés.

Étape suivante : autorisation distincte d'appliquer ce seul fichier complet avec son preflight, puis vérification des objets modifiés et recette distante séparément autorisée : publication A → heure serveur → catalogue → détail → favoris → isolation B. Pas d'audit distant répété, migration appliquée, annonce créée, commit ou push pendant cette revue. git diff --check exécuté ; pas de tests Flutter relancés pour cette revue documentaire.

## Nouvelle demande GitHub/Supabase — 2026-10-31 : connexions non exposées

Contrôle frais du registre des intégrations demandé par l'utilisateur : **GitHub et Supabase ont installed=false**, malgré leur statut de disponibilité ENABLED/AVAILABLE. Aucun outil GitHub/Supabase dans les outils actifs de cette session. Une suggestion Supabase existe déjà ; elle ne vaut pas connexion. Pas de nouvelle proposition identique ni d'installation automatique.

Contrôles locaux complémentaires sans valeurs : aucune variable Supabase/PG/DATABASE_URL dans Process/User/Machine ; config utilisateur MCP sans mention GitHub/Supabase ; pgpass zéro entrée ; CLI gh et Supabase absentes. Le remote Git origin Smeth/kibo existe, mais ne constitue ni une connexion GitHub authentifiée vérifiée ni un accès aux catalogues Supabase. Changements préexistants conservés.

Résultat : projet fcfmfpywpurrvppxdltm non interrogé ; **aucune définition SQL distante observée**, aucune exécution distante du script readonly et aucune cause exacte du 42501 démontrée. Compatibilité migration/distant **encore indéterminée**. Le conflit draft/pending/date NULL reste démontré uniquement sur la fixture locale et décrit dans le contrat historique.

Prochaine étape : terminer l'installation et l'authentification de Supabase dans la même session/application, puis vérifier l'apparition de ses outils et l'accès au projet avant de relancer l'audit readonly. Authentification uniquement dans le flux de connexion, sans clé dans le chat. Autre voie déjà préparée : connexion MCP officielle restreinte au projet en read_only=true, ou audit par l'opérateur dans Dashboard ; détails dans RLS_PUBLICATION_AUDIT.md. La connexion GitHub pourra permettre la lecture du dépôt, mais ne remplace pas l'accès SQL Supabase.

Seuls PROGRESS.md et NEXT_TASK.md actualisés. Migration, script d'audit, code et configuration inchangés ; git diff --check exécuté. Aucun SQL distant, donnée de test, commit ou push.

## Accès audit distant — 2026-10-31 : encore indéterminé

Nouvelle inspection Git/consignes, migration et script readonly effectuée. Aucun outil Supabase actif. Recherche d'intégrations : Supabase existe mais non installé/non connecté ; proposition présentée, aucune installation/connexion confirmée. Variables Supabase/PG/DATABASE_URL absentes de Process/User/Machine ; pgpass existant sans entrée non commentée, aucun pg_service, token CLI ou projet lié détecté. psql 13 disponible au chemin connu ; aucun accès distant configuré. Configurations MCP projet absentes ; config utilisateur sans mention Supabase (contenu non affiché). Aucun secret copié/affiché et aucune session extraite.

**Définitions SQL distantes observées : aucune. Script readonly non exécuté à distance. Compatibilité migration/distant : encore indéterminée.** Les clauses draft/pending/date NULL restent un contrat historique et une preuve sur fixture, pas des métadonnées distantes fraîchement vérifiées. Pas de nouvelle comparaison distante possible.

Action nécessaire : installer/connecter Supabase avec authentification utilisateur hors chat et vérifier les outils exposés ; pour restriction serveur explicite, connexion MCP officielle limitée au projet avec read_only=true et features=database (URL sans secret et étapes dans RLS_PUBLICATION_AUDIT.md). Alternative immédiate : opérateur déjà autorisé dans Dashboard KIBO > SQL Editor, exécuter uniquement supabase/audits/direct_publication_readonly.sql et récupérer tous les résultats des catalogues. Conserver BEGIN READ ONLY/ROLLBACK ; ne pas lancer la migration. Ne partager aucune clé, mot de passe ni URL de connexion avec secret. Revoir les corps de fonctions avant partage des résultats.

Docs RLS_PUBLICATION_AUDIT/PROGRESS/NEXT_TASK complétées ; code, migration et script SQL inchangés. Aucun appel Supabase distant, SQL appliqué, annonce distante, commit ou push. git diff --check contrôlé ; tests non relancés pour cette documentation et cet inventaire d'accès.

## Audit du refus 42501 — 2026-10-31 : preuve distante manquante

Compte A connecté confirmé par l'utilisateur. Code, migration et assertions relus. Le client envoie published et une date non NULL ; les clauses anciennes `status IN (draft,pending)` et `published_at IS NULL` refusent ce tuple sur la fixture. **Cause exacte distante non démontrée**, faute d'accès aux métadonnées : aucun outil Supabase connecté, aucune variable PG/Supabase administrative, aucune entrée pgpass exploitable ni token/projet CLI configuré détecté ; hôte navigateur indisponible et accès Chrome expiré sur l'autorisation. Aucune clé secrète demandée/affichée, aucun appel distant effectué.

Livrables : docs/RLS_PUBLICATION_AUDIT.md (preuves, hypothèses, accès, delta minimal conditionnel), supabase/audits/direct_publication_readonly.sql (catalogues uniquement, BEGIN READ ONLY/ROLLBACK), test/sql/direct_publication_ownership_assertions.sql (isolation UPDATE/INSERT, champs protégés et favoris). Migration et code existants inchangés. Le delta existant reste proposé seulement si l'audit exact confirme son contrat ; aucun grant large ni relâchement RLS ajouté.

Exécution réelle : pg_ctl démarre le seul cluster jetable connu sur 127.0.0.1:55459 ; pg_isready confirme sa disponibilité ; psql -X -v ON_ERROR_STOP=1 exécute assertions existantes, nouvelles assertions ownership, legacy_policy et audit readonly, tous code 0. Transactions de test annulées, pg_ctl stop -m fast réussi. Ancien prédicat refuse published ; B ne peut modifier/publier A, champs privilégiés verrouillés et favoris isolés. Tests exclusivement locaux, pas un audit du serveur réel.

Prochaine étape obligatoire : rendre disponible un accès de métadonnées autorisé ou faire exécuter le script readonly par l'opérateur déjà autorisé, puis comparer politiques/grants/triggers exacts et leurs fonctions dépendantes au delta. Ne pas appliquer la migration ni tester d'écritures distantes avant autorisation distincte. Aucun reset, commit, push, modification distante ou nouvelle annonce de test distante.

## Recette TECNO : refus de publication signalé — 2026-10-31

Observation utilisateur : connexion initialement nécessaire ; ensuite, au clic sur « Publier l'annonce », message « Publication refusée. Reconnectez-vous ou contactez l'assistance. ». L'utilisateur a donc atteint le formulaire et tenté une soumission ; identité A et état exact de session non vérifiés indépendamment.

Revue locale : listing_repository.dart transforme un PostgrestException code 42501 (droits insuffisants) en ListingPublicationDenied ; publish_listing_page.dart affiche précisément ce message. Il s'agit donc d'un refus d'autorisation signalé par le backend, sans preuve de la politique ou du trigger exact responsable. Hypothèse principale cohérente avec le contrat documenté : client INSERT published alors que l'ancienne politique n'accepte que draft/pending et delta non appliqué par l'agent. Les grants, triggers et identité peuvent également intervenir ; aucune conclusion distante définitive.

Commandes : git status --short --branch ; recherche rg du message/42501 ; adb shell pidof et logcat -d --pid=<processus> -v brief -t 300 filtré : aucun diagnostic correspondant PostgREST/42501/crash/exception Flutter dans cet extrait. L'erreur est gérée par l'application ; absence de log ne signifie pas absence du refus.

Recette arrêtée à la publication : catalogue de la nouvelle annonce, détail, favoris, relance fonctionnelle et isolation A/B non validés. Ne pas multiplier les soumissions ni changer RLS pour contourner le refus. Prochaine étape : audit en lecture seule des définitions exactes de politiques/grants/triggers et comparaison avec le delta préparé ; application uniquement après autorisation distincte. Aucune modification Supabase distante, migration appliquée, modification du code, commit ou push pendant ce diagnostic. Seuls PROGRESS.md/NEXT_TASK.md complétés, changements existants conservés.

## Installation TECNO et démarrage — 2026-10-31

Installation explicitement autorisée de l'APK debug déjà compilé, sans relancer les contrôles de compilation/configuration/présence ADB. État Git et consignes relus ; changements locaux conservés. Commandes exécutées avec le chemin ADB du SDK local et `-s H6929CK6NU012345` :

1. `install -r C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk` : **Success**, code 0. Aucune désinstallation ou suppression de données.
2. `shell am start -W -n com.kibo.kibo/.MainActivity` : **Status ok**, démarrage COLD, TotalTime 5405 ms. `shell pidof com.kibo.kibo` : processus 31269 au premier contrôle. `shell dumpsys activity activities` : MainActivity au premier plan.
3. `logcat -d --pid=<processus> -v brief -t 200` puis nouvel extrait de 300 lignes : aucun FATAL EXCEPTION, Unhandled Exception ou E/flutter observé. Avertissements OEM Transsion/ClassNotFound et erreurs de négociation de formats OpenGL/gralloc/AHardwareBuffer présents ; application toujours active. Cela ne prouve pas le rendu visuel, la connexion Supabase ou le succès fonctionnel. Les sorties utiles ont été filtrées sans clé/JWT/URL ; aucun journal brut versionné.

Recette physique guidée, **en attente d'observations utilisateur** : préparer sous A une annonce sans photo, titre Test KIBO 31-10, description fictive, 1000 XAF, catégorie active et Brazzaville. Après soumission unique : relever exactement confirmation ou erreur, puis si succès vérifier carte catalogue, détail, ajout/retrait synchronisés et persistance après relance, puis isolation de B. Ne pas multiplier les soumissions après erreur réseau non confirmée. Aucun de ces résultats fonctionnels n'est encore constaté ; installation et démarrage seuls réussis.

Le suivi indique un delta de publication directe non appliqué au serveur par l'agent et un audit RLS distant restant. Aucun changement distant SQL/RLS/configuration effectué pour contourner un refus éventuel. Aucun INSERT/DELETE distant exécuté par l'agent, aucun commit ni push. La prochaine étape est le retour utilisateur sur le formulaire et, si la recette est effectuée, son résultat exact ; ne pas marquer création/catalogue/détail/favoris/isolation comme validés sans observation.

## APK debug configuré compilé — 2026-10-31

Cette vérification remplace le blocage historique de fichier absent ci-dessous. config/supabase.local.json est présent, ignoré par `/config/*.local.json` et non suivi. Ses champs SUPABASE_ANON_KEY et supabaseAnonKey contiennent la même clé reconnue comme publique ; son URL dupliquée est identique à config/supabase.public.json. Aucun contenu sensible affiché et aucune configuration modifiée. Le premier contrôle exigeant un champ unique a été arrêté ; après inspection des seuls noms de champs et vérification de leurs valeurs en mémoire, ces doublons bénins ont été conservés. Recherche indicative des fichiers suivis/non ignorés : aucune copie des clés locales, clé sb_secret réelle, JWT service_role ou clé privée détectée ; ce contrôle ne constitue pas une garantie exhaustive.

Inventaire : main, HEAD bca1aa2, origin Smeth/kibo, index vide ; 25 fichiers suivis modifiés et 48 non suivis préexistants conservés. Empreintes avant/après compilation, configuration locale comprise : aucun changement. Seuls PROGRESS/NEXT_TASK complétés pour cette tâche ; sorties build ignorées.

Commande exécutée avec les dépendances existantes et accès autorisé aux caches locaux :

```powershell
& 'C:\flutter\bin\flutter.bat' build apk --debug --no-pub --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
```

Résultat : **code 0**, assembleDebug 69,5 s. APK confirmé par Get-Item/Get-FileHash :
- Chemin : C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk
- Taille : 110695992 octets.
- SHA-256 : 781D42361722E8121B5A601FC75552DDA76301CF0F7AD41BE17E51DB638AF511.
- `aapt dump badging` : com.kibo.kibo, version 1.0.0 (1), application-debuggable, min SDK 24, cible 36, arm64-v8a présent (l'APK debug contient aussi des bibliothèques armeabi-v7a/x86_64).

`git check-ignore -v`, `git ls-files`, recherche locale sans valeurs, inventaire/empreintes, `git diff --check`, `adb devices -l`, `get-state` et `getprop ro.product.model` effectués : exclusion correcte, diff check réussi (avertissements LF/CRLF préexistants), TECNO CK6n H6929CK6NU012345 en état device, encore détecté après compilation. Les tests/analyse de la précédente session ne sont pas présentés comme relancés ici. Aucun appel Supabase ou changement distant ; compilation seule ne valide ni connexion réelle ni publication directe.

Prochaine action : attendre la confirmation explicite d'installation, puis utiliser uniquement :

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s H6929CK6NU012345 install -r 'C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk'
```

Aucune installation, désinstallation, ouverture de l'application, modification Supabase distante, migration, commit ou push effectué. La recette réelle de publication reste soumise aux prérequis RLS et autorisations distinctes déjà documentés.

## Préparation APK configuré — 2026-10-31 : bloquée avant compilation

Nouvelle inspection sur main : 25 fichiers suivis modifiés, 48 non suivis, index vide, remote origin Smeth/kibo. Empreintes comparées avant cette note : aucun fichier préexistant modifié/supprimé. Aucun nettoyage ou remplacement.

`git check-ignore -v config/supabase.local.json` confirme la règle `/config/*.local.json` ; `git ls-files --error-unmatch` confirme que ce chemin n'est pas suivi. Cependant **le fichier config/supabase.local.json est absent du dépôt local accessible**, malgré l'annonce de sa saisie. Inventaire de config/ : uniquement supabase.public.json et supabase.local.example.json. Variables SUPABASE_URL/SUPABASE_ANON_KEY absentes dans Process/User/Machine. Le contrôle initial du JSON a donc échoué avant toute compilation ; aucun build lancé ni APK courant certifié. Aucun secret créé, remplacé, extrait ou affiché.

Recherche indicative dans les fichiers suivis/non ignorés : aucun candidat réel sb_secret, JWT service_role ou clé privée. Seul candidat sb_secret détecté dans test/core/supabase_config_test.dart : valeur explicitement fictive du test de rejet des clés privilégiées, relue et confirmée. Ce contrôle ne certifie pas tout secret possible ni le contenu du fichier absent.

`adb devices -l`, `adb -s H6929CK6NU012345 get-state` et `shell getprop ro.product.model` confirment TECNO CK6n, état device. Aucune installation ou lancement de l'application. Aucun changement Supabase distant, commit ou push.

Prochaine étape : enregistrer le fichier local au chemin exact C:\Users\MONSTER\Documents\WORKSPACE\KIBO\config\supabase.local.json, uniquement avec SUPABASE_ANON_KEY publique, selon DEVELOPMENT_SETUP ; ne pas transmettre sa valeur dans le chat. Après vérification locale, commande de compilation prévue, non exécutée :

```powershell
& 'C:\flutter\bin\flutter.bat' build apk --debug --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
```

APK attendu après succès, non certifié par cette tentative : C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk. Installation uniquement après confirmation explicite et compilation réussie :

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s H6929CK6NU012345 install -r 'C:\Users\MONSTER\Documents\WORKSPACE\KIBO\build\app\outputs\flutter-apk\app-debug.apk'
```

## Nouvelle vérification locale — 2026-10-31 (TECNO connecté)

- Inventaire initial : main, HEAD bca1aa2, origin https://github.com/Smeth/kibo.git, index vide, 25 fichiers suivis modifiés et 48 non suivis. Empreintes des fichiers suivis/non ignorés comparées avant la mise à jour documentaire : aucun changement. Travail préexistant conservé ; seuls PROGRESS.md et NEXT_TASK.md complétés. Archives de vérification ignorées sous .dart_tool/kibo-verifications, aucun fichier supprimé.
- `dart format --output=none --set-exit-if-changed lib test` : code 0, 50 fichiers, 0 changement. `flutter analyze --no-pub --fatal-infos` : code 0, aucune anomalie, 4,9 s. `flutter test --no-pub --reporter expanded` : code 0, **95 tests réussis**. `flutter test --no-pub --reporter expanded .dart_tool/kibo-verifications/direct_publication_roundtrip_test.dart` : code 0, **1 scénario simulé réussi**, création published, catalogue, détail, ajout puis retrait du même favori et détail à nouveau sans favori. Aucun test distant ou physique assimilé à ces résultats.
- Premières commandes Flutter en environnement restreint sans sortie, interrompues ; relance avec accès autorisé aux outils locaux réussie. Lecture CIM des processus refusée, sans effet sur les validations. `git diff --check` et `git diff --cached --check` : réussis, seuls avertissements LF/CRLF préexistants.
- Migration relue contre LISTINGS.md et la fixture : INSERT propre draft/pending avec date NULL étendu à published avec horodatage serveur, vues 0 et rejet NULL ; autres politiques conservées. SECURITY INVOKER, search_path pg_catalog, aucune désactivation RLS ni modification de données existantes. Le preflight ne compare pas le texte complet de l'ancien WITH CHECK : audit exact des politiques/grants/triggers distants toujours requis, non réalisé ici.
- PostgreSQL 13.22 : nouveau cluster jetable sous .dart_tool/kibo-verifications/pg-a7cfcab9fb9540e2a0ec4090048631ac, 127.0.0.1:55459, utilisateur fictif kibo_check. `initdb -D <cluster> -U kibo_check --auth=trust --encoding=UTF8 --locale=C`, démarrage pg_ctl, puis `psql -X -h 127.0.0.1 -p 55459 -U kibo_check -d postgres -v ON_ERROR_STOP=1 -f <fichier>` sur fixture, migration, assertions et legacy_policy : codes 0. Publication/date serveur, lecture B/anon, ajout favoris, isolation A/B et refus des champs privilégiés/INSERT anon vérifiés ; ancien prédicat refuse published. Transactions d'assertions annulées, cluster arrêté avec `pg_ctl -D <cluster> -w stop -m fast` (code 0). Aucun service existant touché.
- Incidents de lancement SQL : premier démarrage restreint refusé (restricted token, erreur 87), aucun SQL exécuté. Après relance autorisée, Start-Process -Wait attendait encore le descendant serveur malgré sa disponibilité ; les quatre fichiers ont été exécutés depuis une commande distincte, puis le serveur arrêté. Le lanceur initial s'est alors terminé avec connexion refusée sur sa tentative tardive de fixture ; cette tentative n'a rien exécuté. Aucun processus de vérification laissé en attente, cluster arrêté.
- `adb devices -l`, `adb -s H6929CK6NU012345 get-state` et `shell getprop ro.product.model/ro.build.version.release/ro.product.cpu.abi` : **TECNO CK6n, device, Android 14, arm64-v8a**. `flutter devices --device-timeout 5` lancé mais interrompu sans sortie ; la détection confirmée provient d'ADB. Aucun build, installation, lancement ou effacement de données de l'application.
- Configuration : config/supabase.local.json absent ; variables SUPABASE_URL/SUPABASE_ANON_KEY absentes dans Process/User/Machine, sans affichage de valeurs. Exclusion Git du fichier local confirmée. Aucun secret extrait, demandé dans le chat ou créé.

Prochain geste : renseigner uniquement la clé publique localement selon DEVELOPMENT_SETUP, puis compiler avec les deux fichiers de configuration. Commandes préparées, non exécutées :

```powershell
flutter build apk --debug --target-platform android-arm64 --dart-define-from-file=config/supabase.public.json --dart-define-from-file=config/supabase.local.json
# Uniquement après confirmation explicite d'installation :
adb -s H6929CK6NU012345 install -r build/app/outputs/flutter-apk/app-debug.apk
```

Recette manuelle après audit/application du delta et écritures de test séparément autorisés : créer sans photo à 1000 XAF sous A, vérifier published/date serveur, carte immédiate, détail relu, ajout/retrait synchronisés des favoris, relance puis isolation B/visiteur. Le delta distant n'est pas appliqué par cette session ; aucune publication réelle validée. Aucun commit, push, déploiement ou changement distant.

Dernière mise à jour : 2026-10-31

## Reprise des vérifications locales KIBO-008/009/010 et publication directe

Vérification du 2026-10-31 sur `main`, avec inventaire et empreintes des changements préexistants. Aucun code applicatif, test, migration ou configuration modifié pendant cette reprise ; seuls PROGRESS/NEXT_TASK sont complétés. Aucun commit, push, déploiement ou appel Supabase distant.

- `dart format --output=none --set-exit-if-changed lib test` : 50 fichiers, 0 changement, code 0.
- `flutter analyze --fatal-infos` : aucune anomalie, 25,8 s, code 0.
- `flutter test --reporter expanded` : **95 tests réussis**, environ 12 s, code 0. Parcours simulé création published -> catalogue relu -> détail -> ajout favori réussi ; test complémentaire de synchronisation carte/détail/Favoris et retrait réussi. Validation, erreurs, refus RLS simulés et changement de compte couverts par la suite existante.
- Cluster jetable existant `.dart_tool/kibo-direct-publication-pg` identifié avant redémarrage : PostgreSQL 13, 127.0.0.1:55439, initialement arrêté. `pg_ctl start`, puis `psql -X -v ON_ERROR_STOP=1 -f test/sql/direct_publication_assertions.sql` et `...direct_publication_legacy_policy.sql` : réussis. Transactions de test annulées ; cluster arrêté dans un finally, état arrêté confirmé. Aucun service PostgreSQL préexistant modifié. La migration déjà présente dans cette fixture n'a pas été réappliquée.
- Assertions SQL : date client future remplacée par l'heure serveur, publication propriétaire lisible par B/anon, favoris autorisés et isolation A/B ; usurpation de vendeur, vues/rejet privilégiés, modification du statut et INSERT anon refusés. Ancienne politique : INSERT published refusé comme attendu. Cela valide la fixture, pas les fonctions/RLS du serveur réel.
- `git diff --check` : réussi ; avertissements LF/CRLF préexistants uniquement.

Migration relue et comparée au contrat communiqué : l'INSERT distant connu n'autorise que draft/pending avec date NULL ; le delta ajoute published avec date serveur en conservant vendeur courant, vues 0 et absence de rejet. Il ne change pas les politiques de lecture, UPDATE/DELETE, catégories ou favoris. **Le preflight ne compare pas le corps complet de l'ancien prédicat** : revue des définitions exactes, grants et triggers distants indispensable avant toute application autorisée. Aucun état distant fraîchement vérifié pendant cette reprise.

`flutter devices` et `adb devices -l` : aucun Android connecté (seuls Windows/Chrome/Edge côté Flutter). Aucun modèle/état TECNO vérifiable, aucune installation ou recette physique. Un APK existe déjà, mais sa correspondance au code courant n'est pas certifiée ici. `config/supabase.local.json` absent et clé publique absente des environnements Process/User/Machine ; aucune valeur demandée, extraite ou inventée.

Prochaine étape manuelle : connecter et autoriser le TECNO par USB, puis vérifier modèle et état. Préparer la clé publique uniquement localement selon DEVELOPMENT_SETUP si toujours absente ; reconstruire le build configuré et demander confirmation avant installation. La recette réelle de publication immédiate reste bloquée jusqu'à l'audit/application explicitement autorisée du delta distant. Après ces prérequis, tester une annonce de test sans photo : vendeur courant, published/date serveur, carte immédiate, détail relu, ajout/retrait et persistance des favoris puis isolation du second compte. Ne pas promouvoir l'ancienne annonce pending ni toucher aux données réelles pour débloquer la recette.

## Configuration permanente et continuité ChatGPT/Codex

Instructions AGENTS/WORKFLOW alignées : travail sur main, préservation des changements connus, aucun commit/push ni changement Supabase distant sans autorisation explicite. Guide [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) ajouté ; URL publique du projet confirmée centralisée dans `config/supabase.public.json`. Modèle fictif `config/supabase.local.example.json` et exclusion des fichiers `config/*.local.json` pour réutiliser une clé publique locale avec les paramètres de compilation existants. Aucun changement Flutter ou dépendance, aucune clé réelle copiée/extraite/enregistrée pendant cette tâche.

Inspection : 23 fichiers suivis modifiés et 45 fichiers non suivis préexistants ; environnement Windows Process/User/Machine sans les deux variables Supabase, aucun fichier `.env` ou launch VS Code local détecté. Les paramètres réels étaient fournis aux builds précédents par invites locales et `--dart-define`, sans source durable détectée dans ces emplacements. Préparation locale unique de la clé publique restant à effectuer par le propriétaire si aucune autre configuration locale n'existe. Ne pas extraire la clé des caches/APK. La publication directe reste en attente de revue/application distante autorisée ; aucune recette physique supplémentaire.

Contrôles de cette intervention : format vérifié sans réécriture (50 fichiers, 0 changement), `flutter analyze --fatal-infos` sans anomalie (3,7 s), `flutter test --reporter expanded` : **95 tests réussis**, code 0 ; `git diff --check` réussi. JSON valides avec noms de variables distincts et modèle fictif uniquement ; support de plusieurs `--dart-define-from-file` vérifié dans le SDK Flutter installé. Exclusions du fichier local et de sa sauvegarde vérifiées, modèle et URL non ignorés. Recherche de motifs de clés Supabase/JWT/clés privées sur les fichiers suivis et non ignorés : aucun candidat ; contrôle indicatif, pas une certification exhaustive. Aucun build configuré ou test distant exécuté, aucun commit/push.

## Publication immédiate au lancement — état courant

Décision du propriétaire : création published sans modération préalable, prix obligatoire conservé. Code Flutter adapté ; delta RLS/horodatage serveur préparé sous `supabase/migrations/20261031050000_direct_listing_publication.sql`, **non appliqué à Supabase distant**. Propriétaire/authentification/validations et isolation des favoris préservés. Le catalogue est rechargé après création ; aucun repli silencieux pending. Contrat détaillé : [DIRECT_PUBLICATION.md](DIRECT_PUBLICATION.md).

Tests SQL réellement exécutés sur PostgreSQL 13 jetable, 127.0.0.1:55439, sous rôles clients fictifs : publication et horodatage serveur, lecture anon/B, ajout aux favoris, refus d’usurpation/vues/rejet/INSERT anon, isolation des favoris, protections UPDATE et ligne pending initiale conservées. Ancien prédicat : publication refusée comme prévu ; réapplication du delta : preflight refuse, puis assertions toujours réussies. Instance de test arrêtée ; service PostgreSQL existant et projet distant intacts. Fixture réduite, pas reproduction complète des fonctions distantes.

### Recette physique précédente — observations historiques

L’ancien APK a été reconstruit/installé puis comparé par SHA-256 : identique au build de recette. Deux comptes de test non administrateurs et une seule création étaient autorisés. Le propriétaire confirme création unique sans photo, seller_id correct, pending et 1000 XAF ; annonce absente après actualisation. Erreur hors réseau avec Réessayer, retour réseau et état vide : réussis. Détail publié, ajout/retrait/persistance/isolation de favoris et archivage : bloqués/non exécutés faute d’annonce de test publiée et de moyen administratif. Aucune publication/archivage n’a été fait pour débloquer ces tests.

Les tentatives RLS REST de lecture seule se sont arrêtées avant le compte B : recherche par titre non confirmée, puis recherche par UUID renvoyant zéro ligne sous le compte présumé A. Correspondance du compte au seller_id non confirmée avant le changement de tâche. Aucune conclusion de succès/échec RLS propriétaire/tiers tirée. Aucun INSERT forgé published ni suppression de favori exécuté.

La publication directe exige encore audit/application autorisée du delta puis recette réelle. Aucun UPDATE de données, changement de réglage distant, commit ou push pendant cette modification.

Validations finales : `dart format lib test` réussi (50 fichiers), `flutter analyze --fatal-infos` sans anomalie (4,5 s), `flutter test --reporter expanded` : **95 tests réussis** (91 conservés/adaptés + 4 nouveaux), `git diff --check` réussi. Tests du retour serveur et du refus RLS, horloge UTC injectable, message de refus sans détail brut et parcours publication -> catalogue relu -> détail -> favoris couverts. Premier test intégré corrigé pour défiler jusqu’au titre réellement cliquable au-dessus de la navigation ; pas de correction de données distantes pour le faire passer. Aucun nouveau test physique ou installation de ce flux.

## Historique — lot initial KIBO-008/009/010 en pending

Contrats déployés communiqués par le propriétaire et adaptation prix obligatoire/pending validée. Travail séquentiel sur main pour préserver le socle non committé ; aucun worktree/branche, déplacement de changement, modification distante, dépendance, commit ou push. Détails et recettes dans [LISTINGS.md](LISTINGS.md).

### KIBO-008
Implémenté localement : formulaire français, catégories actives, prix décimal XAF requis, propriétaire issu de la session et vérifié avant INSERT, statut/currency privilégiés laissés aux valeurs par défaut serveur. Sans images. Tests validation, visiteur, succès pending, chargement, erreur, catégories absentes et changement de session ; HTTP SDK contrôlé. Formatage 37 fichiers, analyse stricte sans anomalie, **74 tests réussis** et diff check réussi. Les erreurs initiales de lint et de fixtures widget ont été corrigées. Aucun INSERT réel ni recette TECNO de publication effectué.

### KIBO-009
Implémenté localement : liste réelle published, pagination 20, actualisation et détail relu par ID, états chargement/vide/erreur/indisponible. Cartes responsives extraites, ligne impaire gérée ; le socle visuel et les parcours auth/profil sont conservés. Fixtures de démonstration injectées seulement dans les tests, assertions de devise adaptées à XAF et titre de section adapté au catalogue. **80 tests réussis**, formatage 41 fichiers, analyse stricte sans anomalie et diff check réussi. Refus des statuts non publics et projection explicite testés via HTTP simulé. Aucun appel distant ni recette physique du catalogue effectué.

### KIBO-010
Implémenté localement : repository favorites sans UPDATE, filtres propriétaire, ajout idempotent sur la clé composée et liste de publications visibles par jointure interne. Contrôleur partagé, actions désactivées pendant envoi/relecture, vidage immédiat et réponses tardives ignorées au changement de compte. Cœurs cohérents entre carte/détail/Favoris ; visiteur sans écriture. Les favoris masqués/archivés ne sont pas supprimés et ne donnent pas accès au contenu non public.

Tests ajoutés : état partagé, ajout/retrait/liste, visiteur, double action, refus RLS HTTP, erreurs/reprise, lecture ou écriture tardive et annonces indisponibles. Une couverture supplémentaire de publication à 320 px/texte 150 % avec clavier a été ajoutée au lot. **91 tests réussis**, soit les 67 tests de départ conservés/adaptés et 24 supplémentaires ; formatage 49 fichiers, analyse stricte sans anomalie (2,3 s), suite environ 8 s, diff check réussi, codes 0. L’import de test inutilisé détecté lors du premier passage a été supprimé avant la validation finale. Le cas de session expirée sans événement immédiat a été corrigé et testé pour ne pas laisser le chargement bloqué ou réintroduire des données privées.

Recettes réelles publication/catalogue/favoris et tests RLS adverses non effectués. Aucun compte/annonce/favori distant créé, modifié ou supprimé, aucune installation sur TECNO, aucun réglage serveur changé. La documentation décrit les opérations de recette à autoriser et les limites (statut pending, pas d’images/recherche avancée). Aucun commit ni push.

Build ARM64 de l’état final : `flutter build apk --debug --target-platform android-arm64` réussi, code 0, 21,8 s, sans paramètres réels et sans installation sur téléphone. Comparaison des empreintes locales : aucun fichier préexistant supprimé ; sources auth/profil et infrastructure Supabase/stockage/versions inchangées. État Git complet et commandes de recette dans [LISTINGS.md](LISTINGS.md).

## État confirmé
- Documentation produit, identité visuelle, architecture cible et workflow présents.
- Workflow Direct Main confirmé par le propriétaire : tâches courantes sur `main`, contrôles avant commit et push, aucun force-push.
- Socle Flutter local existant conservé ; accueil de démonstration KIBO dans `lib/main.dart`.
- Flutter 3.38.5 / Dart 3.10.4 ; identifiant Android observé `com.kibo.kibo`, encore à valider définitivement.

## KIBO-001 — Socle Flutter
- **Statut : terminée et publiée sur `origin/main`.** Commit du socle : [`4d7ccd38a98c0868737cb801bc5f79a2fcb1e283`](https://github.com/Smeth/kibo/commit/4d7ccd38a98c0868737cb801bc5f79a2fcb1e283).
- Socle existant ajouté au versionnement avec ses fichiers de plateformes, sans recréer le projet.
- Accueil conservé ; seul le paramètre inutilisé `__` a été remplacé par `_` pour satisfaire le lint.
- Ancien test du compteur remplacé par un test de l’identité et de la navigation de l’accueil.
- `.gitignore` complété pour les fichiers d’environnement et clés privées ; aucun secret détecté dans les candidats selon les motifs recherchés.
- README et automatisation alignés sur Direct Main, suivant l’instruction explicite du propriétaire qui remplace les anciennes exigences de branche/PR de KIBO-001.
- CI adaptée au socle présent, avec Flutter 3.38.5 ; suppression des conditions `hashFiles` au niveau des jobs et du job documentation seule.
- Issue de référence : https://github.com/Smeth/kibo/issues/1 ; aucune PR requise.

### Vérifications locales réussies le 2026-10-30
- `flutter pub get` : dépendances résolues, sans mise à niveau demandée.
- `dart format --output=none --set-exit-if-changed lib test` : 2 fichiers, 0 changement.
- `flutter analyze --fatal-infos` : aucun problème.
- `flutter test` : 1 test réussi.
- `flutter devices` : TECNO CK6n / Android 14 détecté.
- `flutter run -d <identifiant-TECNO> --no-resident` : APK debug compilé, installé et démarré sur le TECNO ; synchronisation terminée, code de sortie 0.
- `git diff --check` : aucune erreur d’espacement.

### Vérification de clôture le 2026-10-30
- État initial propre sur `main` ; fichiers Flutter déjà suivis et présents. Aucune modification locale à préserver ni fichier de socle restant à ajouter.
- `git fetch origin main`, puis `git rev-parse HEAD origin/main` : même SHA `4d7ccd38a98c0868737cb801bc5f79a2fcb1e283`, publication confirmée.
- Contrôles relancés : `flutter pub get` réussi ; `dart format --output=none --set-exit-if-changed lib test` : 2 fichiers, 0 changement ; `flutter analyze --fatal-infos` : aucun problème ; `flutter test` : 1 test réussi.
- [GitHub Actions — KIBO Flutter CI](https://github.com/Smeth/kibo/actions/runs/41129735329) : exécution du commit du socle terminée avec succès, résultat consulté via l’API GitHub.
- Cette clôture ne change que `docs/PROGRESS.md` et `docs/NEXT_TASK.md`. Aucun ajout de dépendance ni changement applicatif ; le lancement Android réussi ci-dessus n’a pas été répété lors de cette vérification.

### Limites
- La validation du lancement repose sur les sorties Flutter ; aucune inspection visuelle de l’écran ni test complet des interactions sur téléphone.
- Aucun essai depuis un clone vierge ; aucune compilation iOS, web ou desktop.
- CI distante du commit du socle réussie ; le commit de clôture documentaire ne modifie pas les chemins qui déclenchent la CI Flutter.
- Accueil statique : ni Supabase, ni authentification, ni fonctionnalités métier ajoutés.
- Signature Android release encore configurée avec la clé debug du projet généré : aucune livraison production validée.
- Le SHA du commit de clôture documentaire et le résultat de son push sont fournis dans le compte rendu de session.

## KIBO-002 — Connexion Supabase
- **Statut : terminée, test réel de connexion Supabase inclus, confirmé par le propriétaire le 2026-10-31.** Issue : https://github.com/Smeth/kibo/issues/2. Implémentation publiée sur `main` dans [`ed1d4fc2997aa914a06e8a78cf4ecf6e1db3e988`](https://github.com/Smeth/kibo/commit/ed1d4fc2997aa914a06e8a78cf4ecf6e1db3e988). Aucune fonctionnalité métier suivante n’est commencée.
- Périmètre : ajouter le SDK Supabase compatible, initialiser le client de façon centralisée et testable, injecter URL + clé anon/publishable via paramètres de build, gérer proprement la configuration absente/invalide et documenter le lancement PowerShell.
- Hors périmètre : schéma SQL, migrations, RLS, authentification, Storage et fonctionnalités métier.
- Garde-fou : jamais de clé `service_role` dans Flutter ; aucune vraie clé ne doit être écrite dans les fichiers du dépôt.
- État initial propre sur `main`, mise à jour en fast-forward depuis `origin/main` avant modification ; aucun projet recréé ni travail local écrasé.
- SDK résolu : `supabase_flutter 2.18.3`, `supabase 2.16.5`, versions verrouillées dans `pubspec.lock`. Le graphe résolu exige Flutter >= 3.38.1, compatible avec Flutter 3.38.5 / Dart 3.10.4.
- `SupabaseConfig` lit les paramètres de build et valide URL HTTPS et format public de clé. Un `SupabaseService` unique, injecté dans l’application, partage son Future d’initialisation et expose le client uniquement après réussite.
- Écrans de chargement et d’erreur explicite ajoutés au démarrage, sans refonte de l’accueil. Les exceptions SDK sont remplacées par un message générique ; aucune valeur de configuration n’est journalisée par notre code et les logs debug SDK sont désactivés.
- Persistance/restauration de session, rafraîchissement des jetons et traitement des liens d’authentification désactivés pour cette étape. Aucun parcours d’authentification ni accès métier ajouté.
- Permission Internet ajoutée au manifeste Android principal. iOS inspecté, sans exception ATS ni callback OAuth ajouté. Registrants desktop régénérés par Flutter pour les dépendances du SDK.
- Commandes PowerShell et limites documentées dans [SUPABASE_SETUP.md](SUPABASE_SETUP.md) ; README, architecture et décisions techniques actualisés.

### Vérifications KIBO-002 — 2026-10-30
- `flutter pub get` : réussi, ainsi que le passage diagnostique `flutter pub get --verbose` (journal local ignoré sous `.dart_tool/`), après interruption d’un téléchargement sans sortie prolongé.
- `dart format --output=none --set-exit-if-changed lib test` : 7 fichiers, 0 changement.
- `flutter analyze --fatal-infos` : aucun problème.
- `flutter test` : 13 tests réussis (configuration absente/incomplète/invalide, formats publics et refus des rôles privilégiés, initialisation unique/concurrente, accès au client, erreurs SDK masquées et parcours de démarrage).
- Le premier passage des widgets a été interrompu lors de l’attente de fermeture de l’isolate d’un vrai client SDK. Le double de test a été remplacé par un faux client sans isolate ni réseau ; la suite complète réussit désormais.
- Aucun paramètre réel utilisé ; les exemples et tests contiennent uniquement des données fictives.
- `flutter build apk --debug` : tentative multiarchitecture bloquée par des erreurs de négociation TLS pendant le téléchargement des moteurs Flutter ARMv7 et x86_64 depuis Google Storage ; retry automatique interrompu. Aucun contrôle TLS désactivé. Ce résultat est distinct des 13 tests réussis.
- `flutter build apk --debug --target-platform android-arm64` : tentative interrompue pendant l’attente réseau, puis vérification Gradle hors ligne avec le JDK Android Studio.
- Depuis `android/`, `gradlew.bat --offline '-Ptarget-platform=android-arm64' '-Ptarget=<chemin-absolu-vers-lib/main.dart>' '-Pbase-application-name=android.app.Application' assembleDebug` : compilation Flutter/Dart et Java/Kotlin réussie, mais assemblage complet en échec sur `:app_links:extractDebugAnnotations`. Dépendances absentes du cache : `com.android.tools.external.com-intellij:intellij-core:31.11.1` et `com.android.tools.external.com-intellij:kotlin-compiler:31.11.1`.
- Au premier diagnostic, Gradle signalait aussi `cmdline-tools/latest/package.xml` corrompu dans le SDK Android local et une installation `latest-2` à un emplacement incohérent. Aucune réparation du SDK global n’avait encore été effectuée à ce stade.
- Les changements ont été préservés dans l’index sans commit ni push pendant ce blocage. Le propriétaire a ensuite autorisé sa résolution ; les résultats finaux ci-dessous remplacent ces échecs initiaux.

### Réparation Android et validations finales — 2026-10-30
- Capture et comparaison de l’index avant/après réparation et contrôles : les 21 fichiers préparés étaient intégralement identiques. Seuls ce document et `NEXT_TASK.md` sont ensuite actualisés pour le compte rendu. Aucun reset, clean destructif, effacement de changement ni force-push.
- Diagnostic avant réparation : `cmdline-tools/latest/package.xml` faisait 18 496 octets, tous nuls. SHA-256 : `E5585BE8A71910C1AA8A20F236E36C515A33FF49A8836B45FB4FAD6F230ECCD9`. Le dossier `latest-2` contenait un XML valide pour le même package `cmdline-tools;latest`, révision 19, au mauvais emplacement. La cause de l’écrasement initial du XML n’est pas déterminée.
- Sauvegarde réversible des deux dossiers complets hors du SDK : `C:\Users\MONSTER\AppData\Local\Android\KIBO-sdk-backups\20261030-225320`. Aucun dossier sauvegardé n’a été supprimé.
- Réinstallation ciblée via le `sdkmanager` officiel sauvegardé, avec `--sdk_root` explicite, `--install "cmdline-tools;latest" --channel=0`. Outils stables officiels réinstallés : révision 23.0. Le passage 19 -> 23 concerne uniquement l’outillage SDK défectueux réinstallé via le package stable `latest`, pas les dépendances de KIBO. Nouveau XML valide, 18 407 octets, chemin et révision cohérents.
- Le premier lancement officiel de `sdkmanager` 23 a installé son remplaçant Android CLI. Inventaire SDK réussi ; plus d’avertissement de XML corrompu ni d’emplacement incohérent. L’avertissement de dépréciation de `sdkmanager` est attendu avec cette version.
- HTTPS vérifié avec Java/JBR sur les endpoints officiels Google Repository, Google Maven et Flutter Storage : réponses HTTP 200 avec les contrôles de certificat et de nom d’hôte standards. Les anciennes erreurs TLS ne se reproduisent plus ; aucune cause réseau définitive n’est affirmée. Aucun certificat ajouté, proxy configuré ou contrôle SSL/TLS désactivé.
- Gradle a résolu les deux JAR exacts manquants depuis Google Maven uniquement, dans un diagnostic isolé sous `.dart_tool/` ignoré par Git : `intellij-core:31.11.1` (37 724 225 octets) et `kotlin-compiler:31.11.1` (50 332 514 octets), commande terminée avec `BUILD SUCCESSFUL`. Aucune modification des versions de `pubspec.yaml`/`pubspec.lock`, du wrapper Gradle, d’AGP, du NDK ou des plateformes Android pendant la réparation.
- `flutter pub get` : réussi après réparation.
- `dart format lib test`, puis `dart format --output=none --set-exit-if-changed lib test` : 7 fichiers, 0 changement.
- `flutter analyze --fatal-infos` : aucun problème.
- `flutter test` : 13 tests réussis.
- `flutter build apk --debug --target-platform android-arm64` : réussi, code de sortie 0 ; assemblage Gradle en 16,1 secondes, sans paramètre Supabase réel. APK local : `build/app/outputs/flutter-apk/app-debug.apk`, 110 695 037 octets ; présence de `lib/arm64-v8a/libflutter.so` vérifiée.
- `git diff --check`, `git diff --cached --check` et revue intégrale du diff : réalisés ; aucun fichier de diagnostic, cache, SDK, clé réelle ou secret privilégié sélectionné pour publication.
- Références officielles : [sdkmanager](https://developer.android.com/tools/sdkmanager), [Android CLI](https://developer.android.com/tools/agents/android-cli). Journaux et scripts de diagnostic locaux conservés sous `.dart_tool/`, hors Git.

### Test réel de connexion — 2026-10-31
- Application lancée sur TECNO CK6n / Android 14 avec les deux paramètres publics saisis localement et injectés au build. Aucune valeur de clé ni URL propre au projet n’est reproduite dans ce compte rendu.
- Initialisation réelle du SDK Supabase réussie et accueil `KiboHomePage` confirmé sur le téléphone.
- Sonde HTTPS temporaire, exécutée en mémoire depuis le processus KIBO sur le téléphone : `GET /auth/v1/settings`, sans clé publique -> HTTP 401 ; même requête avec la clé publique du client initialisé -> HTTP 200.
- Ces résultats confirment la joignabilité du service et l’acceptation de la clé publique depuis le TECNO, au-delà de la seule initialisation locale du SDK.
- Aucun parcours de connexion utilisateur, aucune écriture métier, aucune requête de table ni modification de RLS effectués.
- La clé publique n’a été publiée ni dans le chat ni dans Git. Aucun fichier source modifié, aucun commit ni push supplémentaire pendant ce test ; dépôt propre et synchronisé après contrôle. Le propriétaire confirme ces résultats.
- [CI du commit d’implémentation](https://github.com/Smeth/kibo/actions/runs/41136806799) : terminée avec succès, statut revérifié lors de la clôture documentaire.

### Clôture documentaire — 2026-10-31
- Seuls `README.md`, `docs/PROGRESS.md`, `docs/NEXT_TASK.md` et `docs/SUPABASE_SETUP.md` sont actualisés ; aucun code applicatif ni dépendance modifié et aucune implémentation de KIBO-003 commencée.
- Contrôles avant commit : `dart format --output=none --set-exit-if-changed lib test` (7 fichiers, 0 changement), `flutter analyze --no-pub --fatal-infos` (aucun problème), `flutter test --no-pub` (13 tests réussis), `git diff --check` et relecture du diff.
- La fermeture de l’issue #2 avec résumé du test réel est autorisée par le propriétaire uniquement après confirmation du commit et du push documentaires. Aucun paramètre réel n’est inclus dans les documents ou le commentaire de clôture.

### Limites KIBO-002
- Les tests automatisés restent isolés du réseau. Le test réel ci-dessus valide l’initialisation, la joignabilité du service testé et l’acceptation de la clé publique ; il ne valide pas les tables, les politiques RLS ni les parcours d’authentification utilisateur.
- La validation de format et de rôle du JWT n’est pas une vérification cryptographique. RLS et grants côté serveur restent indispensables avant d’exposer des données ; aucune policy n’est créée ou désactivée ici.
- APK debug ARM64 validé et lancement sur TECNO confirmé lors du test réel ; compilation multiarchitecture et APK release non validés. Aucun contournement de tâche Gradle ni affaiblissement TLS.
- Pas de compilation iOS/desktop ni de validation sur ces plateformes. Pas de livraison production validée.
- Aucun secret ou clé réelle ajouté ; les chaînes de tests qui évoquent un rôle privilégié servent uniquement au rejet de données fictives.
- Le commit de clôture documentaire, le résultat de son push et la fermeture de l’issue sont rapportés dans le compte rendu de session. Le workflow CI Flutter filtre les chemins applicatifs : un commit limité au README et à `docs/` ne déclenche pas cette CI.

## KIBO-003 — Socle UI Manrope / Emerald
- **Statut : implémentation terminée et validations locales réussies le 2026-10-31.** Périmètre validé par le propriétaire ; publication Direct Main après revue du diff. Le SHA, le push et la CI sont communiqués dans le compte rendu de livraison.
- État initial propre sur `main`, synchronisé avec `origin/main` à `a407e04` ; aucun changement préexistant écrasé, aucun projet recréé.
- Manrope locale 400/600/800 provenant du dépôt officiel `googlefonts/manrope`, révision `468c0dbe38efa331b80bfe9448256abe27be44c3`. TTF identiques aux originaux, poids vérifiés ; licence SIL OFL 1.1 complète conservée et embarquée. Provenance et empreintes dans [UI_THEME.md](UI_THEME.md).
- Palette et thème clair centralisés dans `lib/core/theme/`, thème branché sur `MaterialApp`, licence enregistrée une seule fois et chargée à la demande.
- Accueil harmonisé : typographie, couleurs, marges, cartes, boutons et navigation ; textes secondaires portés à 12 px minimum, grille adaptative et contenus pouvant grandir avec le texte. Catégories, quatre annonces fictives, callbacks et cinq destinations conservés.
- `supabase_config.dart`, `supabase_service.dart` et les 13 tests précédents sont inchangés. États de chargement/erreur et initialiseur unique préservés ; aucune clé réelle utilisée ni nouvelle dépendance ajoutée.

### Vérifications KIBO-003 — 2026-10-31
- `flutter pub get` : réussi, sans modification du fichier de verrouillage.
- `dart format lib test` : réussi, 12 fichiers traités.
- `flutter analyze --fatal-infos` : aucun problème.
- `flutter test` : **24 tests réussis**, dont les 13 existants et 11 nouveaux tests (polices/licence, thème, initialisation unique, responsive et erreur de configuration).
- Rendu avec les vrais TTF : 320×640 à texte 1/2/3, 360×800 à 1,5, 393×800 à 2, 800×600 à 2 ; aucun débordement signalé, dernière annonce accessible par défilement et navigation conservée.
- Aperçus 393×852 avec Manrope et Material Icons inspectés en haut de page et après défilement ; fichiers de contrôle uniquement sous `.dart_tool/`, ignorés.
- `flutter build apk --debug --target-platform android-arm64` : réussi, code de sortie 0, assemblage en 18,7 secondes. Présence du moteur ARM64, des trois TTF et de la licence dans l’APK vérifiée ; aucun paramètre Supabase réel au build.
- `git diff --check` : réussi ; revue du diff et contrôle des fichiers sélectionnés avant publication.

### Limites KIBO-003 et suite
- Aucun nouveau déploiement sur TECNO ni nouvelle requête Supabase réelle pour cette tâche ; la validation physique du thème reste à effectuer. Le test réel réussi de KIBO-002 reste distinct.
- Les tests responsive couvrent les dimensions indiquées, pas toutes les combinaisons d’appareils et de réglages. La navigation utilise le plafonnement Material de ses libellés à 1,3 ; le corps ne plafonne pas le texte.
- Aucun build release, multiarchitecture ou iOS validé. Aucune fonctionnalité métier, authentification, table, politique RLS ou messagerie ajoutée.
- Prochaine tâche à cadrer et valider avec le propriétaire ; aucune implémentation de KIBO-004 commencée.

## KIBO-003.1 — Corrections responsive et alignement des cartes
- **Statut : corrections terminées le 2026-10-31, validations automatisées et contrôle physique TECNO réussis. Publication Direct Main après revue du diff ; commit, push et CI rapportés dans le compte rendu.**
- Départ vérifié : dépôt propre sur `main`, synchronisé avec `origin/main`, SHA `ffdf8d430abe2973d51994a69a637190ca58a7af`. TECNO CK6n disponible via ADB.
- Inspection physique précédente de KIBO-003 : à 150 %, « Recherche » passe sur deux lignes et son icône se décale ; à 100 %, les illustrations d’une rangée ont des hauteurs différentes ; à 150 %, elles occupent trop d’espace.

### Première tentative — arrêt demandé après échec
- Corrections préparées, encore non validées : navigation dédiée mesurant les libellés à l’échelle système et répartissant les destinations sur plusieurs rangées si nécessaire ; illustrations bornées entre 140 et 180 px, indépendantes du texte ; rangées de cartes avec début du texte aligné et hauteur textuelle naturelle.
- Les 24 tests sont conservés, avec adaptation des assertions liées au remplacement du composant de navigation. Six tests ciblés supplémentaires sont écrits mais n’ont pas été exécutés.
- `flutter pub get` : réussi, sans nouvelle dépendance. `dart format lib test` : réussi, 14 fichiers traités, 6 formatés.
- `flutter analyze --fatal-infos` : **échec, code 1** : `test/widget_test.dart:2:8 — Unused import: 'package:flutter/material.dart' — unused_import`.
- Cause : l’adaptation du test de navigation a rendu cet import inutile. Reprise proposée : retirer cet import, puis relancer l’ensemble des contrôles demandés et vérifier les rendus avant toute publication.
- `flutter test`, compilation ARM64 et nouvelle installation sur TECNO non exécutés pour cette correction après l’arrêt. Aucun succès de test ou de rendu physique revendiqué. Aucun réglage Android modifié pendant cette tentative.
- Palette, polices, paramètres Supabase, configuration et service Supabase non modifiés. Aucune fonctionnalité métier ni tâche KIBO-004 commencée.

### Reprise KIBO-003.1 — 2026-10-31
- Branche `main` confirmée au même SHA de départ ; tous les changements préparés conservés. Après vérification des symboles utilisés, seul l’import Material inutilisé de `test/widget_test.dart` a été retiré du code à cette reprise.
- Contrôles relancés dans l’ordre demandé : `flutter pub get` réussi ; `dart format lib test` : 14 fichiers, 0 changement ; `flutter analyze --fatal-infos` : aucun problème ; `flutter test` : **30 tests réussis**, dont les 24 précédents et les six nouveaux ; `flutter build apk --debug --target-platform android-arm64` : réussi, code 0, assemblage en 12,3 secondes ; `git diff --check` : réussi.
- TECNO CK6n / Android 14 : version corrigée compilée, installée et lancée avec paramètres publics saisis dans des invites locales masquées ; accueil affiché après initialisation. Aucun fichier de configuration ni valeur publique réelle ajouté au dépôt, aucune modification de Supabase. Ce lancement ne constitue pas une nouvelle sonde HTTPS distante.
- À 100 % : cinq libellés entiers sur une rangée, icônes centrées, séparations illustration/texte alignées dans les deux rangées de cartes ; quatre annonces, prix et localisations accessibles.
- À 150 % (`font_scale=1.5`) : cinq destinations visibles sur deux rangées centrées, « Recherche » entier sur une ligne, sans décalage de son icône ; cartes en une colonne avec illustrations de 180 px logiques et texte naturel. Quatre annonces parcourues, informations lisibles ; les cinq destinations ont été touchées aux deux réglages et Profil sélectionné confirmé visuellement.
- Captures ADB inspectées à 100 % et 150 %, conservées uniquement dans le répertoire temporaire `KIBO-003.1-visual`, hors dépôt. Une capture avec notification privée a été écartée et supprimée ; aucune capture publiée dans Git.
- Réglage Android initial `font_scale=1.0` restauré et application relancée à l’accueil. Les trois défauts ciblés ne se reproduisent plus dans les conditions physiques testées.
- Limites : contrôle physique limité au TECNO en portrait, à 100 % et 150 %. Pas de validation release ou iOS, ni nouvelle fonctionnalité métier. À fort agrandissement, la navigation occupe davantage de hauteur pour préserver les libellés et les zones tactiles. Le layout intrinsèque des cartes convient aux quatre éléments fictifs ; un flux réel devra être conçu séparément. KIBO-004 non commencée.

### Publication KIBO-003.1
- Terminée et publiée sur `main` dans [`bca1aa2b3ced41c2de3fb8f80f3d8dc88aac15a0`](https://github.com/Smeth/kibo/commit/bca1aa2b3ced41c2de3fb8f80f3d8dc88aac15a0), push réussi et [CI réussie](https://github.com/Smeth/kibo/actions/runs/41149539924), selon le compte rendu de livraison. Dépôt propre au début de la préparation suivante.

## KIBO-004 — Formalisation des décisions et audit des prérequis
- **Statut : en préparation, aucune implémentation métier.** Intervention documentaire du 2026-10-31, autorisée sans commit ni push.
- État initial vérifié : `main`, dépôt propre, dernier commit `bca1aa2` ; aucun changement local préexistant à préserver. Aucun fetch, déploiement ou accès Supabase distant nécessaire à cette intervention.
- Règles fonctionnelles validées inscrites dans [CAHIER_DES_CHARGES.md](CAHIER_DES_CHARGES.md#règles-des-annonces--décisions-kibo-004) : prix facultatif/XAF et négociabilité, localisation, archivage/favoris et photos. Anciennes références à huit photos alignées sur le nouveau maximum de trois dans AGENTS, README et documentation de référence.
- Architecture et [décisions techniques](DECISIONS_TECHNIQUES.md#2026-10-31--préparation-du-backend-kibo-004) distinguent règles validées et conception restante, dont contrôles réels Storage, concurrence, droits et purge.
- Audit local en lecture seule : versions et limites détaillées dans [SUPABASE_SETUP.md](SUPABASE_SETUP.md#préparation-de-la-pile-locale--audit-du-2026-10-31). Docker/Podman et CLI Supabase non détectés ; WSL présent sans distribution installée ; outils PostgreSQL existants détectés, service laissé intact, aucune connexion à la base. Proposition d’installation minimale soumise à validation, aucune installation effectuée.
- [NEXT_TASK.md](NEXT_TASK.md) décrit les étapes à valider avant toute implémentation. Aucune migration métier créée ou déployée à ce stade ; aucune métadonnée distante vérifiée pendant cette intervention.
- Contrôles documentaires : `git diff --check`, relecture du diff et vérification des références et règles entre documents. Aucun test Flutter ou SQL exécuté pour ces seules modifications documentaires.
- Aucun fichier Flutter/SQL, dépendance ou configuration de service modifié ; aucun secret inspecté ou enregistré, aucun commit, push ou création d’issue.

## KIBO-005 — Authentification Flutter et Supabase
- **Statut : implémentation locale et validations automatisées réussies ; recette Android/Supabase réelle à effectuer. Aucun commit ni push.**
- Départ sur `main` au commit `bca1aa2`, avec huit documents déjà modifiés pour KIBO-004. Changements préexistants conservés ; aucun reset, nettoyage destructif ou recréation de projet.
- Parcours français email/mot de passe ajoutés dans `features/auth/` : inscription avec confirmation du mot de passe, connexion, visibilité du mot de passe, validation, chargement et erreurs compréhensibles sans exceptions brutes. L’accueil et les composants Manrope/Emerald restent présents ; l’avatar et l’onglet Profil ouvrent l’espace compte.
- Repository injectable et contrôleur réactif : session courante, événements auth, déconnexion locale, récupération du profil, gestion des erreurs de flux et protection contre les réponses de profil tardives. Aucun framework d’état supplémentaire.
- `SupabaseConfig` inchangé ; `SupabaseService` conserve l’initialiseur unique et réactive persistance/rafraîchissement. Session et vérificateurs PKCE stockés via `flutter_secure_storage 11.2.0`, avec sauvegarde/transfert Android adaptés et suppression ordonnée. SDK Supabase et ses versions inchangés. `http 1.6.0`, déjà transitive, devient une dépendance de test explicite ; registrants desktop régénérés par Flutter.
- Contrat `public.profiles` confirmé par le propriétaire pendant la tâche : trigger AFTER INSERT `on_auth_user_created` → `handle_new_user()`, SELECT public et UPDATE limité au propriétaire. Aucun INSERT/UPSERT client : lecture filtrée de `id, full_name, city` seulement après session. Sans session, demande de confirmation email ; profil absent/refusé signalé avec possibilité de relecture sans déconnecter l’utilisateur.
- Aucun fichier SQL/migration ni corps du trigger trouvé dans le dépôt ; aucune métadonnée additionnelle transmise faute de définition vérifiable. Aucun SQL, changement de politique distante ou compte réel créé.

### Vérifications KIBO-005 — 2026-10-31
- `flutter pub get` : réussi ; ajout du stockage chiffré et de ses dépendances transitives depuis pub.dev. Minimum Flutter résolu 3.38.4, compatible avec 3.38.5 installé.
- `dart format lib test` : réussi, 25 fichiers traités ; au dernier passage, 1 fichier formaté.
- `flutter analyze --fatal-infos` : **aucun problème**, code 0, 4,4 secondes au dernier passage.
- `flutter test` : **49 tests réussis**, dont les 30 précédents et 19 nouveaux ; code 0, environ 6 secondes pour l’exécution finale. Les 30 tests précédents restent en place ; seul le faux client commun expose maintenant les accès auth attendus.
- Les premiers passages d’analyse ont révélé des imports/accolades inutiles ou manquants ; corrigés. Deux nouveaux tests HTTP échouaient sur l’absence de stockage PKCE et de référence `response.request` dans leurs fixtures ; fixtures corrigées, protocole PKCE également couvert par le stockage chiffré, suite complète relancée avec succès. Un import de test initialement mal placé a été corrigé avant le passage final du formatage.
- `flutter build apk --debug --target-platform android-arm64` : **réussi**, code 0, 21,8 secondes pour le dernier assemblage, sans paramètre Supabase réel. Une première compilation de la dépendance native avait également réussi en 109,8 secondes.
- `git diff --check` : réussi. Revue des changements applicatifs et des dépendances ; aucun secret ou paramètre réel ajouté. Les exemples et sessions de tests sont fictifs.

### Limites et recette restante
- Aucun test d’inscription/connexion sur le Supabase réel ni nouvelle installation sur TECNO pour cette tâche. Les paramètres publics et un compte de test utilisable n’ont pas été saisis dans cette intervention ; aucune sollicitation de mot de passe dans le chat. Le SDK Android compile, mais la persistance native Keystore et la création effective du profil distant ne sont pas certifiées par les mocks.
- La restauration du SDK après réinitialisation est testée avec stockage simulé, pas après redémarrage physique. Rafraîchissement réel, confirmation email, second compte et déconnexion persistante restent à vérifier sur appareil selon [AUTHENTICATION.md](AUTHENTICATION.md).
- Pas de modification des paramètres email/deep links distants. Confirmation dans le navigateur puis connexion manuelle ; pas d’OAuth/OTP/récupération de mot de passe ou édition de profil dans ce périmètre. Pas de validation iOS/desktop/release.
- KIBO-004 demeure au stade de préparation ; aucun changement métier SQL ni déploiement. Publication de KIBO-005 uniquement après demande explicite du propriétaire.

### Recette réelle KIBO-005 — résultats confirmés sur TECNO

Inscription, réception/ouverture du lien, connexion, récupération du profil avec ville, session restaurée après arrêt complet, déconnexion et session restant fermée après relance, puis second compte : réussis selon les confirmations du propriétaire pendant la recette. Les arrêts/relances ont été effectués par ADB sans effacement des données. Le lien email aboutissait à localhost inaccessible ; la connexion manuelle réussissait. Le rafraîchissement à expiration et le hors réseau restent non vérifiés physiquement.

Contrôles après recette : analyse sans anomalie ; 49 tests réussis ; diff sans erreur. Un échec intermittent `MissingPluginException` sur `shared_preferences` a été reproduit et corrigé uniquement dans le test de restauration, en injectant `SecurePkceStorage` comme dans l’application. Aucun autre fichier modifié pendant cette recette, aucun commit ni push.

## KIBO-006 — Retour natif de confirmation email Android

Implémentation locale : callback `com.kibo.kibo://auth/confirm` envoyé au signup, filtre Android exact, gestionnaire Flutter désactivé au profit du plugin SDK existant. Détection SDK activée avec prédicat strict, échange PKCE unique, vérificateur/session chiffrés et logs debug désactivés conservés. Formulaire fermé sur session reçue, messages français adaptés. Aucune dépendance, migration ou modification distante. Modifications préexistantes conservées, aucun commit ni push.

Tests ajoutés : URI autorisées/refusées, challenge/redirect au signup, échange PKCE après recréation du client, refus sans vérificateur/rejeu, navigation sur session externe. La première analyse a signalé une accolade manquante et un test attendait l’ancien message ; corrigés avant les contrôles finaux.

Contrôles KIBO-006 : `dart format lib test` réussi (27 fichiers), `flutter analyze --fatal-infos` sans anomalie, `flutter test --reporter expanded` : **53 tests réussis**, dont les 49 antérieurs conservés. Configuration manuelle distante et nouvelle recette native à chaud/à froid restant à réaliser selon [AUTHENTICATION.md](AUTHENTICATION.md). Aucun nouveau test physique de confirmation native revendiqué.

Compilation supplémentaire `flutter build apk --debug --target-platform android-arm64` : réussie, code 0, assemblage en 20,9 secondes sans paramètres réels ; APK non installé pendant KIBO-006. `git diff --check` réussi ; aucun changement de version de dépendance ni modification de `SupabaseConfig`, `main.dart` ou du stockage chiffré pendant KIBO-006.

### Recette physique KIBO-006 — 2026-10-31, blocage distant

- TECNO CK6n connecté, Android 14 ; callback, manifeste et stockage PKCE chiffré relus. Les réglages distants sont déclarés prêts par le propriétaire, sans inspection ni modification distante par l’agent.
- Nouvelle compilation ARM64 avec paramètres publics saisis dans des invites locales masquées, installation par `adb install -r` sans effacement et lancement : réussis selon la confirmation du propriétaire. `resolve-activity` résout l’URI sans code vers `com.kibo.kibo/.MainActivity`.
- Première inscription de recette refusée : message « Trop de tentatives. Patientez avant de réessayer. » Le propriétaire fournit le statut HTTP 429 de POST `/auth/v1/signup`, horodaté 03:34:10 dans le tableau de bord. Le redirect demandé correspond au callback attendu. Aucun nom d’hôte réel ni extrait brut de requête conservé ici. Le code précis `over_email_send_rate_limit` ou `over_request_rate_limit` n’est pas accessible dans cet extrait ; aucun délai exact de réinitialisation affirmé.
- Lecture filtrée des logs du processus Android, sans publication de lignes brutes : aucun marqueur des deux codes de limitation, AuthException, SocketException, HandshakeException ou FATAL EXCEPTION dans la fenêtre examinée. Aucun correctif Flutter justifié ; aucune nouvelle tentative automatisée d’inscription.
- Scénarios avec nouvel email à chaud, à froid, lien expiré/déjà utilisé et persistance après confirmation : non validés, recette bloquée avant l’envoi d’un nouvel email. Attendre la levée de la limitation avant une tentative unique ; aucune modification de quota, SMTP, RLS ou schéma effectuée.
- Contrôles relancés après ce blocage : `flutter analyze --fatal-infos` sans anomalie (3,7 s), `flutter test --reporter expanded` : 53 tests réussis, `git diff --check` réussi, codes 0. Seul le suivi documentaire est actualisé ; changements locaux préexistants conservés, aucun commit ni push.

## KIBO-007 — Modifier le nom affiché et la ville

**Statut : implémentation locale terminée ; validation physique et UPDATE distant non effectués. Aucun commit ni push.** Le propriétaire a choisi cette tâche ; KIBO-006 conserve son blocage de recette HTTP 429.

- État initial : `main`, modifications locales KIBO-004/005/006 présentes et conservées. Aucune recréation, suppression, installation de dépendance ou modification distante.
- Nouveau formulaire `features/profile/edit_profile_page.dart`, prérempli depuis le profil chargé, avec nom facultatif, ville obligatoire, indication du caractère public, clavier, chargement et annulation. Validation partagée dans `profile_validation.dart`, sans liste de villes ni longueur métier inventée.
- `AuthRepository`/`AuthController` étendus pour l’édition : UPDATE de `full_name, city` seulement, filtre `id` de la session, identité attendue du formulaire et exactement une ligne retournée. Nom vide converti en null ; messages français sans erreur brute ; aucun INSERT/UPSERT ni champ de rôle écrit.
- Pendant l’enregistrement, doubles soumissions et départ de l’écran bloqués. Réponses obsolètes ignorées après fermeture/changement de session ; le brouillon de l’ancien compte disparaît et le nouveau profil est rechargé. L’ouverture du formulaire capture le profil avant la navigation pour éviter une erreur si la session se ferme immédiatement.
- Tests : 7 de contrôleur/validation, 5 widget/navigation/responsive et 2 HTTP SDK, soit **14 nouveaux tests**. Refus RLS simulé, zéro ligne, absence de session, identité périmée, annulation, erreur/reprise, sauvegarde tardive et 320 px/texte 150 % avec clavier couverts. Les 53 tests précédents sont conservés.
- Vérifications finales : `dart format lib test` réussi, 31 fichiers ; `flutter analyze --fatal-infos` sans anomalie (2,0 s), `flutter test --reporter expanded` : **67 tests réussis**, code 0, environ 8 s ; `git diff --check` réussi. Première analyse corrigée (Semantics non const) ; le retour de l’UPDATE a été rendu explicite sous forme de liste avec contrôle d’une ligne après deux échecs des nouveaux tests HTTP liés au format de réponse objet/liste. Suite complète relancée avec succès.
- Documentation : [PROFILE.md](PROFILE.md), architecture, décisions, contrat d’auth et suivi actualisés. Aucun build ni installation Android supplémentaire pour KIBO-007, aucun compte ou paramètre réel utilisé dans les tests. SupabaseConfig, initialiseur SDK, callback et stockage sécurisé inchangés pendant cette tâche.
- Reste à vérifier séparément : véritable UPDATE autorisé par les grants/RLS actuels, persistance serveur après redémarrage, hors réseau et rendu TECNO à 100 %/150 %. Les simulations ne certifient pas ces résultats. Ne changer aucune politique distante pour faire réussir la recette.


## Vérification locale de reprise — 2026-10-31 (sans publication distante)

### Périmètre et conservation du travail existant

- Reprise après lecture de `AGENTS.md`, `WORKFLOW.md`, `NEXT_TASK.md`, `DEVELOPMENT_SETUP.md`, `DIRECT_PUBLICATION.md`, `LISTINGS.md` et du suivi existant. Branche `main`, HEAD `bca1aa2` et remote `origin` Smeth/kibo ; aucun fetch ni conclusion de synchronisation avec le serveur distant.
- État initial inventorié : 25 fichiers suivis modifiés, nombreux fichiers non suivis (auth/profil/annonces/favoris, configuration, migration et tests), index vide. Empreintes de 209 fichiers suivis ou non ignorés enregistrées avant les contrôles. Avant la présente mise à jour documentaire, aucune empreinte n'avait changé et aucun fichier n'avait été ajouté ou supprimé dans cet inventaire.
- Aucun reset, nettoyage, changement de branche, déplacement ou remplacement du travail existant. Aucun fichier applicatif, migration ou test existant modifié. Seuls des paragraphes sont ajoutés à `PROGRESS.md` et `NEXT_TASK.md`. Le test de recette supplémentaire est créé dans `.dart_tool/kibo-verifications/`, ignoré par Git.

### Commandes et résultats réellement obtenus

| Contrôle | Résultat de cette reprise |
|---|---|
| `git status --short --branch`, `git diff --stat`, `git diff --cached --stat`, `git remote -v`, `git branch --show-current`, `git log -1 --oneline` | Inventaire local effectué ; `main`, HEAD `bca1aa2`, index vide. |
| `C:/flutter/bin/cache/dart-sdk/bin/dart.exe format --output=none --set-exit-if-changed lib test` | Code 0 : 50 fichiers, 0 changement. Aucun formatage avec réécriture. |
| `C:/flutter/bin/flutter.bat --version` | Flutter 3.38.5 / Dart 3.10.4. |
| `C:/flutter/bin/flutter.bat analyze --no-pub --fatal-infos` | Code 0 : aucune anomalie, 4,7 s annoncées par Flutter. |
| `C:/flutter/bin/flutter.bat test --no-pub --reporter expanded` | Code 0 : **95 tests réussis**. Aucun `pub get` ni ajout de dépendance. |
| `C:/flutter/bin/flutter.bat test --no-pub --reporter expanded .dart_tool/kibo-verifications/direct_publication_roundtrip_test.dart` | Code 0 : **1 scénario supplémentaire réussi**, simulé, sur la même annonce créée : publication → catalogue → détail → ajout → retrait → détail de nouveau sans favori. |
| `git diff --check`, `git diff --cached --check` | Codes 0 ; avertissements de conversion LF/CRLF sur des fichiers préexistants, sans réécriture. |
| `adb devices -l` (plusieurs lectures) | Liste vide : aucun Android détecté. Aucun modèle ou état USB ne peut être confirmé. |
| `C:/flutter/bin/flutter.bat devices --device-timeout 5` | Windows, Chrome et Edge seulement ; aucun Android. Aucun de ces clients n'a été lancé. |

Les contrôles Flutter sont exécutés avec `FLUTTER_SUPPRESS_ANALYTICS=true` et `CI=true`, les dépendances existantes et `--no-pub`. Ce sont des simulations/contrôles locaux, pas une recette physique ni un test Supabase distant. Le scénario supplémentaire dérive du test intégré existant sans le modifier, et vérifie effectivement le retrait du favori de l'annonce nouvellement créée ; les tests de favoris existants restent intacts.

### Revue et exécution SQL locale

Migration relue : `supabase/migrations/20261031050000_direct_listing_publication.sql`. Comparaison avec le contrat communiqué dans `LISTINGS.md` et la fixture locale : l'ancien INSERT permet uniquement draft/pending avec `published_at IS NULL`. Le delta ajoute published avec vendeur courant, vues 0, rejet NULL et date imposée par le serveur. Il conserve draft/pending, le défaut pending, les données existantes et les politiques de lecture/modification/suppression et de favoris.

Le preflight vérifie table/RLS, nom/type/rôles/caractère permissif de la politique INSERT et l'absence d'autres politiques INSERT/ALL ou de trigger INSERT applicatif actif. Il **ne certifie pas le corps exact de l'ancien WITH CHECK**, ni les fonctions/triggers/grants réellement déployés. La fonction de trigger est SECURITY INVOKER avec search_path pg_catalog ; aucune désactivation RLS ni fonction SECURITY DEFINER ajoutée. Cette revue locale ne remplace pas l'inventaire autorisé des métadonnées distantes.

PostgreSQL 13.22 existant utilisé sans installation. Nouvelle instance isolée, données fictives, écoute uniquement `127.0.0.1:55449` ; aucune réutilisation du service PostgreSQL existant ou de l'ancienne fixture du dépôt. Commandes du lanceur local :

1. `initdb.exe -D <nouveau-dossier-isolé> -U kibo_check --auth=trust --encoding=UTF8 --locale=C`, puis `pg_ctl.exe -D <ce-dossier> -l <journal> -o "-h 127.0.0.1 -p 55449 -c ssl=off" -w start`.
2. `psql.exe -X -h 127.0.0.1 -p 55449 -U kibo_check -d postgres -v ON_ERROR_STOP=1 -f test/sql/direct_publication_fixture.sql`.
3. Snapshot local des grants, autres politiques et définition du trigger UPDATE ; exécution du delta par le même psql, puis comparaison avant/après : **identiques** hors politique/trigger volontairement ajoutés/modifiés.
4. `-f test/sql/direct_publication_assertions.sql` : code 0, assertions publication/horodatage/RLS/isolation réussies.
5. `-f test/sql/direct_publication_legacy_policy.sql` : code 0, ancien prédicat refuse la publication comme attendu ; rollback.
6. Nouvelle exécution du delta : **code 3 attendu**, preflight « Trigger INSERT deja present ». Nouvelle exécution des assertions : code 0, protections intactes après le refus.
7. Transaction fictive supplémentaire : création published, ajout puis DELETE du favori du propriétaire, absence du favori vérifiée et ajout sur annonce pending refusé ; rollback, code 0.
8. `pg_ctl.exe -D <ce-dossier> -w stop -m fast` : code 0, instance arrêtée. Fichiers de test conservés, aucune suppression des archives ou données existantes.

Incident de lancement, distinct des assertions métier : le premier pg_ctl était attendu via des pipes hérités par le serveur enfant. L'instance prête a été arrêtée explicitement ; la tentative de fixture suivante a alors échoué faute de serveur, sans exécuter la fixture. La reprise a utilisé un second dossier neuf et une sortie pg_ctl vers fichier ; toute la séquence ci-dessus a ensuite réussi. Les deux instances créées pour cette reprise sont arrêtées ; le service existant est resté intact.

### Android, configuration et prochains contrôles manuels

- Aucun appareil Android connecté : pas de modèle Android confirmé, build lancé, installation, lancement d'application, arrêt d'application ou effacement de données pendant cette reprise.
- `config/supabase.public.json` et le modèle local existent. `config/supabase.local.json` est absent mais son exclusion Git est vérifiée. Aucune variable SUPABASE_URL/SUPABASE_ANON_KEY présente dans les environnements Process/User/Machine ; seules les présences ont été examinées, aucune valeur sensible affichée. Aucun fichier de clé créé ou remplacé. L'APK debug déjà présent n'est pas revendiqué comme un build courant de publication directe.
- Prochaine recette physique : connecter/déverrouiller l'Android, autoriser USB, relever modèle/état ; préparer localement la seule clé publique si aucune configuration existante utilisable ; compiler sans installer, puis **attendre une confirmation explicite avant toute installation** (`adb -s <identifiant> install -r ...`, sans désinstallation/effacement).
- La recette réelle de publication/favoris exige séparément un audit RLS distant autorisé, l'autorisation puis l'application du seul delta par l'opérateur autorisé et l'autorisation des écritures sur comptes de test. Rien de cela n'est effectué ici. Après ces prérequis : créer une annonce fictive sous A, vérifier publication/date serveur/carte/détail, ajouter puis retirer le favori et vérifier les vues ; relancer, contrôler B et visiteur, puis les refus/isolation autorisés.

Aucun appel Supabase distant, migration distante, changement de données/réglages, commit, push ou déploiement. KIBO-006 conserve son blocage historique HTTP 429 ; aucune nouvelle tentative d'inscription.
