-- Publication directe au lancement. PREPAREE UNIQUEMENT : ne pas appliquer
-- sans revue des metadonnees distantes et autorisation explicite du proprietaire.
-- Delta sur les tables existantes : aucune table recreee, aucun UPDATE de donnees.
BEGIN;

DO $preflight$
BEGIN
  IF to_regclass('public.listings') IS NULL THEN
    RAISE EXCEPTION 'Table listings absente : cette migration est un delta, pas un schema initial';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.listings'::regclass) THEN
    RAISE EXCEPTION 'RLS doit deja etre active sur listings';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM pg_policy
    WHERE polrelid = 'public.listings'::regclass
      AND polname = 'listings_insert_own' AND polcmd = 'a'
      AND polpermissive AND polroles = ARRAY['authenticated'::regrole::oid]
  ) THEN
    RAISE EXCEPTION 'Politique INSERT attendue absente ou differente : revoir le contrat';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_policy
    WHERE polrelid = 'public.listings'::regclass AND polcmd IN ('a', '*')
      AND polname <> 'listings_insert_own'
  ) THEN
    RAISE EXCEPTION 'Autre politique INSERT/ALL : audit requis avant modification';
  END IF;
  IF EXISTS (
    SELECT 1 FROM pg_trigger
    WHERE tgrelid = 'public.listings'::regclass AND NOT tgisinternal
      AND tgenabled <> 'D' AND (tgtype::integer & 4) = 4
  ) THEN
    RAISE EXCEPTION 'Trigger INSERT deja present : examiner son ordre et ses effets';
  END IF;
END
$preflight$;

-- SECURITY INVOKER : pas de contournement de RLS ni lecture de donnees privilegiees.
-- CREATE sans OR REPLACE : une collision de nom interrompt la transaction.
CREATE FUNCTION private.kibo_stamp_listing_publication()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog
AS $function$
BEGIN
  IF NEW.status::text = 'published' THEN
    NEW.published_at := statement_timestamp();
  END IF;
  RETURN NEW;
END
$function$;

REVOKE ALL ON FUNCTION private.kibo_stamp_listing_publication() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER kibo_stamp_listing_publication
BEFORE INSERT ON public.listings
FOR EACH ROW EXECUTE FUNCTION private.kibo_stamp_listing_publication();

-- Pas de nouvelle politique permissive OR qui contournerait la politique existante.
-- Les voies draft/pending precedentes sont conservees pour compatibilite.
-- Le default pending n'est pas change : le client demande explicitement published.
ALTER POLICY listings_insert_own ON public.listings
TO authenticated
WITH CHECK (
  auth.uid() IS NOT NULL
  AND seller_id = auth.uid()
  AND views_count = 0
  AND rejection_reason IS NULL
  AND (
    (status::text IN ('draft', 'pending') AND published_at IS NULL)
    OR (status::text = 'published' AND published_at = statement_timestamp())
  )
);

-- Aucune modification des politiques SELECT/UPDATE/DELETE, des triggers UPDATE,
-- categories/favorites/Storage, grants de tables ou lignes deja presentes.
COMMIT;
