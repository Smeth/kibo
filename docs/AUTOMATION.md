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
Le dépôt contient du code mobile en développement et des décisions de sécurité à valider. Les modifications doivent passer par une branche et une Pull Request. La fusion et les déploiements restent soumis à validation humaine. Ne jamais exécuter de code arbitraire issu d'une issue directement avec des privilèges élevés.

## Cycle recommandé
1. ChatGPT ou l'utilisateur consigne une tâche dans `docs/NEXT_TASK.md` ou une issue GitHub.
2. Codex dans VS Code lit `AGENTS.md` et la tâche, inspecte Git, puis développe sur une branche.
3. Codex exécute les contrôles locaux et ouvre une Pull Request.
4. GitHub Actions exécute les contrôles CI.
5. ChatGPT examine la PR et les résultats ; l'utilisateur valide la fusion.
6. Après fusion, mettre à jour `docs/PROGRESS.md` et définir la prochaine tâche.
