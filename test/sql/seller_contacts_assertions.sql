-- Fixture locale uniquement, coordonnees fictives, aucun appel/message.
BEGIN;
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status)
VALUES('cccccccc-cccc-4ccc-8ccc-cccccccccccc','11111111-1111-4111-8111-111111111111',
 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Annonce contact','Annonce fictive pour test',1000,'published');
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
INSERT INTO public.kibo_seller_contacts(owner_id,phone_e164,whatsapp_e164)
VALUES(auth.uid(),'+9991234567','+9997654321');
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_listing_seller_contact('cccccccc-cccc-4ccc-8ccc-cccccccccccc'))
 THEN RAISE EXCEPTION 'Consent false leaked contact'; END IF;
 BEGIN UPDATE public.kibo_seller_contacts SET phone_e164='javascript:bad';
  RAISE EXCEPTION 'Invalid number accepted'; EXCEPTION WHEN check_violation THEN NULL; END;
 BEGIN UPDATE public.kibo_seller_contacts SET owner_id='22222222-2222-4222-8222-222222222222';
  RAISE EXCEPTION 'Owner mutation accepted'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN UPDATE public.kibo_seller_contacts SET updated_at='2099-01-01';
  RAISE EXCEPTION 'Timestamp mutation accepted'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
UPDATE public.kibo_seller_contacts SET calls_enabled=true;
SET LOCAL request.jwt.claim.sub='22222222-2222-4222-8222-222222222222';
DO $$ DECLARE affected integer; BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_seller_contacts) THEN RAISE EXCEPTION 'Direct A/B read leak'; END IF;
 UPDATE public.kibo_seller_contacts SET calls_enabled=false WHERE owner_id='11111111-1111-4111-8111-111111111111';
 GET DIAGNOSTICS affected=ROW_COUNT;
 IF affected<>0 THEN RAISE EXCEPTION 'B changed A'; END IF;
 BEGIN INSERT INTO public.kibo_seller_contacts(owner_id) VALUES('11111111-1111-4111-8111-111111111111');
  RAISE EXCEPTION 'B inserted as A'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 IF NOT EXISTS(SELECT 1 FROM public.kibo_listing_seller_contact('cccccccc-cccc-4ccc-8ccc-cccccccccccc')
  WHERE phone_e164='+9991234567' AND whatsapp_e164 IS NULL) THEN RAISE EXCEPTION 'Opt-in channels incorrect'; END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_listing_seller_contact('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'))
 THEN RAISE EXCEPTION 'Unpublished listing contact leaked'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='';
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_listing_seller_contact('cccccccc-cccc-4ccc-8ccc-cccccccccccc'))
 THEN RAISE EXCEPTION 'Missing identity leaked contact'; END IF;
END $$;
SET LOCAL ROLE anon;
DO $$ BEGIN
 BEGIN PERFORM * FROM public.kibo_seller_contacts;
  RAISE EXCEPTION 'Anon table readable'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN PERFORM * FROM public.kibo_listing_seller_contact('cccccccc-cccc-4ccc-8ccc-cccccccccccc');
  RAISE EXCEPTION 'Anon RPC executable'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 BEGIN PERFORM * FROM kibo_contact_private.listing_contact('cccccccc-cccc-4ccc-8ccc-cccccccccccc');
  RAISE EXCEPTION 'Anon helper executable'; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
UPDATE public.kibo_seller_contacts SET calls_enabled=false;
SET LOCAL request.jwt.claim.sub='22222222-2222-4222-8222-222222222222';
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.kibo_listing_seller_contact('cccccccc-cccc-4ccc-8ccc-cccccccccccc'))
 THEN RAISE EXCEPTION 'Withdrawn consent leaked contact'; END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
 IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.kibo_seller_contacts'::regclass)
 THEN RAISE EXCEPTION 'RLS missing'; END IF;
 IF (SELECT prosecdef FROM pg_proc WHERE oid='public.kibo_listing_seller_contact(uuid)'::regprocedure)
 THEN RAISE EXCEPTION 'Public definer function'; END IF;
 IF has_table_privilege('authenticated','public.kibo_seller_contacts','DELETE') OR
    has_table_privilege('anon','public.kibo_seller_contacts','SELECT')
 THEN RAISE EXCEPTION 'Unnecessary table grants'; END IF;
END $$;
ROLLBACK;
