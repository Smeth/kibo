-- Delta audite et applique sur KIBO le 2026-11-01, controle REST 200.
-- Seulement si la politique appelle bien private.is_admin() et si son corps
-- revu est un predicat booleen sans effet de bord, protege cote serveur.
-- Ne pas substituer une fonction public.is_admin() sans verifier le contrat.
-- Aucun GRANT de role administrateur, SELECT de profils ou changement de RLS.
BEGIN;
DO $$
DECLARE target oid := to_regprocedure('private.is_admin()');
BEGIN
  IF target IS NULL OR NOT EXISTS (
    SELECT 1 FROM pg_proc WHERE oid = target AND prorettype = 'boolean'::regtype
      AND pronargs = 0 AND prokind = 'f' AND prosecdef AND provolatile = 's'
      AND regexp_replace(prosrc, '[[:space:]]', '', 'g') =
        'selectcoalesce(auth.jwt()->''app_metadata''->>''role''=''admin'',false);'
      AND proconfig = ARRAY['search_path=""']::text[]
  ) THEN
    RAISE EXCEPTION 'Signature is_admin inattendue : arret pour audit';
  END IF;
END $$;
-- authenticated possede deja EXECUTE ; ne changer que le role public bloque.
GRANT EXECUTE ON FUNCTION private.is_admin() TO anon;
COMMIT;
SELECT has_function_privilege('anon', 'private.is_admin()', 'EXECUTE') AS anon_execute;
