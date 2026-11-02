-- Base locale uniquement, apres les gardes de gestion proprietaire.
CREATE SCHEMA IF NOT EXISTS extensions;
CREATE TABLE public.kibo_listing_photos(
 listing_id uuid REFERENCES public.listings ON DELETE CASCADE,
 position smallint CHECK(position BETWEEN 0 AND 2),owner_id uuid REFERENCES public.profiles,
 path text NOT NULL UNIQUE,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(listing_id,position));
ALTER TABLE public.kibo_listing_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY photos_read ON public.kibo_listing_photos FOR SELECT TO anon,authenticated
 USING(EXISTS(SELECT 1 FROM public.listings l WHERE l.id=listing_id AND l.status='published') OR owner_id=auth.uid());
GRANT SELECT ON public.kibo_listing_photos TO anon,authenticated;
GRANT SELECT ON public.categories TO anon,authenticated;
