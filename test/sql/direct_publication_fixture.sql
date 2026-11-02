-- FIXTURE EXCLUSIVEMENT LOCALE : base jetable vide. NE JAMAIS DEPLOYER.
CREATE ROLE anon NOLOGIN;
CREATE ROLE authenticated NOLOGIN;
CREATE SCHEMA auth;
CREATE SCHEMA private;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS
  $$ SELECT nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
CREATE FUNCTION private.is_admin() RETURNS boolean LANGUAGE sql STABLE AS $$ SELECT false $$;
GRANT USAGE ON SCHEMA public, auth, private TO anon, authenticated;

CREATE TYPE public.listing_status AS ENUM ('draft','pending','published','rejected','archived');
CREATE TYPE public.listing_type AS ENUM ('product','service');
CREATE TABLE public.profiles (id uuid PRIMARY KEY);
CREATE TABLE public.categories (id uuid PRIMARY KEY, name text NOT NULL, is_active boolean NOT NULL DEFAULT true);
CREATE TABLE public.listings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id uuid NOT NULL REFERENCES public.profiles ON DELETE RESTRICT,
  category_id uuid NOT NULL REFERENCES public.categories ON DELETE RESTRICT,
  title text NOT NULL CHECK (char_length(trim(title)) BETWEEN 5 AND 120),
  description text NOT NULL CHECK (char_length(trim(description)) BETWEEN 10 AND 10000),
  listing_type public.listing_type NOT NULL DEFAULT 'product',
  price numeric(14,2) NOT NULL CHECK (price >= 0),
  currency text NOT NULL DEFAULT 'XAF' CHECK (currency = 'XAF'),
  city text NOT NULL DEFAULT 'Brazzaville', neighborhood text,
  attributes jsonb NOT NULL DEFAULT '{}' CHECK (jsonb_typeof(attributes) = 'object'),
  status public.listing_status NOT NULL DEFAULT 'pending', rejection_reason text,
  views_count bigint NOT NULL DEFAULT 0 CHECK (views_count >= 0),
  published_at timestamptz, expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE public.favorites (
  user_id uuid REFERENCES public.profiles ON DELETE CASCADE,
  listing_id uuid REFERENCES public.listings ON DELETE CASCADE,
  PRIMARY KEY (user_id, listing_id)
);
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
CREATE POLICY listings_read_public ON public.listings FOR SELECT TO anon, authenticated
  USING (status = 'published' OR seller_id = auth.uid() OR private.is_admin());
CREATE POLICY listings_insert_own ON public.listings FOR INSERT TO authenticated
  WITH CHECK (seller_id = auth.uid() AND status IN ('draft','pending') AND views_count = 0 AND published_at IS NULL AND rejection_reason IS NULL);
CREATE POLICY listings_update_own ON public.listings FOR UPDATE TO authenticated
  USING (seller_id = auth.uid() OR private.is_admin()) WITH CHECK (seller_id = auth.uid() OR private.is_admin());
CREATE POLICY listings_delete_admin ON public.listings FOR DELETE TO authenticated USING (private.is_admin());
CREATE FUNCTION private.fixture_guard_listing_update() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.seller_id IS DISTINCT FROM OLD.seller_id OR NEW.status IS DISTINCT FROM OLD.status
    OR NEW.views_count IS DISTINCT FROM OLD.views_count OR NEW.published_at IS DISTINCT FROM OLD.published_at
    OR NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN
    RAISE EXCEPTION 'Protected fields' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER fixture_existing_update_guard BEFORE UPDATE ON public.listings
  FOR EACH ROW EXECUTE FUNCTION private.fixture_guard_listing_update();
CREATE POLICY favorites_read_own ON public.favorites FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY favorites_insert_own ON public.favorites FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid() AND EXISTS (SELECT 1 FROM public.listings WHERE id = listing_id AND status = 'published'));
CREATE POLICY favorites_delete_own ON public.favorites FOR DELETE TO authenticated USING (user_id = auth.uid());
GRANT SELECT, INSERT, UPDATE, DELETE ON public.listings, public.favorites TO anon, authenticated;
INSERT INTO public.profiles VALUES ('11111111-1111-4111-8111-111111111111'), ('22222222-2222-4222-8222-222222222222');
INSERT INTO public.categories VALUES ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Categorie fictive', true);
INSERT INTO public.listings (id,seller_id,category_id,title,description,price) VALUES
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb','11111111-1111-4111-8111-111111111111','aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa','Ancien pending','Annonce fictive ancienne',1000);
-- Snapshot des protections a comparer apres le delta (pas de donnees utilisateur).
CREATE TABLE public.fixture_policy_snapshot AS
  SELECT polname, polcmd, pg_get_expr(polqual,polrelid) AS qual, pg_get_expr(polwithcheck,polrelid) AS check_expr
  FROM pg_policy WHERE polrelid IN ('public.listings'::regclass, 'public.favorites'::regclass) AND polname <> 'listings_insert_own';
