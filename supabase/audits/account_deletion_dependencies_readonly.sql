-- Audit de métadonnées uniquement : aucun utilisateur ou objet Storage lu.
-- Ne constitue ni une migration ni une commande de suppression.
BEGIN READ ONLY;
SELECT conrelid::regclass::text AS source_table,
       confrelid::regclass::text AS target_table,
       conname AS constraint_name, pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE contype='f' AND (
 confrelid IN('auth.users'::regclass,'public.profiles'::regclass,
 'public.listings'::regclass,'public.conversations'::regclass,'public.listing_comments'::regclass)
 OR conrelid IN('public.kibo_account_requests'::regclass,'public.kibo_account_request_events'::regclass))
ORDER BY source_table,constraint_name;
SELECT conrelid::regclass::text AS source_table,conname AS constraint_name,
       pg_get_constraintdef(oid) AS definition
FROM pg_constraint WHERE contype='c' AND conrelid IN(
 'public.reports'::regclass,'public.conversations'::regclass,
 'public.messages'::regclass,'public.listing_comments'::regclass)
ORDER BY source_table,constraint_name;
SELECT table_schema,table_name,column_name,is_nullable,data_type
FROM information_schema.columns
WHERE (table_schema='public' AND table_name IN('profiles','messages','conversations','reports','listing_comments','kibo_account_request_events'))
   OR (table_schema='storage' AND table_name='objects' AND column_name IN('owner','owner_id','name','bucket_id'))
ORDER BY table_schema,table_name,ordinal_position;
COMMIT;
