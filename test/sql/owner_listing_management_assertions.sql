-- Contrat CANDIDAT sur fixture locale seulement. Ne prouve pas le schéma distant.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status)
VALUES ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',auth.uid(),
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Annonce vendeur A','Description fictive de vendeur',1000,'published');
UPDATE public.listings SET title='Annonce modifiee A', price=2000
WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
DO $$ DECLARE assignment text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.listings WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'
    AND title='Annonce modifiee A' AND price=2000 AND published_at IS NOT NULL) THEN
    RAISE EXCEPTION 'Own edit failed'; END IF;
  FOREACH assignment IN ARRAY ARRAY[
    'seller_id=''22222222-2222-4222-8222-222222222222''', 'views_count=99',
    'published_at=''2099-01-01''', 'rejection_reason=''fake''',
    'currency=''EUR''', 'attributes=''{}''::jsonb || ''{"unsafe":true}''::jsonb',
    'created_at=''2099-01-01''', 'expires_at=''2099-01-01''',
    'status=''pending''', 'status=''sold'',title=''Contenu en meme temps'''
  ] LOOP
    BEGIN
      EXECUTE 'UPDATE public.listings SET '||assignment||
        ' WHERE id=''eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee''';
      RAISE EXCEPTION 'Protected update accepted: %',assignment;
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  END LOOP;
END $$;

SET LOCAL request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
INSERT INTO public.favorites VALUES (auth.uid(),'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee');
DO $$ DECLARE affected integer;
BEGIN
  UPDATE public.listings SET status='sold' WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  GET DIAGNOSTICS affected=ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'B changed A status'; END IF;
  UPDATE public.listings SET title='B usurpe le contenu' WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
  GET DIAGNOSTICS affected=ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'B edited A'; END IF;
END $$;

SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
UPDATE public.listings SET status='sold' WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
DO $$ BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.listings WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee' AND status='sold') THEN RAISE EXCEPTION 'Own sale failed'; END IF;
  BEGIN
    UPDATE public.listings SET status='published' WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
    RAISE EXCEPTION 'Sold republished';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;

SET LOCAL ROLE anon;
SET LOCAL request.jwt.claim.sub = '';
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.listings WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee') THEN RAISE EXCEPTION 'Sold public'; END IF;
END $$;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM public.listings WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee') THEN RAISE EXCEPTION 'Favorite leaks sold'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.favorites WHERE listing_id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee') THEN RAISE EXCEPTION 'Favorite lost'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
UPDATE public.listings SET status='archived' WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
DO $$ BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.listings WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee' AND status='archived') THEN RAISE EXCEPTION 'Own archive failed'; END IF;
  BEGIN
    UPDATE public.listings SET title='Archive modifiee' WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
    RAISE EXCEPTION 'Archive edited';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    UPDATE public.listings SET status='published' WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
    RAISE EXCEPTION 'Archive republished';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
ROLLBACK;
