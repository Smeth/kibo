BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT public.kibo_push_register('fixture-token-shared-device');
DO $$ BEGIN
 BEGIN PERFORM public.kibo_push_claim();RAISE EXCEPTION 'Client claimed server queue';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 BEGIN PERFORM 1 FROM kibo_push_private.devices;RAISE EXCEPTION 'Token read exposed';EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
SELECT public.kibo_push_register('fixture-token-shared-device');
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT public.kibo_push_unregister('fixture-token-shared-device');
RESET ROLE;
DO $$ BEGIN
 IF (SELECT owner_id FROM kibo_push_private.devices WHERE token='fixture-token-shared-device')<>'22222222-2222-4222-8222-222222222222' THEN RAISE EXCEPTION 'Device reassignment unsafe';END IF;
END $$;
INSERT INTO public.notifications(id,user_id,notification_type,title,body) VALUES('ffffffff-ffff-4fff-8fff-ffffffffffff','22222222-2222-4222-8222-222222222222','system','Fixture','Private content never in queue');
SET LOCAL ROLE service_role;
DO $$ DECLARE jobs jsonb[];job jsonb;BEGIN
 SELECT array_agg(x) INTO jobs FROM public.kibo_push_claim()x;
 IF cardinality(jobs)<>1 THEN RAISE EXCEPTION 'Queue missing';END IF;
 job:=jobs[1];
 IF job::text LIKE '%Private content%' THEN RAISE EXCEPTION 'Message content leaked';END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_push_claim()) THEN RAISE EXCEPTION 'Lease race';END IF;
 PERFORM public.kibo_push_ack((job->>'id')::uuid,(job->>'lease')::uuid,true,ARRAY['fixture-token-shared-device']);
END $$;
RESET ROLE;
DO $$ BEGIN IF EXISTS(SELECT 1 FROM kibo_push_private.devices) THEN RAISE EXCEPTION 'Invalid token retained';END IF;END $$;
ROLLBACK;
