-- KIBO-004: harden seller-controlled listing transitions and enforce the V1 image limit.
-- Apply only after reviewing against the live project; this migration is not auto-applied.

begin;

create or replace function public.guard_listing_owner_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select private.is_admin()) then
    return new;
  end if;

  if new.seller_id is distinct from old.seller_id then
    raise exception 'seller_id cannot be changed';
  end if;

  if new.status is distinct from old.status then
    if old.status in ('draft'::public.listing_status, 'rejected'::public.listing_status)
       and new.status = 'pending'::public.listing_status then
      null;
    else
      raise exception 'seller cannot perform this listing status transition';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.guard_listing_owner_update() from public, anon, authenticated;

drop trigger if exists listings_guard_owner_update on public.listings;
create trigger listings_guard_owner_update
before update on public.listings
for each row execute function public.guard_listing_owner_update();

create or replace function public.enforce_listing_image_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  image_count integer;
begin
  -- Serialize concurrent inserts for a listing so simultaneous uploads cannot
  -- bypass the maximum.
  perform pg_advisory_xact_lock(hashtextextended(new.listing_id::text, 0));

  select count(*)::integer
    into image_count
    from public.listing_images
   where listing_id = new.listing_id;

  if image_count >= 3 then
    raise exception 'A listing may have at most 3 images';
  end if;

  return new;
end;
$$;

revoke all on function public.enforce_listing_image_limit() from public, anon, authenticated;

drop trigger if exists listing_images_enforce_limit on public.listing_images;
create trigger listing_images_enforce_limit
before insert on public.listing_images
for each row execute function public.enforce_listing_image_limit();

commit;
