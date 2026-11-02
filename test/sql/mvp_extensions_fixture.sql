ALTER TABLE public.profiles ADD COLUMN full_name text;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
UPDATE public.profiles SET full_name='Membre fictif';
