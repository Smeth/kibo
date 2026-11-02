-- Audit d'état uniquement : aucune écriture, aucun secret ni contenu de message.
-- À exécuter avec un accès opérateur autorisé, jamais depuis Flutter.
BEGIN TRANSACTION READ ONLY;
SELECT status, count(*) FROM public.listings GROUP BY status;
SELECT count(*) AS seed_listings FROM public.listings
WHERE position('kibo-demo-20261102-v1' IN description)>0
   OR position('kibo-stress-20261102-v1' IN description)>0;
SELECT c.relname, c.relrowsecurity,
 (SELECT count(*) FROM pg_policy p WHERE p.polrelid=c.oid) AS policies
FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname='public' AND c.relkind IN ('r','p') ORDER BY c.relname;
SELECT id,public,file_size_limit,allowed_mime_types FROM storage.buckets;
SELECT count(*) AS missing_objects FROM public.kibo_listing_photos p
LEFT JOIN storage.objects o ON o.bucket_id='kibo-listing-photos' AND o.name=p.path
WHERE o.id IS NULL;
SELECT count(*) AS objects_without_reservation FROM storage.objects o
LEFT JOIN public.kibo_listing_photos p ON p.path=o.name
WHERE o.bucket_id='kibo-listing-photos' AND p.path IS NULL;
SELECT is_nullable FROM information_schema.columns
WHERE table_schema='public' AND table_name='listings' AND column_name='price';
SELECT count(*) AS verified_admin_mfa FROM auth.mfa_factors f
JOIN auth.users u ON u.id=f.user_id
WHERE f.status::text='verified' AND u.raw_app_meta_data->>'role'='admin';
-- Reproduction du défaut de préfixes français, même sans les données du catalogue.
SELECT to_tsvector('french',U&'T\00e9l\00e9phone') AS vector,
       to_tsquery('french',U&'t\00e9l:*') AS prefix_query,
       to_tsvector('french',U&'T\00e9l\00e9phone')
         @@ to_tsquery('french',U&'t\00e9l:*') AS matches;
SELECT q, to_tsquery('french',q||':*')::text AS transformed_query,
 (SELECT count(*) FROM public.listings WHERE status='published'
   AND kibo_search_vector @@ to_tsquery('french',q||':*')) AS matches
FROM unnest(ARRAY['iph',U&'t\00e9l',U&'t\00e9l\00e9',U&'t\00e9l\00e9phone']) q;
COMMIT;
