# Prochaine tâche — KIBO

## Statut
À prendre en charge par Codex dans VS Code. Cette tâche n'est pas encore exécutée.

Issue GitHub : https://github.com/Smeth/kibo/issues/1

## Tâche KIBO-001 — Publier le socle Flutter local dans une branche de travail

### Contexte connu
- Dépôt : https://github.com/Smeth/kibo
- Dossier local : `C:\Users\MONSTER\Documents\WORKSPACE\KIBO`
- Flutter 3.38.5 / Dart 3.10.4.
- Le projet Flutter a été généré localement avec `flutter create --project-name kibo --org com.kibo .`.
- Identifiant Android observé : `com.kibo.kibo`.
- L'application de démonstration a été remplacée par un premier accueil KIBO dans `lib/main.dart` et lancée sur TECNO CK6n / Android 14.
- La branche locale était `main`, synchronisée avec `origin/main`; les fichiers Flutter apparaissaient comme non suivis lors du dernier contrôle.
- La documentation KIBO est déjà dans le dépôt distant.

### Instructions
1. Lire `AGENTS.md` et la documentation `docs/`.
2. Exécuter `git status --short --branch` et vérifier le remote avant toute action.
3. Vérifier que les fichiers locaux Flutter et l'écran KIBO existent ; ne pas recréer le projet.
4. Vérifier `.gitignore` et confirmer qu'aucun secret, dossier de build, cache ou fichier local sensible ne sera ajouté.
5. Créer une branche `feature/flutter-foundation` depuis `origin/main` sans écraser les changements locaux.
6. Ajouter uniquement le socle Flutter nécessaire (par exemple `android/`, `ios/`, `lib/`, `test/`, `web/`, `windows/`, `linux/`, `macos/`, `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`, `.gitignore`). Adapter la sélection à ce qui existe réellement.
7. Exécuter `flutter pub get`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze` et `flutter test`. Corriger seulement les problèmes introduits ou clairement liés au socle, sans réécriture non demandée.
8. Committer sur la branche de fonctionnalité et pousser cette branche.
9. Ouvrir une Pull Request vers `main`, en utilisant le modèle du dépôt.
10. Renseigner `docs/PROGRESS.md` et lier la PR à l'issue KIBO-001 si elle existe.

### Critères d'acceptation
- Le projet Flutter existant est publié dans une branche de fonctionnalité.
- Aucun secret ni fichier temporaire n'est commité.
- Les commandes de validation et leurs résultats sont reportés honnêtement.
- Une Pull Request est ouverte ; ne pas fusionner automatiquement.
- Le téléphone peut toujours lancer l'application après récupération de la branche.

### Limites
Ne pas connecter Supabase, ajouter de dépendances UI ou commencer une nouvelle fonctionnalité dans cette tâche. Ne pas pousser directement sur `main`.
