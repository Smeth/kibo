BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES
 ('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','11111111-1111-4111-8111-111111111111');
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES
 ('dddddddd-dddd-4ddd-8ddd-dddddddddddd','22222222-2222-4222-8222-222222222222','Message fictif');
DO $$ BEGIN
 BEGIN INSERT INTO public.conversations(listing_id,buyer_id,seller_id) VALUES('cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','11111111-1111-4111-8111-111111111111'); RAISE EXCEPTION 'Expected unique refusal'; EXCEPTION WHEN unique_violation THEN NULL; END;
 BEGIN INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','22222222-2222-4222-8222-222222222222',' '); RAISE EXCEPTION 'Expected empty refusal'; EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','11111111-1111-4111-8111-111111111111','Usurpation'); RAISE EXCEPTION 'Expected sender refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.messages) OR EXISTS(SELECT 1 FROM public.conversations) THEN RAISE EXCEPTION 'Non participant read'; END IF;
 BEGIN INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','33333333-3333-4333-8333-333333333333','Intrusion'); RAISE EXCEPTION 'Expected participant refusal'; EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'Expéditeur non autorisé' THEN RAISE; END IF; END;
END $$;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN IF (SELECT count(*) FROM public.messages)<>1 THEN RAISE EXCEPTION 'Seller read denied'; END IF; END $$;
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','11111111-1111-4111-8111-111111111111','Réponse fictive');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claim.sub','',true);
DO $$ BEGIN IF EXISTS(SELECT 1 FROM public.messages) OR EXISTS(SELECT 1 FROM public.conversations) THEN RAISE EXCEPTION 'Anonymous read'; END IF; END $$;
RESET ROLE;
DO $$ BEGIN
 IF (SELECT count(*) FROM pg_publication_tables WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename IN ('messages','conversations'))<>2 THEN RAISE EXCEPTION 'Publication missing'; END IF;
 IF EXISTS(SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname IN('messages','conversations') AND NOT c.relrowsecurity) THEN RAISE EXCEPTION 'RLS changed'; END IF;
END $$;
ROLLBACK;
