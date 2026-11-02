-- Fixtures locales exclusivement, toutes les écritures sont annulées.
BEGIN;
DO $$ DECLARE buyer uuid; thread uuid; BEGIN
 FOR i IN 1..21 LOOP
 buyer=gen_random_uuid(); thread=gen_random_uuid();
 INSERT INTO public.profiles(id,full_name) VALUES(buyer,'Compte fictif');
 INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES(thread,'cccccccc-cccc-4ccc-8ccc-cccccccccccc',buyer,'11111111-1111-4111-8111-111111111111');
 INSERT INTO public.messages(conversation_id,sender_id,content) VALUES(thread,buyer,'Message fictif');
 END LOOP;
END $$;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{}',true);
DO $$ BEGIN
 IF public.kibo_chat_unread_count()<>21 OR (SELECT count(*) FROM public.kibo_chat_summaries(0))<>20 THEN RAISE EXCEPTION 'Compteur global tronqué'; END IF;
 IF public.kibo_notification_preferences()->>'messages'<>'true' THEN RAISE EXCEPTION 'Défaut incorrect'; END IF;
 IF (SELECT count(*) FROM public.notifications)<>21 THEN RAISE EXCEPTION 'Notifications par défaut perdues'; END IF;
 PERFORM public.kibo_notification_preferences(false,false);
 BEGIN UPDATE public.kibo_notification_preferences SET messages_enabled=true; RAISE EXCEPTION 'Expected raw write refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_notification_preferences) OR public.kibo_chat_unread_count()<>0 THEN RAISE EXCEPTION 'Isolation préférences/compteur'; END IF;
 IF public.kibo_notification_preferences()->>'comments'<>'true' THEN RAISE EXCEPTION 'Défaut B incorrect'; END IF;
END $$;
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc',auth.uid(),'11111111-1111-4111-8111-111111111111');
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Message sans notification');
INSERT INTO public.listing_comments(listing_id,user_id,content) VALUES('cccccccc-cccc-4ccc-8ccc-cccccccccccc',auth.uid(),'Commentaire sans notification');
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN
 IF public.kibo_chat_unread_count()<>22 OR (SELECT count(*) FROM public.notifications)<>21 THEN RAISE EXCEPTION 'Préférences sans effet ou compteur altéré'; END IF;
END $$;
SELECT public.kibo_account_request(false);
SELECT public.kibo_account_request(false);
DO $$ BEGIN
 IF jsonb_array_length(public.kibo_account_tracking()->'events')<>1 THEN RAISE EXCEPTION 'Demande non idempotente'; END IF;
 BEGIN PERFORM public.kibo_account_queue('pending'); RAISE EXCEPTION 'Expected member refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN INSERT INTO public.kibo_account_request_events(owner_id,action) VALUES(auth.uid(),'forged'); RAISE EXCEPTION 'Expected event refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SELECT set_config('fixture.old_version',(public.kibo_account_tracking()->'request'->>'version'),true);
SELECT public.kibo_account_request(true);
SELECT public.kibo_account_request(false);
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN
 IF public.kibo_account_tracking()->'request'<>'null'::jsonb OR EXISTS(SELECT 1 FROM public.kibo_account_request_events) THEN RAISE EXCEPTION 'Suivi divulgué'; END IF;
END $$;
SELECT set_config('request.jwt.claims','{"user_metadata":{"role":"admin"}}',true);
DO $$ BEGIN BEGIN PERFORM public.kibo_account_queue('pending'); RAISE EXCEPTION 'Expected spoof refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END; END $$;
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
DO $$ DECLARE request jsonb; BEGIN
 SELECT * INTO request FROM public.kibo_account_queue('pending');
 IF request IS NULL THEN RAISE EXCEPTION 'File manquante'; END IF;
 BEGIN PERFORM public.kibo_account_review((request->>'owner_id')::uuid,current_setting('fixture.old_version')::bigint,'processing','Note ancienne'); RAISE EXCEPTION 'Expected recreated request conflict'; EXCEPTION WHEN serialization_failure THEN NULL; END;
 BEGIN PERFORM public.kibo_account_review((request->>'owner_id')::uuid,(request->>'version')::bigint,'completed','Fausse suppression'); RAISE EXCEPTION 'Expected completion refusal'; EXCEPTION WHEN raise_exception THEN IF SQLERRM='Expected completion refusal' THEN RAISE; END IF; END;
 PERFORM public.kibo_account_review((request->>'owner_id')::uuid,(request->>'version')::bigint,'needs_info','Précisions fictives requises');
 BEGIN PERFORM public.kibo_account_review((request->>'owner_id')::uuid,(request->>'version')::bigint,'processing','Version obsolète'); RAISE EXCEPTION 'Expected stale conflict'; EXCEPTION WHEN serialization_failure THEN NULL; END;
END $$;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT set_config('request.jwt.claims','{}',true);
DO $$ DECLARE state jsonb; BEGIN
 state=public.kibo_account_tracking();
 IF state->'request'->>'status'<>'needs_info' OR (SELECT count(*) FROM public.notifications WHERE notification_type='system')<>1 THEN RAISE EXCEPTION 'Suivi ou notification système perdus'; END IF;
 PERFORM public.kibo_account_reply((state->'request'->>'version')::bigint,'Voici les précisions fictives');
 IF public.kibo_account_tracking()->'request'->>'status'<>'pending' OR jsonb_array_length(public.kibo_account_tracking()->'events')<>5 THEN RAISE EXCEPTION 'Réponse/journal manquants'; END IF;
END $$;
-- Échec volontaire du journal : aucune décision/notification ne doit survivre.
RESET ROLE;
CREATE FUNCTION public.fixture_deny_account_event() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'Fixture journal indisponible'; END $$;
CREATE TRIGGER fixture_deny_account_event BEFORE INSERT ON public.kibo_account_request_events FOR EACH ROW EXECUTE FUNCTION public.fixture_deny_account_event();
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
DO $$ DECLARE request jsonb; BEGIN
 SELECT * INTO request FROM public.kibo_account_queue('pending');
 BEGIN PERFORM public.kibo_account_review((request->>'owner_id')::uuid,(request->>'version')::bigint,'processing','Note fictive'); RAISE EXCEPTION 'Expected journal refusal'; EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Fixture journal indisponible' THEN RAISE; END IF; END;
 IF NOT EXISTS(SELECT 1 FROM public.kibo_account_queue('pending')) THEN RAISE EXCEPTION 'Décision non atomique'; END IF;
END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
 BEGIN PERFORM public.kibo_notification_preferences(); RAISE EXCEPTION 'Expected visitor refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN PERFORM public.kibo_account_tracking(); RAISE EXCEPTION 'Expected visitor tracking refusal'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname IN('kibo_notification_preferences','kibo_account_tracking','kibo_account_queue','kibo_account_review','kibo_account_reply','kibo_chat_unread_count') AND p.prosecdef) THEN RAISE EXCEPTION 'Definer public'; END IF;
 IF (SELECT count(*) FROM pg_class WHERE oid IN('public.kibo_notification_preferences'::regclass,'public.kibo_account_request_events'::regclass) AND relrowsecurity)<>2 THEN RAISE EXCEPTION 'RLS absente'; END IF;
END $$;
ROLLBACK;
