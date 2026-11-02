BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc',auth.uid(),'11111111-1111-4111-8111-111111111111');
INSERT INTO public.messages(id,conversation_id,sender_id,content) VALUES('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Original fictif');
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN
 BEGIN PERFORM public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Intrusion',false,'Original fictif',NULL);RAISE EXCEPTION 'Expected recipient refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $$ DECLARE value jsonb; stamp timestamptz; BEGIN
 IF NOT public.kibo_chat_message_actions('dddddddd-dddd-4ddd-8ddd-dddddddddddd') THEN RAISE EXCEPTION 'Capabilities missing';END IF;
 BEGIN UPDATE public.messages SET content='Contournement';RAISE EXCEPTION 'Expected direct refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 BEGIN PERFORM public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',' ',false,'Original fictif',NULL);RAISE EXCEPTION 'Expected invalid text';EXCEPTION WHEN invalid_parameter_value THEN NULL;END;
 value=public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Texte corrigé',false,'Original fictif',NULL);
 IF value->>'content'<>'Texte corrigé' OR value->>'edited_at' IS NULL OR value->>'deleted_at' IS NOT NULL THEN RAISE EXCEPTION 'Edit not confirmed';END IF;
 stamp=(value->>'edited_at')::timestamptz;
 BEGIN PERFORM public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Perdu',false,'Original fictif',NULL);RAISE EXCEPTION 'Expected stale refusal';EXCEPTION WHEN serialization_failure THEN NULL;END;
 PERFORM public.kibo_chat_set_block('dddddddd-dddd-4ddd-8ddd-dddddddddddd',true);
 BEGIN PERFORM public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',NULL,true,'Texte corrigé',stamp);RAISE EXCEPTION 'Expected blocked refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 PERFORM public.kibo_chat_set_block('dddddddd-dddd-4ddd-8ddd-dddddddddddd',false);
 value=public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',NULL,true,'Texte corrigé',stamp);
 IF value->>'content'<>'Message supprimé' OR value->>'deleted_at' IS NULL OR value->>'sender_id'<>auth.uid()::text THEN RAISE EXCEPTION 'Delete not confirmed';END IF;
 BEGIN PERFORM public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Resurrection',false,'Message supprimé',stamp);RAISE EXCEPTION 'Expected deleted refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 BEGIN PERFORM * FROM public.kibo_message_action_log;RAISE EXCEPTION 'Expected log privacy';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN
 BEGIN PERFORM public.kibo_chat_change_message('dddddddd-dddd-4ddd-8ddd-dddddddddddd','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Intrusion',false,'Message supprimé',NULL);RAISE EXCEPTION 'Expected nonauthor refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN
 BEGIN PERFORM public.kibo_chat_message_actions('dddddddd-dddd-4ddd-8ddd-dddddddddddd');RAISE EXCEPTION 'Expected outsider refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
 BEGIN PERFORM public.kibo_chat_message_actions('dddddddd-dddd-4ddd-8ddd-dddddddddddd');RAISE EXCEPTION 'Expected visitor refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
RESET ROLE;
DO $$ BEGIN
 IF (SELECT count(*) FROM public.kibo_message_action_log)<>2 THEN RAISE EXCEPTION 'Atomic journal mismatch';END IF;
 IF has_any_column_privilege('authenticated','public.messages','UPDATE') OR has_column_privilege('authenticated','public.messages','deleted_at','INSERT') THEN RAISE EXCEPTION 'Client bypass';END IF;
 PERFORM set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
 IF NOT EXISTS(SELECT 1 FROM public.kibo_chat_summaries(0) s WHERE s->>'last_content'='Message supprimé') THEN RAISE EXCEPTION 'Deleted summary missing';END IF;
END $$;
ROLLBACK;
