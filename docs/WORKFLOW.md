# Workflow de collaboration

## Référence commune
Le dépôt GitHub est la source de vérité pour le code, les décisions et la documentation.

## Répartition
- ChatGPT : cadrage, architecture, décisions, revue et accompagnement.
- Codex dans VS Code : inspection du dépôt local, implémentation, commandes, tests et rapports.
- Utilisateur : valide les décisions produit et les changements structurants.

Les assistants ne partagent pas automatiquement leurs historiques de conversation. Toute information durable doit être inscrite dans les fichiers du dépôt.

## Règles Git
- Vérifier `git status` avant toute modification.
- Faire des changements petits et cohérents.
- Utiliser des messages de commit explicites.
- Ne jamais écraser les changements locaux de l'utilisateur.
- Pour une modification importante, utiliser une branche et une pull request.
- Rapporter les tests réellement exécutés et leurs résultats.

## Secrets
Ne jamais ajouter de clés privées, tokens, mots de passe, service_role ou fichiers d'environnement contenant des secrets.