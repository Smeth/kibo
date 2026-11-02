-- Isolate the two known fixture batches without deleting or changing their rows.
BEGIN;
CREATE FUNCTION private.kibo_is_catalogue_fixture(p_description text) RETURNS boolean
LANGUAGE sql IMMUTABLE PARALLEL SAFE SECURITY INVOKER SET search_path='' AS $$
 SELECT coalesce(p_description LIKE 'DONNÉE FICTIVE — lot kibo-demo-20261102-v1, %'
  OR p_description LIKE 'DONNÉE FICTIVE — lot kibo-stress-20261102-v1, %',false)
$$;
REVOKE ALL ON FUNCTION private.kibo_is_catalogue_fixture(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.kibo_is_catalogue_fixture(text) TO anon,authenticated;
CREATE POLICY kibo_catalogue_fixture_scope ON public.listings AS RESTRICTIVE FOR SELECT TO anon,authenticated
USING(NOT private.kibo_is_catalogue_fixture(description) OR seller_id=(SELECT auth.uid()) OR (SELECT private.is_admin()));
COMMIT;
