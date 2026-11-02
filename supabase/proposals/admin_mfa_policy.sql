-- Live role revocation and MFA: enrolled admins require an aal2 session.
BEGIN;
CREATE OR REPLACE FUNCTION private.is_admin() RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT auth.uid() IS NOT NULL
 AND coalesce(auth.jwt()->'app_metadata'->>'role'='admin',false)
 AND EXISTS(SELECT 1 FROM auth.users WHERE id=auth.uid() AND raw_app_meta_data->>'role'='admin')
 AND (auth.jwt()->>'aal'='aal2' OR NOT EXISTS(
  SELECT 1 FROM auth.mfa_factors WHERE user_id=auth.uid() AND status::text='verified'))
$$;
REVOKE ALL ON FUNCTION private.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.is_admin() TO anon,authenticated;
COMMIT;
