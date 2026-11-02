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
- Aucun commit ni push sans autorisation explicite de l'utilisateur. Si autorisés, faire des commits petits et explicites.
- Exécuter formatage, analyse et tests pertinents avant de pousser.
- Pousser sur `origin main` uniquement si le diff est attendu et les contrôles passent.
- Priorité utilisateur du 2026-11-01 : corriger tests, style et outillage non bloquants sans redemander un avis ; poursuivre les fonctionnalités indépendantes vers le MVP. S'arrêter uniquement pour un conflit inattendu ou un risque sur les données, la sécurité ou le travail existant. Les actions distantes restent limitées à celles explicitement autorisées.
- Les branches et Pull Requests restent possibles pour les changements risqués, mais ne sont pas obligatoires.

## Secrets
Ne jamais ajouter de clés privées, tokens, mots de passe, service_role ou fichiers d'environnement contenant des secrets.

## Compte rendu
Après chaque lot validé, lancer la version modifiée sur le téléphone connecté (autorisation utilisateur du 2026-11-01), sans effacer les données. Utiliser les fichiers de configuration locaux existants et distinguer lancement réussi et recette fonctionnelle réelle. Si l'appareil manque, signaler la limite et poursuivre le lot indépendant. Aucun message réel de test à autrui sans autorisation.

Après chaque tâche, indiquer les fichiers modifiés, les commandes et résultats des tests, ainsi que les limites connues. Indiquer le SHA seulement si un commit a été autorisé et créé. Voir [DEVELOPMENT_SETUP.md](DEVELOPMENT_SETUP.md) pour reprendre la configuration locale sans demander à nouveau les paramètres déjà disponibles. Aucun changement Supabase distant sans autorisation explicite.
