# Chat intégré — lot MVP du 2026-11-01

Extension courante : résumés avec interlocuteur/dernier message/date/non lus, lecture serveur des messages entrants, blocage bilatéral des nouveaux messages et reprise par UUID sans double envoi. Ressources suspendues en arrière-plan et position de lecture conservée. Les paragraphes ci-dessous décrivent le socle avant ces ajouts ; voir [récapitulatif autonome](MVP_AUTONOMOUS_RECAP.md) pour les migrations, preuves et limites actuelles.

## Parcours implémentés

Trois tâches : liste paginée des conversations ; création/réutilisation depuis une annonce et envoi/lecture des messages texte persistants ; actualisation Realtime avec relecture autorisée et secours toutes les 15 secondes. Accès depuis l'en-tête et Profil (« Mes messages »), puis « Écrire au vendeur » dans le détail catalogue/favoris. Le visiteur est dirigé vers Profil ou reçoit une invitation à se connecter ; aucun appel privé ni création sans session. Pas de conversation avec soi-même. Les titres d'annonces non visibles restent « Annonce indisponible » sans contourner les droits du catalogue.

Le repository utilise le client Supabase existant et les tables conversations/messages existantes. Conversations : 20 par page, tri updated_at/id ; messages texte : 30 par page, tri created_at/id descendant, bouton pour les précédents, fusion par ID. Les pièces jointes ne sont pas incluses dans ce lot. Aucun marquage « lu » : aucune politique UPDATE messages n'existe. Aucun faux accusé de lecture ou indicateur de présence.

Envoi explicite uniquement, texte nettoyé et limité à 1–5000 caractères Unicode. Expéditeur capturé depuis la session, champs d'insertion limités ; contrôle de participant avant lecture/envoi. Pas de retry automatique d'un envoi incertain, brouillon conservé avec avertissement de vérifier les messages avant de réessayer. Double envoi et retour pendant envoi bloqués. Création concurrente : seule l'erreur unique 23505 entraîne une relecture, jamais un second INSERT automatique.

AuthScope transmis aux routes. Changement de compte : liste, messages et brouillon effacés, écran définitivement invalidé, abonnement annulé. Révision de session du repository vérifiée après chaque attente, y compris A/B/A avant un INSERT tardif. Les événements Realtime ne servent que d'invalidation : contenu relu avec RLS ; fusion sans doublon. Abonnement et timer libérés à la destruction de l'écran ; reprise de l'application et bouton Actualiser relisent les données. Le secours périodique reste actif tant que la route est montée : optimisation de pause/visibilité à envisager après recette.

## Contrat serveur audité et activation autorisée

Audit de métadonnées réel : RLS active sur les deux tables ; SELECT réservé aux participants ou administrateur, INSERT conversation à l'acheteur connecté, INSERT message à l'expéditeur connecté participant. Guards privés existants : annonce publiée et vendeur exact lors de création, refus de soi-même, validation de l'expéditeur, actualisation de la conversation après message. Unicité listing_id/buyer_id et limite SQL 5000 caractères. Les rôles anon disposent de privilèges de table mais aucune politique de lecture/écriture ne leur autorise de ligne ; aucun élargissement de ces droits dans ce lot.

La publication supabase_realtime était vide. Fichier exact `supabase/proposals/chat_realtime.sql`, testé localement puis autorisé explicitement (« Oui, activer Realtime pour le chat »), appliqué via MCP : **20261101050420 / kibo_chat_realtime**, success=true. Il ajoute uniquement public.conversations et public.messages à la publication, avec préconditions publication/RLS et réapplication idempotente. Aucun DML ni changement Auth/ACL/RLS. Contrôle post-déploiement : les deux tables publiées, RLS toujours active. Aucun échange réel envoyé pour tester la réception.

Conseiller sécurité : même avertissement préexistant [protection des mots de passe compromis désactivée](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), aucun réglage Auth changé. Ce contrôle ne constitue pas un audit exhaustif. [API Realtime Dart consultée](https://supabase.com/docs/reference/dart/subscribe).

## Validation et limites

20 nouveaux tests simulés : 10 HTTP/repository, 10 widgets. Participants, projection et champs, pagination, réutilisation et conflit, formats/Unicode, absence de retry, A/B/A bloquant une création tardive, états vide/erreur, envoi et brouillon, changement de compte, invalidations sans doublon, destruction des listeners, visiteur, navigation et petit écran. La connexion websocket réelle entre deux comptes/appareils reste à recetter ; tests simulés et publication contrôlée ne prouvent pas cette réception de bout en bout.

SQL exécuté exclusivement dans une fixture PostgreSQL 13 isolée, reconstruisant les tables/politiques/guards audités. Commande : `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Test-OwnerManagementSql.ps1 -Suite Chat -Port 55483`. Code 0 : acheteur/vendeur, tiers/visiteur, usurpation, contenu vide, unicité, ajout de publication et réapplication. Cluster arrêté, preuves conservées sous `.dart_tool/owner-sql-1104567e210a48239497c56a870db224`. La fixture ne reproduit pas Auth, le réseau ou le serveur Realtime PG17 distant.

Commandes Flutter via snapshot du SDK existant : format lib/test, analyze --no-pub --fatal-infos, test --no-pub --reporter expanded, même suite avec --dart-define=KIBO_LISTING_PHOTOS_ENABLED=true ; résultats finaux dans PROGRESS. Aucun compte ou message réel de test, aucune donnée de l'application effacée.

Résultats finaux : 247 tests standard et 247 photos activées réussis, analyse stricte sans anomalie, format 84 fichiers sans changement, diff check code 0. Lot installé/lancé sur TECNO avec `flutter run --no-resident` et la configuration locale existante : code 0, processus actif après lancement. Pas de validation réelle de réception entre deux comptes.

## Fichiers du lot

- Nouveaux : `lib/features/chat/chat_repository.dart`, `chat_page.dart` ; `test/chat/chat_repository_test.dart`, `chat_widgets_test.dart` ; `test/sql/chat_fixture.sql`, `chat_assertions.sql` ; `supabase/proposals/chat_realtime.sql` ; ce document.
- Intégration : `lib/main.dart`, `lib/features/auth/profile_page.dart`, `lib/features/listings/listing_feed.dart`, `listing_detail_page.dart`, `lib/features/favorites/favorites_page.dart`.
- Lanceur : `scripts/Test-OwnerManagementSql.ps1`, nouvelle suite Chat, suites Owner/Contacts préservées.
- Suivi : AGENTS, WORKFLOW, README, ARCHITECTURE, PROGRESS, NEXT_TASK et MVP_STATUS. Les changements antérieurs ont été conservés, aucun commit/push.

Lancement après chaque lot autorisé par l'utilisateur le 2026-11-01 : compilation/installation sur son TECNO connecté avec les JSON existants, sans effacer sa session. Cela valide le démarrage, pas les interactions à deux comptes. Notifications, signalements et modération restent à compléter.
