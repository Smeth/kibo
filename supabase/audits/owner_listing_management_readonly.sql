BEGIN READ ONLY;
SELECT 'status_values' AS item, string_agg(e.enumlabel, ',' ORDER BY e.enumsortorder) AS value
FROM pg_attribute a JOIN pg_enum e ON e.enumtypid=a.atttypid
WHERE a.attrelid='public.listings'::regclass AND a.attname='status'
UNION ALL
SELECT 'trigger:'||t.tgname, pg_get_triggerdef(t.oid,true)||E'\n'||pg_get_functiondef(t.tgfoid)
FROM pg_trigger t WHERE t.tgrelid='public.listings'::regclass AND NOT t.tgisinternal
UNION ALL
SELECT 'policy:'||policyname, jsonb_build_object('roles',roles,'cmd',cmd,'qual',qual,'check',with_check)::text
FROM pg_policies WHERE schemaname='public' AND tablename='listings'
UNION ALL
SELECT 'constraint:'||conname, pg_get_constraintdef(oid,true)
FROM pg_constraint WHERE conrelid='public.listings'::regclass
UNION ALL
SELECT 'grant:'||grantee, privilege_type
FROM information_schema.role_table_grants
WHERE table_schema='public' AND table_name='listings'
UNION ALL
SELECT 'privileges:'||r, jsonb_build_object(
  'select',has_table_privilege(r,'public.listings','SELECT'),
  'update',has_table_privilege(r,'public.listings','UPDATE'),
  'truncate',has_table_privilege(r,'public.listings','TRUNCATE'))::text
FROM (VALUES ('anon'),('authenticated')) AS roles(r)
UNION ALL
SELECT 'rls', jsonb_build_object('enabled',relrowsecurity,
  'forced',relforcerowsecurity,'owner',pg_get_userbyid(relowner))::text
FROM pg_class WHERE oid='public.listings'::regclass
UNION ALL
SELECT 'column:'||a.attname, jsonb_build_object('generated',a.attgenerated,
  'expression',pg_get_expr(d.adbin,d.adrelid))::text
FROM pg_attribute a LEFT JOIN pg_attrdef d
  ON d.adrelid=a.attrelid AND d.adnum=a.attnum
WHERE a.attrelid='public.listings'::regclass
  AND a.attname IN ('status','updated_at','kibo_search_vector')
ORDER BY item;
ROLLBACK;
