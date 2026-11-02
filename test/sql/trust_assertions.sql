BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('dddddddd-dddd-4ddd-8ddd-dddddddddddd','cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','11111111-1111-4111-8111-111111111111');
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
INSERT INTO public.messages(id,conversation_id,sender_id,content) VALUES('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','dddddddd-dddd-4ddd-8ddd-dddddddddddd',auth.uid(),'Message fictif');
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN
 BEGIN PERFORM public.kibo_report_target('message','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Autre motif',''); RAISE EXCEPTION 'Third party accepted'; EXCEPTION WHEN raise_exception THEN IF SQLERRM='Third party accepted' THEN RAISE;END IF;END;
END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT public.kibo_report_target('message','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Autre motif','Fixture');
SELECT public.kibo_report_target('profile','11111111-1111-4111-8111-111111111111','Autre motif','Fixture');
DO $$ BEGIN
 IF (SELECT count(*) FROM public.reports)<>2 THEN RAISE EXCEPTION 'Missing reports'; END IF;
 BEGIN PERFORM public.kibo_report_target('message','eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee','Autre motif','');RAISE EXCEPTION 'Duplicate accepted';EXCEPTION WHEN unique_violation THEN NULL;END;
 BEGIN INSERT INTO public.kibo_official_accounts(user_id) VALUES(auth.uid());RAISE EXCEPTION 'Self badge allowed';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN IF EXISTS(SELECT 1 FROM public.reports) THEN RAISE EXCEPTION 'Reporter disclosed';END IF;END $$;
RESET ROLE;
INSERT INTO public.kibo_official_accounts(user_id) VALUES('11111111-1111-4111-8111-111111111111');
SET LOCAL ROLE anon;
DO $$ BEGIN
 IF NOT public.kibo_is_official('11111111-1111-4111-8111-111111111111') OR public.kibo_is_official('22222222-2222-4222-8222-222222222222') THEN RAISE EXCEPTION 'Badge incorrect';END IF;
 BEGIN PERFORM public.kibo_report_target('profile','11111111-1111-4111-8111-111111111111','Autre motif','');RAISE EXCEPTION 'Anon report accepted';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
DO $$ DECLARE r record; BEGIN
 FOR r IN SELECT id FROM public.reports LOOP
  IF public.kibo_report_content(r.id) IS NULL THEN RAISE EXCEPTION 'Missing context';END IF;
  PERFORM public.kibo_review_report(r.id,'resolve','Examen fictif motive');
 END LOOP;
 IF (SELECT count(*) FROM public.kibo_moderation_log)<>2 THEN RAISE EXCEPTION 'Missing audit';END IF;
END $$;
ROLLBACK;
