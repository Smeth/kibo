-- Exclusivement dans une NOUVELLE base de fixture locale. Jamais à distance.
-- Le statut sold n'est pas présumé présent sur le serveur réel.
ALTER TYPE public.listing_status ADD VALUE 'sold';
DROP TRIGGER fixture_existing_update_guard ON public.listings;
CREATE TRIGGER fixture_owner_management_guard BEFORE UPDATE ON public.listings
FOR EACH ROW EXECUTE FUNCTION private.kibo_owner_management_candidate();
CREATE FUNCTION private.fixture_owner_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := clock_timestamp(); RETURN NEW; END $$;
CREATE TRIGGER fixture_z_updated_at BEFORE UPDATE ON public.listings
FOR EACH ROW EXECUTE FUNCTION private.fixture_owner_updated_at();
