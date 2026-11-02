CREATE SCHEMA storage;
ALTER ROLE service_role BYPASSRLS;
CREATE TABLE storage.objects(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),bucket_id text,name text,metadata jsonb);
GRANT SELECT ON public.kibo_listing_photos TO service_role;
ALTER TABLE public.kibo_listing_photos ADD CONSTRAINT kibo_listing_photos_check CHECK(
 path ~ ('^'||owner_id::text||'/'||listing_id::text||'/'||position::text||'-[0-9a-f]{64}[.]jpg$'));
