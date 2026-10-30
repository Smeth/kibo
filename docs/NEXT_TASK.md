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

## KIBO-003 — Intégrer le socle UI Manrope et Emerald
**Statut : préparée, périmètre proposé à valider par le propriétaire avant implémentation. Non démarrée.**

Cette proposition suit l’étape « Socle UI » de [ROADMAP.md](ROADMAP.md) et la [charte graphique](CHARTE_GRAPHIQUE.md). Aucune issue KIBO-003 n’est encore créée ; ne pas inventer de numéro ou de lien. La présente clôture documentaire n’autorise aucune modification du code applicatif.

### Objectif proposé
Appliquer la typographie Manrope et centraliser le thème clair Emerald afin d’aligner le socle visuel existant sur la charte, sans développer de fonctionnalité métier.

### Travail à réaliser après validation du périmètre
1. Lire `AGENTS.md`, `CHARTE_GRAPHIQUE.md`, `ARCHITECTURE.md`, `DECISIONS_TECHNIQUES.md` et `PROGRESS.md`. Vérifier le remote, la branche `main` et l’état Git ; préserver tous les changements existants.
2. Inspecter le thème actuel et préparer une intégration Manrope disponible hors ligne. Vérifier la provenance et la licence des fichiers de police avant ajout ; documenter la méthode retenue. Respecter les graisses 400, 600 et 800 de la charte.
3. Centraliser palette, styles de texte et thèmes des composants Flutter nécessaires dans une petite structure dédiée, adaptée à l’architecture existante. Conserver le thème clair ; ne pas imposer de refonte générale de `main.dart`.
4. Harmoniser les composants déjà présents avec la charte : marges horizontales de 16, espacements multiples de 4, rayons des cartes de 16, rayons des boutons de 12, dimensions des champs et icônes conformes. Ne pas modifier les parcours ni les données de démonstration au titre de cette tâche.
5. Préserver le démarrage Supabase centralisé, l’écran de chargement, les erreurs de configuration et l’affichage de l’accueil après réussite ; aucun paramètre réel ne doit entrer dans Git ou les tests.
6. Vérifier le rendu sur petite largeur et avec texte agrandi, ainsi que sur le TECNO. Adapter les tests pertinents sans remplacer les tests de configuration et de démarrage Supabase.
7. Exécuter résolution des dépendances si nécessaire, formatage, `flutter analyze --fatal-infos`, `flutter test`, compilation APK ARM64 et `git diff --check`. Rapporter uniquement les résultats réellement obtenus.
8. Mettre à jour la documentation et les décisions importantes. Committer et pousser sur `main` seulement si les contrôles passent et le diff correspond au périmètre validé ; aucun force-push, aucune branche ou PR systématique.

### Critères d’acceptation proposés
- Manrope et ses graisses sont intégrées selon la charte, sans téléchargement de police nécessaire à l’exécution.
- Couleurs et styles communs sont centralisés ; l’accueil conserve son contenu et le démarrage Supabase conserve ses comportements.
- Aucun débordement observé dans les tailles testées ; contrôles automatiques et compilation ARM64 réussis, limites visuelles rapportées.
- Aucun secret ni clé réelle ajouté ; modifications petites, revues et documentées.

### Hors périmètre
Authentification utilisateur, schéma SQL, migrations, politiques RLS, Storage, publication et consultation d’annonces réelles, chat, favoris, notifications, modération, paiements, nouvelle navigation métier et thème sombre. Ne pas réinitialiser ou recréer le projet Flutter.
