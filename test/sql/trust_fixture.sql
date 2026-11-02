ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS city text DEFAULT 'Brazzaville';
CREATE FUNCTION private.kibo_account_active(p_user uuid) RETURNS boolean LANGUAGE sql STABLE AS $$ SELECT p_user IS NOT NULL $$;
