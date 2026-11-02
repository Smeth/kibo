SELECT 'private_bucket' AS item,
  jsonb_build_object('id',id,'public',public,'limit',file_size_limit,'mime',allowed_mime_types)::text AS value
FROM storage.buckets WHERE id='kibo-listing-photos'
UNION ALL SELECT 'legacy_storage_hash',
  md5(string_agg(policyname||coalesce(qual,'')||coalesce(with_check,'')||roles::text||cmd,'|' ORDER BY policyname))
FROM pg_policies WHERE schemaname='storage' AND policyname IN ('listing_storage_delete','listing_storage_upload')
UNION ALL SELECT 'restrictive_guards',count(*)::text FROM pg_policies
WHERE schemaname='storage' AND tablename='objects' AND permissive='RESTRICTIVE'
  AND policyname IN ('kibo_photo_read_scope','kibo_photo_no_client_insert','kibo_photo_no_client_update','kibo_photo_no_client_delete')
UNION ALL SELECT 'photos_rls',relrowsecurity::text FROM pg_class WHERE oid='public.kibo_listing_photos'::regclass
UNION ALL SELECT 'client_owner_insert',has_column_privilege('authenticated','public.kibo_listing_photos','owner_id','INSERT')::text
UNION ALL SELECT 'client_path_update',has_column_privilege('authenticated','public.kibo_listing_photos','path','UPDATE')::text
UNION ALL SELECT 'indexes',jsonb_agg(jsonb_build_object('name',c.relname,'valid',i.indisvalid))::text
FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid WHERE i.indrelid='public.listings'::regclass
  AND c.relname IN ('kibo_listings_search_gin','kibo_listings_price')
UNION ALL SELECT 'migrations',jsonb_agg(jsonb_build_object('version',version,'name',name))::text
FROM supabase_migrations.schema_migrations WHERE version IN ('20261101022728','20261031220520')
UNION ALL SELECT 'listings_count',count(*)::text FROM public.listings
UNION ALL SELECT 'legacy_images_count',count(*)::text FROM public.listing_images
UNION ALL SELECT 'photo_reservations',count(*)::text FROM public.kibo_listing_photos;
