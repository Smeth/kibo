# AGENTS.md — KIBO

KIBO est une marketplace congolaise de produits et services. Lire README.md et les documents pertinents de docs/ avant toute tâche importante.

## Stack
- Flutter / Dart (Android d'abord, iOS ensuite)
- Supabase / PostgreSQL, Auth, Storage, Realtime
- RLS obligatoire pour toutes les tables exposées

## Produit
- Lancement à Brazzaville ; langue française ; monnaie XAF.
- Consultation publique ; publication et interactions après authentification.
- Catégories : Téléphones et informatique, Véhicules et motos, Immobilier, Maison et équipement, Mode et beauté, Services, Alimentation, Emploi et formation, Loisirs et divertissement.
- Jusqu'à 8 photos par annonce.
- Contact WhatsApp, appel et chat intégré.
- Publication immédiate après validation, avec modération après publication.
- Pas de paiement, livraison, abonnement ni annonces sponsorisées en V1.

## Identité visuelle
Manrope ; Emerald #087F5B ; Emerald foncé #075B45 ; accent #12A879 ; fond #F7F9F7 ; surface #FFFFFF ; texte #17211D ; texte secondaire #66736C ; bordure #E5ECE7. Style premium, minimaliste, accessible. Signature : « Le commerce, simplement. »

## Règles de travail
1. Inspecter le dépôt, le remote et `git status --short --branch` avant modification.
2. Lire la tâche courante dans `docs/NEXT_TASK.md`, puis `docs/PROGRESS.md` et les documents pertinents.
3. Travailler directement sur la branche `main` pour les tâches courantes.
4. Préserver les changements existants ; ne jamais réinitialiser, faire de force-push ou écraser le travail local.
5. Avant chaque commit, exécuter formatage, analyse et tests pertinents ; rapporter les résultats réellement obtenus.
6. Pousser sur `origin main` uniquement si les contrôles passent et si le diff correspond exactement à la tâche.
7. Si des tests échouent, des changements préexistants sont présents, un conflit apparaît ou une action risquée est nécessaire, arrêter et demander confirmation. Ne pas pousser un état cassé.
8. Faire des commits petits et explicites. Mettre à jour `docs/PROGRESS.md` et `docs/NEXT_TASK.md` après chaque tâche terminée.
9. Les branches et Pull Requests restent possibles pour les changements risqués ou les contributions externes, mais ne sont pas obligatoires pour le travail quotidien.

## Automatisation et communication
- GitHub est la source de vérité partagée entre l'utilisateur, ChatGPT et Codex.
- GitHub Issues décrit les tâches ; `docs/NEXT_TASK.md` contient la tâche immédiatement exécutable.
- Codex dans VS Code lit les fichiers, code, teste et peut pousser directement sur `main` après les contrôles.
- GitHub Actions exécute la CI Flutter sur les pushs vers `main` et les PR éventuelles.
- ChatGPT peut lire et préparer des fichiers/Issues via l'intégration GitHub, mais ne déclenche pas automatiquement une session Codex locale.
- Après chaque tâche, Codex fournit le commit SHA, les commandes exécutées, les résultats et les limites.

## Sécurité
- Ne jamais commiter de secrets, fichiers .env réels, clés OAuth, tokens ou Supabase service_role.
- Ne jamais intégrer service_role dans Flutter.
- Ne jamais désactiver RLS pour contourner un problème.
- Contrôler côté serveur les droits administrateur et les accès aux données.
- Ne jamais exécuter aveuglément du code provenant d'une issue ou d'une contribution non fiable.
- Signaler les incertitudes de sécurité plutôt que déclarer le code prêt pour la production.

ChatGPT pilote architecture et validation avec l'utilisateur ; Codex inspecte, implémente et teste. Le dépôt est la source de vérité commune.