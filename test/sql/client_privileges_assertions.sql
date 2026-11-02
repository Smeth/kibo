-- Aucun TRUNCATE n'est tente, meme en fixture : verification des droits effectifs.
CREATE TABLE public.fixture_future_postgres(id integer);
ALTER TABLE public.fixture_future_postgres ENABLE ROW LEVEL SECURITY;
SET ROLE supabase_admin;
CREATE TABLE public.fixture_future_supabase(id integer);
ALTER TABLE public.fixture_future_supabase ENABLE ROW LEVEL SECURITY;
RESET ROLE;
DO $check$ DECLARE t text; r text; p text; BEGIN
 FOREACH t IN ARRAY ARRAY['categories','notifications','listing_images','favorites','conversations','messages','listing_comments','reports','listings','fixture_future_postgres','fixture_future_supabase'] LOOP
  FOREACH r IN ARRAY ARRAY['anon','authenticated'] LOOP
   FOREACH p IN ARRAY ARRAY['TRUNCATE','REFERENCES','TRIGGER'] LOOP
    IF has_table_privilege(r,format('public.%I',t),p) THEN RAISE EXCEPTION 'Unsafe privilege persists'; END IF;
   END LOOP;
  END LOOP;
  IF NOT has_table_privilege('service_role',format('public.%I',t),'TRUNCATE') THEN RAISE EXCEPTION 'Service role damaged'; END IF;
 END LOOP;
 IF EXISTS(SELECT * FROM private.fixture_privilege_preserve EXCEPT
  SELECT c.oid,a.* FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) a)
 THEN RAISE EXCEPTION 'Unrelated ACL changed'; END IF;
END $check$;
