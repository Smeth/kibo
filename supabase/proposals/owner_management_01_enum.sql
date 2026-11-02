-- PROPOSITION LOCALE : aucune autorisation d'application distante.
-- Baseline auditee le 2026-11-01 ; arret sur changement. Pas de db push global.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='20s';
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
ALTER TYPE public.listing_status ADD VALUE IF NOT EXISTS 'sold';
COMMIT;
