-- PROPOSITION LOCALE : aucune autorisation d'application distante.
-- Baseline auditee le 2026-11-01 ; arret sur changement. Pas de db push global.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='20s';
LOCK TABLE public.listings IN SHARE ROW EXCLUSIVE MODE;
DO $check$
DECLARE r record;
BEGIN
  FOR r IN SELECT * FROM (VALUES
    ('private.guard_listing_update()', '377f587c638fc660c0958628c695b06a'),
    ('private.is_admin()', '87538ba0633583b774bba59ad602d3bc'),
    ('private.set_updated_at()', '608ef48381668ad5cc300914a52c93f5'),
    ('public.guard_listing_owner_update()', 'd196de0a983dd575381dcca46bef46ca')
  ) AS expected(signature,hash) LOOP
    IF (SELECT md5(prosrc) FROM pg_proc WHERE oid=to_regprocedure(r.signature)) IS DISTINCT FROM r.hash THEN
      RAISE EXCEPTION 'Function baseline changed: %', r.signature;
    END IF;
  END LOOP;
  IF (SELECT count(*) FROM pg_proc p JOIN pg_language l ON l.oid=p.prolang
    WHERE p.oid IN ('private.guard_listing_update()'::regprocedure,'private.is_admin()'::regprocedure,
      'private.set_updated_at()'::regprocedure,'public.guard_listing_owner_update()'::regprocedure)
    AND p.prosecdef=(p.proname IN ('is_admin','guard_listing_owner_update'))
    AND p.proconfig=ARRAY['search_path=""']
    AND l.lanname=CASE WHEN p.proname='is_admin' THEN 'sql' ELSE 'plpgsql' END
    AND p.provolatile=CASE WHEN p.proname='is_admin' THEN 's'::"char" ELSE 'v'::"char" END)<>4
    THEN RAISE EXCEPTION 'Function attributes changed'; END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.listings'::regclass) THEN
    RAISE EXCEPTION 'RLS required';
  END IF;
  IF (SELECT atttypid FROM pg_attribute WHERE attrelid='public.listings'::regclass AND attname='status')
      <> 'public.listing_status'::regtype THEN RAISE EXCEPTION 'Unexpected status type'; END IF;
  IF EXISTS (SELECT 1 FROM pg_trigger WHERE NOT tgisinternal AND
      tgfoid IN ('private.guard_listing_update()'::regprocedure,'public.guard_listing_owner_update()'::regprocedure)
      AND tgrelid <> 'public.listings'::regclass) THEN RAISE EXCEPTION 'Guard used elsewhere'; END IF;
  IF (SELECT count(*) FROM pg_trigger WHERE tgrelid='public.listings'::regclass AND NOT tgisinternal) <> 4
     OR (SELECT count(*) FROM pg_trigger WHERE tgrelid='public.listings'::regclass AND NOT tgisinternal
       AND tgenabled='O' AND tgqual IS NULL AND (
        (tgname='listings_guard' AND tgtype=19 AND tgfoid='private.guard_listing_update()'::regprocedure) OR
        (tgname='listings_guard_owner_update' AND tgtype=19 AND tgfoid='public.guard_listing_owner_update()'::regprocedure) OR
        (tgname='listings_updated_at' AND tgtype=19 AND tgfoid='private.set_updated_at()'::regprocedure) OR
        (tgname='kibo_stamp_listing_publication' AND tgtype=7))) <> 4
    THEN RAISE EXCEPTION 'Unexpected triggers'; END IF;
  IF (SELECT array_agg(enumlabel::text ORDER BY enumsortorder) FROM pg_enum WHERE enumtypid='public.listing_status'::regtype)
    NOT IN (ARRAY['draft','pending','published','rejected','archived'],
            ARRAY['draft','pending','published','rejected','archived','sold'])
    THEN RAISE EXCEPTION 'Unexpected status values'; END IF;
END $check$;
DO $check$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumtypid='public.listing_status'::regtype AND enumlabel='sold')
    THEN RAISE EXCEPTION 'Commit stage 01 first'; END IF;
END $check$;
CREATE OR REPLACE FUNCTION private.guard_listing_update()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $guard$
BEGIN
  IF private.is_admin() THEN RETURN NEW; END IF;
  IF auth.uid() IS NULL OR OLD.seller_id IS DISTINCT FROM auth.uid()
     OR NEW.seller_id IS DISTINCT FROM OLD.seller_id THEN
    RAISE EXCEPTION 'Listing owner required' USING ERRCODE='42501';
  END IF;
  IF (to_jsonb(NEW) - ARRAY['title','description','price','category_id','city',
       'neighborhood','listing_type','status','updated_at','kibo_search_vector'])
     IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['title','description','price','category_id','city',
       'neighborhood','listing_type','status','updated_at','kibo_search_vector']) THEN
    RAISE EXCEPTION 'Protected listing fields' USING ERRCODE='42501';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT ((OLD.status::text='published' AND NEW.status::text IN ('sold','archived'))
        OR (OLD.status::text='sold' AND NEW.status::text='archived')) THEN
      RAISE EXCEPTION 'Listing transition refused' USING ERRCODE='42501';
    END IF;
    IF (to_jsonb(NEW) - ARRAY['status','updated_at','kibo_search_vector'])
       IS DISTINCT FROM
       (to_jsonb(OLD) - ARRAY['status','updated_at','kibo_search_vector']) THEN
      RAISE EXCEPTION 'Separate content and status' USING ERRCODE='42501';
    END IF;
  ELSIF OLD.status::text NOT IN ('draft','published') THEN
    RAISE EXCEPTION 'Listing content is read only' USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$guard$;
CREATE OR REPLACE FUNCTION public.guard_listing_owner_update()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $guard$
BEGIN
  IF private.is_admin() THEN RETURN NEW; END IF;
  IF auth.uid() IS NULL OR OLD.seller_id IS DISTINCT FROM auth.uid()
     OR NEW.seller_id IS DISTINCT FROM OLD.seller_id THEN
    RAISE EXCEPTION 'Listing owner required' USING ERRCODE='42501';
  END IF;
  IF (to_jsonb(NEW) - ARRAY['title','description','price','category_id','city',
       'neighborhood','listing_type','status','updated_at','kibo_search_vector'])
     IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['title','description','price','category_id','city',
       'neighborhood','listing_type','status','updated_at','kibo_search_vector']) THEN
    RAISE EXCEPTION 'Protected listing fields' USING ERRCODE='42501';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT ((OLD.status::text='published' AND NEW.status::text IN ('sold','archived'))
        OR (OLD.status::text='sold' AND NEW.status::text='archived')) THEN
      RAISE EXCEPTION 'Listing transition refused' USING ERRCODE='42501';
    END IF;
    IF (to_jsonb(NEW) - ARRAY['status','updated_at','kibo_search_vector'])
       IS DISTINCT FROM
       (to_jsonb(OLD) - ARRAY['status','updated_at','kibo_search_vector']) THEN
      RAISE EXCEPTION 'Separate content and status' USING ERRCODE='42501';
    END IF;
  ELSIF OLD.status::text NOT IN ('draft','published') THEN
    RAISE EXCEPTION 'Listing content is read only' USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$guard$;
-- CREATE OR REPLACE preserve proprietaires et ACL ; aucun EXECUTE ajoute.
COMMIT;
