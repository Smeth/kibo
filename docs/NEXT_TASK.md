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

## KIBO-002 — Préparer et vérifier la connexion Supabase dans Flutter
**Statut : implémentée ; contrôles locaux et compilation APK ARM64 réussis. À conserver comme tâche courante pour validation avec le projet Supabase réel.**

Configuration, service injectable, gestion du démarrage, tests isolés et guide PowerShell réalisés. Les contrôles locaux et limites sont consignés dans [PROGRESS.md](PROGRESS.md). Aucune clé réelle n’a été utilisée. Le lancement avec les paramètres publics du projet réel et la validation distante restent à effectuer localement, sans copier de clé dans GitHub. Ne pas démarrer une autre fonctionnalité métier au titre de cette tâche.

### Blocage Android résolu le 2026-10-30
Le propriétaire a autorisé le diagnostic et la réparation de l’environnement. Le XML corrompu contenait uniquement des octets nuls. Les deux anciens dossiers d’outils ont été sauvegardés hors du SDK avant réinstallation officielle des Command-line Tools stables. L’inventaire SDK est désormais cohérent. Les deux JAR manquants ont été résolus par Gradle depuis Google Maven ; les téléchargements ont réussi avec TLS standard, sans désactiver SSL ni modifier les dépendances applicatives.

Les 21 fichiers préparés ont été préservés pendant la réparation ; seuls les comptes rendus sont ensuite actualisés. `flutter pub get`, formatage (7 fichiers inchangés), `flutter analyze --fatal-infos`, `flutter test` (13 tests), compilation APK debug ARM64 et contrôles Git réussis. Voir les preuves et limites dans [PROGRESS.md](PROGRESS.md). Le SHA et le résultat du push figurent dans le compte rendu de session.

### Validation restante
Lancer localement avec les paramètres publics du projet réel selon [SUPABASE_SETUP.md](SUPABASE_SETUP.md), sans écrire les valeurs dans Git ni dans les logs. Aucun test de joignabilité ni d’acceptation d’une clé réelle n’a été effectué. Ne pas déclarer la connexion distante ou la préparation production validée, ni commencer une fonctionnalité métier supplémentaire.

Issue : https://github.com/Smeth/kibo/issues/2

### Objectif
Poser une connexion Supabase propre, centralisée et testable, sans commencer les fonctionnalités métier.

### Instructions
1. Lire `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/DECISIONS_TECHNIQUES.md` et `docs/PROGRESS.md`.
2. Vérifier `git status --short --branch`, le remote et la présence des fichiers avant de modifier quoi que ce soit.
3. Ajouter une version de `supabase_flutter` compatible avec la contrainte Dart/Flutter du projet et consigner les versions dans `pubspec.lock`.
4. Utiliser `--dart-define=SUPABASE_URL=...` et `--dart-define=SUPABASE_ANON_KEY=...` (ou une approche équivalente documentée) pour la configuration. La clé anon/publishable est une clé client publique soumise aux politiques RLS ; elle ne doit jamais être confondue avec `service_role`.
5. Ne jamais mettre de secret privilégié dans l'application, le dépôt, les tests ou les logs. Ne jamais ajouter de valeur réelle de clé dans la documentation.
6. Initialiser Supabase une seule fois, au démarrage, uniquement quand la configuration nécessaire est valide. Si elle est absente ou invalide, garder une interface explicite d'erreur de configuration au lieu de provoquer un crash.
7. Créer une petite abstraction de configuration et d'initialisation facilement testable. Ne pas créer de repositories métier prématurément.
8. Ajouter des tests pour la configuration présente/absente/invalide et pour le chemin de démarrage approprié, avec isolation de l'accès réseau.
9. Documenter les commandes Windows PowerShell pour lancer l'application avec les deux valeurs de configuration. Ne pas inscrire de valeur de clé dans les exemples.
10. Exécuter `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --fatal-infos`, `flutter test` et `git diff --check`.
11. Mettre à jour `docs/PROGRESS.md` avec les résultats réels. Garder ce fichier comme prochaine tâche KIBO-002 jusqu'à sa validation complète.

### Hors périmètre
- Pas de tables SQL, migrations, policies RLS ni données de démonstration Supabase.
- Pas d'authentification, OTP, profil, Storage, annonces, favoris, commentaires ou chat.
- Pas de refonte UI ni dépendance UI.
- Pas de clé `service_role` dans Flutter, même temporairement.

### Critères d'acceptation
- Configuration de connexion centralisée, documentée et testée.
- Application toujours compilable en l'absence de valeurs Supabase.
- Aucun secret privilégié ou clé réelle commité.
- Toutes les commandes de validation réussissent.
- Compte rendu des fichiers modifiés, commandes, résultats et limites.

### Publication
Travailler directement sur `main`. Ne pas créer de branche ou PR pour cette tâche courante. Committer et pousser seulement après que tous les contrôles passent et que le diff ne contient que les changements attendus. Si test échoué, conflit ou changement inattendu : s'arrêter et demander confirmation.
