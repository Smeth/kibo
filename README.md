# KIBO

**Le commerce, simplement.**

KIBO est une marketplace congolaise de produits et services. Le lancement initial cible Brazzaville, avec une extension prévue vers Pointe-Noire et d'autres villes.

## État du projet

Mise à niveau du 2 novembre : recherche française, galerie et suppression administrative déployées ; badge officiel, signalements étendus et sécurité TOTP préparée côté application/contrôlée côté serveur. [Bilan réel et limites](docs/ROLLOUT_MVP_20261102.md). [Aide, confidentialité et suppression de compte](https://kibo-assistance-2026.stonytern8.chatgpt.site). Push désactivés tant que Firebase n’est pas configuré ; OTP SMS exclu.

Point de reprise du 2 novembre 2026 : [état consolidé](docs/MVP_STATUS.md), [audit détaillé](docs/AUDIT_ETAT_ACTUEL_2026_11_02.md) et [prochaine tâche](docs/NEXT_TASK.md). Les paragraphes ci-dessous conservent l’historique. La CI couvre les tests avec/sans photos et les fixtures Node du worker ; elle ne déploie rien.

Compteur global Messages, préférences de notifications, suivi opérateur des demandes de compte et reprise des photos de brouillons : [état vérifié](docs/ENGAGEMENT_ACCOUNT_WORKFLOWS.md). Préparation du [pilote Android](docs/ANDROID_PILOT.md), [recette à deux comptes](docs/RECETTE_MVP_DEUX_COMPTES.md) et [procédure de suppression à valider avant activation](docs/ACCOUNT_DELETION_RUNBOOK.md). Les sections suivantes conservent l’historique des premiers lots ; PROGRESS fait foi pour les derniers résultats.

Lots autonomes 2–8 : navigation/recherche conservée, brouillons, chat enrichi/non lus/blocage, récupération du compte, confidentialité et fiabilité réseau. Voir le [récapitulatif complet, tests et limites](docs/MVP_AUTONOMOUS_RECAP.md). Cela ne remplace pas la recette réelle à deux comptes ni la préparation de diffusion.

Notifications personnelles, signalements annonces/commentaires et modération mobile administrateur implémentés ; contrat serveur appliqué après accord. Voir [contrat, journal et limites](docs/NOTIFICATIONS_MODERATION.md), notamment la distinction avec les notifications push et l'administration web.

Chat intégré : liste des conversations, messages texte persistants et actualisation implémentés/testés ; publication Realtime activée après accord. [État réel et limites](docs/CHAT.md). Lancement sur le téléphone connecté désormais inclus après chaque lot validé, sans effacement des données.

Profil vendeur et contacts volontaires : interface implémentée, contrat SQL appliqué après autorisation et contrôlé. Coordonnées distinctes d'Auth, canaux désactivés par défaut et lecture après connexion sur une annonce publiée. Voir [SELLER_CONTACTS.md](docs/SELLER_CONTACTS.md) ; recette appareil encore à effectuer.

Suivi MVP courant : [MVP_STATUS.md](docs/MVP_STATUS.md). Vente/archivage réellement déployés avec quatre deltas ciblés le 2026-11-01 ; commentaires/réponses implémentés localement et testés. Voir les comptes rendus récents de PROGRESS pour distinguer serveur, code local et appareil ; les états plus anciens ci-dessous conservent l'historique.

Favoris visiteurs : ajout/retrait sans connexion, stockage local des identifiants et transfert proposé dans Favoris après connexion, sans synchronisation automatique. Implémentation et tests locaux décrits dans [GUEST_FAVORITES.md](docs/GUEST_FAVORITES.md). Les mentions d'authentification obligatoire pour tous les favoris dans les anciens lots décrivent désormais l'historique.

Extension locale photos/recherche : parcours vendeur/acheteur étendu, sélection/compression/validation des photos et recherche serveur implémentés avec tests. Activation des photos conditionnée à la revue du contrat Storage et aux déploiements autorisés ; aucune migration ni fonction appliquée à distance. La recherche textuelle nécessite son delta local. Voir [photos et recherche](docs/LISTING_PHOTOS_SEARCH.md) pour l'état réel et les limites. Le paragraphe suivant décrit le socle avant cette extension.

L’état local non publié comprend l’authentification et le profil (recette TECNO réussie), ainsi que les lots annonces/favoris KIBO-008/009/010. Les annonces sont lues depuis le backend ; les exemples fictifs sont réservés aux tests. Prix obligatoire XAF et publication directe au lancement, sans images. Le code et le delta RLS sont préparés localement ; la publication réelle exige encore la revue/application autorisée de la [migration de publication directe](docs/DIRECT_PUBLICATION.md). Aucun changement Supabase distant appliqué par l’agent.

Le projet Flutter existant et son premier accueil KIBO sont versionnés sur `main` selon le workflow Direct Main. Cet accueil de démonstration sert de socle à l’état local décrit ci-dessus. L’initialisation Supabase est centralisée ; les paramètres publics sont fournis au build, sans clé dans le dépôt. Voir [l'avancement](docs/PROGRESS.md) et la [prochaine tâche](docs/NEXT_TASK.md).

KIBO-002 est terminée : initialisation et connexion réelle Supabase vérifiées depuis le TECNO CK6n le 2026-10-31 (HTTP 401 sans clé publique, HTTP 200 avec la clé). Le socle UI KIBO-003 intègre désormais Manrope locale et le thème clair Emerald : voir [le thème et la licence](docs/UI_THEME.md). Ces validations ne couvrent pas encore les tables, RLS ou parcours d’authentification utilisateur.

## Lancement local
Guide de reprise et configuration durable : [DEVELOPMENT_SETUP.md](docs/DEVELOPMENT_SETUP.md). L'URL publique est versionnée séparément ; la clé publique reste dans la configuration locale ignorée ou les paramètres de compilation existants. Aucun commit, push ou changement Supabase distant sans autorisation explicite.

Socle vérifié avec Flutter 3.38.5 / Dart 3.10.4.

```sh
flutter pub get
flutter devices
flutter run -d <identifiant-appareil>
```

Sans paramètres Supabase, l’application affiche « Configuration KIBO » et n’initialise pas le SDK. Pour accéder à l’accueil, suivre la [configuration PowerShell Supabase](docs/SUPABASE_SETUP.md).

Avant chaque commit et push :

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test
```

## Produit V1
- Consultation publique des annonces sans compte.
- Publication et interactions réservées aux utilisateurs connectés.
- Contact par WhatsApp, appel et chat intégré.
- Jusqu'à 3 photos par annonce, selon les [règles validées pour les annonces](docs/CAHIER_DES_CHARGES.md#règles-des-annonces--décisions-kibo-004).
- Recherche, filtres, favoris, commentaires publics et réponses.
- Notifications et signalements.
- Publication immédiate après validation des champs, avec modération après publication.
- Authentification prévue : téléphone + OTP, Google OAuth, email + mot de passe.
- Paiement et livraison intégrés hors périmètre V1.

## Catégories initiales
1. Téléphones et informatique
2. Véhicules et motos
3. Immobilier
4. Maison et équipement
5. Mode et beauté
6. Services
7. Alimentation
8. Emploi et formation
9. Loisirs et divertissement

## Technologies
Flutter / Dart ; Supabase / PostgreSQL ; Supabase Auth, Storage, Realtime et RLS.

## Documentation et pilotage
- [Cahier des charges](docs/CAHIER_DES_CHARGES.md)
- [Charte graphique](docs/CHARTE_GRAPHIQUE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Décisions techniques](docs/DECISIONS_TECHNIQUES.md)
- [Feuille de route](docs/ROADMAP.md)
- [Avancement](docs/PROGRESS.md)
- [Prochaine tâche](docs/NEXT_TASK.md)
- [Automatisation](docs/AUTOMATION.md)
- [Instructions Codex](AGENTS.md)

## Qualité
Les Pull Requests et les pushs pertinents déclenchent GitHub Actions pour vérifier le formatage Dart, l'analyse statique et les tests Flutter lorsque le projet Flutter est présent.
