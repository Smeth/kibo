-- Prix absent = NULL, distinct du prix explicite 0 XAF.
-- Aucun UPDATE/DELETE, aucune modification de RLS/grant/trigger/index.
BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '15s';
DO $check$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname='public' AND c.relname='listings' AND c.relrowsecurity) THEN
    RAISE EXCEPTION 'Listings avec RLS requise';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
      WHERE table_schema='public' AND table_name='listings' AND column_name='price'
      AND data_type='numeric' AND numeric_precision=14 AND numeric_scale=2) THEN
    RAISE EXCEPTION 'Contrat price numeric(14,2) attendu';
  END IF;
END $check$;
ALTER TABLE public.listings ALTER COLUMN price DROP NOT NULL;
COMMIT;
