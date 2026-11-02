BEGIN;
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status)
VALUES('f0000000-0000-4000-8000-000000000001','11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'Telephone fixture','DONNÉE FICTIVE — lot kibo-demo-20261102-v1, annonce fictive.',1000,'published');
SET LOCAL ROLE anon;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.listings WHERE id='f0000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'Visitor sees fixture';END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_search_listings('Telephone fixture') r WHERE r->>'id'='f0000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'Search bypasses fixture scope';END IF;
END $$;
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM public.listings WHERE id='f0000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'Owner lost fixture';END IF;END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $$ BEGIN IF EXISTS(SELECT 1 FROM public.listings WHERE id='f0000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'Other buyer sees fixture';END IF;END $$;
RESET ROLE;
DO $$ BEGIN IF NOT EXISTS(SELECT 1 FROM public.listings WHERE id='f0000000-0000-4000-8000-000000000001') THEN RAISE EXCEPTION 'Fixture erased';END IF;END $$;
ROLLBACK;
