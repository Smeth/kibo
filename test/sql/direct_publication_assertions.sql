-- Tests REELS PostgreSQL mais fixture locale uniquement, pas Supabase distant.
BEGIN;
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.fixture_policy_snapshot old
    LEFT JOIN pg_policy p ON p.polname = old.polname
      AND p.polrelid IN ('public.listings'::regclass,'public.favorites'::regclass)
    WHERE p.polname IS NULL OR p.polcmd <> old.polcmd
      OR pg_get_expr(p.polqual,p.polrelid) IS DISTINCT FROM old.qual
      OR pg_get_expr(p.polwithcheck,p.polrelid) IS DISTINCT FROM old.check_expr
  ) THEN RAISE EXCEPTION 'Other policies changed'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'fixture_existing_update_guard' AND tgrelid = 'public.listings'::regclass)
    THEN RAISE EXCEPTION 'Update trigger lost'; END IF;
  IF (SELECT status FROM public.listings WHERE id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb') <> 'pending'
    THEN RAISE EXCEPTION 'Existing data changed'; END IF;
END $$;

SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
INSERT INTO public.listings (id,seller_id,category_id,title,description,price,status,published_at) VALUES
  ('cccccccc-cccc-4ccc-8ccc-cccccccccccc',auth.uid(),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Publiee localement','Annonce fictive publique',1000,'published','2099-01-01T00:00:00Z');
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.listings WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
    AND status = 'published' AND published_at = statement_timestamp()) THEN
    -- statement_timestamp change entre statements : verifier la proximite serveur.
    IF NOT EXISTS (SELECT 1 FROM public.listings WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc'
      AND published_at BETWEEN transaction_timestamp() AND clock_timestamp()) THEN
      RAISE EXCEPTION 'Timestamp not supplied by server';
    END IF;
  END IF;
  BEGIN
    INSERT INTO public.listings (seller_id,category_id,title,description,price,status)
      VALUES ('22222222-2222-4222-8222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Vendeur usurpe','Description fictive assez longue',1,'published');
    RAISE EXCEPTION 'Spoofed seller accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    INSERT INTO public.listings (seller_id,category_id,title,description,price,status,views_count)
      VALUES (auth.uid(),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Vues usurpees','Description fictive assez longue',1,'published',42);
    RAISE EXCEPTION 'Views accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    INSERT INTO public.listings (seller_id,category_id,title,description,price,status,rejection_reason)
      VALUES (auth.uid(),'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Motif usurpe','Description fictive assez longue',1,'published','fake');
    RAISE EXCEPTION 'Rejection reason accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    UPDATE public.listings SET status = 'archived' WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
    RAISE EXCEPTION 'Protected status update accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
INSERT INTO public.favorites VALUES (auth.uid(),'cccccccc-cccc-4ccc-8ccc-cccccccccccc');

SET LOCAL request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
DO $$
DECLARE affected integer;
BEGIN
  IF (SELECT count(*) FROM public.listings WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc') <> 1 THEN RAISE EXCEPTION 'Public row invisible to B'; END IF;
  IF EXISTS (SELECT 1 FROM public.listings WHERE id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb') THEN RAISE EXCEPTION 'Pending visible to B'; END IF;
  IF EXISTS (SELECT 1 FROM public.favorites) THEN RAISE EXCEPTION 'A favorites visible to B'; END IF;
  DELETE FROM public.favorites WHERE user_id = '11111111-1111-4111-8111-111111111111';
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'B deleted A favorites'; END IF;
END $$;
INSERT INTO public.favorites VALUES (auth.uid(),'cccccccc-cccc-4ccc-8ccc-cccccccccccc');

SET LOCAL ROLE anon;
SET LOCAL request.jwt.claim.sub = '';
DO $$
BEGIN
  IF (SELECT count(*) FROM public.listings WHERE id = 'cccccccc-cccc-4ccc-8ccc-cccccccccccc') <> 1 THEN RAISE EXCEPTION 'Public row invisible to anon'; END IF;
  BEGIN
    INSERT INTO public.listings (seller_id,category_id,title,description,price,status)
      VALUES ('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Anon interdit','Description fictive assez longue',1,'published');
    RAISE EXCEPTION 'Anonymous insert accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
ROLLBACK;
SELECT 'All isolated PostgreSQL assertions passed' AS result;
