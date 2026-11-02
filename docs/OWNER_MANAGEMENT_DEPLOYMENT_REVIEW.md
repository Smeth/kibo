# Vente/archivage et privilèges — propositions locales, 2026-11-01

**Mise à jour :** quatre propositions ont ensuite été autorisées, appliquées et contrôlées à distance. Le delta defaults supabase_admin reste différé faute de rôle. [Compte rendu réel](OWNER_MANAGEMENT_DEPLOYED_20261101.md). Le reste de ce document conserve la préparation et les tests précédant cette application.

Ce lot prépare trois tâches : delta propriétaire, tests SQL isolés avec les deux guards réels, correction ciblée des privilèges clients. **Aucune application distante autorisée ni réalisée.** Le code Flutter et les favoris visiteurs sont inchangés dans ce lot. Les 191+191 tests Flutter précédents restent historiques ; ils ne remplacent pas les tests SQL.

## 1. Delta propriétaire pour revue

Baseline réelle relue via SQL READ ONLY / ROLLBACK, fonctions exportées dans `supabase/proposals/owner_management_baseline.json` (corps, ACL et empreintes de source, sans données métier). Les deux guards, is_admin et l'horodatage correspondent à l'audit précédent. Aucun compte, annonce ni photo réelle lu/modifié.

Ordre proposé : `owner_management_01_enum.sql`, commit, puis `owner_management_02_guards.sql`. Les propositions restent hors du dossier migrations ; CLI Supabase non détectée, aucun numéro de migration fabriqué ni db push. La séparation prévoit la [contrainte PostgreSQL d'utilisation d'une nouvelle valeur enum après commit](https://www.postgresql.org/docs/13/sql-altertype.html).

Les scripts arrêtent la transaction si les sources, les attributs de sécurité/langage/search_path, le type status, RLS, les valeurs enum ou les quatre triggers changent. Étape 2 : verrou borné, deux fonctions remplacées, triggers conservés, ACL/propriétaires préservés. Admin selon app_metadata inchangé ; SECURITY DEFINER déjà présent sur le guard public conservé, aucun nouveau privilège de contournement ajouté.

Contrat propriétaire : contenu modifiable seulement draft/published ; published → sold/archived, sold → archived ; pas de republication, pas de changement simultané contenu/statut. seller, vues, publication, rejet, devise, attributs et autres colonnes restent protégés. Les guards excluent updated_at de leur comparaison car le trigger existant l'écrase avec now(), et la colonne générée de recherche est recalculée après les BEFORE triggers. Les nouvelles colonnes non prévues restent protégées par défaut. Le chemin draft/rejected → pending reste interdit comme dans le comportement effectif antérieur ; sa réactivation serait une décision séparée.

Retour arrière proposé : `owner_management_rollback_guards.sql` refuse des corps différents de ceux de la proposition, restaure les deux corps exportés et conserve sold dans l'enum et toutes les lignes. Après ce retour, un vendeur ne pourra plus faire de transition sur sold ; un opérateur/admin devra gérer les annonces concernées. Ne pas supprimer/recréer l'enum ni convertir les données automatiquement.

## 2. Tests locaux

`scripts/Test-OwnerManagementSql.ps1` crée un dossier GUID sous `.dart_tool`, un cluster PostgreSQL 13 neuf, écoute seulement 127.0.0.1 sur un port dédié, exécute les fixtures puis arrête ce seul cluster. Aucun service existant réutilisé. La fixture reprend les corps exportés avec leurs retours de ligne exacts, reconstitue les deux triggers réels, l'horodatage et un JWT simulé app_metadata ; ce n'est pas le runtime Auth Supabase.

Assertions : propriété A/B, vente/archivage, champs système, statuts interdits, publication et vecteur conservés, édition de brouillon, absence d'élévation user_metadata, voie admin, conflit updated_at entre transactions et visibilité publique. Les photos sont représentées par une table de références de fixture : contrôle de conservation/visibilité de métadonnées uniquement, aucune validation du Storage réel ni de ses objets binaires. Favoris réels de fixture conservés sans octroyer d'accès à l'annonce archivée.

Incidents initiaux : les lanceurs Windows attendaient les descendants PostgreSQL, puis un ExitCode non récupéré a provoqué un arrêt avant toute assertion. La troisième instance créée a été arrêtée proprement ; les deux premières ne répondent plus et leurs PID étaient absents lors du nettoyage. Dossiers conservés. Après accord utilisateur « Oui, corriger et terminer le lot », le lanceur utilise ProcessStartInfo .NET sans fenêtre et attend seulement pg_ctl. Deux écarts supplémentaires ont été détectés par les gardes : snapshot de fixture créé dans public et héritant lui-même des droits à supprimer (déplacé en private), normalisation CRLF du rollback (remplacée par la restauration JSON exacte).

**Validation finale réussie, code 0** : `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/Test-OwnerManagementSql.ps1 -Port 55479`. Journal ignoré `.dart_tool/owner-management-sql-final.log`, cluster conservé sous `.dart_tool/owner-sql-717b082825d246909a4e4168563f1e16`, arrêt confirmé par pg_ctl et absence de réponse sur 55479. Refus attendu de réapplication stage 02 : code psql 3 et message de baseline vérifiés par le lanceur, puis assertions exécutées de nouveau. Réexécution stage 01 avant changement des guards vérifiée, restauration exacte des sources/ACL/attributs et de leur baseline vérifiée après rollback. Retour arrière des grants également exécuté et vérifié sur fixture uniquement, service_role et autres ACL conservés.

Serveur distant réellement relevé : PostgreSQL **17.11**. Tests exécutés avec le PostgreSQL **13** installé localement : aucun test de compatibilité exhaustive PG17, d'Auth réelle, de service Storage ou d'opérateur Supabase administratif revendiqué. Le transfert et la persistance des favoris visiteurs restent ceux du lot précédent, sans nouvelle recette Android. Les tests Flutter ne sont pas relancés pour ce lot exclusivement SQL/PowerShell/documentation ; les 191+191 précédents restent historiques.

## 3. Privilèges clients : revue distincte

Audit réel des ACL et default ACL en lecture seule : 54 grants directs sans grant option, accordés par postgres à anon/authenticated, soit TRUNCATE/REFERENCES/TRIGGER sur neuf tables : categories, notifications, listing_images, favorites, conversations, messages, listing_comments, reports, listings. Aucune appartenance à un autre rôle pour ces deux rôles clients. Les default ACL public des créateurs postgres et supabase_admin accordent aussi ces droits sur les futures tables. L'audit constate leur configuration actuelle ; il ne prouve pas historiquement quel outil a créé chaque grant.

`client_privileges_01_tables.sql` cible ces neuf tables, refuse les sources non auditées, n'utilise pas CASCADE, vérifie les droits effectifs et la conservation des autres ACL. Il ne supprime ni SELECT/INSERT/UPDATE/DELETE ni les droits service_role. Les deux scripts defaults sont séparés par créateur : l'opérateur doit être membre du rôle concerné ; aucun contournement de droits Supabase n'est prévu. Ils refusent une default ACL globale qui rendrait une révocation par schéma inefficace. Les defaults fonctions/séquences ne sont pas modifiés.

Le durcissement est ciblé sur trois privilèges : ce n'est pas une certification complète des accès API, des fonctions publiques, de MAINTAIN sur les versions récentes, ni des schémas Storage/Auth. Aucun TRUNCATE n'est essayé, même localement. Tests de droits sur tables actuelles et futures, avec contrôle que service_role et les autres ACL sont préservés.

`client_privileges_rollback.sql` reconstitue uniquement les grants audités ; **il réintroduit les privilèges excessifs**. Pour revue/retour opérateur expressément autorisé seulement, jamais un repli automatique. Avant application réelle : revoir ACL à jour, dépendances et droit d'agir pour supabase_admin, autoriser les fichiers exacts, enregistrer leurs empreintes et réconcilier l'historique des migrations. Aucune suppression métier requise.

Référence : [ALTER DEFAULT PRIVILEGES](https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html). Le changelog Supabase Markdown a été demandé ; le lecteur web a refusé son type de contenu, aucune conclusion sur ce contenu n'est revendiquée.

## Inventaire du lot

Propositions : `supabase/proposals/owner_management_baseline.json`, `owner_management_01_enum.sql`, `owner_management_02_guards.sql`, `owner_management_rollback_guards.sql`, `client_privileges_01_tables.sql`, `client_privileges_02_defaults_postgres.sql`, `client_privileges_03_defaults_supabase_admin.sql`, `client_privileges_rollback.sql`.

Audit : `supabase/audits/client_privileges_readonly.sql`. Lanceur : `scripts/Test-OwnerManagementSql.ps1`. Fixtures/assertions : `test/sql/owner_management_real_guards_fixture.sql`, `owner_management_extended_assertions.sql`, `client_privileges_fixture.sql`, `client_privileges_assertions.sql`, `client_privileges_rollback_assertions.sql`. Documentation : le présent fichier, `docs/PROGRESS.md` et `docs/NEXT_TASK.md`. Les migrations/candidats/fixtures antérieurs restent intacts ; aucun fichier applicatif, dépendance ou secret modifié. `git diff --check` : code 0, avertissements LF/CRLF préexistants.
