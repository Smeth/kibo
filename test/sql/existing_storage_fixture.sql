-- Fixture locale seulement, avant la variante photos.
INSERT INTO storage.buckets (id,name,public) VALUES ('listing-images','listing-images',true);
CREATE POLICY legacy_other_bucket ON storage.objects FOR ALL TO authenticated
USING (bucket_id = 'listing-images') WITH CHECK (bucket_id = 'listing-images');
