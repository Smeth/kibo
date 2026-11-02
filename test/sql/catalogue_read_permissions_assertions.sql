-- Fixture PostgreSQL locale uniquement ; jamais sur Supabase distant.
BEGIN;
REVOKE EXECUTE ON FUNCTION private.is_admin() FROM PUBLIC, anon, authenticated;
SET LOCAL ROLE anon;
DO $$
BEGIN
  BEGIN
    PERFORM id FROM public.listings LIMIT 0;
    RAISE EXCEPTION 'Le refus EXECUTE attendu ne se produit pas';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END $$;
RESET ROLE;
GRANT EXECUTE ON FUNCTION private.is_admin() TO anon, authenticated;
SET LOCAL ROLE anon;
SELECT id FROM public.listings WHERE status = 'published' LIMIT 0;
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT id FROM public.listings WHERE status = 'published' LIMIT 0;
RESET ROLE;
ROLLBACK;
