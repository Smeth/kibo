-- Fixture locale exclusivement ; aucun contenu reel.
BEGIN;
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status) VALUES
 ('10000000-0000-4000-8000-000000000001','11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'Téléphone Samsung Galaxy','Smartphone de test en excellent état',1200,'published'),
 ('10000000-0000-4000-8000-000000000002','11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'Coque de protection','Accessoire compatible avec un téléphone Samsung',200,'published'),
 ('10000000-0000-4000-8000-000000000003','22222222-2222-4222-8222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'Ordinateur Dell','Machine pour la bureautique',5000,'published'),
 ('10000000-0000-4000-8000-000000000004','22222222-2222-4222-8222-222222222222','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'Secretprivé Samsung','Brouillon jamais visible publiquement',8000,'draft');
SET LOCAL ROLE anon;
DO $t$
DECLARE n integer; r jsonb;
BEGIN
 SELECT count(*) INTO n FROM public.kibo_search_listings('tél');
 IF n<>2 THEN RAISE EXCEPTION 'Prefixe accents: %',n;END IF;
 SELECT count(*) INTO n FROM public.kibo_search_listings('tele');
 IF n<>2 THEN RAISE EXCEPTION 'Prefixe sans accents: %',n;END IF;
 SELECT count(*) INTO n FROM public.kibo_search_listings('samung');
 IF n<>2 THEN RAISE EXCEPTION 'Faute Samsung: %',n;END IF;
 SELECT count(*) INTO n FROM public.kibo_search_listings('pc');
 IF n<>1 THEN RAISE EXCEPTION 'Synonyme pc ordinateur: %',n;END IF;
 SELECT * INTO r FROM public.kibo_search_listings('telephone samsung') LIMIT 1;
 IF r->>'title'<>'Téléphone Samsung Galaxy' THEN RAISE EXCEPTION 'Pertinence titre avant description';END IF;
 SELECT count(*) INTO n FROM public.kibo_search_listings('secretprive');
 IF n<>0 THEN RAISE EXCEPTION 'Brouillon expose';END IF;
 SELECT count(*) INTO n FROM public.kibo_search_suggestions('samung');
 IF n=0 THEN RAISE EXCEPTION 'Suggestions absentes';END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_search_suggestions('secret') s WHERE s->>'text' ILIKE '%secret%') THEN
  RAISE EXCEPTION 'Suggestion privee exposee';END IF;
 SELECT count(*) INTO n FROM public.kibo_search_listings('telephone',p_min=>1000);
 IF n<>1 THEN RAISE EXCEPTION 'Filtre prix ignore';END IF;
END $t$;
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $t$
BEGIN
 UPDATE public.listings SET title='Téléphone Samsung modifié'
 WHERE id='10000000-0000-4000-8000-000000000001';
 IF NOT FOUND THEN RAISE EXCEPTION 'Modification proprietaire bloquee par colonnes generees';END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_search_owned('secret') ) THEN
  RAISE EXCEPTION 'Brouillon autre vendeur expose';END IF;
END $t$;
RESET ROLE;
ROLLBACK;
