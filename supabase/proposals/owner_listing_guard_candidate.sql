-- CANDIDAT LOCAL UNIQUEMENT. Pas une migration distante prête à appliquer.
-- Ne remplace/attache aucun trigger. Comparer d'abord TOUS les guards distants.
-- Le type status doit contenir sold avant les tests/applications correspondants.
CREATE FUNCTION private.kibo_owner_management_candidate()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path = '' AS $$
BEGIN
  IF private.is_admin() THEN RETURN NEW; END IF;
  IF auth.uid() IS NULL OR OLD.seller_id IS DISTINCT FROM auth.uid()
     OR NEW.seller_id IS DISTINCT FROM OLD.seller_id THEN
    RAISE EXCEPTION 'Listing owner required' USING ERRCODE = '42501';
  END IF;
  -- Liste fermée : protège aussi les futures colonnes par défaut. Le vecteur
  -- généré est recalculé après les BEFORE triggers ; updated_at est horodaté
  -- par le trigger existant, à préserver dans le futur delta définitif.
  IF (to_jsonb(NEW) - ARRAY['title','description','price','category_id','city',
      'neighborhood','listing_type','status','updated_at','kibo_search_vector'])
     IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['title','description','price','category_id','city',
      'neighborhood','listing_type','status','updated_at','kibo_search_vector']) THEN
    RAISE EXCEPTION 'Protected listing fields' USING ERRCODE = '42501';
  END IF;
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    IF NOT ((OLD.status::text = 'published' AND NEW.status::text IN ('sold','archived'))
       OR (OLD.status::text = 'sold' AND NEW.status::text = 'archived')) THEN
      RAISE EXCEPTION 'Listing transition refused' USING ERRCODE = '42501';
    END IF;
    IF (to_jsonb(NEW) - ARRAY['status','updated_at','kibo_search_vector'])
       IS DISTINCT FROM
       (to_jsonb(OLD) - ARRAY['status','updated_at','kibo_search_vector']) THEN
      RAISE EXCEPTION 'Separate content and status updates' USING ERRCODE = '42501';
    END IF;
  ELSIF OLD.status::text NOT IN ('draft','published') THEN
    RAISE EXCEPTION 'Listing content is read only' USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.kibo_owner_management_candidate() FROM PUBLIC;
