-- Lecture seule ; examiner les corps localement avant de partager les résultats.
BEGIN READ ONLY;
SELECT n.nspname AS schema_name, p.oid::regprocedure AS signature,
       pg_get_userbyid(p.proowner) AS owner_name, p.prosecdef, p.provolatile,
       p.proacl, pg_get_functiondef(p.oid) AS definition,
       has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_execute,
       has_function_privilege('authenticated', p.oid, 'EXECUTE') AS authenticated_execute
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE p.proname = 'is_admin' AND n.nspname IN ('private', 'public');
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies WHERE (schemaname = 'public' AND tablename IN
  ('listings', 'profiles', 'favorites', 'kibo_listing_photos')) OR schemaname = 'storage';
SELECT table_schema, table_name, grantee, privilege_type
FROM information_schema.role_table_grants
WHERE grantee IN ('anon', 'authenticated') AND table_name IN ('listings', 'kibo_listing_photos');
SELECT table_schema, table_name, column_name, data_type
FROM information_schema.columns WHERE table_schema = 'public' AND
  (table_name = 'kibo_listing_photos' OR (table_name = 'listings' AND column_name = 'kibo_search_vector'));
SELECT id, name, public, file_size_limit, allowed_mime_types FROM storage.buckets;
SELECT to_regclass('supabase_migrations.schema_migrations') AS migration_history;
ROLLBACK;
