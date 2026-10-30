# Automatisation du workflow KIBO

## Ce qui est automatisé
- GitHub Actions lance les contrôles Flutter sur les Pull Requests et les pushs vers `main` lorsque le projet Flutter est présent.
- Les contrôles comprennent formatage Dart, analyse statique et tests Flutter.
- Les modèles d'issues et de Pull Request standardisent les demandes et les revues.
- `docs/NEXT_TASK.md` est la file de travail explicite pour Codex.
- `docs/PROGRESS.md` conserve l'état vérifié du projet.
- `AGENTS.md` fournit les règles persistantes à Codex.

## Ce qui n'est PAS automatisé
Le connecteur GitHub de ChatGPT ne déclenche pas à lui seul une session Codex locale dans VS Code. GitHub Actions ne peut pas piloter ton PC ou réveiller Codex dans VS Code sans un runner auto-hébergé et une intégration d'exécution dédiée. Aucun runner permanent, token Codex, clé API ou secret d'automatisation n'est installé ici.

## Pourquoi ne pas activer un agent autonome qui fusionne
Le propriétaire a choisi le workflow Direct Main : les tâches courantes sont committées et poussées directement sur `main` après contrôles locaux réussis et revue du diff. Les branches et Pull Requests restent possibles pour les changements risqués ou contributions externes. Aucun force-push n’est autorisé. Ne jamais exécuter de code arbitraire issu d'une issue directement avec des privilèges élevés.

## Cycle recommandé
1. ChatGPT ou l'utilisateur consigne une tâche dans `docs/NEXT_TASK.md` ou une issue GitHub.
2. Codex dans VS Code lit `AGENTS.md` et la tâche, inspecte Git, puis développe directement sur `main` en préservant le travail local.
3. Codex exécute les contrôles locaux, vérifie le diff, committe et pousse sur `origin main` si les contrôles passent.
4. GitHub Actions exécute les contrôles CI.
5. Codex rapporte le SHA, les résultats locaux et les limites ; ChatGPT et l'utilisateur peuvent examiner le commit et la CI.
6. À chaque tâche terminée, mettre à jour `docs/PROGRESS.md` et `docs/NEXT_TASK.md` sans inventer de nouvelle décision produit.
