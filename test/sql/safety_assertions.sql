BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT set_config('request.jwt.claims','{}',true);
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','11111111-1111-4111-8111-111111111111');
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','22222222-2222-4222-8222-222222222222','Fictif uniquement');
INSERT INTO public.listing_comments(id,listing_id,user_id,content) VALUES('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','Commentaire fictif');
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.notifications) THEN RAISE EXCEPTION 'Notification visible par expéditeur'; END IF;
 IF public.kibo_can_moderate() THEN RAISE EXCEPTION 'Escalade de droits'; END IF;
 BEGIN PERFORM public.kibo_review_report(gen_random_uuid(),'hide','Motif fictif');RAISE EXCEPTION 'Expected refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 BEGIN INSERT INTO public.notifications(user_id,notification_type,title,body) VALUES(auth.uid(),'system','Faux','Faux');RAISE EXCEPTION 'Expected refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
INSERT INTO public.reports(reporter_id,listing_id,reason,details) VALUES(auth.uid(),'cccccccc-cccc-4ccc-8ccc-cccccccccccc','Arnaque présumée','Signalement fictif');
INSERT INTO public.reports(reporter_id,comment_id,reason,details) VALUES(auth.uid(),'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Contenu interdit','Commentaire signalé fictif');
DO $$ BEGIN
 BEGIN INSERT INTO public.reports(reporter_id,listing_id,reason) VALUES(auth.uid(),'cccccccc-cccc-4ccc-8ccc-cccccccccccc','Arnaque présumée');RAISE EXCEPTION 'Expected duplicate refusal';EXCEPTION WHEN unique_violation THEN NULL;END;
 BEGIN INSERT INTO public.reports(reporter_id,listing_id,comment_id,reason) VALUES(auth.uid(),'cccccccc-cccc-4ccc-8ccc-cccccccccccc','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Test double cible');RAISE EXCEPTION 'Expected target refusal';EXCEPTION WHEN invalid_parameter_value THEN NULL;END;
 BEGIN UPDATE public.reports SET status='resolved';RAISE EXCEPTION 'Expected update refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ DECLARE n uuid; before_read timestamptz; BEGIN
 IF (SELECT count(*) FROM public.notifications)<>2 THEN RAISE EXCEPTION 'Notifications message/comment manquantes';END IF;
 SELECT id INTO n FROM public.notifications LIMIT 1;
 PERFORM set_config('fixture.notice_id',n::text,true);
 PERFORM public.kibo_mark_notification_read(n);
 SELECT read_at INTO before_read FROM public.notifications WHERE id=n;
 PERFORM public.kibo_mark_notification_read(n);
 IF before_read IS NULL OR before_read IS DISTINCT FROM (SELECT read_at FROM public.notifications WHERE id=n) THEN RAISE EXCEPTION 'Lecture non idempotente';END IF;
 IF EXISTS(SELECT 1 FROM public.reports) THEN RAISE EXCEPTION 'Identité du signaleur divulguée';END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.notifications) THEN RAISE EXCEPTION 'Isolation notifications';END IF;
 BEGIN PERFORM public.kibo_mark_notification_read(current_setting('fixture.notice_id')::uuid);RAISE EXCEPTION 'Expected refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claims','{"user_metadata":{"role":"admin"}}',true);
DO $$ BEGIN IF public.kibo_can_moderate() THEN RAISE EXCEPTION 'User metadata escalade';END IF;END $$;
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
DO $$ DECLARE r uuid; result jsonb; BEGIN
 IF NOT public.kibo_can_moderate() THEN RAISE EXCEPTION 'Admin non reconnu';END IF;
 SELECT id INTO r FROM public.reports WHERE listing_id='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
 result=public.kibo_report_content(r);IF result->>'title'<>'Annonce chat test' THEN RAISE EXCEPTION 'Contenu admin manquant';END IF;
 PERFORM public.kibo_review_report(r,'hide','Motif de test uniquement');
 IF (SELECT status FROM public.listings WHERE id='cccccccc-cccc-4ccc-8ccc-cccccccccccc')<>'rejected' THEN RAISE EXCEPTION 'Masquage manquant';END IF;
 IF (SELECT status FROM public.reports WHERE id=r)<>'resolved' OR (SELECT count(*) FROM public.kibo_moderation_log WHERE report_id=r)<>1 THEN RAISE EXCEPTION 'Journal/decision non atomiques';END IF;
 BEGIN PERFORM public.kibo_review_report(r,'hide','Autre motif');RAISE EXCEPTION 'Expected closed refusal';EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Signalement deja traite ou indisponible' THEN RAISE;END IF;END;
 BEGIN INSERT INTO public.kibo_moderation_log(report_id,moderator_id,target_type,target_id,action,reason) VALUES(r,auth.uid(),'listing',r,'hide','Journal forgé');RAISE EXCEPTION 'Expected audit refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
RESET ROLE;
CREATE FUNCTION private.fixture_fail_log() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION 'Fixture log failure';END $$;
CREATE TRIGGER fixture_log_failure BEFORE INSERT ON public.kibo_moderation_log FOR EACH ROW EXECUTE FUNCTION private.fixture_fail_log();
SET LOCAL ROLE authenticated;
DO $$ DECLARE r uuid; BEGIN
 SELECT id INTO r FROM public.reports WHERE comment_id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
 BEGIN PERFORM public.kibo_review_report(r,'hide','Test atomicite');RAISE EXCEPTION 'Expected log failure';EXCEPTION WHEN raise_exception THEN IF SQLERRM<>'Fixture log failure' THEN RAISE;END IF;END;
 IF (SELECT status FROM public.reports WHERE id=r)<>'pending' OR (SELECT status FROM public.listing_comments WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee')<>'published' THEN RAISE EXCEPTION 'Decision partiellement appliquee';END IF;
END $$;
RESET ROLE;
DROP TRIGGER fixture_log_failure ON public.kibo_moderation_log;
SET LOCAL ROLE authenticated;
DO $$ DECLARE r uuid; BEGIN
 SELECT id INTO r FROM public.reports WHERE comment_id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee';
 PERFORM public.kibo_review_report(r,'hide','Masquage commentaire fictif');
 IF (SELECT status FROM public.listing_comments WHERE id='eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee')<>'hidden' OR (SELECT count(*) FROM public.kibo_moderation_log WHERE report_id=r)<>1 THEN RAISE EXCEPTION 'Masquage commentaire non trace';END IF;
END $$;
SELECT set_config('request.jwt.claims','{}',true);
DO $$ BEGIN IF EXISTS(SELECT 1 FROM public.kibo_moderation_log) THEN RAISE EXCEPTION 'Journal public';END IF;END $$;
RESET ROLE;
SET LOCAL ROLE anon;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.notifications) THEN RAISE EXCEPTION 'Visiteur lit notifications';END IF;
 BEGIN PERFORM public.kibo_can_moderate();RAISE EXCEPTION 'Expected anon RPC refusal';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
RESET ROLE;
DO $$ BEGIN IF EXISTS(SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.proname IN('kibo_review_report','kibo_report_content','kibo_mark_notification_read','kibo_can_moderate') AND p.prosecdef) THEN RAISE EXCEPTION 'Definer public';END IF;END $$;
ROLLBACK;
