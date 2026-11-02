DO $check$ BEGIN
 IF NOT has_table_privilege('anon','public.listings','TRUNCATE') OR
    NOT has_table_privilege('authenticated','public.favorites','TRIGGER')
 THEN RAISE EXCEPTION 'Audited grants not restored'; END IF;
 IF EXISTS(SELECT * FROM private.fixture_privilege_preserve EXCEPT
  SELECT c.oid,a.* FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) a)
 THEN RAISE EXCEPTION 'Rollback changed unrelated grants'; END IF;
END $check$;
