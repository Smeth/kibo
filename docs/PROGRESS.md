# Avancement KIBO

Dernière mise à jour : 2026-10-31

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
