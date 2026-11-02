# Gestion de mes annonces — état local au 2026-11-01

**État serveur actualisé :** sold et les deux guards ont été déployés avec autorisation ; les anciens blocages de contrat décrits ci-dessous sont historiques. [Déploiement et contrôles](OWNER_MANAGEMENT_DEPLOYED_20261101.md). La recette d'écriture réelle et physique reste à réaliser séparément.

## Complément : lot confirmation, filtres et recherche

Trois tâches locales terminées : confirmation stricte du résultat UPDATE, filtre par statut et recherche serveur française sur titre/description. Les critères s'appliquent avant pagination, sont conservés lors du chargement suivant et de l'actualisation, et se réinitialisent ensemble. Une recherche vide retrouve les annonces du compte ; aucun résultat se distingue d'une absence d'annonce. Recherche limitée à 120 caractères, déclenchée au clavier ou au bouton, sans requête par frappe. Les réponses devenues obsolètes sont ignorées.

Le retour UPDATE vérifie propriétaire, statut attendu, date valide et toutes les valeurs envoyées. Le prix est comparé en centimes BigInt pour accepter 1000 et 1000.00 sans arrondi binaire. Retour inattendu : message non confirmé et actualisation demandée, aucune relance automatique.

Version finale : **173 tests standard et 173 avec photos activées réussis** ; analyse stricte sans anomalie ; format 68 fichiers conforme ; diff check code 0. Le test de pagination a nécessité une correction de défilement autorisée par l'utilisateur et a révélé un défaut de réinitialisation corrigé (reset avant clear). La recherche valide aussi ses critères si le formulaire est démonté après un long défilement ; ce cas est couvert dans le scénario étendu. Les protections de session et les tests préexistants sont conservés. Tests simulés uniquement, pas de recette TECNO ni d'écriture distante.

**Audit distant maintenant effectué** : [constats exacts](OWNER_LISTING_SERVER_AUDIT.md). sold absent, deux guards bloquent les transitions ; filtrer Vendue renverra une erreur tant que le statut n'existe pas. Recherche vectorielle disponible au serveur. TRUNCATE accordé à anon/authenticated à traiter séparément. Aucune écriture réelle. Les paragraphes ci-dessous décrivent la première reprise et sont conservés comme historique.

Fichiers de ce lot (les autres modifications préexistantes sont conservées) :

- `lib/features/listings/my_listings_page.dart`
- `lib/features/listings/owned_listing_repository.dart`
- `lib/features/listings/owned_listing_query.dart` (nouveau)
- `test/listings/my_listings_widgets_test.dart`
- `test/listings/owned_listing_repository_test.dart`
- `supabase/audits/owner_listing_management_readonly.sql`
- `docs/OWNER_LISTING_MANAGEMENT.md`
- `docs/OWNER_LISTING_SERVER_AUDIT.md` (nouveau)
- `docs/PROGRESS.md`
- `docs/NEXT_TASK.md`

Commandes du lot : `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --no-pub --fatal-infos`, `flutter test --no-pub --reporter expanded`, puis même suite avec `--dart-define=KIBO_LISTING_PHOTOS_ENABLED=true`, et `git diff --check`. Exécution via le SDK existant (`dart .../flutter_tools.snapshot`) avec accès aux caches. Aucun ajout de dépendance ni génération d'APK. Logs de tests uniquement dans `.dart_tool/`, ignoré.

Le Profil donne accès à « Mes annonces » pour le compte connecté. La liste privée est paginée par vingt annonces et affiche les statuts. Le formulaire permet de modifier titre, description, prix XAF, catégorie, type, ville et quartier. Les photos sont conservées, sans gestion de leurs fichiers dans ce lot.

Transitions prévues par le client : published → sold, published → archived et sold → archived. Le contenu est modifiable seulement en draft/published. Aucune republication ni suppression physique. La vente et l'archivage nécessitent une confirmation. Favoris et photos ne sont pas supprimés ; les lectures publiques existantes restent limitées à published.

## Accès et concurrence

Le repository injecté réutilise le client Supabase et sa session. Chaque lecture filtre seller_id. Chaque UPDATE filtre id, seller_id, status et updated_at ; une réponse sans exactement l'ID attendu est un conflit. Les seuls champs envoyés sont le contenu éditable ou le statut, séparément. Les filtres client ne remplacent pas les grants, RLS et triggers serveur.

Le formulaire masque les saisies après changement de compte et ignore les réponses tardives. Les doubles sauvegardes et le retour pendant l'enregistrement sont bloqués. Erreurs réseau et refus serveur conservent la saisie sans annoncer un succès ni relancer automatiquement l'écriture. La liste est relue après succès ; les favoris sont rafraîchis après transition.

## Serveur : activation non validée

Le contrat historique documenté ne contient pas sold ; sa présence réelle n'est pas certifiée. Le relevé distant précédent indique que les guards UPDATE protègent le statut. Le client testé ne prouve donc pas que les transitions fonctionneront sur Supabase réel.

`supabase/audits/owner_listing_management_readonly.sql` et `supabase/proposals/owner_listing_guard_candidate.sql` existaient à la reprise. Le candidat ne remplace ni n'attache de trigger : **ce n'est pas une migration prête à déployer**. Avant tout delta, examiner les valeurs du type/contraintes, grants UPDATE/SELECT, toutes les policies et les corps des guards/horodatage existants. Préserver les protections de modération, d'ownership, les dates et le vecteur de recherche. Ne pas simplement supprimer un guard qui refuse une transition.

Les fixtures `test/sql/owner_listing_management_*` existaient aussi. Elles ne sont pas exécutées pendant cette reprise et ne constituent pas une validation distante. Aucun SQL ni écriture métier distante, build, installation, commit ou push effectué.

## Vérification de cette reprise

L'implémentation et son intégration Profil étaient déjà présentes localement. Cette reprise ajoute le blocage du retour pendant sauvegarde, la garde contre les confirmations multiples et deux tests de navigation/enregistrement ; elle conserve le travail préexistant.

- Tests ciblés repository/widgets : **23 réussis**.
- Suite Flutter complète standard : **152 réussis**.
- Analyse stricte : aucune anomalie, code 0.
- Format : 67 fichiers, aucun changement requis, code 0 après relance avec accès au cache SDK.
- `git diff --check` : code 0, seuls avertissements LF/CRLF préexistants.

Commandes : `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze --no-pub --fatal-infos`, `flutter test --no-pub test/listings/owned_listing_repository_test.dart test/listings/my_listings_widgets_test.dart --reporter expanded`, `flutter test --no-pub --reporter expanded`, `git diff --check`. Les commandes Flutter ont été exécutées via `dart C:/flutter/bin/cache/flutter_tools.snapshot` après blocage des lanceurs sandbox ; ces premières tentatives ont été interrompues. Premier contrôle de format : fichiers conformes mais accès à la télémétrie Dart refusé, puis relance réussie.

Tests avec services fictifs uniquement : aucune recette TECNO, aucun contrôle RLS distant et aucune suite supplémentaire avec le flag photos activé pendant cette reprise. Restent à couvrir sur backend autorisé : transitions réelles, isolation A/B, horodatage/conflits, conservation des photos/favoris et retrait du catalogue après vente/archivage.
