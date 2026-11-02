-- RETOUR ARRIERE POUR REVUE UNIQUEMENT : RETABLIT DES DROITS EXCESSIFS.
-- Ne pas executer a distance sans autorisation distincte et nouvelle revue ACL.
BEGIN;
GRANT TRUNCATE, REFERENCES, TRIGGER ON public.categories, public.notifications, public.listing_images, public.favorites, public.conversations, public.messages, public.listing_comments, public.reports, public.listings TO anon,authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT TRUNCATE,REFERENCES,TRIGGER ON TABLES TO anon,authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public GRANT TRUNCATE,REFERENCES,TRIGGER ON TABLES TO anon,authenticated;
COMMIT;
