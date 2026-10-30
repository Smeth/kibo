# Prochaine tâche — KIBO

## KIBO-001 — Publier le socle Flutter existant sur main

Issue de référence : https://github.com/Smeth/kibo/issues/1

Le socle existant est intégré dans le commit accompagnant ce document. Les contrôles locaux et le lancement Android ont réussi ; voir [PROGRESS.md](PROGRESS.md). Le compte rendu de session indique le SHA et confirme le push, ou précise un éventuel blocage de publication.

## Workflow applicable
Le propriétaire a explicitement choisi Direct Main le 2026-10-30. Cette instruction remplace l’ancienne version de KIBO-001 qui demandait une branche `feature/flutter-foundation` et une Pull Request. Pour les tâches courantes : travailler sur `main`, préserver les modifications locales, tester avant commit et push, ne jamais faire de force-push.

## Suite
Aucune prochaine tâche détaillée n’est encore définie. Faire valider le périmètre du socle UI (Manrope et thème Emerald) avant toute nouvelle implémentation. Ne pas connecter Supabase ni ajouter de dépendance UI au titre de KIBO-001.
