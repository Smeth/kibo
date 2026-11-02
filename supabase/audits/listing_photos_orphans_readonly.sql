-- Inventaire uniquement : aucune suppression automatique apres erreur reseau.
BEGIN READ ONLY;
SELECT o.name AS unreferenced_object
FROM storage.objects o LEFT JOIN public.kibo_listing_photos p ON p.path = o.name
WHERE o.bucket_id = 'kibo-listing-photos' AND p.path IS NULL;
SELECT p.listing_id, p.position, p.path AS reservation_without_object
FROM public.kibo_listing_photos p LEFT JOIN storage.objects o
  ON o.bucket_id = 'kibo-listing-photos' AND o.name = p.path
WHERE o.name IS NULL;
ROLLBACK;
