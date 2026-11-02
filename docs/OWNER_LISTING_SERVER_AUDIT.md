# Audit distant propriétaire — 2026-11-01

Lecture réelle via le connecteur SQL Supabase, projet KIBO `fcfmfpywpurrvppxdltm`, exclusivement dans des transactions `BEGIN READ ONLY` / `ROLLBACK`. Métadonnées seulement : aucune annonce/profil lu, aucun UPDATE, DDL ou déploiement, aucun secret extrait. Les corrections photos antérieures ne sont pas rejouées.

## Contrat constaté

- Enum `listing_status` : draft, pending, published, rejected, archived. **sold absent**.
- Table listings : RLS active, non forcée, propriétaire postgres.
- SELECT anon/authenticated : published OU seller_id = auth.uid() OU private.is_admin().
- UPDATE authenticated : propriétaire ou admin, même contrôle en USING et WITH CHECK. SELECT et UPDATE sont accordés à authenticated.
- INSERT authenticated : contrat de publication directe avec date statement_timestamp, ou draft/pending avec date nulle. DELETE authenticated : admin uniquement.
- `listings_guard` BEFORE UPDATE → `private.guard_listing_update()` SECURITY INVOKER, search_path vide. Hors admin, refuse les changements de seller_id, status, views_count, published_at et rejection_reason. Ses RAISE EXCEPTION ne spécifient pas de SQLSTATE : P0001 par défaut.
- `listings_guard_owner_update` BEFORE UPDATE → `public.guard_listing_owner_update()` SECURITY DEFINER, search_path vide. Même protection des champs système ; transition seulement draft/rejected → pending hors admin. Le premier guard empêche toutefois aussi ces transitions. Aucun des deux ne permet published → archived.
- `listings_updated_at` BEFORE UPDATE → `private.set_updated_at()` : updated_at = now().
- `kibo_stamp_listing_publication` BEFORE INSERT : published_at = statement_timestamp() pour published.
- `kibo_search_vector` est une colonne générée stockée : titre français pondéré A, description française pondérée B. La recherche propriétaire peut réutiliser ce vecteur existant.
- Contraintes : titre trim 5–120, description trim 10–10 000, prix >= 0, devise XAF, attributs objet, vues >= 0, PK ID et FK vendeur/catégorie ON DELETE RESTRICT.

Les filtres par statuts historiques et la recherche utilisent ce contrat de lecture. Filtrer Vendue renverra une erreur tant que sold n'est pas ajouté au serveur ; aucun repli silencieux en liste vide. Vente/archivage ne doivent pas être déclarés fonctionnels à distance.

## Droits à corriger séparément

`has_table_privilege('anon', 'public.listings', 'TRUNCATE')` et le même contrôle pour authenticated retournent **true**. Les grants relevés incluent aussi REFERENCES et TRIGGER. Aucun TRUNCATE n'a été tenté ; ce constat n'affirme pas qu'un endpoint REST de troncature existe. [TRUNCATE n'est pas une opération protégée par la RLS](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) : ces privilèges doivent être retirés des rôles clients dans une intervention explicitement autorisée, après vérification de leur provenance et des autres tables exposées. Aucune révocation effectuée pendant l'audit.

## Delta à préparer

Ne pas appliquer directement `owner_listing_guard_candidate.sql`. L'activation doit ajouter sold puis adapter **les deux** guards en conservant les autres protections, les voies administratives et l'horodatage. Définir explicitement le sort de draft/rejected → pending, actuellement incohérent entre guards ; ne pas élargir automatiquement ces transitions pour le nouveau client. Préserver politiques RLS, INSERT, photos, favoris et vecteur.

Tester un delta local avec les deux guards réels reproduits : accès A/B/visiteur, champs protégés, transitions refusées, dates, photos/favoris, concurrence optimiste et admin. Les fixtures historiques ne reproduisent qu'un guard réduit et ne certifient pas ce futur delta.

Documentation API vérifiée : [UPDATE et retour de ligne](https://supabase.com/docs/reference/dart/update), [recherche textuelle Dart](https://supabase.com/docs/reference/dart/using-filters-textsearch). Le changelog Markdown a été demandé mais le lecteur web a refusé son type de contenu ; aucune conclusion sur son contenu n'est revendiquée.
