-- PROPOSITION LOCALE ; retour arriere soumis a autorisation distincte.
BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='20s';
LOCK TABLE public.listings IN SHARE ROW EXCLUSIVE MODE;
DO $check$ DECLARE r jsonb; BEGIN
 IF (SELECT count(*) FROM pg_proc WHERE oid IN ('private.guard_listing_update()'::regprocedure,
     'public.guard_listing_owner_update()'::regprocedure) AND prosrc=$guard$
BEGIN
  IF private.is_admin() THEN RETURN NEW; END IF;
  IF auth.uid() IS NULL OR OLD.seller_id IS DISTINCT FROM auth.uid()
     OR NEW.seller_id IS DISTINCT FROM OLD.seller_id THEN
    RAISE EXCEPTION 'Listing owner required' USING ERRCODE='42501';
  END IF;
  IF (to_jsonb(NEW) - ARRAY['title','description','price','category_id','city',
       'neighborhood','listing_type','status','updated_at','kibo_search_vector'])
     IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['title','description','price','category_id','city',
       'neighborhood','listing_type','status','updated_at','kibo_search_vector']) THEN
    RAISE EXCEPTION 'Protected listing fields' USING ERRCODE='42501';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT ((OLD.status::text='published' AND NEW.status::text IN ('sold','archived'))
        OR (OLD.status::text='sold' AND NEW.status::text='archived')) THEN
      RAISE EXCEPTION 'Listing transition refused' USING ERRCODE='42501';
    END IF;
    IF (to_jsonb(NEW) - ARRAY['status','updated_at','kibo_search_vector'])
       IS DISTINCT FROM
       (to_jsonb(OLD) - ARRAY['status','updated_at','kibo_search_vector']) THEN
      RAISE EXCEPTION 'Separate content and status' USING ERRCODE='42501';
    END IF;
  ELSIF OLD.status::text NOT IN ('draft','published') THEN
    RAISE EXCEPTION 'Listing content is read only' USING ERRCODE='42501';
  END IF;
  RETURN NEW;
END;
$guard$
     AND prosecdef=(proname='guard_listing_owner_update') AND proconfig=ARRAY['search_path=""'])<>2
 THEN RAISE EXCEPTION 'Guards changed after proposal'; END IF;
 -- JSON preserve les retours CRLF de la source auditee, contrairement a un copier/coller editeur.
 FOR r IN SELECT * FROM jsonb_array_elements($json$[{"schema":"private","name":"guard_listing_update","source_hash":"377f587c638fc660c0958628c695b06a","definition":"CREATE OR REPLACE FUNCTION private.guard_listing_update()\n RETURNS trigger\n LANGUAGE plpgsql\n SET search_path TO ''\nAS $function$\r\nbegin\r\n  if not private.is_admin() then\r\n\r\n    if new.seller_id is distinct from old.seller_id then\r\n      raise exception 'Modification du vendeur interdite';\r\n    end if;\r\n\r\n    if new.status is distinct from old.status then\r\n      raise exception 'Modification du statut interdite';\r\n    end if;\r\n\r\n    if new.views_count is distinct from old.views_count then\r\n      raise exception 'Modification des vues interdite';\r\n    end if;\r\n\r\n    if new.published_at is distinct from old.published_at then\r\n      raise exception 'Modification de publication interdite';\r\n    end if;\r\n\r\n    if new.rejection_reason is distinct from old.rejection_reason then\r\n      raise exception 'Modification du motif de rejet interdite';\r\n    end if;\r\n  end if;\r\n\r\n  return new;\r\nend;\r\n$function$\n","acl":null},{"schema":"public","name":"guard_listing_owner_update","source_hash":"d196de0a983dd575381dcca46bef46ca","definition":"CREATE OR REPLACE FUNCTION public.guard_listing_owner_update()\n RETURNS trigger\n LANGUAGE plpgsql\n SECURITY DEFINER\n SET search_path TO ''\nAS $function$\nbegin\n  if (select private.is_admin()) then return new; end if;\n  if new.seller_id is distinct from old.seller_id\n     or new.views_count is distinct from old.views_count\n     or new.published_at is distinct from old.published_at\n     or new.rejection_reason is distinct from old.rejection_reason then\n    raise exception 'seller cannot modify system-managed listing fields';\n  end if;\n  if new.status is distinct from old.status then\n    if old.status in ('draft'::public.listing_status, 'rejected'::public.listing_status)\n       and new.status = 'pending'::public.listing_status then\n      null;\n    else raise exception 'seller cannot perform this listing status transition';\n    end if;\n  end if;\n  return new;\nend; $function$\n","acl":"{postgres=X/postgres,service_role=X/postgres}"}]$json$::jsonb) LOOP
   EXECUTE r->>'definition';
 END LOOP;
END $check$;
-- sold reste dans l'enum ; aucune donnee convertie/supprimee.
COMMIT;
