BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT set_config('request.jwt.claims','{}',true);
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','11111111-1111-4111-8111-111111111111');
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Message acheteur');
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ DECLARE value jsonb;BEGIN
 SELECT * INTO value FROM public.kibo_chat_summaries(0);
 IF value->>'peer_name'<>'Membre fictif' OR (value->>'unread_count')::integer<>1 THEN RAISE EXCEPTION 'Resume/non lus invalides';END IF;
 PERFORM public.kibo_chat_mark_read('dddddddd-dddd-4ddd-8ddd-dddddddddddd',now());
 IF EXISTS(SELECT 1 FROM public.messages WHERE read_at IS NULL) THEN RAISE EXCEPTION 'Lecture non appliquee';END IF;
END $$;
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Reponse vendeur');
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT public.kibo_chat_set_block('dddddddd-dddd-4ddd-8ddd-dddddddddddd',true);
DO $$ BEGIN
 BEGIN INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Message bloque');RAISE EXCEPTION 'Expected block refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 IF NOT EXISTS(SELECT 1 FROM public.kibo_chat_summaries(0) x WHERE (x->>'blocked')::boolean AND (x->>'blocked_by_me')::boolean) THEN RAISE EXCEPTION 'Etat blocage manquant';END IF;
 IF (SELECT count(*) FROM public.messages)<>2 THEN RAISE EXCEPTION 'Historique perdu';END IF;
END $$;
SELECT public.kibo_account_request(false);
SELECT public.kibo_account_request(false);
DO $$ BEGIN IF (SELECT count(*) FROM public.kibo_account_requests)<>1 THEN RAISE EXCEPTION 'Demande non idempotente';END IF;END $$;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_account_requests) OR EXISTS(SELECT 1 FROM public.kibo_user_blocks) THEN RAISE EXCEPTION 'Donnees privees divulguees';END IF;
 BEGIN INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Message bloque inverse');RAISE EXCEPTION 'Expected inverse block refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_chat_summaries(0)) THEN RAISE EXCEPTION 'Resume tiers';END IF;
 BEGIN PERFORM public.kibo_chat_mark_read('dddddddd-dddd-4ddd-8ddd-dddddddddddd',now());RAISE EXCEPTION 'Expected third party refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 BEGIN PERFORM public.kibo_chat_set_block('dddddddd-dddd-4ddd-8ddd-dddddddddddd',false);RAISE EXCEPTION 'Expected third party block refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT public.kibo_chat_set_block('dddddddd-dddd-4ddd-8ddd-dddddddddddd',false);
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Deblocage confirme');
SELECT public.kibo_account_request(true);
DO $$ BEGIN IF EXISTS(SELECT 1 FROM public.kibo_account_requests) THEN RAISE EXCEPTION 'Annulation manquante';END IF;END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN BEGIN PERFORM public.kibo_chat_summaries(0);RAISE EXCEPTION 'Expected visitor refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;END $$;
RESET ROLE;
DO $$ BEGIN IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname IN('kibo_chat_summaries','kibo_chat_mark_read','kibo_chat_set_block','kibo_account_request') AND p.prosecdef) THEN RAISE EXCEPTION 'Definer public';END IF;END $$;
ROLLBACK;
