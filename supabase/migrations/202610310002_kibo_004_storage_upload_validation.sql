-- KIBO-004: validate image MIME and size at the Storage policy as defense in depth.
-- The bucket also enforces the same allowlist and 5 MiB cap.

begin;

drop policy if exists listing_storage_upload on storage.objects;
create policy listing_storage_upload on storage.objects
for insert to authenticated
with check (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and (metadata->>'mimetype') in ('image/jpeg','image/png','image/webp')
  and coalesce(metadata->>'size','') ~ '^[0-9]+$'
  and (metadata->>'size')::bigint <= 5242880
  and exists (
    select 1 from public.listings l
    where l.id::text = (storage.foldername(objects.name))[2]
      and l.seller_id = (select auth.uid())
      and l.status in ('draft'::public.listing_status,'pending'::public.listing_status,'rejected'::public.listing_status)
  )
);

commit;
