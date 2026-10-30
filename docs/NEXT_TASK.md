# Prochaine tâche — KIBO

## KIBO-001 — Publier le socle Flutter existant sur main

Issue de référence : https://github.com/Smeth/kibo/issues/1

**Statut : terminée et publiée sur `origin/main`.**

Commit du socle : [`4d7ccd38a98c0868737cb801bc5f79a2fcb1e283`](https://github.com/Smeth/kibo/commit/4d7ccd38a98c0868737cb801bc5f79a2fcb1e283).

Le 2026-10-30, une nouvelle vérification a confirmé un dépôt propre, le socle déjà suivi et le même SHA sur `main` et `origin/main` après `git fetch origin main`. Les contrôles locaux ont été relancés avec succès et la [CI du socle](https://github.com/Smeth/kibo/actions/runs/41129735329) est réussie. Voir [PROGRESS.md](PROGRESS.md). Ne pas recréer le projet ni republier un doublon du socle.

## Workflow applicable
Le propriétaire a explicitement choisi Direct Main le 2026-10-30. Cette instruction remplace l’ancienne version de KIBO-001 qui demandait une branche `feature/flutter-foundation` et une Pull Request. Pour les tâches courantes : travailler sur `main`, préserver les modifications locales, tester avant commit et push, ne jamais faire de force-push.

## Suite
Aucune prochaine tâche détaillée n’est encore définie. Faire valider le périmètre du socle UI (Manrope et thème Emerald) avant toute nouvelle implémentation. Ne pas connecter Supabase ni ajouter de dépendance UI au titre de KIBO-001.
