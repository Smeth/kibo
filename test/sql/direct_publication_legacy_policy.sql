-- Prouve le blocage de l'ancienne politique sur la fixture locale uniquement.
-- Le ROLLBACK laisse la migration testee intacte.
BEGIN;
ALTER POLICY listings_insert_own ON public.listings WITH CHECK (
  seller_id = auth.uid() AND status IN ('draft','pending')
  AND views_count = 0 AND published_at IS NULL AND rejection_reason IS NULL
);
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
DO $$
BEGIN
  BEGIN
    INSERT INTO public.listings (seller_id,category_id,title,description,price,status,published_at)
      VALUES (auth.uid(),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Publication refusee','Description fictive sans secret',1000,'published',statement_timestamp());
    RAISE EXCEPTION 'Legacy policy unexpectedly allowed publication';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
ROLLBACK;
SELECT 'Legacy policy rejects direct publication' AS result;
