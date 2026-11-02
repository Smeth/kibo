-- Fixture locale uniquement. Toutes les mutations de recette sont annulées.
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status)
VALUES('cccccccc-cccc-4ccc-8ccc-cccccccccccc','11111111-1111-4111-8111-111111111111',
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Sans prix fictif','Description fictive sans prix',NULL,'published');
DO $test$
BEGIN
 IF NOT EXISTS (SELECT 1 FROM public.listings WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc'
   AND price IS NULL AND published_at IS NOT NULL) THEN
  RAISE EXCEPTION 'Publication sans prix non confirmee'; END IF;
 UPDATE public.listings SET price=0 WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 IF NOT EXISTS (SELECT 1 FROM public.listings WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc' AND price=0) THEN
  RAISE EXCEPTION 'Zero confondu avec prix absent'; END IF;
 UPDATE public.listings SET price=NULL WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 BEGIN
  UPDATE public.listings SET price=-1 WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
  RAISE EXCEPTION 'Prix negatif accepte';
 EXCEPTION WHEN check_violation THEN NULL;
 END;
 IF NOT EXISTS (SELECT 1 FROM public.listings WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc' AND price IS NULL) THEN
  RAISE EXCEPTION 'Suppression du prix non confirmee'; END IF;
END $test$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $test$
DECLARE affected integer;
BEGIN
 UPDATE public.listings SET price=42 WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 GET DIAGNOSTICS affected=ROW_COUNT;
 IF affected<>0 THEN RAISE EXCEPTION 'RLS vendeur contournee'; END IF;
END $test$;
RESET ROLE;
DO $test$
BEGIN
 IF (SELECT price FROM public.listings WHERE id='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb')<>1000 THEN
  RAISE EXCEPTION 'Prix existant modifie'; END IF;
 IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.listings'::regclass) THEN
  RAISE EXCEPTION 'RLS perdue'; END IF;
END $test$;
ROLLBACK;
