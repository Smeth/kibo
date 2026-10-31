# Prochaine tâche — KIBO

## KIBO-001 — Socle Flutter
**Statut : terminée et vérifiée sur `main`.**

Commit du socle : [4d7ccd38a98c0868737cb801bc5f79a2fcb1e283](https://github.com/Smeth/kibo/commit/4d7ccd38a98c0868737cb801bc5f79a2fcb1e283).

Commit de clôture documentaire communiqué : [7f9782d55abb84879896bf42d512ff2cf459652d](https://github.com/Smeth/kibo/commit/7f9782d55abb84879896bf42d512ff2cf459652d).

- Dépôt propre, `main` synchronisée avec `origin/main`, selon le compte rendu de clôture.
- `flutter pub get`, formatage Dart, `flutter analyze --fatal-infos`, `flutter test` et `git diff --check` : réussis.
- CI GitHub : [exécution 41129735329 réussie](https://github.com/Smeth/kibo/actions/runs/41129735329).
- Aucun projet recréé, aucune suppression, branche, PR ou force-push.
- Issue : https://github.com/Smeth/kibo/issues/1 (clôturée).

## Workflow applicable
Le propriétaire a choisi Direct Main le 2026-10-30. Pour les tâches courantes : travailler sur `main`, préserver les modifications locales, tester avant commit et push, ne jamais faire de force-push. En cas de diff inattendu ou de test échoué, ne pas pousser.

## KIBO-002 — Connexion Supabase
**Statut : terminée, test réel inclus, confirmé par le propriétaire le 2026-10-31.**

Issue de référence : https://github.com/Smeth/kibo/issues/2. Implémentation : [`ed1d4fc`](https://github.com/Smeth/kibo/commit/ed1d4fc2997aa914a06e8a78cf4ecf6e1db3e988).

Sur TECNO CK6n / Android 14 : SDK Supabase initialisé, accueil KIBO affiché, requête HTTPS en lecture seule depuis le téléphone -> HTTP 401 sans clé publique et HTTP 200 avec la clé publique. Aucune valeur de clé publiée dans le chat ou Git ; aucun fichier source modifié, commit ou push pendant le test réel. Les détails, la CI réussie et les limites sont conservés dans [PROGRESS.md](PROGRESS.md).

## KIBO-003 — Socle UI Manrope / Emerald
**Statut : implémentation terminée, contrôles locaux réussis le 2026-10-31.**

Le propriétaire a validé le périmètre et autorisé l’implémentation sur `main`. Manrope 400/600/800 est embarquée localement depuis la source officielle, avec licence SIL OFL 1.1. Palette et thème clair centralisés ; accueil harmonisé sans changement fonctionnel ni modification du service ou de la configuration Supabase.

Validations réussies : `flutter pub get`, `dart format lib test`, `flutter analyze --fatal-infos`, `flutter test` (**24 tests, dont les 13 existants inchangés**), `flutter build apk --debug --target-platform android-arm64` et `git diff --check`. Tests responsive avec vraies polices et aperçus locaux inspectés ; aucun nouveau test physique TECNO ni test réseau Supabase réalisé pour cette intégration UI.

Provenance, licence et structure du thème : [UI_THEME.md](UI_THEME.md). Résultats détaillés et limites : [PROGRESS.md](PROGRESS.md). Le commit, le push et le statut CI sont fournis dans le compte rendu de livraison. Aucune issue KIBO-003 attribuée à ce stade.

## Suite à cadrer avec le propriétaire
Aucune tâche KIBO-004 immédiatement exécutable n’est encore définie. Ne pas commencer de fonctionnalité métier sans périmètre validé. KIBO-003.1 a été autorisée entre-temps ; son état courant est décrit ci-dessous.

La revue physique de KIBO-003 sur TECNO a identifié trois défauts ; leurs corrections et la vérification physique de KIBO-003.1 sont consignées ci-dessous. La procédure de saisie locale des paramètres publics reste celle de [SUPABASE_SETUP.md](SUPABASE_SETUP.md).

Authentification, schéma SQL, migrations, RLS, Storage, annonces réelles, chat et autres fonctionnalités restent hors du périmètre de KIBO-003. Conserver le workflow Direct Main et tous les changements existants.

## Tâche courante — KIBO-003.1
**Statut : corrections terminées ; contrôles automatisés et physiques réussis le 2026-10-31.**

Départ confirmé sur `main` propre et synchronisée au commit `ffdf8d430abe2973d51994a69a637190ca58a7af`. Le propriétaire a autorisé les corrections des trois défauts constatés sur TECNO : navigation à 150 %, alignement des illustrations et hauteur excessive des cartes.

L’arrêt initial sur l’import Material inutilisé de `test/widget_test.dart` est documenté dans [PROGRESS.md](PROGRESS.md). Le propriétaire a autorisé la reprise ; l’import a été vérifié puis retiré, sans refaire les corrections existantes.

Contrôles exécutés avec succès dans l’ordre : `flutter pub get`, `dart format lib test`, `flutter analyze --fatal-infos`, `flutter test` (**30 tests : 24 précédents et six nouveaux**), `flutter build apk --debug --target-platform android-arm64` et `git diff --check`.

Version corrigée installée et lancée sur TECNO CK6n / Android 14 avec paramètres publics saisis localement. Les trois corrections sont vérifiées à 100 % et 150 % : libellés complets et icônes alignées, illustrations cohérentes dans les rangées, cartes compactes avec texte lisible. Les cinq destinations ont été touchées et les quatre annonces restent accessibles. Réglage initial `font_scale=1.0` restauré. Captures inspectées, conservées uniquement hors Git ; aucune valeur Supabase publiée.

Documentation actualisée et diff relu pour le commit et le push Direct Main autorisés ; le SHA et le statut CI sont fournis dans le compte rendu de livraison. Aucun force-push. La prochaine tâche reste à cadrer avec le propriétaire : ne pas commencer KIBO-004.
