-- PROPOSITION LOCALE UNIQUEMENT. Autorisation distincte avant application distante.
-- Les droits du role postgres sont requis ; ne pas substituer un autre createur.
BEGIN;
DO $check$ BEGIN
 IF NOT pg_has_role(current_user,'postgres','MEMBER') THEN RAISE EXCEPTION 'Role postgres access required'; END IF;
 IF EXISTS(SELECT 1 FROM pg_default_acl d CROSS JOIN LATERAL aclexplode(d.defaclacl) a
  WHERE d.defaclrole='postgres'::regrole AND d.defaclnamespace=0 AND d.defaclobjtype='r'
    AND a.privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER')
    AND (a.grantee=0 OR a.grantee IN ('anon'::regrole,'authenticated'::regrole)))
 THEN RAISE EXCEPTION 'Global default grant requires separate review'; END IF;
END $check$;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
 REVOKE TRUNCATE, REFERENCES, TRIGGER ON TABLES FROM anon, authenticated RESTRICT;
COMMIT;
