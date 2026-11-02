-- FIXTURE LOCALE MIGREE UNIQUEMENT. Jamais sur Supabase distant.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
INSERT INTO public.listings (id,seller_id,category_id,title,description,price,status,published_at)
VALUES ('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Annonce du compte A','Description fictive pour isolation',1000,'published','2099-01-01');
UPDATE public.listings SET title = 'Titre modifie par A'
WHERE id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
DO $$
DECLARE assignment text;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.listings WHERE id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd'
    AND title = 'Titre modifie par A') THEN RAISE EXCEPTION 'Own update failed'; END IF;
  FOREACH assignment IN ARRAY ARRAY[
    'seller_id = ''22222222-2222-4222-8222-222222222222''',
    'status = ''archived''', 'views_count = 42',
    'published_at = ''2099-01-01''', 'rejection_reason = ''fake'''
  ] LOOP
    BEGIN
      EXECUTE 'UPDATE public.listings SET ' || assignment ||
        ' WHERE id = ''dddddddd-dddd-4ddd-8ddd-dddddddddddd''';
      RAISE EXCEPTION 'Protected update accepted: %', assignment;
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
  END LOOP;
END $$;
INSERT INTO public.favorites VALUES (auth.uid(),'dddddddd-dddd-4ddd-8ddd-dddddddddddd');

SET LOCAL request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
DO $$
DECLARE affected integer;
BEGIN
  -- Un UPDATE sans ligne accessible doit affecter zero ligne, sans exiger une erreur.
  UPDATE public.listings SET title = 'Titre usurpe par B'
    WHERE id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'B modified A listing'; END IF;
  UPDATE public.listings SET status = 'published'
    WHERE id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'B published A pending'; END IF;
  BEGIN
    INSERT INTO public.listings (seller_id,category_id,title,description,price,status)
    VALUES ('11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'Publication usurpee','Description fictive du compte B',1000,'published');
    RAISE EXCEPTION 'B inserted as A';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    INSERT INTO public.favorites VALUES ('11111111-1111-4111-8111-111111111111',
      'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
    RAISE EXCEPTION 'B inserted favorite as A';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    INSERT INTO public.favorites VALUES (auth.uid(),'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb');
    RAISE EXCEPTION 'B favorited pending';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  IF EXISTS (SELECT 1 FROM public.favorites) THEN RAISE EXCEPTION 'B sees A favorites'; END IF;
  DELETE FROM public.favorites WHERE user_id = '11111111-1111-4111-8111-111111111111';
  GET DIAGNOSTICS affected = ROW_COUNT;
  IF affected <> 0 THEN RAISE EXCEPTION 'B deleted A favorites'; END IF;
END $$;
INSERT INTO public.favorites VALUES (auth.uid(),'dddddddd-dddd-4ddd-8ddd-dddddddddddd');
DELETE FROM public.favorites WHERE user_id = auth.uid()
  AND listing_id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public.favorites) THEN RAISE EXCEPTION 'Own favorite delete failed'; END IF;
END $$;

SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
DO $$ BEGIN
  IF (SELECT title FROM public.listings WHERE id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd')
    <> 'Titre modifie par A' THEN RAISE EXCEPTION 'A title changed'; END IF;
  IF (SELECT count(*) FROM public.favorites) <> 1 THEN RAISE EXCEPTION 'A favorite lost'; END IF;
END $$;
DELETE FROM public.favorites WHERE user_id = auth.uid()
  AND listing_id = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM public.favorites) THEN RAISE EXCEPTION 'A favorite delete failed'; END IF;
END $$;
ROLLBACK;
SELECT 'Ownership, protected fields and favorites assertions passed' AS result;
