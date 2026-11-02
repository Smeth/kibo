-- AUDIT UNIQUEMENT : aucune donnee metier, aucun DDL/DML.
-- A executer via un acces SQL deja autorise au projet concerne.
-- Une sortie vide ou partielle ne prouve pas l'absence de privileges/politiques.
BEGIN READ ONLY;
SET LOCAL statement_timeout = '15s';
SELECT current_database(), current_user, version(),
       current_setting('transaction_read_only') AS read_only;

SELECT n.nspname, c.relname, c.relrowsecurity, c.relforcerowsecurity,
       pg_get_userbyid(c.relowner) AS owner, c.relacl
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname IN ('listings', 'favorites', 'categories', 'profiles');

SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public' AND tablename IN ('listings', 'favorites', 'categories', 'profiles')
ORDER BY tablename, policyname;

-- ACL brutes et droits effectifs : inclut les droits herites/PUBLIC.
SELECT n.nspname, n.nspacl, r.rolname,
       has_schema_privilege(r.oid, n.oid, 'USAGE') AS can_use
FROM pg_namespace n CROSS JOIN pg_roles r
WHERE n.nspname IN ('public', 'private', 'auth')
  AND r.rolname IN ('anon', 'authenticated');

SELECT c.relname, r.rolname, p.privilege,
       has_table_privilege(r.oid, c.oid, p.privilege) AS allowed
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
CROSS JOIN pg_roles r
CROSS JOIN (VALUES ('SELECT'), ('INSERT'), ('UPDATE'), ('DELETE')) p(privilege)
WHERE n.nspname = 'public' AND c.relname IN ('listings', 'favorites', 'categories', 'profiles')
  AND r.rolname IN ('anon', 'authenticated')
ORDER BY c.relname, r.rolname, p.privilege;

SELECT c.relname, a.attname, a.attacl, r.rolname,
       has_column_privilege(r.oid, c.oid, a.attnum, 'SELECT') AS can_select,
       has_column_privilege(r.oid, c.oid, a.attnum, 'INSERT') AS can_insert,
       has_column_privilege(r.oid, c.oid, a.attnum, 'UPDATE') AS can_update,
       pg_get_expr(d.adbin, d.adrelid) AS default_expression
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_attribute a ON a.attrelid = c.oid AND a.attnum > 0 AND NOT a.attisdropped
LEFT JOIN pg_attrdef d ON d.adrelid = c.oid AND d.adnum = a.attnum
CROSS JOIN pg_roles r
WHERE n.nspname = 'public' AND c.relname IN ('listings', 'favorites')
  AND r.rolname IN ('anon', 'authenticated')
ORDER BY c.relname, a.attnum, r.rolname;

SELECT c.relname, t.tgname, t.tgenabled, pg_get_triggerdef(t.oid, true) AS definition,
       t.tgfoid::regprocedure AS function_name
FROM pg_trigger t JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname IN ('listings', 'favorites') AND NOT t.tgisinternal
ORDER BY c.relname, t.tgname;

-- Corps des triggers et fonctions directement referencees par les politiques.
WITH function_ids AS (
  SELECT t.tgfoid AS oid FROM pg_trigger t
  WHERE t.tgrelid IN ('public.listings'::regclass, 'public.favorites'::regclass)
    AND NOT t.tgisinternal
  UNION
  SELECT d.refobjid FROM pg_depend d JOIN pg_policy p ON p.oid = d.objid
  WHERE d.classid = 'pg_policy'::regclass AND d.refclassid = 'pg_proc'::regclass
    AND p.polrelid IN ('public.listings'::regclass, 'public.favorites'::regclass)
)
SELECT p.oid::regprocedure AS name, p.prosecdef, p.proconfig, p.proacl,
       pg_get_functiondef(p.oid) AS definition
FROM pg_proc p JOIN function_ids f ON f.oid = p.oid ORDER BY p.oid;

SELECT conrelid::regclass AS relation, conname, pg_get_constraintdef(oid, true)
FROM pg_constraint
WHERE conrelid IN ('public.listings'::regclass, 'public.favorites'::regclass)
ORDER BY conrelid, conname;
ROLLBACK;
