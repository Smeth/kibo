# Récapitulatif autonome KIBO — lots 2 à 8

Exécution autorisée le 2026-11-01, sans intervention utilisateur. Dépôt KIBO confirmé sur main, remote Smeth/kibo ; travail antérieur conservé. Aucun fichier étranger à KIBO modifié ou supprimé, aucune installation d'outil, aucun achat de service. Les SDK existants et leurs caches nécessaires à KIBO ont été utilisés. Aucun commit/push ni diffusion publique.

## Livrables

| Lot | Résultat |
|---|---|
| 2 — recette | 93 tests ciblés et scénarios SQL croisés chat/notifications/annonces ; favoris/contacts inclus dans les tests Flutter. Installation TECNO réussie. Deux comptes réels non disponibles : pas de validation humaine ou réseau inventée. |
| 3 — navigation/UI | Messages et Notifications avec libellés visibles, en-tête qui s'adapte aux petites largeurs et au texte agrandi ; composant de vide/erreur cohérent avec thème Manrope Emerald. 59 tests ciblés et lancement appareil. |
| 4 — découverte | Filtres actifs supprimables individuellement, recherche conservée entre onglets, position conservée au retour d'une fiche, actions utiles dans les états vide/erreur. Titres complets conservés pour l'accessibilité. |
| 5 — vendeur | Brouillon texte propre au projet/compte, sauvegardé dans le stockage sécurisé existant, restaurable et effaçable explicitement. Identifiants de publication conservés pour reprise sans doublon ; photo principale explicite et aperçu avant publication. 110 tests annonces/photos/responsive et lancement appareil. |
| 6 — échanges | Interlocuteur public, dernier message/date et compteurs par conversation ; lecture des seuls messages entrants consultés, accusés réels ; arrivée de messages sans perdre la lecture ancienne, bouton vers les plus récents. 25 tests chat ciblés réussis et lancement appareil. |
| 7 — confiance/compte | Conseils antifraude, blocage/déblocage des messages KIBO, récupération email PKCE et changement de mot de passe, information sur les données, demande de suppression annulable. Le compte n'est pas supprimé automatiquement : traitement opérateur encore nécessaire. |
| 8 — fiabilité/sécurité | Délais de lecture/envoi bornés, contenu déjà lu conservé si rafraîchissement échoué, UUID de reprise pour messages et annonces, pas de retry automatique d'écriture, ressources suspendues en arrière-plan, images décodées à largeur bornée, permissions et anti-abus côté serveur, index ciblés. |

Les photos d'un brouillon restent temporaires tant qu'elles ne sont pas publiées ; le formulaire le précise. En cas de brouillon illisible, sa conservation et le blocage de publication empêchent un écrasement ou une création dont l'identifiant ne pourrait pas être conservé. Le prix reste obligatoire, conformément au contrat serveur actuel. Google OAuth et SMS OTP ne sont pas activés : aucun fournisseur ni secret inventé pour dépasser le socle email.

## Serveur réellement appliqué

- `20261101052757 kibo_mvp_chat_account` : non lus, état de blocage, tables privées par RLS pour blocs et demandes de compte ; fonctions publiques invoker, contrôles d'identité/participant côté serveur.
- `20261101053807 kibo_mvp_chat_hardening` : accès aux colonnes d'insertion messages/conversations limité ; dates et accusés serveur ; 30 nouveaux messages et 5 signalements maximum par minute/compte ; index de lecture/limites.
- `20261101054728 kibo_mvp_block_lookup_index` : index de la référence inverse de la nouvelle table de blocage, sans modification de données ou de permissions.

Contrôles réels après application : aucune table publique sans RLS ; INSERT client de created_at/read_at messages refusé ; ID d'opération autorisé ; visiteur sans EXECUTE de l'état de chat ; triggers de limites installés. Bucket kibo-listing-photos toujours privé, limite 4194304 octets et JPEG normalisé. Aucun message, signalement, blocage ou compte réel créé/modifié pour la recette. Aucun rôle administrateur attribué.

## Preuves et périmètre des tests

Scripts reproductibles : `scripts/Validate-MvpLot.ps1` et `scripts/Test-OwnerManagementSql.ps1 -Suite Mvp` ; journaux sous `.dart_tool/mvp-*`. Format lib/test, analyse stricte, tests standard et photos activées, diff check ; lancement Android configuré avec les deux JSON déjà présents, sans effacement. Résultats globaux finaux et dernier lancement dans PROGRESS.

Résultat final : **293 tests standard + 293 photos activées réussis**, soit 21 tests ajoutés au socle de départ ; analyse stricte sans anomalie, format 100 fichiers sans changement et diff check code 0. Dernier lancement TECNO code 0 : compilation 18,5 s, installation 6,7 s, synchronisation 202 ms ; processus et MainActivity observés. Mesure mémoire debug ponctuelle archivée dans le plan détaillé, sans prétention de benchmark. Aucune capture effectuée faute de confirmation de fenêtre KIBO au premier plan, pour ne pas capturer une autre application.

SQL en PostgreSQL 13 **isolé**, fixtures uniquement : conversations/notifications/modération existantes, non lus, isolation A/B/tiers/visiteur, blocage dans les deux sens, accès au compte, idempotence, limites de fréquence et colonnes protégées. Dernière suite incluant l'index : code 0, cluster 55490 arrêté, dossier `.dart_tool/owner-sql-c55844f2396d4ddcaf089c2c47ce3836` conservé. Ce test ne remplace pas la recette Auth/Realtime PG17 entre deux comptes.

Incidents corrigés sans réduire les assertions : liste de chemins Windows dans le lanceur ; collision PageStorage filtres/scroll ; stockage de brouillon fictif à injecter dans les tests de redémarrage ; double fermeture d'un flux créé dans l'horloge des widgets ; transitions de cycle de vie Flutter ; PKCE fictif avec stockage explicite ; récupération liée à l'identité de l'événement ; titre non tronqué exigé par les tests existants. Trois exécutions de tests bloquées ont été arrêtées après identification exacte de leurs processus ; aucun autre processus touché. Aucun fichier existant supprimé pour résoudre un test.

## Limites restantes

- Recette réelle avec deux comptes/appareils pour chat, notifications et séparation des données ; réception réelle de l'email et ouverture du lien PKCE à froid.
- Suppression effective du compte : demande enregistrée/annulable, mais aucune automatisation de suppression Auth/annonces/messages. L'opérateur peut consulter `public.kibo_account_requests` avec son accès privilégié et doit définir/valider la procédure de traitement et de conservation avant diffusion publique. Aucun délai de traitement fictif promis.
- Notifications push OS, administration web, pièces jointes chat, Google/SMS, signature de diffusion et pilote Android restent hors des lots exécutés.
- Pas de benchmark release/profile, de test de charge ou de validation visuelle humaine complète. Le démarrage sur téléphone et les contraintes d'images/timers ne prouvent pas une performance production.
- Audit Edge TS historique non relancé : Deno non disponible dans l'environnement ; aucun téléchargement d'outil. Contrôles Dart/SQL/Storage exécutés.
- Avertissement Auth préexistant sur [la protection des mots de passe compromis](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection), réglages non modifiés. Conseiller performance : points existants d'index FK/initplans RLS/politiques multiples, sans réécriture globale ; nouveaux index ciblés ajoutés.

## Opération refusée par la revue automatique

Le fichier global `mvp_final_hardening.sql` **n'a pas été appliqué**. Auto-review a refusé le retrait MAINTAIN de toutes les tables publiques et des droits par défaut, estimant la portée trop large. Le contrat réduit, sans cette partie, a été testé puis appliqué avec succès ; aucune tentative de contourner ce refus. Le delta séparé a depuis été explicitement autorisé et appliqué (20261101090123) : MAINTAIN client retiré des neuf tables et des defaults postgres/public, RLS et autres droits inchangés. Les defaults supabase_admin restent hors de ce delta.

Un delta dédié, neuf tables nommées et defaults postgres uniquement, est préparé dans [client_maintain_pending_review.sql](../supabase/proposals/client_maintain_pending_review.sql). **Accord spécifique reçu et delta appliqué : voir [CLIENT_MAINTAIN_DEPLOYED.md](CLIENT_MAINTAIN_DEPLOYED.md).** Ne pas rejouer le fichier global, qui contient aussi des objets déjà créés. [Référence PostgreSQL 17](https://www.postgresql.org/docs/17/sql-grant.html).

## Inventaire des fichiers de cette exécution

- Nouveaux composants : `lib/core/widgets/kibo_state_panel.dart`, `lib/core/diagnostics/operation_id.dart`, `lib/features/listings/listing_draft_store.dart`, `lib/features/auth/password_pages.dart`, `lib/features/profile/account_settings_page.dart`, `lib/features/safety/trading_safety_notice.dart`.
- Intégrations : `lib/main.dart`, auth `auth_repository.dart`, `auth_controller.dart`, `auth_page.dart`, `profile_page.dart` ; chat `chat_repository.dart`, `chat_page.dart` ; annonces `catalogue_search_form.dart`, `listing_feed.dart`, `listing_card.dart`, `listing_models.dart`, `listing_repository.dart`, `listing_photo_widgets.dart`, `publish_listing_page.dart` ; `safety_entry.dart` et `seller_page.dart`.
- Nouveaux tests : `test/listings/mvp_discovery_test.dart`, `listing_draft_store_test.dart`, `mvp_reliability_test.dart`, `test/profile/account_mvp_test.dart`, `test/support/draft_fake.dart`. Adaptations : tests chat repository/widgets et scénarios publication directe/photos.
- SQL : `mvp_chat_account.sql`, `mvp_chat_hardening.sql`, `mvp_block_lookup_index.sql` appliqués ; `mvp_final_hardening.sql` refusé/non appliqué et `client_maintain_pending_review.sql` depuis appliqué après accord spécifique (20261101090123). Fixtures/assertions `test/sql/mvp_extensions_fixture.sql`, `mvp_extensions_assertions.sql`, `mvp_hardening_assertions.sql`.
- Outillage : `scripts/Validate-MvpLot.ps1`, extension du lanceur SQL existant. Documentation : ce rapport, plan autonome, PROGRESS, NEXT_TASK, MVP_STATUS, README et contrats concernés. Les changements préexistants et configurations locales sont conservés.
