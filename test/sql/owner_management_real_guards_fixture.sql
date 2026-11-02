-- FIXTURE LOCALE UNIQUEMENT, apres direct_publication_fixture + delta INSERT.
CREATE ROLE service_role NOLOGIN;
CREATE ROLE supabase_admin NOLOGIN;
CREATE FUNCTION auth.jwt() RETURNS jsonb LANGUAGE sql STABLE AS
  $$ SELECT coalesce(nullif(current_setting('request.jwt.claims',true),''),'{}')::jsonb $$;
DO $baseline$ DECLARE r jsonb; BEGIN
  FOR r IN SELECT * FROM jsonb_array_elements($json$[{"schema":"private","name":"guard_listing_update","source_hash":"377f587c638fc660c0958628c695b06a","definition":"CREATE OR REPLACE FUNCTION private.guard_listing_update()\n RETURNS trigger\n LANGUAGE plpgsql\n SET search_path TO ''\nAS $function$\r\nbegin\r\n  if not private.is_admin() then\r\n\r\n    if new.seller_id is distinct from old.seller_id then\r\n      raise exception 'Modification du vendeur interdite';\r\n    end if;\r\n\r\n    if new.status is distinct from old.status then\r\n      raise exception 'Modification du statut interdite';\r\n    end if;\r\n\r\n    if new.views_count is distinct from old.views_count then\r\n      raise exception 'Modification des vues interdite';\r\n    end if;\r\n\r\n    if new.published_at is distinct from old.published_at then\r\n      raise exception 'Modification de publication interdite';\r\n    end if;\r\n\r\n    if new.rejection_reason is distinct from old.rejection_reason then\r\n      raise exception 'Modification du motif de rejet interdite';\r\n    end if;\r\n  end if;\r\n\r\n  return new;\r\nend;\r\n$function$\n","acl":null},{"schema":"private","name":"is_admin","source_hash":"87538ba0633583b774bba59ad602d3bc","definition":"CREATE OR REPLACE FUNCTION private.is_admin()\n RETURNS boolean\n LANGUAGE sql\n STABLE SECURITY DEFINER\n SET search_path TO ''\nAS $function$\r\n  select coalesce(\r\n    auth.jwt() -> 'app_metadata' ->> 'role' = 'admin',\r\n    false\r\n  );\r\n$function$\n","acl":"{postgres=X/postgres,authenticated=X/postgres,anon=X/postgres}"},{"schema":"private","name":"set_updated_at","source_hash":"608ef48381668ad5cc300914a52c93f5","definition":"CREATE OR REPLACE FUNCTION private.set_updated_at()\n RETURNS trigger\n LANGUAGE plpgsql\n SET search_path TO ''\nAS $function$\r\nbegin\r\n  new.updated_at := now();\r\n  return new;\r\nend;\r\n$function$\n","acl":null},{"schema":"public","name":"guard_listing_owner_update","source_hash":"d196de0a983dd575381dcca46bef46ca","definition":"CREATE OR REPLACE FUNCTION public.guard_listing_owner_update()\n RETURNS trigger\n LANGUAGE plpgsql\n SECURITY DEFINER\n SET search_path TO ''\nAS $function$\nbegin\n  if (select private.is_admin()) then return new; end if;\n  if new.seller_id is distinct from old.seller_id\n     or new.views_count is distinct from old.views_count\n     or new.published_at is distinct from old.published_at\n     or new.rejection_reason is distinct from old.rejection_reason then\n    raise exception 'seller cannot modify system-managed listing fields';\n  end if;\n  if new.status is distinct from old.status then\n    if old.status in ('draft'::public.listing_status, 'rejected'::public.listing_status)\n       and new.status = 'pending'::public.listing_status then\n      null;\n    else raise exception 'seller cannot perform this listing status transition';\n    end if;\n  end if;\n  return new;\nend; $function$\n","acl":"{postgres=X/postgres,service_role=X/postgres}"}]$json$::jsonb) LOOP
    EXECUTE r->>'definition';
  END LOOP;
END $baseline$;
REVOKE ALL ON FUNCTION private.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.is_admin() TO anon,authenticated;
REVOKE ALL ON FUNCTION public.guard_listing_owner_update() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.guard_listing_owner_update() TO service_role;
DROP TRIGGER fixture_existing_update_guard ON public.listings;
CREATE TRIGGER listings_guard BEFORE UPDATE ON public.listings FOR EACH ROW EXECUTE FUNCTION private.guard_listing_update();
CREATE TRIGGER listings_guard_owner_update BEFORE UPDATE ON public.listings FOR EACH ROW EXECUTE FUNCTION public.guard_listing_owner_update();
CREATE TRIGGER listings_updated_at BEFORE UPDATE ON public.listings FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();
ALTER TABLE public.listings ADD COLUMN kibo_search_vector tsvector GENERATED ALWAYS AS
 (setweight(to_tsvector('french'::regconfig,coalesce(title,'')),'A') ||
  setweight(to_tsvector('french'::regconfig,coalesce(description,'')),'B')) STORED;
-- Metadonnees photos de fixture : pas un test Storage.
CREATE TABLE public.fixture_photo_refs(listing_id uuid REFERENCES public.listings, path text);
ALTER TABLE public.fixture_photo_refs ENABLE ROW LEVEL SECURITY;
CREATE POLICY fixture_photo_read ON public.fixture_photo_refs FOR SELECT TO anon,authenticated
 USING (EXISTS(SELECT 1 FROM public.listings WHERE id=listing_id));
GRANT SELECT ON public.fixture_photo_refs TO anon,authenticated;
CREATE TABLE public.fixture_baseline_policies AS SELECT polname,polcmd,
 pg_get_expr(polqual,polrelid) AS qual,pg_get_expr(polwithcheck,polrelid) AS check_expr
 FROM pg_policy WHERE polrelid IN ('public.listings'::regclass,'public.favorites'::regclass);
CREATE TABLE public.fixture_baseline_acl AS SELECT oid::regprocedure::text AS signature,proacl::text AS acl,
 proowner,prosecdef,proconfig,prorettype,prolang FROM pg_proc WHERE oid IN
 ('private.guard_listing_update()'::regprocedure,'public.guard_listing_owner_update()'::regprocedure);
