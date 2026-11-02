BEGIN READ ONLY;
SELECT 'grant' AS item,n.nspname AS schema,c.relname AS object,
 jsonb_build_object('grantor',pg_get_userbyid(a.grantor),
 'grantee',CASE WHEN a.grantee=0 THEN 'PUBLIC' ELSE pg_get_userbyid(a.grantee) END,
 'privilege',a.privilege_type,'grantable',a.is_grantable)::text AS value
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
CROSS JOIN LATERAL aclexplode(c.relacl) a
WHERE n.nspname='public' AND c.relkind IN ('r','p')
 AND a.privilege_type IN ('TRUNCATE','REFERENCES','TRIGGER')
 AND (a.grantee=0 OR pg_get_userbyid(a.grantee) IN ('anon','authenticated'))
UNION ALL
SELECT 'default',coalesce(n.nspname,'GLOBAL'),pg_get_userbyid(d.defaclrole),
 jsonb_build_object('type',d.defaclobjtype,'acl',d.defaclacl::text)::text
FROM pg_default_acl d LEFT JOIN pg_namespace n ON n.oid=d.defaclnamespace
WHERE d.defaclnamespace=0 OR n.nspname='public'
UNION ALL
SELECT 'membership',NULL,m.rolname,r.rolname
FROM pg_auth_members a JOIN pg_roles r ON r.oid=a.roleid JOIN pg_roles m ON m.oid=a.member
WHERE m.rolname IN ('anon','authenticated')
ORDER BY item,schema,object,value;
ROLLBACK;
