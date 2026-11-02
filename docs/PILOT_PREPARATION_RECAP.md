# Recette, suppression et pilote Android — bilan du lot

2026-11-01, Africa/Lagos. Dépôt KIBO confirmé sur main, remote origin github.com/Smeth/kibo.git ; modifications suivies et non suivies préexistantes inventoriées et conservées. Aucun commit/push ni publication.

## Trois chantiers réalisés

1. **Recette à deux comptes préparée.** [Vingt scénarios ordonnés](RECETTE_MVP_DEUX_COMPTES.md), dépendances, écritures à autoriser, critères attendus et collecte de preuves expurgées. Tous les scénarios humains restent non exécutés/bloqués : aucun compte dédié ni donnée réelle n’a été créé par l’assistant.
2. **Procédure de suppression préparée à partir du schéma réel.** [Runbook](ACCOUNT_DELETION_RUNBOOK.md), selon le choix reçu d’anonymiser les échanges conservés et supprimer profil/annonces/coordonnées avant validation de mise en service. Audit distant **en lecture seule de métadonnées**, notamment cascades et contraintes empêchant de supprimer Auth directement sans perdre l’historique de tiers. Aucun worker d’effacement, changement distant de schéma/RLS, suppression Auth ou nettoyage Storage activé. Les durées de conservation et le traitement des textes libres restent à définir.
3. **Pilote Android et corrections UI/UX.** Release distincte de debug, refus de tâche release directe/agrégée sans signature locale ; clé de diffusion non créée. Libellé Android KIBO, applicationId conservé. Nouveau lanceur qui refuse une cible absente avant build et ne désinstalle/efface rien. Corrections de confirmations de demande et d’annulation concurrente, récupération après erreur de lecture, état accessible du compteur et libellés opérateur avec texte agrandi. [Procédure pilote](ANDROID_PILOT.md).

## Vérifications réellement exécutées

- `Validate-MvpLot.ps1 -Lot pilot-standard` : format 108 fichiers sans changement, analyse stricte sans anomalie, **321 tests standard réussis**, diff check conforme ; cinq tests nouveaux.
- Suite complète `flutter test --no-pub --reporter expanded --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true` via SDK snapshot existant : **321 tests réussis**. Logs ignorés `.dart_tool/mvp-pilot-standard-{analyze,tests}.log` et `.dart_tool/pilot-photos-tests.log`.
- Gradle `:app:assembleDebug --dry-run --offline --console=plain` : succès, configuration Kotlin/Gradle vérifiée sans APK. `:app:assembleRelease` puis `:app:assemble`, mêmes options : refus de signature attendus, aucun binaire produit par ces contrôles. Les avertissements de dépréciation Gradle existants n’ont pas été traités par une mise à niveau hors périmètre. Aucune signature release avec véritable certificat testée.
- Lanceur PowerShell : syntaxe analysée, cible fictive absente refusée avant build. Les fichiers de signature/keystore/journal sont ignorés par Git, sans affichage de leurs valeurs. Aucun outil installé.
- Tests nouveaux : relecture réussie effaçant l’ancienne erreur ; demande acceptée puis lecture échouée sans faux état absent ; annulation concurrente avec examen ; lecteur d’écran distinguant zéro et compteur indisponible ; examen opérateur à 320 px/texte double, dialogue accessible et annulation sans décision. Le test de défilement attend le layout stabilisé d’une liste paresseuse ; aucune vérification de résultat supprimée.
- Audit Supabase : FK/colonnes/CHECK réels, sans lecture des lignes des membres. Requête réutilisable `supabase/audits/account_deletion_dependencies_readonly.sql` ; aucun DML/DDL distant. Ce contrôle ne vaut pas recette Auth/Storage/RLS avec comptes réels.

Lancement sur téléphone **réellement exécuté avec succès** par `scripts/Launch-KiboAndroid.ps1` : TECNO H6929CK6NU012345, build debug 21,5 s, installation 8,5 s, synchronisation 137 ms ; processus 31758 et KIBO au premier plan confirmés au retour. Aucun effacement ni désinstallation. Journal ignoré `.dart_tool/kibo-android-launch.log`, compte rendu expurgé `.dart_tool/pilot-device-run.log`. SHA-256 APK : `10723ECAE483B723612D8FCCE1E8BC72647B1139C43BD54ABF42D9EFE96B51BF`. Une tentative ultérieure de capture a été ignorée parce que le focus KIBO n’était plus confirmé ; aucune autre application capturée et aucune recette visuelle physique revendiquée.

## Fichiers modifiés dans ce lot

- Android : `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml` (seul libellé ajouté au diff préexistant).
- Flutter : `lib/features/profile/account_settings_page.dart`, `lib/features/profile/engagement_pages.dart`, `lib/features/chat/chat_overview.dart`.
- Tests : `test/profile/account_mvp_test.dart`, `test/profile/engagement_widgets_test.dart`, `test/chat/chat_overview_test.dart`.
- Outils : `scripts/Launch-KiboAndroid.ps1`, `supabase/audits/account_deletion_dependencies_readonly.sql`.
- Documentation : `README.md`, `docs/PROGRESS.md`, `docs/NEXT_TASK.md`, `docs/RECETTE_MVP_DEUX_COMPTES.md`, `docs/ACCOUNT_DELETION_RUNBOOK.md`, `docs/ANDROID_PILOT.md`, ce bilan.

## Suite proposée

Préparer le modèle d’historique anonymisé et ses tests de conservation/isolation en fixture ; définir les règles de conservation et préparer l’orchestration de suppression idempotente en staging autorisé ; exécuter la recette humaine avec comptes dédiés puis finaliser signature/support/distribution du pilote. Aucune suppression réelle, création de rôle ou publication ne découle automatiquement de ce bilan.
