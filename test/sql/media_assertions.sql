BEGIN;
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status) VALUES
('10000000-0000-4000-8000-000000000001','11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Galerie test','Description de galerie',100,'published');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT public.kibo_prepare_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',0,ARRAY[repeat('a',64)]);
SELECT set_config('fixture.transfer',public.kibo_photo_transfer_begin('11111111-1111-4111-8111-111111111111/10000000-0000-4000-8000-000000000001/edit-20000000-0000-4000-8000-000000000001-'||repeat('a',64)||'.jpg')::text,true);
DO $$ BEGIN
 BEGIN PERFORM public.kibo_photo_transfer_finish(current_setting('fixture.transfer')::uuid,false);RAISE EXCEPTION 'Client closed transfer';
 EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 BEGIN PERFORM public.kibo_apply_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',0,'{}');RAISE EXCEPTION 'Active transfer ignored';
 EXCEPTION WHEN raise_exception THEN IF SQLERRM='Active transfer ignored' THEN RAISE;END IF;END;
END $$;
RESET ROLE;
SET LOCAL ROLE service_role;
SELECT public.kibo_photo_transfer_finish(current_setting('fixture.transfer')::uuid,false);
RESET ROLE;
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 BEGIN
 PERFORM public.kibo_apply_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',0,ARRAY['foreign']);
 RAISE EXCEPTION 'Foreign path accepted';
 EXCEPTION WHEN insufficient_privilege THEN NULL;END;
END $$;
RESET ROLE;
INSERT INTO storage.objects(bucket_id,name,metadata) VALUES('kibo-listing-photos',
'11111111-1111-4111-8111-111111111111/10000000-0000-4000-8000-000000000001/edit-20000000-0000-4000-8000-000000000001-'||repeat('a',64)||'.jpg','{"mimetype":"image/jpeg","size":100}');
SET LOCAL ROLE authenticated;
DO $$ DECLARE p text:='11111111-1111-4111-8111-111111111111/10000000-0000-4000-8000-000000000001/edit-20000000-0000-4000-8000-000000000001-'||repeat('a',64)||'.jpg';r jsonb; BEGIN
 r:=public.kibo_apply_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',0,ARRAY[p]);
 IF (r->>'revision')::int<>1 THEN RAISE EXCEPTION 'Revision';END IF;
 PERFORM public.kibo_apply_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',0,ARRAY[p]);
 BEGIN
 PERFORM public.kibo_prepare_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002',0,'{}');
 RAISE EXCEPTION 'Stale revision accepted';
 EXCEPTION WHEN serialization_failure THEN NULL;END;
 PERFORM public.kibo_prepare_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002',1,'{}');
 PERFORM public.kibo_apply_photo_edit('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000002',1,'{}');
 IF (SELECT count(*) FROM public.kibo_photo_cleanup_queue())<>1 THEN RAISE EXCEPTION 'Cleanup absent';END IF;
END $$;
SELECT set_config('request.jwt.claim.sub','22222222-2222-4222-8222-222222222222',true);
DO $$ BEGIN
 BEGIN
 PERFORM public.kibo_photo_edit_state('10000000-0000-4000-8000-000000000001');
 RAISE EXCEPTION 'Other owner accepted';
 EXCEPTION WHEN insufficient_privilege THEN NULL;END;
 IF (SELECT count(*) FROM public.kibo_photo_cleanup_queue())<>0 THEN RAISE EXCEPTION 'Other cleanup exposed';END IF;
END $$;
ROLLBACK;
