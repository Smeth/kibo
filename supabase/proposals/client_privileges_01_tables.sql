-- PROPOSITION LOCALE UNIQUEMENT. Autorisation distincte avant application distante.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='20s';
DO $check$ BEGIN
 IF (SELECT count(*) FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
     WHERE n.nspname='public' AND c.relname IN ('categories','notifications','listing_images','favorites','conversations','messages','listing_comments','reports','listings') AND c.relkind='r' AND c.relrowsecurity)<>9
 THEN RAISE EXCEPTION 'Target table/RLS baseline changed'; END IF;
 IF EXISTS(SELECT 1 FROM pg_auth_members WHERE member IN ('anon'::regrole,'authenticated'::regrole))
 THEN RAISE EXCEPTION 'Client role memberships require review'; END IF;
 IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
   CROSS JOIN LATERAL aclexplode(c.relacl) a WHERE n.nspname='public' AND c.relkind IN ('r','p')
   AND a.privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER')
   AND (a.grantee=0 OR a.grantee IN ('anon'::regrole,'authenticated'::regrole))
   AND (c.relname NOT IN ('categories','notifications','listing_images','favorites','conversations','messages','listing_comments','reports','listings') OR a.grantee=0 OR a.is_grantable OR pg_get_userbyid(a.grantor)<>'postgres'))
 THEN RAISE EXCEPTION 'Unreviewed privilege source'; END IF;
END $check$;
CREATE TEMP TABLE kibo_acl_keep ON COMMIT DROP AS
 SELECT c.oid AS relation,a.* FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) a
 WHERE c.oid IN ('public.categories'::regclass,'public.notifications'::regclass,'public.listing_images'::regclass,'public.favorites'::regclass,'public.conversations'::regclass,'public.messages'::regclass,'public.listing_comments'::regclass,'public.reports'::regclass,'public.listings'::regclass)
 AND NOT (a.grantee IN ('anon'::regrole,'authenticated'::regrole)
          AND a.privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER'));
REVOKE TRUNCATE, REFERENCES, TRIGGER ON public.categories, public.notifications, public.listing_images, public.favorites, public.conversations, public.messages, public.listing_comments, public.reports, public.listings FROM anon, authenticated RESTRICT;
DO $check$ DECLARE t text; r text; p text; BEGIN
 FOREACH t IN ARRAY ARRAY['categories','notifications','listing_images','favorites','conversations','messages','listing_comments','reports','listings'] LOOP
  FOREACH r IN ARRAY ARRAY['anon','authenticated'] LOOP
   FOREACH p IN ARRAY ARRAY['TRUNCATE','REFERENCES','TRIGGER'] LOOP
    IF has_table_privilege(r,format('public.%I',t),p) THEN RAISE EXCEPTION 'Privilege remains: % % %',t,r,p; END IF;
   END LOOP;
  END LOOP;
 END LOOP;
 IF EXISTS(SELECT * FROM kibo_acl_keep EXCEPT
  SELECT c.oid,a.* FROM pg_class c CROSS JOIN LATERAL aclexplode(c.relacl) a
  WHERE c.oid IN ('public.categories'::regclass,'public.notifications'::regclass,'public.listing_images'::regclass,'public.favorites'::regclass,'public.conversations'::regclass,'public.messages'::regclass,'public.listing_comments'::regclass,'public.reports'::regclass,'public.listings'::regclass))
 THEN RAISE EXCEPTION 'Unrelated grant removed'; END IF;
END $check$;
COMMIT;
