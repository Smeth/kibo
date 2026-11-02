-- LOCAL SEULEMENT. Une future regle permissive globale ne doit pas ouvrir le nouveau bucket.
BEGIN;
CREATE POLICY audit_broad ON storage.objects FOR ALL TO anon, authenticated USING(true) WITH CHECK(true);
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claim.sub = '11111111-1111-4111-8111-111111111111';
INSERT INTO storage.objects(bucket_id,name) VALUES ('listing-images','legacy-test');
UPDATE storage.objects SET name='legacy-test-updated' WHERE bucket_id='listing-images';
DELETE FROM storage.objects WHERE bucket_id='listing-images';
DO $$ BEGIN
  BEGIN
    INSERT INTO storage.objects(bucket_id,name) VALUES ('kibo-listing-photos','blocked');
    RAISE EXCEPTION 'Broad policy bypasses private bucket';
  EXCEPTION WHEN insufficient_privilege THEN NULL; END;
END $$;
RESET ROLE;
INSERT INTO storage.objects(bucket_id,name) VALUES ('kibo-listing-photos','unreferenced');
SET LOCAL ROLE anon;
SET LOCAL request.jwt.claim.sub = '';
DO $$ BEGIN
  IF EXISTS(SELECT 1 FROM storage.objects WHERE bucket_id='kibo-listing-photos') THEN
    RAISE EXCEPTION 'Broad policy leaks private object';
  END IF;
END $$;
RESET ROLE;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='storage' AND tablename='objects'
      AND policyname='legacy_other_bucket' AND qual = '(bucket_id = ''listing-images''::text)'
      AND with_check = '(bucket_id = ''listing-images''::text)') THEN
    RAISE EXCEPTION 'Legacy policy changed';
  END IF;
END $$;
ROLLBACK;
