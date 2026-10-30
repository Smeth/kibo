# Workflow de collaboration KIBO

## Référence commune
Le dépôt GitHub est la source de vérité pour le code, les décisions et la documentation.

## Répartition
- ChatGPT : cadrage, architecture, décisions, revue et accompagnement.
- Codex dans VS Code : inspection du dépôt local, implémentation, commandes, tests et commits.
- Utilisateur : valide les décisions produit et les changements structurants.

Les assistants ne partagent pas automatiquement leurs historiques de conversation. Toute information durable doit être inscrite dans les fichiers du dépôt.

## Règles Git
- Travailler directement sur `main` pour les tâches courantes.
- Vérifier `git status --short --branch` avant toute modification.
- Ne jamais écraser les changements locaux non committés.
- Ne jamais faire de force-push, de reset destructif ou de nettoyage global.
- Faire des commits petits et explicites.
- Exécuter formatage, analyse et tests pertinents avant de pousser.
- Pousser sur `origin main` uniquement si le diff est attendu et les contrôles passent.
- En cas de conflit, test échoué ou changement inattendu, s'arrêter et demander l'avis de l'utilisateur.
- Les branches et Pull Requests restent possibles pour les changements risqués, mais ne sont pas obligatoires.

## Secrets
Ne jamais ajouter de clés privées, tokens, mots de passe, service_role ou fichiers d'environnement contenant des secrets.

## Compte rendu
Après chaque tâche, indiquer le commit SHA, les fichiers modifiés, les commandes et résultats des tests, ainsi que les limites connues.