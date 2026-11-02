-- A visitor has no account to freeze and needs no access to the private schema.
BEGIN;
CREATE OR REPLACE FUNCTION public.kibo_request_guard() RETURNS void
LANGUAGE plpgsql SECURITY INVOKER SET search_path='' AS $$ BEGIN
 IF auth.uid() IS NULL THEN RETURN; END IF;
 IF NOT private.kibo_account_active(auth.uid()) THEN
  RAISE EXCEPTION 'Compte supprime ou suppression en cours' USING ERRCODE='42501';
 END IF;
END $$;
COMMIT;
