# Diagnostic du refus de publication — 2026-10-31

**État actualisé au 2026-11-01 :** publication directe déjà appliquée, accès public réparé et photos/recherche/Edge rétablis après autorisation explicite. Voir [SUPABASE_REPAIR_20261101.md](SUPABASE_REPAIR_20261101.md). Les sections suivantes conservent les constats historiques ; ne pas réappliquer leurs propositions.

## État courant — cause INSERT confirmée, SQL proposé final

Les constats de cette section remplacent les anciens statuts « indéterminé » conservés plus bas comme historique. Source : résultats de l'audit distant en lecture seule **confirmés par l'utilisateur dans la présente reprise** ; cet agent n'a pas réexécuté l'audit et ne dispose pas ici d'un export SQL intégral à attribuer à sa propre observation.

Faits confirmés pour fcfmfpywpurrvppxdltm : listings_insert_own ne permet que draft/pending et exige published_at IS NULL ; authenticated possède INSERT ; les triggers listings relevés sont BEFORE UPDATE, pas INSERT. Le client demande published avec une date : ces deux conditions INSERT échouent. **Cause du refus identifiée : prédicat RLS INSERT incompatible avec la publication directe.** Un droit INSERT existant ne neutralise pas WITH CHECK.

### Revue du SQL final

Fichier final proposé, conservé sans modification : `supabase/migrations/20261031050000_direct_listing_publication.sql`. SHA-256 : `3976C7FF2D33E3CB1998AC7146E6CCB4DE60259C7CA2220F0CA403E6E8E80969`.

**Compatible avec les définitions distantes confirmées pour ce correctif.** Pas de GRANT supplémentaire nécessaire pour INSERT. Le fichier transactionnel complet, y compris son preflight, est la proposition à appliquer ultérieurement ; pas de second fichier SQL concurrent ou d'extrait isolé à appliquer à sa place.

- Ajoute une fonction privée de trigger SECURITY INVOKER, search_path pg_catalog, sans lecture privilégiée, et révoque son EXECUTE direct PUBLIC/anon/authenticated.
- Ajoute un BEFORE INSERT : pour chaque nouvelle ligne published, published_at devient statement_timestamp(), même si le client fournit une date future. Les BEFORE ROW précèdent WITH CHECK ([PostgreSQL CREATE POLICY](https://www.postgresql.org/docs/current/sql-createpolicy.html)). Les triggers BEFORE UPDATE existants ne sont pas déclenchés par cet INSERT et restent intacts.
- Modifie uniquement listings_insert_own pour authenticated : auth.uid non NULL, seller_id = auth.uid, views_count = 0, rejection_reason NULL ; draft/pending avec date NULL conservés, published permis avec l'heure serveur du statement. Aucune politique permissive supplémentaire qui s'ajouterait en OR.
- Ne modifie ni RLS activée, ni grants des tables, ni SELECT/UPDATE/DELETE, ni favoris, ni données anciennes, ni défaut pending. Aucune promotion des annonces pending existantes. Le trigger s'applique aussi aux nouveaux INSERT administratifs published ; les privilèges administratifs existants ne sont pas recréés.
- Le preflight refuse une autre politique INSERT/ALL, une politique nommée mais de type/rôle différent, ou un trigger INSERT actif inattendu. CREATE sans OR REPLACE refuse une collision de fonction. Ne pas contourner ces refus si l'état diffère au moment d'une application autorisée. Le preflight n'établit toujours pas l'équivalence textuelle complète de l'ancien WITH CHECK ; les faits fournis ne sont pas un export SQL complet.

### Assertions vérifiées par lecture, sans nouvelle donnée

Les fichiers `direct_publication_assertions.sql`, `direct_publication_ownership_assertions.sql`, `direct_publication_legacy_policy.sql` et leur fixture ont été relus :

- Publication propre : INSERT published de A, heure serveur à la place de 2099, lecture B/anon ; usurpation seller_id, vues/rejet privilégiés et INSERT anon refusés.
- Propriété et UPDATE : A peut modifier son titre ; seller/status/views/date/rejet protégés par le guard de fixture ; B ne peut modifier le titre de A ni publier son pending (zéro ligne attendue), ni insérer au nom de A.
- Favoris : ajout sur published, refus de l'identité usurpée ou d'une annonce pending, lecture/suppression isolées A/B, retrait personnel et préservation du favori d'autrui.
- Ancienne politique : published refusé ; autres politiques, trigger UPDATE et ligne pending initiale préservés par les assertions existantes.

Les succès PostgreSQL enregistrés précédemment restent historiques ; **aucun test SQL ou Flutter relancé**, aucune fixture créée et aucune donnée insérée, même localement, dans cette reprise. Les tests de champs protégés simulent les guards UPDATE avec la fixture ; ils ne deviennent pas une nouvelle validation des fonctions distantes. Aucun changement du code applicatif ou des tests requis pour ce delta.

### Vérifications restantes seulement

1. Obtenir l'autorisation distincte d'appliquer le fichier transactionnel exact, en conservant les définitions précédentes déjà auditées. La présente demande n'autorise pas l'application.
2. Au moment autorisé, laisser le preflight et la transaction refuser tout écart/collision ; aucune modification supplémentaire pour les contourner.
3. Après application autorisée : vérifier le nouvel état des seuls objets modifiés, puis, avec autorisation distincte des écritures de recette, créer une annonce sous A, contrôler heure serveur/catalogue/détail/favoris et isolation A/B. Ces tests distants restent non effectués.

Aucun nouvel audit distant, aucune application SQL, aucun test distant, commit ou push. La consultation de l'index changelog Supabase a échoué (type Markdown non pris en charge par l'outil) ; la sémantique PostgreSQL du WITH CHECK/BEFORE ROW a été vérifiée dans sa documentation officielle. Aucun nouveau mécanisme Supabase implémenté.

## Nouvelle recherche d'accès : compatibilité encore indéterminée

Une nouvelle inspection confirme : aucun outil Supabase actif, aucune variable de connexion PG/DATABASE_URL/Supabase dans Process/User/Machine, aucun fichier de service PostgreSQL, pgpass présent mais **zéro entrée non commentée**, pas de token CLI aux emplacements vérifiés ni de projet CLI lié. psql 13 existe au chemin connu, sans connexion distante configurée. Les configurations MCP de projet sont absentes ; la configuration utilisateur mentionne MCP mais pas Supabase (contenu non affiché). La recherche d'intégrations découvre Supabase disponible, **non installé/non connecté** ; une proposition d'installation/connexion a été présentée, pas exécutée ni confirmée.

**Définitions SQL distantes observées : aucune. Compatibilité de la migration avec le distant : encore indéterminée.** Les clauses draft/pending citées plus bas proviennent du contrat historique et de la fixture, pas d'une nouvelle observation du serveur. Aucun essai de connexion par identifiants inventés, extraction de session navigateur ou appel avec la clé Flutter pour lire les catalogues.

### Débloquer sans transmettre de secret

Deux méthodes possibles, sans modifier le schéma ni les données :

1. Faire installer/connecter l'intégration Supabase par l'utilisateur via son authentification habituelle. Vérifier ensuite les outils réellement disponibles et la portée autorisée avant l'audit. Ne pas présumer que cette intégration impose la lecture seule : pour une restriction serveur explicite, utiliser une connexion MCP compatible avec l'URL officielle suivante, limitée au projet public identifié par la configuration locale :

   `https://mcp.supabase.com/mcp?project_ref=fcfmfpywpurrvppxdltm&read_only=true&features=database`

   Effectuer l'authentification OAuth dans le navigateur, jamais dans le chat ; la documentation officielle indique qu'aucun PAT n'est nécessaire pour ce flux. Ne créer aucune clé service_role. Le mode read_only exécute les requêtes sous un utilisateur PostgreSQL de lecture seule. Confirmer que execute_sql et les catalogues requis sont accessibles ; les erreurs de visibilité devront être signalées sans les contourner.

2. Sans connexion d'agent, l'utilisateur déjà autorisé ouvre le projet KIBO dans Supabase Dashboard, puis SQL Editor, et exécute le contenu de `supabase/audits/direct_publication_readonly.sql` (BEGIN READ ONLY et ROLLBACK conservés). Relever tous les jeux de résultats : politiques, ACL/droits effectifs, triggers et fonctions. Si l'éditeur n'affiche qu'un résultat à la fois, sélectionner chaque SELECT avec son CTE éventuel et l'exécuter séparément dans une transaction BEGIN READ ONLY / ROLLBACK ; aucune fonction applicative ne doit être appelée. Conserver les résultats localement, sans clé ni identifiants de connexion ; vérifier les corps de fonctions avant tout partage, car ils peuvent contenir des valeurs intégrées. Ne pas exécuter le fichier de migration.

Pour une connexion PostgreSQL directe ultérieure, prendre les paramètres exacts dans Dashboard > Connect, configurer l'authentification uniquement localement et utiliser SSL ; ne pas inventer le pooler/compte. Cette voie n'est pas configurée aujourd'hui et n'est pas nécessaire si la voie Dashboard ou MCP aboutit.

Références officielles consultées : [MCP Supabase, OAuth et paramètres read_only/project_ref/features](https://supabase.com/docs/guides/ai-tools/mcp), [connexion PostgreSQL et paramètres du Dashboard](https://supabase.com/docs/guides/database/connecting-to-postgres).

## Faits et limites

- Compte A connecté et refus au prix de 1000 XAF confirmés par le propriétaire sur TECNO.
- `SupabaseListingRepository.create` utilise la session courante, demande `status = published`, une date UTC, puis `RETURNING id,status,published_at` via PostgREST. Un seul code `42501` est converti en message générique ; le message original n'est pas conservé. Le prix ne permet donc pas d'expliquer ce refus.
- Le delta local n'est pas appliqué au serveur, selon le contexte confirmé. L'ancien contrat communiqué et la fixture exigent simultanément `status IN ('draft','pending')` et `published_at IS NULL` : les deux conditions sont incompatibles avec l'INSERT du client.
- Cette incompatibilité et le refus de l'ancien prédicat sont démontrés **sur la fixture locale**. La cause exacte distante n'est pas démontrée : grants INSERT/SELECT (dont RETURNING), accès aux schémas/fonctions, autres politiques et triggers peuvent aussi produire `42501`.

## Accès réellement examinés

Aucun outil Supabase/PostgreSQL connecté disponible. Aucune variable Supabase/PG/DATABASE_URL trouvée dans Process/User/Machine à cette inspection ; la configuration Flutter publique n'est pas un accès administratif aux catalogues PostgreSQL. Pas de token CLI à l'emplacement usuel, CLI Supabase non détectée, aucun projet CLI lié, aucun fichier de service PostgreSQL trouvé. Le fichier pgpass existant ne fournit aucune entrée exploitable. Aucun secret extrait des caches/APK, aucune nouvelle clé demandée.

L'inventaire navigateur signale un hôte indisponible ; la tentative de lecture de la fenêtre Chrome via Computer Use expire sur l'autorisation. Aucune session Dashboard ni métadonnée distante lue. Aucun appel SQL/REST distant effectué. Il faut reprendre l'audit avec un accès de métadonnées autorisé disponible, sans transmettre de secret dans le chat.

## Audit à effectuer avant correction

`supabase/audits/direct_publication_readonly.sql` prépare une transaction `BEGIN READ ONLY` terminée par `ROLLBACK` : politiques complètes listings/favorites et dépendances, ACL de tables/colonnes/schémas, droits effectifs anon/authenticated, triggers et corps de leurs fonctions, fonctions directement référencées dans les politiques, contraintes et valeurs par défaut. Aucune lecture de ligne métier ni fonction applicative appelée. Script vérifié sur PostgreSQL 13.22 local, **pas exécuté à distance**. Les fonctions appelées indirectement par les corps collectés devront être relues aussi ; une inspection partielle ne vaut pas validation.

Comparer la sortie au delta avant toute autorisation d'application :

1. Vérifier que `listings_insert_own` est bien la politique permissive INSERT authenticated attendue, puis lire son `WITH CHECK` complet et toutes les autres politiques INSERT/ALL, permissives ou restrictives.
2. Vérifier INSERT sur les colonnes envoyées et SELECT sur `id,status,published_at` pour le retour serveur ; relever les droits de schémas et des fonctions. Aucun GRANT global à ajouter par anticipation.
3. Lire les BEFORE/AFTER INSERT et UPDATE, leurs fonctions et dépendances ; repérer toute levée de `42501`. Comparer les protections des champs privilégiés et l'ownership.
4. Conserver un relevé exact avant modification, déterminer le delta requis et le retour arrière. La migration locale ne compare pas le texte intégral de l'ancien prédicat dans son preflight : un nom identique ne garantit pas l'équivalence.

## Delta minimal proposé, conditionnel

Si les métadonnées correspondent au contrat annoncé et les grants requis sont déjà présents, conserver **uniquement** le delta existant `supabase/migrations/20261031050000_direct_listing_publication.sql` : une fonction SECURITY INVOKER d'horodatage serveur, un BEFORE INSERT et l'ALTER de la politique existante. Pas de nouvelle politique permissive en OR, pas de modification SELECT/UPDATE/DELETE/favorites, aucun changement de ligne ancienne ou de défaut pending.

Le nouveau prédicat exige vendeur courant, vues zéro, rejet NULL, puis conserve draft/pending datés NULL et permet published à l'heure serveur imposée par le trigger. Cela ouvre seulement la publication initiale pour soi. Il ne doit pas permettre à un vendeur de modifier l'annonce d'autrui ni de modifier ses propres champs de modération.

Ne pas appliquer ce delta en l'état si un autre trigger INSERT, une politique différente ou un manque de droits est découvert. Corriger alors seulement l'objet identifié après revue, sans élargir aveuglément les grants ou toucher aux gardes UPDATE. Aucune modification de la migration existante proposée sans preuve du contrat exact. Aucune autorisation d'application distante donnée par cet audit.

## Tests exécutés et tests restants

Sur le cluster de fixture jetable déjà migré, 127.0.0.1:55459, utilisateur fictif kibo_check :

- `direct_publication_assertions.sql` : propriétaire publié avec heure serveur, lecture B/anon, usurpation INSERT/champs privilégiés/INSERT anon refusés et favoris isolés : réussi.
- `direct_publication_ownership_assertions.sql` (nouveau) : édition ordinaire par A réussie ; changements seller/status/views/date/rejet par A refusés ; B ne peut modifier le titre de A ni publier son pending (zéro ligne affectée attendu), ni insérer comme A ; favoris usurpés/pending refusés ; ajout/retrait personnel réussi et favori de A conservé lors des actions B : réussi.
- `direct_publication_legacy_policy.sql` : ancien prédicat refuse published : réussi.
- Script d'audit : exécution en lecture seule réussie sur cette fixture.

Toutes les transactions d'assertions sont annulées et le cluster est arrêté. La fixture réduit les fonctions Supabase, avec `is_admin = false` ; elle ne certifie pas les privilèges/guards administratifs réels. Les tests Flutter précédents ne sont pas relancés pour ces seuls fichiers SQL/documentation.

Étape requise : récupérer l'audit distant autorisé en lecture seule, prouver le prédicat/droit fautif, comparer le delta exact et obtenir une autorisation distincte avant toute application. Les tests distants avec A/B ne pourront être exécutés qu'après autorisation distincte de leurs écritures. Aucun test distant ni nouvelle annonce distante créé pendant ce diagnostic.
# Actualisation 2026-11-01 — droits de lecture et contrat distant réparés

La session Dashboard KIBO existante a permis l'inspection réelle : publication directe déjà appliquée (version serveur 20261031214815, nom 20261031050000_direct_listing_publication), guards UPDATE conservés. Le refus public actuel était distinct de l'ancien refus INSERT : EXECUTE sur private.is_admin() manquait à anon. Après lecture du corps app_metadata sûr, ce seul droit a été accordé avec autorisation explicite ; GET public 200 vérifié. Photos/recherche/Edge ont aussi été rétablis. [Compte rendu de l'intervention réelle](SUPABASE_REPAIR_20261101.md). Les sections précédentes conservent l'historique et ne constituent pas des instructions de réapplication.
