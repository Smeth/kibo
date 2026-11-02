-- LOCAL UNIQUEMENT : fixture + delta publication + stub Storage + deltas photos/recherche.
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
INSERT INTO public.listings (id,seller_id,category_id,title,description,price,status)
VALUES ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',auth.uid(),
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Telephone de test','Telephone et ordinateur fictifs',1000,'published');
INSERT INTO public.kibo_listing_photos (listing_id,position,path)
SELECT 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', n,
  auth.uid()::text || '/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee/' || n::text || '-' || repeat('a',64) || '.jpg'
FROM generate_series(0,2) n;
DO $$ BEGIN
  IF (SELECT count(*) FROM public.kibo_listing_photos) <> 3 THEN RAISE EXCEPTION 'Reservation failed'; END IF;
  BEGIN
    INSERT INTO public.kibo_listing_photos (listing_id,position,path) VALUES
      ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',3,auth.uid()::text || '/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee/3-' || repeat('a',64) || '.jpg');
    RAISE EXCEPTION 'Fourth slot accepted';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    INSERT INTO public.kibo_listing_photos (listing_id,position,path) VALUES
      ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',0,auth.uid()::text || '/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee/0-' || repeat('b',64) || '.jpg');
    RAISE EXCEPTION 'Duplicate slot accepted';
  EXCEPTION WHEN unique_violation THEN NULL; END;
  BEGIN
    INSERT INTO storage.objects(bucket_id,name) VALUES ('kibo-listing-photos','direct-upload.jpg');
    RAISE EXCEPTION 'Direct client upload accepted';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  BEGIN
    UPDATE public.kibo_listing_photos SET path = 'spoof';
    RAISE EXCEPTION 'Reservation modified';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  IF (SELECT count(*) FROM public.listings WHERE kibo_search_vector @@ websearch_to_tsquery('french','ordinateur')
    AND status = 'published' AND price BETWEEN 500 AND 1500 AND city = 'Brazzaville') <> 1
  THEN RAISE EXCEPTION 'Search combination failed'; END IF;
END $$;
-- Simulation de l'ecriture du serveur valideur, pas de donnees binaires reelles.
RESET ROLE;
INSERT INTO storage.objects(bucket_id,name)
SELECT 'kibo-listing-photos',path FROM public.kibo_listing_photos;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '22222222-2222-4222-8222-222222222222';
DO $$ BEGIN
  IF (SELECT count(*) FROM storage.objects) <> 3 THEN RAISE EXCEPTION 'Published photos not visible'; END IF;
  BEGIN
    INSERT INTO public.kibo_listing_photos(listing_id,position,path) VALUES
      ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',0,auth.uid()::text || '/eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee/0-' || repeat('a',64) || '.jpg');
    RAISE EXCEPTION 'B reserved A listing';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  IF EXISTS (SELECT 1 FROM public.listings WHERE kibo_search_vector @@ websearch_to_tsquery('french','pending'))
  THEN RAISE EXCEPTION 'Search leaked pending to B'; END IF;
END $$;
RESET ROLE;
-- Moderation par l'operateur fictif : le guard de fixture protege meme postgres,
-- on teste la lecture via un nouveau parent pending reserve par A.
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
INSERT INTO public.kibo_listing_photos(listing_id,position,path)
VALUES ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',0,auth.uid()::text || '/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb/0-' || repeat('a',64) || '.jpg');
RESET ROLE;
INSERT INTO storage.objects(bucket_id,name)
SELECT 'kibo-listing-photos',path FROM public.kibo_listing_photos WHERE listing_id = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
SET LOCAL ROLE anon;
SET LOCAL request.jwt.claim.sub = '';
DO $$ BEGIN
  IF (SELECT count(*) FROM storage.objects) <> 3 THEN RAISE EXCEPTION 'Anon sees pending photo'; END IF;
END $$;
ROLLBACK;
SELECT 'Local photos, Storage RLS and search assertions passed' AS result;
