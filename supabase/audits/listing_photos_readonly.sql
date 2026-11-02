-- Requis avant toute proposition d'application : aucune écriture.
BEGIN READ ONLY;
SELECT id, name, public, file_size_limit, allowed_mime_types FROM storage.buckets;
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies WHERE schemaname = 'storage' OR tablename IN ('listing_images','listing_photos','kibo_listing_photos');
SELECT table_name, column_name, data_type FROM information_schema.columns
WHERE table_schema = 'public' AND table_name IN ('listing_images','listing_photos','kibo_listing_photos');
ROLLBACK;
