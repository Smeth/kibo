-- Local disposable fixture exclusively. No live deletion and no Auth API.
BEGIN;
INSERT INTO public.profiles(id,full_name) VALUES('44444444-4444-4444-8444-444444444444','Ancien auteur fictif');
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc','44444444-4444-4444-8444-444444444444','11111111-1111-4111-8111-111111111111');
INSERT INTO public.messages(id,conversation_id,sender_id,content) VALUES
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','dddddddd-dddd-4ddd-8ddd-dddddddddddd','44444444-4444-4444-8444-444444444444','Ancien texte privé non conservé'),
('ffffffff-ffff-4fff-8fff-ffffffffffff','dddddddd-dddd-4ddd-8ddd-dddddddddddd','11111111-1111-4111-8111-111111111111','Contribution du survivant relue en fixture');
INSERT INTO public.kibo_retained_threads(owner_id,id,last_at,expires_at,policy_version) VALUES
('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd',now(),now()+interval '1 hour','fixture-only-not-production');
INSERT INTO public.kibo_retained_messages(owner_id,thread_id,id,from_survivor,content,created_at) VALUES
('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',false,'Message anonymisé',now()),
('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd','ffffffff-ffff-4fff-8fff-ffffffffffff',true,'Contribution du survivant relue en fixture',now());
INSERT INTO public.kibo_retained_comments(owner_id,id,context_id,from_survivor,content,created_at,expires_at,policy_version) VALUES
('11111111-1111-4111-8111-111111111111',gen_random_uuid(),gen_random_uuid(),false,'Commentaire anonymisé',now(),now()+interval '1 hour','fixture-only');
-- Explicit original cleanup, only inside this rolled-back fixture.
DELETE FROM public.conversations WHERE id='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
DELETE FROM public.profiles WHERE id='44444444-4444-4444-8444-444444444444';
DO $$ BEGIN
 IF (SELECT count(*) FROM public.kibo_retained_messages)<>2 THEN RAISE EXCEPTION 'Survivor history lost'; END IF;
 BEGIN INSERT INTO public.kibo_retained_messages(owner_id,thread_id,id,from_survivor,content,created_at) VALUES('11111111-1111-4111-8111-111111111111','dddddddd-dddd-4ddd-8ddd-dddddddddddd',gen_random_uuid(),false,'Ancien texte privé',now()); RAISE EXCEPTION 'Expected former text refusal'; EXCEPTION WHEN check_violation THEN NULL; END;
END $$;
INSERT INTO public.kibo_retained_threads(owner_id,id,created_at,expires_at,policy_version) VALUES('11111111-1111-4111-8111-111111111111','99999999-9999-4999-8999-999999999999',now()-interval '2 days',now()-interval '1 day','expired-fixture');
INSERT INTO public.kibo_retained_messages(owner_id,thread_id,id,from_survivor,content,created_at) VALUES('11111111-1111-4111-8111-111111111111','99999999-9999-4999-8999-999999999999',gen_random_uuid(),true,'Contribution expirée',now()-interval '2 days');
INSERT INTO public.kibo_retained_comments(owner_id,id,context_id,from_survivor,content,created_at,expires_at,policy_version) VALUES('11111111-1111-4111-8111-111111111111',gen_random_uuid(),gen_random_uuid(),true,'Commentaire expiré',now()-interval '2 days',now()-interval '1 day','expired-fixture');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ DECLARE summary jsonb; BEGIN
 IF (SELECT count(*) FROM public.kibo_retained_threads)<>1 THEN RAISE EXCEPTION 'Expired history exposed'; END IF;
 IF (SELECT count(*) FROM public.kibo_retained_messages)<>2 OR EXISTS(SELECT 1 FROM public.kibo_retained_messages('99999999-9999-4999-8999-999999999999')) THEN RAISE EXCEPTION 'Expired messages exposed'; END IF;
 SELECT * INTO summary FROM public.kibo_retained_threads(0);
 IF summary->>'peer_name'<>'Compte supprimé' OR summary->>'seller_id' IS NOT NULL OR summary->>'listing_id' IS NOT NULL OR summary->>'peer_deleted'<>'true' OR summary->>'blocked'<>'true' THEN RAISE EXCEPTION 'Unsafe projection'; END IF;
 IF (SELECT count(*) FROM public.kibo_retained_messages('dddddddd-dddd-4ddd-8ddd-dddddddddddd'))<>2 THEN RAISE EXCEPTION 'Messages unavailable'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.kibo_retained_messages('dddddddd-dddd-4ddd-8ddd-dddddddddddd') m WHERE m->>'sender_id' IS NULL AND m->>'sender_deleted'='true' AND m->>'content'='Message anonymisé') THEN RAISE EXCEPTION 'Deleted identity exposed'; END IF;
 IF (SELECT count(*) FROM public.kibo_retained_comments(0))<>1 THEN RAISE EXCEPTION 'Comments unavailable'; END IF;
 BEGIN UPDATE public.kibo_retained_messages SET content='forge'; RAISE EXCEPTION 'Expected raw write refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN DELETE FROM public.kibo_retained_threads; RAISE EXCEPTION 'Expected raw delete refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_retained_threads) OR EXISTS(SELECT 1 FROM public.kibo_retained_messages('dddddddd-dddd-4ddd-8ddd-dddddddddddd')) OR EXISTS(SELECT 1 FROM public.kibo_retained_comments(0)) THEN RAISE EXCEPTION 'Third party history exposed'; END IF;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN BEGIN PERFORM public.kibo_retained_threads(0); RAISE EXCEPTION 'Expected guest refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END; END $$;
RESET ROLE;
ROLLBACK;
