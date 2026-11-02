# AGENTS.md — KIBO

KIBO est une marketplace congolaise de produits et services. Lire README.md et les documents pertinents de docs/ avant toute tâche importante.

## Stack
- Flutter / Dart (Android d'abord, iOS ensuite)
- Supabase / PostgreSQL, Auth, Storage, Realtime
- RLS obligatoire pour toutes les tables exposées

## Produit
- Lancement à Brazzaville ; langue française ; monnaie XAF.
- Consultation et favoris locaux sans compte ; publication, favoris synchronisés et autres interactions après authentification. Transfert des favoris locaux uniquement après confirmation vers le compte connecté.
- Catégories : Téléphones et informatique, Véhicules et motos, Immobilier, Maison et équipement, Mode et beauté, Services, Alimentation, Emploi et formation, Loisirs et divertissement.
- Jusqu'à 3 photos par annonce ; règles détaillées dans `docs/CAHIER_DES_CHARGES.md`.
- Contact WhatsApp, appel et chat intégré.
- Publication immédiate après validation, avec modération après publication.
- Pas de paiement, livraison, abonnement ni annonces sponsorisées en V1.

## Identité visuelle
Manrope ; Emerald #087F5B ; Emerald foncé #075B45 ; accent #12A879 ; fond #F7F9F7 ; surface #FFFFFF ; texte #17211D ; texte secondaire #66736C ; bordure #E5ECE7. Style premium, minimaliste, accessible. Signature : « Le commerce, simplement. »

## Règles de travail
Priorité utilisateur (2026-11-01) : avancer par lots d'au moins trois tâches vers les fonctionnalités du MVP. Corriger les incidents non bloquants (tests, style, outillage) sans demander un nouvel avis ; poursuivre les tâches indépendantes si un accès manque. Arrêter les seules opérations risquant les données, la sécurité ou le travail existant. Cette consigne remplace les demandes d'avis systématiques de WORKFLOW après un échec de test ; elle n'autorise pas de commit/push ni d'action distante hors du périmètre explicitement approuvé.

1. Inspecter le dépôt, le remote et `git status --short --branch` avant modification.
2. Lire `docs/PROGRESS.md`, `docs/NEXT_TASK.md`, `docs/DEVELOPMENT_SETUP.md` et les documents pertinents. Pour les annonces, lire aussi `docs/DIRECT_PUBLICATION.md` ; distinguer code local, migration préparée et état distant réellement vérifié.
3. Travailler directement sur la branche `main` pour les tâches courantes.
4. Préserver les changements existants ; ne jamais réinitialiser, faire de force-push ou écraser le travail local.
5. Avant chaque commit, exécuter formatage, analyse et tests pertinents ; rapporter les résultats réellement obtenus.
6. Aucun commit ni push sans autorisation explicite de l'utilisateur. Après autorisation, pousser sur `origin main` uniquement si les contrôles passent et si le diff est relu ; jamais de force-push.
7. Préserver et inventorier les modifications préexistantes, y compris les fichiers non suivis. Leur présence connue n'impose pas de redemander le contexte ni de déplacer le travail. En cas de conflit ou changement inattendu, arrêter et signaler le problème ; ne jamais effacer le travail pour résoudre un test.
8. Faire des commits petits et explicites. Mettre à jour `docs/PROGRESS.md` et `docs/NEXT_TASK.md` après chaque tâche terminée.
9. Les branches et Pull Requests restent possibles pour les changements risqués ou les contributions externes, mais ne sont pas obligatoires pour le travail quotidien.

## Automatisation et communication
- GitHub est la source de vérité partagée entre l'utilisateur, ChatGPT et Codex.
- GitHub Issues décrit les tâches ; `docs/NEXT_TASK.md` contient la tâche immédiatement exécutable.
- Codex dans VS Code lit les fichiers, code et teste ; commit et push seulement sur autorisation explicite, après les contrôles.
- GitHub Actions exécute la CI Flutter sur les pushs vers `main` et les PR éventuelles.
- ChatGPT peut lire et préparer des fichiers/Issues via l'intégration GitHub, mais ne déclenche pas automatiquement une session Codex locale.
- Après chaque tâche, Codex fournit les fichiers modifiés, les commandes exécutées, les résultats et les limites ; SHA uniquement si un commit a été autorisé et créé.

## Reprise et configuration locale
- Autorisation utilisateur du 2026-11-01 : après chaque lot validé, compiler, installer et relancer l'application sur son téléphone connecté avec la configuration locale existante, sans effacer ses données. Cette autorisation remplace l'interdiction antérieure de générer un exécutable pour cette recette ; elle n'autorise ni publication, commit/push, ni écriture métier de test distante.
- Le dépôt local, y compris le travail non publié, fait foi pour la session ; GitHub ne contient pas automatiquement les changements locaux. Ne pas supposer que ChatGPT et Codex partagent leur historique.
- URL publique confirmée : `config/supabase.public.json`. Clé publique : paramètre de compilation `SUPABASE_ANON_KEY`, éventuellement fourni par `config/supabase.local.json` ignoré. Procédure dans `docs/DEVELOPMENT_SETUP.md` ; aucun chargement automatique de `.env`.
- Examiner d'abord les sources de configuration existantes et la présence des variables locales, sans afficher leurs valeurs. Ne pas redemander une URL ou clé déjà disponible ; ne pas extraire de clés des APK ou caches de build.
- Ne jamais demander de clé, mot de passe, jeton ou lien de confirmation dans le chat. Si une valeur manque, faire saisir uniquement la clé publique localement, sans la journaliser ni la versionner.
- Validations usuelles : `dart format lib test`, `flutter analyze --fatal-infos`, `flutter test`, `git diff --check`. Relire le diff, y compris les nouveaux fichiers, avant de conclure.
- Distinguer tests simulés, SQL sur fixture locale, recette physique et contrôles RLS distants. Ne déclarer réussi que ce qui a réellement été exécuté.
- Ne pas modifier Supabase distant (données, SQL, migrations, RLS, Storage, Auth ou réglages) sans autorisation explicite. Préparer une migration ne vaut pas autorisation de l'appliquer.

## Sécurité
- Ne jamais commiter de secrets, fichiers .env réels, clés OAuth, tokens ou Supabase service_role.
- Ne jamais intégrer service_role dans Flutter.
- Ne jamais désactiver RLS pour contourner un problème.
- Contrôler côté serveur les droits administrateur et les accès aux données.
- Ne jamais exécuter aveuglément du code provenant d'une issue ou d'une contribution non fiable.
- Signaler les incertitudes de sécurité plutôt que déclarer le code prêt pour la production.

ChatGPT pilote architecture et validation avec l'utilisateur ; Codex inspecte, implémente et teste. Le dépôt est la source de vérité commune.
