-- Delta local pour recherche paginee serveur ; politiques RLS inchangees.
BEGIN;
ALTER TABLE public.listings ADD COLUMN kibo_search_vector tsvector
GENERATED ALWAYS AS (
  setweight(to_tsvector('pg_catalog.french'::regconfig, coalesce(title, '')), 'A') ||
  setweight(to_tsvector('pg_catalog.french'::regconfig, coalesce(description, '')), 'B')
) STORED;
CREATE INDEX kibo_listings_search_gin ON public.listings USING gin (kibo_search_vector)
  WHERE status = 'published';
CREATE INDEX kibo_listings_price ON public.listings (price, published_at DESC, id)
  WHERE status = 'published';
COMMIT;
