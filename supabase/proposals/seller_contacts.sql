-- PROPOSITION LOCALE : appliquer uniquement apres autorisation explicite.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='20s';
DO $$ BEGIN
 IF to_regclass('public.kibo_seller_contacts') IS NOT NULL OR
    EXISTS(SELECT 1 FROM pg_namespace WHERE nspname='kibo_contact_private') OR
    to_regprocedure('public.kibo_listing_seller_contact(uuid)') IS NOT NULL
 THEN RAISE EXCEPTION 'Contact contract already exists; review instead of overwrite'; END IF;
END $$;
CREATE SCHEMA kibo_contact_private;
REVOKE ALL ON SCHEMA kibo_contact_private FROM PUBLIC,anon;
GRANT USAGE ON SCHEMA kibo_contact_private TO authenticated;
CREATE TABLE public.kibo_seller_contacts(
 owner_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
 phone_e164 text CHECK(phone_e164 IS NULL OR phone_e164 ~ '^\+[1-9][0-9]{1,14}$'),
 whatsapp_e164 text CHECK(whatsapp_e164 IS NULL OR whatsapp_e164 ~ '^\+[1-9][0-9]{1,14}$'),
 calls_enabled boolean NOT NULL DEFAULT false,
 whatsapp_enabled boolean NOT NULL DEFAULT false,
 updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 CHECK(NOT calls_enabled OR phone_e164 IS NOT NULL),
 CHECK(NOT whatsapp_enabled OR whatsapp_e164 IS NOT NULL)
);
ALTER TABLE public.kibo_seller_contacts ENABLE ROW LEVEL SECURITY;
-- Neutraliser aussi les privileges issus des default ACL historiques.
REVOKE ALL ON public.kibo_seller_contacts FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.kibo_seller_contacts TO authenticated;
GRANT INSERT(owner_id,phone_e164,whatsapp_e164,calls_enabled,whatsapp_enabled)
 ON public.kibo_seller_contacts TO authenticated;
GRANT UPDATE(phone_e164,whatsapp_e164,calls_enabled,whatsapp_enabled)
 ON public.kibo_seller_contacts TO authenticated;
CREATE POLICY contact_read_own ON public.kibo_seller_contacts FOR SELECT TO authenticated
 USING(owner_id=(SELECT auth.uid()));
CREATE POLICY contact_insert_own ON public.kibo_seller_contacts FOR INSERT TO authenticated
 WITH CHECK(owner_id=(SELECT auth.uid()));
CREATE POLICY contact_update_own ON public.kibo_seller_contacts FOR UPDATE TO authenticated
 USING(owner_id=(SELECT auth.uid())) WITH CHECK(owner_id=(SELECT auth.uid()));
CREATE FUNCTION kibo_contact_private.stamp_contact() RETURNS trigger
 LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$
 BEGIN NEW.updated_at:=clock_timestamp(); RETURN NEW; END $$;
REVOKE ALL ON FUNCTION kibo_contact_private.stamp_contact() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER contact_updated_at BEFORE UPDATE ON public.kibo_seller_contacts
 FOR EACH ROW EXECUTE FUNCTION kibo_contact_private.stamp_contact();
-- Lecture privilegiee et bornee : ne prend ni vendeur, ni colonne libre en parametre.
CREATE FUNCTION kibo_contact_private.listing_contact(p_listing_id uuid)
 RETURNS TABLE(phone_e164 text,whatsapp_e164 text)
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT CASE WHEN c.calls_enabled THEN c.phone_e164 END,
        CASE WHEN c.whatsapp_enabled THEN c.whatsapp_e164 END
 FROM public.listings l JOIN public.kibo_seller_contacts c ON c.owner_id=l.seller_id
 WHERE auth.uid() IS NOT NULL AND l.id=p_listing_id AND l.status::text='published'
   AND (c.calls_enabled OR c.whatsapp_enabled)
 $$;
REVOKE ALL ON FUNCTION kibo_contact_private.listing_contact(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION kibo_contact_private.listing_contact(uuid) TO authenticated;
CREATE FUNCTION public.kibo_listing_seller_contact(p_listing_id uuid)
 RETURNS TABLE(phone_e164 text,whatsapp_e164 text)
 LANGUAGE sql STABLE SECURITY INVOKER SET search_path='' AS $$
 SELECT * FROM kibo_contact_private.listing_contact(p_listing_id)
 $$;
REVOKE ALL ON FUNCTION public.kibo_listing_seller_contact(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.kibo_listing_seller_contact(uuid) TO authenticated;
COMMIT;
