-- Preserve owner/listing/hash validation while allowing stable paths to be reordered.
BEGIN;
SET LOCAL lock_timeout='5s';
DO $$ BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_constraint WHERE conrelid='public.kibo_listing_photos'::regclass AND conname='kibo_listing_photos_check' AND contype='c') THEN
  RAISE EXCEPTION 'Photo path baseline changed';END IF;
 IF EXISTS(SELECT 1 FROM public.kibo_listing_photos WHERE path !~ ('^'||owner_id::text||'/'||listing_id::text||'/[0-2]-[0-9a-f]{64}[.]jpg$')) THEN
  RAISE EXCEPTION 'Existing photo paths require review';END IF;
END $$;
ALTER TABLE public.kibo_listing_photos DROP CONSTRAINT kibo_listing_photos_check;
ALTER TABLE public.kibo_listing_photos ADD CONSTRAINT kibo_photo_managed_path_check CHECK(
 path ~ ('^'||owner_id::text||'/'||listing_id::text||'/([0-2]-[0-9a-f]{64}|edit-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}-[0-9a-f]{64})[.]jpg$'));
COMMIT;
