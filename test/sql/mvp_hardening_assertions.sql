BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT set_config('request.jwt.claims','{}',true);
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','11111111-1111-4111-8111-111111111111');
DO $$ DECLARE i integer;BEGIN
 IF (public.kibo_chat_thread_state('dddddddd-dddd-4ddd-8ddd-dddddddddddd')->>'blocked')::boolean THEN RAISE EXCEPTION 'Faux blocage';END IF;
 BEGIN INSERT INTO public.messages(conversation_id,sender_id,content,read_at) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Faux lu',now());RAISE EXCEPTION 'Expected column refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 FOR i IN 1..30 LOOP INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Message fictif '||i);END LOOP;
 BEGIN INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Limite');RAISE EXCEPTION 'Expected rate refusal';EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Trop de messages, patientez' THEN RAISE;END IF;END;
END $$;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN BEGIN PERFORM public.kibo_chat_thread_state('dddddddd-dddd-4ddd-8ddd-dddddddddddd');RAISE EXCEPTION 'Expected third party refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;END $$;
RESET ROLE;
DO $$ BEGIN
 IF has_any_column_privilege('authenticated','public.messages','UPDATE') OR has_column_privilege('authenticated','public.messages','read_at','INSERT') THEN RAISE EXCEPTION 'Privilège client excessif';END IF;
END $$;
ROLLBACK;
