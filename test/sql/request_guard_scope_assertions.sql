BEGIN;
REVOKE USAGE ON SCHEMA private FROM anon;
SET LOCAL ROLE anon;
SELECT public.kibo_request_guard();
RESET ROLE;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','11111111-1111-4111-8111-111111111111',true);
SELECT public.kibo_request_guard();
RESET ROLE;
UPDATE kibo_lifecycle_private.accounts SET frozen=true WHERE owner_id='11111111-1111-4111-8111-111111111111';
INSERT INTO kibo_lifecycle_private.accounts(owner_id,frozen) VALUES('11111111-1111-4111-8111-111111111111',true) ON CONFLICT(owner_id) DO UPDATE SET frozen=true;
SET LOCAL ROLE authenticated;
DO $$ BEGIN
 BEGIN PERFORM public.kibo_request_guard();RAISE EXCEPTION 'Frozen account accepted';EXCEPTION WHEN insufficient_privilege THEN
  IF SQLERRM NOT LIKE 'Compte supprime%' THEN RAISE;END IF;
 END;
END $$;
ROLLBACK;
