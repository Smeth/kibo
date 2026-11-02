BEGIN;
INSERT INTO public.kibo_account_requests(owner_id,status) VALUES('11111111-1111-4111-8111-111111111111','processing');
INSERT INTO auth.users VALUES('11111111-1111-4111-8111-111111111111');
INSERT INTO storage.objects(bucket_id,name,owner_id) VALUES('kibo-listing-photos','11111111-1111-4111-8111-111111111111/fixture.jpg','11111111-1111-4111-8111-111111111111');
INSERT INTO public.conversations(id,listing_id,buyer_id,seller_id) VALUES('90000000-0000-4000-8000-000000000001','cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','11111111-1111-4111-8111-111111111111');
INSERT INTO public.messages(conversation_id,sender_id,content) VALUES
('90000000-0000-4000-8000-000000000001','11111111-1111-4111-8111-111111111111','Personal information to remove'),
('90000000-0000-4000-8000-000000000001','22222222-2222-4222-8222-222222222222','Own message to retain');
INSERT INTO public.listing_comments(listing_id,user_id,content) VALUES('cccccccc-cccc-4ccc-8ccc-cccccccccccc','22222222-2222-4222-8222-222222222222','Own comment retained');
SELECT set_config('fixture.version',(SELECT version::text FROM public.kibo_account_requests WHERE owner_id='11111111-1111-4111-8111-111111111111'),true);
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 BEGIN PERFORM public.kibo_deletion_begin('11111111-1111-4111-8111-111111111111','33333333-3333-4333-8333-333333333333',current_setting('fixture.version')::bigint);
 RAISE EXCEPTION 'Client deletion accepted';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT set_config('fixture.job',(public.kibo_deletion_begin('11111111-1111-4111-8111-111111111111','33333333-3333-4333-8333-333333333333',current_setting('fixture.version')::bigint)->>'id'),true);
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
DO $$ BEGIN
 BEGIN PERFORM public.kibo_request_guard();RAISE EXCEPTION 'Old JWT accepted';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 IF EXISTS(SELECT 1 FROM public.listings) THEN RAISE EXCEPTION 'Frozen JWT reads rows';END IF;
END $$;
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT public.kibo_deletion_purge(current_setting('fixture.job')::uuid);
SELECT public.kibo_deletion_purge(current_setting('fixture.job')::uuid);
DO $$ BEGIN
 IF public.kibo_deletion_ready(current_setting('fixture.job')::uuid) THEN RAISE EXCEPTION 'Storage verification bypassed';END IF;
 BEGIN PERFORM public.kibo_deletion_object_ack(current_setting('fixture.job')::uuid,'kibo-listing-photos','11111111-1111-4111-8111-111111111111/fixture.jpg');
 RAISE EXCEPTION 'False ack accepted';EXCEPTION WHEN raise_exception THEN IF SQLERRM='False ack accepted' THEN RAISE;END IF;END;
END $$;
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
SELECT set_config('request.jwt.claims','{"app_metadata":{"role":"admin"}}',true);
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.kibo_account_queue('processing',0) q WHERE q->>'owner_id'='11111111-1111-4111-8111-111111111111') THEN
  RAISE EXCEPTION 'Purged job disappeared from admin queue';END IF;
END $$;
RESET ROLE;
-- Simulated Storage API effect in the disposable fixture only.
DELETE FROM storage.objects;
SET LOCAL ROLE service_role;
SELECT public.kibo_deletion_object_ack(current_setting('fixture.job')::uuid,'kibo-listing-photos','11111111-1111-4111-8111-111111111111/fixture.jpg');
DO $$ BEGIN
 IF NOT public.kibo_deletion_ready(current_setting('fixture.job')::uuid) THEN RAISE EXCEPTION 'Not ready';END IF;
 BEGIN PERFORM public.kibo_deletion_complete(current_setting('fixture.job')::uuid);RAISE EXCEPTION 'Auth verification bypassed';EXCEPTION WHEN raise_exception THEN
 IF SQLERRM='Auth verification bypassed' THEN RAISE;END IF;END;
END $$;
RESET ROLE;
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.profiles WHERE id='11111111-1111-4111-8111-111111111111') THEN RAISE EXCEPTION 'Profile retained';END IF;
 IF (SELECT count(*) FROM public.kibo_retained_messages)<>2 THEN RAISE EXCEPTION 'Messages not retained';END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_retained_messages WHERE content LIKE '%Personal%') THEN RAISE EXCEPTION 'Personal content leaked';END IF;
 IF (SELECT count(*) FROM public.kibo_retained_comments)<>1 THEN RAISE EXCEPTION 'Other comment lost';END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_retained_threads WHERE expires_at>now()+interval '15 days') THEN RAISE EXCEPTION 'Retention';END IF;
END $$;
DELETE FROM auth.users WHERE id='11111111-1111-4111-8111-111111111111';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $$ BEGIN
 IF (SELECT count(*) FROM public.kibo_retained_messages('90000000-0000-4000-8000-000000000001'))<>2 THEN RAISE EXCEPTION 'Survivor cannot read history';END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','33333333-3333-4333-8333-333333333333',true);
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_retained_messages('90000000-0000-4000-8000-000000000001')) THEN RAISE EXCEPTION 'Third party reads private archive';END IF;
END $$;
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT public.kibo_deletion_complete(current_setting('fixture.job')::uuid);
SELECT public.kibo_deletion_complete(current_setting('fixture.job')::uuid);
ROLLBACK;
