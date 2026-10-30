# AGENTS.md — KIBO

KIBO est une marketplace congolaise de produits et services. Lire README.md et docs/ avant toute tâche importante.

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
1. Inspecter le dépôt et git status avant modification.
2. Lire la documentation pertinente et préserver les changements existants.
3. Avancer par petites étapes, sans inventer de décisions métier ou de configuration.
4. Lancer formatage, analyse et tests pertinents avant de conclure.
5. Documenter toute décision d'architecture importante.

## Sécurité
- Ne jamais commiter de secrets, fichiers .env réels, clés OAuth ou Supabase service_role.
- Ne jamais intégrer service_role dans Flutter.
- Ne jamais désactiver RLS pour contourner un problème.
- Contrôler côté serveur les droits administrateur et les accès aux données.
- Signaler les incertitudes de sécurité plutôt que déclarer le code prêt pour la production.

ChatGPT pilote architecture et validation avec l'utilisateur ; Codex inspecte, implémente et teste. Le dépôt est la source de vérité commune.