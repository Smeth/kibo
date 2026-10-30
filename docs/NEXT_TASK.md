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
Aucune tâche KIBO-004 immédiatement exécutable n’est encore définie. Ne pas commencer de fonctionnalité métier sans périmètre validé.

Contrôle complémentaire proposé : revue visuelle du thème sur le TECNO CK6n avec la configuration publique saisie localement selon [SUPABASE_SETUP.md](SUPABASE_SETUP.md), sans publier de valeur ni refaire la configuration Supabase. Ce contrôle physique reste à réaliser ; les aperçus et tests automatisés ne le remplacent pas.

Authentification, schéma SQL, migrations, RLS, Storage, annonces réelles, chat et autres fonctionnalités restent hors du périmètre de KIBO-003. Conserver le workflow Direct Main et tous les changements existants.
