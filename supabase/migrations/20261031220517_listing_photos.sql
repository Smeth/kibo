-- PROPOSITION LOCALE : audit Storage distant obligatoire avant application.
-- Ne remplace aucun bucket, table ou politique existants. Toute collision bloque.
BEGIN;
DO $$ BEGIN
  IF to_regclass('public.kibo_listing_photos') IS NOT NULL
    OR EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'kibo-listing-photos') THEN
    RAISE EXCEPTION 'Contrat photos deja present : audit et adaptation requis';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'storage.objects'::regclass) THEN
    RAISE EXCEPTION 'RLS Storage requise';
  END IF;
  -- Les politiques permissives sont combinees en OR. Une politique existante
  -- pourrait permettre un upload direct et contourner le decodeur Edge.
  IF EXISTS (SELECT 1 FROM pg_policy WHERE polrelid = 'storage.objects'::regclass) THEN
    RAISE EXCEPTION 'Politiques Storage existantes : revue du perimetre obligatoire';
  END IF;
END $$;

CREATE TABLE public.kibo_listing_photos (
  listing_id uuid NOT NULL REFERENCES public.listings(id) ON DELETE CASCADE,
  position smallint NOT NULL CHECK (position BETWEEN 0 AND 2),
  owner_id uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
  path text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (listing_id, position),
  CHECK (path ~ ('^' || owner_id::text || '/' || listing_id::text || '/' || position::text || '-[0-9a-f]{64}\.jpg$'))
);
ALTER TABLE public.kibo_listing_photos ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.kibo_listing_photos FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.kibo_listing_photos TO anon, authenticated;
GRANT INSERT (listing_id, position, path) ON public.kibo_listing_photos TO authenticated;
CREATE POLICY kibo_photos_read ON public.kibo_listing_photos FOR SELECT TO anon, authenticated
USING (EXISTS (SELECT 1 FROM public.listings l WHERE l.id = listing_id
  AND (l.status::text = 'published' OR l.seller_id = auth.uid())));
CREATE POLICY kibo_photos_reserve ON public.kibo_listing_photos FOR INSERT TO authenticated
WITH CHECK (auth.uid() IS NOT NULL AND owner_id = auth.uid()
  AND EXISTS (SELECT 1 FROM public.listings l WHERE l.id = listing_id AND l.seller_id = auth.uid()
    AND l.status::text IN ('draft', 'pending', 'published')));
-- Pas d'UPDATE/DELETE de reservation par les clients : chemin immuable pour
-- permettre une reprise idempotente et empecher l'accumulation par changement.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('kibo-listing-photos', 'kibo-listing-photos', false, 4194304, ARRAY['image/jpeg']);
-- Lecture des seuls objets references par des annonces encore accessibles.
CREATE POLICY kibo_photo_objects_read ON storage.objects FOR SELECT TO anon, authenticated
USING (bucket_id = 'kibo-listing-photos' AND EXISTS (
  SELECT 1 FROM public.kibo_listing_photos p JOIN public.listings l ON l.id = p.listing_id
  WHERE p.path = name AND (l.status::text = 'published' OR l.seller_id = auth.uid())
));
-- Aucun INSERT/UPDATE/DELETE client sur les objets : seule la fonction Edge
-- valide les octets JPEG et la propriete, puis utilise son droit serveur.
COMMIT;
