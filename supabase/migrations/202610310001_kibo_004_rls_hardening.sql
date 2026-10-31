-- KIBO-004: harden profile access, listing transitions, and listing image limits.
-- Apply only after reviewing against the live project; this migration is not auto-applied.

begin;

-- The auth trigger invokes this function as its owner. Clients do not need
-- direct EXECUTE permission on it.
revoke all on function public.handle_new_user() from public, anon, authenticated;

-- RLS controls rows, not columns. Replace broad table grants with a public-safe
-- column allowlist and a narrow authenticated profile-update allowlist.
revoke all on table public.profiles from anon, authenticated;
grant select (id, username, full_name, avatar_path, city, neighborhood, account_type, created_at)
  on table public.profiles to anon, authenticated;
grant update (username, full_name, avatar_path, bio, city, neighborhood, account_type)
  on table public.profiles to authenticated;

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

  if new.seller_id is distinct from old.seller_id
     or new.views_count is distinct from old.views_count
     or new.published_at is distinct from old.published_at
     or new.rejection_reason is distinct from old.rejection_reason then
    raise exception 'seller cannot modify system-managed listing fields';
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

  if image_count >= 8 then
    raise exception 'A listing may have at most 8 images';
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
