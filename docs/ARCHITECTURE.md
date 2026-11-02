# Architecture cible — KIBO

Extensions MVP autonomes : brouillon texte local `ListingDraftStore` projet/compte avec identifiant d'opération persistant ; interfaces optionnelles de capacités pour l'idempotence des annonces/chat ; recovery PKCE dont les événements portent l'identité du compte ; demandes de compte non destructives. Helpers privés pour non lus/blocages et limites, façades publiques invoker. Aucune dépendance ajoutée. [État et limites](MVP_AUTONOMOUS_RECAP.md).

Notifications/modération : `features/safety/` compose repository injectable, centre personnel, formulaire de signalement, file et journal administrateur. Routes AuthScope, révision de session SDK, compteur borné et rafraîchissement après retour. RPC publiques invoker vers helpers privés contrôlés ; données métier existantes réutilisées, décision/journal atomiques et notifications des futurs messages/commentaires. [Contrat et limites](NOTIFICATIONS_MODERATION.md).

Chat : `features/chat/` réutilise le client Supabase et AuthScope, avec repository injectable, routes depuis Profil/en-tête et détail d'annonce. Révision de session et invalidation définitive des écrans A/B/A ; événements Postgres utilisés uniquement pour déclencher une relecture RLS et fusion par ID, secours périodique. Les tables conversations/messages existantes sont réutilisées ; seule leur publication Realtime a été activée après autorisation. [Contrat, tests et limites](CHAT.md).

Commentaires : `features/comments/` réutilise le client Supabase et la session existants. `KiboApp` injecte le repository dans le catalogue/favoris puis le détail ; les routes transportent explicitement AuthScope pour ne pas perdre les changements de session. Discussion publique paginée, formulaire authentifié et un niveau de réponses, sans accès aux profils privés ni modification de RLS. [Contrat](COMMENTS.md).

Favoris visiteurs : `features/favorites/guest_favorites.dart` porte le store local injectable et son contrôleur, séparés du repository et des données authentifiées. `FavoritesSession` les compose et libère leurs listeners ; `KiboApp` injecte le store sécurisé existant et le même repository public. `FavoritesController` ne transfère une sélection locale que sur demande avec propriétaire et révision de session capturés. Aucun nouveau client Supabase ni package. [Contrat détaillé](GUEST_FAVORITES.md).

## Vue d'ensemble
- Client mobile : Flutter / Dart.
- Backend : Supabase.
- Base : PostgreSQL.
- Authentification : Supabase Auth.
- Fichiers : Supabase Storage.
- Temps réel : Supabase Realtime.
- Autorisation : Row Level Security (RLS).
- Administration : application web séparée, à concevoir.

## Organisation Flutter indicative
Adapter à la structure réellement générée et éviter la complexité prématurée.

```text
lib/
  core/
  shared/
  data/
  domain/
  features/
    auth/
    home/
    search/
    listings/
    favorites/
    profile/
    chat/
    comments/
    notifications/
    moderation/
```

## Domaines de données à modéliser
Profils ; catégories ; annonces ; images d'annonces ; favoris ; conversations ; participants ; messages ; commentaires et réponses ; signalements ; notifications ; journaux d'audit.

Le schéma SQL définitif doit être conçu sous forme de migrations versionnées, relues et testées. Un ancien script SQL de travail ne doit pas être considéré comme prêt pour la production.

## Sécurité
- Activer RLS sur toutes les tables accessibles via l'API.
- Définir des grants minimaux et des politiques par opération.
- Séparer données de profil publiques et privées.
- Restreindre les fonctions SECURITY DEFINER et leurs privilèges EXECUTE.
- Contrôler propriétaire et statut des annonces lors des mises à jour.
- Bucket de photos privé ; éviter d’exposer publiquement les photos de brouillons, annonces masquées ou archivées.
- Valider côté serveur nombre, type, taille réelle et chemin des images, y compris en concurrence ; maximum 3 photos par annonce. Les règles fonctionnelles sont centralisées dans le [cahier des charges](CAHIER_DES_CHARGES.md#règles-des-annonces--décisions-kibo-004).
- La compression Flutter et les contraintes SQL sur les métadonnées ne remplacent pas les contrôles du fichier effectivement reçu par Storage.
- Séparer les données de localisation publiques des adresses exactes et coordonnées GPS, non publiques par défaut.
- L’archivage doit retirer l’annonce des lectures publiques, y compris via les favoris, tout en préservant l’historique du propriétaire.
- Protéger les actions administrateur côté serveur, jamais par une simple valeur client.
- Tester les accès autorisés et interdits des politiques RLS.

## Configuration
### Photos et recherche — extension locale

Services de sélection/compression et de photos injectés, contrat privé proposé, validation des octets dans une fonction Edge locale, et requêtes de recherche filtrées/paginées côté serveur. Photos désactivées par défaut tant que le contrat n'est pas audité/déployé avec autorisation ; aucun changement distant effectué. Les deltas locaux, les reprises, tests et limites sont détaillés dans [LISTING_PHOTOS_SEARCH.md](LISTING_PHOTOS_SEARCH.md).

### Lot annonces/favoris KIBO-008/009/010

`features/listings/` porte modèles/validations, repository injectable, formulaire, cartes responsives, liste paginée et détail. `features/favorites/` sépare repository et contrôleur de favoris personnel partagé ; sa portée est explicitement transmise au détail lors de la navigation. `KiboApp` injecte ces repositories après l’unique initialisation Supabase ; aucune nouvelle dépendance ou instance SDK. Les fixtures de catalogue sont uniquement dans `test/support/`. Contrats, adaptation au schéma déployé et limites RLS : [LISTINGS.md](LISTINGS.md).

Publication directe : Flutter insère published avec date UTC, le delta `supabase/migrations/20261031050000_direct_listing_publication.sql` impose la date serveur et adapte uniquement la politique INSERT. Delta préparé et testé sur fixture locale, non appliqué à Supabase. Retour catalogue neuf après succès et favoris immédiatement utilisables pour l’annonce publique ; pas d’ajout automatique. Cette migration incrémentale n’est pas un schéma initial. [Effets et limites](DIRECT_PUBLICATION.md).

Les URL et clés publiques nécessaires au client peuvent être configurées par environnement. Les secrets privilégiés restent côté serveur. Ne jamais commiter de secrets réels.

### Socle Supabase Flutter — 2026-10-30

- `lib/core/config/supabase_config.dart` : lecture des deux paramètres de build, validation HTTPS et format de clé publique, sans valeur réelle par défaut.
- `lib/core/supabase/supabase_service.dart` : accès client centralisé injectable ; un seul Future d’initialisation par service. Aucun accès avant réussite, erreurs publiques génériques sans logs de valeurs.
- `main` crée un service unique injecté dans `KiboApp` ; le démarrage affiche chargement, erreur de configuration ou accueil existant.
- Les tests remplacent l’initialiseur SDK, sans réseau ; aucun repository, schéma ou parcours d’authentification ajouté.
- Voir [SUPABASE_SETUP.md](SUPABASE_SETUP.md) pour PowerShell, limites de validation et garde-fous.

### Socle UI — 2026-10-31

`lib/core/theme/kibo_colors.dart` et `kibo_theme.dart` portent la palette et le thème clair Manrope. Les trois graisses statiques sont des assets locaux déclarés dans `pubspec.yaml`, avec licence embarquée et enregistrée dans Flutter. `main.dart` conserve ses widgets et son chemin de démarrage Supabase ; seules la présentation et l’adaptation aux tailles d’écran changent. Aucun service ou repository métier supplémentaire. Voir [UI_THEME.md](UI_THEME.md) pour provenance, organisation, tests et limites.

### Préparation du backend — KIBO-004

Les règles fonctionnelles sont validées ; le schéma, les transitions de statut, les politiques RLS et le protocole d’upload restent à concevoir et tester. Aucune migration métier créée ou déployée par le projet à ce stade ; les métadonnées du projet distant ne sont pas vérifiées. Les décisions et prérequis sont suivis dans [DECISIONS_TECHNIQUES.md](DECISIONS_TECHNIQUES.md#2026-10-31--préparation-du-backend-kibo-004) et [NEXT_TASK.md](NEXT_TASK.md).

### Authentification Flutter — KIBO-005

`features/auth/` porte repository, contrôleur de session, validations et écrans. `SupabaseService` reste l’initialiseur unique ; son client est injecté dans le repository après réussite du démarrage. `AuthSession`/`AuthScope` assurent la réactivité sans nouveau framework. La session et les vérificateurs PKCE utilisent le stockage chiffré dans `core/supabase/`. L’accueil reste public ; Profil ouvre les parcours et la déconnexion. Le profil est créé par le trigger distant existant, puis lu avec filtre d’identité ; aucune écriture SQL, modification RLS ou migration n’est ajoutée. Contrat confirmé par le propriétaire, limites de vérification et recette dans [AUTHENTICATION.md](AUTHENTICATION.md).

### Confirmation email Android — KIBO-006

`core/config/auth_callback.dart` centralise l’URI publique et son prédicat de réception. Le repository transmet `emailRedirectTo` ; l’initialiseur unique configure le SDK pour recevoir uniquement ce callback PKCE ou ses erreurs. Le manifeste délègue au plugin Supabase existant. Les événements de session existants actualisent le profil et ferment un formulaire encore ouvert ; aucun second initialiseur, routeur ou échange de code ajouté. Configuration et limites dans [AUTHENTICATION.md](AUTHENTICATION.md).

### Édition du profil — KIBO-007

`features/profile/` porte formulaire et validation de ville. Le repository/contrôleur auth existant expose l’UPDATE limité à `full_name, city`, avec identité attendue, filtre de propriétaire, retour serveur et protection des réponses tardives. Le formulaire reste lié au compte qui l’a ouvert. Aucun nouveau stockage, client ou framework ; session et callback inchangés. Contrat RLS communiqué, limites et recette dans [PROFILE.md](PROFILE.md).
