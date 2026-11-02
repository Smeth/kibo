-- Fixture locale seulement : les deux guards reels sont conserves.
DO $assert$ BEGIN
  IF EXISTS (
    SELECT * FROM public.fixture_baseline_policies EXCEPT
    SELECT polname,polcmd,pg_get_expr(polqual,polrelid),pg_get_expr(polwithcheck,polrelid)
    FROM pg_policy WHERE polrelid IN ('public.listings'::regclass,'public.favorites'::regclass)
  ) OR EXISTS (
    SELECT polname,polcmd,pg_get_expr(polqual,polrelid),pg_get_expr(polwithcheck,polrelid)
    FROM pg_policy WHERE polrelid IN ('public.listings'::regclass,'public.favorites'::regclass)
    EXCEPT SELECT * FROM public.fixture_baseline_policies
  ) THEN RAISE EXCEPTION 'Policies changed'; END IF;
  IF EXISTS (SELECT 1 FROM public.fixture_baseline_acl b JOIN pg_proc p ON p.oid=to_regprocedure(b.signature)
    WHERE (p.proacl::text,p.proowner,p.prosecdef,p.proconfig,p.prorettype,p.prolang)
       IS DISTINCT FROM (b.acl,b.proowner,b.prosecdef,b.proconfig,b.prorettype,b.prolang))
    THEN RAISE EXCEPTION 'Function ACL or attributes changed'; END IF;
END $assert$;

CREATE FUNCTION private.fixture_expect_denied(statement text) RETURNS void
LANGUAGE plpgsql SECURITY INVOKER AS $$ BEGIN
  BEGIN EXECUTE statement;
  EXCEPTION WHEN insufficient_privilege THEN RETURN; END;
  RAISE EXCEPTION 'Forbidden operation accepted: %',statement;
END $$;

BEGIN;
INSERT INTO public.listings(id,seller_id,category_id,title,description,price,status)
SELECT ('ffffffff-ffff-4fff-8fff-fffffffffff'||i)::uuid,
 '11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
 'Fixture vente directe','Description fictive de transition',1000,s::public.listing_status
FROM (VALUES (1,'published'),(2,'draft'),(3,'rejected')) t(i,s);
INSERT INTO public.fixture_photo_refs VALUES ('ffffffff-ffff-4fff-8fff-fffffffffff1','fixture/photo.jpg');
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
SELECT private.fixture_expect_denied($sql$UPDATE public.listings SET status='pending' WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff2'$sql$);
SELECT private.fixture_expect_denied($sql$UPDATE public.listings SET status='pending' WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff3'$sql$);
SELECT private.fixture_expect_denied($sql$UPDATE public.listings SET title='Rejet modifie' WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff3'$sql$);
UPDATE public.listings SET title='Brouillon modifie' WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff2';
COMMIT;

CREATE TEMP TABLE fixture_version AS SELECT id,updated_at,published_at
FROM public.listings WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff1';
GRANT SELECT ON fixture_version TO authenticated;
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
UPDATE public.listings SET title='Titre telephone neuf',price=2000 WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff1';
COMMIT;
BEGIN;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
DO $$ DECLARE affected integer; BEGIN
 UPDATE public.listings SET status='archived'
 WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff1' AND updated_at=(SELECT updated_at FROM fixture_version);
 GET DIAGNOSTICS affected=ROW_COUNT;
 IF affected<>0 THEN RAISE EXCEPTION 'Stale version overwritten'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.listings l JOIN fixture_version v USING(id)
   WHERE l.published_at=v.published_at AND l.updated_at>v.updated_at
    AND l.kibo_search_vector @@ websearch_to_tsquery('french','telephone'))
 THEN RAISE EXCEPTION 'Timestamp, publication or vector damaged'; END IF;
END $$;
SET LOCAL request.jwt.claim.sub='22222222-2222-4222-8222-222222222222';
INSERT INTO public.favorites VALUES (auth.uid(),'ffffffff-ffff-4fff-8fff-fffffffffff1');
SET LOCAL request.jwt.claim.sub='11111111-1111-4111-8111-111111111111';
UPDATE public.listings SET status='archived' WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff1';
SET LOCAL request.jwt.claim.sub='22222222-2222-4222-8222-222222222222';
SET LOCAL request.jwt.claims='{"user_metadata":{"role":"admin"}}';
DO $$ BEGIN
 IF private.is_admin() THEN RAISE EXCEPTION 'User metadata elevated'; END IF;
 IF EXISTS (SELECT 1 FROM public.fixture_photo_refs) THEN RAISE EXCEPTION 'Archived photo visible to B'; END IF;
 IF NOT EXISTS (SELECT 1 FROM public.favorites WHERE listing_id='ffffffff-ffff-4fff-8fff-fffffffffff1')
 THEN RAISE EXCEPTION 'Favorite removed'; END IF;
END $$;
SET LOCAL ROLE anon;
SET LOCAL request.jwt.claim.sub='';
DO $$ BEGIN
 IF EXISTS(SELECT 1 FROM public.listings WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff1')
 THEN RAISE EXCEPTION 'Archived listing public'; END IF;
END $$;
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub='22222222-2222-4222-8222-222222222222';
SET LOCAL request.jwt.claims='{"app_metadata":{"role":"admin"}}';
UPDATE public.listings SET status='published',views_count=7 WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff1';
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM public.listings WHERE id='ffffffff-ffff-4fff-8fff-fffffffffff1' AND status='published' AND views_count=7)
 THEN RAISE EXCEPTION 'Admin flow broken'; END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
 IF (SELECT count(*) FROM public.fixture_photo_refs)<>1 THEN RAISE EXCEPTION 'Photo metadata removed'; END IF;
END $$;
ROLLBACK;
-- Les trois lignes initiales sont fictives et restent seulement dans ce cluster jetable.
