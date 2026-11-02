CREATE TABLE auth.users(id uuid PRIMARY KEY);
ALTER TABLE storage.objects ADD COLUMN owner_id text;
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
DO $$ DECLARE r record; BEGIN
 FOR r IN SELECT tablename FROM pg_tables WHERE schemaname='public' LOOP
  EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',r.tablename);
 END LOOP;
END $$;
-- Match the production CASCADE relationships (the original safety fixture predates these).
ALTER TABLE public.listing_comments DROP CONSTRAINT listing_comments_parent_id_fkey,
 DROP CONSTRAINT listing_comments_user_id_fkey,DROP CONSTRAINT listing_comments_listing_id_fkey;
ALTER TABLE public.listing_comments ADD FOREIGN KEY(parent_id) REFERENCES public.listing_comments ON DELETE CASCADE,
 ADD FOREIGN KEY(user_id) REFERENCES public.profiles ON DELETE CASCADE,
 ADD FOREIGN KEY(listing_id) REFERENCES public.listings ON DELETE CASCADE;
